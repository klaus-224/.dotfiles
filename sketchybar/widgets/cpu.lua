local colors = require("colors")

return {
  name = "cpu",
  icon = "󰍛",
  update_freq = 3,
  command = "/usr/bin/top -l 2 -n 0 -s 1 | /usr/bin/grep 'CPU usage' | /usr/bin/tail -1",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    local user = tonumber(output:match("([%d%.]+)%% user"))
    local system = tonumber(output:match("([%d%.]+)%% sys"))
    if not user or not system then return nil end
    return math.floor(user + system + 0.5)
  end,
  render = function(usage)
    if not usage then
      return { icon = { color = colors.muted }, label = { string = "" } }
    end

    local color = colors.yellow
    if usage > 80 then
      color = colors.red
    elseif usage > 50 then
      color = colors.yellow
    end
    return { icon = { color = color }, label = { string = usage .. "%" } }
  end,
}
