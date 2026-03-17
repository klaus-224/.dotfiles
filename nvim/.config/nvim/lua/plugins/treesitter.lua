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
				"bash",
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
				"sql",
			},
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "TSUpdate",
			callback = function()
				require("nvim-treesitter.parsers").zsh = {
					install_info = {
						url = "https://github.com/georgeharker/tree-sitter-zsh",
						files = { "src/parser.c" }, -- often optional; keep if needed for your TS version
						generate_from_json = false,
						queries = "nvim-queries",
					},
					tier = 3,
				}
			end,
		})
	end,
}
