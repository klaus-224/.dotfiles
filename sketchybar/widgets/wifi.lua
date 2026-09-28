local colors = require("colors")

return {
  name = "wifi",
  icon = "󰤨",
  update_freq = 30,
  events = { "routine", "forced", "wifi_change", "system_woke" },
  command = [=[/bin/sh -c '
summary=$(/usr/sbin/ipconfig getsummary en0 2>/dev/null)
ssid=$(printf "%s\n" "$summary" | /usr/bin/awk -F " : " "/^[[:space:]]*SSID : / { print \$2; exit }")
if [ -z "$ssid" ]; then
  airport=$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null)
  case "$airport" in "Current Wi-Fi Network: "*) ssid=${airport#Current Wi-Fi Network: };; esac
fi
if [ "$ssid" = "<redacted>" ]; then ssid=; fi
if [ -n "$ssid" ]; then printf "ssid:%s" "$ssid"
elif /usr/sbin/ipconfig getifaddr en0 >/dev/null 2>&1; then printf connected
else printf disconnected
fi']=],
  parse = function(output)
    if type(output) ~= "string" then return nil end
    if output == "connected" or output == "disconnected" then return { state = output } end
    local ssid = output:match("^ssid:(.+)$")
    if ssid then return { state = "connected", ssid = ssid } end
    return nil
  end,
  render = function(state)
    if not state or state.state == "disconnected" then
      return { icon = { string = "󰤭", color = colors.muted }, label = { string = "" } }
    end
    return {
      icon = { string = "󰤨", color = colors.fg },
      label = { string = state.ssid or "" },
    }
  end,
  on_click = "/usr/bin/open x-apple.systempreferences:com.apple.wifi-settings-extension",
}
