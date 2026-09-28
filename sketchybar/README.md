# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` by using SketchyBar's `CONFIG_DIR`; `init.lua`
owns SbarLua loading, configuration batching, hotload, and the event loop.

The transparent bar places AeroSpace workspaces in a pill on the left. The
right side is one pill per widget, displayed as
`[memory] [CPU] [date] [time] [Slack] [Teams] [Spotify] [battery]`.

## Layout

- `settings.lua`: shared fonts, text padding, bar, pill, and workspace geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `defaults.lua`: properties inherited by every subsequently created item
- `items/init.lua`: explicit item import order
- `items/*.lua`: dynamic items that need direct access to SbarLua
- `widgets/*.lua`: declarative widget specifications
- `helpers/widget.lua`: shared item creation, refresh, parsing, rendering, and click wiring
- `helpers/pill.lua`: one fixed-width pill per widget

Change icon and label fonts in `settings.fonts`, shared text padding in
`settings.item`, bar dimensions in `settings.bar`, pill height/radius/border in
`settings.pill`, and workspace-button spacing and dimensions in
`settings.groups`. Change pill spacing in `settings.pills`, and lock a changing
label with `label_width` in its widget module. Change palette values, including the translucent
`pill_bg`, `pill_border`, and `separator` surfaces, in `colors.lua`.

For an individual widget, edit its module under `widgets/`: `icon` changes the
glyph, `item.icon.font` or `item.label.font` overrides the shared font or size,
and the tables returned by `render` control state-dependent icon and label
colors. Other per-widget overrides such as padding belong in the specification's
`item` table. Pill order lives in `items/init.lua`; each pill surface comes from
`helpers/pill.lua`. Workspace icon, label, and state colors stay in
`items/aerospace-groups.lua`.

## Adding a widget

Add a module under `widgets/` that returns a widget specification, then add its
name to `right_pills` in `items/init.lua`. Names are listed in reverse visual
order because SketchyBar inserts right-side items from right to left. A
specification names the widget and can provide its icon, update interval,
events, command, parser, renderer, and click action. The shared widget helper
owns subscriptions, command execution, error handling, and the initial refresh.
`helpers/pill.lua` wraps each widget in its own pill.

Right-side widgets use Hack Nerd Font glyphs. Their common size, icon-to-label
gap, item padding, and vertical alignment are controlled by `settings.widgets`.
Each pill uses the shared dark translucent background and thin border.

The Spotify pill is always green and has no playback state. Clicking it opens
Spotify.

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
workspace selection and clicks, bracket ordering, Slack, Teams, and Spotify clicks, memory, CPU, battery, date, and time.
