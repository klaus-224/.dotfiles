local custom_functions = require('custom.functions')

vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('v', 'q', '<Esc>')
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, 'D', '"_D', { noremap = true, silent = true })
vim.keymap.set({ 'n' }, '<leader>a', ':edit #<CR>')
vim.keymap.set('n', '<M-a>', 'gg<S-v>G"+y')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { noremap = true })
vim.keymap.set('n', '<M-h>', '<C-w>h')
vim.keymap.set('n', '<M-j>', '<C-w>j')
vim.keymap.set('n', '<M-k>', '<C-w>k')
vim.keymap.set('n', '<M-l>', '<C-w>l')
vim.keymap.set('v', 'J', ':m \'>+1<CR>gv=gv')
vim.keymap.set('v', 'K', ':m \'<-2<CR>gv=gv')
vim.keymap.set('n', '<M-Down>', '5<c-w>+')
vim.keymap.set('n', '<M-Up>', '5<c-w>-')
vim.keymap.set('n', '<M->>', '5<c-w>>')
vim.keymap.set('n', '<M-<>', '5<c-w><')
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration)
vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol)
vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol)
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)
vim.keymap.set('n', '<leader>t]', '<cmd>tabn<cr>')
vim.keymap.set('n', '<leader>t[', '<cmd>tabp<cr>')
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
