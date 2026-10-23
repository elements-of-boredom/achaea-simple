PkCore.harvest = PkCore.harvest or {}
local harvest = PkCore.harvest
local SAVE_KEY = "harvestList" -- for saveTable

harvest.list = loadTable(SAVE_KEY) or {}

local function saveList()
  saveTable(SAVE_KEY, harvest.list)
end

local function isEmpty(t)
  for _, value in pairs(t) do
    if value then return false end
  end
  return true
end

local function cleanName(name)
  return tostring(name or ""):lower():match("^%s*(.-)%s*$")
end

function harvest.add(name)
  name = cleanName(name)
  if name == "" then
    PkCore.note("usage: harvest add <name>")
    return
  end
  harvest.list[name] = true
  saveList()
  PkCore.note("harvest: added " .. name)
end

function harvest.remove(name)
  name = cleanName(name)
  if not harvest.list[name] then
    PkCore.note("harvest: " .. name .. " not in your list")
    return
  end
  local kept = {}
  for plant, value in pairs(harvest.list) do
    if value and plant ~= name then kept[plant] = true end
  end
  harvest.list = kept
  saveList()
  PkCore.note("harvest: removed " .. name)
end

function harvest.showList()
  local names = {}
  for name, value in pairs(harvest.list) do
    if value then table.insert(names, name) end
  end
  table.sort(names)
  PkCore.note("harvest list (" .. #names .. "): " .. (#names > 0 and table.concat(names, ", ") or "none"))
end

-- balance-gated harvest queue
local harvestQueue = {}
local harvestWaiting = false
local harvestActive = false
local harvestSucceeded = 0
local manualPending = false

local function sendNextHarvest()
  if harvestWaiting then return end
  if #harvestQueue == 0 then
    if harvestActive then
      harvestActive = false
      if harvestSucceeded > 0 then send("inr all") end
      harvestSucceeded = 0
    end
    return
  end
  if not PkCore.balance.balance then return end
  local name = table.remove(harvestQueue, 1)
  harvestWaiting = true
  send("harvest " .. name)
end

registerAnonymousEventHandler("PkCore balance gained", function(_, what)
  if what ~= "balance" then return end
  harvestWaiting = false
  sendNextHarvest()
end)

-- Instant rejections - no balance actually spent, so don't wait on an
-- event that's never coming; just move on to the next plant right away.
local function skipPlant()
  harvestWaiting = false
  sendNextHarvest()
end
tempTrigger("That plant has been fully harvested.", skipPlant)
tempTrigger("You have already harvested from this plant recently.", skipPlant)

tempRegexTrigger([[^You reach out and carefully harvest (?:a|an|\d+) .+\.$]], function()
  harvestSucceeded = harvestSucceeded + 1
end)

--  `plants` capture / gag 
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
    if harvest.list[name] then table.insert(matched, name) end
  end
  buffer = {}

  if #matched == 0 then
    PkCore.note("hh: nothing to harvest here")
    return
  end
  PkCore.note("hh: attempting " .. table.concat(matched, ", "))
  harvestActive = true
  for _, name in ipairs(matched) do table.insert(harvestQueue, name) end
  sendNextHarvest()
end

-- Returning false gags the line (Mudlet's deleteLine()).
tempTrigger("The following plants are growing in this room:", function()
  if not manualPending then return end
  capturing = true
  buffer = {}
  captureGeneration = captureGeneration + 1
  local generation = captureGeneration
  tempTimer(CAPTURE_TIMEOUT, function()
    if capturing and generation == captureGeneration then finishCapture() end
  end)
  return false
end)
tempRegexTrigger(ROW_PATTERN, function(_, _, w)
  if not capturing or not manualPending then return end
  table.insert(buffer, tostring(w[2] or ""):lower())
  if #buffer >= CAPTURE_LINE_CAP then finishCapture() end
  return false
end)

-- ── `hh` manual check
function harvest.here()
  if isEmpty(harvest.list) then
    PkCore.note("hh: your list is empty - use 'harvest add <name>' first")
    return
  end
  capturing = false
  buffer = {}
  manualPending = true
  send("plants")
  tempTimer(2, function() manualPending = false end)
end

PkCore.registerAlias("PkCore hh", [[^hh$]], [[PkCore.harvest.here()]])
PkCore.registerAlias("PkCore harvest add", [[^harvest\s+add\s+(\S+)$]], [[PkCore.harvest.add(matches[2])]])
PkCore.registerAlias("PkCore harvest remove", [[^harvest\s+remove\s+(\S+)$]], [[PkCore.harvest.remove(matches[2])]])
PkCore.registerAlias("PkCore harvest list", [[^harvest\s+list$]], [[PkCore.harvest.showList()]])