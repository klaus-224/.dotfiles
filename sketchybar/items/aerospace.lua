local sbar = require("sketchybar")
local colors = require("colors")
local apple = require("items.apple")

local aerospace = "/opt/homebrew/bin/aerospace"
local workspaces = { "1", "2", "3", "4", "5" }

local displays = {}
local in_flight = false
local pending = false

local function quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function add_display(display)
  local workspaces_by_name = {}
  local members = {}

  local logo = apple.add(display)
  members[#members + 1] = "workspace.logo." .. display

  local separator = sbar.add("item", "workspace.separator." .. display, {
    display = display,
    position = "left",
    width = 1,
    padding_left = 0,
    padding_right = 5,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = true,
      color = colors.separator,
      height = 16,
      corner_radius = 0,
    },
  })
  members[#members + 1] = "workspace.separator." .. display

  for _, workspace in ipairs(workspaces) do
    local item = sbar.add("item", "workspace." .. display .. "." .. workspace, {
      display = display,
      position = "left",
      padding_left = 1,
      padding_right = 1,
      icon = { drawing = false },
      label = {
        string = workspace,
        padding_left = 7,
        padding_right = 7,
      },
      background = {
        drawing = true,
        color = colors.transparent,
        corner_radius = 7,
        height = 22,
      },
    })

    item:subscribe("mouse.clicked", function()
      sbar.exec(quote(aerospace) .. " workspace " .. quote(workspace))
    end)

    workspaces_by_name[workspace] = item
    members[#members + 1] = "workspace." .. display .. "." .. workspace
  end

  local bracket = sbar.add(
    "bracket",
    "workspace.bracket." .. display,
    members,
    { background = { color = colors.pill_bg } }
  )

  return {
    workspaces = workspaces_by_name,
    decorations = { logo, separator, bracket },
  }
end

local function apply_snapshot(records)
  local active = {}

  for _, record in ipairs(records) do
    if type(record) ~= "table" then return end

    local display = tonumber(record["monitor-appkit-nsscreen-screens-id"])
    if not display or display < 1 or type(record.workspace) ~= "string" then return end

    active[display] = record.workspace
  end

  for display, group in pairs(displays) do
    if active[display] == nil then
      for _, item in pairs(group.workspaces) do
        sbar.remove(item)
      end
      for _, item in ipairs(group.decorations) do sbar.remove(item) end
      displays[display] = nil
    end
  end

  for display, selected in pairs(active) do
    displays[display] = displays[display] or add_display(display)

    for workspace, item in pairs(displays[display].workspaces) do
      local highlighted = workspace == selected

      item:set({
        background = {
          color = highlighted and colors.yellow or colors.transparent,
        },
        label = {
          color = highlighted and colors.bg or colors.muted,
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
