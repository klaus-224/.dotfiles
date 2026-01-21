local globals = require("lsp.globals")
vim.lsp.config["jsonls"] = globals.base()
vim.lsp.enable("jsonls")
