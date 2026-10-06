PkCore.gmcp = PkCore.gmcp or {}

function PkCore.gmcp.ensureSupport()
  if type(sendGMCP) ~= "function" then return end
  pcall(sendGMCP, [=[Core.Supports.Add ["Char.Vitals 1","Char.Afflictions 1","Char.Defences 1","Char.Items 1","Comm.Channel 1","IRE.Rift 1","IRE.Target 1","IRE.Time 1","IRE.Misc 1","IRE.Tasks 1","IRE.News 1","IRE.Sound 1","IRE.FileStore 1","IRE.Composer 1","Redirect 2","Room 1","IRE.Display 3"]]=])
end

function PkCore.gmcp.refreshSupport()
  PkCore.gmcp.ensureSupport()
  if type(tempTimer) ~= "function" then return end
  tempTimer(1, PkCore.gmcp.ensureSupport)
  tempTimer(3, PkCore.gmcp.ensureSupport)
  tempTimer(6, PkCore.gmcp.ensureSupport)
end

PkCore.gmcp.refreshSupport() -- covers reload while already connected

PkCore.trackHandler(registerAnonymousEventHandler(
  "sysConnectionEvent", PkCore.protected("gmcp.refreshSupport", PkCore.gmcp.refreshSupport)))
PkCore.trackHandler(registerAnonymousEventHandler(
  "gmcp.Core.Hello", PkCore.protected("gmcp.refreshSupport", PkCore.gmcp.refreshSupport)))