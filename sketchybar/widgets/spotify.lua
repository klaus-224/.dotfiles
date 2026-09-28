local colors = require("colors")

return {
  name = "spotify",
  icon = "󰓇",
  item = {
    icon = { color = colors.green },
    label = { drawing = false },
  },
  on_click = '/usr/bin/open -a "Spotify"',
}
