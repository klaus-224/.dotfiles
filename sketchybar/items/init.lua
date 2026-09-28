local pill = require("helpers.pill")

require("items.aerospace")

-- Right-side items are inserted right to left, so this declaration order
-- displays left to right.
local right_pills = {
  "battery",
  "spotify",
  "teams",
  "slack",
  "time",
  "date",
  "cpu",
  "memory",
}

for _, name in ipairs(right_pills) do
  pill.add(require("widgets." .. name), "right")
end
