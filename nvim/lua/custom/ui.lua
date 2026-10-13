local colors = require('custom.colors').palette

local M = {}

local function setup_alpha()
  local quote = {
    '"I can do nothing for you but work on myself...',
    '         you can do nothing for me but work on yourself"',
  }

  local author = { '                              — Ram Dass' }

  local function center_padding()
    local height = vim.fn.winheight(0)
    local content_height = #quote + #author
    return math.floor((height - content_height) / 2) - 1
  end

  vim.api.nvim_set_hl(0, 'AlphaRegular', { fg = colors.yellow, italic = true })
  vim.api.nvim_set_hl(0, 'AlphaItalic', { fg = colors.red, italic = true })
  vim.api.nvim_set_hl(0, 'AlphaAuthor', { fg = colors.blue, italic = true })

  -- alpha
  require('alpha').setup({
    layout = {
      { type = 'padding', val = center_padding() },

      {
        type = 'text',
        val = { quote[1] },
        opts = {
          position = 'center',
          hl = 'AlphaRegular',
        },
      },

      {
        type = 'text',
        val = { quote[2] },
        opts = {
          position = 'center',
          hl = 'AlphaItalic',
        },
      },

      { type = 'padding', val = 1 },

      {
        type = 'text',
        val = author,
        opts = {
          position = 'center',
          hl = 'AlphaAuthor',
        },
      },
      { type = 'padding', val = center_padding() },
    },
  })
end

M.setup = function()
  require('vague').setup({
    italic = false,
  })

  vim.cmd.colorscheme('vague')

  -- transarent background
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = colors.muted, bg = colors.bg })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = colors.muted, bg = colors.bg })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = colors.yellow, bg = colors.bg, bold = true })
  vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE', ctermbg = 'NONE' })
  vim.api.nvim_set_hl(0, 'TabLine', { link = 'LineNrAbove' })
  vim.api.nvim_set_hl(0, 'TabLineFill', { link = 'LineNrAbove' })
  vim.api.nvim_set_hl(0, 'TabLineSel', { fg = colors.yellow, bg = colors.bg })
  -- for the visual highlighitng
  vim.api.nvim_set_hl(0, 'Visual', { bg = colors.selection })


  -- generic floats: hover, cmd+k, docs, random plugin popups
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE', fg = colors.fg })
  vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE', fg = colors.border })
  vim.api.nvim_set_hl(0, 'FloatTitle', { bg = colors.bg, fg = colors.blue, bold = true })
  vim.api.nvim_set_hl(0, 'FloatFooter', { bg = colors.bg, fg = colors.muted, italic = true })

  -- generic completion menu groups
  vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE', fg = colors.fg })
  vim.api.nvim_set_hl(0, 'PmenuSel', { bg = colors.selection, fg = colors.yellow, bold = true })
  vim.api.nvim_set_hl(0, 'PmenuKind', { bg = 'NONE', fg = colors.blue })
  vim.api.nvim_set_hl(0, 'PmenuExtra', { bg = 'NONE', fg = colors.border })
  vim.api.nvim_set_hl(0, 'PmenuBorder', { bg = 'NONE', fg = colors.border, bold = true })

  -- scrollbar, if visible
  vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = colors.border })
  vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = colors.bg })

  -- mini pick
  vim.api.nvim_set_hl(0, 'MiniPickMatchCurrent', {
    fg = colors.yellow,
    bg = colors.selection,
    bold = true,
  })
  vim.api.nvim_set_hl(0, 'MiniPickNormal', {
    fg = colors.fg,
    bg = 'NONE',
  })

  -- blink
  vim.api.nvim_set_hl(0, 'BlinkCmpMenuBorder', { fg = colors.border })

  -- diff


  -- Subtle pastel/flat color palette for diffs
  vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2e3f32", fg = "#a6e22e" })               -- Subtle green background, bright green text
  vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#402d31", fg = "#f92672" })            -- Subtle red background, bright red text
  vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2b3447", fg = "#66d9ef" })            -- Subtle blue background for changed lines
  vim.api.nvim_set_hl(0, "DiffText", { bg = "#3e4b68", fg = "#e6db74", bold = true }) -- Exact inner-word changes (yellow)

  setup_alpha()
end

return M
