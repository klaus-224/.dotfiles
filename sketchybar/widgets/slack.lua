local app_badge = require("helpers.app_badge")
local colors = require("colors")

return app_badge({
  name = "slack",
  app = "Slack",
  icon = "󰒱",
  color = colors.red,
  label_width = 22,
})
