/*
 * ThumbyP8 runtime — Phase 0 implementation
 *
 * Just enough to host a Lua 5.4 VM with a capped allocator and run
 * a string. Everything else (P8 memory map, drawing, audio, cart
 * loader) lives in later phases.
 */
#include "p8.h"

#include <setjmp.h>
#include <stdlib.h>
#include <string.h>

/* Panic recovery via longjmp. When a Lua operation hits an
 * unrecoverable error (typically OOM during compilation or error
 * construction), the panic handler fires. Instead of abort()
 * (which is a hardfault on bare metal), we longjmp back to the
 * caller's setjmp point so they can display a clean error.
 *
 * Usage: call p8_vm_set_panic_recovery() before any Lua call
 * that might panic. If it returns nonzero, panic was caught. */
jmp_buf g_panic_jmp;
volatile int g_panic_armed = 0;
char g_panic_msg[80] = {0};

/* Custom allocator: enforces P8_LUA_HEAP_CAP and tracks peak usage.
 * Lua's allocator contract is documented in lua.h: it doubles as
 * malloc/realloc/free depending on osize/nsize. */
static void *p8_lua_alloc(void *ud, void *ptr, size_t osize, size_t nsize) {
    p8_vm *vm = (p8_vm *)ud;

    /* free */
    if (nsize == 0) {
        if (ptr != NULL) {
            vm->bytes_in_use -= osize;
            free(ptr);
        }
        return NULL;
    }

    /* alloc / realloc — enforce cap on the *new* footprint */
    size_t projected = vm->bytes_in_use + nsize - (ptr ? osize : 0);
    if (projected > vm->bytes_cap) {
        return NULL;  /* Lua treats NULL as out-of-memory */
    }

    void *np = realloc(ptr, nsize);
    if (np == NULL) return NULL;

    vm->bytes_in_use = projected;
    if (vm->bytes_in_use > vm->bytes_peak) {
        vm->bytes_peak = vm->bytes_in_use;
    }
    return np;
}

/* Panic handler: Lua calls this when an error escapes all
 * protected calls (lua_pcall). This typically means an OOM during
 * an internal operation where Lua can't allocate the error
 * message. WE MUST NOT RETURN — Lua's state is invalid after a
 * panic. Returning causes the VM to execute on corrupt state,
 * which on Cortex-M manifests as a hardfault shortly after.
 *
 * On device, the hardfault handler will catch the abort and
 * display the red screen. On host, abort() produces a core dump. */
static int p8_lua_panic(lua_State *L) {
    const char *msg = lua_tostring(L, -1);
    if (msg) {
        strncpy(g_panic_msg, msg, sizeof(g_panic_msg) - 1);
    } else {
        strncpy(g_panic_msg, "unrecoverable Lua error (likely OOM)",
                sizeof(g_panic_msg) - 1);
    }
    g_panic_msg[sizeof(g_panic_msg) - 1] = 0;
    fprintf(stderr, "[ThumbyP8] PANIC: %s\n", g_panic_msg);
    fflush(stderr);
    if (g_panic_armed) {
        longjmp(g_panic_jmp, 1);
        /* unreachable */
    }
    abort();   /* fallback if longjmp isn't armed */
    return 0;
}

int p8_vm_init(p8_vm *vm, size_t heap_cap) {
    memset(vm, 0, sizeof(*vm));
    vm->bytes_cap = heap_cap ? heap_cap : P8_LUA_HEAP_CAP;

    vm->L = lua_newstate(p8_lua_alloc, vm);
    if (vm->L == NULL) return -1;

    lua_atpanic(vm->L, p8_lua_panic);

    /* Curated stdlib subset. PICO-8 itself only exposes a small
     * surface; we mirror that here so host and device builds load
     * the same modules. Crucially, we omit io / os / package /
     * coroutine / debug — io & package would pull fopen/dlopen
     * which the embedded build can't satisfy cheaply. */
    static const luaL_Reg p8_libs[] = {
        { "",              luaopen_base   },  /* Lua 5.2: base lib name is "" */
        { LUA_TABLIBNAME,  luaopen_table  },
        { LUA_STRLIBNAME,  luaopen_string },
        { LUA_MATHLIBNAME, luaopen_math   },
        { NULL, NULL }
    };
    for (const luaL_Reg *lib = p8_libs; lib->func; lib++) {
        luaL_requiref(vm->L, lib->name, lib->func, 1);
        lua_pop(vm->L, 1);
    }

    return 0;
}

void p8_vm_free(p8_vm *vm) {
    if (vm == NULL) return;
    if (vm->L != NULL) {
        lua_close(vm->L);
        vm->L = NULL;
    }
}

int p8_vm_do_string(p8_vm *vm, const char *src, const char *chunkname) {
    int rc = luaL_loadbuffer(vm->L, src, strlen(src),
                             chunkname ? chunkname : "=chunk");
    if (rc != LUA_OK) {
        vm->last_error = rc;
        return rc;
    }
    rc = lua_pcall(vm->L, 0, LUA_MULTRET, 0);
    vm->last_error = rc;
    return rc;
}

const char *p8_vm_last_error_msg(p8_vm *vm) {
    if (vm->last_error == 0) return NULL;
    if (lua_gettop(vm->L) == 0) return "(no message)";
    return lua_tostring(vm->L, -1);
}
