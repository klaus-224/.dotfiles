local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")

local max_chars = 34
local current_app

local function media_item(name, properties)
  properties.position = "center"
  properties.drawing = false
  properties.updates = true
  return sbar.add("item", "media." .. name, properties)
end

local now_playing = media_item("now_playing", {
  padding_left = 10,
  padding_right = 5,
  icon = {
    string = "󰎆",
    color = colors.yellow,
    padding_right = 6,
  },
  label = {
    string = "",
    color = colors.fg,
    max_chars = max_chars,
  },
})

local previous = media_item("previous", {
  padding_left = 4,
  padding_right = 4,
  icon = { string = "󰒮", color = colors.muted },
  label = { drawing = false },
})

local play_pause = media_item("play_pause", {
  padding_left = 4,
  padding_right = 4,
  icon = { string = "󰏤", color = colors.fg },
  label = { drawing = false },
})

local next_track = media_item("next", {
  padding_left = 4,
  padding_right = 10,
  icon = { string = "󰒭", color = colors.muted },
  label = { drawing = false },
})

local members = {
  "media.now_playing",
  "media.previous",
  "media.play_pause",
  "media.next",
}

local bracket = sbar.add("bracket", "media.bracket", members, {
  drawing = false,
  background = {
    color = colors.pill_bg,
    border_color = colors.pill_border,
    border_width = settings.pill.border_width,
    corner_radius = settings.pill.corner_radius,
    height = settings.pill.height,
  },
})

local function set_drawing(drawing)
  now_playing:set({ drawing = drawing })
  previous:set({ drawing = drawing })
  play_pause:set({ drawing = drawing })
  next_track:set({ drawing = drawing })
  bracket:set({ drawing = drawing })
end

now_playing:subscribe("media_change", function(env)
  local info = type(env) == "table" and env.INFO or nil
  info = type(info) == "table" and info or {}
  current_app = info.app

  local title = info.title or ""
  local artist = info.artist or ""
  local text = title
  if title ~= "" and artist ~= "" then text = title .. " – " .. artist end
  if #text > max_chars then text = text:sub(1, max_chars - 1) .. "…" end

  local playing = info.state == "playing" and text ~= ""
  now_playing:set({ label = { string = text } })
  play_pause:set({ icon = { string = info.state == "playing" and "󰏤" or "󰐊" } })
  set_drawing(playing)
end)

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\"'\"'") .. "'"
end

local function control(command)
  return function()
    if not current_app or current_app == "" then return end
    local app = current_app:gsub("\\", "\\\\"):gsub('"', '\\"')
    local script = 'tell application "' .. app .. '" to ' .. command
    sbar.exec("/usr/bin/osascript -e " .. shell_quote(script) .. " >/dev/null 2>&1")
  end
end

previous:subscribe("mouse.clicked", control("previous track"))
play_pause:subscribe("mouse.clicked", control("playpause"))
next_track:subscribe("mouse.clicked", control("next track"))

return { bracket = bracket, members = members }
