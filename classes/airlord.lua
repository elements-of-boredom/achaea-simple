return {
    name = "Air Lord",
    basicAttack = "tp",
    requiredBalances = {"bal", "eq"},
    blockingAfflictions = {},
    auto = {2, 1, 5, 4},
    shieldBreaker = "Drill",
    rageReserve = {
        ability = "Drill",
        targetPercentAtOrBelow = 15
    },
    abilities = {{
        name = "Bolt",
        command = "MANIFEST BOLT",
        cost = 14,
        cooldown = 16,
        known = true,
        description = "Call down a lightning bolt to strike your target, causing them to suffer damage.",
        success = "^You call down a lightning bolt to destroy"
    }, {
        name = "Suffocate",
        command = "AERO SUFFOCATE",
        cost = 22,
        cooldown = 31,
        known = true,
        description = "Choke the breath from your target, causing them to become weak",
        success = "^You rip the breath from"
    }, {
        name = "Drill",
        command = "MANIFEST DRILL",
        cost = 17,
        cooldown = 0,
        known = true,
        description = "Form a drill from the very air itself, piercing through any magical\nshields your foes would attempt to cower behind.",
        success = "^You form a localised twister, spinning it at incredible speed to form a drill that"
    }, {
        name = "PressureWave",
        command = "MANIFEST PRESSUREWAVE",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Direct a crushing wave of pressurised air at your target, dealing\nmassive damage.",
        success = "^You send a crushing wave of pressurised air"
    }, {
        name = "Compress",
        command = "AERO COMPRESS",
        cost = 25,
        cooldown = 23,
        known = true,
        description = "Providing your target is sufficiently unable to prevent it(*), you may\nraise the pressure surrounding them, crushing them and causing massive\ndamage.\n\n* Requires they be either stunned or afflicted with sensitivity.",
        success = "^You raise the pressure surrounding"
    }, {
        name = "Vacuum",
        command = "MANIFEST VACUUM",
        cost = 18,
        cooldown = 25,
        known = true,
        description = "Create a vacuum around a target for a short time. The inability to draw\nin air will make healing health very difficult for a while(*).\n\n* Gives the inhibit affliction.",
        success = "^You bring a vacuum into being with"
    }}
}
