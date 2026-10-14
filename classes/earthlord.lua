----- AK OVERRIDES --------
-- AK has no limb-tracking support at all for Earthlord's own attacks (no weapon
-- entry anywhere in LimbHit's resolution chain) - route it through LimbHit ourselves
-- using the server-reported percentage, under a weapon name AK has never seen.
local WORD_TO_LIMB = {
  ["right leg"] = "rightleg", ["left leg"] = "leftleg",
  ["right arm"] = "rightarm", ["left arm"] = "leftarm",
  ["head"] = "head", ["torso"] = "torso",
}
local CALCIFY_AFFLICTION = { head = "calcifiedskull", torso = "calcifiedtorso" }
local HEAD_SALVE_CURES = { "calcifiedskull", "damagedhead", "mangledhead" }
local BODY_SALVE_CURES = { "calcifiedtorso", "mildtrauma", "serioustrauma" }
local function isCurrentTarget(name)
  return type(target) == "string" and name:lower() == target:lower()
end

local lastRealEarthlordDamage = nil

PkCore.onReady(function()
  ak.limbs.myformulas = ak.limbs.myformulas or {}
  ak.limbs.myformulas.earthfist = function(who, attacker, weapon, limb, augment, check)
    local damage = lastRealEarthlordDamage or 0
    lastRealEarthlordDamage = nil
    return damage
  end
end)

--calcify
PkCore.trackTrigger(tempRegexTrigger(
  "^Reaching out, you press a single stone digit to the (head|torso) of ([\\w'\\-]+), beginning the transformation of the calcium within\\.$",
  PkCore.protected("earthlord.onCalcify", function()
    local aff = CALCIFY_AFFLICTION[matches[2]]
    if not aff or not isCurrentTarget(matches[3]) then return end
    affstrack.score[aff] = 100
    raiseEvent("AK got aff", aff)
    display(affstrack.score)
  end)))

PkCore.trackTrigger(tempRegexTrigger(
  "^As your blow lands with a crunch, you perceive that you have dealt ([\\d.]+)% damage to [\\w'\\-]+'s (.+)\\.$",
  PkCore.protected("earthlord.onLimbHit", function()
    local target = PkCore.room.targetName()
    local limbKey = WORD_TO_LIMB[matches[3]]
    if not target or not limbKey then return end
    lastRealEarthlordDamage = tonumber(matches[2])
    ak.limbs.LimbHit(target, "Me", "earthfist", limbKey, "percent")
  end)))

-- Nothing in AK clears these either, so they'd stick forever - clear on the
-- matching salve application.
PkCore.trackTrigger(tempRegexTrigger(
  "^([\\w'\\-]+) takes some salve from a vial and rubs it on (?:his|her|their) (head|body)\\.$",
  PkCore.protected("earthlord.onSalveApplied", function()
    if not isCurrentTarget(matches[2]) then return end
    if matches[3] == "head" then
      if (affstrack.score.mangledhead or 0) > 0 then
        affstrack.score.mangledhead = 0
        affstrack.score.damagedhead = 100
        affstrack.score.head = 100
        raiseEvent("AK lost aff", "mangledhead")
        raiseEvent("AK got aff", "damagedhead")
      elseif (affstrack.score.damagedhead or 0) > 0 then
        affstrack.score.damagedhead = 0
        affstrack.score.head = 0
        raiseEvent("AK lost aff", "damagedhead")
      elseif (affstrack.score.calcifiedskull or 0) > 0 then
        affstrack.score.calcifiedskull = 0
        raiseEvent("AK lost aff", "calcifiedskull")
      end
    else -- body
      if (affstrack.score.serioustrauma or 0) > 0 then
        affstrack.score.serioustrauma = 0
        affstrack.score.mildtrauma = 100
        affstrack.score.torso = 100
        raiseEvent("AK lost aff", "serioustrauma")
        raiseEvent("AK got aff", "mildtrauma")
      elseif (affstrack.score.mildtrauma or 0) > 0 then
        affstrack.score.mildtrauma = 0
        affstrack.score.torso = 0
        raiseEvent("AK lost aff", "mildtrauma")
      elseif (affstrack.score.calcifiedtorso or 0) > 0 then
        affstrack.score.calcifiedtorso = 0
        raiseEvent("AK lost aff", "calcifiedtorso")
      end
    end
  end)))

-- Head completion: calcifiedskull -> damagedhead, or damagedhead -> mangledhead
PkCore.trackTrigger(tempRegexTrigger(
  "^A look of pain comes over ([\\w'\\-]+) and the bones seem to shift beneath the skin stretched across (?:his|her|their) skull\\.$",
  PkCore.protected("earthlord.onCalcifySkullComplete", function()
    if not isCurrentTarget(matches[2]) then return end
    affstrack.score.calcifiedskull = 0
    raiseEvent("AK lost aff", "calcifiedskull")
    if (affstrack.score.damagedhead or 0) > 0 then
      affstrack.score.damagedhead = 0
      affstrack.score.mangledhead = 100
      affstrack.score.head = 200
      raiseEvent("AK lost aff", "damagedhead")
      raiseEvent("AK got aff", "mangledhead")
    else
      affstrack.score.damagedhead = 100
      affstrack.score.head = 100
      raiseEvent("AK got aff", "damagedhead")
    end
  end)))
-- Torso completion: calcifiedtorso -> mildtrauma, or mildtrauma -> serioustrauma
PkCore.trackTrigger(tempRegexTrigger(
  "^([\\w'\\-]+) clutches at (?:his|her|their) chest, the sound of crackling bone audible over a sharply indrawn breath\\.$",
  PkCore.protected("earthlord.onCalcifyTorsoComplete", function()
    if not isCurrentTarget(matches[2]) then return end
    affstrack.score.calcifiedtorso = 0
    raiseEvent("AK lost aff", "calcifiedtorso")
    if (affstrack.score.mildtrauma or 0) > 0 then
      affstrack.score.mildtrauma = 0
      affstrack.score.serioustrauma = 100
      affstrack.score.torso = 200
      raiseEvent("AK lost aff", "mildtrauma")
      raiseEvent("AK got aff", "serioustrauma")
    else
      affstrack.score.mildtrauma = 100
      affstrack.score.torso = 100
      raiseEvent("AK got aff", "mildtrauma")
    end
  end)))

--- CLASS DATA ---


return {
    name = "Earth Lord",
    basicAttack = "tp",
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
