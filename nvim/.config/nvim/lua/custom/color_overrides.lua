local M = {}

function M.apply_line_number_highlights()
	vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "LineNr", { fg = "#5c6370", bg = "#1e222a" })
	vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffd166", bg = "#1e222a", bold = true })
end

function M.setup()
	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = M.apply_line_number_highlights,
	})

	if vim.g.colors_name then
		M.apply_line_number_highlights()
	end
end

vim.api.nvim_create_user_command("ThemeCatppuccin", function()
	vim.cmd.colorscheme("catppuccin")
end, { desc = "Apply catppuccin" })

vim.api.nvim_create_user_command("ThemeVague", function()
	require("lazy").load({ plugins = { "vague" } })
	vim.cmd.colorscheme("vague")
end, { desc = "Apply vague" })

vim.api.nvim_create_user_command("ThemeGor", function()
	require("lazy").load({ plugins = { "gorgoroth" } })
	vim.cmd.colorscheme("gorgoroth")
end, { desc = "Apply Gorgoroth" })

M.setup()

return M
