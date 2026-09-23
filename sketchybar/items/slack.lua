local sbar = require("sketchybar")
local colors = require("colors")

local slack = sbar.add("item", "slack", {
  position = "right",
  update_freq = 10,
  updates = true,

  icon = {
    string = "󰒱",
    color = colors.yellow,
  },
  label = {
    string = "",
  },
})

local function update()
  sbar.exec('/usr/bin/lsappinfo info -only StatusLabel "Slack"',
    function(result, exit_code)
      if exit_code ~= 0 or type(result) ~= "string" then
        return
      end

      local label = result:match('"label"="([^"]*)"')
      if label == nil then
        return
      end

      local icon_color

      if label == "" then
        icon_color = colors.green -- Green: no badge
      elseif label == "•" then
        icon_color = colors.yellow -- Yellow: unread activity
      elseif label:match("^%d+$") then
        icon_color = colors.red -- Red: numbered badge
      else
        return
      end

      slack:set({
        icon = {
          string = "󰒱",
          color = icon_color,
        },
        label = {
          string = label,
        },
      })
    end
  )
end

slack:subscribe({ "routine", "forced", "system_woke" }, update)

slack:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Slack"')
end)

update()

return slack
