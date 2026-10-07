PkCore.ui.topbar = PkCore.ui.topbar or {}

local BRAND_WIDTH = 165
local STATS_WIDTH = 150
local t = PkCore.ui.theme

local function formatNumber(n)
  if not n then return "?" end
  local str = tostring(math.floor(n))
  local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (formatted:gsub("^,", ""))
end

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

    local titleName = Geyser.Label:new({
        name = "PkCore_topbar_title_name",
        x = BRAND_WIDTH, y = "4px", width = "100%-" .. (BRAND_WIDTH + STATS_WIDTH * 2 + 10), height = "18px",
        font = "Georgia", fontSize = 13, format = "cb",
    }, container)
    titleName:setStyleSheet("background: transparent;")

    local titleSub = Geyser.Label:new({
        name = "PkCore_topbar_title_sub",
        x = BRAND_WIDTH, y = "24px", width = "100%-" .. (BRAND_WIDTH + STATS_WIDTH * 2 + 10), height = "14px",
        font = "Consolas", fontSize = 9, format = "c",
    }, container)
    titleSub:setStyleSheet("background: transparent;")

    local function statColumn(suffix, x)
        local rows = {}
        for i = 1, 3 do 
            local name = "PkCore_topbar_stat_" .. suffix .. i
            local row = Geyser.Label:new({
                name = name,
                x = x, y = (2 + (i - 1) * 14), width = STATS_WIDTH, height = 13,
                font = "Consolas", fontSize = 9,
            }, container)
            row:setStyleSheet("background: transparent;")
            rows[i] = row
            raiseWindow(name)
        end
        return rows
    end

    local statsA = statColumn("a", "100%-" .. (STATS_WIDTH * 2 + 5))
    local statsB = statColumn("b", "100%-" .. STATS_WIDTH)

    for _, name in ipairs({ "PkCore_topbar_brand_name", "PkCore_topbar_brand_sub", "PkCore_topbar_title_name", "PkCore_topbar_title_sub" }) do
        raiseWindow(name)
    end

    PkCore.ui.topbar.widgets = { titleName = titleName, titleSub = titleSub, statsA = statsA, statsB = statsB, brandSub = brandSub }
    return PkCore.ui.topbar.widgets
end

function PkCore.ui.topbar.render()
    local widgets = PkCore.ui.topbar.ensureWidgets()
    if not widgets then return end

    widgets.brandSub:echo(tostring(PkCore.player.class or "COMMANDS SKIN"):upper(), "#7d8b86")
    widgets.titleName:echo(tostring(PkCore.room.name or "Unknown Room"):upper(), "#e4eee6", "cb")

    local exits = table.concat(PkCore.room.sortedExits(), ", ")
    local sub = "[" .. tostring(PkCore.room.number or "?") .. "] "
    if exits ~= "" then sub = sub .. " - EXITS: " .. exits:upper() end
    widgets.titleSub:echo(sub, "#" .. t.idMuted)

    local p = PkCore.player
    widgets.statsA[1]:echo("Lvl: " .. tostring(p.level or "?"), "#" .. t.idMuted)
    widgets.statsA[2]:echo("Lessons: " .. tostring(p.lessons or "?"), "#" .. t.idMuted)
    widgets.statsA[3]:echo(string.format("Credits: %s / %s", tostring(p.boundCredits or "?"), tostring(p.unboundCredits or "?")), "#" .. t.idMuted)

    widgets.statsB[1]:echo(string.format("Msgs: %s | News: %s", tostring(p.unreadMsgs or "?"), tostring(p.unreadNews or "?")), "#" .. t.idMuted)
    widgets.statsB[2]:echo("Gold: " .. formatNumber(p.gold), "#" .. t.idMuted)
    widgets.statsB[3]:echo("Bank: " .. formatNumber(p.bank), "#" .. t.idMuted)
end

PkCore.registerSystem("ui.topbar", { cleanup = PkCore.ui.topbar.cleanup, rebuild = PkCore.ui.topbar.render })
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed", PkCore.protected("ui.topbar.render", PkCore.ui.topbar.render)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Status", PkCore.protected("ui.topbar.render", PkCore.ui.topbar.render)))