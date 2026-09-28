# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` by using SketchyBar's `CONFIG_DIR`.

Responsibilities are split as follows:

- `init.lua` orchestrates startup: module loading, bar and default properties,
  pill order, hotload, and the event loop.
- `helpers/` creates and updates ordinary widgets and owns their SbarLua calls.
- `widgets/*.lua` are configuration: values plus `parse` and `render` functions.
  They do not call SbarLua.
- `widgets/aerospace.lua` is the exception. It is a self-contained dynamic
  integration that owns its own items, events, and live state.

The transparent bar places AeroSpace workspaces in a pill on the left. The
right side is one pill per widget, displayed left to right as
`[Slack] [Teams] [Spotify] [memory] [CPU] [date] [time] [battery]`.

## Layout

- `init.lua`: startup, bar/default application, and right-side pill order
- `settings.lua`: all shared styling, plus bar and workspace geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `widgets/*.lua`: declarative widget specifications
- `widgets/aerospace.lua`: the dynamic workspace integration
- `helpers/style.lua`: the property merge used to resolve styling
- `helpers/widget.lua`: item creation, refresh, parsing, rendering, click wiring
- `helpers/pill.lua`: the pill surface drawn around each widget
- `helpers/app_badge.lua`: shared specification factory for app presence badges
- `tests/style_test.lua`: regression tests for the styling contract

## Styling

Every styling value is a native SketchyBar property written in SbarLua's nested
form. A dotted property in the SketchyBar documentation becomes a sub-table, so
`label.font.size=16` is written as:

```lua
label = { font = { size = 16.0 } }
```

See the upstream [item properties][items] reference for the full list of
available properties. This configuration adds no styling vocabulary of its own.

### Where to edit

| To change | Edit |
|---|---|
| Fonts and colors for everything in the bar | `settings.defaults` |
| Shared spacing for all right-side widgets | `settings.widgets` |
| One widget's static styling | `widgets/<name>.lua` → `item` |
| One widget's state-dependent styling | `widgets/<name>.lua` → `render` |
| The pill surface behind every widget | `settings.pill` |
| The pill surface behind one widget | `widgets/<name>.lua` → `pill` |
| Bar height, position, and outer padding | `settings.bar`, `bar.lua` |
| Workspace buttons and decorations | `settings.groups`, `widgets/aerospace.lua` |
| Palette values | `colors.lua` |

### How properties are resolved

An item's properties are built once at creation, in this order:

1. Properties inherited from `settings.defaults`, applied through
   `sbar.default` before any item exists
2. Shared widget properties from `settings.widgets`
3. The widget module's own `item` table

Each step merges into the previous one. Nested tables merge key by key, so
overriding `label.font.size` keeps the inherited family and style. Any other
explicit value replaces the previous one, including `false` and `0`. The last
explicit write wins, and nothing is applied after the widget's own `item` table.

After the item exists, each refresh applies exactly what `render` returns:

- A returned field is written to the item.
- An omitted field keeps its current value. Omission is not deletion.
- Returning `nil`, or having no `render`, changes nothing.

To undo a value a renderer previously set, return the desired fallback
explicitly. A static value in `item` will not come back on its own.

### Widget specification fields

| Field | Type | Consumed by | Meaning |
|---|---|---|---|
| `name` | string | helpers | Item name `widgets.<name>` and pill name `pill.<name>` |
| `item` | table | SketchyBar | Static item properties for this widget |
| `pill` | table | SketchyBar | Bracket properties for this widget's pill surface |
| `update_freq` | number | SketchyBar | Refresh interval in seconds |
| `events` | list | helpers | Events that trigger a refresh |
| `command` | string | helpers | Shell command run asynchronously on refresh |
| `parse` | function | helpers | Turns command output into a state value |
| `render` | function | helpers | Turns a state value into a property update |
| `on_click` | string | helpers | Shell command run on `mouse.clicked` |

`update_freq` is scheduling, not styling. It stays authoritative even if
`item.update_freq` is also set. A widget without `command` is static and is
rendered once at startup.

### Worked example: battery

`widgets/battery.lua` returns:

```lua
return {
  name = "battery",
  item = {
    icon = { string = icons.empty },
    label = { width = 36 },
  },
  update_freq = 120,
  events = { "routine", "forced", "power_source_change", "system_woke" },
  command = "/usr/bin/pmset -g batt",
  parse = function(output) ... end,
  render = function(state) ... end,
}
```

`init.lua` passes it to `helpers/pill.lua`, which creates two things:

- the item `widgets.battery`, whose properties are
  `settings.defaults` → `settings.widgets` → the module's `item` table
- the bracket `pill.battery`, whose properties are
  `settings.pill` → the module's `pill` table

So at startup the battery icon uses the shared Bold icon font and the shared
icon spacing, and its label uses the shared label font with an explicit width of
36 points.

On each refresh the helper runs `pmset`, passes the output to `parse`, and
passes the resulting state to `render`. While charging, `render` returns:

```lua
{
  icon = { string = "󰂄", color = colors.green },
  label = { string = "84%" },
}
```

Only those four values change. The icon font, the label font, the 36 point label
width, the item padding, and the pill surface are all untouched, because the
renderer did not mention them.

### Common edits

Change only the battery label size, keeping the shared family and style:

```lua
item = {
  icon = { string = icons.empty },
  label = { width = 36, font = { size = 16.0 } },
},
```

Give the battery a wider label and a bigger gap between icon and label:

```lua
item = {
  icon = { string = icons.empty, padding_right = 8 },
  label = { width = 44 },
},
```

Give one widget a different pill surface:

```lua
pill = { background = { color = colors.pill_bg, border_width = 1 } },
```

Change a battery state color by editing the branch in its `render` function.
CPU and memory thresholds work the same way.

### Things worth knowing

- `render` cannot style the pill. The pill is a bracket drawn around the item
  and is a different surface from the item's own `background`. Use `pill` or
  `settings.pill`.
- A static color in `item` is superseded whenever the renderer explicitly writes
  that same color. Set state-dependent colors in `render`, not both places.
- A fixed-width label keeps its space when its string is empty. Hide it with an
  explicit `label = { drawing = false }`.
- Spotify is static: it has no `command` or `render`, so its green icon lives in
  its `item` table. It hides its label and sets `icon.padding_right = 0` so the
  icon-only pill stays symmetric.
- Slack and Teams are built by `helpers/app_badge.lua`, which supplies the shared
  command, parser, and renderer. They pass their own icon, brand color, and
  `item` table into the factory.
- AeroSpace inherits `settings.defaults` but not `settings.widgets`. It styles
  its own workspace buttons from `settings.groups` and reuses `settings.pill`
  for its bracket.

### Migrated field names

| Removed | Use instead |
|---|---|
| `defaults.lua` | `settings.defaults` |
| `settings.fonts`, `settings.item` | `settings.defaults` |
| `settings.widgets.font` | `settings.defaults` |
| `settings.widgets.item_padding` | `settings.widgets.padding_left` / `padding_right` |
| `settings.widgets.icon_label_gap` | `settings.widgets.icon.padding_right` |
| `settings.widgets.y_offset` | `settings.widgets.icon.y_offset` / `label.y_offset` |
| `settings.pills.gap` | `settings.widgets.padding_left` |
| `settings.pill.height` and siblings | `settings.pill.background.*` |
| widget `icon = "󰂎"` | widget `item.icon.string` |
| widget `label_width = 36` | widget `item.label.width` |

### Editing workflow

Hotload is enabled, so saving a file in this directory reloads the bar. To
reload explicitly and inspect what actually applied:

```sh
sketchybar --reload
sketchybar --query defaults
sketchybar --query widgets.battery
sketchybar --query pill.battery
```

Values set from the command line are temporary: the next reload, or the next
explicit property in a renderer, overwrites them.

Run the styling regression tests from the repository root. They use a stubbed
SbarLua module and need neither a running bar nor the native module:

```sh
lua sketchybar/tests/style_test.lua
```

## Adding a widget

Add a module under `widgets/` that returns a widget specification, then add its
name to `right_pills` in `init.lua`. Names are listed in reverse visual order
because SketchyBar inserts right-side items from right to left.
`helpers/widget.lua` owns subscriptions, command execution, error handling, and
the initial refresh, and `helpers/pill.lua` wraps the widget in its own pill.

Right-side widgets use Hack Nerd Font glyphs.

## SbarLua

Startup expects a Lua-compatible SbarLua native module at
`~/.local/share/sketchybar_lua/sketchybar.so`; it does not install or update the
module automatically. Follow the [SbarLua installation instructions][sbarlua]
and build the module with the Lua runtime used to start SketchyBar.

[items]: https://felixkratz.github.io/SketchyBar/config/items
[sbarlua]: https://github.com/FelixKratz/SbarLua
