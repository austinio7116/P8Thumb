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
| Built-in 3×5 font transcribed from Pemsa (MIT) | ✅ |
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
├── 64 KB   p8_machine.mem      (PICO-8's documented 0x0000-0xFFFF)
├── 32 KB   scanline DMA buffer (4bpp → RGB565 expand for the LCD)
├── 32 KB   picker thumbnail    (one cart label image at a time)
├── 32 KB   flash disk cache    (8 erase blocks × 4 KB)
├── ~21 KB  Pico SDK / FatFs / TinyUSB statics
├── ~16 KB  stacks
└── ~325 KB libc heap, of which:
    ├── 192 KB  Lua VM heap cap
    ├── ~100 KB cart bytes during load (transient)
    └── margin

16 MB QSPI flash
├── 0..1 MB    firmware (currently ~700 KB)
└── 1..13 MB   FAT16 cart filesystem (12 MB usable)
```

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
`circ`, `circfill`, `spr`, `sspr`, `map`, `mget`, `mset`, `fget`,
`fset`, `sget`, `sset`, `print`, `cursor`, `color`, `camera`,
`clip`, `pal`, `palt`

**Input**: `btn`, `btnp`

**Math**: `sin`, `cos`, `atan2` (PICO-8 turns), `flr`, `ceil`,
`abs`, `min`, `max`, `mid`, `sgn`, `sqrt`, `rnd`, `srand`,
`shl`, `shr`, `lshr`, `band`, `bor`, `bxor`, `bnot`, `ord`, `chr`

**Tables** (PICO-8-style, lenient on nil): `add`, `del`, `count`,
`foreach`, `all`

**Memory**: `peek`, `poke`, `memcpy`, `memset`, `reload`

**Audio**: `sfx`, `music`, `stat` (channel state queries)

**Time**: `t`, `time`

**Strings**: `sub`, `tostr`, `tonum`, `printh`

**Persistence stubs**: `cartdata`, `dget`, `dset`, `menuitem`

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
| **7** | (in progress) PICO-8 dialect compatibility for arbitrary BBS carts |

---

## Known limitations

- **Lua heap cap is 192 KB.** Carts that pre-allocate more than
  this in `_init` won't run. Lootslime is the canary — it allocates
  ~250 KB of game state in init.
- **`print()` uses a 3×5 placeholder font**, not the actual PICO-8
  font. Visually distinguishable but legible.
- **`sin`/`cos` go through libm `sinf`/`cosf`** which on
  newlib-nano internally promote to double precision and are slow
  (~3 µs/call on M33). A LUT-based version is on the Phase 7 todo.
- **Dialect rewriter doesn't yet handle**: P8SCII string control
  characters (`\^`, `\-`, `\|` inside strings), binary fixed-point
  literals (`0b1010.1`), some non-button Unicode identifiers.
- **No `cstore`/`reload` cross-cart persistence.** `dset`/`dget`
  return zero stubs.
- **Picker doesn't support folders** — flat `/carts/` listing only.

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
