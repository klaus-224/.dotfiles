local M = {}

local function apply_line_number_highlights()
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffd166", bg = "#1e222a", bold = true })
end

local function apply_tab_line_highlights()
	vim.api.nvim_set_hl(0, "TabLine", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "TabLineFill", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffd166", bg = "#1e222a" })
end

function M.setup()
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = function()
			apply_line_number_highlights()
			apply_tab_line_highlights()
		end,
	})

	if vim.g.colors_name then
		apply_line_number_highlights()
		apply_tab_line_highlights()
	end
end

M.setup()

return M
