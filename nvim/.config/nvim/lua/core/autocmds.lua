vim.api.nvim_create_autocmd("RecordingEnter", {
	group = vim.api.nvim_create_augroup("macro-notify", { clear = true }),
	callback = function()
		local last_macro_reg = vim.fn.reg_recording()
		vim.notify("Recording macro @" .. last_macro_reg, vim.log.levels.INFO, { title = "Macros" })
	end,
})

-- save current cursor postion in marks
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SaveExitMark", { clear = true }),
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    -- overwrite global/file mark A in the current buffer
    vim.api.nvim_buf_set_mark(buf, "A", row, col, {})

    -- force-write ShaDa so persisted marks get updated
    pcall(vim.cmd, "wshada!")
  end,
})
