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
  PkCore.ui.header.render()   -- "?" placeholders until real data arrives

  -- Only a reload during a logged-in session has anything to restore. Before login,
  -- onConnect and the GMCP handlers take care of everything as data arrives.
  if getGMCPData("Char.Status") then
    PkCore.gmcp.refreshSupport()
    -- onGMCPUpdate only fires on the NEXT message, so refill the blackboard from what
    -- MudForge already has. Room.Info before items/players: it resets them on a "new" room.
    PkCore.player.onStatus(getGMCPData("Char.Status"))
    PkCore.vitals.onVitals(getGMCPData("Char.Vitals"))
    PkCore.room.onInfo(getGMCPData("Room.Info"))
    PkCore.room.onItemsList(getGMCPData("Char.Items.List"))
    PkCore.room.onPlayers(getGMCPData("Room.Players"))
    PkCore.room.onTargetSet(getGMCPData("IRE.Target.Set"))
    PkCore.room.onTargetInfo(getGMCPData("IRE.Target.Info"))
  end

  echo("[pk_ui] v" .. plugin.version .. " loaded at " .. formatTime(getCurrentTime()), "#a5d3ba")
end

function onConnect()
  PkCore.gmcp.refreshSupport()
end