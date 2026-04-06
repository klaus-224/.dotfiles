local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

			-- don't check markdown
    	-- if vim.bo[bufnr].filetype == "markdown" or vim.bo[bufnr].filetype =="json" then
    	--   vim.lsp.stop_client(client.id)
    	-- end

      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      local ok_telescope, builtin = pcall(require, "telescope.builtin")

    	map("n", "K", vim.lsp.buf.hover, "Hover")
      map("n", "gD", vim.lsp.buf.declaration, "Declaration")
      map("n", "gT", vim.lsp.buf.type_definition, "Type Definition")
      map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")

      if ok_telescope then
        map("n", "<leader>wd", builtin.lsp_document_symbols, "Document Symbols")
        map("n", "<leader>ww", function()
          builtin.diagnostics({ root_dir = true })
        end, "Workspace Diagnostics")
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
