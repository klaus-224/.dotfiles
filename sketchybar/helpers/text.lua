-- Monospace text metrics: SketchyBar cannot measure text from Lua, so cell
-- widths are computed from the font's fixed advance (theme.font.char_width).
local theme = require("theme")

local text = {}
local nbsp = "\u{00A0}"

local function wide(cp)
  -- Hangul, CJK and kana take about 1.45 cells in the fallback fonts.
  return (cp >= 0x1100 and cp <= 0x11ff) or (cp >= 0x2e80 and cp <= 0x9fff)
    or (cp >= 0xac00 and cp <= 0xd7af) or (cp >= 0xf900 and cp <= 0xfaff)
end

local function advance(cp, cw)
  return wide(cp) and cw * 1.44 or cw
end

-- Menu width holding `chars` characters between the side paddings.
function text.menu_width(chars)
  return 2 * theme.popup.padding + math.ceil(chars * theme.font.char_width)
end

function text.width(s, cw)
  cw = cw or theme.font.char_width
  local w = 0
  for _, cp in utf8.codes(tostring(s or "")) do w = w + advance(cp, cw) end
  return math.ceil(w)
end

-- Cuts `s` to fit `max` points, ending with an ellipsis.
function text.fit(s, max, cw)
  cw = cw or theme.font.char_width
  s = tostring(s or "")
  if text.width(s, cw) <= max then return s end
  local out, w = {}, cw -- room for the ellipsis
  for _, cp in utf8.codes(s) do
    local a = advance(cp, cw)
    if w + a > max then break end
    w = w + a
    out[#out + 1] = utf8.char(cp)
  end
  return (table.concat(out):gsub("%s+$", "")) .. "…"
end

-- Joins `left` and `right` with spaces so `right` ends near `width` points.
function text.spread(left, right, width, cw)
  cw = cw or theme.font.char_width
  local gap = math.max(2, math.floor((width - text.width(left, cw) - text.width(right, cw)) / cw + 0.5))
  return left .. string.rep(nbsp, gap) .. right
end

-- Leading/inner spaces survive in labels only as non-breaking spaces.
function text.hard(s)
  return (tostring(s):gsub(" ", nbsp))
end

function text.tokens(n)
  n = tonumber(n) or 0
  if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
  if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
  if n >= 1e3 then return string.format("%.0fk", n / 1e3) end
  return tostring(math.floor(n))
end

function text.clock(seconds)
  seconds = math.max(0, math.floor(tonumber(seconds) or 0))
  return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function text.ago(t)
  local d = os.time() - (tonumber(t) or 0)
  if d < 90 then return "now" end
  if d < 5400 then return string.format("%dm ago", d // 60) end
  if d < 129600 then return string.format("%dh ago", d // 3600) end
  return string.format("%dd ago", d // 86400)
end

return text
