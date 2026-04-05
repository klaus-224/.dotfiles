local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "tombi", "lsp" },
	filetypes = { "toml" },
	root_markers = { "pyproject.toml", "Cargo.toml", ".git" },
})
