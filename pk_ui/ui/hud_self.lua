PkCore.ui = PkCore.ui or {}
PkCore.ui.hudSelf = PkCore.ui.hudSelf or {}
local hud = PkCore.ui.hudSelf

local VITALS = { { "HP", "hp" }, { "MP", "mp" }, { "EP", "ep" }, { "WP", "wp" } }
local STATUS = { { "Mode", "hudMode" }, { "Strategy", "hudStrategy" }, { "Route", "hudRoute" } }
-- Percent sits on the numbers' row, pushed right (the theme puts it beside the label).
local CSS = [[
.mf-theme .mf-vital-track > b { justify-content: space-between; align-items: baseline; }
.mf-theme .mf-vital-track em { color: var(--mf-vital-color); font-size: 10px; font-style: normal; }
.mf-theme .mf-status-field strong:empty::before { content: "\2014"; color: var(--mf-text-muted); }
]]

-- Limbs and Mode/Strategy/Route are static until AK and the reactor are ported.
local function topbar()
  local fields = {} 
  for _, f in ipairs(STATUS) do
    fields[#fields + 1] = '<div class="mf-status-field"><span>' .. f[1] .. "</span>"
      .. '<strong data-mud-bind="' .. f[2] .. '">&#x2014;</strong></div>'
  end
  return '<div class="mf-self-topbar">'
    .. PkCore.ui.limbs.row("YOU", "self-limbs")
    .. '<section class="mf-combat-status" data-field="combat-configuration">' .. table.concat(fields) .. "</section>"
    .. "</div>"
end

local function lamp(kind, label, key)
  return '<div class="mf-readiness-indicator" data-kind="' .. kind .. '" data-ready="false"'
    .. ' data-mud-bind-attr="data-ready:' .. key .. '"><i></i><span>' .. label .. "</span></div>"
end

-- The fill's width is bound directly: it overrides the theme's var(--mf-progress) width.
local function vital(label, key)
  return '<div class="mf-vital" data-vital="' .. label .. '">'
    .. '<span class="mf-vital-label">' .. label .. "</span>"
    .. '<div class="mf-vital-track" style="--mf-progress:0%">'
    ..   '<i data-mud-bind-style="width:' .. key .. 'Bar"></i>'
    ..   '<b><span data-mud-bind="' .. key .. 'Text"></span><em data-mud-bind="' .. key .. 'Pct"></em></b>'
    .. "</div>"
    .. "</div>"
end

function hud.html()
  local vitals = {}
  for _, v in ipairs(VITALS) do vitals[#vitals + 1] = vital(v[1], v[2]) end
  return "<style>" .. CSS .. "</style>" .. '<div class="mf-self">' .. topbar()
    .. '<div class="mf-self-vitals">'
    ..   '<div class="mf-readiness-lights" aria-label="Your balance and equilibrium">'
    ..     lamp("balance", "BAL", "balReady") .. lamp("equilibrium", "EQ", "eqReady")
    ..   "</div>"
    ..   '<div class="mf-vitals" data-field="vitals">' .. table.concat(vitals) .. "</div>"
    .. "</div>"
    .. "</div>"
end

local function percent(current, max)
  if not current or not max or max <= 0 then return nil end
  return math.floor(math.min(100, math.max(0, current / max * 100)))
end

function hud.renderVitals()
  local id = PkCore.ui.layout.widgets.hudSelf
  if not id then return end
  local v, b = PkCore.vitals, PkCore.balance
  local values = {
    balReady = b.balance and "true" or "false",
    eqReady = b.equilibrium and "true" or "false",
  }
  for _, def in ipairs(VITALS) do
    local key = def[2]
    local current, max = v[key], v["max" .. key]
    local pct = percent(current, max)
    values[key .. "Bar"] = (pct or 0) .. "%"
    values[key .. "Text"] = pct and (current .. "/" .. max) or "?"
    values[key .. "Pct"] = pct and (pct .. "%") or ""
  end
  setBoundValues(id, values)
end

function hud.renderStatus()
  local id = PkCore.ui.layout.widgets.hudSelf
  if not id then return end
  local mode = PkCore.reactor and PkCore.reactor.mode or "off"
  setBoundValues(id, { hudMode = string.upper(mode) })
end

PkCore.onVitalsChanged("ui.hudSelf", hud.renderVitals)
PkCore.onStateChanged("ui.hudSelf", hud.renderStatus)
PkCore.ui.layout.setContent("hudSelf", hud.html, function()
  hud.renderVitals()
  hud.renderStatus()
end)