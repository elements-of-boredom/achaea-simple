PkCore.classes = PkCore.classes or {}
local CLASS_FILES = { "sylvan", "bard", "bluedragon" }

for _, name in ipairs(CLASS_FILES) do
  local path = PkCore.path .. "/classes/" .. name .. ".lua"
  local loader, loadErr = loadfile(path)
  if loader then
    local ok, data = pcall(loader)
    if ok and type(data) == "table" then
      PkCore.classes[name] = data
    else
      PkCore.note("classes/" .. name .. ".lua error: " .. tostring(data))
    end
  else
    PkCore.note("classes/" .. name .. ".lua not found: " .. tostring(loadErr))
  end
end

function PkCore.classes.current()
  local status = gmcp and gmcp.Char and gmcp.Char.Status
  local className = status and status.class
  if not className then return nil end
  return PkCore.classes[className:lower():gsub("%s+", "")]
end