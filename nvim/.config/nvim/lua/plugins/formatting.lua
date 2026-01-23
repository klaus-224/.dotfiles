return {
	"stevearc/conform.nvim",
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			desc = "Format buffer",
		},
	},
	config = function()
		require("conform").setup({
			formatters = {
				prettier = {
					options = {
						single_quote = true,
					},
					prefer_local = "node_modules/.bin",
				},
				biome = {
					prefer_local = "node_modules/.bin",
					condition = function(_)
						-- Use biome if biome.json exists in the project
						return vim.fn.filereadable(vim.fn.getcwd() .. "/biome.json") == 1
					end,
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "biome", "prettier", stop_after_first = true },
				typescript = { "biome", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettier", stop_after_first = true },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			-- Set up format-on-save
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			-- Notify on format errors
			notify_on_error = true,
		})
	end,
}
