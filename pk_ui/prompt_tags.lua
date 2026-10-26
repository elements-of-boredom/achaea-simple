PkCore.promptTags = PkCore.promptTags or {}
PkCore.promptTagColors = PkCore.promptTagColors or {}
PkCore.promptDebug = PkCore.promptDebug or false

PkCore.afflictionShort = {
  ensorcelled = "ENS", sandfever = "SAND", mycalium = "myc", flushings = "fls", rebbies = "reb",
  pyramides = "PYR", addiction = "add", aeon = "AEON", agoraphobia = "agor", airfisted = "airf",
  amnesia = "amns", anorexia = "ano", asphyxiating = "asph", asthma = "ast", blackout = "BLKOUT",
  bleeding = "bld", blindness = "blnd", blistered = "blst", bloodfire = "bldfr", bound = "bound",
  brokenleftarm = "la1", brokenleftleg = "ll1", brokenrightarm = "ra1", brokenrightleg = "rl1",
  bruisedribs = "tt1", burning = "burn", cadmuscurse = "cadmus", calcifiedhead = "CAL-HEAD",
  calcifiedtorso = "CAL-TT", claustrophobia = "clau", clumsiness = "clum", coldfate = "cfate",
  concussion = "conc", conflagration = "cnflg", confusion = "conf", corruption = "corr",
  cremated = "crem", crushedthroat = "CRTHROAT", daeggerimpale = "DAEG-IMP", damagedhead = "H2",
  damagedleftarm = "LA2", damagedleftleg = "LL2", damagedrightarm = "RA2", damagedrightleg = "RL2",
  darkshade = "DARK", dazed = "daze", dazzled = "dazz", deadening = "ddn", deafness = "deaf",
  deepsleep = "dsleep", degenerate = "dgen", dehydrated = "dhydr", dementia = "dem",
  demonstain = "dstain", depression = "depr", deteriorate = "det", disloyalty = "disl",
  disrupted = "DISR", dissonance = "diss", dizziness = "dizz", earworm = "ear",
  enlightenment = "ENL", enmesh = "enms", entangled = "entg", entropy = "entr", epilepsy = "epi",
  fear = "fear", flamefisted = "ffst", fratricide = "frat", frozen = "froz", fulminated = "fulm",
  generosity = "gene", guilt = "GUI", haemophilia = "haem", hallucinations = "hall",
  hamstrung = "HAMS", hatred = "hatr", healthleech = "hlch", heartseed = "HSEED",
  hecatecurse = "HECATE", hellsight = "HELL", hindered = "hind", homunculusmercury = "hmrc",
  hypersomnia = "hsomn", hypochondria = "hchon", hypothermia = "hthm", icefisted = "icef",
  impaled = "IMPALED", impatience = "IMP", indifference = "ind", inquisition = "INQ",
  insomnia = "inso", internalbleeding = "IBLD", isolation = "isol", itching = "itch",
  justice = "just", kaisurge = "ksrg", kkractlebrand = "brand", laceratedthroat = "lthr",
  lapsingconsciousness = "lconsc", latched = "LATCH", lethargy = "leth", lightbind = "lbind",
  loneliness = "lone", lovers = "lovers", manaleech = "mleech", mangledhead = "H3",
  mangledleftarm = "LA3", mangledleftleg = "LL3", mangledrightarm = "RA3", mangledrightleg = "RL3",
  masochism = "maso", mildtrauma = "tt1", mindclamp = "mclamp", mindravaged = "mrav",
  muddled = "mudd", nausea = "naus", numbedleftarm = "num-la", numbedrightarm = "num-ra",
  pacified = "PACI", palpatarfeed = "ppfd", paralysis = "PAR", paranoia = "prna",
  parasite = "prst", peace = "PEACE", penitence = "ptc", petrified = "ptri",
  phlogisticated = "phlog", pinshot = "PSHOT", recklessness = "rek", retardation = "RET",
  retribution = "retr", revealed = "rev", scalded = "scal", scrambledbrains = "sbrain",
  scytherus = "SCYT", selarnia = "sela", sensitivity = "SENS", serioustrauma = "TT2",
  shadowmadness = "SMAD", shivering = "shiv", shyness = "shy", silenced = "silnt",
  silver = "silv", slashedthroat = "sthrt", sleeping = "asleep", slickness = "SLCK",
  slimeobscure = "sbs", solarburn = "solb", spiritburn = "sbn", stupidity = "STUP",
  stridulating = "strid", stuttering = "stut", tenderskin = "tsn", tension = "tens",
  timeflux = "tflux", timeloop = "TLOOP", tonguetied = "ttied", transfixation = "TFIX",
  trueblind = "TBLND", vertigo = "vert", vinewreathed = "vwrth", vitiated = "viti",
  vitrified = "vitri", voidfisted = "vfist", voyria = "VOYR", waterbonds = "wbond",
  weakenedmind = "wmind", weariness = "wear", webbed = "webbed", whisperingmadness = "wmad",
  pacifism = "PEACE", prone = "PR", unconsciousness = "unconc",
  unweavingbody = "UwBody", unweavingmind = "UwMind", unweavingspirit = "UwSPIR",
  temperedsanguine = "sang", temperedcholeric = "chol", temperedphlegmatic = "phleg",
  temperedmelancholic = "melan", torntendons = "tendons", wristfractures = "wrist",
  crackedribs = "ribs", skullfractures = "skull", grievouswounds = "gwnd",
  crescendo = "cresc", pressure = "pres", pyre = "pyre", horror = "hor",
}

PkCore.afflictionIgnore = {
  insomnia = true,
  blindness = true,
  deafness = true,
}

local LIMB_KEYS = { rightleg = true, leftleg = true, rightarm = true, leftarm = true, torso = true, head = true }

local AFFLICTION_COLOR_GROUPS = {
  { color = "218,112,214", names = { prone = true } },
  { color = "127,255,0", names = { asthma=true, sensitivity=true, weariness=true, clumsiness=true, healthleech=true, rebbies=true } },
  { color = "255,255,0", names = { dissonance=true, dizziness=true, epilepsy=true, impatience=true, shyness=true, stupidity=true, sandfever=true, mycalium=true, fulminated=true } },
  { color = "184,134,11", names = { addiction=true, darkshade=true, haemophilia=true, lethargy=true, nausea=true, scytherus=true, flushings=true } },
  { color = "165,42,42", names = { damagedhead=true, damagedleftarm=true, damagedleftleg=true, damagedrightarm=true, damagedrightleg=true, mildtrauma=true, brokenleftarm=true, brokenleftleg=true, brokenrightarm=true, brokenrightleg=true, mangledhead=true, mangledleftarm=true, mangledleftleg=true, mangledrightarm=true, mangledrightleg=true, serioustrauma=true } },
  { color = "147,112,219", names = { temperedsanguine=true, temperedcholeric=true, temperedphlegmatic=true, temperedmelancholic=true } },
  { color = "199,21,133", names = { torntendons=true, wristfractures=true, crackedribs=true, skullfractures=true } },
  { color = "255,140,0", names = { crescendo=true, horror=true, pyre=true } },
  { color = "255,20,147", names = { grievouswounds=true } },
  { color = "135,206,235", names = { pressure=true } },
  { color = "255,0,0", names = { kkractlebrand=true } },
  { color = "148,0,211", names = { unweavingbody=true, unweavingmind=true, unweavingspirit=true } },
}

-- Achaea's ui/theme.lua palette as decimals
local C = {
  text = "255,255,255",
  good = "0,100,0", warning = "230,200,0", critical = "220,50,50",
  hp = "93,141,87", hp2 = "181,215,138",
  mana = "122,143,195", mana2 = "167,181,222",
  endurance = "217,154,60", endurance2 = "242,197,114",
  willpower = "179,108,183", willpower2 = "217,160,219",
}

local prompt = "" -- the raw prompt being rewritten

function PkCore.registerPromptTag(name, fn) PkCore.promptTags[name] = fn end
function PkCore.registerPromptTagColor(name, fn) PkCore.promptTagColors[name] = fn end

local function afflictionColor(name)
  for _, group in ipairs(AFFLICTION_COLOR_GROUPS) do
    if group.names[name] then return group.color end
  end
  if PkCore.afflictionShort[name] then return "112,128,144" end -- default (SlateGrey)
  return "205,92,92" -- unknown affliction (IndianRed)
end

-- Data tags --
local function percent(key)
  return function()
    local current, max = PkCore.vitals[key], PkCore.vitals["max" .. key]
    if not (current and max and max > 0) then return "" end
    return math.floor(math.min(100, math.max(0, current / max * 100))) .. "%"
  end
end
-- The +/- change Achaea prints in the prompt, as a percent of max.
local function deltaPerc(unit, maxKey, decimals)
  return function()
    local value = prompt:match("([%+%-]%d+)" .. unit)
    local max = PkCore.vitals[maxKey]
    if not (value and max and max > 0) then return "" end
    return string.format("%+." .. decimals .. "f%%", tonumber(value) / max * 100)
  end
end

-- Registrations -------------------------
for _, key in ipairs({ "hp", "mp", "ep", "wp" }) do
  PkCore.registerPromptTag(key, function() return PkCore.vitals[key] end)
  PkCore.registerPromptTag("max" .. key, function() return PkCore.vitals["max" .. key] end)
  PkCore.registerPromptTag(key .. "perc", percent(key))
end
PkCore.registerPromptTag("hpdelta", deltaPerc("h", "maxhp", 1))
PkCore.registerPromptTag("mpdelta", deltaPerc("m", "maxmp", 1))
PkCore.registerPromptTag("epdelta", deltaPerc("e", "maxep", 2))
PkCore.registerPromptTag("wpdelta", deltaPerc("w", "maxwp", 2))

PkCore.registerPromptTag("bal", function() return PkCore.balance.balance and "x" or "-" end)
PkCore.registerPromptTag("eq", function() return PkCore.balance.equilibrium and "e" or "-" end)
PkCore.registerPromptTag("target", function() return PkCore.room.targetName() or "" end)
PkCore.registerPromptTag("targethpperc", function()
 local opponent = Opponent
  return (opponent and opponent.targetHealth and opponent.targetHealth()) or PkCore.room.targetHpPercent or ""
end)
PkCore.registerPromptTag("rage", function() return tostring(PkCore.playerStatus.rage or "") end)
PkCore.registerPromptTag("shaping", function() return tostring(PkCore.playerStatus.shaping or "") end)
PkCore.registerPromptTag("sunlight", function() return tostring(PkCore.playerStatus.sunlight or "") end)
PkCore.registerPromptTag("flying", function() return PkCore.room.isFlying() and "FLYING" or "" end)
PkCore.registerPromptTag("timestamp", function() return prompt:match("^%[([%d:.]+)%]") or "" end)
PkCore.registerPromptTag("defenses", function()
  return prompt:match("^%[?[%d:.]*%]?%s*%d+/%d+ %d+/%d+ %d+/%d+ %d+/%d+ %S* (%S*)") or ""
end)

PkCore.registerPromptTag("afflictions", function()
  local list = PkCore.afflictions.list
  local names = {}
  for name, value in pairs(list) do
    if value and not PkCore.afflictionIgnore[name] then table.insert(names, name) end
  end
  table.sort(names)

  local parts = {}
  for _, name in ipairs(names) do
    if name == "burning" then
      table.insert(parts, PkCore.afflictionShort[name] or name)
    elseif name ~= "bleeding" or (PkCore.playerStatus.bleed or 0) > 50 then
      local short = PkCore.afflictionShort[name] or name
      if type(list[name]) == "number" then short = short .. "(" .. list[name] .. ")" end
      table.insert(parts, "<" .. afflictionColor(name) .. ">" .. short)
    end
  end
  if #parts == 0 then return "" end
  return table.concat(parts, " ") .. "<" .. C.text .. ">"
end)

PkCore.registerPromptTag("targetafflictions", function()
  local opponent, name = PkCore.opponent, PkCore.room.targetName()
  if not (opponent and opponent.display) then return "" end
  local parts = {}
  for _, entry in ipairs(opponent.display(name)) do
    local short = PkCore.afflictionShort[entry.aff] or entry.aff
    if entry.count then short = short .. "(" .. entry.count .. ")" end
    if entry.p < opponent.Queries.SURE then short = short .. "?" end
    table.insert(parts, "<" .. afflictionColor(entry.aff) .. ">" .. short)
  end
  if #parts == 0 then return "" end
  return table.concat(parts, " ") .. "<" .. C.text .. ">"
end)

-- Colour tags: percentage-tiered --
local function tierColor(current, max, highPct, lowPct)
  if not (current and max and max > 0) then return C.text end
  local pct = current / max
  if pct >= highPct then return C.good end
  if pct >= lowPct then return C.warning end
  return C.critical
end

local function deltaColor(unit, upColor, downColor)
  return function()
    local value = prompt:match("([%+%-]%d+)" .. unit)
    if not value then return nil end
    return value:sub(1, 1) == "+" and upColor or downColor
  end
end

local v = PkCore.vitals
PkCore.registerPromptTagColor("hcolour", function() return tierColor(v.hp, v.maxhp, 0.75, 0.33) end)
PkCore.registerPromptTagColor("mcolour", function() return tierColor(v.mp, v.maxmp, 0.75, 0.50) end)
PkCore.registerPromptTagColor("ecolour", function() return tierColor(v.ep, v.maxep, 0.66, 0.50) end)
PkCore.registerPromptTagColor("wcolour", function() return tierColor(v.wp, v.maxwp, 0.66, 0.50) end)
PkCore.registerPromptTagColor("hpdeltacolour", deltaColor("h", C.hp, C.hp2))
PkCore.registerPromptTagColor("mpdeltacolour", deltaColor("m", C.mana, C.mana2))
PkCore.registerPromptTagColor("epdeltacolour", deltaColor("e", C.endurance, C.endurance2))
PkCore.registerPromptTagColor("wpdeltacolour", deltaColor("w", C.willpower, C.willpower2))
PkCore.registerPromptTagColor("shapingcolour", function()
  local value = PkCore.playerStatus.shaping or 0
  if value >= 4 then return C.critical end
  if value >= 2 then return C.warning end
  if value >= 1 then return C.good end
  return C.text
end)
PkCore.registerPromptTagColor("flyingcolour", function() return "255,0,255" end)
PkCore.registerPromptTagColor("sunlightcolour", function() return "255,215,0" end)

PkCore.promptFormat = PkCore.promptFormat or
  "{flying:#flyingcolour(@flying)<r>}[@timestamp] #hcolour@hp<r>h #mcolour@mp<r>m #ecolour@epperc<r>e #wcolour@wpperc<r>w @eq@bal@defenses {shaping:#shapingcolour S:@shaping<r>}{sunlight:#sunlightcolour S:@sunlight<r>} {rage:R:@rage<r>}{target: [@target(@targethpperc)]}{targetafflictions:T[@targetafflictions]} {afflictions:M[@afflictions]} {hpdelta:(#hpdeltacolour@hpdelta<r>)} {mpdelta:(#mpdeltacolour@mpdelta<r>)} {epdelta:(#epdeltacolour@epdelta<r>)} {wpdelta:(#wpdeltacolour@wpdelta<r>)}"

local function substituteColors(template)
  return (template:gsub("#(%w+)", function(tag)
    local fn = PkCore.promptTagColors[tag]
    if not fn then return "" end
    local ok, color = pcall(fn)
    if not ok or not color then return "" end
    return "<" .. color .. ">"
  end))
end

local function substituteTags(template)
  return (template:gsub("@(%w+)", function(tag)
    local fn = PkCore.promptTags[tag]
    if not fn then return "" end
    local ok, result = pcall(fn)
    if not ok or result == nil then return "" end
    return tostring(result)
  end))
end

local function substituteConditionals(template)
  return (template:gsub("{(%w+):(.-)}", function(tag, inner)
    local fn = PkCore.promptTags[tag]
    if not fn then return "" end
    local ok, result = pcall(fn)
    if not ok or result == nil or tostring(result) == "" then return "" end
    return inner
  end))
end

-- Achaea's own "normal" colour (256-colour index 7). Server lines leave it set and uncoloured lines
-- inherit it, so ours must hand it back too: a bare reset falls to the terminal default, bright white.
local NORMAL = "\27[0m\27[38;5;7m"

local function toAnsi(s)
  s = s:gsub("<r>", NORMAL):gsub("<(%d+),(%d+),(%d+)>", "\27[38;2;%1;%2;%3m")
  return NORMAL .. s .. NORMAL
end

local lastRendered, lastRenderedAt

-- Matches the `config prompt custom` layout sent below. Returning a string replaces the line;
-- false deletes it; nil leaves Achaea's prompt as it was.
addTrigger([[^\[?[\d:.]*\]?\s*\d+/\d+ \d+/\d+ \d+/\d+ \d+/\d+ ]], function(_, line)
  if not PkCore.vitals.hp then return end
  prompt = line
  local ok, rendered = pcall(function()
    return substituteTags(substituteConditionals(substituteColors(PkCore.promptFormat)))
  end)
  if not ok then return end
  rendered = rendered:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")

  local now = getCurrentTime() / 1000
  if rendered == lastRendered and lastRenderedAt and now - lastRenderedAt < 0.15 then
    return false -- same content within 150ms: a duplicate prompt
  end
  lastRendered, lastRenderedAt = rendered, now

  if PkCore.promptDebug then setTimeout(function() PkCore.note("DBG: " .. line) end, 0) end
  return toAnsi(rendered)
end, { type = "regex", priority = 1 })

PkCore.registerAlias("PkCore prompt format set", [[^promptformat\s+(.+)$]], [[PkCore.promptFormat = matches[2] ]])
PkCore.registerAlias("PkCore prompt format report", [[^promptformat$]], [[PkCore.note("prompt format: " .. PkCore.promptFormat)]])
PkCore.registerAlias("PkCore prompt debug", [[^promptdebug\s+(on|off)$]], [[PkCore.promptDebug = (matches[2] == "on")]])

local configured = false
PkCore.onVitalsChanged("prompt.config", function()
  if configured then return end
  configured = true
  send("config prompt custom [*s] *h/*H *m/*M *e/*E *w/*W *b *d *c *r *k *t *T *1 *2 *3 *4")
end)