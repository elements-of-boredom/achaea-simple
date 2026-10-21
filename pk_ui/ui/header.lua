PkCore.ui = PkCore.ui or {}
PkCore.ui.header = PkCore.ui.header or {}

local STATS = {
  { "Lvl", "hdrLevel" }, { "Lessons", "hdrLessons" }, { "Credits", "hdrCredits" },
  { "Msgs:", "hdrMsgs" }, { "Gold", "hdrGold" }, { "Bank", "hdrBank" },
}

local function commas(n)
  if n == nil then return "?" end
  local s = string.reverse(tostring(math.floor(n)))
  s = string.reverse(string.gsub(s, "(%d%d%d)", "%1,"))
  return string.gsub(s, "^,", "")
end

local function show(v)
  if v == nil then return "?" end
  return tostring(v)
end

-- Static html. Using data-mud-bind to bind to lua variables
function PkCore.ui.header.html()
  local stats = {}
  for _, s in ipairs(STATS) do
    stats[#stats + 1] = '<div data-stat="' .. s[1] .. '"><dt>' .. s[1] .. '</dt>'
      .. '<dd data-mud-bind="' .. s[2] .. '"></dd></div>'
  end
  return '<header class="mf-header" data-field="header">'
    .. '<div class="mf-brand"><div><strong>ACHAEA</strong><small data-mud-bind="hdrClass"></small></div></div>'
    .. '<dl class="mf-stats">' .. table.concat(stats) .. "</dl>"
    .. '<div class="mf-location"><div>'
    ..   '<h1 data-mud-bind="hdrRoom"></h1>'
    ..   '<span>[<b data-mud-bind="hdrRoomId"></b>]<span data-mud-bind="hdrExits"></span></span>'
    .. "</div></div>"
    .. "</header>"
end

function PkCore.ui.header.render()
  local id = PkCore.ui.layout.widgets.header
  if not id then return end
  local p, r = PkCore.player, PkCore.room
  local exits = table.concat(r.sortedExits(), ", ")
  setBoundValues(id, {
    hdrClass   = string.upper(p.class or ""),
    hdrLevel   = show(p.level),
    hdrLessons = show(p.lessons),
    hdrCredits = show(p.boundCredits) .. " / " .. show(p.unboundCredits),
    hdrMsgs    = show(p.unreadMsgs) .. " / News: " .. show(p.unreadNews),
    hdrGold    = commas(p.gold),
    hdrBank    = commas(p.bank),
    hdrRoom    = r.name or "Unknown room",
    hdrRoomId  = show(r.number),
    hdrExits   = exits ~= "" and (" · EXITS: " .. string.upper(exits)) or "",
  })
end

PkCore.onStateChanged("ui.header", PkCore.ui.header.render)
PkCore.ui.layout.setContent("header", PkCore.ui.header.html)