-- Apple exposes per-display creation; AeroSpace owns the display lifecycle.
require("items.apple")
-- Register the custom event before Slack and Teams subscribe to it.
require("items.aerospace")

-- SketchyBar inserts right-side items from right to left, so this is the
-- reverse of their visual order. The optional items.clock is not loaded.
require("items.battery")
require("items.time")
require("items.date")
require("items.cpu")
require("items.memory")
require("items.spotify")
require("items.teams")
require("items.slack")
