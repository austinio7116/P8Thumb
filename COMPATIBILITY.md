# ThumbyP8 Cart Compatibility

Last updated: 2026-04-14

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
| adelie-0 | Playable | Working at 280KB heap cap |
| age_of_ants-9 | Broken | OOM during _update |
| air_delivery_1-3 | Playable | Working |
| baba_demake-9 | Playable | Working (pairs(nil) fix) |
| beam4-2 | Playable | Working |
| celeste | Playable | Working |
| celeste_classic_2-5 | Playable | Working (C native px9_decomp fix) |
| combopool-0 | Playable | Working |
| delunky102-0 | Playable | Working |
| digger-2 | Playable | Working |
| dominion_ex-4 | Playable | Working |
| fafomajoje-0 (Dungeon) | Playable | Working |
| fighter_street_ii-1 | Broken | OOM when starting a fight |
| flipknight-0 | Playable | Working |
| fromrust_a-4 | Broken | Does not load |
| fsgupicozombiegarden121-0 | Broken | Needs mouse input (d-pad simulation possible, not yet implemented) |
| grandmothership-4 | Broken | Hangs on loading |
| highstakes-2 | Playable | Working |
| hotwax-5 | Playable | Working |
| kalikan_menu-6 | Partial | Level load issue |
| marble_merger-5 | Playable | Working |
| mini_pharma-1 | Playable | Working |
| mossmoss-12 | Broken | OOM in _init |
| musabanebi-0 | Playable | Working |
| pck404_512px_under-1 | Playable | Working, P8SCII text fixed |
| phoenix08-0 | Playable | Working |
| pico_arcade-2 | Partial | Multi-cart launcher — requires load() to chain-load sub-carts (not yet implemented) |
| pico_ball-5 | Partial | Audio - but not loading graphics |
| picohot-0 | Partial | Loads after P8SCII font + _ENV fixes; some in-game errors may remain |
| picovalley-2 | Playable | Working - not played much |
| poom_0-9 | Partial | Title renders correctly (secret palette fix); crashes on level load |
| porklike-2 | Playable | Working |
| praxis_fighter_x-2 | Broken | OOM on  load |
| province-4 | Playable | Plays fine |
| rtype-5 | Playable | Some performance issues |
| ruwukawisa-0 | Playable | Some performance issues |
| slipways-1 | Broken | OOM - angs on load on device |
| start_picocraft_1-3 | Broken | Hangs on load (px9_decomp fixed but still hangs) |
| subsurface-2 | Playable | Working, some performance issues |
| terra_1cart-43 | Broken | Hangs on load |
| tinygolfpuzzles-1 | Playable | Working |
| woodworm-0 | Playable | Working |

## Summary

- **Playable**: 28 carts
- **Partial**: 5 carts
- **Broken**: 10 carts
- **Impossible**: 1 cart

## Known Limitations

- Carts using mouse input need d-pad simulation (not yet implemented)
- Carts that OOM on a 280KB Lua heap can't run on device (280KB balances Lua heap vs libc headroom)
- `load()` for multi-cart launchers not yet implemented
- `extcmd`, `cstore`, `run`, `reset` etc. are no-ops (intentional for single-cart device)
- Numerics use IEEE single-precision float, not PICO-8's 16.16 fixed-point — precision differs in low bits; some physics-heavy carts may drift. Bitwise-heavy algorithms (e.g. PX9 compression) are handled via C native implementations to avoid precision loss.

## Recent Fixes

### 2026-04-14
- **Heap fragmentation fix**: eliminated 32KB mallocs in picker thumbnail, menu backdrop, and loading screen that fragmented libc heap. Root cause of adelie and other borderline carts failing.
- **Audio buffer**: 2048→512 entries with chunked fill. Saves 3KB BSS.
- **Heap cap**: 300KB→280KB. Better balance between Lua heap and libc headroom.
- **P8SCII translator fix**: `\^` `\*` `\#` `\-` `\|` `\+` escapes now map to correct control bytes (0x06, 0x01-0x05) instead of ASCII values. Fixes `^I` `^T` `^W` showing as text in 512px_under.
- **P8SCII font renderer**: full control code handling (0x00-0x0F) with correct parameter byte counts. `\f` (color), `\^` (command prefix + sub-commands), `\a` (audio), cursor movement, tabs, etc.
- **C native px9_decomp**: fixes celeste_classic_2 and start_picocraft. Lua version lost bits in the 32-bit bit cache due to float precision. C version uses uint32_t, reads machine memory directly, uses static arrays to avoid 256KB stack overflow on device.
- **pairs(nil) returns empty iterator**: PICO-8 compat fix — fixes baba_demake which passes nil to pairs().
- **Audio arpeggio effects (6, 7)**: fixed rate calculation that caused arp notes to never cycle. Now properly cycles through 4-note groups.
- **menuitem() implemented**: carts can register up to 5 custom pause menu items with labels and Lua callbacks. Callbacks receive button bitmask; return true to keep menu open.
- **Save flush rate-limited**: `dset()` writes to file immediately but FAT flush at most once/second + on cart exit. Reduces flash wear and potential corruption.
- **nil coerces to 0 in arithmetic** (PICO-8 compat): `nil + 1` returns 1 instead of erroring.
- **#number**: returns length of string form.

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

- **age_of_ants-9, mossmoss-12**: OOM during `_init` — heap cap.
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
