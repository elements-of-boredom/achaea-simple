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

-- One onMessage per widget, so sections register handlers by kind and this routes to them.
local DISPATCH = [[
<script>
(function () {
  var handlers = window.pkHandlers = window.pkHandlers || {};
  mudforge.onMessage(function (payload) {
    var m = JSON.parse(payload);
    if (handlers[m.kind]) handlers[m.kind](m);
  });
  mudforge.send("ready", {});
})();
</script>
]]

function sidebar.html()
  return '<aside class="mf-sidebar">'
    .. '<div class="mf-controls">' .. waypoints() .. PkCore.ui.recovery.html() .. "</div>"
    .. '<div class="mf-trackers">'
    ..   '<div class="mf-affliction-pair">'
    ..     PkCore.ui.afflictions.box("self", "Your afflictions")
    ..     PkCore.ui.afflictions.box("target", "Target afflictions")
    ..   "</div>"
    ..   PkCore.ui.afflictions.locks()
    .. "</div>"
    .. "</aside>" .. PkCore.ui.afflictions.script() .. DISPATCH
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
  PkCore.ui.afflictions.render(id)
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
  unregisterWidgetEvent(id, "luamsg")
  registerWidgetEvent(id, "action", function(e)
    if e.action == "waypoint" then go(e.data) end
  end)
  registerWidgetEvent(id, "luamsg", function(m)
    if m.event == "ready" then PkCore.ui.afflictions.render(id, true) end   -- fresh document: always send
  end)
  sidebar.render()
end

PkCore.onStateChanged("ui.sidebar", sidebar.render)
PkCore.ui.layout.setContent("sidebar", sidebar.html, sidebar.attach)