local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

sbar.bar({
  position = "top",
  height = settings.bar.height,
  color = colors.bg,
  padding_left = settings.bar.padding_left,
  padding_right = settings.bar.padding_right,
  display = "all"
})
