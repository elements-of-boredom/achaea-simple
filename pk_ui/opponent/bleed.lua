local opponent = Opponent

-- Bleeding from DISCERN (Blademaster, Druid jaguar). Each line is a band, so we keep its middle.
-- Bleeding changes every few seconds, so a reading only counts for BLEED_FRESH seconds.
opponent.bleed = opponent.bleed or {}
opponent.BLEED_FRESH = 10

local function setBleed(name, amount)
    opponent.bleed[name:lower()] = { amount = amount, at = opponent.host.now() }
    opponent.host.changed()
end

local BANDS = {
    { [[^You observe that ([\w'\-]+) is not bleeding at all\.$]], 0 },
    { [[^You observe a small amount of blood trickling from minor wounds on ([\w'\-]+)'s body\.$]], 50 },
    { [[^You observe that ([\w'\-]+) is bleeding slightly\.$]], 150 },
    { [[^You observe thin red rivulets of blood dripping from ([\w'\-]+)'s wounds\.$]], 250 },
    { [[^You observe sluggish bleeding from ([\w'\-]+)'s wounds\.$]], 350 },
    { [[^You observe free-flowing blood streaming from ([\w'\-]+)'s wounds\.$]], 450 },
    { [[^You observe great gouts of blood spurting from ([\w'\-]+)'s many wounds\.$]], 550 },
    { [[^You observe that the wounds of ([\w'\-]+) are bleeding most severely\.$]], 650 },
    { [[^You observe heavy torrents of lifeblood spilling from ([\w'\-]+)'s near-fatal wounds\.$]], 750 },
    { [[^You observe great rivers of blood running from the open wounds of ([\w'\-]+)\.$]], 850 },
    { [[^You observe arterial spray gushing from the open wounds of ([\w'\-]+)\.$]], 950 }, -- AK only
    { [[^You observe that ([\w'\-]+) will shortly bleed to death\.$]], 1000 },
}
for _, entry in ipairs(BANDS) do
    local amount = entry[2]
    addTrigger(entry[1], function(_, _, w)
        if opponent.isTracked(w[1]) then setBleed(w[1], amount) end
    end, { type = "regex" })
end

-- Bleeding stopped outright. Anyone sees these, not only DISCERN users.
local STOPPED = {
    [[^The blood ceases flowing from the wounds of ([\w'\-]+)\.$]],
    [[^([\w'\-]+) writhes in agony as steam begins rising from [\w'\-]+ skin\.$]],
}
for _, pattern in ipairs(STOPPED) do
    addTrigger(pattern, function(_, _, w)
        if opponent.isTracked(w[1]) then setBleed(w[1], 0) end
    end, { type = "regex" })
end

function opponent.bleedAmount(name)
    local entry = opponent.bleed[name:lower()]
    if entry and opponent.host.now() - entry.at <= opponent.BLEED_FRESH then
        return entry.amount
    end
end