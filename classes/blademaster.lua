return {
    name = "Blademaster",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {1, 2},
    shieldBreaker = "Excoriate",
    abilities = {{
        name = "Leapstrike",
        command = "LEAPSTRIKE",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Fire a blast of Shin energy at the ground below you, using it to propel you high in the air. On your way down, strike your target with one knee, focusing all of your weight and downward energy in one devastating blow.",
        success = "^You crack an iron-tipped whip over your head before repeatedly lashing"
    }, {
        name = "Daze",
        command = "SHIN DAZE ",
        cost = 26,
        cooldown = 33,
        known = true,
        description = "Whip a foe repeatedly, dealing heavier damage.",
        success = "^You crack an iron-tipped whip lightly against "
    }, {
        name = "Excoriate",
        command = "EXCORIATE",
        cost = 17,
        known = true,
        description = "Strip away a foe's magical shield.",
        success = "^You lash out at .+ with your whip, stripping .+ translucent shield\\.$"
    }, {
        name = "Throatrip",
        command = "THROATRIP",
        cost = 36,
        known = false,
        description = "Tear at a foe's throat, dealing damage and afflicting them.",
        success = "^You leap upon"
    }, {
        name = "Snare",
        command = "SNARE",
        cost = 25,
        known = false,
        description = "Entangle a foe, hindering their movement."
    }, {
        name = "Obliviate",
        command = "OBLIVIATE",
        cost = 28,
        known = false,
        description = "Assault a foe's mind, inflicting a mental affliction."
    }, {
        name = "Provoke",
        command = "PROVOKE",
        cost = 32,
        known = false,
        description = "Provoke a denizen, forcing it to focus its attacks on you for a short duration."
    }}
}
