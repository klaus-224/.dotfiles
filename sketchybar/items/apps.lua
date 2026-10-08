local sbar = require("sketchybar")
local settings = require("settings")
local colors = require("colors")

sbar.add("item", "spacer.apps", {
  position = "left",
  width = settings.group_paddings,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

require("items.spotify")
require("items.slack")
require("items.teams")

sbar.add("bracket", "pill.apps", {
  "widgets.spotify",
  "widgets.slack",
  "widgets.teams",
}, {
  blur_radius = settings.blur_radius,
  background = {
    drawing = true,
    color = colors.pill_bg,
  },
})
