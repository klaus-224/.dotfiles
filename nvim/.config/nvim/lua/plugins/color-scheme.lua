return {
	{
		"vague-theme/vague.nvim",
		name = "vague",
		lazy = false,
		priority = 1000,
		config = function()
			require("vague").setup({
				italic = false,
			})

			-- sets vague as the default
			vim.cmd.colorscheme("vague")
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
			})
		end,
	},
	{
		"tribela/transparent.nvim",
		event = "VimEnter",
		config = true,
	},
}
