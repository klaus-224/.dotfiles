-- Apps island between the CPU cat and the right island:
-- [󰒱 3  󰊻 1  󰡨 2  󰆚].
-- An app shows only when installed (the island and its gap disappear when
-- none is). The icon is coloured while the app runs, grey when not. The
-- count is the Dock badge for Slack and Teams, and the running containers
-- (Kubernetes pods left out) for Docker Desktop and Rancher Desktop.
-- Menus: recent notification previews (Slack adds its status presets), or
-- the running containers.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")

local c = theme.colors
local i = theme.island
local W = text.menu_width(41)
local INNER = W - theme.popup.key_width - 2 * theme.popup.padding
local ROWS = 5 -- messages or containers per menu
local CELL_GAP = 14
-- Left to right as drawn.
local APPS = {
  { key = "slack", app = "Slack", title = "SLACK", glyph = "\u{F04B1}", color = c.slack,
    bundle = "com.tinyspeck.slackmacgap", kind = "messages" },
  { key = "teams", app = "Microsoft Teams", title = "TEAMS", glyph = "\u{F02BB}", color = c.teams,
    bundle = "com.microsoft.teams2", kind = "messages" },
  { key = "docker", app = "Docker Desktop", title = "DOCKER", glyph = "\u{F0868}", color = c.docker,
    bundle = "com.docker.docker", kind = "containers" },
  { key = "rancher", app = "Rancher Desktop", title = "RANCHER", glyph = "\u{F019A}", color = c.rancher,
    bundle = "io.rancherdesktop.app", kind = "containers" },
}

-- Right side adds right to left: the gap to the right island, the island
-- end padding, the cells, the other end padding.
local gap = island.spacer("gap.apps", "right", i.gap, { drawing = false })
local pad_r = island.spacer("apps.pad.r", "right", i.inner, { drawing = false })
local cells = {}
local members = { "apps.pad.r" }
for n = #APPS, 1, -1 do
  local spec = APPS[n]
  cells[spec.key] = sbar.add("item", "apps." .. spec.key, {
    position = "right",
    drawing = false,
    padding_left = 0, -- gap to the cell on the left is set in sync_cells
    padding_right = 0,
    update_freq = 10,
    updates = true, -- keeps polling while hidden (app not installed yet)
    icon = { string = spec.glyph, font = island.font("Regular", theme.font.size + 4, theme.font.icons), color = c.text3,
             padding_left = 0, padding_right = 0 },
    label = { string = "", color = c.text, padding_left = 4, padding_right = 0, drawing = false },
  })
  table.insert(members, 1, "apps." .. spec.key)
end
local pad_l = island.spacer("apps.pad.l", "right", i.inner, { drawing = false })
table.insert(members, 1, "apps.pad.l")
local bracket = island.bracket("island.apps", members)
bracket:set({ background = { drawing = false } })

local installed = {}
local function sync_cells()
  local any = false
  for _, spec in ipairs(APPS) do
    -- A cell keeps a gap to the cell on its left only when one is shown.
    cells[spec.key]:set({ padding_left = any and CELL_GAP or 0 })
    any = any or installed[spec.key] == true
  end
  for _, it in ipairs({ gap, pad_l, pad_r }) do it:set({ drawing = any }) end
  bracket:set({ background = { drawing = any } })
end

local function clock(t)
  local today = os.date("%Y%m%d") == os.date("%Y%m%d", t)
  return os.date(today and "%H:%M" or "%d-%m", t)
end

local function heading(menu, id, value)
  local row = menu:row(id, { value = value, color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
  row:set({ label = { y_offset = -4 } })
  return row
end

-- Slack status: current status and the presets from config.lua.
local function slack_status(menu)
  heading(menu, "status.h", "STATUS")
  local now = menu:row("status.now", { key = "now", value = "—", color = c.text2 })
  local function apply(r)
    if r.error then
      now:update({ value = text.fit(r.error, INNER), color = c.text3 })
      return
    end
    local value = r.text ~= "" and r.text or (r.emoji ~= "" and r.emoji or "no status")
    if r.expires and r.expires > 0 then value = value .. " · until " .. os.date("%H:%M", r.expires) end
    now:update({ value = text.fit(value, INNER), color = r.text ~= "" and c.text or c.text3 })
  end
  for n, preset in ipairs(config.slack_status) do
    local dur = preset.minutes > 0 and (preset.minutes >= 60 and (preset.minutes // 60) .. "h" or preset.minutes .. "m") or "—"
    menu:row("status.set." .. n, {
      key = n == 1 and "set" or "", value = text.hard(text.spread(preset.text, dur, INNER)), color = c.text2, keep_open = true,
      on_click = function()
        now:update({ value = "setting…", color = c.text3 })
        helper.run({ "slack-status", "set", preset.emoji, preset.text, tostring(preset.minutes) }, apply)
      end,
    })
  end
  menu:row("status.clear", { key = "", value = "Clear status", color = c.text2, keep_open = true, on_click = function()
    now:update({ value = "clearing…", color = c.text3 })
    helper.run({ "slack-status", "clear" }, apply)
  end })
  return function() helper.run({ "slack-status" }, apply) end
end

-- Menu list of title/body row pairs (messages or containers).
local function pair_list(menu, on_click)
  local pairs_ = {}
  for n = 1, ROWS do
    pairs_[n] = {
      title = menu:row("msg." .. n, { key = "", value = "", visible = false, on_click = on_click }),
      body = menu:row("body." .. n, { key = "", value = "", visible = false, color = c.text2, on_click = on_click }),
    }
  end
  local empty = menu:row("empty", { value = "", color = c.text3, visible = false })
  -- entries: { key, title, body }; body = nil hides the body row.
  return function(list, empty_text)
    for n, pair in ipairs(pairs_) do
      local m = list[n]
      pair.title:update({ visible = m ~= nil, key = m and m.key or "", value = m and text.fit(m.title, INNER) or "" })
      pair.body:update({ visible = m ~= nil and m.body ~= nil, value = m and m.body and text.fit(m.body, INNER) or "" })
    end
    empty:update({ visible = #list == 0, value = empty_text })
  end
end

local function app(spec)
  local item = cells[spec.key]
  local containers = spec.kind == "containers"
  local preview
  local open_app = function() sbar.exec("/usr/bin/open -b " .. helper.quote(spec.bundle)) end

  local menu = popup.new(item, {
    title = spec.title,
    width = W,
    align = "right",
    underline = island.underline_item(item),
    on_open = function() preview() end,
  })
  local status_row = menu:row("status", { key = "app", value = "—" })
  heading(menu, "messages", containers and "CONTAINERS" or "MESSAGES")
  local show = pair_list(menu, open_app)
  local status_preview = spec.key == "slack" and slack_status(menu) or nil
  menu:row("open", { key = "open", value = spec.app .. " ↗", color = c.text2, on_click = open_app })
  menu:finish()
  menu:bind({ item })

  preview = helper.single(function(done)
    if status_preview then status_preview() end
    if containers then
      helper.run({ "containers", spec.key }, function(r)
        done()
        local list, shown = r.containers or {}, {}
        for n, m in ipairs(list) do
          if n == ROWS and #list > ROWS then
            shown[n] = { key = "", title = "+" .. (#list - ROWS + 1) .. " more" }
            break
          end
          shown[n] = { key = "", title = m.name, body = m.image .. " · " .. m.status }
        end
        show(shown, r.error or (r.engine and "No running containers" or "Engine not running"))
      end)
    else
      helper.run({ "notifications", spec.key }, function(r)
        done()
        local shown = {}
        for n, m in ipairs(r.messages or {}) do
          shown[n] = { key = clock(m.at), title = m.title, body = m.body }
        end
        show(shown, r.error or "No recent notifications")
      end)
    end
  end)

  local refresh = helper.single(function(done)
    helper.run({ "app", spec.key }, function(r)
      done()
      if r.error then return end
      installed[spec.key] = r.installed == true
      sync_cells()
      local badge = r.badge or ""
      item:set({
        drawing = r.installed == true,
        icon = { color = r.running and spec.color or c.text3 },
        label = { string = badge, drawing = badge ~= "" },
      })
      local what = containers and "running" or "unread"
      local none = containers and "running · no containers" or "running · no unread"
      status_row:update({ value = not r.running and "not running"
        or (badge == "" and none or ("running · " .. badge .. " " .. what)),
        color = r.running and c.text or c.text3 })
    end)
  end)
  item:subscribe({ "routine", "forced", "system_woke", "front_app_switched" }, refresh)
  refresh()
end

for _, spec in ipairs(APPS) do app(spec) end

return { members = members }
