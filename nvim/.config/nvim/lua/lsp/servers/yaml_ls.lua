local globals = require("lsp.globals")
vim.lsp.config["yamlls"] = globals.base()
vim.lsp.enable("yamlls")
