# MUD Web Client — AI Plugin & Library Authoring Guide

**Runtime:** there is exactly ONE plugin engine — the next-gen runtime (`NextGenPluginRuntime`). There is no separate "legacy" engine to choose between; the `engineType` setting is ignored. "Legacy"-labeled functions (`getCurrentRoom`, `findTriggerByName`, the widget-id drawing forms, …) are NOT removed — they live in the shared base API and remain callable; the cleaner globalAPI forms are simply preferred.
**Lua version:** Lua 5.1 syntax. Source is parsed by `luaparse` and transpiled to JavaScript at load time — **there is no Lua VM at runtime**. A handful of Lua-isms (5.2+ `goto`, integer `//`, bitwise ops, `_ENV`) are rejected at parse time with a syntax error.
**Audience:** an LLM (Claude / GPT / etc.) generating plugins or shared libraries for this client.

This document is the complete reference. If a fact is not in here, do not invent it — emit a `TODO: ask user` comment instead.

### Table of contents

0. TL;DR plugin skeleton
1. Hard rules (read these first)
2. Plugin file structure & lifecycle (incl. load order between plugins: `dependsOn`)
3. Runtime environment (`math`, `string`, `table`, `io`/`os` stubs, `setTimeout`, blocked stdlib)
4. Widgets (`createWidget`, active widget, events, `widgetInfo`, library gauges)
5. Drawing API (shapes, text, images, canvas state, batching)
6. MUD I/O (`send`, `echo`, `print`, `utilprint`, `tprint`, color codes, `colorize`, ANSI helpers)
7. Triggers & aliases (substring/wildcard/regex; alias regex callback; Settings and MUSHclient-imported items)
8. Timers (`addTimer` with rate limits; the user's Settings timers; Send To: Script bodies)
9. Variables & persistence (`setVariable`, `saveTable`, `saveState`)
10. Lua-pattern reference (for `string.*` only — NOT for triggers)
11. GMCP / MSDP
11.5. Mapper API (read/edit rooms, exits, stubs, doors, locks, hashes, symbols, room colors, custom env colors, map labels, areas, user data, weighted pathfinding, walk, view controls, map export/import, audit, highlights, minimaps, events, Mudlet porting)
12. Multi-session (session info, cross-session sends/vars/events/GMCP/MSDP)
13. HTTP (`http.get` / `http.post`, HTTPS-only, blocked ranges, permission prompts)
14. Inter-plugin communication
15. `registerCommand` (and `addPaletteCommand` for the command palette)
15.5. MUSHclient compatibility API (`Note`, `Execute`, `DoAfter`, speedwalk notation, etc.)
15.6. Mudlet compatibility API (`raiseEvent`, `registerAnonymousEventHandler`, the `gmcp` table, `tempTimer`, `exists`, `permAlias`, `decho`/`hecho`)
16. `require()` and writing libraries (sandbox subsets, inject-APIs pattern)
17. Lua 5.1 gotchas
18. Five worked examples
19. Common pitfalls — do not do
20. Quick reference card
21. Error → likely cause table
22. Debugging your plugin

---

## 0. TL;DR — what a correct plugin looks like

```lua
plugin = {
  id          = "hello",
  name        = "Hello Widget",
  version     = "1.0.0",
  author      = "Author",
  description = "Smallest correct next-gen plugin.",
  settings    = { saveState = true },
}

function init()
  local widgetId = createWidget({
    type     = "canvas",
    title    = "Hello",
    position = { x = 100, y = 100 },   -- top-level x/y on the config don't position the widget
    size     = { width = 300, height = 120 },
  })
  setActiveWidget(widgetId)            -- REQUIRED before any drawX() call
  clear("#1a1a1a")
  drawRect(10, 10, 280, 100, "#222", "#888")
  drawText("Hello, MUD.", 24, 60, "#ffcc66", "20px monospace")
end

function cleanup() end
```

Note what is NOT here: no `local` on the metadata table, no `return plugin` at the
bottom, no `plugin.init` method syntax. Metadata is a plain global `plugin` table
and lifecycle hooks are bare global functions — that's the whole skeleton.

---

## 1. Hard rules — never violate these

1. **Always call `setActiveWidget(widgetId)` before any drawing function.** Drawing functions operate on the active widget; there is no widgetId parameter. Forgetting this is the single most common AI mistake.
2. **Never emit legacy widgetId-prefixed signatures.** `drawRect(widgetId, x, y, w, h, color)` is wrong. The correct signature is `drawRect(x, y, w, h, color, strokeColor?)`.
3. **Trigger patterns are NOT regex by default and NOT Lua patterns either.** `addTrigger(pattern, cb)` defaults to `type = "substring"` — plain literal substring match, or wildcard match if the pattern contains `*` or `?`. To capture groups, you must opt into regex mode: `addTrigger(pattern, cb, true)` (legacy boolean form) or `addTrigger(pattern, cb, { type = "regex" })`. The regex flavor is **JavaScript regex** (`\d`, `\s`, `\w`), not Lua patterns. Lua patterns are only used by `string.find` / `string.gmatch` / `string.gsub` / `string.match` (see §10).
4. **These stdlib modules are blocked:** `debug`, `loadstring`, `load`. Do not reference them. `dofile` and `loadfile` exist but only load **this plugin's own module files** (multi-file plugins, §16.4) — never a path on disk. A plugin that assigns its own `dofile`/`loadfile`/`loadModule` keeps it (the built-in is never put back over it). (`io` and `os` are NOT blocked — they are restricted implementations: see §"io and os" for exactly which functions work, how `io.*` persists through the storage engine, and the desktop-only File System Access permission that makes `io.*` operate on real files.)
5. **Library code (inside any `require()`-loaded module) runs in a minimal sandbox.** It has no access to `send`, `echo`, `addTrigger`, `createWidget`, drawing functions, timers, GMCP/MSDP, variables, or any other plugin API. If a library needs them, the consuming plugin must inject them via an explicit `lib.init({ send = send, echo = echo, ... })` call.
6. **Lua 5.1 syntax only.** `goto`, integer division `//`, bitwise operators (`&` `|` `~` `<<` `>>`), `_ENV`, and other 5.2+/5.3+ features are rejected by the parser before execution.
7. **`require()` accepts flat module names only.** Top-level calls must match `^[a-zA-Z0-9_-]+$` and be ≤ 64 chars. No paths (`require("foo/bar")`), no extensions (`require("foo.lua")`), no dots (`require("foo.bar")`). Nested `require` calls *inside* a library skip the 64-char length cap but still must match the alphanumeric/hyphen/underscore regex.
8. **`engineType` in `plugin.settings` is ignored.** It is parsed for legacy reasons but the next-gen runtime is always used. Do not include it.

---

### Reading plugin notices — errors and warnings

Every warning and error a plugin causes is printed as ONE boxed notice that names the plugin
(display name + version), and titles its severity in words: **PLUGIN ERROR** (the code crashed),
**PLUGIN WARNING** (a call ran and *did nothing*), **PLUGIN NOTICE** (information). Labelled rows:
`plugin`, `where` (file + line — module files of a multi-file plugin are named), `in` (what was
running: a trigger callback, a timer, `init()`, a GMCP/MSDP handler, an API call), `call`,
`problem`, `code` (the source line), `hint`, `note` (e.g. a failed load: "It was turned off. Fix
the error, then turn it on again in the Plugin Manager.").

```
┌─ ✦ PLUGIN ERROR ✦ ──────────────────────────────────────┐
│ plugin   Health Bar 1.2.0                               │
│ where    ui/theme.lua line 12                           │
│ in       trigger "hp" callback                          │
│ problem  attempt to index a nil value (field 'max')     │
│ code     local pct = hp.max / hp.cur                    │
│ hint     Check that hp is set before the trigger fires. │
├─ actions ───────────────────────────────────────────────┤
│ ▸ open in editor   ▸ turn off   ▸ copy details          │
└─────────────────────────────────────────────────────────┘
```

- **Closed box when it fits** the terminal; when a row would wrap, the right border is dropped.
  Widths are measured with the terminal's own Unicode tables (emoji and CJK count what xterm draws);
  in CJK width mode the right border is always dropped.
- **Actions** (links): open the plugin in the editor at the file and line; turn the plugin off in
  this world (errors only); copy the details as plain text. Links only work when this client printed
  them in this world — a MUD-sent look-alike does nothing.
- **Repeats** of the same error collapse into one line with a count, at most every few seconds:
  `Health Bar: the same error again (×40)`. "Same" = same world, severity, plugin and PLACE — what was
  running (`context`) plus the file and line. NOT the message: `error("no target " .. id)` with a new
  id each time still collapses, and the line then ends `, latest: no target 1093`. The same message
  at a different line is a different bug and gets its own box. (A notice with no context and no
  file/line keys on its message instead.) Still pending when the plugin unloads or reloads, the
  count is printed, not dropped.
- **Expiry**: a place quiet for 60 s is forgotten; its next error gets a fresh box.
- **Cap**: at most 3 boxes per plugin per world every 10 s; that window's other new places roll into
  one `…and N more errors from Health Bar` line. Notices that never collapse (person-driven ones,
  "did nothing" warnings) are never capped either.
- Errors also go to the **notification bell**: one entry per plugin + context, updated in place.
- The player's own Settings trigger/alias/timer scripts read **SCRIPT ERROR** … `your trigger "hp"`;
  client notices about plugins are titled **HOT RELOAD WARNING**, **PLUGIN LOAD ORDER WARNING**,
  **STORAGE WARNING**, **MAPPER WARNING**. A HOT RELOAD WARNING only appears when a save reloaded
  nothing (no matching plugin, a copy, a name clash, the plugin is turned off); every other save reloads the plugin — even an
  unchanged one, so saving restarts it. Only the client's own fresh writes (import, Open in external
  editor) are skipped, silently.
- **Screen Reader Mode / Self-Voice**: no box — one or two sentences, e.g. `Plugin error in Health
  Bar, ui/theme.lua line 12, in trigger "hp" callback: attempt to index a nil value (field 'max').`
  Repeat lines back off there because each is spoken: after 5 s, then 30 s, then every 2 min, each
  with the full count (`(40 times)`).
- Notices go to the plugin's own world, on a line of their own; one raised while a MUD line is being
  processed (inside a trigger) appears right after that line.

A **PLUGIN WARNING** means the call ran fine and *did nothing* — almost always because it was asked
for something that is not there:

```
┌─ ✦ PLUGIN WARNING ✦ ────────────────────────────────────────────────┐
│ plugin   Health Bar 1.2.0                                           │
│ call     toggleTriggerGroup("sweep", true) did nothing              │
│ problem  no trigger in Settings > Triggers belongs to group "sweep" │
│ hint     Group names are case-sensitive.                            │
└─ shown once ────────────────────────────────────────────────────────┘
```

These appear when you:

- address a trigger, alias, timer, macro or group **by a name that does not exist**
  (names are **case-sensitive** — except timer names: `EnableTimer`/`enableTimer` try the
  exact name first, then ignore upper/lower case as MUSHclient does, and warn instead of
  guessing when two timers differ only by case);
- pass a **trigger or alias id that this plugin does not own** to `removeTrigger`,
  `killTrigger`, `enableTrigger`, `disableTrigger` or `removeAlias` — ids only ever come
  from `addTrigger` / `addAlias`, so a bad one is a stale id, a typo, or a double remove;
- **draw with no active widget**, or call `setActiveWidget(id)` with an id that does not
  exist. That second one matters: the active widget is left *unchanged*, so every later
  drawing call silently goes to the previous widget. This covers the canvas-state calls too
  (`save`, `restore`, `translate`, `rotate`, `scale`, `setClipRegion`, `resetClipRegion`,
  `setBlendMode`, `setGlobalAlpha`, `setFont`), plus `drawTextWrapped`, `drawColoredText` and
  `drawImage` (`loadImage` does *not* need a widget);
- give `loadImage` an image that **cannot be loaded** — a missing file, an unreachable URL,
  broken base64, or SVG that is not valid XML (the warning quotes the XML error). It is
  reported once per source, when the load fails. A repeat `loadImage` of the same failed
  source does nothing for 10 seconds, then tries again (a network blip is not permanent)
  without re-reporting. `drawImage` with a plain-name id that was **never loaded** is reported
  once per id;
- **draw on an HTML widget**, or send an HTML-only call (`setBoundValue`, `setBoundValues`,
  `setGauge`, `setGauges`, `sendWidgetMessage`, `bindWidgetVariable`, `bindWidgetGMCP`) to a
  **canvas** widget. Drawing is refused; the HTML-only call is sent but nothing receives it;
- pass a **widget id no widget in this world has** to `showWidget`, `hideWidget`,
  `moveWidget`, `resizeWidget`, `destroyWidget`, `setWidgetProperty`, `setWidgetAppearance`,
  `registerWidgetEvent` or any of the HTML-only calls above. Use the id `createWidget`
  *returned*, not the `name` you gave it. Built-in widgets such as `"terminal"` count as
  present. `setWidgetZOrder` reports an unknown id too; it works on any widget in this world —
  your own, another plugin's, the mapper's or a built-in — not only the ones your plugin created;
- call `playSound` or `preloadSound` with **no file name**, or **before the world's window has
  opened** (there is no sound system yet); pass something that is not a handle from
  `playSound` to `stopSound`, `setSoundVolume` or `setSoundPan` (`stopSound(1)` stops
  *everything*); or use a buffer outside 0-10 with `PlaySound`, `Sound` or `StopSound`. A
  sound that has simply *finished* is not a mistake: `setSoundVolume` returns `false` quietly;
- call `deleteLine` or `replaceLine` **outside a trigger**, where there is no line being
  processed to edit (`moveCursor` returning `false` is its normal answer and stays quiet);
- give `echo` a **colour it does not recognise** (the text is printed in white), `colorize` a
  **format that does not exist** (you get colour segments back), `formatTime` something that
  is **not a time in milliseconds**, or `focusPrompt` a prefill that is **not a string**;
- read `getCanvasWidth()` / `getCanvasHeight()` / `getCanvasSize()` **before the widget is on
  screen when `createWidget` was given no size** — you get a placeholder 400x300, not a
  measurement. If you gave `createWidget` a `width`/`height` (or `size`), that size is returned
  quietly until the canvas measures itself, so "draw at load, redraw on `resize`" just works;
- save with `scope = "global"` **before storage has started**. The write is **lost**; do
  global saves from `onConnect`, not at load time;
- register `onGMCPUpdate`, `onMSDPChange` or `onPluginBroadcast` when the plugin has no
  context — the callback would never fire.

**`addTrigger` and `addAlias` return `""`** when they could not register. A non-empty id
means it worked. `addTrigger` refuses a pattern that is empty or not a string, a callback that
is neither a function nor `nil` (wrap a string of code in `function() ... end`), a `type` other
than `"substring"`, `"wildcard"`, `"regex"` or `"multiline"`, and a pattern that does not
compile. (`addTimer` already used this convention: it returns `""` for a missing callback or a
delay that is not a number, when there is no connection, when the 500-timer cap is reached, or
when you are creating timers too fast.)

Warnings from calls a loop or animation typically drives — drawing, widget targeting, sound,
cross-session sends, mapper writes — are shown **once** per target and then suppressed, so an
animation cannot flood the terminal. Calls that switch something by name (`toggleTriggerGroup`,
`enableTriggerGroup`/`EnableTriggerGroup`, `EnableTrigger`, `EnableAlias`, `EnableTimer`,
`EnableMacro`, the `toggle…ByName` calls) and calls a person usually starts (`registerCommand`,
`switchToSession`) warn every time. That is once **per plugin**: another plugin
making the same mistake still gets its own warning. Reloading the plugin starts them again.
"Not connected" warnings (`send`, `sendGMCP`, `sendToSession`, `sendToSessionId`) are shown once per
disconnection: when that world connects again, the next drop warns again.
A warning always appears in the world whose script made the call.

Calls that succeed stay silent, and so do ordinary "not found" answers you asked for on
purpose: `getVariable` on an unset name, `findTriggerByName` used inside an `if`,
`io.open` returning `nil` for a missing file.

---

## 2. Plugin file structure

A plugin file is a Lua script. It declares some metadata and defines lifecycle/behaviour functions. **Write new plugins in the current style** — a global `plugin` metadata table plus bare global lifecycle functions:

```lua
-- CURRENT STYLE (use this): global metadata table + bare global functions.
plugin = { id = "hello", name = "Hello", version = "1.0.0", author = "You", description = "..." }
function init() ... end
function cleanup() ... end
-- No `return plugin` — nothing to return.
```

An **older style** exists and still loads (kept so existing plugins never break), but do not generate it for new code:

```lua
-- OLDER STYLE (supported for back-compat only — don't write new plugins this way):
plugin = { id = "hello", ... }
function init() ... end
function cleanup() ... end
return plugin   -- optional even here (the runtime finds the table without it),
                -- which is exactly why it's noise — there is nothing a return
                -- accomplishes in either style.
```

The metadata fields (on the table, or a top-level `plugin = {...}`):

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Optional and cosmetic. The client identifies an installed plugin by the id it gave it at install time (the repository listing's id, or a generated id for a file import), not by this field. `getPluginId()` returns that installed id; to address another plugin use `findPluginByName(name).id`. |
| `name` | string | Display name shown in UI. |
| `version` | string | Semver; cosmetic only. |
| `author` | string | Cosmetic. |
| `description` | string | One-line summary. |
| `dependsOn` | string or list of strings | Optional. Plugins that must finish starting (their `init()` has returned) before this one starts. See **Load order (`dependsOn`)** below. |
| `settings` | table | See below. |

### Lifecycle hooks

Define any of these as a `plugin.<name>` method **or** a top-level `function <name>()` — both are found. Every hook has THREE interchangeable spellings, all equivalent:

- the **MudForge-native** name (the recommended default, shown first),
- the **MUSHclient** name (`OnPlugin*`, PascalCase) so plugins ported from MUSHclient work unchanged,
- an older back-compat camelCase `onPlugin*` spelling (still accepted; prefer the native name).

Event hooks receive the **session id as their first argument**.

| Native (recommended) | MUSHclient alias | camelCase alias | Fires | Args | Return |
|----------------------|------------------|-----------------|-------|------|--------|
| `init` | `OnPluginInstall` | `onPluginInstall` | On load/enable. If the plugin creates a widget during script execution, `init` is deferred until that widget's first `plugin-canvas-ready` event (or 2s). | — | — |
| `onEnable` | `OnPluginEnable` | `onPluginEnable` | Right after `init`. | — | — |
| `onConnect` | `OnPluginConnect` | — | After the MUD connection is established. Not called when the iOS app reloads its screen and keeps the connection (the `reattached` event fires instead). | `sessionId: string` | — |
| `onDisconnect` | `OnPluginDisconnect` | — | After the MUD connection is lost. | `sessionId: string` | — |
| `onLine` | `OnPluginLineReceived` | — | Every incoming line. | `sessionId: string, rawLine: string, cleanLine: string` | return `false` (boolean) to **discard** the line (no display, no triggers) |
| `onCommand` | `OnPluginCommand` | — | Player typed a command, before alias processing. | `sessionId: string, command: string` | return `false` (boolean) to **discard** the command |
| `onSend` | `OnPluginSend` | — | Text about to be sent to the MUD. | `sessionId: string, text: string` | return `false` (boolean) to **block** the send |
| `onSaveState` | `OnPluginSaveState` | — | Just before world state is persisted. | `sessionId: string` | — |
| `onBroadcast` | `OnPluginBroadcast` | — | Another plugin in this world called `broadcastPlugin` (your own broadcasts are skipped) or `broadcastToPlugin` targeting you. | `senderId: string, message: any, data: any` | — |
| `onDisable` | `OnPluginDisable` | `onPluginDisable` | On unload, before `cleanup`. | — | — |
| `cleanup` | `OnPluginClose` | `onPluginClose` | On unload. | — | — |

**Auto-cleanup:** triggers, aliases, timers, and widget event handlers you registered through the API are released automatically on unload — you do **not** need to undo them in `cleanup`. Use `cleanup` only for resources you allocated yourself (e.g. a `window` listener you added directly).

**World switch = full restart.** Opening a *different* world in the same session unloads every plugin (`onDisable` → `cleanup`, with any last writes still going to the old world) and then reloads it against the new world — `init()` runs again and reads the new world's data. Don't cache world data in module-level globals expecting it to survive a switch; re-read it in `init()`.

**Saved data replaced while running = restart of that plugin.** When something outside your plugin replaces its saved data (`worlds/<world>/plugins/<id>.state.json`) while it runs — *Get updates* from cloud sync, a Save History restore, another window saving the same world, importing a world file (or recovered data) into the open world, or the user editing the file in the File Manager — MudForge reloads just that plugin: `onDisable` → `cleanup`, widgets/timers/triggers rebuilt, then `init()` runs again and reads the new data. The terminal says which plugin and why. **Saves the old copy makes after the replacement are skipped — including any in its own `cleanup()`** (default-scope `saveTable`/`savePluginFile`/`appendPluginFile`/`deletePluginFile`/`deleteVariable` return `false`; `setVariable` does nothing), because they would write the old data back over the new. The new data wins: before the reload the old copy's `onSaveState()` and `cleanup()` run, and if what they try to save differs from what it had last saved — progress kept only in memory on this device — the terminal says that progress was replaced. Nothing is reloaded when the new file holds the same data. So: load in `init()`, save when the data changes, and never make `cleanup()` your only save.

- **Shared (`"global"`) data works the same way.** When the app-wide shared data is replaced (it syncs too), every plugin that has read or written one of the shared names that **changed** (a variable, table or file name used with `"global"`) since it loaded is reloaded the same way, and its old copy's `"global"` saves are skipped. A plugin that never used a changed name is not reloaded — another plugin's deposit into `"bank"` does not restart a plugin that only reads `"motd"`. A plugin reloaded because only its per-character data changed still saves `"global"` data normally, and the other way round.
- **The same world open in two windows.** Only one window saves a world at a time (the others show *"changes made here are held"*). In a window that is not the saving one, nothing is reloaded when the other window saves your data — your plugin keeps running and reads back its own saves. When that window takes over saving (the other one closes), a plugin that was running when the other window replaced its data is reloaded then, and what **that copy** saved in the meantime is **not kept**, so it cannot overwrite the other window's newer data; the terminal says so. A plugin started (or turned off and on) after the replacement read the new data, so everything it saves is kept as usual.

### Load order (`dependsOn`)

When a world opens, every enabled plugin **starts at the same time**; which plugin's `init()` runs first is NOT fixed and can change between world opens. Plugins do not share Lua globals, so order only matters when plugin B relies, in its `init()`, on something plugin A sets up in **its** `init()` — an `on("…")` handler B `emit`s to, a `"global"`-scope variable A writes, a widget A creates.

Declare it with `dependsOn` in the plugin table. B then starts only after A has loaded **and A's `init()` has returned**. Plugins without `dependsOn` still start immediately, in parallel, exactly as before.

```lua
-- Core Lib: owns a HUD log other plugins print into
plugin = { name = "Core Lib", version = "1.0.0" }

function init()
  on("hud:print", function(data) echo("[HUD] " .. data.text) end)
end
```

```lua
-- Combat HUD: needs Core Lib's handler to exist at init time
plugin = {
  name      = "Combat HUD",
  version   = "1.0.0",
  dependsOn = { "Core Lib" },          -- one name may also be a plain string: dependsOn = "Core Lib"
}

function init()
  emit("hud:print", { text = "Combat HUD ready" })   -- guaranteed to reach Core Lib
end
```

```lua
-- Loot Tracker: waits for BOTH
plugin = { name = "Loot Tracker", version = "1.0.0", dependsOn = { "Core Lib", "Combat HUD" } }
```

Rules:

- **Matching:** each entry is the other plugin's **name** as the Plugin Manager shows it (case and surrounding spaces ignored), or its **id** (its installed id, or the `id = "…"` in its own plugin table).
- **Read before the plugin runs:** write the names as quoted strings. `dependsOn = myList` cannot be read — the terminal says so and that part of the order is ignored. `plugin.dependsOn = { "Core Lib" }` as a separate statement also works.
- **Never blocks for good.** In each case below the plugin still starts, and a PLUGIN LOAD ORDER WARNING notice in the terminal says what happened:

| The dependency… | Result |
|---|---|
| is not installed in this world | starts anyway, notice names it |
| is turned off | starts anyway, notice says to turn it on |
| fails to load (error) | starts once it has failed, notice says it may not work |
| takes longer than 20 seconds to start | stops waiting and starts, notice; the slow plugin keeps loading |
| is part of a loop (A needs B, B needs A) | notice names the loop (`A → B → A`); those plugins start with no order between them (their dependencies outside the loop are still honoured) |
| is the plugin itself | entry ignored, notice |
| is already running | nothing to wait for |

- **No cascade.** Reloading a dependency (editor save, file change) does NOT reload its dependents. Turning a dependency off does not turn its dependents off; the terminal names them. Turning a plugin on (or importing/saving it) starts it at once and says if a dependency is missing, off or not running.
- The Plugin Manager shows **Depends on: …** on the plugin's card, and a **Missing dependency** badge when one is not installed or turned off.
- A server package (`.mfp`) installs its plugins one after another in `dependsOn` order.

**Alternative — a ready handshake with `on`/`emit`** (use it when the dependency is OPTIONAL, or you want to react each time it restarts). It works whichever plugin starts first:

```lua
-- In Core Lib
function init()
  on("core:ping", function() emit("core:ready") end)  -- answer plugins that start after us
  emit("core:ready")                                   -- tell plugins that started before us
end
```

```lua
-- In the plugin that uses it
local started = false
local function start()
  if started then return end
  started = true
  -- set up things that need Core Lib here
end

function init()
  on("core:ready", start)   -- Core Lib starts later: hear its "ready"
  emit("core:ping")         -- Core Lib started earlier: it answers now
end
```

Do NOT use a saved variable (`setVariable`, `"global"` scope) as the ready flag: saved values survive into the next session, so it can read "ready" before the other plugin has started this time.

**Inside one plugin** there is nothing to declare: the file's top level runs top to bottom, then `init()`.
<!-- TODO(lead): document module load order here once multi-file plugins (loadModule) merge. -->

### `plugin.settings` fields

| Field | Type | Default | Effect |
|-------|------|---------|--------|
| `saveState` | boolean | `true` | `false` only skips the bulk save of this plugin's variables at unload and world save. Each `setVariable` is still written through to the world file, and stored variables still load, so it does **not** make variables temporary — keep throwaway state in ordinary Lua variables. (`saveTable` always persists.) |
| `appearance` | table | — | Default frame look for all of this plugin's widgets (the `setWidgetAppearance` fields); a `createWidget` call's `appearance` overrides it field by field. |
| `debugMode` | boolean | `false` | Does nothing. (It was meant to add debug information to the transpiled code; that was never built.) For verbose plugin logs in the browser console use Plugin Manager → Settings → **Enable plugin debugging**. |
| `enableExperimentalFeatures` | boolean | `false` | Reserved; no effect today. |
| `engineType` | (ignored) | — | Parsed but never gates runtime selection. Omit. |

Settings are read before the plugin runs. Every form works — a `settings = { … }` field inside `plugin = { … }` (also with `local plugin`), a separate `plugin.settings = { … }`, or `plugin.settings.saveState = false` — as long as each value is a plain literal (`true`, `false`, a string or number, or a table of those). A value only known once the plugin runs (`saveState = cfg.save`) cannot be read: the client says so on load and uses the default.

---

## 3. Runtime environment

The plugin script is parsed (`luaparse`), transpiled to JavaScript, and executed in a sandboxed function. The following are available as **globals**:

### Lua language built-ins

`type`, `tostring`, `tonumber`, `pairs`, `ipairs`, `unpack`, `select`, `error`, `assert`, `pcall`, `xpcall`, `print`.

`unpack` **is** a top-level global at plugin scope, as in Lua 5.1 (it only moved to `table.unpack` in 5.2). Both spellings work and do the same thing. It used to be missing here while the library scope had it, so `local a, b = unpack(t)` worked inside a `require()`d library and raised "attempt to call a nil value" in the plugin that required it.

### Standard libraries

**`math`** — `abs`, `acos`, `asin`, `atan`, `atan2`, `ceil`, `cos`, `cosh`, `deg`, `exp`, `floor`, `fmod`, `frexp`, `huge`, `ldexp`, `log`, `log10`, `max`, `min`, `modf`, `pi`, `pow`, `rad`, `random`, `randomseed`, `sin`, `sinh`, `sqrt`, `tan`, `tanh`. Note: `math.randomseed` exists but is a **no-op** — `math.random` uses the host's `Math.random` and cannot be seeded.

**`string`** — `byte`, `char`, `find`, `format`, `gmatch`, `gsub`, `len`, `lower`, `match`, `rep`, `reverse`, `sub`, `trim`, `upper`. Patterns use Lua-pattern syntax (see §10).

- `string.rep(s, n, sep?)` — the optional separator goes *between* copies: `string.rep("a", 3, "-")` is `"a-a-a"`. Omit it and you get `"aaa"`.
- `string.trim(s)` — strips leading and trailing whitespace. Not standard Lua, but it has shipped for long enough to rely on.
- In a `gsub` replacement string, `%1`–`%9` are the captures, `%0` is the whole match, and `%%` is a literal percent sign.

**`table`** — `concat`, `insert`, `remove`, `sort`, `maxn`, `getn`, `setn`, `foreach`, `foreachi`, `pack`, `unpack`.

### Provided modules

**`json`**

```lua
json.encode(value)   -- Lua value → JSON string
json.encodeForScript(value) -- same JSON, but < > & U+2028 U+2029 written as \u003c-style
                     -- escapes: safe to paste into an HTML widget's <script>. Use it
                     -- (not json.encode) for any data that goes into widget HTML.
json.decode(s)       -- JSON string → Lua value
json.null            -- the same value as nil (json.null == nil is true): a field set to it is dropped by
                     -- json.encode, and a JSON null decodes to nil. A null INSIDE an array keeps its slot:
                     -- json.decode("[1,null,3]") re-encodes as [1,null,3].
```

**`http`** — see §13.

### `io` / `os` — web-safe stubs, not real

`io` and `os` are exposed but heavily restricted. They are **stubs** that satisfy ports of MUSHclient scripts:
- `os.time`, `os.date`, `os.clock`, `os.difftime`, `os.setlocale`, `os.tmpname` work, with these differences: `os.date()` with no format returns a table (same as `os.date("*t")`), not a string — pass a format such as `"%c"` for text; the `!` UTC prefix is not supported (local time only); `os.clock()` is seconds since the page loaded, not CPU time; `os.setlocale` changes nothing and returns its argument (or `"C"`).
- `os.getenv(name)` returns hardcoded placeholders for `"HOME"` (`"/home/user"`), `"USER"` (`"mudclient"`), `"PATH"` (`"/bin:/usr/bin"`), and `"SHELL"` (`"/bin/sh"`); returns `nil` for everything else. **Do not treat these values as meaningful — they are fake.**
- `os.execute`, `os.exit`, `io.popen`, `io.input`, `io.output`, `io.read` print a PLUGIN WARNING once and return `nil` — **never** use them.
- `os.remove(name)` / `os.rename(old, new)` — real deletion/renaming **only on the desktop app with the plugin's File System Access permission ON** (same home-folder scope and path rules as real-fs `io.open` below); they return `true` on success and bare `nil` on failure. Everywhere else they log a warning and return `nil`.
- `io.open(filename, mode?)` returns a file object whose `:read`/`:write`/`:lines`/`:seek` now persist through the **storage engine** (the world file — portable, included in backup), NOT localStorage. **Real-Lua open semantics**: opening a **missing** file for reading (`"r"`/`"r+"`) returns `nil` — so the classic `local f = io.open(...); if not f then` guard from MUSHclient/Mudlet scripts works; `"w"`/`"w+"` **truncate (and create) the file at open**, not at first write; and consecutive `f:write()` calls **accumulate** (they no longer each replace the whole file). **By default these are pseudo-files, not the real filesystem**: `filename` is just a storage key, so `io.open("/Users/me/notes.txt", "r")` does NOT read that Mac file — it returns `nil` (no pseudo-file by that name) unless your plugin previously wrote one under that exact name. Pseudo-files are **per-character (per-world)** and travel with the world; localStorage is only a fallback when no world is open. Idiomatic `f:write(...)` / `f:read("*a")` work (the `self` arg is handled). For finer control or shared files you can also use the direct functions: `savePluginFile(name, text, scope?)`, `loadPluginFile(name, scope?)`, `appendPluginFile(name, text, scope?)`, `deletePluginFile(name, scope?)` — `scope` "global" puts the file in ONE app-wide namespace shared by all your characters **and every plugin** (keyed by file name; same model as `saveTable`).
- **REAL filesystem io.\* (desktop app only, opt-in per plugin)**: when the user turns ON the plugin's **File System Access** permission (plugin settings → Permissions), `io.open`/`io.lines` (and `os.remove`/`os.rename`) switch from pseudo-files to **actual files on disk**, with the same real-Lua open semantics as above. Scope is enforced natively: paths must stay **inside the user's home folder** (`~` expands; `..` traversal and symlinks escaping home are refused), and **relative names resolve to a per-plugin data folder** `~/MudForge/plugin-files/<plugin>/` (auto-created on first write), so `io.open("save.dat", "w")` from different plugins never collide. Three things to design for: (1) the flip changes where `io.*` looks — pseudo-files written before the permission was granted stay in storage (read them via `loadPluginFile`, which uses the storage engine **regardless** of the toggle); (2) files are read as UTF-8 text (invalid bytes are replaced) — this is a text API, not a binary one; (3) never assume the permission is on: `io.open` returning `nil` for a file you expected is also what a scope refusal looks like, and on web/iOS the toggle does not exist. Real-filesystem reads and writes are capped at 16 MiB per call, directory listings at 20,000 entries, and each call must complete within 5 seconds, otherwise the call fails with an error the plugin can see. Do NOT ask users to enable it unless your plugin genuinely needs real files (log export, reading game data files, etc.).
- Also present: `io.lines(name)` (iterate a pseudo-file's lines), `io.type(f)` (`"file"`, `"closed file"` or nil), `io.tmpfile()` (a new pseudo-file opened `"w+"`), and `io.close()` / `io.flush()` (no-ops returning `true`). `f:read` understands a byte count, `"*a"` and `"*l"` (the default) — not `"*n"` or `"*L"`.
- `io.write` (the top-level one, not a file handle) accepts any args and joins them, but writes to the JS console — not the user's terminal.
- Do not pretend you have real shell or filesystem access. For persistent data, prefer `setVariable` / `saveTable`.

### Not provided

`debug`, `loadstring`, `load`, `package`, `setmetatable`, `getmetatable`, `next`, `collectgarbage`, `getfenv`, `setfenv`, `coroutine`, `bit`/`bit32`, `utf8`. `rawget`, `rawset`, `rawequal` and `rawlen` exist inside a `require()`d library but NOT at plugin scope. (`require` exists but is the library loader described in §16 — not the standard Lua module system. `dofile`/`loadfile` exist but load only the plugin's own module files — §16.4.)

### Browser timers (also available)

`setTimeout(fn, ms)` and `clearTimeout(id)` are exposed for parity with browser scripting. They are `addTimer`/`removeTimer` underneath (§8), so they are tracked, cleaned up on unload and share the same limits; mind the reversed argument order.

---

## 4. Widgets

### `createWidget(config) → widgetId : string`

Creates a widget and returns its id. Config table:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `type` | `"canvas" \| "html" \| "map"` | `"canvas"` | Render mode. Alias: `renderMode`. Any other value raises an error. |
| `name` | string | `"widget"` for the id, `"<plugin name> Widget"` as a title | The widget's identity: its id is derived from your plugin + `name` (see "Multiple widgets"). Also the title when `title` is not given. |
| `title` | string | `name` | Window title shown in the widget chrome. Does not affect the id. |
| `position` | `{ x: number, y: number }` | `{ x = 200, y = 150 }` | Initial position. |
| `x`, `y` | number | — | Used when `position` is omitted and `x` is a number (`y` then defaults to 150). |
| `size` | `{ width: number, height: number }` | `{ width = 300, height = 200 }` | Initial size. |
| `width`, `height` | number | — | Used when `size` is omitted and `width` is a number (`height` then defaults to 200; `height` alone is ignored). |
| `zIndex` | number | above existing widgets | Starting layer, 0–49 (clamped; 50+ is where dialogs/menus start). A layer saved for this widget — the user's ⚙️ Layer Order choice or a later `setWidgetZOrder` — wins on the next load. |
| `transparent` | boolean | `false` | No frame fill and no backdrop blur. |
| `appearance` | table | — | Default frame look (the `setWidgetAppearance` fields, e.g. `resizable = false`, `movable = false`); merged field by field over `plugin.settings.appearance`. |
| `properties` | table | `{}` | Custom properties, read back with `getWidgetProperty`. `properties.content` is an HTML widget's starting markup. |
| `visible` | boolean | `true` | `false` opens a NEW widget hidden (`showWidget` shows it). A visibility saved for the widget — the player's own show/hide — wins on later loads. |
| `resizable`, `movable` | boolean | `true` | Same as `appearance.resizable` / `appearance.movable`; an explicit `appearance` value wins. |
| `template` | string | — | Starting HTML for `type = "html"` when `properties.content` is not set. |
| `scrollable` | boolean | — | Accepted and not needed: an HTML widget scrolls whenever its content is taller than the widget. |

Calling `createWidget` again with a `name` this plugin already used returns that widget's id (get-or-create);
asking for a different `type` under that name is reported once.

```lua
-- Preferred: position/size tables
createWidget{ type="canvas", name="hp", title="HP", position = {x=100, y=120}, size = {width=300, height=80} }

-- Also works: top-level x/y/width/height when position/size are left out
createWidget{ type="canvas", name="hp", title="HP", x=100, y=120, width=300, height=80 }
```

**Phones.** Your widget renders on a phone exactly as it does on a computer — it can
be moved, resized, and shown full screen. Two things to know:

- **`position` and `size` are the desktop numbers.** A phone screen is roughly a
  fifth as wide, so it does not use them: the first time a player opens the world
  on a phone the client places your widget itself, shrinking it to fit if the size
  you asked for is wider or taller than the screen. Pick the size that suits a
  desktop and let the phone handle itself.
- **Each device remembers its own arrangement.** Where a player drags your widget
  on their phone has no effect on where it sits on their computer, and vice versa.
  `moveWidget` / `resizeWidget` act on whichever the player is currently looking at.

Widget sizes below roughly 100×80 are hard to hit with a thumb, so avoid making a
widget the player is expected to interact with any smaller than that.

Widgets on a phone are LOCKED while the player is playing — no title bar, no drag
handles — and become movable only in the client's arrange mode. `moveWidget` and
`resizeWidget` still work from Lua at any time; the lock applies to the player's
finger, not to your plugin.

Arrange mode is also where a player CLOSES a widget, with the ✕ in its corner. It
is the only route your widget has off the screen — the buttons in the phone's top
bar only cover the client's own chat, party, map and gauges — so a plugin whose
widget the player is meant to dismiss should not count on a close control of its
own being reachable.

One widget is off limits on a phone: `hideWidget("terminal")` does nothing there.
The phone has no control to bring the terminal back, so hiding it would strand the
player on an empty screen. Everything else — including `showWidget`, `moveWidget`
and `resizeWidget` on the terminal — behaves normally.


After creating a canvas widget, **`createWidget` automatically sets it as active**, so a single-widget plugin doesn't need to call `setActiveWidget` immediately after. Always call `setActiveWidget` again, however, when:
- You have multiple widgets.
- You're returning to drawing from an event handler.
- Drawing happens in a timer callback that fires after another widget might have stolen focus.

### Active widget management

```lua
setActiveWidget(widgetIdOrInstance)   -- Required before drawX() unless the widget was JUST created.
getActiveWidget()                     -- Returns the active widget instance (rarely needed).
```

### Multiple widgets in one plugin

A single plugin can create as many widgets as it likes — **but each one needs a distinct `name` AND a distinct `position`**, or it will look like only one was created:

- **Distinct `name`:** the widget id is derived from `pluginId + name` (an `id` or `title` in the config plays no part), and `name` defaults to `"widget"`. So two `createWidget` calls *without* distinct names resolve to the **same id** — the second is treated as a duplicate and silently returns the first widget's id (no second widget). Give each a unique `name` (e.g. `"hp-bar"`, `"map-panel"`).
- **Distinct `position`:** widgets with no `position` all default to `{x=200, y=150}` and stack exactly on top of each other (newest on top), so the earlier ones are hidden. Give each its own `position`.
- **Canvas widgets:** call `setActiveWidget(widgetId)` before the `drawX()` calls for each one (the active widget is a single global — see above).

`public/plugins/border-showcase.lua` is the canonical example — four widgets, each with its own `name` and `position`:

```lua
createWidget({ type="html", name="bs-preset",   position={x=60,  y=70},  size={width=230, height=120}, ... })
createWidget({ type="html", name="bs-gradient", position={x=300, y=70},  size={width=230, height=120}, ... })
createWidget({ type="html", name="bs-animated", position={x=540, y=70},  size={width=230, height=120}, ... })
createWidget({ type="html", name="bs-control",  position={x=60,  y=220}, size={width=420, height=360}, ... })
```

### Widget control

```lua
showWidget(widgetId)                          -- Does NOT re-open a widget the user closed (its × button, a visibility toggle, the plugin manager); warns instead, once per widget and again each time the user closes it.
showWidget(widgetId, true)                    -- force: overrides the user's choice. Use it only for an explicit user action, e.g. their own "show" command. A forced show/hide acts only on the widget in THIS world (the Plugin Manager's own show/hide button covers every world).
hideWidget(widgetId)
hideWidget(widgetId, true)                    -- force: the PLAYER closed it (their own "hide" command). Recorded exactly like the × button: remembered across reloads and other devices, and a later showWidget(widgetId) without force stays refused until the player re-opens it. A plain hideWidget is not remembered as the player's choice.
moveWidget(widgetId, x, y)                    -- x, y: number (pixels)
resizeWidget(widgetId, width, height)         -- width, height: number (pixels)
destroyWidget(widgetId)                       -- Removes it from THIS world's screen only (same plugin's widget in other worlds untouched). Frees its event handlers; its saved layout place is kept, so re-creating the same name restores it. Choose a new drawing target afterwards.
setWidgetProperty(widgetId, prop, value)      -- "title" changes the frame title; "visible" shows/hides (false/nil hides);
                                              --   "x"/"y"/"width"/"height" move or resize like moveWidget/resizeWidget (the other
                                              --   coordinate is kept; a docked widget stays put; a non-number is reported once).
                                              --   HTML widgets: "resizeEvents" true/false turns player-resize events on/off (opt-in);
                                              --   "content" replaces the document; any other name is delivered to
                                              --   mudforge.onProperty in the widget.
getWidgetProperty(widgetId, prop)             -- A value you stored (or passed in createWidget's properties); "visible" is live: true/false for whether the widget is showing in THIS world (any widget id)
setWidgetZOrder(widgetId, zIndex)             -- Any widget in THIS world (yours, another plugin's, the mapper's, built-ins like "terminal"/"chat"). zIndex is clamped to [0, 49]; false + a warning for an unknown id or a non-number. Same layer the user edits in the widget's ⚙️ dialog; saved with the layout; dragging/resizing does not change it. Ties draw in page order.
```

**HTML widget data calls** (HTML widgets only — sent to a canvas widget they warn and nothing receives them):

| Function | Returns | Notes |
|----------|---------|-------|
| `sendWidgetMessage(widgetId: string, data: any)` | — | Delivered to `mudforge.onMessage(fn)` inside the widget. |
| `setBoundValue(widgetId: string, key: string, value: any)` | — | Updates every element bound to `key` (`data-mud-bind="key"`, `data-mud-bind-style="prop:key; …"`, `data-mud-bind-attr="attr:key"`); `nil` shows empty. Bound values survive a `content` rebuild. `on*`, `style` and `srcdoc` attributes cannot be bound; URLs are checked. |
| `setBoundValues(widgetId: string, values: table)` | — | Many keys in one pass: `{ hp = 50, mana = 20 }`. |
| `bindWidgetVariable(widgetId: string, key: string, variableName: string, scope?: "global")` | — | Pushes the variable now and again on every `setVariable` of that name by this plugin in this world. With `"global"` it follows the shared variable, written from any world. The default and `"global"` variables of one name are separate — bind with the scope you write with. |
| `bindWidgetGMCP(widgetId: string, key: string, package: string, path?: string)` | — | Pushes the GMCP value now and on every update; `path` is a dot-path into the package. |
| `unbindWidget(widgetId: string)` | — | Stops this widget's variable AND GMCP bindings (binding again later adds no duplicate listener). An id no widget has is reported once. All bindings end when the plugin unloads. |

An element with `data-mud-action="name"` (and optional `data-mud-data="…"`) raises the widget's
`action` event when clicked (see "Widget events").

**Docked widgets (Dynamic widget layout).** On a computer, the player can dock
your widget into the tiled layout by dragging it onto the edge of another widget
(above, below, or as a new column beside it). While it is docked, the layout owns
its position and size: `moveWidget` and `resizeWidget` leave it alone, and the
position/size you passed to `createWidget` only applies while it floats. Your
widget still receives its usual resize event (canvas widgets, and HTML widgets
created with `resizeEvents = true`) or window resize (other HTML widgets) every
time its tile changes size — so build widgets that reflow to
any size rather than assuming the size you asked for. The player floats it again
with Shift + drop, after which `moveWidget`/`resizeWidget` work as before.

**HTML widgets: always escape server text.** Anything from the MUD (names, room
names, GMCP/MSDP values, trigger captures) goes into widget markup through
`escapeHTML(text)`, and into a `<script>` through `json.encodeForScript(value)`.
See §6 "HTML escaping".

**HTML widgets: a content rewrite is a clean slate.** Setting `content` replaces
the widget's whole document, and every `setInterval`, `setTimeout` and
`requestAnimationFrame` the previous content started is stopped with it. That is
what stops an animation from stacking up and running two or three times too fast
after a rebuild. If a timer must keep running, start it again in the new content
— or avoid the rebuild entirely and push values with reactive binding
(`data-mud-bind` + `setBoundValue`), which leaves the DOM, its listeners and its
timers untouched.

### Library gauges — `gaugeHTML`, `setGauge`, `setGauges`, `getGaugeCatalog`

For health/mana/any bar, **use the gauge library instead of hand-drawing one.**
It is the same set of gauges the built-in Party and Status widgets draw (74
treatments, 50 gradients + 8 matched sets, 22 palettes, finishes, danger
signals, readouts, typefaces, ASCII bars), and every HTML widget already has its
stylesheet — you only write markup and push values.

```lua
plugin = { id = "vitals-hud", name = "Vitals HUD", version = "1.0.0", author = "me" }

local hud

function init()
    hud = createWidget({ type = "html", name = "Vitals HUD", size = { width = 260, height = 70 } })
    setWidgetProperty(hud, "content",
        gaugeHTML({ id = "hp", label = "HP", stat = "hp", look = "party" }) ..
        gaugeHTML({ id = "mana", label = "MN", stat = "mn", style = "glossy",
                    gradient = "plasma-lance", percent = true }))

    onGMCPUpdate("Char.Vitals", function(data)
        setGauges(hud, {
            hp = { value = data.hp, max = data.maxhp },
            mana = { value = data.mana, max = data.maxmana },
        })
    end)
end
```

| Function | Returns | Notes |
|---|---|---|
| `gaugeHTML(options: table)` | `string` | HTML for one gauge. Concatenate several; put the result in the widget's `content`. |
| `setGauge(widgetId: string, gaugeId: string, value: number, max?: number)` | — | Repaints that gauge in place (no rebuild, the fill animates). Omit `max` to keep the last one. |
| `setGauges(widgetId: string, values: table)` | — | `{ [gaugeId] = { value = number, max = number } }`; a `{ value, max }` pair or a bare number (value only) also work. |
| `getGaugeCatalog()` | `table` | Lists for pickers: `styles`, `gradients`, `schemes`, `sets`, `asciiSets`, `fonts`, `overlays`, `outers`, `dangerSignals`, `textModes`. Each entry is a table, not a bare id: `styles` entries are `{ id, name, group, minHeight, motion, radial }`, `gradients` `{ id, name, group, diagnostic, stops }`, `sets` `{ id, name, hp, mn, mv }`, everything else `{ id, name }`. |

`gaugeHTML` options (only `id` is required; unknown or invalid values fall back
to defaults, they never error):

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Required. The gauge's id in this widget — what `setGauge` addresses. |
| `value` | `number` | Starting value. Default `0`. |
| `max` | `number` | Starting maximum. Default `100`. |
| `label` | `string` | Short label beside the bar; also the screen-reader name. |
| `showLabel` | `boolean` | `false` = label for screen readers only. Default `true`. |
| `stat` | `string` | Stat key (`"hp"`, `"mn"`, `"mv"`, …): picks that stat's treatment/gradient from a borrowed look. Default `"hp"`. |
| `look` | `"default" \| "party" \| "status"` | Borrow the player's own Party / Status widget look; follows their settings live. Your other fields still override it. |
| `enemy` | `boolean` | Use a borrowed party look's enemy colours. |
| `style` | `string` | Treatment id, e.g. `"glossy"`, `"neon"`, `"lacquer"`, `"ascii-bar"` (see `getGaugeCatalog().styles`). |
| `gradient` | `string` | Gradient id, e.g. `"toxic-core"`, `"synthwave"`, `"vitals"` (see `getGaugeCatalog().gradients`). |
| `colorMode` | `"gradient" \| "threshold" \| "custom"` | `"threshold"` colours by value from a palette (`scheme`). |
| `scheme` | `string` | Palette id for `"threshold"`, e.g. `"verdigris"`, `"dracula"`. |
| `color` | `string` | One `"#rrggbb"` colour for a flat fill. |
| `height` | `number` | Bar height in px, 3–64. Default `14` (`12` with `look = "party"` or `"status"`). |
| `radius` | `number` | Corner radius in px, 0–12. |
| `overlay` | `"none" \| "gloss" \| "sheen" \| "inner" \| "bevel" \| "scan" \| "grain" \| "hatch" \| "edge"` | Surface finish. |
| `outer` | `"none" \| "drop" \| "lift" \| "halo" \| "ring" \| "inset"` | Outer treatment. |
| `track` | `"dark" \| "tint" \| "none"` | Paint of the empty part of the bar. |
| `danger` | `"glow" \| "ring" \| "pulse" \| "desat" \| "none"` | How a gradient bar announces a low value. |
| `dangerBelow` | `number` | Percent at or below which `danger` fires, 5–40. Default `20`. |
| `text` | `"overlay-mid" \| "overlay-end" \| "outside" \| "none"` | Where the readout goes (on bars under 9px it moves beside the bar). |
| `textColor` | `"outline" \| "outline-inv" \| "white" \| "black" \| "auto"` | Readout colour. |
| `textSize` | `number` | Readout size in px, 6–32. |
| `numbers` | `boolean` | Show `current/max`. Default `true`. |
| `percent` | `boolean` | Show the percentage. Default `false`. |
| `font` | `"fixedsys" \| "widget" \| "fira-code" \| "jetbrains-mono" \| "dejavu-sans-mono" \| "system" \| "sans"` | Readout typeface. |
| `ascii` | `string` | Character set for ASCII treatments: `"stars"`, `"hashes"`, `"blocks"`, `"halfmoon"`, `"pipes"`, `"equals"`, `"shade"`, `"dots"`, `"arrows"`, `"plus"`, `"caret"`, `"ticks"`. |
| `asciiCells` | `number` | Cells in an ASCII bar, 4–40. Default `10`. |
| `brackets` | `boolean` | Draw the ASCII set's brackets. Default `true`. |
| `animate` | `boolean` | Tween the fill on change. Default `true`. |
| `motion` | `boolean` | Allow looping animations. Default `true` (also off when the OS asks for reduced motion). |

Rules: give every gauge in a widget a distinct `id`; keep calling `setGauge`
rather than rebuilding `content` for value changes (a rebuild works — values are
remembered and re-applied — but it resets everything else in your widget).

### App window size — `getWindowSize()` + `windowResize` event

`getWindowSize()` returns `{ width, height }` — the MudForge client window
(viewport) size in CSS pixels, the same coordinate space widget positions and
sizes use. Pair it with the `windowResize` plugin event for dynamic layouts:

```lua
-- Initial placement relative to the window:
local size = getWindowSize()
local w = math.floor(size.width * 0.25)
local sidebar = createWidget({
  name     = "sidebar",
  position = { x = size.width - w, y = 20 },
  size     = { width = w, height = size.height - 40 },
})

-- Re-layout when the user resizes the app. Debounced: fires ONCE
-- ~150ms after the resize settles, so real layout work is safe here.
on("windowResize", function(event)
  local sidebarWidth = 240
  moveWidget(sidebar, event.width - sidebarWidth, 20)    -- the id createWidget returned, not the name
  resizeWidget(sidebar, sidebarWidth, event.height - 40)
end)
```

### `widgetInfo(widgetId, infoType) → any`

Returns metadata about one of **your own** widgets (any other id returns `nil` and warns).
`infoType` is an integer (MUSHclient-compatible). Most values are recorded when the widget is
created and are **not** updated by moves, drags or resizes — for the live size use
`getCanvasSize()`, for visibility `getWidgetProperty(id, "visible")`.

| infoType | Meaning |
|----------|---------|
| 1 / 2 | The top-level `x` / `y` given to `createWidget` (200 / 150 when you used `position`) |
| 3 / 4 | Current width / height |
| 5 / 6 | The top-level `width` / `height` given to `createWidget` (else 300 / 200) |
| 7 | `visible` as given at creation — not updated |
| 8 | Is minimized — always `false` |
| 9 | Z-order: 10 unless `zIndex` was given or `setWidgetZOrder` was called |
| 10 | Widget type string |
| 11 / 12 | Last mouse x / y (relative to widget) — tracked only while a mouse handler is registered |
| 13 | Mouse event counter — same condition |
| 14 | Last clicked button: 1 = left or middle, 2 = right — same condition |
| 15 / 16 | Same as 1 / 2 (not the live position) |
| 17 | Creation time (unix seconds) |
| 18 | Owning plugin id |
| 19 | Widget name/title |
| 20 | Widget id |
| 21 | Is canvas ready (bool) |

### Widget events

```lua
registerWidgetEvent(widgetId, eventType, callback)
unregisterWidgetEvent(widgetId, eventType, callback?)  -- omit callback to remove all handlers
```

`eventType` is one of: `"click"`, `"doubleclick"`, `"action"`, `"mousedown"`, `"mouseup"`,
`"mousemove"`, `"keydown"`, `"keyup"`, `"submit"`, `"resize"`, `"move"`, `"close"`, and for HTML
widgets `"luamsg"` (from `mudforge.send`), `"menuselect"` and `"menuclose"` (from
`mudforge.showMenu`).

`"close"` fires when the user dismisses the widget with its × button. That hides the widget
rather than destroying it, and the choice sticks: a plain `showWidget(id)` does not bring it
back (it warns), so re-open it with `showWidget(id, true)` only when the user asks. It does not
fire for your own `destroyWidget` or when the plugin unloads (use `cleanup` for that).

Event-data shape passed to the callback:

| Event | Shape |
|-------|-------|
| `click` / `doubleclick` / `mousedown` / `mouseup` | `{ x: number, y: number, button: number }` — `button` is 0 left, 1 middle, 2 right. HTML `click` adds `targetId`, `targetTag`, `targetText`, `targetValue`, `targetName`, `dataset`, `action`, `data`. |
| `mousemove` | `{ x: number, y: number, buttons: number }` |
| `keydown` / `keyup` | `{ key: string, code: string, mods, repeat: boolean }` (`repeat` on keydown only) |
| `action` | `{ action: string, data, dataset, targetId, targetText, button }` — from a `data-mud-action` element |
| `submit` | `{ formData: table }` |
| `resize` | `{ width: number, height: number }` — a canvas widget gets it whenever its drawing surface changes size (a player resize, a docked tile, a font change); any widget gets it when your plugin calls `resizeWidget`. An HTML widget gets player resizes only if it opts in — `createWidget({ type = "html", resizeEvents = true, ... })` or `setWidgetProperty(id, "resizeEvents", true)` — then once per animation frame with `source = "html-player-resize"`, never for the size it opened at, and not a second time for your own `resizeWidget`. Without the opt-in the HTML reflows by itself and nothing fires. Never answer a player resize with `resizeWidget` — a handler that keeps doing so is stopped and reported once. |
| `move` | `{ x: number, y: number, source: string? }` — once per finished player move (drag, maximize, restore) with `source = "player"` and the position it landed at; and when your plugin calls `moveWidget`. |
| `close` | `{}` |
| `luamsg` | `{ event, data }` |
| `menuselect` / `menuclose` | `{ id, value? }` / `{}` |

Mouse and key events also carry `shiftKey`, `ctrlKey`, `altKey` and `metaKey` (booleans).

Events are per world. With the same plugin open in several worlds, each world has its own
copy of the widget (the id is the same in every world), and an event reaches only the copy of
the plugin running in the world where it happened. Every event table also carries `sessionId`.

```lua
registerWidgetEvent(widgetId, "click", function(event)
  print(string.format("clicked at %d,%d (button %d)", event.x, event.y, event.button))
end)
```

### HTML widget JavaScript — `window.mudforge`

Every HTML widget's iframe gets a `window.mudforge` helper, bound to that widget
and the world it is in, and present from the first line of the widget's own
script. **Use it instead of `window.parent` / `window.frameElement`.**

| Call (widget JS) | What it does |
|------------------|--------------|
| `mudforge.send(event, data)` | Message the plugin. Arrives as a `luamsg` widget event with `{ event, data }`, in this widget's world only. `data` is copied as plain JSON-style values (no DOM nodes, no functions). Returns `false` for a missing event name or uncopyable data. |
| `mudforge.onMessage(fn)` | Receive `sendWidgetMessage(id, data)` from Lua. One receiver; a second call replaces it. |
| `mudforge.onProperty(name, fn)` | Receive `setWidgetProperty(id, name, value)` for a custom `name` as `fn(value, name)`. One receiver per name; any name except `"content"` (which replaces the whole document). |
| `mudforge.showMenu(items, event)` | App-level context menu, never clipped. Items: `{ type: "label", text }`, `{ type: "separator" }`, `{ type: "item", id, text, checked?, disabled? }`, `{ type: "color", id, text, value }`. `(items, clientX, clientY)` works too. The choice comes back as `menuselect` (`data.id`, plus `data.value` for colour items); `menuclose` fires if dismissed. |
| `mudforge.escapeHTML(text)` | Same escaping as Lua `escapeHTML`. Use before any `innerHTML`. |
| `mudforge.setAppearance({...})` / `mudforge.setBorder({...})` | Restyle this widget's frame. |

A mistake in these calls — `send` with no event name, uncopyable data, `showMenu` with a
non-array, `onProperty` with no name or for `"content"`, or an `onMessage`/`onProperty`
receiver that throws — prints a PLUGIN WARNING on this widget's world terminal, once per
widget and call. You don't need the browser console.

```lua
setWidgetProperty(w, "content", [[
<div id="list"></div>
<script>
  mudforge.onProperty("names", function (v) {
    var html = "";
    JSON.parse(v).forEach(function (n) { html += "<div>" + mudforge.escapeHTML(n) + "</div>"; });
    document.getElementById("list").innerHTML = html;
  });
  document.addEventListener("contextmenu", function (e) {
    e.preventDefault();
    mudforge.showMenu([{ type: "item", id: "clear", text: "Clear" }], e);
  });
  document.getElementById("list").onclick = function () { mudforge.send("clicked", { n: 1 }); };
  mudforge.send("ready", {});   // the receivers above are in place now
</script>
]])

registerWidgetEvent(w, "luamsg", function(m)
  if m.event == "ready" then
    setWidgetProperty(w, "names", json.encode({ "Bob", "Alice" }))
  elseif m.event == "clicked" then
    print("clicked", m.data.n)
  end
end)
registerWidgetEvent(w, "menuselect", function(d) print("picked " .. d.id) end)
```

**Wait for the widget before you talk to it.** The new content's script runs a moment after
`setWidgetProperty(w, "content", ...)` returns, and a property or `sendWidgetMessage` sent
before its `onProperty`/`onMessage` receiver exists is not kept for it. Have the widget send
a `"ready"` message, as above, and push the first data from that handler.

Everything the helper does stays in the widget's own world: a frame change from widget
JavaScript (`mudforge.setAppearance`, `mudforge.setBorder`, the `mudforge-appearance` meta tag)
restyles only this world's copy. Data a plugin sends in (`sendWidgetMessage`,
`setWidgetProperty`, `setBoundValue(s)`, `setGauge(s)`) reaches only the copy of the widget in
the plugin's own world, even though the widget id is the same in every world.

Still supported, for existing widgets: listening on `window.parent` for
`plugin-widget-property-change`, and dispatching your own CustomEvents (such as a
`plugin-widget-luamsg`, or a `plugin-widget-menu-request` with top-window
coordinates from `window.frameElement`) on `window.parent`. Don't write new code
that way: it depends on the widget being same-origin with the client, and an update or
restyle event a widget dispatches itself (such as `plugin-widget-appearance-change` or
`plugin-widget-message`) carries no world, so it still reaches the same widget id in every
world.

### Scrollbars in HTML widgets

When an HTML widget's content overflows (for example a grid with `overflow: auto`), the widget automatically gets the **same thin, themed scrollbar as the rest of the client** — a narrow lane with no track and a rounded thumb in the current theme's colours — and it follows theme changes live. You don't need to do anything.

To use your own look, or hide scrollbars, style them in the widget's own CSS. If your widget's markup mentions `scrollbar` anywhere (a stylesheet, an inline style, or a script), MudForge leaves that widget's scrollbars entirely to you:

```css
/* hide them */
#grid { scrollbar-width: none; }
#grid::-webkit-scrollbar { display: none; }

/* or a custom look */
#grid { scrollbar-width: thin; scrollbar-color: #8b5cf6 transparent; }
```

### Widget appearance & per-widget settings

`setWidgetAppearance(widgetId, settings)` sets **anything the widget's ⚙️ settings dialog can** — at runtime, in one flat call. It accepts appearance fields AND the per-widget font settings together (the two key-sets don't overlap). Omitted fields are left unchanged; pass `nil` to clear an *appearance* field back to the theme default. Untrusted input is sanitized (numbers clamped, enums whitelisted, image borders restricted to bundled preset names — a plugin can't point at the user's uploaded images). On the **map** widget, a background set this way shows around the rooms in place of the map palette's background; the rooms keep the palette's look.

```lua
setWidgetAppearance(myWidget, {
  -- chrome
  showTitleBar        = false,    -- hide the title bar
  autoHideSettingsCog = true,     -- the ⚙️ cog fades until hover (settings stay reachable)
  movable             = false,    -- lock position
  resizable           = false,    -- lock size
  -- fonts (per-widget)
  fontFamily          = "fira-code",
  fontSize            = 16,        -- clamped 6–96
  fontWeight          = "bold",    -- "normal"/"bold"/"100".."900"
  zIndex              = 20,        -- the widget's layer, 0–49 (same as setWidgetZOrder)
  -- colors / background / border
  titleTextColor      = "#e5e7eb",
  backgroundColor     = "#0b0f17",
  backgroundGradient  = "linear-gradient(135deg,#222,#000)",
  backgroundOpacity   = 0.8,       -- 0–1; dims the FILL only (content stays solid)
  borderColor = "#22d3ee", borderWidth = 3, borderRadius = 12,
  borderStyle = "dashed",          -- solid/dashed/dotted/double/none
  borderShadow = "0 0 12px 2px #22d3ee",
  borderGradient = "linear-gradient(135deg,#22d3ee,#a855f7)",
  borderAnimation = "pulse",       -- pulse/rotate/rainbow/marching-ants/none
  borderImagePreset = "neon-glow", -- neon-glow/steel-bevel/ornate-gold/pixel-frame
})

setWidgetAppearance(myWidget, { borderColor = nil })  -- clear one field (back to theme default)
```

**Field reference** (all optional; arguments are `widgetId: string`, `settings: table`):

| Field | Type | Notes |
|-------|------|-------|
| `showTitleBar` | `boolean` | Default `true`. `false` hides the title bar. |
| `autoHideSettingsCog` | `boolean` | Default `false`. `true` = the ⚙️ cog fades until hover. |
| `movable` | `boolean` | Default `true`. `false` locks position. |
| `resizable` | `boolean` | Default `true`. `false` locks size. |
| `fontFamily` | `string` | A bundled font key (e.g. `"fira-code"`) or `"system:<name>"`. |
| `fontSize` | `number` | Clamped 6–96. |
| `fontWeight` | `"normal"\|"bold"\|"100"\|"200"\|…\|"900"` | |
| `zIndex` | `number` | The widget's layer, 0–49 (higher draws on top; clamped). Same number as `setWidgetZOrder` and the ⚙️ Layer Order slider. |
| `titleTextColor` | `string` | CSS color. |
| `titleBackgroundColor` | `string` | CSS color. |
| `titleGradient` | `string` | CSS gradient. |
| `backgroundColor` | `string` | CSS color. |
| `backgroundGradient` | `string` | CSS gradient. |
| `backgroundOpacity` | `number` | 0–1; dims the FILL only (content stays solid). |
| `backgroundImageSize` | `"cover"\|"contain"\|"tile"` | The bg *image* itself can only be uploaded from the settings UI, not set by a plugin. |
| `borderColor` | `string` | CSS color. |
| `borderWidth` | `number` | px, clamped 0–32. |
| `borderRadius` | `number` | px, clamped 0–64. |
| `borderStyle` | `"solid"\|"dashed"\|"dotted"\|"double"\|"none"` | |
| `borderShadow` | `string` | CSS box-shadow. |
| `borderGradient` | `string` | CSS gradient painted as the border. |
| `borderAnimation` | `"pulse"\|"rotate"\|"rainbow"\|"marching-ants"\|"none"` | |
| `borderImagePreset` | `string` | One of `"neon-glow"`/`"steel-bevel"`/`"ornate-gold"`/`"pixel-frame"`. |

**At creation:** `createWidget{ ..., appearance = { showTitleBar = false, autoHideSettingsCog = true, ... } }` declares the same *appearance* fields as the widget's plugin-default (the user can still override them in the cog). Per-widget **fonts** are set via `setWidgetAppearance` after creation, not in the `appearance` table.

**True transparency:** a widget's frame is opaque by default (the theme background shows behind it). For a fully see-through widget (so the terminal/app behind it shows), pass `transparent = true` to `createWidget` (drops the frame fill *and* the backdrop blur), or set `appearance = { backgroundOpacity = 0 }`. `backgroundOpacity` between 0 and 1 gives a partly-translucent fill. (Canvas/HTML widget surfaces are already transparent — it was the frame fill that produced the "white background".)

### App theme

A plugin can switch the app's color theme (e.g. to match its MUD) **and define its own custom themes**. Applying a theme is a **real theme change**: it's applied, saved as the active selection, and immediately reflected in **Settings → Appearance** — exactly as if the user picked it there. To keep plugins from fighting the user, a `setTheme` call made from an **automatic lifecycle hook** (`init()`, `onEnable()`, `onConnect()`, …) counts as your plugin's *default* theme: it's honored the **first** time only, and after that the user's own selection survives reconnects (the call returns `false` and changes nothing). Calls made from an alias, trigger, or timer — i.e. driven by the user — always apply. A theme you *register* is persisted into the **app-wide theme library** so you can target it by id later. `getThemeList()` returns every valid id — built-in **and** custom.

```lua
-- 1) SELECT a known theme (built-in OR a custom one) — returns true if the id is valid.
setTheme("dracula")
local ids = getThemeList()   -- e.g. "forge" (the default), "dark", "nord", "gruvbox-dark-hard", plus any custom ids

-- 2) DEFINE a custom theme, then target it by id later.
registerTheme({
  id   = "my-mud",           -- optional; derived from `name` if omitted
  name = "My MUD",
  colors = {                 -- 19 shadcn keys, space-separated HSL ("H S% L%")
    background = "231 15% 18%",
    foreground = "0 0% 92%",
    primary    = "16 100% 55%",
    accent     = "16 100% 55%",
  },                         -- any omitted keys inherit from the Dark theme
  skin = "forge",            -- optional: the default theme's chassis, in your colours
})
setTheme("my-mud")

-- 3) Or define + apply in one call by passing a table to setTheme.
setTheme({ name = "Quick Blue", colors = { primary = "210 100% 60%" } })

-- Common pattern: suggest a theme for this MUD. onConnect is an automatic
-- hook, so this applies ONCE — if the user later picks a different theme,
-- their choice sticks across reconnects.
function onConnect(sessionId)
  setTheme("blood-soaked")
end

-- User-driven switching (an alias) always applies:
addAlias("theme_dark", "^theme dark$", function() setTheme("dark") end)
```

The full `colors` key set: `background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring`. Users can also create themes without a plugin via **Settings → Appearance → Theme → New**, which opens a full visual editor — a color picker for every interface element with live preview, optional terminal palette and glassmorphism controls, and JSON import/export. The **✏️ Edit** button beside a custom theme reopens it. Custom themes are app-wide and appear in the Theme dropdown. (A theme's terminal palette applies when the terminal is on its “default” background; an explicit terminal color scheme still takes precedence.)

**Themes vs. MUD branding — two different things.** A *theme* is app-wide and belongs to the user (or to a plugin acting on their behalf, as above). *MUD branding* is separate: a MUD can supply a logo, display name, and a single accent colour that dress the title bar, session tab, and panel headings for that session only, without touching the user's theme. Branding comes from the MUD's own listing, not from a plugin — there is no plugin API for it, and `setTheme` cannot reach it. Two consequences worth knowing when writing a plugin:

- **Branding is per session; themes are app-wide.** Someone playing two MUDs at once sees each MUD's branding on its own tab, but one shared theme throughout. If your plugin wants a look that follows the MUD, `setTheme` from `onConnect` is still the tool — just expect branding to sit alongside it.
- **The user can switch branding off** (Settings → Display → Appearance → Use MUD branding). Never write a plugin that assumes a MUD's accent colour is on screen; read your own colours from your widget settings instead.

**The default theme is Forge** (`"forge"`): the party and status widgets' own look — neutral near-black panels, white text, brass accents — carried through the whole client. It leaves the terminal alone: it has no `terminalColors`/`terminalBackground`, so the terminal keeps the classic palette on black (or whatever the player chose under Terminal Colors). A player who never picks a theme gets Forge (or the `"light"` built-in if they switched the bottom bar's sun/moon button to light mode). The previous default, plain neutral greys, is still available as `"dark"`.

**Where themes live.** Built-in themes (Forge, Light, Dark, the Gruvbox family, Nord, Dracula, the glass and High Contrast themes) are compiled in. Editor-created customs are stored app-wide in the browser (localStorage). There is also a **themes folder** that mirrors `libs`/`plugins`: curated themes ship as files under `public/themes/` (with a `manifest.json`) and load on web + desktop — currently Sweet, Tokyo Night, Catppuccin Mocha/Latte, Rosé Pine, One Dark, Solarized Dark, Everforest Dark, Monokai, Mars, Kanagawa Wave, Ayu Dark/Mirage, Palenight, Synthwave '84, Cobalt2, GitHub Dark, and Nightfox. On **desktop** there is additionally a writable `{appDataDir}/themes/` folder: drop a `.json` theme file in and it appears on next launch (a user file shadows a bundled one of the same id), and the editor's **To folder** button writes there. The theme JSON in a file is exactly the object shape documented above.

| Function | Args | Returns | Notes |
|----------|------|---------|-------|
| `setTheme` | `themeIdOrObject: string \| table` | `boolean` | String id → SELECT (built-in or custom). Table → DEFINE+register+apply. The change persists and shows in Settings → Appearance; from an automatic hook it applies once (the user's later choice wins), from an alias/trigger/timer it always applies. |
| `registerTheme` | `theme: table` | `string \| nil` | Define a custom theme WITHOUT applying it. Returns the resolved id (targetable via `setTheme`), or `nil` on failure. Upserts by id. |
| `getThemeList` | — | `string[]` | All valid theme ids (built-in + custom). |

#### Theme object reference (what to put in each field)

A theme object is what you pass to `registerTheme`/`setTheme`, and the exact same shape is what the visual editor's **Import** accepts as JSON. Fields:

| Field | Required | Format | Notes |
|-------|----------|--------|-------|
| `name` | yes | string | Display name. `id` is derived from it (kebab-case) if you omit `id`. |
| `id` | no | kebab string | Explicit id (upserts). Must NOT equal a built-in id (e.g. `"dracula"`, `"gruvbox-dark-hard"`) — those are reserved. |
| `colors` | yes | object of **HSL triplets** | **CRITICAL: each value is a space-separated `"H S% L%"` string — NOT hex.** e.g. `"195 6% 12%"` (hue 0–360, sat %, light %). Any of the 19 keys you omit inherit from the Dark theme. |
| `terminalBackground` | no | **hex** `"#rrggbb"` | Terminal background when this theme drives the terminal. |
| `terminalColors` | no | object of **hex** | The ANSI palette (hex, not HSL). Applies when the terminal is on its “default” background (an explicit terminal scheme still wins, and a user-built Custom Palette in Settings → Display → Appearance → Terminal Colors outranks both). |
| `glassmorphism` | no | object | Frosted-glass effects (see below). |
| `skin` | no | string | `"forge"` gives the theme the **Forge chassis** (see below). It is the only value; anything else is ignored and the theme renders without a skin. |

`colors` keys (all 19, HSL triplets): `background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring`.

`terminalColors` keys (all hex): `foreground, cursor, selectionBackground, black, red, green, yellow, blue, magenta, cyan, white, brightBlack, brightRed, brightGreen, brightYellow, brightBlue, brightMagenta, brightCyan, brightWhite`.

`skin = "forge"` restyles the client's *structure*, not just its colours: widget bodies sink into a recessed screen under a machined title strip, the top and bottom bars match, switches and sliders get knobs in your `primary` colour, the active tab is lit with it, and inputs and tab strips are recessed. Every shade it uses is worked out from your `colors` — chiefly `background`, `card`, `secondary`, `border`, `mutedForeground` and `primary` — so a teal `primary` gives teal knobs and a teal active tab. It is designed for dark palettes. Things the player customised themselves (a widget's own background, border or title colour, the App Background, MUD branding) are never overridden by it.

`glassmorphism` fields: `enabled` (bool), `blur` (e.g. `"16px"`), `cardOpacity` (0–1), `borderOpacity` (0–1), `shadowIntensity` (CSS shadow string, e.g. `"0 4px 30px rgba(0,0,0,0.5)"`), `radius` (e.g. `"16px"`), `glowColor` (hex, optional), `frostedHeader` (bool, optional).

**Complete worked example — Gruvbox Dark Hard** (these are the exact values of the built-in theme; note the `colors` are HSL triplets while `terminalColors` are hex). `gruvbox-dark-hard` already ships built-in, so to save your own copy give it a different `name`/`id`:

```lua
registerTheme({
  name = "My Gruvbox",           -- id "gruvbox-dark-hard" is a built-in, so use a new name
  colors = {
    background = "195 6% 12%",   foreground = "38 41% 71%",
    card = "0 0% 16%",           cardForeground = "38 41% 71%",
    popover = "0 0% 16%",        popoverForeground = "38 41% 71%",
    primary = "37 62% 59%",      primaryForeground = "195 6% 12%",
    secondary = "20 5% 22%",     secondaryForeground = "38 41% 71%",
    muted = "20 5% 22%",         mutedForeground = "28 11% 44%",
    accent = "20 5% 22%",        accentForeground = "38 41% 71%",
    destructive = "3 76% 65%",   destructiveForeground = "38 41% 71%",
    border = "22 7% 29%",        input = "20 5% 22%",   ring = "167 23% 59%",
  },
  terminalBackground = "#1d2021",
  terminalColors = {
    foreground = "#d4be98", cursor = "#d4be98", selectionBackground = "#504945",
    black = "#1d2021", red = "#ea6962", green = "#a9b665", yellow = "#d8a657",
    blue = "#7daea3", magenta = "#d3869b", cyan = "#89b482", white = "#d4be98",
    brightBlack = "#928374", brightRed = "#ea6962", brightGreen = "#a9b665", brightYellow = "#d8a657",
    brightBlue = "#7daea3", brightMagenta = "#d3869b", brightCyan = "#89b482", brightWhite = "#ddc7a1",
  },
})
```

The same object as JSON (paste into the editor's **Import**):

```json
{
  "name": "My Gruvbox",
  "colors": {
    "background": "195 6% 12%", "foreground": "38 41% 71%",
    "card": "0 0% 16%", "cardForeground": "38 41% 71%",
    "popover": "0 0% 16%", "popoverForeground": "38 41% 71%",
    "primary": "37 62% 59%", "primaryForeground": "195 6% 12%",
    "secondary": "20 5% 22%", "secondaryForeground": "38 41% 71%",
    "muted": "20 5% 22%", "mutedForeground": "28 11% 44%",
    "accent": "20 5% 22%", "accentForeground": "38 41% 71%",
    "destructive": "3 76% 65%", "destructiveForeground": "38 41% 71%",
    "border": "22 7% 29%", "input": "20 5% 22%", "ring": "167 23% 59%"
  },
  "terminalBackground": "#1d2021",
  "terminalColors": {
    "foreground": "#d4be98", "cursor": "#d4be98", "selectionBackground": "#504945",
    "black": "#1d2021", "red": "#ea6962", "green": "#a9b665", "yellow": "#d8a657",
    "blue": "#7daea3", "magenta": "#d3869b", "cyan": "#89b482", "white": "#d4be98",
    "brightBlack": "#928374", "brightRed": "#ea6962", "brightGreen": "#a9b665", "brightYellow": "#d8a657",
    "brightBlue": "#7daea3", "brightMagenta": "#d3869b", "brightCyan": "#89b482", "brightWhite": "#ddc7a1"
  }
}
```

---

## 5. Drawing API (next-gen, no widgetId argument)

**All shape colors are CSS color strings** (`"#ff8800"`, `"rgba(0,0,0,0.5)"`, `"red"`).
Origin is top-left; `y` grows downward. Angles are radians (`drawArc`, `rotate`).

### Shapes

```lua
drawRect(x, y, width, height, color, strokeColor?)
drawRoundedRect(x, y, width, height, radius, color, strokeColor?)
drawCircle(x, y, radius, color, strokeColor?)
drawEllipse(x, y, radiusX, radiusY, color, strokeColor?)
drawLine(x1, y1, x2, y2, color?, width?)                              -- color defaults to "#000000", width to 1
drawPolygon(points, color, strokeColor?)                              -- points = { {x=…, y=…}, {x=…, y=…}, … }
drawArc(x, y, radius, startAngle, endAngle, color, strokeColor?)      -- radians
drawBezier(x1, y1, cp1x, cp1y, cp2x, cp2y, x2, y2, color, width?)
drawPath(commands, color, strokeColor?)                               -- commands = array of SVG-style strings
drawGradient(x, y, width, height, direction, color1, color2)          -- direction: "horizontal" | "vertical" | "diagonal"
```

`drawPath` accepts a Lua array of strings, each an SVG path command (`"M 10 10"`, `"L 50 50"`, `"Q …"`, `"Z"`).

### Text

```lua
setFont(family: string, size: number, weight?: string)               -- weight: "normal" (default) | "bold" | "100".."900"
                                                                      --   affects drawTextWrapped ONLY (not drawText/measureText)
drawText(text: string, x: number, y: number, color: string, font?: string)
                                                                      -- font: CSS font string e.g. "16px monospace";
                                                                      --   omitted = the widget's own font (getWidgetFont)
drawTextWrapped(text: string, x: number, y: number, maxWidth: number, color: string, lineHeight?: number)
                                                                      -- font: the setFont font, else "14px Arial"; lineHeight default 16
drawColoredText(text: string, x: number, y: number, font?: string, defaultColor?: string)
                                                                      -- parses $-prefixed color codes inline (see §6);
                                                                      --   defaults "14px Arial", "#FFFFFF"
measureText(text: string, font?: string) → { width: number, height: number }
                                                                      -- font default "14px monospace" (ignores setFont);
                                                                      --   height = the font's px size
getFontMetrics(font?) → { ascent, descent, lineHeight, emWidth }
getTerminalFont() → { family, size, cssFont }                         -- matches the user's current terminal font
getWidgetFont(widgetId?) → { family, size, weight, css }              -- the font THIS widget is set to use
getWidgetSettings(widgetId?) → table | nil                           -- what the user SAVED in the widget's settings
```

#### Use the widget's own font — `getWidgetFont(widgetId?)`

A `drawText` with no `font` argument already uses the widget's own font, but a
hardcoded font string overrides it — then the widget's **Font Family** / **Font
Size** / **Font Weight** settings do nothing. `measureText` does not follow the
widget's font by itself (its default is `"14px monospace"`), so pass it the same
font you draw with. `getWidgetFont` is how you read what the user picked.

It always returns a complete font — `family` (the CSS stack), `size` (a number,
in pixels), `weight`, and `css` (ready to pass straight to `drawText` /
`measureText`) — falling back to the client default when the widget has no font
of its own, so there is nothing to check before using it. With no argument it
answers for your plugin's first widget.

```lua
local function draw()
  local font = getWidgetFont(myWidget)

  -- Measure with the SAME font you draw with; that is what keeps
  -- monospace art aligned.
  local charWidth = measureText("X", font.css).width

  drawText("Ready.", 10, 20, "#ffffff", font.css)

  -- Build a variant when you need one:
  drawText("Title", 10, 44, "#ffff00",
    "bold " .. (font.size + 4) .. "px " .. font.family)
end

-- The widget's resize event fires after the user picks a new font, and
-- after that font has finished loading, so a plugin that already redraws
-- on resize follows the font selector with no extra work.
registerWidgetEvent(myWidget, "resize", draw)
```

Fonts and canvas do not otherwise get along: a draw that happens before its font
has loaded silently falls back to another font and never repaints itself. Drawing
from the resize event — rather than only once at startup — is what avoids that.

#### Read the saved widget settings — `getWidgetSettings(widgetId?)`

`getWidgetFont` answers "what font should I draw with". `getWidgetSettings`
answers a different question: what the user actually saved in a widget's
⚙️ settings, in this world. With a widget id it returns that widget's saved
table (`fontFamily`, `fontSize`, `fontWeight`, and `appearance` when the look
was customised) or `nil` when nothing was ever saved for it. With no argument it
returns every widget's saved settings, keyed by widget id — an empty table when
nothing has been saved, and `nil` only when this world's settings cannot be read
at all yet (the world's window has not been set up, as for a plugin reading them
at load time before its world is on screen). Read them from `onConnect` or a later
event to be sure of an answer.

The table is a copy — changing it does not change the settings. A widget id
that no widget in this world has, and that nothing was ever saved for, prints a warning and
returns `nil` (settings saved for a widget that is not on screen right now are still returned); a real
widget that simply was never customised returns `nil` quietly. For drawing,
prefer `getWidgetFont`, which always answers with a complete font.

```lua
local saved = getWidgetSettings(myWidget)
if saved and saved.fontSize then
  print("You set this window to " .. saved.fontSize .. "px")
end
```

### Images

```lua
loadImage(imageId, url?)                                              -- one-time; survives clear()
drawImage(imageId, x, y, width?, height?, alpha?, angle?,
          sourceX?, sourceY?, sourceWidth?, sourceHeight?,
          centerX?, centerY?)
```

`alpha` ∈ [0, 1]. `angle` is radians. `sourceX..sourceHeight` clip a region of the source image. `centerX`/`centerY` set the rotation pivot.

- `url` is a path (`/images/x.png`), a URL, a data URI (PNG, JPEG, GIF, WebP, SVG), or raw SVG
  markup (`loadImage("dot", [[<svg viewBox="0 0 8 8">…</svg>]])`).
- A path or URL can be its own id: `loadImage("/images/x.png")` with one argument loads it under
  that name, and `drawImage("/images/x.png", x, y)` with no `loadImage` at all loads it on first
  use. A plain name (`"sword"`) is always an id, never a file.
- `imageId` is a string (a number also works and means the same as its string form).
- `loadImage` works before any widget exists — calling it in `init()` before `createWidget` is
  fine. Calling it again with the same id and source costs nothing (it does not re-fetch: to
  pick up a changed file, change the URL, e.g. `"/map.png?v=2"`); a new source keeps drawing
  the old image until the new one has loaded.
- Images load in the background, but you do **not** need to wait or redraw. A frame that draws
  an image still loading is held until the image arrives — up to one second from the first
  held draw — so `loadImage(...)` immediately followed by `drawImage(...)` shows the image,
  even if you draw only once (or twice in a row). If you are animating, a `clear()` on a
  later frame ends the wait instead of freezing the animation, and the image appears in the
  first frame you draw after it has loaded. An image that arrives after the wait ended triggers a `resize`
  event on the widget, so a plugin that redraws from its resize handler picks it up too.
- SVG may be written as-is. Raw `<svg>` markup, and any SVG data URI that would not load as
  written — an unencoded `#` colour, a missing `xmlns` or `xmlns:xlink` — is repaired, and if
  its root has no `width`/`height` it is sized from its `viewBox`. An SVG data URI that already
  loaded keeps loading the same way, size included, so a `viewBox`-only one keeps the browser's
  default 150×150: give the root `width`/`height`, or pass a size to `drawImage`. A `.svg` *file* loaded by path
  or URL is used exactly as served.
- Ids are per plugin. An id loaded while a widget was active belongs to that widget first, so
  two widgets can each have their own `"icon"` (kept if the widget is destroyed and created
  again); on any other widget the most recent load of that id is used.

### Canvas state

```lua
clear(color?)                          -- erase the active widget's canvas. NO color = TRANSPARENT (the widget's
                                       -- background/opacity shows through); pass a color to fill it opaque.
                                       -- Also clears any queued draw commands; state changes (transform, clip,
                                       -- alpha, blend mode, font) set before it still apply after it.
                                       -- The clear itself ignores the transform (the WHOLE canvas is wiped
                                       -- after translate/scale/rotate) and ignores globalAlpha for the fill,
                                       -- but respects a clip: inside setClipRegion only the clip is cleared.
-- State calls below take effect IN ORDER with your drawing calls: save(); translate(10,10);
-- drawRect(...); restore() draws the rect translated, and setFont() affects only drawTextWrapped calls after it.
save()
restore()
translate(x, y)
rotate(angle)                          -- radians
scale(x, y)
setClipRegion(x, y, width, height)     -- a save() plus a clip: clips nest by intersecting
resetClipRegion()                      -- a restore(): also undoes translate/scale/rotate/alpha/blend
                                       --   set AFTER the clip; with no clip set it pops your own save()
setBlendMode(mode)                     -- e.g. "multiply", "screen", "source-over"
setGlobalAlpha(alpha)                  -- 0..1
```

### Canvas info

```lua
getCanvasWidth()  → number             -- before the canvas has measured itself: the createWidget
getCanvasHeight() → number             --   size; with no size given, 400x300 and a warning
getCanvasSize()   → { width, height }
```

### Batching — you do not need to do anything

There is no `startBatch` / `endBatch`. There used to be, and they never batched
anything; they have been removed rather than left as a no-op.

Batching is automatic. Every `drawX` call is queued and the whole queue is
flushed once per animation frame, so a thousand draws in one frame already cost
one flush. Draw as much as you like in a single pass and let the runtime do it.

---

## 6. MUD I/O

```lua
send(command)                          -- handled as if typed: aliases, @variables, ";" stacking and # commands apply. If command starts with "#", only the active session dispatches it (avoids dupes in multi-session; elsewhere it warns). While disconnected nothing runs at all, not even an alias — one warning per disconnection.
echo(text, color?)                     -- one line in the terminal. color: a name ("green") or hex ("#ff6600", "#f60"); default "#ffffff";
                                       --   an unknown colour prints white and warns once. Inside a trigger callback it renders right after the matched line (§7).
print(message)                         -- ONE value, in the user's print colour (default "#00ff87"); extra arguments are dropped. Plain text only.
                                       --   nil prints "null" and a table "[object Object]" — build the string yourself (tostring / .. / tprint).
log(message, level?)                   -- level "info" (default) | "warn" | "error". Goes to the plugin editor's Console (and the browser
                                       --   console when plugin debugging is on) — NOT the terminal.
executeCommand(command)                -- run text through the command processor as if typed (aliases, @variables, # commands, plugin
                                       --   commands). A "#" command runs only from the world in front (elsewhere: a warning, once per
                                       --   plugin per world). Unlike send, it does not check the connection first.
utilprint(message)                     -- terminal output using the same print color. Unlike `print`, this interprets $-prefixed color codes (see below).
tprint(table, indent?)                 -- recursive table dump to terminal (debug aid)
hyperlink(text, action, opts?)         -- print a CLICKABLE link, ENDING the line (adds a newline). See "Clickable hyperlinks" below.
hyperlinkInline(text, action, opts?)   -- same, but NO newline — for links composed mid-line.
focusPrompt(text?)                     -- put keyboard focus back in the command input, optionally prefilling it. See "Returning focus to the command input" below.
```

### Clickable hyperlinks

`hyperlink` / `hyperlinkInline` print a clickable link to the terminal (and it's
also clickable in the chat widget). They're modeled on `utilprint`: the link
`text` honors the same `$`/`@` color codes. This is the MudForge equivalent of
MushClient's `Hyperlink`, but simpler — you don't pass separate colour/hint
args, you just colour the text with codes.

- **`text`** — the visible, clickable label (supports `$`/`@` color codes).
- **`action`** — what a click does, auto-detected:
  - a **command** (`"look"`, `"kill dragon"`) → **sent to the MUD**
  - an **http(s):// URL** → **opened in the browser**
- **`opts`** (optional table):
  - `prompt = true` → **prefill** the command into the input box instead of sending (great for `"say "`, `"tell bob "`)
  - `hint = "..."` → hover **tooltip**
  - `style = { ... }` → **style the link**: `color` / `bg` (any CSS color name,
    `#hex`, or `rgb(...)`), `bold`, `italic`, `underline` (`true` or `"wavy"` /
    `"dotted"` / `"dashed"` / `"double"`), `overline`, `strikethrough` — plus
    nested state tables `hover`, `active` and `visited` that restyle the link
    live as the player interacts with it (hover wins over visited, active wins
    over hover).
  - `menu = { ... }` → a **right-click menu**: a list of `{ ["Label"] = "send:command" }`
    entries (also `prompt:` or an http(s) URL), with `"-"` for a separator line.

A link's action or menu entry may be a client command (`"#all get all corpse"`,
`"#trigger {..} {..}"`): the client records the commands your plugin built links
for, per session, and only those run as client commands when clicked. A link that
arrives in the game's text — including raw OSC 8 escapes a plugin writes itself
with `print`/`echo` instead of `hyperlink()` — is refused (with a notice) if it
would run a `#` command, `disconnect`, a map-changing `mapper` command, a
`registerCommand` command or `/gmcp`/`/msdp`. Only a menu's commands (the values
of `{ ["Label"] = "send:command" }`) are remembered, never its labels. Map walks
follow the same rule: an exit the server sends over GMCP named like a client command is not stored (imported maps are kept as they are),
and a walk step that would run one stops the walk.
  - `title = "..."` → a non-clickable **header** above the menu entries (only
    shown when `menu` is present).
  - `id = "..."` → **group** several links: every link sharing the same `id`
    AND action highlights together on hover, as one link.

**Two variants, by newline behavior** (this is the only difference):
- `hyperlink(...)` — appends a newline, so the link is (or ends) its own line.
- `hyperlinkInline(...)` — no newline, so several pieces sit on one line.

```lua
-- Simplest: a clickable command
hyperlink("[look]", "look")

-- Colored + on its own line
hyperlink("$Y[Attack the dragon]$n", "kill dragon")

-- Prefill instead of send (note the trailing space in the action)
hyperlink("say something", "say ", { prompt = true })

-- Open a URL, with a tooltip
hyperlink("$Cthe wiki$n", "https://wiki.example.com", { hint = "Opens in your browser" })

-- Styled: teal, bold, turns gold while hovered
hyperlink("[the merchant]", "look merchant", {
  style = { color = "#4fd6be", bold = true, hover = { color = "gold" } },
})

-- A link with its own right-click menu (and a titled header)
hyperlink("[a goblin]", "look goblin", {
  title = "Goblin",
  menu = {
    { ["Attack"] = "send:kill goblin" },
    { ["Examine"] = "send:look goblin" },
    "-",
    { ["Flee"] = "send:flee" },
  },
})

-- Compose ONE line from several inline links (hyperlinkInline = no newline);
-- the final hyperlink() ends the line:
hyperlinkInline("north", "north")
hyperlinkInline("  ", "look")     -- spacer
hyperlink("south", "south")
-- renders:  north  south   (each direction clickable)
```

Tip: type `#testlinks` in the terminal for a live, clickable tour of everything
links can do (styles, states, menus, spoilers, selection groups, and more) —
useful as a visual reference while designing plugin output.

Clickability is automatic: these emit a standard OSC 8 hyperlink through the
same path as `utilprint`, which the terminal already renders as a clickable
link, and the chat widget parses the same escapes into clickable elements.
Links only fire for safe schemes (`send:`/`prompt:`/`command://`/`http(s)`/`ftp`);
anything else renders as plain, non-clickable text.

### Returning focus to the command input

`focusPrompt(text?)` is the widget-side counterpart to
`hyperlink(..., { prompt = true })`. That option prefills the input when a
**terminal link** is clicked; `focusPrompt` does the same thing from anywhere —
a widget button, a trigger, a timer.

Why you need it: clicking a button inside a widget moves keyboard focus into
that widget, so the next thing the player types goes nowhere until they click
the command line again. Calling `focusPrompt()` at the end of a button handler
hands focus straight back.

- **no argument** → take focus, leave whatever is already typed untouched.
- **`text`** → replace the input with `text` and put the caret at the end
  (a trailing space is usually what you want, so the player can keep typing).

It always targets the session the plugin is running in, so a plugin in one
session can never steal another session's input.

```lua
-- A widget button that sets up a command for the player to finish
registerWidgetEvent("mywidget", "action", function(d)
  if d.action == "tell" then
    focusPrompt("tell " .. d.data .. " ")   -- caret lands after the space
  end
end)

-- Hand focus back without changing what's typed
focusPrompt()
```

**On iPhone and iPad**, the text is filled in and the input is focused, but the
on-screen keyboard does not open by itself. iOS only raises the keyboard during
the tap that caused it, and a plugin callback runs after that tap has already
finished. A connected hardware keyboard is unaffected.

### Color codes

`utilprint`, `hyperlink`/`hyperlinkInline` labels, `drawColoredText`, `cecho` and `colorize` parse inline colour codes prefixed with `$`. The `@` form (`@R`) is NOT converted by any of these — it prints literally. (The chat and party/group widgets do read `@` codes in MUD-sent text.)

**Standard 16 colors** — note these are *MUD-specific hex values*, not the same as ANSI terminal colors:

| Code | Hex | Code | Hex |
|------|-----|------|-----|
| `$k` | `#000000` (black) | `$K` | `#808080` (bright black / grey) |
| `$r` | `#800000` (dim red / maroon) | `$R` | `#ff0000` (bright red) |
| `$g` | `#008000` (dim green) | `$G` | `#00ff00` (bright green) |
| `$y` | `#808000` (dim yellow / olive) | `$Y` | `#ffff00` (bright yellow) |
| `$b` | `#000080` (dim blue / navy) | `$B` | `#0000ff` (bright blue) |
| `$m` | `#800080` (dim magenta / purple) | `$M` | `#ff00ff` (bright magenta) |
| `$c` | `#008080` (dim cyan / teal) | `$C` | `#00ffff` (bright cyan) |
| `$w` | `#c0c0c0` (silver) | `$W` | `#ffffff` (white) |

**Extended codes:**

| Code | Effect |
|------|--------|
| `$x###` | xterm-256 foreground (1–3 decimal digits, e.g. `$x214` = orange). |
| `$X######` | 24-bit hex foreground (6 hex chars, no `#`, e.g. `$Xff8800`). |
| `$1X######` | 24-bit hex background (6 hex chars). Terminal output, `cecho`, `colorize(…, "terminal")` and `"strip"` only — `drawColoredText` and `colorize` segments do not recognise it (it shows as text). |
| `$n` or `$0` | Reset all attributes to default. |
| `$$` | *(not a special — `$` followed by an unrecognized code is emitted as literal text)* |
| `$x` with no digits | Not a code — printed literally. Use `$n` to reset. |

Unknown codes like `$z` are emitted as the literal two-character text `$z`. A trailing `$` with nothing after is emitted as `$`.

**Writing codes back out.** The table above is what the client *reads*. The user separately picks which dialect the client *writes* when they copy terminal text with its colours (Settings → Display → Appearance → Copying Colours): `$Xrrggbb`, `$xNNN`, `@Xrrggbb`, `@xNNN`, `{xNNN`, `{FNNN`, `@[FNNN]`, or raw ANSI escapes. Only the `$` forms round-trip through this client's own parser — the brace forms exist for MUDs whose servers parse them. A plugin that generates coloured text for the *user's own MUD* should emit whichever of these that MUD parses, which is not necessarily what MudForge renders.

### `colorize(text, format?)`

| `format` | Returns |
|----------|---------|
| `"canvas"` (default) / `"segments"` | Array of `{ text, ansiCode, hexColor }`. `ansiCode` is the ANSI escape (`"\27[0m"` after `$n`), or nil for uncoloured text; `hexColor` is `"#rrggbb"` for the 16 letter codes, `"#RRGGBB"` for `$X`, `"rgb(r, g, b)"` for `$x###`, or nil. |
| `"terminal"` | String with ANSI escape codes (`\x1b[38;2;R;G;Bm…`) for direct terminal write. |
| `"strip"` | Plain text with all `$`-prefixed codes removed. |
| `"ansi"` | Same as `"terminal"`. |

Any other format warns once and returns segments.

### ANSI helpers

```lua
parseAnsiText(text)   -- Array of { text, color, backgroundColor?, italic?, underline?, charCount }
                       -- Note: there is no `bold` field; bold renders as a brighter color (via the standard→bright lookup), not a flag.
stripAnsiCodes(text)  -- Plain text
```

### HTML escaping

```lua
escapeHTML(text)      -- & < > " ' → entities. nil → "", numbers/booleans like tostring.
                       -- A table or function returns "" and warns once.
                       -- (Widget JS mudforge.escapeHTML turns an object into "[object Object]".)
```

**Always escape server text before it goes into an HTML widget.** Player names,
room names, GMCP/MSDP values and trigger captures come from the MUD, and an HTML
widget's JavaScript runs with the client's own access. `escapeHTML` makes a value
safe in element content and quoted attributes; it does NOT make a URL safe
(`href`, `src`) or data inside `<script>` safe — use `json.encodeForScript` for
that. Widget JavaScript has the same function as `mudforge.escapeHTML(text)`.

```lua
-- WRONG: a name like <img src=x onerror=...> runs as code
html = '<span class="name">' .. member.name .. '</span>'
-- RIGHT
html = '<span class="name">' .. escapeHTML(member.name) .. '</span>'
-- Data for the widget's own script
html = '<script>var members = ' .. json.encodeForScript(members) .. ';</script>'
```

---

## 7. Triggers & aliases

### `addTrigger(pattern, callback, optionsOrIsRegex?) → triggerId`

> **THE FIRST CALLBACK ARGUMENT COUNTS FROM ZERO. EVERYTHING ELSE COUNTS FROM ONE.**
>
> This is the most common trigger-writing mistake there is, and it fails *quietly* —
> you get the wrong capture, not an error.
>
> ```lua
> -- pattern (\d+)/(\d+) on the line "Hp: 506/606"
> function(captures, line, wildcards)
>     captures[0]   --> "506"      FIRST group  (raw array, 0-based)
>     captures[1]   --> "606"      SECOND group  <-- the trap
>     wildcards[1]  --> "506"      FIRST group  (1-based — USE THIS)
>     wildcards[2]  --> "606"
>     wildcards[0]  --> "506/606"  the whole matched text
> end
> ```
>
> `wildcards` lines up with `%1` in a Send To: Script body and with
> `GetTriggerWildcard(name, n)`. `captures` is the raw match array and is the only
> 0-based reader in the API; it cannot be renumbered without breaking existing
> plugins. The plugin editor raises a **warning** when it sees `captures[1]`.

**Trigger engine (user setting).** Settings › Debug › Advanced › Trigger engine is *Fast & safe* (default, recommended) or *Classic* (a troubleshooting switch; a user's explicit Classic choice is kept). It covers triggers, aliases (`addAlias` and the user's own), sound triggers and highlights (`#highlight`/`#gag`/`#substitute`). Plugins need nothing: with Fast & safe a `"regex"`/`"multiline"` trigger (or alias) produces exactly the same matches, captures and named captures; a pattern that could backtrack catastrophically (e.g. `(\w+\s?)+$`) is simply checked in time linear in the line length instead of freezing the client. The one exception: a pattern with a backreference (`\1`-`\9`, `\k<name>`) has no linear-time algorithm in any engine, so it runs exactly as with Classic (native RegExp, first 32,000 characters) and is NOT freeze-protected. One deliberate difference otherwise: Classic checks only the first 32,000 characters of a line, Fast & safe matches the whole line.

**Match algorithm depends on the third argument.** Without it, the trigger uses `type = "substring"` — see the table below for what that actually does.

The third argument accepts two forms:

- **Boolean form (legacy):** `addTrigger(pattern, cb, true)` — switches the matcher to JavaScript regex. `false` or omitted = substring/wildcard (the default, NOT regex).
- **Options table form:** `addTrigger(pattern, cb, { ... })`:
  | Option | Type | Default | Effect |
  |--------|------|---------|--------|
  | `type` | `"substring" \| "wildcard" \| "regex" \| "multiline"` | `"substring"` | Match algorithm. `"substring"` is plain text — case-insensitive `indexOf` — **but** if the pattern contains `*` or `?`, it auto-upgrades to wildcard (`*` = match any chars, `?` = match any single char). `"regex"` is JavaScript regex. Lua patterns are NOT a trigger option. (`"multiline"` matches ONE regex across several lines — see "MUSHclient-style multi-line" below; it needs `multilineCount`.) Any other value is refused: `addTrigger` returns `""` with a warning. A pattern longer than 1024 characters cannot compile and is refused the same way. |
  | `enabled` | bool | `true` | Disable without removing. |
  | `priority` | number | `50` | Higher fires earlier. |
  | `oneShot` | bool | `false` | Auto-**disable** after the first match (the trigger stays in the list — re-arm with `enableTrigger(id)`; use `removeTrigger(id)` in the callback if you want it gone). |
  | `keepEvaluating` | bool | `true` | If false, stop processing later triggers on the same line. |
  | `omitFromOutput` | bool | `false` | "Gag" the matched line — hide it from the terminal. |
  | `caseSensitive` | bool | `false` | |
  | `matchRawText` | bool | `false` | Match against ANSI-included raw text instead of clean text. |
  | `group` | string | — | Group name for bulk enable/disable via `EnableTriggerGroup`. Case-sensitive. |
  | `sequence` | number | — | Tie-breaker when multiple triggers share priority. |
  | `sound` | string | — | Sound to play on match. Either `"sound:<file>"` or an `https://` URL. A `sound:` name resolves against the world's sound library first (added via Settings → Audio or a sound pack import), then — on desktop — the shared drop-in sounds folder. |
  | `colorize` | table | — | Recolor the matched line IN-PLACE: `{ foreground?, background?, italic?, underline? }`. See "Colorizing a line" below. |
  | `modifyOutput` | string | — | Replace the line text in the terminal with this string template; `$1`–`$9` are substituted with the capture groups. NOT a function. |
  | `name` | string | `"Trigger: <pattern>"` | A name you can address the trigger by. Required if you want to call `setTriggerStayOpen(name, n)` on it. |
  | `fireLength` | number | `0` | **Multi-line trigger.** After this trigger matches, keep firing its callback on the next N lines *without* the pattern having to match again. See "Multi-line triggers" below. |
  | `multilineCount` | number | — | With `type = "multiline"`: match the pattern against this many lines joined with `\n`. See "MUSHclient-style multi-line" below. |

Callback signature: `function(captures, line, wildcards, rawLine)`

You can name these arguments anything you like — they are ordinary function
parameters, and only the ORDER matters. The names below are just the clearest ones.

| Argument | What it is |
|----------|-----------|
| `captures` | The `(…)` groups from your pattern, **counted from 0**. |
| `line` | The text that matched (ANSI stripped, unless `matchRawText = true`). |
| `wildcards` | The same groups, **counted from 1**. Use this one. |
| `rawLine` | The original line with its ANSI colour codes still in it. |

You only have to declare the ones you use: `function(captures, line)` is fine if
you never touch the rest.

> **Which capture is which?**
> `wildcards[1]` is your first `(…)` group, `wildcards[2]` the second, and so on —
> counting from 1, the way Lua counts everything else. **Use `wildcards`.**
>
> `captures` holds exactly the same strings but counts from **0**, so
> `captures[0]` is the first group. Mixing the two up is silent — you get the
> wrong group rather than an error — so the simplest rule is to reach for
> `wildcards` and forget `captures` exists.
>
> Aliases are different again: an alias callback gets ONE table where `[1]` is the
> **whole matched command** and `[2]` is its first capture. See `addAlias` below.

**Callback return value — modify or delete the matched line programmatically.**
The callback's return value is a *line action*:

| You return | Effect on the matched line |
|------------|---------------------------|
| a string | The line is **replaced** with that string in the terminal (ANSI escapes welcome — build any coloring you want) |
| `false` | The line is **deleted** (gagged), same as `omitFromOutput` but decided at match time |
| `nil` / nothing | Line displays unchanged |

This is the dynamic counterpart to the static `modifyOutput`/`colorize`/
`omitFromOutput` options: use the options when the rewrite is fixed, return a
value when you need to compute it from the captures or plugin state. A returned
string wins over `modifyOutput`/`colorize` (the callback runs last).

### Multi-line triggers (`fireLength` + `setTriggerStayOpen`)

Some MUD output only makes sense as a block: a header line followed by detail
lines. A normal trigger sees one line at a time and cannot reach the rest.

A trigger created with `fireLength = N` keeps firing for the next **N lines
after it matches**, whether or not those lines match its pattern. Inside the
callback you can rewrite that countdown at any time:

```lua
setTriggerStayOpen(name, n)   -- fire on n MORE lines; 0 closes immediately
getTriggerStayOpen(name)      -- lines remaining, 0 if closed
```

`name` is the trigger's `name` option (or the id `addTrigger` returned). Pass
`1` on every line while more of the block is still coming and `0` on the last
line, and one trigger reads a block of **any** length.

On a continuation line — one that fired because the gate was open rather than
because the pattern matched — the whole line is `line` (also `captures[0]` and `wildcards[1]`), so you can
re-match it by hand.

```lua
-- Three-line buff report:
--   [Buff Info] ON  shield of faith applied to a small kobold
--     time: 12
--     affect: +20 armour
local buff = {}

addTrigger("^\\[Buff Info\\]", function(captures, line)
  if line:find(" applied to ") then
    buff = {}
    setTriggerStayOpen("BUFF MGMT", 1)          -- more is coming
  elseif line:match("^  time: (.+)$") then
    buff.time = line:match("^  time: (.+)$")
    setTriggerStayOpen("BUFF MGMT", 1)          -- still more
  elseif line:match("^  affect: (.+)$") then
    buff.affect = line:match("^  affect: (.+)$")
    setTriggerStayOpen("BUFF MGMT", 0)          -- last line — close the gate
  end
end, { type = "regex", name = "BUFF MGMT", fireLength = 1 })
```

Gates are per session, and close automatically if the trigger is removed or
disabled.

**This works for your own triggers too.** A trigger created in
Settings → Triggers has an **Extra lines** field — the same `fireLength` — and
its Lua script can call `setTriggerStayOpen("<that trigger's name>", n)`. Name
lookup checks the calling plugin's triggers first and then the session's own
triggers, so a script addresses a trigger by name without caring which of the
two it lives in. Plugin and user triggers keep independent gates even if they
share a name.

### The line cursor — editing lines you have already seen

Reading a block is half the job; the other half is collapsing it, which means
deleting the detail lines and folding their contents onto the header. These
Mudlet functions do that:

| Function | Effect |
|----------|--------|
| `getLineNumber()` | Number of the line at the cursor. Inside a trigger this is the line being processed, so `getLineNumber() - 1` is the line above it. |
| `getLastLineNumber()` | Highest line number you can address. |
| `moveCursor(column, line)` | Move the cursor to a line. Returns `false` if out of range. `column` is accepted for Mudlet compatibility but ignored — MudForge addresses whole lines. |
| `getCurrentLine()` | Text at the cursor, ANSI stripped (so `#getCurrentLine()` measures what you see). |
| `getLines(from, to)` | Table of the editable lines, oldest first. |
| `deleteLine()` | Remove the line at the cursor. Later lines shift up, so the cursor keeps addressing the same position. |
| `replaceLine(text)` | Replace the text of the line at the cursor. |
| `cecho(text)` | Append text to the line at the cursor, with `<colour>` tags (below). Outside trigger processing it writes its own line instead. |
| `insertText(text)` | Same, without tag parsing. |

```lua
-- ... continuing the affect branch above: collapse three lines into one
deleteLine()                              -- drop "  affect: ..."
moveCursor(0, getLineNumber() - 1)
deleteLine()                              -- drop "  time: ..."
moveCursor(0, getLineNumber() - 1)        -- now on the [Buff Info] header

local header = getCurrentLine()
cecho(string.rep(" ", math.max(0, 70 - #header)))
cecho(string.format(" <cyan>%-5s <orange>%s<reset>", buff.time, buff.affect))
```

**What the cursor can reach.** MudForge renders into a terminal that cannot
un-write text, so the cursor addresses output that has been assembled but not
yet displayed — the current network packet, plus everything held back while a
multi-line gate is open. In practice that means: **while your gate is open, every
line of your block stays editable.** Once the gate closes the lines are written
and can no longer be changed. Without a gate, a line can only be edited while
its own packet is being processed, and a MUD may send one paragraph in more than
one packet — so to edit the lines above, keep a gate open over the whole block.
Two safety limits release the hold early rather
than let output stall — 200 lines, or 250 ms of server silence — so a gate you
forget to close costs you the collapsing, never the output.

### `cecho` colour markup — both syntaxes

`cecho` understands **MudForge's `$` codes and Mudlet's `<tags>`**, and you can
mix them in one call. Use whichever you prefer; the tags exist so scripts ported
from Mudlet run unchanged.

**MudForge `$` codes** — the same codes every other output function here speaks:

| Code | Effect |
|------|--------|
| `$r` `$g` `$y` `$b` `$m` `$c` `$w` `$k` | Foreground: red, green, yellow, blue, magenta, cyan, white, black |
| `$R` `$G` `$Y` `$B` `$M` `$C` `$W` `$K` | The bright versions of the same |
| `$xNNN` | Foreground from the 256-colour palette (`NNN` = 0-255) |
| `$XRRGGBB` | Foreground, 24-bit hex |
| `$1XRRGGBB` | **Background**, 24-bit hex |
| `$n` (or `$0`) | Reset all colour |

**Mudlet `<tags>`** — `<colour>`, `<foreground:background>`, `<:background>`, and
`<reset>`. Colours may be names (`red`, `orange`, `gold`, `cyan`, `lightblue`, …),
`#rrggbb`, `#rgb`, or `r,g,b`. `<b> <i> <u> <s>` toggle bold, italic, underline
and strikethrough, with `</b>` etc. to turn them off. Named colours render as
24-bit truecolor, so `<orange>` really is orange rather than being flattened to
yellow. Anything that is not a recognised tag is printed literally, so a typo
shows up instead of vanishing.

```lua
cecho("$Rdanger$n and $Gsafety$n")                 -- $ codes
cecho("<red>danger<reset> and <green>safety<reset>")  -- tags
cecho("$XffffffWhite on $1X202020dark$n")             -- 24-bit fg + bg
cecho("<green>tagged$n and $Rdollar")                 -- mixed, and fine
```

The two syntaxes are disjoint — a `$` code contains no angle brackets and a tag
contains no `$` — so mixing them is well defined rather than merely tolerated.

### Two kinds of multi-line trigger

MudForge supports both of the multi-line designs the major clients use, because
they solve different problems. Pick by asking *"do I know the shape of the block
in advance?"*

| | **MUSHclient style** (`type = "multiline"`) | **Mudlet style** (`fireLength`) |
|---|---|---|
| How it matches | ONE regex against N lines joined with `\n` | Pattern matches the first line; the callback then fires once per following line |
| Captures | Span the whole block | Per line |
| Block length | Fixed, known up front | Any length — the script decides when to stop |
| Script needed | No — captures come out of one match | Yes — the script assembles the block |
| Best for | A fixed report format | A list that ends with a blank line or prompt |

#### MUSHclient-style multi-line

Set `type = "multiline"` and `multilineCount = N`. The pattern is matched against
the last N lines joined with newlines, and fires on the line that **completes**
the block:

```lua
-- You see: a rusty sword
-- Weight: 12
-- Value: 300
addTrigger(
  "^You see: (.+)$\n^Weight: (\\d+)$\n^Value: (\\d+)$",
  function(captures, line, wildcards)
    -- wildcards counts from 1, so wildcards[1] is the FIRST capture.
    echo(string.format("%s - %s lb, %s gold",
      wildcards[1], wildcards[2], wildcards[3]))
  end,
  { type = "multiline", multilineCount = 3, omitFromOutput = true }
)
```

Things worth knowing:

- **`^` and `$` anchor at every line boundary** inside the block, so you can
  write one anchored line per line of the block. (JavaScript regex has no inline
  `(?m)`, so this is always on. Patterns that spell out `\n` explicitly behave
  the same either way.)
- **`.` never crosses a line break.** A greedy `(.+)` stops at the newline rather
  than swallowing the rest of the block.
- **It will not fire on a partial block.** A 3-line trigger stays silent until
  three lines have arrived, so an anchored pattern can never match a block that
  is missing its beginning.
- **It matches across packet boundaries.** The window is independent of how the
  server chunks its output.
- **Gagging or replacing affects the WHOLE block.** `omitFromOutput` hides all N
  lines, and a callback returning a string collapses all N into that one line —
  not just the last one.
- **`multilineCount` of 0 or 1 means "not multi-line"**, which is why an imported
  MUSHclient trigger with `lines_to_match="1"` behaves as an ordinary trigger.

One cost to be aware of: a multi-line trigger that **changes the display** (gags,
replaces, colorizes) has to reach back over the lines before the one it fired on,
so those N-1 lines are held briefly instead of being drawn immediately. Output
therefore trails by N-1 lines while such a trigger exists, and flushes anyway
after 250 ms of server silence. A multi-line trigger that only *captures* data
holds nothing back.

Imported MUSHclient worlds get this automatically: `lines_to_match` is read from
the `.mcl` file and written back on export.

#### A complete example of both

This is a whole working plugin. Each half is independent — take either one.

```lua
plugin = {
  name        = "Multi-line Examples",
  author      = "MudForge",
  version     = "1.0",
  description = "Worked examples of both multi-line trigger styles",
}

-- =========================================================================
--  STYLE 1 - "Lines to match": the block always has the SAME SHAPE.
-- =========================================================================
--  The MUD always prints exactly these three lines together:
--
--      You see: a rusty sword
--      Weight: 12
--      Value: 300
--
--  One regex describes all three. Nothing to remember between lines: the
--  trigger fires ONCE, on the line that completes the block, and every
--  capture arrives together.

addTrigger(
  -- One line of pattern per line of the block, joined by \n.
  -- ^ and $ anchor at each line break, so it reads top to bottom.
  "^You see: (.+)$\n^Weight: (\\d+)$\n^Value: (\\d+)$",

  -- Your callback can name its arguments anything. These are the three you
  -- get, in this order:
  --   captures  - the (...) groups, counted from ZERO (captures[1] is the SECOND!)
  --   line      - the text that matched
  --   wildcards - the same groups, counted from ONE  <-- use this one
  function(captures, line, wildcards)
    echo(string.format("%s  -  %s lb, %s gold",
      wildcards[1],   -- a rusty sword
      wildcards[2],   -- 12
      wildcards[3]))  -- 300
  end,

  {
    type           = "multiline",
    multilineCount = 3,      -- "Lines to match" in Settings > Triggers
    omitFromOutput = true,   -- hides ALL THREE original lines
  }
)

-- =========================================================================
--  STYLE 2 - "Extra lines": the block's LENGTH IS UNKNOWN.
-- =========================================================================
--  A buff cast on a mob is reported over three lines...
--
--      [Buff Info] ON  shield of faith applied to a small kobold
--        time: 12
--        affect: +20 armour
--
--  ...but a buff on yourself is reported on one. A fixed "Lines to match"
--  cannot cope with that, so the trigger stays OPEN and the script decides
--  when the block has ended.

buff = {}

addTrigger(
  "^\\[Buff Info\\]",          -- matches only the FIRST line of a block

  -- This one only needs the line text, so it ignores the other arguments.
  function(captures, line)
    if string.find(line, " applied to ") then
      -- First line: start a fresh block and expect more.
      buff = {}
      setTriggerStayOpen("BUFF", 1)

    elseif string.match(line, "^  time: (.+)$") then
      buff.time = string.match(line, "^  time: (.+)$")
      setTriggerStayOpen("BUFF", 1)        -- still more to come

    elseif string.match(line, "^  affect: (.+)$") then
      buff.affect = string.match(line, "^  affect: (.+)$")

      -- LAST line: fold all three lines into one.
      deleteLine()                         -- drop "  affect: ..."
      moveCursor(0, getLineNumber() - 1)
      deleteLine()                         -- drop "  time: ..."
      moveCursor(0, getLineNumber() - 1)   -- now on the "[Buff Info]" header

      -- Pad out to column 60, then append the details to the header.
      local header = getCurrentLine()
      local pad = 60 - string.len(header)
      if pad > 0 then cecho(string.rep(" ", pad)) end
      cecho(string.format(" $C%s $Y%s$n", buff.time, buff.affect))

      setTriggerStayOpen("BUFF", 0)        -- block finished, close the gate
    end
  end,

  {
    type       = "regex",
    name       = "BUFF",     -- setTriggerStayOpen addresses it BY NAME
    fireLength = 1,          -- "Extra lines" in Settings > Triggers
  }
)

function init()
end

function cleanup()
end
```

What to notice:

- **Style 1 has no state.** The three captures arrive together, once. That is the
  whole reason to prefer it when the block's shape is fixed.
- **Style 2 has state** (`buff`) and a decision on every line, which is the price
  of handling a block whose length you do not know until you see the end of it.
- **`setTriggerStayOpen` takes the trigger's `name`**, so a multi-line trigger of
  this kind needs one.
- **`w[1]` not `c[1]`** for the first capture — see the callback signature above.
- **The line cursor only appears in Style 2**, because only Style 2 needs it:
  Style 1's `omitFromOutput` already hides the whole block by itself.

```lua
-- Compute a rewrite from state: show damage as a percentage of max HP
-- (wildcards counts from 1, so wildcards[1] is the first capture group)
addTrigger("^You take (\\d+) damage", function(captures, line, wildcards)
  local pct = math.floor(tonumber(wildcards[1]) / getVariable("maxhp") * 100)
  return line .. " \27[91m(" .. pct .. "% of your HP!)\27[0m"
end, { type = "regex" })

-- Conditionally delete: gag guild chatter only while AFK
addTrigger("^\\[Guild\\]", function()
  if getVariable("afk") == "yes" then return false end
end, { type = "regex" })
```

```lua
-- Substring (default): matches any line containing the literal text "You gain"
addTrigger("You gain", function() echo("(gained something)") end)

-- Wildcard: * matches any chars, ? matches a single char.
-- Captures fill wildcards[1], wildcards[2], ... (captures[0], captures[1], ... counting from 0)
addTrigger("You gain * experience points", function(captures, line, wildcards)
  echo("+" .. wildcards[1] .. " XP!", "#88ff88")
end)

-- Regex (JavaScript flavor — \d \s \w, NOT %d %s %w):
addTrigger("^You gain (\\d+) experience", function(captures, line, wildcards)
  echo("+" .. wildcards[1] .. " XP!", "#88ff88")
end, true)

-- Regex with full options table:
addTrigger("^You die$", function() send("rez me please") end,
  { type = "regex", oneShot = true, priority = 100, group = "combat" })
```

#### Performance — thousands of triggers are fine

Trigger matching is built to scale to very large trigger sets (10,000+). Every
incoming line is run through a **literal candidate index** (an Aho-Corasick
automaton): in a single pass over the line the client finds exactly which
triggers' literal text is present, and only those are actually evaluated. A line
that contains none of your triggers' literals costs one automaton pass, not one
test per trigger — so a giant list of item-name or keyword triggers does **not**
slow the client down line-by-line.

What this means for how you author triggers:

- **A `type = "regex"` pattern with no regex metacharacters is auto-detected as
  a literal** and gets the same fast treatment as a substring trigger (and is
  eligible for backend offload). So `addTrigger("an opal shield", cb, { type = "regex" })`
  is just as fast as the substring form — you are **not** penalized for a list
  of literal item names written as regexes.
- **Substring and wildcard triggers** are indexed by their literal text (for a
  wildcard, the longest literal run between `*`/`?`). Keep at least a couple of
  literal characters in the pattern so it can be indexed.
- **Only "unavoidable" patterns run on every line:** true regexes (with
  metacharacters), `matchRawText` triggers, and `expandVariables` triggers.
  These are still correct and fast, but they can't be pruned by literal — favor
  a literal or wildcard pattern when the match really is just fixed text.

#### Colorizing a line (the right way — `colorize`, not `echo`)

To recolor a matched line, use the `colorize` option. It rewrites the line
**in place** — the original line is displayed with your colors, in its original
position in the output.

```lua
-- Recolor any line containing "tells you" bright yellow:
addTrigger("tells you", nil, {
  colorize = { foreground = "brightyellow" }
})

-- Red background + underline for death messages (regex match):
addTrigger("^You are DEAD", nil, {
  type = "regex",
  colorize = { foreground = "white", background = "red", underline = true }
})

-- Colorize AND still run a callback (both options work together —
-- `sound` plays a file on match, no callback code needed for that.
-- "sound:NAME" refers to the world's sound library; an https:// URL also works.
-- There are no sounds bundled with the client, so a bare path like
-- "/sounds/alert.mp3" will not resolve — add the audio to the world first.):
addTrigger("^(\\w+) has arrived", function(captures, line, wildcards)
  setVariable("last_arrival", wildcards[1])
end, { type = "regex", colorize = { foreground = "brightcyan" }, sound = "sound:alert.mp3" })

-- Rewrite the line entirely (string template, $1..$9 = captures):
addTrigger("^You gain (\\d+) experience", nil, {
  type = "regex",
  modifyOutput = ">>> XP +$1 <<<"
})

-- Gag the original and show nothing (classic spam filter):
addTrigger("The rain continues to fall", nil, { omitFromOutput = true })
```

`colorize` fields: `foreground` / `background` accept the 16 ANSI color names
(`"red"`, `"brightyellow"`, …) — unknown values fall back to white; `italic`
and `underline` are booleans. Bold is deliberately NOT supported (MUDs use SGR
bold to mean "bright color", so trigger-bold would corrupt server colors —
use a `bright*` foreground instead).

**`echo()` inside a trigger callback is in-place.** Output APIs called while a
trigger callback is running (`echo`, `print`, `colourNote`, `hyperlink`) are
spliced into the server output **directly after the matched line** — not
appended to the end of the packet. On a 5-line server message with a trigger
on line 3, your echo renders between lines 3 and 4. If the trigger also gags
the line (`omitFromOutput`, or the callback returns `false`), the echoed text
takes the line's position — so gag-and-reprint works, though returning a
replacement string from the callback is simpler and preserves the line as a
single unit. Note the splice only applies during trigger processing; an echo
from a timer or widget event still appends at the current end of output.

### Prompt lines and triggers

Prompt lines are full trigger-processable lines:

- On servers that mark prompts with **GA/EOR** (RFC 854/885), the prompt has
  always closed as a normal line — triggers, gags, and colorize all apply.
- On servers that send **no prompt marker at all**, a partial line that stays
  quiet for ~300ms now fires triggers PROVISIONALLY (same detection window
  Mudlet uses — but unlike Mudlet, the prompt itself DISPLAYS at ~50ms) (it displays immediately
  regardless). Provisional semantics: trigger callbacks/actions run normally
  (`send()`, `echo()`, variables, sounds), but line REWRITES (gag /
  `modifyOutput` / colorize / callback return values) don't apply — the line
  is technically still open. If the line later closes with unchanged text,
  triggers do NOT fire a second time; if the server continued the line after
  the quiet period (rare), the full line is processed normally and a pattern
  that already matched the shorter prefix may fire again.

### Trigger management

```lua
removeTrigger(triggerId)
enableTrigger(triggerId)            -- enable a trigger you created, by ID
disableTrigger(triggerId)           -- disable without removing

-- Mudlet compatibility aliases (thin wrappers; ported scripts run as-is):
tempTrigger(substring, callback) → id       -- = addTrigger(substring, callback)
tempRegexTrigger(regex, callback) → id      -- = addTrigger(regex, callback, { type = "regex" })
killTrigger(id)                             -- = removeTrigger(id)
-- MudForge plugin triggers are already "temporary" in the Mudlet sense:
-- runtime-only, gone at plugin unload/reload, never saved to the world file.
-- The callback must be a FUNCTION: a string of Lua (the Mudlet habit) is refused with a warning.
-- More Mudlet functions (events, tempTimer, permAlias, exists, decho/hecho): see §15.6.

-- MUSHclient-style (look up by NAME assigned at creation, returns bool success):
EnableTrigger(name, enabled?)        -- enable/disable a NAMED trigger (defaults to enabled=true)
EnableTriggerGroup(group, enabled?)  -- enable/disable every trigger in a group (= enableTriggerGroup)
EnableAlias(name, enabled?)          -- a Settings alias, case-sensitive name (= enableAlias);
                                     --   no Settings match → your plugin's own named aliases
EnableTimer(name, enabled?)          -- a Settings timer, any case (= enableTimer) — see §8

-- Settings > Triggers only (never plugin triggers):
findTriggerByName(name: string) → { id, name, enabled } | nil
toggleTriggerByName(name: string, enabled: boolean) → boolean
toggleTriggerGroup(group: string, enabled: boolean) → boolean   -- ALWAYS pass enabled: omitted = OFF

-- Inside a TRIGGER SCRIPT (Send to: Script), read the wildcards of the match
-- that fired. Not available in plugin code — use the callback's wildcards there.
GetTriggerWildcard(triggerName, which)  -- `which` is a NAME for a named group,
                                        -- or a NUMBER: 0 = the whole matched
                                        -- text, 1..n = positional captures
```

**MUSHclient names for functions this client already has.** A ported script usually fails on a *name*, not a capability. These spellings now work and delegate to exactly the same implementation as the native ones:

| MUSHclient | does the same as |
|---|---|
| `GetPluginID()` / `GetPluginName()` / `GetPluginInfo()` | `getPluginId()` / `getPluginName()` / `getPluginInfo()` |
| `DeleteTrigger(id)` / `DeleteAlias(id)` / `DeleteTimer(id)` | `removeTrigger(id)` / `removeAlias(id)` / `removeTimer(id)` |
| `GetVariableList()` | `getAllVariables()` |
| `Hyperlink(action, text, hint?)` | `hyperlink(text, action, { hint })` |

Already supported before this: `Send`, `Execute`, `Note`, `ColourNote`/`ColorNote`, `SetVariable`, `GetVariable`, `DeleteVariable`, `EnableTrigger`, `EnableTriggerGroup`, `EnableAlias`, `EnableTimer`, `DoAfter`, `DoAfterSpecial`, `GetPluginVariable`, `GetPluginVariableList`, `SaveState`, `PlaySound`, `StopSound`, `GetSoundStatus`, `Sound`.

`AddAlias`, `AddTimer` and `AddTriggerEx` are **present but refuse**, naming what to use instead — their arguments differ from ours, so aliasing them would give you a function that accepts the call and does something else.

**Named wildcards, and patterns ported from MUSHclient.** MUSHclient and Mudlet are built on PCRE, where a named capture group is written `(?P<name>...)`. JavaScript spells the same thing `(?<name>...)`. **You can write either** — the PCRE form is translated for you, along with `(?P=name)` backreferences — so a trigger set brought over from another client works unchanged:

```lua
-- Both of these are accepted and behave identically:
--   ^Route \(.* step(s|)\)\: (?P<dirs>.*)$      -- MUSHclient / PCRE spelling
--   ^Route \(.* step(s|)\)\: (?<dirs>.*)$       -- JavaScript spelling

-- and the script reads the group by name:
local dirs = GetTriggerWildcard("gps_walk", "dirs")
Execute("#" .. dirs)
EnableTrigger("gps_walk", false)
```

Also translated: the inline flags `(?i)`, `(?s)` and `(?m)` — they apply to the whole pattern wherever they are written, and `(?i)` wins over the trigger's own case-sensitivity setting — and comment groups `(?#...)`, which are removed. Scoped flags — `(?i:...)` makes just that part of the pattern ignore case, and `(?-i:...)`, `(?s:...)` and `(?m:...)` work the same way — work on every device: current browsers understand them as written, and on an older one (an iPhone, iPad or Mac that has not been updated) or one whose own handling of them is faulty, the pattern is rewritten into an equivalent one, so the trigger matches exactly the same lines everywhere; the one form that cannot be rewritten there is a back-reference such as `\1` inside a part whose case rule differs from the rest, which the trigger editor reports. What is **not** translated, because there is no JavaScript equivalent: extended mode `(?x)`, possessive quantifiers such as `a++`, atomic groups `(?>...)` and `\p` properties; the trigger editor and the terminal say so rather than guess. Aliases imported from MUSHclient get the same translation, scoped flags included; aliases you write here are used exactly as written. A pattern that cannot be compiled is reported **once**, in the terminal of the world the trigger runs in, naming the trigger and what is wrong with it, and that trigger simply never fires; it does not stop your other triggers from working.

`EnableTrigger` and `EnableTriggerGroup` search **both** places a trigger can live:

- triggers created in Settings > Triggers, including ones brought in by a world-file or
  MUSHclient `.mcl` import — for a group these match on the trigger's **Group** field;
- triggers this or any other loaded plugin registered with `addTrigger` in the same session —
  for a group these match on the `group` option passed to `addTrigger`.

Group names are matched exactly and are **case-sensitive**: `EnableTriggerGroup("Slash")` will
not touch a group named `slash`. Both return `true` when at least one trigger changed. When a
call matches nothing it returns `false` **and** writes a warning to the terminal naming the
group or trigger it could not find, so a typo shows up instead of failing silently.

Omitting the second argument enables — it does not toggle.

(`findTriggerByName` / `toggleTriggerByName` are available too, but they see only Settings triggers. `EnableTrigger(name, bool)` is the cleaner, preferred form.)

### `feedTriggers(lineOrLines, onDone?)`

Run text through **your plugin's own triggers** exactly as if it had arrived
from the MUD — the same per-line pipeline (candidate index, matching, callbacks,
gag/colorize). Pass a single string or an array of strings. When the batch
finishes it calls the optional `onDone(elapsedMs, lineCount)` callback.

Why it takes a callback instead of returning: processing a line is asynchronous
(trigger callbacks may await), but plugin code is synchronous — so `feedTriggers`
runs the batch for you and reports the wall-clock time when it's done.

Uses: exercise triggers without a live connection (testing), or benchmark your
own trigger set. (Mudlet parity: `feedTriggers`.)

```lua
-- Test a trigger fires, without connecting to a MUD:
addTrigger("you are hungry", function() send("eat bread") end)
feedTriggers("You are hungry.")

-- Benchmark: stream many lines through every trigger and print the time.
feedTriggers(myLines, function(ms, n)
  echo(string.format("Processed %d lines in %.1f ms", n, ms))
end)
```

### `feedTriggersFromUrl(url, onDone?)`

Like `feedTriggers`, but fetches a text/log file (too large to pass from Lua)
and streams it through your triggers line by line. ANSI is stripped to form the
clean text the matcher sees; the raw line (with ANSI) is still passed so
`matchRawText` triggers and color-aware callbacks work. `onDone(elapsedMs,
lineCount)` fires when the whole file is processed. Browser fetch — same-origin
static assets under `public/` work in the web client.

```lua
-- Replay a captured session log through your triggers and time it:
feedTriggersFromUrl("/my-session.log", function(ms, n)
  echo(string.format("Replayed %d lines in %.1f ms", n, ms))
end)
```

### `addAlias(pattern, replacement, callback?, options?) → aliasId`

- **Alias patterns are JavaScript regex**, not Lua patterns. Use `\w`, `\d`, `\s` — not `%w`, `%d`, `%s`.
- `replacement` (string) is sent to the MUD, with `%1`, `%2`, … and `%*` (or `$1`, `$2`, `$*`) filled in from the captures. When `callback` is provided, the `replacement` string is **ignored** — the callback runs instead; pass `""`. (`addAlias(pattern, callback, options?)` with the replacement left out also works, but write the `""`.)
- `options` (table, optional):

  | Field | Type | Default | Notes |
  |-------|------|---------|-------|
  | `name` | string | — | A name for the alias. |
  | `caseSensitive` | boolean | `false` | |
  | `enabled` | boolean | `true` | |

- Returns the alias id (string), or `""` with a terminal warning when the plugin has no active context (it was unloaded, or the world switched while it was starting).
- From a **trigger or alias script** (Settings `sendTo: script`, re-run on every match), adding a pattern
  any trigger/alias script (or the Ctrl+I window) already added **replaces** the earlier alias and returns the **same id** — it does not stack a
  copy per fire. Aliases made by scripts end on a world switch. A loaded plugin's own `addAlias` calls are unchanged.
- Callback signature: `function(matches)` — single argument.
  - `matches[1]` is the **full match**.
  - `matches[2]` is the first capture, `matches[3]` the second, etc. (1-indexed, with index 1 being the whole match.)

```lua
addAlias("^hp$", "score", nil, { name = "hp-shortcut" })

addAlias("^cast (\\w+) on (\\w+)", "", function(matches)
  -- matches[1] = the whole command; matches[2] = first capture; matches[3] = second
  send("cast " .. matches[2] .. " " .. matches[3])
end)
```

```lua
removeAlias(aliasId: string)          -- = DeleteAlias; warns if the id is not one of yours

-- By NAME. enableAlias/EnableAlias look in the user's Settings > Aliases FIRST; only when no alias
-- there has the name do they use YOUR plugin's own aliases with that name (permAlias, or addAlias
-- with options.name). findAliasByName / toggleAliasByName see Settings > Aliases only.
enableAlias(name: string, enabled?: boolean) → boolean   -- = EnableAlias; omitted = enable;
                                                          --   case-sensitive; false + warning on a miss
findAliasByName(name: string) → { id, name, enabled } | nil
toggleAliasByName(name: string, enabled: boolean) → boolean
```

An alias needs a **Name** (in Settings > Aliases, or the name you gave `permAlias`/`addAlias`)
before it can be addressed by name. Your own aliases can always be removed by the id `addAlias` returned.

### Macros (key bindings): `addMacro(key, action, options?) → macroId | nil`

```lua
function init()
  addMacro("F5", "look")                                  -- text, sent as if typed (aliases + #commands apply)
  addMacro("Numpad 0", "stand", { sendTo = "world" })     -- straight to the MUD, skipping aliases (the number pad's 0, not F10)
  addMacro("Alt+F", function(key) send("flee") end, { name = "Flee", description = "Run!" })
end

removeMacro(id)                 -- → bool
enableMacro(id) / disableMacro(id)
getMacros()                     -- this plugin's: { id, name, key = "Ctrl+K", enabled, sendTo = "command"|"world"|"function", description }
findMacroByName(name)           -- a Settings → Macros entry: { id, name, key, enabled } or nil
toggleMacroByName(name, bool)   -- a Settings → Macros entry
EnableMacro(name, enabled?)     -- by name, this plugin's AND Settings macros
```

- **Keys** are written the way people say them: `"F5"`, `"Numpad 8"` (the number pad's 8 — `"Num 8"` works too), `"Ctrl+K"`, `"Alt+Shift+Up"`, `"Cmd+1"` (modifiers: Ctrl/Control, Alt/Option, Shift, Cmd/Command/Meta/Win).
- **Without Ctrl, Alt or Cmd only F1–F24 and number-pad keys can be bound.** Letters, digits, arrows, Tab, Enter, Space and Escape on their own are how people type and how keyboard and screen-reader users move around the app, so they are refused. A refused key is reported on the terminal and `addMacro` returns `nil` — the rest of `init()` still runs.
- **A plugin's macros are runtime-only** (like its aliases): they go when the plugin unloads, so create them in `init()`. The user's own macros (Settings → Macros) are saved with the world and **always win** a key they share with a plugin; between plugins the most recently bound wins.
- Same split as triggers and aliases: ids for your own macros, `…ByName` for the user's Settings macros, `EnableMacro` for both.

### Triggers and aliases made in Settings (or imported from MUSHclient)

A plugin does not create these, but it can switch them by name (`EnableTrigger`, `EnableTriggerGroup`,
`EnableAlias`), and their **Send To: Script** bodies are Lua you may be asked to write. Each one has a
**Send To** destination for its Send text:

| Send To | What happens to the Send text |
|---------|-------------------------------|
| World | Handled as if typed: the author's own `;`, lines, `@variables`, aliases and `#` commands apply; captured text stays text (see §8 "Captured text …"). For an item in MUSHclient placeholder mode: each line goes straight to the MUD as written. |
| Execute | **Trigger:** handled exactly like World. **Alias:** run as a client command — a plugin terminal command (§15) or `mapper …` — and never sent to the MUD; an unknown command prints an error. An alias imported from MUSHclient instead runs each line as if typed (MUSHclient's `Execute`). |
| Speedwalk | Walked as a speedwalk (§15.5 "Speedwalk notation"). Any error rejects the whole walk, and the terminal names the trigger or alias. |
| Output | Shown in the terminal only. |
| Variable | Stored in the named world variable (Settings > Variables). |
| Script | Run as Lua in the shared script context (§8 "Timers in a Settings … script", §9). The globals `name`, `line` and `wildcards` hold the item's name, the line (or typed command) and the captures. |

Items imported from a MUSHclient world file (`.mcl`) or MUSHclient XML keep MUSHclient's rules:

- **Triggers:** a non-regex pattern becomes MUSHclient's own regex — anchored to the whole line, `*`
  matches as little as possible — rather than a substring. Triggers run in MUSHclient's `sequence`
  order (lower first) and stop after the first match unless *Keep evaluating* was on. An item saved
  switched off arrives switched off.
- **Aliases:** an imported alias is tried before the user's other aliases, the whole command must
  match, *Keep evaluating* lets several aliases fire for one command (and the chain carries on into
  the user's own aliases), and a one-shot alias switches itself off after it fires.
- **Send text:** escapes `\n`, `\t` and `\\` are applied, as MUSHclient applies them. *Expand
  variables* decides whether `@name` is expanded — in the Send text for every Send To, and in the
  pattern. Placeholders use MUSHclient's set (`%%`, `%0`–`%9`, `%<n>`, `%<name>`, `%N`; §8).
- **`script="Func"`:** after the send, the client calls the global Lua function `Func(name, line,
  wildcards)`, as MUSHclient does. The MUSHclient script file that defined it is not imported, so
  define a global function of that name yourself — in a Script trigger or alias, or the Immediate
  window (Ctrl+I); a plugin's globals are separate and are not searched. Until it exists, every call
  reports on the terminal that the function is missing. A dotted name (`combat.onHit`) looks inside
  global tables.
- **Multi-line:** `lines_to_match` becomes `multilineCount` (§7 "MUSHclient-style multi-line").

---

## 8. Timers

```lua
addTimer(intervalMs: number, callback: function, repeating?: boolean) → timerId: string  -- "" when refused
removeTimer(timerId: string)                    -- = DeleteTimer
setTimeout(callback: function, ms?: number) → id: string   -- one-shot; arguments reversed
clearTimeout(id: string)
getCurrentTime() → number                       -- milliseconds since the Unix epoch
formatTime(ms: number, format?: string) → string
                                                -- tokens YYYY MM DD HH mm ss, local time;
                                                --   default "HH:mm:ss"; "" + warning if ms is not a time
```

- `intervalMs` is milliseconds.
- `repeating = true` calls the callback every `intervalMs`; `false` (default) is one-shot.
- **Timers do not run when the session is disconnected** — `addTimer` returns an empty string and emits a terminal warning when called while disconnected.
- **The callback is required and the delay must be a number.** `addTimer(5)` or `addTimer("name", 5, fn)` starts nothing: it returns `""` with a terminal warning. Five seconds is `addTimer(5000, callback)`. A numeric string is a number, as in Lua, so `addTimer(getVariable("tick"), fn)` works when the variable holds `"500"`. (`setTimeout` takes the same two arguments the other way round: `setTimeout(callback, ms)`; leaving `ms` out means 0.)

### Rate limits

| Limit | Value |
|-------|-------|
| Burst (immediate creation) | 100 |
| Sustained (token refill) | 30 per second |
| Hard ceiling (live timers per plugin) | 500 |

Do **not** spawn one timer per MUD line, per entity, or per frame. For per-frame work, use a single `repeating` 16 ms timer and iterate inside it.

### The user's Settings timers

`addTimer` timers belong to your plugin and are addressed by id. The user's own timers (Settings >
Timers, including ones imported from MUSHclient) are addressed by **name**:

```lua
enableTimer(name: string, enabled?: boolean) → boolean   -- = EnableTimer; omitted = enable
findTimerByName(name: string) → { id, name, enabled } | nil
toggleTimerByName(name: string, enabled: boolean) → boolean
```

- `EnableTimer` / `enableTimer` match the **exact** name first, then — as MUSHclient does — any
  upper/lower case. If two timers differ only by case and neither matches exactly, nothing changes
  and a warning says so. Not found: `false` plus a warning. They never touch `addTimer` timers
  (cancel those with `removeTimer`).
- `findTimerByName` / `toggleTimerByName` match the exact name only; `toggleTimerByName` warns on a miss.

What a Settings timer does when it fires — useful when you write its script:

| Field | Type | Notes |
|-------|------|-------|
| interval | number (seconds) | Fractions are kept for imported timers (every 0.5 s), down to MUSHclient's 0.1 s; a timer made or edited in Settings needs at least 1 second. |
| time of day | `HH:MM:SS` | An imported MUSHclient "at" timer fires once a day at that local time (midnight included), not on an interval. |
| offset | number (seconds) | Imported only: moves the first fire earlier by that much; later fires add the interval. |
| active when closed | boolean | Imported only: keeps firing while the world is disconnected. Every other timer pauses while disconnected and restarts from its full interval on connect. |
| Send To | `"world"` \| `"execute"` \| `"speedwalk"` \| `"output"` \| `"variable"` \| `"script"` | A timer made in Settings runs its command as if typed. An imported one keeps its MUSHclient destination: *World* sends each line straight to the MUD (no aliases, `;` stacking or `#` commands), *Execute* runs each line as if typed, *Output* shows it, *Variable* sets the named world variable, *Script* runs it as Lua. A script, note or variable timer never sends its text to the MUD. |
| script function | string | Imported `script="Func"`: after the send, the global `Func(name)` is called with the timer's name. Define it in a Script trigger/alias or Ctrl+I (§7); a missing one is reported once per timer. |
| one-shot | boolean | A Settings one-shot timer switches itself off after firing; an imported MUSHclient one-shot timer is deleted, as in MUSHclient. |

A **Send To: Script** timer runs in the same shared script context as Script triggers and aliases:
its globals persist, `name` is the timer's name (`line` is empty, `wildcards` has nothing), and its
text is used as written (no `%` placeholders). It runs in MUSHclient mode, so `Send` and the
`DoAfter` family behave as in MUSHclient (§15.5 "Two modes"). `GetVariable`/`SetVariable` there
read and write the world's variables (§9).

### Timers in a Settings "Send To: Script" trigger or alias

A Settings trigger with **Send To: Script** runs its whole Send box as Lua, from the top, **on every
match** — it is not a plugin and it has no `init()`. The same applies to Script aliases and to the
Immediate Execution window (Ctrl+I). Three consequences matter:

1. **Globals persist between fires; locals do not.** A bare `count = 0` is still there next match. A
   `local count = 0` is rebuilt every match and can never carry state. All Script triggers, Script
   aliases, Script timers and Ctrl+I share **one** global namespace, so choose distinctive names.
2. **Timers and triggers created there outlive the fire.** Call `addTimer` or `addTrigger`
   unconditionally and you create another one on every match. Guard the call, and keep the id:

   ```lua
   -- runs on every match, so only start the loop once
   local function tick()
     if not combatOn then return end
     send("kill " .. (target or "mob"))
     loopTimer = addTimer(5500, tick)   -- one-shot, reschedules itself
   end

   combatOn = true
   if not loopTimer then tick() end
   ```

   ```lua
   -- the stopping trigger, on "^(.+) has been killed!"
   combatOn = false
   if loopTimer then
     removeTimer(loopTimer)
     loopTimer = nil     -- clear it, or the guard above stays stuck
   end
   ```
3. **Disabling the trigger does not cancel its timers.** A timer is independent once created; turning
   the trigger off only stops new ones. Switching world or session does clear them, along with any
   triggers the script registered.

Prefer two Settings triggers over one script that calls `addTrigger`: Settings triggers are saved with
the world, visible in the list, and individually switchable.

The script box checks the Lua as it is typed, with the same checks as the Plugin Editor, and lists
problems under the box with their line numbers — for example `addTimer(5)`, which is missing its
callback and means 5 **milliseconds** (five seconds is `addTimer(5000, callback)`). `%1`/`%0`,
`wildcards`, `line`, `name` (and `GetTriggerWildcard` in a trigger) are understood, and reading a
global another script set is never reported. With the MUSHclient placeholders switch on, `%%`, `%N`
and `%<n>`/`%<name>` are understood too.

**Captured text in a World/Execute Send box is sent as text.** In a Settings trigger whose Send To
is World or Execute, what `%0`, `%1` … capture is placed into the command it sits in and nothing
more: a `;` or line break inside it never starts another command, an `@name` inside it is not
expanded, and it cannot become a `#` command — so `say %2` sends one say even when another player's
tell contains `hi;#all quit`. The author's own `;`, lines, `@variables`, aliases and `#` commands
work as usual (and `;;` in your own text is a literal `;`, as when typing). A command whose FIRST
WORD holds a capture (a Send of just `%1`, or `k%1`) goes to the MUD exactly as captured, with no
alias or `#` command. `#all say %1`, `#2 tell bob %1` and `#session alt say %1`
relay the capture to the other worlds, where it stays text. `#setvar name %1` and other `#`
commands take a capture as a value; but a capture inside `#trigger`, `#alias`, `#highlight`,
`#gag`, `#substitute` (and their removal forms), or one that would choose the `#` command or the
target world, is refused with a notice. In a speedwalk a capture may only add directions and
counts. In a Send box `%1`..`%9` are one digit each (`%10` is `%1` then `0`), and `%0` is what the
pattern matched (the whole line only when the pattern covers it). An alias set off by a trigger's
command treats its own `%1` the same way.

This protection is for the Send box. In a **Send To: Script** body, `%1` is a value inside the
script (see the next section), so by the time `Send("say " .. wildcards[1])` or `Send("say %1")`
runs, the text is finished and is handled as if typed — a `;` in the capture splits it there. The same
goes for `DoAfter(1, "say %1")` and `DoAfterSpecial(..., sendto.world)`. To
send captured text, prefer Send To: World (or, in MUSHclient placeholder mode, `Send`, which sends
each line straight to the MUD).

A trigger in MUSHclient placeholder mode (`placeholderMode = "mushclient"`, set on every trigger
and alias imported from a `.mcl` file or MUSHclient XML) reads MUSHclient's set in its Send text
for every Send To (`%%`, `%0`..`%9`, `%<n>`, `%<name>`, `%N`; in the Send box a named wildcard the
pattern lacks becomes empty), and its Send To: World is exactly MUSHclient's: each line goes to the
MUD as written — no stacking (`;;` stays `;;`), aliases, `#` commands or speedwalk. `@variables`
are expanded only when Expand Variables is on, for every Send To. The one safety difference: a
line break inside a capture becomes a space instead of a second line. The switch itself is shown
only under the script box, and exported XML records it only for script items, so a copied World
trigger pastes back with the ordinary rules.

### Placeholders (`%0`, `%1`, …) in a Send To: Script body

A Send To: Script body may use placeholders. They are always **values**, never code. There are two
placeholder sets, chosen per trigger or alias by the **MUSHclient placeholders (%%, %<n>, %N)** switch
under the script box. It is off by default and on for triggers and aliases imported from a MUSHclient
world file (`.mcl`) or pasted as MUSHclient XML carrying MUSHclient's own header (`<!DOCTYPE muclient>`,
`<muclient>`, or a "MuClient version" line). Plain `<triggers>`/`<aliases>` XML is also what older
versions of this client exported, so it comes in with the switch **off**; if any of it is a script,
the paste says so, and you switch it on for the items that came from MUSHclient. XML this client
exports now records each script item's setting, so a copy and paste keeps it. A plugin's `addTrigger`
callback (and an `addAlias` callback) receives the captures as arguments, so script placeholders do
not apply there; an `addAlias` without a callback fills `%1`, `%*`, `$1` in its replacement text.

| Placeholder | Default (switch off) | MUSHclient placeholders (switch on) |
|---|---|---|
| `%0` | the whole matched line | the whole matched line |
| `%1`, `%2`, … | wildcards; `%12` is wildcard 12 if the pattern has it, else wildcard 1 then `2` | `%1`–`%9` only, one digit: `%10` is wildcard 1 then `0` |
| `%<12>` | left as written | wildcard 12 (use this above 9) |
| `%<mob>` | left as written | the named wildcard `(?<mob>…)` |
| `%N` | left as written | the trigger's (or alias's) name |
| `%%` | left as written (`%%`) | a single `%` — so a Lua pattern digit class is `%%d` |

MUSHclient's `%C` (the clipboard) is not supported and is left as written, as is a wildcard number or
name the pattern does not have.

- **Inside quotes** — `send("kill %1")`, `'%2'`, `[[%1]]` — the value is the text exactly as the MUD
  sent it, quotes and backslashes included; it cannot end the string early.
- **Outside quotes**, a capture that spells a Lua number (`38`, `-3`, `1.5`, `0x10`) or `true`,
  `false`, `nil` is that value, so `if %1 < 38 then` works. Anything else is a string: `x = %1` gives
  `x` the text.
- **In a comment** a placeholder is left out.
- A placeholder counts **anywhere** in the box, including inside an expression: with two wildcards,
  `(n+1)%2` is read as `(n+1)` followed by the second wildcard, not a modulo, and the script stops
  with an error ("attempt to call a number value") instead of running on with a wrong value. The
  same goes for a placeholder straight after a name (`a%1`). Always write Lua's modulo with a
  space — `(n+1) % 2` — and it is never touched.

A backslash right before a placeholder inside quotes (`"C:\%1"`) still combines with the text's first
character, as it always has (`\n…` is a newline, `\U…` stays `\U…`).

Prefer `wildcards[1]`, `wildcards[2]`, … (and `line` for the whole line). They hold the same values
and are clearer, and they avoid two surprises:

- A `%1` inside a Lua pattern or a `gsub` replacement string is **also** a placeholder when the
  pattern has that wildcard — with MUSHclient placeholders on, write `%%1` for a back-reference.
- Code built as a string to run later. A `DoAfterSpecial(…, sendto.script)` body written as **one
  literal** — `DoAfterSpecial(1, "Note('%1')", 12)` — is safe: its placeholders are filled in as values
  when the body runs, with the captures of the match that scheduled it. A body **built by joining
  strings** — `"Note('" .. %1 .. "')"` — has the text inside the code, so text another player sent
  could run. Hand such a value over through a variable.

---

## 8.5. Sound

```lua
playSound(file, options?) → handle | ""   -- options: { volume = 0..1 (default 1), loop = bool (default false), pan = -1..1 (default 0) };
                                          --   out of range is clamped, a non-number means the default. "" (plus a warning)
                                          --   when no file name is given or the world's window has not opened yet.
stopSound(handle?)                        -- no argument = every sound THIS plugin started
isSoundPlaying(handle) → bool
setSoundVolume(handle, volume) → bool     -- 0..1, on an already-playing sound
setSoundPan(handle, pan) → bool           -- -1 left … 0 centre … 1 right
preloadSound(file)                        -- decode ahead of time
soundExists(file, function(found, reason) ... end)  -- would playSound find it? answers on the callback
```

`file` resolves the same way every other sound in the client does, in this order: the **world's
sound library and packs**, then the **desktop drop-in folder** (desktop app only — the web
version, iPhone and iPad have no such folder), then a plain **URL**. The user's
master volume and their sound on/off switch always apply on top.

```lua
playSound("tell.wav")           -- a bare name: the sound library, then (desktop app) the drop-in folder
playSound("sound:tell.wav")     -- the same file, named explicitly
playSound("/audio/alert.mp3")   -- a path on the server the client runs from (self-hosting only)
playSound("https://example.com/horn.ogg")
```

The user adds files to the library in **Settings → Audio → Sound library** (*Add sounds*), and the
name shown there is exactly what you pass. On the web build that library is the only place audio
can live — a browser cannot read a folder on disk — so tell your users to put the file there rather
than shipping a path. Anything containing a `/`, or carrying a scheme like `https://`, is treated as
a location and fetched; everything else is looked up as a library name first.

- **The handle comes back immediately**, before the audio has been fetched and decoded. Lua has no
  `await`, so `playSound` cannot wait — it hands you a token you can stop, query or adjust straight
  away, even for a sound that has not started yet. A file that turns out to be missing is reported
  on the user's terminal, not in the return value. To check first, use `soundExists` (below).
- **A plugin can only stop its own sounds** — and only those it started in the same world (the same plugin loaded in another world has its own) — and everything it started is stopped for it on unload
  and on world switch. A looping sound can never outlive the plugin that began it.
- `setSoundVolume` / `setSoundPan` return `false` if the handle is unknown or the sound has not
  actually started yet.

```lua
-- A looping ambience that survives being re-run
function init()
  preloadSound("thunder.wav")
  if not isSoundPlaying(rain) then
    rain = playSound("rain.ogg", { loop = true, volume = 0.3 })
  end
end

addTrigger("^Lightning splits the sky", function()
  setSoundVolume(rain, 0.1)          -- duck the ambience
  playSound("thunder.wav", { volume = 1 })
  addTimer(2000, function() setSoundVolume(rain, 0.3) end)
end, { type = "regex" })

function cleanup()
  stopSound()                        -- everything this plugin started
end
```

### Checking a sound is there: `soundExists`

`soundExists(file, callback)` asks whether `playSound` would find `file`, looking in the same places
in the same order (library, drop-in folder, path/URL). Nothing is played, and a big file is not
downloaded or decoded to answer. **The answer arrives on the callback, never as the return value**
— finding a file can mean reading storage or the network, and Lua cannot wait — so
`if soundExists("x") then` is wrong: it is always false, and the client reports an error saying so.

```lua
soundExists("tell.wav", function(found, reason)
  if found then
    playSound("tell.wav")
  else
    echo(reason)   -- e.g. "tell.wav" is not in this world's sound library — add it in Settings → Sound
  end
end)

-- Check once at startup, then play only what is there
haveSound = {}

function init()
  for _, name in ipairs({ "tell.wav", "hit.wav", "crit.wav" }) do
    soundExists(name, function(found) haveSound[name] = found end)
  end
end
```

- `callback(found, reason)` runs exactly once; `reason` is a sentence explaining a miss, and nil
  when found. It is never called after the plugin unloads.
- It confirms the file is **there**, not that it is playable audio — a present file that will not
  decode still reports `true`, and `playSound` then reports it on the terminal.
- The user's sound on/off switch does not change the answer.
- Checking from `init()` is fine: if the session's sound system has not started yet, the check
  waits for it.
- A result is a snapshot. A sound the user adds afterwards is not seen until you check again.

> The `sound = "file"` option on `addTrigger` now resolves the same way `playSound` does — the
> world's sound library, then the drop-in folder, then a URL — so a bare name works there too. It is
> still fire-and-forget: no handle, so nothing to stop, adjust or loop. Prefer `playSound` when you
> want any control over the sound.

---

## 9. Variables & persistence

```lua
-- scope (string, optional) is nil for this character + this plugin, or "global" (see below)
setVariable(name: string, value: any, scope?) -- value is coerced to string   (= SetVariable)
getVariable(name: string, scope?) → string | nil                            -- (= GetVariable)
deleteVariable(name: string, scope?) → boolean                              -- (= DeleteVariable)
saveState()                             -- start saving all variables now; returns nothing to test (= SaveState)
saveTable(tableName: string, data: table, scope?) → boolean  -- JSON-encode and persist a Lua table
storageStatus(scope?) → status: string, reason: string | nil -- "ready" | "starting" | "failed"; can I save right now?
loadTable(tableName: string, scope?) → table | nil
getAllVariables(scope?) → table         -- { name = value }; omit = this plugin's vars (this character); scope "global" = the ENTIRE app-wide shared namespace (every plugin's globals). = GetPluginVariableList / GetVariableList
-- Another plugin's data (see §14):
getPluginVariable(pluginId: string, name: string, sessionNameOrScope?: string) → string | nil
getPluginTable(pluginId: string, tableName: string, scope?) → table | nil
-- Plugin text files (also back the Lua io.* library):
savePluginFile(name: string, text: string, scope?) → boolean
loadPluginFile(name: string, scope?) → string | nil
appendPluginFile(name: string, text: string, scope?) → boolean
deletePluginFile(name: string, scope?) → boolean
-- A file from the USER'S device (they choose it in a dialog):
pickFile(function(file, message, reason) ... end, options?)
```

- **`pickFile(callback, options?)`** shows a dialog naming your plugin with a *Choose file…* button (browsers only open a file chooser from a real click, which plugin code never has — so you cannot skip the dialog, and a plugin can only read a file the user picked). The file arrives LATER on the callback as `{ name, size, data, binary }`; on failure the callback gets `nil, message, reason` with reason `"cancelled"`, `"too-large"`, `"read-failed"` or `"unavailable"`. Options: `title` (shown in the dialog), `accept` (e.g. `".db,.sqlite"`), `maxBytes` (default 64 MB, max 256 MB), `binary`. Without `binary`, `data` is the file decoded as UTF-8 text. With `binary = true`, `data` is a **byte string** — one character per byte, codes 0–255 — so `string.byte(data, i)` is the i-th byte and `#data` the size; that is what the `sqlite` library reads. Works on web, desktop and iOS. `if pickFile(...) then` is wrong — it returns nothing; use the callback.

- **Scope (optional last arg).** Omit it for the **default per-character** store — isolated to this plugin and this character (world), never visible to other plugins or other characters. Pass `"global"` to use ONE **app-wide** namespace keyed by name and shared by **every character AND every plugin** (e.g. a shared bank, account-wide preferences, or data one plugin publishes for others to read) — any plugin that asks for the name reads what any other plugin wrote, and it stays readable while the writing plugin is disabled. Global and isolated are separate stores: a `"global"` write is only seen by `"global"` reads, and reads/deletes must use the same scope they were written with. **Because the global namespace is shared, pick distinct names (e.g. prefix with your plugin name) so you don't clobber another plugin's global of the same name.**
- `setVariable` is string-coerced. **For numbers, booleans, or tables, use `saveTable` instead** — otherwise round-tripping requires `tonumber` / parsing.
- Persistence target for the **default** scope: World file (when one is loaded) → IndexedDB → localStorage fallback. The `"global"` scope persists through the **storage engine** (the app's own IndexedDB storage — on desktop too; it is not a folder of files on disk) in a dedicated app-wide store, independent of any open world — so it is portable and included in a full backup, NOT browser-local.
- Writes are debounced 50 ms (`setVariable` coalesces rapid calls into a single IDB write). `saveState()` flushes immediately.
- `saveState = false` in `plugin.settings` only skips the bulk save of variables at unload and world save; each `setVariable` still reaches the world file and stored values still load. `saveTable` always persists.
- Default (no-scope) table data is **per-character and per-plugin**: with a world open, `saveTable`/`loadTable` use that world's file, under your plugin's id — every session on the same world sees the same copy, different worlds are isolated, and another plugin reads it only by asking for it with `getPluginTable(yourPluginId, name)` (its own `loadTable("x")` never sees your `"x"`). With no world open they fall back to localStorage (origin-wide).
- **Where the user can see it.** Right-click a session tab → *File Manager…* shows every stored file. A plugin's variables, tables and pseudo-files live in `worlds/<world>/plugins/<id>.state.json`; the user can edit that file there, and while the world is open the plugin is reloaded so `init()` reads the edited values (see *Saved data replaced while running* under Lifecycle hooks). The `worlds/<world>/plugins/<name>.lua` beside it is a **read-only copy** of your plugin's code for browsing — plugins run from the plugin list, so edits belong in the Plugin Editor (the browser offers a button to open it). This copy is NOT the desktop app's **plugins folder** (`~/MudForge/plugins/<name>.lua`): that folder IS watched, and saving a plugin's file there hot-reloads it (§19.6).
- **Trigger, alias and timer scripts are not plugins.** A Settings trigger/alias/timer script (and Ctrl+I) runs in the world's script context: there `getVariable`/`GetVariable` reads the **world's variables** (Settings → Variables), as a MUSHclient world script reads the world's `<variables>`, and `setVariable` writes them. Exact name first; a variable imported from a MUSHclient world file is also found by any upper/lower case (MUSHclient keys names in lower case) — the same rule for `GetVariable`, `SetVariable`, `DeleteVariable` and a Send To: Variable item. Inside a plugin, `getVariable` reads only that plugin's own variables — unchanged.
- **World variables and plugin variables are separate.** A plugin's (default-scope) `setVariable` also shows in Settings > Variables, under **Set by plugins** — grouped under the plugin's name and **read-only** there; the player edits only *Your variables* (the world's). A plugin variable and a world variable with the same name are two different variables: neither ever changes, hides or deletes the other, the plugin's `deleteVariable` removes only its own, and trigger/alias/timer scripts never read a plugin's. (An entry saved by an older version, before variables had owners, is taken over by the first plugin that writes that name.) In a Send box, `@name` and `#var` show the world's variable when one exists, otherwise the plugin's (`#vars` marks a plugin's with the plugin's name). `"global"` values are not shown on that page. Variables left by a plugin that is no longer installed are listed under *From plugins no longer installed*, where the player can remove them. The page's search box covers both parts.
- **Reading your saved data in `init()` is safe.** When the session has a world, plugins don't start until that world file is open, so `loadTable`/`getVariable` in `init()` return what you saved last session rather than an empty store. You do not need to delay, poll, or retry the first read.
- **Keeping a loaded table in a variable is safe too** — per-character or `"global"`. `loadTable` hands you a copy. If the saved data is replaced while your plugin runs (cloud sync *Get updates*, a restore, another window, an import, a File Manager edit), your plugin is **reloaded** so `init()` loads the new copy — your old copy's next `saveTable` cannot write over it (that save is skipped and returns `false`). Don't depend on a save in `cleanup()`: during such a reload it is skipped too.
- **`storageStatus(scope?)` — ask before you write, if it matters.** Returns `"ready"` (a save will be kept and will reach disk), `"starting"` (storage has not finished starting; a save is kept in memory and written when it does — not lost, but not safe yet, and normal for the first moments after MudForge opens) or `"failed"` plus a reason (storage will not work for the rest of this session: a `"global"` save is dropped, a per-character save lives in memory until you close the app).

```lua
-- Just want to know it is safe?
if storageStatus() == "ready" then saveTable("kills", kills) end

-- Something you cannot lose? Act on each case.
local status, reason = storageStatus()
if status == "failed" then
  echo("Kill log cannot be saved this session: " .. tostring(reason), "#ff8800")
end

-- The shared global scope is separate and can fail on its own.
if storageStatus("global") == "ready" then saveTable("bank", { gold = 9000 }, "global") end
```

  **To get the reason, assign it to a local.** `local status, reason = storageStatus()` gives you
  both. Passing the call straight into something else — `echo(storageStatus())`,
  `{ storageStatus() }` — gives you the status only, not the reason. That is fine for the common
  `if storageStatus() == "ready"` check, which is what most plugins want; just do not expect the
  reason to travel along with it.

  You do not need this for ordinary saving — a failed save already prints why on the user's
  terminal. It is for a plugin that wants to *decide* rather than be told afterwards.

- **A table you load is YOURS — changing it does not save it.** `loadTable` hands you your own copy, and `saveTable` stores a copy of what you pass. So the only way your changes reach storage is calling `saveTable`:

```lua
-- CORRECT: change it, then save it.
local kills = loadTable("kills") or {}
kills[mob] = (kills[mob] or 0) + 1
saveTable("kills", kills)          -- without this line nothing is stored

-- ALSO FINE: keep using your table afterwards; it is yours.
kills[mob] = kills[mob] + 1        -- not stored until you saveTable again
```

  This is what the client has always documented, and it is now what it does. Previously a table you loaded was the *same* table the client held, so changes to it sometimes reached storage on their own — depending on whether something else happened to save at the same moment. If you have a plugin that relied on that, add the `saveTable` call; it was never reliable. Values that cannot be written to a file (a function, for instance) still behave exactly as before while your plugin is running.

- **Load a big table once, then keep it.** Because you get your own copy, the cost of `loadTable`
  grows with the size of the table. Measured on this machine:

  | table | one `loadTable` |
  |---|---|
  | 1,000 rooms | 2 ms |
  | 10,000 rooms | 26 ms |
  | 30,000 rooms | 87 ms |

  That is nothing once, at startup — and far too much to do per line of MUD output or on a repeating
  timer, where it would visibly stall the client. So for anything large:

```lua
-- CORRECT: load once, work with your table, save when it changes.
local rooms

function plugin.init()
    rooms = loadTable("rooms") or {}
end

function plugin.onRoom(room)
    rooms[room.id] = room
    saveTable("rooms", rooms)    -- saving is fine here; re-LOADING would not be
end
```

  A small table — a few hundred entries — costs well under a millisecond, so this only matters for
  the big ones: maps, room caches, long histories.

- **Keep a big table away from anything you write often.** Everything one plugin stores — every
  table, every variable, every plugin file — lives in ONE file for that plugin. So saving *anything*
  rewrites *all of it*. If you keep a 30,000-room map in the same plugin as an HP counter you update
  every few seconds, each counter update rewrites the whole map. Measured: a single `setVariable` on a
  plugin holding a 5 MB table costs about 24 ms, and the client saves every 5 seconds — roughly
  290 ms of stalled client per minute, for as long as the plugin runs.

  Nothing is lost and nothing is at risk; it is time. Two ways to avoid it:

```lua
-- Put the big thing in its own plugin, and read it from the other one if you need to:
--   "mymap"      holds the rooms table and writes it rarely
--   "mymap-hud"  holds the counters and writes them often
-- Two plugins, two files, no interference.

-- Or keep frequently-changing numbers OUT of storage entirely and only save on a real event:
local hp = 0                       -- a plain local: free to update, never written
function plugin.onGmcp(pkg, data)
    hp = data.hp                   -- thousands of times a session, costs nothing
end
function plugin.onDisconnect()
    setVariable("last-hp", hp)     -- written once, when it actually matters
end
```

  If you already have a plugin shaped the wrong way, splitting it is the fix; the client will improve
  this eventually, but the file layout is what it is today.

---

## 10. Lua pattern reference (for `string.find`, `string.match`, `string.gmatch`, `string.gsub` only)

**Important:** these patterns only work inside the `string.*` library functions at plugin scope. They do **not** work in trigger or alias patterns. Triggers default to substring/wildcard matching; aliases use JavaScript regex; library-scope `string.find` is plain-text-only and library-scope `string.gmatch`/`gsub`/`match` use JS regex.

| Pattern | Matches | Regex equivalent |
|---------|---------|------------------|
| `.` | any char | `.` |
| `%a` | letter | `[a-zA-Z]` |
| `%A` | non-letter | `[^a-zA-Z]` |
| `%d` | digit | `\d` |
| `%D` | non-digit | `\D` |
| `%s` | whitespace | `\s` |
| `%S` | non-whitespace | `\S` |
| `%w` | alphanumeric **including underscore** | `[a-zA-Z0-9_]` |
| `%W` | non-alphanumeric (and non-underscore) | `[^a-zA-Z0-9_]` |
| `%p` | punctuation | `[!"#$%&'()*+,\-./:;<=>?@[\]^_\`{\|}~]` |
| `%P` | non-punctuation | negation of above |
| `%l` / `%L` | lowercase / non-lowercase | `[a-z]` / `[^a-z]` |
| `%u` / `%U` | uppercase / non-uppercase | `[A-Z]` / `[^A-Z]` |
| `%c` / `%C` | control char / non-control | `[\x00-\x1f]` / `[^\x00-\x1f]` |
| `%x` / `%X` | hex digit / non-hex | `[0-9a-fA-F]` / `[^0-9a-fA-F]` |
| `%z` / `%Z` | null char / non-null | `\0` / `[^\0]` |
| `[set]` | character class — `[abc]`, `[a-z]` | `[set]` |
| `[^set]` | negated class | `[^set]` |
| `*` | 0 or more (greedy) | `*` |
| `+` | 1 or more (greedy) | `+` |
| `-` (after a pattern element) | 0 or more (**non-greedy** — *not* the same as regex `-`) | `*?` |
| `?` | 0 or 1 | `?` |
| `^` | anchor to start | `^` |
| `$` | anchor to end | `$` |
| `()` | capture group | `()` |
| `%1` … `%9` | back-reference to capture (in `gsub` replacement string) | `$1` … `$9` |
| `%%` | literal `%` | `%` |
| `%(` `%)` `%.` `%+` etc. | escape a Lua-pattern special char to match literally | `\(` `\)` `\.` `\+` |

Lua patterns do **not** support `\|` alternation, `{n,m}` quantifiers, or lookarounds.

Character sets work as you'd expect: ranges (`[a-z]`, `[A-Za-z0-9_]`), negation (`[^.]`), and Lua classes nested inside a set (`[%d%a]`, `[%w_']`, `[%d;]`) are all supported. The one gap is the **negated** Lua classes (`%A`, `%L`, `%U`, `%C`, `%P`, `%X`, `%Z`) *inside* a set — write those out by hand, or negate the whole set instead (`[^%a]` rather than `[%A]`).

---

## 11. GMCP & MSDP

GMCP and MSDP are protocols that some MUDs use to push structured data (room info, party state, character stats) alongside text.

### GMCP

```lua
getGMCPData(packageName?) → table | nil   -- e.g. getGMCPData("Char.Vitals"). With no argument, returns all packages.
onGMCPUpdate(packageName, callback)       -- subscribe to updates for the current session
sendGMCP(package, data?) → boolean        -- send a GMCP message OUT to the server (Mudlet sendGMCP equivalent)
```

```lua
onGMCPUpdate("Char.Vitals", function(data)
  -- data is a Lua table parsed from the GMCP JSON payload
  drawHpBar(data.hp, data.maxhp)
end)
```

**Sending GMCP out** — pass custom GMCP options to the server (e.g. Achaea / IRE MUDs). A table `data` is JSON-encoded for you; a string is appended verbatim; omit `data` to send a pre-formatted `"Package.Name { json }"` string. Returns `true` if handed to a connected transport (needs a bridge or desktop connection). When nothing is sent a warning says why — not connected (once per disconnection), no package name, or a two-argument package name containing a space.

```lua
sendGMCP("Char.Login", { name = "myname", password = "secret" })  -- table → JSON
sendGMCP("Core.Supports.Set", { "Char 1", "Room 1" })             -- arrays work too
sendGMCP("Char.Items.Inv")                                         -- no data
sendGMCP('External.Discord.Get')                                   -- raw one-arg form
```

For cross-session GMCP, see `getSessionGMCP`/`getAllSessionGMCP` in §12.

**Mudlet style:** the global `gmcp` table (`gmcp.Char.Vitals.hp`) and `registerAnonymousEventHandler("gmcp.Char.Vitals", fn)` also work — see §15.6. `getGMCPData`/`onGMCPUpdate` are unchanged by them.

These are available too (the canonical forms above are `getGMCPData()`, `onGMCPUpdate` and `getSessionGMCP` — prefer those for clarity):

```lua
getSessionList() → array   -- { { id = string, name = string, connected = boolean }, … }; disconnected worlds stay listed until closed; ipairs()
getGMCPDataFromSession(sessionId, packageName?) → table | nil   -- sessionId: string (an id from getSessionList, NOT a name)
onGMCPUpdateGlobal(packageName, callback)   -- callback(data: table, sessionId: string), from EVERY session
getAllGMCPData() → table                    -- same as getGMCPData() with no argument
getCurrentRoom() → table | nil              -- last GMCP room table this session received
```

### MSDP

```lua
getMSDPVariable(name) → any
getAllMSDPVariables() → table
onMSDPChange(name, callback)                   -- callback(newValue, oldValue), session-scoped
onMSDPChangeGlobal(name, callback)             -- callback(sessionId, newValue, oldValue), all sessions
```

An error inside one of these callbacks is shown on the plugin's own world terminal as a PLUGIN ERROR notice (`in  MSDP handler for HEALTH`, with the Lua file and line when known), like GMCP callbacks (`in  GMCP handler for Char.Vitals`); the same error again collapses into one counted line.

---

## 11.5. Mapper API

Read and edit the automapper's room database from a plugin: look up rooms, list/search areas, find paths, auto-walk the character, draw highlights, embed a live minimap, and react to movement. Two families live side by side — a **canonical** family (rich Lua tables, camelCase) and a set of **Mudlet aliases** (Mudlet's own names/conventions) so Mudlet mapper scripts port almost verbatim (see the porting subsection).

### Three hard rules for this API

1. **Reads are synchronous, but only once the map is warm.** Room reads, searches, and pathfinding run synchronously against an in-memory snapshot of the map database (Mudlet parity). That snapshot loads shortly *after* your plugin loads. Before it is ready, reads return `nil`/empty, pathfinding returns not-found, and `isMapReady()` is `false`. **Any map code that runs at load time must start inside `onMapReady()`.** Code that runs later (a trigger, alias, timer, or key macro) can call the reads directly — by then the map is warm. The map is always the map of the tab's world; in a tab with no world yet there is no map, and `onMapReady()` waits until the tab has one.

2. **Lists returned by the mapper API are 0-INDEXED.** They are real JavaScript arrays, so `list[0]` is the **first** element and `#list` is the element count. The classic Lua loop `for i = 1, #list do` is **wrong** here (it skips the first element and runs one past the end). Iterate with `ipairs(list)` (which converts correctly for you) or with an explicit `for i = 0, #list - 1 do`.

3. **A mapper call that does nothing says why.** Every call that writes, deletes, moves the player, walks, or changes the view prints a PLUGIN WARNING on the calling world's terminal when it cannot act: the room id is not in the map, the map has not loaded yet, a direction/area/key is `nil`, a label or flag definition does not exist, a patch field has the wrong type (`x = "abc"` — the other fields are still applied), and so on. Each distinct problem prints once, so an auto-mapper firing on every room will not flood the screen — except `walkTo`, `gotoRoom` and `stopWalk`, which a person usually starts, so they warn every time they fail. `highlightRoom` accepts a room that is not on the map (or a map that has not loaded) on purpose: the highlight is an overlay and shows as soon as that room is there. **Reads stay silent** — `getRoomName`, `roomExists`, `roomHasFlag`, `getRoomExits`, `findPath(...).found == false` return `nil`/`false`/empty as the answer. `getMapStats`, `auditMap` and `nextFreeRoomId` are the exception: they warn if the map has not loaded, because their answer would be meaningless. **Clearing what is already clear** (a door, a user-data key, a special exit, a highlight) is silent too. `addRoom(id)` on an existing room returns `false` silently (the Mudlet idiom); `addMapRoom(id, fields)` on one warns, because the fields were discarded. **With the map open, a write to a room it is about to add waits for it:** the map adds a room you walk into for the first time a moment after the MUD describes it, so a GMCP handler reacting to that same room (`setRoomUserData(gmcp.num, ...)`, `setRoomSymbol`, a flag setter, `updateMapRoom`) runs first. Such a write returns `true` and is applied on top of the room when the map adds it (only what the write changed: an exit you set joins the map's exits, it does not replace them). If the room never appears, a warning that it never appeared and the change was dropped is printed 8 to 16 seconds later. With no map open, nothing adds rooms, so the write is refused at once. Calls that need the room itself never wait and warn at once: `setPlayerRoom`, `deleteMapRoom`, `connectExitStub`, and these removals (`setMapExit(v, dir, nil)`, `removeSpecialExit`, `clearSpecialExits`, `setExitStub(v, dir, false)`, `setDoor(v, dir, 0)`, `lockExit(v, dir, false)`, clearing a hash/colour/symbol, `setRoomUserData(v, key, nil)`, `clearRoomUserData*`, `setRoomFlag` with `false` or as a toggle) — only the real room knows what is there to remove (`lockRoom(v, false)`, `setRoomHidden(v, false)` and `resetRoomArea` do wait). Call those once the room is in the map (e.g. from `onRoomChange`). A held write of a blank value (`setRoomCoordinates(v, 0, 0, 0)`, `setRoomName(v, "")`) is applied like any other. A call that refuses its own arguments (`setExit(v, nil, dir)`, an empty flag name, a patch that is not a table) warns once, at once, and leaves nothing waiting — no later "never appeared" warning. `addMapRoom(v, fields)` on a room whose writes are waiting returns `true` and waits too: if the map adds the room, the map's room is kept (it exists, so a create does not apply), the waiting writes land on it, and if you passed fields a warning says they were not applied — use `updateMapRoom` to change a room the map adds; if the map never adds it, `addMapRoom` creates it with your fields and every waiting write, with no warning. A second `addMapRoom` on the same waiting room returns `false`.  Calls with a result **callback** (`walkTo`, `gotoRoom`, `stopWalk`, `setMapZoom`, `setAreaView`, `setWalkDelay`, `setFastWalk`, `deleteMapRoom`, `importMapJson`) deliver a failure to the callback as `{ success = false, error = "..." }` instead of printing it; omit the callback and it is printed. Mistakes visible at the moment of the call (a bad room id, invalid JSON) always print, and the callback is told as well. `getMapView`, `exportMapJson` and every `on...` event function warn if the callback is missing. The map itself warns as well: when it cannot be loaded (it is retried automatically, but an `onMapReady` callback that was waiting says so and does not run), or when a change cannot be saved to browser storage — the warning names what did not save (rooms, a label, the area list, terrain colours, flags, user data). An unsaved change still shows until the next reload.

```lua
local rooms = getAreaRooms("The Docks")

-- Recommended: ipairs handles the 0-index conversion.
for _, vnum in ipairs(rooms) do print(vnum) end

-- Direct access is 0-based:
print(rooms[0])           -- first vnum
print(rooms[#rooms - 1])  -- last vnum
print(#rooms)             -- element count
```

### Readiness

```lua
isMapReady() → boolean                 -- true once synchronous reads are safe
onMapReady(callback)                   -- callback() runs (asynchronously) once ready
```

### Reading the map (synchronous once ready)

```lua
getMapRoom(vnum) → table | nil         -- { num, name, area, zone, terrain, x, y, z, exits, notes, details }
                                       --   area == zone (both spellings); exits = { direction = destVnum }
                                       --   the table is a detached COPY — mutating it does not change the map
roomExists(vnum) → boolean
getPlayerRoom() → vnum | nil           -- current room (a NUMBER, not a room table); GMCP-tracked,
                                       --   or whatever setPlayerRoom() last set
setPlayerRoom(vnum) → boolean          -- tell the mapper where the player is; false if the room
                                       --   doesn't exist yet (addMapRoom it first)
getAreaList() → table                  -- { [areaName] = roomCount }
getAreaRooms(area) → array of vnums    -- 0-indexed list
searchRooms(query, opts?) → array of room tables
                                       -- opts = { exact = false, caseSensitive = false }
getRoomsByPosition(area, x, y, z) → array of vnums
findRoomsWithin(vnum, maxDist) → table -- { [vnum] = distance } via BFS (start room excluded)
```

**`getPlayerRoom()` returns a bare vnum NUMBER (or nil), not a room table** — the single most common trap. To read the name/coordinates of where you are, chain through `getMapRoom`:

```lua
local me = getMapRoom(getPlayerRoom())
if me then print("You are in: " .. me.name) end
```

**`setPlayerRoom(vnum)` is what makes a mapper possible on a MUD that sends no room protocol.** Parse the room out of the text stream, record it with `addMapRoom`/`setMapExit`, then stand in it. The room becomes the origin for `findPath`/`walkTo`/`mapper goto`, `onRoomChange` fires, and an open map moves its cursor (switching level if needed). It never moves the room — the room keeps the coordinates you gave it — and it works with no map widget open. On a MUD that *does* send room data, the next update overwrites it. Mudlet's `centerview(roomID)` is the same function.

```lua
-- A trigger that has just recognised the room you walked into:
local here = getPlayerRoom()
local id = nextFreeRoomId()
addMapRoom(id, { name = "North Road", area = "Village", x = 0, y = -1, z = 0 })
setMapExit(here, "n", id)
setMapExit(id, "s", here)     -- record BOTH ways: two-way exits are what draw links
setPlayerRoom(id)
```

**`findRoomsWithin(vnum, maxDist)` returns a table keyed by vnum → distance (NOT a 0-indexed list; the start room is excluded).** Iterate it with `pairs()`, and `tonumber()` the key before passing it back into `getMapRoom()`:

```lua
local nearby = findRoomsWithin(getPlayerRoom(), 3)
for k, dist in pairs(nearby) do
    local r = getMapRoom(tonumber(k))   -- keys are table keys; convert before reuse
    if r then print(r.name .. " is " .. dist .. " steps away") end
end
```

### Pathfinding & walking

Pathfinding is synchronous. Walking is driven by the real map widget's auto-walker, so it honors your move-delay floor, fastwalk setting, custom-exit `wait()` pauses, and your `mapper walkcmd` template — exactly like clicking a room or `mapper goto`. When a walk command is set, runs of basic directions are sent to the MUD as one speedwalk (`runto 3n2e`) rather than one command per room; diagonals and custom exits still step individually.

> **Pathfinding is weighted and lock-aware.** `findPath`, `getDistance`, `roomsConnected`, `walkTo`/`gotoRoom`, and the terminal `mapper goto` all honor **room locks** (`lockRoom`), **exit locks** (`lockExit`), and **room/exit weights**. A step's cost is `exitWeights[dir]` **or** the destination room's weight **or** `1` (weights are always `>= 1`), so routes prefer cheap rooms and steer around locked/heavy ones.

```lua
findPath(from, to, opts?) → { found, distance, directions, vnums, error }
                                       -- directions/vnums are 0-indexed arrays; error is a string or nil
                                       -- distance = summed traversal COST (= step count on unweighted maps)
                                       -- opts = { avoid = { vnum, ... }  -- rooms the path must NOT pass through
                                       --          ignoreLocks = true }    -- route through locks anyway (weights still apply)
getDistance(from, to) → number         -- summed cost, or -1 if unreachable (honors locks/weights)
roomsConnected(a, b) → boolean
walkTo(vnum, callback?)                -- auto-walk; callback({ success: boolean, error: string?, steps: number }) — steps = moves walked;
                                       --   called when the walk ends, however long it takes; closing the map mid-walk gives success = false
stopWalk(callback?)                    -- abort an in-progress walk
refreshMap()                           -- force the map widget to reload from the database
```

A locked or **avoided destination** means no path; a locked **start** can still be left.

```lua
-- Weight a dangerous room, then route to the shop avoiding it entirely
setRoomWeight(6621, 50)                       -- 50x the cost to cross (it will be shunned if avoidable)
local path = findPath(here, shop, { avoid = {6621} })  -- and never enter it at all
```

**`walkTo`/`stopWalk`/`refreshMap` need the map widget to be open.** If no map widget is mounted, `walkTo`'s callback receives `{ success = false, error = "Map widget is not open ..." }` after a ~2 s timeout. Every *data* function above works headless (no widget needed).

### Editing rooms & exits

Writes go to the per-world map database and are **batched (~250 ms)** before hitting storage — but your own reads see the change immediately (read-your-writes). Areas are zone strings.

```lua
addMapRoom(vnum, fields?) → boolean    -- fails if vnum exists; fields = { name, area, terrain, x, y, z, notes, details }
updateMapRoom(vnum, patch) → boolean   -- fails if it doesn't exist (waits if the open map is about to add it); only the keys you pass change
mergeMapRooms(rooms) → count           -- create OR update many rooms in one call (for MUDs that send their map layout):
                                       --   rooms = list of { vnum (or num/id), name, area, terrain, x, y, z, notes, details,
                                       --   exits = { n = 1002, w = false } } (or a table keyed by vnum). Missing rooms are
                                       --   created; existing ones change only the given fields; given exits are added/replaced,
                                       --   other exits kept, false removes one. Unchanged rooms are not rewritten, so sending
                                       --   the same window every step is free. Returns rooms created/changed; 0 before the map loads.
deleteMapRoom(vnum, callback?)
setMapExit(from, dir, to?) → boolean   -- add/change a standard exit; pass nil for `to` to REMOVE it
                                       --   long dir names are normalized ("north" → "n")
nextFreeRoomId(hint?) → vnum           -- lowest unused id (optionally from a hint upward)
-- Special (custom-command) exits, e.g. "enter portal", "climb rope":
addSpecialExit(from, command, to) → boolean
removeSpecialExit(from, command) → boolean
getSpecialExits(vnum) → table          -- { [command] = destVnum }
clearSpecialExits(vnum) → boolean      -- remove ALL of a room's special exits at once (keeps compass exits)
                                       --   returns true only if at least one was removed
```

**Special exits win ties when routing.** When a room reaches the same neighbour both ways — a plain compass exit *and* a special exit, e.g. `west` alongside `"open west;;west"` — `walkTo`/goto/click-to-walk take the special exit, because it exists precisely to handle what the plain move can't (a closed door, a lever). The preference only picks the command for one hop: it never lengthens a route or changes which rooms it passes through, and a special exit carrying a heavier exit weight is no longer a tie, so the cheaper plain exit wins again.

### Exit stubs (the auto-mapper staple)

A **stub** is a known-but-unconnected exit: you have seen a room has an exit in some direction but have not yet visited (or created) the room on the other side. Stubs are how an auto-mapper records "there is an exit north, destination unknown" and later stitches the map together. Stubs use **compass directions only** (`n/s/e/w/ne/nw/se/sw/u/d`).

```lua
setExitStub(vnum, dir, present?) → boolean
                                       -- omit/true = add the stub (Mudlet-style); false = REMOVE it
                                       --   non-compass dirs are rejected (returns false)
getExitStubs(vnum) → array of dirs     -- 0-INDEXED list; iterate with ipairs()
connectExitStub(vnum, dirOrToVnum) → boolean   -- needs a stub in that direction, else warns and returns false
```

`connectExitStub` has two call shapes (Mudlet parity):

- **By direction** — `connectExitStub(vnum, "north")` finds whatever room sits one grid step that way and connects to it.
- **By destination vnum** — `connectExitStub(vnum, 1240)` connects to a known room, inferring the direction from the two rooms' coordinates (falling back to the only stub when exactly one exists).

Either way it sets the forward exit and clears the stub. When the destination room holds the **matching reverse stub**, it also sets the return exit and clears that stub too — a two-way connect, exactly like Mudlet.

### Doors

Door state is stored per direction as a status level: `0` none, `1` open, `2` closed, `3` locked.

```lua
setDoor(vnum, dir, status) → boolean   -- status 0 REMOVES the door; 1/2/3 set open/closed/locked
                                       --   any other value is rejected
getDoors(vnum) → { dir = status }      -- legacy -1 exit sentinels surface as status 2 (closed)
```

### Locks & weights

> **These fields persist immediately AND pathfinding now honors them.** `findPath`, `getDistance`, `roomsConnected`, `walkTo`/`gotoRoom`, and the terminal `mapper goto` route around locked rooms/exits and prefer low-weight rooms. A step's cost is the exit weight, or the destination room's weight, or `1` (weights are always `>= 1`). A locked/avoided *destination* yields no path; a locked *start* can still be left. Pass `findPath(from, to, { ignoreLocks = true })` to bypass locks for one query (weights still apply). *(Earlier docs said this was "a later phase"; that routing has shipped.)*

```lua
lockRoom(vnum, locked?) → boolean      -- omit/true = locked; false = unlock
roomLocked(vnum) → boolean
lockExit(vnum, dir, locked?) → boolean -- lock a single exit; omit/true = locked, false = unlock
hasExitLock(vnum, dir) → boolean
setRoomWeight(vnum, w) → boolean       -- w >= 1 (higher = more costly); < 1 or non-finite is rejected
getRoomWeight(vnum) → number           -- defaults to 1 when never set
```

### Room hashes (hash-keyed MUDs)

Some MUDs identify rooms by a stable **hash** string (often via GMCP) rather than a numeric vnum. Bind the game's hash to your local vnum so a hash-mapper can ask "do I already have a room for this hash?" and place the player instantly.

```lua
setRoomIDbyHash(vnum, hash) → boolean  -- bind a hash to a vnum; empty hash CLEARS the binding
-- NOTE: on MUDs that identify rooms by string UIDs (GMCP `uid`/`hash`/non-numeric `id`), the
-- built-in mapper auto-creates rooms whose vnum is a stable synthetic number derived from the
-- UID, with the UID pre-bound as the room's hash — getRoomIDbyHash(uid) resolves those rooms
-- with no plugin setup.
getRoomIDbyHash(hash) → vnum | -1      -- Mudlet convention: -1 (NOT nil) when the hash is unknown
getRoomHashByID(vnum) → hash | nil     -- reverse lookup
```

### Room symbols & visibility

> **Symbols and the hidden flag persist immediately AND now render on the map.** A room symbol draws **centered in the room** and **wins over the vnum display** (its `color`/`symbolColor` is honored); a hidden room is **omitted from the render entirely** — it stays in the pathfinding graph and every read, it just isn't drawn. (Earlier docs said this was "a later phase"; that rendering has now shipped.)

```lua
setRoomSymbol(vnum, symbol?, color?) → boolean
                                       -- symbol = 1-2 chars (truncated to 2); omit/empty to CLEAR
                                       --   color = optional CSS glyph color (symbolColor); honored by the renderer
getRoomSymbol(vnum) → { symbol, color } | nil   -- color is nil when none was set; nil when no symbol
setRoomHidden(vnum, hidden?) → boolean -- omit/true = hidden (omitted from render, kept in graph); false = unhide
getRoomHidden(vnum) → boolean
```

### Persistent visual layer — room colors & map labels

Unlike **highlights** (below), everything in this section is **saved map data** — it survives reload and travels with the world file, and it **renders immediately** (no need to re-apply from `onMapReady()`).

**Room fill colors** — a per-room override that beats the terrain color **and** any terrain texture, so it is the way to make a single room pop (a shop, a quest room) without touching its terrain:

```lua
setRoomColor(vnum, cssColor?) → boolean  -- CSS color string; beats terrain color AND texture
                                         --   nil/omitted CLEARS (back to the terrain color/texture)
getRoomColor(vnum) → css | nil           -- the override, or nil when none is set
```

**Custom environment colors** — the Mudlet idiom: register a CSS color for an environment/terrain id, then tag rooms with that env. Rooms of that env render in your color **even when no terrain style is defined for it**. Note these take **CSS color strings**, not Mudlet's `r, g, b` number triplets:

```lua
setCustomEnvColor(env, cssColor?) → boolean  -- env = terrain/env id (number coerced to string)
                                             --   nil/omitted CLEARS the registration
getCustomEnvColorTable() → { env = css }     -- every registered environment color

-- Color every room of env 500 purple, even with no terrain style for 500:
setRoomEnv(1234, 500)              -- tag the room's env/terrain (Mudlet alias for terrain)
setCustomEnvColor(500, "#8800ff") -- register the color for that env
```

**Map labels** — a **persistent** text label placed on the map at grid coordinates (unlike an ephemeral highlight, it survives reload). Labels render on their own z-level and honor Area view. *(Image labels — Mudlet's `addMapImageLabel` — are **not supported yet**; text labels only.)*

```lua
addMapLabel(area, x, y, z, text, opts?) → id | nil
-- area = zone string ("" shows the label in EVERY area); x/y/z = grid coords in room-coordinate space
-- opts = { color (text, default white), bgColor (fill behind text), fontSize (unscaled px, 6–72, default 12),
--          temporary (true = session-only, not persisted) }
-- returns the label id, or nil if the map is not ready / text or coords are invalid
deleteMapLabel(id) → boolean          -- also accepts Mudlet's deleteMapLabel(area, labelId) (area ignored;
                                      --   ids are map-unique here, not per-area)
getMapLabels(area?) → { [id] = label }  -- area filter INCLUDES the global ("") labels; omit for all
                                      --   label = { id, area, x, y, z, text, fgColor, bgColor?, fontSize, pluginId? }
                                      --   (the text colour reads back as fgColor)
```

**Room flags** — user-defined visual tags rooms can carry (like `"armorshop"`, `"quest"`, `"pk"`). A room can carry **any number** of flags. A flag DEFINITION is created once per world, saved with the map, and carried through exports/world-file sync; it attaches optional visuals:

- `color` — tints the room fill while flagged.
- `icon` — a data-URL image superimposed on the room tile at ~70% of the tile size (the "armor icon in an armor shop" case).
- `symbol` + `symbolColor` — a 1–2 char glyph drawn **only when the room has no symbol of its own**.

Every visual is optional: a flag with no options is still a valid *semantic* tag — it draws nothing but is searchable via `getRoomsWithFlag`. Tagging a room with an undefined name is harmless (the tag is kept, it just draws nothing). Names **normalize to lowercase**. Visual priority: `setRoomColor` > flag color > terrain/env; the room's own symbol > flag symbol > vnum.

```lua
defineMapFlag(name, opts?) → boolean   -- opts = { color, icon (data URL), symbol (1-2 chars), symbolColor }
                                       --   all optional; re-defining the same name replaces it; false only for a blank name
deleteMapFlag(name) → boolean          -- rooms KEEP the tag (it stops drawing); re-defining restores the look
getMapFlags() → { name = def }         -- def = { name, color?, icon?, symbol?, symbolColor? }
setRoomFlag(vnum, flag, on?) → boolean | nil  -- omit on = TOGGLE; true/false = set. Returns the room's NEW state,
                                       --   or nil if the room isn't in the map (on = true waits for a room the open
                                       --   map is about to add, returning true). The flag need not be defined first
getRoomFlags(vnum) → array of names    -- 0-indexed; empty when none / room unknown
roomHasFlag(vnum, flag) → boolean
getRoomsWithFlag(flag) → array of vnums  -- 0-indexed; O(V) scan of the whole database — cache it in hot loops

-- Define an armor-shop flag once, tag shops as you see them, walk to the nearest:
defineMapFlag("armorshop", { icon = armorPngDataUrl })
onRoomChange(function(vnum, _old, room)
    if room and room.name and room.name:find("Armor") then setRoomFlag(vnum, "armorshop", true) end
end)
local here, best, bestDist = getPlayerRoom()
for _, vnum in ipairs(getRoomsWithFlag("armorshop")) do
    local d = getDistance(here, vnum)
    if d and (not bestDist or d < bestDist) then best, bestDist = vnum, d end
end
if best then walkTo(best) end
```

Flags are also editable with **no plugin**: right-click (or long-press) a room for **Flags…** (checkbox toggles + inline new-flag creation), define/edit/delete flags in **Map Settings → Room Flags…** (name, color, symbol, icon upload ≤ 256 KB), or use the terminal — `mapper flag <name> [room#]` toggles and `mapper flags` lists definitions. See *Map GUI* below.

### Area management

Areas are zone strings — there are no numeric area IDs (see the Mudlet notes). Our `areaID` **is** the zone string.

```lua
addAreaName(name) → name | nil         -- register an area BEFORE any room is in it (build top-down)
                                       --   returns the name, or nil if it already existed / was blank
deleteArea(name) → count               -- DESTRUCTIVE: deletes the area registry entry AND every room
                                       --   in it; returns the room count. When it deletes rooms it prints a
                                       --   [Mapper] notice naming your plugin; an area with no rooms is removed
                                       --   quietly (0); an unknown or blank name warns and returns 0
resetRoomArea(vnum) → boolean          -- move a room out of its area (zone becomes "")
```

### Highlights (ephemeral)

Highlights are an overlay, **not saved map data** — they vanish on reload, so re-apply them from `onMapReady()` (and after a world switch).

```lua
highlightRoom(vnum, color?, opts?) → boolean   -- color default "#ffff00"; opts = { opacity = 0..1 } for a fill. The room need not be on the map yet.
unhighlightRoom(vnum?) → boolean               -- one room; no arg = clear ALL of this plugin's room highlights
highlightPath(vnums, color?, opts?) → id | nil -- draw a route: the link between each consecutive pair, any distance apart;
                                               --   vnums: array of 2+ room numbers (fewer, or a bad entry, warns and returns nil)
                                               --   color default "#ffaf00"; opts = { width = number } (× an ordinary link, default 1.5, max 10)
                                               --   findPath(a, b).vnums leaves out the start room — put it in front
unhighlightPath(id?) → boolean                 -- one route; no arg = ALL of this plugin's routes (room highlights stay)
```

Room highlights and routes are also cleared when the plugin is turned off or reloaded.

### Embedded map widgets

```lua
createMapperWidget(name, opts?) → widgetId
-- returns the widget id, or nil
-- opts = { title: string, x: number, y: number, width: number (default 300), height: number (default 300),
--          lockedArea: string, fixedZoom: number (0.1–2), interactive: boolean (default false) }
```

Renders the real map engine as a read-only plugin widget (a minimap / area overview). It owns nothing — it never writes rooms, settings, or the map cursor. `lockedArea` pins it to one area regardless of the player's location; `fixedZoom` forces a zoom (0.1–2); `interactive = true` lets clicks on it click-to-walk (default `false`). Clicks fire `onMapRoomClick` either way.

### Room, area & map user data

Attach arbitrary key/value **strings** to a room, an area, or the whole map. Room user data lives on the room (travels with the world file); area and map user data are persisted per-map in `mapExtras`. Values are coerced to strings; passing `nil` for the value **deletes** the key.

```lua
-- Per-room:
setRoomUserData(vnum, key, value?) → boolean   -- nil value DELETES the key (false if it wasn't set)
getRoomUserData(vnum, key) → string | nil
getAllRoomUserData(vnum) → { key = value }
clearRoomUserData(vnum) → boolean              -- remove ALL user data on the room
clearRoomUserDataItem(vnum, key) → boolean     -- delete ONE key (Mudlet name; nil value above also works)
searchRoomUserData(key, value?) → array of vnums  -- 0-indexed; omit value to match any room with the key
                                               --   O(V) scan of every room — fine occasionally, not in a tight loop
-- Per-area (area = zone string):
setAreaUserData(area, key, value?) → boolean   -- nil value DELETES the key
getAreaUserData(area, key) → string | nil
getAllAreaUserData(area) → { key = value }
clearAreaUserData(area) → boolean
-- Map-wide (one bag for the whole map):
setMapUserData(key, value?) → boolean          -- nil value DELETES the key
getMapUserData(key) → string | nil
getAllMapUserData() → { key = value }
clearMapUserData(key?) → boolean               -- omit key to clear the ENTIRE bag

-- Tag every armor shop, then find them later:
setRoomUserData(1234, "shopType", "armor")
for _, vnum in ipairs(searchRoomUserData("shopType", "armor")) do highlightRoom(vnum, "#ffd700") end
```

### Map-wide operations

```lua
getMapStats() → { rooms, areas, labels, exits, levels, currentRoom } | nil   -- nil before the map is ready
auditMap() → { danglingExits, duplicateCoords, oneWayExits } | nil           -- REPORTS, never repairs; O(V+E)
                                       -- danglingExits = exits to vnums that don't exist
                                       -- duplicateCoords = coordinate cells occupied by 2+ rooms
                                       -- oneWayExits = exits whose destination has no return exit
exportMapJson(callback)                -- callback(json, error): the ENTIRE map (rooms+settings+state) as a
                                       --   JSON STRING; async (can be tens of MB on a 30k-room map). json is nil on failure
importMapJson(json, callback?, options?)
                                       -- no options: DESTRUCTIVE full-map replace (settings too); prints a [Mapper]
                                       --   terminal notice naming your plugin. Rebuilds connections and fires
                                       --   change events, so widgets/caches reload automatically.
                                       -- { merge = true }: KEEP the current map (positions, exits, notes, settings,
                                       --   labels, visit counts) and only ADD rooms it lacks, exits a room is
                                       --   missing, notes not already there, empty fields.
                                       -- { keepSettings = true }: replace the rooms, keep settings/labels/extras.
                                       -- callback({ success, error, rooms, merged, laidOut, pieces, stackedRooms,
                                       --   and when merging: roomsAdded, roomsUpdated, exitsAdded, exitConflicts,
                                       --   notesAdded })
```

**Rooms without positions are laid out for you.** A room in the JSON with no `x`/`y`/`z` is placed from its exits, the same way `mapper relayout` does: rooms joined by compass/up/down exits are positioned relative to each other; separate pieces (islands reached only by custom exits or portals) are packed side by side, clear of each other. When merging, new rooms are placed next to the existing rooms they connect to; their own coordinates, if any, are ignored (they would be from another map's frame). So a converter plugin just builds `{ rooms = { { num = 1, name = "...", zone = "...", terrain = "...", exits = { n = 2, ["enter portal"] = 9 } }, ... } }` and passes it through `json.encode`. Custom exits are exits keyed by their command; stack commands with `;;`.

`auditMap`'s `danglingExits`/`oneWayExits` entries are `{ room, direction, target }`; `duplicateCoords` is an array of vnum-arrays that share a cell.

The export carries the **full** map: rooms, settings, state, **map labels**, **flag definitions**, **custom environment colors**, and **area/map user data**. Earlier builds dropped those extras from `exportMapJson`, world-file (`.mfw`) sync, and map copies — that is fixed, so a round-trip preserves your whole visual layer.

### Map view controls

These drive the on-screen map widget (zoom, area view, walker tuning), so **like `walkTo` they need the map widget open** and answer through an optional callback after a ~2 s timeout if none is mounted. They change the *view*, not saved map data.

```lua
setMapZoom(zoom, callback?)             -- zoom 0.1–2 (clamped); callback({ success, error })
getMapView(callback)                    -- callback({ success, zoom, areaView, currentLevel, currentRoom, error })
setAreaView(enabled, callback?)         -- true = single-area (Area) view; false = whole world
setWalkDelay(ms, callback?)             -- auto-walker per-step delay, 0–10000 ms
setFastWalk(enabled, callback?)         -- true = send the whole route at once
```

### Link stretch (saved with the map)

When two connected rooms are not next to each other on the grid, the map joins them with a line up to a limit, and shows a short stub past it. The default (6 cells) suits a map built as you walk, where a very long link is usually a loop and a full line would cross other rooms. A MUD that sends its own layout wants every link drawn:

```lua
setMapLinkStretch(cells?) → boolean     -- 1–1000 cells, 0 = any length, nil = default (6). Saved with the map;
                                        --   also in the map's settings ("Stretch links up to" / "Any length")
getMapLinkStretch() → cells             -- 0 = any length
```

### Lighting (from your MUD's data)

Rooms can fade with distance from the nearest light — warm close by, cooling and greying further out, never fully dark. The user turns this on with **Dim far rooms** on the map's Look tab (Auto = on with a palette). A plugin that knows the MUD's day/night or equipment drives it:

```lua
setMapLight({ radius = 2, ambient = 0, sources = { { vnum = 3001, radius = 3 } } })
-- radius  = your own light, in rooms (0 = none)      ambient = 0 night … 1 day (everything lit)
-- sources = other lights at rooms (another player's lamp, a torch); radius defaults to 2
-- returns boolean: radius must be 0–50 and ambient 0–1 (else a warning and false); each source
--   radius 0–50 (a bad source is skipped with a warning)
setMapLight()                 -- clear THIS plugin's light (also cleared when your plugin unloads); not saved
getMapLight() → { radius, ambient, sources } | nil   -- radius/ambient are nil when unset
```

A light set here turns dimming on even with the Classic palette, unless the user switched "Dim far rooms" Off. With the user's **Line of sight** option on, the player's light stops at walls and closed doors.

### Map GUI (no plugin required)

Most of the persistent visual layer is also editable straight from the map, with no plugin or Lua. Everything set here is saved in the per-world map and rides along with map exports and world-file sync.

**Right-click a room** (long-press on touch devices) for its context menu:

- **Set Color…** — the per-room fill override (same as `setRoomColor`); clear it to fall back to the terrain color.
- **Set Symbol…** — a 1–2 char room symbol and its color (same as `setRoomChar`/`setRoomSymbol`).
- **Hide Room / Show Room** — toggle `Room.hidden`; hidden rooms stop rendering but stay in the pathfinding graph.
- **Flags…** — a checkbox list of every defined flag to toggle on this room, plus an inline field to create a brand-new flag.

**Map Settings → Room Flags…** is the flag-definition manager: define, edit, and delete flags (a name, optional fill color, optional symbol + symbol color, and an optional uploaded icon image ≤ 256 KB — icons embed inline in the map data). It is the GUI twin of `defineMapFlag`/`deleteMapFlag`, and edits show on the map immediately. The terminal offers the same: `mapper flag <name> [room#]` toggles a flag, `mapper flags` lists the definitions.

### Events

```lua
onRoomChange(callback)     -- callback(newVnum, oldVnum, roomTable)  (roomTable is getMapRoom shape, or nil)
                           --   fires for the MUD's room updates AND for setPlayerRoom()
onMapUpdate(callback)      -- callback({ kind })  kind = "rooms-saved" | "room-deleted" | "cleared" | "imported"
onMapRoomClick(callback)   -- callback(vnum, { button })  fires for the primary map AND embedded widgets
```

### Mudlet porting

Mudlet-named aliases wrap the canonical functions, so most Mudlet mapper scripts run with little change. Three traps:

1. **Areas are zone STRINGS, not numeric IDs.** `getAreaTable()` returns an *identity* table `{ [name] = name }`, so `setRoomArea(room, getAreaTable()["The Docks"])` works verbatim. `getRoomArea`/`getRoomAreaName` return the zone string.
2. **Multi-return functions must be destructured.** `getPath(from, to)` returns `found, distance`; `getRoomCoordinates(vnum)` returns `x, y, z` (or `nil` for an unknown room). Write `local ok, cost = getPath(a, b)`. With a single receiver you get the whole result as a 0-indexed list, NOT the first value — so `if getPath(a, b) then` is ALWAYS true. Test `findPath(a, b).found` instead.
3. **`speedWalkDir` / `speedWalkPath` are NOT set.** Mudlet's `getPath()` populates those globals; here it does not. Use `findPath(from, to).directions` (a 0-indexed array of movement commands).

| Mudlet alias | Canonical equivalent | Notes |
| --- | --- | --- |
| `getRooms()` | — (returns `{ vnum = name }`) | Whole-map name table |
| `getRoomName(vnum)` | `getMapRoom(vnum).name` | |
| `setRoomName(vnum, name)` | `updateMapRoom(vnum, { name })` | |
| `getRoomCoordinates(vnum)` | `getMapRoom(vnum).x/.y/.z` | Returns `x, y, z` — use three receivers (trap 2); nil for an unknown room |
| `setRoomCoordinates(vnum, x, y, z)` | `updateMapRoom(vnum, { x, y, z })` | |
| `getRoomExits(vnum)` | `getMapRoom(vnum).exits` | `{ direction = destVnum }` |
| `setExit(from, to, dir)` | `setMapExit(from, dir, to)` | Note Mudlet's `(from, to, dir)` order. A nil `to` is refused (warning), not a removal — use `setMapExit(from, dir, nil)` |
| `getRoomArea(vnum)` | `getMapRoom(vnum).area` | Zone STRING |
| `getRoomAreaName(area)` | — (identity) | Returns the string unchanged |
| `setRoomArea(vnum, area)` | `updateMapRoom(vnum, { area })` | |
| `getAreaTable()` | — (`{ [name] = name }`) | Identity table (trap 1) |
| `searchRoom(q, exact?, cs?)` | `searchRooms(q, opts)` | Returns `{ vnum = name }` |
| `addRoom(vnum)` | `addMapRoom(vnum)` | |
| `createRoomID(hint?)` | `nextFreeRoomId(hint?)` | |
| `getPath(from, to)` | `findPath(from, to)` | Returns `found, distance` — use two receivers (trap 2); no speedWalk globals |
| `gotoRoom(vnum, cb?)` | `walkTo(vnum, cb?)` | |
| `updateMap()` | `refreshMap()` | |
| `centerview(roomID)` | `setPlayerRoom(vnum)` | Room must already exist; returns false if not |
| `unHighlightRoom(vnum?)` | `unhighlightRoom(vnum?)` | Mudlet's capital-H spelling |
| `deleteRoom(vnum)` | `deleteMapRoom(vnum)` | |
| `setRoomEnv(vnum, env)` | `updateMapRoom(vnum, { terrain })` | Mudlet envID maps onto our terrain string (numeric IDs stored as their string form) |
| `getRoomEnv(vnum)` | `getMapRoom(vnum).terrain` | Returns the terrain string |
| `setRoomChar(vnum, char)` | `setRoomSymbol(vnum, char)` | |
| `getRoomChar(vnum)` | `getRoomSymbol(vnum).symbol` | Returns just the glyph string (or nil) |
| `getExitStubs1(vnum)` | `getExitStubs(vnum)` | Mudlet's 1-indexed variant; ours returns the same array |
| `createMapLabel(area, text, x, y, z, fg?, bg?)` | `addMapLabel(area, x, y, z, text, { color, bgColor })` | Note the arg-order difference (Mudlet puts `text` second). CSS color STRINGS only — Mudlet's `r,g,b` triplets are NOT supported |

### Worked examples

A complete, shipped example lives at `public/plugins/mapper-minimap.lua` — an embedded minimap, a hand-drawn radar, and live `onRoomChange`/`onMapRoomClick` events in one plugin. The snippets below are the individual building blocks.

**A `goto shop` alias** (canonical walk):

```lua
addAlias("^gshop$", "", function()
    if not isMapReady() then echo("Map still loading...", "yellow") return end
    walkTo(4210, function(res)   -- 4210 = the shop's vnum
        if not res.success then
            echo("Couldn't reach the shop: " .. tostring(res.error), "red")
        end
    end)
end)
```

**A room tracker** that echoes each new room and its exits:

```lua
onRoomChange(function(newVnum, oldVnum, room)
    if not room then return end
    local dirs = {}
    for dir, _ in pairs(room.exits) do dirs[#dirs + 1] = dir end
    echo(room.name .. " [" .. room.area .. "]  exits: " .. table.concat(dirs, ", "), "cyan")
end)
```

**A hash-mapper skeleton** — the canonical stub + hash workflow. When the MUD reports a room hash (via GMCP or a trigger), either jump to the vnum you already have for that hash, or mint a new room, bind the hash, and stitch it into the map with a stub. This is *the* pattern for hash-keyed MUDs:

```lua
local lastVnum   -- the room we were in before this move

-- Call this with the server's room hash and the direction we just moved.
local function onServerRoom(hash, movedDir)
    local vnum = getRoomIDbyHash(hash)   -- -1 (NOT nil) when we've never seen it

    if vnum == -1 then
        -- New room: mint a vnum, place it one step from where we came from, bind the hash.
        vnum = nextFreeRoomId()
        local prev = lastVnum and getMapRoom(lastVnum)
        local x, y, z = 0, 0, 0
        if prev then x, y, z = prev.x, prev.y, prev.z end   -- (offset by movedDir in real code)
        addMapRoom(vnum, { name = "Unexplored", x = x, y = y, z = z })
        setRoomIDbyHash(vnum, hash)
    end

    -- Stitch the two rooms together: stub on the way out, connect on arrival.
    if lastVnum and movedDir then
        setExitStub(lastVnum, movedDir)    -- record the exit we just used
        connectExitStub(lastVnum, vnum)    -- connect it to the room we landed in
    end                                    --   (two-way if the return stub is present)

    lastVnum = vnum
end
```

**A minimap** embedded as a widget, plus click-to-inspect:

```lua
function init()
    createMapperWidget("minimap", {
        title = "Minimap", x = 20, y = 20,
        width = 260, height = 260,
        fixedZoom = 0.8, interactive = false,
    })
    onMapRoomClick(function(vnum)
        local room = getMapRoom(vnum)
        if room then echo("Clicked: " .. room.name .. " (#" .. vnum .. ")", "cyan") end
    end)
end
```

**Marking a shop route** — the persistent visual layer at work: paint each shop room gold and drop a persistent label above the first one. Because these are saved map data, they render immediately and are still there after a reload (no `onMapReady` re-apply needed):

```lua
onMapReady(function()
    local shops = { 4210, 4215, 4222 }   -- the shop rooms on this route
    for _, vnum in ipairs(shops) do
        setRoomColor(vnum, "#ffd700")    -- gold fill; beats the terrain color/texture
    end

    -- A persistent gold label above the market, on the first shop's z-level:
    local first = getMapRoom(shops[1])
    if first then
        addMapLabel(first.area, first.x, first.y + 1, first.z, "Merchant Row", {
            color = "#ffd700",
            bgColor = "#1a1a1a",
            fontSize = 14,
        })
    end
end)
```

**A hand-drawn radar** — a canvas widget that plots the rooms within 3 steps of the player using `getMapRoom` coordinates and the drawing API:

```lua
local radarId

function init()
    radarId = createWidget({ name = "radar", title = "Radar", width = 160, height = 160 })
end

local function drawRadar()
    if not isMapReady() then return end
    local here = getMapRoom(getPlayerRoom())
    if not here then return end

    setActiveWidget(radarId)
    clear("#0a0a0a")
    local cx, cy, scale = 80, 80, 14      -- widget center + pixels per map unit

    local near = findRoomsWithin(here.num, 3)   -- { [vnum] = distance }, iterate with pairs
    for k, dist in pairs(near) do
        local r = getMapRoom(tonumber(k))       -- keys are table keys; convert before reuse
        if r and r.z == here.z then       -- same level only
            local px = cx + (r.x - here.x) * scale
            local py = cy + (r.y - here.y) * scale
            local color = dist == 1 and "#00ff88" or "#0077cc"
            drawCircle(px, py, 3, color)
        end
    end
    drawCircle(cx, cy, 4, "#ffcc00")       -- you, in the center
end

-- Redraw on every move, and once the map warms up.
onMapReady(drawRadar)
onRoomChange(function() drawRadar() end)
```

---

## 12. Multi-session

Each MUD connection is a session. By default, plugin callbacks are scoped to the session that registered them.

### Session info

```lua
getSession() → table | nil            -- { id, name, host, port, connected, active } for this plugin's session
getSessionId() → string | nil
getAllSessions() → array              -- array of the getSession() shape
getSessionById(id) → table | nil
getSessionByName(name) → table | nil  -- case-sensitive tab name
isActiveSession() → boolean           -- is this the foreground window?
switchToSession(name) → boolean       -- bring a session (tab name or id) to the foreground
```

### Sending across sessions

```lua
sendToSession(name, command) → boolean       -- send to a session by tab name (or id)
sendToSessionId(id, command) → boolean       -- send to a session by id
sendToAll(command) → number                  -- like the `#all` command; returns how many connected sessions it went to
sendToOthers(command) → number               -- all except current
```

`sendToSession` and `sendToSessionId` send the text straight to that world's MUD, exactly as
given — no aliases, `;` stacking or `@variables`. `sendToAll` and `sendToOthers` run it in each
world as if typed there, so aliases apply.

A session is addressed by the name on its tab (case-sensitive) or its id. When
`sendToSession`, `sendToSessionId`, `setSessionVariable`, `emitToSession` or
`switchToSession` cannot reach the target it returns `false` and prints a warning
in *your* session's terminal saying why: no session by that name or id, or (for
the two send calls) the session is not connected. When the problem is an unknown
**name**, the warning also lists the sessions that are open. The send, variable
and emit calls warn once per target, so a loop does not flood the terminal;
`switchToSession` is something a person triggers, so it warns every time.

### Cross-session variables

```lua
getSessionVariable(sessionName, varName, pluginId?) → value | nil   -- pluginId: read that plugin's own variable there
setSessionVariable(sessionName, varName, value, pluginId?)   -- pluginId: set that plugin's own variable there
getAllSessionVariables(varName) → table    -- { [sessionId] = { name = sessionName, value = v } } across all sessions
```

### Cross-session events

These are separate from the inter-plugin broadcasts in §14 — they target *sessions*, not plugins.

```lua
onGlobal(event, function(data) … end) → function   -- subscribe to a cross-session event; call the returned function to stop
broadcast(event, data?)                        -- fire an event to EVERY session, INCLUDING your own (note: this is NOT broadcastPlugin)
emitToSession(sessionName, event, data?) → boolean   -- fire an event to one session
```

`broadcast()` delivers to the sender's own session too, so your own `onGlobal`
handlers hear your own broadcasts (`data.__sessionId` tells you the origin).
Two consequences: (1) calling `broadcast(X)` from inside your own
`onGlobal(X, …)` handler for the same event recurses — guard with a flag if
you re-broadcast; (2) for plugin-to-plugin messaging *within one session*,
the plain `emit()` / `on()` pair (§14) is the simpler, better tool —
`broadcast`/`onGlobal` earn their keep only when multiple sessions are involved.

### Cross-session GMCP / MSDP

```lua
getSessionGMCP(sessionName, packageName?) → table | nil   -- sessionName: tab name or id; omit packageName for all
getAllSessionGMCP(packageName) → table         -- { [sessionId] = { name = sessionName, data = packageData } }; only sessions that have it
getSessionMSDP(sessionName, variableName?) → any | table | nil
getAllSessionMSDP(variableName?) → table       -- { [sessionId] = { name, data } }; only sessions that reported CHARACTER_NAME
requestMSDPFromAllSessions(variables) → number -- variables: array of names; returns how many sessions were asked (values arrive later)
```

---

## 13. HTTP

Only two methods exist:

```lua
http.get(url, headers?, callback?)
http.post(url, body, headers?, callback?)
```

There is **no `http.put`, no `http.delete`, no `http.patch`** — the bridge rejects anything but `GET` and `POST` with HTTP 400.

- **`url` must be HTTPS.** Plain HTTP URLs are rejected.
- `body` must be a **string** — encode JSON yourself: `http.post(url, json.encode({…}), …)`. A non-string body (or an empty `url`) is reported as `http.post: body must be a string` through the callback's `error` argument; with no callback it is raised as an error.
- `headers` is an optional table: `{ ["Content-Type"] = "application/json" }`. The callback is always the LAST argument — `http.get(url, nil, cb)`, not `http.get(url, cb)` (a function in the headers slot is ignored and the reply is lost).
- Callback signature: `function(status: number, body: string|nil, error: string|nil)`. It is called exactly once per request; an error thrown inside it is reported as a plugin error on your session's terminal (it is not fed back to the callback as a failed request).
  - Success (any reply from the server, including 404 or 500): `status` = the HTTP code, `body` = the response text (decoded as UTF-8), `error` = nil. Check `status` yourself. Parse JSON with `json.decode`.
  - Failure (permission denied, invalid or non-HTTPS URL, blocked address, timeout, oversize reply, rate limit): `status` = 0 or a diagnostic code (400, 403, 429, 502), `body` = nil, `error` = a message.
  - Response headers are not returned.
- Limits: 30-second timeout, 10 MB response cap, redirects followed (up to 5, HTTPS only), and on the web build at most 100 requests per minute to one domain.
- **Per-plugin per-domain permission:** the first request to a new host prompts the user. Decisions are remembered (session or persistent) and isolated per plugin id — Plugin A's "allow" does not grant Plugin B.
- **Blocked destinations (web build only)** — in the browser, requests go through a shared server-side proxy, which rejects internal targets with no network call: loopback (`127.0.0.0/8`, `::1`); private (`10/8`, `172.16/12`, `192.168/16`, `fc00::/7`); link-local including cloud metadata IPs (`169.254/16`, AWS/GCP `169.254.169.254`, `fe80::/10`); CGNAT (`100.64/10`); multicast / reserved (`224/4`, `240/4`); IPv4-mapped IPv6; and the hostnames `localhost`, `*.local`, `*.internal`, `*.localhost`, `metadata.google.internal`. DNS rebinding is mitigated by resolving every address before connecting. In the **desktop/mobile app** requests are made natively from the user's own machine (like any MUD client), so private/LAN destinations are allowed — the per-plugin per-domain permission prompt still gates every host.
- `http` is also available inside libraries; the request inherits the **consuming plugin's** permission scope.

```lua
http.post(
  "https://example.com/webhook",
  json.encode({ msg = "hi" }),
  { ["Content-Type"] = "application/json" },
  function(status, body, err)
    if err then
      echo("HTTP error: " .. err, "#ff6666")
      return
    end
    echo("Got " .. tostring(status) .. ": " .. body)
  end
)
```

---

## 14. Inter-plugin communication

> Plugins start in parallel. If a sibling must ALREADY be listening when your `init()` emits, declare `dependsOn` (§2, *Load order*) or use the ready handshake shown there.

The workhorse for plugin-to-plugin messaging **within a session** is the plain
custom-event pair — synchronous, cross-plugin, and (unlike `broadcastPlugin`)
the emitter's own handlers hear it too:

```lua
on(event, function(data) … end)                -- subscribe (custom or built-in event)
emit(event, data?)                             -- deliver synchronously to EVERY plugin's on() handlers in this session, including your own
off(event, callback?)                          -- unsubscribe (usually unnecessary — handlers auto-clean on plugin unload/reload)
```

```lua
-- Central-hub pattern (the Mudlet "one GMCP handler re-emits" style):
-- hub plugin:
onGMCPUpdate("Char.Vitals", function(data)
  emit("myapp.vitals", data)                   -- re-emit for sibling plugins
end)
-- any other plugin:
on("myapp.vitals", function(vitals) drawHpBar(vitals) end)
```

Delivery is synchronous and in registration order; a handler that throws never
blocks the others. Handlers registered *during* an emit start receiving from
the next emit.

Built-in events the client fires (the handler gets one table):

| Event | Payload | Notes |
|-------|---------|-------|
| `connected` | `{ sessionId: string }` | The world connected. |
| `reattached` | `{ sessionId: string }` | iOS app only: the app reloaded its screen and the session picked up the connection it already had. Fired INSTEAD of `connected` (and `onConnect` does not run) because the character is still logged in — rebuild session state here, never send login steps. The latest GMCP/MSDP values are already restored (`getGMCPData`, `getMSDPVariable`) but GMCP/MSDP handlers are NOT called for them. |
| `disconnected` | `{ sessionId: string }` | The world disconnected. |
| `line` | `{ text: string, clean: string, sessionId: string, provisional: boolean? }` | Every incoming line (`text` raw with ANSI, `clean` stripped). `provisional = true` for a prompt line still waiting for its newline. Not fired for lines an `onLine` hook discarded. |
| `windowResize` | `{ width: number, height: number }` | See §4. |

```lua
addEventHandler(eventName: string, callback: function(event))
  -- a browser window event listener. The callback receives the raw DOM Event (payload in
  -- event.detail), not a Lua table. Removed automatically on unload. A non-function callback
  -- warns and adds nothing. For MUD lines and GMCP use on("line", …) / onGMCPUpdate.
```

The MUSHclient-style broadcast channel also exists — note its sender-exclusion
quirk (your own `onPluginBroadcast` does NOT hear your own `broadcastPlugin`).
Like `emit`/`on`, it stays inside one world: with several worlds open, a
broadcast is heard only by plugins in the world that sent it, and
`broadcastToPlugin` reaches the target's copy in that world only. To reach
other worlds use `broadcast`/`onGlobal` (§12).

```lua
broadcastPlugin(message, data?)                -- emit to all other plugins in this world
broadcastToPlugin(targetPluginId, message, data?)  -- the target's copy in this world
onPluginBroadcast(function(senderId, message, data) … end)
```

```lua
getPluginId() → string                          -- this plugin's id
getPluginName() → string
getPluginInfo() → { id, name, version, author, description }
getLoadedPlugins() → array of { id, name, version, author, enabled }
findPluginByName(name) → { id, name, version, author } | nil   -- name compared case-insensitively; only plugins loaded in this world
getPluginVariable(targetPluginId, varName, sessionNameOrScope?) → string | nil
  -- 3rd arg: omit = current session (the target plugin must be loaded there, else nil); a session NAME = that session's live value; "global" = the one app-wide shared value by name (targetPluginId IGNORED for "global" — same as getVariable(varName, "global"))
getPluginTable(targetPluginId, tableName, scope?) → table | nil
  -- same-world by default (reads another plugin's table on the current world); scope "global" reads the one app-wide shared table by name (targetPluginId ignored for "global")
```

`onPluginBroadcast` skips messages your plugin sent via `broadcastPlugin` (the broadcast-to-everyone variant). It **does** fire for `broadcastToPlugin(myOwnId, …)` — if you target yourself, you receive your own message.

---

## 15. Plugin terminal commands

```lua
registerCommand(commandName, handler, description?)
```

Registers a command the user can run by typing it in the terminal (works without a MUD connection). The name is one word and is not case-sensitive — `registerCommand("myStats", …)` is typed as `mystats` or `/mystats`, and a leading `/` in the name is ignored. Names are shared by every plugin in this world; registering a name another plugin in the same world already uses replaces its command and prints a warning. A name the client itself answers when typed (`connect`, `disconnect`, `clear`, `mapper`) is never reached — the client's command runs first. The test words (`testlinks`, `testmxp`, `linkhistory`, `testpassword`, `gmcpdebug`, `msdpdebug`) are the client's only while no MUD is connected; while connected a plugin command of that name runs (the client's versions are always available as `#testlinks` etc.). Useful for `:configure`-style entry points. The `handler` receives a single string argument — everything the user typed after the command name, joined by single spaces, or `""` when nothing follows. A string the handler returns is printed in that world's terminal; it is shown, not treated as MUD text, so triggers never fire on it — whether the command was typed or run by an alias.

```lua
registerCommand("hello", function(args)
  return "Hello, " .. (args ~= "" and args or "world")
end, "Greet someone")
```

**Return your output; do not echo it.** A string the handler returns is printed in the terminal that ran the command. Returning the text cannot miss.

A command belongs to the world (session) whose plugin registered it. With several worlds open, it can only be typed in a world where its plugin is loaded, and the same plugin loaded in two worlds has a separate command in each — typing it runs that world's copy. An empty name or a handler that is not a function registers nothing and prints a warning.

Separate lines with `\r\n`; the string is written to the terminal as-is, so it may carry colour codes.

```lua
registerCommand("status", function()
  return "HP: " .. getVariable("hp") .. "\r\n" ..
         "MP: " .. getVariable("mp")
end, "Show your vitals")
```

Keep `echo` for output that arrives *later* — a timer firing, an HTTP reply coming back — because by then there is no command left to answer.

### Command palette commands

```lua
local id = addPaletteCommand(options)   -- "plugin:<your plugin's id>:<id>", or nil (with a warning)
removePaletteCommand(id)                -- pass the string addPaletteCommand returned; true if it was there
```

Adds a command to the command palette (Ctrl+K, Cmd+K on a Mac), where the player finds it by typing, can pin it, give it an alias, put it on a hotkey, and run it with `#palette run <id>` from a macro. Commands registered with `registerCommand` also appear in the palette, as things to type; `addPaletteCommand` is for a command with a proper title, a section, and — optionally — an on/off switch.

| Option | Type | Meaning |
|---|---|---|
| `title` | string | **Required.** What the row says. |
| `run` | function | **Required.** Called when the player runs it. |
| `isOn` | function | Makes it a switch: return `true`/`false` for its current state. The row shows the state, Enter flips it (your `run` does the flipping), and the palette stays open with the row where it was (the list keeps its order while open), so several can be flipped with Down, Enter. |
| `subtitle` | string | Muted text after the title. |
| `section` | string | Group in the palette. Default: your plugin's name. |
| `keywords` | list of strings | Extra words it is found by. |
| `detail` | string | Text for the palette's detail pane. |
| `id` | string | Stable id. Default: the title. It is lower-cased, every run of other characters becomes `-`, and it is cut to 48 characters; the palette id returned (and used by pins, aliases, hotkeys and `#palette run`) is `plugin:<your plugin's id>:<id>`. Keep it stable. |
| `stayOpen` | boolean | Keep the palette open after running (switches do by default). |

```lua
local autoloot = loadTable("autoloot") or { on = false }

addPaletteCommand({
  title = "Auto-Loot",
  subtitle = "Loot every corpse",
  keywords = { "loot", "corpse" },
  isOn = function() return autoloot.on end,
  run = function()
    autoloot.on = not autoloot.on
    saveTable("autoloot", autoloot)
  end,
})

addPaletteCommand({ title = "Loot All Now", run = function() send("get all corpse") end })
```

Like `registerCommand`, a palette command belongs to the world whose plugin added it, and it is removed when the plugin unloads — add your commands in `init()` each time. Adding the same `id` again replaces the command (so reloading is safe). A missing title, a `run` that is not a function, or an `isOn` that is not a function adds nothing and prints a warning. An error inside `run` or `isOn` is reported in that world's terminal; an `isOn` that errors reads as off.

---

## 15.5. MUSHclient compatibility API

For porting scripts from MUSHclient, the runtime exposes a subset of MUSHclient's globals. New plugins should prefer the lowercase native API, but these are available:

### Naming: Capitalised vs camelCase

Capitalised names are MUSHclient-compatible; camelCase names are ours. Where both
exist they are **the same call running the same implementation**, so they can never
behave differently:

```lua
EnableTriggerGroup("combat", false)   enableTriggerGroup("combat", false)
EnableAlias("speedWalk", false)       enableAlias("speedWalk", false)
EnableTimer("autoSave", false)        enableTimer("autoSave", false)
```

**Two exceptions — these are NOT pairs.** `enableTrigger` and `enableMacro` existed
before the convention settled and take the **id** returned by `addTrigger`/`addMacro`,
while the Capitalised versions take a **name**:

```lua
local id = addTrigger("^You are hungry$", eat)
enableTrigger(id)                  -- by ID, and only your own plugin's trigger
EnableTrigger("Hunger", true)      -- by NAME, and reaches Settings AND plugin triggers

enableMacro(id)                    -- by ID
EnableMacro("Quaff", true)         -- by NAME
```

They cannot be renamed without breaking plugins that already call them. To address a
trigger by name use `EnableTrigger`, which also reaches plugin-registered triggers.

`toggleTriggerGroup` is an older call that does a similar job, but it is **not** the same as
`enableTriggerGroup`: it sees only **Settings** triggers, missing any registered by a plugin with
`{ group = ... }`, and with the second argument left out it turns the group **off**, where
`enableTriggerGroup("x")` turns it on. Prefer `enableTriggerGroup`, and always pass `true` or
`false` to `toggleTriggerGroup`.

### Output

```lua
Note(text)                           -- print an uncolored line to the terminal (same as echo(text))
ColourNote(fg, bg, text)             -- print a colored line. fg/bg are color names:
ColorNote(fg, bg, text)              --   "black"/"red"/"green"/"yellow"/"blue"/"magenta"/"cyan"/"white"
                                     --   (plus gray/bright* variants). Pass "" for bg to skip it.
                                     -- ColourNote/ColorNote (and lowercase colourNote/colorNote) are
                                     -- all the same function — British and American spellings both work.
echo(text, color?)                   -- print one line; color may be a NAME ("green") or a HEX ("#ff8800").
print(text)                          -- print one line using your configured print color.
```

### Execution

```lua
Execute(command)                     -- run as if typed (aliases, # commands), like executeCommand();
                                     --   a # command runs only from the world in front (else it warns, once per plugin per world)
Send(command)                        -- send(): as today, aliases apply. In a MUSHclient-mode
                                     --   trigger/alias script: each line straight to the MUD.
                                     -- Neither expands %1 again: in a trigger script it was
                                     --   already replaced once, before the script ran.
DoAfter(seconds, command) → code     -- run a command after a delay (seconds, not ms), as if
                                     --   typed (aliases apply). MUSHclient mode: straight to the MUD.
DoAfterNote(seconds, text) → code    -- show a note in this world after a delay (never sent)
DoAfterSpeedWalk(seconds, path) → code
                                     -- walk a speedwalk ("3n2e(open door)w") after a delay; a path
                                     --   with a mistake sends nothing and warns when it fires
DoAfterSpecial(seconds, text, sendto) → code
                                     -- the general form: sendto is a name from the table below.
                                     --   DoAfterNote/DoAfterSpeedWalk are exactly this with
                                     --   sendto.output / sendto.speedwalk. DoAfter is close to
                                     --   sendto.world, but decides a # command when you CALL it
                                     --   (refused unless this world is in front), while
                                     --   sendto.world goes through send() when it FIRES (command
                                     --   echo, once-per-disconnection warning).
```

The delay is under **86400 seconds** (a numeric string such as `"5"` is accepted); they
return `error_code.eOK` (0) when scheduled, `error_code.eTimeInvalid` (30022) for a
delay out of range, `error_code.eBadParameter` (30046) for text that is not a string or
number, and `error_code.eOptionOutOfRange` (30026) for a `sendto` not in the table (a bad
call also warns in the terminal and schedules nothing). A missing `sendto` is
eOptionOutOfRange in MUSHclient mode and `sendto.world` with a warning otherwise. Some
calls warn and schedule nothing but still return eOK: a "not available" `sendto`, a bare
`14` outside MUSHclient mode, empty text, and a DoAfter `#` command from a world that is
not in front. **0 is truthy in
Lua** — compare with `error_code.eOK`, don't write `if DoAfter(...) then`.
The text is used exactly as written: inside a trigger script `%1` was already
replaced once, before the script ran, and is never replaced a second time.
They act in the world that scheduled them, even if the user switches tabs.

### Speedwalk notation

What `DoAfterSpeedWalk`, `sendto.speedwalk`, a Send To: Speedwalk trigger/alias/timer and a typed
`#3n2e` all read — MUSHclient's speedwalk grammar, with two extras and without its door letters:

| Item | Meaning |
|------|---------|
| `n` `s` `e` `w` `u` `d` | One step, any case. Sent as the letter (`n`). `sw` is south then west, never south-west. |
| count | `3n` repeats the next item; counts go up to 1000 (MUSHclient stops at 99). A count of 2 or more with nothing after it (or followed by a `{comment}`) is an error. |
| `(text)` | Any other command, sent as written: `(ne)`, `(open n)`, `(enter portal)`. A count repeats it: `2(ne)`. Only the part before a `/` is sent: `(ne/sw)` sends `ne`. |
| `{comment}` | Skipped. |
| `;` | A half-second pause (not in MUSHclient). |
| spaces, line breaks | Ignored between items. |

- **Doors go in brackets:** `(open n)n`. MUSHclient's `O`/`C`/`L`/`K` door letters and its `F`
  filler are **not** speedwalk letters here — they are errors like any other letter. (A MUSHclient
  world import rewrites them into brackets.)
- **Any error rejects the whole walk** — an unknown letter, a comma, a count over 1000, a bracket
  or `{` never closed — and nothing at all is sent, not even the valid part. The terminal names
  what sent it (the alias, trigger or timer) and what is wrong.
- **Typed with `#`**, a line walks only when it is a valid speedwalk; `#done` is not one, so it goes
  to the MUD as typed. Client `#` commands (`#all`, `#highlight`, …) are recognised first.

```lua
DoAfterSpeedWalk(2, "3n2e(open door)w")        -- n n n e e "open door" w
DoAfterSpecial(1, "2(ne);s", sendto.speedwalk) -- ne ne, pause, s
```

**Two modes.** Plugin files, and trigger/alias scripts by default, get
**MudForge mode**: `sendto.world` / DoAfter run as if typed, a bare `1`
shows a note, a bare `14` does nothing (with a warning), and a delay may be as
short as 0. A trigger/alias script whose **placeholder mode is MUSHclient**
gets MUSHclient's semantics for every bare number — `0` straight to the MUD,
`1` the command box, `14` run as Lua — a 0.1 s minimum delay (shorter is refused
with eTimeInvalid, not rounded up), and a raw
`Send`. The `sendto.*` names mean the same thing in both.

### Variables

```lua
SetVariable(name, value, scope?)     -- same as setVariable; value coerced to string. scope "global" = app-wide shared namespace
GetVariable(name, scope?) → string | nil   -- scope "global" reads the app-wide shared value (set by this or any plugin)
DeleteVariable(name, scope?) → bool  -- remove a variable; scope "global" removes the shared value
GetPluginVariableList(scope?) → table  -- this plugin's variables; scope "global" = the entire app-wide shared namespace
GetPluginVariable(pluginId, name, sessionNameOrScope?) → string | nil  -- "global" reads the app-wide shared value (pluginId ignored)
```

In a plugin these are the plugin's own variables. In a trigger, alias or timer script (and Ctrl+I)
`GetVariable` / `SetVariable` / `DeleteVariable` work on the **world's** variables (Settings >
Variables), as a MUSHclient world script does — exact name first, then any upper/lower case for a
variable imported from MUSHclient. See §9.

### Trigger / alias / timer toggling

```lua
EnableTrigger(name, enabled?)        -- look up a trigger by name and enable/disable it
EnableTriggerGroup(group, enabled?)  -- case-sensitive group name; warns if it matches nothing
EnableAlias(name, enabled?)          -- Settings > Aliases; case-sensitive name
EnableTimer(name, enabled?)          -- Settings > Timers; exact name, then any case (as MUSHclient)
```

`EnableTrigger` / `EnableTriggerGroup` cover Settings triggers and plugin-registered triggers alike.
`EnableAlias` and `EnableTimer` reach only the user's Settings aliases and timers. All four return
`true` when something changed, and `false` plus a terminal warning when nothing matched; omitting
`enabled` enables.

### Sound

```lua
PlaySound(buffer, file, loop, volume, pan) → number
StopSound(buffer)                          -- buffer defaults to 0 = stop them all
GetSoundStatus(buffer) → number
Sound(file)                                -- first free buffer; Sound("") stops everything
```

MUSHclient's model, kept faithfully: **ten buffers per plugin**, numbered 1-10.

| Argument | Range | Meaning |
|----------|-------|---------|
| `buffer` | 1-10, or 0 | 0 = first free buffer when playing, ALL buffers when stopping |
| `file`   | string | Empty modifies the sound already in that buffer instead of loading |
| `loop`   | boolean | Default `false` |
| `volume` | -100 to 0 | **Decibels of attenuation**, 0 being full volume. Out of range = full |
| `pan`    | -100 to 100 | -100 hard left, 0 centre, 100 hard right. Out of range = centre |

Playing into an occupied buffer stops what was there first.

`playSoundBuffer(buffer: number, file: string, loop: boolean, volume: number, pan: number) → number`, `stopSoundBuffer(buffer: number) → number` and `soundBufferStatus(buffer: number) → number` are the camelCase spellings of the same three, with one difference: every argument is required — `stopSoundBuffer()` with no buffer returns `30046` (and warns) instead of stopping everything; pass `0`.

`GetSoundStatus` returns MUSHclient's own codes: `2` playing and looping, `1` playing, `0` reached
the end, `-1` buffer out of range, `-2` buffer free, `-3` no sound system. `PlaySound` / `StopSound`
return `0` (eOK), `30046` (eBadParameter) or `30004` (eCannotPlaySound) — MUSHclient's real numbers.

**One unavoidable difference.** Audio decodes asynchronously in a browser, so a missing or
unplayable file cannot be reported in the return value the way DirectSound does it — there is
nothing to report yet when the call returns. It surfaces on the user's terminal instead. Scripts
that test `== 0`, which is nearly all of them, behave exactly as they did under MUSHclient.

```lua
PlaySound(1, "horn.wav")                   -- buffer 1, full volume
PlaySound(0, "rain.wav", true, -20, 0)     -- first free buffer, looping, attenuated 20 dB
PlaySound(2, "", false, -40, 0)            -- just turn buffer 2 down
if GetSoundStatus(1) == 2 then StopSound(1) end
StopSound()                                -- everything
```

**Delayed commands do not outlive the plugin.** A `DoAfter`, `DoAfterSpecial`,
`DoAfterNote` or `DoAfterSpeedWalk` that has not fired yet is cancelled when the plugin is disabled, reloaded or
uninstalled — a plugin that is gone should not still be typing at the MUD.
Schedule anything that must survive an unload from something that survives it
too.

### `sendto`, `error_code` and `error_desc`

MUSHclient's tables and names. **Use the names** — they mean the same thing
in every script. The numbers are MUSHclient's except `command` and
`scriptafteromit`, which hold values only the name produces: a bare `1` and
`14` meant echo and variable in older MudForge plugins, so outside MUSHclient
mode `1` still shows a note and `14` does nothing, with a warning.

```lua
sendto.world = 0            -- run as if typed (aliases apply); MUSHclient mode: straight to the MUD
sendto.command              -- put the text in this world's command box, if it is empty (name only)
sendto.output = 2           -- show the text in the terminal as a note
sendto.status = 3           -- NOT AVAILABLE (no status line): warns, schedules nothing
sendto.notepad = 4          -- NOT AVAILABLE (no notepad): warns, schedules nothing
sendto.notepadappend = 5    -- NOT AVAILABLE
sendto.logfile = 6          -- NOT AVAILABLE (no log file)
sendto.notepadreplace = 7   -- NOT AVAILABLE
sendto.commandqueue = 8     -- send straight to the MUD (there is no command queue here)
sendto.variable = 9         -- NOT AVAILABLE from DoAfterSpecial: its timer has no name
                            --   to give the variable (MUSHclient drops it too)
sendto.execute = 10         -- run as if typed: aliases apply
sendto.speedwalk = 11       -- walk it as a speedwalk
sendto.script = 12          -- run as Lua in THIS plugin's own globals (sees and changes
                            --   them; your `plugin` table is left alone). From a trigger or
                            --   alias script: the globals those scripts share
sendto.immediate = 13       -- send straight to the MUD
sendto.scriptafteromit      -- run as Lua (name only; same as script here)
```

The "not available" destinations never send the text to the MUD instead.
`sendto.script` text is ordinary plugin code: built from MUD output, it runs
MUD output. In a trigger or alias script, a `sendto.script` body written as
ONE string literal may use `%1` — it is filled in as a value when the body
runs, with the captures of the match that scheduled it. Do not BUILD the
body by joining strings with `%1` or `wildcards[1]`; pass the value through a
variable instead.

```lua
local rc = DoAfterSpecial(5, "look", sendto.world)
if rc ~= error_code.eOK then print(error_desc[rc]) end
```

---

## 15.6. Mudlet compatibility API

Mudlet's names with Mudlet's behaviour, so Mudlet scripts can be pasted into a plugin and run. Use these when **porting**; for new code the native API (`addTrigger`, `addTimer`, `on`/`emit`, `onGMCPUpdate`) has more options. Both styles mix freely in one plugin.

### What is supported, and how it differs

| Mudlet | Differences here |
|---|---|
| `raiseEvent`, `registerAnonymousEventHandler`, `killAnonymousEventHandler` | None. One event engine per **world** (= a Mudlet profile): an event reaches every plugin running in that world, never another world |
| `gmcp` table + `gmcp.<Package>` events | None. One event per level of the package name |
| `sysLoadEvent`, `sysConnectionEvent`, `sysDisconnectionEvent` | `sysLoadEvent` goes only to the plugin that has just loaded |
| `tempTimer`, `killTimer` | Runs whether or not you are connected (unlike `addTimer`). Ids are per **world**, shared by every plugin in it (as in a Mudlet profile): `killTimer(id)` stops that timer whichever plugin started it. Max 500 live tempTimers per plugin |
| `tempTrigger`, `tempRegexTrigger`, `killTrigger` | The code must be a **function**; a string of Lua is refused with a warning |
| `exists` | Types `alias`, `trigger`, `timer`, `keybind` (macros). `script`/`button` always 0 |
| `permAlias` | The alias belongs to the plugin, not Settings — see below. The pattern is PCRE, translated like a trigger pattern |
| `enableAlias` | Settings > Aliases first, then the plugin's own named aliases |
| `cecho`, `decho`, `hecho` | No miniconsoles: a window other than `"main"` prints to the main window (warning). Outside a trigger each call prints its own line, so a trailing `"\n"` adds an empty line — leave it off |
| Line cursor (`getLines`, `moveCursor`, `deleteLine`, `replaceLine`, `insertText`, `setTriggerStayOpen`) | See §7 |
| Mapper (`getRooms`, `getPath`, `gotoRoom`, `setExit`, …) | See §11.5 "Mudlet porting" |
| `sendGMCP` | See §11 |

**Not available:** Geyser and Mudlet GUI (labels, miniconsoles, gauges — use widgets, §4), `getMudletHomeDir`, `loadfile`/`dofile` from disk (use one plugin, or `require` with a library, §16), `tempAlias`, `permTimer`, `permTrigger`, `registerNamedEventHandler`, `raiseGlobalEvent`. Calling one stops the script with "attempt to call a nil value"; guard with `if type(tempAlias) == "function" then … end` when a script must run in both clients.

**A plugin's own global wins.** If a plugin defines its own global named like one of these APIs (`exists`, `raiseEvent`, `tempTimer`, `decho`, …), the plugin keeps its own value for its whole life — later runs (DoAfter strings, tempTimer/permAlias string code, the console) do not put the API back over it.

Global variables are **per plugin**. A Mudlet system made of many script files that share globals (`PkCore.x` set in one file, read in another) must be ONE plugin; separate plugins talk through `raiseEvent` (or §14).

### Events

```lua
raiseEvent(name: string, ...: any) → boolean            -- true. Handlers get (name, ...)
registerAnonymousEventHandler(event: string, handler: function | string, oneShot?: boolean) → number | nil
killAnonymousEventHandler(id: number) → true | nil, message: string
```

| Argument | Type | Notes |
|---|---|---|
| `event` | `string` | Event name. `"*"` = every event (called after the named handlers) |
| `handler` | `function \| string` | `function(eventName, ...)`, or the NAME of a global function, looked up each time the event fires (defined later is fine; `"MySys.onVitals"` walks tables; only the plugin's own globals/fields are found — `"toString"` is not a function here). The same name registered twice for one event **by the same plugin** returns the first id; two plugins using one name get two handlers (each plugin's own function) |
| `oneShot` | `boolean` | Removed after it runs, unless the handler returns `true` |
| returns | `number` | Handler id; `nil` + warning when an argument is wrong |

- A handler that errors is reported on the terminal (with its Lua line) — once while it keeps failing with the same error; the other handlers still run.
- `killAnonymousEventHandler` on an id that was already removed (killed, or a oneShot that ran) returns `nil, "Handler with ID 'n' not found."` **quietly** — clean-up code may kill everything it tracked. An id never issued in this world warns.
- Every handler, timer and alias a plugin made with these is removed when the plugin unloads or reloads.

**Events the client raises:**

| Event | Handler args | When |
|---|---|---|
| `gmcp.<Package>` | `(event: string, fullName: string)` | Every GMCP message, once per level: `Char.Vitals` raises `gmcp.Char` then `gmcp.Char.Vitals`, both with `fullName = "gmcp.Char.Vitals"`. Read the data from the `gmcp` table |
| `sysConnectionEvent` | `(event)` | The connection opened (GMCP not negotiated yet) |
| `sysDisconnectionEvent` | `(event)` | The connection closed |
| `sysLoadEvent` | `(event, true)` | This plugin has finished loading (own handlers only) |

### The `gmcp` table

```lua
if gmcp.Char and gmcp.Char.Vitals then
  local hp = tonumber(gmcp.Char.Vitals.hp)
end
```

- Keys use the **exact case the game sends** (`gmcp.Char.Vitals`, not `gmcp.char.vitals`).
- Each message REPLACES the package's previous value; `Char.Status` is MERGED (Mudlet's default).
- JSON lists are 1-based Lua tables: `list[1]`, `#list`, `ipairs(list)`.
- Empty until the first GMCP message; one table per world (a world switch in the same tab starts a fresh, empty one); values are copies (editing them changes nothing else).
- A plugin that already uses its own global named `gmcp` keeps it — the table is only placed while the name is free.

### Timers

```lua
tempTimer(seconds: number, code: function | string, repeating?: boolean) → number | nil
killTimer(id: number) → boolean
```

| Argument | Type | Notes |
|---|---|---|
| `seconds` | `number` | SECONDS, fractions allowed; `0 <= seconds < 86400` |
| `code` | `function \| string` | A string is Lua run in this plugin (sees its globals); syntax-checked when created |
| `repeating` | `boolean` | Run every `seconds` until `killTimer` |

`killTimer` → `true` if it stopped a running timer — ids are per world, so an id another plugin passed you (e.g. through `raiseEvent`) stops THAT plugin's timer, as in Mudlet; `false` quietly for one that already fired or was killed; `false` + warning for an id `tempTimer` never returned in this world (stop `addTimer`/`setTimeout` timers with `removeTimer`). Max 500 live tempTimers per plugin (`tempTimer` past that: `nil` + warning). A timer whose code keeps failing with the same error reports it once, not every tick.

### `exists(nameOrId: string | number, type: string) → number | nil`

| `type` (any case) | Counts |
|---|---|
| `"alias"` | Settings > Aliases + this plugin's named aliases (`permAlias`, `addAlias` with `name`) |
| `"trigger"` | Settings > Triggers + this plugin's named triggers |
| `"timer"` | Settings > Timers by name; tempTimers by id (any plugin's in this world) |
| `"keybind"` | Settings > Macros + this plugin's named macros |
| `"script"`, `"button"` | always `0` |

Returns the count by name (0 when none), or 1/0 for an id. Any other type: warning + `nil`.

### `permAlias(name: string, parent: string, regex: string, code: string | function) → string | nil`

| Argument | Type | Notes |
|---|---|---|
| `name` | `string` | Used by `exists` and `enableAlias` |
| `parent` | `string` | Mudlet's folder — accepted, ignored. Pass `""` |
| `regex` | `string` | Mudlet (PCRE) pattern, translated exactly like a trigger pattern: `(?i)` makes it case-insensitive, `\z`/`\A`/`[[:alpha:]]`/`(?P<n>…)` work. Case-SENSITIVE otherwise (as in Mudlet). A construct with no faithful translation (e.g. `\pL`, atomic groups) is reported with a warning; one that does not compile refuses the alias |
| `code` | `string \| function` | Run in this plugin with global `matches`: `matches[1]` = matched text, `matches[2]…` = captures |

**"Permanent" here:** the alias belongs to the plugin — it lives while the plugin runs, is not added to Settings > Aliases, and is re-created by the plugin's own code on every load. Guard it the Mudlet way and it is created once per load; reloads never stack copies:

```lua
if exists("goto room", "alias") == 0 then
  permAlias("goto room", "", [[^gt (\d+)$]], [[gotoRoom(tonumber(matches[2]))]])
end
enableAlias("goto room", false)   -- off; enableAlias("goto room") turns it back on
```

### `decho` / `hecho` — `([window: string,] text: string)`

| Markup | decho | hecho |
|---|---|---|
| Text colour | `<255,0,0>` | `#ff0000` or `\|cff0000` |
| Text + background | `<255,0,0:0,0,128>` | `#ff0000,000080` |
| Background only | `<:0,0,128>` | `#,000080` |
| Reset | `<r>` or `</r>` | `#r`, `#/r`, `\|r` or `\|/r` |
| Bold / italic / underline / strike / overline | `<b>…</b>`, `<i>`, `<u>`, `<s>`, `<o>` | `#b…#/b`, `#i`, `#u`, `#s`, `#o` |

A code that is not a valid colour is printed as written. In hecho, `\#ff0000` prints the code as text. MudForge `$` codes are NOT read — `$` stays `$`. Inside a trigger the text is appended to the current line, like `cecho`.

### Worked example — a Mudlet script as a plugin

```lua
plugin = { name = "HP Watch", author = "you", version = "1.0", description = "Ported from Mudlet" }

-- ↓ the Mudlet script, unchanged except: no trailing "\n" on echoes
HPWatch = HPWatch or { warned = false }

function HPWatch.onVitals()
  local v = gmcp.Char.Vitals
  local hp, max = tonumber(v.hp), tonumber(v.maxhp)
  if hp < max * 0.3 and not HPWatch.warned then
    HPWatch.warned = true
    hecho("#ff4444LOW HEALTH#r " .. hp .. "/" .. max)
    tempTimer(10, function() HPWatch.warned = false end)   -- allow another warning in 10 s
  end
end

function HPWatch.report()
  local v = gmcp.Char.Vitals
  decho("<0,200,0>HP <255,255,255>" .. v.hp .. "/" .. v.maxhp .. "<r>")
end

registerAnonymousEventHandler("gmcp.Char.Vitals", "HPWatch.onVitals")

if exists("hp report", "alias") == 0 then
  permAlias("hp report", "", "^hp$", [[HPWatch.report()]])
end
-- ↑ end of the Mudlet script

return plugin
```

---

## 16. The `require()` system & writing libraries

### `require(moduleName) → table`

Loads a library and returns its exported table. A library can reach the client four ways, and `require()` resolves all of them identically:

| Source | Where it comes from |
|--------|---------------------|
| **Bundled** | Ships with MudForge (`/public/libs/` on web, the app's resource directory on desktop). |
| **Your libs folder** | A `.lua` file the user dropped in the desktop app's writable libs directory. Hot-reloads on save. |
| **Installed** | Installed from a repository via **Plugin Manager → Libraries**. Stored on the device, available in every world. |
| **From a package** | Carried inside an installed `.mfp` package. |

**Precedence** when two sources offer the same name: a library on disk (bundled or the user's own folder) always wins, then installed, then package. A downloaded library can never shadow one the user has locally, so `require("string")` always resolves to the bundled `string` library.

**Rules:**
- Top-level `require()` calls: `moduleName` must match `^[a-zA-Z0-9_-]+$` and be ≤ 64 chars. Flat names only — no paths, no extensions, no dots.
- Nested `require()` calls *inside* a library: the 64-char cap is not enforced, but the regex still is.
- Each calling plugin gets its **own independent execution** of the library — module-level locals (counters, config, caches) are isolated per plugin.
- Repeated `require("foo")` within the same plugin returns the same instance.
- Libraries may `require` other libraries. The transitive cache is shared per plugin.
- Circular dependencies throw `circular require detected: 'a' is already being loaded. Loading chain: a → b → a`.
- Unknown module name throws `module 'xyz' not found. Available libraries: …`.

### What's available inside a library

The library sandbox is a **subset** of plugin scope — it has the language built-ins, the **same** `math`/`string`/`table` libraries a plugin gets, `json`, `http`, nested `require`, and nothing else. No drawing, no MUD I/O, no GMCP, no widgets, no timers. What a library lacks is the *host* API, not the language.

| Available | Not available |
|-----------|---------------|
| `type`, `tostring`, `tonumber`, `pairs`, `ipairs`, `unpack`, `select`, `error`, `assert`, `pcall`, `xpcall` | `send`, `echo`, `utilprint`, `tprint` |
| `rawget`, `rawset`, `rawequal`, `rawlen` | `addTrigger`, `removeTrigger`, `addAlias`, `removeAlias`, `addTimer`, `removeTimer` |
| `nil` (as a *global*, e.g. `if x == nil`) | `setVariable`, `getVariable`, `saveState`, `saveTable`, `loadTable` |
| `math` — the full library, identical to plugin scope | `createWidget`, `setActiveWidget`, all `drawX` functions |
| `string` — the full library, identical to plugin scope | `getGMCPData`, `onGMCPUpdate`, all MSDP / session APIs |
| `table` — the full library, identical to plugin scope | `broadcastPlugin`, `registerCommand`, `findPluginByName`, etc. |
| `json.encode`, `json.decode`, `json.null` | MUSHclient compat (`Execute`, `Note`, `DoAfter`, etc.) |
| `http.get`, `http.post` (inherits the consuming plugin's permissions) | `io`, `os`, `setTimeout`, `clearTimeout` |
| `require` (nested loads share the consuming plugin's module cache) | |
| `print` — **goes to the debug log only**, not the user's terminal | |
| `_G` (points at the library context itself), `_table` (internal constructor) | |

#### Library stdlib parity

A library gets the **same** `math`, `string` and `table` as a plugin — the same
functions, from the same place. There is nothing to check for and no parity
table to consult.

This was not always true. The two scopes used to be built from separate,
hand-maintained copies, and the differences between them were never designed —
they were simply whichever copy had last been edited. A library could not call
`math.sinh`, `math.modf`, `math.frexp`, `math.ldexp`, `table.unpack` or
`table.getn`; a plugin could not call `string.trim`. All of those work in both
scopes now.

What *is* restricted is the host API, and that is deliberate: a library has no
`send`, `echo`, `addTrigger`, widgets, timers or GMCP, because a library is a
pure utility module. If it needs any of those, the consuming plugin injects
them — see the pattern below.

If a library needs plugin APIs, it must accept them via an explicit injection function (conventionally named `init`):

```lua
-- /public/libs/discord.lua
local discord = {}
local _config = { webhook_url = "", username = "MUD Client" }
local _api = {}  -- injected APIs go here

function discord.setup(opts)
  _config.webhook_url = opts.webhook_url
  _config.username    = opts.username or _config.username
end

function discord.init(apis)
  _api = apis or {}   -- e.g. { echo = echo, addTimer = addTimer }
end

function discord.send(message)
  if _config.webhook_url == "" then
    error("discord.send: call discord.setup({ webhook_url = ... }) first")
  end
  local body = json.encode({ content = message, username = _config.username })
  http.post(_config.webhook_url, body, { ["Content-Type"] = "application/json" })
  if _api.echo then _api.echo("[discord] sent: " .. message, "#5865f2") end
end

return discord
```

Consumer plugin:

```lua
local discord = require("discord")
discord.setup({ webhook_url = "https://discord.com/api/webhooks/…" })
discord.init({ echo = echo })  -- inject what we want the library to use
discord.send("Hello from MUD!")
```

Receiving works the same way — inject the timer functions, then `listen()`:

```lua
local discord = require("discord")

function init()
  discord.init({ addTimer = addTimer, removeTimer = removeTimer, echo = echo, send = send })
end

local function start()
  discord.listen({
    bot_token  = getVariable("discord_bot_token"),
    channel_id = getVariable("discord_channel_id"),
    interval   = 3,                        -- seconds between polls (default 2)
    on_message = function(msg)
      -- msg.author (display name), msg.username, msg.author_id, msg.content,
      -- msg.timestamp, msg.channel_id, msg.id, msg.bot
      echo("[Discord] " .. msg.author .. ": " .. msg.content, "#5865F2")
    end,
  })
end

function onConnect() start() end           -- timers need a live connection
function onDisconnect() discord.stop() end
```

Polling needs a bot token with the **Message Content** intent enabled and a channel the bot can read (View Channels + Read Message History). Messages from other bots are skipped unless `include_bots = true`; posts from your own webhook are always skipped, so a plugin that relays both ways cannot echo itself. A picture posted with no text arrives as `[attachment: filename]`. If the timer cannot be created (no connection yet) `listen()` says so and `is_listening()` stays false — call it again from `onConnect()`.

There is **no `/set` command** in the client. Store credentials with `setVariable()` from a command your plugin registers; the bundled Discord Bridge Example does this with `/discord-config token …` and `/discord-config channel …`.

### Writing a library in the client

Plugin Manager → Libraries → **New library** (or **Edit** next to a library) opens it in the plugin editor in *library mode*: no plugin-table rules, host API calls (`send`, `echo`, timers…) are flagged as unavailable with the injection pattern as the fix, and a missing `return M` is a warning with a fix. Saving stores the library app-wide with the `user` origin: it takes precedence over an installed or package library of the same name, and can never replace a bundled library or a file in the libs folder (those open read-only — save a copy under a new name). **Save & Reload users** restarts the enabled plugins that `require()` it so they pick the new code up immediately; a plain Save takes effect on each plugin's next load.

### Library file template

```lua
-- /public/libs/mylib.lua
local M = {}

-- module-level state: isolated per consuming plugin
local _count = 0

function M.greet(name)
  return "Hello, " .. tostring(name)
end

function M.tick()
  _count = _count + 1
  return _count
end

return M
```

### Library manifest (web builds)

If you ship a new library with the client, register it in `/public/libs/manifest.json`:

```json
{
  "libraries": [
    { "name": "mylib", "version": "1.0.0", "description": "Short description" }
  ]
}
```

Tauri (desktop) builds also auto-discover `.lua` files in the user's libs directory; the manifest is only required for the web build.

### Built-in libraries shipped with the client

| Name | Purpose |
|------|---------|
| `string` | Extended string helpers (split, trim, stripAnsi, wordWrap, padding). |
| `table` | Extended table helpers (deepCopy, merge, map, filter, reduce, slice). |
| `discord` | Webhook send (`send`, `embed`) + bot polling (`listen`, `stop`, `is_listening`). Requires `discord.init({ addTimer, removeTimer, echo })` for polling, and a live connection — start it from `onConnect()`. |
| `sqlite` | Read-only SQLite reader in pure Lua. `sqlite.open(bytes)` → `db` or `nil, reason` (input is a BYTE STRING, e.g. `pickFile(cb, { binary = true })`'s `file.data`); `db:tables()`, `db:hasTable(name)`, `db:columns(name)`, `db:rows(name)` (all rows, small tables), `db:cursor(name)` → `cur:next(n)` (up to n rows, empty list at the end), `cur:done()`, `cur:pagesRead()`. Rows are keyed by column name; NULL reads as nil; `INTEGER PRIMARY KEY` reads as the rowid. Read big tables a batch per `addTimer` tick. Read-only, no SQL; UTF-8 databases only; changes still in a WAL file are not visible (close the owning program first). |
| `test-utils` | Sample library (`add`, `greet`, `reverse`, `clamp`, a per-plugin counter). Handy for checking that `require()` works in your setup before you build a real library. |

### Package-installed libraries

Server packages (`.mfp` — see §16.5) can ship shared libraries under `libs/<name>.lua`. Once installed they are `require("<name>")`-able exactly like file-based libraries, with these precedence rules:

- A **file-based library always wins** over a package library with the same name — the package copy is skipped with a warning at install time. A package can never silently shadow a library the user installed themselves.
- Two packages shipping **byte-identical** sources under one name share a single entry (refcounted; removed when the last package uninstalls).
- Two packages shipping **different** code under one name → the second package's copy is refused.

Package libraries persist per world (`worlds/<w>/packageLibs.json`, not as real files) and re-register automatically on world open.

---

## 16.4. Multi-file plugins (`loadModule` / `dofile` / `loadfile`)

A plugin can be a **main script** (`plugin.script`, what you have written so far) plus any number of **module files**, each at a relative path such as `ui/theme.lua` or `reactor_modes/strategies/x.lua`. Module files never run on their own: the main script (or another module) runs one with `loadModule(path)`. **Modules run in the order `loadModule` is called.** Use this for one big system split into files (the Mudlet "bootstrap + module_registration + 50 files" shape); use `require` (§16) for helper code shared by SEVERAL plugins, and separate plugins for features that are switched on and off on their own.

| Function | Returns | Notes |
|---|---|---|
| `loadModule(path: string)` | `any` — the module's return value(s) | Runs the file in the plugin's own Lua state: **shared globals**, full plugin API, `local`s stay in the file. Throws on a missing file, bad path, syntax error or runtime error; the message starts `file:line:`. Every call runs the file again. |
| `dofile(path: string)` | same | The SAME function as `loadModule` (Lua/MUSHclient/Mudlet name). |
| `loadfile(path: string)` | `function`, or `nil, string` | Never throws. The function runs the module (again on each call) and returns its values. |

- `path`: relative to the plugin, `/` between folders, `.lua` optional (`"ui/theme"` = `"ui/theme.lua"`), leading `./` ignored. Letters of any script (combining accents/vowel signs allowed after a letter), digits, space, `_`, `-`, `.`; stored NFC. Refused with a clear error: absolute paths, `..`, backslashes, names starting with `.`, Windows device names (`CON`, `PRN`, `AUX`, `NUL`, `COM0-9`, `LPT0-9`, any extension, any case) and names ending in `.` or a space; two paths that are one file on Windows/macOS (case-only difference) are refused together. Case-sensitive (a case-only mismatch gets "did you mean …"). Limits: 7 folders deep, 200 chars, 200 files, 1 MB per file, 8 MB per plugin.
- Multiple returns follow the usual rule: `local a, b = loadModule("x")` gets both, `local t = loadModule("x")` the first.
- Hooks (`init`, `onConnect`, …) may be defined in any module loaded while the main script runs.
- A `local function` in a module is ALSO reachable as a global (compatibility behaviour) — don't rely on it; put shared functions in your shared table.
- Load-once: `if not PkCore.ui then loadModule("ui/theme.lua") end` — `loadModule` itself has no cache.
- Libraries loaded with `require` have no `loadModule`/`dofile`/`loadfile`; a module cannot load another plugin's files; trigger/alias scripts and Ctrl+I are not a plugin and get an error saying so.
- Errors: a module error stops the load (a PLUGIN ERROR notice with `where  classes/druid.lua line 12`); errors thrown later by a module's functions name the same file in their `where` row. Wrap optional modules: `local ok, err = pcall(loadModule, "extras.lua")`. A syntax error reads like Lua's too (`bad.lua:2: <name> expected near '='`, also as `loadfile`'s second value); `error(msg, 0)` inside a module is passed on exactly as written, with no `file:line:`.

Where the files live: the player adds them in the Plugin Editor's **Files** panel (all platforms); on desktop they are also in a folder named after the plugin beside its main `.lua` (`~/MudForge/plugins/PK System/ui/theme.lua`) and saving any of them hot-reloads the plugin. Plugin Manager exports a multi-file plugin as one `.zip` (main `<name>.lua` + `<name>/…`) and imports that, or a zipped Mudlet-style folder of `.lua` files (main script = the only top-level `.lua`, else the one named after the zip/folder, else `init.lua`/`main.lua`/`bootstrap.lua`/`loader.lua`/`start.lua`; a `<name>.lua` + `<name>/` pair counts as an export only when it is the only top-level `.lua` or is named after the zip). Any `.lua` left out is named on the terminal. A `files` table in a `.json` plugin (import, repository, URL reinstall) is checked by the same path rules and limits; a set that breaks them refuses the whole import. World export, Save History, Sync and `.mfp` packages carry module files with the plugin.

When you WRITE a multi-file plugin, give each file separately and say which path it goes at:

```lua
-- MAIN SCRIPT
plugin = { name = "PK System", version = "1.0.0", author = "You", description = "Split into modules" }
PkCore = PkCore or {}
loadModule("module_registration.lua")
function init() PkCore.ui.banner("ready") end
```

```lua
-- module_registration.lua  (the load order, in one place)
loadModule("ui/theme.lua")          -- first: others use PkCore.ui
loadModule("classes/druid.lua")
loadModule("reactor_modes/strategies/aggressive.lua")   -- last: uses PkCore.classes
```

```lua
-- ui/theme.lua
PkCore.ui = {}
local accent = "<cyan>"                       -- private to this file
function PkCore.ui.banner(text) cecho(accent .. "[PK] <reset>" .. text) end
```

Porting: Mudlet `loadfile(getMudletHomeDir() .. "/pk/" .. name)` → `loadfile(name)` (or `loadModule(name)`); MUSHclient `dofile(GetPluginInfo(GetPluginID(), 20) .. "x.lua")` → `dofile("x.lua")`.

## 16.5. Server packages (`.mfp` + GMCP `Client.Package`)

MUD servers can recommend an installable content bundle to the client. As a plugin/package author, the essentials:

- **Advertisement:** the server sends GMCP `Client.Package` with at minimum `url` (HTTPS) + `version`, optionally `client` (`"MudForge"`, case-insensitive; omit to target all clients), `name`, `sha256`, `description`, `date`, `releaseNotes`, `required` (hint only — consent is ALWAYS prompted), `minClientVersion`. Three shapes accepted: single object, array of objects, or object keyed by client name. The client advertises `"Client.Package 1"` in `Core.Supports.Set`.
- **Bundle:** a `.mfp` is a ZIP — a `.mfw` world file **minus `world.json`** (bundles containing one are hard-rejected; packages can never carry connection data) **plus a `package.json` manifest** (`formatVersion: 1`, `packageId`, `name`, `version`, `contents[]`, optional `plugins[]`, `libs[]`, `applyTheme`, `minClientVersion`).
- **Contents:** `triggers/aliases/macros/timers/variables/commands/sounds` (arrays, merged by id, provenance-tagged `__pkg`), `themes.json` (added to the global theme library; `applyTheme` or the first theme auto-applies, reverted on uninstall), `layout.json` (whole-object apply with pre-install snapshot), `settings.json` (whitelist: `appSettings`, `soundSettings`, `statusBarSettings`, `groupWidgetSettings`; every touched key records its prior value), `plugins/manifest.json` + `plugins/<id>.lua`, `libs/<name>.lua`, `maps/*` (additive — existing rooms never modified), `border-images/<id>`, `widget-bg-images/<id>`.
- **Id collisions:** a package item whose id matches a USER item is renamed (`<id>-pkg`) — user data is never overwritten, and uninstall removes exactly the package's tagged items.
- **Re-advertising is expected.** Servers normally send `Client.Package` on every login; the client is what stays quiet. An installed package is recognized again by the advertised `name`, the `url`, and the manifest `packageId`, so an offer is suppressed even when your manifest id (`com.mymud.ui`) looks nothing like the advertised name.
- **Keep the advertised `version` equal to the manifest `version`.** These are the two halves of update detection: the advertisement says what is on offer, the manifest says what actually got installed. If the advertisement claims a version the bundle doesn't carry, the client installs something it can never mark as up to date and the player is re-prompted on every login. Bump both together, and note that a package's `packageId` must stay stable across versions — changing it orphans every existing install instead of updating it.
- **Trust model:** sha256-verified when advertised; without a hash the consent dialog shows an "unverified source" warning and Lua content (plugins AND libs) needs an extra explicit opt-in. Installing a package does NOT grant its plugins HTTP permission — the per-domain runtime prompts still apply.
- **Management:** Settings → Packages lists installed packages per world with clean uninstall (removes tagged items, unloads plugins/libs, deletes package themes/images unless pre-existing/shared, reverts settings keys, restores the layout snapshot).
- **Authoring:** build the setup in a MudForge world, then **Settings → Packages → Create Package** — pick the content (your own items only; other packages' `__pkg`-tagged content is never re-shipped), fill in the manifest, and the client emits a validated `.mfp`, its sha256, and the ready-to-paste `Client.Package` advertisement line.
- **Testing before you publish:** **Settings → Packages → Import Package** loads a `.mfp` straight from disk through the same consent prompt, install and uninstall path a server-advertised package uses — so the build → load → check loop needs no hosting. A local file has no advertised sha256, so it is treated as unverified and any Lua stays behind the extra opt-in.

Full wire-format + authoring spec for MUD admins: `/docs/client-package-spec.md` (`public/docs/client-package-spec.md`; the same material is in-client under Help → Client.Package (MUD admins)).

---

## 16.6. Publishing to a plugin repository

A **plugin repository** is how a plugin gets into someone else's client without them importing a file by hand. It is just static hosting — no server code.

**Layout.** A repository is any HTTPS URL serving an index plus the plugin bodies it points at:

```
https://your.host/mudforge/plugins/
  plugins.json          <- the index the client fetches
  files/
    your-plugin.lua     <- the plugin body
```

**Your Lua stays a normal `.lua` file.** `plugins.json` is a *catalogue*, not a container: it lists plugins and points at them, and your script is never escaped into a JSON string. Write the plugin the way you always would, upload it, describe it in the index. (A JSON *plugin record* with the source inside a `script` field is also accepted — see `format` below — but it exists for exporting an installed plugin, not as the way to publish one.)

**Index format.** `plugins.json` is either a bare array of listings, or (preferred) an object:

```json
{
  "schemaVersion": 1,
  "name": "My Plugin Repository",
  "description": "Plugins for my MUD.",
  "plugins": [
    {
      "id": "kill-counter",
      "name": "Kill Counter",
      "version": "1.0.0",
      "author": "You",
      "description": "Counts your kills.",
      "category": "utilities",
      "tags": ["combat", "statistics"],
      "downloadUrl": "files/kill-counter.lua",
      "format": "lua",
      "sha256": "…64 hex chars…",
      "size": 5018,
      "license": "MIT",
      "lastUpdated": "2026-08-04T00:00:00.000Z",
      "featured": false
    }
  ]
}
```

- `id` must be unique within the repository and is what the client keys installs on — **never change it** across versions or every user gets a duplicate rather than an update.
- `downloadUrl` may be relative (resolved against the repository root, so mirrors work) or absolute.
- `format` is `"lua"` for a raw plugin source (the normal case) or `"json"` for a serialised plugin record with a `script` field. Omitted, it is inferred from the URL extension: anything that is not `.json` is read as Lua, so a `.lua` URL needs no `format` at all. For a raw `.lua` download the LISTING is the authority for identity — name/version/author/description come from the index and the file's `plugin = { … }` table only fills gaps — so bump `version` here when you upload a new file, or the client will not see an update.
- `category` must be one of: `widgets`, `automation`, `ui-enhancement`, `mapping`, `combat`, `roleplay`, `utilities`, `themes`, `development`.
- `version` accepts `1`, `1.0` or `1.0.0` and is compared component-by-component to decide what counts as an update. A major bump is flagged **critical** in the Updates tab.
- `rating` and `downloads` are optional — omit them rather than inventing numbers; the client simply hides what you do not publish.

**Publish a `sha256`.** It is the lowercase hex SHA-256 of the exact bytes served at `downloadUrl`. Users running with *Verify plugin integrity* on (the default) **cannot install a plugin that has no hash**, and a hash that fails to match is refused for everyone regardless of the setting. Recompute it every time you change the file.

**CORS.** The index and plugin files must be readable cross-origin — send `Access-Control-Allow-Origin: *`. Without it, the web client cannot read your repository.

**Generating the index.** For plugins kept in a source tree, `scripts/build-plugin-repo.mjs` builds the whole repository from `scripts/plugin-repo-manifest.json` — it reads each plugin's `plugin = { … }` metadata table for name/author/version/description, computes hashes and sizes, and refuses to publish anything it cannot describe:

```bash
node scripts/build-plugin-repo.mjs --out dist/plugin-repo --base-url https://your.host/mudforge/plugins
```

That is also why a published plugin needs a real metadata table (see §2) — a plugin with no `plugin = { name = …, version = … }` cannot be indexed.

**Hosting on GitHub or GitLab.** Commit `plugins.json` (and your `.lua` files) to a repository and users can paste the ordinary browser URL — `https://github.com/you/my-plugins`. The client rewrites it to the raw-file host itself, because `github.com` serves an HTML page and `<that>/plugins.json` would 404:

| Pasted | Fetched from |
| --- | --- |
| `https://github.com/you/repo` | `https://raw.githubusercontent.com/you/repo/HEAD/plugins.json` |
| `https://github.com/you/repo/tree/main/plugins` | `https://raw.githubusercontent.com/you/repo/main/plugins/plugins.json` |
| `https://gitlab.com/you/repo` | `https://gitlab.com/you/repo/-/raw/HEAD/plugins.json` |

`HEAD` means the repository's default branch, so it does not matter whether you named it `main` or `master`. Relative `downloadUrl`s resolve against the same raw base, so `"downloadUrl": "files/x.lua"` works unchanged on a mirror or a fork. Both raw hosts send `Access-Control-Allow-Origin: *`, so no extra configuration is needed.

**Users add it** in Plugin Manager → Repositories → Add Repository, pasting the repository URL (or, for other hosts, the folder containing `plugins.json`, or the `plugins.json` URL itself). The client fetches the index there and then and reports the true plugin count; a repository that does not answer cannot be added.

### Publishing libraries

A repository can publish shared libraries alongside its plugins, in the **same** `plugins.json`, under an optional `libraries` array. A repository that omits it is completely valid — nothing about the plugin side changes.

```json
{
  "schemaVersion": 1,
  "plugins": [ ... ],
  "libraries": [
    {
      "name": "string",
      "version": "1.0.0",
      "author": "MudForge",
      "description": "String utilities — split, trim, stripAnsi, wordWrap, padding, and more",
      "downloadUrl": "libs/string.lua",
      "sha256": "7834c0b0…",
      "size": 14622,
      "license": "MIT",
      "tags": ["strings", "text", "utilities"],
      "lastUpdated": "2026-08-31T11:50:57.914Z"
    }
  ]
}
```

- `name` **is** the `require()` module name, so it must match `^[a-zA-Z0-9_-]+$`, be ≤ 64 chars, and match the filename. A listing that fails those rules is dropped from the index with a log line rather than failing to install later with a confusing "module not found".
- `downloadUrl` may be relative to the repository, exactly like a plugin's.
- `sha256` is verified on install. A repository publishing no hash cannot pass the user's "Verify plugin integrity" setting.
- Library sources are capped at **256 KB**, the same limit a `.mfp` package's libraries face.

To be publishable, a library needs a `library = { ... }` metadata table — the same rule plugins live with, so a listing can never carry an invented name or version:

```lua
-- libs/mylib.lua
library = {
  name = "mylib",          -- must match the filename
  version = "1.2.0",
  description = "Does the thing",
  author = "Your name",
  license = "MIT",
}

local mylib = {}
function mylib.hello() return "hi" end
return mylib
```

The table is optional for a library that is only ever used locally; it is required only to publish one.

**Generating the index.** `scripts/build-plugin-repo.mjs` handles libraries alongside plugins, reading them from `public/libs/` and describing them from their own metadata table. Add an entry under `libraries` in `scripts/plugin-repo-manifest.json` — `tags` is the only catalogue-side field, since everything else comes from the Lua source:

```json
{
  "plugins":   [ { "file": "my-plugin.lua", "category": "utilities", "tags": ["example"] } ],
  "libraries": [ { "file": "mylib.lua", "tags": ["utilities"] } ]
}
```

```bash
pnpm plugin-repo:build                 # index + files/ + libs/ into dist/plugin-repo
bash scripts/deploy-plugin-repo.sh     # upload, then verify the live endpoint matches
```

The build **fails** rather than publishing something it cannot describe: a library with no parseable `library = { ... }` table, a name `require()` could not resolve, a name that disagrees with the filename, a duplicate name, or a source over the 256 KB cap. Plugin and library problems are reported together in one run.

**Users install** from Plugin Manager → Libraries → Check repositories. An installed library is kept on the device (not re-fetched at startup), works offline, and is available to every world.

---

## 17. Lua 5.1 (luaparse → JS transpile) gotchas

- `string.format` supports `%s %d %i %o %x %X %e %E %f %F %g %G %c %%`. **Not supported:** `%u`, `%q`, `%b`, `%n`. Width, padding (`0` and space), `-` left-align, and precision work for the types where they make sense. An unsupported specifier is printed literally and does NOT use up its argument, so the arguments after it shift.
- `#t` on tables with holes is undefined. Use `table.maxn(t)` or maintain an explicit `n` field.
- `pairs(t)` iterates in unspecified order. `ipairs(t)` stops at the first nil — never put `nil` in the middle of an array-style table.
- Tables are the only structured data type; there are no arrays. A "list" is a table with keys `1..n`.
- `==` does not coerce — `1 == "1"` is `false`.
- Strings are immutable; `s[1]` does not work. Use `string.sub(s, 1, 1)`.
- No 5.2+ features: **no `goto`, no integer division `//`, no bitwise `& | ~ << >>`, no `_ENV`, no `\z` string escape, no integer subtype**.
- `function f(self, …)` and `function obj:method(…)` work identically to Lua 5.1.
- Reading a key that isn't there gives `nil` — but **indexing something that is itself nil raises an error**, exactly as in standard Lua:

  ```lua
  local room = {}
  local n = room.exits          -- fine: nil
  local n = room.exits.north    -- ERROR: attempt to index a nil value (field 'exits')
  ```

  The message names the nil value (`local 'x'`, `global 'x'`, `field 'x'`) and the terminal shows the Lua line number. Guard the intermediate step when a table may legitimately be absent:

  ```lua
  local exits = room.exits
  if exits then handle(exits.north) end
  -- or, for a single read:
  local north = room.exits and room.exits.north
  ```

  This applies to both `a.b` and `a["b"]` — they behave identically, on desktop and web alike.
- Multiple return values: assigning several names gets all of them (`local from, to = string.find(s, "x")`), and `return f()` passes them all on; assigning one name gives the **first** value (`local pos = string.find(s, "x")` is the number). Everywhere else a call also gives only its FIRST value — including as the last argument of another call and inside a table constructor, where Lua would expand it: `print(string.find(s, "x"))` passes one value and `{ f() }` holds one. `unpack(t)`, `table.unpack(t)` and `select(n, ...)` are different: assigned to ONE name or passed as an argument they give the whole list as a table, so `string.format("%d %d", unpack(t))` does not work — unpack into names first (`local a, b = unpack(t)`). Some API functions that return several values (e.g. the mapper's `getPath`) also hand a single receiver the whole list — destructure them. `string.gsub` returns the replaced string but not the count. `...` itself works (`{...}`, `select("#", ...)`, `local a, b = ...`).
- Scoping follows Lua 5.1. A `local` (or `local function`) is visible to the rest of its block and to functions nested in it, and nowhere else — the same helper name declared in several functions (`local function add(x) t[#t + 1] = x end` in each string builder) is a separate local each time. Shadowing works too: re-declaring a name makes a **new** local, so a closure created earlier keeps the value it captured, and `local n = n + 1` reads the outer `n` rather than itself.

- A local is not in scope inside its own initializer, which matters for recursion:

  ```lua
  local fib = function(n) return fib(n - 1) end   -- `fib` inside is the GLOBAL fib (nil)
  local function fib(n) return fib(n - 1) end     -- correct: the local IS in scope in its own body
  ```

- **Metatables are not available.** `setmetatable`/`getmetatable` do not exist, so `__index`, operator overloading and metatable-based OO will not work. Use plain tables and functions. The call raises rather than quietly doing nothing, so you find out at once.
- **Coroutines are not available.** There is no `coroutine` library. For anything that needs to wait, use a timer and a callback.
- **The `%f` frontier pattern is not supported.** Every other Lua pattern class works; anchor with `^` or match a surrounding character instead. It does not raise an error — it returns wrong matches.
- **nil does not raise in arithmetic or concatenation.** Real Lua stops with "attempt to perform arithmetic on a nil value" / "attempt to concatenate a nil value"; here a nil local or missing field acts as 0 (`x + 1` is `1`), a never-assigned global gives `NaN`, and `"a" .. nil` is just `"a"`. Check values before using them — a mistyped name will not announce itself.
- Strings are sequences of characters, not bytes: `#s`, `string.len` and `string.sub` count characters, and `string.byte` returns the character code (`string.byte("é")` is 233, not 195). Byte-oriented code (hashes, binary parsing) must not assume UTF-8 bytes — except `pickFile`'s `binary = true` data, which is one character per byte.
- `tostring(t)` of a table is `"[object Object]"` (no address — don't use it as an identity key); `tonumber("")` is `0`, not nil; `string.format("%s", nil)` gives `"null"` — use `tostring(v)` when a value may be nil.
- `%` is Lua's **floored** modulo, so the result takes the sign of the right operand (`-5 % 3` is `1`). `math.fmod` is the truncated one (`math.fmod(-5, 3)` is `-2`), exactly as Lua defines them.
- `table.sort` with no comparator orders by value, so numbers sort numerically and strings alphabetically.
- One deliberate leniency remains: a `local function` is also mirrored into `_G` unless an API function already owns that name, so a helper called from **above** its declaration, or from outside the block that declared it, still resolves. Real Lua would not find it. Do not rely on it for a helper named after an API function (`send`, `echo`, …): from outside its scope, that name is the API.

---

## 18. Worked examples

### 18.1 Canvas dashboard

```lua
plugin = {
  id = "stats-dash", name = "Stats Dashboard", version = "1.0.0",
  author = "AI", description = "HP/MP bars driven by GMCP Char.Vitals.",
  settings = { saveState = false },
}

local widgetId
local vitals = { hp = 0, maxhp = 1, mp = 0, maxmp = 1 }

local function redraw()
  setActiveWidget(widgetId)
  clear("#101418")
  drawText("HP", 8, 22, "#ffaaaa", "14px monospace")
  drawRect(40, 10, 200, 16, "#330000", "#664444")
  drawRect(40, 10, math.floor(200 * vitals.hp / math.max(1, vitals.maxhp)), 16, "#cc3344")
  drawText(string.format("%d / %d", vitals.hp, vitals.maxhp), 250, 22, "#ddd")

  drawText("MP", 8, 50, "#aaaaff", "14px monospace")
  drawRect(40, 38, 200, 16, "#001133", "#445566")
  drawRect(40, 38, math.floor(200 * vitals.mp / math.max(1, vitals.maxmp)), 16, "#3366cc")
  drawText(string.format("%d / %d", vitals.mp, vitals.maxmp), 250, 50, "#ddd")
end

function init()
  widgetId = createWidget({
    type = "canvas", title = "Vitals",
    position = { x = 50, y = 50 },
    size = { width = 320, height = 70 },
  })
  redraw()
  onGMCPUpdate("Char.Vitals", function(data)
    vitals.hp    = tonumber(data.hp)    or vitals.hp
    vitals.maxhp = tonumber(data.maxhp) or vitals.maxhp
    vitals.mp    = tonumber(data.mp)    or vitals.mp
    vitals.maxmp = tonumber(data.maxmp) or vitals.maxmp
    redraw()
  end)
end

function cleanup() end

```

### 18.2 Trigger-driven echo

```lua
plugin = {
  id = "xp-tracker", name = "XP Tracker", version = "1.0.0",
  author = "AI", description = "Sums XP gains since startup.",
  settings = { saveState = true },
}

local total = 0

function init()
  total = tonumber(getVariable("total") or "0") or 0
  -- Regex mode (3rd arg = true). Use JS regex, NOT Lua patterns: \d not %d.
  addTrigger("^You gain (\\d+) experience", function(captures, line, wildcards)
    local gain = tonumber(wildcards[1]) or 0
    total = total + gain
    setVariable("total", tostring(total))
    echo(string.format("[XP] +%d (session total: %d)", gain, total), "#88ff88")
  end, true)
end

function cleanup() end

```

### 18.3 Repeating timer with bounded rate

```lua
plugin = {
  id = "auto-look", name = "Auto Look", version = "1.0.0",
  author = "AI", description = "Sends `look` every 30 seconds while connected.",
  settings = { saveState = false },
}

local timerId

function init()
  timerId = addTimer(30000, function() send("look") end, true)
end

function cleanup()
  if timerId and timerId ~= "" then removeTimer(timerId) end
end

```

### 18.4 HTTP webhook

```lua
plugin = {
  id = "deathnotify", name = "Death Notifier", version = "1.0.0",
  author = "AI", description = "Posts to a webhook when you die.",
  settings = { saveState = true },
}

local WEBHOOK = "https://example.com/hook"  -- user should override via a command

function init()
  registerCommand("setwebhook", function(url)
    setVariable("webhook", url)
    echo("Webhook saved.", "#88ff88")
  end, "Set the death-notify webhook URL")

  -- Substring match (default): any line containing "You have been killed" fires this.
  addTrigger("You have been killed", function()
    local url = getVariable("webhook") or WEBHOOK
    http.post(url, json.encode({ text = "I died." }), { ["Content-Type"] = "application/json" })
  end)
end

function cleanup() end

```

### 18.5 Library + consumer plugin

`/public/libs/formatter.lua`:

```lua
local M = {}
local _api = {}

function M.init(apis) _api = apis or {} end

function M.banner(text)
  local line = string.rep("=", #text + 4)
  if _api.echo then
    _api.echo(line, "#ffaa44")
    _api.echo("  " .. text, "#ffcc88")
    _api.echo(line, "#ffaa44")
  end
  return line
end

return M
```

`/public/plugins/welcome.lua`:

```lua
plugin = {
  id = "welcome", name = "Welcome Banner", version = "1.0.0",
  author = "AI", description = "Demonstrates library use.",
  settings = { saveState = false },
}

function init()
  local fmt = require("formatter")
  fmt.init({ echo = echo })
  fmt.banner("Welcome back, adventurer!")
end

function cleanup() end

```

Don't forget to register `formatter` in `/public/libs/manifest.json` for web builds.

---

## 19. Common pitfalls — DO NOT do these

- Do **not** put `widgetId` as the first arg to `drawRect` / `drawText` / any other drawing function. That is the obsolete legacy API.
- Do **not** call drawing functions without calling `setActiveWidget` first (except immediately after `createWidget`, which sets it automatically).
- Do **not** use `os.execute`, `io.popen`, raw `io.read`, `debug.*`, `loadstring` or `load`. Do **not** pass `dofile`/`loadfile`/`loadModule` an absolute path, a `getMudletHomeDir()`-built path or `..` — they load only the plugin's own module files, by relative path (§16.4). (`io`/`os` exist as web-safe stubs — see §3 — but the shell/popen members are dead.)
- Do **not** call `send`, `echo`, `addTrigger`, `createWidget`, or any other plugin API from inside a library. Inject them through an explicit `lib.init({ … })` function instead.
- Do **not** assume `addTrigger` uses Lua patterns or regex by default. The default `type = "substring"` is plain literal text match (case-insensitive `indexOf`), with `*`/`?` triggering wildcard mode. For capture groups, pass `true` as the third arg (legacy boolean) or `{ type = "regex" }` (options form) and write **JavaScript** regex (`\d`, `\s`, `\w`), not Lua patterns (`%d`, `%s`, `%w`).
- Do **not** write Lua-pattern syntax (`%w`, `%d`) into `addAlias`. **Aliases use JavaScript regex** — use `\w`, `\d`, `\s`.
- Do **not** assume the trigger callback receives `(line, clean, wildcards)`. The real signature is `(captures, line, wildcards, rawLine)` — captures come first.
- Do **not** assume `addAlias`'s callback receives multiple args. It receives **one** arg: a table where `matches[1]` is the full match, `matches[2]` is the first capture, etc.
- Do **not** pass a Lua table to `http.post` expecting auto-encode. The body must be a string — wrap tables with `json.encode(…)`.
- Do **not** use `http.put`, `http.delete`, or HTTP (plain) URLs. Only `http.get` and `http.post` to HTTPS URLs are accepted.
- Do **not** store non-string values with `setVariable` and expect them to round-trip. Use `saveTable(name, { … })` for structured data.
- Do **not** spawn unbounded timers. Burst cap is 100, sustained rate is 30/sec, hard ceiling is 500 live timers per plugin.
- Do **not** use `goto`, `//`, or bitwise operators. The parser rejects them.
- Do **not** generate `require("./foo")`, `require("foo.lua")`, or `require("foo.bar")`. Flat names only matching `^[a-zA-Z0-9_-]+$`, ≤ 64 chars.
- Do **not** include `engineType` in `plugin.settings`. It is parsed but ignored.
- Do **not** expect `math.randomseed` to do anything — it is a no-op stub. `math.random` uses the host `Math.random` and cannot be seeded.
- `getCurrentRoom`, `getAllGMCPData`, `onGMCPUpdateGlobal`, `getGMCPDataFromSession`, `findTriggerByName`, `toggleTriggerByName` ARE callable (shared base API) — they do **not** throw. Prefer the canonical forms `getGMCPData(pkg)`, `onGMCPUpdate(pkg, cb)`, and `EnableTrigger(name, bool)` for clarity.
- Do **not** put `nil` in the middle of an array-style table; `ipairs` and `#t` will stop there.
- Do **not** assume `pairs` iterates in insertion order. It does not.
- Do **not** make blocking HTTP requests in a tight loop. Each request prompts the user for permission (first time per domain) and counts against rate limits.
- Do **not** create new widgets inside event handlers without cleaning up the old ones — widgets stack up fast.

---

## 19.5. Editing plugins in the client

The client ships a plugin workbench (Plugin Manager → Editor, or Edit on any installed plugin). Everything it knows about the API comes from one structured catalogue that is verified against the real runtime, so what it suggests exists:

- **Completions** for every global function, lifecycle hook, event name, Lua library member (`string.*`, `table.*`, `math.*`, `json.*`, `http.*`) and the file's own locals — each with documentation. Inside a table argument (`createWidget({ … })`, `addTrigger(…, { … })`) it offers that table's keys; inside quotes it offers the accepted values (`"regex"`, event names, `"global"`).
- **Parameter hints** while typing arguments, **hover cards** with signature/parameters/example, **go to definition**, **find references**, **rename**, **outline**, and a token-aware **Format**.
- **Problems** with one-click fixes: syntax errors from the runtime's own parser, undefined names (with "did you mean"), a forgotten `local` inside a function, `%d`/`%w` in a JavaScript-regex trigger or alias, `captures[1]` for the first group, too many / missing arguments, a hook declared `local function`, duplicate hooks, `settings.engineType`, `return plugin`, `local plugin = {}`, missing `name`, an unknown `require()`.
- **Save (Ctrl+S)** hot-reloads a running plugin; **Save & Run (Ctrl+Enter)** also enables it. Load errors come back into Problems/Console with the Lua line. Unsaved work is kept as a **draft** across closes and reloads.
- **Screen readers:** with Screen Reader Mode on, the editor switches to its accessible layout (announced suggestions/problems, Tab leaves the editor, Alt+F1 for its help); the ⋯ menu offers a plain text editor.

**If you add or change an API function** you must update three places: the catalogue entry under `lib/plugin-api/entries/`, the help dialog, and this guide. A test boots the runtime and fails when the catalogue and the engine disagree, so a new function cannot ship without documentation the editor can show.

Functions documented but **not provided by the runtime** (they are `nil` at load): `drawRadialGradient`, `drawTab`, `drawTabGroup`, `drawTextAligned`, `drawTextWithShadow`, `drawImageAlpha`, `drawImagePart`, `drawImageRotated`, `getPixel`, `setPixel`, `clearWidget` (use `setActiveWidget(id)` then `clear()`). The editor flags them; do not generate calls to them. `drawRectOn` exists but is an inert stub that only logs a warning — never use it.

`GetTriggerWildcard` exists **only inside a trigger's own script** (a trigger whose *Send to* is *Script*). In plugin code it is `nil` and the editor flags it there — read the trigger callback's `wildcards` argument instead.

---

## 19.6. Hot reload from an external editor (desktop app)

On the **desktop app** a plugin can be written in any text editor (VS Code, Notepad++, Sublime, vim). Saving the file restarts the plugin with the new code about half a second later, in every open world that has it — no reinstall, no app restart. The browser version cannot see files on the computer; there the built-in Plugin Editor's Save does the same job.

**Which `.lua` files are watched, and which are not.** Two different files can hold a plugin's code, and they are easy to confuse:

| File | Where | Watched? | Editing it… |
|---|---|---|---|
| `<name>.lua` (and module files in a `<name>/` folder beside it) | The **plugins folder** on disk — `~/MudForge/plugins` on the desktop app | **Yes** (desktop app only) | reloads the plugin, as described in this section. |
| `worlds/<world>/plugins/<name>.lua` | Inside the app's own storage, shown in the **File Manager** (right-click a session tab) | **No** | is not possible — it is a read-only copy for browsing (§9, "Where the user can see it"). |

The running plugin's code is the copy kept in the plugin list. Saving a watched file copies the new code into that list. The other way round is NOT automatic: a **Plugin Editor** save updates the plugin list but does not rewrite the file on disk. So after editing in the Plugin Editor, the disk file is out of date until **Open in external editor** writes the current code back (keeping the old file as a backup, step 2 below). So when helping a desktop player: editing the watched file works, and so does editing in the Plugin Editor. Neither is "only a backup". Just reopen the file with Open in external editor after switching from one to the other.

**Step by step**

1. Plugin Manager (Ctrl+P) → **Installed**.
2. Next to the plugin's **Edit** button, press **Open in external editor** (the arrow-leaving-a-box icon). The plugin's `.lua` file opens in the computer's default editor; if the plugin had no file yet, one is written first. If the file on disk holds different code from the plugin (an older copy, while the plugin was changed in the client since), it is kept beside it as a backup (`PK System.lua.bak-20261015-013000`, UTC time), the plugin's current code is written in its place, and a terminal line names the backup — nothing is lost, and backups never trigger a reload.
3. Edit and **save**.
4. Once the file has been quiet for **half a second** (editors often save in several quick steps; the wait makes sure the finished file is read), the plugin is stopped — variables saved; its triggers, aliases, timers and widgets removed — and started again from the new code.
5. A toast says what happened, and the **bell** in the bottom bar (the notification center) keeps a notice of it.

**Where the files are:** `~/MudForge/plugins/` (Windows: `C:\Users\<you>\MudForge\plugins\`). Libraries loaded with `require()` live in `~/MudForge/libraries/`.

**How a saved file finds its plugin.** In order — the first step that finds a plugin decides:

1. The `id` in the file's `plugin = { … }` table, if an installed plugin declares the same id (in its stored code, or as its repository id). Renaming a plugin by editing its `name =` line (and even its file name) therefore still reloads it.
2. Otherwise the `name` in that table, if an installed plugin has that name.
3. Otherwise the file name without `.lua`, if an installed plugin has that name.

Names are compared ignoring case, spaces and punctuation. A file whose table cannot be read (half-written) is matched by its file name.

**Copies are not reloaded.** If the table (id or name) points at a plugin but the file's name is not that plugin's, and the plugin's own file still exists, the file is treated as a copy (e.g. "Save As" to start a new plugin): nothing is reloaded and the player is told, in the bell and the terminal, to give it its own `id` and `name` or import it as a new plugin. If the original file is gone, it was a rename and the plugin reloads. **So a new plugin started from a copy must get a new `id` and `name` before it is saved.** Punctuation is dropped from file names (spaces, `-` and `_` are kept); these are the names Open in external editor gives the files it creates:

| Plugin `name` | File |
|---|---|
| `Greeter` | `Greeter.lua` (or `greeter.lua`) |
| `Health Bar` | `Health Bar.lua` |
| `Bob's Tracker v2` | `Bobs Tracker v2.lua` |

A hand-named file may also leave the spaces out: `HealthBar.lua` still reaches `Health Bar`.

Saving a file that matches no installed plugin does **not** install it; the player gets a warning (toast, bell, and a yellow terminal line). To start a new plugin, create or import it in the Plugin Manager first, then use Open in external editor. Renaming a plugin means renaming its file to match. Deleting a file does not uninstall the plugin.

If the deciding step finds two plugins (`Health Bar` and `HealthBar`, with no id in the file to tell them apart), **neither** is reloaded and the player is warned with both names — give plugins names that differ by more than spaces, punctuation or case, and declare an `id`. Every save reloads the plugin — even a save with no changes, which is a quick way to restart it. The only files that never reload anything are the ones the app itself just wrote: a desktop import, or Open in external editor writing the plugin's code to disk (so an import does not start the plugin twice). A save of the same code a few seconds later is the player's and reloads.

**What the toast says**

| Toast | Meaning |
|---|---|
| *Reloaded Greeter* | The saved plugin is running the new code. Fades after a few seconds. |
| *Reloading 12 plugins…* | Many files changed at once (git checkout, find-and-replace, Save All). One toast keeps counting. |
| *Reloaded 50 plugins* | The batch finished — one second after the last file. One bell notice lists all 50 under "Show 50 items". |
| *Reloaded 49 plugins, 1 failed: Broken (line 3)* | One plugin's new code has an error. The toast **stays until closed**; the bell notice has the message. |
| *Broken failed to reload (line 3)* | The only saved plugin has an error and is not running until a fixed version is saved. |
| *notes.lua matches no plugin — nothing reloaded* | No installed plugin has that file's name. |
| *HealthBar.lua matches 2 plugins — nothing reloaded* | The file fits two plugins (names differ only by spaces, punctuation or case, no id to tell them apart); neither was reloaded. Rename one. |
| *New Thing.lua looks like a copy of Health Bar — nothing reloaded* | The file's table belongs to Health Bar, whose own file still exists; give it its own id and name, or import it. |
| *Greeter is turned off — change not loaded* | Installed but switched off; turning it on starts it with the saved code. |
| *Reloaded library utils — 3 plugins reloaded* | A library was saved; every running plugin that uses it was restarted. |
| *Library utils has an error (line 12)* | The library's new code does not load; plugins using it keep the last version that worked. |

However many files change and however many worlds are open, there is **one** toast and **one** bell notice per batch. A plugin installed in one world but not another is not reported as "matches no plugin" — reloading anywhere counts. When the batch ends, a new toast with the result replaces the *Reloading…* one, so another toast in the meantime cannot hide it; a *Reloading…* toast the player closed does not come back (the bell still has the result).

**Errors.** A load error is written to the terminal as a PLUGIN ERROR notice naming the plugin and the line (`problem  Parse error: ')' expected near 'end'`, note "It is not running now. Fix the error and save the file again to reload it."), exactly like any other plugin error, and the toast stays up. "Reloaded" means the new code loaded; `init()` runs a moment later, and errors there (or later, in a trigger or timer) are reported in the terminal as always. The line Lua names is where it *noticed* the problem — a missing `)` is often reported on the next line.

**Example.** Create this plugin in the Plugin Manager's Editor, save, and turn it on:

```lua
plugin = {
  name = "Greeter",
  version = "1.0.0",
}

function plugin.init()
  echo("Greeter says hello!")
end
```

Then Installed → Greeter → Open in external editor (opens `Greeter.lua`), change the message and save: the terminal prints the new greeting and the toast says *Reloaded Greeter*. Delete the `)` after the message and save: a red error appears and the toast says *Greeter failed to reload (line 8)* and stays. Put it back and save: *Reloaded Greeter*.

**Notification center (the bell).** Notices are kept until cleared or until the client is closed or reloaded (newest 200). Opening the list marks them seen; × dismisses one; Clear all empties it; repeated identical notices become one entry "(N times)". For screen readers the bell's name carries the count ("Notifications, 3 unread"), the list never speaks on its own, the outcome of a reload is announced once, and every problem is also written to the terminal. The phone layout has no bell.

**Guidance when helping a player:** tell them to use Open in external editor rather than creating a file by hand (the file then has the right name), and keep the plugin's `name` and the file name in step if either changes.

---

## 20. Quick reference card

```
# Plugin shape:
plugin = { id, name, version, author, description, settings = { saveState = true } }
function init() … end
function cleanup() … end

# Widgets:
id = createWidget{ type="canvas", title=…, position={x=…, y=…}, size={width=…, height=…} }
setActiveWidget(id)
clear(color?); drawRect(x,y,w,h,fill,stroke?); drawText(text,x,y,color,font?)
getWidgetFont(id) → { family, size, weight, css }   -- draw with the font the user picked
registerWidgetEvent(id, "click", function(event) … end)
html = gaugeHTML{ id="hp", label="HP", look="party" }   -- library gauge markup for an HTML widget
setGauge(id, "hp", value, max?); setGauges(id, { hp = { value=…, max=… } })
getGaugeCatalog() → { styles, gradients, schemes, sets, asciiSets, fonts, overlays, outers, dangerSignals, textModes }

# MUD:
send(cmd); echo(text, color?); print(msg); utilprint(msg)

# Triggers / aliases / timers:
-- Default trigger type is substring (with * / ? wildcard upgrade). Pass `true` for regex:
addTrigger(substringOrJsRegex, function(captures, line, wildcards, rawLine) … end, isRegexBool_orOptionsTable)
addAlias(jsRegex, "", function(matches) … end, { name=…, caseSensitive=false })
addTimer(ms, callback, repeating?)
EnableTrigger(name, on?); EnableTriggerGroup(group, on?); EnableAlias(name, on?); EnableTimer(name, on?)  -- Settings items by name
DoAfter(seconds, cmd); DoAfterSpeedWalk(seconds, "3n2e(open door)w")   -- returns error_code.eOK (0)

# Persistence:
setVariable("k", "v"); getVariable("k")          -- add "global" as the last arg for the app-wide shared namespace
saveTable("t", { … });  loadTable("t")           -- this character + this plugin

# GMCP:
onGMCPUpdate("Char.Vitals", function(data) … end)

# Mudlet ports (§15.6):
registerAnonymousEventHandler("gmcp.Char.Vitals", function(event) local hp = gmcp.Char.Vitals.hp end)
raiseEvent("my event", arg); id = tempTimer(1.5, fn_or_luaString, repeating?); killTimer(id)
if exists("name", "alias") == 0 then permAlias("name", "", "^regex$", [[luaCode()]]) end
decho("<255,0,0>red<r>"); hecho("#00ff00green#r")

# HTTP / JSON (HTTPS only; body must be a string; callback gets (status, body, error)):
http.post(url, json.encode({ … }), { ["Content-Type"]="application/json" },
          function(status, body, err) … end)

# Libraries:
local lib = require("name")   -- name matches ^[a-zA-Z0-9_-]{1,64}$
lib.init({ echo = echo })     -- inject any plugin APIs the lib needs

# Multi-file plugins (this plugin's own module files, run in call order):
loadModule("ui/theme.lua")    -- = dofile(...); shared globals; throws "file:line: …"
local fn, err = loadfile("x.lua")
```

---

## 21. Error → likely cause

| Error message / symptom | Likely cause | Fix |
|--------------------------|--------------|-----|
| `attempt to call a nil value` / `X is not a function` | Calling a global that genuinely doesn't exist (typo, or a helper you never defined) — every global compiles to `_G.<name>`, so an unknown one is just nil. NOTE: `getCurrentRoom`, `getAllGMCPData`, `findTriggerByName`, … DO exist and are callable. | Check spelling; see §11/§12 for the canonical GMCP/trigger forms |
| Widget opens at (200, 150) regardless of what you passed | No `position` and no numeric top-level `x`, or a second widget with the same `name` (you got the first one's id back) | Pass `position` and a distinct `name` (§4) |
| Drawing functions appear to do nothing | No active widget — `setActiveWidget(id)` not called before `drawX` | Call `setActiveWidget(widgetId)` (auto-set only immediately after `createWidget` on a canvas) |
| Trigger never fires despite seeing the line | Used Lua-pattern syntax (`%d+`) with default substring matcher | Add `true` as 3rd arg or use `{ type = "regex" }` and write JS regex (`\d+`) (§7) |
| Trigger fires but `captures` is empty / has the whole line | Substring mode has no groups: the full line is `line` (and `captures[0]`); capture groups only work in wildcard and regex mode | Switch to regex mode |
| Trigger callback gets unexpected args | Callback signature is `(captures, line, wildcards, rawLine)` — not `(line, clean, wildcards)` | Declare args in the right order (§7) |
| `addAlias` callback fires but `args` looks wrong | The callback receives one table `matches` where `matches[1]` is the full match and `matches[2]+` are captures | See §7 alias subsection |
| `http.post: body must be a string` | Passed a Lua table | Wrap with `json.encode(table)` |
| `http.post` / `http.get` reply never arrives | No callback passed (errors are only delivered to the callback), callback passed in the headers slot, plain-HTTP URL, or blocked destination | Pass `nil` for headers and a callback as the last argument; read its `error` argument; use HTTPS to a public host (§13) |
| `module 'X' not found. Available libraries: …` | Library name typo, missing manifest entry, or library file absent | Check `/public/libs/manifest.json` and `/public/libs/X.lua` |
| `loadModule/dofile: module 'X' not found …` (or `loadfile:` as the `nil, message` answer) | The plugin has no module file at that path (typo, wrong case, different folder, or it was never added) | Add it in the Plugin Editor's Files panel, or fix the path — the message suggests the file it most likely meant (§16.4) |
| `X.lua:12: …` when the plugin loads | An error inside module file X at its line 12, raised while `loadModule` ran it | Fix that line in the module; wrap optional modules in `pcall(loadModule, "X.lua")` |
| `loadModule/dofile: modules nested more than 64 deep` | A module loads itself, directly or in a cycle | Load each module once from the main script or a registration file |
| `circular require detected: … → X` | Library A requires B which requires A | Restructure: extract shared parts to a third library |
| `require: invalid module name 'X'` | Path traversal attempt, dot, slash, or invalid char in module name | Use only `[a-zA-Z0-9_-]+` (≤64 chars) |
| Library throws `_G.send is not a function` (or `_G.echo`, `_G.addTrigger`, …) | Library is trying to call plugin APIs that aren't in its sandbox | Use the inject-APIs pattern: `lib.init({ send = send, echo = echo })` (§16) |
| PLUGIN WARNING: `addTimer did nothing` … reached its timer limit (500 live timers) | Spawning timers in a loop without cleanup | Use a single repeating timer; track and `removeTimer` old ones |
| PLUGIN WARNING: `send did nothing` — this world is not connected to a MUD | `send`/`addTimer` called when no MUD connection | Wait for the connection: do it from `onConnect` (shown once per disconnection) |
| Random JavaScript SyntaxError on plugin load | Lua 5.2+ feature (`goto`, `//`, `&`, `|`, `~`, `<<`, `>>`, `_ENV`) | Rewrite using Lua 5.1 idioms (§17) |
| Variables come back with the wrong type after reload | `setVariable` stores strings | For numbers, booleans and tables use `saveTable`, or convert with `tonumber` |
| Widget position resets every load | World file has saved coordinates that override `config.position` | Expected — the user's manual placement wins. Use `moveWidget`/`resizeWidget` to override at runtime |
| `moveWidget` / `resizeWidget` do nothing | The player docked the widget into the Dynamic widget layout, which then owns its place and size | Expected — the player's layout wins while it is docked. It works again once they float it (Shift + drop). React to the widget's resize event instead of setting a size |
| `attempt to index a nil value` after `getVariable` | Variable doesn't exist yet — returns `nil`, not `""` | Guard: `local v = getVariable("k") or ""` |
| `attempt to index a nil value (field 'x')` | You indexed something that is nil — `a.x.y` or `a["x"]["y"]` where `a.x` doesn't exist. The message names the nil thing, and the terminal shows the Lua line | Guard the intermediate: `local x = a.x; if x then ... end`, or `local y = a.x and a.x.y` |
| Lua-pattern with a negated class inside a set (`[%A]`, `[%L]`) doesn't match | Negated Lua classes have no in-set equivalent | Negate the whole set instead: `[^%a]`, `[^%l]` |
| `[Speedwalk] Not walked: … is not one: Invalid direction …` | The text sent as a speedwalk has something that is not speedwalk notation — a word, a comma, a MUSHclient door letter (`O`/`C`/`L`/`K`) or `F`. Nothing is walked | Put commands and doors in brackets — `3n(open n)2e`; if the text was meant for the MUD as written, change the item's Send To to World (§15.5 "Speedwalk notation") |
| `MUSHclient script function "X" is not defined` (or a timer's `it calls the script function "X", which does not exist`) | An item imported from MUSHclient has `script="X"`; the MUSHclient script file that defined `X` is not imported | Define a global `function X(name, line, wildcards)` in a Script trigger/alias or Ctrl+I (§7) — not in a plugin |
| `This script ran too long and was stopped` | A loop never finished — a `while`/`repeat` whose condition never becomes false, or a numeric `for` with a far larger bound than you meant. The client stops the script rather than freezing | Check the loop's exit condition. If the work is genuinely large, break it into chunks across `addTimer` calls so the client stays responsive |

---

## 22. Debugging your plugin

- `tprint(t)` — recursively dump a Lua table to the terminal. Best inspection tool.
- `print(msg)` — terminal output, plain text.
- `utilprint(msg)` — terminal output that interprets `$`-prefixed color codes.
- `setTimeout(fn, ms)` (or `addTimer(ms, fn)`) — defer work until after the current event handler returns; useful when you suspect ordering bugs.
- `widgetInfo(id, 21)` — check whether a canvas is ready before drawing.
- Turn on Plugin Manager → Settings → **Enable plugin debugging** for verbose plugin logs in the browser console (`plugin.settings.debugMode` has no effect).
- The browser console (DevTools) shows transpiler errors and library `print()` calls.
- When a trigger doesn't fire, log inside the callback first to confirm whether it's a match problem vs. a callback problem:
  ```lua
  addTrigger("You die", function(captures, line) print("[debug] died, line=" .. line) end)
  ```

---

*End of guide. If you find yourself wanting an API that isn't listed, it doesn't exist — emit a comment asking the user instead of inventing it.*
