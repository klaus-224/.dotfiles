vim.diagnostic.config({
	virtual_text = false,
	signs = false,
	float = {
		border = "rounded",
	},
	virtual_lines = {
		format = function(diagnostic)
			return diagnostic.message
		end,
	},
	jump = {
		float = true,
	},
})

-- keymaps
vim.keymap.set("n", "gK", function()
	local new_config = not vim.diagnostic.config().virtual_lines
	vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = "Toggle diagnostic virtual_lines" })

-- autocmds
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function()
		vim.diagnostic.setloclist({ open = false })
		vim.notify_once("Diagnostics updated", vim.log.levels.INFO, { title = "Diagnostics" })
	end,
})

-- ignore .env
local group = vim.api.nvim_create_augroup("__env", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = ".env*", -- Pattern to match .env, .env.local, etc.
	group = group,
	callback = function(args)
		vim.diagnostic.disable(args.buf)
	end,
})
