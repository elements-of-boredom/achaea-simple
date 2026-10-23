PkCore.listeners = PkCore.listeners or {}
PkCore.vitalsListeners = PkCore.vitalsListeners or {}

local function notify(listeners)
  for name, fn in pairs(listeners) do
    local ok, err = pcall(fn)
    if not ok then echo("[pk_ui] " .. name .. ": " .. tostring(err), "#ff6b6b") end
  end
end

-- Any blackboard change.
function PkCore.onStateChanged(name, fn) PkCore.listeners[name] = fn end
function PkCore.stateChanged() notify(PkCore.listeners) end

-- Every Char.Vitals (each prompt): kept apart so per-prompt work stays small.
function PkCore.onVitalsChanged(name, fn) PkCore.vitalsListeners[name] = fn end
function PkCore.vitalsChanged() notify(PkCore.vitalsListeners) end

function PkCore.note(msg)
  cecho("<cyan>[PkCore]<reset> ".. tostring(msg))
end
function PkCore.now() return getCurrentTime() / 1000 end

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