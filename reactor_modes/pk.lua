PkCore.pk_mode = PkCore.pk_mode or {}

local function evaluate()
    if PkCore.reactor.mode ~= "pk" then return end
    if not PkCore.canAct() then
        return
    end
end

PkCore.reactor.registerMode("pk", { evaluate = evaluate })