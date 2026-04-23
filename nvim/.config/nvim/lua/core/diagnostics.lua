local diag = vim.diagnostic

local function diagnostic_jump_callback(diagnostic, bufnr)
	if not diagnostic then
		return
	end

	diag.show(diagnostic.namespace, bufnr, { diagnostic }, {
		virtual_lines = { current_line = true },
		virtual_text = false,
		underline = true,
	})
end

diag.config({
	signs = false,
	underline = true,
	virtual_text = false,
	virtual_lines = false,
	severity_sort = true,
	float = {
		border = "rounded",
	},
	jump = {
		on_jump = diagnostic_jump_callback,
	},
})

-- Toggle virtual text and lines
vim.keymap.set("n", "gK", function()
	local cfg = diag.config()

	---@diagnostic disable-next-line: need-check-nil
	local text_enabled = cfg.virtual_text
	---@diagnostic disable-next-line: need-check-nil
	local lines_enabled = cfg.virtual_lines

	if type(text_enabled) == "table" and type(lines_enabled) == "table" then
		text_enabled = true
		lines_enabled = true
	end

	diag.config({
		virtual_text = not text_enabled,
		virtual_lines = not lines_enabled,
	})
end)

vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)

vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)

vim.keymap.set("n", "<leader>dq", function()
	vim.diagnostic.setqflist()
	vim.cmd("copen")
end, { desc = "All diagnostics" })

vim.keymap.set("n", "<leader>dl", function()
	vim.diagnostic.setloclist()
	vim.cmd("lopen")
end, { desc = "Buffer/window diagnostics" })

-- ignore .env
local group = vim.api.nvim_create_augroup("__env", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = ".env*",
	group = group,
	callback = function(args)
		diag.enable(false, { bufnr = args.buf })
	end,
})
