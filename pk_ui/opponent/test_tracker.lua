-- To run: lua5.1 opponent/test_tracker.lua   (from pk_ui)
-- Needs the PCRE2 binding: luarocks --lua-version 5.1 install --local lrexlib-pcre2
--
-- Loads the real tracker and parsers with MudForge stand-ins, then feeds real game lines
-- through every registered regex, the way MudForge does. MudForge's regexes are JavaScript
-- flavour; PCRE2 agrees with it on everything these patterns use.
package.cpath = os.getenv("HOME") .. "/.luarocks/lib/lua/5.1/?.so;" .. package.cpath
local rex = require("rex_pcre2")

local failures = 0
local function fail(message)
  failures = failures + 1
  print("FAIL " .. message)
end
local function check(label, got, want)
  local ok = math.abs(got - want) < 0.005
  if not ok then failures = failures + 1 end
  print(string.format("%s %-52s got %.3f want %.3f", ok and "ok  " or "FAIL", label, got, want))
end
local function same(label, got, want)
  local ok = got == want
  if not ok then failures = failures + 1 end
  print(string.format("%s %-52s got %s want %s", ok and "ok  " or "FAIL", label, tostring(got), tostring(want)))
end

-- MudForge stand-ins ----------------------------------------------------------------------
local triggers, promptHooks, clock, currentTarget = {}, {}, 1000, "Bob"

function addTrigger(pattern, fn, opts)
  local ok, compiled = pcall(rex.new, pattern)
  if not ok then
    fail("pattern does not compile: " .. pattern .. "\n     " .. tostring(compiled))
    return ""
  end
  triggers[#triggers + 1] = { pattern = pattern, regex = compiled, fn = fn }
  return tostring(#triggers)
end
function addAlias() return "" end
function addTimer() return "" end
function onGMCPUpdate() end
function cecho() end
function getVariable() end
function setVariable() end
function getCurrentTime() return clock * 1000 end
function loadModule(path) return dofile(path) end

Opponent = {
  host = {
    target = function() return currentTarget end,
    note = function() end,
    onPrompt = function(_, fn) promptHooks[#promptHooks + 1] = fn end,
  },
}
dofile("opponent/tracker.lua")
local o, M = Opponent, Opponent.Model

-- Helpers -------------------------------------------------------------------------------------
-- One line from the game: every matching trigger fires, with captures counted from 1.
local function line(text)
  local hits = 0
  for _, trigger in ipairs(triggers) do
    local found = { trigger.regex:tfind(text) }
    if found[1] then
      local wildcards = {}
      for i, capture in ipairs(found[3] or {}) do
        if capture then wildcards[i] = capture end
      end
      trigger.fn(nil, text, wildcards)
      hits = hits + 1
    end
  end
  if hits == 0 then fail("no trigger matched: " .. text) end
end
local function prompt()
  for _, hook in ipairs(promptHooks) do hook() end
end
local function wait(seconds)
  clock = clock + seconds
end
-- A fresh Bob, far enough from the last test that no cure gap or illusion window carries over.
local function fresh()
  wait(60)
  o.pending = {}
  o.apply({ kind = "reset", name = "Bob" })
  return o.get("Bob")
end
local function p(aff) return M.prob(o.get("Bob"), aff) end
local function bob() return o.get("Bob") end

-- Defences --------------------------------------------------------------------------------------
fresh()
line("A nearly invisible magical shield forms around Bob.")
prompt()
same("shield forms", bob().shield, "shield")
line("You flay away Bob's shield defence.")
prompt()
same("flayed", bob().shield, "no")

fresh()
line("A nearly invisible magical shield forms around Bob.")
line("Bob leaves to the north.")
prompt()
same("moving drops the shield", bob().shield, "no")

fresh()
line("** Illusion **")
line("A nearly invisible magical shield forms around Bob.")
prompt()
same("an illusory shield is ignored", bob().shield, "unknown")

fresh()
line("A shimmering curseward appears around Bob.")
line("Bob inhales and begins holding his breath.")
prompt()
same("curseward up", bob().curseward, "curseward")
same("holding breath", bob().holdbreath, "holdbreath")
line("Bob exhales loudly.")
prompt()
same("breath let out", bob().holdbreath, "no")

local t = fresh()
M.gainMaybe(t, "paralysis", 0.5)
line("Bob easily vaults onto the back of a black stallion.")
prompt()
same("vaulted", bob().mounted, "mounted")
check("vaulting proves no paralysis", p("paralysis"), 0)

-- Speed and sipping -------------------------------------------------------------------------
fresh()
line("You flay away Bob's speed defence.")
line("Bob takes a drink from a glass vial.")
prompt()
same("stripped, just sipped", bob().speed, "no")
wait(o.SPEED_DELAY)
prompt()
same("speed back after the sip", bob().speed, "speed")

fresh()
line("Bob takes a drink from a glass vial.")
wait(o.SPEED_DELAY)
prompt()
same("a sip never claims speed we didn't see go", bob().speed, "unknown")

t = fresh()
M.gainMaybe(t, "voyria", 0.5)
M.gainMaybe(t, "anorexia", 0.5)
M.gain(t, "asthma")
line("Bob takes a drink from a glass vial.")
prompt()
check("any sip clears voyria", p("voyria"), 0)
check("sipping proves no anorexia", p("anorexia"), 0)
check("and leaves the rest", p("asthma"), 1)

-- Announced cures -----------------------------------------------------------------------------
t = fresh()
M.gain(t, "shadowmadness")
M.gain(t, "asthma")
M.gainMaybe(t, "voyria", 0.5)
line("A demonic crimson glow emanates from Bob.")
line("Lucidity returns to the eyes of Bob.")
prompt()
check("passive then announce: took shadowmadness", p("shadowmadness"), 0)
check("not a random one", p("asthma"), 1)
check("and voyria wasn't there to go first", p("voyria"), 0)

t = fresh()
M.gain(t, "unweavingmind", 3)
line("The light behind the eyes of Bob reignites.")
prompt()
same("an announce alone takes one stack", bob().states[1].affs.unweavingmind, 2)

t = fresh()
M.gain(t, "guilt")
M.gain(t, "claustrophobia")
line("Bob eats a lobelia seed.")
line("Bob straightens, as if some great burden had been lifted from his shoulders.")
prompt()
check("lobelia then guilt: took guilt", p("guilt"), 0)
check("not claustrophobia", p("claustrophobia"), 1)

-- Burning, tension, mickey ----------------------------------------------------------------------
t = fresh()
M.gain(t, "burning", 2)
M.gain(t, "mildtrauma")
line("Bob takes some salve from a vial and rubs it on his body.")
line("The fires consuming Bob diminish somewhat.")
prompt()
same("mending takes one burning stack", bob().states[1].affs.burning, 1)
check("and nothing else", p("mildtrauma"), 1)
same("one state, no branching", #bob().states, 1)

t = fresh()
M.gain(t, "burning", 3)
line("Bob saturates himself with water, putting out the fire that raged.")
prompt()
check("water puts the fire out", p("burning"), 0)

t = fresh()
M.gain(t, "tension")
line("Bob sucks in a great gasp of air.")
line("Bob pops a mickey into his mouth.")
prompt()
check("gasp of air ends tension", p("tension"), 0)
check("a mickey gives nausea", p("nausea"), 1)

-- Class cures -----------------------------------------------------------------------------------
t = fresh()
M.gain(t, "asthma")
M.gain(t, "clumsiness")
M.gainMaybe(t, "prone", 0.5)
line("A look of relief comes over Bob as he grows less pale.")
line("Bob grows older before your eyes.")
prompt()
check("boosted accelerate cures two", p("asthma") + p("clumsiness"), 0)
check("and proves no prone", p("prone"), 0)

t = fresh()
M.gain(t, "paralysis")
line("Alice presses a tarot to Bob's forehead, producing a wan smile.")
prompt()
same("fool from someone else: class untouched", bob().class, nil)
check("but it still cures", p("paralysis"), 0)

t = fresh()
M.gain(t, "asthma")
line("The amorphous form of Bob trembles, some of the liquid composing it falling away from the greater whole.")
prompt()
same("purify narrows to waterlord", bob().class, "waterlord")
check("and cures", p("asthma"), 0)

t = fresh()
M.gain(t, "asthma")
M.gain(t, "brokenleftarm")
M.gain(t, "damagedrightleg")
line("Bob crackles with blue energy that wreathes itself about his limbs.")
prompt()
check("restore mends broken limbs", p("brokenleftarm"), 0)
check("but not damaged ones", p("damagedrightleg"), 1)
line("The room is consumed in an explosion of light, out of which Bob emerges refreshed and renewed.")
prompt()
check("sacrifice cures everything", p("asthma") + p("damagedrightleg"), 0)
same("and narrows to priest", bob().class, "priest")

-- Limbs -------------------------------------------------------------------------------------------
t = fresh()
M.gain(t, "damagedleftleg")
line("Bob screams as his left leg is crushed.")
line("An alabaster pegasus breaks the right arm of Bob.")
prompt()
check("a trample never heals a damaged leg", p("damagedleftleg"), 1)
check("or adds broken beside it", p("brokenleftleg"), 0)
check("pegasus breaks the arm", p("brokenrightarm"), 1)
line("Bob's torso has been beaten into uselessness.")
line("Bob's left leg has been beaten into uselessness.")
prompt()
check("useless torso is serious trauma", p("serioustrauma"), 1)
check("useless leg is mangled", p("mangledleftleg"), 1)
check("and no longer damaged", p("damagedleftleg"), 0)

-- Our attacks and misses (Sylvan rend) ---------------------------------------------------------
local RUB = "You rub some curare on the thorny vines covering your arms."
local REND = "You command the razor-edged thorny vines around you to lash out and rend the flesh of Bob."
-- A curare rend on a fresh Bob, followed by the result line if any. Returns the paralysis left.
local function rendWith(result)
  fresh()
  o.offense.arms = nil
  line(RUB)
  line(REND)
  if result then line(result) end
  prompt()
  return p("paralysis")
end
check("parried rend lands nothing", rendWith("Bob parries the attack with a deft manoeuvre."), 0)
check("dodged rend lands nothing", rendWith("Bob dodges nimbly out of the way."), 0)
check("rebounded rend lands nothing", rendWith("The attack rebounds onto you!"), 0)
check("a clean rend lands curare", rendWith(nil), 1)

fresh()
line("A nearly invisible magical shield forms around Bob.")
prompt()
line(REND)
prompt()
same("a landed rend proves no shield", bob().shield, "no")

fresh()
line("You command the razor-edged thorny vines around you to lash out and rend the left leg of Bob.")
line("As you carve into Bob, you perceive that you have dealt 23.5% damage to his left leg.")
prompt()
check("carve records limb damage", bob().limbs.leftleg.damage, 23.5)

print(failures == 0 and "all passed" or (failures .. " failed"))
