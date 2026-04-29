require "core"
require "vim._core.ui2".enable()

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end
})

vim.pack.add({
  -- theme and ui
  'https://github.com/vague-theme/vague.nvim',
  'https://github.com/goolord/alpha-nvim',

  -- lsp
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  'https://github.com/b0o/SchemaStore.nvim',
  'https://github.com/folke/lazydev.nvim', -- just for lua

  --'https://github.com/nvim-treesitter/nvim-treesitter',

  -- OIL
  'https://github.com/stevearc/oil.nvim',
  -- 'https://github.com/JezerM/oil-lsp-diagnostics.nvim',
  -- 'https://github.com/refractalize/oil-git-status.nvim'
})

require 'custom.ui'.setup()

-- TODO: ADD ALPHA CONFIG HERE

-- LSP
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

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my.lsp', {}),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    --       if client:supports_method('textDocument/implementation') then
    --         -- Create a keymap for vim.lsp.buf.implementation ...
    --       end
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    -- Auto-format ("lint") on save.
    -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
    --        if not client:supports_method('textDocument/willSaveWaitUntil')
    --            and client:supports_method('textDocument/formatting') then
    --          vim.api.nvim_create_autocmd('BufWritePre', {
    --            group = vim.api.nvim_create_augroup('my.lsp', {clear=false}),
    --            buffer = ev.buf,
    --            callback = function()
    --              vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
    --            end,
    --          })
    --        end
  end,
})

-- Oil
require "oil".setup({
  delete_to_trash = true,
  view_options = {
    show_hidden = true,
  },
  use_default_keymaps = false,
  keymaps = {
    ["<CR>"] = { "actions.select" },
    ["gq"] = { "actions.send_to_qflist", opts = { action = "a", target = "qflist" } },
  },
})
vim.keymap.set({ "n", "v" }, '-', "<cmd>Oil<cr>")

local quote = {
  '"I can do nothing for you but work on myself...',
  '         you can do nothing for me but work on yourself"',
}

local author = { "                              — Ram Dass" }

local function center_padding()
  local height = vim.fn.winheight(0)
  local content_height = #quote + #author
  return math.floor((height - content_height) / 2) - 1
end

vim.api.nvim_set_hl(0, "AlphaRegular", { fg = "#e8b589", italic = true })
vim.api.nvim_set_hl(0, "AlphaItalic", { fg = "#c48282", italic = true })
vim.api.nvim_set_hl(0, "AlphaAuthor", { fg = "#6e94b2", italic = true })

-- alpha
require "alpha".setup({
  layout = {
    { type = "padding", val = center_padding() },

    {
      type = "text",
      val = { quote[1] },
      opts = {
        position = "center",
        hl = "AlphaRegular",
      },
    },

    {
      type = "text",
      val = { quote[2] },
      opts = {
        position = "center",
        hl = "AlphaItalic",
      },
    },

    { type = "padding", val = 1 },

    {
      type = "text",
      val = author,
      opts = {
        position = "center",
        hl = "AlphaAuthor",
      },
    },
    { type = "padding", val = center_padding() },
  }
})
