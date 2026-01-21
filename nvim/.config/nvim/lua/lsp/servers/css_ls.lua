local globals = require("lsp.globals")
vim.lsp.config["cssls"] = globals.base()
vim.lsp.enable("cssls")
