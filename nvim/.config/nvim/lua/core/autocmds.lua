local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		callback = function()
			vim.diagnostic.setloclist({ open = false })
		end,
	})

	vim.api.nvim_create_autocmd("FileType", { pattern = "help", command = "wincmd L | vertical resize 80" })
end

return M
