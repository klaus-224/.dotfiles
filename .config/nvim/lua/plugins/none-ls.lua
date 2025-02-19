return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		local null_ls = require("null-ls")

		null_ls.setup({
			-- add linters, formatters, completion tools
			sources = {
				-- linter
				require("none-ls.code_actions.eslint_d"),
				-- formatters
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				-- null_ls.builtins.formatting.csharpier,
			},
		})

		-- Key maps
		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
