vim.diagnostic.config({
	virtual_text = true,
	signs = false,
	float = {
		border = "rounded",
	},
	virtual_lines = false,
	-- virtual_lines = {
	-- 	format = function(diagnostic)
	-- 		return diagnostic.message
	-- 	end,
	-- },
	jump = {
		float = true,
	},
})

local set = vim.keymap.set
set("n", "gK", function()
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
