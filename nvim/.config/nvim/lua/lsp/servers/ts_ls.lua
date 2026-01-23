local client_config = require("lsp.client-config")

vim.lsp.config["ts_ls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
})

vim.lsp.enable("ts_ls")
