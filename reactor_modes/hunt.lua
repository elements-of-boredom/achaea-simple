PkCore.hunt_mode = PkCore.hunt_mode or {}

local function findTargetMob()
    if not PkCore.room.targetId then return nil end
    for _, entry in ipairs(PkCore.room.mobEntries()) do
        if tostring(entry.id) == PkCore.room.targetId then
            return entry
        end
    end
    return nil
end

local function evaluate()
    if PkCore.reactor.mode ~= "hunt" then return end
    if not PkCore.canAct() then
        --PkCore.note("hunt: canAct=false (bal=" .. tostring(PkCore.balance.balance) ..
        --" eq=" .. tostring(PkCore.balance.equilibrium) ..
        --" stunned=" .. tostring(PkCore.status.stunned) .. ")")
      return
    end

    local target = findTargetMob()
    if not target then
        --PkCore.note("hunt.lua - Target not in room")
        return
    end

    local classData = PkCore.classes.current()
    if not classData or not classData.basicAttack then
        PkCore.note("hunt.lua - No basic attack found for current class:".. classData.name)
        return
    end

    send(classData.basicAttack)
end

PkCore.reactor.registerMode("hunt", { evaluate = evaluate })