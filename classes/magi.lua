return {
    name = "Magi",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 2, 1, 4},
    shieldBreaker = "Disintegrate",
    rageReserve = {
        ability = "Disintegrate",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Windlash",
        command = "CAST WINDLASH AT",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^You draw upon the power of air to summon sharp gusts of wind which begin to",
        description = "Summon gusts of wind to whip across your target, attacking repeatedly for several seconds."
    }, {
        name = "Dilation",
        command = "CAST DILATION AT",
        cost = 35,
        cooldown = 35,
        known = true,
        success = "^You summon a polar vortex in a tight field around",
        description = "Polar vortex that cracks time around the target, afflicting it with Aeon."
    }, {
        name = "Disintegrate",
        command = "CAST DISINTEGRATE AT",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "^You summon a whirlwind of flame around",
        description = "Use rage to remove a denizen's shield."
    }, {
        name = "Squeeze",
        command = "CAST SQUEEZE",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "You raise a clenched fist and in obedience the earth rises in turn",
        description = "Command earth to form a stone hand to crush your target. Requires an earth channel."
    }, {
        name = "Firefall",
        command = "CAST FIREFALL AT",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "",
        description = "Hurl a flaming rock at your target. Bonus damage against Clumsy or Reckless targets."
    }, {
        name = "Stormbolt",
        command = "CAST STORMBOLT AT",
        cost = 25,
        cooldown = 27,
        known = true,
        success = "A bolt of lightning roars out from your hands as you cast a powerful spell",
        description = "Cast a bolt of electricity, afflicting the target with Sensitivity."
    }}
}
