local opponent = Opponent
local Q = opponent.Queries

-- Plain questions about the current target (or a named one), for writing offense steps.
opponent.target = opponent.target or {}
local T = opponent.target

local function tracked(name)
  name = opponent.nameOrTarget(name)
  return name and opponent.find(name)
end

function T.prob(aff, name)
  local target = tracked(name)
  return target and Q.prob(target, aff) or 0
end

-- Likely enough to act on: Queries.HAS (0.7) unless you ask for more or less.
function T.has(aff, minProb, name)
  return T.prob(aff, name) >= (minProb or Q.HAS)
end

-- 0 healthy, 1 broken, 2 damaged (mildtrauma), 3 mangled (serioustrauma): the worst likely level.
function T.limbLevel(limb, name)
  local target = tracked(name)
  if not target then return 0 end
  local level = 0
  for i, aff in ipairs(opponent.LIMB_RULES.ladder(opponent.LIMB_RULES.key(limb))) do
    if Q.has(target, aff) then level = i end
  end
  return level
end
function T.isBroken(limb, name) return T.limbLevel(limb, name) >= 1 end
function T.isDamaged(limb, name) return T.limbLevel(limb, name) >= 2 end
function T.isMangled(limb, name) return T.limbLevel(limb, name) >= 3 end

-- The next hit steps the limb. hit: the damage you're about to do; without it, the last hit's size.
function T.isPrepped(limb, hit, name)
  local target = tracked(name)
  if not target then return false end
  local damage, hits = Q.limb(target, opponent.LIMB_RULES.key(limb), opponent.host.now())
  if hit then return damage + hit >= Q.LIMB.BREAK end
  return hits == 1
end

-- Up as far as we know: the defence flags, and rebounding as the HUD marker assumes it.
function T.hasDef(def, name)
  local target = tracked(name)
  if not target then return false end
  if def == "rebounding" then return opponent.defenceView(target.name).rebounding == "up" end
  return target[def] == def
end

function T.class(name)
  local target = tracked(name)
  return target and target.class
end

-- A parried limb stays avoided until a hit lands on it, or this many seconds pass (they may switch).
opponent.PARRY_MEMORY = 15

function T.parried(limb, name)
  local target = tracked(name)
  local at = target and target.parried and target.parried[opponent.LIMB_RULES.key(limb)]
  return at ~= nil and opponent.host.now() - at <= opponent.PARRY_MEMORY
end

-- The next limb to work on, from candidates in preference order ({ "rl", "ll" }): skip any already
-- prepped or broken, skip any parried lately, and take the one closest to prepped (ties go to the
-- earlier one). Returns nil, "parried" when parrying is all that's in the way; nil when all are done.
function T.nextLimb(candidates, name)
  local target = tracked(name)
  local now = opponent.host.now()
  local best, bestDamage, blocked = nil, -1, false
  for _, limb in ipairs(candidates) do
    local key = opponent.LIMB_RULES.key(limb)
    if not T.isPrepped(key, nil, name) and not T.isBroken(key, name) then
      if T.parried(key, name) then
        blocked = true
      else
        local damage = target and Q.limb(target, key, now) or 0
        if damage > bestDamage then best, bestDamage = key, damage end
      end
    end
  end
  if best then return best end
  return nil, blocked and "parried" or nil
end