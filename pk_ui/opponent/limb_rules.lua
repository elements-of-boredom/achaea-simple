local rules = {}

-- Game words to keys: "left leg" -> "leftleg".
rules.WORDS = {
    ["left leg"] = "leftleg", ["right leg"] = "rightleg",
    ["left arm"] = "leftarm", ["right arm"] = "rightarm",
    head = "head", torso = "torso",
}
-- 100% damage moves a limb one step along its ladder, and the extra is lost.
rules.BREAK = 100
-- Damage left alone this long is gone.
rules.DECAY = 180
-- The two steps after broken. Most limbs go damaged then mangled; head and torso have their own.
rules.STEPS = {
    head = { "damagedhead", "mangledhead" },
    torso = { "mildtrauma", "serioustrauma" },
}

function rules.steps(limb)
    return rules.STEPS[limb] or { "damaged" .. limb, "mangled" .. limb }
end

-- Every level a limb can be at, mildest first: broken, then its two steps.
function rules.ladder(limb)
    local steps = rules.steps(limb)
    return { "broken" .. limb, steps[1], steps[2] }
end

return rules