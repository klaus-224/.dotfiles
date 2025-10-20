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

vim.api.nvim_create_user_command('FormatSQL', 'lua FormatSQLWithCLI()', {})
