local o = vim.opt
vim.g.mapleader = " "

o.textwidth = 80
o.wrap = true
o.wrapmargin = 0
o.linebreak = true
o.exrc = true
o.termguicolors = true

o.number = true
o.relativenumber = true

o.autoindent = true
o.smartindent = true

o.hlsearch = true

o.backup = false

o.showcmd = true
o.cmdheight = 1

o.laststatus = 2
o.scrolloff = 10

o.inccommand = "split"

o.smartcase = true
o.ignorecase = true

o.smarttab = true
o.breakindent = true

o.foldmethod = "expr"
o.foldexpr = "v:lua.user_treesitter_foldexpr()"
o.foldlevelstart = 99
o.foldopen:remove("hor")
vim.filetype.add({ extension = { har = "json" } })

o.shiftwidth = 2
o.tabstop = 2

o.backspace = { "start", "eol", "indent" }

o.path:append({ "**" })
o.wildignore:append({ "*/node_modules/*" })

o.splitbelow = true
o.splitright = true
o.splitkeep = "cursor"

o.formatoptions:append({ "r" })

o.showtabline = 1

o.clipboard = "unnamedplus"
