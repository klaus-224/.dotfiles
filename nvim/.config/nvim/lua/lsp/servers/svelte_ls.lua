local client_config = require("lsp.client-config")

vim.lsp.config["svelte"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "svelte" },
})

vim.lsp.enable("svelte")
