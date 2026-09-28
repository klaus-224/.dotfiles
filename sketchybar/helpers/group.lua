local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local widget = require("helpers.widget")

local group = {}

function group.add(name, specs)
  local members = {}

  -- Right-side items are inserted from right to left. Accept specs in visual
  -- left-to-right order so extending a group does not require mental reversal.
  for index = #specs, 1, -1 do
    local spec = specs[index]
    spec.item = spec.item or {}
    if index == 1 then
      spec.item.padding_left = settings.widgets.item_padding + settings.widgets.group_padding
    end
    if index == #specs then
      spec.item.padding_right = settings.widgets.item_padding + settings.widgets.group_padding
    end
    widget.add(spec, "right")
    table.insert(members, 1, "widgets." .. specs[index].name)
  end

  local bracket = sbar.add("bracket", "bracket." .. name, members, {
    background = {
      color = colors.pill_bg,
      border_color = colors.pill_border,
      border_width = settings.pill.border_width,
      corner_radius = settings.pill.corner_radius,
      height = settings.pill.height,
    },
  })

  sbar.add("item", "spacer." .. name, {
    position = "right",
    width = settings.widgets.group_gap,
    icon = { drawing = false },
    label = { drawing = false },
  })

  return { bracket = bracket, members = members }
end

return group
