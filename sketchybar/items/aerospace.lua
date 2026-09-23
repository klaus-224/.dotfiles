local sbar = require("sketchybar")
local colors = require("colors")

local aerospace = "/opt/homebrew/bin/aerospace"
local query_command = aerospace
  .. " list-workspaces --all --json --format '%{workspace}%{workspace-is-focused}'"

local items = {}
local order = {}
local focused_workspace = nil
local focus_generation = 0
local refresh_in_flight = false
local refresh_pending = false

local function normalize(value)
  if value == nil then
    return nil
  end
  return tostring(value)
end

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function selected_color(selected)
  if selected then
    return colors.lavender, colors.bg
  end
  return colors.transparent, colors.fg
end

local function apply_focus()
  for workspace, item in pairs(items) do
    local background, label = selected_color(workspace == focused_workspace)
    item:set({
      background = { color = background },
      label = { color = label },
    })
  end
end

local function same_order(next_order)
  if #order ~= #next_order then
    return false
  end
  for index, workspace in ipairs(order) do
    if workspace ~= next_order[index] then
      return false
    end
  end
  return true
end

local function add_workspace(workspace, index)
  local background, label = selected_color(workspace == focused_workspace)
  local item = sbar.add("item", "workspace." .. index, {
    position = "left",
    icon = { drawing = false },
    label = {
      string = workspace,
      color = label,
    },
    background = {
      drawing = true,
      color = background,
      corner_radius = 6,
      height = 24,
    },
  })

  item:subscribe("mouse.clicked", function()
    sbar.exec(aerospace .. " workspace -- " .. shell_quote(workspace))
  end)

  return item
end

local function reconcile(next_order)
  if same_order(next_order) then
    apply_focus()
    return
  end

  for _, item in pairs(items) do
    sbar.remove(item)
  end

  items = {}
  order = next_order

  for index, workspace in ipairs(order) do
    items[workspace] = add_workspace(workspace, index)
  end
end

local function parse_snapshot(result)
  if type(result) ~= "table" then
    return nil
  end

  local next_order = {}
  local seen = {}
  local snapshot_focus = nil

  for index, record in ipairs(result) do
    if type(record) ~= "table" then
      return nil
    end

    local workspace = normalize(record.workspace)
    if not workspace or workspace == "" or seen[workspace] then
      return nil
    end

    seen[workspace] = true
    next_order[index] = workspace

    local is_focused = record["workspace-is-focused"]
    if is_focused == true or normalize(is_focused) == "true" then
      snapshot_focus = workspace
    end
  end

  return next_order, snapshot_focus
end

local refresh

local function finish_refresh()
  refresh_in_flight = false
  if refresh_pending then
    refresh_pending = false
    refresh()
  end
end

refresh = function()
  if refresh_in_flight then
    refresh_pending = true
    return
  end

  refresh_in_flight = true
  local request_generation = focus_generation

  sbar.exec(query_command, function(result, exit_code)
    if exit_code == 0 then
      local next_order, snapshot_focus = parse_snapshot(result)
      if next_order then
        if request_generation == focus_generation then
          focused_workspace = snapshot_focus
        end
        reconcile(next_order)
      end
    end

    finish_refresh()
  end)
end

sbar.add("event", "aerospace_workspace_change")

local observer = sbar.add("item", "aerospace.observer", {
  position = "left",
  drawing = false,
  update_freq = 10,
  updates = true,
})

observer:subscribe({ "routine", "forced", "aerospace_workspace_change" }, function(env)
  if env.SENDER == "aerospace_workspace_change" then
    focused_workspace = normalize(env.FOCUSED_WORKSPACE)
    focus_generation = focus_generation + 1
    apply_focus()
  end
  refresh()
end)

refresh()

return {
  refresh = refresh,
}
