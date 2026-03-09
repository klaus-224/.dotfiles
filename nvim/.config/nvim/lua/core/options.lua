local opt = vim.opt
-- Text width and wrapping
opt.textwidth = 80
opt.wrap = true
opt.wrapmargin = 0
opt.linebreak = true
opt.exrc = true
opt.termguicolors = true

vim.diagnostic.config({
	virtual_text = true,
	signs = false,
})

-- Set leader to spacebar
vim.g.mapleader = " "

--Enable line numbers
opt.number = true
opt.relativenumber = true -- relative line numbers
opt.title = true

-- Enable automatic indentation matching the previous line
opt.autoindent = true

-- Enable smart indentation (automatic indentation in code blocks)
opt.smartindent = true

-- Highlight all search matches
opt.hlsearch = true

-- Disable file backups when writing changes
opt.backup = false

-- Show the command you're typing in the lower-right corner
opt.showcmd = true

-- Set command line height to 0 (hide command line when not in use)
opt.cmdheight = 1

-- Disable status line at the bottom of the window
opt.laststatus = 0

-- Keep at least 10 lines of context above and below the cursor while scrolling
opt.scrolloff = 10

-- Show live preview of substitute commands in a split window
opt.inccommand = "split"

-- Ignore case when searching
opt.ignorecase = true

-- Use smart tab behavior (align tabs based on indentation level)
opt.smarttab = true

-- Preserve indentation for wrapped lines
opt.breakindent = true

-- Fold
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99
opt.foldopen:remove("hor")
vim.filetype.add({ extension = { har = "json" } })

-- Set the number of spaces to use for each indentation level
opt.shiftwidth = 2

-- Set the width of a tab character to 2 spaces
opt.tabstop = 2

-- Configure backspace to delete over indentation, eol, and start of line
opt.backspace = { "start", "eol", "indent" }

-- Allow searching for files in subdirectories recursively
opt.path:append({ "**" })

-- Ignore node_modules directories when doing file name completion
opt.wildignore:append({ "*/node_modules/*" })

-- Open new horizontal splits below the current window
opt.splitbelow = true

-- Open new vertical splits to the right of the current window
opt.splitright = true

-- Keep the cursor position when opening splits (no scroll)
opt.splitkeep = "cursor"

-- Automatically insert comment leader characters when pressing Enter in block comments
opt.formatoptions:append({ "r" })
