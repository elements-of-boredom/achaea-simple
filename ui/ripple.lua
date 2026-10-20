PkCore.ui.ripple = PkCore.ui.ripple or {
  rooms = {}, exits = {}, known = {}, idToKey = {}, cx = 0, cy = 0,
}
local R = PkCore.ui.ripple

local CONSOLE = "PkCore_map_ripple_console"
local VIEW_RADIUS = 5
local DIR_OFFSET = {
  n  = { 0,  1}, s  = { 0, -1},
  e  = { 1,  0}, w  = {-1,  0},
  ne = { 1,  1}, nw = {-1,  1},
  se = { 1, -1}, sw = {-1, -1},
}

local function isShowing()
  return PkCore.ui.map.views ~= nil and PkCore.ui.map.activeTab == "Ripple"
end

function R.clear()
  R.rooms, R.exits, R.known, R.idToKey = {}, {}, {}, {}
  R.cx, R.cy = 0, 0
  R.render()
end

function R.onRoomInfo()
  if not isShowing() then return end
  local info = gmcp and gmcp.Room and gmcp.Room.Info
  if not info then return end
  local id = tonumber(info.num)
  if not id then return end

  if R.idToKey[id] then
    local x, y = R.idToKey[id]:match("(-?%d+),(-?%d+)")
    R.cx, R.cy = tonumber(x), tonumber(y)
    R.render()
    return
  end

  -- anchor off a known neighbour: a north exit to known room X means we're south of X
  local placed = false
  for rawDir, neighborId in pairs(info.exits or {}) do
    local off = DIR_OFFSET[rawDir:lower()]
    local nk = off and R.idToKey[tonumber(neighborId)]
    if nk then
      local nx, ny = nk:match("(-?%d+),(-?%d+)")
      R.cx, R.cy = tonumber(nx) - off[1], tonumber(ny) - off[2]
      placed = true
      break
    end
  end
  if not placed and next(R.rooms) == nil then
    R.cx, R.cy = 0, 0
  end

  local key = R.cx .. "," .. R.cy
  R.rooms[key] = { id = id, name = info.name or "" }
  R.idToKey[id] = key
  R.known[key] = nil

  R.exits[key] = {}
  for rawDir in pairs(info.exits or {}) do
    local dir = rawDir:lower()
    local off = DIR_OFFSET[dir]
    if off then
      R.exits[key][dir] = true
      local nk = (R.cx + off[1]) .. "," .. (R.cy + off[2])
      if not R.rooms[nk] then R.known[nk] = true end
    end
  end

  R.render()
end

function R.render()
  if not isShowing() then return end
  clearWindow(CONSOLE)

  local size = (VIEW_RADIUS * 2 + 1) * 2 - 1
  local grid = {}
  for r = 1, size do
    grid[r] = {}
    for c = 1, size do grid[r][c] = " " end
  end

  for dy = -VIEW_RADIUS, VIEW_RADIUS do
    for dx = -VIEW_RADIUS, VIEW_RADIUS do
      local key = (R.cx + dx) .. "," .. (R.cy + dy)
      local dr = (VIEW_RADIUS - dy) * 2 + 1
      local dc = (VIEW_RADIUS + dx) * 2 + 1
      local isCur = dx == 0 and dy == 0
      local room = R.rooms[key]

      if isCur then grid[dr][dc] = "@"
      elseif room then grid[dr][dc] = "#"
      elseif R.known[key] then grid[dr][dc] = "."
      end

      if room or isCur then
        local ex = R.exits[key] or {}
        if ex.e  and dc + 1 <= size then grid[dr][dc + 1] = "-" end
        if ex.w  and dc - 1 >= 1    then grid[dr][dc - 1] = "-" end
        if ex.n  and dr - 1 >= 1    then grid[dr - 1][dc] = "|" end
        if ex.s  and dr + 1 <= size then grid[dr + 1][dc] = "|" end
        if ex.ne and dr - 1 >= 1    and dc + 1 <= size then grid[dr - 1][dc + 1] = "/"  end
        if ex.nw and dr - 1 >= 1    and dc - 1 >= 1    then grid[dr - 1][dc - 1] = "\\" end
        if ex.se and dr + 1 <= size and dc + 1 <= size then grid[dr + 1][dc + 1] = "\\" end
        if ex.sw and dr + 1 <= size and dc - 1 >= 1    then grid[dr + 1][dc - 1] = "/"  end
      end
    end
  end

  for r = 1, size do
    local row = {}
    for c = 1, size do
      local ch = grid[r][c]
      if ch == "@" then row[c] = "<ansi_011>@<reset>"
      elseif ch == "#" then row[c] = "<ansi_007>#<reset>"
      elseif ch == " " then row[c] = " "
      else row[c] = "<DimGrey>" .. ch .. "<reset>"
      end
    end
    cecho(CONSOLE, table.concat(row) .. "\n")
  end
end

PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.Info",
  PkCore.protected("ui.ripple.onRoomInfo", R.onRoomInfo)))

-- a whirlpool floor ends
PkCore.trackTrigger(tempRegexTrigger("^A fulgent eddy falls still",
  PkCore.protected("ui.ripple.clear", R.clear)))

-- diving in: jump to the Ripple tab with a fresh grid
PkCore.trackTrigger(tempRegexTrigger("^You silently slip beneath the water and the world is as it once was",
  PkCore.protected("ui.ripple.diveIn", function()
    PkCore.ui.map.select("Ripple")
    R.clear()
  end)))

-- Mnemosyne's memory loss ends: back to the real map
PkCore.trackTrigger(tempRegexTrigger("^The Mnemosyne relinquishes memory's grip upon you",
  PkCore.protected("ui.ripple.memoryRestored", function()
    PkCore.ui.map.select("Mudlet")
  end)))