local sbar = require("sketchybar")
local colors = require("colors")
local command = require("helpers.command")

local popup = {}
local active
local watching = false

-- Lua cannot read the mouse, so one JXA process waits for the next button
-- press and prints where it landed, in SketchyBar's top-left coordinates.
popup.click_watcher = "/usr/bin/osascript -l JavaScript -e " .. command.quote([[
ObjC.import("AppKit")
const height = $.NSScreen.screens.objectAtIndex(0).frame.size.height
let held = $.NSEvent.pressedMouseButtons !== 0
while (true) {
  const pressed = $.NSEvent.pressedMouseButtons !== 0
  if (pressed && !held) break
  held = pressed
  delay(0.03)
}
const point = $.NSEvent.mouseLocation
`${point.x} ${height - point.y}`]])

local function contains(rects, x, y)
  for _, rect in pairs(type(rects) == "table" and rects or {}) do
    local origin, size = rect.origin, rect.size
    if origin and size and x >= origin[1] and x <= origin[1] + size[1]
      and y >= origin[2] and y <= origin[2] + size[2] then
      return true
    end
  end
  return false
end

-- Closes the open menu on a click outside its item and popup rows. At most
-- one watcher runs; it stops after the first click with no menu open.
local function watch()
  if watching or not active then return end
  watching = true
  sbar.exec(popup.click_watcher, function(output)
    watching = false
    if not active then return end
    local x, y = tostring(output):match("^%s*(%-?[%d.]+) (%-?[%d.]+)")
    if x and not active.contains(tonumber(x), tonumber(y)) then active.close() end
    watch()
  end)
end

function popup.attach(item, name, refresh, align)
  local menu = { open = false }
  item:set({ popup = {
    drawing = false,
    align = align or "right",
    background = {
      color = colors.bg,
      border_color = colors.purple,
      border_width = 2,
      corner_radius = 12,
    },
  } })

  function menu.close()
    menu.open = false
    item:set({ popup = { drawing = false } })
    if active == menu then active = nil end
  end

  function menu.contains(x, y)
    local parent = sbar.query(name)
    if type(parent) ~= "table" then return false end
    if contains(parent.bounding_rects, x, y) then return true end
    for _, row in ipairs(parent.popup and parent.popup.items or {}) do
      local child = sbar.query(row)
      if type(child) == "table" and contains(child.bounding_rects, x, y) then return true end
    end
    return false
  end

  function menu.row(id, text, action)
    local row = sbar.add("item", name .. "." .. id, {
      position = "popup." .. name,
      width = 380,
      icon = { drawing = false },
      label = {
        string = text,
        align = "left",
        padding_left = 12,
        padding_right = 12,
        max_chars = 38,
      },
      background = { drawing = false },
    })
    if action then
      row:subscribe("mouse.clicked", function()
        menu.close()
        action()
      end)
      row:subscribe("mouse.entered", function() row:set({ label = { color = colors.cyan } }) end)
      row:subscribe("mouse.exited", function() row:set({ label = { color = colors.fg } }) end)
    end
    return row
  end

  item:subscribe("mouse.clicked", function()
    if menu.open then menu.close(); return end
    if active then active.close() end
    active = menu
    menu.open = true
    item:set({ popup = { drawing = true } })
    refresh()
    watch()
  end)
  -- Global exit includes the popup; leaving the parent for its rows stays open.
  item:subscribe({ "mouse.exited.global", "system_will_sleep", "front_app_switched" }, menu.close)
  return menu
end

return popup
