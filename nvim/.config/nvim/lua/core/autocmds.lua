-- update tree sitter when pack is added
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(args)
    local name, kind = args.data.spec.name, args.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not args.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end
})

-- enable lsp stuff
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('MyLSP', {}),
  callback = function(args)
    local lsp = vim.lsp
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method('textDocument/completion') then
      lsp.completion.enable(true, client.id, args.buf)
    end

    if client:supports_method("inlayHint/resolve") then
      lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end

    if client:supports_method("callHierarchy/incomingCalls") then
      vim.set("n", "<leader>li", lsp.buf.incoming_calls)
    end

    if client:supports_method("callHierarchy/outgoingCalls") then
      vim.set("n", "<leader>lo", lsp.buf.outgoing_calls, { noremap = false })
    end
    -- Auto-format ("lint") on save.
    -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
    --        if not client:supports_method('textDocument/willSaveWaitUntil')
    --            and client:supports_method('textDocument/formatting') then
    --          vim.api.nvim_create_autocmd('BufWritePre', {
    --            group = vim.api.nvim_create_augroup('my.lsp', {clear=false}),
    --            buffer = args.buf,
    --            callback = function()
    --              vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
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

vim.api.nvim_create_autocmd("InsertEnter", {
  group = vim.api.nvim_create_augroup('nvim-autopairs', { clear = true }),
  callback = function()
    require "nvim-autopairs".setup({
      enable_check_bracket_line = true,
      ignored_next_char = "[%w%.]",
      fast_wrap = {},
      check_ts = true, -- treesitter
    })

    require "nvim-ts-autotag".setup({
      opts = {
        enable_close = true,           -- Auto close tags
        enable_rename = true,          -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
      },
      per_filetype = {
        ["html"] = {
          enable_close = false,
        },
      }
    })
  end
})
