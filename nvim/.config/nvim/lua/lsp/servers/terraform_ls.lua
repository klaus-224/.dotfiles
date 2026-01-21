local globals = require("lsp.globals")
vim.lsp.config["terraformls"] = globals.base()
vim.lsp.enable("terraformls")
