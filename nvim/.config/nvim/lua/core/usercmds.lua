local M = {}

function M.setup()
	vim.api.nvim_create_user_command("Setwd", function()
		vim.cmd("cd " .. vim.fn.expand("%:p:h"))
	end, {})

	vim.api.nvim_create_user_command("TabRename", function(opts)
		vim.t.tabname = opts.args
	end, { nargs = 1 })
end

return M
