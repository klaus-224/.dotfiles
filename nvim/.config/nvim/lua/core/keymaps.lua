local set = vim.keymap.set
local k = vim.keycode

vim.keymap.set("t", "<esc><esc>", "<C-\\><C-n>")
set("i", "jk", "<Esc>")
set("v", "q", "<Esc>")

-- select all
set("n", "<C-a>", "gg<S-v>G")

-- move selected lines up/down and keep selection
set("v", "J", ":m '>+1<CR>gv=gv")
set("v", "K", ":m '<-2<CR>gv=gv")

-- windows
set("n", "<M-,>", "<c-w>5<")
set("n", "<M-.>", "<c-w>5>")
set("n", "<M-t>", "<C-W>+")
set("n", "<M-s>", "<C-W>-")

-- quickfix, loclist nav
set("n", "]]", "<cmd>cnext<CR>")
set("n", "[[", "<cmd>cprev<CR>")

-- lsp
set("n", "K", vim.lsp.buf.hover)
set("n", "gd", vim.lsp.buf.definition)
set("n", "gD", vim.lsp.buf.declaration)
set("n", "<leader>ds", vim.lsp.buf.document_symbol)
set("n", "<leader>dS", vim.lsp.buf.workspace_symbol)

-- diagnostics
set("n", "<leader>dq", function()
	vim.diagnostic.setqflist()
	vim.cmd("copen")
end)
set("n", "<leader>dl", function()
	vim.diagnostic.setloclist()
	vim.cmd("lopen")
end)
set("n", "<leader>cd", vim.diagnostic.open_float)
set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)

-- Toggle virtual text and lines
vim.keymap.set("n", "gK", function()
	local cfg = vim.diagnostic.config()

	---@diagnostic disable-next-line: need-check-nil
	local text_enabled = cfg.virtual_text
	---@diagnostic disable-next-line: need-check-nil
	local lines_enabled = cfg.virtual_lines

	if type(text_enabled) == "table" and type(lines_enabled) == "table" then
		text_enabled = true
		lines_enabled = true
	end

	vim.diagnostic.config({
		virtual_text = not text_enabled,
		virtual_lines = not lines_enabled,
	})
end)

-- tabs
set("n", "<left>", "gT")
set("n", "<right>", "gt")

-- clear search hightlights
set("n", "<CR>", function()
	---@diagnostic disable-next-line: undefined-field
	if vim.v.hlsearch == 1 then
		vim.cmd.nohl()
		return ""
	else
		return k("<CR>")
	end
end, { expr = true })
