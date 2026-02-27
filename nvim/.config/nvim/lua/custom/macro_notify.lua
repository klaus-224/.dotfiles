local M = {}

function M.setup()
	local macro_group = vim.api.nvim_create_augroup("macro-notify", { clear = true })
	local last_macro_reg = nil

	vim.api.nvim_create_autocmd("RecordingEnter", {
		group = macro_group,
		callback = function()
			last_macro_reg = vim.fn.reg_recording()
			vim.notify("Recording macro @" .. last_macro_reg, vim.log.levels.INFO, { title = "Macros" })
		end,
	})

	vim.api.nvim_create_autocmd("RecordingLeave", {
		group = macro_group,
		callback = function()
			if last_macro_reg then
				vim.notify("Stopped recording @" .. last_macro_reg, vim.log.levels.INFO, { title = "Macros" })
				last_macro_reg = nil
			end
		end,
	})
end

return M
