local Queries = {}
Queries.LIKELY = 0.7
Queries.SURE = 0.9
Queries.HAS = Queries.LIKELY

-- Chance the target has every affliction in the list at the same time.
function Queries.probAll(target, affs)
  local p = 0
  for _, state in ipairs(target.states) do
    local all = true
    for _, aff in ipairs(affs) do
      if state.affs[aff] == nil then all = false end
    end
    if all then p = p + state.p end
  end
  return p
end

-- Chance the target has at least one affliction in the list.
function Queries.probAny(target, affs)
  local p = 0
  for _, state in ipairs(target.states) do
    local any = false
    for _, aff in ipairs(affs) do
      if state.affs[aff] ~= nil then any = true end
    end
    if any then p = p + state.p end
  end
  return p
end

function Queries.prob(target, aff)
  return Queries.probAll(target, { aff })
end

function Queries.has(target, aff, minProb)
  return Queries.prob(target, aff) >= (minProb or Queries.HAS)
end

-- Every group must be satisfied; a group is satisfied by any one of its afflictions.
function Queries.probGroups(target, groups)
    local p = 0
    for _, state in ipairs(target.states) do
        local all = true
        for _, group in ipairs(groups) do
            local any = false
            for _, aff in ipairs(group) do
                if state.affs[aff] ~= nil then any = true end
            end
            if not any then all = false end
        end
        if all then p = p + state.p end
    end
    return p
end
-- Keeping for mental reference
--Queries.LOCKS = {
--  softlock  = { "anorexia", "asthma", "slickness" },
--  venomlock = { "anorexia", "asthma", "slickness", "paralysis" },
--  hardlock  = { "anorexia", "asthma", "slickness", "paralysis", "impatience" },
--  truelock  = { "anorexia", "asthma", "slickness", "paralysis", "impatience" },
--  riftlock  = { "brokenleftarm", "brokenrightarm", "asthma", "slickness" },
--  aeonlock  = { "aeon", "asthma" },
--}
Queries.LOCKS = {
    softlock  = { "eat", "smoke", "apply" },
    venomlock = { "eat", "smoke", "apply", "tree" },
    hardlock  = { "eat", "smoke", "apply", "tree", "focus" },
    truelock  = { "eat", "smoke", "apply", "tree", "focus" },
    riftlock  = { { "brokenleftarm" }, { "brokenrightarm" }, "smoke", "apply" },
    aeonlock  = { { "aeon" }, "smoke" },
}

-- extra: class-specific afflictions to add, e.g. { "weariness" } against a fitness class.
function Queries.lock(target, name, extra)
    local groups = {}
    for _, slot in ipairs(Queries.LOCKS[name]) do
        groups[#groups + 1] = type(slot) == "string" and Queries.CHANNEL_BLOCKERS[slot] or slot
    end
    for _, aff in ipairs(extra or {}) do
        groups[#groups + 1] = { aff }
    end
    return Queries.probGroups(target, groups)
end

Queries.CHANNEL_BLOCKERS = {
  eat     = { "anorexia" },
  smoke   = { "asthma" },
  apply   = { "slickness" },
  focus   = { "impatience" },
  tree    = { "paralysis" },
  fitness = { "weariness" },
}

-- Chance this cure channel is usable right now.
function Queries.channelOpen(target, channel)
  return 1 - Queries.probAny(target, Queries.CHANNEL_BLOCKERS[channel])
end

-- Every affliction in any state with its chance, highest first. For display.
function Queries.sorted(target)
  local probs = {}
  for _, state in ipairs(target.states) do
    for aff, value in pairs(state.affs) do
      if value then probs[aff] = (probs[aff] or 0) + state.p end
    end
  end
  local list = {}
  for aff, p in pairs(probs) do list[#list + 1] = { aff = aff, p = p } end
  table.sort(list, function(a, b)
    if a.p ~= b.p then return a.p > b.p end
    return a.aff < b.aff
  end)
  return list
end

return Queries