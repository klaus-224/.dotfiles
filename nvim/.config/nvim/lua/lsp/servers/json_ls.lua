local client_config = require("lsp.client-config")

vim.lsp.config["jsonls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "json", "jsonc" },
})

vim.lsp.enable("jsonls")
