local client_config = require("lsp.client-config")

vim.lsp.config["lua_ls"] = vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
			},
		},
	},
})

vim.lsp.enable("lua_ls")
