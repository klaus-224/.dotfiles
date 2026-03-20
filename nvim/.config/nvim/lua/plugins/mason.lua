return {
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
}
