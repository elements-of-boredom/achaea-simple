local opponent = Opponent

-- Lines that name a limb's state. { pattern, level, name capture, limb capture }
local LIMB_STATES = {
    { [[^(?:An alabaster pegasus|A steppe eagle) (?:breaks|crushes|pulverises|smashes) the ((?:left|right) (?:arm|leg)) of ([\w'\-]+)\.$]], 1, 2, 1 },
    { [[^The ((?:left|right) (?:arm|leg)) of ([\w'\-]+) is smashed to a bloody pulp\.$]], 1, 2, 1 },
    { [[^([\w'\-]+) screams as [\w'\-]+ ((?:left|right) (?:arm|leg)) is crushed\.$]], 1, 1, 2 },
    { [[^([\w'\-]+)'s (left leg|right leg|left arm|right arm|head|torso) has been beaten into uselessness\.$]], 3, 1, 2 },
}
for _, entry in ipairs(LIMB_STATES) do
    local level, who, where = entry[2], entry[3], entry[4]
    addTrigger(entry[1], function(_, _, w)
        local name, limb = w[who], opponent.LIMBS[w[where]]
        if limb and opponent.isTracked(name) then
            opponent.record(name, { kind = "limbat", limb = limb, level = level })
        end
    end, { type = "regex" })
end

-- Our attack didn't land, so nothing it carried counts: no venom, no limb damage.
local MISSES = {
    [[^([\w'\-]+) dodges nimbly out of the way\.$]],
    [[^([\w'\-]+) quickly jumps back, avoiding the attack\.$]],
    [[^([\w'\-]+) twists [\w'\-]+ body out of harm's way\.$]],
    [[^A reflection of ([\w'\-]+) blinks out of existence\.$]],
    [[^A chaos orb intercepts the attack against ([\w'\-]+) and renders it harmless\.$]],
    [[^Cracks spider across the surface of the crimson shield surrounding ([\w'\-]+), before it abruptly winks out of existence\.$]],
    [[^You lash out at ([\w'\-]+) with .+, but miss\.$]],
    [[^The attack rebounds (?:back )?onto you!$]],
}
for _, pattern in ipairs(MISSES) do
    addTrigger(pattern, function(_, _, w)
        local name = (w and w[1]) or opponent.nameOrTarget()
        if not name then return end
        local attack = opponent.lastPending(name, "attack")
        if attack then attack.missed = true end
    end, { type = "regex" })
end

-- Parries and guards stop a hit on one limb: remember which, so offense can work another.
local PARRIES = {
    [[^([\w'\-]+) parries the attack with a deft manoeuvre\.$]],
    [[^([\w'\-]+) steps into the attack, grabs your arm, and throws you violently to the ground\.$]],
    [[^([\w'\-]+) moves into your attack, knocking your blow aside before viciously countering with a strike to your head\.$]],
}
for _, pattern in ipairs(PARRIES) do
    addTrigger(pattern, function(_, _, w)
        local attack = opponent.lastPending(w[1], "attack")
        if attack then attack.missed, attack.parried = true, true end
    end, { type = "regex" })
end