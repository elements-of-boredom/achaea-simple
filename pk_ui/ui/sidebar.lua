PkCore.ui = PkCore.ui or {}
PkCore.ui.sidebar = PkCore.ui.sidebar or {}
local sidebar = PkCore.ui.sidebar

-- Locations walk there with the mapper; tasks start a PkCore task (task = its name in tasks/).
local WAYPOINTS = {
  { label = "Mtree",        room = 68906 },
  { label = "Heart tree",   room = 68501 },
  { label = "Raia",         room = 50935 },
  { label = "Narcisse",     room = 27584 },
  { label = "Pear tree",    room = 5086 },
  { label = "Adryn",        task = "ADRYN" },
  { label = "Worldreaver",  task = "WorldReaver" },
  { label = "Aster",        task = "ASTER" },
  { label = "Aster cows",   task = "ASTERCOWS" },
  { label = "Divingboard",  task = "DivingBoard" },
  { label = "Dryad garden", task = "DryadGarden" },
  { label = "Ironmill",     task = "IRONMILL" },
}

local ICON_ROOM, ICON_TASK = "&#x2301;", "&#x2316;"

local function heading(title, count)
  return '<div class="mf-panel-heading"><h2>' .. title .. "</h2>"
    .. (count and ("<span>" .. count .. "</span>") or "") .. "</div>"
end

local function waypoints()
  local buttons = {}
  for i, wp in ipairs(WAYPOINTS) do
    buttons[#buttons + 1] = '<button data-mud-action="waypoint" data-mud-data="' .. i .. '"'
      .. ' data-mud-bind-attr="aria-current:wp' .. i .. '">'
      .. "<i>" .. (wp.task and ICON_TASK or ICON_ROOM) .. "</i><span>" .. wp.label .. "</span></button>"
  end
  return '<section class="mf-waypoints-panel" data-field="waypoints">' .. heading("Waypoints", #WAYPOINTS)
    .. '<nav class="mf-waypoints" aria-label="Waypoints">' .. table.concat(buttons) .. "</nav>"
    .. "</section>"
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

function sidebar.html()
  return '<aside class="mf-sidebar">'
    .. '<div class="mf-controls">' .. waypoints() .. recovery() .. "</div>"
    .. '<div class="mf-trackers">'
    ..   '<div class="mf-affliction-pair">'
    ..     '<section class="mf-afflictions" data-side="self">' .. heading("Your afflictions") .. "</section>"
    ..     '<section class="mf-afflictions" data-side="target">' .. heading("Target afflictions") .. "</section>"
    ..   "</div>"
    ..   locks()
    .. "</div>"
    .. "</aside>"
end

-- Current = the task that's running, or the location you're standing in.
local function isCurrent(wp)
  if wp.task then
    local task = PkCore.task
    return task ~= nil and task.active and task.name == wp.task
  end
  return tostring(PkCore.room.number or "") == tostring(wp.room)
end

function sidebar.render()
  local id = PkCore.ui.layout.widgets.sidebar
  if not id then return end
  local values = {}
  for i, wp in ipairs(WAYPOINTS) do
    values["wp" .. i] = isCurrent(wp) and "true" or "false"
  end
  setBoundValues(id, values)
end

local function go(index)
  local wp = WAYPOINTS[tonumber(index)]
  if not wp then return end
  if wp.task then
    PkCore.tasks.start(wp.task)
  else
    send("path track " .. wp.room)
  end
end

-- Runs after every build. Unregister first: init() runs several times per save.
function sidebar.attach(id)
  unregisterWidgetEvent(id, "action")
  registerWidgetEvent(id, "action", function(e)
    if e.action == "waypoint" then go(e.data) end
  end)
  sidebar.render()
end

PkCore.onStateChanged("ui.sidebar", sidebar.render)
PkCore.ui.layout.setContent("sidebar", sidebar.html, sidebar.attach)