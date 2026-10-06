return {
    name = "Blue Dragon",
    basicAttack = "dk",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 2, 1, 4},
    shieldBreaker = "Frostrive",
    rageReserve = {
        ability = "Frostrive",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Dragonchill",
        command = "DRAGONCHILL",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^You form small chunks of ice in your enormous maw, then spit them",
        description = "Use your icy breath to create chunks of ice within your mouth, then spit them in a barrage at your target."
    }, {
        name = "Glaciate",
        command = "GLACIATE",
        cost = 26,
        cooldown = 33,
        known = true,
        success = "^You breathe a column of icy air at",
        description = "Target your opponent's head with a blast of frozen air, stunning it for several seconds."
    }, {
        name = "Frostrive",
        command = "FROSTRIVE",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "",
        description = "Breathe cold air at a denizen, freezing the shield around it until the shield cracks, leaving the denizen defenseless."
    }, {
        name = "Override",
        command = "OVERRIDE",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "^You barrel into",
        description = "Knock your opponent to the ground and ride over the prone form, doing massive damage."
    }, {
        name = "Frostwave",
        command = "FROSTWAVE",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "^You breathe a wave of icy air at",
        description = "Summon a mighty wave of icy air to flow over your target, doing massive damage if your target suffers from amnesia or recklessness."
    }, {
        name = "Ague",
        command = "AGUE",
        cost = 14,
        cooldown = 23,
        known = true,
        success = "^You let loose a steady stream of cold air around",
        description = "A pervasive wave of frigid air surrounds your target, inducing chills that will make your target clumsy for a short time."
    }}
}
