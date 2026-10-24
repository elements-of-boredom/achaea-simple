local opponent = PkCore.opponent

function opponent.show(name)
    name = opponent.nameOrTarget(name)
    if not name then
        PkCore.note("opponent: no target")
        return
    end
    local target = opponent.find(name)
    if not target then
        PkCore.note("opponent: not tracking " .. name)
        return
    end
    local lines = {}
    for _, entry in ipairs(opponent.Queries.sorted(target)) do
        lines[#lines + 1] = string.format("  %3d%%  %s", math.floor(entry.p * 100 + 0.5), entry.aff)
    end
    if #lines == 0 then
        lines[1] = "  clean"
    end
    PkCore.note(string.format("%s: %d states, %s, %s\n", target.name, #target.states, target.blind, target.deaf) ..
                    table.concat(lines, "\n"))
end

-- Death ends the fight: queue a reset so it lands after anything else on this prompt.
local function resetOnDeath(_, _, w)
    if opponent.find(w[1]) then
        opponent.record(w[1], {
            kind = "reset"
        })
    end
end
addTrigger([[^You have slain ([\w'\-]+)\.$]], resetOnDeath, {
    type = "regex"
})
addTrigger([[^([\w'\-]+) has been slain by [\w'\-]+\.$]], resetOnDeath, {
    type = "regex"
})

PkCore.registerAlias("PkCore opponent arms", [[^opparms$]], [[PkCore.opponent.showArms()]])
PkCore.registerAlias("PkCore opponent show", [[^oppshow(?:\s+(\w+))?$]], [[PkCore.opponent.show(matches[2])]])
PkCore.registerAlias("PkCore opponent reset", [[^oppreset(?:\s+(\w+))?$]], [[PkCore.opponent.reset(matches[2])]])
