PkCore.afflictions = PkCore.afflictions or {}
local afflictions = PkCore.afflictions
afflictions.list = afflictions.list or {}   -- name -> true, or its count

afflictions.blocking = {
  prone = true, transfixation = true, paralysis = true, webbed = true, entangled = true,
  bound = true, icebound = true, impaled = true, daeggerimpale = true, speared = true,
}
afflictions.venomLock = { "paralysis", "impatience", "asthma", "anorexia", "slickness" }

local function nameOf(raw)
  return string.match(raw, "^(%a+) %(%d+%)$") or raw
end

local function countOf(raw)
  local n = string.match(raw, "^%a+ %((%d+)%)$")
  return n and tonumber(n) or nil
end

function afflictions.has(name)
  return afflictions.list[name] ~= nil
end

function afflictions.isBlocking(name)
  return afflictions.blocking[name] == true
end

function afflictions.armsDamaged()
  local l = afflictions.list
  local left = l.brokenleftarm or l.damagedleftarm or l.mangledleftarm
  local right = l.brokenrightarm or l.damagedrightarm or l.mangledrightarm
  return left and right
end

function afflictions.venomLockCount()
  local count = 0
  for _, name in ipairs(afflictions.venomLock) do
    if afflictions.has(name) then count = count + 1 end
  end
  return count
end

function afflictions.isVenomLocked()
  return afflictions.venomLockCount() == #afflictions.venomLock
end

local function echoChange(text)
  local config = PkCore.config
  if config.values.affEchos then cecho(text) end
end

function afflictions.onList(data)
  if type(data) ~= "table" then return end
  afflictions.list = {}
  for _, entry in ipairs(data) do
    local raw = type(entry) == "table" and entry.name
    if type(raw) == "string" then afflictions.list[nameOf(raw)] = countOf(raw) or true end
  end
  PkCore.stateChanged()
end

function afflictions.onAdd(entry)
  if type(entry) ~= "table" or type(entry.name) ~= "string" then return end
  echoChange("(<red>+" .. string.lower(entry.name) .. "<reset>)")
  afflictions.list[nameOf(entry.name)] = countOf(entry.name) or true
  PkCore.stateChanged()
end

function afflictions.onRemove(names)
  if type(names) ~= "table" then return end
  for _, raw in ipairs(names) do
    if type(raw) == "string" then
      local name = nameOf(raw)
      echoChange("(<green>-" .. string.lower(name) .. "<reset>)")
      afflictions.list[name] = nil
      if afflictions.isBlocking(name) then raiseEvent("PkCore onBlockingAffliction removed", name) end
    end
  end
  PkCore.stateChanged()
end

onGMCPUpdate("Char.Afflictions.List", afflictions.onList)
onGMCPUpdate("Char.Afflictions.Add", afflictions.onAdd)
onGMCPUpdate("Char.Afflictions.Remove", afflictions.onRemove)