if vim.g.current_compiler then
  return
end
vim.g.current_compiler = 'tsc'

vim.bo.makeprg = 'tsc -p tsconfig.json --noEmit --pretty false'
vim.bo.errorformat = '%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m'
