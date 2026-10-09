PkCore.room = PkCore.room or { items = {}, players = {}, number = nil, name = nil, exits = {}, targetHpPercent = nil }

PkCore.registerKey = function(name, modifier, key, fn)
  if exists(name, "keybind") == 0 then
    permKey(name, "", modifier, key, fn)
  end
  enableKey(name)
end

local function isLiveMobItem(item)
  if type(item) ~= "table" then return false end
  local attrib = tostring(item.attrib or "")
  if not attrib:find("m", 1, true) then return false end
  if attrib:find("d", 1, true) then return false end
  if attrib:find("x", 1, true) then return false end
  local icon = tostring(item.icon or ""):lower()
  local name = tostring(item.name or ""):lower()
  return icon ~= "deadbody" and not name:find("corpse", 1, true)
end

function PkCore.room.mobEntries()
  local entries = {}
  for _, item in ipairs(PkCore.room.items) do
    if isLiveMobItem(item) then
      table.insert(entries, {name = tostring(item.name or "?"), id = item.id } )
    end
  end
  return entries
end

-- rolled up by name (e.g. 6 "a cube sigil" -> one entry, count=6)
function PkCore.room.itemEntries()
  local counts, order, ids = {}, {}, {}
  for _, item in ipairs(PkCore.room.items) do
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
    local idToUse = ""
    if counts[name] == 0 then
        idToUse = ids[name]
    end
    table.insert(entries, { name = name, count = counts[name], id = ids[name] })
  end
  return entries
end

function PkCore.room.playerNames()
  local names = {}
  for _, player in ipairs(PkCore.room.players) do
    local display = type(player) == "table"
      and (player.name or player.fullname or player.id or player[1]) or player
    table.insert(names, tostring(display or "?"))
  end
  return names
end

local EXIT_ORDER = { "n", "ne", "e", "se", "s", "sw", "w", "nw", "u", "d", "in", "out" }
function PkCore.room.sortedExits()
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

function PkCore.room.isTargetPlayer()
  if not PkCore.room.targetId then return false end
  for _, entry in ipairs(PkCore.room.mobEntries()) do
    if tostring(entry.id) == PkCore.room.targetId then
      return false
    end
  end
  return true
end


-- Tab Key Binding call
function PkCore.room.cycleTarget()
  local entries = PkCore.room.mobEntries()
  if #entries == 0 then
    PkCore.note("no mobs in room")
    return
  end
  local currentIndex = 0
  if PkCore.room.targetId then
    for i, entry in ipairs(entries) do
      if tostring(entry.id) == PkCore.room.targetId then
        currentIndex = i
        break
      end
    end
  end
  local nextIndex = (currentIndex % #entries) + 1
  send("st " .. tostring(entries[nextIndex].id))
end

function PkCore.room.targetName()
  if not PkCore.room.targetId then return nil end
  for _, entry in ipairs(PkCore.room.mobEntries()) do
    if tostring(entry.id) == PkCore.room.targetId then return entry.name end
  end
  if type(target) == "string" and target ~= "" then return target end
  return PkCore.room.targetId
end

-- ── GMCP feed ────────────────────────────────────────────────────────────
local function normalizePlayerName(player)
  if type(player) == "table" then
    player = player.name or player.fullname or player.id or player[1]
  end
  return tostring(player or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
end

local function ownPlayerName()
  local status = gmcp and gmcp.Char and gmcp.Char.Status
  return normalizePlayerName(status and status.name or "")
end

local function findPlayerIndex(name)
  for index, player in ipairs(PkCore.room.players) do
    if normalizePlayerName(player) == name then return index end
  end
  return nil
end

local function requestRoomItems()
  if type(sendGMCP) == "function" then
    sendGMCP([[Char.Items.Room ""]])
  end
end

local function findItemIndex(id)
  id = tostring(id or "")
  if id == "" then return nil end
  for index, item in ipairs(PkCore.room.items) do
    if tostring(item.id or "") == id then return index end
  end
  return nil
end

local function onRoomInfo()
  local info = gmcp and gmcp.Room and gmcp.Room.Info
  if not info then return end
  PkCore.room.exits = type(info.exits) == "table" and info.exits or {}
  PkCore.room.name = info.name
  if tostring(info.num or "") ~= tostring(PkCore.room.number or "") then
    PkCore.room.number = info.num
    PkCore.room.players = {}
    local items = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.List
    if items and items.location == "room" then
      PkCore.room.items = type(items.items) == "table" and items.items or {}
    else
      PkCore.room.items = {}
      requestRoomItems()
    end
  end
  PkCore.stateChanged()
end

local function onItemsList()
  local list = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.List
  if not list or list.location ~= "room" then return end
  PkCore.room.items = type(list.items) == "table" and list.items or {}
  PkCore.stateChanged()
end

local function onItemAdd()
  local update = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.Add
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then PkCore.room.items[index] = update.item
  else table.insert(PkCore.room.items, update.item) end
  PkCore.stateChanged()
end

local function onItemUpdate()
  local update = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.Update
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then
    local existing = PkCore.room.items[index]
    for key, value in pairs(update.item) do existing[key] = value end
  end
  PkCore.stateChanged()
end

local function onItemRemove()
  local update = gmcp and gmcp.Char and gmcp.Char.Items and gmcp.Char.Items.Remove
  if not update or update.location ~= "room" or type(update.item) ~= "table" then return end
  local index = findItemIndex(update.item.id)
  if index then table.remove(PkCore.room.items, index) end
  PkCore.stateChanged()
end

local function onRoomPlayers()
  local data = gmcp and gmcp.Room and gmcp.Room.Players
  if not data then return end
  if type(data) == "table" and type(data.players) == "table" then data = data.players end
  local players, me = {}, ownPlayerName()
  if type(data) == "table" then
    for _, player in pairs(data) do
      local name = normalizePlayerName(player)
      if name ~= "" and name ~= me then table.insert(players, player) end
    end
  end
  PkCore.room.players = players
  PkCore.stateChanged()
end

local function onRoomAddPlayer()
  local update = gmcp and gmcp.Room and gmcp.Room.AddPlayer
  if not update then return end
  local name = normalizePlayerName(update)
  if name == "" or name == ownPlayerName() then return end
  local index = findPlayerIndex(name)
  if index then PkCore.room.players[index] = update
  else table.insert(PkCore.room.players, update) end
  PkCore.stateChanged()
end

local function onRoomRemovePlayer()
  local update = gmcp and gmcp.Room and gmcp.Room.RemovePlayer
  if not update then return end
  local name = normalizePlayerName(update)
  if name == "" then return end
  local index = findPlayerIndex(name)
  if index then table.remove(PkCore.room.players, index) end
  PkCore.stateChanged()
end

local function onTargetSet()
  local id = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Set
  PkCore.room.targetId = (id ~= nil and id ~= "") and tostring(id) or nil
  if not PkCore.room.targetId then PkCore.room.targetHpPercent = nil end
  PkCore.stateChanged()
end

local function onTargetInfo()
  local info = gmcp and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
  if not info then return end
  local id = info.id and tostring(info.id) or nil
  if id then
    PkCore.room.targetId = id
  end
  PkCore.room.targetHpPercent = tonumber(tostring(info.hpperc or ""):match("%d+"))
  PkCore.stateChanged()
end

PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.Info", PkCore.protected("room.onRoomInfo", onRoomInfo)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Items.List", PkCore.protected("room.onItemsList", onItemsList)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Items.Add", PkCore.protected("room.onItemAdd", onItemAdd)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Items.Update", PkCore.protected("room.onItemUpdate", onItemUpdate)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Items.Remove", PkCore.protected("room.onItemRemove", onItemRemove)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.Players", PkCore.protected("room.onRoomPlayers", onRoomPlayers)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.AddPlayer", PkCore.protected("room.onRoomAddPlayer", onRoomAddPlayer)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.RemovePlayer", PkCore.protected("room.onRoomRemovePlayer", onRoomRemovePlayer)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.IRE.Target.Set", PkCore.protected("room.onTargetSet", onTargetSet)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.IRE.Target.Info", PkCore.protected("room.onTargetInfo", onTargetInfo)))

-- Key Binding
PkCore.registerKey("PkCore cycle target", mudlet.keymodifier.Alt, mudlet.key.Tab, [[PkCore.room.cycleTarget()]])