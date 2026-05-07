vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('v', 'q', '<Esc>')

-- buffer operations

vim.keymap.set('n', 'bm', '<cmd>bnext<cr>')
vim.keymap.set('n', 'bn', '<cmd>bprevious<cr>')
vim.keymap.set('n', 'bd', '<cmd>bdelete<cr>')

-- execute current line
vim.keymap.set('n', '<leader>x', function()
  vim.cmd('.lua')
end)

vim.keymap.set('n', '<leader><leader>x', function()
  vim.cmd('source %')
  vim.notify('lua file reloaded')
end)

-- select all
vim.keymap.set('n', '<C-a>', 'gg<S-v>G')

-- move selected lines up/down and keep selection
vim.keymap.set('v', 'J', ':m \'>+1<CR>gv=gv')
vim.keymap.set('v', 'K', ':m \'<-2<CR>gv=gv')

-- window resizing
vim.keymap.set('n', '<M-Up>', '5<C-w>+')
vim.keymap.set('n', '<M-Down>', '5<C-w>-')

-- quickfix, loclist nav
vim.keymap.set('n', ']]', '<cmd>cnext<CR>')
vim.keymap.set('n', '[[', '<cmd>cprev<CR>')

-- lsp
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration)

vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol)
vim.keymap.set('n', '<leader>dS', vim.lsp.buf.workspace_symbol)

vim.keymap.set('n', '<leader>dq', function()
  vim.diagnostic.setqflist()
  vim.cmd('copen')
end)
vim.keymap.set('n', '<leader>dl', function()
  vim.diagnostic.setloclist()
  vim.cmd('lopen')
end)

vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float)
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)

-- fzf-lua (needs fzf-lua install + require)
vim.keymap.set({ 'n', 'v' }, '<leader><leader>', '<cmd>FzfLua files<cr>')

-- Toggle virtual text and lines
vim.keymap.set('n', 'gK', function()
  local cfg = vim.diagnostic.config()

  ---@diagnostic disable-next-line: need-check-nil
  local text_enabled = cfg.virtual_text

  ---@diagnostic disable-next-line: need-check-nil
  local lines_enabled = cfg.virtual_lines

  if type(text_enabled) == 'table' and type(lines_enabled) == 'table' then
    text_enabled = true
    lines_enabled = true
  end

  vim.diagnostic.config({
    virtual_text = not text_enabled,
    virtual_lines = not lines_enabled,
  })
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
