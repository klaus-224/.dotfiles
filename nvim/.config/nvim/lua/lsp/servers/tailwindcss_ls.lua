local globals = require("lsp.globals")

vim.lsp.config["tailwindcss"] = vim.tbl_deep_extend("force", globals.base(), {
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
