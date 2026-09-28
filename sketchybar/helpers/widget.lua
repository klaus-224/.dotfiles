local sbar = require("sketchybar")
local settings = require("settings")

-- Shared runtime for declarative widgets: item creation, refresh, parsing,
-- rendering, and click wiring. Widget modules under `widgets/` stay pure data
-- plus `parse`/`render` functions and never talk to SbarLua themselves.
local widget = {}

local function copy(value)
  if type(value) ~= "table" then return value end

  local result = {}
  for key, nested in pairs(value) do result[key] = copy(nested) end
  return result
end

local function merge(target, source)
  for key, value in pairs(source or {}) do
    if type(value) == "table" and type(target[key]) == "table" then
      merge(target[key], value)
    else
      target[key] = copy(value)
    end
  end
  return target
end

-- Item properties for a widget. `overrides` is applied after `spec.item`, so
-- wrappers such as `helpers/pill.lua` can enforce their geometry without
-- mutating the widget module.
local function properties(spec, position, overrides)
  local merged = merge({
    position = position or "right",
    padding_left = settings.widgets.item_padding,
    padding_right = settings.widgets.item_padding,
    icon = {
      string = spec.icon or "",
      font = settings.widgets.font,
      padding_right = 0,
      y_offset = settings.widgets.y_offset,
    },
    label = {
      string = "",
      drawing = false,
      font = settings.widgets.font,
      y_offset = settings.widgets.y_offset,
    },
  }, spec.item)

  merge(merged, overrides)

  if spec.update_freq then merged.update_freq = spec.update_freq end

  return merged
end

function widget.add(spec, position, overrides)
  assert(type(spec) == "table", "widget spec must be a table")
  assert(type(spec.name) == "string", "widget spec requires a name")

  local item = sbar.add("item", "widgets." .. spec.name, properties(spec, position, overrides))

  local function render(state)
    if not spec.render then return end

    local rendered = spec.render(state) or {}
    local label = rendered.label and rendered.label.string
    rendered.icon = rendered.icon or {}
    rendered.label = rendered.label or {}
    rendered.icon.padding_right = label and label ~= "" and settings.widgets.icon_label_gap or 0
    rendered.label.drawing = label ~= nil
    if label == nil then rendered.label.string = "" end
    item:set(rendered)
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
