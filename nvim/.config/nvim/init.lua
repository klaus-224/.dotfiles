require('core')
require('vim._core.ui2').enable()

vim.cmd.packadd('cfilter')
vim.cmd.packadd('nvim.difftool')

vim.pack.add({
  { src = 'https://github.com/vague-theme/vague.nvim' },
  { src = 'https://github.com/goolord/alpha-nvim' },
  { src = 'https://github.com/brenoprata10/nvim-highlight-colors' },
  { src = 'https://github.com/b0o/SchemaStore.nvim' },
  { src = 'https://github.com/folke/lazydev.nvim' },
  { src = 'https://github.com/L3MON4D3/LuaSnip' },
  { src = 'https://github.com/rafamadriz/friendly-snippets' },
  { src = 'https://github.com/saghen/blink.lib' },
  { src = 'https://github.com/saghen/blink.cmp' },
  { src = 'https://github.com/romus204/tree-sitter-manager.nvim' },
  { src = 'https://github.com/stevearc/oil.nvim' },
  { src = 'https://github.com/nvim-mini/mini.pick' },
  { src = 'https://github.com/kylechui/nvim-surround',              version = vim.version.range('4.x') },
  { src = 'https://github.com/windwp/nvim-autopairs' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/tpope/vim-dadbod' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-ui' },
  { src = 'https://github.com/kristijanhusak/vim-dadbod-completion' },
  { src = 'https://github.com/f-person/git-blame.nvim' },
})

require('custom.ui').setup()
require('custom.statusline').setup()
require('custom.execution-buffer').setup()

require('lazydev').setup({
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
})

vim.lsp.enable({
  'lua_ls',
  -- 'basedpyright',
  -- 'bashls',
  -- 'cssls',
  -- 'dockerls',
  -- 'html_ls',
  -- 'jsonls',
  -- 'prismals',
  -- 'ruff',
  -- 'rust_analyzer',
  'sqlls',
  'postgres_lsp',
  -- 'zshcs',
  -- 'svelte',
  'tailwindcss',
  -- 'terraformls',
  'ts_ls',
  'yamlls',
  'tombi',
})

require('conform').setup({
  default_format_opts = {
    lsp_format = 'fallback',
  },
  formatters_by_ft = {
    lua = { 'stylua' },

    -- web
    javascript = { 'biome' },
    javascriptreact = { 'biome' },
    typescript = { 'oxfmt', 'biome' },
    typescriptreact = { 'oxfmt', 'biome' },

    -- data/config
    yaml = { 'biome' },
    -- markdown = { 'biome' },
    sql = { 'sleek' },
    jsonc = { 'oxfmt', 'biome' },
    json = { 'oxfmt', 'biome' },

    -- toml
    toml = { 'tombi' },

    -- python
    python = { 'ruff_format' },

    -- infra
    terraform = { 'terraform_fmt' },
    hcl = { 'terraform_fmt' },
  },

  format_on_save = {
    timeout_ms = 500,
    lsp_format = 'never',
  },
})

require('luasnip.loaders.from_vscode').lazy_load()
local cmp = require('blink.cmp')
-- cmp.build():wait(60000)

-- @type blink.cmp.Config
cmp.setup({
  snippets = {
    preset = 'luasnip',
  },

  completion = {
    menu = {
      auto_show = false,
    },

    ghost_text = {
      enabled = true,
      show_without_selection = true,
    },
  },
})

require('tree-sitter-manager').setup({
  dependencies = {},   -- tree-sitter CLI must be installed system-wide
  ensure_installed = { 'svelte' },
  auto_install = true, -- install missing parsers when editing a new file
  highlight = false,   -- treesitter highlighting is enabled by default
})

require('oil').setup({
  delete_to_trash = true,
  view_options = {
    show_hidden = true,
  },
  use_default_keymaps = false,
  keymaps = {
    ['<CR>'] = { 'actions.select' },
  },
})

require('mini.pick').setup({})

vim.keymap.set({ 'n', 'v', 'x' }, '<leader>f', '<cmd>Pick files<cr>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>h', '<cmd>Pick help<cr>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>b', '<cmd>Pick buffers<cr>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>g', '<cmd>Pick grep_live<cr>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>sr', '<cmd>Pick resume<cr>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>e', '<cmd>Oil<cr>')

require('nvim-highlight-colors').setup({})
require('gitblame').setup({
  enabled = false,
  message_template = ' <summary> • <date> • <author> • <<sha>>',
  date_format = '%r',
  virtual_text_column = 0,
  use_blame_commit_file_urls = false,
})
