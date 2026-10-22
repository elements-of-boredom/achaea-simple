PkCore.room = PkCore.room or {}
local room = PkCore.room

room.exits = room.exits or {}
room.items = room.items or {}
room.players = room.players or {}
room.ignoreNames = room.ignoreNames or {
  "a swarm of bees",
}

-- GMCP lists arrive as JS arrays (0-based underneath). Copy into plain Lua lists before
-- indexing, inserting or removing.
local function copyList(t)
  local out = {}
  if type(t) == "table" then
    for _, v in ipairs(t) do out[#out + 1] = v end
  end
  return out
end

local function has(s, needle)
  return string.find(s, needle, 1, true) ~= nil
end

local function isIgnoredName(name)
  for _, pat in ipairs(room.ignoreNames) do
    if has(name, pat) then return true end
  end
  return false
end

local function isLiveMobItem(item)
  if type(item) ~= "table" then return false end
  local attrib = tostring(item.attrib or "")
  if not has(attrib, "m") or has(attrib, "d") or has(attrib, "x") then return false end
  local icon = string.lower(tostring(item.icon or ""))
  local name = string.lower(tostring(item.name or ""))
  if isIgnoredName(name) then return false end
  return icon ~= "deadbody" and not has(name, "corpse")
end

function room.mobEntries()
  local entries = {}
  for _, item in ipairs(room.items) do
    if isLiveMobItem(item) then
      table.insert(entries, { name = tostring(item.name or "?"), id = item.id })
    end
  end
  return entries
end

-- Rolled up by name (6 "a cube sigil" -> one entry, count = 6).
function room.itemEntries()
  local counts, order, ids = {}, {}, {}
  for _, item in ipairs(room.items) do
    if not isLiveMobItem(item) then
      local name = tostring(item.name or "?")
      ids[name] = tostring(item.id)
      if not counts[name] then
        table.insert(order, name)
        counts[name] = 0
      end
      counts[name] = counts[name] + 1
    end
  end
  local entries = {}
  for _, name in ipairs(order) do
    table.insert(entries, { name = name, count = counts[name], id = ids[name] })
  end
  return entries
end

function room.playerNames()
  local names = {}
  for _, player in ipairs(room.players) do
    local display = type(player) == "table"
      and (player.name or player.fullname or player.id or player[1]) or player
    table.insert(names, tostring(display or "?"))
  end
  return names
end

local EXIT_ORDER = { "n", "ne", "e", "se", "s", "sw", "w", "nw", "u", "d", "in", "out" }

function room.sortedExits()
  local exits, seen, result = PkCore.room.exits, {}, {}
  for _, direction in ipairs(EXIT_ORDER) do
    if exits[direction] ~= nil then
      table.insert(result, direction)
      seen[direction] = true
    end
  end
  for direction in pairs(exits) do
    if not seen[direction] then table.insert(result, direction) end
  end
  return result
end

function room.isTargetPlayer()
  if not room.targetId then return false end
  for _, entry in ipairs(room.mobEntries()) do
    if tostring(entry.id) == room.targetId then return false end
  end
  return true
end

function room.isFlying()
  return type(room.name) == "string" and string.match(room.name, "^Flying above ") ~= nil
end

function room.targetName()
  if not room.targetId then return nil end
  for _, entry in ipairs(room.mobEntries()) do
    if tostring(entry.id) == room.targetId then return entry.name end
  end
  return room.targetDisplayName or room.targetId
end

function room.clearTarget()
  room.targetId = nil
  room.targetHpPercent = nil
  PkCore.stateChanged()
end

-- ── GMCP feed ────────────────────────────────────────────────────────────
-- JSON null arrives as truthy userdata, so only trust real strings and numbers.
local function text(v)
  local t = type(v)
  if t == "number" then return tostring(v) end
  if t == "string" and v ~= "" then return v end
  return nil
end

local function normalizePlayerName(player)
  if type(player) == "table" then
    player = player.name or player.fullname or player.id or player[1]
  end
  local s = string.gsub(text(player) or "", "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return string.lower(s)
end

local function ownPlayerName()
  return normalizePlayerName(PkCore.player.name or "")
end

local function findPlayerIndex(name)
  for index, player in ipairs(room.players) do
    if normalizePlayerName(player) == name then return index end
  end
  return nil
end

local function findItemIndex(id)
  id = tostring(id or "")
  if id == "" then return nil end
  for index, item in ipairs(room.items) do
    if tostring(item.id or "") == id then return index end
  end
  return nil
end

function room.refresh()
  room.players = {}
  requestRoomItems()
  if room.refreshTimer then clearTimeout(room.refreshTimer) end
  room.refreshTimer = setTimeout(function()
    room.refreshTimer = nil
    send("ql")
  end, 500)
end

-- Raw one-argument form: the package and its JSON payload in one string.
local function requestRoomItems()
  sendGMCP('Char.Items.Room ""')
end

function room.onInfo(info)
  if not info then return end
  room.exits = type(info.exits) == "table" and info.exits or {}
  room.name = text(info.name)
  if tostring(info.num or "") ~= tostring(room.number or "") then
    room.number = info.num
    room.players = {}
    local items = getGMCPData("Char.Items.List")
    if items and items.location == "room" then
      room.items = copyList(items.items)
    else
      room.items = {}
      requestRoomItems()
    end
  end
  PkCore.stateChanged()
end

function room.onItemsList(list)
  if not list or list.location ~= "room" then return end
  room.items = copyList(list.items)
  PkCore.stateChanged()
end

function room.onItemAdd(update)
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then room.items[index] = update.item
  else table.insert(room.items, update.item) end
  PkCore.stateChanged()
end

function room.onItemUpdate(update)
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then
    local existing = room.items[index]
    for key, value in pairs(update.item) do existing[key] = value end
  end
  PkCore.stateChanged()
end

function room.onItemRemove(update)
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then table.remove(room.items, index) end
  PkCore.stateChanged()
end

function room.onPlayers(data)
  if not data then return end
  if type(data) == "table" and type(data.players) == "table" then data = data.players end
  local players, me = {}, ownPlayerName()
  for _, player in ipairs(copyList(data)) do
    local name = normalizePlayerName(player)
    if name ~= "" and name ~= me then table.insert(players, player) end
  end
  room.players = players
  PkCore.stateChanged()
end

function room.onAddPlayer(update)
  if not update then return end
  local name = normalizePlayerName(update)
  if name == "" or name == ownPlayerName() then return end
  local index = findPlayerIndex(name)
  if index then room.players[index] = update
  else table.insert(room.players, update) end
  PkCore.stateChanged()
end

function room.onRemovePlayer(update)
  if not update then return end
  local name = normalizePlayerName(update)
  if name == "" then return end
  local index = findPlayerIndex(name)
  if index then table.remove(room.players, index) end
  PkCore.stateChanged()
end

function room.onTargetSet(id)
  local newId = text(id)
  if newId ~= room.targetId then
    room.targetDisplayName = nil   -- the old name would otherwise outlive the switch
  end
  room.targetId = newId
  if not newId then room.targetHpPercent = nil end
  PkCore.stateChanged()
end

-- Players come through with id/hpperc "-1"; keep the id Target.Set gave us.
function room.onTargetInfo(info)
  if type(info) ~= "table" then return end
  local id = text(info.id)
  if id and id ~= "-1" then room.targetId = id end
  room.targetDisplayName = text(info.name) or text(info.short_desc) or room.targetDisplayName
  local hp = tonumber(string.match(text(info.hpperc) or "", "^%-?%d+") or "")
  room.targetHpPercent = (hp and hp >= 0) and hp or nil
  PkCore.stateChanged()
end

onGMCPUpdate("Room.Info", room.onInfo)
onGMCPUpdate("Char.Items.List", room.onItemsList)
onGMCPUpdate("Char.Items.Add", room.onItemAdd)
onGMCPUpdate("Char.Items.Update", room.onItemUpdate)
onGMCPUpdate("Char.Items.Remove", room.onItemRemove)
onGMCPUpdate("Room.Players", room.onPlayers)
onGMCPUpdate("Room.AddPlayer", room.onAddPlayer)
onGMCPUpdate("Room.RemovePlayer", room.onRemovePlayer)
onGMCPUpdate("IRE.Target.Set", room.onTargetSet)
onGMCPUpdate("IRE.Target.Info", room.onTargetInfo)