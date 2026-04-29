require "core"
require "vim._core.ui2".enable()

vim.pack.add({
  -- theme and ui
  { src = 'https://github.com/vague-theme/vague.nvim' },
  { src = 'https://github.com/goolord/alpha-nvim' },
  { src = 'https://github.com/brenoprata10/nvim-highlight-colors' },

  -- lsp
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/b0o/SchemaStore.nvim' },
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },

  -- oil
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/JezerM/oil-lsp-diagnostics.nvim' },
  { src = 'https://github.com/refractalize/oil-git-status.nvim' },

  -- editing
  { src = "https://github.com/kylechui/nvim-surround",                   version = vim.version.range("4.x") }
})

require 'custom.ui'.setup()

-- lsp
require 'mason'.setup()
require 'mason-tool-installer'.setup({
  ensure_installed = {
    --"basedpyright",
    --"bash-language-server",
    --"css-lsp",
    --"docker-language-server",
    --"html-lsp",
    --"json-lsp",
    --"prisma-language-server",
    --"ruff",
    --"shellcheck",
    --"svelte-language-server",
    --"tailwindcss-language-server",
    --"terraform",
    --"tombi",
    --"typescript-language-server",
    --"yaml-language-server",
    "lua-language-server",
  },
})

-- lua types
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

-- setup lua lsp
vim.lsp.enable({ "lua_ls" })

-- oil
require "oil".setup({
  delete_to_trash = true,
  view_options = {
    show_hidden = true,
  },
  win_options = {
    signcolumn = "yes:2", -- apparently needed by git-status
  },
  use_default_keymaps = false,
  keymaps = {
    ["<CR>"] = { "actions.select" },
    ["gq"] = { "actions.send_to_qflist", opts = { action = "a", target = "qflist" } },
  },
})
require 'oil-git-status'.setup({
  show_file_highlights = true,
  show_directory_highlights = false,
  show_ignored_files = true,
})
require 'oil-lsp-diagnostics'.setup()

-- highlights
require 'nvim-highlight-colors'.setup()


vim.keymap.set({ "n", "v" }, '-', "<cmd>Oil<cr>")
