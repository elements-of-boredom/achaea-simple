local opponent = PkCore.opponent

-- One line, one or more afflictions. A chance below 1 makes it evidence instead of proof.
function opponent.symptomLine(pattern, affs, chance)
    addTrigger(pattern, function(_, _, w)
        local name = w and w[1]
        if not name or not opponent.isTracked(name) then
            return
        end
        for _, aff in ipairs(affs) do
            opponent.record(name, { kind = "gain", aff = aff, chance = chance })
        end
    end, { type = "regex" })
end

local SHOWN = {
    { [[^([\w'\-]+) stiffens suddenly, [\w'\-]+ features a masque frozen in agony\.$]], { "darkshade", "paralysis" } },
    { [[^([\w'\-]+) lets out a piercing scream, as if wounded by the very sunlight\.$]], { "darkshade" } },
    { [[^([\w'\-]+) doubles over, vomiting violently\.$]], { "nausea" } },
    { [[^([\w'\-]+) sways unsteadily as [\w'\-]+ face turns an unpleasant shade of green\.$]], { "nausea" } },
    { [[^([\w'\-]+) looks about bemusedly\.$]], { "confusion" } },
    { [[^([\w'\-]+) drives a clenched fist into [\w'\-]+ gut\.$]], { "masochism" } },
    { [[^([\w'\-]+) uses [\w'\-]+ [\w'\-]+ foot to stomp on [\w'\-]+ [\w'\-]+ as hard as possible\.$]], { "masochism" } },
    { [[^([\w'\-]+) smiles as [\w'\-]+ rams [\w'\-]+ fist into [\w'\-]+ jaw\.$]], { "masochism" } },
    { [[^With the heel of [\w'\-]+ palm, ([\w'\-]+) smacks [\w'\-]+ upside the head\.$]], { "masochism" } },
    { [[^The face of ([\w'\-]+) contorts in horrified revulsion\.$]], { "masochism" } },
    { [[^([\w'\-]+) begins to pant in terror\.$]], { "claustrophobia" } },
    { [[^([\w'\-]+) is gripped with fear, staring out with terrified eyes\.$]], { "agoraphobia" } },
    { [[^([\w'\-]+) stares about [\w'\-]+ frenziedly, wild-eyed\.$]], { "dementia" } },
    { [[^([\w'\-]+) begins to jerk and shake violently, foaming at the mouth\.$]], { "epilepsy" } },
    { [[^([\w'\-]+) begins to shake uncontrollably\.$]], { "epilepsy" } },
    { [[^([\w'\-]+) misses you with [\w'\-]+ dirk by a hair\.$]], { "clumsiness" } },
    { [[^([\w'\-]+) points [\w'\-]+ finger at you, but nothing seems to happen\.$]], { "clumsiness" } },
    { [[^A frustrated frown crosses the face of ([\w'\-]+)\.$]], { "clumsiness" } },
    { [[^([\w'\-]+) stumbles clumsily as the blow lands\.$]], { "clumsiness" } },
    { [[^([\w'\-]+) stumbles, [\w'\-]+ attack going wide\.$]], { "clumsiness" } },
    { [[^([\w'\-]+) barely clips you with .+ as [\w'\-]+ fumbles [\w'\-]+ attack\.$]], { "clumsiness" } },
    { [[^([\w'\-]+) suddenly appears tired all of a sudden\.$]], { "hypersomnia" } },
    { [[^([\w'\-]+) screams out in agony, struck by the effects of a vicious venom\.$]], { "scytherus" } },
    { [[^Horror overcomes ([\w'\-]+)'s face as [\w'\-]+ body stiffens into paralysis\.$]], { "paralysis" } },
    { [[^Horror overcomes the face of ([\w'\-]+) as [\w'\-]+ body locks in paralysis\.$]], { "paralysis" } },
    { [[^([\w'\-]+)'s body stiffens rapidly with paralysis\.$]], { "paralysis" } },
    { [[^([\w'\-]+)'s limbs suddenly lock up\.$]], { "paralysis" } },
    { [[^([\w'\-]+) tosses back and forth in restless slumber\.$]], { "sleeping" } },
    { [[^([\w'\-]+) begins to thrash at the water enveloping [\w'\-]+\.$]], { "confusion" } },
    { [[^A look of panic comes over the face of ([\w'\-]+)\.$]], { "vertigo" } },
    { [[^([\w'\-]+) shuffles [\w'\-]+ feet in boredom\.$]], { "impatience" } },
    { [[^([\w'\-]+) suddenly starts scratching at an itch like mad\.$]], { "impatience" } },
    { [[^A puzzled expression crosses the face of ([\w'\-]+)\.$]], { "impatience" } },
    { [[^([\w'\-]+) shivers particularly intensely\.$]], { "frozen", "disrupted" } },
    { [[^([\w'\-]+) begins to sway unsteadily\.$]], { "dizziness" } },
    { [[^([\w'\-]+) staggers and falls to the ground\.$]], { "dizziness", "prone" } },
    { [[^([\w'\-]+) violently quakes and shudders, [\w'\-]+ eyes rolling in their sockets\.$]], { "mycalium" } },
}
for _, entry in ipairs(SHOWN) do
    opponent.symptomLine(entry[1], entry[2])
end

-- People can technically fake this. so just seeing this alone,
-- we will treat is a probability vs a confirmation.
opponent.STUPIDITY_EMOTE = 0.75
local STUPIDITY = {
    [[^Tears fill ([\w'\-]+)'s eyes and begin to slowly run down [\w'\-]+ face\.$]],
    [[^([\w'\-]+) flaps [\w'\-]+ arms madly\.$]],
    [[^([\w'\-]+) stumbles and pokes [\w'\-]+ in the eye\.$]],
    [[^([\w'\-]+) makes a strangled meowing noise and quickly shuts up, blushing\.$]],
    [[^([\w'\-]+) picks [\w'\-]+ nose absently\.$]],
    [[^([\w'\-]+) breaks down and sobs uncontrollably\.$]],
    [[^([\w'\-]+) gets down on one knee and serenades the world\.$]],
    [[^([\w'\-]+) falls to [\w'\-]+ knees in worship\.$]],
    [[^([\w'\-]+) hugs [\w'\-]+ compassionately\.$]],
    [[^([\w'\-]+) grunts a bit and then lets out a loud "OINK!"$]],
    [[^([\w'\-]+) waggles [\w'\-]+ eyebrows comically\.$]],
    [[^([\w'\-]+) wails like an old woman\.$]],
    [[^([\w'\-]+) moans, holding [\w'\-]+ head\.$]],
    [[^([\w'\-]+) twitches spasmodically\.$]],
    [[^([\w'\-]+) fondles [\w'\-]+ absently\.$]],
    [[^([\w'\-]+) blinks\.$]],
    [[^([\w'\-]+) lets out a loud, long "MOOOOOOOOOOO!"$]],
    [[^([\w'\-]+) attempts to do a standing backflip, but merely stumbles over [\w'\-]+ own feet\.$]],
}
for _, pattern in ipairs(STUPIDITY) do
    opponent.symptomLine(pattern, { "stupidity" }, opponent.STUPIDITY_EMOTE)
end

-- Blind/deaf trances (monk, blademaster)
local TRANCES = {
    { [[^A brief look of concentration crosses the face of ([\w'\-]+)\.$]], "deaf", 5 },
    { [[^([\w'\-]+) blinks slowly, and begins to tremble\.$]], "blind", 6 },
}
for _, entry in ipairs(TRANCES) do
    addTrigger(entry[1], function(_, _, w)
        if opponent.isTracked(w[1]) then
            opponent.record(w[1], { kind = "sense", sense = entry[2], value = entry[2], due = PkCore.now() + entry[3] })
        end
    end, { type = "regex" })
end

-- Expert Diagnose (a trait) - only someone with it ever sees these, so no flag is needed.
addTrigger([[^Casting a discerning eye over ([\w'\-]+), you determine that [\w'\-]+ shows the symptoms of ([\w'\-]+)\.$]], function(_, _, w)
    if opponent.isTracked(w[1]) then
        opponent.record(w[1], { kind = "gain", aff = w[2] })
    end
end, { type = "regex" })
addTrigger([[^Casting a discerning eye over ([\w'\-]+), you can see no symptoms of ([\w'\-]+)\.$]], function(_, _, w)
    if opponent.isTracked(w[1]) then
        opponent.record(w[1], { kind = "proof", aff = w[2], present = false })
    end
end, { type = "regex" })

-- Not exhaustive but we just keep adding as we see them.
-- They did something an affliction would have stopped, so the line proves they don't have it.
-- The mirror image of SHOWN. Tumbling is left out: it starts seconds before it finishes,
-- possibly before the paralysis landed.
local MOVED = { "paralysis" }
local FLEW = { "paralysis", "vertigo" }
local ATTACKED = { "paralysis", "sleeping", "transfixation", "webbed", "bound" }
for _, entry in ipairs(loadModule("opponent/attacks.lua")) do
    local classes, acted, blocked = entry[2], entry.acted ~= false, entry.blocked or {}
    addTrigger(entry[1], function(_, _, w)
        local name = w and w[1]
        if not name or not opponent.isTracked(name) then
            return
        end
        if acted then
            for _, aff in ipairs(ATTACKED) do
                opponent.record(name, { kind = "proof", aff = aff, present = false })
            end
            for _, group in ipairs(blocked) do
                opponent.record(name, { kind = "notall", affs = group })
            end
        end
        opponent.record(name, { kind = "class", classes = classes })
    end, { type = "regex" })
end
opponent.ACTED = {
    -- Leaving the room (taken from LEVI)
    { [[^([\w'\-]+) leaves to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) leaves to the [\w'\-]+, .+\.$]], MOVED },
    { [[^([\w'\-]+) leaves, following [\w'\-]+ to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) slips away to the [\w'\-]+\.$]], MOVED },
    { [[^The outline of ([\w'\-]+) fades away to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+)'s somersault takes [\w'\-]+ out of the room to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) gathers [\w'\-]+ legs under [\w'\-]+ and backflips out to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+), riding .+ leaves to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+), riding .+ gathers the reins and jumps off to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+), riding .+ departs to the [\w'\-]+, .+\.$]], MOVED },
    { [[^([\w'\-]+), riding .+ glances [\w'\-]+ and vanishes\.$]], MOVED },
    { [[^([\w'\-]+) leaps majestically to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) bounds powerfully to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) prowls out to the [\w'\-]+, moving like a jaguar\.$]], MOVED },
    { [[^The pop and crackle of lightning follows ([\w'\-]+) as [\w'\-]+ leaves to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) departs to the [\w'\-]+, .+\.$]], MOVED },
    { [[^([\w'\-]+) slowly hobbles [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) glances (?:to the )?[\w'\-]+ and vanishes\.$]], MOVED },
    { [[^Frosty scales scatter around ([\w'\-]+) as [\w'\-]+ leaves to the [\w'\-]+\.$]], MOVED },
    { [[^([\w'\-]+) launches (?:himself|herself) to the [\w'\-]+ in a great leap\.$]], MOVED },
    { [[^([\w'\-]+) stomps out to the [\w'\-]+, shaking the ground with each step\.$]], MOVED },
    { [[^([\w'\-]+) moves (?:his|her) huge bulk to the [\w'\-]+ with surprising grace\.$]], MOVED },
    -- Taking flight or climbing (LEVI): vertigo stops these too
    { [[^([\w'\-]+) is quickly carried up into the skies\.$]], FLEW },
    { [[^([\w'\-]+) crouches down upon [\w'\-]+ haunc?h?es, then with a powerful thrust]], FLEW },
    { [[^([\w'\-]+) vanishes from sight as [\w'\-]+ is carried into the sky at incredible speed\.$]], FLEW },
    { [[^([\w'\-]+) sucks in [\w'\-]+ breath, and with a mighty blast of air exhales while uttering a word of magic\.]], FLEW },
    { [[^([\w'\-]+) grabs hold of a nearby branch and swings up and out of sight into the treetops\.$]], FLEW },
    { [[^([\w'\-]+) begins to flap [\w'\-]+ wings powerfully, and rises quickly up into the firmament\.$]], FLEW },
    { [[^([\w'\-]+) spreads [\w'\-]+ arms wide, a tide of darkness boiling up from the ground and sending [\w'\-]+ aloft\.$]], FLEW },
}
for _, entry in ipairs(opponent.ACTED) do
    local affs = entry[2]
    addTrigger(entry[1], function(_, _, w)
        local name = w and w[1]
        if not name or not opponent.isTracked(name) then
            return
        end
        for _, aff in ipairs(affs) do
            opponent.record(name, { kind = "proof", aff = aff, present = false })
        end
    end, { type = "regex" })
end