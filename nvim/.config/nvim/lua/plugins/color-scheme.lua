return {
	{
		"vague-theme/vague.nvim",
		name = "vague",
		lazy = false,
		priority = 1000,
		config = function()
			require("vague").setup({})
			-- sets catpuccin as the default
			vim.cmd.colorscheme("vague")
		end,
	},
	{
		"gorgoroth",
		name = "gorgoroth",
		lazy = true,
		priority = 1000,
		config = function()
			require("black-metal").setup({
				theme = "gorgoroth",
				code_style = {
					comments = "none",
					headings = "bold", -- Markdown headings
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				-- transparent_background = true,
				-- integrations = {
				-- 	notify = true,
				-- },
				-- custom_highlights = function(colors)
				-- 	return {
				-- 		FloatBorder = { fg = colors.blue },
				-- 	}
				-- end,
			})
		end,
	},
	{
		'tribela/transparent.nvim',
		event = 'VimEnter',
		config = true,
	} }
