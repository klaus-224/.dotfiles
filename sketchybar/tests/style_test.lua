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

  local item = new_item(name, properties)
  recorded.items[name] = item
  record("item", item)
  return item
end

function sbar.remove(item)
  record("remove", item)
end

function sbar.exec(command, callback)
  recorded.execs[#recorded.execs + 1] = { command = command, callback = callback }

  if callback and sbar.exec_handler then
    local output, exit_code = sbar.exec_handler(command)
    if output ~= nil or exit_code ~= nil then callback(output, exit_code or 0) end
  end
end

function sbar.hotload() end
function sbar.begin_config() end
function sbar.end_config() end
function sbar.event_loop() end
function sbar.trigger() end

package.loaded["sketchybar"] = sbar
reset()

--------------------------------------------------------------------------------
-- Modules under test
--------------------------------------------------------------------------------

local style = require("helpers.style")
local settings = require("settings")
local colors = require("colors")
local widget = require("helpers.widget")
local pill = require("helpers.pill")

local function widget_module(name)
  package.loaded["widgets." .. name] = nil
  return require("widgets." .. name)
end

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
-- Widget creation
--------------------------------------------------------------------------------

do
  reset()

  local item = widget.add({
    name = "example",
    update_freq = 7,
    item = {
      icon = { string = "A", color = colors.green },
      label = { width = 36 },
    },
  })

  equals(item.name, "widgets.example", "an item is named after its widget")
  equals(item.properties.position, "right", "widgets default to the right position")
  equals(item.properties.update_freq, 7, "update_freq reaches the item")
  equals(item.properties.icon.string, "A", "the widget icon comes from its item table")
  equals(item.properties.icon.color, colors.green, "a widget colour survives creation")
  equals(item.properties.label.width, 36, "a fixed label width comes from item.label.width")
  equals(item.properties.icon.padding_right, settings.widgets.icon.padding_right,
    "shared widget spacing is applied")
  equals(item.properties.padding_left, settings.widgets.padding_left, "shared outer padding is applied")
  equals(item.properties.padding_right, settings.widgets.padding_right, "shared right padding is applied")
  equals(item.properties.icon.font, nil, "widgets inherit fonts instead of redefining them")
end

do
  reset()

  local item = widget.add({
    name = "override",
    update_freq = 5,
    item = {
      padding_left = 20,
      icon = { padding_right = 0 },
      label = { drawing = false },
      update_freq = 99,
    },
  })

  equals(item.properties.padding_left, 20, "a widget overrides shared outer padding")
  equals(item.properties.icon.padding_right, 0, "a widget overrides the shared icon gap")
  equals(item.properties.label.drawing, false, "a widget controls label visibility explicitly")
  equals(item.properties.update_freq, 5, "the spec update_freq stays authoritative")
end

do
  reset()

  widget.add({ name = "first", item = { icon = { color = colors.red } } })
  widget.add({ name = "second" })

  equals(recorded.items["widgets.second"].properties.icon.color, nil,
    "one widget's styling does not leak into another")
  equals(settings.widgets.icon.padding_right ~= nil, true, "shared settings survive widget creation")
end

--------------------------------------------------------------------------------
-- Render is a plain property update
--------------------------------------------------------------------------------

do
  reset()

  local item = widget.add({
    name = "patch",
    item = { label = { width = 36 } },
    render = function(state) return { label = { string = state } } end,
  })

  item:set({ label = { string = "one" } })
  equals(item.updates[#item.updates], { label = { string = "one" } },
    "an update carries only the fields it sets")
  equals(item.properties.label.width, 36, "a rendered update does not change the configured width")
end

do
  -- Drive the render path through the helper rather than calling it directly.
  reset()
  sbar.exec_handler = function() return "", 0 end

  local nil_item = widget.add({
    name = "nilrender",
    command = "true",
    render = function() return nil end,
  })
  equals(#nil_item.updates, 0, "a nil render result applies no update")

  local empty_item = widget.add({
    name = "emptyrender",
    command = "true",
    render = function() return {} end,
  })
  equals(empty_item.updates[1], {}, "an empty render result changes nothing")

  local silent_item = widget.add({ name = "norender", command = "true" })
  equals(#silent_item.updates, 0, "a widget without a renderer never sets properties")

  sbar.exec_handler = nil
end

do
  reset()

  local item = widget.add({
    name = "noderive",
    item = { icon = { padding_right = 4 }, label = { width = 36 } },
    command = "true",
    parse = function() return "" end,
    render = function(value) return { label = { string = value } } end,
  })

  sbar.exec_handler = function() return "", 0 end
  item.subscriptions.forced()
  sbar.exec_handler = nil

  local update = item.updates[#item.updates]
  equals(update, { label = { string = "" } },
    "an empty label does not trigger derived spacing or visibility changes")
  equals(item.properties.icon.padding_right, 4, "the configured icon gap survives an empty label")
  equals(item.properties.label.drawing, nil, "label visibility is never rewritten at render time")
end

do
  reset()

  local item = widget.add({
    name = "reset",
    item = { icon = { color = colors.fg } },
    command = "true",
    parse = function(output) return output end,
    render = function(state)
      if state == "hot" then return { icon = { color = colors.red } } end
      return { icon = { color = colors.fg } }
    end,
  })

  sbar.exec_handler = function() return "hot", 0 end
  item.subscriptions.forced()
  equals(item.updates[#item.updates].icon.color, colors.red, "a state colour is applied")

  sbar.exec_handler = function() return "cool", 0 end
  item.subscriptions.forced()
  equals(item.updates[#item.updates].icon.color, colors.fg,
    "a previous dynamic value is undone by returning it explicitly")
  sbar.exec_handler = nil
end

--------------------------------------------------------------------------------
-- Pills
--------------------------------------------------------------------------------

do
  reset()

  local item = pill.add({
    name = "surface",
    item = { padding_left = 20, label = { width = 36 } },
  })

  equals(item.properties.padding_left, 20, "a pill no longer overrides item padding")
  equals(item.properties.label.width, 36, "a pill no longer overrides the label width")

  local bracket = recorded.brackets["pill.surface"]
  equals(bracket.members, { "widgets.surface" }, "a pill brackets its own widget")
  equals(bracket.properties, settings.pill, "a pill uses the shared surface properties")
end

do
  reset()

  pill.add({ name = "custom", pill = { background = { color = colors.red } } })
  pill.add({ name = "plain" })

  equals(recorded.brackets["pill.custom"].properties.background.color, colors.red,
    "a per-widget pill override reaches the bracket")
  equals(recorded.brackets["pill.custom"].properties.background.height, settings.pill.background.height,
    "a pill override merges with the shared surface")
  equals(recorded.brackets["pill.plain"].properties.background.color, settings.pill.background.color,
    "a pill override does not leak into another pill")
  equals(recorded.items["widgets.custom"].properties.background, nil,
    "a pill override does not touch the item background")
end

--------------------------------------------------------------------------------
-- Widget modules
--------------------------------------------------------------------------------

do
  local names = { "battery", "cpu", "memory", "date", "time", "clock", "spotify", "slack", "teams" }

  for _, name in ipairs(names) do
    local spec = widget_module(name)
    equals(spec.icon, nil, name .. " no longer uses a top-level icon field")
    equals(spec.label_width, nil, name .. " no longer uses a top-level label_width field")
  end
end

do
  local battery = widget_module("battery")

  equals(battery.item.label.width, 36, "battery keeps its fixed label width")
  equals(battery.update_freq, 120, "battery keeps its refresh interval")
  equals(battery.command, "/usr/bin/pmset -g batt", "battery keeps its command")
  equals(battery.events, { "routine", "forced", "power_source_change", "system_woke" },
    "battery keeps its subscriptions")

  local charging = battery.parse("Now drawing from 'AC Power'\n -InternalBattery-0 84%; charging")
  equals(charging, { percentage = 84, charging = true }, "battery parses a charging state")
  equals(battery.render(charging).icon.color, colors.green, "a charging battery is green")

  local low = { percentage = 8, charging = false }
  equals(battery.render(low).icon.color, colors.red, "a low battery is red")
  equals(battery.render(low).label.string, "8%", "battery renders its percentage")

  local normal = { percentage = 75, charging = false }
  equals(battery.render(normal).icon.color, colors.green, "a healthy battery is green")

  equals(battery.render(nil).icon.color, colors.muted, "a missing battery state is muted")
  equals(battery.render(nil).label.string, "", "a missing battery state clears the label")
end

do
  local cpu = widget_module("cpu")
  equals(cpu.render(90).icon.color, colors.red, "a busy CPU is red")
  equals(cpu.render(10).label.string, "10%", "the CPU label shows a percentage")

  local memory = widget_module("memory")
  equals(memory.render(nil).label.string, "--%", "memory shows a placeholder when unavailable")

  local clock = widget_module("clock")
  equals(clock.render(nil).label.string, "", "the clock clears its label explicitly")

  local date = widget_module("date")
  equals(date.item.label.width, 78, "date keeps its fixed label width")

  local time = widget_module("time")
  equals(time.item.label.width, 42, "time keeps its fixed label width")
end

do
  local spotify = widget_module("spotify")
  equals(spotify.item.label.drawing, false, "spotify hides its label explicitly")
  equals(spotify.item.icon.padding_right, settings.widgets.icon.padding_left,
    "an icon-only pill mirrors the shared left inset explicitly")
  equals(spotify.item.icon.color, colors.green, "spotify keeps its static green icon")
  equals(spotify.on_click, '/usr/bin/open -a "Spotify"', "spotify keeps its click action")
  equals(spotify.render, nil, "spotify has no renderer to override its static colour")
end

do
  local slack = widget_module("slack")
  equals(slack.item.icon.string, "󰒱", "the badge factory forwards its icon into item")
  equals(slack.item.label.width, 22, "the badge factory forwards its label width")
  equals(slack.render(nil).icon.color, colors.muted, "a closed app badge is muted")
  equals(slack.render("3").icon.color, colors.red, "slack keeps its brand colour")
  equals(slack.render("3").label.string, "3", "a badge renders its count")
  equals(slack.on_click, '/usr/bin/open -a "Slack"', "slack keeps its click action")

  local teams = widget_module("teams")
  equals(teams.render("").icon.color, colors.blue, "teams keeps its brand colour")
end

--------------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------------

do
  reset()

  for _, name in ipairs({ "battery", "time", "date", "cpu", "memory", "spotify", "teams", "slack" }) do
    package.loaded["widgets." .. name] = nil
  end
  package.loaded["widgets.aerospace"] = nil
  package.loaded["bar"] = nil

  sbar.exec_handler = function(command)
    if command:find("list%-workspaces") then
      return { { workspace = "2", ["monitor-appkit-nsscreen-screens-id"] = 1 } }, 0
    end
    return nil, 1
  end

  local previous_config = os.getenv("CONFIG_DIR")

  -- Run the real `init.lua` in a sandboxed environment so the startup sequence,
  -- including the bar call, is covered without depending on the caller's
  -- environment or the native module.
  local environment
  environment = setmetatable({
    os = setmetatable({
      getenv = function(name)
        if name == "CONFIG_DIR" then return config_dir end
        if name == "HOME" then return os.getenv("HOME") or "/tmp" end
        return os.getenv(name)
      end,
    }, { __index = os }),
  }, { __index = _G })

  local init = assert(loadfile(config_dir .. "/init.lua", "t", environment))
  init()

  sbar.exec_handler = nil

  equals(recorded.defaults, settings.defaults, "startup applies the shared defaults")
  ok(recorded.bar ~= nil, "startup applies the bar properties")
  equals(recorded.bar.height, settings.bar.height, "the bar uses the configured height")
  equals(recorded.bar.color, colors.transparent, "the bar stays transparent")
  equals(recorded.bar.padding_left, settings.bar.padding_left, "the bar uses the configured padding")
  ok(previous_config == nil or previous_config ~= "", "CONFIG_DIR is not required by the tests")

  local default_index, first_item_index
  for index, call in ipairs(recorded.calls) do
    if call.kind == "default" then default_index = default_index or index end
    if call.kind == "item" then first_item_index = first_item_index or index end
  end
  ok(default_index and first_item_index and default_index < first_item_index,
    "defaults are applied before any item is created")

  for _, name in ipairs({ "battery", "time", "date", "cpu", "memory", "spotify", "teams", "slack" }) do
    ok(recorded.items["widgets." .. name] ~= nil, name .. " is created at startup")
    ok(recorded.brackets["pill." .. name] ~= nil, name .. " is wrapped in a pill")
  end

  local order = {}
  for _, call in ipairs(recorded.calls) do
    if call.kind == "item" and call.value.name:match("^widgets%.") then
      order[#order + 1] = call.value.name:gsub("^widgets%.", "")
    end
  end
  equals(order, { "battery", "time", "date", "cpu", "memory", "spotify", "teams", "slack" },
    "the widget insertion order is unchanged")

  local workspace_bracket = recorded.brackets["workspace.bracket.1"]
  ok(workspace_bracket ~= nil, "aerospace creates a workspace bracket")
  equals(workspace_bracket.properties, settings.pill,
    "left and right surfaces share the same pill properties")

  for _, workspace in ipairs({ "1", "2", "3", "4", "5" }) do
    ok(recorded.items["workspace.1." .. workspace] ~= nil, "workspace " .. workspace .. " is created")
  end

  local selected = recorded.items["workspace.1.2"].updates
  equals(selected[#selected].background.color, colors.yellow, "the active workspace keeps its highlight")

  local inactive = recorded.items["workspace.1.3"].updates
  equals(inactive[#inactive].label.color, colors.muted, "inactive workspaces stay muted")
end

--------------------------------------------------------------------------------

if failures == 0 then
  io.write(string.format("ok - %d checks passed\n", checks))
  os.exit(0)
end

io.write(string.format("FAILED - %d of %d checks failed\n", failures, checks))
os.exit(1)
