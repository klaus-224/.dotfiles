local M = {}

local modes = {
  n = { label = 'N', hl = '%#StatusLineAccent#' },
  no = { label = 'N', hl = '%#StatusLineAccent#' },

  i = { label = 'I', hl = '%#StatusLineInsertAccent#' },
  ic = { label = 'I', hl = '%#StatusLineInsertAccent#' },

  v = { label = 'V', hl = '%#StatusLineVisualAccent#' },
  V = { label = 'VL', hl = '%#StatusLineVisualAccent#' },
  [''] = { label = 'VB', hl = '%#StatusLineVisualAccent#' },

  R = { label = 'R', hl = '%#StatusLineReplaceAccent#' },
  Rv = { label = 'VR', hl = '%#StatusLineReplaceAccent#' },

  c = { label = 'C', hl = '%#StatusLineCmdLineAccent#' },
  cv = { label = 'EX', hl = '%#StatusLineCmdLineAccent#' },
  ce = { label = 'EX', hl = '%#StatusLineCmdLineAccent#' },

  t = { label = 'T', hl = '%#StatusLineTerminalAccent#' },
}

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  local item = modes[current_mode] or {
    label = current_mode:upper(),
    hl = '%#StatusLineAccent#',
  }

  local winid = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local width = vim.wo[winid].numberwidth
  local label = item.label:sub(1, width)
  local padding = width - #label
  local left = math.floor(padding / 2)
  local right = padding - left

  return table.concat({
    item.hl,
    string.rep(' ', left),
    label,
    string.rep(' ', right),
    '%#StatusLine#',
  })
end

local function filename()
  local name = vim.fn.expand('%:h')

  if name == '' then
    name = ''
  end

  local modified = vim.bo.modified and ' [+]' or ''
  local readonly = vim.bo.readonly and ' [RO]' or ''

  return ' ' .. name .. modified .. readonly .. ' '
end

-- local function position()
--   local line = vim.fn.line('.')
--   local col = vim.fn.col('.')
--
--   return string.format(' %4d:%-3d ', line, col)
-- end

local function buffers()
  local current = vim.api.nvim_get_current_buf()
  local all = {}

  -- all buffers that are loaded
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      table.insert(all, bufnr)
    end
  end

  local limit = 4

  if #all > limit then
    local current_index = 1

    for i, bufnr in ipairs(all) do
      if bufnr == current then
        current_index = i
        break
      end
    end

    local start = math.max(1, current_index - math.floor(limit / 2))
    local finish = math.min(#all, start + limit - 1)

    if finish - start + 1 < limit then
      start = math.max(1, finish - limit + 1)
    end

    local visible = {}

    for i = start, finish do
      table.insert(visible, all[i])
    end

    all = visible
  end

  local parts = {}

  for _, bufnr in ipairs(all) do
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == '' then
      return
    else
      name = vim.fn.fnamemodify(name, ':t')
    end

    local hl = bufnr == current and '%#StatusLineBufferActive#' or '%#StatusLineBuffer#'

    table.insert(parts, hl .. ' ' .. name .. ' ')
  end

  return table.concat(parts, '%#StatusLine#')
end

local function set_colors()
  vim.api.nvim_set_hl(0, 'StatusLine', {
    fg = '#cdcdcd',
    bg = '#0f1117',
  })

  vim.api.nvim_set_hl(0, 'StatusLineNC', {
    fg = '#606079',
    bg = '#0f1117',
  })

  vim.api.nvim_set_hl(0, 'StatusLineAccent', {
    fg = '#0f1117',
    bg = '#8ba9c1',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineInsertAccent', {
    fg = '#0f1117',
    bg = '#99b782',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineVisualAccent', {
    fg = '#0f1117',
    bg = '#c9b1ca',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineReplaceAccent', {
    fg = '#0f1117',
    bg = '#e08398',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineCmdLineAccent', {
    fg = '#0f1117',
    bg = '#f5cb96',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineTerminalAccent', {
    fg = '#0f1117',
    bg = '#606079',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBufferActive', {
    fg = '#cdcdcd',
    bg = '#0f1117',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBuffer', {
    fg = '#747b89',
    bg = '#0f1117',
    bold = true,
  })
end

function M.render()
  return table.concat({
    mode(),
    filename(),
    '%=',
    buffers(),
    -- '%#StatusLine#',
    -- position(),
  })
end

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.statusline = '%!v:lua.require\'custom.statusline\'.render()'
  set_colors()
end

return M
