PkCore.parry = PkCore.parry or {}
local parry = PkCore.parry
local RULES = loadModule("opponent/limb_rules.lua")
local WORDS = {}
for words, key in pairs(RULES.WORDS) do WORDS[key] = words end

-- A limb hit this recently is one they're working on.
parry.WINDOW = 10

-- The limb being prepped: hit lately and closest to breaking, ties to the latest hit.
function parry.want()
  local now, best, bestDamage, bestAt = PkCore.now(), nil, -1, 0
  for key, entry in pairs(PkCore.limbs.self) do
    if entry.at and now - entry.at <= parry.WINDOW then
      if entry.damage > bestDamage or (entry.damage == bestDamage and entry.at > bestAt) then
        best, bestDamage, bestAt = key, entry.damage, entry.at
      end
    end
  end
  return best and WORDS[best]
end

-- What to send, or nil when we're already parrying it or nothing's being worked on.
function parry.command()
  if not PkCore.config.values.autoParry then return nil end
  local limb = parry.want()
  if not limb or limb == PkCore.defences.parrying then return nil end
  return "parry " .. limb
end

-- Parry needs full balance. With a reactor queue pending, the queue carries it (see reactor.submitQueue).
local RESEND = 1
function parry.update()
  if PkCore.reactor.lastQueueSent ~= "" then return end
  if not (PkCore.balance.balance and PkCore.balance.equilibrium) then return end
  local command = parry.command()
  if not command then return end
  if PkCore.slowed.busy() then return end
  if command == parry.sent and PkCore.now() - (parry.sentAt or 0) < PkCore.slowed.resendAfter(RESEND) then return end
  parry.sent, parry.sentAt = command, PkCore.now()
  send(command)
end
PkCore.onVitalsChanged("parry", parry.update)

-- What gets past our parry depends on who's attacking. Knights: nausea 
-- prone is everyone. keep adding as we find other blockers.
parry.BLOCKERS = {}
local KNIGHT = { "nausea", "prone" }
parry.CLASS_BLOCKERS = {
  runewarden = KNIGHT, paladin = KNIGHT, infernal = KNIGHT, unnamable = KNIGHT,
  sentinel = { "haemophilia" },
  sylvan = { "vinewreathed" },
}