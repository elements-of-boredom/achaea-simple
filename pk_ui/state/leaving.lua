-- Leaving the realms: the soul-preservation prayer before logging out. Anything that keeps items out or
-- acts on its own should stand down until it's over 
PkCore.leaving = PkCore.leaving or { active = false }
local leaving = PkCore.leaving

local function set(active)
  if leaving.active == active then return end
  leaving.active = active
  raiseEvent("PkCore leaving", active)
end

addTrigger([[^You grow still and begin to silently pray for preservation of your soul while you are out of the land\.$]], function()
  set(true)
  send("inrift all")
  send("put gold in pack")
end, { type = "regex" })
addTrigger([[^You cease your praying\.$]], function()
  set(false)
end, { type = "regex" })