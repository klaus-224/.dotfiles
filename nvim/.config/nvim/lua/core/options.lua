-- leader
vim.g.mapleader = ' '

-- shell
-- vim.opt.shell = '/bin/zsh'
-- vim.opt.shellcmdflag = '-ic'

-- text / wrapping
vim.opt.textwidth = 80
vim.opt.wrap = true

-- local/project config
vim.opt.exrc = true

-- colors / ui
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 10
vim.opt.laststatus = 3
vim.opt.cmdheight = 2
vim.opt.cmdwinheight = 10
vim.opt.winborder = 'rounded'
vim.opt.splitbelow = true
vim.opt.splitright = true

-- indentation / tabs
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.backspace = { 'start', 'eol', 'indent' }

-- search
vim.opt.hlsearch = true
vim.opt.inccommand = 'split'
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.showmatch = true

-- folding
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevelstart = 99

-- clipboard / editing
vim.opt.clipboard = 'unnamedplus'
vim.opt.virtualedit = 'block'

-- completion
vim.opt.completeopt = 'menu,popup,noinsert,fuzzy'

-- keyword search
vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

-- file search
vim.opt.path:append({ '**' })
vim.opt.wildignore:append({
  '*/.git/*',
  '*/node_modules/*',
  '*/dist/*',
  '*/build/*',
  '*/target/*',
})

-- winbar
-- vim.opt.winbar = '%=%m %f %h'
