local o = vim.opt
-- Text width and wrapping
o.textwidth = 80
o.wrap = true
o.wrapmargin = 0
o.linebreak = true
o.exrc = true
o.termguicolors = true

-- Set leader to spacebar
vim.g.mapleader = " "

--Enable line numbers
o.number = true
o.relativenumber = true -- relative line numbers
o.title = true

-- Enable automatic indentation matching the previous line
o.autoindent = true

-- Enable smart indentation (automatic indentation in code blocks)
o.smartindent = true

-- Highlight all search matches
o.hlsearch = true

-- Disable file backups when writing changes
o.backup = false

-- Show the command you're typing in the lower-right corner
o.showcmd = true

-- Set command line height to 0 (hide command line when not in use)
o.cmdheight = 1

-- Disable status line at the bottom of the window
o.laststatus = 2

-- Keep at least 10 lines of context above and below the cursor while scrolling
o.scrolloff = 10

-- Show live preview of substitute commands in a split window
o.inccommand = "split"

-- Ignore case when searching
o.ignorecase = true

-- Use smart tab behavior (align tabs based on indentation level)
o.smarttab = true

-- Preserve indentation for wrapped lines
o.breakindent = true

-- Fold
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevelstart = 99
o.foldopen:remove("hor")
vim.filetype.add({ extension = { har = "json" } })

-- Set the number of spaces to use for each indentation level
o.shiftwidth = 2

-- Set the width of a tab character to 2 spaces
o.tabstop = 2

-- Configure backspace to delete over indentation, eol, and start of line
o.backspace = { "start", "eol", "indent" }

-- Allow searching for files in subdirectories recursively
o.path:append({ "**" })

-- Ignore node_modules directories when doing file name completion
o.wildignore:append({ "*/node_modules/*" })

-- Open new horizontal splits below the current window
o.splitbelow = true

-- Open new vertical splits to the right of the current window
o.splitright = true

-- Keep the cursor position when opening splits (no scroll)
o.splitkeep = "cursor"

-- Automatically insert comment leader characters when pressing Enter in block comments
o.formatoptions:append({ "r" })

-- show tabline if there are atleast 2 pages
vim.o.showtabline = 1

-- function _G.my_tabline()
-- 	local s = ""
--
-- 	for i = 1, vim.fn.tabpagenr("$") do
-- 		local name = vim.fn.gettabvar(i, "tabname", "")
-- 		if name == "" then
-- 			local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
-- 			name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":t")
-- 		end
--
-- 		s = s .. "%" .. i .. "T " .. name .. " "
-- 	end
--
-- 	return s
-- end
--
-- vim.o.tabline = "%!v:lua.my_tabline()"
