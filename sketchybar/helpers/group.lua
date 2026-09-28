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
    widget.add(specs[index], "right")
    table.insert(members, 1, "widgets." .. specs[index].name)
  end

  local bracket = sbar.add("bracket", "bracket." .. name, members, {
    background = {
      color = colors.transparent,
      border_color = colors.yellow,
      border_width = settings.groups.background_border_width,
      corner_radius = settings.groups.background_corner_radius,
      height = settings.groups.background_height,
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
