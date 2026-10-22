local filenames = {
  "adrynn.lua", "aster.lua", "astercows.lua", "divingboard.lua",
  "dryadgarden.lua", "ironmill.lua", "worldreaver.lua",
}

PkCore.tasks = {}
PkCore.taskOrder = {}
for _, filename in ipairs(filenames) do
   local path = "tasks/" .. filename
  local chunk, loadErr = loadfile(path)
  if chunk then
    local ok, data = pcall(chunk)
    if ok and type(data) == "table" and data.name and type(data.build) == "function" then
      PkCore.tasks[data.name] = data
      table.insert(PkCore.taskOrder, data.name)
    else
      cecho("<red>[PkCore]<reset> tasks/" .. filename .. " did not return a valid task table")
    end
  else
    cecho("<red>[PkCore]<reset> tasks/" .. filename .. " error: " .. tostring(loadErr) .. "")
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
