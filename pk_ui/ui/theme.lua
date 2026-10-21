-- Theme for every PkCore widget: the Vector Woodland mock CSS (ui/theme_css.lua)
-- plus the overrides needed to run it as separate MudForge widgets instead of one page.

PkCore.ui = PkCore.ui or {}
PkCore.ui.theme = PkCore.ui.theme or {}

-- The mock is one full-page grid with a 1280x840 minimum and the forest image on its root.
-- Here each region is its own widget, so the root just fills the widget, and the forest
-- is the App Background (set in MudForge settings; plugins cannot set it).
local WIDGET_CSS = [[
html, body { margin: 0; height: 100%; background: transparent; overflow: hidden; }
.mf-theme.pk-widget { min-width: 0; min-height: 0; padding: 0; background: none; }
.mf-theme.pk-widget > * { flex: 1; min-height: 0; }
.pk-scaffold {
  display: flex; align-items: center; justify-content: center; flex: 1; min-height: 0;
  color: var(--mf-text-muted); font: 9px var(--mf-font-game); letter-spacing: 1px;
  border: 1px dashed var(--mf-border);
}
]]

function PkCore.ui.theme.css()
  return PkCore.ui.theme.mockCss .. WIDGET_CSS
end

-- Full document for one widget: the theme, then `body` inside the theme root.
function PkCore.ui.theme.page(body)
  return "<style>" .. PkCore.ui.theme.css() .. "</style>"
    .. '<main class="mf-theme pk-widget">' .. body .. "</main>"
end
