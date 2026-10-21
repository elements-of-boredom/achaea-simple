PkCore.room = PkCore.room or {}
PkCore.room.exits = PkCore.room.exits or {}

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

function PkCore.room.onInfo(info)
  if not info then return end
  PkCore.room.exits = type(info.exits) == "table" and info.exits or {}
  PkCore.room.name = info.name
  PkCore.room.number = info.num
  PkCore.stateChanged()
end


onGMCPUpdate("Room.Info", PkCore.room.onInfo)