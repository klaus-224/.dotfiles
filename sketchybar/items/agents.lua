local sbar = require("sketchybar")
local colors = require("colors")
local settings = require("settings")
local icons = require("icons")
local popup = require("helpers.popup")
local command = require("helpers.command")

-- Agents report busy/idle/waiting through helpers/status.py. An agent is
-- "done" when it moves from working to idle; that stays lit until the menu
-- is opened or the agent starts working again.
local max_rows = 8
local known = {}
local latest = {}

sbar.add("event", "agents_changed")
sbar.add("item", "spacer.agents", {
  position = "right", width = settings.group_paddings,
  icon = { drawing = false }, label = { drawing = false }, background = { drawing = false },
})
local item = sbar.add("item", "widgets.agents", {
  position = "right", update_freq = 5,
  icon = { string = icons.agents, color = colors.muted },
  label = { string = "", drawing = false },
})

local function counts()
  local total = { working = 0, waiting = 0, done = 0 }
  for _, agent in ipairs(latest) do
    local entry = known[agent.key]
    if entry.done then total.done = total.done + 1
    elseif total[agent.state] then total[agent.state] = total[agent.state] + 1 end
  end
  return total
end

local function render_bar()
  local total = counts()
  local parts = {}
  if total.waiting > 0 then parts[#parts + 1] = total.waiting .. " waiting" end
  if total.done > 0 then parts[#parts + 1] = total.done .. " done" end
  if total.working > 0 then parts[#parts + 1] = total.working .. " working" end
  local color = (total.waiting > 0 and colors.yellow) or (total.done > 0 and colors.green)
    or (total.working > 0 and colors.blue) or colors.muted
  item:set({
    icon = { color = color },
    label = { string = table.concat(parts, " · "), drawing = #parts > 0 },
  })
end

local status_row
local rows = {}
local function render_menu()
  status_row:set({ label = { string = #latest == 0 and "No running agents"
    or (#latest .. (#latest == 1 and " agent" or " agents")) } })
  for index, row in ipairs(rows) do
    local agent = latest[index]
    local text, color = "", colors.fg
    if agent then
      local entry = known[agent.key]
      local state = entry.done and "done" or (agent.state == "waiting" and "needs input") or agent.state
      color = (entry.done and colors.green) or (agent.state == "waiting" and colors.yellow)
        or (agent.state == "working" and colors.blue) or colors.muted
      text = agent.agent .. " · " .. agent.name .. " — " .. state
    end
    row:set({ drawing = agent ~= nil, label = { string = text, color = color } })
  end
end

local menu
local busy = false
local acknowledge = false
local function refresh()
  if busy then return end
  busy = true
  command.run({ "agents" }, function(result)
    busy = false
    if result.error or type(result.agents) ~= "table" then
      item:set({ icon = { color = colors.muted }, label = { string = "?", drawing = true } })
      return
    end
    local seen = {}
    latest = {}
    for _, agent in ipairs(result.agents) do
      if type(agent) == "table" and type(agent.key) == "string" then
        local entry = known[agent.key] or { state = agent.state, done = false }
        if agent.state ~= "idle" then entry.done = false
        elseif entry.state == "working" then entry.done = true end
        entry.state = agent.state
        known[agent.key] = entry
        seen[agent.key] = true
        latest[#latest + 1] = agent
      end
    end
    for key in pairs(known) do
      if not seen[key] then known[key] = nil end
    end
    if menu and menu.open then render_menu() end
    -- The open menu still shows what finished; the bar alert is cleared.
    if acknowledge then
      acknowledge = false
      for _, entry in pairs(known) do entry.done = false end
    end
    render_bar()
  end)
end

-- Opening the menu acknowledges, even when it lands on an in-flight poll.
menu = popup.attach(item, "widgets.agents", function()
  acknowledge = true
  refresh()
end)
status_row = menu.row("status", "Loading agents…")
for index = 1, max_rows do
  rows[index] = menu.row("agent." .. index, "")
  rows[index]:set({ drawing = false })
end

item:subscribe({ "routine", "forced", "system_woke", "agents_changed" }, refresh)
refresh()
sbar.add("bracket", "pill.agents", { "widgets.agents" }, {
  blur_radius = settings.blur_radius,
  background = { drawing = true, color = colors.pill_bg },
})
return item
