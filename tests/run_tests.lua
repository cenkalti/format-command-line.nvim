#!/usr/bin/env lua

-- Simple test runner for format-command-line.nvim
-- This script runs the test suite without requiring external test frameworks

-- Mock vim API for testing outside Neovim
_G.vim = {
    api = {
        nvim_create_user_command = function() end,
        nvim_win_get_cursor = function()
            return { 1 }
        end,
        nvim_buf_get_lines = function()
            return { '' }
        end,
        nvim_buf_set_lines = function() end,
        nvim_win_set_cursor = function() end,
    },
    split = function(str, sep)
        local result = {}
        local pattern = string.format('([^%s]+)', sep)
        for match in string.gmatch(str, pattern) do
            table.insert(result, match)
        end
        return result
    end,
    fn = {
        getpos = function()
            return { 0, 1, 1, 0 }
        end,
    },
}

-- Test framework functions
local current_describe = ''
local test_count = 0
local passed_count = 0
local failed_tests = {}

_G.describe = function(name, func)
    current_describe = name
    print('\\n' .. name .. ':')
    func()
end

_G.it = function(description, func)
    test_count = test_count + 1
    local test_name = current_describe .. ' ' .. description
    local success, err = pcall(func)
    if success then
        passed_count = passed_count + 1
        print('  ✓ ' .. description)
    else
        table.insert(failed_tests, { name = test_name, error = err })
        print('  ✗ ' .. description)
        print('    Error: ' .. tostring(err))
    end
end

-- Assertion functions
_G.assert = {}

_G.assert.equals = function(expected, actual)
    if expected ~= actual then
        error(string.format("Expected '%s', got '%s'", expected, actual))
    end
end

_G.assert.truthy = function(value)
    if not value then
        error('Expected truthy value, got ' .. tostring(value))
    end
end

_G.assert.is_not_nil = function(value)
    if value == nil then
        error('Expected non-nil value')
    end
end

-- Add package path to find our module
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- Load and run tests
loadfile('tests/format_command_line_spec.lua')()

-- Print summary
print('\\n' .. string.rep('=', 50))
print(string.format('Tests: %d passed, %d failed, %d total', passed_count, test_count - passed_count, test_count))

if #failed_tests > 0 then
    print('\\nFailed tests:')
    for _, test in ipairs(failed_tests) do
        print('  ' .. test.name)
    end
    os.exit(1)
else
    print('\\nAll tests passed! 🎉')
    os.exit(0)
end