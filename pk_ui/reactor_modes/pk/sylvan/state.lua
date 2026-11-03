PkCore.sylvanPk = PkCore.sylvanPk or {}
local S = PkCore.sylvanPk

-- Settings that last between fights.
S.config = S.config or {
  venom = "prefarar",        -- on every rend that won't step the limb
  plant = "bloodroot",       -- named in every thornrend
  bait = { "rl", "ll" },     -- limbs we may prep to bait a restoration, in preference order
  baitCount = 1,             -- how many must be prepped (or broken) before heartseed
  salveBlocked = false,      -- heartseed without waiting for their salve
}
local C = S.config
S.KILL_WINDOW = 12

-- Per-fight memory, wiped whenever the fight starts over.
function S.reset()
  S.heartseedAt = nil
end

-- The tracker replaces a target's table on a new target, a death, or a return from out of sight:
-- any of those starts the fight over.
function S.check()
  local name = PkCore.room.targetName()
  local ref = name and Opponent.find(name) or nil
  if ref ~= S.targetRef then
    S.targetRef = ref
    S.reset()
  end
end

registerCommand("hs", function(args)
  local key, rest = args:match("^(%a*)%s*(.-)%s*$")
  if key == "venom" or key == "plant" then
    C[key] = rest
  elseif key == "bait" then
    local list = {}
    for limb in rest:gmatch("%a+") do list[#list + 1] = limb end
    if #list > 0 then C.bait = list end
  elseif key == "baitcount" then
    C.baitCount = tonumber(rest) or C.baitCount
  elseif key == "salveblocked" then
    C.salveBlocked = rest == "on"
  elseif key ~= "" then
    return "usage: hs venom <venom> | plant <plant> | bait <limbs> | baitcount <n> | salveblocked on|off"
  end
  return string.format("heartseed: venom %s, plant %s, bait %s (need %d), salveblocked %s",
    C.venom, C.plant, table.concat(C.bait, " "), C.baitCount, tostring(C.salveBlocked))
end, "Heartseed route settings")

-- Momentum route: the setup overcharge leaves them dizzy (herbs busy on asthma and weariness, focus on
-- confusion), so the strike's cyclone lands impatience with paralysis and asthma; the seal then holds.
S.momentum = {
  setup = { "waterspout", "cyclone" },    -- confusion, dizziness, weariness, asthma
  strike = { "thunderclap", "cyclone" },  -- on the dizzy target: sensitivity, impatience, paralysis, asthma
  build = { "cyclone", "hailstone" },
  holdBuild = { "razorwind", "hailstone" },  -- while the lock holds: kelp afflictions they can't eat off
  setupAt = 60,                           -- a full bar: the setup and strike (38) leave 22 to build on
  fitnessCooldown = 9.4,                  -- seconds between their fitnesses (Grulk: 9.4 to 10)
  strikeWindow = 2.5,                     -- the setup still counts this long after it went off
  limbs = { "torso", "ll", "rl" },        -- where the rends go
}
-- Shockwave dumps all stored AE (40 at least) for damage, more with the kelp afflictions on them.
S.shockwave = {
  minAE = 40,
  -- HELP SHOCKWAVE: "one or more" of these makes it hit harder. With 40 AE, shockwave instead of a setup.
  vulnerable = { "healthleech", "impatience", "dizziness", "epilepsy" },
  vulnerableNeeded = 1,
}

local ELEMENT = {
  static = "lightning", thunderclap = "lightning", bolt = "lightning",
  razorwind = "wind", cyclone = "wind",
  hailstone = "water", waterspout = "water",
}
-- From the AE lines in our logs; HELP says 13 for wind, but every cyclone and razorwind cost 5.
local ELEMENT_COST = { lightning = 15, wind = 5, water = 13 }

function S.cost(pair)
  return ELEMENT_COST[ELEMENT[pair[1]]] + ELEMENT_COST[ELEMENT[pair[2]]]
end

-- Arcane energy lives in the room's disturbance and is built through the feedback conduit: leaving
-- the room leaves it behind, and a new disturbance or a new feedback target starts it from 0.
S.weather = S.weather or {}
function S.here()
  local room = PkCore.room.number
  if room == nil then return { disturbed = false, ae = 0 } end
  local key = tostring(room)
  S.weather[key] = S.weather[key] or { disturbed = false, ae = 0 }
  return S.weather[key]
end
function S.ae() return S.here().ae end

local function weatherLine(pattern, fn)
  addTrigger(pattern, function(_, _, w)
    fn(S.here(), w)
    PkCore.stateChanged()
  end, { type = "regex" })
end
local function calm(room) room.disturbed, room.feedback, room.ae = false, nil, 0 end

weatherLine([[^Clouds boil into existence above you, their dark mass seething\.$]], function(room) room.disturbed = true end)
weatherLine([[^The weather here has already been disturbed by a practitioner of your craft\.$]], function(room) room.disturbed = true end)
weatherLine([[^The clouds overhead abruptly wink out of existence\.$]], calm)
weatherLine([[^The weather here is not disturbed - you cannot redirect the feedback of your spells\.$]], calm)
weatherLine([[^Directing a sliver of power through your air and earth channels, you create a conduit between the clouds above and ([\w'\-]+)\.]],
  function(room, w) room.disturbed, room.feedback = true, w[1] end)

weatherLine([[^You have built up insufficient energy to overcharge those spells\.$]], function(room) room.ae = 0 end)
-- An overcharged waterspout only comes from the setup.
weatherLine([[^You have (\d+) units of arcane energy (stored|built up)\.]], function(room, w)
  room.ae = tonumber(w[1])
  if w[2] == "stored" and Opponent.offense.spell == "waterspout" then S.setupAt = PkCore.now() end
end)

-- FSW: shockwave on our next attack, whatever the route says. Cleared when it goes off, or after 10s.
S.FORCE_WINDOW = 10
addTrigger([[^Gathering all of your stored power, you direct a cataclysmic burst of arcane might directly at ]], function()
  S.forceShockwaveAt = nil
end, { type = "regex" })
registerCommand("fsw", function()
  if S.ae() < S.shockwave.minAE then
    return "fsw: only " .. tostring(S.ae()) .. " AE, shockwave needs " .. S.shockwave.minAE
  end
  S.forceShockwaveAt = PkCore.now()
  PkCore.stateChanged()
  return "shockwave on the next attack (" .. tostring(S.ae()) .. " AE)"
end, "Force a shockwave on the next attack")

-- Starts the kill window; the offense parser records the affliction
addTrigger([[^Lunging forward with one palm outstretched and a singular purpose in mind, you strike a blow to ]], function()
  S.heartseedAt = PkCore.now()
end, { type = "regex" })

addTrigger([[^You must be outdoors in order to call upon the might of the Viridian\.$]], function()
  S.indoors = PkCore.room.number
  PkCore.stateChanged()
end, { type = "regex" })
