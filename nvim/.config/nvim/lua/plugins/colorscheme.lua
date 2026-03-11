return {
	{
		"vague-theme/vague.nvim",
		name = "vague",
		lazy = false,
		priority = 1000,
		config = function()
			local function apply_vague_overrides()
				vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#5c6370", bg = "#1e222a" })
				vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#5c6370", bg = "#1e222a" })
				vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffd166", bg = "#1e222a", bold = true })
				vim.api.nvim_set_hl(0, "TabLine", { link = "LineNrAbove" })
				vim.api.nvim_set_hl(0, "TabLineFill", { link = "LineNrAbove" })
				vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffd166", bg = "#1e222a" })
			end

			require("vague").setup({
				italic = false,
			})

			-- sets vague as the default
			vim.cmd.colorscheme("vague")
			apply_vague_overrides()

			local group = vim.api.nvim_create_augroup("vague-highlight-overrides", { clear = true })
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = group,
				callback = function(args)
					if args.match == "vague" then
						apply_vague_overrides()
					end
				end,
			})
			vim.api.nvim_create_autocmd("VimEnter", {
				group = group,
				callback = function()
					if vim.g.colors_name == "vague" then
						vim.schedule(apply_vague_overrides)
					end
				end,
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		enabled = false,
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
