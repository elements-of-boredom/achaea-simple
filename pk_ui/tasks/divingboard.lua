local pathTrack = PkCore.task.pathTrack

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