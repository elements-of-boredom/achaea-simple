PkCore.ui = PkCore.ui or {}
PkCore.ui.afflictions = PkCore.ui.afflictions or {}
local afflictions = PkCore.ui.afflictions

local ROWS = 10
local EMPTY_ROW = '<div class="mf-affliction-row" aria-hidden="true"></div>'

-- Shown elsewhere (prone/lock rows) or not worth a line; Mudlet's rail hid these too.
local LOCKS = {
  { "PARA", "paralysis" }, { "IMP", "impatience" }, { "AST", "asthma" },
  { "ANO", "anorexia" }, { "SLICK", "slickness" },
}

-- Kept out of the list: they have their own rows
local HIDDEN = { prone = true, blindness = true, deafness = true, insomnia = true }
for _, lock in ipairs(LOCKS) do HIDDEN[lock[2]] = true end

local SCRIPT = [[
<script>
(function () {
  var ROWS = ]] .. ROWS .. [[;
  function list(x) { return Array.isArray(x) ? x : Object.values(x || {}); }
  function row(entry) {
    var div = document.createElement("div");
    div.className = "mf-affliction-row";
    if (!entry) { div.setAttribute("aria-hidden", "true"); return div; }
    var name = document.createElement("span");
    name.textContent = entry.n;
    div.appendChild(name);
    if (entry.c) {
      var count = document.createElement("b");
      count.textContent = entry.c;
      div.appendChild(count);
    }
    return div;
  }
  (window.pkHandlers = window.pkHandlers || {}).afflictions = function (m) {
    var entries = list(m.entries);
    document.getElementById(m.side + "-aff-n").textContent = (entries.length < 10 ? "0" : "") + entries.length;
    var box = document.getElementById(m.side + "-aff-list");
    box.replaceChildren();
    entries.forEach(function (e) { box.appendChild(row(e)); });
    for (var i = entries.length; i < ROWS; i++) box.appendChild(row(null));
  };
})();
</script>
]]

-- The section's height comes from its rows (no fixed height in the CSS), so they're always present.
function afflictions.locks()
  local rows = {}
  for _, lock in ipairs(LOCKS) do
    local abbr, key = lock[1], lock[2]
    rows[#rows + 1] = '<div class="mf-lock" data-lock="' .. abbr .. '" data-active="false"'
      .. ' data-mud-bind-attr="data-active:lock_' .. key .. '">'
      .. "<span>" .. abbr .. '</span><i class="mf-lock-light" aria-hidden="true"></i>'
      .. '<b data-mud-bind="lockText_' .. key .. '">OFF</b></div>'
  end
  return '<section class="mf-locks" data-field="locks">'
    .. '<div class="mf-prone" data-field="prone" data-active="false" data-mud-bind-attr="data-active:proneActive">'
    ..   '<i></i><span>PRONE</span><b data-mud-bind="proneText">NO</b>'
    .. "</div>"
    .. '<div class="mf-lock-list">' .. table.concat(rows) .. "</div>"
    .. "</section>"
end

function afflictions.box(side, title)
  return '<section class="mf-afflictions" data-field="' .. side .. '-afflictions" data-side="' .. side .. '">'
    .. '<div class="mf-panel-heading"><h2>' .. title .. '</h2><span id="' .. side .. '-aff-n">00</span></div>'
    .. '<div class="mf-affliction-list" id="' .. side .. '-aff-list">' .. string.rep(EMPTY_ROW, ROWS) .. "</div>"
    .. "</section>"
end

function afflictions.script()
  return SCRIPT
end

local function selfEntries()
  local entries = {}
  for name, value in pairs(PkCore.afflictions.list) do
     if value and not HIDDEN[name] then
      entries[#entries + 1] = { n = name, c = type(value) == "number" and value or nil }
    end
  end
  table.sort(entries, function(a, b) return a.n < b.n end)
  return entries
end

local function targetEntries()
 local opponent = Opponent
  if not (opponent and opponent.display) then return {} end
  local entries = {}
  for _, entry in ipairs(opponent.display(PkCore.room.targetName())) do
    local c = entry.count
    if entry.p < opponent.Queries.SURE then c = math.floor(entry.p * 100 + 0.5) .. "%" end
    entries[#entries + 1] = { n = entry.aff, c = c }
  end
  return entries
end

local function renderLocks(id)
  local has = PkCore.afflictions.has
  local values = {
    proneActive = has("prone") and "true" or "false",
    proneText = has("prone") and "YES" or "NO",
  }
  for _, lock in ipairs(LOCKS) do
    local on = has(lock[2])
    values["lock_" .. lock[2]] = on and "true" or "false"
    values["lockText_" .. lock[2]] = on and "ON" or "OFF"
  end
  setBoundValues(id, values)
end

-- Skips each send when nothing changed: stateChanged() fires for every kind of state.
function afflictions.render(id, force)
  renderLocks(id)
  local self = json.encode({ kind = "afflictions", side = "self", entries = selfEntries() })
  if self ~= afflictions.lastSelf or force then
    afflictions.lastSelf = self
    sendWidgetMessage(id, self)
  end
  local target = json.encode({ kind = "afflictions", side = "target", entries = targetEntries() })
  if target ~= afflictions.lastTarget or force then
    afflictions.lastTarget = target
    sendWidgetMessage(id, target)
  end
end