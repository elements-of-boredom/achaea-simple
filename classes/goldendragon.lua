return {
    name = "Golden Dragon",
    basicAttack = "dk",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {4, 6, 2, 1},
    shieldBreaker = "Psishatter",
    rageReserve = {
        ability = "Psishatter",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Overwhelm",
        command = "OVERWHELM",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Overwhelm your massive form at your target, causing great damage as you collide.",
        success = "^You charge quickly at .+, throwing your mighty form into h\\w+ and sending h\\w+"
    }, {
        name = "Psiblast",
        command = "PSIBLAST",
        cost = 36,
        cooldown = 23,
        known = true,
        description = "Focus your massive intellect on your target's brain, searing the mind with psychic prowess.",
        success = "^You level your draconic gaze at .+, assaulting h\\w+ with psychic waves of force\\."
    }, {
        name = "Psistorm",
        command = "PSISTORM",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Assault your target with a storm of psychic power, bonus damage against weakened or stunned foes.",
        success = "^You summon a psychic storm around .+"
    }, {
        name = "Deaden",
        command = "DEADEN",
        cost = 24,
        cooldown = 35,
        known = true,
        description = "Exert a mental clamp around your opponent's mind, inflicting the Aeon affliction.",
        success = "^You psychically slam your mind into .+, deadening h\\w+ reactions\\."
    }, {
        name = "Psishatter",
        command = "PSISHATTER",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Channel battlerage into a blast of psychic energy that destroys your target's shield.",
        success = "^You blast .+ with psychic energy, demolishing h\\w+ translucent shield\\."
    }, {
        name = "Psidaze",
        command = "PSIDAZE",
        cost = 28,
        cooldown = 41,
        known = true,
        description = "Cause recurring Amnesia with sparkles of psi energy distracting your opponent.",
        success = "^You summon sparkles of psi energy around .+, causing h\\w+ to forget"
    }}
}
