#
# ThumbyP8 — Phase 0.5 device cross-build
#
# Builds the same Lua bench harness as the host build, but targeting
# the Thumby Color (RP2350) using the Pico SDK vendored inside the
# sibling mp-thumby checkout.
#
# Build:
#   cd ThumbyP8
#   cmake -B build_device -S device \
#         -DPICO_SDK_PATH=/home/maustin/mp-thumby/lib/pico-sdk
#   cmake --build build_device -j8
#
# Output: build_device/p8bench_device.uf2
# Flash:  BOOTSEL the Thumby Color, drag the .uf2 onto it.
# Read:   `mpremote connect /dev/ttyACM0` or any USB CDC terminal
#         (the device exposes a CDC ACM serial port — bench output
#         prints there).
#
cmake_minimum_required(VERSION 3.16)

# Pull the SDK in BEFORE project() — it sets the toolchain.
set(PICO_BOARD tinycircuits_thumby_color_rp2350)
set(PICO_PLATFORM rp2350)
include(${PICO_SDK_PATH}/pico_sdk_init.cmake)

project(thumbyp8_device C CXX ASM)
set(CMAKE_C_STANDARD 11)

pico_sdk_init()

set(P8_ROOT ${CMAKE_CURRENT_LIST_DIR}/..)

# ----------------------------------------------------------------------
# Lua 5.2.4 — embedded subset
# ----------------------------------------------------------------------
# Files we deliberately exclude from the device build:
#   lua.c     — standalone interpreter main (excluded at vendor time)
#   luac.c    — bytecode compiler tool   (excluded at vendor time)
#   linit.c   — opens io/os/package/etc; we use our own curated open
#   liolib.c  — fopen/FILE* — too heavy for embedded
#   loadlib.c — dynamic loader (dlopen) — not available
#   loslib.c  — date/time/exit — uses time.h, mostly noise on device
#   ldblib.c  — debug library — drop for now
file(GLOB LUA_ALL CONFIGURE_DEPENDS ${P8_ROOT}/lua/*.c)
set(LUA_EXCLUDE
    ${P8_ROOT}/lua/linit.c
    ${P8_ROOT}/lua/liolib.c
    ${P8_ROOT}/lua/loadlib.c
    ${P8_ROOT}/lua/loslib.c
    ${P8_ROOT}/lua/ldblib.c
)
list(REMOVE_ITEM LUA_ALL ${LUA_EXCLUDE})

add_library(thumbyp8_lua STATIC ${LUA_ALL})
target_include_directories(thumbyp8_lua PUBLIC ${P8_ROOT}/lua)
target_compile_definitions(thumbyp8_lua PUBLIC
    LUA_USE_C89          # avoid POSIX-only paths
    # Lua 5.2 with luaconf.h patched for single-precision float.
    # No LUA_32BITS (that's a 5.3+ feature).
)
# Force -O3 across both Lua and our runtime — Release defaults to -O2.
target_compile_options(thumbyp8_lua PUBLIC -O3)
# Some Lua warnings are noisy with -Wall but harmless. Quiet them
# locally so they don't drown the build log.
target_compile_options(thumbyp8_lua PRIVATE
    -Wno-implicit-fallthrough
    -Wno-deprecated-declarations
    -Wno-stringop-overflow
    -Wno-array-bounds
)

# ----------------------------------------------------------------------
# ThumbyP8 runtime + bench harness
# ----------------------------------------------------------------------
add_executable(p8bench_device
    ${P8_ROOT}/src/p8.c
    ${P8_ROOT}/src/bench_main.c
)
target_include_directories(p8bench_device PRIVATE ${P8_ROOT}/src)
target_compile_options(p8bench_device PRIVATE -O3)
target_link_libraries(p8bench_device PRIVATE
    thumbyp8_lua
    pico_stdlib
    hardware_clocks
)

# Route stdio over USB CDC, not UART — there's no exposed UART pin.
pico_enable_stdio_usb(p8bench_device 1)
pico_enable_stdio_uart(p8bench_device 0)

pico_add_extra_outputs(p8bench_device)

# ----------------------------------------------------------------------
# ThumbyP8 runtime: shared static library for the device
# ----------------------------------------------------------------------
# Same source list as the host build's `thumbyp8` target, but compiled
# with PICO_ON_DEVICE so the file IO path in p8_cart.c is excluded.
# Device runtime: includes the full translation pipeline so .p8.png
# carts can be converted on-device without any host-side tools.
add_library(thumbyp8_runtime STATIC
    ${P8_ROOT}/src/p8.c
    ${P8_ROOT}/src/p8_machine.c
    ${P8_ROOT}/src/p8_draw.c
    ${P8_ROOT}/src/p8_api.c
    ${P8_ROOT}/src/p8_font.c
    ${P8_ROOT}/src/p8_audio.c
    ${P8_ROOT}/src/p8_cart.c
    ${P8_ROOT}/src/p8_translate.c
    ${P8_ROOT}/src/p8_shrinko.c
    ${P8_ROOT}/src/p8_p8png.c
)
target_include_directories(thumbyp8_runtime PUBLIC ${P8_ROOT}/src)
target_compile_options(thumbyp8_runtime PRIVATE -O3)
target_link_libraries(thumbyp8_runtime PUBLIC thumbyp8_lua pico_stdlib)

# ----------------------------------------------------------------------
# p8run_device: full PICO-8 runtime targeting the LCD + buttons
# ----------------------------------------------------------------------
add_executable(p8run_device
    p8_device_main.c
    p8_lcd_gc9107.c
    p8_buttons.c
    p8_audio_pwm.c
    p8_flash_disk.c
    p8_cart_flash.c
    p8_msc.c
    p8_picker.c
    p8_log.c
    p8_bmp.c
    p8_menu.c
    usb_descriptors.c
    fatfs/ff.c
    fatfs/ffsystem.c
    fatfs/ffunicode.c
    fatfs/diskio.c
)
target_include_directories(p8run_device PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}
    ${CMAKE_CURRENT_LIST_DIR}/fatfs
)
target_compile_options(p8run_device PRIVATE -O3 -Wno-unused-parameter)
# Bigger stack. PICO_STACK_SIZE defaults to 0x800 (2 KB!) which is
# too small for a Lua VM that recurses C→Lua→C during foreach/all
# chains. The define must reach crt0.S (assembly), not just C files,
# so we put it on the INTERFACE of pico_platform — that propagates
# to every translation unit including the SDK's own crt0.
# 16 KB gives ~80 nested C call frames, enough for any cart.
target_compile_definitions(pico_platform INTERFACE PICO_STACK_SIZE=0x4000)
# Direct TinyUSB integration (no pico_stdio_usb — we own the descriptors).
target_link_libraries(p8run_device PRIVATE
    thumbyp8_runtime
    pico_stdlib
    pico_unique_id
    hardware_clocks
    hardware_spi
    hardware_dma
    hardware_gpio
    hardware_pwm
    hardware_irq
    hardware_flash
    hardware_sync
    pico_multicore
    tinyusb_device
)
# Core 1 stack: SDK default is 16KB in SCRATCH_X which overflows.
# We pass our own stack via multicore_launch_core1_with_stack,
# so the SDK's built-in stack just needs to be minimal.
target_compile_definitions(p8run_device PRIVATE
    PICO_CORE1_STACK_SIZE=0x100
    tinyusb_board
)
# Stdio: no USB CDC via pico_stdio_usb (would clash with composite),
# no UART (no pin). On-screen errors only for now; CDC is exposed
# through TinyUSB but stdio doesn't auto-route to it yet.
pico_enable_stdio_usb(p8run_device 0)
pico_enable_stdio_uart(p8run_device 0)
pico_add_extra_outputs(p8run_device)
