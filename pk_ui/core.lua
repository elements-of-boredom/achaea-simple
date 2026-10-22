PkCore.listeners = PkCore.listeners or {}

function PkCore.onStateChanged(name, fn)
  PkCore.listeners[name] = fn
end

function PkCore.stateChanged()
  for name, fn in pairs(PkCore.listeners) do
    local ok, err = pcall(fn)
    if not ok then echo("[pk_ui] " .. name .. ": " .. tostring(err), "#ff6b6b") end
  end
end

function PkCore.note(msg)
  cecho("<cyan>[PkCore]<reset> ".. tostring(msg))
end

function PkCore.protected(label, fn)
  return function()
    local ok, err = pcall(fn)
    if not ok then cecho("<red>[PkCore]<reset> error in " .. tostring(label) .. ": " .. tostring(err)) end
  end
end

-- The alias code is frozen once created, so keep it a thin call into a PkCore.* function.
function PkCore.registerAlias(name, pattern, code)
  if exists(name, "alias") == 0 and not permAlias(name, "", pattern, code) then
    cecho("<red>[PkCore]<reset> failed to create " .. name .. " alias")
    return
  end
  enableAlias(name)
end