local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Remap esc
keymap.set("i", "jk", "<Esc>", {})

-- Select All
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Save file and quit
keymap.set("n", "<leader>s", ":update<Return>", opts)
keymap.set("n", "<leader>w", ":quit<Return>", opts)
keymap.set("n", "<leader>Q", ":qa<Return>", opts)

-- Split window
keymap.set("n", "<leader>sv", ":vsplit<Return>", opts)
keymap.set("n", "<leader>sh", ":split<Return>", opts)

-- Move windows
keymap.set("n", "<leader>h", "<C-w>h")
keymap.set("n", "<leader>k", "<C-w>k")
keymap.set("n", "<leader>j", "<C-w>j")
keymap.set("n", "<leader>l", "<C-w>l")

-- Resize windows
keymap.set("n", "=", [[<cmd>vertical resize +5<cr>]]) -- make the window biger vertically
keymap.set("n", "-", [[<cmd>vertical resize -5<cr>]]) -- make the window smaller vertically
keymap.set("n", "+", [[<cmd>horizontal resize +2<cr>]]) -- make the window bigger horizontally by pressing shift and =
keymap.set("n", "_", [[<cmd>horizontal resize -2<cr>]]) -- make the window smaller horizontally by pressing shift and -

-- Formatting
keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})

-- LSP
keymap.set("n", "K", vim.lsp.buf.hover)
keymap.set("n", "gd", vim.lsp.buf.definition)
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)

-- Obsidian
keymap.set("n", "<leader>oo", "<cmd>ObsidianBacklinks<cr>", { desc = "Obsidian Backlinks" })
keymap.set("n", "<leader>of", "<cmd>ObsidianFollowLink vsplit<cr>", { desc = "Obsidian Follow Link" })
keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Obsidian New Note" })
keymap.set("n", "<leader>ot", "<cmd>ObsidianToday<cr>", { desc = "Obsidian Today" })
keymap.set("n", "<leader>oy", "<cmd>ObsidianYesterday<cr>", { desc = "Obsidian Yesterday" })
keymap.set("n", "<leader>or", "<cmd>ObsidianTomorrow<cr>", { desc = "Obsidian Tomorrow" })

