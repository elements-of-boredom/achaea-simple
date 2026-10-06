PkCore.ui = PkCore.ui or {}

PkCore.ui.PANEL_CSS = [[background: qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 rgba(6,12,13,168), stop:1 rgba(6,7,11,199)); border: 1px solid rgba(82,98,106,158);]]

local function panelBackground(container, name)
  local bg = Geyser.Label:new({
    name = name,
    x = "0%", y = "0%", width = "100%", height = "100%",
  }, container)
  bg:setStyleSheet(PkCore.ui.PANEL_CSS)
  return bg
end

local function styleMainWindow()
    setBackgroundColor("main", 4, 7, 9, 200)
    local width, height = getMainWindowSize()
    local leftPanelWidth = width * 0.08
    setBorderLeft(leftPanelWidth + 5)
    setBorderRight((width * .25) + 5)
    setBorderTop(56)
    setBorderBottom(61)
    setBackgroundImage("main", getMudletHomeDir() .. "/pk/assets/forestral-grove-bg-v2.png", "cover", true)
end

function PkCore.ui.build()
    if PkCore.ui.root then return end

    PkCore.ui.root = Geyser.Container:new({
        name = "PkCore_ui_root",
        x = "0%", y = "0%", width = "100%", height = "100%",
    })

    PkCore.ui.sections = {
        topbar = Geyser.Container:new({ name = "PkCore_ui_topbar", x = "5px", y = "5px", width = "75%-10px", height = "46px" }, PkCore.ui.root),
        left   = Geyser.Container:new({ name = "PkCore_ui_left",   x = "5px", y = "56px", width = "8%-5px", height = "100%-61" }, PkCore.ui.root),
        center = Geyser.Container:new({ name = "PkCore_ui_center", x = "8%+5px", y = "46px", width = "67%-10px", height = "100%-46" }, PkCore.ui.root),
        right  = Geyser.Container:new({ name = "PkCore_ui_right",  x = "75%", y = "5px", width = "25%-5px", height = "100%-10" }, PkCore.ui.root),
    }

    -- center column: terminal (flex) + vitals (fixed 50px), stacked
    PkCore.ui.sections.vitals   = Geyser.Container:new({ x = "0%", y = "100%-55", width = "100%", height = "50px" }, PkCore.ui.sections.center)
    PkCore.ui.sections.playerVitals = Geyser.Container:new({ x = "0%", y = "0%", width = "60%", height = "100%" }, PkCore.ui.sections.vitals)
    PkCore.ui.sections.target       = Geyser.Container:new({ x = "60%+5px", y = "0%", width = "40%-5px", height = "100%" }, PkCore.ui.sections.vitals)

    -- right column: map / chat / room, stacked (same keys as before, so room.lua/vitals.lua/chat.lua need no changes)
    PkCore.ui.sections.map  = Geyser.Container:new({ x = "0%", y = "0%", width = "100%", height = "35%" }, PkCore.ui.sections.right)
    PkCore.ui.sections.chat = Geyser.Container:new({ x = "0%", y = "35%+5px", width = "100%", height = "40%-10px" }, PkCore.ui.sections.right)
    PkCore.ui.sections.room = Geyser.Container:new({ x = "0%", y = "75%", width = "100%", height = "25%" }, PkCore.ui.sections.right)

    panelBackground(PkCore.ui.sections.topbar, "PkCore_ui_top_bg")
    panelBackground(PkCore.ui.sections.playerVitals, "PkCore_ui_vitals_player")
    panelBackground(PkCore.ui.sections.target, "PkCore_ui_vitals_target")
    panelBackground(PkCore.ui.sections.left, "PkCore_ui_left_bg")
    panelBackground(PkCore.ui.sections.map, "PkCore_ui_map_bg")
    panelBackground(PkCore.ui.sections.chat,"PkCore_ui_chat_bg")
    panelBackground(PkCore.ui.sections.room,"PkCore_ui_room_bg")
    
    styleMainWindow()    
end

function PkCore.ui.cleanup()
    if not PkCore.ui.root then return end
    PkCore.ui.root:hide()
    PkCore.ui.root = nil
    PkCore.ui.sections = nil
end

PkCore.registerSystem("ui", { rebuild = PkCore.ui.build, cleanup = PkCore.ui.cleanup })