local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

sbar.bar({
  position = "top",
  color = colors.bg,
  height = settings.bar.height,
  border_color = colors.purple,
  broder_width = settings.bar.border_width,
  padding_left = settings.bar.padding_left,
  padding_right = settings.bar.padding_right,
  -- y_offset = settings.bar.margin,
  -- margin = settings.bar.margin,
  -- corner_radius = settings.bar.radius,
  display = "all",
  font_smoothing = true
})
