PkCore.opponent = PkCore.opponent or {}
local opponent = PkCore.opponent

opponent.Model = loadModule("opponent/model.lua")
opponent.Queries = loadModule("opponent/queries.lua")
opponent.Model.load(loadModule("opponent/cures.lua"))
opponent.Model.addCure("smoke:skullcap", {"norebounding"})
opponent.Model.addCure("apply:mass", { "nodensity" })
-- A pending restoration ties up the salve channel like slickness (AK's "tempslickness").
for _, marker in pairs(opponent.Model.DELAYED) do
    table.insert(opponent.Queries.CHANNEL_BLOCKERS.apply, marker)
end
opponent.RESTORATION_DELAY = 4.0
opponent.SILERIS_DELAY = 9.0
opponent.SENSE_WINDOW = { deaf = { 2.0, 4.2 } }
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
    local current = PkCore.room.targetName()
    return type(current) == "string" and current:lower() == name:lower()
end

-- Tracking/Recording
opponent.HERB_GAP = 1.2
opponent.lastCure = opponent.lastCure or {}

-- Triggers only record. Nothing touches the model until the prompt.
function opponent.record(name, event)
    event.name = name
    event.time = PkCore.now()
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
function opponent.acceptCure(name, group, gap)
    local key, now = name:lower(), PkCore.now()
    local last = opponent.lastCure[key] or {}
    if last[group] and now - last[group] < gap then
        PkCore.note("ignored " .. group .. " from " .. name .. " (too soon, likely an illusion)")
        return false
    end
    last[group] = now
    opponent.lastCure[key] = last
    return true
end

-- A cure through a channel proves the channel wasn't blocked: eating proves no anorexia.
function opponent.channelProof(target, cureKey)
    local channel = cureKey:match("^(%a+)")
    for _, blocker in ipairs(opponent.Queries.CHANNEL_BLOCKERS[channel] or {}) do
        opponent.Model.proof(target, blocker, false)
    end
end

function opponent.apply(event)
    if event.kind == "reset" then
        opponent.targets[event.name:lower()] = opponent.Model.newTarget(event.name)
        return
    end
    if event.kind == "gain" then
        opponent.Model.gain(opponent.get(event.name), event.aff, event.count)
        return
    end
    if event.kind == "lose" then
        opponent.Model.remove(opponent.get(event.name), event.aff)
        return
    end
    if event.kind == "proof" then
        opponent.Model.proof(opponent.get(event.name), event.aff, event.present)
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

function opponent.flush()
    if #opponent.pending == 0 then
        return
    end
    local events, now, applied = opponent.pending, PkCore.now(), false
    opponent.pending = {}
    for _, event in ipairs(events) do
        if event.due and event.due > now then
            opponent.pending[#opponent.pending + 1] = event
        else
            opponent.apply(event)
            applied = true
        end
    end
    if applied then
        PkCore.stateChanged()
    end
end

-- The name given, or the current target.
function opponent.nameOrTarget(name)
    if type(name) == "string" and name ~= "" then
        return name
    end
    local current = PkCore.room.targetName()
    if type(current) == "string" and current ~= "" then
        return current
    end
end

function opponent.reset(name)
    if name == "all" then
        opponent.targets = {}
        PkCore.note("opponent: reset everyone")
    else
        name = opponent.nameOrTarget(name)
        if not name then
            PkCore.note("opponent: no target to reset")
            return
        end
        opponent.apply({
            kind = "reset",
            name = name
        })
        PkCore.note("opponent: reset " .. name)
    end
    PkCore.stateChanged()
end

PkCore.onVitalsChanged("opponent.flush", opponent.flush)
loadModule("opponent/parse_cures.lua")
loadModule("opponent/parse_class_cures.lua")
-- classes
loadModule("opponent/offense/sylvan.lua")

-- commands/aliases
loadModule("opponent/commands.lua")
