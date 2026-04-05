return {
	{
		"mason-org/mason.nvim",
		dependencies = { "mason-org/mason-lspconfig.nvim", "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"yamlls",
				"dockerls",
				"terraformls",
				"bashls",
				"svelte",
				"prismals",
				"html",
				"cssls",
				"tailwindcss",
				"jsonls",
				"basedpyright",
				"sqlls",
				"shellcheck",
			},
		},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- local ok, blink = pcall(require, "blink.cmp")
		-- if ok and blink.get_lsp_capabilities then
		-- 	M.capabilities = blink.get_lsp_capabilities()
		-- else
		-- 	M.capabilities = vim.lsp.protocol.make_client_capabilities()
		-- end
	end
}
