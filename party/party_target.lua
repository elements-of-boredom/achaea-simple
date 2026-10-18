-- Party target calls - only obeyed from the configured caller.
PkCore.partyTarget = PkCore.partyTarget or {}

function PkCore.partyTarget.setCaller(name)
  if not name or name == "" then
    PkCore.note("target caller: " .. (PkCore.partyTarget.caller or "none"))
    return
  end
  if name:lower() == "off" then
    PkCore.partyTarget.caller = nil
    PkCore.note("target caller OFF")
    return
  end
  PkCore.partyTarget.caller = name:sub(1, 1):upper() .. name:sub(2):lower()
  PkCore.note("target caller: " .. PkCore.partyTarget.caller)
end

local function onTargetCall()
  local caller, target = matches[2], matches[3]
  if not PkCore.partyTarget.caller or caller:lower() ~= PkCore.partyTarget.caller:lower() then
    return
  end
  send("st " .. target, false)
  PkCore.note("target -> " .. target .. " (called by " .. caller .. ")")
end

PkCore.trackTrigger(tempRegexTrigger([[^\(Party\): (\w+) says, "Target(?: changed to|:) (\w+)\."$]],
  PkCore.protected("partyTarget.onTargetCall", onTargetCall)))

PkCore.registerAlias("PkCore partyTarget caller", [[^pcaller(?:\s+(\w+))?$]],
  [[PkCore.partyTarget.setCaller(matches[2])]])