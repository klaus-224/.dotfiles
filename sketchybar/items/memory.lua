local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")
local colors = require("colors")
local icons = require("icons")

local function parse(output)
  if type(output) ~= "string" then return nil end
  local free = tonumber(output:match("free percentage:%s*(%d+)%%"))
  if not free then return nil end
  return 100 - free
end

local function render(used)
  if not used then
    return { icon = { color = colors.muted }, label = { string = "--%" } }
  end

  local color = colors.green
  if used > 80 then
    color = colors.red
  elseif used > 60 then
    color = colors.yellow
  end

  return {
    icon = { color = color },
    label = { string = used .. "%" },
  }
end

local item = sbar.add("item", "widgets.memory", style.resolve({
  position = "right",
  icon = { string = "" },
  label = { string = "" },
}, settings.widgets, {
  icon = { string = icons.memory },
  label = { width = 36 },
  update_freq = 10,
}))

local function refresh()
  sbar.exec("/usr/bin/memory_pressure", function(output, exit_code)
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

sbar.add("bracket", "pill.memory", { "widgets.memory" }, style.resolve(settings.pill))

return item
