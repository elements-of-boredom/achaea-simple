PkCore.vitals = PkCore.vitals or {}
PkCore.balance = PkCore.balance or {}
PkCore.playerStatus = PkCore.playerStatus or {}

local VITALS = { "hp", "mp", "ep", "wp" }

local function num(v)
  if type(v) == "number" then return v end
  if type(v) ~= "string" or v == "" then return nil end
  return tonumber(v)
end

function PkCore.balance.has(name)
  return PkCore.balance[name] == true
end

-- Char.Vitals repeats bal/eq on every prompt; only a real change raises the event.
local function applyChange(name, value)
  if PkCore.balance[name] == value then return end
  PkCore.balance[name] = value
  raiseEvent(value and "PkCore balance gained" or "PkCore balance lost", name)
end

function PkCore.vitals.onVitals(data)
  if type(data) ~= "table" then return end
  applyChange("balance", tostring(data.bal) == "1")
  applyChange("equilibrium", tostring(data.eq) == "1")
  for _, key in ipairs(VITALS) do
    PkCore.vitals[key] = num(data[key])
    PkCore.vitals["max" .. key] = num(data["max" .. key])
  end
  PkCore.playerStatus = statsOf(data.charstats)
  PkCore.vitalsChanged()
end

onGMCPUpdate("Char.Vitals", PkCore.vitals.onVitals)

-- charstats: { "Bleed: 0", "Rage: 12", ... } -> { bleed = 0, rage = 12 }
local function statsOf(charstats)
  local stats = {}
  if type(charstats) ~= "table" then return stats end
  for _, entry in ipairs(charstats) do
    if type(entry) == "string" then
      local key, value = entry:match("^(%a+):%s*(%-?%d+)$")
      if key then stats[key:lower()] = tonumber(value) end
    end
  end
  return stats
end