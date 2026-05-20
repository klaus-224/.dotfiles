require('core')
require('vim._core.ui2').enable()

-- ONLY UNCOMMENT TO DELETE ALL PLUGINS
-- vim.pack.del(vim
--   .iter(vim.pack.get())
--   :filter(function(x)
--     return not x.active
--   end)
--   :map(function(x)
--     return x.spec.name
--   end)
--   :totable())

-- add plugins
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
  { src = 'https://github.com/L3MON4D3/LuaSnip' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/saghen/blink.lib' },
  { src = 'https://github.com/saghen/blink.cmp' },

  -- oil/file search and nav
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/JezerM/oil-lsp-diagnostics.nvim' },
  { src = 'https://github.com/refractalize/oil-git-status.nvim' },
  { src = 'https://github.com/ibhagwan/fzf-lua' },

  -- editing/formatting
  { src = 'https://github.com/kylechui/nvim-surround', version = vim.version.range('4.x') },
  { src = 'https://github.com/windwp/nvim-autopairs' },
  { src = 'https://github.com/stevearc/conform.nvim' },

  -- database stuff
  { src = 'https://github.com/tpope/vim-dadbod' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-ui' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-completion' },

  -- git
  { src = 'https://github.com/f-person/git-blame.nvim' },
})

require('custom.ui').setup()
require('custom.statusline').setup()

-- start lsp setup/config
require('mason').setup()
require('mason-tool-installer').setup({
  ensure_installed = {
    'basedpyright',
    'bash-language-server',
    'css-lsp',
    'docker-language-server',
    'html-lsp',
    'json-lsp',
    'lua-language-server',
    'prisma-language-server',
    'ruff',
    'shellcheck',
    'svelte-language-server',
    'tailwindcss-language-server',
    'terraform',
    'tombi',
    'typescript-language-server',
    'yaml-language-server',
    'stylua',
  },
})

require('lazydev').setup({
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
})

vim.lsp.enable({ 'lua_ls' })
vim.lsp.enable({ 'basedpyright' })
vim.lsp.enable({ 'bashls' })
vim.lsp.enable({ 'cssls' })
vim.lsp.enable({ 'dockerls' })
vim.lsp.enable({ 'html_ls' })
vim.lsp.enable({ 'jsonls' })
vim.lsp.enable({ 'prismals' })
vim.lsp.enable({ 'ruff' })
vim.lsp.enable({ 'rust_analyzer' })
vim.lsp.enable({ 'zshcs' })
vim.lsp.enable({ 'svelte' })
vim.lsp.enable({ 'tailwindcss' })
vim.lsp.enable({ 'terraformls' })
vim.lsp.enable({ 'ts_ls' })
vim.lsp.enable({ 'yamlls' })
vim.lsp.enable({ 'tombi' })

-- formatting
require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },

    -- web
    javascript = { 'oxfmt', 'biome', 'prettier' },
    javascriptreact = { 'oxfmt', 'biome', 'prettier' },
    typescript = { 'oxfmt', 'biome', 'prettier' },
    typescriptreact = { 'oxfmt', 'biome', 'prettier' },

    -- data/config
    json = { 'oxfmt', 'biome', 'prettier' },
    jsonc = { 'biome', 'prettier' },
    yaml = { 'prettier' },
    markdown = { 'oxfmt', 'prettier' },
    sql = { 'sleek' },

    -- python
    python = { 'ruff_format' },

    -- infra
    terraform = { 'terraform_fmt' },
    hcl = { 'terraform_fmt' },

    -- toml
    toml = { 'tombi' },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = 'fallback',
  },
})

require('luasnip.loaders.from_vscode').lazy_load()
local cmp = require('blink.cmp')
-- cmp.build():wait(60000)

-- @type blink.cmp.Config
cmp.setup({
  appearance = {
    nerd_font_variant = 'mono',
  },

  snippets = {
    preset = 'luasnip',
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lsp = { score_offset = 4 },
      path = { score_offset = 3 },
      snippets = { score_offset = 2 },
      buffer = { score_offset = -1 },
    },
  },

  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 250,
    },

    ghost_text = {
      enabled = true,
      show_with_selection = true,
      show_without_selection = false,
      show_with_menu = true,
      show_without_menu = true,
    },

    menu = {
      auto_show = true,
      draw = {
        treesitter = { 'lsp' },
        columns = {
          { 'kind_icon', 'label', 'label_description', gap = 1 },
          { 'kind' },
          { 'source_name' },
        },
      },
      winhighlight = table.concat({
        'Normal:BlinkCmpMenu',
        'FloatBorder:BlinkCmpMenuBorder',
        'CursorLine:BlinkCmpMenuSelection',
        'Search:None',
      }, ','),
    },
  },
  cmdline = {
    enabled = true,
    keymap = {
      preset = 'cmdline',
    },
    sources = {
      default = { 'cmdline', 'path' },
    },
    completion = {
      list = {
        selection = {
          preselect = false,
          auto_insert = false,
        },
      },
      menu = {
        auto_show = function()
          return vim.fn.getcmdtype() == ':'
        end,
      },
      ghost_text = {
        enabled = true,
      },
    },
  },
})
-- end lsp setup/config

-- start oil setup.config
require('oil').setup({
  delete_to_trash = true,
  view_options = {
    show_hidden = true,
  },
  win_options = {
    -- signcolumn = 'yes:2', -- apparently needed by git-status
  },
  use_default_keymaps = false,
  keymaps = {
    ['<CR>'] = { 'actions.select' },
    ['gq'] = { 'actions.send_to_qflist', opts = { action = 'a', target = 'qflist' } },
  },
})

-- require('oil-git-status').setup({
--   show_file_highlights = true,
--   show_directory_highlights = false,
--   show_ignored_files = true,
-- })

require('oil-lsp-diagnostics').setup()

vim.keymap.set({ 'n', 'v' }, '-', '<cmd>Oil<cr>')
-- end oil setup.config

-- start fzf-lua setup
require('fzf-lua').setup({
  winopts = {
    split = 'belowright new',
    width = 0.25,
    preview = {
      hidden = true,
    },
  },
})

-- highlights
require('nvim-highlight-colors').setup({})

-- gitblame
require('gitblame').setup({
  enabled = false,
  message_template = ' <summary> • <date> • <author> • <<sha>>',
  date_format = '%r',
  virtual_text_column = 0,
  use_blame_commit_file_urls = false,
})
