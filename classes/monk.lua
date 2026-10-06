return {
    name = "Monk",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 2, 1, 4},
    shieldBreaker = "Splinterkick",
    rageReserve = {
        ability = "Splinterkick",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "SpinningBackfist",
        command = "SBP",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^You spin and strike",
        description = "Use the back of your fist to deliver a powerful blow, fueled by your rage and \nthe uncoiling of your spinning body."
    }, {
        name = "Scramble",
        command = "MIND SCRAMBLE",
        cost = 22,
        cooldown = 31,
        known = true,
        success = "^You rummage quickly through",
        description = "Send a small tendril of psychic energy through your target's mind to\ndeaden the nerves that govern fine motor control. This attack will give\nyour target clumsiness for several seconds."
    }, {
        name = "Splinterkick",
        command = "SPK",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "^You focus your rage in a single powerful sidekick",
        description = "Use rage to remove a denizen's shield."
    }, {
        name = "Tornado",
        command = "TNK",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "",
        description = "Leap in the air and spin rapidly, striking your target with an outstretched foot."
    }, {
        name = "Mind Blast",
        command = "MIND BLAST",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "",
        description = "Hurl your mental might in a psychic blast at your target. Targets that are \nafflicted by weakness or sensitivity will take significantly increased damage \nfrom this attack."
    }, {
        name = "Ripplestrike",
        command = "RPST",
        cost = 25,
        cooldown = 27,
        known = true,
        success = "",
        description = "Strike your target repeatedly with the tips of your fingers, causing\nyour target to become unable to heal for several seconds."
    }}
}
