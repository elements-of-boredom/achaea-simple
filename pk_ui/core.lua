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