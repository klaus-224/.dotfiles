-- [04-11 17:30]: date (dd-mm) and time. Menu CALENDAR: month view with
-- paging, then today's events with their times.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")

local c = theme.colors
local i = theme.island
local W = text.menu_width(34)
local NAMES = { "SU", "MO", "TU", "WE", "TH", "FR", "SA" }

-- The island's end padding is a spacer that hosts the menu, so the menu's
-- right edge meets the island edge while the underline stays clear of the
-- rounded corner. Right items are added right to left.
local edge = island.spacer("clock.edge", "right", i.inner)
local item = sbar.add("item", "clock", {
  position = "right",
  padding_left = i.cell_gap,
  padding_right = 0,
  update_freq = 1,
  icon = { string = os.date("%d-%m"), color = c.text3, padding_left = 0, padding_right = i.tag_gap },
  label = { string = os.date("%H:%M"), color = c.text, padding_left = 0, padding_right = 0 },
})
item:subscribe({ "routine", "forced", "system_woke" }, function()
  item:set({ icon = { string = os.date("%d-%m") }, label = { string = os.date("%H:%M") } })
end)

local offset = 0
local events, events_error = {}, nil
local month_row, header_row, week_rows, today_row, event_rows, empty_row

local fetch
local menu = popup.new(edge, {
  title = "CALENDAR",
  width = W,
  align = "right",
  hosts = { "clock" },
  underline = island.underline_item(item),
  on_open = function() offset = 0; fetch(true) end,
})

local function hard_row(id, o)
  o.value_font = o.value_font or island.font()
  local row = menu:row(id, o)
  return row
end

-- One row: [‹ 10    2026.11    12 ›]. SketchyBar reports no click position,
-- so a click asks the helper where the pointer is: the left third pages
-- back, the right third forward, the middle returns to this month.
local function page(row_name)
  helper.run({ "mouse" }, function(at)
    local q = sbar.query(row_name)
    for _, r in pairs(type(q) == "table" and q.bounding_rects or {}) do
      if at.x and r.origin and r.size[1] > 0 then
        local third = (at.x - r.origin[1]) / r.size[1] * 3
        if third < 1 then offset = offset - 1 elseif third >= 2 then offset = offset + 1 else offset = 0 end
        fetch(false)
        return
      end
    end
  end)
end
month_row = hard_row("month", { value = "", keep_open = true, on_click = function(_, row) page(row.name) end })
header_row = hard_row("weekdays", { value = "", color = c.text3 })
week_rows = {}
for w = 1, 6 do week_rows[w] = hard_row("week." .. w, { value = "", visible = false }) end
today_row = menu:row("today", { value = "TODAY", color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
today_row:set({ label = { y_offset = -4 } })
event_rows = {}
for e = 1, config.calendar.max_events do
  event_rows[e] = menu:row("event." .. e, { key = "", value = "", visible = false,
    on_click = function() helper.open("/System/Applications/Calendar.app") end })
end
empty_row = menu:row("empty", { value = "No events today", color = c.text3, visible = false })
menu:row("open", { value = "Calendar ↗", color = c.text2, on_click = function() helper.open("/System/Applications/Calendar.app") end })
menu:finish()

local inner = W - 2 * theme.popup.padding

local function render_month(m)
  local ws = config.calendar.week_start or 0
  local prev = (m.month + 10) % 12 + 1
  local nxt = m.month % 12 + 1
  local left, title, right = string.format("‹ %02d", prev), string.format("%04d.%02d", m.year, m.month), string.format("%02d ›", nxt)
  -- The title centred in the 34-column grid; another month shows in accent.
  local cols = math.floor(inner / theme.font.char_width + 0.5)
  local at = (cols - #title) // 2
  local line = left .. string.rep(" ", at - utf8.len(left)) .. title
  line = line .. string.rep(" ", cols - utf8.len(line) - utf8.len(right)) .. right
  month_row:update({ value = text.hard(line), color = m.offset == 0 and c.text or c.accent })
  local head = {}
  for k = 0, 6 do head[#head + 1] = NAMES[(k + ws) % 7 + 1] end
  header_row:update({ value = text.hard(" " .. table.concat(head, "   ")) })
  local lead = (m.first_weekday - ws) % 7
  local cells, rows = {}, {}
  for _ = 1, lead do cells[#cells + 1] = "     " end
  for d = 1, m.days do
    cells[#cells + 1] = d == m.today and string.format("[%2d] ", d) or string.format(" %2d  ", d)
    if #cells == 7 or d == m.days then
      rows[#rows + 1] = (table.concat(cells):gsub("%s+$", ""))
      cells = {}
    end
  end
  for w = 1, 6 do
    week_rows[w]:update({ visible = rows[w] ~= nil, value = text.hard(rows[w] or "") })
  end
end

local function render_events()
  local max_title = W - theme.popup.key_width - 2 * theme.popup.padding
  if events_error then
    event_rows[1]:update({ visible = true, key = "!", value = "Calendar access needed ↗", color = c.warn })
    for e = 2, #event_rows do event_rows[e]:update({ visible = false }) end
    empty_row:update({ visible = false })
    return
  end
  for e, row in ipairs(event_rows) do
    local ev = events[e]
    if ev then
      local color = ev.ended and c.text3 or (ev.now and c.accent or c.text)
      row:update({ visible = true, key = ev.all_day and "all day" or os.date("%H:%M", ev.start),
                   key_color = ev.now and c.accent or c.text3, value = text.fit(ev.title, max_title), color = color })
    else
      row:update({ visible = false })
    end
  end
  empty_row:update({ visible = #events == 0 })
end

fetch = helper.single(function(done, with_events)
  local args = { "calendar", tostring(offset) }
  if not with_events then args[#args + 1] = "--no-events" end
  helper.run(args, function(r)
    done()
    if not r.year then return end
    render_month(r)
    if with_events then
      events_error = r.error
      events = r.events or {}
      render_events()
    end
  end)
end)

-- The access-needed row opens the Calendars privacy pane.
event_rows[1].item:subscribe("mouse.clicked", function()
  if events_error then helper.open("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") end
end)

menu:bind({ item, edge })
item:subscribe("mouse.scrolled", function(env)
  if not menu.open then return end
  local delta = tonumber(env.INFO and env.INFO.delta) or 0
  offset = offset + (delta > 0 and -1 or 1)
  fetch(false)
end)
fetch(true)

return item
