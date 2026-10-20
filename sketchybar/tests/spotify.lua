-- Run from the repository root: lua sketchybar/tests/spotify.lua
package.path = "sketchybar/?.lua;sketchybar/?/init.lua;" .. package.path
local commands = {}
package.loaded.sketchybar = {
  exec = function(command, callback) commands[#commands + 1] = { command = command, callback = callback } end,
}
local spotify = require("helpers.spotify")

local function varint(value)
  local out = {}
  while value > 0x7f do
    out[#out + 1] = string.char(value & 0x7f | 0x80)
    value = value >> 7
  end
  return table.concat(out) .. string.char(value)
end
local function field(number, value)
  if math.type(value) == "integer" then return varint(number << 3) .. varint(value) end
  return varint(number << 3 | 2) .. varint(#value) .. value
end
local function frecency(entries)
  local out = {}
  for _, entry in ipairs(entries) do
    -- A fixed64 score (field 1) precedes the counters, as in Spotify's file.
    local stats = varint(1 << 3 | 1) .. string.rep("\0", 8) .. field(2, 1) .. field(4, entry[2])
    out[#out + 1] = field(1, field(1, entry[1]) .. field(2, stats))
  end
  return table.concat(out)
end

local uris = spotify.read_frecency(frecency({
  { "spotify:playlist:old", 100 }, { "spotify:album:skip", 900 }, { "spotify:playlist:new", 500 },
  { 'spotify:playlist:bad"uri', 999 }, { "spotify:playlist:old", 300 },
}))
assert(#uris == 2 and uris[1] == "spotify:playlist:new" and uris[2] == "spotify:playlist:old")
assert(not pcall(spotify.read_frecency, field(1, "\x0a\x7f")))

local playing = spotify.parse_player("playing\nSong — Live\nBand\n", 0)
assert(playing.running and playing.state == "playing" and playing.track == "Song — Live" and playing.artist == "Band")
assert(spotify.parse_player("stopped\n", 0).track == "")
assert(spotify.parse_player("__NOT_RUNNING__\n", 0).running == false)
assert(spotify.parse_player("", 1).error)
assert(spotify.parse_player("weird\n", 0).error)

-- Titles resolve through oEmbed once, then come from the in-memory cache.
local tmp = os.tmpname()
local file = assert(io.open(tmp, "wb"))
file:write(frecency({ { "spotify:playlist:aaa", 2 }, { "spotify:playlist:bbb", 1 } }))
file:close()
local results = {}
spotify.playlists(function(result) results[#results + 1] = result end)
assert(commands[1].command:find("ls -t", 1, true))
-- Stand in for `ls`: point the helper at the fixture via an absolute path.
local home = os.getenv("HOME") .. "/Library/Application Support/Spotify/Users/"
local relative = string.rep("../", select(2, home:gsub("/", "")) - 1) .. tmp:gsub("^/", "")
commands[1].callback(relative .. "\n")
assert(#commands == 3 and commands[2].command:find("oembed", 1, true))
commands[2].callback({ title = "Focus" })
commands[3].callback("curl: (6) offline")
assert(results[1].playlists[1].name == "Focus" and results[1].playlists[2].name == "Playlist")
spotify.playlists(function(result) results[#results + 1] = result end)
commands[4].callback(relative)
assert(#commands == 5 and commands[5].command:find("bbb", 1, true))
commands[5].callback({ title = "Late" })
assert(results[2].playlists[1].name == "Focus" and results[2].playlists[2].name == "Late")
os.remove(tmp)

spotify.playlists(function(result) results[#results + 1] = result end)
commands[#commands].callback("")
assert(results[3].error and #results[3].playlists == 0)
print("Spotify frecency parsing, player states, title lookup, and cache passed")
