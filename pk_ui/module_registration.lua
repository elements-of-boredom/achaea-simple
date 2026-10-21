-- Load order matters: a module may only use what was loaded before it.

-- UI: the theme first, every widget uses it. Layout builds the (empty) panels.
loadModule("ui/theme_css.lua")
loadModule("ui/theme.lua")
loadModule("ui/layout.lua")
