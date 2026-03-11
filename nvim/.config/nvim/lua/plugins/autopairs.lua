return {
	{
		"windwp/nvim-autopairs",
		dependencies = {
			"windwp/nvim-ts-autotag",
		},
		event = "InsertEnter",
		config = function()
			-- for brackets
			local autopairs = require("nvim-autopairs")

			autopairs.setup({
				enable_check_bracket_line = true,
				ignored_next_char = "[%w%.]",
				fast_wrap = {},
				check_ts = true, -- treesitter
			})

			-- for html
			local autotag = require("nvim-ts-autotag")
			autotag.setup({
				opts = {
					enable_close = true, -- Auto close tags
					enable_rename = true, -- Auto rename pairs of tags
					enable_close_on_slash = false, -- Auto close on trailing </
				},
				per_filetype = {
					["html"] = {
						enable_close = false,
					},
				},
			})
		end,
	},
}
