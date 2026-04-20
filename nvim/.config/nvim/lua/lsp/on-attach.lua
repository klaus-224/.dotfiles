local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(args)
			local bufnr = args.buf
			local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

			local set = vim.keymap.set

			local ok_telescope, builtin = pcall(require, "telescope.builtin")

			if ok_telescope then
				set("n", "<leader>wd", builtin.lsp_document_symbols)
				set("n", "<leader>ww", function()
					builtin.diagnostics({ root_dir = true })
				end)
			end

			-- Example: disable semantic tokens for selected filetypes
			local disable_semantic_tokens = {
				-- lua = true,
			}

			local ft = vim.bo[bufnr].filetype
			if disable_semantic_tokens[ft] then
				client.server_capabilities.semanticTokensProvider = nil
			end
		end,
	})
end

return M
