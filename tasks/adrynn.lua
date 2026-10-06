-- Adrynn quest chain
local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

-- Some NPCs don't respond to `greet` right away - resends every 2.5s
-- until confirmPattern matches. tempRegexTrigger, not tempTrigger - the
-- latter is substring-only, so a leading "^" (meant as a regex anchor)
-- could never match real text. Returns `stop` so taskrunner.lua's
-- fnCleanup hook tears this down the instant the step resolves via its
-- OWN wait condition too - confirmPattern isn't guaranteed to fire before
-- that (e.g. the NPC can skip straight to granting the quest), and
-- without this the retry loop kept sending greet commands into whatever
-- LATER step/room the task had already moved on to (confirmed live).
-- MAX_RETRIES is still a backstop in case fnCleanup itself never runs.
local RETRY_INTERVAL = 2.5
local MAX_RETRIES = 6

local function retryGreet(command, confirmPattern)
  return function()
    local tmr, tid, attempts = nil, nil, 0
    local function stop()
      if tmr then pcall(killTimer, tmr); tmr = nil end
      if tid then pcall(killTrigger, tid); tid = nil end
    end
    local function retry()
      attempts = attempts + 1
      if attempts > MAX_RETRIES then
        stop()
        return
      end
      send(command)
      tmr = tempTimer(RETRY_INTERVAL, retry)
    end
    tid = tempRegexTrigger(confirmPattern, stop)
    retry()
    return stop
  end
end

local function build()
  return {
    pathTrack(24621),
    { send = "get stick", wait = "You pick up a large stick.", timeout = 5 },
    { send = "put stick in wheel", wait = "You put a large stick into a massive copper wheel.", timeout = 5 },
    pathTrack(24619),
    { send = "get flour", wait = "You pick up a small pinch of flour.", timeout = 5 },
    pathTrack(25816),
    { send = "greet lord", wait = "\"A Missing Hound\"", timeout = 5 },
    pathTrack(25821),
    { send = "give flour to baker", wait = "\"Baking Needs\"", timeout = 15 },
    pathTrack(24664),
    { send = "give food to bailiff", wait = "\"A Sharper Axe\"", timeout = 25 },
    pathTrack(24583),
    { send = "give axe to logger", wait = "With a slight nod of his head, Isash", timeout = 15 },
    pathTrack(24761),
    { send = "give log to blacksmith", wait = "\"A Champion's Guard\"", timeout = 15 },
    pathTrack(25835),
    { send = "give shield185647 to champion", wait = "\"A Champion's Guard\"", timeout = 15 },
    pathTrack(25838),
    {
      fn = retryGreet("greet enula", "^Enula, the chambermaid says, \"Yes"),
      wait = "\"Calming the Crazy\"",
      timeout = 18,
    },
    pathTrack(25841),
    {
      fn = retryGreet("greet denod", "^Denod exclaims,"),
      waitPattern = "^Denod exclaims,",
      timeout = 12,
    },
    { send = "Beckon Denod", wait = "Denod falls into line behind you.", timeout = 15 },
    { send = "Beckon Radlar", wait = "Radlar falls into line behind you.", timeout = 15 },
    pathTrack(24593),
    { delay = 3.0 },
    pathTrack(25848), -- Go to the dog
    { delay = 1.0 },
    pathTrack(25816),
    { send = "put gold in pack", wait = "With a small wink", timeout = 15 },
    pathTrack(25819),
    { send = "give cup to Jehen", wait = "You give an empty china teacup to", timeout = 15 },
    pathTrack(25838),
    { send = "give cup to enula", wait = "Enula, the chambermaid lets out a long sigh", timeout = 15 },
    pathTrack(25824),
    {
      fn = retryGreet("greet adelo", "^Adelo says, \"Look"),
      wait = "After a quick check for witnesses, Adelo discreetly hands you an emerald ring",
      timeout = 18,
    },
    pathTrack(25816),
    { send = "give ring to lord", wait = "\"Happy Wife, Happy Life\"", timeout = 15 },
    pathTrack(25833),
    { send = "give 104950 to lady", wait = "You give a bulky letter to Lady", timeout = 15 },
    pathTrack(24851),
    {
      fn = retryGreet("greet ageysh", "^Ageysh, the stable keeper exclaims"),
      wait = "\"Aiding the Invalid\"",
      timeout = 18,
    },
    pathTrack(24761),
    { send = "give note to blacksmith", wait = "With a discriminating frown, Caurnn, the blacksmith pulls a new horseshoe", timeout = 20 },
    pathTrack(24288),
    { send = "", wait = "When you are finished attaching the horseshoe", timeout = 30},
    pathTrack(24664)
  }
end

return {
  name = "ADRYN",
  description = "Adryn task sequence.",
  build = build,
}
