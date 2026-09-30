local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")
local colors = require("colors")
local icons = require("icons")

local function parse(output)
  if type(output) ~= "string" then return nil end
  if not output:match("pid%s*=%s*%d+") then return nil end

  local label = output:match('"label"%s*=%s*"([^"]*)"') or ""
  if label == "" or label == "•" or label:match("^%d+$") then return label end
  return ""
end

local function render(label)
  return {
    icon = { color = label ~= nil and colors.red or colors.muted },
    label = { string = label or "" },
  }
end

local item = sbar.add("item", "widgets.slack", style.resolve({
  position = "right",
  icon = { string = "" },
  label = { string = "" },
}, settings.widgets, {
  icon = { string = icons.slack },
  update_freq = 10,
}))

local function refresh()
  sbar.exec('/bin/sh -c \'app="$1"; /usr/bin/lsappinfo info -only pid "$app"; '
    .. '/usr/bin/lsappinfo info -only StatusLabel "$app"\' _ "Slack"', function(output, exit_code)
    local label
    if exit_code == 0 then
      local ok, parsed = pcall(parse, output)
      if ok then label = parsed end
    end
    item:set(render(label))
  end)
end

item:subscribe({ "routine", "forced", "aerospace_workspace_change" }, refresh)
item:subscribe("mouse.clicked", function()
  sbar.exec('/usr/bin/open -a "Slack"')
end)
refresh()

sbar.add("bracket", "pill.slack", { "widgets.slack" }, style.resolve(settings.pill))

return item
