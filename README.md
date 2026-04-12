# ThumbyP8

A PICO-8-compatible fantasy console runtime for the **TinyCircuits Thumby Color** (RP2350 Cortex-M33, 128×128 RGB565 LCD, 4-channel audio, 520 KB SRAM, 16 MB flash).

Drop `.p8.png` cart files onto the USB drive — they are automatically converted and ready to play on next boot. No host tools required.

PICO-8 is a trademark of Lexaloffle Games. ThumbyP8 is an independent, clean-room reimplementation of the publicly documented PICO-8 fantasy console API.

---

## Quick Start

### 1. Flash the firmware

Download [`firmware.uf2`](firmware.uf2) from this repo (click the file, then "Download raw file").

> **Warning:** Flashing ThumbyP8 replaces whatever is currently on your Thumby Color (the stock MicroPython system, any games, etc). To go back, reflash the original Thumby Color firmware the same way.

To flash:
1. Power off the Thumby Color
2. Hold **DOWN** on the d-pad and power on — the device enters BOOTSEL mode
3. It appears as a USB drive called `RPI-RP2350` on your computer
4. Drag `firmware.uf2` onto that drive
5. The device reboots automatically into ThumbyP8

### 2. Add carts

On first boot, the device formats its flash storage and appears as a USB drive labelled **P8THUMBv1**.

1. Download `.p8.png` cart files from the [PICO-8 BBS](https://www.lexaloffle.com/bbs/?cat=7) or elsewhere
2. Drag them into the `/carts/` folder on the P8THUMBv1 drive
3. Eject the drive from your OS (or just wait — it auto-flushes)
4. Press **A** to enter the game picker

The device automatically converts `.p8.png` files to playable bytecode on boot. This takes one reboot per cart (a few seconds each). You'll see a progress screen during conversion.

### 3. Play

Use **◀ ▶** in the picker to browse carts (shows the cart's label art). Press **A** to launch.

### 4. In-game menu

Long-press **MENU** (>400ms) during gameplay to open the pause menu:
- **Resume** — return to the game
- **Volume** — master audio (slider)
- **Show FPS** — toggle FPS counter
- **Disk** / **Battery** — info displays
- **Quit to picker** — exit the current cart

The same menu is available from the picker (without Quit).

### 5. Troubleshooting

- **USB drive not showing up or not named P8THUMBv1?** Hold **MENU** while powering on — this forces a full reformat of the flash filesystem.
- **Cart conversion stuck?** Hold **B** while powering on to skip conversion.
- **Want to go back to the stock Thumby Color firmware?** Enter BOOTSEL (power off → hold DOWN → power on) and flash the original `.uf2`. The RP2350 boot ROM cannot be bricked — BOOTSEL always works.

---

## How It Works

### The Big Picture

When you drop a `.p8.png` onto the USB drive and reboot, here's what happens:

```
  .p8.png file on FAT filesystem
       │
       ▼
  ┌─────────────────────────────────────────────┐
  │  ON-DEVICE CONVERSION (runs at boot)        │
  │                                             │
  │  1. PNG decode (stb_image via file I/O)     │
  │  2. Steganographic byte extraction          │
  │  3. PXA Lua decompression                   │
  │  4. shrinko8 parse + unminify (C port)      │
  │  5. PICO-8 dialect → Lua 5.4 translation    │
  │  6. Lua 5.4 bytecode compilation            │
  │  7. Save .luac + .rom + .bmp to FAT         │
  │  8. Reboot (one cart per cycle)             │
  │                                             │
  └─────────────────────────────────────────────┘
       │
       ▼
  .luac (bytecode) + .rom (sprites/sfx/map) + .bmp (thumbnail)
       │
       ▼
  ┌─────────────────────────────────────────────┐
  │  GAME EXECUTION                             │
  │                                             │
  │  1. Program .luac + .rom into XIP flash     │
  │  2. Load bytecode directly from flash       │
  │     (Proto.code[] stays in XIP, not heap)   │
  │  3. Copy ROM into PICO-8 memory map         │
  │  4. Call _init(), then _update()/_draw()    │
  │     loop at 30 or 60 fps                    │
  │                                             │
  └─────────────────────────────────────────────┘
```

### Layer 1: The Conversion Pipeline

PICO-8 `.p8.png` carts steganographically encode 32 KB of data in the low 2 bits of each pixel of a 160×205 PNG. The data contains:
- **ROM** (0x0000–0x42FF): sprite sheet, sprite flags, map, SFX, music
- **Lua source** (0x4300–0x7FFF): compressed with PXA (move-to-front + Golomb-coded bitstream)

The conversion pipeline has three stages:

**Stage 1: PNG decode + PXA decompress** (`src/p8_p8png.c`)
- stb_image decodes the PNG via file I/O callbacks (no full PNG in heap — saves ~70KB)
- Cart bytes extracted from low 2 bits of RGBA pixels
- Thumbnail extracted from visible PNG pixels (128×128 crop at 16,24) → saved as BMP
- ROM bytes saved directly to `.rom` file
- PXA bitstream decompressed to raw PICO-8 Lua source

**Stage 2: shrinko8 unminify** (`src/p8_shrinko.c`)

A streaming C port of [shrinko8](https://github.com/thisismypassport/shrinko8) (MIT). This is a proper PICO-8 tokenizer + recursive-descent parser that handles minified source correctly (e.g. `j-=1return0nC()` → proper token boundaries). The streaming architecture uses ~90KB peak memory (no AST, no token array — the C call stack IS the parse tree).

The parser also converts PICO-8 fixed-point bitwise operators to function calls during emission:
- `a << b` → `shl(a, b)` / `a >> b` → `shr(a, b)`
- `a >>> b` → `lshr(a, b)` / `a <<> b` → `rotl(a, b)` / `a >>< b` → `rotr(a, b)`
- `a & b` → `band(a, b)` / `a | b` → `bor(a, b)` / `a ^^ b` → `bxor(a, b)`
- `~a` → `bnot(a)`

This is necessary because PICO-8 uses 16.16 fixed-point for all bitwise operations (`0.5 << 1 = 1.0`), while Lua 5.4's native operators require integers.

The unminifier also handles:
- Shorthand `if (cond) stmt` → `if cond then stmt end`
- Shorthand `while (cond) stmt` → `while cond do stmt end`
- `if cond do` → `if cond then`
- `? expr` print shorthand → `print(expr)`
- `// comments` → `-- comments`
- Proper whitespace insertion between tokens

**Stage 3: Dialect translation** (`src/p8_translate.c`)

Character-level transforms on the clean shrinko8 output:
- `\` → `//` (integer divide), `\=` → `//=`
- `@addr` → `peek(addr)`, `%addr` → `peek2(addr)`, `$addr` → `peek4(addr)`
- `0b1010` binary literals → decimal
- Button/arrow glyphs (⬅➡⬆⬇🅾❎) → button indices (0–5)
- P8SCII high bytes in code → numeric values
- String escape rewriting (`\^`, `\-`, etc. → `\xHH`)
- `;` before `(` at line start (Lua parser disambiguation)

Then a line-based rewriter expands compound assigns (`x += y` → `x = x + (y)`) and converts `!=` → `~=`.

**Stage 4: Compile** (Lua 5.4's `luaL_loadbuffer` + `lua_dump`)

The translated Lua 5.4 source is compiled to bytecode by the standard Lua compiler (vendored PUC Lua 5.4.7). The bytecode is dumped to a `.luac` file on the FAT filesystem.

### Layer 2: The Lua Runtime

ThumbyP8 vendors **PUC Lua 5.4.7** (MIT, unmodified reference implementation from lua.org) compiled with `LUA_32BITS=1` for 32-bit integer + 32-bit float (the RP2350's Cortex-M33 has a single-precision FPU but no double FPU).

```
src/p8.c               ← Lua VM lifecycle + capped allocator
  │
  ▼
lua/                   ← Vendored Lua 5.4.7
├── lvm.c              ← Bytecode dispatch (the hot loop)
├── lparser.c          ← Parser → bytecode compiler
├── lgc.c              ← Garbage collector
├── lapi.c, ldo.c, llex.c, lstring.c, ltable.c, …
└── lbaselib.c, ltablib.c, lstrlib.c, lmathlib.c
```

**What runs as Lua bytecode** (interpreted by `lvm.c`):
- The cart's `_init`, `_update`/`_update60`, and `_draw` functions
- All game logic: entity systems, level generation, particles, AI, menus
- Everything the cart author wrote

**What runs as native C** (called from Lua via the C API):
- Every PICO-8 API binding in `src/p8_api.c` (~80 functions)
- Drawing primitives in `src/p8_draw.c` (Bresenham line, midpoint circle, sprite blit, tilemap, palette remap)
- Audio synth in `src/p8_audio.c` (4 channels, 8 waveforms, effects)
- Font rendering in `src/p8_font.c`

**The boundary in practice:** When Celeste calls `circfill(64, 64, 8, 7)`:
1. Lua's `lvm.c` executes the CALL instruction
2. Jumps to C function `l_circfill` in `p8_api.c`
3. Which reads arguments from the Lua stack
4. Calls `p8_circfill` in `p8_draw.c`
5. Which writes pixels into the 4bpp framebuffer at `machine.mem[0x6000..]`
6. At frame end, `p8_machine_present` expands 4bpp → RGB565 into a scanline buffer
7. `p8_lcd_present` DMAs the buffer to the GC9107 LCD

**Performance:** Lua bytecode dispatch costs ~148 ns per instruction at 250 MHz. Carts do 10K–30K instructions per frame at 30 fps, so the interpreter uses ~1–4 ms of the 33 ms frame budget. Drawing and audio (pure C) dominate.

**Fixed-point bitwise operations:** PICO-8 uses 16.16 fixed-point for all bitwise ops. The runtime functions (`shl`, `shr`, `band`, `bor`, etc.) convert to/from fixed-point:
```c
int32_t fix = (int32_t)(lua_value * 65536.0f);  // to fixed-point
// ... operate on fix ...
// return as integer if fractional part is zero, float otherwise
if ((result & 0xFFFF) == 0) lua_pushinteger(L, result >> 16);
else lua_pushnumber(L, (float)result / 65536.0f);
```
This preserves Lua 5.4's integer/float key distinction (`t[3]` ≠ `t[3.0]`).

### Layer 3: XIP Bytecode Execution

Compiled `.luac` bytecode is programmed into a dedicated "active cart" region in QSPI flash (256 KB at 13 MB offset). When `luaL_loadbuffer` loads the bytecode, a patched `lundump.c` detects that the source pointer is in the XIP address range (0x10000000–0x11000000) and stores `Proto.code[]` as a direct pointer into flash instead of copying to heap. This saves ~30-50 KB of Lua heap per cart.

A corresponding patch in `lfunc.c` ensures the GC doesn't try to free XIP-resident code arrays.

### Layer 4: Hardware Drivers

| Component | File | Details |
|-----------|------|---------|
| LCD | `device/p8_lcd_gc9107.c` | GC9107 SPI at 80 MHz, DMA transfer, GP18/19/17/16/4/7 |
| Buttons | `device/p8_buttons.c` | GPIO read, 5-frame diagonal coalescing (LB=UP+LEFT, RB=UP+RIGHT) |
| Audio | `device/p8_audio_pwm.c` | GP23 PWM 9-bit DAC, GP20 amp enable, 22050 Hz IRQ, ring buffer |
| Flash disk | `device/p8_flash_disk.c` | 12 MB at 1 MB offset, 8-block write-back cache, cooperative drain |
| USB MSC | `device/p8_msc.c` | TinyUSB MSC+CDC composite, FAT16 filesystem |
| Cart flash | `device/p8_cart_flash.c` | Active cart region: 256 KB at 13 MB, erase + program + XIP map |

---

## Memory Map

```
520 KB SRAM
├── ~148 KB  BSS (machine state, scanline buffer, flash cache, statics)
├── 16 KB    Stack (PICO_STACK_SIZE=0x4000, needed for Lua C→Lua→C recursion)
├── ~356 KB  Heap, of which:
│   ├── 300 KB  Lua VM heap cap
│   └── ~56 KB  Cart load transients (freed before _init)

16 MB QSPI Flash
├── 0–1 MB       Firmware (~740 KB)
├── 1–13 MB      FAT16 cart filesystem (12 MB usable)
└── 13–13.25 MB  Active cart region (bytecode + ROM in XIP)
```

### Conversion Memory Budget

The on-device conversion pipeline uses ~260 KB peak during PNG decode (stb_image internals). To avoid heap fragmentation, only one cart is converted per boot — the device reboots after each conversion. On next boot, the just-converted cart is skipped (has `.luac`), and the next unconverted cart is processed.

---

## In-Game Menu

Long-press MENU (>400 ms) during gameplay to open:

| Item | Type | Description |
|------|------|-------------|
| Resume | Action | Close menu, return to game |
| Volume | Slider 0–30 | Master audio volume (unity at 15) |
| Show FPS | Toggle | FPS counter overlay (top-right, green) |
| Disk | Info | Used/total KB with progress bar |
| Battery | Info | Percentage with progress bar |
| Quit to picker | Action | Exit current cart |

The menu renders as a translucent overlay on top of the dimmed game frame.

---

## Cart Compatibility

See [COMPATIBILITY.md](COMPATIBILITY.md) for per-cart test results.

**34/34** test carts compile successfully through the on-device pipeline. Runtime compatibility varies — see the compatibility file for details.

### Known Limitations

- **Lua heap cap is 300 KB.** Very large carts may OOM during `_init`.
- **`fillp` is a stub** — fill patterns don't render.
- **`tline` is a stub** — mode-7/floor effects don't render.
- **`reload` is a stub** — runtime ROM restore doesn't work.
- **`cstore`/`dget`/`dset` are stubs** — no persistent save data.
- **No multi-cart support** — `load()` won't load other carts.
- **No mouse input** — carts requiring mouse won't work.
- **P8SCII special characters** display as blocks, not glyphs.

---

## Building

### Prerequisites

```bash
sudo apt install build-essential cmake gcc-arm-none-eabi \
                 libnewlib-arm-none-eabi libsdl2-dev python3-pillow
```

Pico SDK required at a known path (e.g. `../mp-thumby/lib/pico-sdk`).

### Device Firmware

```bash
cd ThumbyP8
cmake -B build_device -S device \
      -DPICO_SDK_PATH=/path/to/pico-sdk
cmake --build build_device -j8
# Output: build_device/p8run_device.uf2
```

### Host Test Tool

```bash
gcc -O2 -I src -I src/lib -o tools/test_translate \
    tools/test_translate.c src/p8_p8png.c src/p8_translate.c \
    src/p8_shrinko.c src/p8_machine.c -lm

# Test a cart:
./tools/test_translate carts/celeste.p8.png > /tmp/celeste.lua
./tools/luac54 -o /dev/null /tmp/celeste.lua  # should succeed
```

---

## Repository Layout

```
ThumbyP8/
├── README.md                  ← this file
├── COMPATIBILITY.md           ← per-cart test results
├── lua/                       ← vendored Lua 5.4.7 (MIT)
├── src/                       ← cross-platform runtime
│   ├── p8.c/h                 ← Lua VM lifecycle + capped allocator
│   ├── p8_machine.c/h         ← 64 KB PICO-8 memory map
│   ├── p8_draw.c/h            ← drawing primitives
│   ├── p8_api.c/h             ← ~80 Lua bindings for PICO-8 API
│   ├── p8_audio.c/h           ← 4-channel synth
│   ├── p8_font.c/h            ← 3×5 bitmap font (Pemsa, MIT)
│   ├── p8_shrinko.c/h         ← streaming shrinko8 C port (tokenize+parse+emit)
│   ├── p8_translate.c/h       ← PICO-8 dialect → Lua 5.4 translator
│   ├── p8_p8png.c/h           ← .p8.png decoder (stb_image + PXA)
│   ├── p8_cart.c/h            ← .p8 text cart loader
│   ├── p8_input.c/h           ← button mask helpers
│   └── lib/stb_image.h        ← vendored PNG decoder
│
├── device/                    ← device-only firmware
│   ├── CMakeLists.txt         ← Pico SDK build
│   ├── p8_device_main.c       ← boot → convert → lobby → pick → play
│   ├── p8_menu.c/h            ← in-game pause menu
│   ├── p8_lcd_gc9107.c/h      ← GC9107 SPI/DMA LCD driver
│   ├── p8_buttons.c/h         ← GPIO button reader
│   ├── p8_audio_pwm.c/h       ← PWM audio + master volume
│   ├── p8_flash_disk.c/h      ← flash-backed FAT disk
│   ├── p8_cart_flash.c/h      ← active cart flash region
│   ├── p8_picker.c/h          ← cart picker UI
│   ├── p8_bmp.c/h             ← BMP loader + writer
│   ├── p8_log.c/h             ← ring buffer + file logging
│   ├── p8_msc.c               ← TinyUSB MSC callbacks
│   ├── usb_descriptors.c      ← USB device descriptors
│   └── fatfs/                 ← vendored FatFs R0.15 (BSD-1, ChaN)
│
├── tools/
│   ├── test_translate.c       ← host-side translation tester
│   ├── test_full_pipeline.c   ← end-to-end pipeline tester
│   ├── p8png_extract.py       ← (legacy) host preprocessor
│   ├── pico8_lua.py           ← (legacy) token rewriter
│   └── shrinko8/              ← vendored shrinko8 (MIT)
│
└── carts/                     ← test .p8.png cart files
```

---

## Licenses

- **Lua 5.4.7** — MIT, Lua.org
- **stb_image** — Public domain / MIT, Sean Barrett
- **FatFs R0.15** — BSD-1-clause, ChaN
- **shrinko8** — MIT, thisismypassport (C port in p8_shrinko.c)
- **Pemsa font** — MIT, egordorichev (glyph data in p8_font.c)

ThumbyP8 reproduces none of Lexaloffle's source code. The runtime is implemented from the publicly documented PICO-8 fantasy console API.
