local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "prisma-language-server", "--stdio" },
	filetypes = { "prisma" },
	root_markers = { ".git", "package.json" },
	settings = {
		prisma = {
			prismaFmtBinPath = "",
		},
	},
})
