-- Left island, one per display: [  1 2 3 4 5  finder ]. AeroSpace only
-- supplies highlighting, so the islands exist even before it answers (or
-- when it fails). Displays are created and removed from SketchyBar's list.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local island = require("helpers.island")

local c = theme.colors
local i = theme.island
local aerospace = config.aerospace
local workspaces = config.workspaces

local displays = {}
local in_flight = false
local pending = false
local layout_ready = false
local anchor = "workspace.anchor"
local front_app = ""

local function quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function add_display(display)
  local by_name, members, decorations = {}, {}, {}

  local logo = sbar.add("item", "workspace.logo." .. display, {
    display = display,
    position = "left",
    padding_left = i.inner,
    padding_right = 8,
    icon = { string = config.logo, color = c.text, font = island.font("Regular", theme.font.size + 2, theme.font.icons),
             padding_left = 0, padding_right = 0 },
    label = { drawing = false },
  })
  members[#members + 1] = logo.name
  decorations[#decorations + 1] = logo

  for _, workspace in ipairs(workspaces) do
    local item = sbar.add("item", "workspace." .. display .. "." .. workspace, {
      display = display,
      position = "left",
      padding_left = 1,
      padding_right = 1,
      icon = { drawing = false },
      label = { string = workspace, color = c.text3, padding_left = 7, padding_right = 7 },
      background = { drawing = true, color = c.transparent, corner_radius = 7, height = i.height - 12, border_width = 0 },
    })
    item:subscribe("mouse.clicked", function()
      sbar.exec(quote(aerospace) .. " workspace " .. quote(workspace))
    end)
    by_name[workspace] = item
    members[#members + 1] = item.name
  end

  local app = sbar.add("item", "front_app." .. display, {
    display = display,
    position = "left",
    padding_left = 8,
    padding_right = i.inner,
    icon = { drawing = false },
    label = { string = front_app, color = c.text2, padding_left = 0, padding_right = 0 },
  })
  members[#members + 1] = app.name
  decorations[#decorations + 1] = app

  decorations[#decorations + 1] = island.bracket("island.left." .. display, members)
  return { workspaces = by_name, decorations = decorations, app = app }
end

local function item_names(display)
  local names = { "workspace.logo." .. display }
  for _, workspace in ipairs(workspaces) do names[#names + 1] = "workspace." .. display .. "." .. workspace end
  names[#names + 1] = "front_app." .. display
  return names
end

local function sync_displays()
  -- Build the layout from SketchyBar, even while AeroSpace is unavailable.
  local records = sbar.query("displays")
  if type(records) ~= "table" or #records == 0 then return end

  local active, order = {}, {}
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
        -- New items append after the other left items; move them before.
        for _, name in ipairs(item_names(display)) do
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
      local on = workspace == selected
      item:set({
        label = { color = on and c.text or c.text3 },
        background = { color = on and c.line2 or c.transparent },
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
      if exit_code == 0 and type(result) == "table" then apply_snapshot(result) end
    end
  )
end

-- Create the islands synchronously, before the other left items load.
sync_displays()
sbar.add("item", anchor, { position = "left", drawing = false, width = 0 })
layout_ready = true

sbar.add("event", "aerospace_workspace_change")
local observer = sbar.add("item", "aerospace.observer", { drawing = false, update_freq = 10, updates = true })
observer:subscribe({ "aerospace_workspace_change", "display_change", "system_woke", "routine", "forced" }, refresh)
observer:subscribe("front_app_switched", function(env)
  front_app = (env.INFO or ""):lower()
  for _, group in pairs(displays) do group.app:set({ label = { string = front_app } }) end
end)
refresh()

return { refresh = refresh }
