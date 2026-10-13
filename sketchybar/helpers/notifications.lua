local sbar = require("sketchybar")
local colors = require("colors")
local popup = require("helpers.popup")
local command = require("helpers.command")

local notifications = {}

function notifications.add(key, app, icon, color)
  local name = "widgets." .. key
  local item = sbar.add("item", name, {
    position = "left",
    icon = { string = icon, color = colors.muted, padding_right = key == "slack" and 0 or 2 },
    label = { string = "" },
    update_freq = 10,
  })
  local function open_app() sbar.exec("/usr/bin/open -a " .. command.quote(app)) end
  local menu, status, preview_status
  local rows = {}
  local busy = false
  local function refresh_previews()
    if busy then return end
    busy = true
    command.run({ "notifications", key }, function(result)
      busy = false
      local messages = result.messages or {}
      preview_status:set({ label = { string = result.error
        or (#messages == 0 and "No recent notifications" or "Recent notifications · last 24 hours") } })
      for index, pair in ipairs(rows) do
        local message = messages[index]
        pair.title:set({ drawing = message ~= nil, label = { string = message and message.title or "" } })
        pair.body:set({ drawing = message ~= nil, label = { string = message and message.body or "" } })
      end
    end)
  end
  menu = popup.attach(item, name, refresh_previews, "left")
  status = menu.row("status", app)
  preview_status = menu.row("preview_status", "Loading notifications…")
  for index = 1, 5 do
    rows[index] = {
      title = menu.row("title." .. index, "", open_app),
      body = menu.row("body." .. index, "", open_app),
    }
    rows[index].title:set({ drawing = false })
    rows[index].body:set({ drawing = false })
  end
  menu.row("open", "Open " .. app, open_app)
  menu.row("settings", "Notification settings…", function()
    sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.Notifications-Settings.extension'")
  end)
  menu.row("access", "Preview access settings…", function()
    sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'")
  end)

  local badge_busy = false
  local function refresh()
    if badge_busy then return end
    badge_busy = true
    command.run({ "badge", key }, function(result)
      badge_busy = false
      local badge = result.badge or ""
      item:set({
        icon = { color = result.running and (badge ~= "" and colors.yellow or color) or colors.muted },
        label = { string = result.error and "?" or badge, color = colors.yellow },
      })
      status:set({ label = { string = result.error or (not result.running and app .. " is not running")
        or (badge == "" and "No unread badge") or ("Unread badge: " .. badge) } })
    end)
    if menu.open then refresh_previews() end
  end
  item:subscribe({ "routine", "forced", "system_woke", "aerospace_workspace_change" }, refresh)
  refresh()
  -- items.apps owns the shared app pill and its spacing.
  return item
end

return notifications
