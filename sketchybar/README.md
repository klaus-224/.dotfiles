# SketchyBar

Home Manager links this directory to `~/.config/sketchybar`. The executable
`sketchybarrc` loads `init.lua` by using SketchyBar's `CONFIG_DIR`; `init.lua`
owns SbarLua loading, configuration batching, hotload, and the event loop.

## Layout

- `settings.lua`: shared fonts, text padding, bar geometry, and workspace-group geometry
- `colors.lua`: the shared Vague palette and semantic colors
- `bar.lua`: bar-only placement, display association, and appearance
- `defaults.lua`: properties inherited by every subsequently created item
- `items/init.lua`: explicit item import order
- `items/*.lua`: widget definitions, subscriptions, refresh logic, and meaningful overrides

Change icon and label fonts in `settings.fonts`, shared text padding in
`settings.item`, bar dimensions in `settings.bar`, and workspace-button spacing
and dimensions in `settings.groups`. Change palette values in `colors.lua`.
State-dependent colors, update intervals, icons, and command behavior stay with
their item modules.

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

The check does not contact SketchyBar, switch workspaces, or launch Slack. After
configuration changes, reload the live bar separately and compare both displays,
workspace selection, group clicks, Slack status/click behavior, and the clock.
Group clicks call `scripts/aerospace-groups.sh`, which intentionally requires
exactly two connected displays.
