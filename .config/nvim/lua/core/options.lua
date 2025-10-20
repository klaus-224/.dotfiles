-- Text width and wrapping
vim.opt.textwidth = 80
vim.opt.wrap = true
vim.opt.textwidth = 0
vim.opt.wrapmargin = 0
vim.opt.linebreak = true

-- Set leader to spacebar
vim.g.mapleader = " "

--Enable line numbers
vim.opt.number = true -- absolute line numbers
-- vim.opt.relativenumber = true -- relative line numbers

vim.opt.title = true

-- Enable automatic indentation matching the previous line
vim.opt.autoindent = true

-- Enable smart indentation (automatic indentation in code blocks)
vim.opt.smartindent = true

-- Highlight all search matches
vim.opt.hlsearch = true

-- Disable file backups when writing changes
vim.opt.backup = false

-- Show the command you're typing in the lower-right corner
vim.opt.showcmd = true

-- Set command line height to 0 (hide command line when not in use)
vim.opt.cmdheight = 0

-- Disable status line at the bottom of the window
vim.opt.laststatus = 0

-- Keep at least 10 lines of context above and below the cursor while scrolling
vim.opt.scrolloff = 10

-- Show live preview of substitute commands in a split window
vim.opt.inccommand = "split"

-- Ignore case when searching
vim.opt.ignorecase = true

-- Use smart tab behavior (align tabs based on indentation level)
vim.opt.smarttab = true

-- Preserve indentation for wrapped lines
vim.opt.breakindent = true

-- Set the number of spaces to use for each indentation level
vim.opt.shiftwidth = 2

-- Set the width of a tab character to 2 spaces
vim.opt.tabstop = 2

-- Configure backspace to delete over indentation, eol, and start of line
vim.opt.backspace = { "start", "eol", "indent" }

-- Allow searching for files in subdirectories recursively
vim.opt.path:append({ "**" })

-- Ignore node_modules directories when doing file name completion
vim.opt.wildignore:append({ "*/node_modules/*" })

-- Open new horizontal splits below the current window
vim.opt.splitbelow = true

-- Open new vertical splits to the right of the current window
vim.opt.splitright = true

-- Keep the cursor position when opening splits (no scroll)
vim.opt.splitkeep = "cursor"

-- Disable mouse support in Vim
vim.opt.mouse = ""

-- Automatically insert comment leader characters when pressing Enter in block comments
vim.opt.formatoptions:append({ "r" })
