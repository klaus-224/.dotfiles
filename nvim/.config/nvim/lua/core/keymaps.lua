local set = vim.keymap.set
local k = vim.keycode

set("i", "jk", "<Esc>")
set("v", "q", "<Esc>")

-- execute current line
set("n", "<leader>x", function()
	vim.cmd(".lua")
end)

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

-- quickfix, loclist nav
set("n", "]]", "<cmd>cnext<CR>")
set("n", "[[", "<cmd>cprev<CR>")

-- lsp
set("n", "K", vim.lsp.buf.hover)
set("n", "grr", vim.lsp.buf.references)
set("n", "gD", vim.lsp.buf.definition)
set("n", "gd", vim.lsp.buf.declaration)
set("n", "<leader>ca", vim.lsp.buf.code_action)

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
