 local opponent = Opponent

-- Health from ASSESS, the only source for a player (GMCP target health is denizens only).
-- A reading goes stale fast in a fight, so it only counts for ASSESS_FRESH seconds.
opponent.health = opponent.health or {}
opponent.ASSESS_FRESH = 6

addTrigger([[^You glance over ([\w'\-]+) and see that [\w'\-]+ health is at (\d+)/(\d+) \[(\d+)%\]\.$]], function(_, _, w)
    opponent.health[w[1]:lower()] = { percent = tonumber(w[4]), at = opponent.host.now() }
   opponent.host.changed()
end, { type = "regex" })

function opponent.healthPercent(name)
    local entry = opponent.health[name:lower()]
    if entry and opponent.host.now() - entry.at <= opponent.ASSESS_FRESH then
        return entry.percent
    end
end
-- The current target's health %: GMCP for denizens, our last fresh ASSESS for players.
function opponent.targetHealth()
    local name = opponent.host.target()
    return opponent.host.targetHealth() or (name and opponent.healthPercent(name))
end

-- Heals we can see raise the last reading, never past 100. A mana sip looks the same as a health
-- sip, so this can overestimate. That's the safe side: a "below 75%" check just doesn't fire.
opponent.HEALS = {
    { [[^([\w'\-]+) takes a drink from .+\.$]], 17 },
    { [[^([\w'\-]+) eats (?:some irid moss|a potash crystal)\.$]], 8 },
    { [[^([\w'\-]+) swoons for a moment then rises again, flushed but strong\.$]], 40 },
    { [[^A look of relief crosses ([\w'\-]+)'s face as [\w'\-]+ touches a crystal tattoo\.$]], 100 },
}
for _, entry in ipairs(opponent.HEALS) do
    local amount = entry[2]
    addTrigger(entry[1], function(_, _, w)
        local reading = opponent.health[w[1]:lower()]
        if reading then
            reading.percent = math.min(100, reading.percent + amount)
           opponent.host.changed()
        end
    end, { type = "regex" })
end