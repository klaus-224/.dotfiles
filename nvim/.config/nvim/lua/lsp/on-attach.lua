local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
			local set = vim.keymap.set
			local lsp = vim.lsp

			if client:supports_method("textDocument/inlayHint") then
				lsp.inlay_hint.enable(true, { bufnr = args.buf })
			end

			if client:supports_method("callHierarchy/incomingCalls") then
				set("n", "<leader>li", lsp.buf.incoming_calls)
			end

			if client:supports_method("callHierarchy/incomingCalls") then
				set("n", "<leader>lo", lsp.buf.outgoing_calls, { noremap = false })
			end
		end,
	})
end

return M
