-- Builders for the island look: spacers, island brackets, circles, gauges
-- and popup-parent underlines. All geometry comes from theme.lua.
local sbar = require("sketchybar")
local theme = require("theme")

local c = theme.colors
local island = {}

function island.font(style, size, family)
  return string.format("%s:%s:%.1f", family or theme.font.text, style or "Regular", size or theme.font.size)
end

function island.spacer(name, position, width, extra)
  local props = {
    position = position,
    width = width,
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = false },
  }
  for k, v in pairs(extra or {}) do props[k] = v end
  return sbar.add("item", name, props)
end

function island.background(color, opacity)
  local i = theme.island
  return {
    drawing = true,
    color = theme.alpha(color or i.color, opacity or i.opacity),
    height = i.height,
    corner_radius = i.corner_radius,
    border_width = i.border_width,
    border_color = i.border_color,
  }
end

function island.bracket(name, members, color, opacity)
  return sbar.add("bracket", name, members, { background = island.background(color, opacity) })
end

-- Circle cell: a round item background with a pixel image inside.
function island.circle(name, position, image, extra)
  local h = theme.island.height
  local props = {
    position = position,
    width = h,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
    background = {
      drawing = true,
      color = theme.alpha(theme.island.color, theme.island.opacity),
      height = h,
      corner_radius = math.floor(h / 2),
      border_width = theme.island.border_width,
      border_color = theme.island.border_color,
      image = { string = image or "", scale = 0.5, drawing = image ~= nil },
    },
  }
  for k, v in pairs(extra or {}) do props[k] = v end
  return sbar.add("item", name, props)
end

local function underline_offset()
  return 1 - math.floor(theme.island.height / 2) + theme.island.border_width
end

-- Underline drawn by the item's own background (single-item cells).
-- Setting a background colour switches the background on, and SbarLua
-- sends table keys in no fixed order, so `drawing = false` goes separately.
local function underline_style()
  return {
    color = theme.underline.color,
    height = theme.underline.height,
    corner_radius = 0,
    border_width = 0,
    y_offset = underline_offset(),
  }
end

function island.underline_item(item)
  item:set({ background = underline_style() })
  item:set({ background = { drawing = false } })
  return { show = function(on) item:set({ background = { drawing = on } }) end }
end

-- Underline under several items; created after the island bracket so it
-- draws on top of the island fill.
function island.underline_group(name, members)
  local b = sbar.add("bracket", name, members, { background = underline_style() })
  b:set({ background = { drawing = false } })
  return { show = function(on) b:set({ background = { drawing = on } }) end }
end

-- Circles show an open menu with a bright rim instead of an underline.
function island.underline_circle(item)
  return { show = function(on)
    item:set({ background = { border_color = on and theme.underline.color or theme.island.border_color } })
  end }
end

-- Five 4×10 cells with 2pt gaps (volume, battery). Returns the items left
-- to right. Left items are added left to right; right and notch-queue
-- items right to left.
function island.gauge_cells(prefix, position, handler)
  local cells = {}
  local first, last, step = 5, 1, -1
  if position == "left" then first, last, step = 1, 5, 1 end
  for i = first, last, step do
    local cell = sbar.add("item", prefix .. "." .. i, {
      position = position,
      padding_left = 0,
      padding_right = i == 5 and 0 or 2,
      icon = { drawing = false },
      label = { string = "", width = 4, padding_left = 0, padding_right = 0 },
      background = { drawing = true, color = c.line, height = 10, corner_radius = 0, border_width = 0 },
    })
    if handler then cell:subscribe("mouse.clicked", handler) end
    cells[i] = cell
  end
  return cells
end

function island.fill_cells(cells, percent, color, empty)
  local n = math.floor(((tonumber(percent) or 0) + 19) / 20)
  for i, cell in ipairs(cells) do
    cell:set({ background = { color = i <= n and color or (empty or c.line) } })
  end
end

return island
