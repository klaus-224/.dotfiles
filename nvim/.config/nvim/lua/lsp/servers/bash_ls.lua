local client_config = require("lua.lsp.client-config")

vim.lsp.config["bashls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "sh", "bash", "zsh" },
})

vim.lsp.enable("bashls")
