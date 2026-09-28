local sbar = require("sketchybar")
local settings = require("settings")
local style = require("helpers.style")

-- Shared runtime for declarative widgets: item creation, refresh, parsing,
-- rendering, and click wiring. Widget modules under `widgets/` stay pure data
-- plus `parse`/`render` functions and never talk to SbarLua themselves.
local widget = {}

-- Runtime fallbacks only. Everything visual comes from `settings.widgets` and
-- the widget module's own `item` table.
local function base(position)
  return {
    position = position or "right",
    icon = { string = "" },
    label = { string = "" },
  }
end

-- Creation-time properties for a widget, resolved in a single documented order:
-- inherited SketchyBar defaults, then runtime fallbacks, then
-- `settings.widgets`, then the widget module's own `item` table.
local function properties(spec, position)
  local resolved = style.resolve(base(position), settings.widgets, spec.item)

  -- Scheduling, not styling: the spec field stays authoritative.
  if spec.update_freq then resolved.update_freq = spec.update_freq end

  return resolved
end

function widget.add(spec, position)
  assert(type(spec) == "table", "widget spec must be a table")
  assert(type(spec.name) == "string", "widget spec requires a name")

  local item = sbar.add("item", "widgets." .. spec.name, properties(spec, position))

  -- A render result is a plain property update: only the fields it returns
  -- change, and everything else keeps its current value.
  local function render(state)
    if not spec.render then return end

    local rendered = spec.render(state)
    if type(rendered) ~= "table" then return end

    item:set(style.copy(rendered))
  end

  local function refresh()
    if not spec.command then
      render(nil)
      return
    end

    sbar.exec(spec.command, function(output, exit_code)
      if exit_code ~= 0 then
        render(nil)
        return
      end

      local ok, state = pcall(spec.parse or function(value) return value end, output, exit_code)
      render(ok and state or nil)
    end)
  end

  local events = spec.events
  if not events and spec.command then events = { "routine", "forced" } end
  if events and #events > 0 then item:subscribe(events, refresh) end

  if spec.on_click then
    item:subscribe("mouse.clicked", function()
      sbar.exec(spec.on_click)
    end)
  end

  if spec.command then refresh() end

  return item
end

return widget
