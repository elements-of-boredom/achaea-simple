PkCore.gmcp = PkCore.gmcp or {}

-- Achaea modules beyond the client's defaults. Pulled from Nexus
local MODULES = {
  "Char.Vitals 1", "Char.Afflictions 1", "Char.Defences 1", "Char.Items 1", "Comm.Channel 1",
  "IRE.Rift 1", "IRE.Target 1", "IRE.Time 1", "IRE.Misc 1", "IRE.Tasks 1", "IRE.News 1",
  "IRE.Sound 1", "IRE.FileStore 1", "IRE.Composer 1", "Redirect 2", "Room 1", "IRE.Display 3",
}

-- Returns false when not connected (sendGMCP warns once per disconnection).
function PkCore.gmcp.ensureSupport()
  return sendGMCP("Core.Supports.Add", MODULES)
end

--  The client sends its own Core.Supports.Set during login, which replaces the list
function PkCore.gmcp.refreshSupport()
  if not PkCore.gmcp.ensureSupport() then return end   -- offline: onConnect will call this again
  setTimeout(PkCore.gmcp.ensureSupport, 1000)
  setTimeout(PkCore.gmcp.ensureSupport, 3000)
  setTimeout(PkCore.gmcp.ensureSupport, 6000)
end

onGMCPUpdate("Core.Hello", PkCore.gmcp.refreshSupport)