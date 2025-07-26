# format-command-line.nvim

A Neovim plugin for formatting long shell command lines into readable multi-line format with proper indentation and line continuations.

## Installation with lazy.nvim

```lua
{
    "cenkalti/format-command-line.nvim",
    config = function()
        require("format-command-line").setup()
    end,
}
```

## Usage

The plugin provides a single command: `FormatCommandLine`

Position your cursor on a line with a shell command or select text containing a shell command and run:
```
:FormatCommandLine
```

### Example

**Before:**
```bash
curl --request POST --url https://api.example.com/endpoint --header 'Content-Type: application/json' --data '{"key": "value"}' && echo "Success"
```

**After:**
```bash
curl \
    --request POST \
    --url https://api.example.com/endpoint \
    --header 'Content-Type: application/json' \
    --data '{"key": "value"}' \
&& echo "Success"
```

## Integration with Zsh

This plugin works great with zsh's `edit-command-line` widget. Add this to your `.zshrc`:

```bash
# Set Neovim as your editor
export EDITOR=nvim

# Enable edit-command-line widget
autoload edit-command-line
zle -N edit-command-line

# Bind Ctrl-X then E to edit current command line
bindkey '^Xe' edit-command-line
```

Now you can:
1. Type a long command in your shell
2. Press `Ctrl-X` then `E` to open it in Neovim
3. Run `:FormatCommandLine` to format it
4. Save and exit to return to your formatted command in the shell

## Formatting Rules

The plugin follows these opinionated formatting rules:

- **4 spaces** for indentation
- **Backslash (`\`)** for line continuations
- **Flags** (`--flag`, `-f`) start new lines
- **Operators** (`&&`, `||`, `|`) start new lines without continuation
- **Quoted strings** are preserved intact
- **Flag values** stay on the same line as their flag

## License

MIT
