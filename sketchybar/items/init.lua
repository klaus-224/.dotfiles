-- Item order matters: left items are added left to right, right items
-- right to left, and notch-queue items (q) from the notch outwards.
local sbar = require("sketchybar")
local theme = require("theme")
local island = require("helpers.island")
local stats = require("helpers.stats")

local i = theme.island

-- Far-left anchor for the click shield below.
island.spacer("bar.start", "left", 0)

-- Left: one island per display (workspaces + front app).
require("items.aerospace")

-- Media island with Spotify and the volume, after the AeroSpace island.
local media = (require("items.media"))

-- Right island: [agent … · mem · bat · wifi · date time]
require("items.clock")
require("items.wifi")
local battery = require("items.battery")
require("items.memory")
local agents = require("items.agents")
local right = { "agents", "agents.claude", "agents.codex", "agents.opencode",
  "memory", "battery", "battery.1", "battery.2", "battery.3", "battery.4", "battery.5", "wifi", "clock", "clock.edge" }
island.bracket("island.right", right)
-- Underlines after the island so they draw on top of its fill.
battery.underline()
agents.underline()

-- Apps island, left of the right island: Slack, Teams, Docker, Rancher
-- (hidden with its gap when none is installed).
require("items.apps")

-- Circles, left of the right island. On a notched display they move to
-- the left of the notch (items/notch.lua), nearest first.
local circles = { island.spacer("gap.cpu", "right", i.gap), (require("items.cpu")) }
if require("config").pilo.enabled then
  circles[#circles + 1] = island.spacer("gap.pilo", "right", i.gap)
  circles[#circles + 1] = (require("items.pilo"))
end
require("items.notch")(circles, #circles > 2 and "pilo" or "cpu", media)

-- macOS 27: clicking an empty part of the bar can raise the bar's own
-- window over the items (SketchyBar #850). A transparent bracket spanning
-- the bar takes that place. Only the two fixed end items are members.
sbar.add("bracket", "shield", { "bar.start", "clock.edge" }, {
  background = { drawing = true, color = theme.colors.transparent, height = i.height },
})

stats.start()
