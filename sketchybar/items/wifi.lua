-- [wifi home-5G]. Menu WI-FI: ssid, ip, router, signal, saved networks in
-- range (scanned when the menu opens; click one to join), Wi-Fi Settings.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")

local c = theme.colors
local i = theme.island
local W = text.menu_width(33)
local VALUE_W = W - theme.popup.key_width - 2 * theme.popup.padding
local MAX_NETWORKS = 4

local item = sbar.add("item", "wifi", {
  position = "right",
  padding_left = i.cell_gap,
  padding_right = 0,
  update_freq = 30,
  icon = { string = "wifi", color = c.text3, padding_left = 0, padding_right = i.tag_gap },
  label = { string = "—", color = c.text, padding_left = 0, padding_right = 0 },
})

local function strength(rssi)
  rssi = tonumber(rssi) or -100
  if rssi >= -55 then return "\u{F0928}" end
  if rssi >= -65 then return "\u{F0925}" end
  if rssi >= -75 then return "\u{F0922}" end
  return "\u{F091F}"
end

local info = {}
local scanning, scan_status, networks = false, nil, {}
local ssid_row, ip_row, router_row, signal_row, nets_row, net_rows

local menu
local scan
menu = popup.new(item, {
  title = "WI-FI",
  width = W,
  align = "right",
  underline = island.underline_item(item),
  on_open = function() scan() end,
})
ssid_row = menu:row("ssid", { key = "ssid", value = "—" })
ip_row = menu:row("ip", { key = "ip", value = "—" })
router_row = menu:row("router", { key = "router", value = "—" })
signal_row = menu:row("signal", { key = "signal", value = "—" })
nets_row = menu:row("networks", { value = "NETWORKS", color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
nets_row:set({ label = { y_offset = -4 } })
net_rows = {}
local join
for n = 1, MAX_NETWORKS do
  net_rows[n] = menu:row("net." .. n, {
    key = "", key_font = island.font("Regular", 14, theme.font.icons), value = "", visible = false, keep_open = true,
    on_click = function(_, row) if row.ssid then join(row) end end,
  })
end
menu:row("settings", { key = "open", value = "Wi-Fi Settings ↗", color = c.text2,
  on_click = function() helper.open("x-apple.systempreferences:com.apple.wifi-settings-extension") end })
menu:finish()

local function render()
  local name = info.ssid
  if info.connected then
    item:set({ label = { string = text.fit(name or "on", 16 * theme.font.char_width), color = c.text } })
  else
    item:set({ label = { string = "off", color = c.err } })
  end
  ssid_row:update({ value = info.connected and text.fit(name or "name hidden", VALUE_W) or "not connected",
                    color = info.connected and c.text or c.text3 })
  ip_row:update({ value = info.ip or "—" })
  router_row:update({ value = info.router or "—" })
  signal_row:update({ value = info.rssi and (info.rssi .. " dBm") or "—" })
  nets_row:update({ value = scanning and "NETWORKS  …" or "NETWORKS" })
  local shown = 0
  if scan_status == "denied" or scan_status == "undetermined" then
    shown = 1
    net_rows[1]:update({ visible = true, key = "!", value = "Location access needed ↗", color = c.text3 })
    net_rows[1].ssid = nil
    net_rows[1].settings = true
  else
    for _, net in ipairs(networks) do
      shown = shown + 1
      local row = net_rows[shown]
      row.ssid, row.settings, row.current = net.ssid, nil, net.current
      row:update({ visible = true, key = strength(net.rssi), key_color = net.current and c.text or c.text3,
        value = net.current and text.spread(text.fit(net.ssid, VALUE_W - 20), "✓", VALUE_W) or text.fit(net.ssid, VALUE_W),
        color = net.current and c.text or c.text2 })
      if shown == MAX_NETWORKS then break end
    end
    if shown == 0 then
      shown = 1
      net_rows[1].ssid = nil
      net_rows[1]:update({ visible = true, key = "", value = scanning and "Scanning …" or "No saved networks nearby", color = c.text3 })
    end
  end
  for n = shown + 1, MAX_NETWORKS do net_rows[n]:update({ visible = false }) end
end

local refresh = helper.single(function(done)
  helper.run({ "wifi" }, function(r)
    done()
    if r.error then return end
    info = r
    render()
  end)
end)

scan = helper.single(function(done)
  scanning = true
  render()
  helper.run({ "wifi", "scan" }, function(r)
    done()
    scanning = false
    scan_status = r.status
    networks = r.networks or {}
    render()
    refresh()
  end)
end)

join = function(row)
  if row.current then return end
  row:update({ value = text.spread(text.fit(row.ssid, VALUE_W - 40), "···", VALUE_W), color = c.text3 })
  helper.run({ "wifi", "join", row.ssid }, function(r)
    if r.ok then refresh(); scan() else
      row:update({ value = text.spread(text.fit(row.ssid, VALUE_W - 60), "failed", VALUE_W), color = c.err })
      sbar.delay(3, function() render() end)
    end
  end)
end
net_rows[1].item:subscribe("mouse.clicked", function()
  if net_rows[1].settings then helper.open("x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") end
end)

menu:bind({ item })
item:subscribe({ "routine", "forced", "wifi_change", "system_woke" }, refresh)
refresh()

return item
