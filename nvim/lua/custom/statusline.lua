local colors = require('custom.colors').palette
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


  vim.api.nvim_set_hl(0, 'StatusLine', {
    fg = colors.yellow,
    bg = colors.bg,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBufferActive', {
    fg = colors.yellow,
    bg = colors.bg,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineBuffer', {
    fg = colors.muted,
    bg = colors.bg,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineNC', {
    fg = colors.muted,
    bg = colors.bg,
  })

  vim.api.nvim_set_hl(0, 'StatusLineAccent', {
    fg = colors.deep_blue,
    bg = colors.blue,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineInsertAccent', {
    fg = colors.deep_blue,
    bg = colors.green,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineVisualAccent', {
    fg = colors.deep_blue,
    bg = colors.purple,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineReplaceAccent', {
    fg = colors.deep_blue,
    bg = colors.red,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineCmdLineAccent', {
    fg = colors.deep_blue,
    bg = colors.yellow,
    bold = true,
  })

  vim.api.nvim_set_hl(0, 'StatusLineTerminalAccent', {
    fg = colors.deep_blue,
    bg = colors.blue,
    bold = true,
  })
end

function M.render()
  return table.concat({
    mode(),
    '%#StatusLine#',
    ' %f',
    ' %m',
    '%=',
    '%#StatusLine#[%{&filetype}] ',
  })
end

function M.setup()
  vim.opt.laststatus = 3
  vim.opt.statusline = '%!v:lua.require\'custom.statusline\'.render()'
  set_colors()
end

return M
