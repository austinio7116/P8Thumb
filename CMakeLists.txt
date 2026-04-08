cmake_minimum_required(VERSION 3.16)
project(ThumbyP8 C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Aggressive but portable host flags. We mirror what we'd use on
# the device so the bench numbers are roughly comparable.
add_compile_options(
    -Wall
    -Wextra
    -Wno-unused-parameter
    -Wno-sign-compare
    -fno-strict-aliasing
)

# ----------------------------------------------------------------------
# Lua 5.4.7 (vendored, MIT — see lua/README)
# ----------------------------------------------------------------------
file(GLOB LUA_SOURCES CONFIGURE_DEPENDS lua/*.c)
# lua.c (standalone interpreter) and luac.c (compiler) are excluded
# at vendor time, so the glob is safe.

add_library(thumbyp8_lua STATIC ${LUA_SOURCES})
target_include_directories(thumbyp8_lua PUBLIC lua)
target_compile_definitions(thumbyp8_lua PUBLIC
    LUA_USE_POSIX            # enables POSIX features in loslib (host only)
    LUA_COMPAT_5_3
)
# Lua wants libm for math.sin/cos/etc.
target_link_libraries(thumbyp8_lua PUBLIC m)

# ----------------------------------------------------------------------
# ThumbyP8 runtime
# ----------------------------------------------------------------------
add_library(thumbyp8 STATIC
    src/p8.c
    src/p8_machine.c
    src/p8_draw.c
    src/p8_api.c
    src/p8_cart.c
    src/p8_rewrite.c
    src/p8_font.c
    src/p8_audio.c
)
target_include_directories(thumbyp8 PUBLIC src)
target_link_libraries(thumbyp8 PUBLIC thumbyp8_lua)

# ----------------------------------------------------------------------
# Phase 0 benchmark harness
# ----------------------------------------------------------------------
add_executable(p8bench src/bench_main.c)
target_link_libraries(p8bench PRIVATE thumbyp8)

# ----------------------------------------------------------------------
# Phase 1+2 SDL2 host runner
# ----------------------------------------------------------------------
find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL2 REQUIRED sdl2)

add_executable(p8run src/host_main.c)
target_link_libraries(p8run PRIVATE thumbyp8 ${SDL2_LIBRARIES})
target_include_directories(p8run PRIVATE ${SDL2_INCLUDE_DIRS})
target_compile_options(p8run PRIVATE ${SDL2_CFLAGS_OTHER})
