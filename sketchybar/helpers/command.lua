local sbar = require("sketchybar")
local command = {}

function command.quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

function command.run(arguments, callback)
  local path = assert(os.getenv("CONFIG_DIR")) .. "/helpers/status.py"
  local parts = {
    'PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"',
    "python3", command.quote(path),
  }
  for _, argument in ipairs(arguments) do parts[#parts + 1] = command.quote(argument) end
  sbar.exec(table.concat(parts, " "), function(result, code)
    if code ~= 0 or type(result) ~= "table" then
      result = { error = "Helper unavailable — check Python 3" }
    end
    callback(result)
  end)
end

return command
