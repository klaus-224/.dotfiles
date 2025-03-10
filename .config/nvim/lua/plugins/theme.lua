return {
	{
		"xiyaowong/transparent.nvim",
		config = function()
			local transparentConfig = require("transparent")

			-- General config
			transparentConfig.setup({
				-- table: default groups
				groups = {
					"Normal",
					"NormalNC",
					"Comment",
					"Constant",
					"Special",
					"Identifier",
					"Statement",
					"PreProc",
					"Type",
					"Underlined",
					"Todo",
					"String",
					"Function",
					"Conditional",
					"Repeat",
					"Operator",
					"Structure",
					"LineNr",
					"NonText",
					"SignColumn",
					"CursorLine",
					"CursorLineNr",
					"StatusLine",
					"StatusLineNC",
					"EndOfBuffer",
				},
				-- table: additional groups that should be cleared
				extra_groups = {
					"NormalFloat"
				},
				-- table: groups you don't want to clear
				exclude_groups = {},
				-- function: code to be executed after highlight groups are cleared
				-- Also the user event "TransparentClear" will be triggered
				on_clear = function() end,
			})

			-- clear neo tree
			transparentConfig.clear_prefix("NeoTree")
			transparentConfig.clear_prefix("Telescope")
		end,
	},
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
			})

			vim.cmd.colorscheme "catppuccin"
		end,
	},
	-- {
	-- 	"binhtran432k/dracula.nvim",
	-- 	lazy = false,
	-- 	name = "dracula",
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function()
	-- 		require("dracula").setup({
	-- 			style = "soft",
	-- 			transparent = true,
	-- 		})
	-- 		vim.cmd("colorscheme dracula")
	-- 	end,
	-- },
}
