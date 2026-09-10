vim.api.nvim_create_user_command('Home', 'Alpha', {})

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

-- Open terminal in a split
vim.keymap.set('n', '<leader>tt', function()
  vim.cmd('botright split | resize 5 | terminal')
end, {})

-- Rerun make/test/lint command through quickfix
vim.keymap.set('n', '<leader>m', function()
  vim.cmd('silent make')
  vim.cmd('copen')
end, {})

-- remove unused `vim.pack.del( { 'plugin' })`packs
vim.api.nvim_create_user_command('PackClean', function()
  local active_plugins = {}
  local unused_plugins = {}

  for _, plugin in ipairs(vim.pack.get()) do
    active_plugins[plugin.spec.name] = plugin.active
  end

  for _, plugin in ipairs(vim.pack.get()) do
    if not active_plugins[plugin.spec.name] then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end

  if #unused_plugins == 0 then
    print('No unused plugins.')
    return
  end

  local choice = vim.fn.confirm('Remove unused plugins?', '&Yes\n&No', 2)
  if choice == 1 then
    vim.pack.del(unused_plugins)
  end
end, {})

-- copy path of current buffer
vim.api.nvim_create_user_command('CopyPath', function()
  local path = vim.fn.expand('%:p')

  if path == '' then
    vim.notify('Current buffer has no file path', vim.log.levels.WARN)
    return
  end

  vim.fn.setreg('+', path)
  vim.notify('Copied path: ' .. path)
end, {})
