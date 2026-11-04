-- Volume at the right end of the media island: [glyph ▮▮▯▯▯]. Menu VOLUME:
-- slider, mute, output devices, Sound Settings. Updates on volume_change and
-- on audio_change from `sbar-helper watch` (mute keys, device switches).
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")

local c = theme.colors
local volume = {}

local G = {
  low = "\u{F057F}", mid = "\u{F0580}", high = "\u{F057E}", mute = "\u{F0581}",
  bt = "\u{F0970}", bt_mute = "\u{F07CE}", laptop = "\u{F0322}", headphones = "\u{F02CB}",
  display = "\u{F0379}", airplay = "\u{F01F4}",
}
local MAX_DEVICES = 6

local function glyph(state)
  if state.kind == "bluetooth" then return state.muted and G.bt_mute or G.bt end
  if state.muted then return G.mute end
  local v = state.volume or 0
  return v <= 33 and G.low or (v <= 66 and G.mid or G.high)
end

local function device_glyph(d)
  if d.kind == "bluetooth" then return G.bt end
  if d.kind == "display" then return G.display end
  if d.kind == "airplay" then return G.airplay end
  if (d.name or ""):lower():find("headphone") then return G.headphones end
  if d.kind == "builtin" then return G.laptop end
  return G.high
end

-- Adds the volume items at the right end of the media island (left side,
-- added left to right): [| glyph ▮▮▮▯▯ pad]. Returns the island members.
function volume.add()
  local items = {}
  local menu
  local open = function() if menu then menu:toggle() end end
  local sep = sbar.add("item", "volume.sep", {
    position = "left",
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { string = "", width = 1, padding_left = 0, padding_right = 0 },
    background = { drawing = true, color = c.text3, height = 12, corner_radius = 0, border_width = 0 },
  })
  items[#items + 1] = sep
  local item = sbar.add("item", "volume", {
    position = "left",
    padding_left = 0,
    padding_right = 0,
    icon = { string = G.high, font = island.font("Regular", theme.font.size, theme.font.icons), color = c.text2,
             width = 34, align = "center", padding_left = 0, padding_right = 0 },
    label = { drawing = false },
    update_freq = 30,
  })
  items[#items + 1] = item
  local cells = island.gauge_cells("volume", "left", open)
  for i = 1, 5 do items[#items + 1] = cells[i] end
  local pad = island.spacer("volume.pad", "left", theme.island.inner)
  pad:subscribe("mouse.clicked", open)
  items[#items + 1] = pad

  local state = {}
  local slider, mute_row, devices = nil, nil, {}

  local function render()
    item:set({ icon = { string = glyph(state), color = state.muted and c.text3 or c.text2 } })
    island.fill_cells(cells, state.muted and 0 or state.volume, state.muted and c.text3 or c.text, c.bg)
    if not menu then return end
    local v = state.volume or 0
    local label = state.muted and "off" or (v .. "%")
    slider:set({ slider = { percentage = v, highlight_color = state.muted and c.text3 or c.text },
                 label = { string = label, color = state.muted and c.text3 or c.text } })
    mute_row:update({ value = state.muted and "Unmute" or "Mute", key_color = state.muted and c.text or c.text3 })
    local list = state.devices or {}
    for i = 1, MAX_DEVICES do
      local d = list[i]
      local row = devices[i]
      if d then
        local width = menu.width - theme.popup.key_width - 2 * theme.popup.padding
        row:update({ visible = true, key = device_glyph(d), key_color = d.current and c.text or c.text3,
                     value = d.current and text.spread(text.fit(d.name, width - 20), "✓", width) or text.fit(d.name, width),
                     color = d.current and c.text or c.text2 })
        row.device = d
      else
        row:update({ visible = false })
        row.device = nil
      end
    end
  end

  local refresh = helper.single(function(done)
    helper.run({ "audio" }, function(r)
      done()
      if r.error then return end
      state = r
      render()
    end)
  end)

  menu = popup.new(item, {
    title = "VOLUME",
    width = text.menu_width(33),
    align = "right",
    hosts = { "volume.pad", "volume.sep", "volume.1", "volume.2", "volume.3", "volume.4", "volume.5" },
    on_open = refresh,
  })
  slider = sbar.add("slider", "volume.slider", 132, {
    position = "popup.volume",
    icon = { string = "vol", color = c.text3, width = theme.popup.key_width, padding_left = theme.popup.padding, padding_right = 0,
             font = island.font() },
    label = { string = "", color = c.text, width = 52, align = "right", padding_left = 0, padding_right = theme.popup.padding,
              font = island.font() },
    slider = {
      highlight_color = c.text,
      knob = { drawing = false },
      background = { color = c.line, height = 10, corner_radius = 0 },
    },
    background = { drawing = true, color = c.transparent, height = theme.popup.row_height },
  })
  menu.rows[#menu.rows + 1] = "volume.slider"
  slider:subscribe("mouse.clicked", function(env)
    local v = tonumber(env.PERCENTAGE)
    if not v then return end
    state.volume, state.muted = math.floor(v + 0.5), false
    render()
    helper.run({ "audio", "volume", tostring(state.volume) }, function(r) if not r.error then state = r; render() end end)
  end)
  mute_row = menu:row("mute", {
    key = G.mute, key_font = island.font("Regular", 14, theme.font.icons), value = "Mute", keep_open = true,
    on_click = function()
      helper.run({ "audio", "mute" }, function(r) if not r.error then state = r; render() end end)
    end,
  })
  menu:row("output", { value = "OUTPUT", color = c.text3, value_font = island.font("Regular", theme.font.small) })
  for i = 1, MAX_DEVICES do
    devices[i] = menu:row("device." .. i, {
      key = "", key_font = island.font("Regular", 14, theme.font.icons), visible = false, keep_open = true,
      on_click = function(_, row)
        if not row.device or row.device.current then return end
        helper.run({ "audio", "output", tostring(row.device.id) }, function(r) if not r.error then state = r; render() end end)
      end,
    })
  end
  menu:row("settings", { key = "open", value = "Sound Settings ↗", color = c.text2,
    on_click = function() helper.open("x-apple.systempreferences:com.apple.Sound-Settings.extension") end })
  menu:finish()

  for _, it in ipairs({ item, sep }) do it:subscribe("mouse.clicked", open) end
  item:subscribe("volume_change", function(env)
    local v = tonumber(env.INFO)
    if v then state.volume = v; render() end
  end)
  sbar.add("event", "audio_change")
  item:subscribe({ "audio_change", "routine", "forced", "system_woke" }, refresh)
  refresh()
  helper.spawn({ "watch" })

  volume.menu = menu
  -- items.media adds the underline after the island bracket (draw order).
  volume.underline_members = { "volume", "volume.1", "volume.2", "volume.3", "volume.4", "volume.5" }
  return items
end

return volume
