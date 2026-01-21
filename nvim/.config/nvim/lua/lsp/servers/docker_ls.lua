local globals = require("lsp.globals")
vim.lsp.config["dockerls"] = globals.base()
vim.lsp.enable("dockerls")
