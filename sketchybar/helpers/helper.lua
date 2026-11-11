-- Runs `sbar-helper <args>`; the callback always gets a table (the parsed
-- JSON, or {error = ...}).
local sbar = require("sketchybar")
local config = require("config")

local helper = {}

local function exists(path)
  local f = io.open(path, "r")
  if f then f:close() end
  return f ~= nil
end

local path
for _, candidate in ipairs(config.helper) do
  if exists(candidate) then path = candidate; break end
end
helper.path = path

function helper.quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function helper.command(args)
  local parts = { helper.quote(path or "sbar-helper") }
  for _, a in ipairs(args) do parts[#parts + 1] = helper.quote(a) end
  return table.concat(parts, " ")
end

function helper.run(args, callback)
  if not path then
    if callback then callback({ error = "sbar-helper missing: run `just install-sketchybar-helper`" }) end
    return
  end
  sbar.exec(helper.command(args), function(result)
    if type(result) ~= "table" then result = { error = "sbar-helper failed" } end
    if callback then callback(result) end
  end)
end

-- Starts a helper that keeps running (output discarded).
function helper.spawn(args)
  if path then sbar.exec("/usr/bin/nohup " .. helper.command(args) .. " >/dev/null 2>&1 &") end
end

function helper.open(target)
  sbar.exec("/usr/bin/open " .. helper.quote(target))
end

-- Guards a refresh so a slow helper never runs twice at once.
function helper.single(fn)
  local busy = false
  return function(...)
    if busy then return end
    busy = true
    local args = { ... }
    fn(function() busy = false end, table.unpack(args))
  end
end

return helper
