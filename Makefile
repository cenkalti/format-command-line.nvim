.PHONY: test lint demo

test:
	@echo "Running tests..."
	@lua tests/run_tests.lua


lint:
	@echo "Running luacheck..."
	@luacheck lua/ tests/ --globals vim


demo:
	@echo "Demo of format-command-line.nvim:"
	@lua -e 'package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"; local fmt = require("format-command-line"); local examples = {"curl --request POST --url https://api.example.com", "docker run -d --name app -p 8080:80 image:latest", "ps aux | grep nginx | head -10"}; for i, cmd in ipairs(examples) do print("Example " .. i .. ":"); print("Input:  " .. cmd); print("Output:"); print(fmt.format_command_line(cmd)); print(""); end'