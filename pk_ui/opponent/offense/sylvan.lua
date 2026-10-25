local opponent = PkCore.opponent

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
    PkCore.note("arms: " .. tostring(opponent.offense.arms))
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
        PkCore.note("unknown arms plant: " .. w[1])
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
PkCore.onVitalsChanged("sylvan venom", function()
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
            PkCore.note("unknown venom: " .. venom)
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