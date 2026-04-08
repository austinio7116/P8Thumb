/*
 * ThumbyP8 — Lua bindings for the PICO-8 API.
 *
 * Each binding is a tiny C function that pulls args off the Lua
 * stack and calls into the corresponding p8_draw / p8_machine /
 * p8_input routine. The bindings are intentionally lenient with
 * argument coercion (PICO-8 carts pass numbers where ints are
 * expected, sometimes negative, sometimes out of range) — we
 * defer to luaL_optnumber and floor.
 *
 * Stash p8_machine* and p8_input* in the Lua registry under
 * lightuserdata keys so each binding can recover them in O(1).
 */
#include "p8_api.h"
#include "p8_draw.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Registry keys — addresses of these statics are unique cookies. */
static const char k_machine_key = 0;
static const char k_input_key   = 0;

static p8_machine *get_machine(lua_State *L) {
    lua_pushlightuserdata(L, (void *)&k_machine_key);
    lua_rawget(L, LUA_REGISTRYINDEX);
    p8_machine *m = (p8_machine *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    return m;
}
static p8_input *get_input(lua_State *L) {
    lua_pushlightuserdata(L, (void *)&k_input_key);
    lua_rawget(L, LUA_REGISTRYINDEX);
    p8_input *in = (p8_input *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    return in;
}

/* PICO-8 numbers are 16.16 fixed point in real PICO-8; here they're
 * lua_Number. Floor-cast for coordinate args. */
static int argi(lua_State *L, int idx, int dflt) {
    if (lua_isnoneornil(L, idx)) return dflt;
    lua_Number n = luaL_checknumber(L, idx);
    return (int)floor((double)n);
}
/* (argn helper removed — unused after Phase 2 binding pass.) */

/* --- drawing primitives --------------------------------------------- */

static int l_cls(lua_State *L) {
    p8_cls(get_machine(L), argi(L, 1, 0));
    return 0;
}
static int l_pset(lua_State *L) {
    p8_machine *m = get_machine(L);
    int x = argi(L, 1, 0);
    int y = argi(L, 2, 0);
    int c = argi(L, 3, p8_pen(m));
    p8_pset(m, x, y, c);
    return 0;
}
static int l_pget(lua_State *L) {
    int v = p8_pget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0));
    lua_pushinteger(L, v);
    return 1;
}
static int l_color(lua_State *L) {
    p8_color(get_machine(L), argi(L, 1, 6));
    return 0;
}
static int l_camera(lua_State *L) {
    p8_camera(get_machine(L), argi(L, 1, 0), argi(L, 2, 0));
    return 0;
}
static int l_clip(lua_State *L) {
    p8_machine *m = get_machine(L);
    if (lua_gettop(L) == 0) { p8_clip(m, 0, 0, 0, 0, 1); return 0; }
    p8_clip(m, argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, 128), argi(L, 4, 128), 0);
    return 0;
}
static int l_line(lua_State *L) {
    p8_machine *m = get_machine(L);
    int x0 = argi(L, 1, 0);
    int y0 = argi(L, 2, 0);
    int x1 = argi(L, 3, 0);
    int y1 = argi(L, 4, 0);
    int c  = argi(L, 5, p8_pen(m));
    p8_line(m, x0, y0, x1, y1, c);
    return 0;
}
static int l_rect(lua_State *L) {
    p8_machine *m = get_machine(L);
    p8_rect(m, argi(L, 1, 0), argi(L, 2, 0),
               argi(L, 3, 0), argi(L, 4, 0),
               argi(L, 5, p8_pen(m)));
    return 0;
}
static int l_rectfill(lua_State *L) {
    p8_machine *m = get_machine(L);
    p8_rectfill(m, argi(L, 1, 0), argi(L, 2, 0),
                   argi(L, 3, 0), argi(L, 4, 0),
                   argi(L, 5, p8_pen(m)));
    return 0;
}
static int l_circ(lua_State *L) {
    p8_machine *m = get_machine(L);
    p8_circ(m, argi(L, 1, 0), argi(L, 2, 0),
               argi(L, 3, 4), argi(L, 4, p8_pen(m)));
    return 0;
}
static int l_circfill(lua_State *L) {
    p8_machine *m = get_machine(L);
    p8_circfill(m, argi(L, 1, 0), argi(L, 2, 0),
                   argi(L, 3, 4), argi(L, 4, p8_pen(m)));
    return 0;
}

static int l_pal(lua_State *L) {
    p8_machine *m = get_machine(L);
    if (lua_gettop(L) == 0) { p8_pal_reset(m); return 0; }
    int c0 = argi(L, 1, 0);
    int c1 = argi(L, 2, 0);
    int p  = argi(L, 3, 0);
    p8_pal_set(m, c0, c1, p);
    return 0;
}
static int l_palt(lua_State *L) {
    p8_machine *m = get_machine(L);
    if (lua_gettop(L) == 0) {
        /* reset transparency: only color 0 transparent */
        for (int i = 0; i < 16; i++) {
            if (i == 0) m->mem[P8_DS_DRAW_PAL + i] |= 0x10;
            else        m->mem[P8_DS_DRAW_PAL + i] &= ~0x10;
        }
        return 0;
    }
    int c = argi(L, 1, 0);
    int t = lua_toboolean(L, 2);
    p8_palt(m, c, t);
    return 0;
}

/* --- sprites + map --------------------------------------------------- */

static int l_spr(lua_State *L) {
    p8_machine *m = get_machine(L);
    int n  = argi(L, 1, 0);
    int x  = argi(L, 2, 0);
    int y  = argi(L, 3, 0);
    int w  = argi(L, 4, 1);
    int h  = argi(L, 5, 1);
    int fx = lua_toboolean(L, 6);
    int fy = lua_toboolean(L, 7);
    p8_spr(m, n, x, y, w, h, fx, fy);
    return 0;
}
static int l_sspr(lua_State *L) {
    p8_machine *m = get_machine(L);
    int sx = argi(L, 1, 0);
    int sy = argi(L, 2, 0);
    int sw = argi(L, 3, 8);
    int sh = argi(L, 4, 8);
    int dx = argi(L, 5, 0);
    int dy = argi(L, 6, 0);
    int dw = argi(L, 7, sw);
    int dh = argi(L, 8, sh);
    int fx = lua_toboolean(L, 9);
    int fy = lua_toboolean(L, 10);
    p8_sspr(m, sx, sy, sw, sh, dx, dy, dw, dh, fx, fy);
    return 0;
}
static int l_map(lua_State *L) {
    p8_machine *m = get_machine(L);
    int cx = argi(L, 1, 0);
    int cy = argi(L, 2, 0);
    int sx = argi(L, 3, 0);
    int sy = argi(L, 4, 0);
    int cw = argi(L, 5, 128);
    int ch = argi(L, 6, 64);
    int layer = argi(L, 7, 0);
    p8_map(m, cx, cy, sx, sy, cw, ch, layer);
    return 0;
}
static int l_mget(lua_State *L) {
    lua_pushinteger(L, p8_mget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0)));
    return 1;
}
static int l_mset(lua_State *L) {
    p8_mset(get_machine(L), argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, 0));
    return 0;
}
static int l_fget(lua_State *L) {
    p8_machine *m = get_machine(L);
    int n = argi(L, 1, 0);
    if (lua_isnoneornil(L, 2)) {
        lua_pushinteger(L, p8_fget(m, n, -1));
    } else {
        lua_pushboolean(L, p8_fget(m, n, argi(L, 2, 0)));
    }
    return 1;
}
static int l_fset(lua_State *L) {
    p8_machine *m = get_machine(L);
    int n = argi(L, 1, 0);
    if (lua_isboolean(L, 2)) {
        p8_fset(m, n, -1, lua_toboolean(L, 2));
    } else if (lua_isnoneornil(L, 3)) {
        p8_fset(m, n, -1, argi(L, 2, 0));
    } else {
        int f = argi(L, 2, 0);
        int v = lua_toboolean(L, 3);
        p8_fset(m, n, f, v);
    }
    return 0;
}
static int l_sget(lua_State *L) {
    lua_pushinteger(L, p8_sget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0)));
    return 1;
}
static int l_sset(lua_State *L) {
    p8_machine *m = get_machine(L);
    p8_sset(m, argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, p8_pen(m)));
    return 0;
}

/* --- input ----------------------------------------------------------- */

static int l_btn(lua_State *L) {
    if (lua_isnoneornil(L, 1)) {
        lua_pushinteger(L, get_input(L)->cur);
        return 1;
    }
    lua_pushboolean(L, p8_btn(get_input(L), argi(L, 1, 0)));
    return 1;
}
static int l_btnp(lua_State *L) {
    if (lua_isnoneornil(L, 1)) {
        p8_input *in = get_input(L);
        lua_pushinteger(L, in->cur & ~in->prev);
        return 1;
    }
    lua_pushboolean(L, p8_btnp(get_input(L), argi(L, 1, 0)));
    return 1;
}

/* --- math helpers (PICO-8 idioms) ------------------------------------ */
/* PICO-8 sin/cos take *turns* (0..1), and sin is negated relative to
 * libm. atan2 also returns turns and is anticlockwise in screenspace. */

static int l_p8_sin(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);
    lua_pushnumber(L, -sin(a * 2.0 * M_PI));
    return 1;
}
static int l_p8_cos(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);
    lua_pushnumber(L, cos(a * 2.0 * M_PI));
    return 1;
}
static int l_p8_atan2(lua_State *L) {
    lua_Number dx = luaL_checknumber(L, 1);
    lua_Number dy = luaL_checknumber(L, 2);
    if (dx == 0 && dy == 0) { lua_pushnumber(L, 0.25); return 1; }
    /* PICO-8 anticlockwise screenspace: atan2(0,-1) -> 0.25 */
    lua_Number a = 1.0 - atan2(dy, dx) / (2.0 * M_PI);
    a = a - floor(a);  /* wrap to [0,1) */
    lua_pushnumber(L, a);
    return 1;
}
static int l_p8_flr(lua_State *L) { lua_pushnumber(L, floor(luaL_checknumber(L, 1))); return 1; }
static int l_p8_ceil(lua_State *L){ lua_pushnumber(L, ceil(luaL_checknumber(L, 1)));  return 1; }
static int l_p8_abs(lua_State *L) { lua_pushnumber(L, fabs(luaL_checknumber(L, 1)));  return 1; }
static int l_p8_min(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);
    lua_Number b = luaL_checknumber(L, 2);
    lua_pushnumber(L, a < b ? a : b);
    return 1;
}
static int l_p8_max(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);
    lua_Number b = luaL_checknumber(L, 2);
    lua_pushnumber(L, a > b ? a : b);
    return 1;
}
static int l_p8_mid(lua_State *L) {
    lua_Number a = luaL_checknumber(L, 1);
    lua_Number b = luaL_checknumber(L, 2);
    lua_Number c = luaL_checknumber(L, 3);
    lua_Number lo = a < b ? a : b;
    lua_Number hi = a > b ? a : b;
    if (c < lo) c = lo;
    if (c > hi) c = hi;
    lua_pushnumber(L, c);
    return 1;
}
static int l_p8_rnd(lua_State *L) {
    /* No 1st arg → 0..1; numeric arg → 0..arg; table → random element */
    if (lua_isnoneornil(L, 1)) {
        lua_pushnumber(L, (lua_Number)rand() / (lua_Number)RAND_MAX);
        return 1;
    }
    if (lua_istable(L, 1)) {
        lua_Integer len = luaL_len(L, 1);
        if (len <= 0) { lua_pushnil(L); return 1; }
        lua_Integer idx = (rand() % len) + 1;
        lua_geti(L, 1, idx);
        return 1;
    }
    lua_Number top = luaL_checknumber(L, 1);
    lua_pushnumber(L, ((lua_Number)rand() / (lua_Number)RAND_MAX) * top);
    return 1;
}
static int l_p8_srand(lua_State *L) {
    srand((unsigned)luaL_checknumber(L, 1));
    return 0;
}

/* --- memory peek/poke ------------------------------------------------- */
static int l_peek(lua_State *L) {
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    if ((unsigned)addr >= P8_MEM_SIZE) { lua_pushinteger(L, 0); return 1; }
    lua_pushinteger(L, m->mem[addr]);
    return 1;
}
static int l_poke(lua_State *L) {
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    int val  = argi(L, 2, 0);
    if ((unsigned)addr < P8_MEM_SIZE) m->mem[addr] = (uint8_t)(val & 0xff);
    return 0;
}

/* --- print stub ------------------------------------------------------- */
/* Real font lands in Phase 3. For now we just route to stdout so
 * carts can debug-print. PICO-8 print() with x/y draws to screen;
 * we ignore those args until the font is ready. */
static int l_print(lua_State *L) {
    const char *s = luaL_optstring(L, 1, "");
    fputs(s, stdout);
    fputc('\n', stdout);
    return 0;
}

/* --- frame counter, string helpers, audio stubs --------------------- */
/* t() / time() return seconds since program start. We piggyback on
 * a counter the host runner increments each frame. */
static int l_p8_time(lua_State *L) {
    p8_machine *m = get_machine(L);
    /* Stash frame count in unused draw-state word 0x5f30..0x5f33 as
     * a uint32; host runner writes it each frame. */
    uint32_t frames = (uint32_t)m->mem[P8_DRAWSTATE + 0x34]
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x35] << 8)
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x36] << 16)
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x37] << 24);
    /* 30 fps assumption for now; the host chooses. */
    lua_pushnumber(L, (lua_Number)frames / 30.0);
    return 1;
}

/* sub(s, i, [j]) — 1-indexed, supports negatives. PICO-8 semantics
 * match Lua's string.sub exactly, so we just route there. */
static int l_p8_sub(lua_State *L) {
    lua_getglobal(L, "string");
    lua_getfield(L, -1, "sub");
    lua_remove(L, -2);
    lua_insert(L, 1);
    lua_call(L, lua_gettop(L) - 1, 1);
    return 1;
}

/* tostr(v, hex) / tonum(s) */
static int l_p8_tostr(lua_State *L) {
    if (lua_isnoneornil(L, 1)) { lua_pushstring(L, ""); return 1; }
    if (lua_isnumber(L, 1)) {
        char buf[32];
        lua_Number n = lua_tonumber(L, 1);
        if (n == (lua_Number)(long long)n) {
            snprintf(buf, sizeof(buf), "%lld", (long long)n);
        } else {
            snprintf(buf, sizeof(buf), "%g", (double)n);
        }
        lua_pushstring(L, buf);
        return 1;
    }
    if (lua_isboolean(L, 1)) {
        lua_pushstring(L, lua_toboolean(L, 1) ? "true" : "false");
        return 1;
    }
    const char *s = lua_tostring(L, 1);
    lua_pushstring(L, s ? s : "");
    return 1;
}
static int l_p8_tonum(lua_State *L) {
    if (lua_isnumber(L, 1)) { lua_pushvalue(L, 1); return 1; }
    const char *s = luaL_checkstring(L, 1);
    char *end;
    double v = strtod(s, &end);
    if (end == s) { lua_pushnil(L); return 1; }
    lua_pushnumber(L, (lua_Number)v);
    return 1;
}

/* Audio stubs for Phase 3 — return nothing, do nothing. Real synth
 * arrives in Phase 4. Important: they must NOT error so carts that
 * call sfx()/music() from _init don't crash. */
static int l_p8_sfx_stub(lua_State *L)   { (void)L; return 0; }
static int l_p8_music_stub(lua_State *L) { (void)L; return 0; }
static int l_p8_stat(lua_State *L) {
    (void)L;
    lua_pushnumber(L, 0);
    return 1;
}

/* printh — PICO-8 debug print, routes to stdout. */
static int l_p8_printh(lua_State *L) {
    const char *s = luaL_optstring(L, 1, "");
    fputs(s, stdout);
    fputc('\n', stdout);
    return 0;
}

/* menuitem, cartdata, dget, dset — stubs. */
static int l_p8_menuitem(lua_State *L) { (void)L; return 0; }
static int l_p8_cartdata(lua_State *L) { (void)L; return 0; }
static int l_p8_dget(lua_State *L)     { lua_pushinteger(L, 0); return 1; }
static int l_p8_dset(lua_State *L)     { (void)L; return 0; }

/* --- table helpers (add/del/foreach/count + all iterator) ----------- */
/* PICO-8 ships these as built-in globals on top of the Lua tables. */

/* all(t) returns an iterator over t[1..#t]. PICO-8 iterator is
 * "safe" against del() during iteration, but we're pragmatic: a
 * simple index-based iterator is enough for Celeste Classic and most
 * carts (they del() on separate lists). */
static int all_iter(lua_State *L) {
    /* upvalues: table, index */
    int idx = (int)lua_tointeger(L, lua_upvalueindex(2)) + 1;
    lua_geti(L, lua_upvalueindex(1), idx);
    if (lua_isnil(L, -1)) return 1;  /* nil terminates */
    /* store updated index */
    lua_pushinteger(L, idx);
    lua_replace(L, lua_upvalueindex(2));
    return 1;
}
static int l_p8_all(lua_State *L) {
    if (lua_isnoneornil(L, 1)) {
        /* empty iterator */
        lua_pushcfunction(L, all_iter);
        lua_newtable(L);
        lua_pushinteger(L, 0);
        lua_pushcclosure(L, all_iter, 2);
        return 1;
    }
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 0);
    lua_pushcclosure(L, all_iter, 2);
    return 1;
}

static int l_add(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    /* PICO-8 add returns the inserted value */
    lua_Integer len = luaL_len(L, 1);
    lua_pushvalue(L, 2);
    lua_seti(L, 1, len + 1);
    lua_pushvalue(L, 2);
    return 1;
}
static int l_del(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_Integer len = luaL_len(L, 1);
    for (lua_Integer i = 1; i <= len; i++) {
        lua_geti(L, 1, i);
        int eq = lua_rawequal(L, -1, 2);
        lua_pop(L, 1);
        if (eq) {
            /* shift down */
            for (lua_Integer j = i; j < len; j++) {
                lua_geti(L, 1, j + 1);
                lua_seti(L, 1, j);
            }
            lua_pushnil(L);
            lua_seti(L, 1, len);
            lua_pushvalue(L, 2);
            return 1;
        }
    }
    lua_pushnil(L);
    return 1;
}
static int l_count(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushinteger(L, luaL_len(L, 1));
    return 1;
}
static int l_foreach(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checktype(L, 2, LUA_TFUNCTION);
    lua_Integer len = luaL_len(L, 1);
    for (lua_Integer i = 1; i <= len; i++) {
        lua_pushvalue(L, 2);
        lua_geti(L, 1, i);
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
            return lua_error(L);
        }
    }
    return 0;
}

/* --- registration ---------------------------------------------------- */

static const luaL_Reg p8_funcs[] = {
    /* draw */
    { "cls",      l_cls },
    { "pset",     l_pset },
    { "pget",     l_pget },
    { "color",    l_color },
    { "camera",   l_camera },
    { "clip",     l_clip },
    { "line",     l_line },
    { "rect",     l_rect },
    { "rectfill", l_rectfill },
    { "circ",     l_circ },
    { "circfill", l_circfill },
    { "pal",      l_pal },
    { "palt",     l_palt },
    /* sprites + map */
    { "spr",      l_spr },
    { "sspr",     l_sspr },
    { "map",      l_map },
    { "mget",     l_mget },
    { "mset",     l_mset },
    { "fget",     l_fget },
    { "fset",     l_fset },
    { "sget",     l_sget },
    { "sset",     l_sset },
    /* input */
    { "btn",      l_btn },
    { "btnp",     l_btnp },
    /* math */
    { "sin",      l_p8_sin },
    { "cos",      l_p8_cos },
    { "atan2",    l_p8_atan2 },
    { "flr",      l_p8_flr },
    { "ceil",     l_p8_ceil },
    { "abs",      l_p8_abs },
    { "min",      l_p8_min },
    { "max",      l_p8_max },
    { "mid",      l_p8_mid },
    { "rnd",      l_p8_rnd },
    { "srand",    l_p8_srand },
    /* memory */
    { "peek",     l_peek },
    { "poke",     l_poke },
    /* misc */
    { "print",    l_print },
    /* table helpers */
    { "add",      l_add },
    { "del",      l_del },
    { "count",    l_count },
    { "foreach",  l_foreach },
    { "all",      l_p8_all },
    /* string / number conversion */
    { "sub",      l_p8_sub },
    { "tostr",    l_p8_tostr },
    { "tonum",    l_p8_tonum },
    /* frame counter */
    { "t",        l_p8_time },
    { "time",     l_p8_time },
    /* audio + persistence stubs (Phase 4/6) */
    { "sfx",      l_p8_sfx_stub },
    { "music",    l_p8_music_stub },
    { "stat",     l_p8_stat },
    { "printh",   l_p8_printh },
    { "menuitem", l_p8_menuitem },
    { "cartdata", l_p8_cartdata },
    { "dget",     l_p8_dget },
    { "dset",     l_p8_dset },
    { NULL, NULL }
};

void p8_api_install(p8_vm *vm, p8_machine *machine, p8_input *input) {
    lua_State *L = vm->L;

    /* Stash machine + input pointers in registry. */
    lua_pushlightuserdata(L, (void *)&k_machine_key);
    lua_pushlightuserdata(L, machine);
    lua_rawset(L, LUA_REGISTRYINDEX);

    lua_pushlightuserdata(L, (void *)&k_input_key);
    lua_pushlightuserdata(L, input);
    lua_rawset(L, LUA_REGISTRYINDEX);

    /* Register every binding as a global. PICO-8 carts call the
     * functions bare (`spr(0, 64, 64)`), not `pico8.spr(...)`. */
    for (const luaL_Reg *r = p8_funcs; r->name; r++) {
        lua_pushcfunction(L, r->func);
        lua_setglobal(L, r->name);
    }
}

int p8_api_call_optional(p8_vm *vm, const char *name) {
    lua_State *L = vm->L;
    lua_getglobal(L, name);
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 1);
        return 0;
    }
    int rc = lua_pcall(L, 0, 0, 0);
    if (rc != LUA_OK) {
        fprintf(stderr, "[ThumbyP8] %s() error: %s\n", name, lua_tostring(L, -1));
        lua_pop(L, 1);
        return rc;
    }
    return 0;
}
