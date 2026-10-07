PkCore.pk_mode = PkCore.pk_mode or { strategy = nil }
PkCore.pk_mode.strategies = PkCore.pk_mode.strategies or {}

function PkCore.pk_mode.registerStrategy(name, spec)
  PkCore.pk_mode.strategies[name] = spec
end

function PkCore.pk_mode.setStrategy(name)
  if not PkCore.pk_mode.strategies[name] then
    local names = {}
    for n in pairs(PkCore.pk_mode.strategies) do table.insert(names, n) end
    table.sort(names)
    PkCore.note("pk: unknown strategy '" .. tostring(name) .. "' (known: " .. table.concat(names, ", ") .. ")")
    return
  end
  PkCore.pk_mode.strategy = name
  PkCore.note("pk: strategy set to " .. name)
  PkCore.stateChanged()
end

function PkCore.pk_mode.report()
  PkCore.note("pk: strategy=" .. tostring(PkCore.pk_mode.strategy))
end

local function evaluate()
    if PkCore.reactor.mode ~= "pk" then return end
    if not PkCore.canAct() then
        return
    end
    local strategy = PkCore.pk_mode.strategy and PkCore.pk_mode.strategies[PkCore.pk_mode.strategy]
    if not strategy or not strategy.evaluate then return end
    strategy.evaluate()
end

PkCore.reactor.registerMode("pk", { evaluate = evaluate })
PkCore.registerAlias("PkCore pk strategy set", [[^pk\s+(\w+)$]], [[PkCore.pk_mode.setStrategy(matches[2])]])
PkCore.registerAlias("PkCore pk strategy report", [[^pk$]], [[PkCore.pk_mode.report()]])