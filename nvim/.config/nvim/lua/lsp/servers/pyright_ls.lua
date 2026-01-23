local client_config = require("lsp.client-config")

vim.lsp.config["pyright"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "python" },
	settings = {
		python = {
			pythonPath = ".venv/bin/python",
		},
	},
})

vim.lsp.enable("pyright")
