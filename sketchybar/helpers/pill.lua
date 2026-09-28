local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local widget = require("helpers.widget")

local pill = {}

function pill.add(spec, position)
  spec.item = spec.item or {}
  spec.item.padding_left = settings.pills.gap
  spec.item.padding_right = 0
  spec.item.label = spec.item.label or {}
  spec.item.label.width = spec.label_width

  local item = widget.add(spec, position or "right")

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
