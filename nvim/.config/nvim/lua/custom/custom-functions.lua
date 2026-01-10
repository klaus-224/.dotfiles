-- SQL FORMATTER - IN PROGRESS
function _G.FormatSQLWithCLI()
	local current_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local handle = io.popen('sql-formatter -', 'w')
	if handle then
		handle:write(table.concat(current_content, '\n'))
		handle:close()
	end

	local formatted_content = {}
	for line in io.popen('sql-formatter -', 'r') do
		table.insert(formatted_content, line:gsub('[\r\n]+$', ''))
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_content)
end

-- User command for SQL Formatter
vim.api.nvim_create_user_command('FormatSQL', 'lua FormatSQLWithCLI()', {})

-- Reload custom lua files
function ReloadCustomLuaFiles()
	local config_dir = vim.fn.stdpath("config") .. "/lua/custom/"
	local files = {
		"auto-cmds.lua",
		"custom-functions.lua",
	}
	for _, file in ipairs(files) do
		vim.cmd("luafile " .. config_dir .. file)
	end
	print("Custom config reloaded.")
end

-- User command to Reload lua
vim.api.nvim_create_user_command('ReloadLua', 'lua ReloadCustomLuaFiles()', {})

-- Decompress String
local lzstring = require('custom.lzstring')

function DecompressLZ()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local compressed = table.concat(lines, "\n")
	local decompressed = lzstring.decompressFromBase64(compressed)
	vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, vim.split(decompressed, "\n"))
end

vim.api.nvim_create_user_command("Decompress", function()
	DecompressLZ()
end, { range = true })
