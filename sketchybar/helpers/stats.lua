-- One `sbar-helper system` poll (CPU, memory, disk, battery) shared by the
-- cat circle, the memory cell and the battery cell.
local sbar = require("sketchybar")
local helper = require("helpers.helper")

local stats = { latest = nil }
local listeners = {}

function stats.on(fn)
  listeners[#listeners + 1] = fn
  if stats.latest then fn(stats.latest) end
end

local refresh = helper.single(function(done)
  helper.run({ "system" }, function(r)
    done()
    if r.error then return end
    stats.latest = r
    for _, fn in ipairs(listeners) do fn(r) end
  end)
end)
stats.refresh = refresh

function stats.start()
  local poller = sbar.add("item", "stats.poller", { drawing = false, updates = true, update_freq = 3 })
  poller:subscribe({ "routine", "forced", "system_woke", "power_source_change" }, refresh)
  refresh()
end

return stats
