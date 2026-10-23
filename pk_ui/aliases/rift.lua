-- Rift curing-stock checker: parses `ir` (Achaea's rift-contents command)
-- and flags any cure whose rift stock is below THRESHOLD, so you know what
-- to shop for. Ported from codex-ui's real, working rift.lua - CURE_GROUPS
-- is real Achaea curing data (herb/mineral/salve/elixir pairs per
-- affliction), not guessed.
PkCore.rift = PkCore.rift or {}

PkCore.rift.THRESHOLD = 500

PkCore.rift.CURE_GROUPS = {
  { label = "Aeon / Deadening",          herb = "elm",        mineral = "cinnabar"    },
  { label = "Addiction / Darkshade",     herb = "ginseng",    mineral = "ferrum"      },
  { label = "Agoraphobia / Vertigo",     herb = "lobelia",    mineral = "argentum"    },
  { label = "Anti-Weapon (Rebounding)",  herb = "skullcap",   mineral = "malachite"   },
  { label = "Blindness",                 herb = "bayberry",   mineral = "arsenic"     },
  { label = "Confusion / Dementia",      herb = "ash",        mineral = "stannum"     },
  { label = "Deafness",                  herb = "hawthorn",   mineral = "calamine"    },
  { label = "Deathsight",                herb = "skullcap",   mineral = "azurite"     },
  { label = "Dissonance / Epilepsy",     herb = "goldenseal", mineral = "plumbum"     },
  { label = "Disfigurement / Hellsight", herb = "valerian",   mineral = "realgar"     },
  { label = "Drowning",                  herb = "pear",       mineral = "calcite"     },
  { label = "Generosity / Peace",        herb = "bellwort",   mineral = "cuprum"      },
  { label = "Health / Mana",             herb = "irid",       mineral = "potash"      },
  { label = "Health Leech / Asthma",     herb = "kelp",       mineral = "aurum"       },
  { label = "Insomnia",                  herb = "cohosh",     mineral = "gypsum"      },
  { label = "Learning Speed",            herb = "myrrh gum",  mineral = "bisemutum"   },
  { label = "Paralysis / Slickness",     herb = "bloodroot",  mineral = "magnesium"   },
  { label = "Serpent Venom Defense",     herb = "sileris",    mineral = "quicksilver" },
  { label = "Sleep Resistance (Kola)",   herb = "kola",       mineral = "quartz"      },
  { label = "Tempered Humours",          herb = "ginger",     mineral = "antimony"    },
  { label = "Third Eye",                 herb = "echinacea",  mineral = "dolomite"    },
  { label = "Ablaze / Crippled",         salve = "mending"     },
  { label = "Anorexia / Blindness",      salve = "epidermal"   },
  { label = "Concussion / Damaged",      salve = "restoration" },
  { label = "Freezing",                  salve = "caloric"     },
  { label = "Mass",                      salve = "mass"        },
  { label = "Voyria",                    elixir = "immunity"   },
  { label = "Health",                    elixir = "health"     },
  { label = "Mana",                      elixir = "mana"       },
  { label = "Frost",                     elixir = "frost"      },
  { label = "Venom",                     elixir = "venom"      },
  { label = "Speed",                     elixir = "speed"      },
  { label = "Levitation",                elixir = "levitation" },
  
}

-- Built as one string and delivered through PkCore.note(), same
-- pattern bash.lua's/rage.lua's explain() use for multi-line reports.
function PkCore.rift.report(rift)
  local T = PkCore.rift.THRESHOLD
  local anyWarn = false
  local lines = {}

  table.insert(lines, string.format("<white>  %-30s %-16s%4s   %-16s%4s   %5s<reset>",
    "Cure Type", "Herb", "Qty", "Mineral", "Qty", "Total"))
  table.insert(lines, "  " .. string.rep("-", 82))

  for _, g in ipairs(PkCore.rift.CURE_GROUPS) do
    if g.herb then
      local hq = rift[g.herb] or 0
      local mq = rift[g.mineral] or 0
      local total = hq + mq
      local low = total < T
      if low then anyWarn = true end
      local col = low and "<red>" or "<green>"
      table.insert(lines, string.format("  %-30s %s%-16s%4d<reset>   %s%-16s%4d<reset>   %s%5d<reset>",
        g.label .. ":", col, g.herb, hq, col, g.mineral, mq, col, total))
    end
  end

  table.insert(lines, "")
  table.insert(lines, string.format("<white>  %-30s %-16s%4s<reset>", "Salves & Elixirs", "Item", "Qty"))
  table.insert(lines, "  " .. string.rep("-", 51))
  for _, g in ipairs(PkCore.rift.CURE_GROUPS) do
    local item = g.salve or g.elixir
    if item then
      local qty = rift[item] or 0
      local low = qty < T
      if low then anyWarn = true end
      local col = low and "<red>" or "<green>"
      table.insert(lines, string.format("  %-30s %s%-16s%4d<reset>", g.label .. ":", col, item, qty))
    end
  end

  table.insert(lines, "")
  if anyWarn then
    table.insert(lines, "<red>One or more curing stocks need restocking.<reset>")
  else
    table.insert(lines, string.format("<green>All curing stocks are sufficient (>= %d).<reset>", T))
  end

  PkCore.note(string.format("rift check (threshold %d):\n", T) .. table.concat(lines, "\n"))
end

-- IRE.Rift.List is the whole rift, IRE.Rift.Change one item. getGMCPData only keeps the
-- last message of each, so the merged view lives here.
PkCore.rift.items = PkCore.rift.items or {}
-- `name` is Achaea's id ("moss", "mending"); `desc` is what `ir` shows ("irid",
-- "a salve of mending"). CURE_GROUPS mixes the two, so store under both.
local function record(items, entry)
  if type(entry) ~= "table" then return end
  local amount = tonumber(entry.amount) or 0
  if type(entry.name) == "string" then items[entry.name:lower()] = amount end
  if type(entry.desc) == "string" then items[entry.desc:lower()] = amount end
end

-- GMCP arrays can come through 0-indexed; ipairs starts at 1 and would skip the first entry.
local function eachEntry(list, fn)
  if list[0] ~= nil then fn(list[0]) end
  for _, entry in ipairs(list) do fn(entry) end
end

function PkCore.rift.onList(list)
  if type(list) ~= "table" then return end
  local items = {}
  eachEntry(list, function(entry) record(items, entry) end)
  PkCore.rift.items = items
  PkCore.rift.loaded = true
end

function PkCore.rift.onChange(entry)
  record(PkCore.rift.items, entry)
end

function PkCore.rift.check()
  if not PkCore.rift.loaded then
    PkCore.rift.onList(getGMCPData("IRE.Rift.List"))
    sendGMCP("IRE.Rift.Request") -- the cached list misses Changes since it arrived; refresh quietly
  end
  if not PkCore.rift.loaded then
    PkCore.note("no rift data yet - requested; try rcheck again after your next command")
    return
  end
  PkCore.rift.report(PkCore.rift.items)
end

onGMCPUpdate("IRE.Rift.List", PkCore.rift.onList)
onGMCPUpdate("IRE.Rift.Change", PkCore.rift.onChange)

PkCore.registerAlias("PkCore rift check", [[^rcheck$]], [[PkCore.rift.check()]])