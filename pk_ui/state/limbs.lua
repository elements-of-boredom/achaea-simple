PkCore.limbs = PkCore.limbs or {}
local limbs = PkCore.limbs
limbs.self = limbs.self or {}

-- The game's limb rules, the same file the opponent tracker uses.
local RULES = loadModule("opponent/limb_rules.lua")

-- One hit on us; at 100 the game steps the limb (GMCP shows it) and the extra is lost.
function limbs.hit(limb, amount, now)
  local entry = limbs.self[limb] or { damage = 0 }
  if entry.at and now - entry.at > RULES.DECAY then entry.damage = 0 end
  entry.damage = entry.damage + amount
  entry.lastHit = amount
  entry.at = now
  if entry.damage >= RULES.BREAK then entry.damage = 0 end
  limbs.self[limb] = entry
end

-- The same shape as opponent.limbView, so ui/limbs.lua draws both rows the same way.
function limbs.selfView()
  local now, view = PkCore.now(), {}
  for _, limb in pairs(RULES.WORDS) do
    local cell, entry = { damage = 0 }, limbs.self[limb]
    if entry and now - entry.at <= RULES.DECAY then
      cell.damage = entry.damage
      cell.hits = entry.lastHit > 0 and math.ceil((RULES.BREAK - entry.damage) / entry.lastHit) or nil
    end
    for level, aff in ipairs(RULES.ladder(limb)) do
      if PkCore.afflictions.has(aff) then cell.level = level end
    end
    view[limb] = cell
  end
  return view
end

addTrigger([[^.+, you perceive that [\w'\-]+ has dealt ([\d.]+)% damage to your (.+)\.$]], function(_, _, w)
  local limb = RULES.WORDS[w[2]]
  if not limb then return end
  limbs.hit(limb, tonumber(w[1]), PkCore.now())
  PkCore.stateChanged()
end, { type = "regex" })