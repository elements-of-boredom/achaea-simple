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

-- Heartseed went off: the target now carries it (a body restoration cures it) and the window opens.
function S.heartseedCast()
  local name = PkCore.room.targetName()
  if not name then return end
  S.heartseedAt = PkCore.now()
  Opponent.record(name, { kind = "gain", aff = "heartseed" })
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