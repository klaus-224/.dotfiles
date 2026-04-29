local diag = vim.diagnostic

diag.config({
  signs = false,
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  severity_sort = true,
  float = {
    border = "rounded",
  },
})

-- ignore .env
local group = vim.api.nvim_create_augroup("__env", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = ".env*",
  group = group,
  callback = function(args)
    diag.enable(false, { bufnr = args.buf })
  end,
})
