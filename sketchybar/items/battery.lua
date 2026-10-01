local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons").battery

local function parse(output)
  if type(output) ~= "string" then return nil end
  local percentage = tonumber(output:match("(%d+)%%"))
  if not percentage then return nil end
  return {
    percentage = percentage,
    charging = output:find("AC Power", 1, true) ~= nil
      or output:find("charging", 1, true) ~= nil,
  }
end

local function render(state)
  if not state then
    return { icon = { string = icons.empty, color = colors.muted }, label = { string = "" } }
  end

  local icon = icons.full
  local color = colors.fg
  if state.charging then
    icon = icons.charging
    color = colors.green
  elseif state.percentage <= 10 then
    icon = icons.empty
    color = colors.red
  elseif state.percentage <= 30 then
    icon = icons.low
    color = colors.red
  elseif state.percentage <= 60 then
    icon = icons.medium
    color = colors.yellow
  elseif state.percentage <= 90 then
    icon = icons.high
    color = colors.green
  end

  return {
    icon = { string = icon, color = color },
    label = { string = state.percentage .. "%" },
  }
end

local item = sbar.add("item", "widgets.battery", {
  position = "right",
  icon = { string = icons.empty },
  label = { width = 36 },
  update_freq = 120,
})

local function refresh()
  sbar.exec("/usr/bin/pmset -g batt", function(output, exit_code)
    local state
    if exit_code == 0 then
      local ok, parsed = pcall(parse, output)
      if ok then state = parsed end
    end
    item:set(render(state))
  end)
end

item:subscribe({ "routine", "forced", "power_source_change", "system_woke" }, refresh)
refresh()

sbar.add("bracket", "pill.battery", { "widgets.battery" }, {
  background = { color = colors.pill_bg },
})

return item
