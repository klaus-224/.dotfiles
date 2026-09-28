local colors = require("colors")

return {
  name = "spotify",
  item = {
    icon = {
      string = "󰓇",
      color = colors.green,
    },
  },
  on_click = '/usr/bin/open -a "Spotify"',
}
