require "core"
require "vim._core.ui2".enable()

vim.pack.add({
  -- theme and ui
  { src = 'https://github.com/vague-theme/vague.nvim' },
  { src = 'https://github.com/goolord/alpha-nvim' },
  { src = 'https://github.com/brenoprata10/nvim-highlight-colors' },

  -- lsp/completions
  { src = 'https://github.com/mason-org/mason.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/b0o/SchemaStore.nvim' },
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter' },
  { src = 'https://github.com/L3MON4D3/LuaSnip' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/saghen/blink.lib' },
  { src = 'https://github.com/saghen/blink.cmp' },

  -- oil
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/JezerM/oil-lsp-diagnostics.nvim' },
  { src = 'https://github.com/refractalize/oil-git-status.nvim' },

  -- editing
  { src = "https://github.com/kylechui/nvim-surround",                   version = vim.version.range("4.x") },
  { src = "https://github.com/windwp/nvim-autopairs"}
})

require 'custom.ui'.setup()

-- start lsp setup/config
require 'mason'.setup()
require 'mason-tool-installer'.setup({
  ensure_installed = {
    "basedpyright",
    "bash-language-server",
    "css-lsp",
    "docker-language-server",
    "html-lsp",
    "json-lsp",
    "lua-language-server",
    "prisma-language-server",
    "ruff",
    "shellcheck",
    "svelte-language-server",
    "tailwindcss-language-server",
    "terraform",
    "tombi",
    "typescript-language-server",
    "yaml-language-server",
  },
})

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

vim.lsp.enable({ "lua_ls" })
vim.lsp.enable({ "basedpyright" })
vim.lsp.enable({ "bashls" })
vim.lsp.enable({ "cssls" })
vim.lsp.enable({ "dockerls" })
vim.lsp.enable({ "html_ls" })
vim.lsp.enable({ "jsonls" })
vim.lsp.enable({ "prismals" })
vim.lsp.enable({ "ruff" })
vim.lsp.enable({ "zshcs" })
vim.lsp.enable({ "svelte" })
vim.lsp.enable({ "tailwindcss" })
vim.lsp.enable({ "terraformls" })
vim.lsp.enable({ "ts_ls" })
vim.lsp.enable({ "yamlls" })
vim.lsp.enable({ "tombi" })

require("luasnip.loaders.from_vscode").lazy_load()
local cmp = require 'blink.cmp'
-- cmp.build():wait(60000)

-- @type blink.cmp.Config
cmp.setup({
  appearance = {
    nerd_font_variant = "mono",
  },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
    ghost_text = {
      enabled = true,
      show_with_selection = true,
      show_without_selection = false,
      show_with_menu = true,
      show_without_menu = true,
    },
    menu = {
      border = 'rounded',
      auto_show = true,
      draw = {
        treesitter = { "lsp" },
        columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
  },
})
-- end lsp setup/config

-- start oil setup.config
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

vim.keymap.set({ "n", "v" }, '-', "<cmd>Oil<cr>")
-- end oil setup.config

-- highlights
require 'nvim-highlight-colors'.setup({})
