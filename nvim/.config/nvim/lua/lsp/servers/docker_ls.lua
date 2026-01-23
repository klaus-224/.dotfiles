local globals = require("lsp.globals")

vim.lsp.config["dockerls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "dockerfile" },
})

vim.lsp.enable("dockerls")
