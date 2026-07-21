vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('v', 'q', '<Esc>')
vim.keymap.set({ 'n', 'v' }, 'd', '"_d', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v' }, 'D', '"_D', { noremap = true, silent = true })
vim.keymap.set({ 'n' }, '<leader>a', ':edit #<CR>', { desc = 'Switch to the alternate buffer' })
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
-- terminal
vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { noremap = true })

vim.keymap.set({ 't', 'i' }, '<M-h>', [[<C-\><C-N><C-w>h]], { noremap = true })
vim.keymap.set({ 't', 'i' }, '<M-j>', [[<C-\><C-N><C-w>j]], { noremap = true })
vim.keymap.set({ 't', 'i' }, '<M-k>', [[<C-\><C-N><C-w>k]], { noremap = true })
vim.keymap.set({ 't', 'i' }, '<M-l>', [[<C-\><C-N><C-w>l]], { noremap = true })
vim.keymap.set('n', '<A-h>', '<C-w>h')
vim.keymap.set('n', '<A-j>', '<C-w>j')
vim.keymap.set('n', '<A-k>', '<C-w>k')
vim.keymap.set('n', '<A-l>', '<C-w>l')

-- select all
vim.keymap.set('n', '<C-a>', 'gg<S-v>G')

-- move selected lines up/down and keep selection
vim.keymap.set('v', 'J', ':m \'>+1<CR>gv=gv')
vim.keymap.set('v', 'K', ':m \'<-2<CR>gv=gv')

-- window resizing
vim.keymap.set('n', '<M-Down>', '5<c-w>+')
vim.keymap.set('n', '<M-Up>', '5<c-w>-')
vim.keymap.set('n', '<M->>', '5<c-w>>')
vim.keymap.set('n', '<M-<>', '5<c-w><')

-- lsp
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration)

vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol)
vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol)

vim.keymap.set('n', '<leader>dq', function()
  vim.diagnostic.setqflist()
  vim.cmd('copen')
end)
vim.keymap.set('n', '<leader>dl', function()
  vim.diagnostic.setloclist()
  vim.cmd('lopen')
end)

vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set('n', '<leader>lf', function()
  require('conform').format()
end)

-- tabs
vim.keymap.set('n', '<leader>t]', '<cmd>tabn<cr>')
vim.keymap.set('n', '<leader>t[', '<cmd>tabp<cr>')

-- clear search hightlights
vim.keymap.set('n', '<CR>', function()
  ---@diagnostic disable-next-line: undefined-field
  if vim.v.hlsearch == 1 then
    vim.cmd.nohl()
    return ''
  else
    return vim.keycode('<CR>')
  end
end, { expr = true })
