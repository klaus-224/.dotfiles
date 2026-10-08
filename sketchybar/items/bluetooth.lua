local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local icons = require("icons")
local popup = require("helpers.popup")
local command = require("helpers.command")

sbar.add("item", "spacer.bluetooth", {
  position = "right", width = settings.group_paddings,
  icon = { drawing = false }, label = { drawing = false }, background = { drawing = false },
})
local item = sbar.add("item", "widgets.bluetooth", {
  position = "right", update_freq = 60,
  icon = { string = icons.bluetooth, color = colors.muted, padding_right = 2 * settings.paddings },
  label = { drawing = false },
})
local status, summary
local devices = {}
local busy = false
local function refresh()
  if busy then return end
  busy = true
  command.run({ "bluetooth" }, function(result)
    busy = false
    local connected = result.devices or {}
    item:set({ icon = { color = result.error and colors.muted
      or (result.enabled and colors.blue) or colors.muted } })
    status:set({ label = { string = result.error or (result.enabled and "Bluetooth on" or "Bluetooth off") } })
    summary:set({ drawing = result.error == nil, label = { string = #connected == 0 and "No connected devices"
      or (tostring(#connected) .. " connected devices") } })
    for index, row in ipairs(devices) do
      row:set({ drawing = connected[index] ~= nil, label = { string = connected[index] or "" } })
    end
  end)
end
local menu = popup.attach(item, "widgets.bluetooth", refresh)
status = menu.row("status", "Loading Bluetooth…")
summary = menu.row("summary", "")
for index = 1, 8 do
  devices[index] = menu.row("device." .. index, "")
  devices[index]:set({ drawing = false })
end
menu.row("settings", "Bluetooth settings…", function()
  sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.BluetoothSettings'")
end)
item:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()
sbar.add("bracket", "pill.bluetooth", { "widgets.bluetooth" }, {
  blur_radius = settings.blur_radius,
  background = { drawing = true, color = colors.pill_bg },
})
return item
