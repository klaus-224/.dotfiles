local sbar = require("sketchybar")
local colors = require("colors")

local icon = "󰒱"

local slack = sbar.add("item", "widgets.slack", {
  position = "right",
  icon = {
    string = icon,
    color = colors.muted,
  },
  label = { string = "" },
  update_freq = 30,
})

local function set_unavailable()
  slack:set({
    icon = { color = colors.muted },
    label = { string = "" },
  })
end

local function refresh()
  sbar.exec('/usr/bin/lsappinfo info -only StatusLabel "Slack"', function(status_info, exit_code)
    if exit_code ~= 0 or type(status_info) ~= "string" then
      set_unavailable()
      return
    end

    local label = status_info:match('"label"%s*=%s*"([^"]*)"')
    if label == nil then
      set_unavailable()
      return
    end

    local icon_color
    if label == "" then
      icon_color = colors.green
    elseif label == "•" then
      icon_color = colors.yellow
    elseif label:match("^%d+$") then
      icon_color = colors.red
    else
      set_unavailable()
      return
    end

    slack:set({
      icon = { color = icon_color },
      label = { string = label },
    })
  end)
end

slack:subscribe({ "routine", "forced", "aerospace_workspace_change" }, refresh)

slack:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Slack"')
end)

refresh()

return slack
