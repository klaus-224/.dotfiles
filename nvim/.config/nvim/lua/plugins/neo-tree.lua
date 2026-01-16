return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "F", "<cmd>Neotree toggle float<cr>", desc = "Toggle Neo-tree" }
	},
	config = function()
		local neotree = require("neo-tree")
		neotree.setup({
			popup_border_style = "rounded",
			filesystem = {
				filtered_items = {
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
		})
	end,
}
