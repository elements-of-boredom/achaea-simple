
local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  return {
    pathTrack(10741),
    { send = "JUMP BOARD", wait = "You jump onto a diving board.", timeout = 8 },
  }
end

return {
  name = "DivingBoard",
  description = "50 Renown, Jump!.",
  build = build,
}