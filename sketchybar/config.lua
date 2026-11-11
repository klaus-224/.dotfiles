-- Behaviour of the bar. Look and colours live in theme.lua.
local home = os.getenv("HOME") or ""

return {
  -- sbar-helper inside its app bundle (macOS grants Location and Calendar
  -- access to the bundle). Built by `just install-sketchybar-helper`.
  helper = {
    home .. "/.local/share/sketchybar-helper/SketchyBarHelper.app/Contents/MacOS/sbar-helper",
    home .. "/.local/bin/sbar-helper",
  },

  -- launchd job that runs SketchyBar (`brew services`). The bar restarts
  -- itself through it when macOS leaves a ghost display behind (lid closed
  -- on an external display). nil turns that off.
  service = "sh.brew.sketchybar",
  uid = (function()
    local p = io.popen("/usr/bin/id -u")
    local uid = p and p:read("l")
    if p then p:close() end
    return uid or "501"
  end)(),

  logo = "\u{F179}", -- left end of each left island (Nerd Font Apple logo)
  aerospace = "/opt/homebrew/bin/aerospace",
  workspaces = { "1", "2", "3", "4", "5" },

  agents = {
    show = "remaining", -- "remaining" or "used" for the bar percentages
    claude_icon = "\u{EC82}",
    codex_icon = "\u{EC81}",
    poll = 30, -- seconds
  },

  -- Agent-state circle. `command` must print {"agents": [{key, agent, name,
  -- state}]} with state working|waiting|idle|failed; nil uses the built-in
  -- reader of Claude Code and OpenCode sessions (`sbar-helper agents`).
  pilo = { enabled = true, command = nil, animate = true, poll = 5 },

  calendar = {
    week_start = 0,  -- 0 = Sunday, 1 = Monday
    max_events = 8,
  },

  -- Slack status presets in the Slack menu. `minutes` = 0 keeps the status
  -- until cleared. Needs a user token in the Keychain item "sketchybar-slack".
  slack_status = {
    { emoji = ":technologist:", text = "Focusing", minutes = 120 },
    { emoji = ":spiral_calendar_pad:", text = "In a meeting", minutes = 60 },
    { emoji = ":coffee:", text = "Away", minutes = 30 },
    { emoji = ":palm_tree:", text = "Out of office", minutes = 0 },
  },

  terminal = "Ghostty",
}
