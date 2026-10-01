local sbar = require("sketchybar")
local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local function parse(output)
  if type(output) ~= "string" then return nil end
  local value = output:match("^%s*(.-)%s*$")
  return value ~= "" and value or nil
end

local function render(value)
  return { label = { string = value or "--" } }
end

sbar.add("item", "spacer.date", {
  position = "right",
  width = settings.group_paddings,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local item = sbar.add("item", "widgets.date", {
  position = "right",
  icon = { string = icons.date },
  label = { width = 78 },
  update_freq = 60,
})

local function refresh()
  sbar.exec("/bin/date '+%d %b %a'", function(output, exit_code)
    local state
    if exit_code == 0 then
      local ok, parsed = pcall(parse, output)
      if ok then state = parsed end
    end
    item:set(render(state))
  end)
end

item:subscribe({ "routine", "forced" }, refresh)
refresh()

sbar.add("bracket", "pill.date", { "widgets.date" }, {
  background = { color = colors.pill_bg },
})

return item
