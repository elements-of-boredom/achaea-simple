PkCore.goldPickup = PkCore.goldPickup or { mode = "me", pending = false }

local VALID_MODES = { on = true, me = true, off = true }
local SELF_KILL_WINDOW = 2
local GOLD_DROP_PATTERNS = {
  "sovereigns? spills? from the corpse",
  "^Golden sovereigns spill onto the ground from",
  "drops some golden sovereigns onto the ground",
}

local recentlyKilledByMe = false

local function onGoldSpill()
  local mode = PkCore.goldPickup.mode
  if mode == "off" then return end
  if mode == "self" and not recentlyKilledSelf then return end
  PkCore.goldPickup.pending = true
  PkCore.goldPickup.attemptPickup()
end

function PkCore.goldPickup.setMode(mode)
    if not VALID_MODES[mode] then
        PkCore.note("goldpickup: unknown mode:".. tostring(mode))
        return
    end
    PkCore.goldPickup.mode = mode
    PkCore.note("goldpickup: mode set to:"..mode)
    if mode == "off" then
        PkCore.goldPickup.pending = false
    end
end

function PkCore.goldPickup.report()
    PkCore.note("goldpickup: mode="..PkCore.goldPickup.mode)
end

function PkCore.goldPickup.attemptPickup()
    if not PkCore.goldPickup.pending then return end
    send("gg")
    PkCore.goldPickup.pending = false
end

-- Triggers for pickup & kills
PkCore.trackTrigger(tempRegexTrigger("^You have slain ",
  PkCore.protected("goldPickup.onSelfKill", function()
    recentlyKilledByMe = true
    PkCore.trackTimer(tempTimer(SELF_KILL_WINDOW, PkCore.protected("goldPickup.clearSelfKill", function()
      recentlyKilledByMe = false
    end)))
  end)))

for _, pattern in ipairs(GOLD_DROP_PATTERNS) do
  PkCore.trackTrigger(tempRegexTrigger(pattern, PkCore.protected("goldPickup.onSpill", onGoldSpill)))
end

PkCore.registerAlias("PkCore goldpickup set", [[^goldpickup\s+(on|self|off)$]],
  [[PkCore.goldPickup.setMode(matches[2])]])
PkCore.registerAlias("PkCore goldpickup report", [[^goldpickup$]],
  [[PkCore.goldPickup.report()]])