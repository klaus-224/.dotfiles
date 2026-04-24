require("core")

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

	-- OIL
	--  'https://github.com/stevearc/oil.nvim',
	-- 'https://github.com/JezerM/oil-lsp-diagnostics.nvim',
	-- 'https://github.com/refractalize/oil-git-status.nvim'
})

-- setup lua lsp

-- color-scheme
vim.cmd.colorscheme("vague")
require("vague").setup({
	italic = false,
})

