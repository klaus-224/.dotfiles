local globals = require("lsp.globals")

vim.lsp.config["cssls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "css", "scss", "less" },
})

vim.lsp.enable("cssls")
