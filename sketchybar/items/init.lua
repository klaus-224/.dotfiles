require("items.aerospace-groups")

local group = require("helpers.group")

-- Each group added on the right is placed to the left of the previous group.
group.add("clock", { (require("widgets.clock")) })
group.add("metrics", {
  (require("widgets.cpu")),
  (require("widgets.battery")),
  (require("widgets.wifi")),
  (require("widgets.bluetooth")),
})
group.add("socials", {
  (require("widgets.slack")),
  (require("widgets.teams")),
})
