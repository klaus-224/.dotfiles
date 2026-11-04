-- Look of the bar. Edit values here, then `sketchybar --reload`.
-- Colours are 0xAARRGGBB. The palette is Vague (starship/nvim/tmux), laid out
-- as the island design of github.com/garamnohhh/sketchybar-island.

-- Base palette ------------------------------------------------------------
local palette = {
  bg = 0xff08090a,      -- island fill (github.com/garamnohhh/sketchybar-island dark BG)
  surface = 0xff18181c, -- popup fill
  line = 0xff1e2422,    -- island borders, media island, empty gauge cells (reference LINE)
  line2 = 0xff333340,   -- active workspace chip
  text = 0xffcdcdcd,    -- values
  text2 = 0xff878787,   -- secondary values, controls
  text3 = 0xff606079,   -- tags ("wifi", "bat"), captions
  accent = 0xff99b782,  -- playing, charging, finished agents
  warn = 0xffe8b589,
  err = 0xffc48282,
  info = 0xff6e94b2,
  claude = 0xffd99a78,
  slack = 0xffc48282, -- Slack icon while Slack runs
  teams = 0xff6e94b2, -- Teams icon while Teams runs
  docker = 0xff9bb4bc, -- Docker icon while Docker Desktop runs
  rancher = 0xffb4d4cf, -- Rancher icon while Rancher Desktop runs
  transparent = 0x00000000,
}

-- Mixes two opaque colours: t = 0 gives `a`, 1 gives `b`.
local function mix(a, b, t)
  local function ch(c, s) return (c >> s) & 0xff end
  local out = 0xff000000
  for _, s in ipairs({ 16, 8, 0 }) do
    out = out | (math.floor(ch(a, s) + (ch(b, s) - ch(a, s)) * t + 0.5) << s)
  end
  return out
end

-- Applies an opacity percentage to a colour.
local function alpha(color, percent)
  return (color & 0x00ffffff) | (math.floor(255 * percent / 100 + 0.5) << 24)
end

-- Surface of islands and menus: solid Vague background with a dark edge.
-- For glass, lower `opacity` (menus then also blur by `blur`).
local surface = {
  color = palette.bg,
  opacity = 100,       -- fill opacity (%)
  edge = palette.info, -- island and menu borders: tmux popup border (@c_active)
  blur = 0,            -- menu blur radius; only visible below 100% opacity
}

local island = {
  height = 32,        -- island and circle height (pt)
  corner_radius = 8, -- island corners; circles use height / 2
  border_width = 1,
  border_color = surface.edge,
  color = surface.color,
  opacity = surface.opacity, -- island fill opacity (%)
  gap = 5,                   -- space between islands and circles
  inner = 11,                -- padding inside the island ends
  cell_gap = 24,             -- space between cells inside an island
  tag_gap = 8,               -- space between a tag ("wifi") and its value
}

return {
  colors = palette,
  mix = mix,
  alpha = alpha,

  font = {
    text = "Hack Nerd Font Mono", -- nerd-fonts.hack (nix/darwin/default.nix)
    icons = "Hack Nerd Font Propo",
    gauge = "Menlo",              -- gauge cells (U+258B) in popups
    size = 13.5,
    small = 12.0,                 -- menu section headings ("TODAY", "OUTPUT")
    -- Advance of one character at `size` (Hack: 1233/2048 em). Text fitting,
    -- the calendar grid and menu widths are computed from it.
    char_width = 14.0 * 1233 / 2048,
  },

  bar = {
    height = island.height,
    margin = 12,       -- left/right screen margin; matches AeroSpace gaps.outer.left/right
    y_offset = 6,      -- distance from the top of the screen (islands float)
    display = "all",   -- "all", "main", or a display number
    notch_width = 230, -- notch + 2 × island.gap on notched displays
    topmost = "window",
  },

  island = island,

  -- CPU cat's grass: blades and ground, Vague green over the island black.
  cat = {
    blade = 0xff5a9e7a, -- lighter than the ground so blades show
    ground = 0xff3f775c, -- the reference's grass green
  },

  media = {
    title_width = 220,                -- title cell width (pt)
    color = palette.line,             -- media island fill
    opacity = 80,                     -- media island opacity (%): translucent
    fill = alpha(palette.accent, 25), -- progress fill, translucent like the island
  },

  popup = {
    color = surface.color,
    opacity = surface.opacity,
    border_color = surface.edge,
    border_width = 1,
    corner_radius = 0,
    blur_radius = surface.blur,
    y_offset = 2,
    row_height = 26,
    key_width = 76, -- left key column
    padding = 12,
  },

  underline = { color = palette.text, height = 2 },

  -- Usage thresholds (percent used) for warning and error colours.
  thresholds = { warn = 80, err = 95 },
}
