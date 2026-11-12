local config_dir = os.getenv("CONFIG_DIR")

if not config_dir or config_dir == "" then
  error("CONFIG_DIR is not set; start SketchyBar through sketchybarrc")
end

package.path = table.concat({
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
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

local theme = require("theme")
local island = require("helpers.island")
local c = theme.colors

sbar.begin_config()

-- Bound to locals: since Lua 5.4 a first `require` also returns loader
-- data, which SbarLua would reject as an extra argument.
local bar = {
  position = "top",
  height = theme.bar.height,
  margin = theme.bar.margin,
  y_offset = theme.bar.y_offset,
  display = theme.bar.display,
  topmost = theme.bar.topmost,
  color = c.transparent,
  border_width = 0,
  corner_radius = 0,
  blur_radius = 0,
  shadow = false,
  padding_left = 0,
  padding_right = 0,
  font_smoothing = true,
}
sbar.bar(bar)

local defaults = {
  updates = "when_shown",
  padding_left = 0,
  padding_right = 0,
  icon = { font = island.font(), color = c.text3, padding_left = 0, padding_right = 0 },
  label = { font = island.font(), color = c.text, padding_left = 0, padding_right = 0 },
  background = { corner_radius = 0, border_width = 0 },
}
sbar.default(defaults)

require("items")

sbar.hotload(true)
sbar.end_config()
sbar.event_loop()
