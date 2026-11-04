PkCore.limbs = PkCore.limbs or {}
local limbs = PkCore.limbs
limbs.self = limbs.self or {}

-- The game's limb rules, the same file the opponent tracker uses.
local RULES = loadModule("opponent/limb_rules.lua")
limbs.PREDICT_AFTER = 0.5
-- The torso's first step in the game is mild trauma; the shared ladder starts with a broken torso.
local function gameLadder(limb)
  local ladder = RULES.ladder(limb)
  if limb == "torso" then table.remove(ladder, 1) end
  return ladder
end

function limbs.crossed(limb)
  local ladder, level = gameLadder(limb), 0
  for i, aff in ipairs(ladder) do
    if PkCore.afflictions.has(aff) then level = i end
  end
  local expected = ladder[level + 1]
  if not expected then return end
  setTimeout(function()
    if PkCore.afflictions.has(expected) then return end
    send("curing predict " .. expected)
    PkCore.note("predicted " .. expected .. ": " .. limb .. " past 100% with no affliction shown")
  end, limbs.PREDICT_AFTER * 1000)
end

-- One hit on us; at 100 the game steps the limb (GMCP shows it) and the extra is lost.
function limbs.hit(limb, amount, now)
  local entry = limbs.self[limb] or { damage = 0 }
  if entry.at and now - entry.at > RULES.DECAY then entry.damage = 0 end
  entry.damage = entry.damage + amount
  entry.lastHit = amount
  entry.at = now
  if entry.damage >= RULES.BREAK then
    entry.damage = 0
    limbs.crossed(limb)
  end
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