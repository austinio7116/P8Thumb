# ThumbyP8

A clean-room PICO-8-compatible fantasy console runtime for the
**TinyCircuits Thumby Color** (RP2350, 128×128 RGB565, 4-channel
DMA audio, 520 KB SRAM, 16 MB flash).

ThumbyP8 is a from-scratch implementation of the documented PICO-8
fantasy console API. It runs unmodified PICO-8 carts on real Thumby
Color hardware after a small host-side preprocessing pass to convert
`.p8.png` cart files into a device-friendly text + label format.

PICO-8 is a trademark of Lexaloffle Games. ThumbyP8 is an
independent, clean-room reimplementation of the publicly documented
PICO-8 fantasy-console API and is not affiliated with or endorsed
by Lexaloffle.

---

## What works

| Subsystem | Status |
|---|---|
| Lua 5.4 VM (vendored) with capped allocator | ✅ |
| 128×128 RGB565 framebuffer + 4bpp PICO-8 model | ✅ |
| Drawing primitives (`cls` `pset` `line` `rect` `circ` `spr` `sspr` `map` `print` …) | ✅ |
| Sprites, tilemap, sprite flags | ✅ |
| PICO-8 font shape (3×5 glyphs) — transcribed from Pemsa, MIT | ✅ |
| Input (`btn`/`btnp`) with diagonal coalescing + trigger chord shortcuts | ✅ |
| 4-channel audio synth (8 waveforms, slide / vibrato / drop / fades) | ✅ |
| Hardware audio: 9-bit PWM + sample-rate IRQ | ✅ |
| GC9107 LCD driver with DMA push | ✅ |
| USB MSC: drag-and-drop carts via Windows/macOS Explorer | ✅ |
| FAT FS on flash (12 MB cart storage) | ✅ |
| Cart picker with BMP label thumbnails | ✅ |
| Lua dialect handling (`+= -= *= /= %= ^= |= &=`, `if (cond) stmt`, …) | ✅ |
| Full PICO-8 dialect compatibility for arbitrary BBS carts | 🟡 partial (Phase 7) |
| Device-side `.p8.png` decoding | ❌ (too slow, host-side preprocess instead) |

End-to-end tested on real hardware with Celeste Classic, Delunky,
Ruwukawisa, Dominion, Flipknight, and Pico Arcade — all play with
graphics, sound, and input working.

---

## Repository layout

```
ThumbyP8/
├── README.md                  ← this file
├── CMakeLists.txt             ← host build (SDL2 + benchmark)
├── lua/                       ← vendored Lua 5.4.7 (MIT)
├── src/                       ← cross-platform runtime (host + device)
│   ├── p8.[ch]                ← Lua VM lifecycle + capped allocator
│   ├── p8_machine.[ch]        ← 64 KB PICO-8 memory map + draw state
│   ├── p8_draw.[ch]           ← drawing primitives
│   ├── p8_api.[ch]            ← Lua bindings for the PICO-8 API
│   ├── p8_audio.[ch]          ← 4-channel synth, software mixer
│   ├── p8_cart.[ch]           ← .p8 text cart loader
│   ├── p8_p8png.[ch]          ← .p8.png decoder (host only — too slow on device)
│   ├── p8_rewrite.[ch]        ← residual dialect rewriter (compound assigns, !=)
│   ├── p8_font.[ch]           ← 3×5 bitmap font (Pemsa, MIT)
│   ├── p8_input.[ch]          ← button mask helpers
│   ├── host_main.c            ← SDL2 host runner
│   ├── bench_main.c           ← Lua VM benchmark harness (host + device)
│   └── lib/stb_image.h        ← vendored PNG decoder (host only)
│
├── device/                    ← device-only firmware glue
│   ├── CMakeLists.txt         ← Pico SDK build
│   ├── p8_device_main.c       ← entry point + lobby/picker/cart state machine
│   ├── p8_lcd_gc9107.[ch]     ← GC9107 SPI/DMA LCD driver
│   ├── p8_buttons.[ch]        ← GPIO button reader + diagonal coalescing
│   ├── p8_audio_pwm.[ch]      ← PWM audio output + sample IRQ
│   ├── p8_flash_disk.[ch]     ← flash-backed disk + RAM write-back cache
│   ├── p8_msc.c               ← TinyUSB MSC class callbacks
│   ├── usb_descriptors.c      ← TinyUSB device + composite descriptors
│   ├── tusb_config.h          ← TinyUSB compile config
│   ├── p8_picker.[ch]         ← cart picker UI
│   ├── p8_bmp.[ch]            ← minimal BMP loader for label thumbnails
│   ├── p8_log.[ch]            ← on-screen + file logging
│   └── fatfs/                 ← vendored FatFs R0.15 (BSD-1, ChaN)
│
├── tools/
│   ├── p8png_extract.py       ← host preprocessor: .p8.png → .p8 + .bmp
│   ├── pico8_lua.py           ← (deprecated) hand-rolled token rewriter
│   ├── p8png_to_p8.py         ← legacy stub
│   ├── embed_cart.py          ← (legacy) bake .p8 into a C array
│   └── shrinko8/              ← vendored shrinko8 (MIT, thisismypassport)
│
├── carts/                     ← test carts (.p8 + .bmp pairs)
└── build/, build_device/      ← out-of-tree build outputs (gitignored)
```

---

## Architecture

### How the Lua interpreter works

ThumbyP8 doesn't ship its own Lua VM — it **vendors PUC Lua 5.4.7**
(unmodified, MIT-licensed, the canonical reference implementation
from lua.org) as a static library and links it into both the host
emulator and the device firmware. Roughly:

```
src/p8.c               ← thin C wrapper around lua_State
  │
  ▼
lua/                   ← vendored Lua 5.4.7 source tree
├── lapi.c             ← Lua C API
├── ldo.c              ← interpreter loop / call stack
├── lvm.c              ← bytecode dispatch (the hot loop)
├── lparser.c          ← parser → bytecode compiler
├── llex.c             ← lexer
├── lgc.c              ← garbage collector
├── lstring.c, ltable.c, lstate.c, lobject.c …
├── lbaselib.c, ltablib.c, lstrlib.c, lmathlib.c
└── (we exclude liolib, loslib, loadlib, lcorolib, ldblib for size)
```

**What runs as Lua bytecode** (interpreted by `lvm.c`):
- The cart's `_init`, `_update`, and `_draw` functions
- All entity logic, level generation, particle systems, AI, etc.
- The cart's helper functions and table manipulation
- Effectively everything the cart author wrote

**What runs as native C** (called from Lua via the C API):
- Every PICO-8 API binding in `src/p8_api.c` — `cls`, `pset`,
  `line`, `rect`, `circ`, `circfill`, `spr`, `sspr`, `map`,
  `print`, `btn`, `btnp`, `sin`, `cos`, `atan2`, `flr`, `ceil`,
  `abs`, `min`, `max`, `mid`, `rnd`, `srand`, `sgn`, `sqrt`,
  bitwise helpers, `peek`/`poke`/`memcpy`/`memset`, `add`/`del`/
  `count`/`foreach`/`all`, `sub`/`tostr`/`tonum`/`split`/`ord`/`chr`,
  `sfx`/`music`/`stat`, `printh`, `cartdata`/`dget`/`dset` (stubs),
  `reload` (no-op stub), `time`/`t`, `cursor`
- The drawing primitives in `src/p8_draw.c` — Bresenham line,
  midpoint circle, sprite blit, tilemap walk, palette remap, clip
- The 4-channel audio synth in `src/p8_audio.c` — phase
  accumulators, waveform generation, effect modulation, mixing
- The font glyph blitter in `src/p8_font.c`
- Cart loading and rewriter in `src/p8_cart.c` + `src/p8_rewrite.c`

**The boundary in practice.** When Celeste calls `circfill(64, 64,
8, 7)`, the Lua interpreter executes the call instruction in
`lvm.c`, which jumps to the C function `l_circfill` in
`p8_api.c`, which reads its arguments off the Lua stack and calls
`p8_circfill` in `p8_draw.c`, which writes pixels into the 4bpp
framebuffer at `machine.mem[0x6000..]`. Once per frame, the
device's main loop calls `p8_machine_present` (also C) to expand
the framebuffer into a 16-bit RGB565 scanline buffer and DMA it
to the GC9107 LCD via `p8_lcd_present` (in
`device/p8_lcd_gc9107.c`).

**Performance.** Lua bytecode dispatch on the RP2350 at 250 MHz
costs ~148 ns per VM instruction (we measured this in the Phase 0
benchmark). PICO-8 carts do on the order of 10 000–30 000 VM
instructions per frame at 30 fps, so the interpreter alone uses
roughly 1–4 ms of the 33 ms frame budget. The drawing primitives
and audio synth (both pure C) consume more time than the Lua
interpreter for most carts.

**Memory.** The Lua VM uses a custom allocator (`p8_lua_alloc` in
`src/p8.c`) that wraps libc `malloc`/`free`/`realloc` and tracks
total bytes-in-use against a hard ceiling. The cap is 256 KB on
device — Lua's `lua_Alloc` callback returns NULL when a request
would exceed it, which Lua treats as an out-of-memory condition
that propagates as a Lua error. This bounds runaway allocations
and gives us a deterministic OOM diagnostic instead of a runtime
crash. Lua's incremental garbage collector handles cleanup of
dead tables/strings/closures throughout the cart's lifetime.

**The dialect rewriter** (`src/p8_rewrite.c`) is a thin
preprocessing layer that runs *before* `luaL_loadbuffer`. It
walks the cart's Lua source character-by-character with a
string/comment state machine and translates the residual PICO-8
dialect bits that the host preprocessor leaves behind: compound
assignments (`x += 1` → `x = x + (1)`), `!=` → `~=`, and a
disabled-by-default shorthand-if pass. Once the rewriter is done,
the source is plain Lua 5.4 that PUC Lua's parser accepts
without modification.

**The host preprocessor** (`tools/p8png_extract.py`) handles the
heavy lifting: PNG decode, PXA decompression, and the bulk of
the dialect translation via vendored shrinko8 (MIT,
thisismypassport — a full PICO-8 Lua parser/AST/emitter). Doing
this on the host means the device only ever sees clean text
`.p8` files; PUC Lua's compiler in `lparser.c` does the rest.

### Three-layer design

```
┌────────────────────────────────────────────────┐
│  HOST PREPROCESSOR (Python)                    │
│  tools/p8png_extract.py + shrinko8             │
│  .p8.png → unminify → dialect post-fix         │
│           → .p8 (text) + .bmp (label)          │
└────────────────────────────────────────────────┘
                       │
                       │  USB MSC drag-and-drop
                       ▼
┌────────────────────────────────────────────────┐
│  DEVICE FIRMWARE (Pico SDK + ThumbyP8)         │
│  ┌──────────────────────────────────────────┐  │
│  │  LOBBY  (USB active, RAM cache, drain)   │  │
│  └──────────────────────────────────────────┘  │
│                  ↓ A press                     │
│  ┌──────────────────────────────────────────┐  │
│  │  PICKER  (BMP thumbnails, cart pick)     │  │
│  └──────────────────────────────────────────┘  │
│                  ↓ A press                     │
│  ┌──────────────────────────────────────────┐  │
│  │  CART RUN  (Lua VM + drawing + audio)    │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────┐
│  CROSS-PLATFORM RUNTIME (src/)                 │
│  Lua 5.4 + p8_machine + p8_draw + p8_api +     │
│  p8_audio + p8_cart + dialect rewriter         │
│  — same code runs on host (SDL2) and device.   │
└────────────────────────────────────────────────┘
```

The key idea: **the runtime is identical** between the host SDL2
emulator and the device firmware. Only the I/O backends differ
(SDL window/keyboard/audio device vs LCD/GPIO/PWM). This means
every fix improves both.

### Why a host preprocessor

PICO-8's `.p8.png` cart format steganographically encodes the cart
ROM in the low 2 bits of each pixel of a 160×205 PNG. Decoding
requires:

1. PNG decode (zlib inflate + filter unfilter + RGBA assembly)
2. Steganographic byte extraction
3. PXA Lua decompression (custom move-to-front + Golomb-coded
   bitstream)
4. PICO-8 dialect translation to vanilla Lua 5.4

Steps 1 and 4 are *very* slow on a Cortex-M33 with code in XIP
flash — we measured stb_image taking 30–60 seconds per cart on
device. The preprocessor moves all of this to the host, where it
takes milliseconds. The device only ever loads plain text `.p8`
files plus a sibling `.bmp` for the label thumbnail.

The dialect translation uses **shrinko8** (MIT, thisismypassport)
as a vendored library — it has a full PICO-8 Lua parser that
handles every quirk. We use its `-U` (unminify) mode and apply a
small post-fix for the few things shrinko8 leaves behind (the
`if cond do` alt-keyword, `?expr` print shorthand, the `\` integer
divide operator, the `^^` XOR operator, the `@`/`%`/`$` peek
shorthands, and the ⬅➡⬆⬇🅾❎ Unicode button glyphs).

### Memory map (device)

```
520 KB SRAM
├── 64 KB   p8_machine.mem       (PICO-8's documented 0x0000-0xFFFF)
├── 32 KB   scanline DMA buffer  (4bpp → RGB565 expand for the LCD)
├── 32 KB   flash disk cache     (8 erase blocks × 4 KB)
├── ~20 KB  Pico SDK / FatFs / TinyUSB / misc statics
├── 16 KB   stack (bumped from SDK default 2 KB — see below)
├── ~2 KB   audio scratch buffer
├── ═══════════════════════════════
├── ~356 KB libc heap, of which:
│   ├── 256 KB  Lua VM heap cap
│   ├── ~95 KB  cart bytes during load (transient, freed before _init)
│   └── ~5 KB   margin
│
│   At game-run time, cart.lua_source (~43 KB) is freed immediately
│   after compilation and a GC cycle is forced, so the effective
│   heap available to Lua at runtime is ~300 KB (of which 256 KB
│   is the hard cap).
│
│   Picker thumbnail is malloc'd on demand (32 KB) and freed
│   before the cart launches, so it doesn't compete with Lua.

16 MB QSPI flash
├── 0..1 MB    firmware (currently ~720 KB)
└── 1..13 MB   FAT16 cart filesystem (12 MB usable)
```

### Stack

The Pico SDK's RP2350 default stack is `StackSize = 0x800` (2 KB),
set via `PICO_STACK_SIZE` in `crt0.S`. This is wildly insufficient
for a Lua VM that recurses C → Lua → C during `foreach` / `all`
iteration chains. Three levels of nested `foreach` is enough to
overflow 2 KB.

ThumbyP8 bumps this to **16 KB** via:
```cmake
target_compile_definitions(pico_platform INTERFACE PICO_STACK_SIZE=0x4000)
```
This must be on `pico_platform`'s INTERFACE (not PRIVATE on the
target) so it reaches `crt0.S` — the assembly file that actually
reserves the stack. Previous attempts using `target_compile_definitions(PRIVATE)`,
`target_link_options(--defsym=__stack_size__)`, and `--defsym=StackSize`
all failed because they either didn't reach the assembly file or
set the wrong symbol.

### OOM and panic handling

When a cart exhausts the 256 KB Lua heap cap, the allocator returns
NULL. Lua handles most OOMs gracefully via `lua_pcall` error
propagation. But for some internal operations (stack growth, error
message construction), the OOM triggers `lua_atpanic` — an
unrecoverable error.

The panic handler uses `longjmp` to jump back to a recovery point
set up before the cart's Lua lifecycle begins. This avoids the
alternative (calling `abort()` which on bare-metal Cortex-M is
a hardfault). The device shows a **dark purple screen** with the
panic message + cart name, logs `PANIC: <message>` to
`/thumbyp8.log`, and MENU returns to the picker.

After a panic the Lua VM is invalid and is intentionally leaked
(not `lua_close`'d, since `lua_close` itself can trigger panics
during GC finalization). The next cart launch creates a fresh VM.
If leaked VMs accumulate (e.g. user tries 3 carts that all OOM),
eventually there's no heap left and the next VM init fails
cleanly. Power cycling always gives a clean slate.

### State machines

**Lobby** (only mode where USB is active):

```
MOUNTED ──────► FLUSHING ──────► READY
   ▲              │                 │
   └──────────────┴─────────────────┘
   (any new write makes it dirty again)
```

The lobby continuously commits one dirty cache block per main-loop
iteration whenever MSC has been quiet for >300 ms. On the user
pressing **A** with a clean cache and at least one cart on disk,
the lobby tears down USB, hands over to the picker.

**Picker → Cart Run → Picker** (USB inactive, no `tud_task` calls):
the user picks a cart with ◀ ▶, presses A to launch, plays, and
returns to the picker via the **MENU** button. To upload more carts
they power-cycle back into the lobby.

---

## Building

### Prerequisites

```
sudo apt install build-essential cmake libsdl2-dev libffi-dev \
                 python3-pillow gcc-arm-none-eabi
```

You also need the Pico SDK, vendored as `lib/pico-sdk` inside the
sibling `mp-thumby` checkout (or set `PICO_SDK_PATH` manually).

### Host build (SDL2 emulator)

```
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j8
./build/p8run carts/test1.p8
```

`p8run` is the SDL2 emulator. Keyboard mapping: arrows = d-pad,
Z = O button, X = X button, Esc = quit.

### Device firmware

```
cmake -B build_device -S device \
      -DPICO_SDK_PATH=/path/to/mp-thumby/lib/pico-sdk
cmake --build build_device -j8 --target p8run_device
```

Output: `build_device/p8run_device.uf2`. Flash via BOOTSEL (off →
hold DOWN d-pad → on → drag the .uf2 onto the RPI-RP2350 mass-
storage drive).

There's also a benchmark target `p8bench_device` that runs the Lua
VM perf suite over USB CDC for confirming cross-build sanity.

### Running the host VM benchmark

```
./build/p8bench
```

Reports raw Lua interpreter throughput (empty loop, arith, table
read/write, function call, string ops, trig). Useful for comparing
optimisations against the device baseline (250 MHz, 32-bit
`lua_Number`, ≈148 ns / interpreter dispatch).

---

## Workflow: getting a cart onto the device

1. **Get a `.p8.png` cart** from the PICO-8 BBS or anywhere.

2. **Preprocess** with the host script:
   ```
   python3 tools/p8png_extract.py /path/to/cart_dir /path/to/output_dir
   ```
   For each `cart.p8.png` you get `cart.p8` (text source) and
   `cart.bmp` (128×128 RGB565 label thumbnail).

3. **Power-cycle the Thumby** into the lobby. It enumerates as a
   USB removable drive labelled `P8THUMBv1`.

4. **Drag the `.p8` and `.bmp` pair** into the drive's `/carts/`
   folder. The on-screen indicator shows "writes pending" while
   the cache fills.

5. **Eject from the OS** (or just wait — the lobby auto-flushes
   any dirty cache after a few hundred ms of MSC inactivity). The
   indicator changes to "drive idle / ready".

6. **Press A** in the lobby. Picker opens, shows the cart label
   thumbnail. ◀ ▶ to switch carts, A to launch.

7. **MENU** during gameplay returns to the picker. Power-cycle
   to upload more carts.

### Recovery / rescue

- **Stuck firmware?** BOOTSEL (off → hold DOWN → on) → drag any
  known-good `.uf2` onto the RPI-RP2350 mass-storage drive. The
  RP2350 boot ROM cannot be bricked.
- **Stuck filesystem?** Hold the **MENU** button at boot — the
  lobby will reformat the disk unconditionally.

---

## How the dialect translation works

PICO-8 extends Lua 5.2 with several syntactic shortcuts. shrinko8
handles most of them via a real parser; our small post-pass in
`tools/p8png_extract.py` mops up the rest:

| PICO-8 dialect | Translates to | Where |
|---|---|---|
| `+= -= *= /= %= ^= ..= |= &= ^^=` | `x = x op (rhs)` | Device-side `p8_rewrite.c` |
| `!=` | `~=` | Device-side `p8_rewrite.c` |
| `if (cond) stmt` (shorthand) | `if cond then stmt end` | shrinko8 -U |
| `if cond do ... end` | `if cond then ... end` | post-fix regex |
| `?expr` (print shorthand) | `print(expr)` | post-fix regex |
| `\` (integer divide) | `//` | post-fix state machine |
| `^^` (binary XOR) | `~` | post-fix state machine |
| `@addr` (peek shorthand) | `peek(addr)` | post-fix state machine |
| `%addr` (peek2) | `peek2(addr)` | post-fix state machine |
| `$addr` (peek4) | `peek4(addr)` | post-fix state machine |
| `0b1010` (binary literal) | decimal | shrinko8 -U |
| `⬅ ➡ ⬆ ⬇ 🅾 ❎` button glyph identifiers | `0..5` | post-fix byte substitution |

The post-fix uses a small string/comment-aware state machine to
make sure operator substitutions only happen in code, not inside
string literals or comments.

---

## API surface (Lua bindings)

The runtime exposes the documented PICO-8 API. Highlights:

**Drawing**: `cls`, `pset`, `pget`, `line`, `rect`, `rectfill`,
`circ`, `circfill`, `oval`, `ovalfill`, `spr`, `sspr`, `map`,
`mapdraw`, `mget`, `mset`, `fget`, `fset`, `sget`, `sset`,
`print`, `cursor`, `color`, `camera`, `clip`, `pal`, `palt`,
`fillp` (stub), `tline` (stub), `flip` (stub)

**Input**: `btn`, `btnp`

**Math**: `sin`, `cos`, `atan2` (PICO-8 turns), `flr`, `ceil`,
`abs`, `min`, `max`, `mid`, `sgn`, `sqrt`, `rnd`, `srand`,
`shl`, `shr`, `lshr`, `band`, `bor`, `bxor`, `bnot`, `rotl`,
`rotr`, `ord`, `chr`

**Tables** (PICO-8-style, lenient on nil): `add`, `del`, `deli`,
`count`, `foreach`, `all`, `pack`, `unpack`, `split`

**Memory**: `peek`, `poke`, `peek2`, `poke2`, `peek4`, `poke4`,
`memcpy`, `memset`, `reload` (stub)

**Audio**: `sfx`, `music`, `stat` (channel state queries)

**Time**: `t`, `time`

**Strings**: `sub`, `tostr`, `tonum`, `printh`

**Persistence stubs**: `cartdata`, `dget`, `dset`, `menuitem`

**Host-control stubs** (no-op): `extcmd`, `cstore`, `serial`,
`stop`, `run`, `reset`, `ls`, `holdframe`, `_set_fps`

All numeric arguments are PICO-8-lenient: passing `nil` is treated
as `0` instead of erroring (matches what real carts assume).

---

## Project history (phase by phase)

| Phase | What landed |
|---|---|
| **0** | Spike: vendored Lua 5.4.7, host bench harness, capped allocator |
| **0.5** | Cross-build for RP2350; Lua perf measured on real device (148 ns / dispatch at 250 MHz, 32-bit `lua_Number`) |
| **1** | 64 KB PICO-8 memory map, drawing primitives, RGB565 expand, SDL2 host runner |
| **2** | Sprites, sprite sheets, tilemap, sprite flags, button input |
| **3** | Built-in font, dialect rewriter (compound assigns, `!=`, `if (cond) stmt`), Celeste Classic loads |
| **3 device** | GC9107 LCD driver, button GPIO reader; first runs on real hardware |
| **4** | 4-channel audio synth (host SDL2), then PWM + IRQ on device; full audio playback |
| **6** | USB MSC + FatFs on flash, lobby state machine, picker UI with BMP thumbnails |
| **6.5** | Host preprocessor with shrinko8 integration; multi-cart support |
| **7** | (in progress) PICO-8 dialect compatibility, memory optimisation, hardfault diagnosis |

---

## Known limitations

### Memory

- **Lua heap cap is 256 KB** (raised from the initial 128 KB →
  192 KB → 256 KB as we discovered how much real carts need). The
  cap is enforced by a custom `lua_Alloc` that returns NULL when
  a request would exceed it.
- **Total SRAM is 520 KB.** After BSS (~148 KB), stack (16 KB),
  and libc overhead, ~356 KB is available for the libc heap. The
  256 KB Lua cap plus ~95 KB of transient cart-load buffers
  (freed before _init) fits, but barely.
- **Carts that need >256 KB of Lua heap at runtime will OOM.**
  The device shows a dark-purple "PANIC (oom?)" screen, logs the
  error, and MENU returns to the picker. Lootslime (~300 KB+) and
  mossmoss are known to exceed this. Delunky fits just under.
- **Leaked VMs accumulate.** After a panic, the Lua VM is
  intentionally not closed (lua_close can itself panic during GC
  finalization). Each leaked VM holds its peak heap allocation.
  After 2–3 panics in a row, heap may be exhausted; power-cycle
  to reset.

### Dialect / compatibility

- **13 of 25 test carts load on host.** Failures are clustered
  into: P8SCII string escapes (`\^`, `\-` etc.), PICO-8 rotate
  operators (`>>>`, `<<>`, `>><`), non-button Unicode glyphs in
  code positions, and a handful of edge cases.
- **`fillp` is a no-op stub.** Carts that use fill patterns draw
  without them. Visual-only degradation.
- **`tline` is a no-op stub.** Mode-7 / floor-texture effects
  don't render.
- **`reload` is a no-op stub.** Carts that restore sprites/map
  from the cart's ROM at runtime won't see the restore.
- **`cstore`/`dset`/`dget` are stubs.** No persistent save data
  across sessions.

### Performance

- **`sin`/`cos` go through libm `sinf`/`cosf`** which on
  newlib-nano internally promote to double precision and are slow
  (~3 µs/call on M33). A LUT-based version would give ~60×
  speedup.
- **On-device PNG decoding is not currently used** (stb_image was
  too slow or hitting memory issues). Carts are preprocessed on
  the host via `tools/p8png_extract.py`. Re-enabling the on-device
  path is planned now that memory headroom is better.

### Other

- **Picker doesn't support folders** — flat `/carts/` listing.
- **No multi-cart support** — carts that `load()` other carts
  won't work.

---

## Licenses

ThumbyP8 itself is original work; contributors retain their
copyright. Vendored components:

- **Lua 5.4.7** — MIT, Lua.org
- **stb_image** — Public domain / MIT, Sean Barrett (host only)
- **FatFs R0.15** — BSD-1-clause, ChaN (device only)
- **shrinko8** — MIT, thisismypassport (host preprocessor only)
- **Pemsa font transcription** — MIT, egordorichev (font glyphs)

PICO-8 is a trademark of Lexaloffle Games. ThumbyP8 reproduces
none of Lexaloffle's source code; the runtime is implemented from
the publicly documented PICO-8 fantasy console API.
