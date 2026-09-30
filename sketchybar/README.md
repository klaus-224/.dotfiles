# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` using SketchyBar's `CONFIG_DIR`.

The transparent bar places the decorative Apple logo, separator, and five
AeroSpace workspaces in one pill per display on the left. The right side has
one pill per item, displayed left to right as
`[Slack] [Teams] [Spotify] [memory] [CPU] [date] [time] [battery]`.

## Layout

```text
sketchybar/
├── sketchybarrc
├── init.lua
├── bar.lua
├── settings.lua
├── colors.lua
├── icons.lua
├── items/
│   ├── init.lua
│   ├── apple.lua
│   ├── aerospace.lua
│   ├── battery.lua
│   ├── time.lua
│   ├── date.lua
│   ├── cpu.lua
│   ├── memory.lua
│   ├── spotify.lua
│   ├── teams.lua
│   ├── slack.lua
│   └── clock.lua
├── helpers/
│   └── style.lua
└── tests/
    └── style_test.lua
```

- Root `init.lua` loads SbarLua, applies the bar and shared defaults, loads
  `items`, and manages hotload and the configuration/event-loop lifecycle.
- `items/init.lua` explicitly imports items in insertion order. SketchyBar
  inserts right-side items from right to left, so imports reverse visual order.
- Each ordinary item module creates its item and bracket, owns subscriptions
  and click handlers, and performs its initial refresh when it has a command.
  Spotify is static and only subscribes to clicks.
- `items/apple.lua` exposes `add(display)`, which creates and returns a
  decorative logo. AeroSpace calls it when a display appears and includes it
  in the workspace bracket; importing Apple alone creates no items.
- `items/aerospace.lua` owns display discovery, workspace state and clicks,
  brackets, the separator, and removal of all per-display items. It registers
  `aerospace_workspace_change` before Slack and Teams subscribe to it.
- `items/clock.lua` is an optional combined date/time item. It is not imported
  by default; the separate date and time items remain active.
- `helpers/style.lua` contains pure utilities for copying and merging property
  tables, with no SketchyBar item creation or subscriptions. Slack and Teams
  each contain their own commands, parsing, rendering, and click actions.

Runtime names remain `widgets.<name>`, `pill.<name>`, and
`workspace.<display>.<name>`, even though Lua modules now live under `items/`.
Existing query commands therefore continue to work. There is no declarative
widget specification or shared widget runtime.

## Styling

The migration preserves the existing Vague palette, glyphs, fonts, dimensions,
spacing, status colors, and pill groupings. Shared values remain centralized:

| To change | Edit |
|---|---|
| Palette and semantic colors | `colors.lua` |
| Glyphs | `icons.lua` |
| Default fonts and icon/label colors | `settings.defaults` |
| Shared right-side item spacing | `settings.widgets` |
| Shared pill surface | `settings.pill` |
| Bar geometry and placement | `settings.bar`, `bar.lua` |
| Workspace geometry | `settings.groups`, `items/aerospace.lua` |
| One item's properties or state-dependent appearance | `items/<name>.lua` |
| Apple logo geometry | `items/apple.lua` |

`settings.widgets` keeps its existing name as the shared right-side styling
preset. It is not a widget factory. Properties use native SketchyBar names in
SbarLua's nested form; for example, `label.font.size` is
`label = { font = { size = 16.0 } }`.

Each right-side item resolves its properties from runtime defaults (position
and empty strings), then `settings.widgets`, then its own properties. The
`style.resolve` helper merges nested tables without mutating the inputs.
Explicit `false` and `0` override previous values. Fonts and default colors
are inherited from `sbar.default(settings.defaults)`.

A bracket draws the pill separately from the item's own background. Adjust
one item's surface in that module's bracket call, for example:

```lua
sbar.add("bracket", "pill.battery", { "widgets.battery" },
  style.resolve(settings.pill, { background = { color = colors.pill_bg } }))
```

Refresh callbacks apply partial property updates: omitted fields retain their
current values. Returning an empty label does not change padding, width, or
visibility. Spotify keeps the shared padding and an empty label; Slack and
Teams use content-sized labels, with no fixed label width. Their renderers
use brand colors when the app is running and a muted icon otherwise.

## Adding or editing an item

Create `items/<name>.lua` and import it explicitly in `items/init.lua` at the
intended position. Follow an existing module:

- Create the item using `sbar.add` and shared styling where appropriate.
- Define its command, parser, renderer, and refresh callback locally.
- Subscribe to its refresh events and click action, and refresh once at startup
  if it has dynamic data. Failed commands or parsing use the item's fallback.
- Create its bracket and return the item handle.

There is no helper build step. CPU still polls `top`; memory uses
`memory_pressure`, battery uses `pmset`, and app badges use `lsappinfo`.
AeroSpace uses its existing trigger plus display, wake, and fallback refresh
notifications. Its five numbered workspaces match `persistent-workspaces` in
`aerospace/aerospace.toml`.

## Verification and activation

Run the regression tests from the repository root. They use a stubbed SbarLua
module and require neither a running bar nor the native module:

```sh
lua sketchybar/tests/style_test.lua
```

The tests exercise item creation and order, shared styles, refresh and click
callbacks, malformed output, and AeroSpace multi-display state, disconnects,
reconnects, and overlapping refreshes.

Syntax-check the Lua sources and executable Lua entrypoint:

```sh
for file in sketchybar/*.lua sketchybar/items/*.lua sketchybar/helpers/*.lua sketchybar/tests/*.lua sketchybar/sketchybarrc; do
  luac -p "$file" || exit 1
done
```

Home Manager points at `~/.dotfiles/sketchybar`. Changes in another worktree
are not active until integrated into that checkout. Once active, hotload
reloads saved edits; an explicit reload and inspection use:

```sh
sketchybar --reload
sketchybar --query defaults
sketchybar --query widgets.battery
sketchybar --query pill.battery
```

Compare the live appearance, item order and spacing, clicks, and dynamic
updates. Exercise workspaces on each monitor, display disconnect/reconnect,
and wake. Each monitor should highlight its own active workspace with no
stale or duplicate items.

Configuration errors can leave the bar running with incomplete properties.
Inspect both service logs:

```sh
tail /opt/homebrew/var/log/sketchybar/sketchybar.err.log
tail /opt/homebrew/var/log/sketchybar/sketchybar.out.log
```

Bind `require` to a local before passing its result to SbarLua: since Lua 5.4,
a first `require` returns both the module and loader data. For example,
`sbar.bar(require("bar"))` passes an extra argument and SbarLua rejects it.
The startup regression test covers this case.

## SbarLua

Startup expects a Lua-compatible native module at
`~/.local/share/sketchybar_lua/sketchybar.so`; it does not install or update the
module automatically. Follow the [SbarLua installation instructions][sbarlua]
and build with the Lua runtime used to start SketchyBar.

[items]: https://felixkratz.github.io/SketchyBar/config/items
[sbarlua]: https://github.com/FelixKratz/SbarLua
