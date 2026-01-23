local client_config = require("lsp.client-config")

vim.lsp.config["yamlls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "yaml", "yaml.docker-compose", "yaml.ansible" },
})

vim.lsp.enable("yamlls")
