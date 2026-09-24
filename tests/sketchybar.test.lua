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
function sbar.add(kind, name, properties)
  local effective = merge(copy(default_properties), properties or {})
  local item = {
    kind = kind,
    name = name,
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

local function group_count(display)
  local count = 0
  for name in pairs(items) do
    if name:match("^group%." .. display .. "%.") then count = count + 1 end
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
equal(bar.height, 36, "bar height")
equal(bar.color, 0xff252530, "bar background")
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
equal(group_count(1), 0, "failed discovery preserves empty registry")

observer.subscriptions.routine()
next_execution("list-workspaces").callback({
  { workspace = "code-main", ["monitor-appkit-nsscreen-screens-id"] = 1 },
  { workspace = "browse-secondary", ["monitor-appkit-nsscreen-screens-id"] = "2" },
}, 0)
equal(group_count(1), 6, "first display receives six groups")
equal(group_count(2), 6, "second display receives six groups")
local code = assert(items["group.1.code"])
local browse = assert(items["group.2.browse"])
equal(code.properties.position, "left", "group position")
equal(code.properties.padding_left, 3, "group padding")
equal(code.properties.label.string, "Code", "group label")
equal(code.properties.label.padding_left, 8, "group label override")
equal(code.properties.label.font.family, "Hack Nerd Font", "deferred group inherits label font")
equal(latest(code, "background", "color"), colors.lavender, "selected group background")
equal(latest(code, "label", "color"), colors.bg, "selected group label")
equal(latest(items["group.1.browse"], "background", "color"), colors.transparent, "inactive group background")
equal(latest(browse, "label", "color"), colors.bg, "second display selection")

local additions, removals = count_calls("add"), count_calls("remove")
observer.subscriptions.forced()
next_execution("list-workspaces").callback({
  { workspace = "code-main", ["monitor-appkit-nsscreen-screens-id"] = 1 },
  { workspace = "browse-secondary", ["monitor-appkit-nsscreen-screens-id"] = 2 },
}, 0)
equal(count_calls("add"), additions, "unchanged snapshot does not duplicate items")
equal(count_calls("remove"), removals, "unchanged snapshot does not remove items")

observer.subscriptions.display_change()
next_execution("list-workspaces").callback({
  { workspace = "music", ["monitor-appkit-nsscreen-screens-id"] = 1 },
}, 0)
equal(group_count(2), 0, "disconnected display groups are removed")
equal(group_count(1), 6, "remaining display groups are retained")

observer.subscriptions.routine()
next_execution("list-workspaces").callback("malformed", 0)
equal(group_count(1), 6, "malformed discovery preserves registry")
observer.subscriptions.routine()
next_execution("list-workspaces").callback({}, 1)
equal(group_count(1), 6, "failed discovery preserves registry")

observer.subscriptions.routine()
observer.subscriptions.aerospace_workspace_change()
local stale = next_execution("list-workspaces")
stale.callback({ { workspace = "slack", ["monitor-appkit-nsscreen-screens-id"] = 1 } }, 0)
equal(latest(items["group.1.music"], "background", "color"), colors.lavender, "superseded snapshot is discarded")
next_execution("list-workspaces").callback({
  { workspace = "teams-call", ["monitor-appkit-nsscreen-screens-id"] = 1 },
}, 0)
equal(latest(items["group.1.teams"], "background", "color"), colors.lavender, "queued refresh applies newest snapshot")

local click_item = items["group.1.teams"]
click_item.subscriptions["mouse.clicked"]()
local click = next_execution("aerospace-groups.sh")
equal(click.command, "/bin/bash '" .. os.getenv("HOME") .. "/.dotfiles/scripts/aerospace-groups.sh' 'teams'", "group click uses shell helper")
click.callback("", 0)
local printed
local real_print = print
print = function(message) printed = message end
click_item.subscriptions["mouse.clicked"]()
next_execution("aerospace-groups.sh").callback("", 1)
print = real_print
expect(printed and printed:find("aerospace-group failed for teams", 1, true), "group click failure is reported")

local slack = assert(items["widgets.slack"], "Slack item is present")
equal(slack.properties.update_freq, 30, "Slack interval")
equal(slack.properties.icon.font.size, 14.0, "Slack inherits icon font")
equal(slack.properties.padding_left, nil, "group item padding does not leak to Slack")
equal(slack.properties.background, nil, "group background does not leak to Slack")
local slack_initial = next_execution("lsappinfo")
slack_initial.callback("unavailable", 1)
equal(latest(slack, "icon", "color"), colors.muted, "unavailable Slack is muted")
slack.subscriptions.routine(); next_execution("lsappinfo").callback('"label"=""', 0)
equal(latest(slack, "icon", "color"), colors.green, "empty Slack status is green")
slack.subscriptions.forced(); next_execution("lsappinfo").callback('"label" = "•"', 0)
equal(latest(slack, "icon", "color"), colors.yellow, "bullet Slack status is yellow")
slack.subscriptions.aerospace_workspace_change(); next_execution("lsappinfo").callback('"label" = "12"', 0)
equal(latest(slack, "icon", "color"), colors.red, "numeric Slack status is red")
slack.subscriptions.routine(); next_execution("lsappinfo").callback('"label" = "?"', 0)
equal(latest(slack, "icon", "color"), colors.muted, "unknown Slack status is muted")
slack.subscriptions["mouse.clicked"]()
equal(next_execution('/usr/bin/open -a "Slack"').command, '/usr/bin/open -a "Slack"', "Slack click opens Slack")

local clock = assert(items.clock, "clock item is present")
equal(clock.properties.update_freq, 30, "clock interval")
equal(clock.properties.label.color, colors.fg, "clock inherits foreground")
equal(clock.properties.label.padding_left, 0, "clock inherits shared label padding")
local clock_initial = next_execution("/bin/date")
clock_initial.callback(" 09:42\n", 0)
equal(latest(clock, "label", "string"), "09:42", "clock trims output")
local clock_sets = #clock.sets
clock.subscriptions.routine(); next_execution("/bin/date").callback("", 0)
equal(#clock.sets, clock_sets, "empty clock output preserves label")
clock.subscriptions.forced(); next_execution("/bin/date").callback("ignored", 1)
equal(#clock.sets, clock_sets, "failed clock output preserves label")

observer.subscriptions.routine()
next_execution("list-workspaces").callback({}, 0)
equal(group_count(1), 0, "valid empty snapshot clears groups")

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
  { workspace = "code-main", ["monitor-appkit-nsscreen-screens-id"] = 3 },
}, 0)
equal(items["group.3.code"].properties.label.padding_left, 9, "deferred groups consume changed label padding")
equal(items["group.3.code"].properties.label.font.size, 15, "deferred groups inherit changed defaults")
equal(items["group.3.code"].properties.padding_left, 3, "font changes do not alter group geometry")

print("PASS: SketchyBar Lua configuration")
