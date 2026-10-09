PkCore.ui.chat = PkCore.ui.chat or {}
PkCore.ui.chat.unread = PkCore.ui.chat.unread or {}
PkCore.ui.chat.activeTab = PkCore.ui.chat.activeTab or "all"

local TABS = {
  { key = "all", label = "All", width = "50px" },
  { key = "tells", label = "Tells", width = "60px" },
  { key = "channels", label = "Channels", width = "70px" },
}
local t = PkCore.ui.theme
local TAB_INACTIVE_CSS = "background-color: #" .. t.tabBg .. "; border: 1px solid rgba(82,98,106,140); padding: 0 11px;"
local TAB_ACTIVE_CSS   = "background-color: #" .. t.tabBg .. "; border: 1px solid #" .. t.tabAccent .. "; padding: 0 11px;"

local function selectTab(key)
  if not PkCore.ui.chat.consoles or not PkCore.ui.chat.consoles[key] then return end
  PkCore.ui.chat.activeTab = key
  PkCore.ui.chat.unread[key] = 0
  for _, tab in ipairs(TABS) do
    local console = PkCore.ui.chat.consoles[tab.key]
    if tab.key == key then console:show() else console:hide() end
  end
  PkCore.ui.chat.refreshTabs()
end
PkCore.ui.chat.selectTab = selectTab

local function noteActivity(key)
  if key == PkCore.ui.chat.activeTab then return end
  PkCore.ui.chat.unread[key] = (PkCore.ui.chat.unread[key] or 0) + 1
  PkCore.ui.chat.refreshTabs()
end

function PkCore.ui.chat.refreshTabs()
  if not PkCore.ui.chat.tabLabels then return end
  local t = PkCore.ui.theme
  for _, tab in ipairs(TABS) do
    local label = PkCore.ui.chat.tabLabels[tab.key]
    local active = PkCore.ui.chat.activeTab == tab.key
    local unread = PkCore.ui.chat.unread[tab.key] or 0
    local text = tab.label
    if unread > 0 and not active then
      text = string.format("%s (%d)", tab.label, unread)
    end
    label:setStyleSheet(active and TAB_ACTIVE_CSS or TAB_INACTIVE_CSS)
    label:echo(text, active and ("#" .. t.tabTextActive) or ("#" .. t.tabText))
  end
end

function PkCore.ui.chat.cleanup()
  PkCore.ui.chat.consoles = nil
  PkCore.ui.chat.tabLabels = nil
  PkCore.ui.chat.tabBar = nil
end

function PkCore.ui.chat.ensureWidgets()
  if PkCore.ui.chat.consoles then return PkCore.ui.chat.consoles end
  if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.chat) then return nil end

  local headerHeight = PkCore.ui.header.create(PkCore.ui.sections.chat, "PkCore_chat", "Chat")

  PkCore.ui.chat.tabLabels = {}
  PkCore.ui.chat.consoles = {}

  local tabFont, tabFontSize = "Ubuntu", 9
  local charW = calcFontSize(tabFontSize, tabFont)
  local tabHeight = 26
  local paddingH = 8
  local paddingV = 7
  local gap = 5
  local tabPadX = 11  -- matches the mock's .tab{padding:0 11px}

  local tabsRowHeight = paddingV + tabHeight + paddingV
  local belowTabs = headerHeight + tabsRowHeight + 2

  local tabsRowBg = Geyser.Label:new({
    name = "PkCore_chat_tabsrow_bg",
    x = "0%", y = headerHeight, width = "100%", height = tabsRowHeight,
  }, PkCore.ui.sections.chat)
  tabsRowBg:setStyleSheet("background-color: rgba(1,4,5,70); border-bottom: 1px solid rgba(82,98,106,90);")

  local tabX = paddingH
  for _, tab in ipairs(TABS) do
    local tabWidth = (tabPadX * 2) + (charW * (#tab.label + 5))
    local label = Geyser.Label:new({
      name = "PkCore_chat_tab_" .. tab.key,
      x = tabX, y = headerHeight + paddingV, width = tabWidth, height = tabHeight,
      font = tabFont, fontSize = tabFontSize, format = "c",
    }, PkCore.ui.sections.chat)
    label:setClickCallback(selectTab, tab.key)
    PkCore.ui.chat.tabLabels[tab.key] = label
    raiseWindow("PkCore_chat_tab_" .. tab.key)
    tabX = tabX + tabWidth + gap

    local console = Geyser.MiniConsole:new({
      name = "PkCore_chat_" .. tab.key,
      x = "1%", y = belowTabs, width = "99%", height = "100%-" .. belowTabs,
      autoWrap = true, font = "SF Mono",
      fontSize = 10,
    }, PkCore.ui.sections.chat)
    setBgColor("PkCore_chat_" .. tab.key, 0, 0, 0, 0)
    setBackgroundColor("PkCore_chat_" .. tab.key, 4, 7, 9, 0)
    PkCore.ui.chat.consoles[tab.key] = console
    if tab.key ~= "all" then console:hide() end
  end

  selectTab(PkCore.ui.chat.activeTab)
  return PkCore.ui.chat.consoles
end

local function onChannelText()
  local message = gmcp and gmcp.Comm and gmcp.Comm.Channel and gmcp.Comm.Channel.Text
  if type(message) ~= "table" or type(message.text) ~= "string" then return end
  local consoles = PkCore.ui.chat.ensureWidgets()
  if not consoles then return end

  local text = ansi2decho(message.text) .. "\n"
  consoles.all:decho(text)
  noteActivity("all")

  local channel = type(message.channel) == "string" and message.channel:lower() or ""
  local family = channel:find("tell", 1, true) and "tells" or "channels"
  consoles[family]:decho(text)
  noteActivity(family)
end

local function enableChannelCapture()
  if type(gmod) == "table" and gmod.enableModule then
    gmod.enableModule("PkCore", "Comm.Channel")
  end
end

PkCore.registerSystem("ui.chat",   { cleanup = PkCore.ui.chat.cleanup,   rebuild = PkCore.ui.chat.ensureWidgets })
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Comm.Channel.Text", PkCore.protected("ui.chat.onChannelText", onChannelText)))
PkCore.trackHandler(registerAnonymousEventHandler("sysConnectionEvent", PkCore.protected("ui.chat.enableChannelCapture", enableChannelCapture)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Core.Hello", PkCore.protected("ui.chat.enableChannelCapture", enableChannelCapture)))
enableChannelCapture()