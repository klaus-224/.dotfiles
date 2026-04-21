local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = {
		".git",
	},
	settings = {
		basedpyright = {
			analysis = {
				typeCheckingMode = "standard",
				diagnosticMode = "openFilesOnly",
				useLibraryCodeForTypes = true,
			},
		},
		pyright = {
			disableOrganizeImports = true,
		},
	},
})
