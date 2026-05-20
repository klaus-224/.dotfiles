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

local function set_colors()
  local bg_color = '#252530'

  vim.api.nvim_set_hl(0, 'StatusLine', {
    fg = '#CDCDCD',
    bg = bg_color,
  })

  vim.api.nvim_set_hl(0, 'StatusLineNC', {
    fg = '#606079',
    bg = bg_color,
  })

  vim.api.nvim_set_hl(0, 'StatusLineAccent', {
    fg = '#0f1117',
    bg = '#7E98E8',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineInsertAccent', {
    fg = '#0f1117',
    bg = '#7FA563',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineVisualAccent', {
    fg = '#0f1117',
    bg = '#BB9DBD',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineReplaceAccent', {
    fg = '#0f1117',
    bg = '#D8647E',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineCmdLineAccent', {
    fg = '#0f1117',
    bg = '#F3BE7C',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineTerminalAccent', {
    fg = '#0f1117',
    bg = '#6E94B2',
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBufferActive', {
    fg = '#CDCDCD',
    bg = bg_color,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBuffer', {
    fg = '#747b89',
    bg = bg_color,
    bold = true,
  })
end

function M.render()
  return table.concat({
    mode(),
    '%#StatusLine#',
    ' %f',
    '%m',
    '%=',
    '[%{&filetype}]',
  })
end

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.statusline = '%!v:lua.require\'custom.statusline\'.render()'
  set_colors()
end

return M
