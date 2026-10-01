local sbar = require("sketchybar")
local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local bytes_per_gb = 1024 ^ 3

local function parse(output)
  if type(output) ~= "string" then return nil end
  local total = tonumber(output:match("^%s*(%d+)%s"))
  local page_size = tonumber(output:match("page size of (%d+) bytes"))
  local anonymous = tonumber(output:match("Anonymous pages:%s*(%d+)"))
  local purgeable = tonumber(output:match("Pages purgeable:%s*(%d+)"))
  local wired = tonumber(output:match("Pages wired down:%s*(%d+)"))
  local compressed = tonumber(output:match("Pages occupied by compressor:%s*(%d+)"))
  if not total or total <= 0 or not page_size or page_size <= 0
      or not anonymous or not purgeable or not wired or not compressed then
    return nil
  end

  -- Count physical compressor pages, not the uncompressed pages stored inside.
  local used = (math.max(0, anonymous - purgeable) + wired + compressed) * page_size
  return { used = math.min(used, total), total = total }
end

local function render(state)
  if not state then
    return { icon = { color = colors.muted }, label = { string = "-- GB / -- GB" } }
  end

  local percentage = 100 * state.used / state.total
  local color = colors.green
  if percentage > 80 then
    color = colors.red
  elseif percentage > 60 then
    color = colors.yellow
  end

  return {
    icon = { color = color },
    label = {
      string = string.format("%.1f GB / %g GB", state.used / bytes_per_gb, state.total / bytes_per_gb),
    },
  }
end

sbar.add("item", "spacer.memory", {
  position = "right",
  width = settings.group_paddings,
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
})

local item = sbar.add("item", "widgets.memory", {
  position = "right",
  icon = { string = icons.memory },
  label = { string = "-- GB / -- GB" },
  update_freq = 10,
})

local function refresh()
  sbar.exec("/usr/sbin/sysctl -n hw.memsize && /usr/bin/vm_stat", function(output, exit_code)
    local state
    if exit_code == 0 then
      local ok, parsed = pcall(parse, output)
      if ok then state = parsed end
    end
    item:set(render(state))
  end)
end

item:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()

sbar.add("bracket", "pill.memory", { "widgets.memory" }, {
  background = { color = colors.pill_bg },
})

return item
