local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local aerospace = "/opt/homebrew/bin/aerospace"
local workspaces = { "1", "2", "3", "4", "5" }

local displays = {}
local in_flight = false
local pending = false

local function quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function add_display(display)
  local items = {}

  for _, workspace in ipairs(workspaces) do
    local item = sbar.add("item", "workspace." .. display .. "." .. workspace, {
      display = display,
      position = "left",
      padding_left = settings.groups.item_padding_left,
      padding_right = settings.groups.item_padding_right,
      icon = { drawing = false },
      label = {
        string = workspace,
        padding_left = settings.groups.label_padding_left,
        padding_right = settings.groups.label_padding_right,
      },
      background = {
        drawing = true,
        color = colors.transparent,
        border_color = colors.yellow,
        border_width = settings.groups.background_border_width,
        corner_radius = settings.groups.background_corner_radius,
        height = settings.groups.background_height,
      },
    })

    item:subscribe("mouse.clicked", function()
      sbar.exec(quote(aerospace) .. " workspace " .. quote(workspace))
    end)

    items[workspace] = item
  end

  return items
end

local function apply_snapshot(records)
  local active = {}

  for _, record in ipairs(records) do
    if type(record) ~= "table" then return end

    local display = tonumber(record["monitor-appkit-nsscreen-screens-id"])
    if not display or display < 1 or type(record.workspace) ~= "string" then return end

    active[display] = record.workspace
  end

  for display, items in pairs(displays) do
    if active[display] == nil then
      for _, item in pairs(items) do
        sbar.remove(item)
      end
      displays[display] = nil
    end
  end

  for display, selected in pairs(active) do
    displays[display] = displays[display] or add_display(display)

    for workspace, item in pairs(displays[display]) do
      local highlighted = workspace == selected

      item:set({
        background = {
          color = highlighted and colors.yellow or colors.transparent,
        },
        label = {
          color = highlighted and colors.bg or colors.fg,
        },
      })
    end
  end
end

local refresh

refresh = function()
  if in_flight then
    pending = true
    return
  end

  in_flight = true

  sbar.exec(
    quote(aerospace)
      .. " list-workspaces --monitor all --visible --json"
      .. " --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}'",
    function(result, exit_code)
      in_flight = false

      if pending then
        pending = false
        refresh()
        return
      end

      if exit_code == 0 and type(result) == "table" then
        apply_snapshot(result)
      end
    end
  )
end

sbar.add("event", "aerospace_workspace_change")

local observer = sbar.add("item", "aerospace.observer", {
  drawing = false,
  update_freq = 10,
  updates = true,
})

observer:subscribe({
  "aerospace_workspace_change",
  "display_change",
  "system_woke",
  "routine",
  "forced",
}, refresh)

refresh()

return { refresh = refresh }
