local colors = require("colors")

return {
  name = "bluetooth",
  icon = "󰂯",
  update_freq = 30,
  command = "/usr/sbin/system_profiler SPBluetoothDataType",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    if output:match("State:%s+Off") then return "off" end
    if not output:match("State:%s+On") then return nil end
    if output:match("Connected:%s*\n%s+.-:%s*\n") then return "connected" end
    return "on"
  end,
  render = function(state)
    local color = colors.muted
    if state == "connected" then
      color = colors.blue
    elseif state == "on" then
      color = colors.fg
    end
    return { icon = { color = color }, label = { string = "" } }
  end,
  on_click = "/usr/bin/open x-apple.systempreferences:com.apple.BluetoothSettings",
}
