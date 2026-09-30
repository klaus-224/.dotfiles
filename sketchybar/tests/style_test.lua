-- Dependency-free regression tests for the SketchyBar styling contract.
--
-- Run from the repository root:
--   lua sketchybar/tests/style_test.lua
--
-- A stub `sketchybar` module records every SbarLua call, so no native module,
-- running bar, or shell command is required.

local config_dir = arg[0]:match("^(.*)/tests/[^/]+$") or "sketchybar"

package.path = table.concat({
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
  package.path,
}, ";")

--------------------------------------------------------------------------------
-- Assertions
--------------------------------------------------------------------------------

local failures = 0
local checks = 0

local function fail(message)
  failures = failures + 1
  io.write("not ok - " .. message .. "\n")
end

local function ok(condition, message)
  checks = checks + 1
  if not condition then fail(message) end
end

local function describe(value, seen)
  if type(value) ~= "table" then return tostring(value) end

  seen = seen or {}
  if seen[value] then return "<cycle>" end
  seen[value] = true

  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = tostring(key) end
  table.sort(keys)

  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = key .. " = " .. describe(value[key] ~= nil and value[key] or value[tonumber(key)], seen)
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local function same(actual, expected)
  if type(actual) ~= "table" or type(expected) ~= "table" then return actual == expected end

  for key, value in pairs(expected) do
    if not same(actual[key], value) then return false end
  end
  for key in pairs(actual) do
    if expected[key] == nil then return false end
  end
  return true
end

local function equals(actual, expected, message)
  checks = checks + 1
  if not same(actual, expected) then
    fail(message .. "\n  expected: " .. describe(expected) .. "\n  actual:   " .. describe(actual))
  end
end

--------------------------------------------------------------------------------
-- SbarLua stub
--------------------------------------------------------------------------------

local sbar = {}
local recorded

local function reset()
  recorded = {
    calls = {},
    defaults = nil,
    bar = nil,
    items = {},
    brackets = {},
    events = {},
    execs = {},
  }
  sbar.exec_handler = nil
end

local function record(kind, value)
  recorded.calls[#recorded.calls + 1] = { kind = kind, value = value }
end

local function new_item(name, properties)
  local item = {
    name = name,
    properties = properties,
    updates = {},
    subscriptions = {},
  }

  function item:set(update)
    self.updates[#self.updates + 1] = update
    record("set", { name = self.name, update = update })
  end

  function item:subscribe(events, callback)
    if type(events) == "string" then events = { events } end
    for _, event in ipairs(events) do
      self.subscriptions[event] = callback
      record("subscribe", { name = self.name, event = event })
    end
  end

  function item:query()
    return self.properties
  end

  return item
end

-- SbarLua rejects a call that receives more than the arguments it expects.
-- Since Lua 5.4 `require` returns the module *and* its loader data, so
-- `sbar.bar(require("bar"))` passes two arguments and is silently dropped.
local function arity(name, expected, ...)
  local received = select("#", ...)
  if received > expected then
    error(string.format(
      "expecting %d argument(s) to function '%s', received %d; "
        .. "bind require() to a local before passing it on",
      expected, name, received
    ), 3)
  end
end

function sbar.bar(properties, ...)
  arity("bar", 1, properties, ...)
  recorded.bar = properties
  record("bar", properties)
end

function sbar.default(properties, ...)
  arity("default", 1, properties, ...)
  recorded.defaults = properties
  record("default", properties)
end

function sbar.add(kind, name, third, fourth)
  if kind == "event" then
    recorded.events[#recorded.events + 1] = name
    record("event", name)
    return { name = name }
  end

  if kind == "bracket" then
    ok(recorded.brackets[name] == nil, "no duplicate bracket: " .. name)
    local bracket = { name = name, members = third, properties = fourth }
    recorded.brackets[name] = bracket
    record("bracket", bracket)
    return bracket
  end

  local properties = third
  if type(name) == "table" then
    properties = name
    name = "anonymous." .. tostring(#recorded.calls)
  end

  ok(recorded.items[name] == nil, "no duplicate item: " .. name)
  local item = new_item(name, properties)
  recorded.items[name] = item
  record("item", item)
  return item
end

function sbar.remove(item)
  record("remove", item)
  recorded.items[item.name] = nil
  recorded.brackets[item.name] = nil
end

function sbar.exec(command, callback)
  recorded.execs[#recorded.execs + 1] = { command = command, callback = callback }

  if callback and sbar.exec_handler then
    local output, exit_code = sbar.exec_handler(command)
    if output ~= nil or exit_code ~= nil then callback(output, exit_code or 0) end
  end
end

function sbar.hotload(value) record("hotload", value) end
function sbar.begin_config() record("begin_config", true) end
function sbar.end_config() record("end_config", true) end
function sbar.event_loop() record("event_loop", true) end
function sbar.trigger() end

package.loaded["sketchybar"] = sbar
reset()

--------------------------------------------------------------------------------
-- Modules under test
--------------------------------------------------------------------------------

local style = require("helpers.style")
local settings = require("settings")
local colors = require("colors")


--------------------------------------------------------------------------------
-- style.lua
--------------------------------------------------------------------------------

do
  local shared = { label = { font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 } } }
  local override = { label = { font = { size = 16.0 } } }
  local resolved = style.resolve(shared, override)

  equals(resolved.label.font, { family = "Hack Nerd Font", style = "Bold", size = 16.0 },
    "a partial font override merges recursively")
  equals(shared.label.font.size, 14.0, "resolving does not mutate a shared settings table")
  equals(override.label.font.size, 16.0, "resolving does not mutate a widget table")

  resolved.label.font.family = "Changed"
  equals(shared.label.font.family, "Hack Nerd Font", "resolved tables do not share nested state")

  equals(style.resolve({ label = { drawing = true } }, { label = { drawing = false } }).label.drawing, false,
    "an explicit false overrides a previous true")
  equals(style.resolve({ icon = { padding_right = 4 } }, { icon = { padding_right = 0 } }).icon.padding_right, 0,
    "an explicit zero overrides a previous value")
  equals(style.resolve({ a = 1 }, nil, { b = 2 }), { a = 1, b = 2 }, "nil property tables are skipped")

  local replaced = style.resolve({ label = { width = 36 } }, { label = "text" })
  equals(replaced.label, "text", "a scalar replaces a table")
end

--------------------------------------------------------------------------------
-- settings.lua
--------------------------------------------------------------------------------

do
  equals(settings.fonts, nil, "the removed settings.fonts alias is gone")
  equals(settings.item, nil, "the removed settings.item alias is gone")
  equals(settings.pills, nil, "the removed settings.pills alias is gone")
  equals(settings.widgets.font, nil, "widgets no longer carry a competing font source")
  equals(settings.widgets.item_padding, nil, "the removed item_padding alias is gone")
  equals(settings.widgets.icon_label_gap, nil, "the removed icon_label_gap alias is gone")

  ok(settings.defaults.icon.font.family ~= nil, "the shared icon font lives in settings.defaults")
  ok(settings.defaults.label.font.family ~= nil, "the shared label font lives in settings.defaults")
  ok(settings.pill.background ~= nil, "the pill surface is expressed as bracket background properties")
end

-- The reference-inspired baseline. These are chosen approximations, pinned so a
-- later edit cannot drift them silently.
do
  equals(settings.defaults.icon.font, { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
    "icons use the bold shared font")
  equals(settings.defaults.label.font, { family = "Hack Nerd Font", style = "Regular", size = 14.0 },
    "labels use the regular shared font")
  equals(settings.defaults.icon.color, colors.cyan, "icons default to the pale cyan accent")
  equals(settings.defaults.label.color, colors.fg, "labels default to the light foreground")

  equals(settings.bar.height, 40, "the bar height matches the chosen baseline")
  equals(settings.pill.background.height, 28, "pills use the compact height")
  equals(settings.pill.background.corner_radius, 12, "pills stay rounded")
  equals(settings.pill.background.border_width, 0, "pills are borderless")
  equals(settings.pill.background.color, colors.pill_bg, "pills use the shared surface colour")

  equals(settings.widgets.padding_left, 8, "pills are separated by a consistent gap")
  equals(settings.widgets.padding_right, 0, "the inter-pill gap is applied on one side only")
  equals(settings.widgets.icon.padding_left, 8, "labelled pills have a left inset")
  equals(settings.widgets.label.padding_right, 8, "labelled pills have a matching right inset")

  equals(settings.groups.background_height, 22, "workspace buttons fit inside the pill")
  equals(settings.groups.background_corner_radius, 7, "workspace buttons stay rounded")
end

--------------------------------------------------------------------------------
-- Item modules: exercise the callbacks, not the old declarative specifications.
--------------------------------------------------------------------------------

local icons = require("icons")
local order = { "battery", "time", "date", "cpu", "memory", "spotify", "teams", "slack" }
local commands = {
  battery = "/usr/bin/pmset -g batt",
  time = "/bin/date '+%H:%M'",
  date = "/bin/date '+%d %b %a'",
  cpu = "/usr/bin/top -l 2 -n 0 -s 1 | /usr/bin/grep 'CPU usage' | /usr/bin/tail -1",
  memory = "/usr/bin/memory_pressure",
  clock = "/bin/date '+%a %d %b %H:%M'",
}
for name, app in pairs({ slack = "Slack", teams = "Microsoft Teams" }) do
  commands[name] = '/bin/sh -c \'app="$1"; /usr/bin/lsappinfo info -only pid "$app"; '
    .. '/usr/bin/lsappinfo info -only StatusLabel "$app"\' _ "' .. app .. '"'
end
local intervals = { battery = 120, time = 30, date = 60, cpu = 3, memory = 10, teams = 10, slack = 10, clock = 30 }
local widths = { battery = 36, time = 42, date = 78, cpu = 36, memory = 36 }
local events = {
  battery = { "routine", "forced", "power_source_change", "system_woke" },
  slack = { "routine", "forced", "aerospace_workspace_change", "mouse.clicked" },
  teams = { "routine", "forced", "aerospace_workspace_change", "mouse.clicked" },
  spotify = { "mouse.clicked" },
}

local function keys(value)
  local result = {}
  for key in pairs(value) do result[#result + 1] = key end
  table.sort(result)
  return result
end

local function load_item(name)
  package.loaded["items." .. name] = nil
  return require("items." .. name)
end

local function latest(item)
  return item.updates[#item.updates]
end

local function refresh(item, output, exit_code, event)
  sbar.exec_handler = function() return output, exit_code or 0 end
  item.subscriptions[event or "forced"]()
  sbar.exec_handler = nil
  return latest(item)
end

local names = { table.unpack(order) }
names[#names + 1] = "clock"
for _, name in ipairs(names) do
  reset()
  local shared_before = style.copy(settings)
  sbar.exec_handler = function() return "", 1 end
  local item = load_item(name)
  sbar.exec_handler = nil

  local expected = {
    position = "right",
    padding_left = 8,
    padding_right = 0,
    icon = { string = name == "battery" and icons.battery.empty or icons[name] or "",
      padding_left = 8, padding_right = 4, y_offset = 0 },
    label = { string = "", padding_left = 0, padding_right = 8, y_offset = 0 },
    update_freq = intervals[name],
  }
  expected.label.width = widths[name]
  if name == "spotify" then expected.icon.color = colors.green end
  equals(item.properties, expected, name .. " preserves its complete creation properties")
  equals(recorded.brackets["pill." .. name].members, { "widgets." .. name }, name .. " keeps its bracket membership")
  equals(recorded.brackets["pill." .. name].properties, settings.pill, name .. " keeps its surface")
  equals(settings, shared_before, name .. " does not mutate shared settings")
  local expected_events = events[name] or { "routine", "forced" }
  local sorted = { table.unpack(expected_events) }
  table.sort(sorted)
  equals(keys(item.subscriptions), sorted, name .. " keeps exactly its subscriptions")

  if commands[name] then
    equals(#recorded.execs, 1, name .. " refreshes once during loading")
    equals(recorded.execs[1].command, commands[name], name .. " keeps its command")
    for _, event in ipairs(expected_events) do
      if event ~= "mouse.clicked" then
        local count = #recorded.execs
        refresh(item, "", 1, event)
        equals(#recorded.execs, count + 1, name .. " refreshes on " .. event)
        equals(recorded.execs[#recorded.execs].command, commands[name], name .. " repeats the same command")
      end
    end
  else
    equals(#recorded.execs, 0, "Spotify stays static")
    equals(#item.updates, 0, "Spotify has no dynamic renderer")
  end

  local app = ({ spotify = "Spotify", teams = "Microsoft Teams", slack = "Slack" })[name]
  if app then
    item.subscriptions["mouse.clicked"]()
    equals(recorded.execs[#recorded.execs].command, '/usr/bin/open -a "' .. app .. '"', name .. " keeps its launcher")
  end
end

-- Test real output through subscription callbacks, including dynamic colours,
-- placeholders, and invalid command output. Updates must remain partial.
local cases = {
  { "battery", "Now drawing from 'AC Power'\n84%; charging", { icon = { string = icons.battery.charging, color = colors.green }, label = { string = "84%" } } },
  { "battery", "8%", { icon = { string = icons.battery.empty, color = colors.red }, label = { string = "8%" } } },
  { "battery", "30%", { icon = { string = icons.battery.low, color = colors.red }, label = { string = "30%" } } },
  { "battery", "60%", { icon = { string = icons.battery.medium, color = colors.yellow }, label = { string = "60%" } } },
  { "battery", "90%", { icon = { string = icons.battery.high, color = colors.green }, label = { string = "90%" } } },
  { "battery", "100%", { icon = { string = icons.battery.full, color = colors.fg }, label = { string = "100%" } } },
  { "cpu", "CPU usage: 5.2% user, 4.6% sys, 90.2% idle", { icon = { color = colors.yellow }, label = { string = "10%" } } },
  { "cpu", "90% user, 1% sys", { icon = { color = colors.red }, label = { string = "91%" } } },
  { "cpu", "0% user, 0% sys", { icon = { color = colors.yellow }, label = { string = "0%" } } },
  { "memory", "System-wide memory free percentage: 50%", { icon = { color = colors.green }, label = { string = "50%" } } },
  { "memory", "free percentage: 30%", { icon = { color = colors.yellow }, label = { string = "70%" } } },
  { "memory", "free percentage: 10%", { icon = { color = colors.red }, label = { string = "90%" } } },
  { "time", " 10:42\n", { label = { string = "10:42" } } },
  { "date", " 30 Sep Wed\n", { label = { string = "30 Sep Wed" } } },
  { "clock", " Wed 30 Sep 10:42\n", { label = { string = "Wed 30 Sep 10:42" } } },
}
for _, name in ipairs({ "slack", "teams" }) do
  for _, label in ipairs({ "", "•", "3", "unexpected" }) do
    cases[#cases + 1] = { name, 'pid=123; "label"="' .. label .. '"', {
      icon = { color = name == "slack" and colors.red or colors.blue },
      label = { string = label == "unexpected" and "" or label },
    } }
  end
end
for _, case in ipairs(cases) do
  reset()
  local item = load_item(case[1])
  equals(refresh(item, case[2]), case[3], case[1] .. " renders " .. case[2])
end

local fallbacks = {
  battery = { icon = { string = icons.battery.empty, color = colors.muted }, label = { string = "" } },
  cpu = { icon = { color = colors.muted }, label = { string = "" } },
  memory = { icon = { color = colors.muted }, label = { string = "--%" } },
  time = { label = { string = "--:--" } }, date = { label = { string = "--" } },
  clock = { label = { string = "" } },
  slack = { icon = { color = colors.muted }, label = { string = "" } },
  teams = { icon = { color = colors.muted }, label = { string = "" } },
}
for name, fallback in pairs(fallbacks) do
  reset()
  local item = load_item(name)
  for _, output in ipairs({ "", {}, false }) do
    equals(refresh(item, output), fallback, name .. " handles missing or malformed output")
  end
  equals(refresh(item, "84%; 90% user, 1% sys; free percentage: 10%; pid=123", 1), fallback,
    name .. " ignores output from a failed command")
end

--------------------------------------------------------------------------------
-- Startup and multi-display AeroSpace lifecycle
--------------------------------------------------------------------------------

local workspace_command = "'/opt/homebrew/bin/aerospace' list-workspaces --monitor all --visible --json"
  .. " --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}'"
local function snapshot(first, second)
  local records = {}
  if first then records[#records + 1] = { workspace = first, ["monitor-appkit-nsscreen-screens-id"] = 1 } end
  if second then records[#records + 1] = { workspace = second, ["monitor-appkit-nsscreen-screens-id"] = 2 } end
  return records
end
local function count_calls(kind)
  local count = 0
  for _, call in ipairs(recorded.calls) do if call.kind == kind then count = count + 1 end end
  return count
end

reset()
for name in pairs(package.loaded) do
  if name == "items" or name:match("^items%.") then package.loaded[name] = nil end
end
package.loaded.bar = nil
sbar.exec_handler = function(command)
  if command == workspace_command then return snapshot("2", "4"), 0 end
  return "", 1
end
local environment = setmetatable({
  os = setmetatable({ getenv = function(name)
    if name == "CONFIG_DIR" then return config_dir end
    if name == "HOME" then return os.getenv("HOME") or "/tmp" end
    return os.getenv(name)
  end }, { __index = os }),
}, { __index = _G })
assert(loadfile(config_dir .. "/init.lua", "t", environment))()
sbar.exec_handler = nil

equals(recorded.defaults, settings.defaults, "startup applies shared defaults")
equals(recorded.bar, {
  position = "top", color = colors.transparent, height = 40, padding_left = 8,
  padding_right = 8, display = "all", font_smoothing = true,
}, "startup preserves the bar configuration")
equals(recorded.calls[1].kind, "begin_config", "configuration begins before SbarLua setup")
equals(recorded.calls[#recorded.calls - 2], { kind = "hotload", value = true }, "hotload remains enabled")
equals(recorded.calls[#recorded.calls - 1].kind, "end_config", "configuration ends before event loop")
equals(recorded.calls[#recorded.calls].kind, "event_loop", "event loop starts last")
equals(recorded.events, { "aerospace_workspace_change" }, "the custom event is registered once")
equals(recorded.items["widgets.clock"], nil, "the optional combined clock is not loaded")
local insertion_order = {}
local default_index, event_index
for index, call in ipairs(recorded.calls) do
  if call.kind == "default" then default_index = index end
  if call.kind == "event" then event_index = index end
  if call.kind == "item" then
    ok(default_index and default_index < index, "defaults precede " .. call.value.name)
    local name = call.value.name:match("^widgets%.(.+)$")
    if name then insertion_order[#insertion_order + 1] = name end
  elseif call.kind == "subscribe" and call.value.event == "aerospace_workspace_change" then
    ok(event_index and event_index < index, "custom event exists before subscription")
  end
end
equals(insertion_order, order, "the visual order is unchanged")

local function check_display(display, selected)
  local members = { "workspace.logo." .. display, "workspace.separator." .. display }
  local logo = recorded.items[members[1]]
  equals(logo.properties, {
    display = display, position = "left", padding_left = 8, padding_right = 7,
    icon = { string = "", color = colors.fg, padding_left = 0, padding_right = 0 },
    label = { drawing = false },
  }, "Apple keeps its styling on display " .. display)
  equals(logo.subscriptions, {}, "Apple remains decorative")
  equals(recorded.items[members[2]].properties, {
    display = display, position = "left", width = 1, padding_left = 0, padding_right = 5,
    icon = { drawing = false }, label = { drawing = false },
    background = { drawing = true, color = colors.separator, height = 16 },
  }, "the separator keeps its styling")
  for workspace = 1, 5 do
    local name = "workspace." .. display .. "." .. workspace
    members[#members + 1] = name
    local item = recorded.items[name]
    equals(item.properties, {
      display = display, position = "left", padding_left = 1, padding_right = 1,
      icon = { drawing = false }, label = { string = tostring(workspace), padding_left = 7, padding_right = 7 },
      background = { drawing = true, color = colors.transparent, corner_radius = 7, height = 22 },
    }, name .. " keeps its styling")
    equals(latest(item), {
      background = { color = workspace == selected and colors.yellow or colors.transparent },
      label = { color = workspace == selected and colors.bg or colors.muted },
    }, name .. " reflects the active workspace for its display")
    item.subscriptions["mouse.clicked"]()
    equals(recorded.execs[#recorded.execs].command, "'/opt/homebrew/bin/aerospace' workspace '" .. workspace .. "'",
      name .. " keeps its workspace command")
  end
  local bracket = recorded.brackets["workspace.bracket." .. display]
  equals(bracket.members, members, "Apple, separator, and workspaces share one bracket")
  equals(bracket.properties, settings.pill, "workspace surface stays unchanged")
end
check_display(1, 2)
check_display(2, 4)

local observer = recorded.items["aerospace.observer"]
equals(observer.properties, { drawing = false, update_freq = 10, updates = true }, "observer keeps its fallback interval")
equals(keys(observer.subscriptions), { "aerospace_workspace_change", "display_change", "forced", "routine", "system_woke" },
  "observer keeps its refresh events")
local creations = count_calls("item") + count_calls("bracket")
for _, event in ipairs(keys(observer.subscriptions)) do
  refresh(observer, snapshot("3", "5"), 0, event)
  equals(recorded.execs[#recorded.execs].command, workspace_command, event .. " queries visible workspaces")
end
equals(count_calls("item") + count_calls("bracket"), creations, "repeated refreshes do not recreate items")
check_display(1, 3)
check_display(2, 5)

local sets = count_calls("set")
local removes = count_calls("remove")
for _, result in ipairs({ "invalid", { false }, { { workspace = "1" } }, {
  { workspace = "2", ["monitor-appkit-nsscreen-screens-id"] = 1 },
  { workspace = 3, ["monitor-appkit-nsscreen-screens-id"] = 2 },
} }) do
  refresh(observer, result)
end
refresh(observer, snapshot("1"), 1)
equals(count_calls("set"), sets, "failed and malformed snapshots do not change highlights")
equals(count_calls("remove"), removes, "failed and malformed snapshots do not remove displays")

refresh(observer, snapshot("1"), 0, "display_change")
equals(count_calls("remove") - removes, 8, "disconnect removes five buttons, logo, separator, and bracket")
equals(recorded.brackets["workspace.bracket.2"], nil, "disconnected bracket is removed")
check_display(1, 1)
refresh(observer, snapshot("1", "4"), 0, "display_change")
equals(count_calls("item") + count_calls("bracket"), creations + 8, "reconnect recreates only the missing display")
check_display(2, 4)

-- While a query is in flight, repeated events queue just one follow-up. The
-- stale result is discarded; only the latest response changes the display.
local before = #recorded.execs
observer.subscriptions.forced()
local first_callback = recorded.execs[#recorded.execs].callback
observer.subscriptions.system_woke()
observer.subscriptions.aerospace_workspace_change()
equals(#recorded.execs, before + 1, "overlapping events do not start concurrent queries")
sets = count_calls("set")
first_callback(snapshot("2", "3"), 0)
equals(#recorded.execs, before + 2, "one pending query runs after completion")
equals(count_calls("set"), sets, "superseded snapshot is discarded")
recorded.execs[#recorded.execs].callback(snapshot("5", "1"), 0)
check_display(1, 5)
check_display(2, 1)
refresh(observer, {})
equals(keys(recorded.brackets), { "pill.battery", "pill.cpu", "pill.date", "pill.memory", "pill.slack", "pill.spotify", "pill.teams", "pill.time" },
  "an empty display snapshot removes all workspace brackets")

--------------------------------------------------------------------------------
if failures == 0 then
  io.write(string.format("ok - %d checks passed\n", checks))
  os.exit(0)
end
io.write(string.format("FAILED - %d of %d checks failed\n", failures, checks))
os.exit(1)
