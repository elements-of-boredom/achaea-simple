PkCore.defences = PkCore.defences or {}
local defences = PkCore.defences
local data = loadModule("state/defence_data.lua")
defences.have = defences.have or {}

-- GMCP sends parrying and guarding as "parrying (left leg)": keep the defence and the limb apart.
local function add(name)
  if type(name) ~= "string" then return end
  local base, limb = name:match("^(%a+) %((.+)%)$")
  if base then
    defences.have[base] = true
    defences.parrying = limb
  else
    defences.have[name] = true
  end
end

local function remove(name)
  if type(name) ~= "string" then return end
  local base = name:match("^(%a+) %(") or name
  defences.have[base] = nil
  if base == "parrying" or base == "guarding" then defences.parrying = nil end
end

local function onList(list)
  if type(list) ~= "table" then return end
  defences.have, defences.parrying = {}, nil
  for _, entry in ipairs(list) do
    if type(entry) == "table" then add(entry.name) end
  end
  PkCore.stateChanged()
end
onGMCPUpdate("Char.Defences.List", onList)
-- A reload doesn't make the server send the list again, so start from the last one the client kept.
onList(getGMCPData("Char.Defences.List"))
onGMCPUpdate("Char.Defences.Add", function(entry)
  if type(entry) == "table" then add(entry.name) end
  PkCore.stateChanged()
end)
onGMCPUpdate("Char.Defences.Remove", function(names)
  if type(names) ~= "table" then return end
  for _, name in ipairs(names) do remove(name) end
  PkCore.stateChanged()
end)

-- Channels come in Char.Vitals ("Channels: W A E"), not as defences.
local CHANNELS = { F = "fire", W = "water", A = "air", E = "earth" }
function defences.channels()
  local open = {}
  local text = PkCore.playerStatus.channels
  if type(text) ~= "string" then return open end
  for letter in text:gmatch("%a") do
    if CHANNELS[letter] then open[CHANNELS[letter]] = true end
  end
  return open
end

-- GMCP never reports being mounted, so these lines do (from WunderSys).
local MOUNTED = {
  { [[^You easily vault onto the back of ]], true },
  { [[^You cannot do that while mounted\.$]], true },
  { [[^You must dismount before you can mount anything else\.$]], true },
  { [[^You step down off of ]], false },
  { [[^You lose purchase on ]], false },
  { [[^You have no mount on which to jump\.$]], false },
}
for _, entry in ipairs(MOUNTED) do
  local mounted = entry[2]
  addTrigger(entry[1], function()
    defences.mounted = mounted
    PkCore.stateChanged()
  end, { type = "regex" })
end

function defences.report()
  local names = {}
  for name in pairs(defences.have) do names[#names + 1] = name end
  table.sort(names)
  local open = {}
  for _, element in ipairs({ "fire", "water", "air", "earth" }) do
    if defences.channels()[element] then open[#open + 1] = element end
  end
  PkCore.note(string.format("defences (%d): %s\nparrying: %s  mounted: %s  channels: %s",
    #names, table.concat(names, ", "), tostring(defences.parrying), tostring(defences.mounted),
    #open > 0 and table.concat(open, " ") or "none"))
end

-- GMCP class to the data's class key: "Blue Dragon" -> "dragon", "Earth Elemental Lord" -> "earthlord".
function defences.classKey()
  local class = PkCore.player.class
  if type(class) ~= "string" then return nil end
  class = class:lower():gsub("%s+", "")
  if class:find("dragon$") then return "dragon" end
  local element = class:match("^(%a+)elemental")
  return element and (element .. "lord") or class
end

-- Each list is saved per character and class as a space-separated string: pk_keepup_greg_sylvan.
local function listKey(kind)
  local who, class = PkCore.player.name, defences.classKey()
  if type(who) ~= "string" or not class then return nil end
  return "pk_" .. kind .. "_" .. who:lower() .. "_" .. class
end

function defences.list(kind)
  local key, set = listKey(kind), {}
  local text = key and getVariable(key)
  if type(text) == "string" then
    for name in text:gmatch("%S+") do set[name] = true end
  end
  return set
end

local function saveList(kind, set)
  local key = listKey(kind)
  if not key then return false end
  local names = {}
  for name in pairs(set) do names[#names + 1] = name end
  table.sort(names)
  setVariable(key, table.concat(names, " "))
  return true
end

function defences.toggle(kind, name)
  local def = data.defences[name]
  if not def then
    PkCore.note("defences: unknown defence " .. tostring(name))
    return
  end
  if kind == "keepup" and def.manual then
    PkCore.note("defences: the server can't keep up " .. def.name .. "; put it on defup instead")
    return
  end
  local set = defences.list(kind)
  set[name] = not set[name] or nil
  if not saveList(kind, set) then
    PkCore.note("defences: character or class not known yet")
    return
  end
  if kind == "keepup" then defences.write(name, set[name] and 25 or "reset") end
  defences.show(kind)
end

-- three columns, [X] chosen, [M] chosen and drains mana, the name green while it's up.
-- Each cell is one link, so clicking anywhere on it toggles that defence.
local COLUMNS, WIDTH = 3, 25

local function showGroup(kind, title, group, chosen)
  local skills = data.classSkills[group]
  if not skills then return end
  local wanted, names = {}, {}
  for _, skill in ipairs(skills) do wanted[skill] = true end
  for key, def in pairs(data.defences) do
    for _, skill in ipairs(def.skillsets) do
      if wanted[skill] then names[#names + 1] = key break end
    end
  end
  if #names == 0 then return end
  table.sort(names)
  PkCore.note(title .. ":")
  for i, key in ipairs(names) do
    local def = data.defences[key]
    local mark = chosen[key] and (def.mana and "$RM" or "$WX") or " "
    local label = def.name:sub(1, WIDTH)
    label = label .. string.rep(" ", WIDTH - #label)
    local text = "$K[" .. mark .. "$K] " .. (defences.have[key] and "$G" or "$W") .. label .. " "
    local link = (i % COLUMNS == 0 or i == #names) and hyperlink or hyperlinkInline
    link(text, "pkdef toggle " .. kind .. " " .. key, { hint = "Toggle " .. kind .. " of " .. def.name })
  end
end

function defences.show(kind)
  local class = defences.classKey()
  if not class then
    PkCore.note("defences: class not known yet")
    return
  end
  local chosen = defences.list(kind)
  PkCore.note(kind .. " for " .. tostring(PkCore.player.name) .. " (" .. class .. ")")
  showGroup(kind, "Class free", "free", chosen)
  showGroup(kind, class, class, chosen)
  if class == "druid" or class == "sentinel" then
    showGroup(kind, "Animal spirits", "animalspirit", chosen)
  end
  showGroup(kind, "Artefacts", "artefact", chosen)
end

-- Server writes, combined into one command every 250 ms (the server drops CURING PRIORITY writes past
-- 5 a second). They wait until we're on the class's own curing set, so they never land in another set.
local pendingWrites, flushing = {}, false
local function flushWrites()
  flushing = false
  if defences.set ~= defences.classKey() then
    defences.ensureSet()
    return
  end
  local parts = {}
  for name, priority in pairs(pendingWrites) do parts[#parts + 1] = name .. " " .. priority end
  pendingWrites = {}
  if #parts > 0 then send("curing priority defence " .. table.concat(parts, " ")) end
end

function defences.write(name, priority)
  pendingWrites[name] = priority
  if flushing then return end
  flushing = addTimer(250, flushWrites, false) ~= ""
  if not flushing then flushWrites() end
end

-- One curing set per class, named after it. A missing one is created and cloned from the set we were
-- on, so nothing else is ever overwritten.
local listing, sets, currentSet = false, {}, nil

function defences.ensureSet()
  if listing or not defences.classKey() then return end
  listing, sets, currentSet = true, {}, nil
  send("curingset list")
end

addTrigger([[^Your current curing sets$]], function() sets = {} end, { type = "regex" })
addTrigger([[^(\w+)(?: \(current\))?$]], function(_, line, w)
  if not listing then return end
  sets[w[1]] = true
  if line:find("(current)", 1, true) then currentSet = w[1] end
end, { type = "regex" })
addTrigger([[^You are using a total of (\d+) of your allowed (\d+) curing sets\.$]], function(_, _, w)
  listing = false
  local class = defences.classKey()
  if sets[class] then
    if currentSet ~= class then send("curingset switch " .. class) else defences.onSet(class) end
  elseif tonumber(w[1]) < tonumber(w[2]) then
    send("curingset new " .. class)
    send("curingset switch " .. class)
    if currentSet then send("curingset clone " .. currentSet) end
  else
    PkCore.note("defences: no free curing set for " .. class .. " (" .. w[1] .. " of " .. w[2] .. " used)")
  end
end, { type = "regex" })

addTrigger([[^You will now cure using the (\w+) set\.$]], function(_, _, w)
  defences.onSet(w[1])
end, { type = "regex" })

-- The list starts with a header line. A prompt before that header belongs to an earlier command.
local awaitingList, reading, serverList = false, false, {}

function defences.onSet(name)
  defences.set = name
  if name ~= defences.classKey() then return end
  awaitingList, reading, serverList = true, false, {}
  send("curing priority defence list")
end

addTrigger([[^Your defence priorities for curing set (\w+):$]], function()
  if awaitingList then awaitingList, reading = false, true end
end, { type = "regex" })

addTrigger([[^(\w+)\s+:\s+(\d+)$]], function(_, _, w)
  if reading then serverList[w[1]] = tonumber(w[2]) end
end, { type = "regex" })

PkCore.onVitalsChanged("defences.sync", function()
  if not reading then return end
  reading = false
  local saved = defences.list("keepup")
  if next(saved) == nil then
    saveList("keepup", serverList)
    PkCore.note("defences: adopted " .. defences.set .. "'s defence list as your keepup")
  else
    for name in pairs(saved) do
      if not serverList[name] then defences.write(name, 25) end
    end
    for name in pairs(serverList) do
      if not saved[name] then defences.write(name, "reset") end
    end
  end
  flushWrites()
end)

-- A class change moves us to that class's set.
local lastClass
PkCore.onStateChanged("defences.class", function()
  local class = defences.classKey()
  if class and class ~= lastClass then
    lastClass = class
    defences.ensureSet()
  end
end)

registerCommand("pkdef", function(args)
  local action, kind, name = args:match("^(%a*)%s*(%a*)%s*(%S*)")
  if action == "keepup" or action == "defup" then
    defences.show(action)
  elseif action == "toggle" and (kind == "keepup" or kind == "defup") and name ~= "" then
    defences.toggle(kind, name)
  else
    return "usage: pkdef keepup | pkdef defup | pkdef toggle <keepup|defup> <defence>"
  end
end, "Show or change your defence keepup and defup lists")

PkCore.registerAlias("PkCore defences", [[^pkdefs$]], [[PkCore.defences.report()]])