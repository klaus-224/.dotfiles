local client_config = require("lsp.client-config")

vim.lsp.config["tailwindcss"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = {
		"html",
		"css",
		"scss",
		"less",
		"postcss",
		"sass",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"svelte",
		"vue",
	},
})

vim.lsp.enable("tailwindcss")
