local repo = assert(arg[1], "repository path argument is required")
local config_dir = repo .. "/sketchybar"

package.path = table.concat({
  config_dir .. "/?.lua",
  config_dir .. "/?/init.lua",
  config_dir .. "/?/?.lua",
  package.path,
}, ";")

local calls = {}
local items = {}
local executions = {}

local function fail(message)
  io.stderr:write("FAIL: " .. message .. "\n")
  os.exit(1)
end

local function expect(condition, message)
  if not condition then
    fail(message)
  end
end

local function expect_equal(actual, expected, message)
  if actual ~= expected then
    fail(message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function record(kind, value)
  calls[#calls + 1] = { kind = kind, value = value }
end

local sbar = {}

function sbar.begin_config()
  record("lifecycle", "begin")
end

function sbar.end_config()
  record("lifecycle", "end")
end

function sbar.event_loop()
  record("lifecycle", "event_loop")
end

function sbar.bar(properties)
  record("bar", properties)
end

function sbar.default(properties)
  record("default", properties)
end

function sbar.add(kind, name, properties)
  local item = {
    kind = kind,
    name = name,
    properties = properties,
    subscriptions = {},
    sets = {},
  }

  function item:set(next_properties)
    self.sets[#self.sets + 1] = next_properties
  end

  function item:subscribe(events, callback)
    if type(events) == "string" then
      events = { events }
    end
    for _, event in ipairs(events) do
      self.subscriptions[event] = callback
    end
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
  executions[#executions + 1] = {
    command = command,
    callback = callback,
  }
end

package.preload.sketchybar = function()
  return sbar
end

local function count_calls(kind)
  local count = 0
  for _, call in ipairs(calls) do
    if call.kind == kind then
      count = count + 1
    end
  end
  return count
end

local function next_execution(fragment)
  for index, execution in ipairs(executions) do
    if not execution.used and execution.command:find(fragment, 1, true) then
      execution.used = true
      return execution
    end
  end
  fail("missing queued execution containing " .. fragment)
end

local function latest_set(item)
  return item.sets[#item.sets]
end

local function workspace_items()
  local result = {}
  local index = 1
  while items["workspace." .. index] do
    result[#result + 1] = items["workspace." .. index]
    index = index + 1
  end
  return result
end

local original_directory = assert(io.popen("pwd", "r")):read("*l")
expect(original_directory ~= config_dir, "test must load configuration from a different working directory")

dofile(config_dir .. "/init.lua")

expect_equal(calls[1].kind, "lifecycle", "configuration starts with lifecycle call")
expect_equal(calls[1].value, "begin", "configuration begins before adding components")
expect_equal(calls[#calls - 1].value, "end", "configuration ends before event loop")
expect_equal(calls[#calls].value, "event_loop", "event loop starts last")

local bar
for _, call in ipairs(calls) do
  if call.kind == "bar" then
    bar = call.value
    break
  end
end
expect(bar ~= nil, "bar configuration is present")
expect_equal(bar.position, "top", "bar position")
expect_equal(bar.height, 36, "bar height")
expect_equal(bar.color, 0x00000000, "bar transparency")
expect_equal(bar.padding_left, 8, "left bar padding")
expect_equal(bar.padding_right, 8, "right bar padding")

local colors = require("colors")
expect_equal(colors.bg, 0xff252530, "Vague dark background")
expect_equal(colors.fg, 0xffcdcdcd, "Vague foreground")
expect_equal(colors.muted, 0xff606079, "Vague muted color")
expect_equal(colors.blue, 0xff6e94b2, "Vague blue")
expect_equal(colors.green, 0xff99b782, "Vague green")
expect_equal(colors.yellow, 0xffe8b589, "Vague yellow")
expect_equal(colors.red, 0xffc48282, "Vague red")
expect_equal(colors.lavender, 0xffc9b1ca, "Vague lavender")
expect_equal(colors.cyan, 0xff78a8ad, "Vague cyan")
expect_equal(colors.teal, 0xff7fa89a, "Vague teal")
expect_equal(colors.orange, 0xffd99a78, "Vague orange")
expect_equal(colors.pink, 0xffc996a5, "Vague pink")
expect_equal(colors.purple, 0xffa993bd, "Vague purple")
expect_equal(colors.transparent, 0x00000000, "transparent color")

local clock = assert(items.clock, "clock item is present")
expect_equal(clock.properties.position, "right", "clock position")
expect_equal(clock.properties.update_freq, 10, "clock interval")
expect_equal(clock.properties.label.color, colors.fg, "clock foreground")

local first_clock = next_execution("/bin/date")
first_clock.callback("09:42\n", 0)
expect_equal(latest_set(clock).label.string, "09:42", "clock trims command output")
local clock_sets = #clock.sets
clock.subscriptions.routine()
next_execution("/bin/date").callback("ignored\n", 1)
expect_equal(#clock.sets, clock_sets, "failed clock command preserves prior label")

local observer = assert(items["aerospace.observer"], "AeroSpace observer is present")
expect_equal(observer.properties.drawing, false, "observer is hidden")
expect_equal(observer.properties.update_freq, 10, "observer heartbeat")
expect(type(observer.subscriptions.forced) == "function", "forced updates refresh workspace discovery")

local initial_query = next_execution("list-workspaces")
expect(initial_query.command:find("--all --json", 1, true) ~= nil, "workspace query requests JSON")
initial_query.callback("aerospace unavailable", 1)
expect_equal(#workspace_items(), 0, "failed initial discovery keeps empty registry")

observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback({
  { workspace = "1", ["workspace-is-focused"] = false },
  { workspace = "2", ["workspace-is-focused"] = true },
  { workspace = "3", ["workspace-is-focused"] = false },
  { workspace = "4", ["workspace-is-focused"] = false },
  { workspace = "5", ["workspace-is-focused"] = false },
}, 0)

local spaces = workspace_items()
expect_equal(#spaces, 5, "late AeroSpace startup populates all persistent workspaces")
expect_equal(spaces[2].properties.background.color, colors.lavender, "snapshot initializes focused background")
expect_equal(spaces[2].properties.label.color, colors.bg, "focused workspace uses contrasting dark text")
expect_equal(spaces[1].properties.background.color, colors.transparent, "inactive workspace is transparent")
expect_equal(spaces[1].properties.label.color, colors.fg, "inactive workspace uses normal text")

local additions = count_calls("add")
local removals = count_calls("remove")
observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback({
  { workspace = "1", ["workspace-is-focused"] = false },
  { workspace = "2", ["workspace-is-focused"] = true },
  { workspace = "3", ["workspace-is-focused"] = false },
  { workspace = "4", ["workspace-is-focused"] = false },
  { workspace = "5", ["workspace-is-focused"] = false },
}, 0)
expect_equal(count_calls("add"), additions, "unchanged snapshot does not duplicate items")
expect_equal(count_calls("remove"), removals, "unchanged snapshot does not remove items")

observer.subscriptions.aerospace_workspace_change({
  SENDER = "aerospace_workspace_change",
  FOCUSED_WORKSPACE = 2,
})
expect_equal(latest_set(items["workspace.2"]).label.color, colors.bg, "numeric event values are normalized")

observer.subscriptions.aerospace_workspace_change({
  SENDER = "aerospace_workspace_change",
  FOCUSED_WORKSPACE = "3",
})
expect_equal(latest_set(items["workspace.3"]).background.color, colors.lavender, "string event updates focus promptly")

next_execution("list-workspaces").callback({
  { workspace = "1", ["workspace-is-focused"] = true },
  { workspace = "2", ["workspace-is-focused"] = false },
  { workspace = "3", ["workspace-is-focused"] = false },
  { workspace = "4", ["workspace-is-focused"] = false },
  { workspace = "5", ["workspace-is-focused"] = false },
}, 0)
expect_equal(latest_set(items["workspace.3"]).background.color, colors.lavender, "stale response does not overwrite event focus")

next_execution("list-workspaces").callback({
  { workspace = "1", ["workspace-is-focused"] = false },
  { workspace = "2", ["workspace-is-focused"] = false },
  { workspace = "3", ["workspace-is-focused"] = true },
  { workspace = "4", ["workspace-is-focused"] = false },
  { workspace = "5", ["workspace-is-focused"] = false },
}, 0)
expect_equal(latest_set(items["workspace.3"]).label.color, colors.bg, "queued refresh confirms latest focus")

observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback("not json", 0)
expect_equal(#workspace_items(), 5, "malformed discovery preserves registry")

observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback({}, 1)
expect_equal(#workspace_items(), 5, "failed discovery preserves the last valid registry")

observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback({
  { workspace = "5", ["workspace-is-focused"] = false },
  { workspace = "dev docs", ["workspace-is-focused"] = true },
  { workspace = "Bob's", ["workspace-is-focused"] = false },
}, 0)

spaces = workspace_items()
expect_equal(#spaces, 3, "workspace removal updates registry")
expect_equal(spaces[1].properties.label.string, "5", "workspace order is authoritative")
expect_equal(spaces[2].properties.label.string, "dev docs", "workspace names preserve spaces")
expect_equal(spaces[3].properties.label.string, "Bob's", "workspace names preserve quotes")
spaces[3].subscriptions["mouse.clicked"]()
local click = next_execution("workspace --")
expect_equal(
  click.command,
  "/opt/homebrew/bin/aerospace workspace -- 'Bob'\"'\"'s'",
  "click command shell-quotes the whole workspace name"
)

observer.subscriptions.routine({ SENDER = "routine" })
next_execution("list-workspaces").callback({}, 0)
expect_equal(#workspace_items(), 0, "valid empty snapshot clears workspace registry")

print("PASS: SketchyBar Lua configuration")
