PkCore.pipes = PkCore.pipes or {}

-- A lit pipe goes out after two minutes, and the curing only relights it when it wants to smoke. Lighting
-- probably needs our arms: in a riftlock a cold pipe means no valerian for the slickness. Keep it lit.
addTrigger([[^Your pipe, containing .+, has gone cold and dark\.$]], function()
  if PkCore.leaving.active then return end
  send("light pipes")
end, { type = "regex" })