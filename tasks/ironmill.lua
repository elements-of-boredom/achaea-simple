-- Pay Gorme, work the mill machinery, deliver the sack to Zeuris. Ported
-- directly from codex-ui's real, working tasks.lua (buildIronmillSteps) -
-- room numbers/commands are exact quest text, not guessed.
local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  return {
    pathTrack(22583),
    { send = "get 50 gold from pack" },
    { send = "give 50 gold to Gorme" },
    { delay = 0.3 },
    pathTrack(33145),
    { send = "turn crank clockwise" },
    { delay = 0.3 },
    pathTrack(33150),
    { send = "pull lever closed" },
    { delay = 0.3 },
    pathTrack(33226),
    { send = "pull gate open" },
    { delay = 1.5 },
    pathTrack(33230),
    { send = "put sack in chute" },
    pathTrack(33150),
    { send = "drop sack" },
    { delay = 0.9 },
    { send = "pull lever open", wait = "Fresh flour falls from the chute, quickly filling the sack below it.", timeout = 5 },
    { send = "get sack" },
    { delay = 0.3 },
    pathTrack(1968),
    { send = "give sack to Zeuris" },
  }
end

return {
  name = "IRONMILL",
  description = "Pay Gorme, work the mill, deliver sack to Zeuris (17 steps).",
  build = build,
}
