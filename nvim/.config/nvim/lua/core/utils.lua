local M = {}

M.opts = { noremap = true, silent = true }

function M.opts_with_desc(desc)
	return vim.tbl_extend('force', M.opts, { desc = desc })
end

function M.close_all_windows()
	local closed_windows = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= '' then     -- is_floating_window?
			vim.api.nvim_win_close(win, false) -- do not force
			table.insert(closed_windows, win)
		end
	end
	print(string.format('Closed %d windows: %s', #closed_windows, vim.inspect(closed_windows)))
end

function M.copy_to_clipboard()
	vim.cmd('normal! "+y')
	vim.notify("Copied selection to clipboard")
end

function M.copy_cwd()
	vim.fn.setreg('+', vim.fn.expand('%:p'))
	vim.notify('Copied file path to clipboard')
end

return M;
