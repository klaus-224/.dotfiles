-- [bat ▮▮▮▮▯]: five cells, accent on AC power, red at 20% or below on
-- battery. Hidden on Macs without a battery. Menu BATTERY.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local stats = require("helpers.stats")

local c = theme.colors
local i = theme.island
local battery = {}

-- Right side adds right to left: the cells first, then the tag.
local menu
local open = function() if menu then menu:toggle() end end
local cells = island.gauge_cells("battery", "right", open)
local item = sbar.add("item", "battery", {
  position = "right",
  padding_left = i.cell_gap,
  padding_right = 0,
  icon = { string = "bat", color = c.text3, padding_left = 0, padding_right = 4 },
  label = { drawing = false },
})
battery.members = { "battery", "battery.1", "battery.2", "battery.3", "battery.4", "battery.5" }

menu = popup.new(item, { title = "BATTERY", width = require("helpers.text").menu_width(27), hosts = battery.members })
local level = menu:row("level", { key = "level", value = "—" })
local source = menu:row("source", { key = "power", value = "—" })
local remaining = menu:row("time", { key = "time", value = "—" })
menu:row("open", { key = "open", value = "Battery Settings ↗", color = c.text2,
  on_click = function() helper.open("x-apple.systempreferences:com.apple.Battery-Settings.extension") end })
menu:finish()
menu:bind({ item })

stats.on(function(s)
  local b = s.battery
  local visible = type(b) == "table" and b.percent ~= nil
  item:set({ drawing = visible })
  for _, cell in ipairs(cells) do cell:set({ drawing = visible }) end
  if not visible then return end
  local low = b.percent <= 20 and not b.ac
  island.fill_cells(cells, b.percent, b.ac and c.accent or (low and c.err or c.text))
  level:update({ value = b.percent .. "%", color = low and c.err or c.text })
  source:update({ value = b.charging and "charging" or (b.ac and "power adapter" or "battery") })
  local t = b.remaining and b.remaining ~= "0:00" and b.remaining or nil
  remaining:update({ value = t and (t .. (b.charging and " to full" or " left")) or "—" })
end)

function battery.underline()
  menu.opts.underline = island.underline_group("battery.u", battery.members)
end

return battery
