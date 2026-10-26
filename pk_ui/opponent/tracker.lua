Opponent = Opponent or {}
local opponent = Opponent

-- What the package needs from the plugin it runs in. A host sets Opponent.host before loading this
-- file; anything it leaves out falls back to these, which work in any MudForge plugin.
local DEFAULT_HOST = {
    now = function() return getCurrentTime() / 1000 end,              -- the time, in seconds
    note = function(text) cecho("<cyan>[opponent]<reset> " .. tostring(text)) end,
    changed = function() end,                                         -- redraw, if there's a UI
    target = function() return nil end,                               -- current target's name
    targetHealth = function() return nil end,                         -- its health %, if known
    onPrompt = function(name, fn) onGMCPUpdate("Char.Vitals", function() fn() end) end,
}
opponent.host = opponent.host or {}
for key, fn in pairs(DEFAULT_HOST) do
    if opponent.host[key] == nil then
        opponent.host[key] = fn
    end
end

opponent.Model = loadModule("opponent/model.lua")
opponent.Queries = loadModule("opponent/queries.lua")
opponent.Model.load(loadModule("opponent/cures.lua"))
opponent.Model.addCure("smoke:skullcap", {"norebounding"})
opponent.Model.addCure("apply:mass", { "nodensity" })
-- A pending restoration ties up the salve channel like slickness (AK's "tempslickness").
for _, marker in pairs(opponent.Model.DELAYED) do
    table.insert(opponent.Queries.BLOCKERS.apply, marker)
end
opponent.RESTORATION_DELAY = 4.0
opponent.SILERIS_DELAY = 9.0
opponent.SENSE_WINDOW = { deaf = { 2.0, 4.2 } }
-- The game's limb rules, shared with our own limb tracking without depending on it.
opponent.LIMB_RULES = loadModule("opponent/limb_rules.lua")
opponent.Model.LIMB = opponent.LIMB_RULES
opponent.Queries.LIMB = opponent.LIMB_RULES
opponent.LIMBS = opponent.LIMB_RULES.WORDS

opponent.classCures = loadModule("opponent/class_cures.lua")
opponent.VENOMS = loadModule("opponent/offense/venoms.lua")

opponent.targets = opponent.targets or {}
opponent.pending = opponent.pending or {}

-- Names are stored lowercase so "Bob" and "bob" are the same target.
function opponent.find(name)
    return opponent.targets[name:lower()]
end

-- Creates the model the first time we need one.
function opponent.get(name)
    local key = name:lower()
    if not opponent.targets[key] then
        opponent.targets[key] = opponent.Model.newTarget(name)
    end
    return opponent.targets[key]
end

-- Who we listen to: anyone we already track, plus the current target.
function opponent.isTracked(name)
    if opponent.find(name) then
        return true
    end
    local current = opponent.host.target()
    return type(current) == "string" and current:lower() == name:lower()
end

-- Tracking/Recording
-- How soon after a cure the same cure balance can be used again, per cure group.
-- A second cure sooner than this is ignored as an illusion; the overdue check waits at least this long.
opponent.GAPS = {
    eat = 1.3,
    smoke = 1.2,
    apply = 0.9,
    focus = 2,
    tree = 12.5
}

opponent.lastCure = opponent.lastCure or {}

-- Triggers only record. Nothing touches the model until the prompt.
function opponent.record(name, event)
    event.name = name
    event.time = opponent.host.now()
    opponent.pending[#opponent.pending + 1] = event
    return event
end

-- The latest pending event of this kind for this name, so a follow-up line can mark it.
function opponent.lastPending(name, kind)
    local key = name:lower()
    for i = #opponent.pending, 1, -1 do
        local event = opponent.pending[i]
        if event.name:lower() == key and event.kind == kind then
            return event
        end
    end
end

-- Illusion/Double eat check: two real cures on one balance can't come closer together than that balance.
function opponent.acceptCure(name, group)
    local key, now, gap = name:lower(), opponent.host.now(), opponent.GAPS[group] or 0
    local last = opponent.lastCure[key] or {}
    if last[group] and now - last[group] < gap then
        opponent.host.note("ignored " .. group .. " from " .. name .. " (too soon, likely an illusion)")
        return false
    end
    last[group] = now
    opponent.lastCure[key] = last
    return true
end

-- A cure through a channel proves the channel wasn't blocked: eating proves no anorexia.
function opponent.channelProof(target, cureKey)
    local channel = cureKey:match("^(%a+)")
    for _, blocker in ipairs(opponent.Queries.BLOCKERS[channel] or {}) do
        opponent.Model.proof(target, blocker, false)
    end
end

function opponent.apply(event)
    if event.kind == "reset" then
        opponent.targets[event.name:lower()] = opponent.Model.newTarget(event.name)
        return
    end
    if event.kind == "gain" then
        local target = opponent.get(event.name)
        if event.chance then
            opponent.Model.gainMaybe(target, event.aff, event.chance)
        else
            opponent.Model.gain(target, event.aff, event.count)
        end
        return
    end
    if event.kind == "lose" then
        if event.expiry and opponent.expiries[event.expiry] ~= event.token then
            return
        end
        opponent.Model.remove(opponent.get(event.name), event.aff)
        return
    end
    if event.kind == "proof" then
        opponent.Model.proof(opponent.get(event.name), event.aff, event.present)
        return
    end
     if event.kind == "notall" then
        opponent.Model.proofNotAll(opponent.get(event.name), event.affs)
        return
    end
    if event.kind == "limbreset" then
        opponent.Model.limbReset(opponent.get(event.name), event.limb)
        return
    end
    if event.kind == "class" then
        local target = opponent.get(event.name)
        local narrowed = {}
        for _, class in ipairs(event.classes) do
            for _, known in ipairs(target.classes or event.classes) do
                if known == class then
                    narrowed[#narrowed + 1] = class
                end
            end
        end
        target.classes = #narrowed > 0 and narrowed or event.classes
        if #target.classes == 1 then
            target.class = target.classes[1]
        end
        return
    end
    if event.kind == "sense" then
        local target = opponent.get(event.name)
        if event.ifUnknown and target[event.sense] ~= "unknown" then
            return
        end
        target[event.sense] = event.value
        return
    end
     if event.kind == "attack" then
        if event.missed or not event.confirmed then
            return
        end
        local target = opponent.get(event.name)
        for _, entry in ipairs(event.deliveries) do
            opponent.Model.deliver(target, entry)
        end
        if event.limb and event.damage then
            opponent.Model.limbDamage(target, opponent.LIMBS[event.limb] or event.limb, event.damage, event.time)
        end
        return
    end
    if event.kind == "land" then
        opponent.Model.land(opponent.get(event.name), event.key)
        return
    end
    if event.kind == "classcure" then
        local entry = opponent.classCures.active[event.cure] or opponent.classCures.passive[event.cure]
        if not entry then
            return
        end
        local target = opponent.get(event.name)
        for _, group in ipairs(entry.blockers or {}) do
            if #group == 1 then
                opponent.Model.proof(target, group[1], false)
            else
                opponent.Model.proofNotAll(target, group)
            end
        end
        if entry.cures == "all" then
            target.states = { { p = 1, affs = {} } }
        elseif entry.only then
            for _, aff in ipairs(entry.only) do
                opponent.Model.removeOne(target, aff)
            end
        elseif entry.cures then
            opponent.Model.cureRandom(target, entry.cures, entry.pool, entry.first)
        end
        if #entry.classes == 1 then
            target.class = entry.classes[1]
        end
        return
    end
    local target = opponent.get(event.name)
    if event.kind == "cure" then
        opponent.channelProof(target, event.cure)
        if event.sense then
            local window = opponent.SENSE_WINDOW[event.sense]
            if window then
                target[event.sense] = "no"
                opponent.record(event.name, { kind = "sense", sense = event.sense, value = "unknown", due = event.time + window[1] })
                opponent.record(event.name, { kind = "sense", sense = event.sense, value = event.sense, due = event.time + window[2], ifUnknown = true })
            else
                target[event.sense] = event.sense
            end
        elseif event.announced then
            opponent.Model.proof(target, event.announced, true)
            opponent.Model.removeOne(target, event.announced)
        elseif event.keys then
            opponent.Model.cureUnknown(target, event.keys)
            for _, key in ipairs(event.keys) do
                if opponent.Model.DELAYED[key] then
                    opponent.record(event.name, { kind = "land", key = key, due = event.time + opponent.RESTORATION_DELAY })
                end
            end
        else
            opponent.Model.cure(target, event.cure)
        end
    end
end

function opponent.flush(dueOnly)
    if #opponent.pending == 0 then
        return
    end
    local events, now, applied = opponent.pending, opponent.host.now(), false
    opponent.pending = {}
    for _, event in ipairs(events) do
        if (event.due and event.due > now) or (dueOnly and not event.due) then
            opponent.pending[#opponent.pending + 1] = event
        else
            opponent.apply(event)
            applied = true
        end
    end
    if applied then
       opponent.host.changed()
    end
end

-- The name given, or the current target.
function opponent.nameOrTarget(name)
    if type(name) == "string" and name ~= "" then
        return name
    end
    local current = opponent.host.target()
    if type(current) == "string" and current ~= "" then
        return current
    end
end

function opponent.reset(name)
    if name == "all" then
        opponent.targets = {}
        opponent.host.note("opponent: reset everyone")
    else
        name = opponent.nameOrTarget(name)
        if not name then
            opponent.host.note("opponent: no target to reset")
            return
        end
        opponent.apply({
            kind = "reset",
            name = name
        })
        opponent.host.note("opponent: reset " .. name)
    end
   opponent.host.changed()
end

function opponent.resetLimb(name, limb)
    name = opponent.nameOrTarget(name)
    if not name or not limb then
        return
    end
    opponent.apply({ kind = "limbreset", name = name, limb = limb })
   opponent.host.changed()
end

opponent.events = {
    gain = function(aff, chance) return { kind = "gain", aff = aff, chance = chance } end,
    lose = function(aff, delay) return { kind = "lose", aff = aff, delay = delay } end,
    present = function(aff) return { kind = "proof", aff = aff, present = true } end,
    absent = function(aff) return { kind = "proof", aff = aff, present = false } end,
    sense = function(sense, value, delay) return { kind = "sense", sense = sense, value = value, delay = delay } end,
    notall = function(affs) return { kind = "notall", affs = affs } end,
    class = function(classes) return { kind = "class", classes = classes } end,
}

function opponent.onLine(pattern, events, who)
    addTrigger(pattern, function(_, _, w)
        local name = (w and w[who or 1]) or opponent.nameOrTarget()
        if not name or not opponent.isTracked(name) then
            return
        end
        for _, template in ipairs(events) do
            if template.delay and template.kind == "lose" then
                opponent.recordExpiry(name, template.aff, template.delay)
            else
                local event = {}
                for key, value in pairs(template) do
                    event[key] = value
                end
                if template.delay then
                    event.due = opponent.host.now() + template.delay
                end
                opponent.record(name, event)
            end
        end
    end, { type = "regex" })
end

-- Sub-modules: timing and health first, then the parsers (they use onLine and the events above).
loadModule("opponent/timing.lua")
loadModule("opponent/health.lua")
loadModule("opponent/parse_cures.lua")
loadModule("opponent/parse_class_cures.lua")
loadModule("opponent/parse_symptoms.lua")
loadModule("opponent/parse_attacks.lua")
-- classes
loadModule("opponent/offense/sylvan.lua")

-- commands/aliases
loadModule("opponent/commands.lua")
