-- [mem 69% 48G]: used share and total RAM. Menu MEMORY: used / free and
-- the top processes by memory, captured when the menu opens.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local stats = require("helpers.stats")
local text = require("helpers.text")

local c = theme.colors
local i = theme.island
local W = text.menu_width(33)
local TOP = 5

local item = sbar.add("item", "memory", {
  position = "right",
  padding_left = i.cell_gap,
  padding_right = 0,
  icon = { string = "mem", color = c.text3, padding_left = 0, padding_right = i.tag_gap },
  label = { string = "—", color = c.text, padding_left = 0, padding_right = 0 },
})

local function level(percent)
  if percent >= 90 then return c.err end
  if percent >= theme.thresholds.warn then return c.warn end
  return c.text
end

local function size(bytes)
  local gb = bytes / 1073741824
  if gb >= 1 then return string.format("%.1fG", gb) end
  return string.format("%.0fM", bytes / 1048576)
end

local snapshot
local menu = popup.new(item, {
  title = "MEMORY",
  width = W,
  align = "right",
  underline = island.underline_item(item),
  on_open = function() snapshot() end,
})
local used_row = menu:row("used", { key = "used", value = "—" })
local free_row = menu:row("free", { key = "free", value = "—" })
local top_row = menu:row("top", { value = "TOP PROCESSES", color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
top_row:set({ label = { y_offset = -4 } })
local procs = {}
for n = 1, TOP do procs[n] = menu:row("proc." .. n, { key = "", value = "", visible = false, key_color = c.text2 }) end
menu:row("open", { key = "open", value = "Activity Monitor ↗", color = c.text2,
  on_click = function() helper.open("/System/Applications/Utilities/Activity Monitor.app") end })
menu:finish()
menu:bind({ item })

stats.on(function(s)
  local m = s.memory
  if type(m) ~= "table" then return end
  item:set({ label = { string = string.format("%d%% %dG", m.percent, m.total_gb), color = level(m.percent) } })
  used_row:update({ value = string.format("%.1f / %d GB  (%d%%)", m.used_gb, m.total_gb, m.percent), color = level(m.percent) })
  free_row:update({ value = string.format("%.1f GB", m.total_gb - m.used_gb) })
end)

-- Frozen at the time of the click: the list is not refreshed while open.
snapshot = helper.single(function(done)
  top_row:update({ value = "TOP PROCESSES  …" })
  stats.refresh()
  helper.run({ "procs" }, function(r)
    done()
    top_row:update({ value = r.at and ("TOP PROCESSES  " .. os.date("%H:%M:%S", r.at)) or "TOP PROCESSES" })
    local list = r.processes or {}
    for n = 1, TOP do
      local p = list[n]
      procs[n]:update({ visible = p ~= nil, key = p and size(p.bytes) or "",
                        value = p and text.fit(p.name, W - theme.popup.key_width - 2 * theme.popup.padding) or "" })
    end
  end)
end)

return item
