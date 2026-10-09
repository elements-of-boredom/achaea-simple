PkCore.heartseed = PkCore.heartseed or {}
local H = PkCore.heartseed

local KILL_WINDOW = 12       -- Heartseed's timer
local SALVE_BALANCE = 4.0    -- Restoration salve balance duration

local LIMB_WORDS = {
  rightleg = "right leg", leftleg = "left leg",
  rightarm = "right arm", leftarm = "left arm",
  torso = "torso", head = "head",
}
local ARM_LEG_KEYS = { "rightleg", "leftleg", "rightarm", "leftarm" }
local WORD_TO_LIMB = {}
for key, word in pairs(LIMB_WORDS) do WORD_TO_LIMB[word] = key end


-- Config , TODO: wire into config maybe?
H.venom = H.venom or "prefarar"
H.prepLimbs = H.prepLimbs or { "rightleg" }
H.armsPlant = H.armsPlant or "Bloodroot"
H.salveBlocked = H.salveBlocked or false
H.damagePerHit = H.damagePerHit or 22

-- In-flight combat timing
H.active = false
H.startTime = nil
H.lastApply = nil -- { target = "legs"|"arms"|"body"|"torso"|"head", startTime, resolveTime }
H.torsoMildtrauma = false
H.pendingLimb = nil
H.consecutiveParries = 0
H.vinewreatheActive = false

local function liveTarget()
  return PkCore.room.targetName()
end

local function isSylvan()
  local classData = PkCore.classes.current()
  return classData ~= nil and classData.name == "Sylvan"
end

local function resetTracking()
  H.active = false
  H.startTime = nil
  H.lastApply = nil
  H.torsoMildtrauma = false
  H.pendingLimb = nil
  H.consecutiveParries = 0
  H.vinewreatheActive = false
  PkCore.stateChanged()
end
H.reset = resetTracking

local lastTargetName = nil
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed",
  PkCore.protected("heartseed.onTargetSwapCheck", function()
    local current = liveTarget() or ""
    local previous = lastTargetName or ""
    lastTargetName = current
    if current ~= "" and previous ~= "" and current ~= previous then
      resetTracking()
    end
  end))
)
PkCore.trackTrigger(tempRegexTrigger("^You have slain ", PkCore.protected("heartseed.onTargetSlain", resetTracking)))

local function onRestorationApply(kind)
  H.lastApply = { target = kind, startTime = getEpoch(), resolveTime = getEpoch() + SALVE_BALANCE }
  PkCore.note("heartseed: restoration applied to " .. kind)
  PkCore.stateChanged()
end


function H.setPrepLimbs(a, b)
  H.prepLimbs = { a }
  if b and b ~= "" then
    table.insert(H.prepLimbs, b)
  end
  PkCore.note("heartseed: prep limbs set to " .. table.concat(H.prepLimbs, ", "))
  PkCore.stateChanged()
end

function H.heartseedActive()
  if not H.active then return false end
  if getEpoch() > H.startTime + KILL_WINDOW then
    H.active = false
    return false
  end
  return true
end

local function applyActive(kinds)
  local apply = H.lastApply
  if not apply or getEpoch() >= apply.resolveTime then return false end
  for _, kind in ipairs(kinds) do
    if apply.target == kind then return true end
  end
  return false
end

local function limbRestorationActive() return applyActive({ "legs", "arms" }) end
local function bodyRestorationActive() return applyActive({ "body", "torso" }) end

-- Reads AK, then determines if next hit would put us over breakpoint
local function ready(key)
  local target = liveTarget()
  if not target then return false end
  local current = ak.limbs.limbcount[target] and ak.limbs.limbcount[target][key]
  if not current then return false end
  return current + H.damagePerHit >= 100
end

local function readyLimb()
  for _, key in ipairs(ARM_LEG_KEYS) do
    if ready(key) then return key end
  end
  return nil
end

local function broken(key)
  local threshold = (key == "torso" or key == "head") and 100 or 200
  return (affstrack.score[key] or 0) >= threshold
end

local function allPrepLimbsPrimed()
  for _, key in ipairs(H.prepLimbs) do
    if not (ready(key) or broken(key)) then
      return false
    end
  end
  return true
end

local function nextUnpreparedLimb()
  for _, key in ipairs(H.prepLimbs) do
    if not (ready(key) or broken(key)) then
      return key
    end
  end
  return nil
end

function H.explain()
  local lines = {
    "target: " .. tostring(liveTarget() or "none"),
    "venom: " .. tostring(H.venom),
    "arms plant: " .. tostring(H.armsPlant),
    "prep limbs: " .. table.concat(H.prepLimbs, ", "),
    "damage per hit: " .. tostring(H.damagePerHit),
    "salve blocked override: " .. tostring(H.salveBlocked),
    "torso ready: " .. tostring(ready("torso")),
    "torso broken: " .. tostring(broken("torso")),
    "torso mildtrauma: " .. tostring(H.torsoMildtrauma),
    "a limb ready: " .. tostring(readyLimb() or "none"),
    "limb restoration active: " .. tostring(limbRestorationActive()),
    "body restoration active: " .. tostring(bodyRestorationActive()),
    "heartseed active: " .. tostring(H.heartseedActive()),
    "vinewreathe active: " .. tostring(H.vinewreatheActive),
    "consecutive parries: " .. tostring(H.consecutiveParries),
  }
  PkCore.note("heartseed status:\n  " .. table.concat(lines, "\n  "))
end

function H.thornrend(key)
  local target = liveTarget()
  if not target then return end
  local word = LIMB_WORDS[key] or key
  H.pendingLimb = key
  local venom = ready(key) and "gecko" or H.venom
  local fullrend = "thornrend " .. target .. " " .. venom .. " " .. word .. " " .. H.armsPlant
  if key == "rightleg" or key == "leftleg" then
    fullrend = fullrend .. " | SWING QUARTERSTAFF ".. target
  end
  send(fullrend)
end

function H.castHeartseed()
  local target = liveTarget()
  if not target then return end
  send("HEARTSEED " .. target)
  H.active = true
  H.startTime = getEpoch()
  PkCore.note("heartseed: cast, kill window ~" .. KILL_WINDOW .. "s")
  PkCore.stateChanged()
end

function H.vinewreathe()
  local target = liveTarget()
  if not target then return end
  send("VINEWREATHE " .. target)
  H.vinewreatheActive = true
  -- Disable it after 15 seconds as a safety. --
  PkCore.trackTimer(tempTimer(15, function()
    H.vinewreatheActive = false
    PkCore.stateChanged()
  end))
end

local function evaluate()
  if PkCore.isHindered() then return end
  if not isSylvan() then return end
  local target = liveTarget()
  if not target then return end

  -- heartseed-specific decision logic goes here
  if H.consecutiveParries > 0 and not H.vinewreatheActive then
    PkCore.note("heartseed: getting parried - vinewreathe!")
    H.vinewreathe()
  end

  local torsoReady = ready("torso")
  local hsActive = H.heartseedActive()

  if hsActive and bodyRestorationActive() and torsoReady then
    PkCore.note("heartseed: steal restoration to torso!")
    H.thornrend("torso")
    return
  end

  if not torsoReady then
    H.thornrend("torso")
    return
  end

  if hsActive then
    PkCore.note("heartseed: active, torso is primed. Waiting for restoration apply!")
    return
  end

  if not allPrepLimbsPrimed() then
    local limb = nextUnpreparedLimb() or H.prepLimbs[1]
    PkCore.note("heartseed: prepping " .. (LIMB_WORDS[limb] or limb) .. " to bait a limb restoration")
    H.thornrend(limb)
    return
  end

  -- They are applying to their legs/arms and torso is prepped
  if limbRestorationActive() then
    H.castHeartseed()
    return
  end

  if H.torsoMildtrauma or H.salveBlocked then
    H.castHeartseed()
    return
  end

  local limbToBreak = readyLimb()
  if limbToBreak then
    H.thornrend(limbToBreak)
    return
  end

  PkCore.note("heartseed: waiting on opponent to apply a restoration")
end

----- AK OVERRIDES --------
-- Override AK's Viridianrend damage calc the server-reported percentage
-- instead of its hardcoded health-tier guess.
local lastRealViridianrendDamage = nil

PkCore.trackTrigger(tempRegexTrigger(
  "^As you carve into [\\w'\\-]+, you perceive that you have dealt ([\\d.]+)% damage to \\w+ (.+)\\.$",
  PkCore.protected("heartseed.onViridianrendDamage", function()
    lastRealViridianrendDamage = tonumber(matches[2])
    H.consecutiveParries = 0
    PkCore.stateChanged()
  end)))

local function realLimbDamage(who, attacker, weapon, limb, augment, check)
  local damage = lastRealViridianrendDamage or 22
  lastRealViridianrendDamage = nil -- consume once, force it to be reset each time, prolly not needed....
  return damage
end
-- Queue up for onready so we don't error on cold start -- 
PkCore.onReady(function()
  ak.limbs.myformulas = ak.limbs.myformulas or {}
  ak.limbs.myformulas.viridianrend = realLimbDamage
  ak.limbs.myformulas.wreathed = realLimbDamage
end)

--- REGISTRATIONS ----

PkCore.pk_mode.registerStrategy("heartseed", { evaluate = evaluate })

PkCore.registerAlias("PkCore heartseed venom", [[^heartseed\s+venom\s+(\S+)$]], [[PkCore.heartseed.venom = matches[2] ]])
PkCore.registerAlias("PkCore heartseed limb", [[^heartseed\s+limb\s+(rightarm|leftarm|rightleg|leftleg)(?:\s+(rightarm|leftarm|rightleg|leftleg))?$]], [[PkCore.heartseed.setPrepLimbs(matches[2], matches[3])]])
PkCore.registerAlias("PkCore heartseed arms", [[^heartseed\s+arms\s+(\S+)$]], [[PkCore.heartseed.armsPlant = matches[2] ]])
PkCore.registerAlias("PkCore heartseed salveblocked", [[^heartseed\s+salveblocked\s+(on|off)$]], [[PkCore.heartseed.salveBlocked = (matches[2] == "on")]])
PkCore.registerAlias("PkCore heartseed damageperhit", [[^heartseed\s+damageperhit\s+(\d+)$]], [[PkCore.heartseed.damagePerHit = tonumber(matches[2])]])
PkCore.registerAlias("PkCore heartseed status", [[^heartseed\s+(?:status|why)$]], [[PkCore.heartseed.explain()]])
PkCore.registerAlias("PkCore heartseed reset", [[^heartseed\s+reset$]], [[PkCore.heartseed.reset()]])

-- Triggers --
-- Parry tracking --
PkCore.trackTrigger(tempRegexTrigger(
  "^(\\w+) parries the attack with a deft manoeuvre\\.$",
  PkCore.protected("heartseed.onParry", function()
    local tgt = liveTarget()
    if tgt and matches[2] == tgt then
      H.consecutiveParries = H.consecutiveParries + 1
      PkCore.stateChanged()
    end
  end))
)
-- vinewreathe down -- 
PkCore.trackTrigger(tempRegexTrigger(
  "^The vines flailing about (\\w+)'s form recede\\.$",
  PkCore.protected("heartseed.onVinewreatheExpired", function()
    local tgt = liveTarget()
    if tgt and matches[2] == tgt then
      H.vinewreatheActive = false
      PkCore.stateChanged()
    end
  end))
)

-- Restoration tracking
-- legs/arms restoration applied --
PkCore.trackTrigger(tempRegexTrigger(
  "^(\\w+) takes some salve from a vial and rubs it on (?:his|her|their) (legs|arms)\\.$",
  PkCore.protected("heartseed.onLimbRestoration", function()
    local tgt = liveTarget()
    if tgt and matches[2] == tgt then
      onRestorationApply(matches[3])
    end
  end)))

-- body/torso restoration applied --
PkCore.trackTrigger(tempRegexTrigger(
  "^(\\w+) takes some salve from a vial and rubs it on (?:his|her|their) body\\.$",
  PkCore.protected("heartseed.onBodyRestoration", function()
    local tgt = liveTarget()
    if tgt and matches[2] == tgt then
      onRestorationApply("body")
    end
  end)))