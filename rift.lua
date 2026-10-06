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

-- Captures `ir` output: two "----" dash lines bound the item block, item
-- lines are "[ qty ] name" pairs. AchaeaUI.hookMainLine() (ui.lua) calls
-- PkCore.rift.handleLine() directly for every main line (same
-- mechanism map.lua's ascii capture uses). Always reset on load, not
-- `... or` - a ui-reload mid-capture would leave `active` stuck true forever otherwise.
PkCore.rift.capture = { active = false }

local function finishCapture()
  local cap = PkCore.rift.capture
  if not cap.active then
    return
  end
  cap.active = false
  pcall(killTimer, cap.timerId)
  pcall(killTrigger, cap.triggerId)
  local rift = cap.rift
  tempTimer(0, function() PkCore.rift.report(rift) end)
end

-- Returns true if this line was consumed (part of the `ir` block), so
-- hookMainLine() gags it from main via deleteLine().
function PkCore.rift.handleLine(rawLine)
  local cap = PkCore.rift.capture
  if not cap.active then
    return false
  end

  if rawLine:match("^Glancing into your rift") or rawLine:match("^%($") then
    return true
  end

  if rawLine:match("^%-%-%-%-%-%-%-%-%-%-+$") then
    cap.dashCount = cap.dashCount + 1
    if cap.dashCount >= 2 then
      finishCapture()
    end
    return true
  end

  if cap.dashCount ~= 1 then
    return false
  end

  if rawLine:match("^%[") then
    for qtyStr, raw in rawLine:gmatch("%[%s*(%d+)%]%s+([^%[]+)") do
      local qty = tonumber(qtyStr)
      local name = raw:match("^(.-)%s*$"):lower()
      if qty and name ~= "" then
        cap.rift[name] = qty
      end
    end
    return true
  end

  -- Section headers (Herbs/Minerals/...) and the blank lines between them.
  if rawLine == "" or rawLine:match("^%a[%a ]*$") then
    return true
  end

  return false
end

function PkCore.rift.check()
  local cap = PkCore.rift.capture
  if cap.active then
    return
  end
  cap.active = true
  cap.dashCount = 0
  cap.rift = {}
  cap.timerId = PkCore.trackTimer(tempTimer(8, PkCore.protected("rift.checkTimeout", finishCapture)))
  cap.triggerId = tempRegexTrigger("^.*$", PkCore.protected("rift.onLine", function()
    PkCore.note("inside trigger")
    if PkCore.rift.handleLine(line) then
      deleteLine()
    end
  end))

  send("ir")
end

PkCore.registerAlias("PkCore rift check", [[^rcheck$]], [[PkCore.rift.check()]])
