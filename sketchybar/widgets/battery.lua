local colors = require("colors")

local icons = {
  empty = "󰂎",
  low = "󰁺",
  medium = "󰁾",
  high = "󰂀",
  full = "󰁹",
  charging = "󰂄",
}

return {
  name = "battery",
  icon = icons.empty,
  update_freq = 120,
  events = { "routine", "forced", "power_source_change", "system_woke" },
  command = "/usr/bin/pmset -g batt",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    local percentage = tonumber(output:match("(%d+)%%"))
    if not percentage then return nil end
    return {
      percentage = percentage,
      charging = output:find("AC Power", 1, true) ~= nil
        or output:find("charging", 1, true) ~= nil,
    }
  end,
  render = function(state)
    if not state then
      return { icon = { string = icons.empty, color = colors.muted }, label = { string = "" } }
    end

    local icon = icons.full
    if state.charging then
      icon = icons.charging
    elseif state.percentage <= 10 then
      icon = icons.empty
    elseif state.percentage <= 30 then
      icon = icons.low
    elseif state.percentage <= 60 then
      icon = icons.medium
    elseif state.percentage <= 90 then
      icon = icons.high
    end

    local color = colors.fg
    if state.percentage <= 20 then
      color = colors.red
    elseif state.percentage <= 40 then
      color = colors.yellow
    end
    return {
      icon = { string = icon, color = color },
      label = { string = state.percentage .. "%" },
    }
  end,
}
