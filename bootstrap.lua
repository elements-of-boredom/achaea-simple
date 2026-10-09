-- This system leverages and builds upon 2 externally maintained projects
-- AK (Affliction Tracker) https://www.dropbox.com/scl/fo/04ci9tq4rivks1r4oar37/ABxzEVpvvrBvjv9V4IYc2s0?rlkey=kyu53u5f96w5ra05xkkvujd3d&e=4&dl=0
-- SVOF - https://svof.github.io/svof/#

PkCore = PkCore or {}
PkCore.objects = PkCore.objects or {}
PkCore.handlers = PkCore.handlers or {}
PkCore.timerIds = PkCore.timerIds or {}
-- Holds the temporary trigger ids
PkCore.triggerIds = PkCore.triggerIds or {}
-- Holds systems, every .rebuild() calls system.rebuild(), 
-- every .cleanup() calls system.cleanup()
PkCore.systems = PkCore.systems or {}
PkCore.systemsOrder = PkCore.systemsOrder or {}
-- Generic event to let other systems/modules know something happened.
-- generally only used to trigger UI updates across modules.
PkCore.onStateChange = PkCore.onStateChange or nil

PkCore.path = getMudletHomeDir() .. "/pk"
PkCore.bootstrapFile = PkCore.path .. "/bootstrap.lua"

-- Thin facade, just protects against future mudlet changes
function PkCore.echo(msg) echo(msg) end
function PkCore.cecho(msg) cecho(msg) end
function PkCore.decho(msg) decho(msg) end
function PkCore.hecho(msg) hecho(msg) end

function PkCore.note(msg)
  PkCore.cecho("\n<cyan>[PkCore]<reset> " .. tostring(msg) .. "\n")
end

function PkCore.track(obj)
  table.insert(PkCore.objects, obj)
  return obj
end

function PkCore.trackHandler(id)
  table.insert(PkCore.handlers, id)
  return id
end

function PkCore.trackTrigger(id)
  table.insert(PkCore.triggerIds, id)
  return id
end

function PkCore.trackTimer(id)
  table.insert(PkCore.timerIds, id)
  return id
end

function PkCore.registerSystem(name, spec)
   if not PkCore.systems[name] then
    table.insert(PkCore.systemsOrder, name)
  end
  PkCore.systems[name] = spec
end

function PkCore.protected(label, fn)
  return function(...)
    local ok, err = pcall(fn, ...)
    if not ok then
      PkCore.cecho("\n<red>[PkCore]<reset> error in " .. tostring(label) .. ": " .. tostring(err) .. "\n")
    end
  end
end

-- No API replaces a permanent alias by name - `code` is frozen once
-- created, so it must always be a thin delegate to a real PkCore.* function, never inline logic.
function PkCore.registerAlias(name, pattern, code)
  if exists(name, "alias") == 0 then
    local id, err = permAlias(name, "", pattern, code)
    if not id then
      cecho("\n<red>[PkCore]<reset> failed to create " .. name .. " alias: " .. tostring(err) .. "\n")
      return
    end
  end
  if type(enableAlias) == "function" then
    enableAlias(name)
  end
end

function PkCore.stateChanged()
  raiseEvent("PkCore state changed")
end

function PkCore.loadModule(name, printSuccess)
  local path = PkCore.path .. "/" .. name
  local loader, loadErr = loadfile(path)
  if not loader then
    PkCore.note(name .. " not found: " .. tostring(loadErr))
    return
  end
  local ok, runErr = pcall(loader)
  if not ok then
    PkCore.note(name .. " error: " .. tostring(runErr))
  elseif ok and printSuccess then
    PkCore.note(name .. " loaded successfully.")
  end
end

function PkCore.onReady(fn)
  if gmcp and gmcp.Char and gmcp.Char.Vitals then
    fn()
    return
  end
  local handlerId
  handlerId = registerAnonymousEventHandler("gmcp.Char.Vitals", PkCore.protected("PkCore.onReady", function()
    killAnonymousEventHandler(handlerId)
    fn()
  end))
  PkCore.trackHandler(handlerId)
end

function PkCore.cleanup()
  for _, id in ipairs(PkCore.triggerIds) do pcall(killTrigger, id) end
  for _, id in ipairs(PkCore.timerIds) do pcall(killTimer, id) end
  for _, id in ipairs(PkCore.handlers) do pcall(killAnonymousEventHandler, id) end
  PkCore.handlers, PkCore.timerIds, PkCore.triggerIds = {}, {}, {}
  for _, system in pairs(PkCore.systems) do
    if system.cleanup then pcall(system.cleanup) end
  end
end

function PkCore.reload()
  local chunk, err = loadfile(PkCore.bootstrapFile)
  if not chunk then
    PkCore.cecho("\n<red>[PkCore]<reset> could not load " .. PkCore.bootstrapFile .. ": " .. tostring(err) .. "\n")
    return nil, err
  end
  PkCore.cleanup()
  local ok, result = pcall(chunk)
  if not ok then
    PkCore.cecho("\n<red>[PkCore]<reset> error while rebuilding: " .. tostring(result) .. "\n")
    return nil, result
  end
  return result
end

function PkCore.rebuild()
  for _, name in ipairs(PkCore.systemsOrder) do
    local system = PkCore.systems[name]
    if system and system.rebuild then pcall(system.rebuild) end
  end
end

PkCore.registerAlias("PkCore reload", [[^reload$]], [[PkCore.reload()]])

PkCore.loadModule("module_registration.lua", true)
PkCore.rebuild()