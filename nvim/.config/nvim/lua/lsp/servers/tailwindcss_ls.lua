local globals = require("lsp.globals")
vim.lsp.config["tailwindcss"] = globals.base()
vim.lsp.enable("tailwindcss")
