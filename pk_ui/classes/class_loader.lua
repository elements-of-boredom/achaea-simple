PkCore.classes = PkCore.classes or {}

-- MudForge can't list a folder, so add new class files here.
local CLASS_FILES = { "sylvan", "bluedragon", "earthlord" }
local CLASS_NAME_ALIASES = { earthlord = { "earthelementallord" } }

for _, name in ipairs(CLASS_FILES) do
  local ok, data = pcall(loadModule, "classes/" .. name .. ".lua")
  if ok and type(data) == "table" then
      PkCore.classes[name] = data
      for _, alias in ipairs(CLASS_NAME_ALIASES[name] or {}) do PkCore.classes[alias] = data end
    else
    PkCore.note("classes/" .. name .. ".lua error: " .. tostring(data))
  end
end

function PkCore.classes.current()
  local className = PkCore.player.class
  if type(className) ~= "string" then return nil end
  return PkCore.classes[(className:lower():gsub("%s+", ""))]
end