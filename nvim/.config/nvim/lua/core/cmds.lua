-- cd to project root
local function cd_project_root()
  local root = vim.fs.root(0, {
    '.git',
    'package.json',
    'pyproject.toml',
    'Cargo.toml',
    'Makefile',
  })

  if root then
    vim.cmd.cd(root)
    print('Changed directory to ' .. root)
  else
    vim.notify('Project root not found', vim.log.levels.WARN)
  end
end

vim.keymap.set('n', '<leader>cd', cd_project_root, {
  desc = 'Change directory to project root',
})

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

-- Run shell command and show output in a scratch buffer
vim.keymap.set('n', '<leader>!', function()
  vim.ui.input({ prompt = 'shell> ' }, function(cmd)
    if not cmd or cmd == '' then
      return
    end

    vim.system({ 'zsh', '-lc', cmd }, { text = true }, function(result)
      vim.schedule(function()
        vim.cmd('botright new')
        vim.bo.buftype = 'nofile'
        vim.bo.bufhidden = 'wipe'
        vim.bo.swapfile = false
        vim.api.nvim_buf_set_name(0, 'shell: ' .. cmd)

        local output = vim.split(result.stdout .. result.stderr, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
      end)
    end)
  end)
end, {})

-- Open terminal in a split
vim.keymap.set('n', '<leader>tt', function()
  vim.cmd('botright split | resize 5 | terminal')
end, {})

-- Rerun make/test/lint command through quickfix
vim.keymap.set('n', '<leader>m', function()
  vim.cmd('silent make')
  vim.cmd('copen')
end, {})

-- change to git root

-- remove unused packs
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
