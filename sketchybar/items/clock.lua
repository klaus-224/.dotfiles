local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")

local function parse(output)
  if type(output) ~= "string" then return nil end
  local value = output:match("^%s*(.-)%s*$")
  return value ~= "" and value or nil
end

local function render(value)
  return { label = { string = value or "" } }
end

local item = sbar.add("item", "widgets.clock", style.resolve({
  position = "right",
  icon = { string = "" },
  label = { string = "" },
}, settings.widgets, {
  update_freq = 30,
}))

local function refresh()
  sbar.exec("/bin/date '+%a %d %b %H:%M'", function(output, exit_code)
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

sbar.add("bracket", "pill.clock", { "widgets.clock" }, style.resolve(settings.pill))

return item
