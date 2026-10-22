-- Load order matters: a module may only use what was loaded before it.

-- Core/Global registrations: the state-changed signal and other utilities everyone uses.
loadModule("core.lua")
loadModule("gmcp.lua")

-- State: GMCP -> the PkCore blackboard.
loadModule("state/player.lua")
loadModule("state/room.lua")
loadModule("state/vitals.lua")
loadModule("state/afflictions.lua")

-- UI: the theme first, every widget uses it. Layout builds the (empty) panels.
loadModule("ui/theme_css.lua")
loadModule("ui/theme.lua")
loadModule("ui/layout.lua")
-- sub ui modules

loadModule("ui/header.lua")
loadModule("ui/chat.lua")
loadModule("ui/room.lua")
loadModule("ui/afflictions.lua")
loadModule("ui/sidebar.lua")
loadModule("ui/limbs.lua")
loadModule("ui/hud_self.lua")
loadModule("ui/hud_target.lua")

-- Task system
loadModule("tasks/taskrunner.lua")
loadModule("tasks/tasks.lua")