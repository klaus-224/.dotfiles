return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"yamlls",
					"prismals",
					-- "emmetls",
					-- "html_ls",
					"dockerls",
					-- "csharp_ls",
					"terraformls",
					"bashls",
					"svelte",
				},
			})
		end,
	},
	{
		"rmagatti/goto-preview", -- buffer window
		event = "BufEnter",
		config = true,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")
			local goto_preview = require('goto-preview')
			local border = {
				{ "┌", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "┐", "FloatBorder" },
				{ "│", "FloatBorder" },
				{ "┘", "FloatBorder" },
				{ "─", "FloatBorder" },
				{ "└", "FloatBorder" },
				{ "│", "FloatBorder" },
			}
			local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts = opts or {}
				opts.border = opts.border or border
				return orig_util_open_floating_preview(contents, syntax, opts, ...)
			end

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})

			lspconfig.yamlls.setup({
				capabilities = capabilities,
			})

			lspconfig.prismals.setup({
				capabilities = capabilities,
			})

			lspconfig.dockerls.setup({
				capabilities = capabilities,
			})

			-- lspconfig.csharp_ls.setup({
			-- 	capabilities = capabilities,
			-- })

			lspconfig.terraformls.setup({
				capabilities = capabilities,
			})

			lspconfig.bashls.setup({
				capabilities = capabilities,
			})

			lspconfig.svelte.setup({
				capabilities = capabilities,
			})

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", goto_preview.goto_preview_definition, {})
			vim.keymap.set("n", "gi", goto_preview.goto_preview_implementation, {})
			vim.keymap.set("n", "gr", goto_preview.goto_preview_references, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
