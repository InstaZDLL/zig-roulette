# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
zig build              # Compile the application
zig build run          # Build and run the GTK app (sets GTK_THEME=Adwaita)
zig build test         # Run unit tests (src/game.zig only)
zig fmt src/*.zig build.zig   # Format
./scripts/opengrep.sh         # Static analysis (Opengrep); --sarif to emit opengrep.sarif
```

There is no single-test filter; `zig build test` runs the whole `game.zig` test block. To run one test in isolation, narrow it with `zig test src/game.zig --test-filter "<name substring>"`.

Requires Zig `0.16.0` and the GTK4 + libadwaita development packages (linked via `pkg-config`). The build also installs desktop integration files (`.desktop`, AppStream metainfo, SVG + PNG icons) under the app id `dev.instazdll.ZigRoulette`.

### Static analysis (Opengrep)

`scripts/opengrep.sh` runs [Opengrep](https://opengrep.dev) with `--config auto` (registry rules) plus the project rules in `.opengrep/rules/`. The same scan runs in CI (`.github/workflows/opengrep.yml`), which uploads SARIF to GitHub Code Scanning. **Zig is not a natively-supported language**, so `.zig` files are covered only by the `generic` (token-based) engine — add project rules to `.opengrep/rules/zig-generic.yml` with `languages: [generic]` and a `paths.include: ["*.zig"]` filter. `--config auto` needs no token (unlike Semgrep).

## Architecture

The codebase is split into focused modules so game rules are testable without a display server and the GTK frontend stays readable. The import graph is a clean DAG: `main → ui → render → app → gtk`, with `wheel`, `game`, and `audio` as shared leaves.

- **`src/game.zig`** — pure roulette logic, zero GTK dependencies. This is the **test root** declared in `build.zig`; all unit tests live here. Contains `GameState`, bet types (`BetKind` tagged union: straight/color/parity/range/dozen/column), payout math (`wins`, `payoutMultiplier`, `settle`), and validation. Keep this module GUI-free.
- **`src/gtk.zig`** — hand-written GTK4/libadwaita/Cairo/GLib `extern fn` bindings (no deps). Add new C symbols here.
- **`src/wheel.zig`** — pure wheel geometry (`order`, `sliceAngle`, `angleForNumber`) and spin easing (`lerp`, `easeOutCubic`, `normalizeAngle`). No GTK/game deps.
- **`src/audio.zig`** — self-contained SFX engine. Loads `libpulse-simple` at runtime via `dlopen` (no link-time dep, no headers): if absent, sound silently disables. Synthesises 16-bit PCM buffers (`chip`/`spin`/`win`) once at init and plays them on detached threads. No GTK deps.
- **`src/app.zig`** — the shared `AppState` (incl. the `Audio` instance) plus `HitZone`, `HistoryEntry`, and constants. Depends on `gtk` + `game` + `audio`.
- **`src/render.zig`** — Cairo draw funcs (`drawWheel`, `drawTable`) and the `ZoneColor` palette. Rebuilds `hit_zones` during `drawTable`.
- **`src/ui.zig`** — GTK glue: widget construction (`buildMenu`/`buildGame`), signal callbacks, spin animation, list/label refresh (`refreshUi`).
- **`src/main.zig`** — thin entry point: allocator, `AppState` init, GTK warning silencing, `activate`.
- **`src/style.css`** — the app stylesheet, loaded via `@embedFile("style.css")` in `ui.zig` (no longer an inline Zig string).

### Money model (`GameState`)
`balance` is the player's credits; `reserved` is the sum of staked-but-unsettled bets. `available() = balance - reserved`. `addBet` validates, checks against `available()`, and increments `reserved`. `settle(outcome)` computes returns, applies `balance += returned - wagered`, then clears bets and `reserved`. Winning returns include the stake (`amount * (multiplier + 1)`). Number `0` and any `> 36` lose all even-money/group bets.

### GTK binding style (`gtk.zig`)
GTK/Adwaita/Cairo/GLib are bound by **hand-written `extern fn` declarations** in `src/gtk.zig` (imported as `const gtk = @import("gtk.zig")`) — there is no `@cImport`. When you need a C function not yet bound, add its `extern fn` declaration there. C callbacks use `callconv(.c)`.

### State passing
A single heap-allocated `AppState` (created in `main`, freed via `defer`) holds the game state, RNG, animation fields, and every widget pointer. It is passed as the `user_data` (`?*anyopaque`) argument through GTK signal connections and cast back inside each callback. There is no other shared/global state.

### Spin animation
`spinClicked` picks the target number and seeds start/end angles; `g_timeout_add` repeatedly fires `spinTick`, which advances `wheel_angle`/`ball_angle` with `easeOutCubic` and calls `gtk_widget_queue_draw`. When ticks complete it calls `settle`, appends a `HistoryEntry`, and refreshes the UI. `drawWheel`/`drawTable` are Cairo draw funcs; table clicks hit-test against `hit_zones` (rebuilt during `drawTable`) to place bets.

### Conventions
- UI strings are **French** (`Rouge`, `Noir`, `Pair`, `Lancer`, etc.); `label()` methods on the game enums provide these.
- `main` uses `DebugAllocator` so leaks fail in debug builds. The `audio` engine pre-allocates its PCM buffers once and frees them in `Audio.deinit` (called first in `AppState.deinit`).
- This codebase uses the newer `std.array_list.Managed` API (Zig 0.16).
- GTK warnings are intentionally silenced via `g_log_set_handler` / `g_log_set_writer_func`.
