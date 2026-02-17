return {
	-- color scheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.g.configured_colorschemes = { "catppuccin" }
			vim.g.default_colorscheme = "catppuccin"

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

			vim.cmd.colorscheme(vim.g.default_colorscheme)
		end,
	},
}
