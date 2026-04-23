local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yml" },
	settings = {
		yaml = {
			schemaStore = {
				-- You must disable built-in schemaStore support if you want to use
				-- this plugin and its advanced options like `ignore`.
				enable = false,
				-- Avoid TypeError: Cannot read properties of undefined (reading 'length')
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
		},
	},
	on_init = function(client)
		client.server_capabilities.documentFormattingProvider = true
	end,
	root_markers = { ".git" },
})
