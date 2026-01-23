local globals = require("lsp.globals")

vim.lsp.config["html"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "html" },
})

vim.lsp.enable("html")
