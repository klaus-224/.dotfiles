local client_config = require("lsp.client-config")

vim.lsp.config["prismals"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "prisma" },
})

vim.lsp.enable("prismals")
