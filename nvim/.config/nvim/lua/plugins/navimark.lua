return {
	"zongben/navimark.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
		"folke/which-key.nvim"
	},
	config = function()
		local navimark = require('navimark')
		local wk = require("which-key")

		local keymaps = {
			base = {
				mark_toggle = "<leader>mm",
				goto_next_mark = "]m",
				goto_prev_mark = "[m",
				open_mark_picker = "<leader>fm",
			},
			telescope = {
				n = {
					delete_mark = "d",
					clear_marks = "c",
					new_stack = "n",
					next_stack = "<Tab>",
					rename_stack = "r",
					delete_stack = "D",
				},
			},

		}

		navimark.setup({
			key = keymaps
		})

		wk.add({
			{ "<leader>fm", desc = "Find marks (Telescope)" },
			{ "<leader>m",  group = "Marks" },
			{ "<leader>mm", desc = "Toggle mark" },
			{ "[m",         desc = "Previous mark" },
			{ "]m",         desc = "Next mark" },
		}, { mode = "n" })
	end,
}
