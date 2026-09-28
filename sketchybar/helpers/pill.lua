local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")
local widget = require("helpers.widget")

-- One pill per widget: the widget item plus the bracket that draws the pill
-- surface around it. The bracket is a separate surface from the item's own
-- `background`, so it is styled through `settings.pill` and an optional
-- per-widget `pill` table, never through the widget's `item` table.
local pill = {}

function pill.add(spec, position)
  local item = widget.add(spec, position or "right")

  sbar.add(
    "bracket",
    "pill." .. spec.name,
    { "widgets." .. spec.name },
    style.resolve(settings.pill, spec.pill)
  )

  return item
end

return pill
