return {
    name = "Druid",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 2, 4, 1},
    shieldBreaker = "Vinecrack",
    abilities = {{
        name = "Strangle",
        command = "STRANGLE",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Summon vines from your quarterstaff which will throttle your opponent.\n The vines will continue to choke the life from your target for some time, doing damage to the denizen for the duration.",
        success = "Gesturing at"
    }, {
        name = "Redeem",
        command = "RECLAMATION REDEEM",
        cost = 22,
        cooldown = 31,
        known = true,
        description = "Steal a target's energy for a short time to feed the natural world around it, giving the weakness \n affliction for several seconds.",
        success = "At your command, undergrowth rises from the ground under"
    }, {
        name = "Vinecrack",
        command = "VINECRACK",
        cost = 17,
        known = true,
        description = "Wrap your target in vines which constrict around it, shattering a denizen's shield.",
        success = "At your command, undergrowth rises from the ground"
    }, {
        name = "Ravage",
        command = "RAVAGE",
        cooldown = 23,
        cost = 36,
        known = false,
        description = "Spring upon your target and savagely attack it with your fangs and claws.",
        success = "^You leap upon"
    }, {
        name = "Sear",
        command = "SEAR",
        cooldown = 23,
        cost = 25,
        known = false,
        description = "Summon a blast of sunlight from your outstretched quarterstaff to blind\nyour opponent. This attack will do significantly increased damage to\ntargets that are afflicted by recklessness or are stunned."
    }, {
        name = "Glare",
        command = "QSTAFF GLARE",
        cooldown = 23,
        cost = 14,
        known = false,
        description = "Assault your target with the brightened tip of your quarterstaff, causing the target to become \nclumsy for several seconds."
    }, {
        name = "Provoke",
        command = "PROVOKE",
        cost = 32,
        known = false,
        description = "Provoke a denizen, forcing it to focus its attacks on you for a short duration."
    }}
}
