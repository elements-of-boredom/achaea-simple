function PkCore.iht()
  local mobs = PkCore.room.mobEntries()
  if #mobs == 0 then
    PkCore.note("iht: no live mobs in room")
    return
  end
  local mob = mobs[1]
  local names = {}
  for _, m in ipairs(mobs) do
    table.insert(names, m.name)
  end
  --PkCore.note("iht: " .. table.concat(names, ", "))
  send("st " .. mob.id)
  PkCore.room.targetId = tostring(mob.id)
  PkCore.reactor.evaluate()
end

PkCore.registerAlias("PkCore iht", [[^iht$]], [[PkCore.iht()]])