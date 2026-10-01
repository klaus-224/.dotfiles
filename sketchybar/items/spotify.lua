local sbar = require("sketchybar")
local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

sbar.add("item", "spacer.spotify", {
  position = "right",
  width = settings.group_paddings,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local item = sbar.add("item", "widgets.spotify", {
  position = "right",
  icon = { string = icons.spotify, color = colors.green, padding_right = 2 * settings.paddings },
  label = { drawing = false },
})

item:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Spotify"')
end)

sbar.add("bracket", "pill.spotify", { "widgets.spotify" }, {
  background = { color = colors.pill_bg },
})

return item
