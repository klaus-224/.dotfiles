local notifications = require("helpers.notifications")
local icons = require("icons")
local colors = require("colors")

return notifications.add("slack", "Slack", icons.slack, colors.red)
