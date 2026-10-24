local opponent = PkCore.opponent

opponent.EAT_ITEMS = {
    ["piece of kelp"] = "kelp",     ["aurum flake"] = "kelp",
    ["lobelia seed"] = "lobelia",    ["argentum flake"] = "lobelia",
    ["prickly ash bark"] = "ash",    ["stannum flake"] = "ash",
    ["bellwort flower"] = "bellwort",    ["cuprum flake"] = "bellwort",
    ["goldenseal root"] = "goldenseal",    ["plumbum flake"] = "goldenseal",
    ["bloodroot leaf"] = "bloodroot",    ["magnesium chip"] = "bloodroot",
    ["ginseng root"] = "ginseng",    ["ferrum flake"] = "ginseng",
    ["prickly pear"] = "pear",    ["calcite mote"] = "pear",
    ["ginger root"] = "ginger",    ["antimony flake"] = "ginger",
    ["bayberry bark"] = "bayberry",    ["arsenic pellet"] = "bayberry",
    ["hawthorn berry"] = "hawthorn",    ["calamine crystal"] = "hawthorn"
}

opponent.EAT_SENSES = {
    bayberry = "blind",
    hawthorn = "deaf"
}
opponent.FOCUS_GAP = 1.9
opponent.TREE_GAP = 12.5
opponent.PIPE_GAP = 1.1
opponent.SMOKES = { "smoke:elm", "smoke:valerian", "smoke:skullcap" }

--------------------------------------------
-----------HERB/Focus/Tree------------------
--------------------------------------------
-- A cure line whose cure is always the same: the first capture is the name.
function opponent.fixedCureLine(pattern, group, gap, cure, keys)
  addTrigger(pattern, function(_, _, w)
    local name = w[1]
    if not opponent.isTracked(name) then return end
    if not opponent.acceptCure(name, group, gap) then return end
    opponent.record(name, { kind = "cure", cure = cure, keys = keys })
  end, { type = "regex" })
end
opponent.fixedCureLine([[^A look of extreme focus crosses the face of ([\w'\-]+)\.$]], "focus", opponent.FOCUS_GAP, "focus")
opponent.fixedCureLine([[^([\w'\-]+) touches a tree of life tattoo\.$]], "tree", opponent.TREE_GAP, "tree")

addTrigger([[^([\w'\-]+) eats (?:a|an|some) (.+)\.$]], function(_, _, w)
    local name, item = w[1], w[2]:gsub("^withered ", "")
    local herb = opponent.EAT_ITEMS[item]
    if not herb or not opponent.isTracked(name) then
        return
    end
    if not opponent.acceptCure(name, "eat", opponent.HERB_GAP) then
        return
    end
    opponent.record(name, {
        kind = "cure",
        cure = "eat:" .. herb,
        sense = opponent.EAT_SENSES[herb]
    })
end, {
    type = "regex"
})

--------------------------------------------
-----------------PIPES----------------------
--------------------------------------------
-- Rebounding: down adds "norebounding", which skullcap cures; up removes it.
function opponent.reboundingLine(pattern, kind)
    addTrigger(pattern, function(_, _, w)
        local name = (w and w[1]) or opponent.nameOrTarget()
        if not name or not opponent.isTracked(name) then
            return
        end
        opponent.record(name, {
            kind = kind,
            aff = "norebounding"
        })
    end, {
        type = "regex"
    })
end

local REBOUNDING_DOWN = {
    [[^([\w'\-]+)'s aura of weapons rebounding disappears\.$]],
    [[^You flay away ([\w'\-]+)'s aura of rebounding defence\.$]],
    [[^You raze ([\w'\-]+)'s aura of rebounding with .+\.$]],
    [[^[\w'\-]+ razes ([\w'\-]+)'s aura of rebounding with .+\.$]],
    [[^The aura of rebounding surrounding ([\w'\-]+) is swept aside in an instant\.$]],
    [[^The falcon dives at ([\w'\-]+), ripping apart [\w'\-]+ aura of rebounding with its talons\.$]],
}
local REBOUNDING_UP = {
    [[^You suddenly perceive the vague outline of an aura of rebounding around ([\w'\-]+)\.$]],
    [[^You would be unable to pierce through the aura of rebounding protecting ([\w'\-]+)\.$]],
    [[^The attack rebounds (?:back )?onto you!$]],
}
for _, pattern in ipairs(REBOUNDING_DOWN) do
    opponent.reboundingLine(pattern, "gain")
end
for _, pattern in ipairs(REBOUNDING_UP) do
    opponent.reboundingLine(pattern, "lose")
end

local SMOKE_LINES = {
    [[^([\w'\-]+) takes a long drag off [\w'\-]+ .+\.$]],
    [[^A great gurgling sound is heard as ([\w'\-]+) takes a long drag from .+$]],
    [[^([\w'\-]+) takes a long, smooth drag from [\w'\-]+ pipe\.$]],
    [[^([\w'\-]+) takes a few short puffs from [\w'\-]+ pipe\.$]],
}
for _, pattern in ipairs(SMOKE_LINES) do
  opponent.fixedCureLine(pattern, "smoke", opponent.PIPE_GAP, "smoke", opponent.SMOKES)
end

--------------------------------------------
-----------------SALVES---------------------
--------------------------------------------
opponent.SALVE_GAP = 1.0
-- What could have been applied at each spot the line names.
opponent.SALVE_SPOTS = {
    arms  = { "apply:mending.arms", "apply:restoration.arms", "apply:health.arms" },
    legs  = { "apply:mending.legs", "apply:restoration.legs", "apply:health.legs" },
    head  = { "apply:mending.head", "apply:restoration.head", "apply:health.head", "apply:epidermal.head" },
    torso = { "apply:mending.body", "apply:restoration.body", "apply:health.torso", "apply:epidermal.body" },
    skin  = { "apply:caloric", "apply:mass" },
    -- ears: a blademaster thing we haven't identified; still proves no slickness.
}
opponent.SALVE_SPOTS.body = opponent.SALVE_SPOTS.torso
-- The elixir line is always the health salve, so the cure is known.
opponent.ELIXIR_SPOTS = {
    arms = "apply:health.arms", legs = "apply:health.legs",
    head = "apply:health.head", torso = "apply:health.torso", body = "apply:health.torso",
}
function opponent.applyLine(pattern, spots, known)
    addTrigger(pattern, function(_, _, w)
        local name, spot = w[1], w[2]
        if not opponent.isTracked(name) then return end
        if not opponent.acceptCure(name, "apply", opponent.SALVE_GAP) then return end
        if known then
            opponent.record(name, { kind = "cure", cure = spots[spot] or "apply" })
        else
            opponent.record(name, { kind = "cure", cure = "apply", keys = spots[spot] })
        end
    end, { type = "regex" })
end
opponent.applyLine([[^([\w'\-]+) takes some (?:balm|salve) from a vial and rubs it on [\w'\-]+ ([\w'\-]+)\.$]], opponent.SALVE_SPOTS, false)
opponent.applyLine([[^([\w'\-]+) takes some elixir from .+ and rubs it into [\w'\-]+ ([\w'\-]+)\.$]], opponent.ELIXIR_SPOTS, true)