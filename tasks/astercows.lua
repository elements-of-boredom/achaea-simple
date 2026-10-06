local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  return {
    pathTrack(54719),
    { send = "say Need help?", wait = "\"Brushing off Burrs\" has been added to your log", timeout = 15 },
    { send = "sw" },
    {
      fn = function()
        local done = false
        local tmr
        local calfs = { "calf184598", "calf238906", "calf236242", "calf128425" }

        tempTrigger("You feel a tangible increase in your worldly experience as the quest \"Brushing off Burrs\"", function()
          if done then return end
          done = true
          pcall(killTimer, tmr)
          raiseEvent("AchaeaCore.task.asterBurrsDone")
        end)

        local sequence = {}
        for _, c in ipairs(calfs) do sequence[#sequence + 1] = "brush " .. c end
        sequence[#sequence + 1] = "n"
        for _, c in ipairs(calfs) do sequence[#sequence + 1] = "brush " .. c end

        local idx = 0
        local function runNext()
          if done then return end
          idx = idx + 1
          if idx > #sequence then
            done = true
            cecho("\n<bold><red>FAILED TO COMPLETE\n")
            raiseEvent("AchaeaCore.task.asterBurrsDone")
            return
          end
          send(sequence[idx])
          tmr = tempTimer(0.4, runNext)
        end
        runNext()
      end,
      waitEvent = "AchaeaCore.task.asterBurrsDone",
      timeout = 60,
    },
  }
end

return {
  name = "ASTERCOWS",
  description = "Aster cows continuation.",
  build = build,
}
