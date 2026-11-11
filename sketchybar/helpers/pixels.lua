-- Pixel-art PNGs (cat, pilo faces) rendered by `sbar-helper pixels` in the
-- theme colours into ~/.cache/sketchybar/px. Callbacks run once ready.
local helper = require("helpers.helper")
local theme = require("theme")

local c = theme.colors
local pixels = { dir = (os.getenv("HOME") or "") .. "/.cache/sketchybar/px", ready = false }
local waiting = {}

function pixels.path(name) return pixels.dir .. "/" .. name .. ".png" end

function pixels.when_ready(fn)
  if pixels.ready then fn() else waiting[#waiting + 1] = fn end
end

local function hex(v) return string.format("0x%08x", v) end

helper.run({
  "pixels", pixels.dir,
  "text=" .. hex(c.text), "muted=" .. hex(c.text3), "warn=" .. hex(c.warn), "err=" .. hex(c.err),
  "done=" .. hex(c.accent), "blade=" .. hex(theme.cat.blade), "ground=" .. hex(theme.cat.ground),
}, function(r)
  if r.error then return end
  pixels.ready = true
  for _, fn in ipairs(waiting) do fn() end
  waiting = {}
end)

return pixels
