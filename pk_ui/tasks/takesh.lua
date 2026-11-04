local pathTrack = PkCore.task.pathTrack

local function build()
  return {
    pathTrack(1250),
    { send = "greet Takesh", wait = "Takesh, a mhun courier says, \"If you would be willing to assist me, I would see you compensated. So, what say you?\"", timeout = 25 },
    pathTrack(20882),
    { send = "give missive to mhun", wait = "Makesh says, \"Aha! I was wondering where this delivery was. Thank you.\"", timeout = 15 },
    pathTrack(1250),
    { send = "greet Takesh", wait = "Takesh, a mhun courier says, \"Another job? Yes, I have one for you", timeout = 15 },
    { send = "say Yes", wait = "Takesh, a mhun courier hands you a sealed missive.", timeout = 15 },
    pathTrack(1833),
    { send = "give missive to mhun", wait = "You give a sealed missive to a mhun worker.", timeout = 15 },
    pathTrack(1250),
    { send = "greet Takesh", wait = "Takesh, a mhun courier says, \"I have another job, but its important", timeout = 15 },
    { send = "say Yes", wait = "Takesh, a mhun courier hands you a sealed package.", timeout = 15 },
    pathTrack(2844),
    { send = "give package to mhun", wait = "Lieutenant Serentesh studies the package intently.", timeout = 15 },
    pathTrack(1250),
  }
end

return {
  name = "TAKESH",
  description = "Takesh delivery.",
  build = build,
}
