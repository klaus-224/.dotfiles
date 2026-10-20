-- Run from the repository root: lua sketchybar/tests/menus.lua
package.path = "sketchybar/?.lua;sketchybar/?/init.lua;" .. package.path
local items, commands, callbacks = {}, {}, {}
local responses = {
  ["badge:slack"] = { running = true, badge = "4" },
  ["badge:teams"] = { running = true, badge = "•" },
  ["notifications:slack"] = { messages = { { title = "Sender", body = "Hello 世界" } } },
  ["notifications:teams"] = { messages = {} },
  wifi = { enabled = true, connected = true, ssid = "Office", ip = "192.168.1.2" },
  bluetooth = { enabled = true, devices = { "Keyboard" } },
  spotify = { running = true, state = "playing", track = "Song", artist = "Band" },
  ["spotify-playlists"] = { playlists = { { uri = "spotify:playlist:abc", name = "Focus" } } },
}
local function merge(target, values)
  for key, value in pairs(values) do
    if type(value) == "table" then
      target[key] = target[key] or {}
      merge(target[key], value)
    else target[key] = value end
  end
end
package.loaded.sketchybar = {
  add = function(kind, name, properties, bracket_properties)
    if kind == "event" then return end
    if kind == "bracket" then properties = bracket_properties end
    assert(not items[name], "Duplicate item: " .. name)
    local item = { props = properties, events = {} }
    function item:set(values) merge(self.props, values) end
    function item:subscribe(events, callback)
      if type(events) == "string" then events = { events } end
      for _, event in ipairs(events) do self.events[event] = callback end
    end
    local count = 0
    for _ in pairs(items) do count = count + 1 end
    item.origin = { count * 20, 0 }
    items[name] = item
    return item
  end,
  exec = function(command, callback)
    commands[#commands + 1] = command
    callbacks[command] = callback
  end,
  -- Every item sits at a distinct 10x10 cell so clicks can target it.
  query = function(name)
    local item = assert(items[name], "Unknown item: " .. name)
    local children = {}
    for child, value in pairs(items) do
      if value.props.position == "popup." .. name then children[#children + 1] = child end
    end
    return { bounding_rects = { ["display-1"] = { origin = item.origin, size = { 10, 10 } } },
      popup = { items = children } }
  end,
}
local command = require("helpers.command")
assert(command.quote("a'b $(no)") == "'a'\\''b $(no)'")
command.run = function(args, callback)
  callback(assert(responses[table.concat(args, ":")]))
end
local spotify = require("helpers.spotify")
spotify.player = function(callback) callback(responses.spotify) end
spotify.playlists = function(callback) callback(responses["spotify-playlists"]) end
local popup = require("helpers.popup")
local function click(name)
  local watcher = assert(callbacks[popup.click_watcher], "No click watcher running")
  callbacks[popup.click_watcher] = nil
  local origin = name and items[name].origin or { -50, -50 }
  watcher(string.format("%d %d\n", origin[1] + 5, origin[2] + 5))
end

for _, name in ipairs({ "slack", "teams", "wifi", "bluetooth", "spotify" }) do require("items." .. name) end
local function event(name, kind) items["widgets." .. name].events[kind]() end
local function props(name) return items["widgets." .. name].props end
assert(props("slack").label.string == "4")
assert(props("teams").label.string == "•")
for _, name in ipairs({ "slack", "teams", "wifi", "bluetooth" }) do
  local position = (name == "slack" or name == "teams") and "left" or "right"
  assert(props(name).position == position)
  assert(props(name).popup.align == position)
  assert(props(name).icon.string ~= "")
  assert(props(name).popup.drawing == false)
end
event("slack", "mouse.clicked")
assert(props("slack").popup.drawing)
assert(props("slack.body.1").drawing and props("slack.body.1").label.string == "Hello 世界")
event("teams", "mouse.clicked")
assert(not props("slack").popup.drawing and props("teams").popup.drawing)
event("teams", "mouse.clicked")
assert(not props("teams").popup.drawing)
event("wifi", "mouse.clicked")
assert(props("wifi").popup.drawing and props("wifi.network").label.string == "Office")
event("wifi", "mouse.exited.global")
assert(not props("wifi").popup.drawing)
event("bluetooth", "mouse.clicked")
assert(props("bluetooth.device.1").label.string == "Keyboard")
event("bluetooth.settings", "mouse.clicked")
assert(not props("bluetooth").popup.drawing)
assert(commands[#commands]:find("BluetoothSettings", 1, true))
event("slack", "mouse.clicked")
responses["badge:slack"] = { running = true, badge = "" }
responses["notifications:slack"] = { error = "Access denied" }
event("slack", "routine")
assert(props("slack").label.string == "")
assert(not props("slack.body.1").drawing)
assert(props("slack.preview_status").label.string == "Access denied")
responses["badge:slack"] = { error = "Unavailable" }
event("slack", "routine")
assert(props("slack").label.string == "?" and props("slack").icon.string ~= "")
event("slack", "front_app_switched")
assert(not props("slack").popup.drawing)
responses.bluetooth = { error = "Unavailable" }
event("bluetooth", "routine")
assert(not props("bluetooth.device.1").drawing)
assert(props("spotify").position == "left" and props("spotify").popup.align == "left")
event("spotify", "mouse.clicked")
assert(props("spotify").popup.drawing and not props("bluetooth").popup.drawing)
assert(props("spotify.track").label.string == "Song" and props("spotify.artist").label.string == "Band")
assert(props("spotify.toggle").label.string == "Pause")
assert(props("spotify.playlist.1").drawing and props("spotify.playlist.1").label.string:find("Focus", 1, true))
assert(not props("spotify.playlist.2").drawing)
event("spotify.playlist.1", "mouse.clicked")
assert(not props("spotify").popup.drawing)
assert(commands[#commands]:find('play track "spotify:playlist:abc"', 1, true))
responses.spotify = { running = false }
event("spotify", "routine")
assert(props("spotify.status").label.string == "Spotify is not running" and not props("spotify.track").drawing)
assert(not props("spotify.toggle").drawing)
event("wifi", "mouse.clicked")
click("widgets.wifi.status")
assert(props("wifi").popup.drawing)
click("widgets.wifi")
assert(props("wifi").popup.drawing)
click("widgets.slack")
assert(not props("wifi").popup.drawing)
assert(callbacks[popup.click_watcher] == nil)
event("spotify", "mouse.clicked")
click()
assert(not props("spotify").popup.drawing)
print("Popup lifecycle, badges, previews, actions, and failure recovery passed")
