local client_config = require("lsp.client-config")

vim.lsp.config["html"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "html" },
})

vim.lsp.enable("html")
