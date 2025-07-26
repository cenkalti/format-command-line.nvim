-- Test suite for format-command-line.nvim
-- Tests the tokenizer, formatter, and complete formatting functionality
local format_cmd = require('format-command-line')
describe('format-command-line', function()
    describe('tokenizer', function()
        it('should tokenize simple command', function()
            local result = format_cmd.format_command_line('ls -la')
            assert.is_not_nil(result)
        end)
        it('should handle quoted strings', function()
            local input = 'echo "hello world" \'single quote\''
            local result = format_cmd.format_command_line(input)
            assert.truthy(result:find('"hello world"'))
            assert.truthy(result:find("'single quote'"))
        end)
        it('should handle escaped quotes', function()
            local input = 'echo "hello \\"world\\"" \'it\\\'s here\''
            local result = format_cmd.format_command_line(input)
            assert.truthy(result:find('"hello \\"world\\""'))
            assert.truthy(result:find("'it\\'s here'"))
        end)
        it('should tokenize flags correctly', function()
            local input = 'curl -X POST --header "Content-Type: json"'
            local result = format_cmd.format_command_line(input)
            assert.truthy(result:find('-X POST'))
            assert.truthy(result:find('--header'))
        end)
        it('should handle operators', function()
            local input = 'command1 && command2 || command3 | grep test'
            local result = format_cmd.format_command_line(input)
            assert.truthy(result:find('&&'))
            assert.truthy(result:find('||'))
            assert.truthy(result:find('|'))
        end)
        it('should handle redirection operators', function()
            local input = 'command > file >> append < input 2> error &> all'
            local result = format_cmd.format_command_line(input)
            assert.truthy(result:find('>'))
            assert.truthy(result:find('>>'))
            assert.truthy(result:find('<'))
            assert.truthy(result:find('2>'))
            assert.truthy(result:find('&>'))
        end)
    end)
    describe('formatter', function()
        it('should format curl command correctly', function()
            local input = 'curl --request POST --url https://api.example.com/endpoint '
                .. '--header \'Content-Type: application/json\' --data \'{"key": "value"}\''
            local expected = 'curl \\\n    --request POST \\\n    --url https://api.example.com/endpoint \\'
                .. '\n    --header \'Content-Type: application/json\' \\\n    --data \'{"key": "value"}\''
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format command with operators', function()
            local input = 'curl --url example.com && echo "success" || echo "failed"'
            local expected = 'curl \\\n    --url example.com\n    && echo "success"\n    || echo "failed"'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format command with pipes', function()
            local input = 'ps aux | grep nginx | head -10'
            local expected = 'ps aux\n    | grep nginx\n    | head -10'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should handle complex docker command', function()
            local input = 'docker run -d --name myapp -p 8080:80 -v /host/path:/container/path '
                .. '-e NODE_ENV=production myimage:latest'
            local expected = 'docker run \\\n    -d \\\n    --name myapp \\\n    -p 8080:80 \\'
                .. '\n    -v /host/path:/container/path \\\n    -e NODE_ENV=production myimage:latest'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format git command with flags', function()
            local input = 'git log --oneline --graph --decorate --all'
            local expected = 'git log \\\n    --oneline \\\n    --graph \\\n    --decorate \\\n    --all'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should handle redirection', function()
            local input = 'find /var/log -name "*.log" -exec grep "error" {} \\; > errors.txt 2>&1'
            local result = format_cmd.format_command_line(input)
            -- Should include redirection operators
            assert.truthy(result:find('>'))
            assert.truthy(result:find('2>&1'))
        end)
        it('should preserve flag values on same line', function()
            local input = 'wget --timeout=30 --tries=3 --output-document=file.html https://example.com'
            local expected = 'wget \\\n    --timeout=30 \\\n    --tries=3 \\'
                .. '\n    --output-document=file.html https://example.com'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should handle mixed short and long flags', function()
            local input = 'tar -czf archive.tar.gz --exclude="*.tmp" /path/to/directory'
            local expected = 'tar \\\n    -czf archive.tar.gz \\\n    --exclude="*.tmp" /path/to/directory'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
    end)
    describe('edge cases', function()
        it('should handle empty string', function()
            local result = format_cmd.format_command_line('')
            assert.equals('', result)
        end)
        it('should handle whitespace only', function()
            local result = format_cmd.format_command_line('   \t  ')
            assert.equals('', result)
        end)
        it('should handle single command without flags', function()
            local input = 'ls'
            local result = format_cmd.format_command_line(input)
            assert.equals('ls', result)
        end)
        it('should handle already formatted command', function()
            local input = 'curl \\\n    --url example.com'
            local result = format_cmd.format_command_line(input)
            -- Should return as-is since it contains continuation
            assert.equals(input, result)
        end)
        it('should handle command with only arguments', function()
            local input = 'echo hello world'
            local result = format_cmd.format_command_line(input)
            assert.equals('echo hello world', result)
        end)
        it('should handle unclosed quotes gracefully', function()
            local input = 'echo "unclosed quote'
            local result = format_cmd.format_command_line(input)
            -- Should not crash, return some reasonable result
            assert.is_not_nil(result)
        end)
        it('should handle multiple consecutive operators', function()
            local input = 'command1 && command2 && command3'
            local expected = 'command1\n    && command2\n    && command3'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should handle flag at end of command', function()
            local input = 'git push origin main --force'
            local expected = 'git push origin main \\\n    --force'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
    end)
    describe('real world examples', function()
        it('should format ssh command', function()
            local input = 'ssh -i ~/.ssh/id_rsa -p 2222 -L 8080:localhost:8080 user@server.com'
            local expected = 'ssh \\\n    -i ~/.ssh/id_rsa \\\n    -p 2222 \\'
                .. '\n    -L 8080:localhost:8080 user@server.com'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format rsync command', function()
            local input = 'rsync -avz --progress --exclude="*.tmp" /source/ user@host:/destination/'
            local expected = 'rsync \\\n    -avz \\\n    --progress \\'
                .. '\n    --exclude="*.tmp" /source/ user@host:/destination/'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format ffmpeg command', function()
            local input = 'ffmpeg -i input.mp4 -vcodec libx264 -acodec aac -b:v 1000k -b:a 128k output.mp4'
            local expected = 'ffmpeg \\\n    -i input.mp4 \\\n    -vcodec libx264 \\\n    -acodec aac \\'
                .. '\n    -b:v 1000k \\\n    -b:a 128k output.mp4'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format complex pipeline', function()
            local input = 'cat /var/log/nginx/access.log | grep "POST" | awk \'{print $1}\' | '
                .. 'sort | uniq -c | sort -nr | head -10'
            local expected = 'cat /var/log/nginx/access.log\n    | grep "POST"\n    | awk \'{print $1}\''
                .. '\n    | sort\n    | uniq -c\n    | sort -nr\n    | head -10'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
        it('should format kubernetes command', function()
            local input = 'kubectl apply -f deployment.yaml --namespace=production --dry-run=client -o yaml'
            local expected = 'kubectl apply \\\n    -f deployment.yaml \\\n    --namespace=production \\'
                .. '\n    --dry-run=client \\\n    -o yaml'
            local result = format_cmd.format_command_line(input)
            assert.equals(expected, result)
        end)
    end)
end)