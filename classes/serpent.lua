return {
    name = "Serpent",
    basicAttack = "gk",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 6, 1, 4},
    shieldBreaker = "Excoriate",
    abilities = {{
        name = "Thrash",
        command = "THRASH",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Lash a foe with your whip, dealing damage.",
        success = "^You crack .* over your head before repeatedly lashing"
    }, {
        name = "Flagellate",
        command = "FLAGELLATE",
        cost = 25,
        cooldown = 27,
        known = true,
        description = "Whip a foe repeatedly, dealing heavier damage.",
        success = "^You crack"
    }, {
        name = "Excoriate",
        command = "EXCORIATE",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Strip away a foe's magical shield.",
        success = "^You lash out at .+ with your whip, stripping .+ translucent shield\\.$"
    }, {
        name = "Throatrip",
        command = "THROATRIP",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Tear at a foe's throat, dealing damage and afflicting them.",
        success = "^You leap upon"
    }, {
        name = "Snare",
        command = "SNARE",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Entangle a foe, hindering their movement.",
        success = "^You step behind .*"
    }, {
        name = "Obliviate",
        command = "OBLIVIATE",
        cost = 28,
        cooldown = 41,
        known = true,
        description = "Assault a foe's mind, inflicting a mental affliction."
    }, {
        name = "Provoke",
        command = "PROVOKE",
        cost = 32,
        known = false,
        description = "Provoke a denizen, forcing it to focus its attacks on you for a short duration."
    }}
}
