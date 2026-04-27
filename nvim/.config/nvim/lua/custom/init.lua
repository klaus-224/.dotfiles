require("custom.floating_terminal").setup({
	width = 80,
	height = 20,
	border = "rounded",
})

local csviewer = require("custom.csviewer.init").setup()

vim.api.nvim_create_user_command("CsvView", function()
	csviewer.open()
end, {})

vim.api.nvim_create_user_command("CsvInsertCol", function()
	csviewer.insert_col()
end, {})

vim.api.nvim_create_user_command("CsvDeleteCol", function()
	csviewer.delete_col()
end, {})
