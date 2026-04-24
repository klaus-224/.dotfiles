
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("v", "q", "<Esc>")

-- execute current line
vim.keymap.set("n", "<leader>x", function()
	vim.cmd(".lua")
end)

vim.keymap.set("n", "<leader><leader>x", function()
	vim.cmd("source %")
	vim.notify("lua file reloaded")
end)

-- select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")

-- move selected lines up/down and keep selection
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- windows
vim.keymap.set("n", "<M-,>", "<c-w>5<")
vim.keymap.set("n", "<M-.>", "<c-w>5>")
vim.keymap.set("n", "<M-t>", "<C-W>+")
vim.keymap.set("n", "<M-s>", "<C-W>-")

-- quickfix, loclist nav
vim.keymap.set("n", "]]", "<cmd>cnext<CR>")
vim.keymap.set("n", "[[", "<cmd>cprev<CR>")

-- lsp
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol)
vim.keymap.set("n", "<leader>dS", vim.lsp.buf.workspace_symbol)
vim.keymap.set("n", "<leader>dq", function()
	vim.diagnostic.setqflist()
	vim.cmd("copen")
end)
vim.keymap.set("n", "<leader>dl", function()
	vim.diagnostic.setloclist()
	vim.cmd("lopen")
end)
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float)
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)

-- tabs
vim.keymap.set("n", "<left>", "gT")
vim.keymap.set("n", "<right>", "gt")

-- clear search hightlights
vim.keymap.set("n", "<CR>", function()
	---@diagnostic disable-next-line: undefined-field
	if vim.v.hlsearch == 1 then
		vim.cmd.nohl()
		return ""
	else
		return vim.keycode("<CR>")
	end
	-- copy current selection to the system clipboad
end, { expr = true })
