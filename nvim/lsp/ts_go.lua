---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = 'tsc'

    if config.root_dir then
      local local_cmd = vim.fs.joinpath(config.root_dir, 'node_modules/.bin/tsc')

      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end

    return vim.lsp.rpc.start({
      cmd,
      '--lsp',
      '--stdio',
    }, dispatchers)
  end,

  filetypes = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },

  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, {
      'pnpm-lock.yaml',
      'package-lock.json',
      'yarn.lock',
      'bun.lock',
      'bun.lockb',
      '.git',
    })

    on_dir(root or vim.fn.getcwd())
  end,
}
