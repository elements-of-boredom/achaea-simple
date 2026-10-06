return {
    name = "Depthswalker",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {3, 5, 1, 2},
    shieldBreaker = "Nakail",
    rageReserve = {
        ability = "Nakail",
        targetPercentAtOrBelow = 15
    },
    huntOpener = {
        command = "IL",
        balance = "word"
    },
    abilities = {{
        name = "Drain",
        command = "SHADOW DRAIN",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Cause a denizen's shadow to leech strength, causing periodic damage over time."
    }, {
        name = "Lash",
        command = "SHADOW LASH",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Command the shadows to lash a denizen, causing damage.",
        success = "^You lay into .+ with a vicious blow from a scythe of shadows\\.$"
    }, {
        name = "Curse",
        command = "CHRONO CURSE",
        cost = 24,
        cooldown = 35,
        known = true,
        description = "Bring down the Aeon affliction onto a denizen, slowing its passage through time."
    }, {
        name = "Nakail",
        command = "INTONE NAKAIL",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Destroy any shield that a denizen may be cowering behind.",
        success = "^Directing your power against the magical shield surrounding .+, you intone,.*$"
    }, {
        name = "Erasure",
        command = "CHRONO ERASURE",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Erase the concept of a denizen from the timestream, inflicting catastrophic damage."
    }, {
        name = "Boinad",
        command = "INTONE BOINAD",
        cost = 32,
        cooldown = 38,
        known = true,
        description = "Convey charm upon a denizen, forcing it to attack other denizens briefly."
    }, {
        name = "Provoke",
        command = "PROVOKE",
        cost = 32,
        cooldown = 20,
        known = false,
        description = "Provoke a denizen, forcing it to focus its attacks on you for a short duration."
    }}
}
