return {
    name = "Sylvan",
    basicAttack = "ck",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {6, 1, 4},
    shieldBreaker = "Disintegrate",
    rageReserve = {
        ability = "Disintegrate",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Torrent",
        command = "CAST TORRENT AT",
        cost = 14,
        cooldown = 16,
        known = true,
        success = "^.* coughs and splutters as you channel a gout of water",
        description = "Channel a gout of water at a victim's face, preventing them from breathing and causing damage"
    }, {
        name = "Sandstorm",
        command = "CAST Sandstorm AT",
        cost = 29,
        cooldown = 34,
        known = true,
        success = "^.* stumbles about in fear and flails at h\\w+ head as you summon",
        description = "Using the powers of wind and earth, summon a small sandstorm around your victim's head. Your victim will flee in terror to try and escape it."
    }, {
        name = "Thornpierce",
        command = "Thornpierce",
        cost = 17,
        cooldown = 0,
        known = true,
        success = "",
        description = "This ability requires the viridian form, allowing you to expend your rage through a thorny vine that will pierce through a denizen's shield."
    }, {
        name = "Stonevine",
        command = "STONEVINE",
        cost = 36,
        cooldown = 23,
        known = true,
        success = "^You command the razor-edged thorny vines around you",
        description = "Use your power over nature to cause a vine to grow up around your target, then channel earth to cause the vine to constrict around your target and cause great pain."
    }, {
        name = "Leechroot",
        command = "LEECHROOT",
        cost = 25,
        cooldown = 23,
        known = true,
        success = "^A deadly root flies from your hand and burrows into",
        description = "Fire a deadly thorn into your victim which will leech your victim's vitality and do damage. \nShould your victim be unable to heal properly or suffer from a weakened body, the root will do increased damage"
    }, {
        name = "Rockshot",
        command = "CAST ROCKSHOT AT",
        cost = 41,
        cooldown = 28,
        known = true,
        success = "^You form a small pebble, then channel air to fling it violently",
        description = "Summon a small pebble of earth, then channel a gust of air to fling the pebble in a precise shot at your victim's head,\n afflicting with temporary amnesia."
    }}
}
