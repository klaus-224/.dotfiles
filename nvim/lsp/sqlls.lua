---@brief
---
--- https://github.com/joe-re/sql-language-server
---
--- Install with `npm install -g sql-language-server`.

---@type vim.lsp.Config
return {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  root_dir = function(bufnr, on_dir)
    -- return if sql-language-server is not installed
    if vim.fn.executable("sql-language-server") ~= 1 then
      return
    end
    on_dir(vim.fs.root(bufnr, { ".sqllsrc.json", ".git" }) or vim.fn.getcwd())
  end,
}
