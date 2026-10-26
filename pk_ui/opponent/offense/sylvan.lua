 local opponent = Opponent
local E = opponent.events

-- The plant our arms are propagated with. It persists until the next crush line,
-- and every thornrend delivers it before the venom.
local ARMS = {
  kelp       = { gives = "healthleech" },
  bellwort   = { gives = "weariness" },
  lobelia    = { gives = "vertigo" },
  elm        = { gives = "dizziness" },
  goldenseal = { gives = "epilepsy" },
  valerian   = { gives = "slickness" },
  hawthorn   = { gives = "sensitivity", strips = "deaf" },
  kola       = { gives = "sleeping", strips = "insomnia", shown = true },
  bloodroot  = {},
  sileris    = {},
  skullcap   = {},
}

opponent.offense = opponent.offense or {}

-- Which arms plant an item is: "piece of slippery elm" -> "elm".
local function sylvanArmsPlant(item)
    for plant in pairs(ARMS) do
        if item:find(plant, 1, true) then
            return plant
        end
    end
end
function opponent.clearArms()
    opponent.offense.arms = nil
    setVariable("pk_arms", "")
end
function opponent.showArms()
    opponent.host.note("arms: " .. tostring(opponent.offense.arms))
end
-- Leaving or (re)entering viridian unpropagates the arms; GMCP sees every way out.
function opponent.sylvanDefenceList(data)
    if type(data) ~= "table" then return end
    for _, entry in ipairs(data) do
        if type(entry) == "table" and entry.name == "viridian" then
            return
        end
    end
    opponent.clearArms()
end

function opponent.sylvanDefenceAdd(entry)
    if type(entry) == "table" and entry.name == "viridian" then
        opponent.clearArms()
    end
end

function opponent.sylvanDefenceRemove(names)
    if type(names) ~= "table" then return end
    for _, name in ipairs(names) do
        if name == "viridian" then
            opponent.clearArms()
        end
    end
end

onGMCPUpdate("Char.Defences.List", opponent.sylvanDefenceList)
onGMCPUpdate("Char.Defences.Add", opponent.sylvanDefenceAdd)
onGMCPUpdate("Char.Defences.Remove", opponent.sylvanDefenceRemove)


local savedArms = getVariable("pk_arms")
if type(savedArms) == "string" and ARMS[savedArms] then
    opponent.offense.arms = savedArms
end

addTrigger([[^Crushing (?:a|an|some) (.+) in your hand, you absorb the remnants of natural energy stored within\.$]], function(_, _, w)
    local plant = sylvanArmsPlant(w[1])
    if not plant then
        opponent.host.note("unknown arms plant: " .. w[1])
        return
    end
    opponent.offense.arms = plant
    setVariable("pk_arms", plant)
end, { type = "regex" })

-- The venom on our vines for the next rend. Cleared by that rend, or by the prompt if no rend came.
addTrigger([[^You rub some ([\w'\-]+) on the thorny vines covering your arms\.$]], function(_, _, w)
    opponent.offense.venom = w[1]:lower()
end, { type = "regex" })
-- onVitalsChanged is the same as getting a prompt. Clear venom for sylvan here.
opponent.host.onPrompt("sylvan venom", function()
    opponent.offense.venom = nil
end)

addTrigger([[^You command the razor-edged thorny vines around you to lash out and rend the (.+) of ([\w'\-]+)\.$]], function(_, _, w)
    local limb, name = w[1], w[2]
    local deliveries = {}
    if opponent.offense.arms then
        deliveries[#deliveries + 1] = ARMS[opponent.offense.arms]
    end
    local venom = opponent.offense.venom
    if venom then
        if opponent.VENOMS[venom] then
            deliveries[#deliveries + 1] = opponent.VENOMS[venom]
        else
            opponent.host.note("unknown venom: " .. venom)
        end
    end
    opponent.offense.venom = nil
    opponent.record(name, {
        kind = "attack",
        deliveries = deliveries,
        limb = limb ~= "flesh" and limb or nil,
        confirmed = limb == "flesh",
    })
end, { type = "regex" })

addTrigger([[^As you carve into ([\w'\-]+), you perceive that you have dealt ([\d.]+)% damage to [\w'\-]+ (.+)\.$]], function(_, _, w)
    local attack = opponent.lastPending(w[1], "attack")
    if not attack then return end
    attack.confirmed = true
    attack.damage = tonumber(w[2])
end, { type = "regex" })

-- Generic to any attack; TODO: Move to a shared offense file when a second class needs it.
addTrigger([[^([\w'\-]+) parries the attack with a deft manoeuvre\.$]], function(_, _, w)
    local attack = opponent.lastPending(w[1], "attack")
    if attack then attack.missed = true end
end, { type = "regex" })

opponent.BLACKOUT_ECLIPSE = 6
opponent.BLACKOUT_BOLT = 4
opponent.VINEWREATHE = 25
local SPELLS = {
    { [[^Channeling arcane power through your air and earth channels, you summon forth a burst of arcane static directed at ([\w'\-]+)\.$]],
        { E.gain("paralysis") } },
    { [[^Channeling large quantities of arcane power through your air channel, you direct a localised explosion of pure sound at ([\w'\-]+)\.$]],
        { E.gain("sensitivity"), E.sense("deaf", "no") } },
    { [[^Channeling large quantities of arcane power through your air channel, you direct a localised explosion of pure sound at ([\w'\-]+), restoring [\w'\-]+ hearing\.$]],
        { E.sense("deaf", "no") } },
    { [[^Summoning forth power through your air and earth channels, you conjure forth a brilliant flash of light at ([\w'\-]+), who blinks rapidly\.$]],
        { E.sense("blind", "no") } },
    { [[^Summoning forth power through your air and earth channels, you conjure forth a brilliant flash of light at ([\w'\-]+), who freezes in place\.$]],
        { E.gain("transfixation"), E.sense("blind", "no") } },
    { [[^Tapping into your air channel, you summon forth a vicious wind to lacerate the body of ([\w'\-]+)\.$]],
        { E.gain("healthleech") } },
    { [[^[\w'\-]+ thrusts one hand toward ([\w'\-]+), summoning forth a wind to viciously lacerate [\w'\-]+\.$]],
        { E.gain("healthleech") } },
    { [[^Summoning forth energy that you have gathered, you conjure forth a terrible cyclone of wind, picking up ([\w'\-]+) and whipping [\w'\-]+ about in a frenzy\.$]],
        { E.gain("dizziness") } },
    { [[^Summoning forth energy that you have gathered, you conjure forth a terrible cyclone of wind, picking up the disorientated form of ([\w'\-]+) and whipping [\w'\-]+ about in a frenzy, dashing [\w'\-]+ against any available surfaces\.$]],
        { E.present("dizziness"), E.gain("impatience") } },
    { [[^A flare of (?:sun|moon)light streaks forward to engulf ([\w'\-]+)\.$]],
        { E.gain("blackout"), E.lose("blackout", opponent.BLACKOUT_ECLIPSE) } },
    { [[^A flare of (?:sun|moon)light streaks forward, but ([\w'\-]+) ducks out of the way\.$]],
        -- bound and transfixation are inferred (they hold the target in place like webbed); not tested yet.
        { E.absent("prone"), E.absent("webbed"), E.absent("bound"), E.absent("transfixation") } },
    { [[^Blood sprays forth as the thorn-laden vine rips a deep wound in ([\w'\-]+)'s throat\.$]],
        { E.gain("laceratedthroat") } },
    { [[^Lunging forward with one palm outstretched and a singular purpose in mind, you strike a blow to ([\w'\-]+)'s heart\. Willing Nature's ire into [\w'\-]+ very soul, a warm pulse accompanies your attack as it connects\.$]],
        { E.gain("heartseed") } },
    { [[^Uttering a quiet recitation, you gesture towards ([\w'\-]+)\. A mass of writhing vines burst forth from the ground, grabbing hold of [\w'\-]+ form\.$]],
        { E.gain("vinewreathed"), E.lose("vinewreathed", opponent.VINEWREATHE) } },
    { [[^The vines flailing about ([\w'\-]+)'s form recede\.$]],
        { E.lose("vinewreathed") } },
}
for _, entry in ipairs(SPELLS) do
    opponent.onLine(entry[1], entry[2])
end

-- The progression spells: the follow-up names the step, and proves every step below it.
-- Only right after our own cast: the same lines come from anyone's hailstone or waterspout.
local LADDERS = {
    hailstone = { "clumsiness", "epilepsy", "impatience" },
    waterspout = { "confusion", "dizziness", "vertigo" },
}
addTrigger([[^Channeling power through your water channel, you conjure forth a hailstone to strike ([\w'\-]+) in the side of the head\.$]], function()
    opponent.offense.spell = "hailstone"
end, { type = "regex" })
addTrigger([[^You summon forth a spout of water, directing it at ([\w'\-]+)\.$]], function()
    opponent.offense.spell = "waterspout"
end, { type = "regex" })
opponent.host.onPrompt("sylvan spell", function()
    opponent.offense.spell = nil
end)

local FOLLOWUPS = {
    { [[^([\w'\-]+) stumbles clumsily as the blow lands\.$]], "hailstone", 1 },
    { [[^([\w'\-]+) begins to shake uncontrollably\.$]], "hailstone", 2 },
    { [[^A puzzled expression crosses the face of ([\w'\-]+)\.$]], "hailstone", 3 },
    { [[^([\w'\-]+) begins to thrash at the water enveloping [\w'\-]+\.$]], "waterspout", 1 },
    { [[^([\w'\-]+) begins to sway unsteadily\.$]], "waterspout", 2 },
    { [[^A look of panic comes over the face of ([\w'\-]+)\.$]], "waterspout", 3 },
}
for _, entry in ipairs(FOLLOWUPS) do
    local spell, step = entry[2], entry[3]
    addTrigger(entry[1], function(_, _, w)
        if opponent.offense.spell ~= spell or not opponent.isTracked(w[1]) then
            return
        end
        for i = 1, step - 1 do
            opponent.record(w[1], { kind = "proof", aff = LADDERS[spell][i], present = true })
        end
    end, { type = "regex" })
end

addTrigger([[^Raising your hands above your head, you channel power through your earth and air channels\. Focusing upon ([\w'\-]+), you direct your arcane might in a focused burst, bringing down lightning to smite [\w'\-]+\.$]], function(_, _, w)
    local name = w[1]
    local hp = opponent.healthPercent(name)
    if not opponent.isTracked(name) or not hp or hp >= 75 then
        return
    end
    opponent.record(name, { kind = "gain", aff = "blackout" })
    opponent.recordExpiry(name, "blackout", opponent.BLACKOUT_BOLT)
end, { type = "regex" })