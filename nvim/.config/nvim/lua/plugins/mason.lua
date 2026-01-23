return {
	{
		"mason-org/mason.nvim",
		dependencies = { "mason-org/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
		config = function()
			-- Mason installer
			require("mason").setup({})
			-- LSP server management
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"yamlls",
					"dockerls",
					"terraformls",
					"bashls",
					"svelte",
					"prismals",
					"html",
					"cssls",
					"tailwindcss",
					"jsonls",
					"pyright",
				},
			})

			-- server and client setting
			require("lsp")
		end,
	},
}
