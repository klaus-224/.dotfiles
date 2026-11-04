# SketchyBar

An island-style bar modelled on
[garamnohhh/sketchybar-island](https://github.com/garamnohhh/sketchybar-island),
in the Vague palette. Lua (SbarLua) draws the UI; the Rust helper
[`sbar-helper`](../sketchybar-helper) supplies the data. Home Manager links
this directory to `~/.config/sketchybar`; `sketchybarrc` loads `init.lua`.

```text
[  1 2 3 4 5 app ] [ ▮▮▮ spotify title  󰒮 󰐊 󰒭 | 󰕾 ▮▮▮▯▯ ]      (pilo) (cat) [󰒱 3 󰊻 1 · agent ✳ 81% ▣ 1.2M · mem 69% 48G · bat ▮▮▮▮▯ · wifi home · 04-11 17:30]
```

| Cell | Bar | Menu (click; click anywhere else closes it) |
|---|---|---|
| Left island | one per display: AeroSpace workspaces, front app | — |
| Media | right of the AeroSpace island: Spotify title, progress fill, EQ, controls | cover, title, artist, time, gauge, controls, open Spotify |
| Volume | speaker glyph + five cells | slider, mute, output devices, Sound Settings |
| Slack / Teams | start of the right island, shown only when installed; Slack red / Teams blue while running, grey when not; Dock badge count | recent notification previews; Slack also: current status, presets, clear |
| Pilo | face acting out the most urgent agent state | each running agent and its state |
| Cat | runs faster with CPU load; yellow at high memory | CPU, memory, disk |
| Agents | Claude / Codex 5-hour usage left, OpenCode tokens today (after the OpenCode mark) | 5h and weekly usage with reset times; OpenCode tokens and cost |
| Memory | used %, total RAM | used / free, top 5 processes captured when opened |
| Battery | five cells (hidden without a battery) | level, power source, time left |
| Wi-Fi | network name, `off` in red | ssid, ip, router, signal, saved networks in range (click to join) |
| Clock | `dd-mm HH:MM` | month view (click the left / right third of the `‹ 10  2026.11  12 ›` row to page, the middle for this month; scroll too), today's events with times |

## Make it yours

- `theme.lua`: colours, island height, borders, radius, gaps, fonts, popup
  look, warning thresholds. Change a value and save (hotload reloads).
  `bar.margin` matches AeroSpace's `gaps.outer.left/right`. Menu widths are
  counted in characters, so they follow `font.size` and `font.char_width`.
- `config.lua`: logo, workspaces, agents (`show = "remaining" | "used"`),
  Pilo data source, calendar week start, Slack status presets.

## Install

```sh
just install-sketchybar-helper   # builds the helper into an app bundle
```

The helper lives in
`~/.local/share/sketchybar-helper/SketchyBarHelper.app` (linked as
`~/.local/bin/sbar-helper`). macOS grants Location and Calendar access to that
bundle. Rebuilding changes its ad-hoc signature, so macOS may ask again.

Font: Hack Nerd Font (`nerd-fonts.hack` in `nix/darwin/default.nix`). Text
fitting assumes a monospace font; if you change it, set `font.char_width` to
its advance. SbarLua must be built at
`~/.local/share/sketchybar_lua/sketchybar.so` ([instructions][sbarlua]).

One-time permissions (the helper asks the first time each one is used):

- **Location**, for "SketchyBar Helper": macOS only reveals Wi-Fi names to
  apps with Location access. The location itself is never read.
- **Calendars**: today's events in the clock menu.
- **Full Disk Access** for SketchyBar: Slack/Teams previews come from the
  Notification Center database.
- **Automation → Spotify / System Events**: now playing; Dock badges.

## Data sources

All local except the Slack status, which calls the Slack Web API.

- **Claude**: `~/.claude/abtop-rate-limits.json`, written by the abtop
  status-line hook from Claude Code's `rate_limits`; falls back to the
  `/usage` cache in `~/.claude.json`. Numbers older than an hour show
  "updated … ago" in the menu.
- **Codex**: the newest `rate_limits` record in `~/.codex/sessions`
  rollouts. Hidden when `~/.codex` does not exist.
- **OpenCode**: per-session token and cost totals in the `session` table of
  `~/.local/share/opencode/opencode*.db`, opened read-only. Sessions count on
  the day they were last updated. Providers that report no usage (e.g. GitHub
  Copilot) show zero.
- **Pilo**: `sbar-helper agents` reads Claude Code's `~/.claude/sessions/*.json`
  and `${XDG_STATE_HOME:-~/.local/state}/agents/*.json` (written by
  `opencode/plugins/agent-status`). Any agent can join by writing one file
  per session, atomically, and removing it when the session ends:

  ```json
  {"agent": "codex", "id": "session-id", "pid": 1234, "name": "repo", "status": "busy"}
  ```

  `status` is `busy`, `idle`, `waiting` or `failed`; `sketchybar --trigger
  agents_changed` updates at once. To use another source (my own Pilo, later),
  set `config.pilo.command` to a command printing
  `{"agents": [{"key", "agent", "name", "state"}]}`.
- **Slack / Teams**: badges from `lsappinfo` (Dock `AXStatusLabel` as a
  fallback); previews from the last 24 hours of Notification Center records.
  These are delivered notifications, not an unread inbox.
- **Slack status**: needs a user token (`xoxp-…`) with
  `users.profile:read` and `users.profile:write`, stored in the login
  Keychain. The helper passes it to curl through stdin and never prints it.

  ```sh
  security add-generic-password -U -s sketchybar-slack -a "$USER" -w
  ```

- **Spotify**: AppleScript (only when Spotify is installed, so it never
  launches the app). Covers are cached in `~/.cache/sketchybar/art-*.jpg`.
- **Volume**: CoreAudio. `sbar-helper watch` (started by the bar, exits with
  it) fires `audio_change` for mute keys and device switches.

## Layout notes

- Left items are added left to right (AeroSpace, then the media island),
  right items right to left: `items/init.lua` keeps that order.
- The media progress fill is a zero-width item at the island's left edge;
  the island width is measured after layout. It is never narrower than its
  two corners, so it cannot spill past the island's rounded edge.
- The calendar menu hangs from `clock.edge`, the island's end padding, so it
  lines up with the island edge.
- Click-away: `sbar-helper clickaway` waits for the window server's
  mouse-down counter to change (a short tap is never missed) and returns
  the pointer position; Lua closes the menu when it is outside.
- Setting a background colour switches the background on, and SbarLua sends
  table keys in no fixed order, so hidden backgrounds (underlines) are turned
  off with a second `set`.
- A transparent `shield` bracket spans the bar: on macOS 27, clicking an
  empty part of the bar otherwise raises the bar window over the items
  (SketchyBar #850).

## Checks

```sh
just check-sketchybar
```

This runs `cargo fmt`, `clippy` and the Rust tests, `luac -p` on every Lua
file, and `tests/layout.lua`, which loads the whole config against a mocked
SbarLua with fixture data: layout order, rendered values, every menu opening
and closing, and a display disconnect. It does not check native rendering,
permissions or the installed SbarLua module.

Inspect a live item with `sketchybar --query <name>`; startup errors are in
`/opt/homebrew/var/log/sketchybar/sketchybar.err.log`.

[sbarlua]: https://github.com/FelixKratz/SbarLua
