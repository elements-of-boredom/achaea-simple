PkCore.status = PkCore.status or { stunned = false }

function PkCore.isHindered()
  if PkCore.status.stunned then return true end
  if PkCore.afflictions.armsDamaged() then return true end
  for name, value in pairs(PkCore.afflictions.list) do
    if value and PkCore.afflictions.isBlocking(name) then return true end
  end
  return false
end

function PkCore.canAct()
  if PkCore.isHindered() then return false end
  return PkCore.balance.balance and PkCore.balance.equilibrium
end

function PkCore.balance.report()
  PkCore.note(string.format("balance=%s  equilibrium=%s stunned=%s",
    tostring(PkCore.balance.balance), tostring(PkCore.balance.equilibrium), tostring(PkCore.status.stunned)))
end

tempTrigger("You are too stunned to be able to do anything.", function()
  if PkCore.status.stunned then return end
  PkCore.status.stunned = true
  raiseEvent("PkCore action blocked", "stunned")
end)

tempTrigger("You are no longer stunned.", function()
  PkCore.status.stunned = false
  raiseEvent("PkCore action unblocked", "stunned")
end)
PkCore.registerAlias("PkCore balance check", [[^balcheck$]], [[PkCore.balance.report()]])