local colors = require("colors")

-- The single source of shared styling. Every table below holds native
-- SketchyBar properties in SbarLua's nested form, so a dotted property such as
-- `label.font.size` is written as `label = { font = { size = ... } }`.
--
-- The visual values here are a deliberate approximation of a reference
-- screenshot: compact rounded dark pills, light monospaced labels, pale cyan
-- default icons, and a warm active-workspace highlight. They were chosen by eye
-- rather than recovered from the reference configuration.
return {
  -- Applied through `sbar.default`, so every item created afterwards inherits
  -- these values, including the AeroSpace workspace items.
  defaults = {
    icon = {
      color = colors.cyan,
      font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
      padding_left = 0,
      padding_right = 0,
      align = "center",
    },
    label = {
      color = colors.fg,
      font = { family = "Hack Nerd Font", style = "Regular", size = 14.0 },
      padding_left = 0,
      padding_right = 0,
      align = "center",
    },
  },

  -- Shared properties for right-side items under `items/`. Applied after the
  -- inherited defaults and before each item's own properties.
  widgets = {
    padding_left = 8,
    padding_right = 0,
    icon = {
      padding_left = 8,
      padding_right = 4,
      y_offset = 0,
    },
    label = {
      padding_left = 0,
      padding_right = 8,
      y_offset = 0,
    },
  },

  -- Bracket properties for the pill surface drawn around a widget. This is a
  -- different surface from an item's own `background`.
  pill = {
    background = {
      color = colors.pill_bg,
      border_color = colors.pill_border,
      border_width = 0,
      corner_radius = 12,
      height = 28,
    },
  },

  bar = {
    height = 40,
    padding_left = 8,
    padding_right = 8,
  },

  -- Geometry for the AeroSpace workspace buttons only.
  groups = {
    item_padding_left = 1,
    item_padding_right = 1,
    label_padding_left = 7,
    label_padding_right = 7,
    background_height = 22,
    background_corner_radius = 7,
  },
}
