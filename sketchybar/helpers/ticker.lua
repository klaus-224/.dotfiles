-- Sub-second loops (cat frames, EQ bars) on SbarLua's timer. `interval`
-- may be a function so the speed can follow live data.
local sbar = require("sketchybar")

local ticker = {}

function ticker.every(interval, fn)
  local loop = { running = false, generation = 0 }
  local function step(generation)
    -- A stop followed by a start bumps the generation, so a timer left over
    -- from the earlier run ends instead of doubling the speed.
    if not loop.running or generation ~= loop.generation then return end
    fn()
    local wait = type(interval) == "function" and interval() or interval
    sbar.delay(wait, function() step(generation) end)
  end
  function loop.start()
    if loop.running then return end
    loop.running = true
    loop.generation = loop.generation + 1
    step(loop.generation)
  end
  function loop.stop() loop.running = false end
  return loop
end

return ticker
