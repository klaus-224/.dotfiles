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

sbar.begin_config()

require("bar")
require("items.aerospace")
require("items.clock")

sbar.end_config()
sbar.event_loop()
