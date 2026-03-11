local M = {}
do
	local ok, blink = pcall(require, "blink.cmp")
	if ok and blink.get_lsp_capabilities then
		M.capabilities = blink.get_lsp_capabilities()
	else
		M.capabilities = vim.lsp.protocol.make_client_capabilities()
	end
end

function M.base()
	return {
		capabilities = M.capabilities,
	}
end

return M
