-- format-command-line.nvim - A Neovim plugin for formatting shell command lines
-- This plugin formats long shell commands into multiple lines with proper indentation

local M = {}

-- Tokenizer for parsing shell command lines
-- Handles quoted strings, flags, operators, and regular arguments
local function tokenize_command(line)
    local tokens = {}
    local i = 1
    local len = #line

    while i <= len do
        local char = line:sub(i, i)

        -- Skip whitespace
        if char:match('%s') then
            i = i + 1
        -- Handle quoted strings (single and double quotes)
        elseif char == '"' or char == "'" then
            local quote_char = char
            local start = i
            i = i + 1

            -- Find closing quote, handling escaped quotes
            while i <= len do
                local current = line:sub(i, i)
                if current == quote_char then
                    -- Check if it's escaped
                    local escape_count = 0
                    local j = i - 1
                    while j >= 1 and line:sub(j, j) == '\\' do
                        escape_count = escape_count + 1
                        j = j - 1
                    end

                    if escape_count % 2 == 0 then
                        -- Not escaped, this is the closing quote
                        i = i + 1
                        break
                    end
                end
                i = i + 1
            end

            table.insert(tokens, {
                type = 'quoted',
                value = line:sub(start, i - 1),
            })
        -- Handle operators (&&, ||, |, >, >>, <, 2>, &>)
        elseif char == '&' and i < len and line:sub(i + 1, i + 1) == '&' then
            table.insert(tokens, { type = 'operator', value = '&&' })
            i = i + 2
        elseif char == '|' and i < len and line:sub(i + 1, i + 1) == '|' then
            table.insert(tokens, { type = 'operator', value = '||' })
            i = i + 2
        elseif char == '>' and i < len and line:sub(i + 1, i + 1) == '>' then
            table.insert(tokens, { type = 'operator', value = '>>' })
            i = i + 2
        elseif char == '2' and i < len and line:sub(i + 1, i + 1) == '>' then
            table.insert(tokens, { type = 'operator', value = '2>' })
            i = i + 2
        elseif char == '&' and i < len and line:sub(i + 1, i + 1) == '>' then
            table.insert(tokens, { type = 'operator', value = '&>' })
            i = i + 2
        elseif char == '|' or char == '>' or char == '<' then
            table.insert(tokens, { type = 'operator', value = char })
            i = i + 1
        -- Handle flags (starting with - or --)
        elseif char == '-' then
            local start = i
            i = i + 1

            -- Check for long flag (--)
            if i <= len and line:sub(i, i) == '-' then
                i = i + 1
            end

            -- Continue until whitespace or special character
            -- Include = in flags to handle --flag=value
            while i <= len do
                local current = line:sub(i, i)
                if current:match('%s') or current:match('[|>&<]') then
                    break
                end
                i = i + 1
            end

            table.insert(tokens, {
                type = 'flag',
                value = line:sub(start, i - 1),
            })
        -- Handle regular arguments
        else
            local start = i

            -- Continue until whitespace or special character
            while i <= len do
                local current = line:sub(i, i)
                if current:match('%s') or current:match('[|>&<]') then
                    break
                end
                i = i + 1
            end

            table.insert(tokens, {
                type = 'argument',
                value = line:sub(start, i - 1),
            })
        end
    end

    return tokens
end

-- Format tokens into multiple lines with proper indentation
-- Uses 4 spaces for indentation and backslash for line continuation
local function format_tokens(tokens)
    if #tokens == 0 then
        return ''
    end

    local lines = {}
    local current_line = ''
    local indent = '    ' -- 4 spaces
    local in_pipeline = false -- Track if we're in a pipeline after |

    local i = 1
    while i <= #tokens do
        local token = tokens[i]
        local value = token.value

        -- First token (command) goes on first line without indentation
        if i == 1 then
            current_line = value
            in_pipeline = false
        -- Operators start new lines without continuation on previous line
        elseif token.type == 'operator' then
            table.insert(lines, current_line)
            current_line = indent .. value
            -- Set pipeline flag for pipe operators only
            in_pipeline = (value == '|')
        -- Flags start new lines with continuation, but not when in a pipeline
        elseif token.type == 'flag' and not in_pipeline then
            -- Add continuation to previous line if it exists
            if current_line ~= '' then
                table.insert(lines, current_line .. ' \\')
            end
            current_line = indent .. value

            -- Check if next token is an argument (flag value)
            -- Only do this if the flag doesn't already contain = (like --timeout=30)
            if i < #tokens and tokens[i + 1].type == 'argument' and not value:find('=') then
                current_line = current_line .. ' ' .. tokens[i + 1].value
                -- Skip the next token since we processed it
                i = i + 1
            end
        -- Other arguments (including flags in pipelines) continue on same line
        else
            if current_line == '' then
                current_line = indent .. value
            else
                current_line = current_line .. ' ' .. value
            end
            -- Reset pipeline state if we hit && or ||
            if token.type == 'operator' and (value == '&&' or value == '||') then
                in_pipeline = false
            end
        end

        i = i + 1
    end

    -- Add the last line
    if current_line ~= '' then
        table.insert(lines, current_line)
    end

    return table.concat(lines, '\n')
end

-- Main formatting function
-- Takes a shell command line and returns formatted multi-line version
function M.format_command_line(line)
    -- Remove leading/trailing whitespace
    line = line:match('^%s*(.-)%s*$') or ''

    if line == '' then
        return line
    end

    -- Check if line is already formatted (contains backslash continuation)
    if line:find(' \\') then
        -- Already formatted, return as-is or could implement reformatting
        return line
    end

    -- Tokenize the command line
    local tokens = tokenize_command(line)

    -- Format tokens into multiple lines
    return format_tokens(tokens)
end

-- Format current line in normal mode
local function format_current_line()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

    local formatted = M.format_command_line(line)

    -- Replace current line with formatted version
    local formatted_lines = vim.split(formatted, '\n')
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, formatted_lines)

    -- Position cursor at the end of the formatted text
    local last_line = line_num - 1 + #formatted_lines
    local last_col = #formatted_lines[#formatted_lines]
    vim.api.nvim_win_set_cursor(0, { last_line, last_col })
end

-- Format selected text in visual mode
local function format_visual_selection()
    -- Get visual selection range
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local start_line = start_pos[2]
    local end_line = end_pos[2]

    -- Get selected lines
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local selected_text = table.concat(lines, ' ')

    -- Format the selected text
    local formatted = M.format_command_line(selected_text)

    -- Replace selection with formatted version
    local formatted_lines = vim.split(formatted, '\n')
    vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, formatted_lines)
end

-- Setup function to register commands
function M.setup()
    -- Only register commands if vim is available (running in Neovim)
    if vim and vim.api then
        -- Register the FormatCommandLine command
        vim.api.nvim_create_user_command('FormatCommandLine', function(opts)
            if opts.range > 0 then
                -- Visual mode
                format_visual_selection()
            else
                -- Normal mode
                format_current_line()
            end
        end, {
            range = true,
            desc = 'Format shell command line into multiple lines with proper indentation',
        })
    end
end


return M