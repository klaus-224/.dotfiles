local colors = require("colors")

local function quote(value)
  return '"' .. value:gsub('"', '\\"') .. '"'
end

return function(options)
  return {
    name = options.name,
    icon = options.icon,
    label_width = options.label_width,
    update_freq = 30,
    command = '/bin/sh -c \'app="$1"; /usr/bin/lsappinfo info -only pid "$app"; '
      .. '/usr/bin/lsappinfo info -only StatusLabel "$app"\' _ ' .. quote(options.app),
    events = { "routine", "forced", "aerospace_workspace_change" },
    parse = function(output)
      if type(output) ~= "string" then return nil end

      if not output:match("pid%s*=%s*%d+") then return nil end

      local label = output:match('"label"%s*=%s*"([^"]*)"') or ""
      if label == "" or label == "•" or label:match("^%d+$") then return label end
      return ""
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
