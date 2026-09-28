local colors = require("colors")

return {
  name = "spotify",
  item = {
    icon = {
      string = "󰓇",
      color = colors.green,
      -- Icon-only pill: no gap is needed between the icon and a hidden label.
      padding_right = 0,
    },
    label = { drawing = false },
  },
  on_click = '/usr/bin/open -a "Spotify"',
}
