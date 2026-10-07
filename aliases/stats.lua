PkCore.stats = PkCore.stats or {}
PkCore.stats.shield = PkCore.stats.shield or { absorbed = 0, heavyHits = 0 }
PkCore.stats.huntGold = PkCore.stats.huntGold or 0
PkCore.stats.huntXP = PkCore.stats.huntXP or 0
PkCore.stats.huntXPStart = PkCore.stats.huntXPStart or nil
PkCore.stats.incDmg = PkCore.stats.incDmg or { hits = {} }
PkCore.stats.sips = PkCore.stats.sips
  or { count = 0, total = 0, preHp = nil, pending = false, prevHp = nil, currHp = nil }
PkCore.stats.crits = PkCore.stats.crits or { total = 0, pending = nil, hits = {} }
PkCore.stats.crits.ignoreNext = false

-- ── Hits and Crits ──────────────────────────────────────────────────────────────────
local HEAVY_HIT_THRESHOLD = 100
local INC_DMG_WINDOW = 30
local CRIT_TIERS = {
  "CRITICAL", "CRUSHING CRITICAL", "OBLITERATING CRITICAL",
  "ANNIHILATINGLY POWERFUL CRITICAL", "WORLD-SHATTERING CRITICAL",
}
for _, tier in ipairs(CRIT_TIERS) do
  PkCore.stats.crits.hits[tier] = PkCore.stats.crits.hits[tier] or 0
end

local function formatNumber(n)
  local s = tostring(math.floor(tonumber(n) or 0))
  s = (s:reverse():gsub("(%d%d%d)", "%1,")):reverse()
  return (s:gsub("^,", ""))
end
PkCore.stats.formatNumber = formatNumber

local function onHealthLost()
  local cleaned = tostring(matches[2] or ""):gsub(",", "")
  local dmg = tonumber(cleaned) or 0
  if dmg > HEAVY_HIT_THRESHOLD then
    PkCore.stats.shield.heavyHits = PkCore.stats.shield.heavyHits + 1
  end
  if dmg > 0 then
    local hits = PkCore.stats.incDmg.hits
    table.insert(hits, { t = os.time(), dmg = dmg })
    local cutoff = os.time() - INC_DMG_WINDOW
    while hits[1] and hits[1].t < cutoff do
      table.remove(hits, 1)
    end
    PkCore.stateChanged()
  end
end

local function onShieldAbsorb()
  PkCore.stats.shield.absorbed = PkCore.stats.shield.absorbed + 1
  PkCore.stateChanged()
end

function PkCore.stats.shieldPercent()
  local s = PkCore.stats.shield
  if s.heavyHits <= 0 then return 0 end
  return math.floor((s.absorbed / s.heavyHits * 100) + 0.5)
end

local function onGoldPickedUp()
  local cleaned = tostring(matches[2] or ""):gsub(",", "")
  PkCore.stats.huntGold = PkCore.stats.huntGold + (tonumber(cleaned) or 0)
  PkCore.stateChanged()
end

local function onExperienceGain()
  local cleaned = tostring(matches[2] or ""):gsub(",", "")
  local xp = tonumber(cleaned) or 0
  if xp > 0 then
    PkCore.stats.huntXPStart = PkCore.stats.huntXPStart or os.time()
    PkCore.stats.huntXP = PkCore.stats.huntXP + xp
    PkCore.stateChanged()
  end
end

function PkCore.stats.huntXPPerHour()
  local start = PkCore.stats.huntXPStart
  if not start or PkCore.stats.huntXP == 0 then return 0 end
  local elapsed = os.time() - start
  if elapsed <= 0 then return 0 end
  return math.floor((PkCore.stats.huntXP / elapsed) * 3600)
end

function PkCore.stats.huntXPMinutesElapsed()
  local start = PkCore.stats.huntXPStart
  return start and math.floor((os.time() - start) / 60) or 0
end

PkCore.trackTrigger(tempRegexTrigger("^Health lost:\\s+([\\d,]+)\\s+\\(.+\\)\\.$",  PkCore.protected("stats.onHealthLost", onHealthLost)))
PkCore.trackTrigger(tempRegexTrigger("^Your shield completely absorbs the damage\\.$",  PkCore.protected("stats.onShieldAbsorb", onShieldAbsorb)))
PkCore.trackTrigger(tempRegexTrigger("^You pick up ([\\d,]+) gold sovereigns\\.$",  PkCore.protected("stats.onGoldPickedUp", onGoldPickedUp)))
PkCore.trackTrigger(tempRegexTrigger("^You have gained ([\\d,]+) experience\\.$",  PkCore.protected("stats.onExperienceGain", onExperienceGain)))

-- ── DPS ──────────────────────────────────────────────────────────────────
local DPS_HISTORY_MAX = 25

local function dpsFresh()
  return {
    active = false, frozen = false,
    fightDamage = 0, fightStart = 0, fightDps = 0,
    history = {}, historyHead = 0, historyCount = 0,
    ttkHistory = {}, ttkHead = 0, ttkCount = 0,
    sessionDamage = 0, sessionCombat = 0, sessionFightStart = nil,
  }
end

PkCore.stats.dps = PkCore.stats.dps or dpsFresh()

local function dpsNow() return os.time() end

local function liveFightDps(s)
  if not s.active or s.fightStart == 0 then return s.fightDps end
  return s.fightDamage / math.max(dpsNow() - s.fightStart, 1)
end

local function pushHistory(s, dps)
  local idx = (s.historyHead % DPS_HISTORY_MAX) + 1
  s.history[idx] = dps
  s.historyHead = idx
  if s.historyCount < DPS_HISTORY_MAX then s.historyCount = s.historyCount + 1 end
end

local function pushTtk(s, ttk)
  local idx = (s.ttkHead % DPS_HISTORY_MAX) + 1
  s.ttkHistory[idx] = ttk
  s.ttkHead = idx
  if s.ttkCount < DPS_HISTORY_MAX then s.ttkCount = s.ttkCount + 1 end
end

local function avgOf(list, count)
  if count == 0 then return 0 end
  local sum = 0
  for i = 1, count do sum = sum + list[i] end
  return sum / count
end

local function accumCombatTime(s)
  if s.active and s.sessionFightStart then
    s.sessionCombat = s.sessionCombat + (dpsNow() - s.sessionFightStart)
    s.sessionFightStart = dpsNow()
  end
end

local function computeSessionDps(s)
  local combat = s.sessionCombat
  if s.active and s.sessionFightStart then
    combat = combat + (dpsNow() - s.sessionFightStart)
  end
  if combat <= 0 then return 0 end
  return s.sessionDamage / math.max(combat, 1)
end

function PkCore.stats.dpsFormat(v)
  if v < 10 then return string.format("%.1f", v) end
  return string.format("%d", math.floor(v))
end

function PkCore.stats.currentDps() return liveFightDps(PkCore.stats.dps) end
function PkCore.stats.sessionDps() return computeSessionDps(PkCore.stats.dps) end
function PkCore.stats.isFightActive() return PkCore.stats.dps.active end
function PkCore.stats.isFightFrozen() return PkCore.stats.dps.frozen end

function PkCore.stats.avgMobDps()
  local s = PkCore.stats.dps
  return avgOf(s.history, s.historyCount), s.historyCount
end

function PkCore.stats.avgTtk()
  local s = PkCore.stats.dps
  return avgOf(s.ttkHistory, s.ttkCount), s.ttkCount
end

local function onDpsDamage(amount)
  local s = PkCore.stats.dps
  if not s.active then
    s.fightDamage = 0
    s.fightStart = dpsNow()
    s.active = true
    s.frozen = false
    s.sessionFightStart = dpsNow()
  end
  s.fightDamage = s.fightDamage + amount
  s.sessionDamage = s.sessionDamage + amount
  PkCore.stateChanged()
end

local function onMobDeath()
  local s = PkCore.stats.dps
  if not s.active then return end
  pushHistory(s, liveFightDps(s))
  pushTtk(s, math.max(dpsNow() - s.fightStart, 1))
  s.fightDps = liveFightDps(s)
  accumCombatTime(s)
  s.active = false
  s.frozen = true
  s.sessionFightStart = nil
  PkCore.stateChanged()
end

local function onTargetSwap()
  local s = PkCore.stats.dps
  if not s.active then return end
  local dps = liveFightDps(s)
  if dps > 0 then pushHistory(s, dps) end
  pushTtk(s, math.max(dpsNow() - s.fightStart, 1))
  accumCombatTime(s)
  s.fightDamage = 0
  s.fightStart = dpsNow()
  s.sessionFightStart = dpsNow()
  PkCore.stateChanged()
end

function PkCore.stats.critPercent(tier)
  local c = PkCore.stats.crits
  if c.total == 0 then return nil end
  return (c.hits[tier] or 0) / c.total * 100
end

function PkCore.stats.anyCritPercent()
  local c = PkCore.stats.crits
  if c.total == 0 then return nil end
  local anyHits = 0
  for _, v in pairs(c.hits) do anyHits = anyHits + v end
  return anyHits / c.total * 100
end

PkCore.trackTrigger(tempRegexTrigger("^You have scored an? (.+) hit!+$",
  PkCore.protected("stats.onCritHit", function()
    PkCore.stats.crits.pending = matches[2]
  end)))

PkCore.trackTrigger(tempRegexTrigger("^Time wreaks ruin upon .+$",
  PkCore.protected("stats.onDotTick", function()
    PkCore.stats.crits.ignoreNext = true
  end)))

PkCore.trackTrigger(tempRegexTrigger("^Damage dealt:\\s+([\\d,]+)\\s+\\(.+\\)\\.$",
  PkCore.protected("stats.onDpsDamage", function()
    local cleaned = tostring(matches[2] or ""):gsub(",", "")
    local amount = tonumber(cleaned) or 0
    if amount > 0 then onDpsDamage(amount) end

    local crits = PkCore.stats.crits
    if crits.ignoreNext then
      crits.ignoreNext = false
    else
      crits.total = crits.total + 1
      if crits.pending then
        crits.hits[crits.pending] = (crits.hits[crits.pending] or 0) + 1
        crits.pending = nil
      end
    end
    PkCore.stateChanged()
  end)))
PkCore.trackTrigger(tempRegexTrigger("^You have slain ",
  PkCore.protected("stats.onMobDeath", onMobDeath)))

local dpsLastTarget = nil
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed",
  PkCore.protected("stats.onTargetSwapCheck", function()
    local current = PkCore.room.targetName() or ""
    local previous = dpsLastTarget or ""
    dpsLastTarget = current
    if current ~= previous and current ~= "" and previous ~= "" then
      onTargetSwap()
    end
  end)))

  -- ── Sips ─────────────────────────────────────────────────────────────────
function PkCore.stats.avgSipHeal()
  local s = PkCore.stats.sips
  if s.count <= 0 then return 0 end
  return math.floor(s.total / s.count)
end

function PkCore.stats.avgIncomingDamage()
  local cutoff = os.time() - INC_DMG_WINDOW
  local total, count = 0, 0
  for _, h in ipairs(PkCore.stats.incDmg.hits) do
    if h.t >= cutoff then
      total = total + h.dmg
      count = count + 1
    end
  end
  if count == 0 then return nil end
  return math.floor(total / INC_DMG_WINDOW)
end

local function recordSipHeal(healed)
  if healed > 0 then
    PkCore.stats.sips.count = PkCore.stats.sips.count + 1
    PkCore.stats.sips.total = PkCore.stats.sips.total + healed
    PkCore.stateChanged()
  end
end

local function onElixirHeals()
  local s = PkCore.stats.sips
  local curr, prev = s.currHp or 0, s.prevHp or 0
  if curr > 0 and prev > 0 and curr > prev then
    recordSipHeal(curr - prev)
  elseif curr > 0 then
    s.preHp = curr
    s.pending = true
  end
end

local function onSipVitals()
  local vitals = gmcp and gmcp.Char and gmcp.Char.Vitals
  if not vitals then return end
  local s = PkCore.stats.sips
  local newHp = tonumber(vitals.hp) or 0
  if s.pending and s.preHp then
    recordSipHeal(newHp - s.preHp)
    s.pending = false
    s.preHp = nil
  end
  s.prevHp = s.currHp
  s.currHp = newHp
end

PkCore.trackTrigger(tempRegexTrigger("^The elixir heals and soothes you\\.$",
  PkCore.protected("stats.onElixirHeals", onElixirHeals)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Vitals",
  PkCore.protected("stats.onSipVitals", onSipVitals)))

-- ── Report / reset ───────────────────────────────────────────────────────
function PkCore.stats.report()
  local lines = {}
  table.insert(lines, string.format("XP: %s (%s/hr, %dm elapsed)",
    formatNumber(PkCore.stats.huntXP), formatNumber(PkCore.stats.huntXPPerHour()), PkCore.stats.huntXPMinutesElapsed()))
  table.insert(lines, "Gold: " .. formatNumber(PkCore.stats.huntGold))
  table.insert(lines, "Sip avg: " .. formatNumber(PkCore.stats.avgSipHeal()) .. " hp")
  local incDmg = PkCore.stats.avgIncomingDamage()
  table.insert(lines, "Incoming dmg/s (30s): " .. (incDmg and (formatNumber(incDmg)) or "-"))

  local anyCrit = PkCore.stats.anyCritPercent()
  table.insert(lines, "Crit %: " .. (anyCrit and string.format("%.1f%%", anyCrit) or "-"))
  for _, tier in ipairs(CRIT_TIERS) do
    local pct = PkCore.stats.critPercent(tier)
    if pct and pct > 0 then
      table.insert(lines, string.format("  %s: %.1f%%", tier, pct))
    end
  end

  local avgMob, mobCount = PkCore.stats.avgMobDps()
  local avgTtk, ttkCount = PkCore.stats.avgTtk()
  table.insert(lines, string.format("DPS: current %s | session %s | avg/mob %s (%d fights) | avg TTK %ds (%d fights)",
    PkCore.stats.dpsFormat(PkCore.stats.currentDps()), PkCore.stats.dpsFormat(PkCore.stats.sessionDps()),
    PkCore.stats.dpsFormat(avgMob), mobCount, math.floor(avgTtk), ttkCount))

  table.insert(lines, string.format("Shield: %d%% absorbed (%d/%d heavy hits)",
    PkCore.stats.shieldPercent(), PkCore.stats.shield.absorbed, PkCore.stats.shield.heavyHits))

  PkCore.note("=== Session Stats ===\n  " .. table.concat(lines, "\n  "))
end

PkCore.registerAlias("PkCore stats", [[^stats$]], [[PkCore.stats.report()]])

function PkCore.stats.resetAll()
  PkCore.stats.shield = { absorbed = 0, heavyHits = 0 }
  PkCore.stats.huntGold = 0
  PkCore.stats.huntXP = 0
  PkCore.stats.huntXPStart = nil
  PkCore.stats.incDmg = { hits = {} }
  PkCore.stats.sips = { count = 0, total = 0, preHp = nil, pending = false, prevHp = nil, currHp = nil }
  PkCore.stats.crits = { total = 0, pending = nil, hits = {} }
  for _, tier in ipairs(CRIT_TIERS) do PkCore.stats.crits.hits[tier] = 0 end
  PkCore.stats.dps = dpsFresh()
  PkCore.note("session stats reset")
  PkCore.stateChanged()
end

PkCore.registerAlias("PkCore stats reset", [[^stats\s+reset$]], [[PkCore.stats.resetAll()]])