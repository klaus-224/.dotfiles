local client_config = require("lsp.client-config")

vim.lsp.config["lua_ls"] = vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylelua.toml",
		"stylelua.toml",
		".git",
	},
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = false,
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})

vim.lsp.enable('lua_ls')
