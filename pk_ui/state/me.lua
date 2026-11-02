PkCore.me = PkCore.me or {}
local me = PkCore.me
local RULES = loadModule("opponent/limb_rules.lua")

-- The same questions as Opponent.target, about ourselves.
function me.has(aff) return PkCore.afflictions.has(aff) end

function me.limbLevel(limb)
  local level = 0
  for i, aff in ipairs(RULES.ladder(RULES.key(limb))) do
    if PkCore.afflictions.has(aff) then level = i end
  end
  return level
end
function me.isBroken(limb) return me.limbLevel(limb) >= 1 end
function me.isDamaged(limb) return me.limbLevel(limb) >= 2 end
function me.isMangled(limb) return me.limbLevel(limb) >= 3 end

-- The next hit steps our limb. hit: the size you expect; without it, the last hit's size.
function me.isPrepped(limb, hit)
  local entry = PkCore.limbs.self[RULES.key(limb)]
  if not entry or PkCore.now() - entry.at > RULES.DECAY then return false end
  local size = hit or entry.lastHit
  return size ~= nil and size > 0 and entry.damage + size >= RULES.BREAK
end

function me.hasDef(def) return PkCore.defences.have[def] == true end
function me.ready(balance) return PkCore.balances.isReady(balance) end