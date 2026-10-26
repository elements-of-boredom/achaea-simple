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
    ["hawthorn berry"] = "hawthorn",    ["calamine crystal"] = "hawthorn",
    ["black cohosh root"] = "cohosh",   ["gypsum crystal"] = "cohosh"
}

opponent.EAT_SENSES = {
    bayberry = "blind",
    hawthorn = "deaf",
    cohosh = "insomnia",
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
-- A line that certainly adds or removes one affliction. who: which capture is the target (default 1);
  -- a pattern with no capture means the current target.
  function opponent.affLine(pattern, kind, aff, who)
      addTrigger(pattern, function(_, _, w)
          local name = (w and w[who or 1]) or opponent.nameOrTarget()
          if not name or not opponent.isTracked(name) then
              return
          end
          opponent.record(name, { kind = kind, aff = aff })
      end, { type = "regex" })
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
for _, pattern in ipairs(REBOUNDING_DOWN) do opponent.affLine(pattern, "gain", "norebounding") end
for _, pattern in ipairs(REBOUNDING_UP) do opponent.affLine(pattern, "lose", "norebounding") end
-- Copy paste habits ftw. DOn't think density has more than one line, but to be prepared.
local DENSITY_DOWN = {
    [[^A great weight seems to have been lifted from ([\w'\-]+)\.$]],
}
for _, pattern in ipairs(DENSITY_DOWN) do opponent.affLine(pattern, "gain", "nodensity") end

local FANGBARRIER_DOWN = {
    [[^You try to flay a non-existent sileris coating from ([\w'\-]+)\.$]],
    [[^You flay the metallic coating from ([\w'\-]+)\.$]],
}
local FANGBARRIER_UP = {
    [[^You try to bite ([\w'\-]+), but your fangs are stopped by an odd (?:metallic|waxy) coating\.$]],
}
for _, pattern in ipairs(FANGBARRIER_DOWN) do opponent.affLine(pattern, "gain", "nofangbarrier") end
for _, pattern in ipairs(FANGBARRIER_UP) do opponent.affLine(pattern, "lose", "nofangbarrier") end

local SLICKNESS_STRIP = [[^The protective coating covering the skin of ([\w'\-]+) sloughs off\.$]]
opponent.affLine(SLICKNESS_STRIP, "gain", "nofangbarrier")
opponent.affLine(SLICKNESS_STRIP, "gain", "slickness")

local SILERIS_LINES = {
    [[^([\w'\-]+) applies a sileris berry to [\w'\-]+\.$]],
    [[^([\w'\-]+) applies a quicksilver droplet to [\w'\-]+\.$]],
}
for _, pattern in ipairs(SILERIS_LINES) do
    addTrigger(pattern, function(_, _, w)
        local name = w[1]
        if not opponent.isTracked(name) then return end
        opponent.record(name, { kind = "proof", aff = "slickness", present = false })
        opponent.record(name, { kind = "gain", aff = "nofangbarrier" })
        opponent.record(name, { kind = "lose", aff = "nofangbarrier", due = PkCore.now() + opponent.SILERIS_DELAY })
    end, { type = "regex" })
end

-- The Survival skill INSOMNIA; Puts the defence straight up.
addTrigger([[^([\w'\-]+) clenches [\w'\-]+ fists and grits [\w'\-]+ teeth\.$]], function(_, _, w)
    local name = w[1]
    if not opponent.isTracked(name) then return end
    opponent.record(name, { kind = "sense", sense = "insomnia", value = "insomnia" })
end, { type = "regex" })
-- Falling asleep: proof of sleep, and that nothing (insomnia) was up to stop it.
addTrigger([[^([\w'\-]+)'s eyes close suddenly as [\w'\-]+ falls asleep\.$]], function(_, _, w)
    local name = w[1]
    if not opponent.isTracked(name) then return end
    opponent.record(name, { kind = "gain", aff = "sleeping" })
    opponent.record(name, { kind = "sense", sense = "insomnia", value = "no" })
end, { type = "regex" })

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
    ears  = {},   -- epidermal: takes deafness down; cures nothing the model tracks
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
        if spot == "ears" then -- Theres no BM cure here right????
            opponent.record(name, { kind = "sense", sense = "deaf", value = "no" })
        end
        if known then
            opponent.record(name, { kind = "cure", cure = spots[spot] or "apply" })
        else
            opponent.record(name, { kind = "cure", cure = "apply", keys = spots[spot] })
        end
    end, { type = "regex" })
end
opponent.applyLine([[^([\w'\-]+) takes some (?:balm|salve) from a vial and rubs it on [\w'\-]+ ([\w'\-]+)\.$]], opponent.SALVE_SPOTS, false)
opponent.applyLine([[^([\w'\-]+) takes some elixir from .+ and rubs it into [\w'\-]+ ([\w'\-]+)\.$]], opponent.ELIXIR_SPOTS, true)


--------------------------------------------
-------------100% REMOVALS---------------
--------------------------------------------
local REMOVALS = {
    { [[^([\w'\-]+) has writhed free of [\w'\-]+ state of transfixation\.$]], "transfixation" },
    { [[^([\w'\-]+) has writhed free of [\w'\-]+ entanglement by (?:tied )?ropes\.$]], "bound" },
    -- Inferred from our own "You have writhed free of your entanglement by webs."; not yet seen third-person.
    { [[^([\w'\-]+) has writhed free of [\w'\-]+ entanglement by webs\.$]], "webbed" },
    { [[^Gritting [\w'\-]+ glistening teeth into a rictus grin, ([\w'\-]+) emits a low rumble as [\w'\-]+ flexes [\w'\-]+ rippling muscles, bursting the bindings that hold [\w'\-]+\.$]], "bound" },
    { [[^With a look of agony on [\w'\-]+ face, ([\w'\-]+) manages to writhe [\w'\-]+ free of the weapon which impaled [\w'\-]+\.$]], "impaled" },
    { [[^([\w'\-]+) wakes up with a gasp of pain\.$]], "sleeping" },
    { [[^([\w'\-]+) awakens with a start\.$]], "sleeping" },
    { [[^([\w'\-]+) opens [\w'\-]+ eyes and stretches languidly, a smile on [\w'\-]+ face\.$]], "sleeping" },
    { [[^([\w'\-]+) opens [\w'\-]+ eyes and yawns mightily\.$]], "sleeping" },
    { [[^([\w'\-]+) seems able to move more freely all of a sudden\.$]], "hamstrung" },
    { [[^([\w'\-]+)'s eyes lose their focus suddenly\.$]], "disrupted" },
}
for _, entry in ipairs(REMOVALS) do
    opponent.affLine(entry[1], "lose", entry[2])
end
-- Fire Lord: writhing out of the weave frees them but sets them alight.
local WEAVE = [[^([\w'\-]+) has writhed free of [\w'\-]+ conflagrant weave\.$]]
opponent.affLine(WEAVE, "lose", "bound")
opponent.affLine(WEAVE, "gain", "burning")

local STANDS = {
    [[^([\w'\-]+) stands up\.$]],
    [[^([\w'\-]+) rolls smoothly back to [\w'\-]+ feet\.$]],
    [[^([\w'\-]+) pushes off the ground, coming back up into a guard position\.$]],
    [[^([\w'\-]+) backs away and out of your reach\.$]],
}
for _, pattern in ipairs(STANDS) do
    opponent.fixedCureLine(pattern, "stand", 0, "stand")
end
opponent.fixedCureLine([[^([\w'\-]+)'s eyes lose their focus suddenly\.$]], "concentrate", 0, "concentrate")

--------------------------------------------
------------------IMPALE--------------------
--------------------------------------------
local IMPALE_ON = {
    { [[^You draw your blade back and plunge it deep into the body of ([\w'\-]+) impaling [\w'\-]+ to the hilt\.$]] },
    { [[^([\w'\-]+) draws back [\w'\-]+ blade and impales ([\w'\-]+) to the hilt\.$]], 2 },
    { [[^([\w'\-]+) shifts the sword impaling ([\w'\-]+)'s abdomen, and blood streams freely from ?the grave wound\.$]], 2 },
    { [[^([\w'\-]+) is already impaled upon the sword of [\w'\-]+ and you can see no room for your own blade\.$]] },
}
local IMPALE_OFF = {
    { [[^With a vicious snarl you carve a merciless swathe through the steaming guts of ([\w'\-]+), .+$]] },
    { [[^With a vicious snarl [\w'\-]+ carves a merciless swathe through the steaming guts of ([\w'\-]+), .+$]] },
    { [[^With a snarl of contempt, you allow ([\w'\-]+) to slide free of your weapon\.$]] },
    { [[^As ([\w'\-]+) wrenches away from you, your blade rips through [\w'\-]+ innards in a violent ?fashion.+$]] },
    { [[^([\w'\-]+) tumbles out to the .+\.$]] },
}
for _, entry in ipairs(IMPALE_ON) do opponent.affLine(entry[1], "gain", "impaled", entry[2]) end
for _, entry in ipairs(IMPALE_OFF) do opponent.affLine(entry[1], "lose", "impaled", entry[2]) end
