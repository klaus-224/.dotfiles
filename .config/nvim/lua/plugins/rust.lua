return {
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false, -- This plugin is already lazy
		config = function()
			local bufnr = vim.api.nvim_get_current_buf()
			vim.keymap.set(
				"n",
				"K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
				function()
					vim.cmd.RustLsp({ "hover", "actions" })
				end,
				{ silent = true, buffer = bufnr }
			)
		end,
	},
	{
		'rust-lang/rust.vim',
		ft = "rust",
		init = function()
			vim.g.rustfmt_autosave = 1
		end
	}
}
