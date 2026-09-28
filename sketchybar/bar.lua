local colors = require("colors")
local settings = require("settings")

-- Bar appearance only; `init.lua` applies it through SbarLua.
return {
  position = "top",
  color = colors.transparent,
  height = settings.bar.height,
  padding_left = settings.bar.padding_left,
  padding_right = settings.bar.padding_right,
  display = "all",
  font_smoothing = true,
}
