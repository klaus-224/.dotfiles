local globals = require("lsp.globals")

vim.lsp.config["ts_ls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
})

vim.lsp.enable("ts_ls")
