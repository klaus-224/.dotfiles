-- - require("core")

vim.api.nvim_create_autocmd('PackChanged', { callback = function(ev)
  local name, kind = ev.data.spec.name, ev.data.kind
  if name == 'nvim-treesitter' and kind == 'update' then
    if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
    vim.cmd('TSUpdate')
  end
end })

vim.pack.add({
	'https://github.com/vague-theme/vague.nvim',
	'https://github.com/goolord/alpha-nvim',
	'https://github.com/nvim-treesitter/nvim-treesitter',
	'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/stevearc/oil.nvim',
})

-- options
vim.g.mapleader = " "
vim.opt.textwidth = 80
vim.opt.wrap = true
vim.opt.wrapmargin = 0
vim.opt.linebreak = true
vim.opt.exrc = true
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.hlsearch = true
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.scrolloff = 10
vim.opt.inccommand = "split"
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.splitkeep = "cursor"
vim.opt.showtabline = 1
vim.opt.clipboard = "unnamedplus"

-- color-scheme
vim.cmd.colorscheme("vague")
require("vague").setup({
	italic = false,
})

require('oil').setup {
    keymaps = { ['<C-h>'] = false },
    columns = { 'size', 'mtime' },
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
}


-- keymaps
vim.keymap.set('n', '-', ':Oil<CR>' )
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("v", "q", "<Esc>")
vim.keymap.set("n", "<C-a>", "gg<S-v>G")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "<M-,>", "<c-w>5<")
vim.keymap.set("n", "<M-.>", "<c-w>5>")
vim.keymap.set("n", "<M-t>", "<C-W>+")
vim.keymap.set("n", "<M-s>", "<C-W>-")
vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol)
vim.keymap.set("n", "<leader>dS", vim.lsp.buf.workspace_symbol)
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float)
vim.keymap.set("n", "<left>", "gT")
vim.keymap.set("n", "<right>", "gt")

vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end)
vim.keymap.set("n", "<leader>dq", function()
	vim.diagnostic.setqflist()
	vim.cmd("copen")
end)
vim.keymap.set("n", "<leader>dl", function()
	vim.diagnostic.setloclist()
	vim.cmd("lopen")
end)
vim.keymap.set("n", "<leader>x", function()
	vim.cmd(".lua")
end)
vim.keymap.set("n", "<leader><leader>x", function()
	vim.cmd("source %")
	vim.notify("lua file reloaded")
end)
vim.keymap.set("n", "<CR>", function()
	---@diagnostic disable-next-line: undefined-field
	if vim.v.hlsearch == 1 then
		vim.cmd.nohl()
		return ""
	else
		return k("<CR>")
	end
end, { expr = true })
