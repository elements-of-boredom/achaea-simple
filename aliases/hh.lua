PkCore.harvest = PkCore.harvest or {}
PkCore.harvest.list = PkCore.harvest.list or {}

local LIST_FILE = PkCore.path .. "/harvest-list.dat"
pcall(table.load, LIST_FILE, PkCore.harvest.list)

local manualPending = false
local harvestActive = false

local function saveList()
    pcall(table.save, LIST_FILE, PkCore.harvest.list)
end

function PkCore.harvest.add(name)
    name = tostring(name or ""):lower():match("^%s*(.-)%s*$")
    if name == "" then
        PkCore.note("usage: harvest add <name>")
        return
    end
    PkCore.harvest.list[name] = true
    saveList()
    PkCore.note("harvest: added " .. name)
end

function PkCore.harvest.remove(name)
    name = tostring(name or ""):lower():match("^%s*(.-)%s*$")
    if not PkCore.harvest.list[name] then
        PkCore.note("harvest: " .. name .. " not in your list")
        return
    end
    PkCore.harvest.list[name] = nil
    saveList()
    PkCore.note("harvest: removed " .. name)
end

function PkCore.harvest.showList()
    local names = {}
    for name in pairs(PkCore.harvest.list) do
        table.insert(names, name)
    end
    table.sort(names)
    PkCore.note("harvest list (" .. #names .. "): " .. (#names > 0 and table.concat(names, ", ") or "none"))
end

-- ── balance-gated harvest queue ──────────────────────────────────────────
local harvestQueue = {}
local harvestWaiting = false
local harvestActive = false
local harvestSucceeded = 0

local function sendNextHarvest()
    if harvestWaiting then
        return
    end
    if #harvestQueue == 0 then
        if harvestActive then
            harvestActive = false
            if harvestSucceeded > 0 then
                send("inr all")
            end
            harvestSucceeded = 0
        end
        return
    end
    if not PkCore.balance.balance then
        return
    end
    local name = table.remove(harvestQueue, 1)
    harvestWaiting = true
    send("harvest " .. name)
end

PkCore.trackHandler(registerAnonymousEventHandler("PkCore balance gained",
    PkCore.protected("hh.onBalanceGained", function(_, what)
        if what ~= "balance" then
            return
        end
        harvestWaiting = false
        sendNextHarvest()
    end)))

-- Instant rejections - no balance actually spent, so don't wait on an
-- event that's never coming; just move on to the next plant right away.
PkCore.trackTrigger(tempTrigger("That plant has been fully harvested.",
    PkCore.protected("hh.alreadyHarvested", function()
        harvestWaiting = false
        sendNextHarvest()
    end)))
PkCore.trackTrigger(tempTrigger("You have already harvested from this plant recently.",
    PkCore.protected("hh.onCooldown", function()
        harvestWaiting = false
        sendNextHarvest()
    end)))
PkCore.trackTrigger(tempRegexTrigger([[^You reach out and carefully harvest (?:a|an|\d+) .+\.$]],
  PkCore.protected("hh.onHarvestSuccess", function()
    harvestSucceeded = harvestSucceeded + 1
  end)))

-- ── `plants` capture / gag ───────────────────────────────────────────────
local ROW_PATTERN = [[^(.+?)\s*\(([a-zA-Z]+)\)\s*(.*)$]]
local CAPTURE_LINE_CAP = 40
local CAPTURE_TIMEOUT = 0.4

local capturing = false
local buffer = {}
local captureGeneration = 0

local function finishCapture()
    capturing = false
    manualPending = false
    local matched = {}
    for _, name in ipairs(buffer) do
        if PkCore.harvest.list[name] then
            table.insert(matched, name)
        end
    end
    buffer = {}

    if #matched == 0 then
        PkCore.note("hh: nothing to harvest here")
        return
    end
    PkCore.note("hh: attempting " .. table.concat(matched, ", "))
    harvestActive = true
    for _, name in ipairs(matched) do
        table.insert(harvestQueue, name)
    end
    sendNextHarvest()
end

PkCore.trackTrigger(tempTrigger("The following plants are growing in this room:",
    PkCore.protected("hh.onHeader", function()
        if not manualPending then return end
        deleteLine()
        capturing = true
        buffer = {}
        captureGeneration = captureGeneration + 1
        local generation = captureGeneration
        PkCore.trackTimer(tempTimer(CAPTURE_TIMEOUT, PkCore.protected("hh.captureTimeout", function()
            if capturing and generation == captureGeneration then
                finishCapture()
            end
        end)))
    end)))

PkCore.trackTrigger(tempRegexTrigger(ROW_PATTERN, PkCore.protected("hh.onRow", function()
    if not capturing or not manualPending then
        return
    end
    table.insert(buffer, tostring(matches[3] or ""):lower())
    deleteLine()
    if #buffer >= CAPTURE_LINE_CAP then
        finishCapture()
    end
end)))

-- ── `hh` manual check ────────────────────────────────────────────────────
function PkCore.harvest.here()
    if not next(PkCore.harvest.list) then
        PkCore.note("hh: your list is empty - use 'harvest add <name>' first")
        return
    end
    capturing = false
    buffer = {}
    manualPending = true
    send("plants")
    PkCore.trackTimer(tempTimer(2, PkCore.protected("hh.manualTimeout", function()
        manualPending = false
    end)))
end

PkCore.registerAlias("PkCore hh", [[^hh$]], [[PkCore.harvest.here()]])
PkCore.registerAlias("PkCore harvest add", [[^harvest\s+add\s+(\S+)$]], [[PkCore.harvest.add(matches[2])]])
PkCore.registerAlias("PkCore harvest remove", [[^harvest\s+remove\s+(\S+)$]], [[PkCore.harvest.remove(matches[2])]])
PkCore.registerAlias("PkCore harvest list", [[^harvest\s+list$]], [[PkCore.harvest.showList()]])
