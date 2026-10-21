# Hand-off: pk_ui (PkCore UI for MudForge)

This folder holds MudForge's plugins and is now the source of truth for the `pk_ui` plugin. It is about to become its own git repo.

- Real path: `~/Library/Application Support/com.mudforge.app/plugins`
- `~/MudForge/plugins` is a symlink to it.
- Work from the real path. Hot reload only fires for real files here (see below).

## Goal

The user's PvP system for Achaea runs in Mudlet today: PkCore, profile `achaea-pk`. The goal is to move it to MudForge (desktop and web client) with 1:1 parity. The UI comes first.

The UI is a port of a finished visual mock, "Vector Woodland":
- Mock folder: `~/Documents/Codex/2026-10-21/i-wa/outputs/mudforge-theme/` (read-only reference)
- `index.html`: the target layout. `preview.jpg` shows how it looks.
- `HOST-INTEGRATION.md`: the state contract, i.e. which classes and attributes each piece of state drives. **Read this before filling in any panel.**
- `START-HERE.md`, `VERIFICATION.md`: notes from the mock's author.
- `demo/`: fake data for the mock. Don't ship it.

The Mudlet originals of each panel, for behavior and data sources, are in `~/.config/mudlet/profiles/achaea-pk/pk/ui/`:
- `ui.lua`, `theme.lua`, `vitals.lua`, `limbs.lua`, `rail.lua`, `topbar.lua`, `header.lua`
- `room.lua`, `chat.lua`, `map.lua`, `ripple.lua`, `balances.lua`

Those panels read the PkCore blackboard and re-render on the `PkCore state changed` event. The data comes from AK (`ak.limbs`, affstrack) and WunderSys (`wsys.selfLimbCounter`, …), which don't exist in MudForge yet. Build each panel against a data contract (a table it renders from) so it can be fed later.

## Working with the user

- The user writes the combat-system logic (curing, offense, tracking) themselves. For that code, explain and review; don't write it unless asked.
- The user has asked for the UI widgets and scaffolding to be built.
- Never add a `Co-Authored-By: Claude` trailer (or any AI attribution) to commits. This is a hard rule.
- Never require copying code out of the MudForge app. Files on disk here are the truth.

## Folder layout

```
pk_ui.lua                     main plugin: metadata, PkCore global, init()
pk_ui/module_registration.lua load order (loadModule calls)
pk_ui/ui/theme_css.lua        GENERATED from design/theme.css - don't edit
pk_ui/ui/theme.lua            mock CSS + per-widget overrides; theme.page(body) -> widget HTML
pk_ui/ui/layout.lua           creates the panel widgets, positions them and the native terminal
design/theme.css              the mock's stylesheet (edit here, then regenerate)
design/forest.jpg             App Background image (user uploads it in MudForge settings)
design/preview.jpg            mock screenshot
tools/build_theme_css.sh      design/theme.css -> pk_ui/ui/theme_css.lua
```

Before `git init`, add a `.gitignore` covering:
- `Archive.zip` (41 MB, unrelated)
- `.DS_Store`
- probably `.claude/`. Ask the user.

`design/` and `tools/` sit at the plugins root. MudForge seems to recognise only `<name>.lua` plus a matching `<name>/` folder as a plugin, so they should be ignored. If MudForge complains about them, move them.

## MudForge facts (verified in practice)

The AI guide `~/Downloads/mud-client-ai-plugin-guide.md` is **out of date in places**; the MudForge owner (Asmodeus) said so. Trust these over the guide:

- **Hot reload:**
  - Editing a `.lua` file in this folder reloads the plugin.
  - One save can fire `init()` 2–3 times, so `init()` and everything it calls must be idempotent. `createWidget` is get-or-create by name, which helps.
- **Hot reload doesn't follow symlinks.** A symlinked `pk_ui/` folder pointing at another repo did not reload on edit. That's why the repo now lives here.
- **Multi-file plugins:**
  - `loadModule("path.lua")`, with paths relative to `pk_ui/`.
  - Modules share globals and have the full plugin API.
  - `loadModule` works even though the guide says file loading is blocked.
- **First install:** a plugin needs a one-time Import (Plugin Manager → Import). The import accepts a zip containing `<name>.lua` next to a `<name>/` folder. After that, on-disk edits hot-reload. It is already imported.
- **Libraries** (`~/MudForge/libraries`, loaded with `require`) are sandboxed with no host API. Don't use them for this.
- **`getWindowSize()`** includes MudForge's own top and bottom bars, about 75 px each. `layout.lua` has `insetTop`/`insetBottom = 75`. Measure and tune them.
- **The App Background can't be set by a plugin.** The user uploads `design/forest.jpg` in MudForge's settings.
- **Achaea GMCP `Char.Vitals`:** values arrive as **strings**. Parse them with `tonumber` and guard against nil or empty.

**Runtime quirks.** Lua 5.1 is transpiled to JS by luaparse; there is no real Lua VM.
- Not available: metatables, coroutines, `next`.
- Nil arithmetic yields 0 instead of erroring.
- Multiple return values get truncated.
- `string.format("%s", nil)` returns `"null"`.
- `tonumber("")` returns `0`.
- Write defensively.

## APIs in use

- Widgets:
  - `createWidget{type="html", name, title, transparent, position, size, appearance}`
  - `setWidgetProperty(id, "content", html)`
  - `setWidgetAppearance(id, {showTitleBar, movable, resizable, backgroundColor, backgroundOpacity, autoHideSettingsCog, …})`
  - `moveWidget`, `resizeWidget`
- Partial updates without re-rendering: `setBoundValues` with `data-mud-bind`, `data-mud-bind-style` and `data-mud-bind-attr` attributes in the HTML. Also `gaugeHTML`/`setGauges`.
- Window: `getWindowSize()`; `on("windowResize", fn)` (debounced, roughly 150 ms).
- GMCP: `onGMCPUpdate(pkg, fn)`, `getGMCPData(pkg)`.
- Other: `registerCommand(name, handler)` (handler returns its output string), `echo(text, color)`, `formatTime(getCurrentTime())`.
- Native widgets: `"terminal"` is the built-in terminal's id, and `createMapperWidget` creates a map. A widget the user has docked ignores move and resize.

## Current state (v0.3.0): empty scaffolding

`layout.lua` rebuilds the mock's page grid as separate widgets placed around the native terminal:

```
header ........................ | map
sidebar | terminal (native)     | room
        | hud self | hud target | chat
```

- **Seven HTML widgets**, each named `pk-<key>`:
  - `header` and `sidebar` (the sidebar holds waypoints, recovery, self and target afflictions, and locks)
  - `hudSelf` and `hudTarget`
  - `map` (mode buttons plus a slot), `room`, `chat` (filters)
- **Every widget:**
  - is transparent, with no title bar, and can't be moved or resized
  - holds the mock's outer markup with dashed `.pk-scaffold` placeholder labels
- **Geometry** is the `G` table in `layout.lua`, taken from the mock's tokens:
  - sidebar 180, dock 348, header 60, HUD 116
  - HUD split 70/30; dock split 30/30/40 (map/room/chat)
  - gap 10
- **`compute(w, h)`** returns the panel rectangles. **`apply(w, h)`** moves and resizes every widget plus `"terminal"`. `build()` runs from `init()`, and `windowResize` calls `apply`.
- **Each widget is its own HTML document.** `theme.page(body)` inlines the whole mock CSS, about 24 KB per widget. `theme.lua`'s `WIDGET_CSS` undoes the mock's full-page rules (1280×840 minimum, page padding, background image) so the CSS works inside each widget.

## Not yet verified in MudForge

1. The panels line up with the 75 px insets.
2. The terminal really moves and resizes into the center slot.
3. `setWidgetAppearance("terminal", {backgroundColor="#000000", backgroundOpacity=0.15})` gives the mock's 15% black backing.
4. The mock CSS renders correctly inside widget frames: fonts, CSS variables, layout.
5. Window resize re-lays out cleanly.

## Next steps

1. Finish verifying the scaffold (list above) and tune `G`.
2. **Map:** put a native map in the map slot. The built-in map widget's id is unknown; try `createMapperWidget` and position it over `.mf-map-slot`, below the mode buttons.
3. **Fill the panels, one at a time**, each from a render function plus a data table, following `HOST-INTEGRATION.md`:
   - **HUD self:** vitals from `Char.Vitals`, plus limbs, mode and balance/equilibrium. This replaces an earlier vitals widget whose logic was string parsing, a `readNumber` guard, percentages, and bound bal/eq classes.
   - **HUD target, header, room, chat, sidebar** in turn.
   - **Cooldowns:** `.mf-cooldown` driven by `data-state` and `--mf-progress`.
   - **Locks:** `.mf-lock` with `data-active`.
   - **Limbs:** `.mf-limb` with `data-damaged` and `--mf-damage`.
   - **Status fields:** Mode, Strategy and Route are read-only.
   - **Interactive bits:** map modes and chat filters use `aria-pressed`; waypoints use `aria-current`.
   - **Affliction lists:** 10-row viewports.
4. Prefer `setBoundValues` for frequent updates (vitals every prompt) over re-sending the 24 KB document.
5. Later: an event contract equivalent to `PkCore state changed` (planned as `pk.*` events) so ported logic can drive the UI.
