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
