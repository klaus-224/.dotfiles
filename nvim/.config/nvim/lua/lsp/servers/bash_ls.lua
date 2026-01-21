local globals = require("lsp.globals")
vim.lsp.config["bashls"] = globals.base()
vim.lsp.enable("bashls")
