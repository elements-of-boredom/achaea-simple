-- Task definition registry. Auto-discovers every file in tasks/
-- via lfs.dir() adding a new task is "copy a file in tasks/, edit name/description/build" - no other change
-- needed. Each file returns { name=, description=, build=fn-returning-
-- steps-table } - build() is called fresh per run() so re-running a task
-- never reuses stale per-run state from a previous attempt.
local tasksDir = PkCore.path .. "/tasks"
local filenames = {}
for filename in lfs.dir(tasksDir) do
  if filename:match("%.lua$") then
    table.insert(filenames, filename)
  end
end
table.sort(filenames) -- lfs.dir() order isn't guaranteed - fixed panel order

PkCore.tasks = {}
PkCore.taskOrder = {}
for _, filename in ipairs(filenames) do
  local path = tasksDir .. "/" .. filename
  local chunk, loadErr = loadfile(path)
  if chunk then
    local ok, data = pcall(chunk)
    if ok and type(data) == "table" and data.name and type(data.build) == "function" then
      PkCore.tasks[data.name] = data
      table.insert(PkCore.taskOrder, data.name)
    else
      cecho("\n<red>[PkCore]<reset> tasks/" .. filename .. " did not return a valid task table\n")
    end
  else
    cecho("\n<red>[PkCore]<reset> tasks/" .. filename .. " error: " .. tostring(loadErr) .. "\n")
  end
end

function PkCore.tasks.start(name)
  local def = PkCore.tasks[name]
  if not def then
    PkCore.note("no such task: " .. tostring(name))
    return
  end
  PkCore.task.run(def.name, def.build())
end

-- One alias per task, case-insensitive bare word (e.g. typing DRYADGARDEN starts it, same as clicking it in the Tasks pane).
for _, name in ipairs(PkCore.taskOrder) do
  PkCore.registerAlias("PkCore task start " .. name, "(?i)^" .. name .. "$",
    [[PkCore.tasks.start("]] .. name .. [[")]])
end
