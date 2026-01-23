local client_config = require("lsp.client-config")

vim.lsp.config["dockerls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "dockerfile" },
})

vim.lsp.enable("dockerls")
