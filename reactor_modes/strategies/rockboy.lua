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
R.leg1Broken = R.leg1Broken or false
R.leg2Broken = R.leg2Broken or false
R.legKey = R.legKey or "rightleg"
R.headKey = "head"
R.torsoKey = "torso"
R.damagePerHit = R.damagePerHit or 21
R.calcifyInFlight = R.calcifyInFlight or {}
R.routeChoice = R.routeChoice or "basic"
R.missedRouteWarned = R.missedRouteWarned or false
R.calcifyCommitted = R.calcifyCommitted or false
R.torsoCommitted = R.torsoCommitted or false
--Fissure
R.buried = R.buried or false
R.buriedName = R.buriedName or nil
R.buryCount = R.buryCount or 0
R.entombed = R.entombed or false
R.fissureLegsNeeded = R.fissureLegsNeeded or 1
R.fissureLegsReached = R.fissureLegsReached or false

function R.resetTracking()
    R.legBroken = false
    R.leg1Broken = false
    R.leg2Broken = false
    R.pendingQuake = false
    R.calcifyInFlight = {}
    R.missedRouteWarned = false
    R.calcifyCommitted = false
    R.torsoCommitted = false
    PkCore.limbPrep.parryStreak = {}
    PkCore.limbPrep.lastAttemptedLimb = nil
    --Fissure
    R.buried = false
    R.buriedName = nil
    R.buryCount = 0
    R.entombed = false
    R.fissureLegsNeeded = 1
    R.fissureLegsReached = false
end

local CALCIFY_AFF = {
    head = "calcifiedhead",
    torso = "calcifiedtorso"
}
local LIMB_TRAUMA_AFFS = {
    head = {"damagedhead", "mangledhead"},
    torso = {"mildtrauma", "serioustrauma"}
}
local ROUTE_LIMBS = {
    basic = {R.legKey, R.headKey},
    squeeze = {"rightleg", "leftleg", "torso"}
}

local function liveTarget()
    return PkCore.room.targetName()
end
local function isEarthlord()
    local classData = PkCore.classes.current()
    return classData ~= nil and classData.name == "Earth Lord"
end

-- temporary generic aff checker (look to move this higher for all reactors)
local function hasAff(name)
    return (affstrack.score[name] or 0) > 0
end

local function currentShaping()
    return PkCore.playerStatus.shaping or 0
end
local function currentDamagePerHit(upcomingSculptingReduction)
    local reduction = upcomingSculptingReduction or 0
    local shaping = currentShaping() - reduction
    return shaping >= 4 and 43 or R.damagePerHit
end

-- will we break, or is it broken already
local function primed(key)
    return PkCore.limbPrep.ready(key, currentDamagePerHit()) or PkCore.limbPrep.broken(key)
end

-- will we break even if we have to quake?
local function safeForCombo(key)
    return PkCore.limbPrep.ready(key, currentDamagePerHit(2))
end

-- true once calcify's touched this limb in any way, stays true
-- through cast -> pending -> completion, until the limb is fully clean again.
local function chasingLimb(key)
    if CALCIFY_AFF[key] and hasAff(CALCIFY_AFF[key]) then
        return true
    end -- calcify already landed
    if R.calcifyInFlight[key] then
        return true
    end -- calcify cast
    if PkCore.limbPrep.broken(key) then
        return true
    end -- is a limb broken
    for _, aff in ipairs(LIMB_TRAUMA_AFFS[key] or {}) do -- head/torso trauma checks
        if hasAff(aff) then
            return true
        end
    end
    return false
end

-- They cannot parry while prone, so never trust a parry-streak reading then.
local function willPrefixQuake(key)
    -- Don't quake if they aren't prone. (this may end up being a problem in groups? idk)
    if hasAff("prone") then
        return false
    end
    return R.pendingQuake or ((PkCore.limbPrep.parryStreak[key] or 0) >= 1 and currentShaping() >= 2)
end

local function powderiseCmd(key)
    local target = liveTarget()
    if not target then
        return nil
    end
    PkCore.limbPrep.recordAttempt(key)

    local word = (key == "rightleg" or key == "leftleg") and (key == "rightleg" and "right leg" or "left leg") or key
    local cmd = "TERRAN POWDERISE " .. target .. " " .. word

    if willPrefixQuake(key) then
        cmd = "MANIFEST QUAKE|" .. cmd
        R.pendingQuake = false
    end
    return cmd
end

local function calcifyCmd(limb)
    local target = liveTarget()
    if not target then
        return nil
    end
    R.calcifyInFlight[limb] = true
    tempTimer(4, function()
        R.calcifyInFlight[limb] = false
    end)
    return "TERRAN CALCIFY " .. target .. " " .. limb
end

local function crunchCmd()
    local target = liveTarget()
    return target and ("TERRAN CRUNCH " .. target) or nil
end

-- which legs need to be broken
local function fissureLegs()
    return R.fissureLegsNeeded >= 2 and {"rightleg", "leftleg"} or {R.legKey}
end
local function brokenCount(limbs)
    local n = 0
    for _, key in ipairs(limbs) do
        if PkCore.limbPrep.broken(key) then n = n + 1 end
    end
    return n
end
-- Only lose that if they cure every leg.
local function fissureReady()
    local legs = fissureLegs()
    local anyBroken = brokenCount({"rightleg", "leftleg"})
    if brokenCount(legs) >= #legs then
        R.fissureLegsReached = true
    elseif anyBroken == 0 then
        R.fissureLegsReached = false
    end
    return R.fissureLegsReached and anyBroken >= 1
end

-- ACTIONS: all things rockboy can do
local ACTIONS = {
    finish_quake_avalanche = {
        -- default/preferred finish whenever affordable - always re-prone via
        -- Quake rather than trusting our own prone-tracking isn't stale
        can = function()
            return R.calcifyCommitted and PkCore.limbPrep.broken(R.headKey) and currentShaping() >= 3
        end,
        build = function()
            return "MANIFEST QUAKE|MANIFEST AVALANCHE"
        end
    },
    finish_avalanche_fallback = {
        -- shaping fell to exactly 2 (e.g. the combo's hit got quake-prefixed
        -- for parry) - can't afford Quake first, only works if still prone
        can = function()
            return R.calcifyCommitted and PkCore.limbPrep.broken(R.headKey) and currentShaping() == 2 and
                       hasAff("prone")
        end,
        build = function()
            return "MANIFEST AVALANCHE"
        end
    },
    finish_missed_head_route = {
        can = function()
            return PkCore.limbPrep.broken(R.headKey) and not R.missedRouteWarned
        end,
        build = function()
            PkCore.note("!!! ROCKBOY: MISSED KILL ROUTE !!!")
            PkCore.note("!!! Target not prone / shaping too low to finish - likely a skilled cure !!!")
            PkCore.note("!!! Consider: rbr <name> to pivot to something more robust !!!")
            R.missedRouteWarned = true
            R.legBroken = false
            R.calcifyCommitted = false
            return nil
        end
    },
    ramp_head_while_calcifying = {
        can = function()
            return hasAff(CALCIFY_AFF.head)
        end,
        build = function()
            R.legBroken = false
            return powderiseCmd(R.headKey)
        end
    },
    calcify_and_hit_head = {
        can = function()
            return (R.legBroken or chasingLimb("head")) and currentShaping() >= 4 and safeForCombo(R.headKey)
        end,
        build = function()
            R.missedRouteWarned = false
            R.calcifyCommitted = true
            local cCmd, hCmd = calcifyCmd("head"), powderiseCmd(R.headKey)
            if cCmd and hCmd then
                -- TODO: Add separator to global config
                return cCmd .. "|" .. hCmd
            end
            -- we shouldn't ever hit this...
            return cCmd or hCmd
        end
    },
    ramp_head_for_combo = {
        -- unconditional priority on head unt
        can = function()
            return not safeForCombo(R.headKey)
        end,
        build = function()
            return powderiseCmd(R.headKey)
        end
    },
    build_shaping_for_break = {
        can = function()
            if not primed(R.legKey) or not safeForCombo(R.headKey) then
                return false
            end
            local needed = willPrefixQuake(R.legKey) and 4 or 3
            return currentShaping() < needed
        end,
        build = function()
            return crunchCmd()
        end
    },
    break_leg = {
        can = function()
            if not primed(R.legKey) or not safeForCombo(R.headKey) or R.legBroken or chasingLimb(R.headKey) then
                return false
            end
            local needed = willPrefixQuake(R.legKey) and 4 or 3
            return currentShaping() >= needed
        end,
        build = function()
            return powderiseCmd(R.legKey)
        end
    },
    prep = {
        can = function() return true end,
        build = function()
            local limbs = ROUTE_LIMBS[R.routeChoice] or ROUTE_LIMBS.basic
            if R.routeChoice == "squeeze" and R.leg1Broken then
                limbs = {"leftleg", "torso"}
            elseif R.routeChoice == "bury" then
                limbs = fissureLegs()
            end
            local limb = PkCore.limbPrep.nextUnprepared(limbs, currentDamagePerHit())
            if not limb then return nil end
            return powderiseCmd(limb)
        end
    },

    -- squeeze kill actions
    break_leg1 = {
        can = function() return primed("rightleg") and primed("leftleg") and safeForCombo(R.torsoKey) 
            and not R.leg1Broken and not chasingLimb(R.torsoKey) 
        end,
        build = function() return powderiseCmd("rightleg") end,
    },
    break_leg2_and_calcify_torso = {
        can = function()
            return R.leg1Broken and primed("leftleg") and currentShaping() >= 4
                and safeForCombo(R.torsoKey) and not chasingLimb(R.torsoKey)
        end,
        build = function()
            R.torsoCommitted = true
            local cCmd, hCmd = calcifyCmd("torso"), powderiseCmd("leftleg")
            if cCmd and hCmd then return cCmd .. "|" .. hCmd end
            return cCmd or hCmd
        end,
    },
    press_torso = {
        -- committed to the torso: leg cures no longer matter, drive it to serious trauma
        can = function()
            return (R.torsoCommitted or chasingLimb(R.torsoKey)) and not hasAff("serioustrauma")
        end,
        build = function()
            local calcifyPending = hasAff(CALCIFY_AFF.torso) or R.calcifyInFlight[R.torsoKey]
            if calcifyPending and currentShaping() < 4 then
                -- calcify will finish the trauma tier for us; be at 4 shaping for calcify|squeeze
                return crunchCmd()
            end
            return powderiseCmd(R.torsoKey)
        end,
    },
    ramp_torso_for_combo = {
        can = function() return not safeForCombo(R.torsoKey) end,
        build = function() return powderiseCmd(R.torsoKey) end,
    },
    ramp_torso_while_calcifying = {
        can = function() return hasAff(CALCIFY_AFF.torso) and not PkCore.limbPrep.broken(R.torsoKey) end,
        build = function() return powderiseCmd(R.torsoKey) end,
    },
    rebuild_shaping_for_kill = {
        can = function() return hasAff("serioustrauma") and not hasAff(CALCIFY_AFF.torso) and currentShaping() < 4 end,
        build = function() return crunchCmd() end,
    },
    calcify_squeeze_kill = {
        can = function() return hasAff("serioustrauma") and not hasAff(CALCIFY_AFF.torso) and currentShaping() >= 4 end,
        build = function()
            local target = liveTarget()
            if not target then return nil end
            return calcifyCmd("torso") .. "|TERRAN SQUEEZE " .. target
        end,
    },
    squeeze_kill = {
        can = function() return hasAff("serioustrauma") and hasAff(CALCIFY_AFF.torso) end,
        build = function() 
            local target = liveTarget()
            if not target then return nil end
            return "TERRAN SQUEEZE " .. target
        end,
    },

    -- BURY/Entomb
    entomb = {
        can = function() return R.buried and R.buryCount >= 2 and not R.entombed end,
        build = function() return "TERRAN ENTOMB" end,
    },
    bury = {
        can = function() return R.buried end,
        build =  function() return "TERRAN BURY" end
    },
    fissure = {
        can = function() return hasAff("prone") and fissureReady() end,
        build = function()
            local target = liveTarget()
            return target and ("MANIFEST FISSURE " .. target) or nil
        end,
    },
    fissure_needs_prone = {
        can = function() return not hasAff("prone") and currentShaping() >= 2 and fissureReady() end,
        build = function()
            local target = liveTarget()
            if not target then return nil end
            return "MANIFEST QUAKE | MANIFEST FISSURE ".. target
        end,
    },
    shaping_for_fissure = {
        can = function() return not hasAff("prone") and fissureReady() end,
        build = function() return crunchCmd() end,
    },
    break_leg_for_fissure = {
        can = function()
            if fissureReady() then return false end
            for _, key in ipairs(fissureLegs()) do
                if not primed(key) then return false end
            end
            return true
        end,
        build = function()
            local legs = fissureLegs()
            local leg
            for _, key in ipairs(legs) do
                if not PkCore.limbPrep.broken(key) then leg = key; break end
            end
            local cmd = powderiseCmd(leg)
            local lastLeg = brokenCount(legs) == #legs - 1
            if cmd and lastLeg and not hasAff("prone") and currentShaping() >= 2
                and not cmd:find("^MANIFEST QUAKE") then
                cmd = "MANIFEST QUAKE|" .. cmd
            end
            return cmd
        end,
    },

    -- general
    squeeze_spam = {
        can = function() return true end,
        build = function() 
            local target = liveTarget()
            if not target then return nil end
            return "TERRAN SQUEEZE " .. target
        end,
    },
}

local ROUTES = {
    basic = {
        "finish_quake_avalanche", 
        "finish_avalanche_fallback", 
        "finish_missed_head_route",
        "ramp_head_while_calcifying", 
        "calcify_and_hit_head", 
        "ramp_head_for_combo", 
        "build_shaping_for_break",
        "break_leg", 
        "prep"
    },
    squeeze = {
        "squeeze_kill",
        "calcify_squeeze_kill", 
        "rebuild_shaping_for_kill", 
        "ramp_torso_while_calcifying",
        "press_torso",
        "break_leg2_and_calcify_torso", 
        --"ramp_torso_for_combo",
        "break_leg1", 
        "prep",
    },
    group = {
        "squeeze_spam",
    },
    bury = {
        "entomb",
        "bury",
        "fissure",
        "fissure_needs_prone",
        "shaping_for_fissure",
        "break_leg_for_fissure",
        "prep"
    }
}

local function pickAction(routeList)
    for _, name in ipairs(routeList) do
        local action = ACTIONS[name]
        if action and action.can() then
            PkCore.note("DB:RB: chose ".. name)
            return action.build()
        end
    end
    return nil
end

function R.selectRoute(name)
    if not ROUTES[name] then
        local names = {}
        for k in pairs(ROUTES) do
            table.insert(names, k)
        end
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

-- fissure landed: they're under us
PkCore.trackTrigger(tempRegexTrigger(
    "^With a rumble of stone a great fissure opens beneath ([\\w'\\-]+), (?:his|her|their) body plunging out of sight\\.$",
    PkCore.protected("rockboy.onFissure", function()
        local target = liveTarget()
        if not target or matches[2]:lower() ~= target:lower() then return end
        R.buried = true
        R.buriedName = matches[2]:lower()
        R.buryCount = 0
        R.entombed = false
    end)))

-- generic bury line; only means progress while someone's actually under us
PkCore.trackTrigger(tempRegexTrigger(
    "^You dig your hands into the ground at your feet, manipulating seismic forces to damage the underlying terrain\\.$",
    PkCore.protected("rockboy.onBury", function()
        if R.buried then R.buryCount = R.buryCount + 1 end
    end)))
PkCore.trackTrigger(tempRegexTrigger(
    "^Commanding the earth to feast, you clench a great stone hand to form a fist\\.$",
    PkCore.protected("rockboy.onEntomb", function()
        if R.buried then R.entombed = true end
    end)))
-- they climbed out before the kill: alert, drop the queue, restart needing both legs
function R.onEscapedBury()
    local who = R.buriedName or "target"
    R.buried, R.buriedName, R.buryCount, R.entombed = false, nil, 0, false
    R.fissureLegsNeeded = 2
    R.fissureLegsReached = false
    R.legBroken, R.leg1Broken, R.leg2Broken = false, false, false
    send("cq all")
    PkCore.reactor.lastQueueSent = ""
    wsys.boxDisplay(who:upper() .. " SURFACED - need both legs for fissure", "white:red")
end

-- Track if the target re-enters the room. We can't bury/entomb if they are in our room.
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.AddPlayer",
    PkCore.protected("rockboy.onSurface", function()
        if not R.buried then return end
        local p = gmcp.Room.AddPlayer
        local name = tostring(type(p) == "table" and p.name or p or ""):lower()
        if name == R.buriedName then R.onEscapedBury() end
    end)))

local function evaluate()
    if not isEarthlord() then
        return
    end
    if not liveTarget() then
        return
    end

    if PkCore.limbPrep.broken(R.legKey) then
        R.legBroken = true
    end
    if PkCore.limbPrep.broken("rightleg") then 
        R.leg1Broken = true 
    end
    if PkCore.limbPrep.broken("leftleg") then
        R.leg2Broken = true
    end

    local cmd = pickAction(ROUTES[R.routeChoice] or ROUTES.basic)
    if cmd then
        PkCore.reactor.submitQueue({cmd})
    end
end

PkCore.pk_mode.registerStrategy("rockboy", {
    evaluate = evaluate
})

PkCore.registerAlias("PkCore rockboy leg", [[^rb\s+leg\s+(rightleg|leftleg)$]], [[PkCore.rockboy.legKey = matches[2] ]])
PkCore.registerAlias("PkCore rockboy reset", [[^rb\s+reset$]], [[PkCore.rockboy.resetTracking() ]])
PkCore.registerAlias("PkCore rockboy mmq", [[^mmq$]], [[PkCore.rockboy.pendingQuake = true]])
PkCore.registerAlias("PkCore rockboy route", [[^rbr\s+(\w+)$]], [[PkCore.rockboy.selectRoute(matches[2])]])
