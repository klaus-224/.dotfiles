# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` by using SketchyBar's `CONFIG_DIR`; `init.lua`
owns SbarLua loading, configuration batching, hotload, and the event loop.

The bar places AeroSpace workspaces on the far left. The right side is grouped
as `[Slack | Teams] [CPU | battery | Wi-Fi | Bluetooth] [date and time]`.

## Layout

- `settings.lua`: shared fonts, text padding, bar geometry, and workspace-group geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `defaults.lua`: properties inherited by every subsequently created item
- `items/init.lua`: explicit item import order
- `items/*.lua`: dynamic items that need direct access to SbarLua
- `widgets/*.lua`: declarative widget specifications
- `helpers/widget.lua`: shared item creation, refresh, parsing, rendering, and click wiring
- `helpers/group.lua`: right-side ordering, bracket styling, and group spacing

Change icon and label fonts in `settings.fonts`, shared text padding in
`settings.item`, bar dimensions in `settings.bar`, and workspace-button spacing
and dimensions in `settings.groups`. Change palette values in `colors.lua`.
State-dependent colors, update intervals, icons, and command behavior stay with
their item modules.

## Adding a widget

Add a module under `widgets/` that returns a widget specification, then include
it in a `group.add` call in `items/init.lua`. A specification names the widget
and can provide its icon, update interval, events, command, parser, renderer,
and click action. The shared widget helper owns subscriptions, command execution,
error handling, and the initial refresh. Group members are declared in visual
left-to-right order; the group helper handles SketchyBar's reversed right-side
insertion order and creates the surrounding bracket.

Wi-Fi SSIDs can be redacted by macOS privacy controls. When the interface has
an address but the SSID is unavailable, the widget still shows a connected
icon and leaves its label empty.

The font values (`Hack Nerd Font`, Bold, 14) record the effective defaults
queried from the running SketchyBar configuration before this layout was
introduced. They are now explicit to prevent upstream defaults from changing
the appearance unexpectedly.

## SbarLua

Startup expects a Lua-compatible SbarLua native module at
`~/.local/share/sketchybar_lua/sketchybar.so`; it does not install or update the
module automatically. Follow the [SbarLua installation instructions][sbarlua]
and build the module with the Lua runtime used to start SketchyBar.

[sbarlua]: https://github.com/FelixKratz/SbarLua

## Validation

Run the isolated syntax and mock behavior checks with:

```sh
just validate-sketchybar
```

The check does not contact SketchyBar, switch workspaces, or launch apps. After
configuration changes, reload the live bar separately and compare both displays,
workspace selection and clicks, bracket ordering, Slack and Teams badges and
clicks, CPU and battery values, Wi-Fi and Bluetooth state, and the clock.
