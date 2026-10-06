local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  return {
    pathTrack(55762),
    { send = "say I request entry", wait = "A trio of guards nods in your direction before escorting you beneath the portcullis and into Aster", timeout = 15 },
    pathTrack(54906),
    { send = "say Need help?", wait = "\"Sweatin' Smiths\" has been added to your log", timeout = 15 },
    pathTrack(54719),
    { send = "say Milk?", wait = "Hilga, the cowherd hands you a bottle of fresh milk.", timeout = 15 },
    pathTrack(54906),
    { send = "give milk to blacksmith", wait = "Blacksmith Hoj says, \"Ahh, that always hits the spot", timeout = 15 },
    pathTrack(55470),
    { send = "say Need help?", wait = "\"Dough Dusting\" has been added to your log", timeout = 15 },
    { send = "dust", wait = "Holding your breath, you swiftly dust down", timeout = 15 },
    { send = "w" },
    { send = "dust", wait = "Holding your breath, you swiftly dust down", timeout = 15 },
    pathTrack(61847),
    { send = "say Need help?", wait = "\"Fresh off the Pier\" has been added to your log", timeout = 15 },
    pathTrack(62399),
    {
      -- Fishing net doesn't always land on the first pull - keep pulling
      -- every 2.5s until it does, or the step's own 120s timeout gives up.
      fn = function()
        local tmr
        local function retry() send("pull net"); tmr = tempTimer(2.5, retry) end
        tempTrigger("You quickly heft an old fishing net from the water", function() pcall(killTimer, tmr) end)
        retry()
      end,
      wait = "You quickly heft an old fishing net from the water",
      timeout = 120,
    },
    pathTrack(61847),
    { send = "GIVE NET TO JOVAR", wait = "Jovar, the Aster fishmonger exclaims, \"Aha! This is perfect", timeout = 15 },
    pathTrack(55025),
    { send = "dig", wait = "You unearth a sizable carrot!", timeout = 15 },
    { send = "get carrot" },
    pathTrack(55703),
    { send = "say Need help?", wait = "\"Leavened Leftovers\" has been added to your log", timeout = 15 },
    { send = "e" },
    { send = "say Need help?", wait = "\"Carrots, Cut and Cooked\" has been added to your log", timeout = 15 },
    { send = "give carrot to Hettie", wait = "Hettie, the Ostler's cook says, \"Just in time", timeout = 15 },
    pathTrack(51486),
    {
      -- The child's name (boy/girl) varies - look every few seconds until
      -- one appears, then hand over the bread.
      fn = function()
        local done = false
        local tmr
        local function tryFind()
          if done then return end
          local tidB, tidG
          local function found(target)
            if done then return end
            done = true
            pcall(killTrigger, tidB); pcall(killTrigger, tidG); pcall(killTimer, tmr)
            tempTrigger("You give a stale slice of bread to", function()
              raiseEvent("AchaeaCore.task.asterChildFound")
            end)
            send("give bread to " .. target)
          end
          tidB = tempTrigger("boy", function() found("boy") end)
          tidG = tempTrigger("girl", function() found("girl") end)
          tempTimer(2, function()
            if not done then
              pcall(killTrigger, tidB); pcall(killTrigger, tidG)
            end
          end)
          send("look")
          tmr = tempTimer(6, tryFind)
        end
        tryFind()
      end,
      waitEvent = "AchaeaCore.task.asterChildFound",
      timeout = 120,
    },
    pathTrack(55425),
    { send = "say Need help?", wait = "\"Nagging Nags\" has been added to your log", timeout = 20 },
    {
      fn = function()
        cecho("\n<bold><yellow>FIND A HORSE, PET HORSE, ")
        echoLink("PATH TRACK 55425", [[send("path track 55425")]], "Send: path track 55425", true)
        echo("\n")
      end,
    },
  }
end

return {
  name = "ASTER",
  description = "Aster task sequence.",
  build = build,
}
