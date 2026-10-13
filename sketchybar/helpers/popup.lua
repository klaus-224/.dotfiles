local sbar = require("sketchybar")
local colors = require("colors")

local popup = {}
local active

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
  end)
  -- Global exit includes the popup; leaving the parent for its rows stays open.
  item:subscribe({ "mouse.exited.global", "system_will_sleep", "front_app_switched" }, menu.close)
  return menu
end

return popup
