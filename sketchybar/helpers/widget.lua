local sbar = require("sketchybar")

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

function widget.add(spec, position)
  assert(type(spec) == "table", "widget spec must be a table")
  assert(type(spec.name) == "string", "widget spec requires a name")

  local properties = merge({
    position = position or "right",
    icon = { string = spec.icon or "" },
    label = { string = "" },
  }, spec.item)

  if spec.update_freq then properties.update_freq = spec.update_freq end

  local item = sbar.add("item", "widgets." .. spec.name, properties)

  local function render(state)
    if spec.render then item:set(spec.render(state)) end
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
      if type(spec.on_click) == "function" then
        spec.on_click(item)
      else
        sbar.exec(spec.on_click)
      end
    end)
  end

  if spec.command then refresh() end

  return item
end

return widget
