local M = {}

local function capabilities()
	if pcall(require, "blink.cmp") then
		return require("blink.cmp").get_lsp_capabilities()
	end
	return vim.lsp.protocol.make_client_capabilities()
end

function M.setup()
	vim.lsp.config("*", { capabilities = capabilities() })

	vim.lsp.enable({
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
	})
end

return M
