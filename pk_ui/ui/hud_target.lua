PkCore.ui = PkCore.ui or {}
PkCore.ui.hudTarget = PkCore.ui.hudTarget or {}
local hud = PkCore.ui.hudTarget

local CSS = [[
.mf-theme .mf-target-data > div:first-child { align-items: baseline; }
.mf-theme .mf-target-data strong { grid-area: 1 / 1 / 2 / 2; font-size: 12px; }
.mf-theme .mf-target-data small { font-size: 12px; }
.mf-theme .mf-target-data strong:empty::before { content: "\2014"; color: var(--mf-text-muted); }
.mf-theme .mf-target-track i { background: var(--mf-affliction); }
.mf-theme .mf-target { align-items: flex-end; }
.mf-theme .mf-target-symbol { align-self: center; }
]]

function hud.html()
  return "<style>" .. CSS .. "</style>" ..'<div class="mf-target-panel">'
    .. PkCore.ui.limbs.row("TARGET", "target-limbs")
    .. '<div class="mf-target" data-field="target">'
    ..   '<span class="mf-target-symbol">&#x2316;</span>'
    ..   '<div class="mf-target-data">'
    ..     '<div><strong data-mud-bind="tgtName">&#x2014;</strong><small data-mud-bind="tgtPct"></small></div>'
    ..     '<div class="mf-target-track"><i data-mud-bind-style="width:tgtBar"></i></div>'
    ..   "</div>"
    .. "</div>"
    .. "</div>"
end

function hud.render()
  local id = PkCore.ui.layout.widgets.hudTarget
  if not id then return end
  local r = PkCore.room
  local pct = r.targetHpPercent
  setBoundValues(id, {
    tgtName = r.targetName() or "",
    tgtPct = pct and (pct .. "%") or "",
    tgtBar = (pct or 0) .. "%",
  })
end

PkCore.onStateChanged("ui.hudTarget", hud.render)
PkCore.ui.layout.setContent("hudTarget", hud.html, hud.render)