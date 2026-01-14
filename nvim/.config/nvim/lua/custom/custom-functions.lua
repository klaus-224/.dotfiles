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


KEYMAP = vim.keymap
OPTS = { noremap = true, silent = true }

function OPTS_WITH_DESC(desc)
	return vim.tbl_extend('force', opts, { desc = desc })
end
