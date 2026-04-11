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
/* Device: 520 KB SRAM − ~148 KB BSS − 16 KB stack = ~356 KB for
 * libc heap. With the XIP bytecode patch, Proto.code[] arrays
 * live in flash (not heap), so the Lua heap only holds strings,
 * tables, closures, and GC metadata. 300 KB cap leaves ~56 KB
 * for libc overhead + malloc fragmentation. */
#define P8_LUA_HEAP_CAP (300 * 1024)
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

/* Panic recovery. Call p8_vm_panic_arm() before any Lua operation
 * that might trigger an unrecoverable error (typically OOM during
 * compilation). Returns 0 on first call (arm succeeded). If a
 * panic fires, longjmp brings us back here with return value 1.
 * Call p8_vm_panic_disarm() when done with the dangerous section.
 * After a panic, the Lua VM is INVALID — do not use it. */
#include <setjmp.h>
extern jmp_buf g_panic_jmp;
extern volatile int g_panic_armed;
extern char g_panic_msg[80];
#define p8_vm_panic_arm()    (g_panic_armed = 1, setjmp(g_panic_jmp))
#define p8_vm_panic_disarm() (g_panic_armed = 0)

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
