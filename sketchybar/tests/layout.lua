-- Loads the whole config against a mocked SbarLua with fixture helper data.
-- Run from the repository root: lua sketchybar/tests/layout.lua
local root = os.getenv("SKETCHYBAR_TEST_CONFIG") or "sketchybar"
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local items, order, events = {}, {}, {}
local pending_exec, delays = {}, {}
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

function sbar.add(kind, name, a, b)
  if kind == "event" then events[name] = a or true; return end
  assert(not items[name], "duplicate item " .. name)
  local item = { name = name, properties = {}, handlers = {}, kind = kind }
  local props = (kind == "bracket" or kind == "slider") and b or a
  if kind == "bracket" then
    item.members = a
    for _, m in ipairs(a) do assert(items[m], "bracket " .. name .. " references missing item " .. m) end
  end
  merge(item.properties, props or {})
  function item:set(values) merge(self.properties, values) end
  function item:subscribe(evs, handler)
    if type(evs) == "string" then evs = { evs } end
    for _, e in ipairs(evs) do self.handlers[e] = handler end
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

function sbar.end_config() for name in pairs(items) do committed[name] = true end end
function sbar.query(domain)
  if domain == "displays" then sbar.end_config(); return display_list end
  return { bounding_rects = {} }
end
function sbar.exec(command, callback)
  pending_exec[#pending_exec + 1] = { command = command, callback = callback }
end
function sbar.delay(seconds, fn) delays[#delays + 1] = fn end
function sbar.default() end
function sbar.bar() end
function sbar.begin_config() end
function sbar.hotload() end
function sbar.event_loop() end
function sbar.trigger() end
package.loaded.sketchybar = sbar

-- Point the helper at an existing file so commands are issued.
local config = require("config")
config.helper = { root .. "/tests/layout.lua" }

local now = os.time()
local fixtures = {
  usage = { claude = { five = { used = 19, resets_at = now + 3600 }, week = { used = 11, resets_at = now + 86400 }, updated_at = now },
            opencode = { today = { tokens = 1200000, cost = 0.42, sessions = 2 }, week = { tokens = 5e6, cost = 3.1, sessions = 9 },
                         month = { tokens = 9e6, cost = 7, sessions = 20 }, models = { { name = "claude-sonnet", tokens = 4e6, cost = 2 } } } },
  agents = { agents = { { key = "claude:a", agent = "claude", name = "dotfiles", state = "working" },
                        { key = "opencode:b", agent = "opencode", name = "api", state = "waiting" } } },
  system = { cpu = 42, cores = 10, memory = { used = 1, total = 2, percent = 69, used_gb = 33.1, total_gb = 48 },
             disk = { total_gb = 995, free_gb = 497, used_gb = 498 }, battery = { percent = 15, ac = false, charging = false, remaining = "1:10" } },
  procs = { processes = { { pid = 1, name = "Arc", bytes = 7e8, mb = 667 } }, at = now },
  ["app slack"] = { installed = true, running = true, badge = "3" },
  ["app teams"] = { installed = false, running = false, badge = "" },
  ["notifications slack"] = { messages = { { title = "#general", body = "hello", at = now } } },
  ["slack-status"] = { error = "Add a Slack token to the Keychain item 'sketchybar-slack'" },
  wifi = { interface = "en0", power = true, connected = true, ssid = "home-5G", ip = "192.168.1.24", router = "192.168.1.1", rssi = -51 },
  ["wifi scan"] = { status = "ok", networks = { { ssid = "home-5G", rssi = -51, current = true }, { ssid = "office", rssi = -70, current = false } } },
  audio = { volume = 40, muted = false, settable = true, device = "MacBook Pro Speakers", kind = "builtin",
            devices = { { id = 83, name = "MacBook Pro Speakers", kind = "builtin", current = true }, { id = 99, name = "AirPods", kind = "bluetooth", current = false } } },
  spotify = { installed = true, running = true, state = "playing", title = "Night Drive", artist = "Example Band",
              album = "A", duration = 263, position = 72, art = "/tmp/art.jpg" },
  calendar = { year = 2026, month = 11, first_weekday = 0, days = 30, today = 4, offset = 0,
               events = { { title = "Standup", start = now - 7200, ["end"] = now - 6000, all_day = false, ended = true, now = false },
                          { title = "Design review", start = now + 600, ["end"] = now + 3600, all_day = false, ended = false, now = false } } },
  pixels = { files = 38 },
  clickaway = { timeout = true },
}

-- Answers queued helper commands from the fixtures until none are left.
local function drain()
  local guard = 0
  while #pending_exec > 0 do
    guard = guard + 1
    assert(guard < 500, "exec loop did not settle")
    local job = table.remove(pending_exec, 1)
    local args = {}
    for word in job.command:gmatch("'([^']*)'") do args[#args + 1] = word end
    table.remove(args, 1)
    local key = table.concat(args, " ")
    local data = fixtures[key] or fixtures[args[1] .. (args[2] and (" " .. args[2]) or "")] or fixtures[args[1]]
    if key:match("^calendar") then data = fixtures.calendar end
    if key:match("^pixels") then data = fixtures.pixels end
    if job.command:find("list-workspaces", 1, true) then data = { { ["monitor-appkit-nsscreen-screens-id"] = 1, workspace = "2" } } end
    if job.callback and key ~= "clickaway" then job.callback(data or {}, data and 0 or 1) end
  end
end

require("items")
sbar.end_config()
drain()
-- Run each timer once (cat, EQ, pilo frames).
local timers = delays
delays = {}
for _, fn in ipairs(timers) do fn() end
drain()

local function position_list(position, display)
  local list = {}
  for _, name in ipairs(order) do
    local it = items[name]
    local p = it.properties
    if it.kind ~= "bracket" and p.position == position and not name:match("^spacer")
      and (not p.display or p.display == display) then
      if position == "left" then list[#list + 1] = name else table.insert(list, 1, name) end
    end
  end
  return table.concat(list, ",")
end

-- Layout ---------------------------------------------------------------------
local left = position_list("left", 1)
assert(left:find("^bar.start,workspace.logo.1,workspace.1.1,workspace.1.2,workspace.1.3,workspace.1.4,workspace.1.5,front_app.1"),
  "unexpected left layout: " .. left)
local right = position_list("right")
assert(right:find("apps.pad.l,apps.slack,apps.teams,apps.pad.r,gap.apps,pilo,gap.pilo,cpu,gap.cpu,agents,agents.claude,agents.codex,agents.opencode,memory,battery,battery.1",
  1, true), "unexpected right layout: " .. right)
assert(right:find("battery.5,wifi,clock,clock.edge$"), "right island must end with wifi, clock: " .. right)
assert(left:find("front_app.1,.-media.gap,media.fill,media.eq.1,media.eq.2,media.eq.3,media,media.prev,media.play,media.next,"
  .. "volume.sep,volume,volume.1,volume.2,volume.3,volume.4,volume.5,volume.pad$"), "media island after AeroSpace: " .. left)
assert(position_list("q") == "", "nothing left of the notch")
for _, b in ipairs({ "island.left.1", "island.left.2", "island.media", "island.right", "island.apps", "shield" }) do
  assert(items[b] and items[b].kind == "bracket", "missing bracket " .. b)
end

-- Rendered values ------------------------------------------------------------
local theme = require("theme")
local c = theme.colors
local P = function(name) return items[name].properties end
assert(P("media").label.string == "Night Drive", "media title: " .. tostring(P("media").label.string))
assert(P("media.play").label.string == "\u{F03E4}", "pause glyph while playing")
assert(P("media.fill").drawing == true and P("media.fill").label.width > 0, "progress fill shown")
local f = P("media.fill")
assert(f.padding_left + f.label.width + f.padding_right == 0, "fill must take no space")
assert(f.label.width >= 2 * f.background.corner_radius, "fill never narrower than its corners")
assert(P("agents.claude").label.string == "81%", "claude 5h remaining: " .. tostring(P("agents.claude").label.string))
assert(P("agents.codex").drawing == false, "codex hidden when not installed")
assert(P("agents.opencode").label.string == "1.2M", "opencode tokens today")
assert(P("memory").label.string == "69% 48G", "memory label: " .. tostring(P("memory").label.string))
assert(P("battery.1").background.color == c.err and P("battery.2").background.color == c.line, "low battery is red")
assert(P("wifi").label.string == "home-5G")
assert(P("clock").icon.string == os.date("%d-%m"), "date is dd-mm")
assert(P("apps.slack").drawing == true and P("apps.slack").icon.color == c.slack, "Slack red while running")
assert(P("apps.slack").label.string == "3", "Slack badge")
assert(P("apps.teams").drawing == false, "Teams hidden when not installed")
assert(P("workspace.1.2").label.color == c.text and P("workspace.1.1").label.color == c.text3, "active workspace")
assert(P("cpu").background.image.string:find("cat_%d"), "cat frame")
assert(P("pilo").background.image.string:find("pilo_waiting_"), "pilo shows the most urgent state")

-- Every menu opens without errors and shows rows --------------------------------
local owner = { clock = "clock.edge" } -- items whose menu lives on another item
for _, name in ipairs({ "media", "volume", "clock", "wifi", "battery", "memory", "agents", "cpu", "pilo", "apps.slack" }) do
  local handler = items[name].handlers["mouse.clicked"]
  assert(handler, name .. " has no click handler")
  handler({})
  drain()
  assert(P(owner[name] or name).popup.drawing == true, name .. " menu did not open")
  handler({})
  assert(P(owner[name] or name).popup.drawing == false, name .. " menu did not close")
end
assert(P("memory.r.proc.1").label.string == "Arc", "top process captured on open")
assert(P("clock.edge.r.week.1").label.string:find("1"), "calendar grid")
local nav = P("clock.edge.r.month").label.string:gsub("\u{00A0}", " ")
assert(nav == "‹ 10         2026.11          12 ›", "calendar nav row: [" .. nav .. "]")
assert(P("clock.edge.r.event.2").label.string == "Design review")
assert(P("wifi.r.net.1").label.string:find("✓"), "current network marked")
assert(P("apps.slack.r.msg.1").label.string == "#general")
assert(P("agents.r.claude.5h").label.string:find("^81%%.*left.*reset$"), "5h row")

-- Opening a second menu closes the first.
items["clock"].handlers["mouse.clicked"]({})
items["wifi"].handlers["mouse.clicked"]({})
assert(P("clock.edge").popup.drawing == false and P("wifi").popup.drawing == true, "one menu at a time")

-- A reconnecting display gets its island back before the anchor.
display_list = { { ["arrangement-id"] = 1 } }
items["aerospace.observer"].handlers["display_change"]({})
drain()
assert(not items["workspace.logo.2"], "disconnected display retained")

print("PASS: layout, rendered values, menus, display changes")
