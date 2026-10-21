-- Layout: the mock's page grid rebuilt as positioned MudForge widgets around the native terminal.
--
--   header ........................ | map
--   sidebar | terminal (native)     | room
--           | hud self | hud target | chat
--
-- Panels are empty scaffolding for now; content modules fill them later.

PkCore.ui = PkCore.ui or {}
PkCore.ui.layout = PkCore.ui.layout or {}
PkCore.ui.layout.widgets = PkCore.ui.layout.widgets or {}
PkCore.ui.layout.content = PkCore.ui.layout.content or {}

-- Sizes from the mock's tokens (design/theme.css section 1). getWindowSize() includes
-- MudForge's own top and bottom bars, so insetTop/insetBottom keep panels clear of them.
local G = {
  padX = 12, padTop = 0, padBottom = 10, gap = 10,   -- header and dock sit flush under the app bar
  sidebar = 180, dock = 448, header = 80, hud = 116,
  hudSelfShare = 0.7,                                  -- mf-hud: 7fr / 3fr
  mapShare = 0.3, roomShare = 0.3,                     -- dock: 30 / 30 / 40 after gaps
  insetTop = 0, insetBottom = 95,
}
PkCore.ui.layout.geometry = G

-- Content registration
function PkCore.ui.layout.setContent(key, htmlFn)
  PkCore.ui.layout.content[key] = htmlFn
end

local function heading(title)
  return '<div class="mf-panel-heading"><h2>' .. title .. "</h2></div>"
end

local function scaffold(label)
  -- pkRect shows the rect apply() asked for, to compare against where the widget really lands.
  return '<div class="pk-scaffold">' .. label .. ' <span data-mud-bind="pkRect"></span></div>'
end

-- Prone + lock rows, all off. The section's height comes from its rows (no fixed height in the CSS),
-- so it needs them even while empty. The names are fixed labels, not data.
local LOCKS = { "PARA", "IMP", "AST", "ANO", "SLICK" }

local function locks()
  local rows = {}
  for _, name in ipairs(LOCKS) do
    rows[#rows + 1] = '<div class="mf-lock" data-lock="' .. name .. '" data-active="false" role="img" aria-label="'
      .. name .. ': off"><span>' .. name .. '</span><i class="mf-lock-light" aria-hidden="true"></i><b>OFF</b></div>'
  end
  return '<section class="mf-locks" data-field="locks">'
    .. '<div class="mf-prone" data-field="prone" data-active="false"><i></i><span>PRONE</span><b>NO</b></div>'
    .. '<div class="mf-lock-list">' .. table.concat(rows) .. "</div>"
    .. "</section>"
end

-- Recovery meters, all ready (100%). Primary is full width; secondary is two columns, and
-- the CSS stretches the last one across both, so an odd count looks intentional.
local RECOVERY_PRIMARY = { { "balance", "Balance" }, { "equilibrium", "Equilibrium" } }
local RECOVERY_SECONDARY = {
  { "tree", "Tree" }, { "focus", "Focus" }, { "elixir", "Elixir" }, { "moss", "Moss" },
  { "herb", "Herb" }, { "pipe", "Pipe" }, { "salve", "Salve" },
}

local function cooldowns(list)
  local out = {}
  for _, c in ipairs(list) do
    local kind, label = c[1], c[2]
    out[#out + 1] = '<div class="mf-cooldown" data-kind="' .. kind .. '" data-state="ready" role="progressbar"'
      .. ' aria-label="' .. label .. ' recovery" aria-valuemin="0" aria-valuemax="100" aria-valuenow="100" aria-valuetext="Ready">'
      .. '<i class="mf-cooldown-fill" aria-hidden="true"></i><span>' .. label .. '</span><b class="mf-cooldown-value">Ready</b></div>'
  end
  return table.concat(out)
end

local function recovery()
  return '<section class="mf-recovery" data-field="recovery">' .. heading("Recovery")
    .. '<div class="mf-recovery-primary">' .. cooldowns(RECOVERY_PRIMARY) .. "</div>"
    .. '<div class="mf-recovery-secondary">' .. cooldowns(RECOVERY_SECONDARY) .. "</div>"
    .. "</section>"
end

-- Region skeletons: the mock's outer markup with the content left out.
local PANELS = {
   { key = "header", title = "Header",
    html = '<header class="mf-header">' .. scaffold("HEADER") .. "</header>" },
  { key = "sidebar", title = "Sidebar",
    html = '<aside class="mf-sidebar">'
      .. '<div class="mf-controls">'
      ..   '<section class="mf-waypoints-panel">' .. heading("Waypoints") .. scaffold("WAYPOINTS") .. "</section>"
      ..   recovery()
      .. "</div>"
      .. '<div class="mf-trackers">'
      ..   '<div class="mf-affliction-pair">'
      ..     '<section class="mf-afflictions" data-side="self">' .. heading("Your afflictions") .. "</section>"
      ..     '<section class="mf-afflictions" data-side="target">' .. heading("Target afflictions") .. "</section>"
      ..   "</div>"
      ..   locks()
      .. "</div>"
      .. "</aside>" },
  { key = "hudSelf", title = "You",
    html = '<div class="mf-self">' .. scaffold("SELF: LIMBS / MODE / VITALS") .. "</div>" },
  { key = "hudTarget", title = "Target",
    html = '<div class="mf-target-panel">' .. scaffold("TARGET: LIMBS / HEALTH") .. "</div>" },
  { key = "map", title = "Map",
    html = '<section class="mf-map">'
      .. '<div class="mf-map-modes">'
      ..   '<button aria-pressed="true">MUDLET</button><button aria-pressed="false">ASCII</button>'
      ..   '<button aria-pressed="false">RIPPLE</button>'
      .. "</div>"
      .. '<div class="mf-map-slot">' .. scaffold("MAP") .. "</div>"
      .. "</section>" },
  { key = "room", title = "Room",
    html = '<section class="mf-room">' .. heading("Room information") .. scaffold("ITEMS / EXITS / PLAYERS / MOBS") .. "</section>" },
  { key = "chat", title = "Chat",
    html = '<section class="mf-chat">' .. heading("Chat")
      .. '<div class="mf-chat-filters">'
      ..   '<button aria-pressed="true">All</button><button aria-pressed="false">Tells</button>'
      ..   '<button aria-pressed="false">Channels</button>'
      .. "</div>"
      .. scaffold("CHAT LOG")
      .. "</section>" },
}

local function rect(x, y, w, h)
  return { x = math.floor(x), y = math.floor(y), w = math.floor(w), h = math.floor(h) }
end

function PkCore.ui.layout.compute(width, height)
  local left, right = G.padX, width - G.padX
  local top, bottom = G.insetTop + G.padTop, height - G.insetBottom - G.padBottom

  local dockX = right - G.dock
  local mainRight = dockX - G.gap
  local bodyY = top + G.header + G.gap
  local mainX = left + G.sidebar + G.gap
  local mainW = mainRight - mainX
  local hudY = bottom - G.hud
  local selfW = math.floor((mainW - G.gap) * G.hudSelfShare)

  local dockH = bottom - top - 2 * G.gap
  local mapH = dockH * G.mapShare
  local roomH = dockH * G.roomShare
  local chatH = dockH - mapH - roomH

  return {
    header    = rect(left, top, mainRight - left, G.header),
    sidebar   = rect(left, bodyY, G.sidebar, bottom - bodyY),
    terminal  = rect(mainX, bodyY, mainW, hudY - G.gap - bodyY),
    hudSelf   = rect(mainX, hudY, selfW, G.hud),
    hudTarget = rect(mainX + selfW + G.gap, hudY, mainW - selfW - G.gap, G.hud),
    map       = rect(dockX, top, G.dock, mapH),
    room      = rect(dockX, top + mapH + G.gap, G.dock, roomH),
    chat      = rect(dockX, top + mapH + roomH + 2 * G.gap, G.dock, chatH),
  }
end

-- Moves every widget, ours and the native terminal, to the computed layout.
-- A widget the player docked ignores move/resize; that is MudForge's rule, not a bug here.
function PkCore.ui.layout.apply(width, height)
  local rects = PkCore.ui.layout.compute(width, height)
  for key, id in pairs(PkCore.ui.layout.widgets) do
    local r = rects[key]
    moveWidget(id, r.x, r.y)
    resizeWidget(id, r.w, r.h)
    setBoundValue(id, "pkRect", "@" .. r.x .. "," .. r.y .. " " .. r.w .. "x" .. r.h)
  end
  local t = rects.terminal
  moveWidget("terminal", t.x, t.y)
  resizeWidget("terminal", t.w, t.h)
end

-- Widget frame for every panel: no chrome, locked in place, square corners.
local CHROME = {
  showTitleBar = false, autoHideSettingsCog = true,
  movable = false, resizable = false,
  borderRadius = 0,
}

-- Safe to call repeatedly: createWidget returns the existing widget for a name it already made.
function PkCore.ui.layout.build()
  local size = getWindowSize()
  local rects = PkCore.ui.layout.compute(size.width, size.height)
  for _, panel in ipairs(PANELS) do
    local r = rects[panel.key]
    local id = createWidget({
      type        = "html",
      name        = "pk-" .. panel.key,
      title       = panel.title,
      transparent = true,
      position    = { x = r.x, y = r.y },
      size        = { width = r.w, height = r.h },
      appearance  = CHROME,
    })
    PkCore.ui.layout.widgets[panel.key] = id
    -- createWidget's appearance is only a default for a new widget; this also updates one that already exists.
    setWidgetAppearance(id, CHROME)

    local contentFn = PkCore.ui.layout.content[panel.key]
    local html = contentFn and contentFn() or panel.html
    setWidgetProperty(id, "content", PkCore.ui.theme.page(html))
  end

  -- Mock: terminal backing is black at 15% opacity. Unverified that the terminal accepts this.
  setWidgetAppearance("terminal", { backgroundColor = "#000000", backgroundOpacity = 0.15, borderRadius = 0 })

  -- A saved layout overrides createWidget's position on later loads, so place everything explicitly.
  PkCore.ui.layout.apply(size.width, size.height)
end

-- Debounced by MudForge: fires once, ~150ms after the window stops resizing.
on("windowResize", function(event)
  PkCore.ui.layout.apply(event.width, event.height)
end)
