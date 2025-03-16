return {
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
	-- transparent
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
					-- "NormalFloat",
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
}
