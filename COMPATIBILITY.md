# ThumbyP8 Cart Compatibility

Last updated: 2026-04-12

## Status Key
- **Playable** — loads, controls work, plays to completion or reasonable extent
- **Partial** — loads but has issues (visual glitches, some features broken)
- **Broken** — crashes, hangs, or unplayable
- **Untested** — needs retesting after recent fixes

## Test Results

| Cart | Compiles | Status | Notes |
|------|----------|--------|-------|
| 49232 | OK | Untested | Was playable, numbers showed as floats — may be fixed by int/float fix |
| adelie-0 | OK | Untested | Was running OK |
| age_of_ants-9 | OK | Broken | Load error: attempt to index a string value (local 'o') |
| beam4-2 | OK | Broken | Hangs on load — was working with host builds |
| celeste | OK | Playable | Controls work, fully playable |
| cheezymaze_ex-0 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| delunky102-0 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| digger-2 | OK | Partial | Quite playable but crashes late in level 1 |
| dominion_ex-4 | OK | Partial | Plays but eventually crashes/hangs |
| flipknight-0 | OK | Untested | Was running OK |
| fromrust_a-4 | OK | Partial | Loads but crashes during gameplay: nil concat field '?' |
| fsgupicozombiegarden121-0 | OK | Partial | Loads but needs mouse input (not supported) |
| hotwax-5 | OK | Broken | Slow then crashes |
| kalikan_menu-6 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| lootslime-1 | OK | Broken | OOM in _init — cart too large for 300KB heap |
| lorez-1 | OK | Broken | Hangs after load |
| mini_pharma-1 | OK | Untested | Had nil arith error — may be fixed by int/float fix |
| mossmoss-12 | OK | Broken | Hangs after load |
| mot_pool-23 | OK | Untested | Was hanging on trying to start game |
| musabanebi-0 | OK | Partial | Runtime: nil index field '?' — P8SCII glyph as table key |
| pck404_512px_under-1 | OK | Partial | Playable but ^T ^W ^I appearing in strings (P8SCII display) |
| phoenix08-0 | OK | Untested | Was running OK |
| pico_arcade-2 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| pico_ball-5 | OK | Broken | Load error: attempt to get length of a number value (global 'dat') |
| picovalley-2 | OK | Untested | Was rendering in top-left quarter, controls broken |
| poom_0-9 | OK | Untested | Bootstrap cart — was running OK |
| praxis_fighter_x-2 | OK | Untested | Had nil concat — may be fixed by int/float fix |
| province-4 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| rtype-5 | OK | Partial | Runtime: nil arith field '?' — P8SCII glyph as table key |
| ruwukawisa-0 | OK | Untested | Was running OK |
| start_picocraft_1-3 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| terra_1cart-43 | OK | Untested | Had nil concat in _init — may be fixed by int/float fix |
| tinygolfpuzzles-1 | OK | Untested | Controls were broken — should be fixed by glyph fix |
| woodworm-0 | OK | Untested | Had "number has no integer representation" — should be fixed by bitwise fix |

## Known Limitations
- Carts using mouse input (fsgupicozombiegarden) won't work — no mouse on Thumby Color
- Very large carts may OOM during _init (lootslime) — 300KB Lua heap cap
- P8SCII special characters in strings display as blocks, not glyphs
- Some carts hang in _init (beam, mossmoss, lorez) — needs investigation
- Button glyph display in strings shows numbers instead of icons

## Recent Fixes (2026-04-12)
- Button/arrow glyphs now correctly map to button indices 0-5 (was using P8SCII byte values)
- All bitwise ops (& | ^ ~ << >> >>> <<> >><) now use 16.16 fixed-point via function calls
- Fixed-point results return as integer when fractional part is zero (Lua 5.4 int/float key distinction)
- PXA decompressor: removed 32-iteration limit on back-ref length (was truncating 4 carts)
- Conversion scan now finds all carts (was limited to first 16)
- In-game pause menu added (long-press MENU)
