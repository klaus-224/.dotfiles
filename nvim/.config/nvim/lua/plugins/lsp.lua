return {
	{
		"mason-org/mason.nvim",
		dependencies = {
			-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins.
			{
				"folke/lazydev.nvim",
				ft = "lua",
				opts = {},
			},
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = {
						"bash-language-server",
						"basedpyright",
						"css-lsp",
						"docker-language-server",
						"html-lsp",
						"json-lsp",
						"lua-language-server",
						"prisma-language-server",
						"ruff",
						"svelte-language-server",
						"tailwindcss-language-server",
						"terraform",
						"tombi",
						"typescript-language-server",
						"yaml-language-server",
						"shellcheck",
					},
				},
			},
			-- Schema information.
			"b0o/SchemaStore.nvim",
		},
		opts = {},
		config = function(_, opts)
			require("mason").setup(opts)
			require("lsp").setup()

		end,
	},
}
