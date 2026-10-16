PkCore.rockboyfork = PkCore.rockboyfork or {}
local F = PkCore.rockboyfork

F.legKey = F.legKey or "leftleg"
F.headKey = "head"
F.torsoKey = "torso"
F.damagePerHit = F.damagePerHit or 21
F.legBroken = F.legBroken or false
F.calcifyInFlight = F.calcifyInFlight or {}
F.pendingQuake = false

function F.resetTracking()
    F.legBroken = false
    F.calcifyInFlight = {}
    F.pendingQuake = false
    PkCore.limbPrep.parryStreak = {}
    PkCore.limbPrep.lastAttemptedLimb = nil
end

local function prepLimbs() return {F.legKey, F.headKey, F.torsoKey} end
local function liveTarget() return PkCore.room.targetName() end
local function isEarthlord()
    local classData = PkCore.classes.current()
    return classData ~= nil and classData.name == "Earth Lord"
end
local function calcifyPending(limb)
    local aff = limb == "head" and "calcifiedskull" or "calcifiedtorso"
    return (affstrack.score[aff] or 0) > 0
end
local function targetProne() return (affstrack.score.prone or 0) > 0 end
local function headMangled() return (affstrack.score.mangledhead or 0) > 0 end
local function headDamaged() return (affstrack.score.damagedhead or 0) > 0 end
local function torsoSerious() return (affstrack.score.serioustrauma or 0) > 0 end
local function torsoMild() return (affstrack.score.mildtrauma or 0) > 0 end
local function kickEvaluateSoon() tempTimer(0, function() PkCore.reactor.evaluate() end) end
local function currentDamagePerHit(upcomingSculptingReduction)
    local reduction = upcomingSculptingReduction or 0
    local shaping = (PkCore.playerStatus.shaping - reduction) or 0
    return shaping >= 4 and 43 or F.damagePerHit
end

local lastTargetName = nil
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed",
    PkCore.protected("rockboyfork.onTargetSwapCheck", function()
        local current = liveTarget() or ""
        local previous = lastTargetName or ""
        lastTargetName = current
        if current ~= "" and previous ~= "" and current ~= previous then
            F.resetTracking()
        end
    end)))
PkCore.trackTrigger(tempRegexTrigger("^You have slain ", PkCore.protected("rockboyfork.onTargetSlain", F.resetTracking)))

function F.powderise(key)
    local target = liveTarget()
    if not target then return end
    local word = (key == "rightleg" or key == "leftleg") and (key == "rightleg" and "right leg" or "left leg")
        or (key == "torso" and "torso" or "head")
    PkCore.limbPrep.recordAttempt(key)

    local shaping = PkCore.playerStatus.shaping or 0
    if (PkCore.limbPrep.parryStreak[key] or 0) >= 1 and shaping >= 2 then
        F.pendingQuake = true
    end
    
    local prefix = ""
    if F.pendingQuake then
        prefix = "MANIFEST QUAKE|"
        F.pendingQuake = false
    end
    send(prefix .. "TERRAN POWDERISE " .. target .. " " .. word)
end

function F.calcify(limb)
    local target = liveTarget()
    if not target then return end
    send("TERRAN CALCIFY " .. target .. " " .. limb)
    F.calcifyInFlight[limb] = true
    tempTimer(4, function() F.calcifyInFlight[limb] = false end)
end

function F.quake() send("MANIFEST QUAKE") end
function F.avalanche() send("MANIFEST AVALANCHE") end
function F.squeeze()
    local target = liveTarget()
    if not target then return end
    send("TERRAN SQUEEZE " .. target)
end
function F.crunch()
    send("TERRAN CRUNCH " .. target)
end

local function evaluate()
    if not PkCore.canAct() then return end
    if not isEarthlord() then return end
    local target = liveTarget()
    if not target then return end

    local shaping = PkCore.playerStatus.shaping or 0

    if PkCore.limbPrep.broken(F.legKey) then F.legBroken = true end

    local headPrimed = PkCore.limbPrep.ready(F.headKey, currentDamagePerHit()) or PkCore.limbPrep.broken(F.headKey)
    local torsoPrimed = PkCore.limbPrep.ready(F.torsoKey, currentDamagePerHit()) or PkCore.limbPrep.broken(F.torsoKey)
    local legPrimed = PkCore.limbPrep.ready(F.legKey, currentDamagePerHit()) or PkCore.limbPrep.broken(F.legKey)

    -- We've send a calcify, reset the broken leg state.
    if calcifyPending("head") or calcifyPending("torso") then F.legBroken = false end
    local chasingHeadOrTorso = calcifyPending("head") or calcifyPending("torso")
        or F.calcifyInFlight.head or F.calcifyInFlight.torso
        or headDamaged() or torsoMild()
    -- Head is mangled with calcify still pending. Technically we are done
    -- but lots could still happen.
    if headDamaged() and calcifyPending("head") then
        PkCore.note("Rockboy: HEAD DAMAGED, CALCIFY RUNNING - escalating to mangled")
        if targetProne() and shaping >= 2 then
            F.avalanche()
            return
        elseif not targetProne() and shaping >= 3 then
            F.quake()
            F.avalanche()
            return
        elseif shaping < 4 then
            F.crunch()
            return
        end
        return
    end

    -- Torso is serious with calcify still pending - Squeeze for the kill
    if torsoSerious() and calcifyPending("torso") then
        PkCore.note("Rockboy: TORSO MANGLED, CALCIFY RUNNING! MAYBE ABOUT TO GET YOUR SQUUUUEEEZE!!")
        F.squeeze()
        return
    end

    -- Torso is still mild (not yet serious) with calcify pending, and is
    -- ready for another hit - keep hitting it (covers the case where Avalanche's boosted hit wasn't enough on its own to cross 200)
    if torsoMild() and calcifyPending("torso") and PkCore.limbPrep.ready(F.torsoKey, currentDamagePerHit()) then
        F.powderise(F.torsoKey)
        return
    end

    -- Leg broken, head and torso both primed, neither calcified yet, calcify head first (free at 4 Shaping), 
    -- then torso (costs balance Shaping has dropped), then break each once to get to first tier
    if (F.legBroken or chasingHeadOrTorso) and headPrimed and torsoPrimed then
        if not calcifyPending("head") and not F.calcifyInFlight.head then
            F.calcify("head")
            kickEvaluateSoon()
        elseif not calcifyPending("torso") and not F.calcifyInFlight.torso then
            F.calcify("torso")
        elseif not headDamaged() and PkCore.limbPrep.ready(F.headKey, currentDamagePerHit()) then
            F.powderise(F.headKey)
        elseif not torsoMild() and PkCore.limbPrep.ready(F.torsoKey, currentDamagePerHit()) then
            F.powderise(F.torsoKey)
        else
            -- not sure we should do this, its a weird fall through
            if shaping < 4 then
                PkCore.note("RB: Crunch for Shape charges")
                F.crunch()
            end
        end
        return
    end

    -- Leg is ready to break
    if legPrimed and headPrimed and torsoPrimed and not F.legBroken and not chasingHeadOrTorso then
        F.powderise(F.legKey)
        return
    end

    -- Prep whichever of the three isn't primed yet
    -- TODO : We need parry tracking... 
    local limb = PkCore.limbPrep.nextUnprepared(prepLimbs(), currentDamagePerHit()) or F.legKey
    F.powderise(limb)
end

PkCore.pk_mode.registerStrategy("rockboyfork", { evaluate = evaluate })

PkCore.registerAlias("PkCore rockboyfork leg", [[^rockboyfork\s+leg\s+(rightleg|leftleg)$]],
    [[PkCore.rockboyfork.legKey = matches[2] ]])
PkCore.registerAlias("PkCore rockboyfork damageperhit", [[^rockboyfork\s+damageperhit\s+(\d+)$]],
    [[PkCore.rockboyfork.damagePerHit = tonumber(matches[2])]])
PkCore.registerAlias("PkCore rockboyfork reset", [[^rockboyfork\s+reset$]], [[PkCore.rockboyfork.resetTracking() ]])
PkCore.registerAlias("PkCore rockboyfork mmq", [[^mmq$]], [[PkCore.rockboyfork.pendingQuake = true]])