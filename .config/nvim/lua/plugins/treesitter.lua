return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = { "lua", "rust", "toml" },
		})
		vim.api.nvim_set_hl(0, "TSNormal", { bg = "NONE" })

		vim.treesitter.language.register('markdown', 'octo')
	end,
}
