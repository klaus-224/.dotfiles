local sbar = require("sketchybar")
local colors = require("colors")

local clock = sbar.add("item", "clock", {
  position = "right",
  update_freq = 30,
  label = { color = colors.fg },
})

local function update_clock()
  sbar.exec("/bin/date '+%H:%M'", function(time, exit_code)
    if exit_code ~= 0 or type(time) ~= "string" then
      return
    end

    time = time:match("^%s*(.-)%s*$")
    if time ~= "" then
      clock:set({ label = { string = time } })
    end
  end)
end

clock:subscribe({ "routine", "forced" }, update_clock)
update_clock()

return clock
