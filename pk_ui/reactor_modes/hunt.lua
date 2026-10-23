PkCore.hunt_mode = PkCore.hunt_mode or {}
local hunt = PkCore.hunt_mode
-- Denizen shields, keyed by lowercased short name ("a sturdy troll woman"). Names aren't
-- unique, but they're per room, so we forget everything when we move.
hunt.shielded = hunt.shielded or {}
hunt.staleAfter = hunt.staleAfter or 2.0
local lastQueueAt = 0
local lastRoom

local function findTargetMob()
  if not PkCore.room.targetId then return nil end
  for _, entry in ipairs(PkCore.room.mobEntries()) do
    if tostring(entry.id) == PkCore.room.targetId then return entry end
  end
  return nil
end

-- Bal and eq both up but the queue still hasn't fired: after staleAfter, allow a resend.
local function clearStaleQueue()
  if PkCore.reactor.lastQueueSent == "" then return end
  if not (PkCore.balance.balance and PkCore.balance.equilibrium) then
    lastQueueAt = PkCore.now() -- off balance: the queue is legitimately waiting
    return
  end
  if PkCore.now() - lastQueueAt >= hunt.staleAfter then PkCore.reactor.queueConsumed() end
end

local function submitAttack(actions)
  local before = PkCore.reactor.lastQueueSent
  PkCore.reactor.submitQueue(actions)
  if PkCore.reactor.lastQueueSent ~= before then lastQueueAt = PkCore.now() end
end

local function setShield(name, up)
  hunt.shielded[name:lower()] = up or nil
end

function hunt.isShielded(mob)
  return mob ~= nil and hunt.shielded[mob.name:lower()] == true
end

local function evaluateHunt()
  if PkCore.reactor.mode ~= "hunt" then return end
  clearStaleQueue()
  local target = findTargetMob()
  if not target then return end

  local classData = PkCore.classes.current()
  if not classData or not classData.basicAttack then
    PkCore.note("hunt: no basic attack for class " .. tostring(PkCore.player.class))
    PkCore.reactor.set("off")
    return
  end

  -- Rage is outside the queue, has no balance reqs
  local breaker = classData.shieldBreaker and PkCore.rage.find(classData, classData.shieldBreaker)
  if breaker and hunt.isShielded(target) then
    PkCore.rage.tryUse(breaker.name)
  else
    PkCore.rage.attemptUse()
  end

  if not hunt.isShielded(target) then
    submitAttack({ classData.basicAttack })
  end
end
hunt.evaluate = evaluateHunt

-- Shield tracking
tempRegexTrigger([[^A nearly invisible magical shield forms around (.+)\.$]], function(_, _, w)
  setShield(w[1], true)
  local target = findTargetMob()
  if PkCore.reactor.mode == "hunt" and target and target.name:lower() == w[1]:lower() then
    send("cq all")
    PkCore.reactor.queueConsumed()
  end
end)
tempRegexTrigger([[^The magical shield surrounding (.+) fades away\.$]], function(_, _, w)
  setShield(w[1], false)
end)
-- our breaker landed: the shield's gone from whoever we're hitting
local seenBreakers = {}
for _, classData in pairs(PkCore.classes) do
  local breaker = type(classData) == "table" and classData.shieldBreaker
    and PkCore.rage.find(classData, classData.shieldBreaker)
  if breaker and breaker.success and breaker.success ~= "" and not seenBreakers[breaker] then
    seenBreakers[breaker] = true
    tempRegexTrigger(breaker.success, function()
      local target = findTargetMob()
      if target then setShield(target.name, false) end
    end)
  end
end
-- New room: clear shields.
PkCore.onStateChanged("hunt.room", function()
  local num = tostring(PkCore.room.number or "")
  if num ~= lastRoom then
    lastRoom = num
    hunt.shielded = {}
  end
end)

PkCore.reactor.registerMode("hunt", { evaluate = evaluateHunt })