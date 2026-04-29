local M = {}

local transparent_groups = {
  'Normal',
  'NormalNC',
  'Comment',
  'Constant',
  'Identifier',
  'Statement',
  'PreProc',
  'Type',
  'Underlined',
  'Todo',
  'String',
  'Function',
  'Conditional',
  'Repeat',
  'Operator',
  'Structure',
  'NonText',
  'CursorLine',
  'CursorLineNr',
  'EndOfBuffer',
}


M.setup = function()
  require "vague".setup({
    italic = false,
  })

  vim.cmd.colorscheme("vague")

  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
  end

  vim.api.nvim_set_hl(0, "StatusLine", { fg = "#ffd166", bg = "#282828" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#5c6370", bg = "#282828" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#5c6370", bg = "#282828" })
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#ffd166", bg = "#282828", bold = true })
  vim.api.nvim_set_hl(0, "TabLine", { link = "LineNrAbove" })
  vim.api.nvim_set_hl(0, "TabLineFill", { link = "LineNrAbove" })
  vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffd166", bg = "#282828" })
end

return M
