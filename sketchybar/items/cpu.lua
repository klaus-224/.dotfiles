local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")
local colors = require("colors")
local icons = require("icons")

local function parse(output)
  if type(output) ~= "string" then return nil end
  local user = tonumber(output:match("([%d%.]+)%% user"))
  local system = tonumber(output:match("([%d%.]+)%% sys"))
  if not user or not system then return nil end
  return math.floor(user + system + 0.5)
end

local function render(usage)
  if not usage then
    return { icon = { color = colors.muted }, label = { string = "" } }
  end

  local color = colors.yellow
  if usage > 80 then
    color = colors.red
  elseif usage > 50 then
    color = colors.yellow
  end
  return { icon = { color = color }, label = { string = usage .. "%" } }
end

local item = sbar.add("item", "widgets.cpu", style.resolve({
  position = "right",
  icon = { string = "" },
  label = { string = "" },
}, settings.widgets, {
  icon = { string = icons.cpu },
  label = { width = 36 },
  update_freq = 3,
}))

local function refresh()
  sbar.exec("/usr/bin/top -l 2 -n 0 -s 1 | /usr/bin/grep 'CPU usage' | /usr/bin/tail -1", function(output, exit_code)
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

sbar.add("bracket", "pill.cpu", { "widgets.cpu" }, style.resolve(settings.pill))

return item
