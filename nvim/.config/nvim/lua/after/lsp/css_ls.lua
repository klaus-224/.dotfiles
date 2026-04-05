local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
	init_options = {
		provideFormatter = true,
	},
	root_markers = { "package.json", ".git" },
	settings = {
		css = { validate = true },
		scss = { validate = true },
		less = { validate = true },
	},
})
