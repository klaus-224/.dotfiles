vim.opt_local.wrap = false
vim.opt_local.list = true
vim.opt_local.cursorline = true
vim.opt_local.cursorcolumn = true
vim.opt_local.sidescroll = 1
vim.opt_local.sidescrolloff = 8

-- highlight commas
vim.fn.matchadd('Comment', ',')

local function fields(line)
  local out = {}
  local start = 1
  local quoted = false

  for i = 1, #line do
    local c = line:sub(i, i)
    if c == '"' then
      quoted = not quoted
    elseif c == ',' and not quoted then
      table.insert(out, { start, i - 1 })
      start = i + 1
    end
  end

  table.insert(out, { start, #line })
  return out
end

local function jump_field(dir)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local fs = fields(line)

  if dir > 0 then
    for _, f in ipairs(fs) do
      if f[1] > col then
        vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), f[1] - 1 })
        return
      end
    end
  else
    for i = #fs, 1, -1 do
      if fs[i][1] < col then
        vim.api.nvim_win_set_cursor(0, { vim.fn.line('.'), fs[i][1] - 1 })
        return
      end
    end
  end
end

vim.keymap.set('n', ']c', function()
  jump_field(1)
end, { buffer = true, desc = 'Next CSV field' })

vim.keymap.set('n', '[c', function()
  jump_field(-1)
end, { buffer = true, desc = 'Previous CSV field' })

vim.api.nvim_create_user_command('CsvView', function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local rows = {}
  local widths = {}

  for _, line in ipairs(lines) do
    local row = vim.split(line, ',', { plain = true })
    table.insert(rows, row)

    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i] or 0, #cell)
    end
  end

  local pretty = {}

  for _, row in ipairs(rows) do
    local parts = {}
    for i, cell in ipairs(row) do
      table.insert(parts, cell .. string.rep(' ', widths[i] - #cell))
    end
    table.insert(pretty, table.concat(parts, ' │ '))
  end

  vim.cmd('vnew')
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(0, 0, -1, false, pretty)
  vim.bo.modifiable = false
end, {})
