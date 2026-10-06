return {
    name = "Fire Lord",
    basicAttack = "tp",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 1, 5, 4},
    shieldBreaker = "Wires",
    rageReserve = {
        ability = "Charge",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Engulf",
        command = "MANIFEST ENGULF",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Engulf your target in incandescent flame, causing them to suffer damage.",
        success = "^Summoning forth the primal fires, you engulf"
    }, {
        name = "Scourge",
        command = "MANIFEST SCOURGE",
        cost = 25,
        cooldown = 27,
        known = true,
        description = "Scourge your target with a lash of flame, leaving them sensitive and raw.",
        success = "^You scourge"
    }, {
        name = "Wires",
        command = "MANIFEST WIRES",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Create thin filaments of flame to rip through any magical shields that would surround your foe.",
        success = "^Raising a hand, you send forth thin wires of flame"
    }, {
        name = "Devastation",
        command = "MANIFEST DEVASTATION",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Call forth an all-consuming firestorm to ravage your foe, dealing massive damage",
        success = "^You call forth a raging firestorm to destroy"
    }, {
        name = "Cataclysm",
        command = "MANIFEST CATACLYSM",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Bring forth a cataclysm to destroy your foes, dealing massive damage\nproviding they are either stunned or reckless enough to not flee your wrath.",
        success = "^You prepare to unleash a cataclysm against"
    }, {
        name = "Bonds",
        command = "MANIFEST BONDS",
        cost = 30,
        cooldown = 42,
        known = true,
        description = "Cast a net of flame about your target, causing them to take periodic damage as they attempt to struggle free of the bonds",
        success = "^You manifest a net of flame and cast it about the form"
    }}
}
