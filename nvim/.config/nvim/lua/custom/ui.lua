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

  vim.api.nvim_set_hl(0, 'AlphaRegular', { fg = '#e8b589', italic = true })
  vim.api.nvim_set_hl(0, 'AlphaItalic', { fg = '#c48282', italic = true })
  vim.api.nvim_set_hl(0, 'AlphaAuthor', { fg = '#6e94b2', italic = true })

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
  vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE', ctermbg = 'NONE' })
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#606079', bg = '#0f1117' })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#606079', bg = '#0f1117' })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = '#ffd166', bg = '#0f1117', bold = true })
  vim.api.nvim_set_hl(0, 'TabLine', { link = 'LineNrAbove' })
  vim.api.nvim_set_hl(0, 'TabLineFill', { link = 'LineNrAbove' })
  vim.api.nvim_set_hl(0, 'TabLineSel', { fg = '#ffd166', bg = '#0f1117' })

  local colors = {
    bg = '#000000',
    fg = '#b4bcc8',
    muted = '#747b89',
    border = '#e6c384',
    selection = '#23252e',
    blue = '#8aadf4',
    yellow = '#e6c384',
  }

  -- generic floats: hover, cmd+k, docs, random plugin popups
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = colors.bg, fg = colors.fg })
  vim.api.nvim_set_hl(0, 'FloatBorder', { bg = colors.bg, fg = colors.border })
  vim.api.nvim_set_hl(0, 'FloatTitle', { bg = colors.bg, fg = colors.blue, bold = true })
  vim.api.nvim_set_hl(0, 'FloatFooter', { bg = colors.bg, fg = colors.muted, italic = true })

  -- generic completion menu groups
  vim.api.nvim_set_hl(0, 'Pmenu', { bg = colors.bg, fg = colors.fg })
  vim.api.nvim_set_hl(0, 'PmenuSel', { bg = colors.selection, fg = colors.fg, bold = true })
  vim.api.nvim_set_hl(0, 'PmenuKind', { bg = colors.bg, fg = colors.blue })
  vim.api.nvim_set_hl(0, 'PmenuExtra', { bg = colors.bg, fg = colors.muted })
  vim.api.nvim_set_hl(0, 'PmenuBorder', { bg = colors.bg, fg = colors.border })

  -- scrollbar, if visible
  vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = colors.border })
  vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = colors.bg })

  setup_alpha()
end

return M
