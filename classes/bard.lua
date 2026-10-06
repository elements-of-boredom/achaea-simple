return {
    name = "Bard",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 1},
    shieldBreaker = "Resonance",
    rageReserve = {
        ability = "Resonance",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Moulinet",
        command = "MOULINET",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^You twist your wrist swiftly, slicing",
        description = "The moulinet is a circular cut, using the wrist to quickly slash down the length of your target's body"
    }, {
        name = "Trill",
        command = "PLAY TRILL AT",
        cost = 28,
        cooldown = 41,
        known = true,
        success = "^You direct your voice in a high-pitched trill",
        description = "A high-pitched chant that will make your target forgetful for a short time."
    }, {
        name = "Resonance",
        command = "PLAY RESONANCE AT",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "",
        description = "Use your rage and the pitch of your voice at exactly the right frequency to resonate with a \ndenizen's shield, causing it to shatter."
    }, {
        name = "Howlslash",
        command = "HOWLSLASH",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "^You use your powerful voice to distract",
        description = "Use the power of your voice to distract your target before attacking with a vicious strike."
    }, {
        name = "Cyclone",
        command = "CYCLONE",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "^Your careful footwork leads you in a tight spin",
        description = "Spin in a tight circle, slashing out with your blade as you pass by your target. Opponents that are \ntoo stunned or clumsy to avoid the brunt of the onslaught will take substantially increased damage."
    }, {
        name = "Charm",
        command = "PLAY CHARM AT",
        cost = 32,
        cooldown = 43,
        known = true,
        success = "",
        description = "A beguiling song that charms your victim."
    }}
}
