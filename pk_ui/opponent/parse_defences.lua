local opponent = Opponent
local E = opponent.events

local DEFENCE_LINES = {
    shield = {
        up = {
            [[^A nearly invisible magical shield forms around ([\w'\-]+)\.$]],
            [[^A dizzying beam of energy strikes you as your attack rebounds off of ([\w'\-]+)'s shield\.$]],
            [[^The magical shield surrounding ([\w'\-]+) makes that impossible\.$]],
            [[^A shimmering barrier of crystal forms about ([\w'\-]+)\.$]],
            [[^A guardian angel surrounds ([\w'\-]+) with a protective shield\.$]],
            [[^A gentle hum arises from ([\w'\-]+)'s angel, as it raises a shield to protect [\w'\-]+\.$]],
        },
        down = {
            [[^You try to flay a non-existent shield from ([\w'\-]+)\.$]],
            [[^You flay away ([\w'\-]+)'s shield defence\.$]],
            [[^You raze ([\w'\-]+)'s magical shield with .+\.$]],
            [[^[\w'\-]+ razes ([\w'\-]+)'s magical shield with .+\.$]],
            [[^([\w'\-]+) is not surrounded by a magical shield\.$]],
            [[^You find no magical shield surrounding ([\w'\-]+), and your power is unable to take hold\.$]],
            [[^Calling upon Garash, you unleash a crushing blow at the magical shield surrounding ([\w'\-]+), shattering it\.$]],
            [[^You command your gremlin to shatter the defences surrounding ([\w'\-]+)\.$]],
            [[^([\w'\-]+) has no shield for your gremlin to shatter, occultist\.$]],
            [[^As the kick strikes the magical shield surrounding ([\w'\-]+), it shatters into glimmering fragments\.$]],
            [[^The othala rune on the ground suddenly erupts in a great gout of boiling magma, the concussive blast smashing into the magical shield surrounding ([\w'\-]+) and rendering it asunder\.$]],
            [[^Lunging forward, you bring .+ in a savage diagonal blow, carving through ([\w'\-]+)'s shield\.$]],
            [[^You lunge toward ([\w'\-]+) with .+, but finding no resistance, you stumble hopelessly off balance\.$]],
            [[^The end of your staff smashes the magical shield surrounding ([\w'\-]+) in an explosion of translucent shards\.$]],
            [[^Your shadow leaps for ([\w'\-]+), hammering [\w'\-]+ shield in a silent frenzy that causes it to explode in a shower of prismatic shards\.$]],
            [[^Following the momentum of your initial strike, you come back around with a crushing blow that makes the magical shield surrounding ([\w'\-]+) explode into myriad shards\.$]],
            [[^Bleeding off the momentum from your initial blow, you come around again, slicing cleanly through ([\w'\-]+)'s magical shield\.$]],
            [[^You prepare yourself to flick your tail at ([\w'\-]+) before realising that doing so would not actually do anything\.$]],
            [[^You flick your tail at ([\w'\-]+), dismissively brushing aside the paltry shield protecting [\w'\-]+\.$]],
            [[^[\w'\-]+ dismissively flicks [\w'\-]+ tail at ([\w'\-]+), annihilating the magical shield surrounding [\w'\-]+ with casual ease\.$]],
            [[^You conjure a blade of ice and drive it straight through the magical shield surrounding ([\w'\-]+), causing it to explode in a shower of prismatic shards\.$]],
            [[^You deliver a single, powerful blow against the magical shield surrounding ([\w'\-]+), fracturing it\.$]],
            [[^(?:A miriad image of )?[\w'\-]+ brings a translucent battleaxe down in a powerful overhanded blow upon ([\w'\-]+)\.$]],
            [[^Your blow cleaves through the magical shield surrounding ([\w'\-]+), continuing on to drive [\w'\-]+ from [\w'\-]+ feet\.$]],
            [[^In your mind's eye, you see your meteor shatter ([\w'\-]+)'s shield\.$]],
            [[^A violent cracking sound from the air in front of ([\w'\-]+) heralds [\w'\-]+ magical shield exploding into a shower of translucent shards\.$]],
            [[^You touch your tattoo and summon the hammer but find nothing to strike\.$]],
            [[^You touch your tattoo and a massive, translucent hammer rises up and shatters the magical shield surrounding ([\w'\-]+)\.$]],
            [[^You command your many heads to lash out at ([\w'\-]+)'s protective shield, which shatters beneath ?the assault\.$]],
            [[^You command your heads to lash out at ([\w'\-]+)'s protective shield, but there isn't one to be ?found\.$]],
            [[^A small brown lemming rips apart the magical shield defence of ([\w'\-]+)\.$]],
        },
    },
    speed = {
        down = {
            [[^You flay away ([\w'\-]+)'s speed defence\.$]],
            [[^[\w'\-]+ razes ([\w'\-]+)'s speed defence with .+\.$]],
            [[^You stand an Aeon tarot on your palm, and blow it lightly at ([\w'\-]+)\.$]],
            [[^([\w'\-]+) suddenly seems less dexterous, [\w'\-]+ reactions becoming noticeably slower\.$]],
            [[^Directing your will upon ([\w'\-]+), you tear away the protection granted to [\w'\-]+ by the speed elixir\.$]],
            [[^You curse your doll to move slowly and tardily, and ([\w'\-]+)'s speed defence is removed\.$]],
        },
    },
    curseward = {
        up = {
            [[^A shimmering curseward appears around ([\w'\-]+)\.$]],
            [[^You try to curse ([\w'\-]+), but [\w'\-]+ is warded\.$]],
            [[^You stare at ([\w'\-]+), giving [\w'\-]+ the evil eye, but [\w'\-]+ is warded\.$]],
        },
        down = {
            [[^([\w'\-]+)'s curseward shatters!$]],
            [[^Your attempt to breach ([\w'\-]+)'s curseward has no effect\.$]],
            [[^Your attempt to breach finds no curseward\.$]],
        },
    },
    holdbreath = {
        up = {
            [[^([\w'\-]+) inhales and begins holding [\w'\-]+ breath\.$]],
            [[^You attempt to squeeze the life out of the effigy in your hands, but find the torso too tight\.$]],
            [[^You feel some resistance against your choking attempt\.$]],
        },
        down = {
            [[^([\w'\-]+) exhales loudly\.$]],
        },
    },
    prismatic = {
        up = {
            [[^([\w'\-]+) strums a few notes on .+, and a prismatic barrier forms around [\w'\-]+\.$]],
            [[^Your attack is repelled by the prismatic barrier surrounding ([\w'\-]+)\.$]],
            [[^([\w'\-]+) is surrounded by a sudden rush of feathers, and a prismatic barrier forms around [\w'\-]+\.$]],
        },
        down = {
            [[^([\w'\-]+)'s prismatic barrier dissolves into nothing\.$]],
            [[^The breath weapon rips apart ([\w'\-]+)'s prismatic barrier\.$]],
            [[^The othala rune on the ground suddenly erupts in a great gout of boiling magma, the concussive blast smashing into the prismatic barrier surrounding ([\w'\-]+) and rendering it asunder\.$]],
            [[^The prismatic barrier surrounding ([\w'\-]+) is swept aside in an instant\.$]],
        },
    },
    mounted = {
        up = {
            [[^You cannot sweep kick a mounted opponent\.$]],
        },
        down = {
            [[^([\w'\-]+) steps down off of .+\.$]],
            [[^The instep of your foot smashes into the [\w'\-]+ underarm of ([\w'\-]+), throwing [\w'\-]+ from [\w'\-]+ steed\.$]],
            [[^([\w'\-]+) begins to tumble towards the [\w'\-]+\.$]],
        },
    },
}
for def, lines in pairs(DEFENCE_LINES) do
    for _, pattern in ipairs(lines.up or {}) do opponent.onLine(pattern, { E.sense(def, def) }) end
    for _, pattern in ipairs(lines.down or {}) do opponent.onLine(pattern, { E.sense(def, "no") }) end
end
-- A speed sip looks like any other sip. LEVI puts speed back 3s, AK does 4.5. We'll do 4, after any sip once it's known stripped.
opponent.SPEED_DELAY = 4
opponent.onLine([[^([\w'\-]+) takes a drink from .+\.$]], { E.sense("speed", "speed", opponent.SPEED_DELAY, "no") })

local EXTRA = {
    -- A wild swing goes through: neither shield nor rebounding was up.
    { [[^You lurch forward at ([\w'\-]+), swinging .+ in a wildly innacurate blow\.$]], { E.sense("shield", "no"), E.gain("norebounding") } },
    { [[^A small brown lemming rips apart the aura of rebounding defence of ([\w'\-]+)\.$]], { E.gain("norebounding") } },
    -- Vaulting takes a working body.
    { [[^([\w'\-]+) easily vaults onto the back of .+\.$]], { E.sense("mounted", "mounted"), E.absent("paralysis"), E.absent("prone") } },
    { [[^As the power of your kai builds within you, you lift a hand towards ([\w'\-]+)\. A searing bolt of power leaps forth, blasting [\w'\-]+ backwards and leaving [\w'\-]+ lying, twitching, upon the ground\.$]], { E.sense("mounted", "no"), E.gain("prone") } },
    { [[^As [\w'\-]+ lifts a hand in the direction of ([\w'\-]+), [\w'\-]+ summons forth a bolt of incandescent power\. As it strikes [\w'\-]+, [\w'\-]+ is flung helplessly through the air, landing in a twitching heap\.$]], { E.sense("mounted", "no"), E.gain("prone") } },
}
for _, entry in ipairs(EXTRA) do
    opponent.onLine(entry[1], entry[2])
end

-- "** Illusion **" sits right before or after the faked line.
opponent.ILLUSION_WINDOW = 0.05
addTrigger([[^\*\* Illusion \*\*$]], function()
    opponent.illusionAt = opponent.host.now()
end, { type = "regex" })