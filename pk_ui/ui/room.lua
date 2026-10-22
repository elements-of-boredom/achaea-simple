PkCore.ui = PkCore.ui or {}
PkCore.ui.room = PkCore.ui.room or {}
local panel = PkCore.ui.room

local CSS = [[
#room-exits { display: contents; }   /* buttons join .mf-room-exits' flex row and gap */
.mf-room-list button[data-target="true"] span { color: var(--mf-affliction); }
]]

-- Rebuilds the lists from the JSON model Lua sends. Names go in via textContent, never HTML.
-- Clicks go back to Lua: an exit moves, a mob becomes the target.
local SCRIPT = [[
<script>
(function () {
  var ARROWS = { n: "↑", ne: "↗", e: "→", se: "↘", s: "↓", sw: "↙", w: "←", nw: "↖", u: "⇡", d: "⇣" };
  function list(x) { return Array.isArray(x) ? x : Object.values(x || {}); }
  function $(id) { return document.getElementById(id); }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function row(name, tag) {
    var b = el("button");
    b.appendChild(el("span", null, name));
    b.appendChild(el("code", null, tag));
    return b;
  }
  function fill(box, nodes) {
    box.replaceChildren();
    if (!nodes.length) { box.appendChild(el("span", "mf-empty", "—")); return; }
    nodes.forEach(function (n) { box.appendChild(n); });
  }

  mudforge.onMessage(function (payload) {
    try{
      var m = JSON.parse(payload);
      var items = list(m.items), exits = list(m.exits), players = list(m.players), mobs = list(m.mobs);

      $("room-num").textContent = m.num;
      $("room-items-n").textContent = items.length;
      $("room-players-n").textContent = players.length;
      $("room-mobs-n").textContent = mobs.length;

      fill($("room-items"), items.map(function (it) {
        return row(it.name, it.count > 1 ? "x" + it.count : "@" + it.id);
      }));

      fill($("room-exits"), exits.map(function (d) {
        var b = el("button", null, ARROWS[d] ? d + " " + ARROWS[d] : d);
        b.onclick = function () { mudforge.send("move", { dir: d }); };
        return b;
      }));

      var p = $("room-players");
      p.replaceChildren();
      if (!players.length) p.appendChild(el("span", "mf-empty", "—"));
      players.forEach(function (name, i) {
        if (i > 0) p.appendChild(document.createTextNode(", "));
        p.appendChild(el("button", null, name));
      });

      fill($("room-mobs"), mobs.map(function (mob) {
        var b = row(mob.target ? "> " + mob.name : mob.name, "@" + mob.id);
        if (mob.target) b.setAttribute("data-target", "true");
        b.onclick = function () { mudforge.send("target", { id: mob.id }); };
        return b;
      }));
    } catch(e) {mudforge.send("err", { msg: String(e) }); }
  });
  mudforge.send("ready", {});
})();
</script>
]]

function panel.html()
  return "<style>" .. CSS .. "</style>"
    .. '<section class="mf-room" data-field="room-information">'
    .. '<div class="mf-panel-heading"><h2>Room information</h2><span id="room-num"></span></div>'
    .. '<div class="mf-room-columns">'
    ..   '<div class="mf-room-items">'
    ..     '<h3>Items <b id="room-items-n">0</b></h3>'
    ..     '<div class="mf-room-list" id="room-items"></div>'
    ..   "</div>"
    ..   '<div class="mf-room-occupants">'
    ..     '<div class="mf-room-exits"><h3>Exits</h3><span id="room-exits"></span></div>'
    ..     '<div class="mf-room-group">'
    ..       '<h3>Players <b id="room-players-n">0</b></h3>'
    ..       '<div class="mf-room-list mf-player-list" id="room-players"></div>'
    ..     "</div>"
    ..     '<div class="mf-room-group">'
    ..       '<h3>Mobs <b id="room-mobs-n">0</b></h3>'
    ..       '<div class="mf-room-list" id="room-mobs"></div>'
    ..     "</div>"
    ..   "</div>"
    .. "</div>"
    .. "</section>"
    .. SCRIPT
end

local function model()
  local r = PkCore.room
  local mobs = {}
  for _, entry in ipairs(r.mobEntries()) do
    local id = tostring(entry.id)
    mobs[#mobs + 1] = { name = entry.name, id = id, target = r.targetId == id }
  end
  return {
    num = r.number and tostring(r.number) or "",
    items = r.itemEntries(),
    exits = r.sortedExits(),
    players = r.playerNames(),
    mobs = mobs,
  }
end

-- Skips the send when nothing changed: stateChanged() fires for every kind of state.
function panel.render(force)
  local id = PkCore.ui.layout.widgets.room
  if not id then return end
  local payload = json.encode(model())
  if payload == panel.lastPayload and not force then return end
  panel.lastPayload = payload
  sendWidgetMessage(id, payload)
end

-- Runs after every build. Unregister first: init() runs several times per save.
function panel.attach(id)
  unregisterWidgetEvent(id, "luamsg")
  registerWidgetEvent(id, "luamsg", function(m)
    if m.event == "ready" then
      panel.render(true)                          -- fresh document: always send
    elseif m.event == "move" then
      send(m.data.dir)
    elseif m.event == "target" then
      send("st " .. m.data.id)
    elseif m.event == "err" then 
      echo("[room] js: " .. m.data.msg, "#ff6b6b")
    end
  end)
end

PkCore.onStateChanged("ui.room", panel.render)
PkCore.ui.layout.setContent("room", panel.html, panel.attach)