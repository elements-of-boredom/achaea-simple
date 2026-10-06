PkCore.reactor = PkCore.reactor or { mode = "off" }
PkCore.reactor.modes = PkCore.reactor.modes or {}

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

function PkCore.reactor.set(mode)
    if not VALID_MODES[mode] then
        PkCore.note("unkown mode: " .. tostring(mode) .. " (valid: off/hunt/pk)")
        return
    end
    if PkCore.reactor.mode == mode then return end
    PkCore.reactor.mode = mode
    raiseEvent("PkCore mode changed", mode)
    PkCore.note("mode: " .. tostring(mode))
    evaluate()
end

function PkCore.reactor.report()
    PkCore.note("mode: " .. tostring(PkCore.reactor.mode))
end

PkCore.registerAlias("PkCore mode report", [[^mode$]], [[PkCore.reactor.report()]])
PkCore.registerAlias("PkCore mode set", [[^mode\s+(\w+)$]], [[PkCore.reactor.set(matches[2])]])

PkCore.trackHandler(registerAnonymousEventHandler("PkCore balance gained", PkCore.protected("reactor.evaluate", evaluate)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore balance lost", PkCore.protected("reactor.evaluate", evaluate)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore action blocked", PkCore.protected("reactor.evaluate", evaluate)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore action unblocked", PkCore.protected("reactor.evaluate", evaluate)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore onBlockingAffliction removed", PkCore.protected("reactor.evaluate", evaluate)))
