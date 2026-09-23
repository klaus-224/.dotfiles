local sbar = require("sketchybar")
local colors = require("colors")

sbar.bar({
  position = "top",
  height = 36,
  color = colors.transparent,
  padding_left = 8,
  padding_right = 8,
})

sbar.default({
  icon = { color = colors.fg },
  label = { color = colors.fg },
})
