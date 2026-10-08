local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")

local item = sbar.add("item", "widgets.spotify", {
  position = "left",
  icon = { string = icons.spotify, color = colors.green, padding_right = 2 },
  label = { drawing = false },
})

item:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Spotify"')
end)

return item
