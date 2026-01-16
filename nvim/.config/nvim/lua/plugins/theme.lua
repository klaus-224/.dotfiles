return {
	{
		"nvim-mini/mini.nvim",
		version = false
	},
	-- color scheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = true,
				integrations = {
					notify = true,
				},
				custom_highlights = function(colors)
					return {
						FloatBorder = { fg = colors.blue },
					}
				end,
			})
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
