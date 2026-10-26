local Model = {}

-- Notes for future me because I'm gonna forget why i did this....
-- AK does concrete numbers, if you have 2 kelp afflictions and you eat kelp,
-- 50% chance you have one or the other. Thats...ok,
-- But when they cure in a way we CAN'T see (Tree, class cures that don't give cured messasges)
-- Then AK's system falls apart. We need to branch at that point, with every cure -possibly- being cured
-- and then look going forward for confirmations of what DID cure. i.e they had slickness, asthma and anorexia
-- if they touch tree and smoke, tree cured asthma etc. So we need multiple potential states... 
-- then have to reconcile them later.  Probably going to regret this SOOO hard.

-- The idea:
-- Herbs all share one balance. When their system eats kelp, it is telling us "the highest-priority thing I 
-- could fix with a herb right now is something kelp cures." For each state 
-- (each picture of the target) we ask: if this picture were true, how likely is it that 
-- their system would have eaten kelp? States where kelp is the obvious choice keep their 
-- weight. States where they should have eaten something else lose most of it.

-- Additionally, and this is big brain crap that Claude's pushing me towards
-- but we could start preserving curing profiles for people (dangerous nerd activity here...)

Model.PRUNE = 0.01
Model.MAX_STATES = 50
Model.SLACK = 0.1
Model.UNKNOWN_TIER = 99
Model.DEFAULT_WEIGHTS = {
    wsys = 0.5,
    pk = 0.3,
    game = 0.2
}
-- How likely a defence we know nothing about is up, when a hit has to strip it first.
Model.UNKNOWN_DEFENCE = 0.5
Model.NOTHING = 0.01

-- Restoration turns these into the next stage instead of curing them outright.
Model.TRANSFORMS = {
    mangledleftleg = "damagedleftleg",    damagedleftleg = "brokenleftleg",
    mangledrightleg = "damagedrightleg",    damagedrightleg = "brokenrightleg",
    mangledleftarm = "damagedleftarm",    damagedleftarm = "brokenleftarm",
    mangledrightarm = "damagedrightarm",    damagedrightarm = "brokenrightarm",
    mangledhead = "damagedhead",    serioustrauma = "mildtrauma"
}

-- Limb salves cure the left limb before the right.
Model.LEFT_FIRST = {
    ["apply:mending.arms"] = true,    ["apply:mending.legs"] = true,
    ["apply:restoration.arms"] = true,    ["apply:restoration.legs"] = true
}

-- Restoration lands about 4 s after the apply. The value is the marker its branches carry until then.
Model.DELAYED = {
    ["apply:restoration.arms"] = "restoring.arms",    ["apply:restoration.legs"] = "restoring.legs",
    ["apply:restoration.head"] = "restoring.head",    ["apply:restoration.body"] = "restoring.body"
}

-- Made-up afflictions that track defences or pending cures. Random cures never pick these.
Model.PSEUDO = { norebounding = true, nodensity = true, nofangbarrier = true }
for _, marker in pairs(Model.DELAYED) do
    Model.PSEUDO[marker] = true
end


-- Load our cures data and mappings
function Model.load(data)
    Model.data = data
    Model.cureSets = {}
    local function addCureSet(key, list)
        local set = {}
        for _, aff in ipairs(list) do
            set[aff] = true
        end
        Model.cureSets[key] = set
    end
    for item, list in pairs(data.eat) do
        addCureSet("eat:" .. item, list)
    end
    for item, list in pairs(data.smoke) do
        addCureSet("smoke:" .. item, list)
    end
    for spot, list in pairs(data.apply) do
        addCureSet("apply:" .. spot, list)
    end
    addCureSet("focus", data.focus)
    addCureSet("tree", data.tree)
    addCureSet("writhe", data.writhe)
    for action, list in pairs(data.other) do
        addCureSet(action, list)
    end
    Model.announced = {}
    for _, aff in ipairs(data.announced) do
        Model.announced[aff] = true
    end

    -- key:match("^(%a+):") takes the part before the colon, so "eat:kelp" becomes "eat".
    -- keys with no colon (tree/focus) fall into their own group
    Model.groups = {}
    for key in pairs(Model.cureSets) do
        local group = key:match("^(%a+):") or key
        Model.groups[group] = Model.groups[group] or {}
        table.insert(Model.groups[group], key)
    end
end

-- A cure the game data doesn't list, such as skullcap restoring rebounding.
function Model.addCure(key, list)
    local set = {}
    for _, aff in ipairs(list) do
        set[aff] = true
    end
    Model.cureSets[key] = set
    local group = key:match("^(%a+):") or key
    Model.groups[group] = Model.groups[group] or {}
    table.insert(Model.groups[group], key)
end

function Model.newTarget(name)
    return {
        name = name,
        states = {{
            p = 1,
            affs = {}
        }},
        weights = Model.DEFAULT_WEIGHTS,
        blind = "unknown",
        deaf = "unknown",
        insomnia = "unknown",
        limbs = {}
    }
end

function Model.copyAffs(affs, without)
    local copy = {}
    for aff, value in pairs(affs) do
        if value and aff ~= without then
            copy[aff] = value
        end
    end
    return copy
end
-- Pressure 6 becomes 5. handles stacked afflictions
function Model.withOneLess(affs, aff)
    local value = affs[aff]
    if type(value) == "number" and value > 1 then
        local copy = Model.copyAffs(affs)
        copy[aff] = value - 1
        return copy
    end
    return Model.copyAffs(affs, aff)
end

-- One cure of one affliction: restoration's next stage if it has one, otherwise one stack less.
function Model.afterCure(affs, aff)
    local becomes = Model.TRANSFORMS[aff]
    if not becomes then
        return Model.withOneLess(affs, aff)
    end
    local copy = Model.copyAffs(affs, aff)
    copy[becomes] = true
    return copy
end

function Model.signature(affs)
    local keys = {}
    for aff, value in pairs(affs) do
        if value then
            keys[#keys + 1] = aff .. "=" .. tostring(value)
        end
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

-- Merge identical states, drop the unlikely ones, keep the top MAX_STATES, renormalise.
function Model.settle(target)
    local merged, order = {}, {}
    for _, state in ipairs(target.states) do
        local key = Model.signature(state.affs)
        if merged[key] then
            merged[key].p = merged[key].p + state.p
        else
            merged[key] = {
                p = state.p,
                affs = state.affs
            }
            order[#order + 1] = merged[key]
        end
    end
    local total = 0
    for _, state in ipairs(order) do
        total = total + state.p
    end
    local kept = {}
    for _, state in ipairs(order) do
        if total > 0 and state.p / total >= Model.PRUNE then
            kept[#kept + 1] = state
        end
    end
    if #kept == 0 then
        kept = order
    end
    table.sort(kept, function(a, b)
        return a.p > b.p
    end)
    local states, sum = {}, 0
    for i = 1, math.min(#kept, Model.MAX_STATES) do
        states[i] = kept[i]
        sum = sum + kept[i].p
    end
    for _, state in ipairs(states) do
        state.p = state.p / sum
    end
    target.states = states
end

function Model.gain(target, aff, count)
    for _, state in ipairs(target.states) do
        state.affs = Model.copyAffs(state.affs)
        state.affs[aff] = count or true
    end
    Model.settle(target)
end

-- An affliction that landed with chance p: each state splits into "got it" and "didn't".
function Model.gainMaybe(target, aff, p)
    local branched = {}
    for _, state in ipairs(target.states) do
        local with = Model.copyAffs(state.affs)
        with[aff] = true
        branched[#branched + 1] = { p = state.p * p, affs = with }
        branched[#branched + 1] = { p = state.p * (1 - p), affs = state.affs }
    end
    target.states = branched
    Model.settle(target)
end

-- A limb counts as hurt at any of the three levels; numbness doesn't count.
function Model.limbHurt(affs, side, limb)
    return affs["broken" .. side .. limb] or affs["damaged" .. side .. limb] or affs["mangled" .. side .. limb]
end

-- Epteth/epseth: the left limb breaks first, the right if the left is already hurt, nothing if both are.
function Model.breakLimb(target, limb)
    for _, state in ipairs(target.states) do
        for _, side in ipairs({ "left", "right" }) do
            if not Model.limbHurt(state.affs, side, limb) then
                state.affs = Model.copyAffs(state.affs)
                state.affs["broken" .. side .. limb] = true
                break
            end
        end
    end
    Model.settle(target)
end

-- One delivery from offense data: { gives, strips, senses, breaks }.
function Model.deliver(target, entry)
    for _, sense in ipairs(entry.senses or {}) do
        target[sense] = sense
    end
    if entry.breaks then
        Model.breakLimb(target, entry.breaks)
    end
    if not entry.gives then
        return
    end
    local defence = entry.strips
    if entry.shown then
        if defence then target[defence] = "no" end
        return
    end
    if defence and target[defence] == defence then
        target[defence] = "no"
    elseif defence and target[defence] == "unknown" then
        target[defence] = "no"
        Model.gainMaybe(target, entry.gives, 1 - Model.UNKNOWN_DEFENCE)
    else
        if defence then target[defence] = "no" end
        Model.gain(target, entry.gives)
    end
end

-- 100% on a limb moves it one step along its ladder; the extra is lost. Mildest first.
Model.LIMB_BREAK = 100
Model.LIMB_DECAY = 180
Model.LIMB_STEPS = {
    head = { "damagedhead", "mangledhead" },
    torso = { "mildtrauma", "serioustrauma" },
}
function Model.limbSteps(limb)
    return Model.LIMB_STEPS[limb] or { "damaged" .. limb, "mangled" .. limb }
end

-- Per state: healthy or broken becomes the first step, each step the next, the last step stays.
function Model.limbWorsen(target, limb)
    local steps = Model.limbSteps(limb)
    for _, state in ipairs(target.states) do
        local at = 0
        for i, aff in ipairs(steps) do
            if state.affs[aff] then at = i end
        end
        if at < #steps then
            local affs = Model.copyAffs(Model.copyAffs(state.affs, steps[at]), "broken" .. limb)
            affs[steps[at + 1]] = true
            state.affs = affs
        end
    end
    Model.settle(target)
end

-- A hit for a known amount at a known time. Damage left alone for LIMB_DECAY seconds is gone.
function Model.limbDamage(target, limb, amount, now)
    local entry = target.limbs[limb] or { damage = 0 }
    if entry.at and now - entry.at > Model.LIMB_DECAY then
        entry.damage = 0
    end
    entry.damage = entry.damage + amount
    entry.lastHit = amount
    entry.at = now
    if entry.damage >= Model.LIMB_BREAK then
        entry.damage = 0
        Model.limbWorsen(target, limb)
    end
    target.limbs[limb] = entry
end

-- A way to reset a limb manually if needed.
function Model.limbReset(target, limb)
    target.limbs[limb] = { damage = 0 }
end

-- A certain removal: the game told us, or a self-announcing cure.
function Model.remove(target, aff)
    for _, state in ipairs(target.states) do
        state.affs = Model.copyAffs(state.affs, aff)
    end
    Model.settle(target)
end

-- A certain cure of one stack: pressure 6 becomes 5, a plain affliction is removed.
function Model.removeOne(target, aff)
    for _, state in ipairs(target.states) do
        state.affs = Model.withOneLess(state.affs, aff)
    end
    Model.settle(target)
end

-- present=true keeps the states that have it; false keeps the ones that don't.
-- If no state agrees, our model was wrong: force the fact into every state instead.
function Model.proof(target, aff, present)
    local agreeing = {}
    for _, state in ipairs(target.states) do
        if (state.affs[aff] ~= nil) == present then
            agreeing[#agreeing + 1] = state
        end
    end
    if #agreeing > 0 then
        target.states = agreeing
        Model.settle(target)
    elseif present then
        Model.gain(target, aff)
    else
        Model.remove(target, aff)
    end
end

function Model.tierOf(profile, aff, value)
    if type(value) == "number" then
        local stacked = profile[aff .. "(" .. value .. ")"]
        if stacked then
            return stacked
        end
    end
    return profile[aff] or Model.UNKNOWN_TIER
end

-- The cures in this balance group a profile would reach for, given this state: best tier only.
-- Loop each herb in a group and every affliction, find best tier
function Model.profileChoices(profile, group, affs)
    local best, choices, count = nil, {}, 0
    for _, key in ipairs(Model.groups[group]) do
        local cures = Model.cureSets[key]
        for aff, value in pairs(affs) do
            if value and cures[aff] then
                local tier = Model.tierOf(profile, aff, value)
                if not best or tier < best then
                    best, choices, count = tier, {
                        [key] = true
                    }, 1
                elseif tier == best and not choices[key] then
                    choices[key], count = true, count + 1
                end
            end
        end
    end
    return choices, count
end

-- How likely this target was to use this cure if the state were true.
function Model.cureLikelihood(target, affs, cureKey)
    local cures = Model.cureSets[cureKey]
    local curable = false
    for aff, value in pairs(affs) do
        if value and cures[aff] then
            curable = true
        end
    end
    if not curable then
        return Model.NOTHING
    end
    local group = cureKey:match("^(%a+):") or cureKey
    local total = 0
    for name, weight in pairs(target.weights) do
        local choices, count = Model.profileChoices(Model.data.profiles[name], group, affs)
        local chosen = choices[cureKey] and (1 - Model.SLACK) / count or 0
        total = total + weight * (chosen + Model.SLACK)
    end
    return total
end

-- One cure's removal, added to branched. landing: restoration arriving now, so apply it instead of marking it.
function Model.branchCure(branched, p, affs, key, landing)
    local cures = Model.cureSets[key]
    local candidates = {}
    for aff, value in pairs(affs) do
        if value and cures[aff] then
            candidates[#candidates + 1] = aff
        end
    end
    if #candidates == 0 then
        branched[#branched + 1] = { p = p, affs = affs }
        return
    end
    local marker = not landing and Model.DELAYED[key]
    if marker then
        local copy = Model.copyAffs(affs)
        copy[marker] = true
        branched[#branched + 1] = { p = p, affs = copy }
        return
    end
    if Model.LEFT_FIRST[key] then
        local left = {}
        for _, aff in ipairs(candidates) do
            if aff:find("left", 1, true) then
                left[#left + 1] = aff
            end
        end
        if #left > 0 then
            candidates = left
        end
    end
    for _, aff in ipairs(candidates) do
        branched[#branched + 1] = { p = p / #candidates, affs = Model.afterCure(affs, aff) }
    end
end

-- A cure from one of several items we can't tell apart: a smoke, or a salve to one spot.
function Model.cureUnknown(target, keys)
    if #keys == 0 then
        return
    end
    local branched = {}
    for _, state in ipairs(target.states) do
        for _, key in ipairs(keys) do
            local p = state.p * Model.cureLikelihood(target, state.affs, key) / #keys
            Model.branchCure(branched, p, state.affs, key)
        end
    end
    target.states = branched
    Model.settle(target)
end

-- Restoration arriving: every state that applied it gets the cure now; the rest are untouched.
function Model.land(target, key)
    local marker = Model.DELAYED[key]
    local branched = {}
    for _, state in ipairs(target.states) do
        if state.affs[marker] then
            Model.branchCure(branched, state.p, Model.copyAffs(state.affs, marker), key, true)
        else
            branched[#branched + 1] = state
        end
    end
    target.states = branched
    Model.settle(target)
end

-- What a random cure could take from this state: a "first" affliction (voyria if panacea etc) if one is present, otherwise
-- anything in the pool (a cure key, e.g. "focus"), otherwise any real affliction.
function Model.randomCandidates(affs, pool, first)
    for _, aff in ipairs(first or {}) do
        if affs[aff] ~= nil then
            return { aff }
        end
    end
    local allowed = pool and Model.cureSets[pool]
    local candidates = {}
    for aff, value in pairs(affs) do
        if value and not Model.PSEUDO[aff] and (not allowed or allowed[aff]) then
            candidates[#candidates + 1] = aff
        end
    end
    return candidates
end

-- count afflictions cured at random, one after another (fool takes three, Dragonheal takes 3 etc).
function Model.cureRandom(target, count, pool, first)
    for pass = 1, count do
        local branched = {}
        for _, state in ipairs(target.states) do
            local candidates = Model.randomCandidates(state.affs, pool, first)
            if #candidates == 0 then
                local p = pass == 1 and state.p * Model.NOTHING or state.p
                branched[#branched + 1] = { p = p, affs = state.affs }
            else
                for _, aff in ipairs(candidates) do
                    branched[#branched + 1] = { p = state.p / #candidates, affs = Model.withOneLess(state.affs, aff) }
                end
            end
        end
        target.states = branched
        Model.settle(target)
    end
end

-- Proof that these weren't all present at once. If no state agrees, we can't tell which one was missing, so change nothing.
function Model.proofNotAll(target, affs)
    local agreeing = {}
    for _, state in ipairs(target.states) do
        local all = true
        for _, aff in ipairs(affs) do
            if state.affs[aff] == nil then
                all = false
            end
        end
        if not all then
            agreeing[#agreeing + 1] = state
        end
    end
    if #agreeing > 0 then
        target.states = agreeing
        Model.settle(target)
    end
end

-- Evidence first (how likely they'd pick this cure in each state), then a random removal among what it can cure.
function Model.cure(target, cureKey)
    if not Model.cureSets[cureKey] then
        return false
    end
    Model.cureUnknown(target, { cureKey })
    return true
end

function Model.prob(target, aff)
    local p = 0
    for _, state in ipairs(target.states) do
        if state.affs[aff] ~= nil then
            p = p + state.p
        end
    end
    return p
end

return Model
