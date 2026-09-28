local repo = assert(arg[1], "repository path argument is required")
local config_dir = repo .. "/sketchybar"

package.path = table.concat({
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
  config_dir .. "/?/?.lua",
  package.path,
}, ";")

local calls, items, executions = {}, {}, {}
local default_properties = {}

local function fail(message)
  io.stderr:write("FAIL: " .. message .. "\n")
  os.exit(1)
end

local function expect(condition, message)
  if not condition then fail(message) end
end

local function equal(actual, expected, message)
  if actual ~= expected then
    fail(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function record(kind, value)
  calls[#calls + 1] = { kind = kind, value = value }
end

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, nested in pairs(value) do result[key] = copy(nested) end
  return result
end

local function merge(target, source)
  for key, value in pairs(source or {}) do
    if type(value) == "table" and type(target[key]) == "table" then
      merge(target[key], value)
    else
      target[key] = copy(value)
    end
  end
  return target
end

local sbar = {}
function sbar.begin_config() record("lifecycle", "begin") end
function sbar.hotload(value) record("lifecycle", "hotload:" .. tostring(value)) end
function sbar.end_config() record("lifecycle", "end") end
function sbar.event_loop() record("lifecycle", "event_loop") end
function sbar.bar(properties) record("bar", properties) end
function sbar.default(properties)
  merge(default_properties, properties)
  record("default", properties)
end
function sbar.add(kind, name, properties, bracket_properties)
  local members
  if kind == "bracket" then
    members = properties
    properties = bracket_properties
  end
  local effective = merge(copy(default_properties), properties or {})
  local item = {
    kind = kind,
    name = name,
    members = members,
    declared = properties or {},
    properties = effective,
    subscriptions = {},
    sets = {},
  }
  function item:set(properties) self.sets[#self.sets + 1] = properties end
  function item:subscribe(events, callback)
    if type(events) == "string" then events = { events } end
    for _, event in ipairs(events) do self.subscriptions[event] = callback end
  end
  items[name] = item
  record("add", item)
  return item
end
function sbar.remove(item)
  record("remove", item)
  items[item.name] = nil
end
function sbar.exec(command, callback)
  executions[#executions + 1] = { command = command, callback = callback }
end

package.preload.sketchybar = function() return sbar end

local real_getenv = os.getenv
local function expect_startup_error(path, missing_variable, fragment)
  os.getenv = function(name)
    if name == missing_variable then return nil end
    return real_getenv(name)
  end
  local ok, message = pcall(dofile, path)
  os.getenv = real_getenv
  expect(not ok and tostring(message):find(fragment, 1, true), "startup reports " .. fragment)
end

expect_startup_error(config_dir .. "/sketchybarrc", "CONFIG_DIR", "CONFIG_DIR is not set")
expect_startup_error(config_dir .. "/init.lua", "HOME", "HOME is not set")

do
  local preload = package.preload.sketchybar
  package.loaded.sketchybar = nil
  package.preload.sketchybar = function() error("mock native module failure") end
  local ok, message = pcall(dofile, config_dir .. "/init.lua")
  expect(not ok and tostring(message):find("cannot load SbarLua", 1, true), "native-module failure is actionable")
  package.preload.sketchybar = preload
  package.loaded.sketchybar = nil
end

local function next_execution(fragment)
  for _, execution in ipairs(executions) do
    if not execution.used and execution.command:find(fragment, 1, true) then
      execution.used = true
      return execution
    end
  end
  fail("missing queued execution containing " .. fragment)
end

local function count_calls(kind)
  local count = 0
  for _, call in ipairs(calls) do if call.kind == kind then count = count + 1 end end
  return count
end

local function workspace_count(display)
  local count = 0
  for name in pairs(items) do
    if name:match("^workspace%." .. display .. "%.") then count = count + 1 end
  end
  return count
end

local function latest(item, component, property)
  for index = #item.sets, 1, -1 do
    local value = item.sets[index][component]
    if value and value[property] ~= nil then return value[property] end
  end
  return item.properties[component] and item.properties[component][property]
end

local original_directory = assert(io.popen("pwd", "r")):read("*l")
expect(original_directory ~= config_dir, "entry point must work outside the configuration directory")
dofile(config_dir .. "/sketchybarrc")

local lifecycle = {}
for _, call in ipairs(calls) do
  if call.kind == "lifecycle" then lifecycle[#lifecycle + 1] = call.value end
end
equal(table.concat(lifecycle, ","), "begin,hotload:true,end,event_loop", "single lifecycle order")
equal(_G.sbar, nil, "SbarLua is not leaked as a global")

local default_index, first_add_index
for index, call in ipairs(calls) do
  if call.kind == "default" and not default_index then default_index = index end
  if call.kind == "add" and not first_add_index then first_add_index = index end
end
expect(default_index and first_add_index and default_index < first_add_index, "defaults precede all item creation")

local bar
for _, call in ipairs(calls) do if call.kind == "bar" then bar = call.value end end
expect(bar, "bar configuration is present")
equal(bar.position, "top", "bar position")
equal(bar.height, 44, "bar height")
equal(bar.color, 0x00000000, "bar background")
equal(bar.padding_left, 8, "bar left padding")
equal(bar.padding_right, 8, "bar right padding")
equal(bar.display, "all", "bar display association")

local settings = require("settings")
equal(settings.fonts.icon.family, "Hack Nerd Font", "baseline icon font family")
equal(settings.fonts.icon.style, "Bold", "baseline icon font style")
equal(settings.fonts.icon.size, 14.0, "baseline icon font size")
equal(settings.fonts.label.family, "Hack Nerd Font", "baseline label font family")
equal(settings.fonts.label.size, 14.0, "baseline label font size")

local colors = require("colors")
equal(colors.bg, 0xff252530, "Vague background")
equal(colors.fg, 0xffcdcdcd, "Vague foreground")
equal(colors.muted, 0xff606079, "Vague muted color")
equal(colors.green, 0xff99b782, "Vague green")
equal(colors.yellow, 0xffe8b589, "Vague yellow")
equal(colors.red, 0xffc48282, "Vague red")
equal(colors.lavender, 0xffc9b1ca, "Vague lavender")
equal(colors.pill_bg, 0xd9252530, "translucent pill background")
equal(colors.pill_border, 0x30cdcdcd, "subtle pill border")
equal(colors.transparent, 0x00000000, "transparent color")

local observer = assert(items["aerospace.observer"], "AeroSpace observer is present")
equal(observer.properties.drawing, false, "observer hidden")
equal(observer.properties.update_freq, 10, "observer heartbeat")
equal(observer.properties.icon.font.size, 14.0, "observer inherits shared icon font")
equal(observer.properties.label.font.size, 14.0, "observer inherits shared label font")
equal(observer.properties.background, nil, "group background defaults do not leak to observer")
for _, event in ipairs({ "aerospace_workspace_change", "display_change", "system_woke", "routine", "forced" }) do
  expect(type(observer.subscriptions[event]) == "function", "observer subscribes to " .. event)
end

local initial = next_execution("list-workspaces")
expect(initial.command:find("--monitor all --visible --json", 1, true), "query requests visible JSON workspaces")
expect(initial.command:find("monitor-appkit-nsscreen-screens-id", 1, true), "query requests AppKit display IDs")
initial.callback("unavailable", 1)
equal(workspace_count(1), 0, "failed discovery preserves empty registry")

observer.subscriptions.routine()
next_execution("list-workspaces").callback({
  { workspace = "1", ["monitor-appkit-nsscreen-screens-id"] = 1 },
  { workspace = "2", ["monitor-appkit-nsscreen-screens-id"] = "2" },
}, 0)
equal(workspace_count(1), 5, "first display receives five workspaces")
equal(workspace_count(2), 5, "second display receives five workspaces")
local workspace_one = assert(items["workspace.1.1"])
local workspace_two = assert(items["workspace.2.2"])
equal(workspace_one.properties.position, "left", "workspace position")
equal(workspace_one.properties.padding_left, 1, "workspace padding")
equal(workspace_one.properties.label.string, "1", "workspace label")
equal(workspace_one.properties.label.padding_left, 7, "workspace label override")
equal(workspace_one.properties.label.font.family, "Hack Nerd Font", "deferred workspace inherits label font")
equal(workspace_one.properties.background.border_width, nil, "workspace has no individual border")
equal(latest(workspace_one, "background", "color"), colors.yellow, "selected workspace background")
equal(latest(workspace_one, "label", "color"), colors.bg, "selected workspace label")
equal(latest(items["workspace.1.2"], "background", "color"), colors.transparent, "inactive workspace background")
equal(latest(items["workspace.1.2"], "label", "color"), colors.muted, "inactive workspace label")
equal(latest(workspace_two, "label", "color"), colors.bg, "second display selection")

local workspace_logo = assert(items["workspace.logo.1"], "workspace logo is present")
equal(workspace_logo.properties.icon.string, "", "workspace logo glyph")
expect(items["workspace.separator.1"], "workspace separator is present")
local workspace_bracket = assert(items["workspace.bracket.1"], "workspace bracket is present")
equal(table.concat(workspace_bracket.members, ","), table.concat({
  "workspace.logo.1", "workspace.separator.1", "workspace.1.1",
  "workspace.1.2", "workspace.1.3", "workspace.1.4", "workspace.1.5",
}, ","), "workspace bracket membership")
equal(workspace_bracket.properties.background.color, colors.pill_bg, "workspace bracket uses pill background")

local additions, removals = count_calls("add"), count_calls("remove")
observer.subscriptions.forced()
next_execution("list-workspaces").callback({
  { workspace = "1", ["monitor-appkit-nsscreen-screens-id"] = 1 },
  { workspace = "2", ["monitor-appkit-nsscreen-screens-id"] = 2 },
}, 0)
equal(count_calls("add"), additions, "unchanged snapshot does not duplicate items")
equal(count_calls("remove"), removals, "unchanged snapshot does not remove items")

observer.subscriptions.display_change()
next_execution("list-workspaces").callback({
  { workspace = "3", ["monitor-appkit-nsscreen-screens-id"] = 1 },
}, 0)
equal(workspace_count(2), 0, "disconnected display workspaces are removed")
equal(items["workspace.logo.2"], nil, "disconnected display logo is removed")
equal(items["workspace.separator.2"], nil, "disconnected display separator is removed")
equal(items["workspace.bracket.2"], nil, "disconnected display bracket is removed")
equal(workspace_count(1), 5, "remaining display workspaces are retained")

observer.subscriptions.routine()
next_execution("list-workspaces").callback("malformed", 0)
equal(workspace_count(1), 5, "malformed discovery preserves registry")
observer.subscriptions.routine()
next_execution("list-workspaces").callback({}, 1)
equal(workspace_count(1), 5, "failed discovery preserves registry")

observer.subscriptions.routine()
observer.subscriptions.aerospace_workspace_change()
local stale = next_execution("list-workspaces")
stale.callback({ { workspace = "4", ["monitor-appkit-nsscreen-screens-id"] = 1 } }, 0)
equal(latest(items["workspace.1.3"], "background", "color"), colors.yellow, "superseded snapshot is discarded")
next_execution("list-workspaces").callback({
  { workspace = "5", ["monitor-appkit-nsscreen-screens-id"] = 1 },
}, 0)
equal(latest(items["workspace.1.5"], "background", "color"), colors.yellow, "queued refresh applies newest snapshot")

local click_item = items["workspace.1.5"]
click_item.subscriptions["mouse.clicked"]()
local click = next_execution(" workspace ")
equal(click.command, "'/opt/homebrew/bin/aerospace' workspace '5'", "workspace click invokes AeroSpace")

local slack = assert(items["widgets.slack"], "Slack item is present")
equal(slack.properties.update_freq, 30, "Slack interval")
equal(slack.properties.icon.font.size, 14.0, "Slack uses widget icon font")
equal(slack.properties.label.font.size, 14.0, "Slack uses widget label font")
equal(slack.properties.padding_left, 12, "Slack includes outer group padding")
equal(slack.properties.background, nil, "group background does not leak to Slack")
local slack_initial = next_execution('_ "Slack"')
slack_initial.callback("unavailable", 1)
equal(latest(slack, "icon", "color"), colors.muted, "unavailable Slack is muted")
slack.subscriptions.routine(); next_execution('_ "Slack"').callback('pid = 93254\n[ NULL ]', 0)
equal(latest(slack, "icon", "color"), colors.red, "running Slack without a badge is red")
equal(latest(slack, "label", "string"), "", "running Slack without a badge has no label")
equal(latest(slack, "label", "drawing"), false, "empty Slack badge hides its label")
equal(latest(slack, "icon", "padding_right"), 0, "empty Slack badge removes icon gap")
slack.subscriptions.forced(); next_execution('_ "Slack"').callback('pid = 93254\n"label" = "•"', 0)
equal(latest(slack, "icon", "color"), colors.red, "bullet Slack status is red")
slack.subscriptions.aerospace_workspace_change(); next_execution('_ "Slack"').callback('pid = 93254\n"label" = "12"', 0)
equal(latest(slack, "icon", "color"), colors.red, "numeric Slack status is red")
equal(latest(slack, "label", "drawing"), true, "Slack badge shows its label")
equal(latest(slack, "icon", "padding_right"), 6, "Slack badge restores icon gap")
slack.subscriptions.routine(); next_execution('_ "Slack"').callback('[ NULL ]\n[ NULL ]', 0)
equal(latest(slack, "icon", "color"), colors.muted, "stopped Slack is muted")
slack.subscriptions["mouse.clicked"]()
equal(next_execution('/usr/bin/open -a "Slack"').command, '/usr/bin/open -a "Slack"', "Slack click opens Slack")

local teams = assert(items["widgets.teams"], "Teams item is present")
next_execution('_ "Microsoft Teams"').callback('pid = 74517\n"label" = "4"', 0)
equal(latest(teams, "icon", "color"), colors.blue, "Teams badge is blue")
equal(latest(teams, "label", "string"), "4", "Teams badge count")
teams.subscriptions.routine(); next_execution('_ "Microsoft Teams"').callback("[ NULL ]\n[ NULL ]", 0)
equal(latest(teams, "icon", "color"), colors.muted, "unavailable Teams is muted")
teams.subscriptions["mouse.clicked"]()
equal(next_execution('/usr/bin/open -a "Microsoft Teams"').command, '/usr/bin/open -a "Microsoft Teams"', "Teams click opens Teams")

local cpu = assert(items["widgets.cpu"], "CPU item is present")
equal(cpu.properties.update_freq, 3, "CPU interval")
next_execution("CPU usage").callback("CPU usage: 20.5% user, 10.4% sys, 69.1% idle", 0)
equal(latest(cpu, "label", "string"), "31%", "CPU sums user and system usage")
equal(latest(cpu, "icon", "color"), colors.fg, "normal CPU uses foreground")
cpu.subscriptions.routine(); next_execution("CPU usage").callback("CPU usage: 45% user, 10% sys, 45% idle", 0)
equal(latest(cpu, "icon", "color"), colors.yellow, "elevated CPU is yellow")
cpu.subscriptions.forced(); next_execution("CPU usage").callback("CPU usage: 70% user, 15% sys, 15% idle", 0)
equal(latest(cpu, "icon", "color"), colors.red, "high CPU is red")

local battery = assert(items["widgets.battery"], "battery item is present")
equal(battery.properties.update_freq, 120, "battery interval")
for _, event in ipairs({ "routine", "forced", "power_source_change", "system_woke" }) do
  expect(type(battery.subscriptions[event]) == "function", "battery subscribes to " .. event)
end
next_execution("pmset -g batt").callback("Now drawing from 'Battery Power'\n -InternalBattery-0 18%; discharging", 0)
equal(latest(battery, "label", "string"), "18%", "battery percentage")
equal(latest(battery, "icon", "color"), colors.red, "low battery is red")
battery.subscriptions.power_source_change()
next_execution("pmset -g batt").callback("Now drawing from 'AC Power'\n -InternalBattery-0 75%; charging", 0)
equal(latest(battery, "icon", "string"), "󰂄", "charging battery uses charging icon")

equal(items["widgets.wifi"], nil, "Wi-Fi widget is removed")
equal(items["widgets.bluetooth"], nil, "Bluetooth widget is removed")

local memory = assert(items["widgets.memory"], "memory item is present")
equal(memory.properties.label.width, 36, "memory label has fixed width")
next_execution("memory_pressure").callback("System-wide memory free percentage: 58%", 0)
equal(latest(memory, "label", "string"), "42%", "memory reports used percentage")

local date = assert(items["widgets.date"], "date item is present")
equal(date.properties.label.width, 78, "date label has fixed width")
next_execution("+%d %b %a").callback(" 28 Sep Sun\n", 0)
equal(latest(date, "label", "string"), "28 Sep Sun", "date trims output")

local time = assert(items["widgets.time"], "time item is present")
equal(time.properties.label.width, 42, "time label has fixed width")
equal(time.properties.label.font.size, 14.0, "time uses widget label font")
next_execution("+%H:%M").callback(" 09:42\n", 0)
equal(latest(time, "label", "string"), "09:42", "time trims output")
local time_sets = #time.sets
time.subscriptions.routine(); next_execution("+%H:%M").callback("", 0)
equal(#time.sets, time_sets + 1, "empty time output renders unavailable state")
time.subscriptions.forced(); next_execution("+%H:%M").callback("ignored", 1)
equal(#time.sets, time_sets + 2, "failed time output renders unavailable state")

local cpu_pill = assert(items["pill.cpu"], "CPU has its own pill")
equal(table.concat(cpu_pill.members, ","), "widgets.cpu", "CPU pill contains only CPU")
equal(cpu_pill.properties.background.color, colors.pill_bg, "widget pills use pill background")
equal(cpu_pill.properties.background.border_width, 1, "widget pills have a thin border")
equal(cpu.properties.label.width, 36, "CPU label has fixed width")
equal(battery.properties.label.width, 36, "battery label has fixed width")
local spotify = assert(items["widgets.spotify"], "Spotify item is present")
equal(spotify.properties.icon.color, colors.green, "Spotify stays green")
equal(spotify.properties.label.drawing, false, "Spotify has no label")
spotify.subscriptions["mouse.clicked"]()
equal(next_execution('/usr/bin/open -a "Spotify"').command, '/usr/bin/open -a "Spotify"', "Spotify click opens Spotify")

local right_additions = {}
for _, call in ipairs(calls) do
  if call.kind == "add" and call.value.kind == "item" and call.value.properties.position == "right"
      and call.value.name:match("^widgets%.") and call.value.name ~= "widgets.function-test" then
    right_additions[#right_additions + 1] = call.value.name
  end
end
equal(table.concat(right_additions, ","), table.concat({
  "widgets.battery", "widgets.spotify", "widgets.teams", "widgets.slack", "widgets.time",
  "widgets.date", "widgets.cpu", "widgets.memory",
}, ","), "right-side pills are added in reverse visual order")

local widget = require("helpers.widget")
local function_spec = {
  name = "function-test",
  command = "function-test-command",
  parse = function(output) return output == "valid" and output or nil end,
  render = function(value) return { label = { string = value or "unavailable" } } end,
  on_click = function(item) item:set({ icon = { color = colors.blue } }) end,
}
local function_item = widget.add(function_spec)
next_execution("function-test-command").callback("invalid", 0)
equal(latest(function_item, "label", "string"), "unavailable", "nil parse renders unavailable state")
function_item.subscriptions.routine()
next_execution("function-test-command").callback("valid", 0)
equal(latest(function_item, "label", "string"), "valid", "default events refresh widget")
function_item.subscriptions.forced()
next_execution("function-test-command").callback("valid", 1)
equal(latest(function_item, "label", "string"), "unavailable", "failed command renders unavailable state")
function_item.subscriptions["mouse.clicked"]()
equal(latest(function_item, "icon", "color"), colors.blue, "function click handler receives item")

observer.subscriptions.routine()
next_execution("list-workspaces").callback({}, 0)
equal(workspace_count(1), 0, "valid empty snapshot clears workspaces")

settings.bar.padding_left = 11
settings.fonts.label.size = 15
settings.groups.label_padding_left = 9
dofile(config_dir .. "/bar.lua")
dofile(config_dir .. "/defaults.lua")
local changed_bar = calls[#calls - 1].value
local changed_defaults = calls[#calls].value
equal(changed_bar.padding_left, 11, "bar consumes changed shared padding")
equal(changed_defaults.label.font.size, 15, "defaults consume changed label font size")
observer.subscriptions.routine()
next_execution("list-workspaces").callback({
  { workspace = "1", ["monitor-appkit-nsscreen-screens-id"] = 3 },
}, 0)
equal(items["workspace.3.1"].properties.label.padding_left, 9, "deferred workspaces consume changed label padding")
equal(items["workspace.3.1"].properties.label.font.size, 15, "deferred workspaces inherit changed defaults")
equal(items["workspace.3.1"].properties.padding_left, 1, "font changes do not alter workspace geometry")

print("PASS: SketchyBar Lua configuration")
