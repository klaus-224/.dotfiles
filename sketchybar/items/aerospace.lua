local sbar = require("sketchybar")
local colors = require("colors")
local apple = require("items.apple")
local settings = require("settings")

local aerospace = "/opt/homebrew/bin/aerospace"
local workspaces = { "1", "2", "3", "4", "5" }

local displays = {}
local in_flight = false
local pending = false
local layout_ready = false
local anchor = "workspace.anchor"

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
        padding_right = 10,
      },
      background = {
        drawing = true,
        color = colors.transparent,
        corner_radius = 7,
        height = 22,
        border_width = 0,
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
    {
      blur_radius = settings.blur_radius,
      background = {
        drawing = true,
        color = colors.pill_bg,
      },
    }
  )

  return {
    workspaces = workspaces_by_name,
    decorations = { logo, separator, bracket },
  }
end

local function sync_displays()
  -- Build the layout from SketchyBar, even while AeroSpace is unavailable.
  local records = sbar.query("displays")
  if type(records) ~= "table" or #records == 0 then return end

  local active = {}
  local order = {}
  for _, record in ipairs(records) do
    if type(record) ~= "table" then return end
    local display = tonumber(record["arrangement-id"])
    if not display or display < 1 or display % 1 ~= 0 then return end
    if not active[display] then order[#order + 1] = display end
    active[display] = true
  end
  table.sort(order)

  for display, group in pairs(displays) do
    if not active[display] then
      for _, item in pairs(group.workspaces) do sbar.remove(item) end
      for _, item in ipairs(group.decorations) do sbar.remove(item) end
      displays[display] = nil
    end
  end

  local moves = {}
  for _, display in ipairs(order) do
    if not displays[display] then
      displays[display] = add_display(display)
      if layout_ready then
        -- New items append after the app pills; move the group before them.
        local names = { "workspace.logo." .. display, "workspace.separator." .. display }
        for _, workspace in ipairs(workspaces) do
          names[#names + 1] = "workspace." .. display .. "." .. workspace
        end
        for _, name in ipairs(names) do
          moves[#moves + 1] = "--move " .. quote(name) .. " before " .. quote(anchor)
        end
      end
    end
  end

  if #moves > 0 then
    -- Commit new items before a separate CLI process tries to move them.
    sbar.end_config()
    sbar.exec("sketchybar " .. table.concat(moves, " "))
  end
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
    local selected = active[display]
    for workspace, item in pairs(group.workspaces) do
      local highlighted = workspace == selected

      item:set({
        label = {
          color = highlighted and colors.purple or colors.fg,
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
  sync_displays()

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

-- Create workspace pills synchronously, before items/init.lua loads the apps.
sync_displays()
sbar.add("item", anchor, {
  position = "left",
  drawing = false,
  width = 0,
})
layout_ready = true

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
