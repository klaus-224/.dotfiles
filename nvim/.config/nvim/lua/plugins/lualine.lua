return {
	"nvim-lualine/lualine.nvim",
	enabled = false,
	dependencies = {
		"f-person/git-blame.nvim",
	},
	config = function()
		local git_blame = require("gitblame")
		-- hide gitblame inline
		vim.g.gitblame_display_virtual_text = 0

		require("lualine").setup({
			options = {
				theme = "catppuccin",
				globalstatus = true,
			},
			sections = {
				lualine_a = { "mode", "branch" },
				lualine_b = {},
				lualine_c = {
					{
						"filename",
						path = 1,
					},
				},
				lualine_x = {
					{ git_blame.get_current_blame_text, cond = git_blame.is_blame_text_available },
				},
				lualine_y = {},
				lualine_z = { "location" },
			},
		})
	end,
}
