-- To run (from pk_ui):  lua5.1 reactor_modes/pk/sim.lua [route] [options]
--   lua5.1 reactor_modes/pk/sim.lua lock
--   lua5.1 reactor_modes/pk/sim.lua heartseed -v            every game line, not just the timeline
--   lua5.1 reactor_modes/pk/sim.lua lock --runs 20          many fights, summary only
--   lua5.1 reactor_modes/pk/sim.lua lock --holdbreath --tree-off --seconds 60 --seed 7
--   lua5.1 reactor_modes/pk/sim.lua burst --curer wsys --extra path/to/experiment.lua
--     --curer antilock (default): lock afflictions first, then WunderSys's order
--     --curer wsys: WunderSys's default priorities, what most opponents actually run
--     --extra: a file loaded after the routes, to try new actions and routes without touching them
-- Needs the PCRE2 binding, same as opponent/test_tracker.lua.
--
-- A fight against a perfect curer. The real tracker and the real sylvan route run unchanged: the sim
-- plays the game, printing the lines the game would print, and the route only knows what the tracker
-- makes of them. The opponent cures through every channel the moment it's free, anti-lock first.
package.cpath = os.getenv("HOME") .. "/.luarocks/lib/lua/5.1/?.so;" .. package.cpath
local rex = require("rex_pcre2")

-- Options ---------------------------------------------------------------------------------------
local opts = { route = "momentum", seconds = 90, runs = 1, seed = os.time(), verbose = false,
  holdbreath = false, tree = true, parry = 0, name = "Bob", curer = "antilock", extra = {} }
do
  local i = 1
  while arg[i] do
    local a = arg[i]
    if a == "-v" then opts.verbose = true
    elseif a == "--runs" then i = i + 1; opts.runs = tonumber(arg[i])
    elseif a == "--seconds" then i = i + 1; opts.seconds = tonumber(arg[i])
    elseif a == "--seed" then i = i + 1; opts.seed = tonumber(arg[i])
    elseif a == "--parry" then i = i + 1; opts.parry = tonumber(arg[i])
    elseif a == "--holdbreath" then opts.holdbreath = true
    elseif a == "--tree-off" then opts.tree = false
    elseif a == "--curer" then i = i + 1; opts.curer = arg[i]
    elseif a == "--reaction" then i = i + 1; opts.reaction = tonumber(arg[i])
    elseif a == "--fitness" then opts.fitness = true
    elseif a == "--extra" then i = i + 1; opts.extra[#opts.extra + 1] = arg[i]
    else opts.route = a end
    i = i + 1
  end
end

-- Game timings. Ours are from the logs ("Equilibrium used"); theirs are what we measured on ourselves.
local EQ = { thornrend = 2.34, vinewreathe = 2.18, heartseed = 4.30, synchronise = 1.95, overcharge = 1.95,
  disturb = 0.97, feedback = 2.34, shockwave = 2.65 }
local SWING_BALANCE = 2.4
local CURE_GAP = { eat = 1.5, smoke = 1.5, apply = 1.0, focus = 2.4, tree = 14.0, stand = 0.6, fitness = 10.0 }
local REACTION = opts.reaction or 0.15  -- how long the curer takes to notice a balance is back
local RESTORATION_DELAY = 4.0
local HEARTSEED_KILL = 10.1      -- heartseed to death, from the Kushy and Jakiro kills
local LIMB_HIT = 22
local AE_CAP = 60
local AE_PER_SPELL = 5
local TICK = 0.05

-- MudForge stand-ins ------------------------------------------------------------------------------
local clock, triggers, promptHooks, timers, variables, notes = 1000, {}, {}, {}, {}, {}
function addTrigger(pattern, fn)
  local ok, compiled = pcall(rex.new, pattern)
  if not ok then error("pattern does not compile: " .. pattern) end
  triggers[#triggers + 1] = { regex = compiled, fn = fn }
  return tostring(#triggers)
end
tempRegexTrigger = addTrigger
function addAlias() return "" end
function addTimer(ms, fn, repeating)
  timers[#timers + 1] = { every = ms / 1000, fn = fn, at = clock + ms / 1000, repeating = repeating }
  return tostring(#timers)
end
function removeTimer() end
function onGMCPUpdate() end
function registerAnonymousEventHandler() end
function raiseEvent() end
function registerCommand() end
function send() end
function cecho() end
function getVariable(name) return variables[name] end
function setVariable(name, value) variables[name] = value end
function deleteVariable(name) variables[name] = nil end
function getCurrentTime() return clock * 1000 end
function loadModule(path) return dofile(path) end

local TARGET = opts.name
PkCore = {
  now = function() return clock end,
  note = function(text) notes[#notes + 1] = text end,
  stateChanged = function() end,
  onVitalsChanged = function(_, fn) promptHooks[#promptHooks + 1] = fn end,
  registerAlias = function() end,
  room = { number = 1, targetName = function() return TARGET end, playerNames = function() return { TARGET } end },
  defences = { classKey = function() return "sylvan" end, have = { viridian = true } },
  reactor = { mode = "pk", registerMode = function() end, submitQueue = function() end },
}
Opponent = {
  host = {
    now = PkCore.now,
    note = PkCore.note,
    target = function() return TARGET end,
    onPrompt = PkCore.onVitalsChanged,
  },
}
dofile("opponent/tracker.lua")
dofile("reactor_modes/pk.lua")
dofile("reactor_modes/pk/sylvan/state.lua")
dofile("reactor_modes/pk/sylvan/actions.lua")
dofile("reactor_modes/pk/sylvan/routes.lua")
for _, path in ipairs(opts.extra) do dofile(path) end
local pk, S, T, RULES, CURES = PkCore.pk, PkCore.sylvanPk, Opponent.target, Opponent.LIMB_RULES, Opponent.Model.data

-- Output -------------------------------------------------------------------------------------------
local start
local function stamp() return string.format("%6.2f", clock - start) end
local function say(text) if opts.runs == 1 then print(stamp() .. "  " .. text) end end

-- One game line: every matching trigger fires, the way MudForge does.
local function line(text)
  if opts.verbose and opts.runs == 1 then print(stamp() .. "    | " .. text) end
  for _, trigger in ipairs(triggers) do
    local found = { trigger.regex:tfind(text) }
    if found[1] then
      local wildcards = {}
      for i, capture in ipairs(found[3] or {}) do
        if capture then wildcards[i] = capture end
      end
      trigger.fn(nil, text, wildcards)
    end
  end
end
local function prompt() for _, hook in ipairs(promptHooks) do hook() end end

-- The truth --------------------------------------------------------------------------------------
-- What the opponent really has. A rend that reaches 100% steps the limb along the same steps the
-- tracker uses (damaged, then mangled; mildtrauma, then serioustrauma); "broken" only comes from elsewhere.
local truth, me, world
local function has(aff) return truth.affs[aff] ~= nil end
local function gain(aff) truth.affs[aff] = true end
local function cure(aff) truth.affs[aff] = nil end

local function limbLevel(limb)
  local level = 0
  for i, aff in ipairs(RULES.ladder(limb)) do if has(aff) then level = i end end
  return level
end
local function hitLimb(limb, amount)
  truth.limbs[limb] = (truth.limbs[limb] or 0) + amount
  if truth.limbs[limb] < RULES.BREAK then return end
  truth.limbs[limb] = 0
  local steps, at = RULES.steps(limb), 0
  for i, aff in ipairs(steps) do if has(aff) then at = i end end
  if at < #steps then
    cure("broken" .. limb)
    if at > 0 then cure(steps[at]) end
    gain(steps[at + 1])
  end
end
local function legBroken()
  return limbLevel("leftleg") > 0 or limbLevel("rightleg") > 0
end

-- Our offence -------------------------------------------------------------------------------------
local VENOMS = Opponent.VENOMS
local PLANTS = { kelp = "healthleech", bellwort = "weariness", lobelia = "vertigo", elm = "dizziness",
  goldenseal = "epilepsy", valerian = "slickness", hawthorn = "sensitivity", kola = "sleeping" }
local PLANT_ITEM = { kelp = "piece of kelp", bellwort = "bellwort flower", lobelia = "lobelia seed",
  elm = "piece of slippery elm", goldenseal = "goldenseal root", valerian = "valerian leaf",
  hawthorn = "hawthorn berry", kola = "kola nut", bloodroot = "bloodroot leaf", sileris = "sileris berry",
  skullcap = "skullcap flower" }

local ELEMENT = { static = "lightning", thunderclap = "lightning", razorwind = "wind", cyclone = "wind",
  hailstone = "water", waterspout = "water" }
local ELEMENT_COST = { lightning = 15, wind = 5, water = 13 }
local ELEMENT_AFF = { lightning = "paralysis", wind = "asthma", water = "weariness" }
local LADDERS = {
  hailstone = { affs = { "clumsiness", "epilepsy", "impatience" }, lines = {
    "%s stumbles clumsily as the blow lands.", "%s begins to shake uncontrollably.", "A puzzled expression crosses the face of %s." } },
  waterspout = { affs = { "confusion", "dizziness", "vertigo" }, lines = {
    "%s begins to thrash at the water enveloping him.", "%s begins to sway unsteadily.", "A look of panic comes over the face of %s." } },
}

local function spell(name, t)
  if name == "static" then
    line("Channeling arcane power through your air and earth channels, you summon forth a burst of arcane static directed at " .. t .. ".")
    gain("paralysis")
  elseif name == "thunderclap" then
    line("Channeling large quantities of arcane power through your air channel, you direct a localised explosion of pure sound at " .. t .. ".")
    gain("sensitivity")
  elseif name == "razorwind" then
    line("Tapping into your air channel, you summon forth a vicious wind to lacerate the body of " .. t .. ".")
    gain("healthleech")
  elseif name == "cyclone" then
    if has("dizziness") then
      line("Summoning forth energy that you have gathered, you conjure forth a terrible cyclone of wind, picking up the disorientated form of " .. t .. " and whipping him about in a frenzy, dashing him against any available surfaces.")
      gain("impatience")
    else
      line("Summoning forth energy that you have gathered, you conjure forth a terrible cyclone of wind, picking up " .. t .. " and whipping him about in a frenzy.")
      gain("dizziness")
    end
  elseif LADDERS[name] then
    line(name == "hailstone"
      and "Channeling power through your water channel, you conjure forth a hailstone to strike " .. t .. " in the side of the head."
      or "You summon forth a spout of water, directing it at " .. t .. ".")
    local steps = LADDERS[name]
    for i, aff in ipairs(steps.affs) do
      if not has(aff) then
        gain(aff)
        line(string.format(steps.lines[i], t))
        break
      end
    end
  else
    return false
  end
  return true
end

local function weave(verb, a, b, t)
  if not (world.disturbed and world.feedback == t) then
    for _, name in ipairs({ a, b }) do spell(name, t) end
    return
  end
  if verb == "overcharge" then
    local cost = ELEMENT_COST[ELEMENT[a]] + ELEMENT_COST[ELEMENT[b]]
    if world.ae < cost then
      line("You have built up insufficient energy to overcharge those spells.")
      world.ae = 0
      return
    end
  end
  for _, name in ipairs({ a, b }) do
    spell(name, t)
    if verb == "overcharge" then
      local element = ELEMENT[name]
      world.ae = world.ae - ELEMENT_COST[element]
      if element == "wind" and truth.holdbreath then
        truth.holdbreath = false
        truth.exhaledAt = clock
        line(t .. " exhales loudly.")
      else
        gain(ELEMENT_AFF[element])
      end
      line("You have " .. world.ae .. " units of arcane energy stored.")
    else
      world.ae = math.min(AE_CAP, world.ae + AE_PER_SPELL)
      line("You have " .. world.ae .. " units of arcane energy built up.")
    end
  end
end

local function thornrend(words)
  local t, venom, plant = words[2], words[3], words[#words]
  local limbWords = table.concat(words, " ", 4, #words - 1)
  if plant ~= me.arms then
    me.arms = plant
    line("Crushing a " .. (PLANT_ITEM[plant] or plant) .. " in your hand, you absorb the remnants of natural energy stored within.")
  end
  line("You rub some " .. venom .. " on the thorny vines covering your arms.")
  line("You command the razor-edged thorny vines around you to lash out and rend the " .. limbWords .. " of " .. t .. ".")
  if math.random() < opts.parry then
    line(t .. " parries the attack with a deft manoeuvre.")
    return
  end
  if PLANTS[plant] then gain(PLANTS[plant]) end
  local v = VENOMS[venom]
  if v and v.gives then gain(v.gives) end
  line(string.format("As you carve into %s, you perceive that you have dealt %.1f%% damage to his %s.", t, LIMB_HIT, limbWords))
  hitLimb(RULES.key(limbWords), LIMB_HIT)
end

-- One command, possibly several joined with "|". Returns false for anything the sim doesn't know.
local function perform(command)
  for part in command:gmatch("[^|]+") do
    local words = {}
    for w in part:gmatch("%S+") do words[#words + 1] = w:lower() end
    local verb, t = words[1], TARGET
    if verb == "wipe" or verb == "assess" then
    elseif verb == "thornrend" then
      thornrend(words)
      me.eq = clock + EQ.thornrend
    elseif verb == "swing" then
      if legBroken() then
        line("You strike a savage blow with your quarterstaff at " .. t .. "'s damaged leg, bringing him crashing to the ground.")
        gain("prone")
      end
      me.bal = clock + SWING_BALANCE
    elseif verb == "vinewreathe" then
      line("Uttering a quiet recitation, you gesture towards " .. t .. ". A mass of writhing vines burst forth from the ground, grabbing hold of his form.")
      me.eq = clock + EQ.vinewreathe
    elseif verb == "heartseed" then
      line("Lunging forward with one palm outstretched and a singular purpose in mind, you strike a blow to " .. t .. "'s heart. Willing Nature's ire into his very soul, a warm pulse accompanies your attack as it connects.")
      gain("heartseed")
      truth.heartseedAt = clock
      me.eq = clock + EQ.heartseed
    elseif verb == "cast" and words[2] == "disturb" then
      if world.disturbed then
        line("The weather here has already been disturbed by a practitioner of your craft.")
      else
        line("Clouds boil into existence above you, their dark mass seething.")
        world.disturbed, world.ae, world.feedback = true, 0, nil
      end
      me.eq = clock + EQ.disturb
    elseif verb == "cast" and words[2] == "feedback" then
      line("Directing a sliver of power through your air and earth channels, you create a conduit between the clouds above and " .. t .. ".")
      world.feedback, world.ae = t, 0
      me.eq = clock + EQ.feedback
    elseif verb == "cast" and words[2] == "shockwave" then
      if world.ae >= 40 then
        local on = {}
        for _, aff in ipairs({ "asthma", "clumsiness", "healthleech", "sensitivity", "weariness", "impatience", "dizziness", "epilepsy" }) do
          if has(aff) then on[#on + 1] = aff end
        end
        say("** shockwave at " .. world.ae .. " AE with " .. #on .. " stacked: " .. table.concat(on, " "))
        world.ae = 0
        line("Gathering all of your stored power, you direct a cataclysmic burst of arcane might directly at " .. t .. ".")
        line("You have 0 units of arcane energy built up.")
      end
      me.eq = clock + EQ.shockwave
    elseif verb == "synchronise" or verb == "overcharge" then
      weave(verb, words[2], words[3], t)
      me.eq = clock + EQ[verb]
    else
      return false
    end
  end
  return true
end

-- The curer ---------------------------------------------------------------------------------------
-- Anti-lock: the lock afflictions first, then WunderSys's order. WunderSys: its default order alone.
-- Grulk (from the 2026-11-03 spar): impatience before anything, paralysis late, asthma left mostly to
-- fitness every 10s, which he has and the others don't unless --fitness.
local LOCK = { "anorexia", "asthma", "slickness", "impatience", "paralysis" }
local GRULK = { "impatience", "anorexia", "slickness", "paralysis", "asthma" }
local priority = {}
if opts.curer == "antilock" then
  for i, aff in ipairs(LOCK) do priority[aff] = i end
elseif opts.curer == "grulk" then
  for i, aff in ipairs(GRULK) do priority[aff] = i end
  opts.fitness = true
end
for aff, p in pairs(CURES.profiles.wsys) do
  if not aff:find("%(") and not priority[aff] then priority[aff] = 10 + p end
end
local function rank(aff) return priority[aff] or 99 end

local BLOCKED_BY = { eat = "anorexia", smoke = "asthma", apply = "slickness", focus = "impatience", tree = "paralysis",
  fitness = "weariness" }
local HERB_ITEM = { kelp = "piece of kelp", goldenseal = "goldenseal root", bloodroot = "bloodroot leaf",
  lobelia = "lobelia seed", ash = "prickly ash bark", ginseng = "ginseng root", bellwort = "bellwort flower",
  ginger = "ginger root", pear = "prickly pear" }
local SPOT_WORD = { body = "body", legs = "legs", arms = "arms", head = "head" }
-- Restoration cures in the game's own order: torso trauma before heartseed.
local RESTORE_ORDER = {
  body = { "mildtrauma", "serioustrauma", "heartseed", "internalbleeding", "calcifiedtorso", "hypothermia" },
}

-- Every cure each channel could do right now: { aff, how, line }.
local function options(channel)
  local list = {}
  local function add(aff, how) if has(aff) then list[#list + 1] = { aff = aff, how = how } end end
  if channel == "eat" then
    for herb, affs in pairs(CURES.eat) do for _, aff in ipairs(affs) do add(aff, herb) end end
  elseif channel == "smoke" then
    for herb, affs in pairs(CURES.smoke) do for _, aff in ipairs(affs) do add(aff, herb) end end
  elseif channel == "focus" then
    for _, aff in ipairs(CURES.focus) do add(aff, "focus") end
  elseif channel == "apply" then
    for key, affs in pairs(CURES.apply) do
      local salve, spot = key:match("^(%a+)%.(%a+)$")
      if salve and SPOT_WORD[spot] and not (salve == "restoration" and truth.restoring[spot]) then
        for _, aff in ipairs(affs) do add(aff, key) end
      end
    end
  end
  table.sort(list, function(a, b)
    if rank(a.aff) ~= rank(b.aff) then return rank(a.aff) < rank(b.aff) end
    return a.aff < b.aff
  end)
  return list
end

local function blocked(channel)
  return BLOCKED_BY[channel] and has(BLOCKED_BY[channel])
    or (channel == "apply" and next(truth.restoring) ~= nil)
end

local function useChannel(channel)
  if truth.ready[channel] > clock or blocked(channel) then return end
  local t = TARGET
  if channel == "fitness" then
    if not opts.fitness or not has("asthma") then return end
    line(t .. " draws a deep, measured breath.")
    cure("asthma")
    say("<  fitness -> asthma")
  elseif channel == "tree" then
    if not opts.tree then return end
    local pool = {}
    for _, aff in ipairs(CURES.tree) do if has(aff) then pool[#pool + 1] = aff end end
    if #pool == 0 then return end
    local aff = pool[math.random(#pool)]
    line(t .. " touches a tree of life tattoo.")
    cure(aff)
    say("<  tree -> " .. aff)
  elseif channel == "stand" then
    if not has("prone") then return end
    if has("paralysis") or legBroken() then return end
    line(t .. " stands up.")
    cure("prone")
    say("<  stands")
  else
    local choice = options(channel)[1]
    if not choice then return end
    if channel == "eat" then
      line(t .. " eats " .. (HERB_ITEM[choice.how]:match("^[aeiou]") and "an " or "a ") .. HERB_ITEM[choice.how] .. ".")
      cure(choice.aff)
    elseif channel == "smoke" then
      line(t .. " takes a long drag off his pipe.")
      cure(choice.aff)
    elseif channel == "focus" then
      line("A look of extreme focus crosses the face of " .. t .. ".")
      cure(choice.aff)
    elseif channel == "apply" then
      local salve, spot = choice.how:match("^(%a+)%.(%a+)$")
      line(t .. " takes some salve from a vial and rubs it on his " .. SPOT_WORD[spot] .. ".")
      if salve == "restoration" then
        truth.restoring[spot] = clock + RESTORATION_DELAY
      else
        cure(choice.aff)
      end
    end
    say("<  " .. (channel == choice.how and channel or channel .. " " .. choice.how) .. " -> " .. (choice.how:find("^restoration") and "(lands in 4s)" or choice.aff))
  end
  truth.ready[channel] = clock + CURE_GAP[channel] + REACTION
  return true
end

local function landRestorations()
  for spot, at in pairs(truth.restoring) do
    if at <= clock then
      truth.restoring[spot] = nil
      local order = RESTORE_ORDER[spot]
      if not order then
        order = {}
        for _, aff in ipairs(CURES.apply["restoration." .. spot]) do order[#order + 1] = aff end
        table.sort(order, function(a, b) return a:find("^damaged") ~= nil and b:find("^damaged") == nil end)
      end
      -- Restoration takes a limb one step back: mangled to damaged, damaged to broken (which still
      -- needs mending), mildtrauma to whole.
      for _, aff in ipairs(order) do
        if has(aff) then
          cure(aff)
          local limb = aff:match("^damaged(%a+)$") or aff:match("^mangled(%a+)$")
          local back = aff:find("^mangled") and "damaged" .. limb or limb and "broken" .. limb
            or aff == "serioustrauma" and "mildtrauma"
          if back then gain(back) end
          say("<  restoration on " .. spot .. " lands -> " .. aff .. (back and " (now " .. back .. ")" or ""))
          break
        end
      end
    end
  end
end

local function breathe()
  if not opts.holdbreath or truth.holdbreath then return end
  if truth.exhaledAt and clock - truth.exhaledAt < 4 then return end
  truth.holdbreath = true
  line(TARGET .. " inhales and begins holding his breath.")
  say("<  holds breath")
end

-- The fight ---------------------------------------------------------------------------------------
local WATCH = { "anorexia", "asthma", "slickness", "impatience", "paralysis", "dizziness", "heartseed" }

local function fight(seed)
  math.randomseed(seed)
  clock = clock + 600
  start = clock
  truth = { affs = {}, limbs = {}, restoring = {}, ready = {} }
  for channel in pairs(CURE_GAP) do truth.ready[channel] = clock end
  me = { eq = clock, bal = clock }
  world = { disturbed = false, ae = 0 }
  S.weather = {}
  Opponent.pending = {}
  Opponent.apply({ kind = "reset", name = TARGET })
  pk.routeChoice.sylvan = opts.route
  if S.reset then S.reset() end

  local result = { actions = {}, lockAt = nil, locked = 0, maxLock = 0, wrong = {}, unknown = {} }
  for _, aff in ipairs(WATCH) do result.wrong[aff] = { ghost = 0, missed = 0 } end
  local nextTick = clock
  while clock - start < opts.seconds do
    landRestorations()
    for _, channel in ipairs({ "tree", "apply", "eat", "smoke", "focus", "fitness", "stand" }) do
      if useChannel(channel) then prompt() end
    end
    breathe()
    if truth.heartseedAt and has("heartseed") and clock - truth.heartseedAt >= HEARTSEED_KILL then
      line("Horror seizes " .. TARGET .. "'s features as his skin rapidly withers and parches.")
      result.killed = clock - start
      say("** heartseed kills")
      break
    end
    if truth.heartseedAt and not has("heartseed") then truth.heartseedAt = nil end

    if me.eq <= clock and me.bal <= clock then
      local name, action, command = pk.choose()
      if command then
        result.actions[name] = (result.actions[name] or 0) + 1
        local before = {}
        for aff in pairs(truth.affs) do before[aff] = true end
        local ok = perform(command)
        local landed = {}
        for aff in pairs(truth.affs) do if not before[aff] then landed[#landed + 1] = "+" .. aff end end
        table.sort(landed)
        say(">  " .. command .. "   [" .. name .. "]" .. (#landed > 0 and "  " .. table.concat(landed, " ") or ""))
        if ok then
          if action.fired then action.fired() end
        else
          result.unknown[command] = true
          me.eq = clock + 2
        end
        prompt()
      end
    end

    if clock >= nextTick then
      nextTick = clock + Opponent.TICK_MS / 1000
      Opponent.flush(true)
      Opponent.checkOverdue()
    end

    -- How the lock stands, and how far the tracker's belief is from the truth.
    local count = 0
    for _, aff in ipairs(LOCK) do if has(aff) then count = count + 1 end end
    result.maxLock = math.max(result.maxLock, count)
    if count == #LOCK then
      result.locked = result.locked + TICK
      result.lockAt = result.lockAt or (clock - start)
    end
    for _, aff in ipairs(WATCH) do
      local believed = T.has(aff)
      if believed and not has(aff) then result.wrong[aff].ghost = result.wrong[aff].ghost + TICK end
      if has(aff) and not believed then result.wrong[aff].missed = result.wrong[aff].missed + TICK end
    end
    clock = clock + TICK
  end
  result.seconds = clock - start
  result.final = {}
  for aff in pairs(truth.affs) do result.final[#result.final + 1] = aff end
  table.sort(result.final)
  return result
end

-- Report ------------------------------------------------------------------------------------------
local function report(r)
  print(string.format("\nroute %s vs %s curer, %.1fs%s%s", opts.route, opts.curer, r.seconds,
    r.killed and string.format(", heartseed killed at %.1fs", r.killed) or "",
    r.lockAt and string.format(", true lock at %.1fs (held %.1fs)", r.lockAt, r.locked) or ", never locked"))
  print("most lock affs at once: " .. r.maxLock .. "/" .. #LOCK .. " (" .. table.concat(LOCK, ", ") .. ")")
  print("still on them at the end: " .. (#r.final > 0 and table.concat(r.final, ", ") or "nothing"))
  local names = {}
  for name, n in pairs(r.actions) do names[#names + 1] = string.format("%s x%d", name, n) end
  table.sort(names)
  print("actions: " .. table.concat(names, ", "))
  print("tracker vs truth (seconds believed but absent / present but not believed):")
  for _, aff in ipairs(WATCH) do
    local w = r.wrong[aff]
    if w.ghost > 0 or w.missed > 0 then
      print(string.format("  %-12s %5.1f / %5.1f", aff, w.ghost, w.missed))
    end
  end
  for command in pairs(r.unknown) do print("sim doesn't know: " .. command) end
end

if opts.runs == 1 then
  report(fight(opts.seed))
else
  local locks, kills, maxLock, lockTime = 0, 0, 0, 0
  for run = 1, opts.runs do
    local r = fight(opts.seed + run)
    if r.lockAt then locks = locks + 1; lockTime = lockTime + r.lockAt end
    if r.killed then kills = kills + 1 end
    maxLock = maxLock + r.maxLock
  end
  print(string.format("route %s vs %s curer over %d fights of %ds: locked %d, heartseed kills %d, avg best lock %.1f/%d%s",
    opts.route, opts.curer, opts.runs, opts.seconds, locks, kills, maxLock / opts.runs, #LOCK,
    locks > 0 and string.format(", avg time to lock %.1fs", lockTime / locks) or ""))
end
