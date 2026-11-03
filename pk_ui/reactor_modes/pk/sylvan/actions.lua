local S = PkCore.sylvanPk
local C = S.config
local T = Opponent.target
local RULES = Opponent.LIMB_RULES

local WORDS = {}
for words, key in pairs(RULES.WORDS) do WORDS[key] = words end

-- Named conditions, so each action reads like the plan.
local function torsoReady() return T.isPrepped("torso") end
local function torsoTrauma() return T.isDamaged("torso") end
local function salveOn(spot) return T.has("restoring." .. spot, 0.5) end
local function heartseedActive()
  return S.heartseedAt ~= nil and PkCore.now() - S.heartseedAt <= S.KILL_WINDOW and T.has("heartseed", 0.5)
end
local function baitPrimed()
  local count = 0
  for _, limb in ipairs(C.bait) do
    if T.isPrepped(limb) or T.isBroken(limb) then count = count + 1 end
  end
  return count >= C.baitCount
end
local function preppedBait()
  for _, limb in ipairs(C.bait) do
    if T.isPrepped(limb) and not T.isBroken(limb) then return RULES.key(limb) end
  end
end
local function beingParried()
  if T.parried("torso") then return true end
  local _, why = T.nextLimb(C.bait)
  return why == "parried"
end

-- A hit that will step the limb carries gecko (slickness keeps the restoration off). Leg rends add the
-- free quarterstaff swing, which prones them if that leg is broken.
local function rend(limb)
  local key, target = RULES.key(limb), PkCore.room.targetName()
  local venom = T.isPrepped(key) and "gecko" or C.venom
  local command = "thornrend " .. target .. " " .. venom .. " " .. WORDS[key] .. " " .. C.plant
  if key == "leftleg" or key == "rightleg" then command = command .. "|swing quarterstaff " .. target end
  return command
end
local function heartseed() return "heartseed " .. PkCore.room.targetName() end

S.actions = {
  vinewreathe = {
    why = "being parried: vinewreathe",
    can = function() return beingParried() and not T.has("vinewreathed") end,
    build = function() return "vinewreathe " .. PkCore.room.targetName() end,
  },
  steal_body_restoration = {
    why = "heartseed up and they're restoring the body: hit the prepped torso",
    can = function() return heartseedActive() and salveOn("body") and torsoReady() end,
    build = function() return rend("torso") end,
  },
  prep_torso = {
    why = "torso isn't prepped yet",
    can = function() return not torsoReady() and not torsoTrauma() end,
    build = function() return rend("torso") end,
  },
  wait_heartseed = {
    why = "heartseed up, torso prepped: waiting for their restoration",
    can = heartseedActive,
    build = function() return nil end,
  },
  prep_bait = {
    why = "prepping a bait limb",
    can = function() return not baitPrimed() and T.nextLimb(C.bait) ~= nil end,
    build = function() return rend(T.nextLimb(C.bait)) end,
  },
  heartseed_on_limb_salve = {
    why = "their salve is busy on a limb: heartseed",
    can = function() return salveOn("legs") or salveOn("arms") end,
    build = heartseed,
    fired = S.heartseedCast,
  },
  heartseed_now = {
    why = "torso already in trauma, or salve blocked: heartseed",
    can = function() return torsoTrauma() or C.salveBlocked end,
    build = heartseed,
    fired = S.heartseedCast,
  },
  break_bait = {
    why = "break a prepped bait limb to draw a restoration",
    can = function() return preppedBait() ~= nil end,
    build = function() return rend(preppedBait()) end,
  },
  wait_restoration = {
    why = "everything prepped: waiting for them to apply restoration",
    can = function() return true end,
    build = function() return nil end,
  },
}

-- Thornrend needs the Viridian form; the arena portal and anything else that drops it leave every rend
-- failing with "But you are not a Viridian." Indoors it takes the staff driven into the earth.
S.actions.viridian = {
  why = "not in Viridian form: thornrend needs it",
  can = function() return not PkCore.defences.have.viridian end,
  build = function() return S.indoors == PkCore.room.number and "assume viridian staff" or "assume viridian" end,
}

local function target() return PkCore.room.targetName() end
local function cast(verb, pair) return verb .. " " .. pair[1] .. " " .. pair[2] .. " " .. target() end
local function sealed() return T.has("anorexia") and T.has("slickness") end

S.actions.lock_disturb = {
  why = "weather isn't disturbed here",
  can = function() return not S.here().disturbed end,
  build = function() return "cast disturb" end,
}
S.actions.lock_feedback = {
  why = "feedback isn't on them",
  can = function()
    local on = S.here().feedback
    return not (on and on:lower() == target():lower())
  end,
  build = function() return "cast feedback at " .. target() end,
}

-- Momentum route: setup overcharge, strike overcharge, seal, static. Anorexia, impatience, slickness and
-- asthma hold each other up (no eating, focus, salve or pipe); paralysis then takes the tree away.
local Mo = C.momentum
local function on(aff) return T.has(aff) end
local function core() return on("asthma") and on("impatience") and on("anorexia") and on("slickness") end
-- Wiping first (free) makes the named venom the only one on the vines, so it's the one the rend carries.
local function rendWith(venom, plant)
  local limb = T.nextLimb(Mo.limbs) or "torso"
  return "wipe arms|thornrend " .. target() .. " " .. venom .. " " .. WORDS[RULES.key(limb)] .. " " .. plant
end
local function setupJustLanded()
  for _, spell in ipairs(Mo.setup) do
    local at = S.storedAt and S.storedAt[spell]
    if not at or PkCore.now() - at > Mo.strikeWindow then return false end
  end
  return true
end

-- Doesn't wait to be sure of impatience: the cyclone brings it back on a dizzy target anyway.
S.actions.momentum_static = {
  why = "anorexia, slickness, asthma on: paralysis takes the tree away",
  can = function() return on("anorexia") and on("slickness") and on("asthma") and not on("paralysis") end,
  build = function() return cast("synchronise", { "static", "cyclone" }) end,
}
-- Fitness cures asthma whatever else is on them; weariness is the only thing that stops it. Grulk's
-- 5/5 at 13:35:40 broke to fitness two seconds later.
-- Only once we've seen them use fitness and it's (nearly) ready again: otherwise the 18 AE is better
-- spent on the shockwave.
local function fitnessReady()
  local at = S.fitnessAt[target():lower()]
  return at ~= nil and PkCore.now() - at >= Mo.fitnessCooldown - 2
end
-- Overcharged water if the AE is there; otherwise vernalius on the vines, which costs none (and the
-- valerian keeps the slickness topped up).
S.actions.momentum_weariness = {
  why = "locked and their fitness is due: weariness so it can't take the asthma",
  can = function()
    return on("anorexia") and on("slickness") and on("asthma") and on("paralysis") and not on("weariness")
      and fitnessReady()
  end,
  build = function()
    if S.ae() >= S.cost({ "hailstone", "cyclone" }) then return cast("overcharge", { "hailstone", "cyclone" }) end
    return rendWith("vernalius", "valerian")
  end,
}
S.actions.momentum_asthma = {
  why = "anorexia, slickness, impatience on: asthma back",
  can = function() return on("anorexia") and on("slickness") and on("impatience") and not on("asthma") end,
  build = function()
    if S.ae() >= S.cost({ "razorwind", "cyclone" }) then return cast("overcharge", { "razorwind", "cyclone" }) end
    return rendWith("kalmia", "valerian")
  end,
}
S.actions.momentum_impatience = {
  why = "anorexia, slickness, asthma on: impatience back",
  can = function() return on("anorexia") and on("slickness") and on("asthma") and not on("impatience") end,
  build = function() return cast("synchronise", { "cyclone", "hailstone" }) end,
}
S.actions.momentum_seal = {
  why = "asthma with impatience or paralysis on: anorexia + slickness",
  can = function() return on("asthma") and (on("impatience") or on("paralysis")) and not sealed() end,
  build = function() return rendWith("slike", "valerian") end,
}
-- All five on: slickness keeps the body restoration off, so nothing they have cures heartseed. Waits on
-- weariness once we've seen fitness, since the kill takes ~10s and a fitness would open their pipe.
S.actions.momentum_heartseed = {
  why = "5/5 lock: heartseed",
  can = function()
    return on("anorexia") and on("slickness") and on("asthma") and on("impatience") and on("paralysis")
      and (on("weariness") or not S.fitnessAt[target():lower()]) and not heartseedActive()
  end,
  build = heartseed,
  fired = S.heartseedCast,
}
-- Right after the setup we know they're dizzy, whatever the tracker makes of their focus.
S.actions.momentum_strike = {
  why = "dizzy: paralysis, asthma, impatience in one cast",
  can = function() return not core() and (setupJustLanded() or on("dizziness")) and S.ae() >= S.cost(Mo.strike) end,
  build = function() return cast("overcharge", Mo.strike) end,
}
S.actions.momentum_setup = {
  why = "AE for both overcharges: setup",
  can = function() return not core() and S.ae() >= Mo.setupAt end,
  build = function() return cast("overcharge", Mo.setup) end,
}
-- While anorexia, slickness and asthma hold, nothing they eat off: build with kelp afflictions instead.
local function lockHolds() return on("anorexia") and on("slickness") and on("asthma") end
S.actions.momentum_build = {
  why = "building AE",
  can = function() return true end,
  build = function() return cast("synchronise", lockHolds() and Mo.holdBuild or Mo.build) end,
}

-- Shockwave whenever it's on: sensitivity and most of the other kelp afflictions. We don't know its
-- line yet, so the queue confirmation zeroes our AE; the next AE line corrects it if the cast failed.
local SW = C.shockwave
local function count(affs)
  local n = 0
  for _, aff in ipairs(affs) do
    if T.has(aff) then n = n + 1 end
  end
  return n
end
-- Only while the lock holds: that's when what's on them stays on. The setup waits for 60 AE, so
-- after setup and strike the lock builds back up to 40 with afflictions they can't cure.
S.actions.shockwave = {
  why = "locked, 40 AE and they're vulnerable: shockwave",
  can = function()
    if S.ae() < SW.minAE or setupJustLanded() or not lockHolds() then return false end
    if T.has("sensitivity", SW.sensitivity) and count(SW.kelp) >= SW.kelpNeeded then return true end
    -- Expected count, not "sure of each": one goldenseal leaves dizziness, epilepsy and impatience each
    -- uncertain, but two of the three are certainly still there.
    local expected = 0
    for _, aff in ipairs(SW.vulnerable) do expected = expected + T.prob(aff) end
    return expected >= SW.vulnerableNeeded
  end,
  build = function() return "cast shockwave at " .. target() end,
}

S.actions.force_shockwave = {
  why = "FSW: forced shockwave",
  can = function()
    return S.forceShockwaveAt ~= nil and PkCore.now() - S.forceShockwaveAt <= S.FORCE_WINDOW and S.ae() >= SW.minAE
  end,
  build = function() return "cast shockwave at " .. target() end,
}
