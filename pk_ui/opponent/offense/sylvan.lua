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
  kola       = { gives = "sleeping", strips = "insomnia" },
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