local sbar = require("sketchybar")
local command = require("helpers.command")

local spotify = {}
local users = (os.getenv("HOME") or "") .. "/Library/Application Support/Spotify/Users"
-- Public playlist titles, kept for the life of the SketchyBar process.
local names = {}

local function varint(data, index)
  local value, shift = 0, 0
  while true do
    local byte = data:byte(index)
    if not byte then error("Truncated protobuf") end
    index = index + 1
    value = value | ((byte & 0x7f) << shift)
    shift = shift + 7
    if byte < 0x80 then return value, index end
  end
end

-- Iterates (field, value); value is a string for length-delimited fields,
-- an integer for varints, and false for fixed-width fields.
local function fields(data)
  local index = 1
  return function()
    if index > #data then return nil end
    local key, field, wire, value
    key, index = varint(data, index)
    field, wire = key >> 3, key & 7
    if wire == 0 then
      value, index = varint(data, index)
    elseif wire == 2 then
      local length
      length, index = varint(data, index)
      value, index = data:sub(index, index + length - 1), index + length
    elseif wire == 1 or wire == 5 then
      value, index = false, index + (wire == 1 and 8 or 4)
    else
      error("Unsupported protobuf wire type")
    end
    if index > #data + 1 then error("Truncated protobuf") end
    return field, value
  end
end

-- Spotify's private frecency.pb backs its "Recents": each entry holds a URI
-- (field 1) and stats (field 2) whose field 4 is the last-used Unix time.
function spotify.read_frecency(data)
  local used, uris = {}, {}
  for field, entry in fields(data) do
    if field == 1 and type(entry) == "string" then
      local uri, last = "", 0
      for key, value in fields(entry) do
        if key == 1 and type(value) == "string" then uri = value
        elseif key == 2 and type(value) == "string" then
          for stat, number in fields(value) do
            if stat == 4 and math.type(number) == "integer" then last = number end
          end
        end
      end
      if uri:match("^spotify:playlist:%w+$") then
        if not used[uri] then uris[#uris + 1] = uri end
        used[uri] = math.max(last, used[uri] or 0)
      end
    end
  end
  table.sort(uris, function(a, b)
    if used[a] ~= used[b] then return used[a] > used[b] end
    return a < b
  end)
  return uris
end

function spotify.parse_player(output, code)
  if code ~= 0 or type(output) ~= "string" then
    return { error = "Spotify unavailable — check Automation access" }
  end
  local lines = {}
  for line in (output .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
  if lines[1] == "__NOT_RUNNING__" then return { running = false } end
  if lines[1] ~= "playing" and lines[1] ~= "paused" and lines[1] ~= "stopped" then
    return { error = "Spotify status unavailable" }
  end
  return { running = true, state = lines[1], track = lines[2] or "", artist = lines[3] or "" }
end

-- Checking `is running` first keeps the query from launching Spotify.
local player_script = [[
if application "Spotify" is running then
  tell application "Spotify"
    set playerState to player state as text
    if playerState is "stopped" then return playerState
    return playerState & linefeed & (name of current track) & linefeed & (artist of current track)
  end tell
end if
return "__NOT_RUNNING__"]]

function spotify.player(callback)
  sbar.exec("/usr/bin/osascript -e " .. command.quote(player_script), function(output, code)
    callback(spotify.parse_player(output, code))
  end)
end

local function resolve(playlists, callback)
  local pending = 0
  for _, playlist in ipairs(playlists) do
    if not names[playlist.uri] then pending = pending + 1 end
  end
  local function finish()
    for _, playlist in ipairs(playlists) do playlist.name = names[playlist.uri] or "Playlist" end
    callback({ playlists = playlists })
  end
  if pending == 0 then return finish() end
  for _, playlist in ipairs(playlists) do
    if not names[playlist.uri] then
      local id = playlist.uri:match("(%w+)$")
      local url = "https://open.spotify.com/oembed?url=https%3A%2F%2Fopen.spotify.com%2Fplaylist%2F" .. id
      sbar.exec("/usr/bin/curl -fsS -m 3 " .. command.quote(url), function(result)
        if type(result) == "table" and type(result.title) == "string" and result.title ~= "" then
          names[playlist.uri] = result.title
        end
        pending = pending - 1
        if pending == 0 then finish() end
      end)
    end
  end
end

function spotify.playlists(callback, limit)
  limit = limit or 5
  local newest = "cd " .. command.quote(users) .. " 2>/dev/null && /bin/ls -t */frecency.pb 2>/dev/null | /usr/bin/head -1"
  sbar.exec(newest, function(output)
    local path = type(output) == "string" and output:match("^%s*(.-)%s*$") or ""
    if path == "" then
      return callback({ error = "No Spotify listening history found", playlists = {} })
    end
    local file = io.open(users .. "/" .. path, "rb")
    local data = file and file:read("a")
    if file then file:close() end
    local ok, uris = pcall(spotify.read_frecency, data or "")
    if not data or not ok then
      return callback({ error = "Spotify history unreadable", playlists = {} })
    end
    local playlists = {}
    for index = 1, math.min(limit, #uris) do playlists[index] = { uri = uris[index] } end
    resolve(playlists, callback)
  end)
end

return spotify
