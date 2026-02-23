local M = {}

do
	local ok, blink = pcall(require, "blink.cmp")
	if ok and blink.get_lsp_capabilities then
		M.capabilities = blink.get_lsp_capabilities()
	else
		M.capabilities = vim.lsp.protocol.make_client_capabilities()
	end
end

M.on_attach = function(_, bufnr)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
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
	}
end

return M
