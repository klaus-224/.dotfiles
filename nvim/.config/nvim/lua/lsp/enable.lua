local M = {}

function M.setup()
	local server_configs = {
		bashls = require("after.lsp.bash_ls"),
		basedpyright = require("after.lsp.basedpyright_ls"),
		cssls = require("after.lsp.css_ls"),
		dockerls = require("after.lsp.docker_ls"),
		html = require("after.lsp.html_ls"),
		jsonls = require("after.lsp.json_ls"),
		lua_ls = require("after.lsp.lua_ls"),
		prismals = require("after.lsp.prisma_ls"),
		ruff = require("after.lsp.ruff"),
		svelte = require("after.lsp.svelte_ls"),
		tailwindcss = require("after.lsp.tailwindcss_ls"),
		terraformls = require("after.lsp.terraform_ls"),
		tombi = require("after.lsp.tombi_ls"),
		ts_ls = require("after.lsp.ts_ls"),
		yamlls = require("after.lsp.yaml_ls"),
	}
	local servers = {
		"bashls",
		"basedpyright",
		"cssls",
		"dockerls",
		"html",
		"jsonls",
		"lua_ls",
		"prismals",
		"ruff",
		"svelte",
		"tailwindcss",
		"terraformls",
		"tombi",
		"ts_ls",
		"yamlls",
	}

	vim.lsp.config("*", require("lsp.client-config").base())
	for name, config in pairs(server_configs) do
		vim.lsp.config(name, config)
	end

	vim.lsp.enable(servers)
end

return M
