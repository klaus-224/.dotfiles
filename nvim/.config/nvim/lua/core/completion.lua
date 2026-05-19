-- native completion sources.
vim.opt.complete = { '.', 'w', 'b', 'o' }

-- native popup menu behavior.
vim.opt.completeopt = { 'menuone', 'noselect', 'fuzzy', 'popup' }
vim.opt.autocomplete = true
vim.opt.autocompletedelay = 250
vim.opt.pumheight = 8
vim.opt.pumborder = 'rounded'

-- cmdline completion.
vim.opt.wildmenu = true
vim.opt.wildmode = { 'longest:full', 'full' }
vim.opt.wildignore:append({
  '*/.git/*',
  '*/node_modules/*',
  '*/dist/*',
  '*/build/*',
  '*/target/*',
})

-- enable lsp completion when a server attaches.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('native-completion', { clear = true }),
  callback = function(ev)
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = true,
      })
    end

    if client:supports_method('inlayHint/resolve') then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

    if client:supports_method('callHierarchy/incomingCalls') then
      vim.keymap.set('n', '<leader>li', vim.lsp.buf.incoming_calls)
    end

    if client:supports_method('callHierarchy/outgoingCalls') then
      vim.keymap.set('n', '<leader>lo', vim.lsp.buf.outgoing_calls, { noremap = false })
    end
  end,
})

-- manually trigger lsp completion.
vim.keymap.set('i', '<C-Space>', function()
  vim.lsp.completion.get()
end, {})

-- accept native completion with tab.
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-y>'
  end

  return '<Tab>'
end, { expr = true, replace_keycodes = true })

-- path completion.
vim.keymap.set('i', '<C-f>', '<C-x><C-f>', {})

-- hover documentation.
vim.keymap.set('n', 'K', function()
  vim.lsp.buf.hover({
    border = 'rounded',
    max_width = 80,
    max_height = 20,
  })
end, {})

-- signature help.
vim.keymap.set('i', '<C-k>', function()
  vim.lsp.buf.signature_help({
    border = 'rounded',
    max_width = 80,
    max_height = 12,
  })
end, {})

-- snippets
-- require('luasnip.loaders.from_vscode').lazy_load()
--
-- vim.keymap.set({ 'i', 's' }, '<C-j>', function()
--   local ls = require('luasnip')
--
--   if ls.expand_or_jumpable() then
--     ls.expand_or_jump()
--   end
-- end, {})
