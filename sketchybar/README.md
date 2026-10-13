# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` using SketchyBar's `CONFIG_DIR`.

The transparent bar places the Apple logo, separator, and five AeroSpace
workspaces in one pill per display. The layout, from left to right, is:

- Left: `[Apple | 1 2 3 4 5] [Spotify Slack Teams]`
- Right: `[Wi-Fi] [Bluetooth] [memory] [CPU] [date] [time] [battery]`

Slack and Teams are available on every account; their icons are muted when
those apps are not running.

## Notifications and connectivity menus

Click Slack, Teams, Wi-Fi, or Bluetooth to toggle its popup. Only one of these
menus opens at a time. Leaving the bar and popup, switching apps, or choosing
an action closes it. Menus use the existing palette and pill spacing.

Slack and Teams keep their icons visible. Their badges refresh every 10 seconds,
on wake, and on workspace changes. A yellow count (or `•` for activity without
a count) comes from the app's badge, not from notification history. Zero clears
the badge; a stopped app is muted. An unavailable badge shows `?`. The reader
tries `lsappinfo` and then the Dock's Accessibility `AXStatusLabel` for apps
that do not publish a usable status label, including newer Teams versions.
Enable app badges in macOS Notifications and in the app's own preferences.
Counts follow each app's badge semantics (for example, Slack may count mentions
rather than every unread message).

Each app menu shows up to five recent Notification Center previews from the
last 24 hours. Clicking a preview opens the app; it does not mark a message read
or navigate to a particular conversation. These are recent delivered
notifications, **not an unread inbox**. Preview history may outlive an unread
badge. Slack must use macOS notifications for those messages to appear here.
The helper reads only Slack/Teams records from the current user's database,
opens SQLite read-only (including its live WAL), and does not save a separate
message cache. It supports the `db2` format in both the older
`DARWIN_USER_DIR/com.apple.notificationcenter` location and the newer
`~/Library/Group Containers/group.com.apple.usernoted` location. This is a
private macOS format, so future OS changes may require updating the reader.

On your Mac, permissions may be needed for the service that runs SketchyBar:

- For Dock badges, allow the responsible app/process in **Privacy & Security →
  Accessibility**, and allow **Automation → System Events** if prompted.
- For previews, allow the responsible app/process in **Full Disk Access**,
  then restart SketchyBar. Running a helper in Terminal and running it from the
  Homebrew service can have different permission attribution. The popup links
  to Full Disk Access settings. A blocked database displays an access error.
- Message text must be supplied by Slack/Teams. Missing text is shown as
  “Preview not supplied by the app”; the helper cannot recover hidden content.

Wi-Fi shows radio/connection state, network name when available, and the IPv4
address. Bluetooth shows radio state and up to eight connected device names.
Their menus open the corresponding System Settings pane to change networks,
toggle radios, pair, or disconnect devices. No `sudo`, `blueutil`, or network
credentials are needed. Wi-Fi polls every 30 seconds and Bluetooth every 60;
opening a menu or waking refreshes it. macOS may withhold the SSID; an active
link then shows “Connected · network name unavailable”.

`helpers/status.py` uses Python 3's standard library. Python is declared in
`nix/home/packages.nix`; activate that package change if Python is not already
installed. The launcher checks Home Manager and Homebrew paths explicitly so
the SketchyBar service does not depend on your interactive shell's PATH.

## Configuration

Startup applies bar properties, then loads these modules in order:

```lua
require("default")
require("items")
```

- `settings.lua` holds basic font and spacing values.
- `default.lua` calls `sbar.default({...})` directly. Native SketchyBar defaults
  provide shared fonts, colors, content padding, and background geometry.
- `bar.lua` holds bar placement, height, and edge padding.
- `colors.lua` holds the palette; `icons.lua` holds glyphs.
- `items/init.lua` imports items in insertion order. Right-side items insert
  from right to left, so their imports reverse the visual order.
- Items pass properties directly to `sbar.add(...)` and create pill brackets.
  `helpers/notifications.lua` shares the Slack/Teams implementation;
  `helpers/popup.lua` manages popup rows and dismissal. There is no Lua
  property-merging layer.
- `items/aerospace.lua` owns workspace geometry, per-display creation and
  removal, active-workspace highlighting, and the workspace-change event.
  It creates the groups from SketchyBar\'s display list before loading app
  items. AeroSpace only supplies highlighting, so a delayed, failed, or empty
  AeroSpace response cannot hide the groups. Newly connected display groups
  are moved before the hidden `workspace.anchor` to preserve the left order.
  `items/apple.lua` supplies the decorative logo for each display.
- `items/clock.lua` is an optional combined clock; it is not loaded by default.

Pill backgrounds inherit a height of 32 and corner radius of 16 from native
defaults. Explicit 8-point spacers sit between pills, outside their
brackets. Item padding cannot substitute for these spacers because bracket
backgrounds include their members' outer padding.

Runtime names remain `widgets.<name>`, `pill.<name>`, and
`workspace.<display>.<name>`. Gap items are named `spacer.<name>`.

## Memory and fonts

Memory displays used / total physical RAM, for example `12.4 GB / 16 GB`.
Values use 1024³ bytes per displayed GB. Total capacity comes from
`sysctl hw.memsize`; usage comes from `vm_stat` using its reported page size:
anonymous pages minus purgeable pages, plus wired pages and physical pages
occupied by the compressor. File cache and swapped-out memory are excluded.
The value refreshes every 10 seconds and on wake. Failed measurements show
`-- GB / -- GB` with a muted icon. Usage above 60% is yellow and above 80% red.

Both Nix host configurations install `pkgs.nerd-fonts.hack` through
`fonts.packages`. Activate the relevant host configuration to install the
font, then reload SketchyBar. Setting a font family in Lua alone does not
install its glyphs.

## Verification and activation

Syntax-check the Lua sources and executable entrypoint:

```sh
for file in sketchybar/*.lua sketchybar/items/*.lua sketchybar/helpers/*.lua sketchybar/sketchybarrc; do
  luac -p "$file" || exit 1
done
python3 -B -m unittest discover -s sketchybar/tests -p 'test_*.py'
lua sketchybar/tests/menus.lua
CONFIG_DIR="$PWD/sketchybar" lua sketchybar/tests/layout.lua
```

The regression test mocks SketchyBar and covers layout before AeroSpace responds,
failed/empty/malformed snapshots, per-display highlighting, monitor disconnects
and reconnects, and overlapping workspace events. It does not verify native
macOS rendering or the installed SbarLua module.

Home Manager points at `~/.dotfiles/sketchybar`. Changes in another worktree
are not active until integrated into that checkout. Once active, hotload
reloads saved edits; an explicit reload and inspection use:

```sh
sketchybar --reload
sketchybar --query defaults
sketchybar --query widgets.memory
sketchybar --query pill.memory
sketchybar --query widgets.slack
sketchybar --query widgets.teams
sketchybar --query widgets.wifi
sketchybar --query widgets.bluetooth
```

Check icons, pill gaps, memory-label fit, work-app visibility, clicks, and
workspace highlighting on each display. If the entire bar is still missing, inspect startup errors with:

```sh
tail /opt/homebrew/var/log/sketchybar/sketchybar.err.log
tail /opt/homebrew/var/log/sketchybar/sketchybar.out.log
```

On macOS, also send a test notification to each app, check its badge and menu,
read the message in the app, and check that the badge clears. Try Wi-Fi on/off,
Bluetooth on/off, and opening another menu while one is open. Linux fixture
tests cannot verify macOS permissions, app badge publication, or popup geometry.

When passing a required table to SbarLua, bind it to a local first. Since Lua
5.4, the first `require` returns both the module and loader data, so
`sbar.bar(require("bar"))` passes an unexpected second argument. The defaults
module instead applies its properties itself when required.

## SbarLua

Startup expects a Lua-compatible native module at
`~/.local/share/sketchybar_lua/sketchybar.so`; it does not install or update the
module automatically. Follow the [SbarLua installation instructions][sbarlua]
and build with the Lua runtime used to start SketchyBar.

[items]: https://felixkratz.github.io/SketchyBar/config/items
[sbarlua]: https://github.com/FelixKratz/SbarLua
