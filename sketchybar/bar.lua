local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

sbar.bar({
  position = "top",
  color = colors.transparent,
  height = settings.bar.height,
  padding_left = settings.bar.padding_left,
  padding_right = settings.bar.padding_right,
  display = "all",
  font_smoothing = true
})
