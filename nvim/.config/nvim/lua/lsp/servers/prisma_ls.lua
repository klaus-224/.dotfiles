local globals = require("lsp.globals")

vim.lsp.config["prismals"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "prisma" },
})

vim.lsp.enable("prismals")
