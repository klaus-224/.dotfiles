local globals = require("lsp.globals")
vim.lsp.config["pyright"] = vim.tbl_deep_extend("force", globals.base(), {
	settings = {
		python = {
			pythonPath = ".venv/bin/python",
		},
	},
})
vim.lsp.enable("pyright")
