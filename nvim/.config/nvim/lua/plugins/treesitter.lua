return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		-- Neovim 0.12.1 can crash in injected markdown/help docs when the
		-- fenced-code info-string directive resolves an invalid node.
		vim.treesitter.query.set("vimdoc", "injections", "")
		vim.treesitter.query.set("markdown", "injections", [[
((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
		]])

		require("nvim-treesitter.configs").setup({
			highlight = {
				-- enable = true,
				disable = function(lang, buf)
					return lang == "markdown" and vim.bo[buf].buftype == "nofile"
				end,
			},
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
						files = { "src/parser.c" },
						generate_from_json = false,
						queries = "nvim-queries",
					},
					tier = 3,
				}
			end,
		})
	end,
}
