PkCore.config = PkCore.config or {}
PkCore.config.path = PkCore.path .. "/config.dat"
PkCore.config.values = PkCore.config.values or {}

PkCore.config.defaults = {
  affEchos = false,
}
local function load()
    for key, value in pairs(PkCore.config.defaults) do
        if PkCore.config.values[key] == nil then PkCore.config.values[key] = value end
    end
    table.load(PkCore.config.path, PkCore.config.values)  -- overlays any saved values on top of defaults
end


function PkCore.config.set(key, value)
    if PkCore.config.defaults[key] == nil then
        PkCore.note("unknown config key: " .. tostring(key))
        return
    end
    PkCore.config.values[key] = value
    table.save(PkCore.config.path, PkCore.config.values)
end

function PkCore.config.alias(key, rawValue)
    local value = rawValue
    if rawValue == "on" or rawValue == "true" then value = true
    elseif rawValue == "off" or rawValue == "false" then value = false
    elseif tonumber(rawValue) then value = tonumber(rawValue)
    end
    PkCore.config.set(key, value)
end

function PkCore.config.report()
    local lines = {}
    for key in pairs(PkCore.config.defaults) do
        table.insert(lines, string.format("  %-20s %s", key, tostring(PkCore.config.values[key])))
    end
    table.sort(lines)  -- pairs() order isn't guaranteed - same reasoning tasks.lua uses for its own table.sort
    PkCore.note("config:\n" .. table.concat(lines, "\n"))
end

-- Grab our defaults
load()

PkCore.registerAlias("PkCore config list", [[^pkconfig$]], [[PkCore.config.report()]])
PkCore.registerAlias("PkCore config set", [[^pkconfig\s+(\S+)\s+(\S+)$]], [[PkCore.config.alias(matches[2], matches[3])]])