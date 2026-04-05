local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "typescript-language-server", "--stdio" },
	init_options = {
		hostInfo = "neovim",
	},
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_markers = {
		"package-lock.json",
		"yarn.lock",
		"pnpm-lock.yaml",
		"bun.lockb",
		"bun.lock",
		"tsconfig.json",
		"jsconfig.json",
		".git",
	},
})
