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
