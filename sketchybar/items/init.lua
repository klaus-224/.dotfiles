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
local aerospace = require("items.aerospace")

-- Media island with Spotify and the volume, after the AeroSpace island.
local media = (require("items.media"))

-- Right island: [agent … · mem · bat · wifi · date time]
require("items.clock")
require("items.wifi")
local battery = require("items.battery")
local memory = require("items.memory")
local agents = require("items.agents")
local rest = { "memory", "battery", "battery.1", "battery.2", "battery.3", "battery.4", "battery.5", "wifi", "clock", "clock.edge" }
local right = { table.unpack(agents.cells) }
for _, name in ipairs(rest) do right[#right + 1] = name end
local right_island = island.bracket("island.right", right)
-- With a notch the agent cells become their own island left of it
-- (items/notch.lua); these two islands replace the right island then.
local agents_island = island.bracket("island.agents", agents.cells)
local rest_island = island.bracket("island.rest", rest)
agents_island:set({ background = { drawing = false } })
rest_island:set({ background = { drawing = false } })
-- Underlines after the island so they draw on top of its fill.
battery.underline()
agents.underline()

-- Apps island, left of the right island: Slack, Teams, Docker, Rancher
-- (hidden with its gap when none is installed).
require("items.apps")

-- Circles, left of the right island.
island.spacer("gap.cpu", "right", i.gap)
require("items.cpu")
if require("config").pilo.enabled then
  island.spacer("gap.pilo", "right", i.gap)
  require("items.pilo")
end

-- On a notched display the agents island moves left of the notch.
require("items.notch")({
  queue = agents.items,
  outer = "island.agents", -- the island: an item rect leaves out its padding
  media = media,
  on_change = function(on)
    right_island:set({ background = { drawing = not on } })
    agents_island:set({ background = { drawing = on } })
    rest_island:set({ background = { drawing = on } })
    agents.edge:set({ width = on and i.inner or 0 })
    memory:set({ padding_left = on and i.inner or i.cell_gap })
    aerospace.set_app_width(on and math.ceil(theme.front_app.notch_chars * theme.font.char_width) or nil)
  end,
})

-- macOS 27: clicking an empty part of the bar can raise the bar's own
-- window over the items (SketchyBar #850). A transparent bracket spanning
-- the bar takes that place. Only the two fixed end items are members.
sbar.add("bracket", "shield", { "bar.start", "clock.edge" }, {
  background = { drawing = true, color = theme.colors.transparent, height = i.height },
})

stats.start()
