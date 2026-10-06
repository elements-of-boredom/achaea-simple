PkCore.ui.topbar = PkCore.ui.topbar or {}

local BRAND_WIDTH = 165

function PkCore.ui.topbar.cleanup()
    PkCore.ui.topbar.widgets = nil
end

function PkCore.ui.topbar.ensureWidgets()
    if PkCore.ui.topbar.widgets then return PkCore.ui.topbar.widgets end
    if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.topbar) then return nil end

    local container = PkCore.ui.sections.topbar

    local brandName = Geyser.Label:new({
        name = "PkCore_topbar_brand_name",
        x = "10px", y = "6px", width = (BRAND_WIDTH - 15), height = "16px",
        font = "Georgia", fontSize = 12,
    }, container)
    brandName:setStyleSheet("background: transparent;")
    brandName:echo("ACHAEA", "#dce6dc", "b")

    local brandSub = Geyser.Label:new({
        name = "PkCore_topbar_brand_sub",
        x = "10px", y = "24px", width = (BRAND_WIDTH - 15), height = "14px",
        font = "Consolas", fontSize = 7,
    }, container)
    brandSub:setStyleSheet("background: transparent;")
    brandSub:echo("COMMAND SKIN", "#7d8b86")

    local titleName = Geyser.Label:new({
        name = "PkCore_topbar_title_name",
        x = BRAND_WIDTH, y = "4px", width = "100%-" .. (BRAND_WIDTH + 10), height = "18px",
        font = "Georgia", fontSize = 13, format = "cb",
    }, container)
    titleName:setStyleSheet("background: transparent;")

    local titleSub = Geyser.Label:new({
        name = "PkCore_topbar_title_sub",
        x = BRAND_WIDTH, y = "24px", width = "100%-" .. (BRAND_WIDTH + 10), height = "14px",
        font = "Consolas", fontSize = 9, format = "c",
    }, container)
    titleSub:setStyleSheet("background: transparent;")

    for _, name in ipairs({ "PkCore_topbar_brand_name", "PkCore_topbar_brand_sub", "PkCore_topbar_title_name", "PkCore_topbar_title_sub" }) do
        raiseWindow(name)
    end

    PkCore.ui.topbar.widgets = { titleName = titleName, titleSub = titleSub }
    return PkCore.ui.topbar.widgets
end

function PkCore.ui.topbar.render()
    local widgets = PkCore.ui.topbar.ensureWidgets()
    if not widgets then return end

    widgets.titleName:echo(tostring(PkCore.room.name or "Unknown Room"):upper(), "#e4eee6", "cb")

    local exits = table.concat(PkCore.room.sortedExits(), ", ")
    local sub = "[" .. tostring(PkCore.room.number or "?") .. "] "
    if exits ~= "" then sub = sub .. " - EXITS: " .. exits:upper() end
    widgets.titleSub:echo(sub, "#9aa8a1")
end

PkCore.registerSystem("ui.topbar", { cleanup = PkCore.ui.topbar.cleanup, rebuild = PkCore.ui.topbar.render })
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed", PkCore.protected("ui.topbar.render", PkCore.ui.topbar.render)))