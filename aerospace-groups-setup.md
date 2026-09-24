# AeroSpace workspace groups — Bash

One command selects the workspaces for a named activity. Keybindings are intentionally left for you to choose.

| Command argument | Monitor 1 (macOS main display) | Monitor 2 (other display) | Final focus |
| --- | --- | --- | --- |
| `code` | `code-main`: Ghostty | `code-secondary`: Arc | Monitor 1 |
| `browse` | `browse-main`: Arc | `browse-secondary`: Arc | Monitor 1 |
| `music` | Keep current workspace | `music`: Spotify | Monitor 2 |
| `slack` | Keep current workspace | `slack`: Slack | Monitor 2 |
| `discord` | Keep current workspace | `discord`: Discord | Monitor 2 |
| `teams` | Keep current workspace | `teams`: Teams chat | Monitor 2 |
| `teams-call` | `teams-call`: separate call window | `teams`: Teams chat | Monitor 1 |

This version switches existing workspaces. Place windows once using the steps below; it does not launch apps, reconstruct layouts, or implement `--restore`. It focuses the last-focused window in each selected workspace. Empty workspaces remain empty.

**Arc choice:** this setup uses three separate Arc windows: one for Code and two for Browse. Sharing Code's secondary Arc window with Browse was not decided; keeping them separate avoids moving a window between groups.

## 1. Install the script

Save `aerospace-group.sh` as `~/.dotfiles/scripts/aerospace-group.sh`, then:

```bash
chmod +x ~/.dotfiles/scripts/aerospace-group.sh
~/.dotfiles/scripts/aerospace-group.sh --help
```

The script uses macOS's built-in `/bin/bash` and works with Bash 3.2. No Cargo, Rust toolchain, or extra shell packages are required. It searches PATH, then the standard Homebrew locations, for AeroSpace.

Replace the previous Cargo commands in your AeroSpace and SketchyBar configuration with the Bash invocations below. The old `aerospace-group.rs` is no longer used by this setup.

## 2. Configure monitor assignments

In `aerospace/aerospace.toml`, replace the existing `persistent-workspaces` value and `[workspace-to-monitor-force-assignment]` table with these. Keep the top-level `persistent-workspaces` setting above any table headers.

```toml
persistent-workspaces = [
  "code-main", "code-secondary",
  "browse-main", "browse-secondary",
  "music", "slack", "discord", "teams", "teams-call",
]

[workspace-to-monitor-force-assignment]
code-main = "main"
code-secondary = "secondary"
browse-main = "main"
browse-secondary = "secondary"
music = "secondary"
slack = "secondary"
discord = "secondary"
teams = "secondary"
teams-call = "main"
```

Set your intended monitor 1 as the main display in macOS Display settings. AeroSpace's numeric monitor IDs are ordered left-to-right; they are not necessarily your conceptual monitor 1/2. This configuration deliberately uses `main`/`secondary`. The script checks for exactly two connected displays before switching, so it will report an error on a laptop-only or three-display setup.

## 3. Update app rules

Replace the existing `[[on-window-detected]]` blocks for Ghostty, Arc, Spotify and Slack with the following rules. In particular, remove the blanket Arc-to-workspace-2 rule; otherwise newly opened Arc windows will keep going there. The existing Slack bundle ID has a typo (`come.` rather than `com.`).

```toml
[[on-window-detected]]
if.app-id = "com.mitchellh.ghostty"
run = "move-node-to-workspace code-main"

[[on-window-detected]]
if.app-id = "com.spotify.client"
run = "move-node-to-workspace music"

[[on-window-detected]]
if.app-id = "com.tinyspeck.slackmacgap"
run = "move-node-to-workspace slack"

[[on-window-detected]]
if.app-id = "com.hnc.Discord"
run = "move-node-to-workspace discord"
```

Arc and Teams placement is manual because different windows of each app have different destinations. No title matching or automatic call detection is assumed. Existing windows also need moving once; do not rely on a config reload to relocate them.

Reload after editing:

```bash
aerospace reload-config
```

List window IDs and titles:

```bash
aerospace list-windows --all --format '%{window-id} | %{app-bundle-id} | %{window-title}'
```

Use each actual ID to assign a window, for example (replace `12345`):

```bash
aerospace move-node-to-workspace --window-id 12345 code-secondary
```

Place the three Arc windows in `code-secondary`, `browse-main` and `browse-secondary`. Place existing Ghostty, Spotify, Slack and Discord windows according to the table above. Put Teams chat in `teams`. When Teams opens a separate call window, move its ID to `teams-call`. A new call may have a new ID and need moving again. If Teams keeps a call inside its chat window, that one window cannot fill both workspaces.

The app bundle IDs in the rules can be checked against the `list-windows` output if a rule does not match your installed app.

## 4. Test the groups

```bash
~/.dotfiles/scripts/aerospace-group.sh code
~/.dotfiles/scripts/aerospace-group.sh browse
~/.dotfiles/scripts/aerospace-group.sh music
~/.dotfiles/scripts/aerospace-group.sh slack
~/.dotfiles/scripts/aerospace-group.sh discord
~/.dotfiles/scripts/aerospace-group.sh teams
~/.dotfiles/scripts/aerospace-group.sh teams-call
```

With Code visible, this switches keyboard focus between Ghostty and Arc without changing the displayed workspaces:

```bash
aerospace focus-monitor --wrap-around next
```

In Browse it switches between the two Arc windows. It always focuses the other currently visible monitor, so Code + Music would switch between Ghostty and Spotify.

Single-monitor groups preserve monitor 1. For example, `teams` after `teams-call` leaves the call workspace on monitor 1; select Code or Browse to replace it.

## 5. Show group names in SketchyBar

Replace the contents of `~/.dotfiles/sketchybar/items/aerospace.lua` with `aerospace-groups.lua`. Your existing `require("items.aerospace")` in `init.lua` can stay as it is. This replaces the old workspace items and observer; do not load both versions.

In your existing `sbar.bar({...})` settings in `sketchybar/bar.lua`, ensure:

```lua
display = "all",
```

Keep your existing AeroSpace event callback at the top level of `aerospace.toml`:

```toml
exec-on-workspace-change = [
  "/bin/bash",
  "-c",
  "/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change \"FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE\"",
]
```

The module uses your existing colors and Homebrew AeroSpace path. If your checkout is elsewhere, edit `script` near the top of the module. The module invokes `/bin/bash` explicitly, so it does not need Cargo or your interactive shell's startup files. It displays `Code · Browse · Music · Slack · Discord · Teams` on each display and invokes the script when you click an item. Teams calls use the Teams label; invoke `teams-call` separately.

Highlights are derived from each monitor's visible workspace, with the AeroSpace-to-SketchyBar display ID mapping queried rather than assumed. Code remains highlighted when focus moves between its Ghostty and Arc windows. Code + Music highlights Code on monitor 1 and Music on monitor 2. Unknown/old numeric workspaces leave every group unselected on that display. Refreshes run on workspace/display events, wake, and every ten seconds, including after bar restarts; no saved group-state file is needed.

```bash
sketchybar --reload
```

## 6. Keybindings: choose later

Your current `alt-1` through `alt-5` and `alt-shift-1` through `alt-shift-5` still target the old numeric workspaces. Remove or comment out those specific lines when switching to groups so they do not recreate numeric workspaces. Keep the directional focus, move and resize bindings.

When you supply the keys, put their entries under your existing `[mode.main.binding]`. The command value for Code will be:

```toml
"exec-and-forget /bin/bash \"$HOME/.dotfiles/scripts/aerospace-group.sh\" code"
```

This is a value template, not a standalone TOML assignment. Use the same value with the other group names. The monitor-focus command value is `"focus-monitor --wrap-around next"`. No new keybindings are assigned in this deliverable.

## Verification and limits

The Bash script passed syntax and mocked AeroSpace checks covering all seven groups, help, invalid arguments, missing dependencies, disconnected displays and command failure. The SketchyBar launcher was checked for correct Bash invocation. Live window placement and SketchyBar rendering still require testing on your Mac. Group selection consists of sequential workspace commands; it is not an atomic AeroSpace operation. If a command fails, it leaves earlier successful switches in place. Let each invocation finish before selecting another group.

Exit codes: `0` success/help, `2` invalid arguments, `127` missing AeroSpace, `1` runtime/display errors.

References: [AeroSpace commands](https://nikitabobko.github.io/AeroSpace/commands), [monitor assignments](https://nikitabobko.github.io/AeroSpace/guide#assign-workspaces-to-monitors), [SbarLua](https://github.com/FelixKratz/SbarLua), [SketchyBar items](https://felixkratz.github.io/SketchyBar/config/items).
