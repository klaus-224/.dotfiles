local colors = require("colors")
local settings = require("settings")

-- Properties inherited by every item; `init.lua` applies them through SbarLua.
return {
  icon = {
    color = colors.fg,
    font = settings.fonts.icon,
    padding_left = settings.item.icon_padding_left,
    padding_right = settings.item.icon_padding_right,
    align = "center",
  },
  label = {
    color = colors.fg,
    font = settings.fonts.label,
    padding_left = settings.item.label_padding_left,
    padding_right = settings.item.label_padding_right,
    align = "center",
  },
}
