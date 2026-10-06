return {
    name = "Water Lord",
    basicAttack = "mcc",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 2, 1, 4},
    shieldBreaker = "Aquahammer",
    rageReserve = {
        ability = "Aquahammer",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Icicles",
        command = "MANIFEST ICICLES",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Forge an array of lethally sharp icicles from the vapour that eternally\nsurrounds you, casting them at your target to deal damage.",
        success = "^You manifest icicles from the vapour surrounding you"
    }, {
        name = "Dehydrate",
        command = "MANIFEST DEHYDRATE",
        cost = 14,
        cooldown = 23,
        known = true,
        description = "Pull the sustaining fluids from your target, leaving them dizzy and\nentirely unable to act in a coordinated manner",
        success = "^You dehydrate the moisture from"
    }, {
        name = "Aquahammer",
        command = "MANIFEST AQUAHAMMER",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Charge straight through magical shields that your foe would attempt to guard against your assault with.",
        success = "^Wreathing yourself in magma, you charge into .+, smashing through the magical shield"
    }, {
        name = "Needlerain",
        command = "MANIFEST NEEDLERAIN",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Bring down an icy rain of needle-sharp spears upon your foe, dealing massive damage.",
        success = "^You call down a rain of needle-sharp spears of ice"
    }, {
        name = "Waterfall",
        command = "MANIFEST WATERFALL",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Bring down a deluge of water and ice upon a target, dealing massive\ndamage providing they are either hindered by being weak or having the aeon affliction.",
        success = "^You bring down a deluge upon"
    }, {
        name = "Swell",
        command = "MANIFEST SWELL",
        cost = 30,
        cooldown = 42,
        known = true,
        success = "^You begin to draw the fluid from",
        description = "Draw the vital waters from your target, reducing their health \nperiodically and bolstering your own."
    }}
}
