 local opponent = Opponent

-- A timed affliction ending. A re-application restarts the clock, so only the newest timer ends it.
opponent.expiries = opponent.expiries or {}
function opponent.recordExpiry(name, aff, seconds)
    local key = name:lower() .. ":" .. aff
    local token = {}
    opponent.expiries[key] = token
    opponent.record(name, { kind = "lose", aff = aff, due = opponent.host.now() + seconds, expiry = key, token = token })
end

-- While they're actively curing, a pipe that's been free past its gap with no smoke
-- counts against every state that would be smoking. Asleep can't smoke either.
opponent.OVERDUE_PER_SECOND = 0.7
opponent.OVERDUE_GRACE = 1.0
opponent.ACTIVE_WINDOW = 8

opponent.OVERDUE_CHANNELS = {
    { group = "smoke" },
    { group = "eat" },
    { group = "apply" },
}
-- Conditions that stop every channel, on top of each channel's own blockers.
opponent.CANT_ACT = { "sleeping" }

function opponent.overdueBlockers(channel)
    local blockers = {}
    for _, aff in ipairs(opponent.CANT_ACT) do
        blockers[#blockers + 1] = aff
    end
    for _, aff in ipairs(opponent.Queries.BLOCKERS[channel.group] or {}) do
        blockers[#blockers + 1] = aff
    end
    return blockers
end

function opponent.checkOverdue()
    local now = opponent.host.now()
    local factor = opponent.OVERDUE_PER_SECOND ^ (opponent.TICK_MS / 1000)
    local changed = false
    for key, target in pairs(opponent.targets) do
        local last = opponent.lastCure[key]
        if target and last and not target.leftAt and opponent.isTracked(target.name) then
            local latest = 0
            for _, at in pairs(last) do
                if at and at > latest then
                    latest = at
                end
            end
            if now - latest < opponent.ACTIVE_WINDOW then
                for _, channel in ipairs(opponent.OVERDUE_CHANNELS) do
                    local ready = math.max((last[channel.group] or 0) + opponent.GAPS[channel.group], latest)
                    if now - ready > opponent.OVERDUE_GRACE then
                        opponent.Model.overdue(target, channel.group, opponent.overdueBlockers(channel), factor)
                        changed = true
                    end
                end
            end
        end
    end
    if changed then
       opponent.host.changed()
    end
end

opponent.host.onPrompt("opponent.flush", opponent.flush)
-- Timed events (an affliction wearing off, a sense window) apply on time, not at the next prompt.
-- Fresh events still wait for the prompt: a burst of lines isn't finished until then (rend, then carve).
opponent.TICK_MS = 200
function opponent.startTick()
    if opponent.tickTimer and opponent.tickTimer ~= "" then
        removeTimer(opponent.tickTimer)
    end
    opponent.tickTimer = addTimer(opponent.TICK_MS, function()
        opponent.flush(true)
        opponent.checkOverdue()
    end, true)
end
