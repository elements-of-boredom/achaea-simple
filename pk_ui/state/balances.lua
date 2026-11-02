PkCore.balances = PkCore.balances or {}
local B = PkCore.balances

local FAILSAFE_SLACK = 1

-- gmcp: driven by PkCore.balance. 
local DEFS = {
  balance = { gmcp = true }, equilibrium = { gmcp = true },
  tree = { default = 14 }, elixir = { default = 4.5 }, moss = { default = 6.5 },
  herb = { default = 1.6, defaults = { slow = 2.9 } },
  focus = { default = 2.5, defaults = { slow = 7.7 } }, pipe = { default = 1.5 }, 
  salve = { default = 1.4, defaults = { restoration = 4.0, slow = 1.9, ["restoration-slow"] = 6.0 } },
  fitness = { default = 10, defaults = { retry = 1 } },
  dragonheal = { default = 20, defaults = { retry = 2 } },
  shrugging = { default = 10.5, defaults = { retry = 1 } },
  rage = { default = 11, defaults = { retry = 2 } },
  accelerate = { default = 10, defaults = { retry = 1 } },
  fool = { default = 62 },
  eruption = { default = 9 },
  grovecure = { default = 4.2 },
}
local SLOWED_BY = { herb = "homunculusmercury", focus = "weakenedmind", salve = "timeflux" }
local function slowVariant(id, variant)
  local aff = SLOWED_BY[id]
  if not (aff and PkCore.afflictions.has(aff)) then return variant end
  return variant and (variant .. "-slow") or "slow"
end

-- A reload kills the failsafe timers
B.downAt = {}                  -- id -> seconds it went down
B.variant = {}                 -- id -> what used it (salve type), for per-variant timing
B.failsafe = {}
B.expected = B.expected or {}  -- "id" or "id:variant" -> seconds
B.missing = B.missing or {}    -- id -> true: the game says we don't have it (no tree tattoo)

local function now()
  return getCurrentTime() / 1000
end

local function expectedKey(id)
  local variant = B.variant[id]
  return variant and (id .. ":" .. variant) or id
end

function B.expectedFor(id)
  local def, variant = DEFS[id], B.variant[id]
  return B.expected[expectedKey(id)] or (variant and def.defaults and def.defaults[variant]) or def.default
end

function B.isReady(id)
  if B.missing[id] then return false end
  if DEFS[id].gmcp then return PkCore.balance[id] ~= false end
  return B.downAt[id] == nil
end

-- Seconds since it went down; nil when we never saw it go down.
function B.elapsed(id)
  local since = B.downAt[id]
  return since and (now() - since) or nil
end

function B.anyDown()
  for id in pairs(DEFS) do
    if not B.missing[id] and not B.isReady(id) then return true end
  end
  return false
end

local markUp

local function markDown(id, variant)
  B.missing[id] = nil
  variant = slowVariant(id, variant)
  B.downAt[id] = B.downAt[id] or now()
  B.variant[id] = variant
  if not DEFS[id].gmcp then
    if B.failsafe[id] then killTimer(B.failsafe[id]) end
    B.failsafe[id] = tempTimer(B.expectedFor(id) + FAILSAFE_SLACK, function()
      B.failsafe[id] = nil
      markUp(id, true)
    end)
  end
  PkCore.stateChanged()
end

-- timedOut: the failsafe fired, so don't learn a duration from it.
markUp = function(id, timedOut)
  if not B.downAt[id] then return end
  if not DEFS[id].gmcp and not timedOut then
    B.expected[expectedKey(id)] = now() - B.downAt[id]
  end
  if B.failsafe[id] then
    killTimer(B.failsafe[id])
    B.failsafe[id] = nil
  end
  B.downAt[id] = nil
  PkCore.stateChanged()
end

-- bal / eq -----------------
registerAnonymousEventHandler("PkCore balance lost", function(_, id) if DEFS[id] then markDown(id) end end)
registerAnonymousEventHandler("PkCore balance gained", function(_, id) if DEFS[id] then markUp(id) end end)
tempRegexTrigger([[^(Balance|Equilibrium) used: ([\d.]+)s\.$]], function(_, _, w)
  local id = w[1] == "Balance" and "balance" or "equilibrium"
  B.expected[id] = tonumber(w[2])
  markDown(id)
end)

-- server-side curing -----------------
-- "[Curing]: EAT KELP" with only the very next line counts as doing it, 
-- fireLength = 1 calls this again on that next line, and
-- priority 10 (default 50; higher runs first) makes that call run after the action triggers below.
local CURING_VERBS = { EAT = true, SIP = true, SMOKE = true, TOUCH = true, FOCUS = true }

addTrigger([[^\[Curing\]: (EAT|SIP|SMOKE|TOUCH|FOCUS)]], function(_, line)
  local verb = string.match(line, "^%[Curing%]: (%u+)")
  if verb and CURING_VERBS[verb] then
    B.curing = { verb = verb, what = string.lower(string.match(line, "^%[Curing%]: %u+%s*(%w*)") or "") }
  else
    B.curing = nil
  end
end, { type = "regex", fireLength = 1, priority = 10 })

-- Salves differ: the APPLY announcement sticks until the rub line.
-- APPLY HEALTH TO <limb> is an elixir, and takes elixir balance right away.
tempRegexTrigger([[^\[Curing\]: APPLY (\w+)(?: TO (\w+))?$]], function(_, _, w)
  local what = string.lower(w[1])
  if what == "health" then
    markDown("elixir")
  elseif what ~= "quicksilver" and what ~= "sileris" then
    B.applying = what
  end
end)

local function curingIs(verb)
  return B.curing ~= nil and B.curing.verb == verb
end

local function isElixirSip()
  return curingIs("SIP") and (B.curing.what == "health" or B.curing.what == "mana")
end

tempRegexTrigger([[^You eat ]], function()
  if not curingIs("EAT") then return end
  local what = B.curing.what
  markDown((what == "moss" or what == "potash" or what == "irid") and "moss" or "herb")
end)
tempRegexTrigger([[^You take a drink from ]], function() if isElixirSip() then markDown("elixir") end end)
tempRegexTrigger([[^You down the last drop from ]], function() if isElixirSip() then markDown("elixir") end end)
tempRegexTrigger([[^You take a long drag ]], function() if curingIs("SMOKE") then markDown("pipe") end end)
tempRegexTrigger([[^You touch the tree of life tattoo\.$]], function() markDown("tree") end)
tempRegexTrigger([[^You focus your mind intently on curing your mental maladies\.$]], function() markDown("focus") end)
-- A fizzled tree still costs tree balance, and isn't chained to an announcement.
tempRegexTrigger([[^Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged\.$]],
  function() markDown("tree") end)

tempRegexTrigger([[^You take out some (?:salve|balm) and quickly rub it on your \w+\.$]], function()
  if not B.applying then return end
  markDown("salve", string.find(B.applying, "^restoration") and "restoration" or B.applying)
  B.applying = nil
end)

-- recovery lines -----------------
local RECOVERY_LINES = {
  { [[^You may utilise the tree tattoo again\.$]], "tree" },
  { [[^Your mind is able to focus once again\.$]], "focus" },
  { [[^You may eat another plant or mineral\.$]], "herb" },
  { [[^You may eat another bit of irid moss or potash\.$]], "moss" },
  { [[^Your lungs have recovered enough to smoke another mineral or plant\.$]], "pipe" },
  { [[^You may apply another salve or balm to yourself\.$]], "salve" },
  { [[^You may drink another health or mana elixir(?: or tonic)?\.$]], "elixir" },
}
for _, r in ipairs(RECOVERY_LINES) do
  local id = r[2]
  tempRegexTrigger(r[1], function() markUp(id) end)
end
-- No tree tattoo. It stays missing until a tree use succeeds.
tempRegexTrigger([[^You have no tree\.$]], function()
  B.missing.tree = true
  PkCore.stateChanged()
end)

-- class cures -----------------
-- used: it just went down. refused: it's down but we don't know since when, so the short retry
-- timing lets server-side curing try again soon (as WunderSys does). ready: back up.
-- Dragonheal and fitness have no ready line we know of, so they rely on the failsafe timer.
local CLASS_CURES = {
  fitness = {
    used = [[^You inhale deeply, purging yourself of your asthmatic condition\.$]],
    refused = [[^You may not purge your lungs again as of this time\.$]],
    ready = [[^You may purge your lungs once again\.$]],
  },
  dragonheal = {
    used = [[^You let out a great keening, and cast the impurities from your form\.$]],
    refused = [[^You have not yet recovered enough to purge your great form of afflictions\.$]],
    ready = [[^You may purge your great form of afflictions once again\.$]],
  },
  shrugging = {
    used = [[^Focusing inward, you purge your body of afflictions\.$]],
    refused = [[^You may not shrug again so soon\.$]],
    ready = [[^Your body has recovered enough to shrug afflictions once again\.$]],
  },
  rage = {
    used = [[^You allow your pent-up rage to vent and your eyes flash dangerously\.$]],
    refused = [[^You are too exhausted to summon the rage of battle to throw off afflictions\.$]],
    ready = [[^You may channel your rage to cure your afflictions once again\.$]],
  },
  accelerate = {
    used = [[^You accelerate your body's ability to purge afflictions a thousandfold\.$]],
    refused = [[^You have not recovered enough to accelerate time in that way again so soon\.$]],
    ready = [[^You may accelerate time to cleanse your afflictions once again\.$]],
  },
  fool = {
    used = [[^You press the Fool tarot to your forehead\.$]],
    ready = [[^You may heal another affliction\.$]],
  },
  eruption = {
    used = [[^You summon up the magma that courses beneath your outer layers, sending it forth in an eruption to drive out that which taints your perfect form\.$]],
    refused = [[^You may not cleanse your form of weakness quite so soon after doing so previously\.$]],
    ready = [[^You may purge yourself of weakness once again\.$]],
  },
  grovecure = {
    used = [[^You stand upright, fists clenched, and feel the power of the earth rushing upwards to heal your body and mind\.$]],
  },
}
for id, lines in pairs(CLASS_CURES) do
  tempRegexTrigger(lines.used, function()
    B.downAt[id] = nil
    markDown(id)
  end)
  if lines.refused then
    tempRegexTrigger(lines.refused, function()
      if not B.downAt[id] then markDown(id, "retry") end
    end)
  end
  if lines.ready then
    tempRegexTrigger(lines.ready, function() markUp(id) end)
  end
end