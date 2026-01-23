local client_config = require("lsp.client-config")

vim.lsp.config["cssls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "css", "scss", "less" },
})

vim.lsp.enable("cssls")
