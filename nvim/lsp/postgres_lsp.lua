---@brief
---
--- https://pg-language-server.com
---
--- A collection of language tools and a Language Server Protocol (LSP) implementation for Postgres, focusing on developer experience and reliable SQL tooling.

---@type vim.lsp.Config
return {
  cmd = { 'postgres-language-server', 'lsp-proxy' },
  filetypes = {
    'sql',
  },
  root_dir = function(bufnr, on_dir)
    -- return if postgres-language-server is not installed
    if vim.fn.executable("postgres-language-server") ~= 1 then
      return
    end
    on_dir(vim.fs.root(bufnr, { "postgres-language-server.jsonc", ".git" }) or vim.fn.getcwd())
  end,
  root_markers = { 'postgres-language-server.jsonc' },
  workspace_required = true,
}
