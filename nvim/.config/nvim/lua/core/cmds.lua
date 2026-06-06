-- restart and restore session
vim.api.nvim_create_user_command('Restart', function()
  vim.cmd('mksession! Session.vim ')
  vim.cmd([[restart +source\ Session.vim]])
end, {})

vim.api.nvim_create_user_command('Restart', function()
  local session_file = vim.fn.stdpath('state') .. '/restart_session.vim'
  vim.cmd('mksession! ' .. vim.fn.fnameescape(session_file))
  vim.cmd('restart source ' .. vim.fn.fnameescape(session_file))
end, {})

-- search Files
vim.api.nvim_create_user_command('Files', function(opts)
  local query = opts.args
  local cmd = { 'fd', '--type', 'f', '--hidden', '--exclude', '.git' }

  if query ~= '' then
    table.insert(cmd, query)
  end

  vim.system(cmd, { text = true }, function(obj)
    vim.schedule(function()
      local items = {}

      for line in obj.stdout:gmatch('[^\r\n]+') do
        table.insert(items, {
          filename = line,
          lnum = 1,
          col = 1,
          text = line,
        })
      end

      vim.fn.setqflist({}, ' ', {
        title = 'Files: ' .. query,
        items = items,
      })

      vim.cmd.copen()
    end)
  end)
end, {
  nargs = '*',
  complete = 'file',
})

vim.api.nvim_create_user_command('DeletePacks', function()
  vim.pack.del(vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable())
end, {})
