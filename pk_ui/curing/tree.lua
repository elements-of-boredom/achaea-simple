PkCore.tree = PkCore.tree or {}
local tree = PkCore.tree
local B = PkCore.balances
local function has(aff) return PkCore.afflictions.has(aff) end

local CURES = Opponent.Model.data
local TREE = {}
for _, aff in ipairs(CURES.tree) do TREE[aff] = true end

local function count(list)
  local n = 0
  for _, aff in ipairs(list) do
    if has(aff) then n = n + 1 end
  end
  return n
end

local RULES = Opponent.LIMB_RULES
-- One more hit the size of the last one breaks it.
local function nearBreak(limb)
  local entry = PkCore.limbs.self[limb]
  if not entry or PkCore.now() - entry.at > RULES.DECAY then return false end
  return entry.damage + math.max(entry.lastHit or 0, 24) >= RULES.BREAK
end
local function armOut(side)
  return has("broken" .. side .. "arm") or has("damaged" .. side .. "arm") or has("mangled" .. side .. "arm")
end
local function armGoing(side)
  return armOut(side) or nearBreak(side .. "arm")
end

local function treeCurable()
  local n = 0
  for aff in pairs(PkCore.afflictions.list) do
    if TREE[aff] then n = n + 1 end
  end
  return n
end

local LOCK = { "anorexia", "asthma", "slickness", "impatience" }
local LIMBS = { "brokenleftarm", "brokenrightarm", "brokenleftleg", "brokenrightleg" }
local function sameHerbTwice()
  for _, affs in pairs(CURES.eat) do
    if count(affs) >= 2 then return true end
  end
  return false
end
tree.STALE = 20

-- Each lock affliction shuts a cure channel; whatever waits on that channel can only go to tree.
local function flatten(sets)
  local list = {}
  for _, entry in pairs(sets) do
    if type(entry) == "table" then
      for _, aff in ipairs(entry) do list[#list + 1] = aff end
    else
      list[#list + 1] = entry
    end
  end
  return list
end
local CHANNELS = {
  { blocker = "anorexia", affs = flatten(CURES.eat) },
  { blocker = "asthma", affs = flatten(CURES.smoke) },
  { blocker = "slickness", affs = flatten(CURES.apply) },
  { blocker = "impatience", affs = CURES.focus },
}
local function channelBlocked()
  for _, channel in ipairs(CHANNELS) do
    if has(channel.blocker) then
      for _, aff in ipairs(channel.affs) do
        if aff ~= channel.blocker and TREE[aff] and has(aff) then return true end
      end
    end
  end
  return false
end


local DRAINS = { "voyria", "haemophilia", "healthleech", "burning" }
tree.LOW_HEALTH = 0.4
local function lowHealth()
  local hp, max = PkCore.vitals.hp, PkCore.vitals.maxhp
  return hp and max and max > 0 and hp / max < tree.LOW_HEALTH
end

local REASONS = {
  { "lock", function() return count(LOCK) >= 3 end },
  { "riftlock coming", function()
      return has("slickness") and armGoing("left") and armGoing("right")
    end },
  { "draining", function() return lowHealth() and count(DRAINS) > 0 end },
  { "nearly locked", function() return has("anorexia") and has("slickness") and not B.isReady("smoke") end },
  { "blocked channel", channelBlocked },
  { "aeon", function() return has("aeon") and (has("asthma") or not B.isReady("smoke")) end },
  { "same herb twice", function() return not B.isReady("herb") and sameHerbTwice() end },
  { "broken limbs", function() return not B.isReady("salve") and count(LIMBS) >= 2 end },
  { "swamped", function() return treeCurable() >= 5 end },
  { "unused", function() return (tree.readyFor() or 0) >= tree.STALE and treeCurable() >= 2 end },
}

local RESEND = 1
function tree.readyFor()
  local up = B.elapsed("tree")
  return up and up - B.expectedFor("tree") or nil
end

function tree.update()
  if not PkCore.config.values.treeAssist then return end
  if not B.isReady("tree") or has("paralysis") or PkCore.afflictions.armsDamaged() or treeCurable() == 0 then return end
  local now = PkCore.now()
  if now - (tree.sentAt or 0) < RESEND then return end
  for _, reason in ipairs(REASONS) do
    if reason[2]() then
      tree.sentAt = now
      send("touch tree")
      PkCore.note("tree (" .. reason[1] .. ")")
      return
    end
  end
end

PkCore.onVitalsChanged("tree", tree.update)

-- Only one of us touches tree: the server's own tree use goes off while we handle it, and back on when we don't.
function tree.syncServer()
  send("curing tree " .. (PkCore.config.values.treeAssist and "off" or "on"))
end
PkCore.config.onChange("treeAssist", tree.syncServer)
onGMCPUpdate("Char.Name", tree.syncServer)
tree.syncServer()