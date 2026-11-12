-- Left island, one per display: [  1 2 3 4 5  finder ]. AeroSpace only
-- supplies highlighting, so the islands exist even before it answers (or
-- when it fails). Displays are created and removed from SketchyBar's list.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local island = require("helpers.island")
local text = require("helpers.text")

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
-- Fixed front app width (pt) on a notched display, so switching apps does
-- not move the media island into the items left of the notch; nil = fit.
local app_width

local function quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function app_label()
  if not app_width then return { string = front_app, width = "dynamic" } end
  return { string = text.fit(front_app, app_width), width = app_width }
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
  app:set({ label = app_label() })
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

-- A display SketchyBar still lists after macOS dropped it (closing the lid
-- with an external display attached): arrangement-id 0, DirectDisplayID 0.
local function is_ghost(record)
  local display = tonumber(record["arrangement-id"])
  return not display or display < 1 or display % 1 ~= 0 or tonumber(record.DirectDisplayID) == 0
end

local function has_ghost(records)
  for _, record in ipairs(type(records) == "table" and records or {}) do
    if type(record) ~= "table" or is_ghost(record) then return true end
  end
  return false
end

-- SketchyBar keeps a bar window for the ghost, placed over the real display
-- with the old geometry: a second set of islands appears and that window
-- swallows clicks, so menus stop opening. Only a restart of the SketchyBar
-- process rebuilds its display list. Checked again after a pause (displays
-- settle a moment after wake or lid close) and at most once a minute.
local restart_scheduled = false
local function restart_if_ghost()
  if restart_scheduled or not config.service then return end
  restart_scheduled = true
  sbar.delay(3, function()
    restart_scheduled = false
    if not has_ghost(sbar.query("displays")) then return end
    local stamp = (os.getenv("HOME") or "") .. "/.cache/sketchybar/restart-stamp"
    local f = io.open(stamp, "r")
    local last = f and tonumber(f:read("l")) or 0
    if f then f:close() end
    if os.time() - last < 60 then return end
    os.execute("/bin/mkdir -p " .. quote(stamp:match("(.*)/")))
    f = io.open(stamp, "w")
    if f then f:write(os.time(), "\n"); f:close() end
    sbar.exec("/usr/bin/nohup /bin/launchctl kickstart -k " .. quote("gui/" .. config.uid .. "/" .. config.service)
      .. " >/dev/null 2>&1 &")
  end)
end

local function sync_displays()
  -- Build the layout from SketchyBar, even while AeroSpace is unavailable.
  local records = sbar.query("displays")
  if type(records) ~= "table" or #records == 0 then return end

  local active, order = {}, {}
  for _, record in ipairs(records) do
    if type(record) == "table" and not is_ghost(record) then
      local display = tonumber(record["arrangement-id"])
      if not active[display] then order[#order + 1] = display end
      active[display] = true
    end
  end
  if has_ghost(records) then restart_if_ghost() end
  if #order == 0 then return end
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
  for _, group in pairs(displays) do group.app:set({ label = app_label() }) end
end)
refresh()

local function set_app_width(w)
  app_width = w
  for _, group in pairs(displays) do group.app:set({ label = app_label() }) end
end

return { refresh = refresh, set_app_width = set_app_width }
