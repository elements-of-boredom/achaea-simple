return {
    name = "Priest",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 1},
    shieldBreaker = "Crack",
    rageReserve = {
        ability = "Crack",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Torment",
        command = "ANGEL TORMENT",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^Your angel flares its wings and flaps them powerfully",
        description = "Your angel crystalizes its wings and buffets the target with them, causing painful wounds."
    }, {
        name = "Incense",
        command = "ANGEL INCENSE",
        cost = 18,
        cooldown = 19,
        known = true,
        success = "^Your guardian angel becomes translucent as she floats first through you",
        description = "Your angel absorbs your rage and channels it into your target instead, making \nit impossible for the target to shield itself for several seconds."
    }, {
        name = "Crack",
        command = "CRACK",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "^You summon a whirlwind of flame around",
        description = "Expend your rage in a powerful blow with your mace that is able to shatter a \ndenizen's shield."
    }, {
        name = "Desolation",
        command = "PERFORM RITE OF DESOLATION ON",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "Praying to the Gods, you lay a desolating rite on",
        description = "This rite will torture the unfaithful, causing their very bones to ache. The\npain will last for several seconds, doing damage to your target for the duration."
    }, {
        name = "Hammer",
        command = "HAMMER",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "",
        description = "Swing your mace in a mighty blow at your target. This attack will do \nsignificantly increased damage to those who are too clumsy to see it coming or \nforgetful enough to neglect to dodge it."
    }, {
        name = "Horrify",
        command = "PERFORM RITE OF HORRIFY ON",
        cost = 29,
        cooldown = 34,
        known = true,
        success = "",
        description = "Summon a rite of terrible visions that causes your target to flee \nuncontrollably for several seconds."
    }}
}
