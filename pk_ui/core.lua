PkCore.listeners = PkCore.listeners or {}

function PkCore.onStateChanged(name, fn)
  PkCore.listeners[name] = fn
end

function PkCore.stateChanged()
  for _, fn in pairs(PkCore.listeners) do fn() end
end