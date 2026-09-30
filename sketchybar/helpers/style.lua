-- Pure property table helpers shared by the item modules.
--
-- SketchyBar properties are plain nested tables, so styling is resolved by
-- merging those tables in a fixed order. Nested tables merge key by key; any
-- other explicit value, including `false` and `0`, replaces the previous one.
local style = {}

-- Deep copy, so no resolved property table ever shares mutable state with a
-- settings table or a widget module.
function style.copy(value)
  if type(value) ~= "table" then return value end

  local result = {}
  for key, nested in pairs(value) do result[key] = style.copy(nested) end
  return result
end

-- Merge `source` into `target` in place. `target` is expected to be a private
-- copy; `source` is never mutated and never shared into `target`.
function style.merge(target, source)
  for key, value in pairs(source or {}) do
    if type(value) == "table" and type(target[key]) == "table" then
      style.merge(target[key], value)
    else
      target[key] = style.copy(value)
    end
  end
  return target
end

-- Resolve any number of property tables, later tables overriding earlier ones.
function style.resolve(...)
  local resolved = {}
  for index = 1, select("#", ...) do
    style.merge(resolved, (select(index, ...)))
  end
  return resolved
end

return style
