local globals = require("lsp.globals")
vim.lsp.config["ts_ls"] = globals.base()
vim.lsp.enable("ts_ls")
