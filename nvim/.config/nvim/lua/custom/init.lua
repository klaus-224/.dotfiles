require("custom.floating_terminal").setup({
	width = 80,
	height = 20,
	border = "rounded",
})

local csviewer = require("custom.csviewer.init").setup()

vim.api.nvim_create_user_command("CsvView", function()
	-- if csviewer then
	csviewer.open()
	-- end
end, {})
