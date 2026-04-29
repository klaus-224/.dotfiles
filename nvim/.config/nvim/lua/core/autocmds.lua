-- update tree sitter when pack is added
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end
})

-- enable lsp stuff
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('MyLSP', {}),
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

vim.api.nvim_create_autocmd("RecordingEnter", {
  group = vim.api.nvim_create_augroup("macro-notify", { clear = true }),
  callback = function()
    local last_macro_reg = vim.fn.reg_recording()
    vim.notify("Recording macro @" .. last_macro_reg, vim.log.levels.INFO, { title = "Macros" })
  end,
})

-- save current cursor postion in marks
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SaveExitMark", { clear = true }),
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    -- overwrite global/file mark A in the current buffer
    vim.api.nvim_buf_set_mark(buf, "A", row, col, {})

    -- force-write ShaDa so persisted marks get updated
    pcall(vim.cmd, "wshada!")
  end,
})
