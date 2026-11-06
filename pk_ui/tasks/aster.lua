local pathTrack = PkCore.task.pathTrack

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
        local tmr, tid
        local function retry() send("pull net"); tmr = tempTimer(2.5, retry) end
        tid = tempTrigger("You quickly heft an old fishing net from the water", function() pcall(killTimer, tmr) end)
        retry()
        return function() pcall(killTimer, tmr); pcall(killTrigger, tid) end
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
      -- The child (a boy or a girl) wanders the hovel: watch for one the whole step, look every 6s in
      -- case it's already here, and finish on the give no matter who sent it.
      fn = function()
        local tmr, tid, givenAt
        tid = tempRegexTrigger([[\b(?:serf|small) (boy|girl)\b]], function(_, _, w)
          if givenAt and PkCore.now() - givenAt < 3 then return end
          givenAt = PkCore.now()
          send("give bread to " .. w[1])
        end)
        local function look() send("look"); tmr = tempTimer(6, look) end
        look()
        return function() pcall(killTimer, tmr); pcall(killTrigger, tid) end
      end,
      wait = "You give a stale slice of bread to",
      timeout = 120,
    },
    pathTrack(55425),
    { send = "say Need help?", wait = "\"Nagging Nags\" has been added to your log", timeout = 20 },
    {
      fn = function()
        PkCore.cecho("\n<b><yellow>FIND A HORSE, PET HORSE, ")
        hyperlink("PATH TRACK 55425", "path track 55425", { hint = "Send: path track 55425" })
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
