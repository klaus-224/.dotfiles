# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` by using SketchyBar's `CONFIG_DIR`; `init.lua`
owns SbarLua loading, configuration batching, hotload, and the event loop.

The transparent bar places an Apple logo and AeroSpace workspaces in a pill on
the far left, a now-playing pill in the center, and groups the right side as
`[Slack | Teams] [CPU | battery | Wi-Fi | Bluetooth] [date and time]`.

## Layout

- `settings.lua`: shared fonts, text padding, bar, pill, and workspace geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `defaults.lua`: properties inherited by every subsequently created item
- `items/init.lua`: explicit item import order
- `items/*.lua`: dynamic items that need direct access to SbarLua
- `widgets/*.lua`: declarative widget specifications
- `helpers/widget.lua`: shared item creation, refresh, parsing, rendering, and click wiring
- `helpers/group.lua`: right-side ordering, bracket styling, and group spacing

Change icon and label fonts in `settings.fonts`, shared text padding in
`settings.item`, bar dimensions in `settings.bar`, pill height/radius/border in
`settings.pill`, and workspace-button spacing and dimensions in
`settings.groups`. Change palette values, including the translucent
`pill_bg`, `pill_border`, and `separator` surfaces, in `colors.lua`.

For an individual widget, edit its module under `widgets/`: `icon` changes the
glyph, `item.icon.font` or `item.label.font` overrides the shared font or size,
and the tables returned by `render` control state-dependent icon and label
colors. Other per-widget overrides such as padding belong in the specification's
`item` table. Group membership and ordering live in `items/init.lua`; group-wide
spacing and surfaces are controlled by `settings.widgets` and
`helpers/group.lua`. Direct items such as workspaces and media keep their icon,
label, and state colors in `items/aerospace-groups.lua` and `items/media.lua`.

## Adding a widget

Add a module under `widgets/` that returns a widget specification, then include
it in a `group.add` call in `items/init.lua`. A specification names the widget
and can provide its icon, update interval, events, command, parser, renderer,
and click action. The shared widget helper owns subscriptions, command execution,
error handling, and the initial refresh. Group members are declared in visual
left-to-right order; the group helper handles SketchyBar's reversed right-side
insertion order and creates the surrounding bracket.

Right-side widgets use Hack Nerd Font glyphs. Their common size, icon-to-label
gap, item padding, group spacing, and vertical alignment are controlled by
`settings.widgets`. Groups use the shared dark translucent pill background and
thin foreground-tinted border over the transparent, full-width bar.

The center media pill listens to SketchyBar's native `media_change` event and
adds no Homebrew dependency. It is hidden unless media is playing. Previous,
play/pause, and next clicks send AppleScript commands to the app named by the
event; apps without a compatible scripting interface may ignore those controls.

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
