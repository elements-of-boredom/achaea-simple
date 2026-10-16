-- Prep a leg and the head. Prone and break leg, calcify head break head, 
-- then prone avalanche on balance. Guaranteed dead.. Their only block is standing and shielding 
-- to block the avalanche hit.

-- 2nd route option is squeeze , usually two legs and torso prepped, 
-- break both legs, powderise/calcify torso. to put into mild, then serious crunch to get back to 4 shaping
-- and calcify/squeeze for instant kill. 
PkCore.rockboy = PkCore.rockboy or {}
local R = PkCore.rockboy

R.pendingQuake = R.pendingQuake or false
R.legBroken = R.legBroken or false
R.legKey = R.legKey or "rightleg"
R.headKey = "head"
R.damagePerHit = R.damagePerHit or 21
R.calcifyInFlight = R.calcifyInFlight or false
R.routeChoice = R.routeChoice or "headonly"
R.missedRouteWarned = R.missedRouteWarned or false
R.calcifyCommitted = R.calcifyCommitted or false

function R.resetTracking()
    R.legBroken = false
    R.pendingQuake = false
    R.calcifyInFlight = false
    R.missedRouteWarned = false
    R.calcifyCommitted = false
    PkCore.limbPrep.parryStreak = {}
    PkCore.limbPrep.lastAttemptedLimb = nil
end

local function prepLimbs() return {R.legKey, R.headKey} end
local function liveTarget() return PkCore.room.targetName() end
local function isEarthlord()
    local classData = PkCore.classes.current()
    return classData ~= nil and classData.name == "Earth Lord"
end
local function calcifyPending() return (affstrack.score.calcifiedskull or 0) > 0 end
local function targetProne() return (affstrack.score.prone or 0) > 0 end
local function currentShaping() return PkCore.playerStatus.shaping or 0 end
local function currentDamagePerHit(upcomingSculptingReduction)
    local reduction = upcomingSculptingReduction or 0
    local shaping = currentShaping() - reduction
    return shaping >= 4 and 43 or R.damagePerHit
end
local function headPrimed() return PkCore.limbPrep.ready(R.headKey, currentDamagePerHit()) or PkCore.limbPrep.broken(R.headKey) end
local function legPrimed() return PkCore.limbPrep.ready(R.legKey, currentDamagePerHit()) or PkCore.limbPrep.broken(R.legKey) end
local function headSafeForCombo() return PkCore.limbPrep.ready(R.headKey, currentDamagePerHit(2)) end
local function chasingHead() return calcifyPending() or R.calcifyInFlight or PkCore.limbPrep.broken(R.headKey) end

-- Mirrors exactly what powderiseCmd below decides, so we can predict the
-- shaping outcome of a Powderise BEFORE sending it
local function willPrefixQuake(key)
    if targetProne() then return R.pendingQuake end
    return R.pendingQuake or ((PkCore.limbPrep.parryStreak[key] or 0) >= 1 and currentShaping() >= 2)
end

local function powderiseCmd(key)
    local target = liveTarget()
    if not target then return nil end
    PkCore.limbPrep.recordAttempt(key)

    local word = (key == "rightleg" or key == "leftleg") and (key == "rightleg" and "right leg" or "left leg") or "head"
    local cmd = "TERRAN POWDERISE " .. target .. " " .. word

    if willPrefixQuake(key) then
        cmd = "MANIFEST QUAKE|" .. cmd
        R.pendingQuake = false
    end
    return cmd
end

local function calcifyHeadCmd()
    local target = liveTarget()
    if not target then return nil end
    R.calcifyInFlight = true
    tempTimer(4, function() R.calcifyInFlight = false end)
    return "TERRAN CALCIFY " .. target .. " head"
end

local function crunchCmd()
    local target = liveTarget()
    return target and ("TERRAN CRUNCH " .. target) or nil
end

-- ACTIONS: all things rockboy can do
local ACTIONS = {
    finish_quake_avalanche = {
        -- default/preferred finish whenever affordable - always re-prone via
        -- Quake rather than trusting our own prone-tracking isn't stale
        can = function() return R.calcifyCommitted and PkCore.limbPrep.broken(R.headKey) and currentShaping() >= 3 end,
        build = function() return "MANIFEST QUAKE|MANIFEST AVALANCHE" end,
    },
    finish_avalanche_fallback = {
        -- shaping fell to exactly 2 (e.g. the combo's hit got quake-prefixed
        -- for parry) - can't afford Quake first, only works if still prone
        can = function() return R.calcifyCommitted and PkCore.limbPrep.broken(R.headKey) and currentShaping() == 2 and targetProne() end,
        build = function() return "MANIFEST AVALANCHE" end,
    },
    finish_missed_route = {
        can = function() return PkCore.limbPrep.broken(R.headKey) and not R.missedRouteWarned end,
        build = function()
            PkCore.note("!!! ROCKBOY: MISSED KILL ROUTE !!!")
            PkCore.note("!!! Target not prone / shaping too low to finish - likely a skilled cure !!!")
            PkCore.note("!!! Consider: rbr <name> to pivot to something more robust !!!")
            R.missedRouteWarned = true
            R.legBroken = false
            return nil
        end,
    },
    ramp_head_while_calcifying = {
        can = function() return calcifyPending() end,
        build = function()
            R.legBroken = false
            return powderiseCmd(R.headKey)
        end,
    },
    calcify_and_hit_head = {
        can = function()
            return (R.legBroken or chasingHead()) and currentShaping() >= 4 and headSafeForCombo()
        end,
        build = function()
            R.missedRouteWarned = false
            R.calcifyCommitted = true
            local calcifyCmd = calcifyHeadCmd()
            local hitCmd = powderiseCmd(R.headKey)
            if calcifyCmd and hitCmd then return calcifyCmd .. "|" .. hitCmd end
            return calcifyCmd or hitCmd
        end,
    },
    ramp_head_for_combo = {
        -- unconditional priority on head unt
        can = function() return not headSafeForCombo() end,
        build = function() return powderiseCmd(R.headKey) end,
    },
    build_shaping_for_break = {
        can = function()
            if not legPrimed() or not headSafeForCombo() then return false end
            local needed = willPrefixQuake(R.legKey) and 4 or 3
            return currentShaping() < needed
        end,
        build = function() return crunchCmd() end,
    },
    break_leg = {
        can = function()
            if not legPrimed() or not headSafeForCombo() or R.legBroken or chasingHead() then return false end
            local needed = willPrefixQuake(R.legKey) and 4 or 3
            return currentShaping() >= needed
        end,
        build = function() return powderiseCmd(R.legKey) end,
    },
    prep = {
        can = function() return true end,
        build = function() return powderiseCmd(R.legKey) end,
    },
}

local ROUTES = {
    headonly = {
        "finish_quake_avalanche",
        "finish_avalanche_fallback",
        "finish_missed_route",
        "ramp_head_while_calcifying",
        "calcify_and_hit_head",
        "ramp_head_for_combo",
        "build_shaping_for_break",
        "break_leg",
        "prep",
    },
}

local function pickAction(routeList)
    for _, name in ipairs(routeList) do
        local action = ACTIONS[name]
        if action and action.can() then
            return action.build()
        end
    end
    return nil
end

function R.selectRoute(name)
    if not ROUTES[name] then
        local names = {}
        for k in pairs(ROUTES) do table.insert(names, k) end
        PkCore.note("rockboy: unknown route '" .. tostring(name) .. "' (known: " .. table.concat(names, ", ") .. ")")
        return
    end
    R.routeChoice = name
    PkCore.note("rockboy: route=" .. name)
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

local function evaluate()
    if not isEarthlord() then return end
    if not liveTarget() then return end

    if PkCore.limbPrep.broken(R.legKey) then R.legBroken = true end

    local cmd = pickAction(ROUTES[R.routeChoice] or ROUTES.headonly)
    if cmd then PkCore.reactor.submitQueue({cmd}) end
end

PkCore.pk_mode.registerStrategy("rockboy", { evaluate = evaluate })

PkCore.registerAlias("PkCore rockboy leg", [[^rb\s+leg\s+(rightleg|leftleg)$]],
    [[PkCore.rockboy.legKey = matches[2] ]])
PkCore.registerAlias("PkCore rockboy reset", [[^rb\s+reset$]], [[PkCore.rockboy.resetTracking() ]])
PkCore.registerAlias("PkCore rockboy mmq", [[^mmq$]], [[PkCore.rockboy.pendingQuake = true]])
PkCore.registerAlias("PkCore rockboy route", [[^rbr\s+(\w+)$]], [[PkCore.rockboy.selectRoute(matches[2])]])