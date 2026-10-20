PkCore.hunt_mode = PkCore.hunt_mode or {}
-- Denizen shields, keyed by lowercased short name ("a sturdy troll woman"). Names aren't
-- unique, but they're per room, so we forget everything when we move.
PkCore.hunt_mode.shielded = PkCore.hunt_mode.shielded or {}
PkCore.hunt_mode.staleAfter = PkCore.hunt_mode.staleAfter or 2.0
local lastQueueAt = 0

local function findTargetMob()
    if not PkCore.room.targetId then return nil end
    for _, entry in ipairs(PkCore.room.mobEntries()) do
        if tostring(entry.id) == PkCore.room.targetId then
            return entry
        end
    end
    return nil
end

local function clearStaleQueue()
    if PkCore.reactor.lastQueueSent == "" then return end
    local v = gmcp.Char and gmcp.Char.Vitals
    if not v or v.bal ~= "1" or v.eq ~= "1" then
        -- off balance: the queue is legitimately waiting, restart the grace period
        lastQueueAt = getEpoch()
        return
    end
    if getEpoch() - lastQueueAt >= PkCore.hunt_mode.staleAfter then
        PkCore.reactor.lastQueueSent = ""
    end
end

local function submitAttack(actions)
    local before = PkCore.reactor.lastQueueSent
    PkCore.reactor.submitQueue(actions)
    if PkCore.reactor.lastQueueSent ~= before then lastQueueAt = getEpoch() end
end

local function setShield(name, up)
    PkCore.hunt_mode.shielded[name:lower()] = up or nil
end
function PkCore.hunt_mode.isShielded(mob)
    return mob ~= nil and PkCore.hunt_mode.shielded[mob.name:lower()] == true
end

local function evaluate()
    if PkCore.reactor.mode ~= "hunt" then return end
    clearStaleQueue()
    local target = findTargetMob()
    if not target then
        --PkCore.note("hunt.lua - Target not in room")
        return
    end

    local classData = PkCore.classes.current()
    if not classData or not classData.basicAttack then
        PkCore.note("hunt.lua - No basic attack found for current class:".. classData.name)
        return
    end

    -- Rage is outside the queue, has no balance reqs
    local breaker = classData.shieldBreaker and PkCore.rage.find(classData, classData.shieldBreaker)
    if breaker and PkCore.hunt_mode.isShielded(target) then
        PkCore.rage.tryUse(breaker.name)
    else
        PkCore.rage.attemptUse()
    end

    if not PkCore.hunt_mode.isShielded(target) then
        submitAttack({classData.basicAttack})
    end
end
-- add this so we can leverage it from aliases
PkCore.hunt_mode.evaluate = evaluate

PkCore.trackTrigger(tempRegexTrigger(
    "^A nearly invisible magical shield forms around (.+)\\.$",
    PkCore.protected("hunt.shieldUp", function() 
        setShield(matches[2], true) 
        local target = findTargetMob()
        if PkCore.reactor.mode == "hunt" and target and target.name:lower() == matches[2]:lower() then
            send("cq all")
            PkCore.reactor.lastQueueSent = ""
        end
    end)))

PkCore.trackTrigger(tempRegexTrigger(
    "^The magical shield surrounding (.+) fades away\\.$",
    PkCore.protected("hunt.shieldDown", function() setShield(matches[2], false) end)))

-- our breaker landed: the shield's gone from whoever we're hitting
local seenBreakers = {}
for _, classData in pairs(PkCore.classes) do
    local breaker = type(classData) == "table" and classData.shieldBreaker
        and PkCore.rage.find(classData, classData.shieldBreaker)
    if breaker and breaker.success and breaker.success ~= "" and not seenBreakers[breaker] then
        seenBreakers[breaker] = true
        PkCore.trackTrigger(tempRegexTrigger(breaker.success,
            PkCore.protected("hunt.shieldBroken." .. breaker.name, function()
                local target = findTargetMob()
                if target then setShield(target.name, false) end
            end)))
    end
end

local lastRoom
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.Info",
    PkCore.protected("hunt.shieldRoomChange", function()
        local num = gmcp.Room.Info.num
        if num ~= lastRoom then
            lastRoom = num
            PkCore.hunt_mode.shielded = {}
        end
    end)))

PkCore.reactor.registerMode("hunt", { evaluate = evaluate })