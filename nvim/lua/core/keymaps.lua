local custom_functions = require('custom.functions')

vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('v', 'q', '<Esc>')
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, 'D', '"_D', { noremap = true, silent = true })
vim.keymap.set({ 'n' }, '<leader>a', ':edit #<CR>')
vim.keymap.set('n', '<leader>Y', 'gg<S-v>G"+y')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { noremap = true })
vim.keymap.set('v', 'J', ':m \'>+1<CR>gv=gv')
vim.keymap.set('v', 'K', ':m \'<-2<CR>gv=gv')
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration)
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol)
vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol)
vim.keymap.set('n', '<leader>w', '<cmd>update<cr>')
vim.keymap.set('n', '<leader>Q', '<cmd>qa!<cr>')
vim.keymap.set('n', '<leader>cd', custom_functions.cd_project_root, {
  desc = 'Change directory to project root',
})
vim.keymap.set('n', '<CR>', function()
  ---@diagnostic disable-next-line: undefined-field
  if vim.v.hlsearch == 1 then
    vim.cmd.nohl()
    return ''
  else
    return vim.keycode('<CR>')
  end
end, { expr = true })

vim.keymap.set('n', '<leader>A', function()
  vim.cmd('$argadd %')
  vim.cmd('argdedup')
end)
vim.keymap.set('n', '<C-h>', function() vim.cmd('silent! 1argument') end)
vim.keymap.set('n', '<C-j>', function() vim.cmd('silent! 2argument') end)
vim.keymap.set('n', '<C-k>', function() vim.cmd('silent! 3argument') end)
vim.keymap.set('n', '<C-n>', function() vim.cmd('silent! 4argument') end)
vim.keymap.set('n', '<C-m>', function() vim.cmd('silent! 5argument') end)
