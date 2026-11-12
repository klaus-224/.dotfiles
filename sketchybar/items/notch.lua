-- Built-in display notch. The right side is wider than the space right of
-- the notch, so while a notched display is connected the agents island and
-- Pilo move to the notch queue, left of the notch, and the media island
-- drops its "spotify" tag and narrows its title until it ends a gap before
-- them. Without a notched display (external only, lid closed) the layout
-- is unchanged. SketchyBar applies notch_width only on notched displays;
-- the items are shared, so an external display next to the open lid shows
-- the same arrangement.
local sbar = require("sketchybar")
local theme = require("theme")
local helper = require("helpers.helper")

local gap = theme.island.gap

-- opts.queue: items to move, nearest the notch first; opts.outer: name of
-- the outermost one; opts.media: items/media.lua; opts.on_change(on).
return function(opts)
  local notch -- { width, x, w } from `sbar-helper notch`, nil without one
  local observer = sbar.add("item", "notch.observer", { drawing = false, updates = true })

  -- bounding_rects key of the notched display, matched by its frame.
  local function display_key()
    for _, d in ipairs(sbar.query("displays") or {}) do
      local f = d.frame
      if f and math.abs(f.x - notch.x) < 1 and math.abs(f.w - notch.w) < 1 then
        return "display-" .. d["arrangement-id"]
      end
    end
  end

  local function rect(name, key)
    local q = sbar.query(name)
    local r = type(q) == "table" and type(q.bounding_rects) == "table" and q.bounding_rects[key]
    if r and r.size and r.size[1] > 0 then return r.origin[1], r.size[1] end
  end

  -- Moves the title width by the overlap (or the room left) between the
  -- media island and the outermost queued item.
  local function fit()
    if not notch then return end
    local key = display_key()
    if not key then return end
    local mx, mw = rect("island.media", key)
    local ox = rect(opts.outer, key)
    if not (mx and ox) then return end
    local room = ox - gap - (mx + mw)
    local w = math.floor(opts.media.title_width() + room)
    w = math.max(theme.media.min_title_width, math.min(theme.media.title_width, w))
    opts.media.set_title_width(w)
  end

  local function apply(r)
    local width = tonumber(r.width) or 0
    notch = width > 0 and { width = width, x = tonumber(r.x) or 0, w = tonumber(r.w) or 0 } or nil
    -- A gap on each side of the notch.
    sbar.bar({ notch_width = notch and math.floor(notch.width) + 2 * gap or 0 })
    for _, item in ipairs(opts.queue) do item:set({ position = notch and "q" or "right" }) end
    opts.on_change(notch ~= nil)
    if notch then
      opts.media.set_title_width(opts.media.title_width())
      sbar.delay(0.5, fit)
    else
      opts.media.set_title_width(nil)
    end
  end

  local function refresh() helper.run({ "notch" }, apply) end

  observer:subscribe({ "display_change", "system_woke" }, refresh)
  -- The front app name changes the AeroSpace island's width.
  observer:subscribe("front_app_switched", function() if notch then sbar.delay(0.2, fit) end end)
  refresh()
end
