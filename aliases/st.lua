function PkCore.setTarget(name)
  name = tostring(name or ""):match("^%s*(.-)%s*$")
  if name == "" then
    PkCore.note("usage: st <name>")
    return
  end
  send("st " .. name)
  target2 = name:lower()
  target = target2:title()
  if ak and ak.oresetparse then
    ak.oresetparse()
  end
end

PkCore.registerAlias("PkCore st", [[^st\s+(.+)$]], [[PkCore.setTarget(matches[2])]])