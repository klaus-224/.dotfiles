vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4

vim.opt_local.autoindent = true
vim.opt_local.smartindent = false
vim.opt_local.cindent = false

vim.keymap.set('n', ']]', '<cmd>bnext<cr>', { noremap = true })
vim.keymap.set('n', '[[', '<cmd>bprevious<cr>', { noremap = true })
