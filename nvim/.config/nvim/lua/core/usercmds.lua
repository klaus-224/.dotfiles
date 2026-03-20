vim.api.nvim_create_user_command("Setwd", function()
	vim.cmd("cd " .. vim.fn.expand("%:p:h"))
end, {})
