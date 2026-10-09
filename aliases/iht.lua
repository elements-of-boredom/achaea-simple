function PkCore.iht()
  local mobs = PkCore.room.mobEntries()
  if #mobs == 0 then
    PkCore.note("iht: no live mobs in room")
    return
  end
  local mob = mobs[1]
  send("st " .. mob.id)
  PkCore.room.targetId = tostring(mob.id)
  target2 = mob.name:lower()
  target = target2:title()
  if ak and ak.oresetparse then
    ak.oresetparse()
  end
  PkCore.reactor.evaluate()
end

PkCore.registerAlias("PkCore iht", [[^iht$]], [[PkCore.iht()]])