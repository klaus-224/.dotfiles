-- Pilo circle (placeholder for my own Pilo): a pixel face acting out the
-- most urgent state of the running coding agents: waiting on you, failed,
-- finished (since you last looked), working, idle, none. Menu PILO lists
-- each agent. Swap the data source with config.pilo.command; the face only
-- needs {"agents": [{key, agent, name, state}]}.
local sbar = require("sketchybar")
local theme = require("theme")
local config = require("config")
local helper = require("helpers.helper")
local island = require("helpers.island")
local popup = require("helpers.popup")
local pixels = require("helpers.pixels")
local text = require("helpers.text")
local ticker = require("helpers.ticker")

local cfg = config.pilo
if not cfg.enabled then return nil end

local c = theme.colors
local W = text.menu_width(38)
local MAX_ROWS = 8
local FRAMES = { working = 4, waiting = 2, done = 2, failed = 2, idle = 2, none = 1 }
local COLORS = { working = c.text, waiting = c.warn, done = c.accent, failed = c.err, idle = c.text3 }
local LABELS = { working = "working", waiting = "needs you", done = "done", failed = "failed", idle = "idle" }

local face = island.circle("pilo", "right")
sbar.add("event", "agents_changed")

local known, latest = {}, {}
local mood = "none"
local frame = 1
local loop = ticker.every(function() return mood == "working" and 0.4 or 0.9 end, function()
  frame = cfg.animate and (frame % FRAMES[mood] + 1) or 1
  face:set({ background = { image = { string = pixels.path("pilo_" .. mood .. "_" .. frame), drawing = true } } })
end)
pixels.when_ready(loop.start)

local menu
local rows, status_row = {}, nil

local function state_of(agent)
  local entry = known[agent.key]
  return entry and entry.done and "done" or agent.state
end

local function render()
  local counts = {}
  for _, a in ipairs(latest) do
    local s = state_of(a)
    counts[s] = (counts[s] or 0) + 1
  end
  local previous = mood
  mood = (counts.waiting and "waiting") or (counts.failed and "failed") or (counts.done and "done")
    or (counts.working and "working") or (#latest > 0 and "idle") or "none"
  if mood ~= previous then frame = 0 end
  local parts = {}
  for _, s in ipairs({ "waiting", "failed", "done", "working", "idle" }) do
    if counts[s] then parts[#parts + 1] = counts[s] .. " " .. LABELS[s] end
  end
  status_row:update({ value = #latest == 0 and "No running agents" or table.concat(parts, " · "),
                      color = COLORS[mood] or c.text3 })
  for n, row in ipairs(rows) do
    local a = latest[n]
    if a then
      local s = state_of(a)
      local inner = W - theme.popup.key_width - 2 * theme.popup.padding
      row:update({ visible = true, key = text.fit(a.agent, theme.popup.key_width - 8),
                   value = text.hard(text.spread(text.fit(a.name, inner - 80), LABELS[s] or s, inner)), color = COLORS[s] or c.text })
    else
      row:update({ visible = false })
    end
  end
end

local acknowledge = false
local refresh = helper.single(function(done)
  local function apply(r)
    done()
    if type(r) ~= "table" or type(r.agents) ~= "table" then return end
    local seen = {}
    latest = {}
    for _, a in ipairs(r.agents) do
      if type(a) == "table" and type(a.key) == "string" then
        local entry = known[a.key] or { state = a.state, done = false }
        -- "done" = went from working to idle; cleared by opening the menu.
        if a.state ~= "idle" then entry.done = false
        elseif entry.state == "working" then entry.done = true end
        entry.state = a.state
        known[a.key] = entry
        seen[a.key] = true
        latest[#latest + 1] = a
      end
    end
    for key in pairs(known) do if not seen[key] then known[key] = nil end end
    render()
    if acknowledge then
      acknowledge = false
      for _, e in pairs(known) do e.done = false end
    end
  end
  if cfg.command then sbar.exec(cfg.command, apply) else helper.run({ "agents" }, apply) end
end)

menu = popup.new(face, {
  title = "PILO",
  width = W,
  underline = island.underline_circle(face),
  on_open = function() acknowledge = true; refresh() end,
  on_close = function() render() end,
})
status_row = menu:row("status", { value = "Loading agents…" })
for n = 1, MAX_ROWS do rows[n] = menu:row("agent." .. n, { key = "", value = "", visible = false }) end
menu:finish()
menu:bind({ face })

face:set({ update_freq = cfg.poll, updates = true })
face:subscribe({ "routine", "forced", "system_woke", "agents_changed" }, refresh)
refresh()

return face
