local M = {}

local config = {
  height = 0.33,
  focus = true,
}

local state = {
  bufnr = nil,
  winid = nil,
  process = nil,
}

local function set_lines(lines)
  if not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end

  vim.bo[state.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.bo[state.bufnr].modifiable = false
end

local function split_output(value)
  if not value or value == '' then
    return {}
  end

  value = value:gsub('\r\n', '\n'):gsub('\r', '\n')

  if value:sub(-1) == '\n' then
    value = value:sub(1, -2)
  end

  return vim.split(value, '\n', { plain = true })
end

local function create_buffer()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    return state.bufnr
  end

  state.bufnr = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(state.bufnr, 'command://output')

  vim.bo[state.bufnr].buftype = 'nofile'
  vim.bo[state.bufnr].bufhidden = 'hide'
  vim.bo[state.bufnr].swapfile = false
  vim.bo[state.bufnr].filetype = 'command-output'

  vim.keymap.set('n', '<C-c>', M.stop, {
    buffer = state.bufnr,
    silent = true,
    desc = 'Stop command',
  })

  return state.bufnr
end

local function open_window(opts)
  local bufnr = create_buffer()

  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    if opts.focus then
      vim.api.nvim_set_current_win(state.winid)
    end

    return bufnr, state.winid
  end

  local current_win = vim.api.nvim_get_current_win()
  local current_height = vim.api.nvim_win_get_height(current_win)
  local height = math.max(1, math.floor(current_height * opts.height))

  vim.cmd('belowright split')

  state.winid = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(state.winid, bufnr)
  vim.api.nvim_win_set_height(state.winid, height)

  vim.wo[state.winid].winfixheight = true
  vim.wo[state.winid].number = false
  vim.wo[state.winid].relativenumber = false
  vim.wo[state.winid].signcolumn = 'no'

  if not opts.focus then
    vim.api.nvim_set_current_win(current_win)
  end

  return bufnr, state.winid
end

function M.run(command, opts)
  opts = vim.tbl_extend('force', config, opts or {})

  if not command or command == '' then
    vim.notify('No command provided', vim.log.levels.WARN)
    return
  end

  if state.process then
    state.process:kill(15)
  end

  local bufnr, winid = open_window(opts)

  set_lines({
    '$ ' .. command,
    '',
    'Running...',
  })

  state.process = vim.system(
    {
      vim.o.shell,
      vim.o.shellcmdflag,
      command,
    },
    {
      cwd = opts.cwd or vim.fn.getcwd(),
      text = true,
    },
    vim.schedule_wrap(function(result)
      state.process = nil

      local lines = {
        '$ ' .. command,
        '',
      }

      vim.list_extend(lines, split_output(result.stdout))

      if result.stderr and result.stderr ~= '' then
        if #lines > 2 then
          table.insert(lines, '')
        end

        vim.list_extend(lines, split_output(result.stderr))
      end

      table.insert(lines, '')
      table.insert(lines, ('Process exited with code %d'):format(result.code))

      set_lines(lines)

      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_set_cursor(winid, { 1, 0 })
      end
    end)
  )

  return {
    bufnr = bufnr,
    winid = winid,
    process = state.process,
  }
end

function M.stop()
  if state.process then
    state.process:kill(15)
    state.process = nil
  end
end

function M.close()
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
  end

  state.winid = nil
end

function M.get_buffer()
  return state.bufnr
end

function M.setup(opts)
  config = vim.tbl_extend('force', config, opts or {})

  vim.api.nvim_create_user_command('Run', function(command_opts)
    M.run(command_opts.args)
  end, {
    nargs = '+',
    complete = 'shellcmd',
    desc = 'Run a shell command in an output buffer',
  })
end

return M
