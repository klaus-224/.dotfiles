local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Remap esc
keymap.set("i", "jk", "<Esc>", {})
keymap.set("v", "q", "<Esc>", {})

-- Select All
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Copy
-- keymap.set({"n", "v"}, "<C-c>", "\"+y")

keymap.set("n", "<leader>s", ":write<Return>", opts)
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
keymap.set("n", "<leader>=", [[<cmd>vertical resize +5<cr>]]) -- make the window bigger vertically
keymap.set("n", "<leader>-", [[<cmd>vertical resize -5<cr>]]) -- make the window smaller vertically
keymap.set("n", "<leader>+", [[<cmd>horizontal resize +2<cr>]]) -- make the window bigger horizontally by pressing shift and =
keymap.set("n", "<leader>_", [[<cmd>horizontal resize -2<cr>]]) -- make the window smaller horizontally by pressing shift and -

-- Formatting
keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})

-- Obsidian - TODO move to obsidian plugin
keymap.set("n", "<leader>oo", "<cmd>ObsidianBacklinks<cr>", { desc = "Obsidian Backlinks" })
keymap.set("n", "<leader>of", "<cmd>ObsidianFollowLink vsplit<cr>", { desc = "Obsidian Follow Link" })
keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Obsidian New Note" })
keymap.set("n", "<leader>ot", "<cmd>ObsidianToday<cr>", { desc = "Obsidian Today" })
keymap.set("n", "<leader>oy", "<cmd>ObsidianYesterday<cr>", { desc = "Obsidian Yesterday" })
keymap.set("n", "<leader>or", "<cmd>ObsidianTomorrow<cr>", { desc = "Obsidian Tomorrow" })

-- Close all floating windows
keymap.set("n", "<leader>W", function()
	local closed_windows = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" then -- is_floating_window?
			vim.api.nvim_win_close(win, false) -- do not force
			table.insert(closed_windows, win)
		end
	end
	print(string.format("Closed %d windows: %s", #closed_windows, vim.inspect(closed_windows)))
end)
