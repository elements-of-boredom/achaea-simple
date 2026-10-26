----- AK OVERRIDES --------
-- AK has no limb-tracking support at all for Earthlord's own attacks (no weapon
-- entry anywhere in LimbHit's resolution chain) - route it through LimbHit ourselves
-- using the server-reported percentage, under a weapon name AK has never seen.
local WORD_TO_LIMB = {
  ["right leg"] = "rightleg", ["left leg"] = "leftleg",
  ["right arm"] = "rightarm", ["left arm"] = "leftarm",
  ["head"] = "head", ["torso"] = "torso",
}
local LIMB_TRAUMA = {
  head  = { [100] = "damagedhead", [200] = "mangledhead" },
  torso = { [100] = "mildtrauma",  [200] = "serioustrauma" },
}
local EARTHLORD_SALVE_BALANCE = 4.0

local function isCurrentTarget(name)
  return type(target) == "string" and name:lower() == target:lower()
end

local function syncLimbTrauma(limb)
  local tiers = LIMB_TRAUMA[limb]
  if not tiers then return end
  local score = affstrack.score[limb] or 0
  for threshold, name in pairs(tiers) do
    if score >= threshold then
      if (affstrack.score[name] or 0) == 0 then
        affstrack.score[name] = 100
        raiseEvent("AK got aff", name)
      end
    else
      if (affstrack.score[name] or 0) > 0 then
        affstrack.score[name] = 0
        raiseEvent("AK lost aff", name)
      end
    end
  end
end


local lastRealEarthlordDamage = nil

PkCore.onReady(function()
  ak.limbs.myformulas = ak.limbs.myformulas or {}
  ak.limbs.myformulas.earthfist = function(who, attacker, weapon, limb, augment, check)
    local damage = lastRealEarthlordDamage or 0
    lastRealEarthlordDamage = nil
    return damage
  end
  local originalCalculateSalve = AKcalculateSalve
  AKcalculateSalve = function(...)
    originalCalculateSalve(...)
    syncLimbTrauma("torso")
    syncLimbTrauma("head")
  end
  -- Calcify completing is modeled as "another hit" through the same pipeline -
  -- flat 100 guarantees exactly one tier crossing, same cap-and-reset AK already
  -- does correctly for Powderise.
  ak.limbs.myformulas.earthcalcify = function(who, attacker, weapon, limb, augment, check)
    return 100
  end
end)

-- powderise
PkCore.trackTrigger(tempRegexTrigger(
  "^As your blow lands with a crunch, you perceive that you have dealt ([\\d.]+)% damage to [\\w'\\-]+'s (.+)\\.$",
  PkCore.protected("earthlord.onLimbHit", function()
    local resolvedTarget = PkCore.room.targetName()
    local limbKey = WORD_TO_LIMB[matches[3]]
    if not resolvedTarget or not limbKey then return end
    if type(target) ~= "string" or resolvedTarget:lower() ~= target:lower() then
      PkCore.note("earthlord: target mismatch (" .. tostring(resolvedTarget) .. " vs AK's " .. tostring(target) .. ") - limb tracking for this hit may silently fail")
    end
    lastRealEarthlordDamage = tonumber(matches[2])
    ak.limbs.LimbHit(resolvedTarget, "Me", "earthfist", limbKey, "percent")
    syncLimbTrauma(limbKey)
    PkCore.limbPrep.recordHit(limbKey)
  end)))

-- only a parry on the line right after our own swing is ours
PkCore.trackTrigger(tempRegexTrigger(
  "^With a roar you swing a colossal fist at the (.+) of [\\w'\\-]+\\.$",
  PkCore.protected("earthlord.onSwing", function()
    local limbKey = WORD_TO_LIMB[matches[2]]
    if not limbKey then return end
    PkCore.limbPrep.recordAttempt(limbKey)
    PkCore.trackTrigger(tempLineTrigger(1, 1, function()
      if line:match("^[%w'%-]+ parries the attack with a deft manoeuvre%.$") then
        PkCore.limbPrep.recordParry()
      end
    end))
  end)))


PkCore.trackTrigger(tempRegexTrigger(
  "^Reaching out, you press a single stone digit to the torso of ([\\w'\\-]+), beginning the transformation of the calcium within\\.$",
  PkCore.protected("earthlord.onCalcifyTorsoCast", function()
    if not isCurrentTarget(matches[2]) then return end
    affstrack.score.calcifiedtorso = 100
    raiseEvent("AK got aff", "calcifiedtorso")
  end)))

-- Head completion calcifiedskull -> damagedhead, or damagedhead -> mangledhead
PkCore.trackTrigger(tempRegexTrigger(
  "^A look of pain comes over ([\\w'\\-]+) and the bones seem to shift beneath the skin stretched across (?:his|her|their) skull\\.$",
  PkCore.protected("earthlord.onCalcifySkullComplete", function()
    if not isCurrentTarget(matches[2]) then return end
    affstrack.score.calcifiedhead = 0
    raiseEvent("AK lost aff", "calcifiedhead")
    if (affstrack.score.head or 0) < 200 then
      ak.limbs.LimbHit(matches[2], "Me", "earthcalcify", "head", "percent")
      syncLimbTrauma("head")
    end
    -- else: already mangled - this is the instant-kill case, nothing to update
  end)))

-- Torso completion calcifiedtorso -> mildtrauma, or mildtrauma -> serioustrauma
PkCore.trackTrigger(tempRegexTrigger(
  "^([\\w'\\-]+) clutches at (?:his|her|their) chest, the sound of crackling bone audible over a sharply indrawn breath\\.$",
  PkCore.protected("earthlord.onCalcifyTorsoComplete", function()
    if not isCurrentTarget(matches[2]) then return end
    affstrack.score.calcifiedtorso = 0
    raiseEvent("AK lost aff", "calcifiedtorso")
    if (affstrack.score.torso or 0) < 200 then 
      ak.limbs.LimbHit(matches[2], "Me", "earthcalcify", "torso", "percent")
      syncLimbTrauma("torso")
    end
  end)))

-- Salve cure: downgrade the raw score by one tier (100), let syncLimbTrauma
-- derive the resulting affliction; only touch the pending calcify marker if
-- there's no real damage left to cure instead
PkCore.trackTrigger(tempRegexTrigger(
  "^\\s*-- Target Cured (\\w+) --\\s*$",
  PkCore.protected("earthlord.onAkConfirmedCure", function()
    local limb = matches[2]:lower()
    PkCore.note("We are in here")
    if limb == "head" or limb == "torso" then
      syncLimbTrauma(limb)  -- affstrack.score[limb] is already cleared by AK itself by this point
    end
  end)))

PkCore.trackTrigger(tempRegexTrigger(
  "^([\\w'\\-]+) takes some salve from a vial and rubs it on (?:his|her|their) body\\.$",
  PkCore.protected("earthlord.onBodyRestorationCuresCalcify", function()
    if not isCurrentTarget(matches[2]) then return end
    if (affstrack.score.calcifiedtorso or 0) > 0 then
      affstrack.score.calcifiedtorso = 0
      raiseEvent("AK lost aff", "calcifiedtorso")
    end
  end)))


local function isEarthlord()
  local classData = PkCore.classes.current()
  return classData ~= nil and classData.name == "Earth Lord"
end

  -- Handle AirLord specifically here with a good ol paste
PkCore.trackTrigger(tempRegexTrigger(
  "^([\\w'\\-]+) points an imperious finger at you, a wall of air manifesting beneath you and sending you streaking upwards\\.$",
  PkCore.protected("earthlord.onThrownAirborne", function()
    if not isEarthlord() then return end
    send("TERRAN PASTE " .. matches[2])
  end)))

--  Help AK properly track calcification
  local originalCalculateSalve = AKcalculateSalve
  AKcalculateSalve = function(...)
    originalCalculateSalve(...)
    PkCore.note("DB: AKcalculateSalve ran, torso score=" .. tostring(affstrack.score.torso))
    syncLimbTrauma("torso")
    syncLimbTrauma("head")
  end

-- AK has no idea Manifest Quake exists; the stomp prones the room, our target included
PkCore.trackTrigger(tempRegexTrigger(
  "^You stomp upon the ground, a ripple of tremors radiating out from the impact\\.$",
  PkCore.protected("earthlord.onQuake", function()
    if type(target) == "string" and (affstrack.score.prone or 0) == 0 then
      OppGainedAff("prone")
    end
  end)))

--- CLASS DATA ---
--47% SQueeze with mild trauma , 55% in titan
--27% Squeeze with no trauma

return {
    name = "Earth Lord",
    basicAttack = "tpul",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 1, 4},
    shieldBreaker = "Charge",
    rageReserve = {
        ability = "Charge",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Smash",
        command = "TERRAN SMASH",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Strike a foe with your great stone fists, dealing damage.",
        success = "^You bring one of your stone fists down upon .+ in a smashing blow\\.$"
    }, {
        name = "Rockfall",
        command = "MANIFEST ROCKFALL",
        cost = 26,
        cooldown = 33,
        known = true,
        description = "Manifest a cascading deluge of stone above your target, burying them under the downpour and stunning them.",
        success = "^You manifest rocks directly above .+, burying h\\w+ under a cascading hammer of stone\\.$"
    }, {
        name = "Charge",
        command = "TERRAN CHARGE",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Charge straight through magical shields that your foe would attempt to guard against your assault with.",
        success = "^Wreathing yourself in magma, you charge into .+, smashing through the magical shield"
    }, {
        name = "Flurry",
        command = "TERRAN FLURRY",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Deliver a terrible onslaught of blows against a foe with your empowered fists, dealing massive damage.",
        success = "^Imbuing your form with the might of earth, you launch a terrible assault upon"
    }, {
        name = "Magmaburst",
        command = "MANIFEST MAGMABURST",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Summon a column of magma to strike a foe that is either clumsy or reckless, dealing massive damage.",
        success = "^You call up a column of magma to strike down .+"
    }, {
        name = "Rampart",
        command = "TERRAN RAMPART",
        cost = 30,
        cooldown = 40,
        known = true,
        description = "Move to stand before an ally, protecting them from half of all incoming damage for eight seconds."
    }}
}
