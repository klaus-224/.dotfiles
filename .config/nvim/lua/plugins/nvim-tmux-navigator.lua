return {
	"christoomey/vim-tmux-navigator",
	vim.keymap.set("n", "C-h", ":TmuxNavigateLeft<CR>", { desc = "tmux navigator switch left" }),
	vim.keymap.set("n", "C-j", ":TmuxNavigateDown<CR>", { desc = "tmux navigator switch down" }),
	vim.keymap.set("n", "C-k", ":TmuxNavigateUp<CR>", { desc = "tmux navigator switch up" }),
	vim.keymap.set("n", "C-l", ":TmuxNavigateRight<CR>", { desc = "tmux navigator switch right" }),
}
