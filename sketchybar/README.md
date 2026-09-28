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
- `settings.lua`: shared fonts, text padding, bar, pill, and workspace geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `defaults.lua`: properties inherited by every subsequently created item
- `widgets/*.lua`: declarative widget specifications
- `widgets/aerospace.lua`: the dynamic workspace integration
- `helpers/widget.lua`: item creation, refresh, parsing, rendering, click wiring
- `helpers/pill.lua`: one fixed-width pill per widget
- `helpers/app_badge.lua`: shared specification factory for app presence badges

## Where styles live

| To change | Edit | Notes |
|---|---|---|
| Base item font and padding | `settings.fonts`, `settings.item` | Inherited by every item. Right-side widgets override the font. |
| Right-widget font and vertical offset | `settings.widgets.font`, `y_offset` | Fallback for all right-side widgets. |
| One widget's font or static properties | `widgets/<name>.lua` → `item` | Wins over the shared widget fallbacks. |
| One widget's fixed label width | `widgets/<name>.lua` → `label_width` | Prevents a changing label from resizing the pill. |
| State-dependent glyphs, text, colors | `widgets/<name>.lua` → `render` | Applied on every refresh. |
| Gap between pills | `settings.pills.gap` | Applied as each pill's left padding. |
| Gap between icon and label | `settings.widgets.icon_label_gap` | Applied at render time. |
| Pill height, radius, border width | `settings.pill` | Shared by all pills. |
| Pill background and border colors | `colors.pill_bg`, `colors.pill_border` | Shared by all pills. |
| Workspace buttons and decorations | `widgets/aerospace.lua` | Uses shared geometry from `settings.groups`. |
| Palette values | `colors.lua` | Includes the translucent pill and separator surfaces. |

### Precedence

Item properties are resolved in this order, each step overriding the previous:

1. Properties inherited from `defaults.lua`
2. Shared widget properties from `settings.widgets`
3. The widget module's own `item` table
4. Pill geometry: left padding, zero right padding, and `label_width`

After an item exists, each refresh applies whatever `render` returns. Only the
fields present in that update change; everything else keeps its current value.

Three things are therefore not worth overriding per widget:

- **Static colors that `render` also sets.** The renderer wins on the first
  refresh. Change the color inside `render` instead.
- **`item.padding_left` and `item.padding_right` for pills.** The pill helper
  replaces both. Use `settings.pills.gap` for the shared gap.
- **Icon right padding and label `drawing`.** Both are derived at render time
  from whether the rendered label has content.

There is currently no per-widget pill override. All pills share the appearance
from `settings.pill` and the pill colors. Note that a widget's `item.background`
and its pill are different surfaces: the pill is a bracket drawn around the item.

### Examples

To change the battery font and label width, edit only `widgets/battery.lua`:

```lua
return {
  name = "battery",
  label_width = 36,
  item = {
    icon = { font = { family = "Hack Nerd Font", style = "Bold", size = 16.0 } },
    label = { font = { family = "Hack Nerd Font", style = "Regular", size = 13.0 } },
  },
  -- ...
}
```

To change its charging or low-battery colors, edit the branches in that same
file's `render` function. CPU and memory thresholds and colors live in their
renderers the same way. Spotify's static green icon lives in its `item` table,
since it has no state. Slack and Teams pass their icon and color into
`helpers/app_badge.lua`, which supplies the shared badge command and rendering.

## Adding a widget

Add a module under `widgets/` that returns a widget specification, then add its
name to `right_pills` in `init.lua`. Names are listed in reverse visual order
because SketchyBar inserts right-side items from right to left. A specification
names the widget and can provide its icon, update interval, events, command,
parser, renderer, and click action. `helpers/widget.lua` owns subscriptions,
command execution, error handling, and the initial refresh, and
`helpers/pill.lua` wraps the widget in its own pill.

Right-side widgets use Hack Nerd Font glyphs. The Spotify pill is always green
and has no playback state; clicking it opens Spotify.

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
