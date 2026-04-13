# ThumbyP8 Cart Compatibility

Last updated: 2026-04-13

## Status Key
- **Playable** — loads, controls work, plays to completion or reasonable extent
- **Partial** — loads but has issues (visual glitches, some features broken, eventual crash)
- **Broken** — crashes, hangs, or unplayable
- **Impossible** — exceeds hardware memory limits

## Test Results

| Cart | Status | Notes |
|------|--------|-------|
| 24981 (Mcraft) | Impossible | OOM on device |
| 49232 | Playable | Working |
| adelie-0 | Broken | OOM during _init |
| age_of_ants-9 | Broken | OOM during _update |
| air_delivery_1-3 | Partial | Title + gameplay render; a few sprites show as dark silhouettes (needs investigation on device) |
| beam4-2 | Playable | Working |
| celeste | Playable | Fully playable |
| celeste_classic_2-5 | Broken | Loads but only shows clouds, no gameplay |
| combopool-0 | Playable | Working |
| delunky102-0 | Playable | Working (same seed every time) |
| digger-2 | Playable | Working |
| dominion_ex-4 | Playable | Working |
| fafomajoje-0 (Dungeon) | Playable | Working |
| flipknight-0 | Playable | Working |
| fromrust_a-4 | Partial | Loads, crashes during gameplay |
| fsgupicozombiegarden121-0 | Broken | Needs mouse input (not supported) |
| highstakes-2 | Playable | Working |
| hotwax-5 | Broken | _init runtime error |
| kalikan_menu-6 | Untested on device | _init OK on host |
| mini_pharma-1 | Untested on device | _init OK on host |
| mossmoss-12 | Broken | OOM in _init |
| musabanebi-0 | Playable (device) | Plays fine; fuzz harness triggers a latent cart bug (nil index on P8SCII field) under random-input stress |
| pck404_512px_under-1 | Partial | Playable (P8SCII now renders correctly after font fix) |
| phoenix08-0 | Playable | Stars now single pixels after _ENV metatable fix |
| pico_arcade-2 | Untested on device | _init OK on host |
| pico_ball-5 | Partial | Loads after _ENV for-loop fix; gameplay not yet verified on device |
| picohot-0 | Partial | Loads after P8SCII font + _ENV fixes; some in-game errors may remain |
| picovalley-2 | Untested on device | _init OK on host |
| poom_0-9 | Partial | Title renders correctly (secret palette fix); crashes on level load |
| porklike-2 | Playable | Working (fixed by P8SCII identifier support) |
| praxis_fighter_x-2 | Broken | OOM during translation on host; untested on device |
| province-4 | Playable (device) | Plays fine; fuzz harness triggers compare-nil on an uninitialized-under-chaotic-input variable |
| rtype-5 | Partial | Loads and plays after _ENV fix; ERROR on long play (unverified) |
| ruwukawisa-0 | Playable | Fixed after _ENV metatable leak in foreach; fuzz can trigger an uninitialized-global error that doesn't occur in real play |
| slipways-1 | Broken | OOM during translation on host; hangs on load on device |
| start_picocraft_1-3 | Untested on device | _init OK on host |
| terra_1cart-43 | Broken | Hangs during translation (LZW decoder issue) |
| tinygolfpuzzles-1 | Playable | Working |
| woodworm-0 | Untested on device | _init OK on host |

## Summary

- **Playable**: 16 carts
- **Partial**: 7 carts
- **Broken**: 9 carts
- **Impossible**: 1 cart
- **Untested on device**: 6 carts

## Known Limitations

- Carts using mouse input (e.g. fsgupicozombiegarden) won't work — no mouse on Thumby Color
- Carts that OOM on a 300KB Lua heap can't run on device (300KB is the safe cap; hitting this with complex games is unavoidable)
- Arpeggio audio effects (fx 6 and 7) are silent — most music still sounds recognizable
- `extcmd`, `cstore`, `run`, `reset` etc. are no-ops (intentional for single-cart device)
- `menuitem()` is a no-op (custom pause menu entries not supported)
- Numerics use IEEE float, not PICO-8's 16.16 fixed-point — precision differs in low bits; some physics-heavy carts may drift

## Recent Fixes

### 2026-04-13
- `_ENV` compatibility: source rewriter handles `local _ENV = X`, `local a, _ENV = A, X`, `for _ENV in EXPR do`, and `function(_ENV)` patterns. Injects `_ENV = __p8_env(_ENV)` so bare identifiers fall through to globals.
- Host `dump_ppm` now routes through `p8_machine_present` — host screenshots match device LCD including secret palette.
- `tonum("42")` now returns the number 42 (was returning the string "42" unchanged because `lua_isnumber` returns true for numeric strings).
- `rrect` / `rrectfill` implemented with proper quarter-circle corners.
- `reload()` implemented (preserves ROM in XIP flash, zero SRAM cost on device).
- `cartdata`, `dget`, `dset` implemented with `.sav` files on device.
- `fillp(pat)` implemented, including 4x4 pattern + primary/secondary color + transparency.
- `tline` implemented for mode-7 floor effects.
- `btnp()` autorepeat (15-frame delay, 4-frame rate), with "ignore held button from last scene" logic to prevent carry-over.
- `time()` / `t()` now returns accurate elapsed seconds from hardware timer instead of frame-count / 30fps.
- `music(n, fade_len)` fade-in and fade-out implemented.
- `pal(table, p)` table form and `pal(nil)` reset form.
- `palt(N)` bitmask form.
- P8SCII glyphs 128..255 render as proper 7x5 bitmaps (was a fallback block).
- PICO-8 secret palette (colors 128..143) supported in `p8_machine_present`.

### 2026-04-12
- Audio: fixed severe distortion from rogue `*4` gain multiplier in master volume.
- P8SCII bytes (≥0x80) work as Lua identifier characters — fixes porklike and others.
- Host pipeline unified with device (shrinko8 + full PICO-8 dialect translation).
- API: `add(tbl,val,index)`, `count(tbl,val)`, multi-byte `peek`/`poke`.
- Button/arrow glyphs correctly map to button indices 0-5.
- All bitwise ops use 16.16 fixed-point via function calls.
- PXA decompressor: removed 32-iteration limit on back-ref length.
- RNG seeded from hardware timer at cart launch.
- In-game pause menu with volume, FPS toggle, disk/battery info.
- Lobby skipped when carts exist — boots straight to picker.

## Known unresolved errors

### Real (reproduces in normal play)

- **adelie-0, age_of_ants-9, mossmoss-12**: OOM during `_init` — heap cap.
- **24981 (Mcraft)**: OOM.
- **praxis_fighter_x-2, slipways-1**: OOM during translation — cart too large for translator's working memory.
- **terra_1cart-43**: translation hangs — suspected LZW decoder pathology.

### Fuzz-only (NOT reproduced in normal play)

The fuzz harness presses ~4 random buttons per frame plus A pulsing.
That's far more chaotic than real input and drives carts into states
human players never reach. Several carts throw errors under fuzz that
are harmless in real play:

- **ruwukawisa-0**: `arithmetic on 'wfr' (nil)` — walking-frame global not set under chaotic input.
- **province-4**: `compare number with nil` — state variable uninitialized under fuzz conditions.
- **musabanebi-0**: `index field '?' (nil)` — P8SCII glyph used as table key, populated lazily.
- **delunky102-0**: OOM after many levels under fuzz; real play stays under heap cap.
- **pico_ball-5**: *Fixed* — for-loop `_ENV` rewrite surfaced a bug where the injected helper call itself needed the helper. Loop var is now renamed to avoid the chicken-and-egg.

These aren't emulator bugs per se; they're cart code paths that aren't
robust to random input. Still worth noting — a less-chaotic fuzz profile
(one button at a time, longer holds, pauses) would give more useful
signal. See `NEXT_STEPS.md`.

### Host-only

- Host screenshots previously bypassed `p8_machine_present` and did
  their own palette lookup. Fixed (secret palette now shows correctly
  on host screenshots).
