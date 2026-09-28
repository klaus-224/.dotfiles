local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local widget = require("helpers.widget")

-- One fixed-width pill per widget: the widget item plus the bracket that draws
-- the pill surface around it.
local pill = {}

function pill.add(spec, position)
  -- Enforced after the widget module's own `item` properties, so a pill always
  -- has a consistent outer gap and an optional fixed label width.
  local overrides = {
    padding_left = settings.pills.gap,
    padding_right = 0,
    label = { width = spec.label_width },
  }

  local item = widget.add(spec, position or "right", overrides)

  sbar.add("bracket", "pill." .. spec.name, { "widgets." .. spec.name }, {
    background = {
      color = colors.pill_bg,
      border_color = colors.pill_border,
      border_width = settings.pill.border_width,
      corner_radius = settings.pill.corner_radius,
      height = settings.pill.height,
    },
  })

  return item
end

return pill
