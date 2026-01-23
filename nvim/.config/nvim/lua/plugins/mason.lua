return {
	{
		-- LSP Package manager
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},
	-- make sure LSPs are installed
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
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
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			require("lsp")
		end,
	},
}

