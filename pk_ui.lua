-- pk_ui: PkCore for MudForge. Main script: metadata, the shared table, and load order.
-- Modules live in pk_ui/ beside this file (MudForge's plugin folder layout).

plugin = {
  name        = "pk_ui",
  version     = "0.3.0",
  author      = "greg",
  description = "PkCore UI widgets (MudForge port)",
}

PkCore = PkCore or {}

loadModule("module_registration.lua")

-- init() can run several times in a row (one save can fire several hot reloads),
-- so everything it calls must be safe to repeat.
function init()
  PkCore.ui.layout.build()
  echo("[pk_ui] v" .. plugin.version .. " loaded at " .. formatTime(getCurrentTime()), "#a5d3ba")
end

function onConnect()
  PkCore.gmcp.refreshSupport()
end