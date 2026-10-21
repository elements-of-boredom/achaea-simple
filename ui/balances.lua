PkCore.ui.balances = PkCore.ui.balances or {}
local B = PkCore.ui.balances
local t = PkCore.ui.theme

local GAUGE_BACK = "#2c313a"
local GAUGE_TEXT_CSS = [[background-color: transparent;]]
local ROW_GAP = 4
local COL_GAP = 4
local GAP_ABOVE_TARGET = 8
local TICK = 0.1
local FAILSAFE_SLACK = 3 -- seconds past expected before we assume we missed the recovery line

-- gmcp = true: driven by PkCore.balance (bal/eq). The rest come from server-side curing text below.
-- default / defaults[variant]: starting countdown until we've seen the real recovery time once
local ROWS = {
    { { id = "balance", label = "Balance", gmcp = true } },
    { { id = "equilibrium", label = "Equilibrium", gmcp = true } },
    { { id = "tree", label = "Tree", default = 15 }, { id = "focus", label = "Focus", default = 3.8 } },
    { { id = "elixir", label = "Elixir", default = 4.5 }, { id = "moss", label = "Moss", default = 6.5 } },
    { { id = "herb", label = "Herb", default = 1.9 }, { id = "pipe", label = "Pipe", default = 2 } },
    { { id = "salve", label = "Salve", default = 1.4, defaults = { restoration = 4.3 } } },
}

local DEFS = {}
for _, row in ipairs(ROWS) do
    for _, def in ipairs(row) do DEFS[def.id] = def end
end

B.downAt = B.downAt or {}     -- id -> epoch it went down
B.variant = B.variant or {}   -- id -> what used it (salve type), for per-variant timing
B.expected = B.expected or {} -- "id" or "id:variant" -> seconds; exact for bal/eq, last observed for the rest
B.failsafe = {}
B.state = {}

local function gaugeStyle(color1, color2)
    return string.format(
        [[background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 %s, stop:1 %s); border: none;]],
        color1, color2)
end

local function expectedKey(id)
    local variant = B.variant[id]
    return variant and (id .. ":" .. variant) or id
end

local function expectedFor(def)
    local variant = B.variant[def.id]
    return B.expected[expectedKey(def.id)]
        or (variant and def.defaults and def.defaults[variant])
        or def.default
end

local function isReady(def)
    if def.gmcp then return PkCore.balance[def.id] ~= false end
    return B.downAt[def.id] == nil
end

local function anyDown()
    for _, def in pairs(DEFS) do
        if not isReady(def) then return true end
    end
    return false
end

local function renderCell(def)
    local gauge = B.gauges and B.gauges[def.id]
    if not gauge then return end
    local ready = isReady(def)
    local state = ready and "ready" or "down"
    if B.state[def.id] ~= state then
        B.state[def.id] = state
        if ready then
            gauge:setStyleSheet(gaugeStyle("#" .. t.hp, "#" .. t.hp2), gaugeStyle(GAUGE_BACK, GAUGE_BACK), GAUGE_TEXT_CSS)
            gauge:setFgColor("#0a0a0a")
        else
            gauge:setStyleSheet(gaugeStyle("#" .. t.mana, "#" .. t.mana2), gaugeStyle(GAUGE_BACK, GAUGE_BACK), GAUGE_TEXT_CSS)
            gauge:setFgColor("#e8eee2")
        end
    end

    if ready then
        gauge:setValue(1, 1, def.label)
        return
    end
    local since = B.downAt[def.id]
    local expected = expectedFor(def)
    if not since then
        gauge:setValue(0, 1, def.label)
        return
    end
    local elapsed = getEpoch() - since
    if expected and expected > 0 then
        local remaining = math.max(0, expected - elapsed)
        gauge:setValue(math.min(elapsed, expected), expected, string.format("%s %.1f", def.label, remaining))
    else
        gauge:setValue(0, 1, string.format("%s +%.1f", def.label, elapsed))
    end
end

function B.render()
    if not B.gauges then return end
    for _, def in pairs(DEFS) do renderCell(def) end
end

-- one repeating timer, only alive while something is down
local function startTicker()
    if B.tickTimer then return end
    B.tickTimer = PkCore.trackTimer(tempTimer(TICK, PkCore.protected("ui.balances.tick", function()
        B.render()
        if not anyDown() then
            killTimer(B.tickTimer)
            B.tickTimer = nil
        end
    end), true))
end

local markUp

local function markDown(id, variant)
    local def = DEFS[id]
    B.downAt[id] = B.downAt[id] or getEpoch()
    B.variant[id] = variant
    if not def.gmcp then
        if B.failsafe[id] then killTimer(B.failsafe[id]) end
        B.failsafe[id] = PkCore.trackTimer(tempTimer(expectedFor(def) + FAILSAFE_SLACK, function()
            B.failsafe[id] = nil
            markUp(id, true)
        end))
    end
    startTicker()
    B.render()
end

-- timedOut: the failsafe fired, so don't learn a duration from it
markUp = function(id, timedOut)
    local def = DEFS[id]
    if not B.downAt[id] then return end
    if not def.gmcp and not timedOut then
        B.expected[expectedKey(id)] = getEpoch() - B.downAt[id]
    end
    if B.failsafe[id] then
        killTimer(B.failsafe[id])
        B.failsafe[id] = nil
    end
    B.downAt[id] = nil
    B.render()
end

function B.build()
    if B.gauges then return end
    local sections = PkCore.ui.sections
    if not (sections and sections.left and sections.playerVitals and PkCore.ui.rail.targetConsoleOffset) then return end

    local height = math.floor(sections.playerVitals:get_height() / 2) - 6 -- same as the HP gauge ("50%-6px")
    local pad = PkCore.ui.rail.pad
    local step = height + ROW_GAP
    local top = PkCore.ui.rail.targetConsoleOffset + GAP_ABOVE_TARGET + (#ROWS * step) - ROW_GAP

    local halfWidth = "50%-" .. (pad + COL_GAP / 2)
    local gauges = {}
    for i, row in ipairs(ROWS) do
        local y = "100%-" .. (top - (i - 1) * step)
        for col, def in ipairs(row) do
            local x, width
            if #row == 1 then
                x, width = pad, "100%-" .. (pad * 2)
            elseif col == 1 then
                x, width = pad, halfWidth
            else
                x, width = "50%+" .. (COL_GAP / 2), halfWidth
            end
            local name = "PkCore_rail_bal_" .. def.id
            local gauge = Geyser.Gauge:new({
                name = name, x = x, y = y, width = width, height = height,
                font = "SF Mono", fontSize = 10,
            }, sections.left)
            gauge:setAlignment("c")
            raiseWindow(name)
            gauges[def.id] = gauge
        end
    end
    B.gauges = gauges
    B.state = {}
    if anyDown() then startTicker() end
    B.render()
end

function B.cleanup()
    B.gauges = nil
    B.state = {}
    B.tickTimer = nil -- tracked timers are killed by PkCore.cleanup
    B.failsafe = {}
    B.downAt = {}     -- their failsafes just died, so don't keep anything stuck down
    B.curing = nil
    B.applying = nil
end

---------------------------------------------------------------- bal / eq (gmcp)

PkCore.trackHandler(registerAnonymousEventHandler("PkCore balance lost",
    PkCore.protected("ui.balances.pkLost", function(_, name) if DEFS[name] then markDown(name) end end)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore balance gained",
    PkCore.protected("ui.balances.pkGained", function(_, name) if DEFS[name] then markUp(name) end end)))

-- exact recovery time for bal/eq
PkCore.trackTrigger(tempRegexTrigger("^(Balance|Equilibrium) used: ([\\d.]+)s\\.$",
    PkCore.protected("ui.balances.used", function()
        local id = matches[2] == "Balance" and "balance" or "equilibrium"
        B.expected[id] = tonumber(matches[3])
        markDown(id)
    end)))

---------------------------------------------------------------- server-side curing
-- "[Curing]: EAT KELP" announces the action; only the very next line counts as doing it
-- (same as WunderSys's one-line chains), so food, manual sips etc. never touch the trackers.

PkCore.trackTrigger(tempRegexTrigger("^\\[Curing\\]: (EAT|SIP|SMOKE|TOUCH|FOCUS)\\s*(\\w*)",
    PkCore.protected("ui.balances.curing", function()
        local curing = { verb = matches[2], what = matches[3]:lower() }
        B.curing = curing
        -- created after the action triggers, so it runs after them on the next line
        tempLineTrigger(1, 1, function()
            if B.curing == curing then B.curing = nil end
        end)
    end)))

-- salves are tracked differently: the APPLY announcement sticks until the rub line
-- (APPLY HEALTH TO <limb> is an elixir, and takes elixir balance right away)
PkCore.trackTrigger(tempRegexTrigger("^\\[Curing\\]: APPLY (\\w+)(?: TO (\\w+))?$",
    PkCore.protected("ui.balances.applying", function()
        local what = matches[2]:lower()
        if what == "health" then
            markDown("elixir")
        elseif what ~= "quicksilver" and what ~= "sileris" then
            B.applying = what
        end
    end)))

local function curingIs(verb)
    return B.curing and B.curing.verb == verb
end

local function onAction(kind, pattern, label, fn)
    local make = kind == "exact" and tempExactMatchTrigger or tempBeginOfLineTrigger
    PkCore.trackTrigger(make(pattern, PkCore.protected("ui.balances." .. label, fn)))
end

onAction("begins", "You eat ", "eat", function()
    if not curingIs("EAT") then return end
    local what = B.curing.what
    markDown((what == "moss" or what == "potash" or what == "irid") and "moss" or "herb")
end)
onAction("begins", "You take a drink from ", "sip", function()
    if curingIs("SIP") and (B.curing.what == "health" or B.curing.what == "mana") then markDown("elixir") end
end)
onAction("begins", "You down the last drop from ", "sipLast", function()
    if curingIs("SIP") and (B.curing.what == "health" or B.curing.what == "mana") then markDown("elixir") end
end)
onAction("begins", "You take a long drag ", "smoke", function()
    if curingIs("SMOKE") then markDown("pipe") end
end)
onAction("exact", "You touch the tree of life tattoo.", "tree", function()
    markDown("tree")
end)
onAction("exact", "You focus your mind intently on curing your mental maladies.", "focus", function()
    if curingIs("FOCUS") then markDown("focus") end
end)
-- a fizzled tree still costs tree balance, and isn't chained to an announcement
onAction("exact", "Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged.", "treeFizzle",
    function() markDown("tree") end)

PkCore.trackTrigger(tempRegexTrigger("^You take out some (?:salve|balm) and quickly rub it on your \\w+\\.$",
    PkCore.protected("ui.balances.applied", function()
        if not B.applying then return end
        markDown("salve", B.applying:find("^restoration") and "restoration" or B.applying)
        B.applying = nil
    end)))

---------------------------------------------------------------- recovery lines

local function onRecover(pattern, id, regex)
    local make = regex and tempRegexTrigger or tempExactMatchTrigger
    PkCore.trackTrigger(make(pattern, PkCore.protected("ui.balances.recover." .. id, function() markUp(id) end)))
end

onRecover("You may utilise the tree tattoo again.", "tree")
onRecover("Your mind is able to focus once again.", "focus")
onRecover("You may eat another plant or mineral.", "herb")
onRecover("You may eat another bit of irid moss or potash.", "moss")
onRecover("Your lungs have recovered enough to smoke another mineral or plant.", "pipe")
onRecover("You may apply another salve or balm to yourself.", "salve")
onRecover("^You may drink another health or mana elixir(?: or tonic)?\\.$", "elixir", true)

PkCore.registerSystem("ui.balances", { cleanup = B.cleanup, rebuild = B.build })