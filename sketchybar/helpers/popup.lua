-- Popup menus in the island style: an uppercase title, rows of a muted key
-- column plus a value, gauge rows, and an underline under the open cell.
-- One menu is open at a time; a click anywhere outside it closes it.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")

local c = theme.colors
local p = theme.popup
local popup = {}
local active
local watching = false

local function contains(rects, x, y)
  for _, rect in pairs(type(rects) == "table" and rects or {}) do
    local o, s = rect.origin, rect.size
    if o and s and x >= o[1] and x <= o[1] + s[1] and y >= o[2] and y <= o[2] + s[2] then return true end
  end
  return false
end

-- `sbar-helper clickaway` returns the position of the next mouse press.
local function watch()
  if watching or not active then return end
  watching = true
  helper.run({ "clickaway" }, function(r)
    watching = false
    if not active then return end
    if r.x then
      if not active:contains(r.x, r.y) then active:close() end
      watch()
    elseif r.timeout then
      watch()
    end
  end)
end

local Row = {}
Row.__index = Row

local function font(size, style, family) return island.font(style, size, family) end

function Row:update(o)
  local props = {}
  if o.visible ~= nil then props.drawing = o.visible end
  if o.key ~= nil or o.key_color ~= nil then
    props.icon = { string = o.key, color = o.key_color }
  end
  if o.value ~= nil or o.color ~= nil then
    props.label = { string = o.value, color = o.color }
    if o.color then self.color = o.color end
  end
  self.item:set(props)
end

function Row:set(props) self.item:set(props) end
function Row:show(on) self.item:set({ drawing = on }) end

function popup.new(parent, opts)
  opts = opts or {}
  local menu = setmetatable({ parent = parent, name = parent.name, open = false, rows = {}, count = 0,
    width = opts.width or (2 * p.padding + math.ceil(33 * theme.font.char_width)), hosts = opts.hosts or {}, opts = opts }, { __index = popup })
  parent:set({ popup = {
    drawing = false,
    align = opts.align or "left",
    y_offset = p.y_offset,
    height = 1,
    blur_radius = p.blur_radius,
    background = {
      drawing = true,
      color = theme.alpha(p.color, p.opacity),
      border_color = p.border_color,
      border_width = p.border_width,
      corner_radius = p.corner_radius,
    },
  } })
  menu:pad(6)
  if opts.title then
    menu:row("heading", { key = opts.title, key_color = c.text2, key_font = font(theme.font.small, "Bold"), key_width = "dynamic", height = 24 })
    menu:pad(6)
  end
  parent:subscribe("system_will_sleep", function() menu:close() end)
  return menu
end

function popup:pad(height)
  self.count = self.count + 1
  sbar.add("item", self.name .. ".p" .. self.count, {
    position = "popup." .. self.name,
    icon = { drawing = false },
    label = { drawing = false },
    background = { drawing = true, color = c.transparent, height = height },
  })
end

-- o: key, value, color, key_color, key_width, height, on_click(env),
--    keep_open, key_font, value_font, align ("left"|"right")
function popup:row(id, o)
  o = o or {}
  self.count = self.count + 1
  local name = self.name .. ".r." .. id
  local has_key = o.key ~= nil
  local item = sbar.add("item", name, {
    position = "popup." .. self.name,
    width = self.width,
    drawing = o.visible ~= false,
    icon = {
      drawing = has_key,
      string = o.key or "",
      width = o.key_width or p.key_width,
      padding_left = p.padding,
      padding_right = 0,
      color = o.key_color or c.text3,
      font = o.key_font or font(),
    },
    label = {
      string = o.value or "",
      color = o.color or c.text,
      padding_left = has_key and 0 or p.padding,
      padding_right = p.padding,
      font = o.value_font or font(),
    },
    background = { drawing = true, color = c.transparent, height = o.height or p.row_height, corner_radius = 0, border_width = 0 },
  })
  local row = setmetatable({ item = item, name = name, color = o.color or c.text }, Row)
  self.rows[#self.rows + 1] = name
  if o.on_click then
    item:subscribe("mouse.clicked", function(env)
      if not o.keep_open then self:close() end
      o.on_click(env, row)
    end)
    item:subscribe("mouse.entered", function() item:set({ label = { color = c.text } }) end)
    item:subscribe("mouse.exited", function() item:set({ label = { color = row.color } }) end)
  end
  return row
end

-- A 50-cell bar under a value: filled cells in `color`, the rest in line.
function popup:gauge(id, cells, indent)
  local row = self:row(id, { height = 16 })
  row.cells = cells or 50
  row.indent = indent or (p.key_width + 1)
  row:set({ icon = { drawing = true, width = "dynamic", padding_left = row.indent, font = font(9.8, "Regular", theme.font.gauge) },
            label = { font = font(9.8, "Regular", theme.font.gauge), color = c.line, padding_right = 10 } })
  function row:fill(percent, color)
    local n = percent and math.max(0, math.min(self.cells, math.floor(percent / 100 * self.cells + 0.5))) or 0
    local both = n > 0 and n < self.cells
    self.item:set({
      icon = { drawing = n > 0, string = string.rep("▋", n), color = color },
      -- SketchyBar trims the gap where the two runs meet; 1pt restores it.
      label = { drawing = n < self.cells, string = string.rep("▋", self.cells - n),
                padding_left = n == 0 and self.indent or (both and 1 or 0) },
    })
  end
  return row
end

-- Adds the bottom padding; call after the last row.
function popup:finish() self:pad(6); return self end

function popup:contains(x, y)
  local names = { self.name }
  for _, h in ipairs(self.hosts) do names[#names + 1] = h end
  for _, r in ipairs(self.rows) do names[#names + 1] = r end
  for _, n in ipairs(names) do
    local q = sbar.query(n)
    if type(q) == "table" and contains(q.bounding_rects, x, y) then return true end
  end
  return false
end

function popup:show()
  if active and active ~= self then active:close() end
  active = self
  self.open = true
  if self.opts.on_open then self.opts.on_open() end
  self.parent:set({ popup = { drawing = true } })
  if self.opts.underline then self.opts.underline.show(true) end
  watch()
end

function popup:close()
  if not self.open then return end
  self.open = false
  self.parent:set({ popup = { drawing = false } })
  if self.opts.underline then self.opts.underline.show(false) end
  if active == self then active = nil end
  if self.opts.on_close then self.opts.on_close() end
end

function popup:toggle()
  if self.open then self:close() else self:show() end
end

-- Subscribes every item of a cell to open this menu.
function popup:bind(items)
  for _, it in ipairs(items) do
    it:subscribe("mouse.clicked", function() self:toggle() end)
  end
end

return popup
