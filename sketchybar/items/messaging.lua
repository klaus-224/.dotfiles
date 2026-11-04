-- Slack / Teams at the start of the right island: [󰒱 3  󰊻 1   agent …].
-- An app shows only when installed (both cells and their spacers disappear
-- when neither is). Slack is red and Teams blue while running, grey when
-- not. The count is the app's Dock badge.
-- Menus: recent notification previews; Slack adds its status presets.
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
local MESSAGES = 5
local APPS = {
  { key = "teams", app = "Microsoft Teams", glyph = "\u{F02BB}", color = c.teams, bundle = "com.microsoft.teams2" },
  { key = "slack", app = "Slack", glyph = "\u{F04B1}", color = c.slack, bundle = "com.tinyspeck.slackmacgap" },
}

-- Right side adds right to left: the gap to the agents cell (whose own
-- padding is the island end padding), Teams, Slack, the island end padding.
local pad_r = island.spacer("apps.pad.r", "right", i.cell_gap - i.inner)
local cells = {}
for n, spec in ipairs(APPS) do
  cells[spec.key] = sbar.add("item", "apps." .. spec.key, {
    position = "right",
    drawing = false,
    padding_left = 0, -- Teams' gap to Slack is set in sync_cells
    padding_right = 0,
    update_freq = 10,
    updates = true, -- keeps polling while hidden (app not installed yet)
    icon = { string = spec.glyph, font = island.font("Regular", theme.font.size + 4, theme.font.icons), color = c.text3,
             padding_left = 0, padding_right = 0 },
    label = { string = "", color = c.text, padding_left = 4, padding_right = 0, drawing = false },
  })
end
local pad_l = island.spacer("apps.pad.l", "right", i.inner)

local installed = {}
local function sync_cells()
  local any = installed.slack or installed.teams
  pad_l:set({ drawing = any or false })
  pad_r:set({ drawing = any or false })
  -- Teams keeps a gap to Slack only when Slack is there.
  cells.teams:set({ padding_left = installed.slack and 14 or 0 })
end

local function clock(t)
  local today = os.date("%Y%m%d") == os.date("%Y%m%d", t)
  return os.date(today and "%H:%M" or "%d-%m", t)
end

local function messaging(spec)
  local item = cells[spec.key]
  local status_row, header_row, pairs_, empty_row
  local slack_rows
  local preview
  local open_app = function() sbar.exec("/usr/bin/open -b " .. helper.quote(spec.bundle)) end

  local menu = popup.new(item, {
    title = spec.app:upper():gsub("MICROSOFT ", ""),
    width = W,
    align = "right",
    underline = island.underline_item(item),
    on_open = function() preview() end,
  })
  status_row = menu:row("status", { key = "app", value = "—" })
  header_row = menu:row("messages", { value = "MESSAGES", color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
  header_row:set({ label = { y_offset = -4 } })
  pairs_ = {}
  for n = 1, MESSAGES do
    pairs_[n] = {
      title = menu:row("msg." .. n, { key = "", value = "", visible = false, on_click = open_app }),
      body = menu:row("body." .. n, { key = "", value = "", visible = false, color = c.text2, on_click = open_app }),
    }
  end
  empty_row = menu:row("empty", { value = "No recent notifications", color = c.text3, visible = false })

  if spec.key == "slack" then
    slack_rows = { presets = {} }
    local h = menu:row("status.h", { value = "STATUS", color = c.text3, value_font = island.font("Regular", theme.font.small), height = 32 })
    h:set({ label = { y_offset = -4 } })
    slack_rows.now = menu:row("status.now", { key = "now", value = "—", color = c.text2 })
    local function apply(r)
      if r.error then
        slack_rows.now:update({ value = text.fit(r.error, INNER), color = c.text3 })
        return
      end
      local value = r.text ~= "" and r.text or (r.emoji ~= "" and r.emoji or "no status")
      if r.expires and r.expires > 0 then value = value .. " · until " .. os.date("%H:%M", r.expires) end
      slack_rows.now:update({ value = text.fit(value, INNER), color = r.text ~= "" and c.text or c.text3 })
    end
    slack_rows.apply = apply
    for n, preset in ipairs(config.slack_status) do
      local dur = preset.minutes > 0 and (preset.minutes >= 60 and (preset.minutes // 60) .. "h" or preset.minutes .. "m") or "—"
      slack_rows.presets[n] = menu:row("status.set." .. n, {
        key = n == 1 and "set" or "", value = text.hard(text.spread(preset.text, dur, INNER)), color = c.text2, keep_open = true,
        on_click = function()
          slack_rows.now:update({ value = "setting…", color = c.text3 })
          helper.run({ "slack-status", "set", preset.emoji, preset.text, tostring(preset.minutes) }, apply)
        end,
      })
    end
    menu:row("status.clear", { key = "", value = "Clear status", color = c.text2, keep_open = true, on_click = function()
      slack_rows.now:update({ value = "clearing…", color = c.text3 })
      helper.run({ "slack-status", "clear" }, apply)
    end })
  end
  menu:row("open", { key = "open", value = spec.app .. " ↗", color = c.text2, on_click = open_app })
  menu:finish()
  menu:bind({ item })

  preview = helper.single(function(done)
    if slack_rows then helper.run({ "slack-status" }, slack_rows.apply) end
    helper.run({ "notifications", spec.key }, function(r)
      done()
      local list = r.messages or {}
      for n, pair in ipairs(pairs_) do
        local m = list[n]
        pair.title:update({ visible = m ~= nil, key = m and clock(m.at) or "", value = m and text.fit(m.title, INNER) or "" })
        pair.body:update({ visible = m ~= nil, value = m and text.fit(m.body, INNER) or "" })
      end
      empty_row:update({ visible = #list == 0, value = r.error or "No recent notifications" })
    end)
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
      status_row:update({ value = not r.running and "not running"
        or (badge == "" and "running · no unread" or ("running · " .. badge .. " unread")),
        color = r.running and c.text or c.text3 })
    end)
  end)
  item:subscribe({ "routine", "forced", "system_woke", "front_app_switched" }, refresh)
  refresh()
end

for _, spec in ipairs(APPS) do messaging(spec) end

return { members = { "apps.pad.l", "apps.slack", "apps.teams", "apps.pad.r" } }
