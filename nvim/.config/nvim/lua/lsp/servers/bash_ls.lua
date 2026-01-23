local globals = require("lsp.globals")

vim.lsp.config["bashls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "sh", "bash", "zsh" },
})

vim.lsp.enable("bashls")
