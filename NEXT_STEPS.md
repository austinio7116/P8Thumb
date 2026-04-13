# ThumbyP8 Roadmap — Next Phase

Written 2026-04-13 after the initial burn-in session. Reflects what
we've learned from hitting ~15 concrete bugs one at a time and
what's left to do systematically.

## Where we are

**Working:** Most popular carts load and run. Porklike, POOM title,
rtype title, celeste, delunky, combopool, highstakes, digger,
air_delivery title, pico_arcade, province, start_picocraft, and
~20 others.

**Known deviations from real PICO-8:** see "Deviations" below. The
big ones: float numerics (we're not 16.16 fixed-point), `_ENV`
handled via source rewrite rather than parser/VM, missing fill
pattern and arpeggio edge cases.

**Major known broken:** terra (translation hangs — LZW decoder),
a few carts OOM during gameplay (hit the 300KB Lua heap cap).

## The meta-problem

Every bug we've fixed was triggered by someone noticing a visible
failure. This is linear effort at best and misses silent bugs
entirely. To get close to a perfect PICO-8 implementation we need
to flip this: have the tooling find bugs, not the user.

## Priority ordering

### P0 — reference-comparison harness (biggest lever)

Build a script that:

1. Runs each cart on **fake-08** (C++, compiles on Linux, widely
   validated PICO-8 compatibility) as the reference.
2. Runs the same cart on our host `p8run` with the same input.
3. Compares screenshots every 30 frames. Pixel diff with tolerance.
4. Flags divergences, reports per-cart, per-frame.

Rationale: we don't know what's wrong when a cart visually "looks
off." Diff output tells us exactly where and lets us prioritize
by impact. Expect to find 20-50 divergences on first run, most of
which are small palette/rendering bugs with trivial fixes once
isolated.

Tools needed:
- fake-08 compiled in a Linux sidecar
- Deterministic input for both runners (seeded RNG, synthetic
  button sequence)
- Pixel diff utility (ImageMagick `compare` with `-metric AE`)

Expected output: `/tmp/p8diff/<cart>/frame_XXXX_us_vs_them.png`,
plus a summary ranking carts by total divergent pixels.

### P1 — PICO-8 conformance test carts

The PICO-8 community has published "quirk" carts that exercise
specific edge cases:

- **fillp bit-order cart** — tests each bit of the 16-bit fill
  pattern against known pixel positions.
- **fixed-point precision cart** — stresses 16.16 semantics; we'll
  likely fail some tests since we're float.
- **audio timing carts** — measure note durations, SFX advance.
- **music loop carts** — test `music(n, fade, mask)` edge cases.
- **sprite flag / map boundary carts** — test `mget(128, y)` behavior.

Port whichever we can find published, run through harness, score
pass/fail automatically. Each failing test is a concrete, small,
fixable bug.

### P2 — replace the source-level `_ENV` rewriter with a parser patch

Current state: regex-based source rewrite handles `local _ENV = X`,
`local a, _ENV = A, X`, `for _ENV in EXPR do`, `function(_ENV)`.
Works but is regex-fragile — any new syntactic idiom we haven't
thought of will miss.

Proper fix: patch `lua/lparser.c`. When `new_localvar` is called
with name `_ENV`, emit bytecode immediately after
`adjustlocalvars` that calls `setmetatable(_ENV, {__index=_G})`
if `_ENV` has no existing metatable. Hooks: `localstat`,
`forlist`, `parlist`.

This is strictly more robust — no regex misses, no string-state
worries, fires once per binding site regardless of syntactic form.

Cost: ~50 lines in lparser.c; understanding Lua's `expdesc` /
`luaK_*` emission API.

Don't do this until P0 and P1 have flushed out bigger issues —
the current rewriter works in practice.

### P3 — 16.16 fixed-point numerics

Our Lua uses `float` (IEEE single) for `lua_Number`. Real PICO-8
uses 16.16 fixed-point signed integers: range ±32767.9999,
resolution 1/65536. Differences that matter:

- **Precision.** Floats lose precision above 2^24 ≈ 16M but we're
  bounded to 32768. More relevantly: float's mantissa is 23 bits
  vs fixed's 16 bits of fraction. Some operations produce
  different low-order bits, which carts using bitwise operations
  on numbers can detect.
- **Overflow wrap.** PICO-8's fixed-point wraps at ±32768. Ours
  clamps or goes to inf. Matters for carts that rely on wrap.
- **Division by zero.** Different behavior.

Implementing 16.16 properly means rewriting `lua_Number` to
`int32_t` with fixed-point semantics in `luaconf.h` and patching
all the arithmetic ops. That's a big change.

Feasibility: fake-08 / zepto-8 both do this, so the patch set
exists as reference. RP2350 has single-precision FPU; pure integer
16.16 is likely *faster* than float on this chip for most ops
(no FP load/store overhead). But some ops (sqrt, sin/cos) are
more complex in fixed-point.

Priority: probably P3, not P0. Most carts don't notice. Carts
that DO notice will show up in the reference comparison harness.

### P4 — fill remaining API gaps

From memory, still stubbed or partial:

- **Arpeggio audio effects (6 and 7)** — currently silent. Need
  to track a "next 3 notes" lookahead in the synth.
- **Custom font via poke** — carts can write to 0x5600 to replace
  the font. Our p8_font.c uses a compiled-in table.
- **Extended palette memory writes** — `poke(0x5F2E, 1)` toggles
  "hollow palette" mode, etc. We ignore these hardware flags.
- **Mouse/keyboard input** — `stat(32..39)` and related. Some
  carts gate features on this.
- **`reload(dst, src, len, filename)` cross-cart** — we ignore
  the filename argument.
- **Coroutines** — we expose `cocreate/coresume/costatus/yield`
  but haven't tested them heavily. Some carts use them for music
  or level transitions.

Each is bounded work (hours, not days) once prioritized by
impact from the reference harness.

### P5 — compatibility tracking

`COMPATIBILITY.md` is hand-maintained. Automate it:

- Every commit: CI runs the full cart suite through fake-08 diff,
  classifies each cart (Playable / Partial / Broken) by divergence
  metric.
- Emit `COMPATIBILITY.md` as output. Diff over time shows regressions
  and progress.

## Deviations from real PICO-8 (known)

| Area | Our behavior | PICO-8 behavior | Impact |
|------|--------------|-----------------|--------|
| Numerics | IEEE single float | 16.16 signed fixed-point | Precision differences, different overflow, some bitwise corner cases |
| `_ENV` locals | Source-rewritten `__p8_env(t)` call injected | Implicit fallback in Lua core | Works for common idioms; regex could miss exotic ones |
| Screen palette writes | 0x5F10-0x5F1F bytes work with secret bit | Same, plus `persist palette` flag at 0x5F2E | Minor cosmetic |
| Fill pattern | Supported; pattern-transparency supported | Same, plus bit 14-15 sprite/globalpal flags | Sprites don't apply fillp (PICO-8 has flag for this) |
| Audio arpeggio | Silent (effects 6, 7) | 4-note subdivisions | Some music sounds wrong |
| Mouse/keyboard | Always returns 0 | Configurable via 0x5F2D | Some carts won't respond to menus |
| Memory map | 0x8000-0xFFFF is user data but not simulated via any accessor | Same as PICO-8 | OK for most carts |
| `extcmd`, `cstore`, `run`, etc. | No-ops | Various host-level actions | Intentional — embedded device |

## Anti-patterns to avoid going forward

1. **Adding a stub when a cart errors.** If we're adding a stub, first
   check if a real implementation is possible. Stubs accumulate as
   silent divergences.

2. **Source rewriting when parser-level works.** Every regex is debt.
   Future syntactic patterns will miss. Prefer AST-level or
   bytecode-level transformations.

3. **"Looks fine on title screen" → ship.** Title screens exercise 10%
   of the cart. Real bugs live in gameplay loops. Minimum bar:
   reach level 1 via scripted input.

4. **Fixing what the user just reported without searching for siblings.**
   If POOM has wrong palettes, so might 20 other carts. Fix the
   class of bug, not just the instance.

## Immediate actions for next session

1. Implement P0 (fake-08 diff harness). Budget: half a day.
2. Run it, triage the top 10 divergences, fix each (another half
   day).
3. If time: port 2-3 conformance carts from the community (P1).

Estimated time to "near-perfect" PICO-8: weeks of targeted work
given the harness. Without the harness: months of reactive bug
hunting.

## Reference implementations to study

- **fake-08** — https://github.com/jtothebell/fake-08 (C++, most
  compatible, reads same PNG cart format)
- **zepto-8** — https://github.com/samhocevar/zepto-8 (C++, more
  academic, exact 16.16 semantics)
- **picolove** — https://github.com/pico-8/picolove (Lua on
  Love2D, rapidly iterable for reference behavior)
- **shrinko8** — https://github.com/thisismypassport/shrinko8
  (Python, canonical PICO-8 parser + minifier)
