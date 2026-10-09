PkCore.balance = PkCore.balance or { balance = nil, equilibrium = nil }
PkCore.vitals = PkCore.vitals or {}
PkCore.status = PkCore.status or { stunned = false }
PkCore.afflictions = PkCore.afflictions or { list = {} }
PkCore.afflictions.blocking = {
  prone = true,           
  transfixation = true,   
  paralysis = true,       
  webbed = true,
  entangled = true,
  bound = true,
  icebound = true,
  impaled = true,
  daeggerimpale = true,
  speared = true,
}
PkCore.afflictions.venomLock = { "paralysis", "impatience", "asthma", "anorexia", "slickness" }

function PkCore.isHindered()
  if PkCore.status.stunned then return true end
  if PkCore.afflictions.armsDamaged() then return true end
  for name in pairs(PkCore.afflictions.list) do
    if PkCore.afflictions.isBlocking(name) then return true end
  end
  return false
end

function PkCore.canAct()
  if PkCore.isHindered() then return false end
  return PkCore.balance.balance and PkCore.balance.equilibrium
end

function PkCore.afflictions.isBlocking(name)
  return PkCore.afflictions.blocking[name] == true
end

function PkCore.afflictions.armsDamaged()
  local left = PkCore.afflictions.list.brokenleftarm
            or PkCore.afflictions.list.damagedleftarm
            or PkCore.afflictions.list.mangledleftarm
  local right = PkCore.afflictions.list.brokenrightarm
             or PkCore.afflictions.list.damagedrightarm
             or PkCore.afflictions.list.mangledrightarm
  return left and right
end

function PkCore.afflictions.venomLockCount()
  local count = 0
  for _, name in ipairs(PkCore.afflictions.venomLock) do
    if PkCore.afflictions.has(name) then count = count + 1 end
  end
  return count
end

function PkCore.afflictions.isVenomLocked()
  return PkCore.afflictions.venomLockCount() == #PkCore.afflictions.venomLock
end

-- BALANCE HANDLING --
function PkCore.balance.has(name)
  return PkCore.balance[name] == true
end

function PkCore.balance.report()
  PkCore.note(string.format("balance=%s  equilibrium=%s stunned=%s",
    tostring(PkCore.balance.balance), tostring(PkCore.balance.equilibrium), tostring(PkCore.status.stunned)))
end


local function applyChange(name, value)
  if PkCore.balance[name] == value then return end
  PkCore.balance[name] = value
  raiseEvent(value and "PkCore balance gained" or "PkCore balance lost", name)
end

-- GMCP Char.Vitals also carries hp/mp/ep/wp on every tick, so bal/eq are
-- diffed against the last known value here to avoid spamming the event.
local function onVitals()
  local vitals = gmcp and gmcp.Char and gmcp.Char.Vitals
  if not vitals then return end
  applyChange("balance", vitals.bal == "1")
  applyChange("equilibrium", vitals.eq == "1")
  PkCore.vitals.hp, PkCore.vitals.maxhp = tonumber(vitals.hp), tonumber(vitals.maxhp)
  PkCore.vitals.mp, PkCore.vitals.maxmp = tonumber(vitals.mp), tonumber(vitals.maxmp)
  PkCore.vitals.ep, PkCore.vitals.maxep = tonumber(vitals.ep), tonumber(vitals.maxep)
  PkCore.vitals.wp, PkCore.vitals.maxwp = tonumber(vitals.wp), tonumber(vitals.maxwp)
end

-- STUN HANDLING --
local function onStunned()
  if PkCore.status.stunned then return end
  PkCore.status.stunned = true
  raiseEvent("PkCore action blocked", "stunned")
end

local function onUnstunned()
  PkCore.status.stunned = false
  raiseEvent("PkCore action unblocked", "stunned")
end

-- SELF AFFLICTION TRACKING --
local function parseAffliction(raw)
  local name, count = raw:match("^(%a+) %((%d+)%)$")
  if name then return name, tonumber(count) end
  return raw, nil
end

function PkCore.afflictions.has(name)
  return PkCore.afflictions.list[name] == true
end

local function onAfflictionsList()
  local data = gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.List
  if not data then return end
  PkCore.afflictions.list = {}
  for _, entry in ipairs(data) do
    local name, count = parseAffliction(entry.name)
    PkCore.afflictions.list[entry.name] = count or true
  end
  PkCore.stateChanged()
end

local function onAfflictionAdd()
  local entry = gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.Add
  if not entry or not entry.name then return end
  local name, count = parseAffliction(entry.name)
  if PkCore.config.values.affEchos then
    PkCore.cecho("(<red>+" .. entry.name:lower() .. "<reset>)\n")
  end
  PkCore.afflictions.list[name] = count or true
  PkCore.stateChanged()
end

local function onAfflictionRemove()
  local names = gmcp and gmcp.Char and gmcp.Char.Afflictions and gmcp.Char.Afflictions.Remove
  if not names then return end
  for _, raw in ipairs(names) do
    local name = parseAffliction(raw)
    if PkCore.config.values.affEchos then
      PkCore.cecho("(<green>-" .. name:lower() .. "<reset>)\n")
    end
    PkCore.afflictions.list[name] = nil
    if PkCore.afflictions.isBlocking(name) then
      raiseEvent("PkCore onBlockingAffliction removed", name)
    end
    PkCore.stateChanged()
  end
end

PkCore.trackTrigger(tempTrigger("You are too stunned to be able to do anything.", PkCore.protected("status.onStunned", onStunned)))
PkCore.trackTrigger(tempTrigger("You are no longer stunned.", PkCore.protected("status.onUnstunned", onUnstunned)))

PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Afflictions.List", PkCore.protected("afflictions.onList", onAfflictionsList)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Afflictions.Add", PkCore.protected("afflictions.onAdd", onAfflictionAdd)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Afflictions.Remove", PkCore.protected("afflictions.onRemove", onAfflictionRemove)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Vitals", PkCore.protected("balance.onVitals", onVitals)))

PkCore.registerAlias("PkCore balance check", [[^balcheck$]], [[PkCore.balance.report()]])
