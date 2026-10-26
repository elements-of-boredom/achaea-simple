 local opponent = Opponent
local E = opponent.events

-- They did this, so nothing that blocks it is present: one absent proof per blocker.
function opponent.did(action)
    local events = {}
    for _, aff in ipairs(opponent.Queries.BLOCKERS[action]) do
        events[#events + 1] = E.absent(aff)
    end
    return events
end
local MOVED, FLEW = opponent.did("move"), opponent.did("fly")
MOVED[#MOVED + 1] = E.left()
FLEW[#FLEW + 1] = E.left()

for _, entry in ipairs(loadModule("opponent/attacks.lua")) do
    local events = entry.acted ~= false and opponent.did("attack") or {}
    for _, group in ipairs(entry.blocked or {}) do
        events[#events + 1] = E.notall(group)
    end
    events[#events + 1] = E.class(entry[2])
    opponent.onLine(entry[1], events)
end


-- Not exhaustive but we just keep adding as we see them.
-- They did something an affliction would have stopped, so the line proves they don't have it.
-- The mirror image of SHOWN. Tumbling is left out: it starts seconds before it finishes,
-- possibly before the paralysis landed.
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
    opponent.onLine(entry[1], entry[2])
end