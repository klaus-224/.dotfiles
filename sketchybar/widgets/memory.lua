local colors = require("colors")

return {
  name = "memory",
  item = {
    icon = { string = "󰍛" },
    label = { width = 36 },
  },
  update_freq = 10,
  command = "/usr/bin/memory_pressure",
  parse = function(output)
    if type(output) ~= "string" then return nil end
    local free = tonumber(output:match("free percentage:%s*(%d+)%%"))
    if not free then return nil end
    return 100 - free
  end,
  render = function(used)
    if not used then
      return { icon = { color = colors.muted }, label = { string = "--%" } }
    end

    local color = colors.green
    if used > 80 then
      color = colors.red
    elseif used > 60 then
      color = colors.yellow
    end

    return {
      icon = { color = color },
      label = { string = used .. "%" },
    }
  end,
}
