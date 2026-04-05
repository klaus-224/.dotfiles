local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.ansible", "yaml.gitlab", "yaml.helm-values" },
	root_markers = { ".git" },
	settings = {
		redhat = { telemetry = { enabled = false } },
		yaml = { format = { enable = true } },
	},
	on_init = function(client)
		client.server_capabilities.documentFormattingProvider = true
	end,
})
