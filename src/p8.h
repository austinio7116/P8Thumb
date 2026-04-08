/*
 * ThumbyP8 — PICO-8-compatible fantasy console runtime
 *
 * Phase 0: bare Lua VM wrapper + benchmark hooks. No PICO-8 API
 * surface yet — that arrives in Phase 1+ once we know the VM fits
 * in our CPU budget.
 */
#ifndef THUMBYP8_P8_H
#define THUMBYP8_P8_H

#include <stddef.h>
#include <stdint.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Heap cap for the Lua VM, in bytes. Phase 0 cap is intentionally
 * tight so OOMs surface early. Will be raised in Phase 1 once the
 * 64 KB P8 memory map and framebuffers are accounted for. */
#ifndef P8_LUA_HEAP_CAP
/* 256 KB is comfortably above what real PICO-8 carts use in
 * practice (Celeste Classic peaks around 60 KB; Lootslime
 * pre-allocates a couple of large tables in _init and exceeds
 * 128 KB; nothing legitimate goes past ~200 KB). */
/* Realistic device ceiling: 520 KB SRAM minus ~280 KB BSS minus
 * ~16 KB stacks ≈ 220 KB free at boot. We leave a safety margin
 * for malloc fragmentation, FatFs/MSC scratch buffers, and the
 * stb_image transient when picker thumbnails are decoded. 192 KB
 * is the largest cap that comfortably fits all of those. Carts
 * that legitimately need more (e.g. lootslime which pre-allocates
 * many large tables in _init) can't run on this hardware. */
#define P8_LUA_HEAP_CAP (192 * 1024)
#endif

typedef struct p8_vm {
    lua_State *L;
    size_t bytes_in_use;   /* live bytes counted by our allocator */
    size_t bytes_peak;     /* high-water mark */
    size_t bytes_cap;      /* hard ceiling — alloc returns NULL beyond this */
    int    last_error;     /* last lua_pcall result, 0 = ok */
} p8_vm;

/* Lifecycle */
int  p8_vm_init(p8_vm *vm, size_t heap_cap);
void p8_vm_free(p8_vm *vm);

/* Run a chunk of Lua source. Returns 0 on success, nonzero on error.
 * On error, the error message is left on the Lua stack and can be
 * fetched with p8_vm_last_error_msg(). */
int  p8_vm_do_string(p8_vm *vm, const char *src, const char *chunkname);

/* After an error, returns the message string (valid until the next
 * VM call). NULL if there was no error. */
const char *p8_vm_last_error_msg(p8_vm *vm);

#ifdef __cplusplus
}
#endif

#endif /* THUMBYP8_P8_H */
