-- To run: lua5.1 opponent/test_model.lua
local Model = dofile("opponent/model.lua")
Model.load(dofile("opponent/cures.lua"))
local Queries = dofile("opponent/queries.lua")
local LIMB_RULES = dofile("opponent/limb_rules.lua")
Model.LIMB = LIMB_RULES
Queries.LIMB = LIMB_RULES
local VENOMS = dofile("opponent/offense/venoms.lua")

local failures = 0
local function check(label, got, want)
  local ok = math.abs(got - want) < 0.005
  if not ok then failures = failures + 1 end
  print(string.format("%s %-48s got %.3f want %.3f", ok and "ok  " or "FAIL", label, got, want))
end

local t = Model.newTarget("Bob")
Model.gain(t, "asthma")
Model.cure(t, "eat:kelp")
check("only candidate is cured outright", Model.prob(t, "asthma"), 0)

t = Model.newTarget("Bob")
Model.gain(t, "asthma")
Model.gain(t, "clumsiness")
Model.cure(t, "eat:kelp")
-- both are kelp-curable and the game picks at random: an even split.
check("kelp cures one of the two at random", Model.prob(t, "asthma"), 0.5)
check("clumsiness kept half the time", Model.prob(t, "clumsiness"), 0.5)

t = Model.newTarget("Bob")
Model.gain(t, "paralysis")
Model.gain(t, "slickness")
Model.cure(t, "eat:bloodroot")
-- both are bloodroot-curable: an even split, priority doesn't pick.
check("bloodroot cures one of the two at random", Model.prob(t, "paralysis"), 0.5)

t = Model.newTarget("Bob")
Model.gain(t, "brokenleftarm")
Model.gain(t, "agoraphobia")
t.weights = { pk = 1 }
Model.proof(t, "agoraphobia", true)
check("proof present keeps it", Model.prob(t, "agoraphobia"), 1)
Model.cure(t, "eat:lobelia")
check("lobelia cures its only candidate", Model.prob(t, "agoraphobia"), 0)

t = Model.newTarget("Bob")
Model.gain(t, "asthma")
Model.gain(t, "clumsiness")
Model.cure(t, "eat:kelp")
Model.proof(t, "asthma", true)
check("asthma proof means kelp took clumsiness", Model.prob(t, "clumsiness"), 0)
check("asthma certain after proof", Model.prob(t, "asthma"), 1)

t = Model.newTarget("Bob")
Model.gain(t, "pressure", 6)
Model.cure(t, "eat:pear")
check("pear takes one stack of pressure", t.states[1].affs.pressure, 5)

t = Model.newTarget("Bob")
Model.cure(t, "eat:kelp")
check("cure of nothing leaves one state", #t.states, 1)

t = Model.newTarget("Bob")
t.states = {
  { p = 0.5, affs = { asthma = true, paralysis = true } },
  { p = 0.5, affs = { asthma = true } },
}
Model.cure(t, "eat:kelp")
-- every profile would eat bloodroot first if paralysed (Except freaking Murray), so the paralysis picture scores 0.1 against 1.0.
check("eating kelp is evidence against paralysis", Model.prob(t, "paralysis"), 0.05 / 0.55)
check("asthma was the only kelp candidate", Model.prob(t, "asthma"), 0)

t = Model.newTarget("Bob")
for _, aff in ipairs({ "asthma", "clumsiness", "weariness", "sensitivity", "healthleech", "parasite" }) do Model.gain(t, aff) end
for _ = 1, 6 do Model.cure(t, "eat:kelp") end
check("six kelp eats clear six kelp affs", Model.prob(t, "parasite") + Model.prob(t, "asthma"), 0)
check("state count stays bounded", #t.states <= Model.MAX_STATES and 1 or 0, 1)

t = Model.newTarget("Bob")
for _, aff in ipairs({ "anorexia", "asthma", "slickness" }) do Model.gain(t, aff) end
check("softlocked before tree", Queries.lock(t, "softlock"), 1)
Model.cure(t, "tree")
check("tree always breaks the softlock", Queries.lock(t, "softlock"), 0)
check("each pair survives a third of the time", Queries.probAll(t, { "asthma", "slickness" }), 1 / 3)
check("each single aff is two thirds", Queries.prob(t, "asthma"), 2 / 3)
check("has() at LIKELY says no to two thirds", Queries.has(t, "asthma") and 1 or 0, 0)

t = Model.newTarget("Bob")
for _, aff in ipairs({ "anorexia", "asthma", "slickness", "paralysis" }) do Model.gain(t, aff) end
check("venomlocked", Queries.lock(t, "venomlock"), 1)
check("not hardlocked without impatience", Queries.lock(t, "hardlock"), 0)
check("eat is shut", Queries.channelOpen(t, "eat"), 0)
check("tree is shut", Queries.channelOpen(t, "tree"), 0)
check("focus is the way out", Queries.channelOpen(t, "focus"), 1)
check("truelock needs the class aff", Queries.lock(t, "truelock", { "weariness" }), 0)
check("extra doesn't change the lock list", #Queries.LOCKS.truelock, 5)

t = Model.newTarget("Bob")
Model.gain(t, "unweavingbody", 4)
Model.removeOne(t, "unweavingbody")
check("announced cure takes one stack", t.states[1].affs.unweavingbody, 3)
Model.removeOne(t, "nausea")
check("removeOne of a missing aff changes nothing", #t.states, 1)

Model.addCure("smoke:skullcap", { "norebounding" })
local SMOKES = { "smoke:elm", "smoke:valerian", "smoke:skullcap" }

t = Model.newTarget("Bob")
Model.gain(t, "slickness")
Model.gain(t, "norebounding")
Model.cureUnknown(t, SMOKES)
check("an affliction beats rebounding", Model.prob(t, "slickness"), 0.1 / 1.1)

t = Model.newTarget("Bob")
t.states = { { p = 0.5, affs = { slickness = true, norebounding = true } }, { p = 0.5, affs = { norebounding = true } } }
Model.cureUnknown(t, SMOKES)
check("cured or never there, slickness is gone", Model.prob(t, "slickness") < 0.06 and 1 or 0, 1)

local LEGS = { "apply:mending.legs", "apply:restoration.legs", "apply:health.legs" }

t = Model.newTarget("Bob")
Model.gain(t, "brokenleftleg")
Model.gain(t, "brokenrightleg")
Model.cureUnknown(t, LEGS)
check("mending takes the left leg first", Model.prob(t, "brokenrightleg"), 1)

t = Model.newTarget("Bob")
Model.gain(t, "damagedleftleg")
Model.cureUnknown(t, LEGS)
check("restoration waits: still damaged", Model.prob(t, "damagedleftleg"), 1)
Model.land(t, "apply:restoration.legs")
check("restoration lands: damaged becomes broken", Model.prob(t, "brokenleftleg") > 0.95 and 1 or 0, 1)

t = Model.newTarget("Bob")
for _, aff in ipairs({ "anorexia", "asthma", "restoring.legs" }) do Model.gain(t, aff) end
table.insert(Queries.BLOCKERS.apply, "restoring.legs")
check("a pending restoration counts as slick for a softlock", Queries.lock(t, "softlock"), 1)
check("and shuts the apply channel", Queries.channelOpen(t, "apply"), 0)

t = Model.newTarget("Bob")
Model.gain(t, "prone")
t.states = { { p = 0.5, affs = { prone = true, paralysis = true } }, { p = 0.5, affs = { prone = true } } }
Model.proof(t, "paralysis", false)
Model.cure(t, "stand")
check("standing proves no paralysis", Model.prob(t, "paralysis"), 0)
check("and cures prone", Model.prob(t, "prone"), 0)

t = Model.newTarget("Bob")
t.states = { { p = 0.5, affs = { prone = true, brokenrightleg = true } }, { p = 0.5, affs = { prone = true } } }
for _, blocker in ipairs(Queries.BLOCKERS.stand) do Model.proof(t, blocker, false) end
check("standing proves the right leg is fine", Model.prob(t, "brokenrightleg"), 0)

t = Model.newTarget("Bob")
for _, aff in ipairs({ "anorexia", "asthma", "slickness", "norebounding" }) do Model.gain(t, aff) end
Model.cureRandom(t, 1)
check("random cure never takes a defence", Model.prob(t, "norebounding"), 1)
check("random cure takes one of three", Model.prob(t, "asthma"), 2 / 3)

t = Model.newTarget("Bob")
Model.gain(t, "voyria")
Model.gain(t, "asthma")
Model.cureRandom(t, 1, nil, { "voyria" })
check("passives cure voyria first", Model.prob(t, "voyria"), 0)

t = Model.newTarget("Bob")
t.states = { { p = 0.5, affs = { brokenleftarm = true, brokenrightarm = true } }, { p = 0.5, affs = { brokenleftarm = true } } }
Model.proofNotAll(t, { "brokenleftarm", "brokenrightarm" })
check("bloodboil proves not both arms", Model.prob(t, "brokenrightarm"), 0)

t = Model.newTarget("Bob")
Model.gain(t, "asthma")
Model.gain(t, "nofangbarrier")
Model.cureRandom(t, 1)
check("random cure never takes the barrier", Model.prob(t, "nofangbarrier"), 1)

t = Model.newTarget("Bob")
Model.deliver(t, VENOMS.curare)
check("a plain venom lands", Model.prob(t, "paralysis"), 1)

t = Model.newTarget("Bob")
t.deaf = "deaf"
Model.deliver(t, VENOMS.prefarar)
check("prefarar on a deaf target gives nothing", Model.prob(t, "sensitivity"), 0)
check("and strips deafness", t.deaf == "no" and 1 or 0, 1)

t = Model.newTarget("Bob")
Model.deliver(t, VENOMS.prefarar)
check("prefarar on unknown deafness is a coin flip", Model.prob(t, "sensitivity"), 0.5)
check("but deafness is known gone after", t.deaf == "no" and 1 or 0, 1)
Model.deliver(t, VENOMS.prefarar)
check("a second prefarar lands for sure", Model.prob(t, "sensitivity"), 1)

t = Model.newTarget("Bob")
Model.deliver(t, VENOMS.colocasia)
check("colocasia gives the blind defence", t.blind == "blind" and 1 or 0, 1)

t = Model.newTarget("Bob")
Model.deliver(t, VENOMS.epteth)
check("epteth breaks the left arm first", Model.prob(t, "brokenleftarm"), 1)
Model.deliver(t, VENOMS.epteth)
check("then the right arm", Model.prob(t, "brokenrightarm"), 1)

t = Model.newTarget("Bob")
t.states = { { p = 0.6, affs = { damagedleftarm = true } }, { p = 0.4, affs = {} } }
Model.deliver(t, VENOMS.epteth)
check("a maybe-hurt left arm puts the break right", Model.prob(t, "brokenrightarm"), 0.6)
check("or left", Model.prob(t, "brokenleftarm"), 0.4)

t = Model.newTarget("Bob")
Model.deliver(t, VENOMS.delphinium)
check("a shown venom leaves the gain to its line", Model.prob(t, "sleeping"), 0)
check("but always settles the defence", t.insomnia == "no" and 1 or 0, 1)

t = Model.newTarget("Bob")
for i = 1, 4 do Model.limbDamage(t, "leftarm", 24, i) end
check("four 24% hits sit at 96", t.limbs.leftarm.damage, 96)
check("and the arm is still healthy", Model.prob(t, "damagedleftarm"), 0)
Model.limbDamage(t, "leftarm", 24, 5)
check("the fifth crosses 100: damaged", Model.prob(t, "damagedleftarm"), 1)
check("and the extra 20 is thrown away", t.limbs.leftarm.damage, 0)

t = Model.newTarget("Bob")
Model.gain(t, "brokenleftarm")
Model.limbDamage(t, "leftarm", 120, 1)
check("broken over 100 becomes damaged", Model.prob(t, "damagedleftarm"), 1)
check("not damaged and broken", Model.prob(t, "brokenleftarm"), 0)
Model.limbDamage(t, "leftarm", 100, 2)
check("damaged over 100 becomes mangled", Model.prob(t, "mangledleftarm"), 1)
Model.limbDamage(t, "leftarm", 100, 3)
check("mangled is the last step", Model.prob(t, "mangledleftarm"), 1)

t = Model.newTarget("Bob")
Model.limbDamage(t, "torso", 100, 1)
check("torso's first step is mild trauma", Model.prob(t, "mildtrauma"), 1)
Model.limbDamage(t, "torso", 100, 2)
check("then serious trauma", Model.prob(t, "serioustrauma"), 1)

t = Model.newTarget("Bob")
t.states = { { p = 0.6, affs = { damagedleftleg = true } }, { p = 0.4, affs = {} } }
Model.limbDamage(t, "leftleg", 100, 1)
check("a maybe-damaged leg steps per state: mangled", Model.prob(t, "mangledleftleg"), 0.6)
check("or damaged", Model.prob(t, "damagedleftleg"), 0.4)

t = Model.newTarget("Bob")
Model.limbDamage(t, "head", 90, 0)
Model.limbDamage(t, "head", 20, 200)
check("damage left alone past the decay is gone", t.limbs.head.damage, 20)
check("so 90 then 20 much later doesn't step", Model.prob(t, "damagedhead"), 0)

  t = Model.newTarget("Bob")
Model.gain(t, "slickness")
Model.gain(t, "asthma")
Model.gain(t, "weariness")
Model.cure(t, "eat:kelp")
for _ = 1, 5 do
  Model.overdue(t, "smoke", { "asthma" }, 0.7 ^ 0.2)
end
check("a second with no smoke favours asthma", Model.prob(t, "asthma"), 0.588)

t = Model.newTarget("Bob")
t.states = { { p = 0.5, affs = { damagedleftarm = true, mangledrightarm = true } }, { p = 0.5, affs = { brokenleftarm = true } } }
Model.proofNotAll(t, { "leftarm", "rightarm" })
check("both arms out at any level is ruled out", Model.prob(t, "mangledrightarm"), 0)
check("one arm out survives", Model.prob(t, "brokenleftarm"), 1)

print(failures == 0 and "all passed" or (failures .. " failed"))
