# ThumbyP8 Cart Compatibility

Last updated: 2026-04-15

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
| hotwax-5 | Broken | OOM in _init after fixed-point conversion (was Playable on float build). Close to heap ceiling; runtime peak marginally higher now. |
| kalikan_menu-6 | Playable | Multi-cart chain-load works with BBS suffix stripping |
| marble_merger-5 | Playable | Working |
| mini_pharma-1 | Playable | Working |
| mossmoss-12 | Broken | OOM in _init |
| musabanebi-0 | Playable | Working |
| pck404_512px_under-1 | Playable | Working, P8SCII text fixed |
| phoenix08-0 | Playable | Working |
| pico_arcade-2 | Partial | Multi-cart launcher — requires load() to chain-load sub-carts (not yet implemented) |
| pico_ball-5 | Playable | Chain-loads pico_ball_match via load() |
| picohot-0 | Partial | Loads after P8SCII font + _ENV fixes; some in-game errors may remain |
| picovalley-2 | Playable | Works correctly with screen-mode-3 (64×64 doubled) support. |
| poom_0-9 | Partial | Menu works; entering a level exits because poom_1 decompresses only part of the BBS-edition map (71 sectors + 446 sides, 0 verts/lines) and no `_plyr` spawns. Verified against stock Lua 5.2 with identical output — this isn't a ThumbyP8 bug, the BBS edition of POOM appears to rely on PICO-8 memory behaviour we don't fully match. |
| poom_1 | Partial | Hidden sub-cart for poom_0. |
| kalikan_stage_1a | Playable | Hidden sub-cart, loaded via picker from kalikan menu |
| kalikan_stage_1b | Playable | Hidden sub-cart |
| pico_ball_match | Playable | Hidden sub-cart, chain-loaded from pico_ball |
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

- **Playable**: 32 carts (incl. 3 hidden sub-carts)
- **Partial**: 4 carts
- **Broken**: 11 carts
- **Impossible**: 1 cart

## Known Limitations

- Carts using mouse input need d-pad simulation (not yet implemented)
- Carts that OOM on a 280KB Lua heap can't run on device (280KB balances Lua heap vs libc headroom)
- `load()` multi-cart games work via reboot — sub-carts need to be present on the device (see README "Multi-Cart Games"). Missing sub-carts are logged and silently no-op'd so the parent keeps running (debug-cruft `load()` calls don't crash to picker).
- Keyboard input via `stat(28..32, key)` returns false (no keyboard hardware)
- `extcmd`, `cstore`, `run`, `reset` etc. are no-ops (intentional for single-cart device)
- Numerics are PICO-8-exact int32 16.16 fixed-point: arithmetic wraps on overflow, bitwise ops preserve the 32-bit pattern, hex literals keep the expected bit representation.

## Recent Fixes

### 2026-04-16
- **PICO-8 screen mode 3** (`poke(0x5f2c, 3)` → 64×64 doubled to 128×128) implemented in `p8_machine_present`. Fixes picovalley, which draws its title/HUD at 64×64 coords expecting the display to upscale.
- **`lua_Number` is now int32 16.16 fixed-point** (was single-precision float). Matches PICO-8 exactly: bitwise ops preserve the 32-bit pattern, arithmetic wraps on overflow. Removes the C-native `px9_decomp` workaround — the cart's Lua version is now bit-exact.
- **`lua_str2number` wraps on overflow instead of saturating** — hex literals like `0xbe74` (48756 > 32767) keep the correct PICO-8 bit pattern `0xbe740000` for use as addresses or bitmasks.
- **`argaddr` helper masks memory addresses to 16 bits unsigned** — `peek(0xbe74)` etc. now index the machine correctly. Applied to peek/poke/peek2/poke2/peek4/poke4/memcpy/memset/reload.
- **Claims-graph out-degree tiebreaker** for picker sub-cart hiding. A launcher (kalikan menu) claims many sub-carts and has high out-degree; sub-carts claim one cart back. Fixes kalikan menu being incorrectly hidden when its stages pointed back at it.
- **`load()` to missing cart swallowed** — cart keeps running instead of crashing to picker when the target doesn't exist on disk. Restores pre-multi-cart no-op behaviour for debug-cruft `load()` calls (fixes fafomajoje entering dungeons).
- **`.luac` cache format version** — bumped so device auto-invalidates stale bytecode whenever the Lua number model or parser semantics change. Carts re-translate on first boot after firmware flash.
- **Regression: hotwax-5** — moved from Playable to Broken. _init OOM. Runtime peak crept up slightly and hotwax was near the 280KB ceiling already.

### 2026-04-15
- **`load()` multi-cart support**: reboot-based chain-loading with user memory preservation (0x4300..0xffff saved to `/.pending_mem` with magic+checksum across reboot). Sub-carts auto-hide from picker. Fixes picoball campaign/versus matches, kalikan stages.
- **BBS suffix stripping**: `load("#foo")` now matches `foo-6.luac` (cart revision suffixes).
- **`inext` global**: PICO-8's stateless ipairs iterator. Required by kalikan's `for k,v in inext, t do` idiom.
- **`all(string)`**: iterates over characters (used by carts that receive param data via stat(6)).
- **`tonum(true)=1, tonum(false)=0`**: PICO-8 compat. Fixes kalikan d-pad input which uses `tonum(btn(1)) - tonum(btn(0))`.
- **`stat(28..32, key)` returns false**: Lua integer 0 is truthy, so our old stub broke baba's title-screen key detection. Returns proper boolean false.
- **sspr negative width/height**: PICO-8 spec — flips and shifts origin. Fixes picoball player sprite disappearing when facing left.
- **Frame counter moved off 0x5f34**: PICO-8's GFX flags byte (carts poke bit 1 for inverted-circle peephole). We were corrupting it every frame causing flicker in picoball cutscene. Counter now lives in p8_machine struct field.
- **Inverted circfill**: `poke(0x5f34, 2)` + `circfill(..., bor(0, 0x1800))` fills outside the circle — picoball peephole transition.
- **Picker features**: favorites (B short-tap), delete (B hold 5s→warn, 10s→delete + reboot), sort (alphabetical/favorites/most-played), play count display, filter toggle.
- **Quit to picker**: reboots to fully reclaim heap instead of leaking VM.
- **GC tuning**: pause 200→110, mul 200→400 for tighter heap management.
- **Debug info stripping** + **XIP lineinfo**: `.luac` files compiled without locvars/upvalue names (saves 5-20KB/cart); lineinfo stays in flash like bytecode (saves 8-32KB).

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

- **age_of_ants-9, mossmoss-12, hotwax-5**: OOM during `_init` — heap cap.
- **24981 (Mcraft)**: OOM.
- **praxis_fighter_x-2, slipways-1**: OOM during translation — cart too large for translator's working memory.
- **terra_1cart-43**: translation hangs — suspected LZW decoder pathology.
- **poom_0-9 / poom_1**: BBS-edition POOM decompresses to 71 sectors + 446 sides with 0 verts/lines (verified against stock Lua 5.2 producing bit-identical output). The full level data isn't in the 1164 bytes of compressed map at `_map_offset=0xbe74`; the cart must rely on PICO-8 memory behaviour we don't fully match.
- **fighter_street_ii-1**: OOM when starting a fight.
- **grandmothership-4, fromrust_a-4, start_picocraft_1-3**: hang or fail to load (root cause unknown).
- **fsgupicozombiegarden121-0**: needs mouse input (not supported).
- **pico_arcade-2**: multi-cart launcher referencing 35+ BBS-ID sub-carts not locally available.

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
