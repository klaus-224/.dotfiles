local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local icons = require("icons")
local popup = require("helpers.popup")
local command = require("helpers.command")

sbar.add("item", "spacer.wifi", {
  position = "right", width = settings.group_paddings,
  icon = { drawing = false }, label = { drawing = false }, background = { drawing = false },
})
local item = sbar.add("item", "widgets.wifi", {
  position = "right", update_freq = 30,
  icon = { string = icons.wifi, color = colors.muted, padding_right = 2 * settings.paddings },
  label = { drawing = false },
})
local status, network, address
local busy = false
local function refresh()
  if busy then return end
  busy = true
  command.run({ "wifi" }, function(result)
    busy = false
    item:set({ icon = { color = result.error and colors.muted
      or (result.connected and colors.green) or (result.enabled and colors.yellow) or colors.muted } })
    status:set({ label = { string = result.error or (result.enabled and "Wi-Fi on" or "Wi-Fi off") } })
    network:set({ drawing = result.error == nil, label = { string = result.connected
      and (result.ssid ~= "" and result.ssid or "Connected · network name unavailable") or "Not connected" } })
    address:set({ drawing = result.error == nil,
      label = { string = result.ip and result.ip ~= "" and ("IP: " .. result.ip) or "IP: —" } })
  end)
end
local menu = popup.attach(item, "widgets.wifi", refresh)
status = menu.row("status", "Loading Wi-Fi…")
network = menu.row("network", "")
address = menu.row("address", "")
menu.row("settings", "Wi-Fi settings…", function()
  sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
end)
item:subscribe({ "routine", "forced", "wifi_change", "system_woke" }, refresh)
refresh()
sbar.add("bracket", "pill.wifi", { "widgets.wifi" }, {
  blur_radius = settings.blur_radius,
  background = { drawing = true, color = colors.pill_bg },
})
return item
