-- Media island, right of the AeroSpace island:
--   [ EQ  spotify  title   󰒮 󰐊 󰒭  | volume ▮▮▮▯▯ ]
-- A progress fill sweeps the island behind the text. Menu MEDIA: cover,
-- title, artist, time, gauge, controls, open Spotify.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")
local ticker = require("helpers.ticker")
local volume = require("items.volume")

local c = theme.colors
local i = theme.island
local APP = "spotify"
local app_w = text.width(APP)
local title_w = theme.media.title_width
-- Nerd Font media glyphs: drawn on one centred box, unlike text arrows.
local G = { prev = "\u{F04AE}", play = "\u{F040A}", pause = "\u{F03E4}", next = "\u{F04AD}" }
local CTL_W = 22 -- control button width
-- Estimated island width (fallback before layout): eq 29 + app/title + controls + sep 1 +
-- volume glyph 34 + gauge 28 + inner right 11.
local ISLAND_W = 29 + (app_w + i.tag_gap + title_w) + 12 + 3 * CTL_W + 12 + 1 + 34 + 28 + i.inner
-- The fill sits 2pt inside the island; its corners follow the island's.
local FILL_R = math.max(0, i.corner_radius - 2)

-- Left items are added left to right, after the AeroSpace island.
island.spacer("media.gap", "left", i.gap)
-- Zero-footprint fill at the island's left edge (+2): padding_left + width +
-- padding_right = 0. Added before the text so it draws beneath it.
local fill = sbar.add("item", "media.fill", {
  position = "left",
  drawing = false,
  padding_left = 2,
  padding_right = -2,
  icon = { drawing = false },
  label = { string = "", width = 0, padding_left = 0, padding_right = 0 },
  background = { drawing = true, color = theme.media.fill, height = i.height - 4,
                 corner_radius = FILL_R, border_width = 0 },
})

local members = {}
local eq = {}
-- { width, padding_right, padding_left } for bars 1..3, left to right.
for n, spec in ipairs({ { 2, 2, i.inner }, { 2, 2, 0 }, { 2, 8, 0 } }) do
  eq[n] = sbar.add("item", "media.eq." .. n, {
    position = "left",
    padding_left = spec[3],
    padding_right = spec[2],
    icon = { drawing = false },
    label = { string = "", width = spec[1], padding_left = 0, padding_right = 0 },
    background = { drawing = true, color = c.bg, height = 2, y_offset = -4, corner_radius = 0, border_width = 0 },
  })
  members[#members + 1] = eq[n]
end

local media = sbar.add("item", "media", {
  position = "left",
  padding_left = 0,
  padding_right = 0,
  update_freq = 5,
  icon = { string = APP, color = c.text3, width = app_w + i.tag_gap, padding_left = 0, padding_right = 0 },
  label = { string = "—", width = title_w, align = "left", color = c.text, padding_left = 0, padding_right = 0 },
})
members[#members + 1] = media

local function control(name, glyph, pad_left, pad_right)
  local it = sbar.add("item", name, {
    position = "left",
    padding_left = pad_left,
    padding_right = pad_right,
    icon = { drawing = false },
    label = { string = glyph, font = island.font("Regular", theme.font.size + 2, theme.font.icons),
              width = CTL_W, align = "center", color = c.text3, padding_left = 0, padding_right = 0 },
  })
  members[#members + 1] = it
  return it
end
local prev_b = control("media.prev", G.prev, 12, 0)
local play_b = control("media.play", G.play, 0, 0)
local next_b = control("media.next", G.next, 0, 12)

for _, it in ipairs(volume.add()) do members[#members + 1] = it end

local names = {}
for _, it in ipairs(members) do names[#names + 1] = it.name end
island.bracket("island.media", names, theme.media.color, theme.media.opacity)
volume.menu.opts.underline = island.underline_group("volume.u", volume.underline_members)

-- EQ bars: heights step every 0.5 s while playing; bottoms stay level.
local frames = { { 4, 8, 6 }, { 8, 6, 10 }, { 6, 10, 4 }, { 10, 6, 8 }, { 6, 8, 10 } }
local frame = 0
local eq_loop = ticker.every(0.5, function()
  frame = frame % #frames + 1
  for n = 1, 3 do
    local h = frames[frame][n]
    eq[n]:set({ background = { height = h, y_offset = (h - 10) // 2 } })
  end
end)
local function eq_idle(color)
  eq_loop.stop()
  for n = 1, 3 do eq[n]:set({ background = { color = color, height = 2, y_offset = -4 } }) end
end

-- Menu ---------------------------------------------------------------------
local state = { state = "none" }
local W = 262
local art_row, title_row, artist_row, time_row, gauge_row, toggle_row, rows
local refresh
-- Spotify posts PlaybackStateChanged afterwards; the delayed refresh covers
-- the cases where it does not (e.g. launching the app).
local function run(cmd)
  return function() helper.run({ "spotify", cmd }, function() sbar.delay(0.4, function() refresh() end) end) end
end

local menu = popup.new(media, {
  title = "MEDIA",
  width = W,
  align = "left",
  hosts = { "media.eq.1", "media.eq.2", "media.eq.3" },
  underline = island.underline_item(media),
  on_open = function() refresh() end,
})
art_row = menu:row("art", { height = 238 })
-- 476 px covers (helper-resized) drawn at 0.5 = 238 pt.
art_row:set({ width = 238, padding_left = theme.popup.padding, padding_right = theme.popup.padding,
  label = { drawing = false },
  background = { drawing = true, color = c.bg, height = 238, image = { string = "", scale = 0.5, drawing = false } } })
title_row = menu:row("title", { value = "", color = c.text })
artist_row = menu:row("artist", { value = "", color = c.text2 })
time_row = menu:row("time", { key = "", key_width = "dynamic", key_color = c.text2, color = c.text3 })
gauge_row = menu:gauge("gauge", 40, theme.popup.padding)
local function ctl_row(id, glyph, label, cmd)
  return menu:row(id, { key = glyph, key_font = island.font("Regular", theme.font.size, theme.font.icons),
    value = label, keep_open = true, on_click = function()
    if cmd == "playpause" and not state.running then run("play")() else run(cmd)() end
  end })
end
ctl_row("prev", G.prev, "Previous", "previous")
toggle_row = ctl_row("toggle", G.play, "Play", "playpause")
ctl_row("next", G.next, "Next", "next")
menu:row("open", { key = "open", value = "spotify ↗", color = c.text2, on_click = run("open") })
menu:finish()
rows = { title_row, artist_row, time_row, gauge_row }

-- The drawn island width (text metrics can differ from the estimate above);
-- measured once laid out, again after display changes.
local measured
local function island_width()
  if not measured then
    local q = sbar.query("island.media")
    for _, r in pairs(type(q) == "table" and q.bounding_rects or {}) do
      if r.size and r.size[1] > 0 then measured = math.floor(r.size[1] + 0.5); break end
    end
  end
  return measured or ISLAND_W
end

local function set_fill(ratio)
  local iw = island_width()
  local w = math.floor((iw - 4) * math.max(0, math.min(1, ratio)) + 0.5)
  if w <= 0 then fill:set({ drawing = false }); return end
  -- Narrower than its two corners, the plate would spill past the island's
  -- rounded edge, so it starts as a full-height pill.
  w = math.max(w, 2 * FILL_R)
  fill:set({ drawing = true, label = { width = w }, padding_right = -(2 + w) })
end

local function render()
  local s = state
  local active = s.state == "playing" or s.state == "paused"
  local playing = s.state == "playing"
  media:set({
    update_freq = playing and 2 or 5,
    label = { string = active and text.fit(s.title, title_w) or "—", color = active and c.text or c.text3 },
  })
  local ctl = playing and c.text2 or (s.installed and c.text3 or c.line)
  play_b:set({ label = { string = playing and G.pause or G.play, color = ctl } })
  prev_b:set({ label = { color = active and ctl or c.line } })
  next_b:set({ label = { color = active and ctl or c.line } })
  if playing then
    for n = 1, 3 do eq[n]:set({ background = { color = c.accent } }) end
    eq_loop.start()
  else
    eq_idle(active and c.text3 or c.bg)
  end
  set_fill(active and (s.duration or 0) > 0 and (s.position or 0) / s.duration or 0)

  -- Menu rows (cheap; done even while closed so opening is instant).
  toggle_row:update({ key = playing and G.pause or G.play, value = playing and "Pause" or "Play" })
  if active then
    title_row:update({ visible = true, value = text.fit(s.title, W - 24) })
    artist_row:update({ visible = true, value = text.fit(s.artist ~= "" and s.artist or "—", W - 24) })
    local pos, dur = text.clock(s.position), text.clock(s.duration)
    time_row:update({ visible = true, key = pos })
    time_row:set({ label = { string = dur, align = "right", width = W - 2 * theme.popup.padding - text.width(pos) } })
    gauge_row:show(true)
    gauge_row:fill((s.duration or 0) > 0 and 100 * s.position / s.duration or 0, c.text)
    if s.art then
      art_row:set({ background = { color = c.transparent, image = { string = s.art, drawing = true } } })
    else
      art_row:set({ background = { color = c.bg, image = { drawing = false } } })
    end
    art_row:show(true)
  else
    for _, r in ipairs(rows) do r:show(false) end
    art_row:show(false)
    title_row:update({ visible = true, value = s.installed and (s.running and "Nothing playing" or "Spotify is not running")
      or "Spotify is not installed", color = c.text2 })
  end
end

refresh = helper.single(function(done)
  helper.run({ "spotify" }, function(r)
    done()
    if r.error and not r.state then return end
    state = r
    render()
  end)
end)

menu:bind({ media, eq[1], eq[2], eq[3] })
play_b:subscribe("mouse.clicked", function()
  if state.state == "playing" or state.state == "paused" then run("playpause")() else run("play")() end
end)
prev_b:subscribe("mouse.clicked", function() if state.state ~= "none" then run("previous")() end end)
next_b:subscribe("mouse.clicked", function() if state.state ~= "none" then run("next")() end end)
for _, b in ipairs({ play_b, prev_b, next_b }) do
  b:subscribe("mouse.entered", function() if state.installed then b:set({ label = { color = c.text } }) end end)
  b:subscribe("mouse.exited", function() render() end)
end

sbar.add("event", "spotify_change", "com.spotify.client.PlaybackStateChanged")
media:subscribe({ "routine", "forced", "system_woke", "spotify_change" }, refresh)
media:subscribe({ "display_change", "system_woke" }, function() measured = nil; refresh() end)
refresh()

-- The title cell narrows on a notched display (items/notch.lua) so the
-- island stops before the circles left of the notch; nil restores it.
local function set_title_width(w)
  w = w or theme.media.title_width
  if w == title_w then return end
  title_w = w
  measured = nil
  media:set({ label = { width = title_w } })
  render()
end

return { item = media, title_width = function() return title_w end, set_title_width = set_title_width }
