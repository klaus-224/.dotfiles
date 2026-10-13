-- Run from the repository root: CONFIG_DIR="$PWD/sketchybar" lua sketchybar/tests/layout.lua
local root = os.getenv("SKETCHYBAR_TEST_CONFIG") or "sketchybar"
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local items, order, callbacks = {}, {}, {}
local display_list = { { ["arrangement-id"] = 1 }, { ["arrangement-id"] = 2 } }
local committed = {}
local sbar = {}

local function merge(target, values)
  for key, value in pairs(values) do
    if type(value) == "table" then
      if type(target[key]) ~= "table" then target[key] = {} end
      merge(target[key], value)
    else
      target[key] = value
    end
  end
end

function sbar.add(kind, name, properties, bracket_properties)
  if kind == "event" then return end
  assert(not items[name], "duplicate item " .. name)
  local item = { name = name, properties = {}, handlers = {}, kind = kind }
  merge(item.properties, bracket_properties or properties)
  function item:set(values) merge(self.properties, values) end
  function item:subscribe(events, handler)
    if type(events) == "string" then events = { events } end
    for _, event in ipairs(events) do self.handlers[event] = handler end
  end
  items[name] = item
  order[#order + 1] = name
  return item
end

function sbar.remove(item)
  items[item.name] = nil
  for i, name in ipairs(order) do
    if name == item.name then table.remove(order, i); break end
  end
end

function sbar.end_config()
  for name in pairs(items) do committed[name] = true end
end
function sbar.query(domain)
  assert(domain == "displays")
  sbar.end_config()
  return display_list
end
function sbar.exec(command, callback)
  if command:find("list-workspaces", 1, true) then
    callbacks[#callbacks + 1] = callback
  elseif command:find("--move", 1, true) then
    for name, anchor in command:gmatch("%-%-move '([^']+)' before '([^']+)'") do
      assert(committed[name] and committed[anchor], "move before item creation was committed")
      for i, current in ipairs(order) do
        if current == name then table.remove(order, i); break end
      end
      for i, current in ipairs(order) do
        if current == anchor then table.insert(order, i, name); break end
      end
    end
  end
end
function sbar.default() end
function sbar.bar() end
function sbar.begin_config() end
function sbar.hotload() end
function sbar.event_loop() end
package.loaded.sketchybar = sbar

require("items")
sbar.end_config()
local function check_layout(display)
  local left, right = {}, {}
  for _, name in ipairs(order) do
    local item = items[name]
    local p = item.properties
    if item.kind == "item" and p.drawing ~= false and not name:match("^spacer%.")
      and (not p.display or p.display == display) then
      if p.position == "left" then left[#left + 1] = name end
      if p.position == "right" then table.insert(right, 1, name) end
    end
  end
  local expected = { "workspace.logo." .. display, "workspace.separator." .. display }
  for i = 1, 5 do expected[#expected + 1] = "workspace." .. display .. "." .. i end
  for _, app in ipairs({ "spotify", "slack", "teams" }) do expected[#expected + 1] = "widgets." .. app end
  assert(table.concat(left, ",") == table.concat(expected, ","), "unexpected left layout: " .. table.concat(left, ","))
  assert(table.concat(right, ",") == "widgets.wifi,widgets.bluetooth,widgets.memory,widgets.cpu,widgets.date,widgets.time,widgets.battery", "unexpected right layout")
end
local function complete(result, code)
  assert(#callbacks > 0, "missing pending AeroSpace request")
  table.remove(callbacks, 1)(result, code)
end
local function refresh(event) items["aerospace.observer"].handlers[event or "routine"]() end
local function snapshot(display, workspace)
  return { ["monitor-appkit-nsscreen-screens-id"] = display, workspace = workspace }
end

-- The complete left layout must exist before AeroSpace responds.
check_layout(1)
check_layout(2)
complete("AeroSpace is not running", 1)
check_layout(1)
refresh()
complete({}, 0)
check_layout(1)
check_layout(2)
refresh()
complete({ snapshot(1, "2"), snapshot(2, "4") }, 0)
local colors = require("colors")
assert(items["workspace.1.2"].properties.label.color == colors.purple)
assert(items["workspace.2.4"].properties.label.color == colors.purple)
assert(items["workspace.1.1"].properties.label.color == colors.fg)
refresh()
complete({ snapshot(1, "1"), "malformed" }, 0)
assert(items["workspace.1.2"].properties.label.color == colors.purple, "partial malformed snapshot applied")

-- A real disconnect removes the old group; reconnects keep it before apps.
display_list = { { ["arrangement-id"] = 1 } }
refresh("display_change")
assert(not items["workspace.logo.2"], "disconnected display retained")
complete({ snapshot(1, "2") }, 0)
display_list = { { ["arrangement-id"] = 1 }, { ["arrangement-id"] = 3 } }
refresh("display_change")
complete({ snapshot(1, "2"), snapshot(3, "5") }, 0)
check_layout(1)
check_layout(3)

-- Invalid display data preserves the last known layout.
display_list = { { ["arrangement-id"] = 1 }, { ["arrangement-id"] = "bad" } }
refresh()
complete({}, 1)
check_layout(3)
display_list = { { ["arrangement-id"] = 1 }, { ["arrangement-id"] = 3 } }

-- Workspace changes during a query discard stale results and refresh once.
refresh()
refresh("aerospace_workspace_change")
refresh("aerospace_workspace_change")
assert(#callbacks == 1)
complete({ snapshot(1, "1") }, 0)
assert(#callbacks == 1)
assert(items["workspace.1.2"].properties.label.color == colors.purple)
complete({ snapshot(1, "3"), snapshot(3, "5") }, 0)
assert(items["workspace.1.3"].properties.label.color == colors.purple)
assert(#callbacks == 0)
assert(items["pill.apps"].properties.background.drawing == true)
print("PASS: startup, failed/empty/malformed snapshots, highlighting, reconnect order, event coalescing, and right-side layout")
