local M = {}

local transparent_groups = {
  'Normal',
  'Identifier',
  'Statement',
  'PreProc',
  'Type',
  'Underlined',
  'Todo',
  'Function',
  'Conditional',
  'Repeat',
  'Operator',
  'Structure',
  'NonText',
  'EndOfBuffer',
}

local function setup_alpha()
  local quote = {
    '"I can do nothing for you but work on myself...',
    '         you can do nothing for me but work on yourself"',
  }

  local author = { "                              — Ram Dass" }

  local function center_padding()
    local height = vim.fn.winheight(0)
    local content_height = #quote + #author
    return math.floor((height - content_height) / 2) - 1
  end

  vim.api.nvim_set_hl(0, "AlphaRegular", { fg = "#e8b589", italic = true })
  vim.api.nvim_set_hl(0, "AlphaItalic", { fg = "#c48282", italic = true })
  vim.api.nvim_set_hl(0, "AlphaAuthor", { fg = "#6e94b2", italic = true })

  -- alpha
  require "alpha".setup({
    layout = {
      { type = "padding", val = center_padding() },

      {
        type = "text",
        val = { quote[1] },
        opts = {
          position = "center",
          hl = "AlphaRegular",
        },
      },

      {
        type = "text",
        val = { quote[2] },
        opts = {
          position = "center",
          hl = "AlphaItalic",
        },
      },

      { type = "padding", val = 1 },

      {
        type = "text",
        val = author,
        opts = {
          position = "center",
          hl = "AlphaAuthor",
        },
      },
      { type = "padding", val = center_padding() },
    }
  })
end

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

  setup_alpha()
end

return M
