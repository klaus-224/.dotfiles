local config_dir = os.getenv("CONFIG_DIR")

if not config_dir or config_dir == "" then
  error("CONFIG_DIR is not set; start SketchyBar through sketchybarrc")
end

package.path = table.concat({
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
  config_dir .. "/?/?.lua",
  package.path,
}, ";")

local home = os.getenv("HOME")
if not home or home == "" then
  error("HOME is not set; cannot locate the SbarLua native module")
end

package.cpath = home .. "/.local/share/sketchybar_lua/?.so;" .. package.cpath

local loaded, sbar = pcall(require, "sketchybar")
if not loaded then
  error(
    "cannot load SbarLua from ~/.local/share/sketchybar_lua/sketchybar.so; "
    .. "install a Lua-compatible module before starting SketchyBar: "
    .. tostring(sbar)
  )
end

local pill = require("helpers.pill")

-- Right-side pills in insertion order. SketchyBar inserts right-side items from
-- right to left, so this is the reverse of the visual order.
local right_pills = {
  "battery",
  "time",
  "date",
  "cpu",
  "memory",
  "spotify",
  "teams",
  "slack",
}

sbar.begin_config()

sbar.bar(require("bar"))
sbar.default(require("defaults"))

-- AeroSpace is a self-contained dynamic integration and registers its custom
-- event, so it is loaded before the widgets that subscribe to it.
require("widgets.aerospace")

for _, name in ipairs(right_pills) do
  pill.add(require("widgets." .. name), "right")
end

sbar.hotload(true)
sbar.end_config()
sbar.event_loop()
