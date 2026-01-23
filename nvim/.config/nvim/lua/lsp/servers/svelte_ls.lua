local globals = require("lsp.globals")

vim.lsp.config["svelte"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "svelte" },
})

vim.lsp.enable("svelte")
