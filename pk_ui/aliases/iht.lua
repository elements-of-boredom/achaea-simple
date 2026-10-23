function PkCore.iht()
  local mobs = PkCore.room.mobEntries()
  if #mobs == 0 then
    PkCore.note("iht: no live mobs in room")
    return
  end
  local mob = mobs[1]
  send("st " .. mob.id)
  PkCore.room.targetId = tostring(mob.id)

  PkCore.hunt_mode.evaluate()
end

PkCore.registerAlias("PkCore iht", [[^iht$]], [[PkCore.iht()]])