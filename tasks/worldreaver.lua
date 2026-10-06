
local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  return {
    pathTrack(17695)
  }
end

return {
  name = "WorldReaver",
  description = "100 Renown, listen.",
  build = build,
}