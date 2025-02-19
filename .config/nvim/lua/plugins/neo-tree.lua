return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		local neotree = require("neo-tree")
		vim.keymap.set("n", "E", ":Neotree toggle right<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "F", ":Neotree toggle float<CR>", { noremap = true, silent = true })

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
