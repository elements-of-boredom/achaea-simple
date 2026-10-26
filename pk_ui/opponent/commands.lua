 local opponent = Opponent

function opponent.show(name)
    opponent.flush() -- pretend we got a prompt incase we do this back to back with inline lua.
    name = opponent.nameOrTarget(name)
    if not name then
        opponent.host.note("opponent: no target")
        return
    end
    local target = opponent.find(name)
    if not target then
        opponent.host.note("opponent: not tracking " .. name)
        return
    end
    local lines = {}
    for _, entry in ipairs(opponent.Queries.sorted(target)) do
        lines[#lines + 1] = string.format("  %3d%%  %s", math.floor(entry.p * 100 + 0.5), entry.aff)
    end
    if #lines == 0 then
        lines[1] = "  clean"
    end
    opponent.host.note(string.format("%s: %d states, %s, %s\n", target.name, #target.states, target.blind, target.deaf) ..
                    table.concat(lines, "\n"))

    local limbs = {}
    for limb, entry in pairs(target.limbs) do
        limbs[#limbs + 1] = string.format("%s %.1f%%", limb, entry.damage)
    end
    if #limbs > 0 then
        table.sort(limbs)
        opponent.host.note("limbs: " .. table.concat(limbs, ", "))
    end
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

-- What the UI shows for one target: real afflictions at DISPLAY_FLOOR or above, most likely first.
opponent.DISPLAY_FLOOR = 0.45

function opponent.display(name)
    local target = type(name) == "string" and opponent.find(name)
    if not target then
        return {}
    end
    local top = target.states[1].affs
    local shown = {}
    for _, entry in ipairs(opponent.Queries.sorted(target)) do
        if entry.p >= opponent.DISPLAY_FLOOR and not opponent.Model.PSEUDO[entry.aff] then
            local count = top[entry.aff]
            shown[#shown + 1] = { aff = entry.aff, p = entry.p, count = type(count) == "number" and count or nil }
        end
    end
    return shown
end

-- What the limb row shows for one target, per limb: damage that still counts, hits to the next
-- step, and the worst likely state as a level (1 broken, 2 the first step, 3 the second).
function opponent.limbView(name)
    local target = type(name) == "string" and opponent.find(name)
    local view = {}
    for _, limb in pairs(opponent.LIMBS) do
        local cell = { damage = 0 }
        if target then
            cell.damage, cell.hits = opponent.Queries.limb(target, limb, opponent.host.now())
            local ladder = opponent.LIMB_RULES.ladder(limb)
            for level, aff in ipairs(ladder) do
                if opponent.Queries.has(target, aff) then cell.level = level end
            end
        end
        view[limb] = cell
    end
    return view
end

addAlias([[^opparms$]], "", function() opponent.showArms() end, { name = "opponent arms" })
addAlias([[^oppshow(?:\s+(\w+))?$]], "", function(matches) opponent.show(matches[2]) end, { name = "opponent show" })
addAlias([[^oppreset(?:\s+(\w+))?$]], "", function(matches) opponent.reset(matches[2]) end, { name = "opponent reset" })
