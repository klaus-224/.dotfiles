local sbar = require("sketchybar")
local settings = require("settings")
local colors = require("colors")

sbar.default({
  padding_left = 0,
  padding_right = 0,
  icon = {
    color = colors.cyan,
    font = {
      family = settings.font.text,
      style = settings.font.style_map.Bold,
      size = settings.font.size,
    },
    padding_left = 2 * settings.paddings,
    padding_right = settings.paddings,
    align = "center",
  },
  label = {
    color = colors.fg,
    font = {
      family = settings.font.text,
      style = settings.font.style_map.Regular,
      size = settings.font.size,
    },
    padding_left = 0,
    padding_right = 2 * settings.paddings,
    align = "center",
  },
  background = {
    border_color = colors.purple,
    border_width = 2,
    corner_radius = 16,
    height = 28,
  },
})
