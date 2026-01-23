local M = {}

M.capabilities = require("cmp_nvim_lsp").default_capabilities()

M.handlers = {
	["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
	["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
}

M.on_attach = function(_, bufnr)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
	map("n", "gr", vim.lsp.buf.references, "Go to references")
	map("n", "K", function()
		vim.lsp.buf.hover({ border = "rounded" })
	end, "LSP hover")
	map("n", "gl", function()
		vim.diagnostic.open_float({ border = "rounded" })
	end, "Line diagnostics")
end

function M.base()
	return {
		capabilities = M.capabilities,
		on_attach = M.on_attach,
		handlers = M.handlers,
	}
end

return M
