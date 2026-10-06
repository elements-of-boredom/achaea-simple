PkCore.ui.map = PkCore.ui.map or {}

local t = PkCore.ui.theme
local MAP_TAB_INACTIVE_CSS = "background-color: #" .. t.tabBg .. "; border: 1px solid rgba(82,98,106,140); padding: 0 11px;"
local MAP_TAB_ACTIVE_CSS   = "background-color: #" .. t.tabBg .. "; border: 1px solid #" .. t.tabAccent .. "; padding: 0 11px;"
local MAP_TABS = { "Mudlet", "ASCII", "Ripple" }

local function selectMapTab(key)
  if not PkCore.ui.map.tabs then return end
  for _, tab in ipairs(PkCore.ui.map.tabs) do
    local active = tab.key == key
    tab.widget:setStyleSheet(active and MAP_TAB_ACTIVE_CSS or MAP_TAB_INACTIVE_CSS)
    tab.widget:echo(tab.key:upper(), active and ("#" .. t.tabTextActive) or ("#" .. t.tabText))
  end
  if not PkCore.ui.map.views then return end
  for viewKey, view in pairs(PkCore.ui.map.views) do
    if viewKey == key then view:show() else view:hide() end
  end
end

function PkCore.ui.map.cleanup()
  PkCore.ui.map.widget = nil
  PkCore.ui.map.tabs = nil
  PkCore.ui.map.views = nil
end

function PkCore.ui.map.ensure()
if PkCore.ui.map.widget then return end
  if not (PkCore.ui.sections and PkCore.ui.sections.map) then return end
  if not next(getRooms()) then return end

  local headerHeight = PkCore.ui.header.create(PkCore.ui.sections.map, "PkCore_map", "Map")
  
  local tabFont, tabFontSize = "Ubuntu", 9
  local charW = calcFontSize(tabFontSize, tabFont)
  local tabHeight, paddingV, paddingH, gap, tabPadX = 26, 7, 8, 5, 11
  local tabsRowHeight = paddingV + tabHeight + paddingV
  local belowTabs = headerHeight + tabsRowHeight + 2

  -- Temp until we get the other maps embedded
    local function placeholder(key, text)
        local label = Geyser.Label:new({
            name = "PkCore_map_view_" .. key:lower(),
            x = "1%", y = belowTabs, width = "98%", height = "100%-" .. (belowTabs + 2),
            font = "Georgia", fontSize = 11, format = "c",
        }, PkCore.ui.sections.map)
        label:setStyleSheet("background-color: transparent;")
        label:echo(text, "#" .. t.textMuted)
        label:hide()
        return label
    end

  local tabsRowBg = Geyser.Label:new({
    name = "PkCore_map_tabsrow_bg",
    x = "0%", y = headerHeight, width = "100%", height = tabsRowHeight,
  }, PkCore.ui.sections.map)
  tabsRowBg:setStyleSheet("background-color: rgba(1,4,5,70); border-bottom: 1px solid rgba(82,98,106,90);")

  PkCore.ui.map.tabs = {}
  local tabX = paddingH
  for _, key in ipairs(MAP_TABS) do
    local tabWidth = (tabPadX * 2) + (charW * (#key + 5))
    local name = "PkCore_map_tab_" .. key:lower()
    local label = Geyser.Label:new({
      name = name,
      x = tabX, y = headerHeight + paddingV, width = tabWidth, height = tabHeight,
      font = tabFont, fontSize = tabFontSize, format = "c",
    }, PkCore.ui.sections.map)
    label:setClickCallback(selectMapTab, key)
    raiseWindow(name)
    table.insert(PkCore.ui.map.tabs, { key = key, widget = label })
    tabX = tabX + tabWidth + gap
  end

    PkCore.ui.map.widget = Geyser.Mapper:new({
        name = "PkCore_ui_map",
        x = "1%", y = belowTabs, width = "98%", height = "100%-" .. (belowTabs + 2),
    }, PkCore.ui.sections.map)
    raiseWindow("PkCore_ui_map")

    PkCore.ui.map.views = {
        Mudlet = PkCore.ui.map.widget,
        ASCII  = placeholder("ASCII", "ASCII view — coming soon"),
        Ripple = placeholder("Ripple", "Ripple view — coming soon"),
    }
    selectMapTab("Mudlet")
end

PkCore.registerSystem("ui.map", { cleanup = PkCore.ui.map.cleanup, rebuild = PkCore.ui.map.ensure })
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Room.Info", PkCore.protected("ui.map.ensure", PkCore.ui.map.ensure)))