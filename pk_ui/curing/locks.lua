PkCore.locks = PkCore.locks or {}
local locks = PkCore.locks

-- Lock pressure: three or more of these at once (Grulk's numbers).
locks.AFFS = { "paralysis", "slickness", "asthma", "anorexia", "impatience", "weariness" }
locks.PRESSURE = 3

-- Under pressure, cure the affliction that blocks a cure we're about to have. The first rule that fits wins.
local RULES = {
  { has = { "impatience", "anorexia" }, without = "slickness", ready = "salve", cure = "anorexia",
    why = "salve ready, can't eat or focus" },
  { has = { "asthma", "slickness" }, ready = "pipe", cure = "asthma",
    why = "pipe ready, asthma stops smoking" },
  { has = { "slickness", "anorexia" }, ready = "salve", cure = "slickness",
    why = "salve ready, slickness stops applying" },
  { has = { "anorexia", "asthma" }, without = "slickness", ready = "salve", cure = "anorexia",
    why = "salve ready, clears the way to eat" },
  { has = { "weariness", "asthma" }, ready = "fitness", cure = "weariness",
    why = "fitness ready, weariness stops it" },
}

-- Fitness only counts for classes that have it (the opponent package's class cure list).
local function canUse(balance)
  if balance == "fitness" then
    local fitness = Opponent and Opponent.classCures and Opponent.classCures.active.fitness
    local mine, known = PkCore.defences.classKey(), false
    for _, class in ipairs(fitness and fitness.classes or {}) do
      if class == mine then known = true end
    end
    if not known then return false end
  end
  return PkCore.balances.isReady(balance)
end

local function pressure()
  local count = 0
  for _, aff in ipairs(locks.AFFS) do
    if PkCore.afflictions.has(aff) then count = count + 1 end
  end
  return count
end

local function fits(rule)
  for _, aff in ipairs(rule.has) do
    if not PkCore.afflictions.has(aff) then return false end
  end
  if rule.without and PkCore.afflictions.has(rule.without) then return false end
  return canUse(rule.ready)
end

function locks.choose()
  if pressure() < locks.PRESSURE then return nil end
  for _, rule in ipairs(RULES) do
    if fits(rule) then return rule end
  end
end

function locks.update()
  if not PkCore.config.values.lockPrio then return end
  -- Cured: the server drops the prioaff by itself.
  if locks.current and not PkCore.afflictions.has(locks.current) then locks.current = nil end
  local rule = locks.choose()
  if rule and rule.cure ~= locks.current then
    locks.current = rule.cure
    send("curing prioaff " .. rule.cure)
    PkCore.note("prioaff " .. rule.cure .. " (" .. rule.why .. ")")
  elseif not rule and locks.current and pressure() < locks.PRESSURE then
    locks.current = nil
    send("curing prioaff none")
  end
end

PkCore.onVitalsChanged("locks", locks.update)