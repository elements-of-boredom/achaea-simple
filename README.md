# PkCore

A custom PK/combat system for Achaea, built as a Mudlet profile package under the `PkCore` Lua namespace.

## Requirements

PkCore builds on top of two externally maintained Mudlet packages, which must already be installed in the profile:

- **[WunderSys](https://github.com/Wundersys-Mudlet/WunderSys)** ([docs](https://wundersys-mudlet.github.io/WunderSys/docs.html)) — curing engine, defence/affliction tracking, and prompt handling. PkCore reads and overrides pieces of WunderSys's state (`wsys.*`) rather than replacing it outright.
- **AK** (Affliction/Opponent Tracker) — [distribution](https://www.dropbox.com/scl/fo/04ci9tq4rivks1r4oar37/ABxzEVpvvrBvjv9V4IYc2s0?rlkey=kyu53u5f96w5ra05xkkvujd3d&e=4&dl=0) — target/limb/affliction tracking (`ak.*`, `affstrack.*`, `target`/`target2`). PkCore relies on AK as the authoritative source for opponent state rather than reimplementing it.

Install both packages into the profile before loading PkCore.

## Setup

Mudlet requires something in its own Script tree to auto-run on profile connect — PkCore keeps that to a single, permanent line so the rest of the system can live entirely in version-controlled files under `pk/`.

Add a Script item in Mudlet (e.g. named "Bootstrapping") containing just:

```lua
dofile(getMudletHomeDir() .. "/pk/bootstrap.lua")
```

This should never need to change again — `pk/bootstrap.lua` owns the actual load sequence (`pk/module_registration.lua`) and the `reload` alias used to pick up changes without reconnecting.
