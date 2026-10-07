PkCore.ui.rail = PkCore.ui.rail or {}

local t = PkCore.ui.theme
local RAIL_BTN_CSS = "background-color: rgba(12,22,19,184); border: 1px solid #" .. t.border .. ";"
local RAIL_BTN_TEXT = "#e8eee2"
local CONSOLE_BG_CSS = "background: transparent; border: 1px solid #" .. t.border .. ";"

local BUTTON_ORDER = {"MTree", "Heart Tree", "Raia", "Narcisse", "Pear Tree", " ", "Adryn", "WorldReaver", "Aster",
                      "Aster Cows", "DivingBoard", "Dryad Garden", "IronMill"}

local BUTTONS = {
    ["MTree"] = {
        command = "path track 68906"
    },
    ["Heart Tree"] = {
        command = "path track 68501"
    },
    ["Raia"] = {
        command = "path track 50935"
    },
    ["Narcisse"] = {
        command = "path track 27584"
    },
    ["Pear Tree"] = {
        command = "path track 5086"
    },
    [" "] = {
        command = " "
    },
    ["Adryn"] = {
        command = "adryn",
        localAlias = true
    },
    ["WorldReaver"] = {
        command = "WorldReaver",
        localAlias = true
    },
    ["Aster Cows"] = {
        command = "ASTERCOWS",
        localAlias = true
    },
    ["Aster"] = {
        command = "ASTER",
        localAlias = true
    },
    ["DivingBoard"] = {
        command = "DivingBoard",
        localAlias = true
    },
    ["Dryad Garden"] = {
        command = "DryadGarden",
        localAlias = true
    },
    ["IronMill"] = {
        command = "IronMill",
        localAlias = true
    }
}

local STATUS_ROWS = {{
    key = "prone",
    label = "Prone"
}}
local LOCK_AFFLICTIONS = {{
    key = "paralysis",
    abbr = "PARA",
    label = "Paralysis"
}, {
    key = "impatience",
    abbr = "IMP",
    label = "Impatience"
}, {
    key = "asthma",
    abbr = "AST",
    label = "Asthma"
}, {
    key = "anorexia",
    abbr = "ANO",
    label = "Anorexia"
}, {
    key = "slickness",
    abbr = "SLIK",
    label = "Slickness"
}}
local KNOWN_AFFLICTIONS = {
    prone = true,
    blindness = true,
    deafness = true,
    insomnia = true
}
for _, def in ipairs(LOCK_AFFLICTIONS) do
    KNOWN_AFFLICTIONS[def.key] = true
end
local CONSOLE_GAP = 8
local CONSOLE_ROWS = 8
local _, LINE_HEIGHT = calcFontSize(9, "Consolas")
local CONSOLE_HEIGHT = (LINE_HEIGHT * CONSOLE_ROWS) + 8

local TARGET_CONSOLE_ROWS = 12
local TARGET_CONSOLE_HEIGHT = (LINE_HEIGHT * TARGET_CONSOLE_ROWS) + 8

local BUTTON_HEIGHT = 20
local GAP = 5
local PAD = 7

local PRONE_HEIGHT = 20
local LOCK_HEIGHT = 70
local LOCK_GAP = 4
local BLOCK_GAP = 6

local function statusStyle(hexfg, hexbg)
    return "background-color: " .. PkCore.ui.theme.rgba(hexbg, 90) .. "; border: 1px solid #" .. hexfg .. ";"
end

local function onRailClick(label)
    local def = BUTTONS[label]
    if not def then
        PkCore.note("No button by that label:" .. label)
        return
    end
    if def.localAlias then
        expandAlias(def.command)
    else
        send(def.command)
    end
end

local function spaceOut(s)
    local chars = {}
    for c in s:gmatch(".") do
        table.insert(chars, c)
    end
    return table.concat(chars, "<br>")
end

local function buildButtons()
    local buttons = {}
    local y = PAD
    for i, label in ipairs(BUTTON_ORDER) do
        local def = BUTTONS[label]
        local name = "PkCore_rail_" .. i
        local btn = Geyser.Label:new({
            name = name,
            x = PAD,
            y = y,
            width = "100%-" .. (PAD * 2),
            height = BUTTON_HEIGHT,
            font = "Consolas",
            fontSize = 9
        }, PkCore.ui.sections.left)
        btn:setStyleSheet(RAIL_BTN_CSS)
        btn:echo(label:upper(), RAIL_BTN_TEXT, "cb")
        btn:setClickCallback(onRailClick, label)
        raiseWindow(name)
        buttons[i] = btn
        y = y + BUTTON_HEIGHT + GAP
    end
    PkCore.ui.rail.buttons = buttons
    return y
end

local function buildTargetAfflictionConsole(totalBlockHeight)
    local targetConsoleY = "100%-" ..
                               (totalBlockHeight + CONSOLE_GAP + CONSOLE_HEIGHT + CONSOLE_GAP + TARGET_CONSOLE_HEIGHT +
                                   PAD)

    local targetConsoleBg = Geyser.Label:new({
        name = "PkCore_rail_target_afflictions_bg",
        x = PAD,
        y = targetConsoleY,
        width = "100%-" .. (PAD * 2),
        height = TARGET_CONSOLE_HEIGHT
    }, PkCore.ui.sections.left)
    targetConsoleBg:setStyleSheet(CONSOLE_BG_CSS)

    local targetConsole = Geyser.MiniConsole:new({
        name = "PkCore_rail_target_afflictions",
        x = PAD,
        y = targetConsoleY,
        width = "100%-" .. (PAD * 2),
        height = TARGET_CONSOLE_HEIGHT,
        font = "Consolas",
        fontSize = 9
    }, PkCore.ui.sections.left)
    setBackgroundColor("PkCore_rail_target_afflictions", 0, 0, 0, 0)
    setBgColor("PkCore_rail_target_afflictions", 0, 0, 0, 0)
    targetConsole:disableAutoWrap()
    raiseWindow("PkCore_rail_target_afflictions")
    PkCore.ui.rail.targetAfflictionsConsole = targetConsole
end

local function buildAfflictionConsole(totalBlockHeight)
    local consoleY = "100%-" .. (totalBlockHeight + CONSOLE_GAP + CONSOLE_HEIGHT + PAD)

    local consoleBg = Geyser.Label:new({
        name = "PkCore_rail_afflictions_bg",
        x = PAD,
        y = consoleY,
        width = "100%-" .. (PAD * 2),
        height = CONSOLE_HEIGHT
    }, PkCore.ui.sections.left)
    consoleBg:setStyleSheet(CONSOLE_BG_CSS)

    local console = Geyser.MiniConsole:new({
        name = "PkCore_rail_afflictions",
        x = PAD,
        y = consoleY,
        width = "100%-" .. (PAD * 2),
        height = CONSOLE_HEIGHT,
        font = "Consolas",
        fontSize = 9
    }, PkCore.ui.sections.left)
    setBackgroundColor("PkCore_rail_afflictions", 0, 0, 0, 0)
    setBgColor("PkCore_rail_afflictions", 0, 0, 0, 0)
    console:disableAutoWrap()
    PkCore.ui.rail.afflictionsConsole = console
end

local function buildAfflictionBars(y, totalBlockHeight)
    local proneY = "100%-" .. (totalBlockHeight + PAD)
    local lockY = "100%-" .. (LOCK_HEIGHT + PAD)

    local status = {}

    local proneName = "PkCore_rail_status_prone"
    local prone = Geyser.Label:new({
        name = proneName,
        x = PAD,
        y = proneY,
        width = "100%-" .. (PAD * 2),
        height = PRONE_HEIGHT,
        font = "Consolas",
        fontSize = 9
    }, PkCore.ui.sections.left)
    raiseWindow(proneName)
    status.prone = prone

    local containerWidth = PkCore.ui.sections.left:get_width()
    local count = #LOCK_AFFLICTIONS
    local totalGap = LOCK_GAP * (count - 1)
    local cellWidth = math.floor((containerWidth - (PAD * 2) - totalGap) / count)

    local cellX = PAD
    for _, def in ipairs(LOCK_AFFLICTIONS) do
        local name = "PkCore_rail_status_" .. def.key
        local cell = Geyser.Label:new({
            name = name,
            x = cellX,
            y = lockY,
            width = cellWidth,
            height = LOCK_HEIGHT,
            font = "Consolas",
            fontSize = 10
        }, PkCore.ui.sections.left)
        cell:setToolTip(def.label)
        raiseWindow(name)
        status[def.key] = cell
        cellX = cellX + cellWidth + LOCK_GAP
    end

    PkCore.ui.rail.status = status
    return y
end

function PkCore.ui.rail.cleanup()
    PkCore.ui.rail.buttons = nil
    PkCore.ui.rail.status = nil
    PkCore.ui.rail.afflictionsConsole = nil
    PkCore.ui.rail.targetAfflictionsConsole = nil
end

function PkCore.ui.rail.renderTargetAfflictions()
    local console = PkCore.ui.rail.targetAfflictionsConsole
    if not console then
        return
    end
    console:clear()

    if not PkCore.room.isTargetPlayer() then
        return
    end

    local names = PkCore.target.afflictions
    if #names == 0 then
        return
    end

    local shown = #names > TARGET_CONSOLE_ROWS and (TARGET_CONSOLE_ROWS - 1) or #names
    for i = 1, shown do
        console:hecho("|c" .. t.willpower .. names[i]:upper() .. "|r\n")
    end
    if #names > TARGET_CONSOLE_ROWS then
        console:hecho("|c" .. t.textMuted .. "(+" .. (#names - shown) .. " more)|r\n")
    end
end

function PkCore.ui.rail.render()
    local status = PkCore.ui.rail.status
    if not status then
        return
    end

    local proneActive = PkCore.afflictions.has("prone")
    if proneActive then
        status.prone:setStyleSheet(statusStyle(t.blood, t.blood2))
    else
        status.prone:setStyleSheet(statusStyle(t.hp, t.buttonBg))
    end
    status.prone:echo("PRONE", proneActive and ("#" .. t.blood) or ("#" .. t.hp), "cb")

    for _, def in ipairs(LOCK_AFFLICTIONS) do
        local active = PkCore.afflictions.has(def.key)
        if active then
            status[def.key]:setStyleSheet(statusStyle(t.blood, t.blood2))
        else
            status[def.key]:setStyleSheet(statusStyle(t.hp, t.buttonBg))
        end
        status[def.key]:echo(spaceOut(def.abbr), active and ("#" .. t.blood) or ("#" .. t.hp), "cb")
    end
    PkCore.ui.rail.renderAfflictions()
    PkCore.ui.rail.renderTargetAfflictions()
end

function PkCore.ui.rail.renderAfflictions()
    local console = PkCore.ui.rail.afflictionsConsole
    if not console then
        return
    end
    console:clear()

    local names = {}
    for name in pairs(PkCore.afflictions.list) do
        if not KNOWN_AFFLICTIONS[name] then
            table.insert(names, name)
        end
    end
    table.sort(names)
    if #names == 0 then
        return
    end

    local shown = #names > CONSOLE_ROWS and (CONSOLE_ROWS - 1) or #names
    for i = 1, shown do
        console:hecho("|c" .. t.willpower .. names[i]:upper() .. "|r\n")
    end
    if #names > CONSOLE_ROWS then
        console:hecho("|c" .. t.textMuted .. "(+" .. (#names - shown) .. " more)|r\n")
    end
end

function PkCore.ui.rail.build()
    if PkCore.ui.rail.buttons then
        return
    end
    if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.left) then
        return
    end

    local totalBlockHeight = PRONE_HEIGHT + BLOCK_GAP + LOCK_HEIGHT

    local y = buildButtons()
    -- Affliction console - them --
    buildTargetAfflictionConsole(totalBlockHeight)
    -- Affliction console - me --
    buildAfflictionConsole(totalBlockHeight)
    -- affliction status --
    y = buildAfflictionBars(y, totalBlockHeight)

    PkCore.ui.rail.render()
    PkCore.ui.rail.renderAfflictions()
end

PkCore.registerSystem("ui.rail", {
    cleanup = PkCore.ui.rail.cleanup,
    rebuild = PkCore.ui.rail.build
})
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed",
    PkCore.protected("ui.rail.render", PkCore.ui.rail.render)))
