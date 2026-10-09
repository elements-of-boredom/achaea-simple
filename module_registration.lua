-- Bootstrap sub-modules -- should have no other dependencies
PkCore.loadModule("config.lua")
PkCore.loadModule("ui/ui.lua")
PkCore.loadModule("ui/theme.lua") 

-- Blackboards (state) --
PkCore.loadModule("gmcp.lua")
PkCore.loadModule("readiness.lua")
PkCore.loadModule("target_afflictions.lua")
PkCore.loadModule("room_info.lua")
PkCore.loadModule("player_status.lua")
PkCore.loadModule("prompt_tags.lua")

-- Class systems --
PkCore.loadModule("classes/class_loader.lua")
PkCore.loadModule("rage.lua")

-- PRETTY! --
PkCore.loadModule("colorize.lua")

-- UI --
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
-- All pk stragies must go aver pk.lua
PkCore.loadModule("reactor_modes/strategies/heartseed.lua")
PkCore.loadModule("reactor_modes/strategies/shockwave.lua")
PkCore.loadModule("reactor_modes/strategies/sylvan_lock.lua")
PkCore.loadModule("reactor_modes/strategies/fireguy.lua")

-- Utility / Aliases --
PkCore.loadModule("gold_pickup.lua")
PkCore.loadModule("aliases/stats.lua")
PkCore.loadModule("aliases/iht.lua")
PkCore.loadModule("aliases/hh.lua") 
PkCore.loadModule("aliases/st.lua")

-- Compatabiilty fixes --
PkCore.loadModule("wundersys_compat.lua")
