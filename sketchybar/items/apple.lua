local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

local apple = {}

-- AeroSpace calls this once per display and includes the decorative logo in
-- its shared workspace bracket. The logo intentionally has no click action.
function apple.add(display)
  return sbar.add("item", "workspace.logo." .. display, {
    display = display,
    position = "left",
    padding_left = 8,
    padding_right = 7,
    icon = {
      string = icons.apple,
      color = colors.fg,
      padding_left = 0,
      padding_right = 0,
    },
    label = { drawing = false },
  })
end

return apple
