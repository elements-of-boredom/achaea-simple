 local opponent = Opponent
local E = opponent.events

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
    local events = {}
    for _, aff in ipairs(entry[2]) do
        events[#events + 1] = E.gain(aff)
    end
    opponent.onLine(entry[1], events)
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
    opponent.onLine(pattern, { E.gain("stupidity", opponent.STUPIDITY_EMOTE) })
end

-- Blind/deaf trances (monk, blademaster): the defence comes up a few seconds after the line.
local TRANCES = {
    { [[^A brief look of concentration crosses the face of ([\w'\-]+)\.$]], { E.sense("deaf", "deaf", 5) } },
    { [[^([\w'\-]+) blinks slowly, and begins to tremble\.$]], { E.sense("blind", "blind", 6) } },
}
for _, entry in ipairs(TRANCES) do
    opponent.onLine(entry[1], entry[2])
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