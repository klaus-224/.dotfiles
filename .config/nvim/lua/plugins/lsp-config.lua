return {
	-- Mason for LSP management
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},

	-- Mason-LSPConfig to ensure specific LSP servers are installed
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
				},
			})
		end,
	},

	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})

			lspconfig.yamlls.setup({
				capabilities = capabilities,
			})

			lspconfig.dockerls.setup({
				capabilities = capabilities,
			})

			lspconfig.terraformls.setup({
				capabilities = capabilities,
			})

			lspconfig.bashls.setup({
				capabilities = capabilities,
			})

			-- Front end
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})

			lspconfig.prismals.setup({
				capabilities = capabilities,
			})

			lspconfig.svelte.setup({
				capabilities = capabilities,
			})

			lspconfig.html.setup({
				capabilities = capabilities,
			})

			lspconfig.cssls.setup({
				capabilities = capabilities,
			})

			-- you need to install this globally using pnpm or npm => npm i -g @tailwindcss/language-server
			lspconfig.tailwindcss.setup({
				capabilities = capabilities,
			})

			lspconfig.jsonls.setup({
				capabilities = capabilities,
			})


			-- hot keys
			local opts = { noremap = true, silent = true }
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts, { desc = "go to declaration" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts, { desc = "go to definition" })
			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover({ border = 'rounded' })
			end, opts)
			vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts, { desc = "go to implementation" })
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts, { desc = "go to references" })
			vim.keymap.set("n", "gl", function()
				vim.diagnostic.open_float({ border = 'rounded' })
			end, opts)
		end
	},
}
