PkCore.pk = PkCore.pk or {}
local pk = PkCore.pk
pk.classes = pk.classes or {}   -- class key -> { actions, routes, defaultRoute, state }
pk.routeChoice = pk.routeChoice or {}

-- A class registers its actions ({ why, can, build, fired }), its routes (ordered action names) and,
-- optionally, a state table with reset(), wiped whenever a fight starts over.
function pk.register(class, spec)
  pk.classes[class] = spec
end

local function current()
  local class = PkCore.defences.classKey()
  return class and pk.classes[class], class
end

local function routeOf(spec, class)
  local saved = getVariable("pk_route_" .. class)
  local name = pk.routeChoice[class] or (type(saved) == "string" and spec.routes[saved] and saved) or spec.defaultRoute
  return spec.routes[name], name
end

-- The first action in the route whose can() is true, and the command it builds.
function pk.choose()
  local spec, class = current()
  if not spec then return nil end
  if spec.state and spec.state.check then spec.state.check() end
  local route, routeName = routeOf(spec, class)
  for _, name in ipairs(route or {}) do
    local action = spec.actions[name]
    if not action then error("pk: route " .. routeName .. " names unknown action " .. name) end
    if action.can() then
      return name, action, action.build()
    end
  end
end

-- Hidden and shrouded players never show in the room's player list, so the target counts as here until
-- an attack fails to find them. That holds us off in this room for a few seconds, or until they show.
pk.MISSING_RETRY = 3

local function listed(name)
  for _, player in ipairs(PkCore.room.playerNames()) do
    if player:lower() == name:lower() then return true end
  end
  return false
end

local function missing(name)
  local m = pk.missing
  return m ~= nil and m.name == name:lower() and m.room == PkCore.room.number
    and PkCore.now() - m.at < pk.MISSING_RETRY and not listed(name)
end

for _, line in ipairs({
  [[^You cannot see that being here\.$]],
  [[^You detect nothing here by that name\.$]],
  [[^Ahh, I am truly sorry, but I do not see anyone by that name here\.$]],
}) do
  addTrigger(line, function()
    local name = PkCore.room.targetName()
    if PkCore.reactor.mode == "pk" and name then
      pk.missing = { name = name:lower(), room = PkCore.room.number, at = PkCore.now() }
    end
  end, { type = "regex" })
end

local function evaluate()
  if PkCore.reactor.mode ~= "pk" then return end
  local name = PkCore.room.targetName()
  if not name or missing(name) then return end
  local name, action, command = pk.choose()
  pk.last = name and { name = name, why = action.why, command = command, at = PkCore.now() } or nil
  if command then PkCore.reactor.submitQueue({ command }, action.fired) end
end

function pk.why()
  local spec, class = current()
  if not spec then return PkCore.note("pk: no routes for " .. tostring(class)) end
  local _, routeName = routeOf(spec, class)
  local last = pk.last
  PkCore.note(string.format("pk %s/%s: %s", class, tostring(routeName),
    last and (last.name .. " (" .. last.why .. ") -> " .. tostring(last.command)) or "nothing chosen"))
end

function pk.setRoute(name)
  local spec, class = current()
  if not spec or not spec.routes[name] then
    return PkCore.note("pk: unknown route " .. tostring(name) .. " for " .. tostring(class))
  end
  pk.routeChoice[class] = name
  setVariable("pk_route_" .. class, name)
  if spec.state and spec.state.reset then spec.state.reset() end
  PkCore.note("pk: route " .. name)
end

PkCore.reactor.registerMode("pk", { evaluate = evaluate })
PkCore.registerAlias("PkCore pk why", [[^pk why$]], [[PkCore.pk.why()]])
PkCore.registerAlias("PkCore pk route", [[^pk route (\w+)$]], [[PkCore.pk.setRoute(matches[2])]])