PkCore.rage = PkCore.rage or {}
local R = PkCore.rage

local GLOBAL_COOLDOWN = 1.0
local SAFETY_TIMEOUT = 45

R.cooldownReady = R.cooldownReady or {}   -- [abilityName] = true/false
R.sendSeq = R.sendSeq or {}               -- [abilityName] = number
R.lastGlobalSend = R.lastGlobalSend or 0

local function nextSendSeq(name)
  R.sendSeq[name] = (R.sendSeq[name] or 0) + 1
  return R.sendSeq[name]
end

local function setReady(name, ready)
  R.cooldownReady[name] = ready
end

local function isReady(name)
  if R.cooldownReady[name] == nil then return true end -- unknown = assume ready until proven otherwise
  return R.cooldownReady[name]
end

local function armFallback(ability, seq)
  tempTimer(ability.cooldown or SAFETY_TIMEOUT, function()
    if R.sendSeq[ability.name] == seq then setReady(ability.name, true) end
  end)
  tempTimer(SAFETY_TIMEOUT, function()
    if R.sendSeq[ability.name] == seq then setReady(ability.name, true) end
  end)
end

local function canSend()
  if PkCore.isHindered() then return false end
  return PkCore.now() - R.lastGlobalSend >= GLOBAL_COOLDOWN
end

local function canUse(ability)
  return ability.known and isReady(ability.name) and (ability.cost or 0) <= (PkCore.playerStatus.rage or 0)
end

local function useAbility(ability)
  send(ability.command)
  setReady(ability.name, false)
  R.lastGlobalSend = PkCore.now()
  armFallback(ability, nextSendSeq(ability.name))
end

-- fire one specific ability (e.g. the class shield breaker) if it's usable right now
function R.tryUse(name)
  if not canSend() then return false end
  local ability = R.find(PkCore.classes.current(), name)
  if not ability or not canUse(ability) then return false end
  useAbility(ability)
  return true
end

function R.attemptUse()
  if not canSend() then return end
  local classData = PkCore.classes.current()
  if not classData or not classData.auto then return end

  local targetPercent = PkCore.room.targetHpPercent
  local reserved = classData.rageReserve
  local reserving = reserved and targetPercent and targetPercent <= reserved.targetPercentAtOrBelow

  for _, index in ipairs(classData.auto) do
    local ability = classData.abilities[index]
    if canUse(ability) and (not reserving or ability.name == reserved.ability) then
      useAbility(ability)
      return
    end
  end
end

function R.find(classData, name)
  for _, ability in ipairs(classData and classData.abilities or {}) do
    if ability.name == name then return ability end
  end
end

-- Tier 1: authoritative list
tempRegexTrigger([[^Available abilities: (.+)\.$]], function(_, _, w)
  local classData = PkCore.classes.current()
  if not classData then return end
  local listed = {}
  for word in w[1]:gmatch("[%w' ]+") do
    listed[(word:gsub("^%s+", ""):gsub("%s+$", ""))] = true
  end
  for _, ability in ipairs(classData.abilities) do
    setReady(ability.name, listed[ability.name] or false)
  end
end)

-- Tier 2: per-ability success / recovery lines, built from the class data
local seenClasses = {}
for _, classData in pairs(PkCore.classes) do
  if type(classData) == "table" and classData.abilities and not seenClasses[classData] then
    seenClasses[classData] = true
    for _, ability in ipairs(classData.abilities) do
      if ability.success and ability.success ~= "" then
        tempRegexTrigger(ability.success, function() PkCore.note("rage: " .. ability.name .. " landed") end)
      end
      if ability.recovery and ability.recovery ~= "" then
        tempRegexTrigger(ability.recovery, function() setReady(ability.name, true) end)
      end
    end
  end
end