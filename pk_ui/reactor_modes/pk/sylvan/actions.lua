local S = PkCore.sylvanPk
local C = S.config
local T = Opponent.target
local RULES = Opponent.LIMB_RULES

local WORDS = {}
for words, key in pairs(RULES.WORDS) do
    WORDS[key] = words
end

-- Named conditions, so each action reads like the plan.
local function torsoReady()
    return T.isPrepped("torso")
end
local function torsoTrauma()
    return T.isDamaged("torso")
end
local function salveOn(spot)
    return T.has("restoring." .. spot, 0.5)
end
local function heartseedActive()
    return S.heartseedAt ~= nil and PkCore.now() - S.heartseedAt <= S.KILL_WINDOW and T.has("heartseed", 0.5)
end
local function baitPrimed()
    local count = 0
    for _, limb in ipairs(C.bait) do
        if T.isPrepped(limb) or T.isBroken(limb) then
            count = count + 1
        end
    end
    return count >= C.baitCount
end
local function preppedBait()
    for _, limb in ipairs(C.bait) do
        if T.isPrepped(limb) and not T.isBroken(limb) then
            return RULES.key(limb)
        end
    end
end
local function beingParried()
    if T.parried("torso") then
        return true
    end
    local _, why = T.nextLimb(C.bait)
    return why == "parried"
end

-- A hit that will step the limb carries gecko (slickness keeps the restoration off). Leg rends add the
-- free quarterstaff swing, which prones them if that leg is broken.
local function rend(limb)
    local key, target = RULES.key(limb), PkCore.room.targetName()
    local venom = T.isPrepped(key) and "gecko" or C.venom
    local command = "thornrend " .. target .. " " .. venom .. " " .. WORDS[key] .. " " .. C.plant
    if key == "leftleg" or key == "rightleg" then
        command = command .. "|swing quarterstaff " .. target
    end
    return command
end
local function heartseed()
    return "heartseed " .. PkCore.room.targetName()
end

S.actions = {
    vinewreathe = {
        why = "being parried: vinewreathe",
        can = function()
            return beingParried() and not T.has("vinewreathed")
        end,
        build = function()
            return "vinewreathe " .. PkCore.room.targetName()
        end
    },
    steal_body_restoration = {
        why = "heartseed up and they're restoring the body: hit the prepped torso",
        can = function()
            return heartseedActive() and salveOn("body") and torsoReady()
        end,
        build = function()
            return rend("torso")
        end
    },
    prep_torso = {
        why = "torso isn't prepped yet",
        can = function()
            return not torsoReady() and not torsoTrauma()
        end,
        build = function()
            return rend("torso")
        end
    },
    wait_heartseed = {
        why = "heartseed up, torso prepped: waiting for their restoration",
        can = heartseedActive,
        build = function()
            return nil
        end
    },
    prep_bait = {
        why = "prepping a bait limb",
        can = function()
            return not baitPrimed() and T.nextLimb(C.bait) ~= nil
        end,
        build = function()
            return rend(T.nextLimb(C.bait))
        end
    },
    heartseed_on_limb_salve = {
        why = "their salve is busy on a limb: heartseed",
        can = function()
            return salveOn("legs") or salveOn("arms")
        end,
        build = heartseed
    },
    heartseed_now = {
        why = "torso already in trauma, or salve blocked: heartseed",
        can = function()
            return torsoTrauma() or C.salveBlocked
        end,
        build = heartseed
    },
    break_bait = {
        why = "break a prepped bait limb to draw a restoration",
        can = function()
            return preppedBait() ~= nil
        end,
        build = function()
            return rend(preppedBait())
        end
    },
    wait_restoration = {
        why = "everything prepped: waiting for them to apply restoration",
        can = function()
            return true
        end,
        build = function()
            return nil
        end
    }
}

-- Thornrend needs the Viridian form; the arena portal and anything else that drops it leave every rend
-- failing with "But you are not a Viridian." Indoors it takes the staff driven into the earth.
S.actions.viridian = {
    why = "not in Viridian form: thornrend needs it",
    can = function()
        return not PkCore.defences.have.viridian
    end,
    build = function()
        return S.indoors == PkCore.room.number and "assume viridian staff" or "assume viridian"
    end
}

local function target()
    return PkCore.room.targetName()
end
local function cast(verb, pair)
    return verb .. " " .. pair[1] .. " " .. pair[2] .. " " .. target()
end
local function sealed()
    return T.has("anorexia") and T.has("slickness")
end
S.actions.break_shield = {
  why = "they're shielded: shear",
  can = function() return T.hasDef("shield") end,
  build = function()
    if S.here().disturbed then return cast("synchronise", { "shear", "cyclone" }) end
    return "cast shear at " .. target()
  end,
}

S.actions.weather_disturb = {
    why = "weather isn't disturbed here",
    can = function()
        return not S.here().disturbed
    end,
    build = function()
        return "cast disturb"
    end
}
S.actions.weather_feedback = {
    why = "feedback isn't on them",
    can = function()
        local on = S.here().feedback
        return not (on and on:lower() == target():lower())
    end,
    build = function()
        return "cast feedback at " .. target()
    end
}

-- Momentum route: setup overcharge, strike overcharge, seal, static. Anorexia, impatience, slickness and
-- asthma hold each other up (no eating, focus, salve or pipe); paralysis then takes the tree away.
local Mo = S.momentum
local function on(aff)
    return T.has(aff)
end
local function core()
    return on("asthma") and on("impatience") and on("anorexia") and on("slickness")
end
local function lockHolds()
    return on("anorexia") and on("slickness") and on("asthma")
end
-- Read from the class cure data, so a class added there is covered here too.
local function hasClassCure(cure)
    local entry = Opponent.classCures.active[cure] or Opponent.classCures.passive[cure]
    for _, class in ipairs(entry and entry.classes or {}) do
        for _, possible in ipairs(T.classes()) do
            if class == possible then
                return true
            end
        end
    end
    return false
end
-- Against might, a lock without prone breaks: the seal has to land on a prepped leg.
local function needsLeg()
    return hasClassCure("might") or (Opponent.classCureAt[target():lower()] or {}).might ~= nil
end

-- Wiping first (free) makes the named venom the only one on the vines, so it's the one the rend carries.
local function rendWith(venom, plant)
    local limb = T.nextLimb(Mo.limbs) or "torso"
    return "wipe arms|thornrend " .. target() .. " " .. venom .. " " .. WORDS[RULES.key(limb)] .. " " .. plant
end
local function setupJustLanded()
    return S.setupAt ~= nil and PkCore.now() - S.setupAt <= Mo.strikeWindow
end

-- Doesn't wait to be sure of impatience: the cyclone brings it back on a dizzy target anyway.
S.actions.momentum_static = {
    why = "anorexia, slickness, asthma on: paralysis takes the tree away",
    can = function()
        return lockHolds() and not on("paralysis")
    end,
    build = function()
        return cast("synchronise", {"static", "cyclone"})
    end
}
-- Fitness cures asthma whatever else is on them; weariness is the only thing that stops it.
-- Only once we've seen them use fitness and it's (nearly) ready again: otherwise the 18 AE is better
-- spent on the shockwave.
local function fitnessReady()
    local at = (Opponent.classCureAt[target():lower()] or {}).fitness
    return at ~= nil and PkCore.now() - at >= Mo.fitnessCooldown - 2
end
-- Overcharged water if the AE is there; otherwise vernalius on the vines, which costs none (and the
-- valerian keeps the slickness topped up).
S.actions.momentum_weariness = {
    why = "locked and their fitness is due: weariness so it can't take the asthma",
    can = function()
        return lockHolds() and on("paralysis") and not on("weariness") and fitnessReady()
    end,
    build = function()
        if S.ae() >= S.cost({"hailstone", "cyclone"}) then
            return cast("overcharge", {"hailstone", "cyclone"})
        end
        return rendWith("vernalius", "valerian")
    end
}
S.actions.momentum_asthma = {
    why = "anorexia, slickness, impatience on: asthma back",
    can = function()
        return on("anorexia") and on("slickness") and on("impatience") and not on("asthma")
    end,
    build = function()
        if S.ae() >= S.cost({"razorwind", "cyclone"}) then
            return cast("overcharge", {"razorwind", "cyclone"})
        end
        return rendWith("kalmia", "valerian")
    end
}
S.actions.momentum_impatience = {
    why = "anorexia, slickness, asthma on: impatience back",
    can = function()
        return lockHolds() and not on("impatience")
    end,
    build = function()
        return cast("synchronise", {"cyclone", "hailstone"})
    end
}
S.actions.momentum_seal = {
    why = "asthma with impatience or paralysis on: anorexia + slickness",
    can = function()
        return on("asthma") and (on("impatience") or on("paralysis")) and not sealed()
    end,
    build = function()
        local leg = needsLeg() and preppedBait()
        if not leg then
            return rendWith("slike", "valerian")
        end
        return "wipe arms|thornrend " .. target() .. " slike " .. WORDS[leg] .. " valerian|swing quarterstaff " ..
                   target()
    end
}
-- All five on: slickness keeps the body restoration off, so nothing they have cures heartseed. Waits on
-- weariness once we've seen fitness, since the kill takes ~10s and a fitness would open their pipe.
S.actions.momentum_heartseed = {
    why = "5/5 lock: heartseed",
    can = function()
        return lockHolds() and on("impatience") and on("paralysis") and
                   (on("weariness") or not (Opponent.classCureAt[target():lower()] or {}).fitness) and
                   not heartseedActive()
    end,
    build = heartseed
}
-- Right after the setup we know they're dizzy, whatever the tracker makes of their focus.
S.actions.momentum_strike = {
    why = "dizzy: paralysis, asthma, impatience in one cast",
    can = function()
        return not core() and (setupJustLanded() or on("dizziness")) and S.ae() >= S.cost(Mo.strike)
    end,
    build = function()
        return cast("overcharge", Mo.strike)
    end
}
S.actions.momentum_setup = {
    why = "AE for both overcharges: setup",
    can = function()
        return not core() and S.ae() >= Mo.setupAt and (preppedBait() or not needsLeg() or T.nextLimb(C.bait) == nil)
    end,
    build = function()
        return cast("overcharge", Mo.setup)
    end
}

-- Four rends prep a leg (22% each); the seal's rend is the fifth and breaks it.
S.actions.momentum_prep_leg = {
    why = "they have might: prepping a leg for the seal to break",
    can = function()
        return needsLeg() and not core() and not preppedBait() and T.nextLimb(C.bait) ~= nil
    end,
    build = function()
         return "wipe arms|thornrend " .. target() .. " " .. Mo.prepVenom .. " " .. WORDS[RULES.key(T.nextLimb(C.bait))] ..
                   " " .. Mo.prepPlant
    end
}

S.actions.momentum_build = {
    why = "building AE",
    can = function()
        return true
    end,
    build = function()
        return cast("synchronise", lockHolds() and Mo.holdBuild or Mo.build)
    end
}

local SW = S.shockwave

-- Only while the lock holds: that's when what's on them stays on. The setup waits for 60 AE, so
-- after setup and strike the lock builds back up to 40 with afflictions they can't cure.
S.actions.shockwave = {
    why = "locked, 40 AE and they're vulnerable: shockwave",
    can = function()
        if S.ae() < SW.minAE or setupJustLanded() or not lockHolds() then
            return false
        end
        -- Expected count, not "sure of each": one goldenseal leaves dizziness, epilepsy and impatience each
        -- uncertain, but two of the three are certainly still there.
        local expected = 0
        for _, aff in ipairs(SW.vulnerable) do
            expected = expected + T.prob(aff)
        end
        return expected >= SW.vulnerableNeeded
    end,
    build = function()
        return "cast shockwave at " .. target()
    end
}

S.actions.force_shockwave = {
    why = "FSW: forced shockwave",
    can = function()
        return S.forceShockwaveAt ~= nil and PkCore.now() - S.forceShockwaveAt <= S.FORCE_WINDOW and S.ae() >= SW.minAE
    end,
    build = function()
        return "cast shockwave at " .. target()
    end
}

-- Group: no lock to keep, so shockwave the moment there's any reason to. Thunderclap and cyclone
-- build the AE and put on sensitivity and dizziness while they do.
local GROUP = { minAE = 40, afflictions = 2, build = { "thunderclap", "cyclone" } }
local function afflictionCount()
    local n = 0
    for _, entry in ipairs(Opponent.display(target())) do
        if entry.p >= Opponent.Queries.HAS then
            n = n + 1
        end
    end
    return n
end
S.actions.group_shockwave = {
    why = "40 AE and sensitivity or 2+ afflictions: shockwave",
    can = function()
        return S.ae() >= GROUP.minAE and (T.has("sensitivity") or afflictionCount() >= GROUP.afflictions)
    end,
    build = function()
        return "cast shockwave at " .. target()
    end
}
S.actions.group_build = {
    why = "building AE: sensitivity and dizziness on the way",
    can = function()
        return true
    end,
    build = function()
        return cast("synchronise", GROUP.build)
    end
}