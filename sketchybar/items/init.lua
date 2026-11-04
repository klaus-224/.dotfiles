-- Item order matters: left items are added left to right, the notch queue
-- (media island) from the notch outwards, and right items right to left.
local sbar = require("sketchybar")
local theme = require("theme")
local island = require("helpers.island")
local stats = require("helpers.stats")

local i = theme.island

-- Far-left anchor for the click shield below.
island.spacer("bar.start", "left", 0)

-- Left: one island per display (workspaces + front app).
require("items.aerospace")

-- Notch queue: the media island with Spotify and the volume.
require("items.media")

-- Right island: [slack teams · agent … · mem · bat · wifi · date time]
require("items.clock")
require("items.wifi")
local battery = require("items.battery")
require("items.memory")
local agents = require("items.agents")
-- Slack and Teams open the island (hidden when neither is installed).
local messaging = require("items.messaging")
local right = { "agents", "agents.claude", "agents.codex", "agents.opencode",
  "memory", "battery", "battery.1", "battery.2", "battery.3", "battery.4", "battery.5", "wifi", "clock", "clock.edge" }
for k, name in ipairs(messaging.members) do table.insert(right, k, name) end
island.bracket("island.right", right)
-- Underlines after the island so they draw on top of its fill.
battery.underline()
agents.underline()

-- Circles, left of the right island.
island.spacer("gap.cpu", "right", i.gap)
require("items.cpu")
if require("config").pilo.enabled then
  island.spacer("gap.pilo", "right", i.gap)
  require("items.pilo")
end

-- macOS 27: clicking an empty part of the bar can raise the bar's own
-- window over the items (SketchyBar #850). A transparent bracket spanning
-- the bar takes that place. Only the two fixed end items are members.
sbar.add("bracket", "shield", { "bar.start", "clock.edge" }, {
  background = { drawing = true, color = theme.colors.transparent, height = i.height },
})

stats.start()
