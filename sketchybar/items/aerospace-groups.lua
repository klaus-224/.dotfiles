local sbar = require("sketchybar")
local colors = require("colors")

local aerospace = "/opt/homebrew/bin/aerospace"
local script = os.getenv("HOME") .. "/.dotfiles/scripts/aerospace-groups.sh"
local groups = {
  { id = "code", label = "Code" },
  { id = "browse", label = "Browse" },
  { id = "music", label = "Music" },
  { id = "slack", label = "Slack" },
  { id = "discord", label = "Discord" },
  { id = "teams", label = "Teams" },
}
local workspace_groups = {
  ["code-main"] = "code", ["code-secondary"] = "code",
  ["browse-main"] = "browse", ["browse-secondary"] = "browse",
  music = "music", slack = "slack", discord = "discord",
  teams = "teams", ["teams-call"] = "teams",
}
local displays = {}
local in_flight = false
local pending = false

local function quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function add_display(display)
  local items = {}
  for _, group in ipairs(groups) do
    local group_id = group.id
    local item = sbar.add("item", "group." .. display .. "." .. group_id, {
      display = display,
      position = "left",
      padding_left = 3,
      padding_right = 3,
      icon = { drawing = false },
      label = { string = group.label, color = colors.fg, padding_left = 8, padding_right = 8 },
      background = {
        drawing = true, color = colors.transparent,
        border_color = colors.lavender, border_width = 1,
        corner_radius = 6, height = 24,
      },
    })
    item:subscribe("mouse.clicked", function()
      sbar.exec("/bin/bash " .. quote(script) .. " " .. quote(group_id), function(_, exit_code)
        if exit_code ~= 0 then
          print("aerospace-group failed for " .. group_id .. "; run it in a terminal for details")
        end
      end)
    end)
    items[group_id] = item
  end
  return items
end

local function apply_snapshot(records)
  local active = {}
  -- Validate before changing the bar; failed queries preserve existing items.
  for _, record in ipairs(records) do
    if type(record) ~= "table" then return end
    local display = tonumber(record["monitor-appkit-nsscreen-screens-id"])
    if not display or display < 1 or type(record.workspace) ~= "string" then return end
    active[display] = workspace_groups[record.workspace] or false
  end
  for display, items in pairs(displays) do
    if active[display] == nil then
      for _, item in pairs(items) do sbar.remove(item) end
      displays[display] = nil
    end
  end
  for display, selected in pairs(active) do
    displays[display] = displays[display] or add_display(display)
    for group_id, item in pairs(displays[display]) do
      local highlighted = group_id == selected
      item:set({
        background = { color = highlighted and colors.lavender or colors.transparent },
        label = { color = highlighted and colors.bg or colors.fg },
      })
    end
  end
end

local refresh
refresh = function()
  if in_flight then pending = true; return end
  in_flight = true
  sbar.exec(quote(aerospace)
    .. " list-workspaces --monitor all --visible --json"
    .. " --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}'",
    function(result, exit_code)
      in_flight = false
      if pending then
        -- An event arrived during the query: discard this older snapshot.
        pending = false
        refresh()
        return
      end
      if exit_code == 0 and type(result) == "table" then apply_snapshot(result) end
    end)
end

sbar.add("event", "aerospace_workspace_change")
local observer = sbar.add("item", "aerospace.observer", {
  drawing = false, update_freq = 10, updates = true,
})
observer:subscribe({
  "aerospace_workspace_change", "display_change", "system_woke", "routine", "forced",
}, refresh)
refresh()

return { refresh = refresh }
