-- Aeon (an affliction) or retardation (from the room): each action goes off about a second after it's
-- sent, and anything sent in that second cancels it. Retardation has no affliction, only the sluggish
-- line, so it counts as over once that line stops for QUIET seconds or we change rooms.
PkCore.slowed = PkCore.slowed or { lastSluggish = 0, on = false }
local slowed = PkCore.slowed
slowed.ACTION_DELAY = 1.25
slowed.QUIET = 5

function slowed.active()
  return PkCore.afflictions.has("aeon") or PkCore.now() - slowed.lastSluggish < slowed.QUIET
end

-- One of our actions is still waiting to go off: send nothing new.
function slowed.busy()
  return PkCore.now() - slowed.lastSluggish < slowed.ACTION_DELAY
end

local function syncRoom()
  if PkCore.room.number ~= slowed.room then
    slowed.room = PkCore.room.number
    slowed.lastSluggish = 0
  end
end

function slowed.check()
  syncRoom()
  local now = slowed.active()
  if now == slowed.on then return end
  slowed.on = now
  send("curing batch " .. (now and "off" or "on"))
  raiseEvent("PkCore slowed", now)
  PkCore.note(now and "slowed: one action at a time, batch curing off" or "no longer slowed: batch curing on")
end

tempRegexTrigger([[^You move sluggishly into action\.$]], function()
  syncRoom()
  slowed.lastSluggish = PkCore.now()
  slowed.check()
end)
PkCore.onVitalsChanged("slowed", slowed.check)