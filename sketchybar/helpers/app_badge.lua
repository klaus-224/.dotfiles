local colors = require("colors")

local function quote(value)
  return '"' .. value:gsub('"', '\\"') .. '"'
end

return function(options)
  return {
    name = options.name,
    icon = options.icon,
    update_freq = 30,
    command = '/usr/bin/lsappinfo info -only StatusLabel ' .. quote(options.app),
    events = { "routine", "forced", "aerospace_workspace_change" },
    parse = function(output)
      if type(output) ~= "string" then return nil end

      local label = output:match('"label"%s*=%s*"([^"]*)"')
      if label == "" or label == "•" or (label and label:match("^%d+$")) then
        return label
      end
      return nil
    end,
    render = function(label)
      return {
        icon = { color = label ~= nil and options.color or colors.muted },
        label = { string = label or "" },
      }
    end,
    on_click = '/usr/bin/open -a ' .. quote(options.app),
  }
end
