PkCore.config = PkCore.config or {}
local config = PkCore.config
local SAVE_KEY = "config" -- for saveTable

config.defaults = {
  affEchos = false,
}

-- Defaults first, then saved values on top; keys no longer in defaults are dropped.
local function load()
  local saved = loadTable(SAVE_KEY) or {}
  config.values = {}
  for key, value in pairs(config.defaults) do
    if saved[key] ~= nil then config.values[key] = saved[key] else config.values[key] = value end
  end
end

function config.set(key, value)
  if config.defaults[key] == nil then
    PkCore.note("unknown config key: " .. tostring(key))
    return
  end
  config.values[key] = value
  saveTable(SAVE_KEY, config.values)
end

function config.alias(key, rawValue)
  local value = rawValue
  if rawValue == "on" or rawValue == "true" then value = true
  elseif rawValue == "off" or rawValue == "false" then value = false
  elseif tonumber(rawValue) then value = tonumber(rawValue)
  end
  config.set(key, value)
end

function config.report()
  local lines = {}
  for key in pairs(config.defaults) do
    table.insert(lines, string.format("  %-20s %s", key, tostring(config.values[key])))
  end
  table.sort(lines)
  PkCore.note("config:\n" .. table.concat(lines, "\n"))
end

load()

PkCore.registerAlias("PkCore config list", [[^pkconfig$]], [[PkCore.config.report()]])
PkCore.registerAlias("PkCore config set", [[^pkconfig\s+(\S+)\s+(\S+)$]], [[PkCore.config.alias(matches[2], matches[3])]])