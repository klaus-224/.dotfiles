local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")
local colors = require("colors")
local icons = require("icons")

local item = sbar.add("item", "widgets.spotify", style.resolve({
  position = "right",
  icon = { string = "" },
  label = { string = "" },
}, settings.widgets, {
  icon = { string = icons.spotify, color = colors.green },
}))

item:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Spotify"')
end)

sbar.add("bracket", "pill.spotify", { "widgets.spotify" }, style.resolve(settings.pill))

return item
