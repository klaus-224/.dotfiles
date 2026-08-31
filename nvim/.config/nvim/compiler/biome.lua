if vim.g.current_compiler then
  return
end

vim.g.current_compiler = 'biome'

local buffer_path = vim.api.nvim_buf_get_name(0)
local start_path = buffer_path ~= '' and vim.fs.dirname(buffer_path) or vim.fn.getcwd()

local package_json = vim.fs.find('package.json', {
  path = start_path,
  upward = true,
})[1]

local package_root = package_json and vim.fs.dirname(package_json) or vim.fn.getcwd()

vim.opt_local.makeprg = string.format('pnpm --dir %s biome lint . --reporter=concise', vim.fn.shellescape(package_root))

vim.opt_local.errorformat = {
  '%*[×!] %f:%l:%c: %m',
  '%-G%.%#',
}
