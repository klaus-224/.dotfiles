-- Cat circle: a pixel cat that runs faster as CPU load rises (0.6 s per
-- frame idle, 0.12 s at 80%+) and turns yellow when memory passes the warn
-- threshold. Menu SYSTEM: cpu, memory, disk, Activity Monitor.
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local pixels = require("helpers.pixels")
local stats = require("helpers.stats")
local ticker = require("helpers.ticker")

local c = theme.colors
local cat = island.circle("cpu", "right")

local cpu, mem = 0, 0
local frame = 1
local loop = ticker.every(function()
  if cpu >= 80 then return 0.12 end
  return 0.6 - cpu * 0.003
end, function()
  frame = frame % 4 + 1
  local warn = mem >= theme.thresholds.warn and "_warn" or ""
  cat:set({ background = { image = { string = pixels.path("cat_" .. frame .. warn), drawing = true } } })
end)
pixels.when_ready(loop.start)

local menu = popup.new(cat, { title = "SYSTEM", width = require("helpers.text").menu_width(33), underline = island.underline_circle(cat) })
local cpu_row = menu:row("cpu", { key = "cpu", value = "—" })
local mem_row = menu:row("mem", { key = "mem", value = "—" })
local ssd_row = menu:row("ssd", { key = "ssd", value = "—" })
menu:row("open", { key = "open", value = "Activity Monitor ↗", color = c.text2,
  on_click = function() helper.open("/System/Applications/Utilities/Activity Monitor.app") end })
menu:finish()
menu:bind({ cat })

stats.on(function(s)
  cpu = tonumber(s.cpu) or 0
  local m = s.memory or {}
  mem = tonumber(m.percent) or 0
  cpu_row:update({ value = cpu .. "%" .. (s.cores and ("  · " .. s.cores .. " cores") or ""),
                   color = cpu >= theme.thresholds.warn and c.warn or c.text })
  if m.total_gb then
    mem_row:update({ value = string.format("%d%%  %.1f/%dG", mem, m.used_gb, m.total_gb),
                     color = mem >= theme.thresholds.warn and c.warn or c.text })
  end
  local d = s.disk
  if type(d) == "table" then
    ssd_row:update({ value = string.format("%d / %d GB · %d free", d.used_gb, d.total_gb, d.free_gb) })
  end
end)

return cat
