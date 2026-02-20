return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			highlight = { enable = true },
			sync_install = false,
			auto_install = true,
			modules = {},
			ignore_install = {},
			indent = { enable = true },
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"json",
				"jsonc",
				"javascript",
				"typescript",
				"tsx",
				"rust",
			},
		})
	end,
}
