PkCore.reactor = PkCore.reactor or { mode = "off" }
local reactor = PkCore.reactor
reactor.modes = reactor.modes or {}
reactor.pollInterval = reactor.pollInterval or 0.35
reactor.lastQueueSent = ""
reactor.pollGeneration = reactor.pollGeneration or 0

function reactor.registerMode(name, spec)
  reactor.modes[name] = spec
end

function reactor.evaluate()
  local mode = reactor.modes[reactor.mode]
  if mode and mode.evaluate then mode.evaluate() end
end

-- A newer generation retires the old one.
-- An error turns the reactor off instead of silently killing the chain.
local function poll(generation)
  if reactor.mode == "off" or generation ~= reactor.pollGeneration then return end
  local ok, err = pcall(reactor.evaluate)
  if not ok then
    PkCore.note("reactor error, mode off: " .. tostring(err))
    reactor.set("off")
    return
  end
  tempTimer(reactor.pollInterval, function() poll(generation) end)
end

-- Every "our queued command is done" signal comes through here. For now that's
-- balance/eq used; Achaea's own queue-ran line replaces it once we have the text.
function reactor.queueConsumed()
  reactor.lastQueueSent = ""
end

function reactor.submitQueue(actions)
  if #actions == 0 then return end
  local commands = table.concat(actions, "|")
  if commands == reactor.lastQueueSent then return end
  reactor.lastQueueSent = commands
  send("queue addclear free " .. commands)
end

function reactor.set(mode)
  if mode ~= "off" and not reactor.modes[mode] then
    local names = { "off" }
    for name in pairs(reactor.modes) do table.insert(names, name) end
    table.sort(names)
    PkCore.note("unknown mode: " .. tostring(mode) .. " (valid: " .. table.concat(names, "/") .. ")")
    return
  end
  if reactor.mode == mode then reactor.report() return end
  local previous = reactor.mode
  reactor.mode = mode
  reactor.lastQueueSent = "" -- whatever we queued under the old mode may never have fired
  raiseEvent("PkCore mode changed", mode)
  PkCore.note("mode: " .. mode)
  PkCore.stateChanged()
  if previous == "off" then
    reactor.pollGeneration = reactor.pollGeneration + 1
    poll(reactor.pollGeneration)
  else
    reactor.evaluate() -- chain's already alive (e.g. hunt->pk)
  end
end

function reactor.report()
  PkCore.note("mode: " .. tostring(reactor.mode))
end

PkCore.registerAlias("PkCore mode report", [[^mode$]], [[PkCore.reactor.report()]])
PkCore.registerAlias("PkCore mode set", [[^mode\s+(\w+)$]], [[PkCore.reactor.set(matches[2])]])

-- Achaea echoes queued commands upper-cased. Only ours clears the dedupe; one you queued yourself doesn't.
tempRegexTrigger([[^\[System\]: Running queued \w+ command: (.+)$]], function(_, _, w)
  if w[1]:upper() == reactor.lastQueueSent:upper() then reactor.queueConsumed() end
end)
-- target gone (dead, moved, we flew): the queued attack failed without spending balance
tempRegexTrigger([[^You cannot see that being here\.$]], reactor.queueConsumed)

-- Restart the chain on reload if we were already in a mode.
reactor.pollGeneration = reactor.pollGeneration + 1
poll(reactor.pollGeneration)