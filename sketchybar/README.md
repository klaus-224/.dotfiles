# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` using SketchyBar's `CONFIG_DIR`.

The transparent bar places the Apple logo, separator, and five AeroSpace
workspaces in one pill per display on the left. Right-side pills appear as:

- Personal: `[Spotify] [memory] [CPU] [date] [time] [battery]`
- Work (`USER=rohineshram`): `[Slack] [Teams] [Spotify] [memory] [CPU] [date] [time] [battery]`

Slack and Teams are imported only for the work account, so other accounts do
not create their items, spacers, subscriptions, or polling commands.

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
- Each item passes its own properties directly to `sbar.add(...)`, owns its
  subscriptions and click actions, and creates its pill bracket. There is no
  Lua property-merging layer.
- `items/aerospace.lua` owns workspace geometry, per-display creation and
  removal, active-workspace highlighting, and the workspace-change event.
  `items/apple.lua` supplies the decorative logo for each display.
- `items/clock.lua` is an optional combined clock; it is not loaded by default.

Pill backgrounds inherit a height of 28 and corner radius of 12 from native
defaults. Explicit 8-point spacers sit between right-side pills, outside their
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
for file in sketchybar/*.lua sketchybar/items/*.lua sketchybar/sketchybarrc; do
  luac -p "$file" || exit 1
done
```

Home Manager points at `~/.dotfiles/sketchybar`. Changes in another worktree
are not active until integrated into that checkout. Once active, hotload
reloads saved edits; an explicit reload and inspection use:

```sh
sketchybar --reload
sketchybar --query defaults
sketchybar --query widgets.memory
sketchybar --query pill.memory
```

Check icons, pill gaps, memory-label fit, work-app visibility, clicks, and
workspace highlighting on each display. Inspect configuration errors with:

```sh
tail /opt/homebrew/var/log/sketchybar/sketchybar.err.log
tail /opt/homebrew/var/log/sketchybar/sketchybar.out.log
```

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
