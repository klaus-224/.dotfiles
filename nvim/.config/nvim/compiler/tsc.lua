if vim.g.current_compiler then
  return
end
vim.g.current_compiler = 'tsc'

local buffer_path = vim.api.nvim_buf_get_name(0)
local start_path = buffer_path ~= '' and vim.fs.dirname(buffer_path) or vim.fn.getcwd()
local tsconfig = vim.fs.find('tsconfig.json', { path = start_path, upward = true })[1]
local tsc = vim.fs.find('node_modules/.bin/tsc', { path = start_path, upward = true, type = 'file' })[1]
  or vim.fn.exepath('tsc')

vim.bo.makeprg = table.concat({
  vim.fn.shellescape(tsc ~= '' and tsc or 'tsc'),
  '-p',
  vim.fn.shellescape(tsconfig or 'tsconfig.json'),
  '--noEmit',
  '--pretty',
  'false',
}, ' ')
vim.bo.errorformat = [[%f(%l\,%c): %trror %m,%f(%l\,%c): %tarning %m]]
