local sbar = require("sketchybar")
local colors = require("colors")
local icons = require("icons")
local popup = require("helpers.popup")
local command = require("helpers.command")

local item = sbar.add("item", "widgets.spotify", {
  position = "left",
  update_freq = 10,
  icon = { string = icons.spotify, color = colors.muted, padding_right = 2 },
  label = { drawing = false },
})

local function open_app() sbar.exec('/usr/bin/open -a "Spotify"') end
local function control(verb)
  return function()
    -- Spotify posts PlaybackStateChanged afterwards, which refreshes the item.
    sbar.exec("/usr/bin/osascript -e " .. command.quote('tell application "Spotify" to ' .. verb))
  end
end

local menu, status, track, artist, toggle, playlist_status
local playlists, rows = {}, {}
local busy, playlists_busy = false, false
local function refresh_playlists()
  if playlists_busy then return end
  playlists_busy = true
  command.run({ "spotify-playlists" }, function(result)
    playlists_busy = false
    playlists = result.playlists or {}
    playlist_status:set({ label = { string = result.error
      or (#playlists == 0 and "No recent playlists" or "Recently played playlists") } })
    for index, row in ipairs(rows) do
      local playlist = playlists[index]
      row:set({ drawing = playlist ~= nil, label = { string = playlist and ("  " .. playlist.name) or "" } })
    end
  end)
end
local function refresh()
  if busy then return end
  busy = true
  command.run({ "spotify" }, function(result)
    busy = false
    local playing = result.state == "playing"
    local has_track = result.running and result.state ~= "stopped" and (result.track or "") ~= ""
    item:set({ icon = { color = playing and colors.green or (result.running and colors.fg) or colors.muted } })
    status:set({ label = { string = result.error or (not result.running and "Spotify is not running")
      or (playing and "Now playing") or (result.state == "paused" and "Paused") or "Nothing playing" } })
    track:set({ drawing = has_track, label = { string = has_track and result.track or "" } })
    artist:set({ drawing = has_track and result.artist ~= "", label = { string = has_track and result.artist or "" } })
    toggle:set({ drawing = result.running == true, label = { string = playing and "Pause" or "Play" } })
  end)
end

menu = popup.attach(item, "widgets.spotify", function() refresh(); refresh_playlists() end, "left")
status = menu.row("status", "Loading Spotify…")
track = menu.row("track", "", open_app)
artist = menu.row("artist", "")
track:set({ drawing = false, label = { color = colors.green } })
artist:set({ drawing = false, label = { color = colors.muted } })
toggle = menu.row("toggle", "Play", control("playpause"))
menu.row("next", "Next track", control("next track"))
playlist_status = menu.row("playlist_status", "Loading playlists…")
for index = 1, 5 do
  rows[index] = menu.row("playlist." .. index, "", function()
    local playlist = playlists[index]
    -- The helper only returns URIs matching spotify:playlist:[A-Za-z0-9]+.
    if playlist then control('play track "' .. playlist.uri .. '"')() end
  end)
  rows[index]:set({ drawing = false })
end
menu.row("open", "Open Spotify", open_app)

sbar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
item:subscribe({ "routine", "forced", "system_woke", "spotify_change" }, refresh)
refresh()

return item
