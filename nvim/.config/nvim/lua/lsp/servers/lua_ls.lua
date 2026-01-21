local globals = require("lsp.globals")

vim.lsp.config["lua_ls"] = vim.tbl_deep_extend("force", globals.base(), {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylelua.toml",
		"stylelua.toml",
	},
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})

vim.lsp.enable('lua_ls')
