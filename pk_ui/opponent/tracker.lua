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
-- Game limb words to the model's keys: "left leg" -> "leftleg".
opponent.LIMBS = {
    ["left leg"] = "leftleg", ["right leg"] = "rightleg",
    ["left arm"] = "leftarm", ["right arm"] = "rightarm",
    head = "head", torso = "torso",
}
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
    local events, now, applied = opponent.pending, PkCore.now(), false
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

function opponent.resetLimb(name, limb)
    name = opponent.nameOrTarget(name)
    if not name or not limb then
        return
    end
    opponent.apply({ kind = "limbreset", name = name, limb = limb })
    PkCore.stateChanged()
end

-- A timed affliction ending. A re-application restarts the clock, so only the newest timer ends it.
opponent.expiries = opponent.expiries or {}
function opponent.recordExpiry(name, aff, seconds)
    local key = name:lower() .. ":" .. aff
    local token = {}
    opponent.expiries[key] = token
    opponent.record(name, { kind = "lose", aff = aff, due = PkCore.now() + seconds, expiry = key, token = token })
end

-- Health from ASSESS, the only source for a player (GMCP target health is denizens only).
-- A reading goes stale fast in a fight, so it only counts for ASSESS_FRESH seconds.
opponent.health = opponent.health or {}
opponent.ASSESS_FRESH = 6

addTrigger([[^You glance over ([\w'\-]+) and see that [\w'\-]+ health is at (\d+)/(\d+) \[(\d+)%\]\.$]], function(_, _, w)
    opponent.health[w[1]:lower()] = { percent = tonumber(w[4]), at = PkCore.now() }
    PkCore.stateChanged()
end, { type = "regex" })

function opponent.healthPercent(name)
    local entry = opponent.health[name:lower()]
    if entry and PkCore.now() - entry.at <= opponent.ASSESS_FRESH then
        return entry.percent
    end
end
-- The current target's health %: GMCP for denizens, our last fresh ASSESS for players.
function opponent.targetHealth()
    local name = PkCore.room.targetName()
    return PkCore.room.targetHpPercent or (name and opponent.healthPercent(name))
end

-- Heals we can see raise the last reading, never past 100. A mana sip looks the same as a health
-- sip, so this can overestimate. That's the safe side: a "below 75%" check just doesn't fire.
opponent.HEALS = {
    { [[^([\w'\-]+) takes a drink from .+\.$]], 17 },
    { [[^([\w'\-]+) eats (?:some irid moss|a potash crystal)\.$]], 8 },
    { [[^([\w'\-]+) swoons for a moment then rises again, flushed but strong\.$]], 40 },
    { [[^A look of relief crosses ([\w'\-]+)'s face as [\w'\-]+ touches a crystal tattoo\.$]], 100 },
}
for _, entry in ipairs(opponent.HEALS) do
    local amount = entry[2]
    addTrigger(entry[1], function(_, _, w)
        local reading = opponent.health[w[1]:lower()]
        if reading then
            reading.percent = math.min(100, reading.percent + amount)
            PkCore.stateChanged()
        end
    end, { type = "regex" })
end

-- while they're actively curing, a pipe that's been free past its gap with no smoke
-- counts against every state that would be smoking. Asleep can't smoke either.
opponent.OVERDUE_PER_SECOND = 0.7
opponent.OVERDUE_GRACE = 1.0
opponent.ACTIVE_WINDOW = 8
-- A restoration still landing (about 4 s) blocks every other salve, as slickness does.
opponent.RESTORING = {}
for _, marker in pairs(opponent.Model.DELAYED) do
    opponent.RESTORING[#opponent.RESTORING + 1] = marker
end
opponent.OVERDUE_CHANNELS = {
    { group = "smoke", gap = "PIPE_GAP" },
    { group = "eat", gap = "HERB_GAP" },
    { group = "apply", gap = "SALVE_GAP", extra = opponent.RESTORING },
}
-- Conditions that stop every channel, on top of each channel's own blockers.
opponent.CANT_ACT = { "sleeping" }

function opponent.overdueBlockers(channel)
    local blockers = {}
    for _, aff in ipairs(opponent.CANT_ACT) do
        blockers[#blockers + 1] = aff
    end
    for _, aff in ipairs(opponent.Queries.CHANNEL_BLOCKERS[channel.group] or {}) do
        blockers[#blockers + 1] = aff
    end
    for _, aff in ipairs(channel.extra or {}) do
        blockers[#blockers + 1] = aff
    end
    return blockers
end

function opponent.checkOverdue()
    local now = PkCore.now()
    local factor = opponent.OVERDUE_PER_SECOND ^ (opponent.TICK_MS / 1000)
    local changed = false
    for key, target in pairs(opponent.targets) do
        local last = opponent.lastCure[key]
        if target and last and opponent.isTracked(target.name) then
            local latest = 0
            for _, at in pairs(last) do
                if at and at > latest then
                    latest = at
                end
            end
            if now - latest < opponent.ACTIVE_WINDOW then
                for _, channel in ipairs(opponent.OVERDUE_CHANNELS) do
                    local ready = math.max((last[channel.group] or 0) + opponent[channel.gap], latest)
                    if now - ready > opponent.OVERDUE_GRACE then
                        opponent.Model.overdue(target, channel.group, opponent.overdueBlockers(channel), factor)
                        changed = true
                    end
                end
            end
        end
    end
    if changed then
        PkCore.stateChanged()
    end
end

PkCore.onVitalsChanged("opponent.flush", opponent.flush)
-- Timed events (an affliction wearing off, a sense window) apply on time, not at the next prompt.
-- Fresh events still wait for the prompt: a burst of lines isn't finished until then (rend, then carve).
opponent.TICK_MS = 200
if opponent.tickTimer then
    removeTimer(opponent.tickTimer)
end
opponent.tickTimer = addTimer(opponent.TICK_MS, function()
    opponent.flush(true)
    opponent.checkOverdue()
end, true)



-- Sub-modules
loadModule("opponent/parse_cures.lua")
loadModule("opponent/parse_class_cures.lua")
loadModule("opponent/parse_symptoms.lua")
-- classes
loadModule("opponent/offense/sylvan.lua")

-- commands/aliases
loadModule("opponent/commands.lua")
