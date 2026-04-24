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
			vim.cmd.colorscheme("vague")

			-- overrides
			vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#5c6370", bg = "#1e222a" })
			vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#5c6370", bg = "#1e222a" })
			vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffd166", bg = "#1e222a", bold = true })
			vim.api.nvim_set_hl(0, "TabLine", { link = "LineNrAbove" })
			vim.api.nvim_set_hl(0, "TabLineFill", { link = "LineNrAbove" })
			vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffd166", bg = "#1e222a" })
		end,
	},
	{
		"tribela/transparent.nvim",
		event = "VimEnter",
		config = true,
	},
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({
				options = {
					icons_enabled = false,
					theme = "auto",
					component_separators = "",
					section_separators = "",
				},

				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = { "filename" },
					lualine_x = {
						function()
							local encoding = vim.o.fileencoding
							if encoding == "" then
								return vim.bo.fileformat .. " :: " .. vim.bo.filetype
							else
								return encoding .. " :: " .. vim.bo.fileformat .. " :: " .. vim.bo.filetype
							end
						end,
					},
					lualine_z = { "location" },
				},
			})
		end,
	},
}
