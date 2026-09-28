local colors = require("colors")

return {
  name = "spotify",
  item = {
    icon = {
      string = "󰓇",
      color = colors.green,
      -- Icon-only pill: mirror the shared left inset instead of the gap that
      -- would sit between an icon and a label.
      padding_right = 8,
    },
    label = { drawing = false },
  },
  on_click = '/usr/bin/open -a "Spotify"',
}
