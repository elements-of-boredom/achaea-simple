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
    if R.sendSeq[ability.name] == seq then
      setReady(ability.name, true)
    end
  end)
  tempTimer(SAFETY_TIMEOUT, function()
    if R.sendSeq[ability.name] == seq then
      setReady(ability.name, true)
    end
  end)
end

-- Tier 1: authoritative list
PkCore.trackTrigger(tempRegexTrigger(
  "^Available abilities: (.+)\\.$",
  PkCore.protected("rage.onAvailableList", function()
    local classData = PkCore.classes.current()
    if not classData then return end
    local listed = {}
    for word in matches[2]:gmatch("[%w' ]+") do
      listed[word:gsub("^%s+", ""):gsub("%s+$", "")] = true
    end
    for _, ability in ipairs(classData.abilities) do
      setReady(ability.name, listed[ability.name] or false)
    end
  end))
)

-- Tier 2: per-ability specific recovery line (one trigger, built per ability at registration time)
local function registerAbilityTriggers(ability)
  if ability.success then
    PkCore.trackTrigger(tempRegexTrigger(ability.success,
      PkCore.protected("rage.success." .. ability.name, function()
        PkCore.note("rage: " .. ability.name .. " landed")
      end)))
  end
  if ability.recovery then -- e.g. "^Your " .. ability.name .. " ability could be used again\\.$"
    PkCore.trackTrigger(tempRegexTrigger(ability.recovery,
      PkCore.protected("rage.recovery." .. ability.name, function()
        setReady(ability.name, true)
      end)))
  end
end

function R.attemptUse()
  if PkCore.isHindered() then return end
  if getEpoch() - R.lastGlobalSend < GLOBAL_COOLDOWN then return end

  local classData = PkCore.classes.current()
  if not classData or not classData.auto then return end

  local targetPercent = PkCore.room.targetHpPercent
  local reserved = classData.rageReserve
  local reserving = reserved and targetPercent and targetPercent <= reserved.targetPercentAtOrBelow

  for _, index in ipairs(classData.auto) do
    local ability = classData.abilities[index]
    if ability.known and isReady(ability.name) and (ability.cost or 0) <= (PkCore.playerStatus.rage or 0) then
      if not reserving or ability.name == reserved.ability then
        send(ability.command)
        setReady(ability.name, false)
        R.lastGlobalSend = getEpoch()
        armFallback(ability, nextSendSeq(ability.name))
        return
      end
    end
  end
end

-- Register each classes Triggers
for _, classData in pairs(PkCore.classes) do
  if type(classData) == "table" and classData.abilities then
    for _, ability in ipairs(classData.abilities) do
      registerAbilityTriggers(ability)
    end
  end
end