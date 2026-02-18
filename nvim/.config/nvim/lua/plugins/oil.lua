return {
	'stevearc/oil.nvim',
	dependencies = {
		"JezerM/oil-lsp-diagnostics.nvim"
	},
	lazy = false,
	config = function()
		require("oil").setup({
			delete_to_trash = true,
			view_options = {
				show_hidden = true,
			},
		})
		-- keymaps
		local globals = require("core.globals")
		local utils = require('core.utils')

		globals.keymap.set("n", '<leader>-', "<CMD> Oil <CR>", utils.opts_with_desc(
			"Open oil"
		))
	end
}
