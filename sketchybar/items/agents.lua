-- [agent ✳ 79%  ◎ 92%  ▣ 1.2M]: 5-hour usage left (or used) for Claude
-- Code and Codex, and OpenCode tokens today. Menu AGENTS: 5h and weekly
-- usage with gauges and reset times; OpenCode tokens and cost.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local text = require("helpers.text")
local pixels = require("helpers.pixels")

local c = theme.colors
local i = theme.island
local cfg = config.agents
local W = text.menu_width(48)
local INNER = W - theme.popup.key_width - 2 * theme.popup.padding
local agents = {}

local glyph_font = island.font("Regular", theme.font.size + 2, theme.font.icons)
-- Right side: added right to left.
-- The OpenCode mark is a pixel image (sbar-helper pixels) drawn as the
-- icon's background, centred across the icon's width: the icon text is
-- empty and exactly as wide as the mark, and the gap is label padding.
-- Right end of the cells: zero-width beside the memory cell; the island's
-- inner padding when the agents form their own island left of the notch.
agents.edge = island.spacer("agents.edge", "right", 0)
local oc = sbar.add("item", "agents.opencode", {
  position = "right", padding_left = 12, padding_right = 0, drawing = false,
  icon = { string = "", width = 8, padding_left = 0, padding_right = 0,
           background = { drawing = true, color = c.transparent } },
  label = { string = "—", color = c.text3, padding_left = 5, padding_right = 0 },
})
local codex = sbar.add("item", "agents.codex", {
  position = "right", padding_left = 12, padding_right = 0, drawing = false,
  icon = { string = cfg.codex_icon, font = glyph_font, color = c.text, padding_left = 0, padding_right = 4 },
  label = { string = "—", color = c.text3, padding_left = 0, padding_right = 0 },
})
local claude = sbar.add("item", "agents.claude", {
  position = "right", padding_left = 0, padding_right = 0, drawing = false,
  icon = { string = cfg.claude_icon, font = glyph_font, color = c.claude, padding_left = 0, padding_right = 4 },
  label = { string = "—", color = c.text3, padding_left = 0, padding_right = 0 },
})
local tag = sbar.add("item", "agents", {
  position = "right", padding_left = i.inner, padding_right = 0, update_freq = cfg.poll, updates = true,
  icon = { string = "agent", color = c.text3, padding_left = 0, padding_right = i.tag_gap },
  label = { drawing = false },
})
agents.members = { "agents", "agents.claude", "agents.codex", "agents.opencode" }
agents.cells = { "agents", "agents.claude", "agents.codex", "agents.opencode", "agents.edge" }
agents.items = { agents.edge, oc, codex, claude, tag } -- right to left

local remaining = cfg.show ~= "used"
local function shown(used) return remaining and math.max(0, 100 - used) or used end

local function level(used)
  if not used then return c.text3 end
  if used >= theme.thresholds.err then return c.err end
  if used >= theme.thresholds.warn then return c.warn end
  return c.text
end

-- Warn when usage runs ahead of the time elapsed in the window.
local function pace(used, resets_at, span)
  local color = level(used)
  if color ~= c.text or not resets_at then return color end
  local elapsed = 100 * (span - (resets_at - os.time())) / span
  return used > elapsed and c.warn or c.text
end

local function pct(w)
  if type(w) ~= "table" or w.used == nil then return "—" end
  return math.floor(shown(w.used)) .. "%"
end

-- Menu -------------------------------------------------------------------
local menu = popup.new(tag, { title = "AGENTS", width = W, hosts = agents.members })
local sections = {}
local function window_rows(key, label)
  return { line = menu:row(key, { key = label, value = "—" }), gauge = menu:gauge(key .. ".g", 50) }
end
local function agent_section(key, glyph, name, color)
  local head = menu:row(key, { key = glyph, key_font = glyph_font, key_color = color, value = name })
  local s = { head = head, color = color, name = name,
              five = window_rows(key .. ".5h", "5h"), week = window_rows(key .. ".week", "week") }
  s.all = { head, s.five.line, s.five.gauge, s.week.line, s.week.gauge }
  sections[key] = s
  return s
end
local claude_s = agent_section("claude", cfg.claude_icon, "claude", c.claude)
menu:pad(6)
local codex_s = agent_section("codex", cfg.codex_icon, "codex", c.text)
menu:pad(6)
local oc_head = menu:row("oc", { key = "", value = "opencode" })
-- The mark is centred across the icon's width and padding, so the side gap
-- moves to the item and the icon is exactly the mark's 8pt.
oc_head:set({ padding_left = theme.popup.padding, width = W - theme.popup.padding,
  icon = { width = 8, padding_left = 0, background = { drawing = true, color = c.transparent } },
  -- In a popup, SketchyBar shifts the label by the item padding too, so it
  -- is taken off again here (checked against the claude row on screen).
  label = { padding_left = theme.popup.key_width - 8 - theme.popup.padding } })
-- The PNG is written at startup; an image set before it exists stays off.
pixels.when_ready(function()
  local mark = { string = pixels.path("opencode"), scale = 0.5 }
  oc:set({ icon = { background = { image = mark } } })
  oc_head:set({ icon = { background = { image = mark } } })
end)
local oc_rows = {
  today = menu:row("oc.today", { key = "today", value = "—" }),
  week = menu:row("oc.week", { key = "7d", value = "—" }),
  month = menu:row("oc.month", { key = "30d", value = "—" }),
}
local oc_models = {}
for n = 1, 3 do oc_models[n] = menu:row("oc.model." .. n, { key = "", value = "", visible = false, color = c.text2 }) end
menu:finish()
menu:bind({ tag, claude, codex, oc })

local function render_window(rows, w, span, fmt, color)
  if type(w) ~= "table" or w.used == nil then
    rows.line:update({ value = "—", color = c.text3 })
    rows.gauge:fill(0, color)
    return
  end
  local left = (remaining and "%d%% left" or "%d%%"):format(math.floor(shown(w.used)))
  local reset = w.resets_at and (os.date(fmt, w.resets_at) .. " reset") or "—"
  rows.line:update({ value = text.hard(text.spread(left, reset, INNER)), color = pace(w.used, w.resets_at, span) })
  rows.gauge:fill(w.used, color)
end

local function render_agent(s, data)
  local visible = type(data) == "table"
  for _, r in ipairs(s.all) do r:show(visible) end
  if not visible then return end
  local stale = data.updated_at and (os.time() - data.updated_at > 3600) and ("updated " .. text.ago(data.updated_at)) or ""
  s.head:update({ value = text.hard(text.spread(s.name, stale, INNER)), color = c.text })
  render_window(s.five, data.five, 5 * 3600, "%H:%M", s.color)
  render_window(s.week, data.week, 7 * 86400, "%a %H:%M", s.color)
end

local function money(v) return string.format("$%.2f", tonumber(v) or 0) end

local function render(r)
  local five = function(d) return type(d) == "table" and d.five or nil end
  claude:set({ drawing = r.claude ~= nil, label = { string = pct(five(r.claude)),
    color = five(r.claude) and level(five(r.claude).used) or c.text3 } })
  codex:set({ drawing = r.codex ~= nil, label = { string = pct(five(r.codex)),
    color = five(r.codex) and level(five(r.codex).used) or c.text3 } })
  local o = r.opencode
  oc:set({ drawing = o ~= nil, label = { string = o and text.tokens(o.today.tokens) or "—",
    color = o and o.today.tokens > 0 and c.text or c.text3 } })
  -- The cell is hidden when no agent is installed at all.
  local any = r.claude or r.codex or o
  tag:set({ drawing = any ~= nil })

  render_agent(claude_s, r.claude)
  render_agent(codex_s, r.codex)
  local oc_visible = o ~= nil
  oc_head:show(oc_visible)
  for _, row in pairs(oc_rows) do row:show(oc_visible) end
  if oc_visible then
    for key, row in pairs(oc_rows) do
      local t = o[key]
      row:update({ value = text.hard(text.spread(text.tokens(t.tokens) .. " tok · " .. t.sessions .. " sess", money(t.cost), INNER)),
                   color = t.tokens > 0 and c.text or c.text3 })
    end
  end
  for n, row in ipairs(oc_models) do
    local m = oc_visible and o.models[n]
    row:update({ visible = m and true or false, value = m and text.hard(text.spread(text.fit(m.name, INNER - 70), text.tokens(m.tokens), INNER)) or "" })
  end
end

local refresh = helper.single(function(done)
  helper.run({ "usage" }, function(r)
    done()
    if r.error then return end
    render(r)
  end)
end)

tag:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()

function agents.underline()
  menu.opts.underline = island.underline_group("agents.u", agents.members)
end

return agents
