PkCore.reactor = PkCore.reactor or { mode = "off" }
PkCore.reactor.modes = PkCore.reactor.modes or {}
PkCore.reactor.pollInterval = PkCore.reactor.pollInterval or 0.3
PkCore.reactor.lastQueueSent = PkCore.reactor.lastQueueSent or ""
PkCore.reactor.pollGeneration = PkCore.reactor.pollGeneration or 0

local VALID_MODES = { off = true, hunt = true, pk = true }

function PkCore.reactor.registerMode(name, spec)
    PkCore.reactor.modes[name] = spec
end

local function evaluate()
    local mode = PkCore.reactor.modes[PkCore.reactor.mode]
    if mode and mode.evaluate then
        mode.evaluate()
    end
end
PkCore.reactor.evaluate = evaluate

local function poll(generation)
    if PkCore.reactor.mode == "off" then return end
    -- a newer chain took over; this one's stale, maybe dont turn it off and on so fast nerd.
    if generation ~= PkCore.reactor.pollGeneration then return end 
    evaluate()
    tempTimer(PkCore.reactor.pollInterval, function() poll(generation) end)
end

function PkCore.reactor.submitQueue(actions)
    if #actions == 0 then return end
    local queueStr = "queue addclear free " .. table.concat(actions, "|")
    
    send(queueStr)
end

function PkCore.reactor.set(mode)
    if not VALID_MODES[mode] then
        PkCore.note("unkown mode: " .. tostring(mode) .. " (valid: off/hunt/pk)")
        return
    end
    if PkCore.reactor.mode == mode then return end
    local previousMode = PkCore.reactor.mode
    PkCore.reactor.mode = mode
    raiseEvent("PkCore mode changed", mode)
    PkCore.note("mode: " .. tostring(mode))
    if previousMode == "off" and mode ~= "off" then
        PkCore.reactor.pollGeneration = PkCore.reactor.pollGeneration + 1
        -- the self-rescheduling chain died last time mode went "off" - restart it
        poll(PkCore.reactor.pollGeneration) 
    else
         -- chain's already alive (e.g. hunt->pk)
        evaluate()
    end
end

function PkCore.reactor.report()
    PkCore.note("mode: " .. tostring(PkCore.reactor.mode))
end

PkCore.registerAlias("PkCore mode report", [[^mode$]], [[PkCore.reactor.report()]])
PkCore.registerAlias("PkCore mode set", [[^mode\s+(\w+)$]], [[PkCore.reactor.set(matches[2])]])

-- Start our engine, mostly useful if `reload` is called.
PkCore.reactor.pollGeneration = PkCore.reactor.pollGeneration + 1
poll(PkCore.reactor.pollGeneration)
