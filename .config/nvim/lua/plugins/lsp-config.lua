local lsp_helpers = require("helpers.lsp")

-- CENTRALIZED CONFIGURATION FOR LSP SERVERS
local servers_with_filetypes = {
	lua_ls = {
		filetypes = { "lua" },
		extend_capabilities = function(capabilities)
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			return capabilities
		end,
	},
	ts_ls = {
		filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	},
	rust_analyzer = {
		filetypes = { "rust" },
	},
	yamlls = {
		filetypes = { "yaml" },
	},
	prismals = {
		filetypes = { "prisma" },
	},
	dockerls = {
		filetypes = { "dockerfile" },
	},
	terraformls = {
		filetypes = { "terraform" },
	},
	bashls = {
		filetypes = { "sh", "bash" },
	},
	svelte = {
		filetypes = { "svelte" },
	},
}

return {
	-- Mason for LSP management
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({})
		end,
	},

	-- Mason-LSPConfig to ensure specific LSP servers are installed
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			local ensure_installed_servers = {}
			for server_name, _ in pairs(servers_with_filetypes) do
				table.insert(ensure_installed_servers, server_name)
			end

			require("mason-lspconfig").setup({
				ensure_installed = ensure_installed_servers,
			})
		end,
	},

	-- Nicer preview windows for definitions, implementations, etc.
	{
		"rmagatti/goto-preview",
		event = "BufEnter",
		config = true,
	},

	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		config = function()
			local lspconfig = require("lspconfig")
			local cmp_nvim_lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Iterate over the centralized configuration table and set up each server
			for server_name, config in pairs(servers_with_filetypes) do
				local capabilities = config.extend_capabilities
						and config.extend_capabilities(vim.deepcopy(cmp_nvim_lsp_capabilities))
					or cmp_nvim_lsp_capabilities

				lspconfig[server_name].setup({
					capabilities = capabilities,
					on_attach = lsp_helpers.on_attach,
					filetypes = config.filetypes,
				})
			end
		end,
	},
}
