----- AK OVERRIDES --------
-- AK has no limb-tracking support at all for Earthlord's own attacks (no weapon
-- entry anywhere in LimbHit's resolution chain) - route it through LimbHit ourselves
-- using the server-reported percentage, under a weapon name AK has never seen.
local WORD_TO_LIMB = {
  ["right leg"] = "rightleg", ["left leg"] = "leftleg",
  ["right arm"] = "rightarm", ["left arm"] = "leftarm",
  ["head"] = "head", ["torso"] = "torso",
}

local lastRealEarthlordDamage = nil

PkCore.onReady(function()
  ak.limbs.myformulas = ak.limbs.myformulas or {}
  ak.limbs.myformulas.earthfist = function(who, attacker, weapon, limb, augment, check)
    local damage = lastRealEarthlordDamage or 0
    lastRealEarthlordDamage = nil
    return damage
  end
end)

PkCore.trackTrigger(tempRegexTrigger(
  "^As your blow lands with a crunch, you perceive that you have dealt ([\\d.]+)% damage to [\\w'\\-]+'s (.+)\\.$",
  PkCore.protected("earthlord.onLimbHit", function()
    local target = PkCore.room.targetName()
    local limbKey = WORD_TO_LIMB[matches[3]]
    if not target or not limbKey then return end
    lastRealEarthlordDamage = tonumber(matches[2])
    ak.limbs.LimbHit(target, "Me", "earthfist", limbKey, "percent")
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
