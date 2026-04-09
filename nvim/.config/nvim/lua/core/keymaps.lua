local set = vim.keymap.set
local k = vim.keycode
local f = require("custom.f")
local fn = f.fn

set("i", "jk", "<Esc>")
set("v", "q", "<Esc>")

set("n", "<leader>x", function()
	vim.cmd(".lua")
end, { desc = "Execute the current line" })

set("n", "<leader><leader>x", function()
	vim.cmd("source %")
	vim.notify("lua file reloaded")
end, { desc = "Execute the current file" })

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

-- copy current buffer absolute file path to system clipboard
set("n", "<leader>YY", function()
	vim.fn.setreg("+", vim.fn.expand("%:p"))
	vim.notify("Copied file path to clipboard")
end)

-- quickfix, loclist nav
set("n", "]]", "<cmd>cnext<CR>")
set("n", "[[", "<cmd>cprev<CR>")

-- lsp
set("n", "gd", vim.lsp.buf.definition)
set("n", "gD", vim.lsp.buf.declaration)
set("n", "gT", vim.lsp.buf.type_definition)
set("n", "<leader>ca", vim.lsp.buf.code_action)
set("n", "]d", fn(vim.diagnostic.jump, { count = 1, float = true }))
set("n", "[d", fn(vim.diagnostic.jump, { count = -1, float = true }))

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
	-- copy current selection to the system clipboad
end, { expr = true })
