local S = PkCore.sylvanPk
local C = S.config
local T = Opponent.target
local RULES = Opponent.LIMB_RULES

local WORDS = {}
for words, key in pairs(RULES.WORDS) do WORDS[key] = words end

-- Named conditions, so each action reads like the plan.
local function torsoReady() return T.isPrepped("torso") end
local function torsoTrauma() return T.isDamaged("torso") end
local function salveOn(spot) return T.has("restoring." .. spot, 0.5) end
local function heartseedActive()
  return S.heartseedAt ~= nil and PkCore.now() - S.heartseedAt <= S.KILL_WINDOW and T.has("heartseed", 0.5)
end
local function baitPrimed()
  local count = 0
  for _, limb in ipairs(C.bait) do
    if T.isPrepped(limb) or T.isBroken(limb) then count = count + 1 end
  end
  return count >= C.baitCount
end
local function preppedBait()
  for _, limb in ipairs(C.bait) do
    if T.isPrepped(limb) and not T.isBroken(limb) then return RULES.key(limb) end
  end
end
local function beingParried()
  if T.parried("torso") then return true end
  local _, why = T.nextLimb(C.bait)
  return why == "parried"
end

-- A hit that will step the limb carries gecko (slickness keeps the restoration off). Leg rends add the
-- free quarterstaff swing, which prones them if that leg is broken.
local function rend(limb)
  local key, target = RULES.key(limb), PkCore.room.targetName()
  local venom = T.isPrepped(key) and "gecko" or C.venom
  local command = "thornrend " .. target .. " " .. venom .. " " .. WORDS[key] .. " " .. C.plant
  if key == "leftleg" or key == "rightleg" then command = command .. "|swing quarterstaff " .. target end
  return command
end
local function heartseed() return "heartseed " .. PkCore.room.targetName() end

S.actions = {
  vinewreathe = {
    why = "being parried: vinewreathe",
    can = function() return beingParried() and not T.has("vinewreathed") end,
    build = function() return "vinewreathe " .. PkCore.room.targetName() end,
  },
  steal_body_restoration = {
    why = "heartseed up and they're restoring the body: hit the prepped torso",
    can = function() return heartseedActive() and salveOn("body") and torsoReady() end,
    build = function() return rend("torso") end,
  },
  prep_torso = {
    why = "torso isn't prepped yet",
    can = function() return not torsoReady() and not torsoTrauma() end,
    build = function() return rend("torso") end,
  },
  wait_heartseed = {
    why = "heartseed up, torso prepped: waiting for their restoration",
    can = heartseedActive,
    build = function() return nil end,
  },
  prep_bait = {
    why = "prepping a bait limb",
    can = function() return not baitPrimed() and T.nextLimb(C.bait) ~= nil end,
    build = function() return rend(T.nextLimb(C.bait)) end,
  },
  heartseed_on_limb_salve = {
    why = "their salve is busy on a limb: heartseed",
    can = function() return salveOn("legs") or salveOn("arms") end,
    build = heartseed,
    fired = S.heartseedCast,
  },
  heartseed_now = {
    why = "torso already in trauma, or salve blocked: heartseed",
    can = function() return torsoTrauma() or C.salveBlocked end,
    build = heartseed,
    fired = S.heartseedCast,
  },
  break_bait = {
    why = "break a prepped bait limb to draw a restoration",
    can = function() return preppedBait() ~= nil end,
    build = function() return rend(preppedBait()) end,
  },
  wait_restoration = {
    why = "everything prepped: waiting for them to apply restoration",
    can = function() return true end,
    build = function() return nil end,
  },
}