-- Shared limb prep/break tracking for PK strategies that bait restorations by
-- priming multiple limbs toward "next hit breaks it" (heartseed, rockboy, etc.)
PkCore.limbPrep = PkCore.limbPrep or {}

-- Would the next hit of `damagePerHit` push this limb's AK-tracked damage over 100?
function PkCore.limbPrep.ready(key, damagePerHit)
  local target = PkCore.room.targetName()
  if not target then return false end
  local current = ak.limbs.limbcount[target] and ak.limbs.limbcount[target][key]
  if not current then return false end
  return current + damagePerHit >= 100
end

-- Has this limb actually broken? torso/head break at 100, arms/legs at 200.
-- arms/legs at 200 are specific to how ak tracks, not that it needs 200% limb damage.
function PkCore.limbPrep.broken(key)
  local threshold = (key == "torso" or key == "head") and 100 or 200
  return (affstrack.score[key] or 0) >= threshold
end

-- First limb in the list ready to break right now.
function PkCore.limbPrep.readyAmong(keys, damagePerHit)
  for _, key in ipairs(keys) do
    if PkCore.limbPrep.ready(key, damagePerHit) then return key end
  end
  return nil
end

-- Are every one of the given limbs already primed (ready, or already broken)?
function PkCore.limbPrep.allPrimed(keys, damagePerHit)
  for _, key in ipairs(keys) do
    if not (PkCore.limbPrep.ready(key, damagePerHit) or PkCore.limbPrep.broken(key)) then
      return false
    end
  end
  return true
end

-- First limb in the list that still needs more prep hits.
function PkCore.limbPrep.nextUnprepared(keys, damagePerHit)
  for _, key in ipairs(keys) do
    if not (PkCore.limbPrep.ready(key, damagePerHit) or PkCore.limbPrep.broken(key)) then
      return key
    end
  end
  return nil
end