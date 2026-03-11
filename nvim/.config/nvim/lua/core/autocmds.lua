vim.api.nvim_create_autocmd("RecordingEnter", {
	group = vim.api.nvim_create_augroup("macro-notify", { clear = true }),
	callback = function()
		local last_macro_reg = vim.fn.reg_recording()
		vim.notify("Recording macro @" .. last_macro_reg, vim.log.levels.INFO, { title = "Macros" })
	end,
})
