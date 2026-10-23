PkCore.goldPickup = PkCore.goldPickup or { mode = "me", pending = false }
local gold = PkCore.goldPickup

local VALID_MODES = { on = true, me = true, off = true }
local SELF_KILL_WINDOW = 2
local GOLD_DROP_PATTERNS = {
  "sovereigns? spills? from the corpse",
  "^Golden sovereigns spill onto the ground from",
  "drops some golden sovereigns onto the ground",
}

local recentlyKilledByMe = false
local killSeq = 0

function gold.setMode(mode)
  if not VALID_MODES[mode] then
    PkCore.note("goldpickup: unknown mode: " .. tostring(mode))
    return
  end
  gold.mode = mode
  PkCore.note("goldpickup: mode set to: " .. mode)
  if mode == "off" then gold.pending = false end
end

function gold.report()
  PkCore.note("goldpickup: mode=" .. gold.mode)
end

function gold.attemptPickup()
  if not gold.pending then return end
  send("gg")
  gold.pending = false
end

local function onGoldSpill()
  if gold.mode == "off" then return end
  if gold.mode == "me" and not recentlyKilledByMe then return end
  gold.pending = true
  gold.attemptPickup()
end

-- Each kill restarts the window; an older kill's timer can't close a newer one's.
tempRegexTrigger([[^You have slain ]], function()
  recentlyKilledByMe = true
  killSeq = killSeq + 1
  local seq = killSeq
  tempTimer(SELF_KILL_WINDOW, function()
    if seq == killSeq then recentlyKilledByMe = false end
  end)
end)

for _, pattern in ipairs(GOLD_DROP_PATTERNS) do
  tempRegexTrigger(pattern, onGoldSpill)
end

PkCore.registerAlias("PkCore goldpickup set", [[^gp\s+(on|me|off)$]], [[PkCore.goldPickup.setMode(matches[2])]])
PkCore.registerAlias("PkCore goldpickup report", [[^gp$]], [[PkCore.goldPickup.report()]])