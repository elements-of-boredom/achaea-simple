-- Bootstrap sub-modules
PkCore.loadModule("config.lua")

PkCore.loadModule("gmcp.lua")
PkCore.loadModule("readiness.lua")
PkCore.loadModule("target_afflictions.lua")
PkCore.loadModule("room_info.lua")

-- Class systems --
PkCore.loadModule("classes/class_loader.lua")

-- PRETTY! --
PkCore.loadModule("colorize.lua")

-- UI --
PkCore.loadModule("ui/ui.lua")
PkCore.loadModule("ui/theme.lua")
PkCore.loadModule("ui/header.lua")
PkCore.loadModule("ui/topbar.lua")
PkCore.loadModule("ui/map.lua")
PkCore.loadModule("ui/chat.lua")
PkCore.loadModule("ui/room.lua")
PkCore.loadModule("ui/vitals.lua")
PkCore.loadModule("ui/rail.lua")

-- Task System 
PkCore.loadModule("taskrunner.lua")
PkCore.loadModule("tasks.lua")
PkCore.loadModule("rift.lua")

-- Reactor Modes --
PkCore.loadModule("reactor.lua")
PkCore.loadModule("reactor_modes/hunt.lua")
PkCore.loadModule("reactor_modes/pk.lua")
