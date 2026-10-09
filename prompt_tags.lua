PkCore.promptTags = PkCore.promptTags or {}
PkCore.promptTagColors = PkCore.promptTagColors or {}
PkCore.promptDebug = PkCore.promptDebug or false

PkCore.afflictionShort = {
  ensorcelled = "ENS", sandfever = "SAND", mycalium = "myc", flushings = "fls", rebbies = "reb",
  pyramides = "PYR", addiction = "add", aeon = "AEON", agoraphobia = "agor", airfisted = "airf",
  amnesia = "amns", anorexia = "ano", asphyxiating = "asph", asthma = "ast", blackout = "BLKOUT",
  bleeding = "bld", blindness = "blnd", blistered = "blst", bloodfire = "bldfr", bound = "bound",
  brokenleftarm = "la1", brokenleftleg = "ll1", brokenrightarm = "ra1", brokenrightleg = "rl1",
  bruisedribs = "tt1", burning = "burn", cadmuscurse = "cadmus", calcifiedskull = "CAL-SKLL",
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

local t = PkCore.ui.theme

-- Prompt registry --
function PkCore.registerPromptTag(name, fn)
  PkCore.promptTags[name] = fn
end

function PkCore.registerPromptTagColor(name, fn)
  PkCore.promptTagColors[name] = fn
end

local function nativeDelta(unit)
  return function()
    local value = line:match("([%+%-]%d+)" .. unit)
    return value and (value .. unit) or ""
  end
end

local function nativeDeltaPerc(unit, maxKey, decimals)
  decimals = decimals or 1
  return function()
    local value = line:match("([%+%-]%d+)" .. unit)
    if not value then return "" end
    local max = PkCore.vitals[maxKey]
    if not max or max == 0 then return "" end
    local pct = (tonumber(value) / max) * 100
    return string.format("%+." .. decimals .. "f%%", pct)
  end
end

local function afflictionColor(name)
  for _, group in ipairs(AFFLICTION_COLOR_GROUPS) do
    if group.names[name] then return group.color end
  end
  if PkCore.afflictionShort[name] then return "112,128,144" end -- default (SlateGrey)
  return "205,92,92" -- unknown affliction (IndianRed)
end

-- Data tags --
PkCore.registerPromptTag("hp", function() return PkCore.vitals.hp end)
PkCore.registerPromptTag("maxhp", function() return PkCore.vitals.maxhp end)
PkCore.registerPromptTag("mp", function() return PkCore.vitals.mp end)
PkCore.registerPromptTag("maxmp", function() return PkCore.vitals.maxmp end)
PkCore.registerPromptTag("ep", function() return PkCore.vitals.ep end)
PkCore.registerPromptTag("maxep", function() return PkCore.vitals.maxep end)
PkCore.registerPromptTag("wp", function() return PkCore.vitals.wp end)
PkCore.registerPromptTag("maxwp", function() return PkCore.vitals.maxwp end)
PkCore.registerPromptTag("hpperc", function()
  return math.floor(math.min(100, math.max(0, (PkCore.vitals.hp / PkCore.vitals.maxhp) * 100))) .. "%"
end)
PkCore.registerPromptTag("mpperc", function()
  return math.floor(math.min(100, math.max(0, (PkCore.vitals.mp / PkCore.vitals.maxmp) * 100)))  .. "%"
end)
PkCore.registerPromptTag("epperc", function()
  return math.floor(math.min(100, math.max(0, (PkCore.vitals.ep / PkCore.vitals.maxep) * 100)))  .. "%"
end)
PkCore.registerPromptTag("wpperc", function()
  return math.floor(math.min(100, math.max(0, (PkCore.vitals.wp / PkCore.vitals.maxwp) * 100)))  .. "%"
end)
PkCore.registerPromptTag("hpdelta", nativeDelta("h"))
PkCore.registerPromptTag("mpdelta", nativeDelta("m"))
PkCore.registerPromptTag("epdelta", nativeDelta("e"))
PkCore.registerPromptTag("wpdelta", nativeDelta("w"))
PkCore.registerPromptTag("hpdelta", nativeDeltaPerc("h", "maxhp"))
PkCore.registerPromptTag("mpdelta", nativeDeltaPerc("m", "maxmp"))
PkCore.registerPromptTag("epdelta", nativeDeltaPerc("e", "maxep", 2))
PkCore.registerPromptTag("wpdelta", nativeDeltaPerc("w", "maxwp", 2))

PkCore.registerPromptTag("bal", function() return PkCore.balance.balance and "x" or "-" end)
PkCore.registerPromptTag("eq", function() return PkCore.balance.equilibrium and "e" or "-" end)
PkCore.registerPromptTag("target", function() return PkCore.room.targetName() or "" end)
PkCore.registerPromptTag("targethpperc", function() return PkCore.room.targetHpPercent or "" end)
PkCore.registerPromptTag("rage", function() return tostring(PkCore.playerStatus.rage or 0) end)
PkCore.registerPromptTag("afflictions", function()
  local names = {}
  for name in pairs(PkCore.afflictions.list) do
    if not PkCore.afflictionIgnore[name] then
      table.insert(names, name)
    end
  end
  table.sort(names)

  local parts = {}
  for _, name in ipairs(names) do
    local count = PkCore.afflictions.list[name]
    if name == "bleeding" and not ((PkCore.playerStatus.bleed or 0) > 50) then
    elseif name ~= "burning" then
      local short = PkCore.afflictionShort[name] or name
      if type(count) == "number" then
        short = short .. "(" .. count .. ")"
      end
      table.insert(parts, "<" .. afflictionColor(name) .. ">" .. short)
    else
      table.insert(parts, PkCore.afflictionShort[name] or name)
    end
  end
  if #parts == 0 then return "" end
  local theme = PkCore.ui.theme
  return table.concat(parts, " ") .. "<" .. theme.decimal(theme.text) .. ">"
end)
PkCore.registerPromptTag("targetafflictions", function()
  local parts = {}
  for _, name in ipairs(PkCore.target.afflictions) do
    if not LIMB_KEYS[name] then
      local short = PkCore.afflictionShort[name] or name
      table.insert(parts, "<" .. afflictionColor(name) .. ">" .. short)
    end
  end
  if #parts == 0 then return "" end
  local theme = PkCore.ui.theme
  return table.concat(parts, " ") .. "<" .. theme.decimal(theme.text) .. ">"
end)
PkCore.registerPromptTag("timestamp", function()
  local ts = line:match("^%[([%d:.]+)%]")
  return ts or ""
end)

PkCore.registerPromptTag("defenses", function()
  local d = line:match("^%[?[%d:.]*%]?%s*%d+/%d+ %d+/%d+ %d+/%d+ %d+/%d+ %S* (%S*)")
  return d or ""
end)

-- Color tags: percentage-tiered, same thresholds WunderSys uses --
local function tierColor(current, max, highPct, lowPct)
  if not current or not max or max == 0 then return t.decimal(t.text) end
  local pct = current / max
  if pct >= highPct then return t.decimal(t.good) end
  if pct >= lowPct then return t.decimal(t.warning) end
  return t.decimal(t.critical)
end

local function deltaColorTag(unit, upColor, downColor)
  return function()
    local v = line:match("([%+%-]%d+)" .. unit)
    if not v then return nil end
    return t.decimal(v:sub(1, 1) == "+" and upColor or downColor)
  end
end

PkCore.registerPromptTagColor("hcolour", function() return tierColor(PkCore.vitals.hp, PkCore.vitals.maxhp, 0.75, 0.33) end)
PkCore.registerPromptTagColor("mcolour", function() return tierColor(PkCore.vitals.mp, PkCore.vitals.maxmp, 0.75, 0.50) end)
PkCore.registerPromptTagColor("ecolour", function() return tierColor(PkCore.vitals.ep, PkCore.vitals.maxep, 0.66, 0.50) end)
PkCore.registerPromptTagColor("wcolour", function() return tierColor(PkCore.vitals.wp, PkCore.vitals.maxwp, 0.66, 0.50) end)
PkCore.registerPromptTagColor("hpdeltacolour", deltaColorTag("h", t.hp, t.hp2))
PkCore.registerPromptTagColor("mpdeltacolour", deltaColorTag("m", t.mana, t.mana2))
PkCore.registerPromptTagColor("epdeltacolour", deltaColorTag("e", t.endurance, t.endurance2))
PkCore.registerPromptTagColor("wpdeltacolour", deltaColorTag("w", t.willpower, t.willpower2))


PkCore.promptFormat = PkCore.promptFormat or
  "[@timestamp] #hcolour@hp<r>h #mcolour@mp<r>m #ecolour@epperc<r>e #wcolour@wpperc<r>w @eq@bal@defenses {rage:R:@rage}{target: [@target(@targethpperc)]}{targetafflictions:T[@targetafflictions]} {afflictions:M[@afflictions]} {hpdelta:(#hpdeltacolour@hpdelta<r>)} {mpdelta:(#mpdeltacolour@mpdelta<r>)} {epdelta:(#epdeltacolour@epdelta<r>)} {wpdelta:(#wpdeltacolour@wpdelta<r>)}"

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

PkCore.trackTrigger(tempPromptTrigger(
  PkCore.protected("status.promptAnnotate", function()
    if not PkCore.vitals.hp then return end
    if PkCore.promptDebug then
      PkCore.lastRawPrompt = line
    end
    local rendered = substituteTags(substituteConditionals(substituteColors(PkCore.promptFormat)))
      :gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
    deleteLine()
    decho("\n"..rendered)
  end)))

PkCore.registerAlias("PkCore prompt format set", [[^promptformat\s+(.+)$]], [[PkCore.promptFormat = matches[2] ]])
PkCore.registerAlias("PkCore prompt format report", [[^promptformat$]], [[PkCore.note("prompt format: " .. PkCore.promptFormat)]])
PkCore.registerAlias("PkCore prompt debug", [[^promptdebug\s+(on|off)$]], [[PkCore.promptDebug = (matches[2] == "on")]])

-- Send the full prompt we will ultimately use for parsing/replacement
PkCore.onReady(function()
  send("config prompt custom [*s] *h/*H *m/*M *e/*E *w/*W *b *d *c *r *k *t *T *1 *2 *3 *4")
end)


