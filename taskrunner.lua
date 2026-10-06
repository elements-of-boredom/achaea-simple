-- Task/sequence runner: runs an ordered list of steps, one sequence at a
-- time. Each step can send a command, then wait asynchronously for a line,
-- event, or room arrival. 
--
-- Step fields (all optional; need at least one of send/wait/waitPattern/fn/waitEvent/waitRoom):
--   send      string    Command sent to the server before waiting.
--   wait      string    Substring to wait for in server output (tempTrigger - no wildcards).
--   waitPattern string  PCRE regex to wait for (tempRegexTrigger) - use when the exact text varies.
--   waitEvent string    Mudlet/raiseEvent name to wait for.
--   waitRoom  number    Room number; resolves when gmcp.Room.Info.num matches.
--   fn        fn(ctx)   Sync callback; runs before send/wait if both present.
--                        May return a cleanup fn, called when the step
--                        resolves via ANY path - use this to tear down
--                        any ad-hoc timer/trigger fn() itself created.
--   delay     number    Seconds to pause, then advance (no send/wait needed).
--   timeout   number    Seconds before onFail fires. Default 10.
--   settleDelay number  Extra pause after wait/waitEvent/waitRoom resolves.
--   onSuccess branch    Default "next".
--   onFail    branch    Default "abort".
--
-- branch: "next" | "complete" | "abort" | "retry" | <step-index> | fn(ctx)
--
-- API: PkCore.task.run(name, steps) / .abort() / .isActive() /
-- .jumpTo(n) / .resume() / .status() / .list() / .resolve("ok"|"fail") / .retry()

PkCore.task = PkCore.task or {
  active = false, name = nil, steps = {}, index = 1,
  trigger = nil, handler = nil, timer = nil,
  lastResult = nil, lastReason = nil,
}

-- Step-scoped trigger/timer/handler are deliberately NOT run through
-- PkCore.trackTrigger/trackTimer/trackHandler (the session-long global
-- lists) - they're swapped out every step, so tracking them there would
-- just grow that list forever. _taskKillWaits() is the only cleanup they
-- need. Aborting unconditionally on load/reload (below) guarantees a task
-- left running across a ui-reload doesn't leave orphaned waits behind.
local T = PkCore.task

local function taskLog(msg)
  PkCore.note((T.name and ("[task:" .. T.name .. "] ") or "[task] ") .. msg)
end

local function killWaits()
  if T.trigger then pcall(killTrigger, T.trigger); T.trigger = nil end
  if T.handler then pcall(killAnonymousEventHandler, T.handler); T.handler = nil end
  if T.timer then pcall(killTimer, T.timer); T.timer = nil end
  -- fn() can return its own cleanup (e.g. an ad-hoc retry timer) - runs
  -- here too, so it's torn down the moment the step resolves via ANY
  -- path, not just its own internal confirmation trigger.
  if T.fnCleanup then pcall(T.fnCleanup); T.fnCleanup = nil end
end

local function describeStep(step)
  if not step then return "?" end
  return step.send or step.wait or step.waitPattern or step.waitEvent
    or (step.waitRoom and "room:" .. step.waitRoom)
    or (step.delay and "delay:" .. step.delay)
    or (step.fn and "fn") or "?"
end

local runStep -- forward declaration
local resolve -- forward declaration

resolve = function(result)
  if not T.active then return end
  killWaits()

  local step = T.steps[T.index]
  if not step then
    T.active = false
    return
  end

  local branch = (result == "ok") and (step.onSuccess or "next") or (step.onFail or "abort")

  if type(branch) == "function" then
    pcall(branch, { name = T.name, index = T.index, result = result })
    branch = "next"
  end

  if branch == "complete" then
    T.active = false
    T.lastResult, T.lastReason = "complete", nil
    taskLog("complete")
    PkCore.stateChanged()
    return
  elseif branch == "abort" then
    T.active = false
    T.lastResult, T.lastReason = "failed", "step " .. T.index .. " failed"
    taskLog("aborted at step " .. T.index)
    PkCore.stateChanged()
    return
  elseif branch == "retry" then
    T.timer = tempTimer(0, function() T.timer = nil; runStep(step) end)
    return
  elseif type(branch) == "number" then
    T.index = branch
  else -- "next"
    T.index = T.index + 1
  end

  local nextStep = T.steps[T.index]
  if not nextStep then
    T.active = false
    T.lastResult, T.lastReason = "complete", nil
    taskLog("complete")
    PkCore.stateChanged()
    return
  end
  -- 0-second timer so a newly-armed trigger for the next step can't
  -- re-enter on the same line that just resolved this one.
  T.timer = tempTimer(0, function() T.timer = nil; runStep(nextStep) end)
  PkCore.stateChanged()
end

runStep = function(step)
  killWaits()

  if step.fn then
    local ok, result = pcall(step.fn, { name = T.name, index = T.index })
    if not ok then
      taskLog("step " .. T.index .. " error: " .. tostring(result))
      resolve("fail")
      return
    end
    if type(result) == "function" then
      T.fnCleanup = result
    end
  end

  if step.send then
    send(step.send)
  end

  if step.delay then
    T.timer = tempTimer(step.delay, PkCore.protected("task.delay", function()
      T.timer = nil
      resolve("ok")
    end))
    return
  end

  if not step.wait and not step.waitPattern and not step.waitEvent and not step.waitRoom then
    resolve("ok")
    return
  end

  local timeout = step.timeout or 10

  local function resolveAfterSettle()
    local sd = step.settleDelay
    if sd and sd > 0 then
      killWaits() -- drop the timeout timer + trigger before the settle delay
      T.timer = tempTimer(sd, function() T.timer = nil; resolve("ok") end)
    else
      resolve("ok")
    end
  end

  if step.wait then
    T.trigger = tempTrigger(step.wait, resolveAfterSettle)
  elseif step.waitPattern then
    T.trigger = tempRegexTrigger(step.waitPattern, resolveAfterSettle)
  elseif step.waitEvent then
    T.handler = registerAnonymousEventHandler(step.waitEvent, resolveAfterSettle)
  elseif step.waitRoom then
    local targetRoom = tonumber(step.waitRoom)
    T.handler = registerAnonymousEventHandler("gmcp.Room.Info", function()
      if gmcp and gmcp.Room and gmcp.Room.Info and tonumber(gmcp.Room.Info.num) == targetRoom then
        resolveAfterSettle()
      end
    end)
  end

  T.timer = tempTimer(timeout, PkCore.protected("task.timeout", function()
    T.timer = nil
    taskLog("step " .. T.index .. " timed out after " .. timeout .. "s")
    resolve("fail")
  end))
end

function PkCore.task.run(name, steps)
  if T.active then
    PkCore.task.abort()
  end

  T.name, T.steps, T.index, T.active = name, steps or {}, 1, true
  T.lastResult, T.lastReason = nil, nil

  local first = T.steps[1]
  if not first then
    T.active = false
    return
  end

  taskLog("starting '" .. tostring(name) .. "' (" .. #T.steps .. " steps)")
  PkCore.stateChanged()
  runStep(first)
end

function PkCore.task.abort()
  if not T.active then
    return
  end
  killWaits()
  T.active = false
  T.lastResult, T.lastReason = "aborted", nil
  taskLog("aborted")
  PkCore.stateChanged()
end

function PkCore.task.isActive()
  return T.active
end

function PkCore.task.jumpTo(n)
  n = tonumber(n)
  if not T.steps or #T.steps == 0 then
    PkCore.note("[task] no task loaded - run a task first")
    return
  end
  if not n or n < 1 or n > #T.steps then
    PkCore.note(string.format("[task:%s] step must be 1-%d", tostring(T.name), #T.steps))
    return
  end
  killWaits()
  T.active = true
  T.index = n
  taskLog("jumping to step " .. n .. "/" .. #T.steps)
  PkCore.stateChanged()
  runStep(T.steps[n])
end

function PkCore.task.status()
  if not T.steps or #T.steps == 0 then
    PkCore.note("[task] no task loaded")
    return
  end
  if T.active then
    PkCore.note(string.format("[task:%s] step %d/%d: %s",
      tostring(T.name), T.index, #T.steps, describeStep(T.steps[T.index])))
  else
    PkCore.note(string.format("[task:%s] stopped (%s) at step %d/%d - 'task resume' to continue",
      tostring(T.name), tostring(T.lastResult), T.index, #T.steps))
  end
end

function PkCore.task.list()
  if not T.steps or #T.steps == 0 then
    PkCore.note("[task] no task loaded")
    return
  end
  PkCore.note(string.format("[task:%s] %d steps:", tostring(T.name), #T.steps))
  for i, step in ipairs(T.steps) do
    local marker = (i == T.index) and " <--" or ""
    PkCore.note(string.format("  %2d. %s%s", i, describeStep(step), marker))
  end
end

-- Continues from wherever the task last stopped (aborted, failed, or a
-- reload) - reuses jumpTo()'s bounds check, so a fully-completed task
-- (index past the last step) correctly reports nothing to resume.
function PkCore.task.resume()
  if T.active then
    PkCore.note("[task] already running")
    return
  end
  if not T.steps or #T.steps == 0 then
    PkCore.note("[task] no task to resume - run a task first")
    return
  end
  PkCore.task.jumpTo(T.index)
end

function PkCore.task.resolve(result)
  resolve(result)
end

function PkCore.task.retry()
  if not T.active then
    return
  end
  local step = T.steps[T.index]
  if not step or not step.send then
    return
  end
  taskLog("retrying step " .. T.index .. " (" .. step.send .. ")")
  killWaits()
  runStep(step)
end

-- UI-facing summary (Tasks pane - see actions.lua). Returns nil when
-- there's nothing to show at all (never run, and nothing left over).
function PkCore.task.summary()
  if T.active then
    return string.format("%s - step %d/%d: %s", tostring(T.name), T.index, #T.steps, describeStep(T.steps[T.index]))
  end
  if T.lastResult then
    return string.format("%s - %s%s", tostring(T.name), T.lastResult, T.lastReason and (" (" .. T.lastReason .. ")") or "")
  end
  return nil
end

-- A task left active across a ui-reload would otherwise leave its step's
-- trigger/timer/handler orphaned (see the file header) - kill them now,
-- unconditionally, as this file re-executes.
PkCore.task.abort()

-- Real Achaea mapper message - self-heals a "path track" step that got
-- knocked off course mid-walk.
PkCore.trackTrigger(tempRegexTrigger(
  "^You have gone off%-course and stop walking toward your goal\\.$",
  PkCore.protected("task.autoRetry", function() PkCore.task.retry() end)))

-- One alias set (codex-ui had two overlapping ones - TASK ABORT/STATUS
-- plus a separate ctask abort/status/list/jump); lowercase, matching this
-- codebase's convention (bash on|off, rage why, ...).
local TASK_ALIASES = {
  { name = "PkCore task abort", pattern = [[^task\s+abort$]], body = [[PkCore.task.abort()]] },
  { name = "PkCore task status", pattern = [[^task\s+status$]], body = [[PkCore.task.status()]] },
  { name = "PkCore task list", pattern = [[^task\s+list$]], body = [[PkCore.task.list()]] },
  { name = "PkCore task jump", pattern = [[^task\s+jump\s+(\d+)$]], body = [[PkCore.task.jumpTo(matches[2])]] },
  { name = "PkCore task resume", pattern = [[^task\s+resume$]], body = [[PkCore.task.resume()]] },
}
for _, a in ipairs(TASK_ALIASES) do
  PkCore.registerAlias(a.name, a.pattern, a.body)
end
