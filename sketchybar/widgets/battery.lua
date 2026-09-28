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
  end,
}
