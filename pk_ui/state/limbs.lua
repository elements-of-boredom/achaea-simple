PkCore.limbs = PkCore.limbs or {}
local limbs = PkCore.limbs
limbs.self = limbs.self or {}

-- Game limb words to keys: "left leg" -> "leftleg". The opponent tracker uses these too.
limbs.WORDS = {
  ["left leg"] = "leftleg", ["right leg"] = "rightleg",
  ["left arm"] = "leftarm", ["right arm"] = "rightarm",
  head = "head", torso = "torso",
}
-- The same rules as the opponent model (model.lua keeps its own copy so it loads without PkCore).
limbs.BREAK = 100
limbs.DECAY = 180
local STEPS = { head = { "damagedhead", "mangledhead" }, torso = { "mildtrauma", "serioustrauma" } }

local function ladderOf(limb)
  local steps = STEPS[limb] or { "damaged" .. limb, "mangled" .. limb }
  return { "broken" .. limb, steps[1], steps[2] }
end

-- One hit on us; at 100 the game steps the limb (GMCP shows it) and the extra is lost.
function limbs.hit(limb, amount, now)
  local entry = limbs.self[limb] or { damage = 0 }
  if entry.at and now - entry.at > limbs.DECAY then entry.damage = 0 end
  entry.damage = entry.damage + amount
  entry.lastHit = amount
  entry.at = now
  if entry.damage >= limbs.BREAK then entry.damage = 0 end
  limbs.self[limb] = entry
end

-- The same shape as opponent.limbView, so ui/limbs.lua draws both rows the same way.
function limbs.selfView()
  local now, view = PkCore.now(), {}
  for _, limb in pairs(limbs.WORDS) do
    local cell, entry = { damage = 0 }, limbs.self[limb]
    if entry and now - entry.at <= limbs.DECAY then
      cell.damage = entry.damage
      cell.hits = entry.lastHit > 0 and math.ceil((limbs.BREAK - entry.damage) / entry.lastHit) or nil
    end
    for level, aff in ipairs(ladderOf(limb)) do
      if PkCore.afflictions.has(aff) then cell.level = level end
    end
    view[limb] = cell
  end
  return view
end

addTrigger([[^.+, you perceive that [\w'\-]+ has dealt ([\d.]+)% damage to your (.+)\.$]], function(_, _, w)
  local limb = limbs.WORDS[w[2]]
  if not limb then return end
  limbs.hit(limb, tonumber(w[1]), PkCore.now())
  PkCore.stateChanged()
end, { type = "regex" })