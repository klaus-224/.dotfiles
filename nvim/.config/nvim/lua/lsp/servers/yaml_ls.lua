local globals = require("lsp.globals")

vim.lsp.config["yamlls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "yaml", "yaml.docker-compose", "yaml.ansible" },
})

vim.lsp.enable("yamlls")
