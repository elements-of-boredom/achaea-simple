-- Prep a leg and the head. Prone and break leg, calcify head break head, 
-- then prone avalanche on balance. Guaranteed dead."
PkCore.rockboy = PkCore.rockboy or {}
local R = PkCore.rockboy

R.pendingQuake = R.pendingQuake or false
R.legBroken = R.legBroken or false
R.legKey = R.legKey or "rightleg"
R.headKey = "head"
R.damagePerHit = R.damagePerHit or 21

function R.resetTracking()
    R.legBroken = false
    R.pendingQuake = false
    PkCore.limbPrep.parryStreak = {}
    PkCore.limbPrep.lastAttemptedLimb = nil
end

local function prepLimbs()
    return {R.legKey, R.headKey}
end

local function liveTarget()
    return PkCore.room.targetName()
end

local function isEarthlord()
    local classData = PkCore.classes.current()
    return classData ~= nil and classData.name == "Earth Lord"
end

local function calcifyPending()
    return (affstrack.score.calcifiedskull or 0) > 0
end

local function targetProne()
    return (affstrack.score.prone or 0) > 0
end

local function currentDamagePerHit(upcomingSculptingReduction)
    local reduction = upcomingSculptingReduction or 0
    local shaping = (PkCore.playerStatus.shaping - reduction) or 0
    return shaping >= 4 and 43 or R.damagePerHit
end

local function kickEvaluateSoon()
    tempTimer(0, function()
        PkCore.reactor.evaluate()
    end)
end

local lastTargetName = nil
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed",
    PkCore.protected("rockboy.onTargetSwapCheck", function()
        local current = liveTarget() or ""
        local previous = lastTargetName or ""
        lastTargetName = current
        if current ~= "" and previous ~= "" and current ~= previous then
            R.resetTracking()
        end
    end)))
PkCore.trackTrigger(tempRegexTrigger("^You have slain ", PkCore.protected("rockboy.onTargetSlain", R.resetTracking)))

function R.powderise(key)
    local target = liveTarget()
    if not target then
        return
    end
    PkCore.limbPrep.recordAttempt(key)

    local prefix = ""
    local shaping = PkCore.playerStatus.shaping or 0
    if (PkCore.limbPrep.parryStreak[key] or 0) >= 1 and shaping >= 2 then
        R.pendingQuake = true 
    end
    if R.pendingQuakethen then
        prefix = "MANIFEST QUAKE|"
        R.pendingQuake = false
    end
    local word = (key == "rightleg" or key == "leftleg") and (key == "rightleg" and "right leg" or "left leg") or "head"
    send(prefix .. "TERRAN POWDERISE " .. target .. " " .. word)
end

function R.calcifyHead()
    local target = liveTarget()
    if not target then
        return
    end
    send("TERRAN CALCIFY " .. target .. " head")
    R.calcifyInFlight = true
    tempTimer(2, function() R.calcifyInFlight = false end)
end

function R.quake()
    send("MANIFEST QUAKE")
end

function R.avalanche(includeQuake)
    if includeQuake and PkCore.playerStatus.shaping >= 2 then
        send("MANIFEST QUAKE|MANIFEST AVALANCHE")
    end
    send("MANIFEST AVALANCHE")
end

local function evaluate()
    -- rockboy flow
    if PkCore.isHindered() then
        return
    end
    if not isEarthlord() then
        return
    end
    local target = liveTarget()
    if not target then
        return
    end

    local shaping = PkCore.playerStatus.shaping or 0

    if PkCore.limbPrep.broken(R.legKey) then
        R.legBroken = true
    end

    local headPrimed = PkCore.limbPrep.ready(R.headKey, currentDamagePerHit()) or PkCore.limbPrep.broken(R.headKey)
    local legPrimed = PkCore.limbPrep.ready(R.legKey, currentDamagePerHit()) or PkCore.limbPrep.broken(R.legKey)
     local chasingHead = calcifyPending() or R.calcifyInFlight or PkCore.limbPrep.broken(R.headKey)

    -- 1. Head is broken - finish
    if PkCore.limbPrep.broken(R.headKey) then
        if targetProne() and shaping >= 2 then
            R.avalanche()
        elseif not targetProne() and shaping >= 3 then
            R.avalanche(true)
        end
        return
    end

    -- 2. Calcify already pending - head should already be primed from step 4,
    -- so this powderise actually breaks it now instead of landing a wasted first hit
    if calcifyPending() then
        R.legBroken = false
        R.powderise(R.headKey)
        return
    end

    -- 3. Leg has broken (ever) and head is primed - calcify the head
    if (R.legBroken or chasingHead) and headPrimed and not R.calcifyInFlight then
        -- need to make sure if we are going to send calcify & powderise together we are truly primed
        -- as calcify will drop the limb damage
        if PkCore.limbPrep.ready(R.headKey, currentDamagePerHit(2)) then
            if shaping >= 4 then
                R.calcifyHead()
                R.powderise(R.headKey)
            else
                R.calcifyHead()
            end
        else 
            if shaping >= 2 then
                R.quake()
            end
            R.powderise(R.headKey)
        end
        return
    end

    -- 4. Both leg and head are primed, but leg isn't broken yet - break it
    if legPrimed and headPrimed and not R.legBroken and not chasingHead then 
        R.powderise(R.legKey)
        return
    end

    -- 5. Prep whichever of leg/head isn't primed yet
    local limb = PkCore.limbPrep.nextUnprepared(prepLimbs(), currentDamagePerHit()) or R.legKey
    R.powderise(limb)
end

PkCore.pk_mode.registerStrategy("rockboy", {
    evaluate = evaluate
})

PkCore.registerAlias("PkCore rockboy leg", [[^rockboy\s+leg\s+(rightleg|leftleg)$]],
    [[PkCore.rockboy.legKey = matches[2] ]])
PkCore.registerAlias("PkCore rockboy damageperhit", [[^rockboy\s+damageperhit\s+(\d+)$]],
    [[PkCore.rockboy.damagePerHit = tonumber(matches[2])]])
PkCore.registerAlias("PkCore rockboy reset", [[^rockboy\s+reset$]], [[PkCore.rockboy.resetTracking() ]])
PkCore.registerAlias("PkCore rockboy mmq", [[^mmq$]], [[PkCore.rockboy.pendingQuake = true]])
