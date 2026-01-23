local globals = require("lsp.globals")

vim.lsp.config["jsonls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "json", "jsonc" },
})

vim.lsp.enable("jsonls")
