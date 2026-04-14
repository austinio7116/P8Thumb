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
#include "p8_font.h"
#include "p8_audio.h"

/* Optional binding-call trace hook. NULL by default; the device
 * firmware sets this to p8_log_ring at boot so a hardfault dump
 * shows the last binding called. The TRACE macro is used inside
 * suspect bindings (drawing / audio / memory) to write their name
 * to the hook. Hot-path bindings (math, button reads, table ops)
 * are deliberately NOT traced — they fire too often to be useful
 * and would just spam the ring. */

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void (*p8_trace_hook)(const char *name) = NULL;
#define TRACE(name) do { if (p8_trace_hook) p8_trace_hook(name); } while (0)

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

/* PICO-8 is far more permissive than Lua about nil-as-number.
 * Real carts pass nil/missing where the API expects numbers and
 * PICO-8 just treats it as 0. Match that.  argi/argn return the
 * default (or 0) if the arg is nil, missing, or not coercible. */
static int argi(lua_State *L, int idx, int dflt) {
    if (lua_isnoneornil(L, idx)) return dflt;
    int isnum = 0;
    lua_Number n = lua_tonumberx(L, idx, &isnum);
    if (!isnum) return dflt;
    return (int)floor((double)n);
}
static lua_Number argn0(lua_State *L, int idx) {
    if (lua_isnoneornil(L, idx)) return 0;
    int isnum = 0;
    lua_Number n = lua_tonumberx(L, idx, &isnum);
    return isnum ? n : 0;
}
/* (argn helper removed — unused after Phase 2 binding pass.) */

/* --- drawing primitives --------------------------------------------- */

static int l_cls(lua_State *L) {
    TRACE("cls");
    p8_cls(get_machine(L), argi(L, 1, 0));
    return 0;
}
static int l_pset(lua_State *L) {
    TRACE("pset");
    p8_machine *m = get_machine(L);
    int x = argi(L, 1, 0);
    int y = argi(L, 2, 0);
    int c = argi(L, 3, p8_pen(m));
    p8_pset(m, x, y, c);
    return 0;
}
static int l_pget(lua_State *L) {
    TRACE("pget");
    int v = p8_pget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0));
    lua_pushinteger(L, v);
    return 1;
}
static int l_color(lua_State *L) {
    TRACE("color");
    p8_color(get_machine(L), argi(L, 1, 6));
    return 0;
}
static int l_camera(lua_State *L) {
    TRACE("camera");
    p8_camera(get_machine(L), argi(L, 1, 0), argi(L, 2, 0));
    return 0;
}
static int l_clip(lua_State *L) {
    TRACE("clip");
    p8_machine *m = get_machine(L);
    if (lua_gettop(L) == 0) { p8_clip(m, 0, 0, 0, 0, 1); return 0; }
    p8_clip(m, argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, 128), argi(L, 4, 128), 0);
    return 0;
}
static int l_line(lua_State *L) {
    TRACE("line");
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
    TRACE("rect");
    p8_machine *m = get_machine(L);
    p8_rect(m, argi(L, 1, 0), argi(L, 2, 0),
               argi(L, 3, 0), argi(L, 4, 0),
               argi(L, 5, p8_pen(m)));
    return 0;
}
static int l_rectfill(lua_State *L) {
    TRACE("rectfill");
    p8_machine *m = get_machine(L);
    p8_rectfill(m, argi(L, 1, 0), argi(L, 2, 0),
                   argi(L, 3, 0), argi(L, 4, 0),
                   argi(L, 5, p8_pen(m)));
    return 0;
}
/* rrect(x, y, w, h, r, [col]) — rounded rect outline */
static int l_rrect(lua_State *L) {
    TRACE("rrect");
    p8_machine *m = get_machine(L);
    p8_rrect(m, argi(L, 1, 0), argi(L, 2, 0),
                argi(L, 3, 0), argi(L, 4, 0),
                argi(L, 5, 0),
                argi(L, 6, p8_pen(m)));
    return 0;
}
static int l_rrectfill(lua_State *L) {
    TRACE("rrectfill");
    p8_machine *m = get_machine(L);
    p8_rrectfill(m, argi(L, 1, 0), argi(L, 2, 0),
                    argi(L, 3, 0), argi(L, 4, 0),
                    argi(L, 5, 0),
                    argi(L, 6, p8_pen(m)));
    return 0;
}
static int l_circ(lua_State *L) {
    TRACE("circ");
    p8_machine *m = get_machine(L);
    p8_circ(m, argi(L, 1, 0), argi(L, 2, 0),
               argi(L, 3, 4), argi(L, 4, p8_pen(m)));
    return 0;
}
static int l_circfill(lua_State *L) {
    TRACE("circfill");
    p8_machine *m = get_machine(L);
    p8_circfill(m, argi(L, 1, 0), argi(L, 2, 0),
                   argi(L, 3, 4), argi(L, 4, p8_pen(m)));
    return 0;
}

/* pal() with no args: reset all palettes.
 * pal(c0, c1, [p]): remap color c0 → c1 in palette p (0=draw, 1=screen).
 * pal(tbl, [p]):    apply a whole palette map from table tbl.
 *                   Table keys 0..15 (or 1..16) → target colors. */
static int l_pal(lua_State *L) {
    TRACE("pal");
    p8_machine *m = get_machine(L);
    int n = lua_gettop(L);
    /* No args, or nil first arg → reset both palettes. */
    if (n == 0 || lua_isnil(L, 1)) {
        p8_pal_reset(m);
        return 0;
    }
    /* Single-number arg: reset just that palette (0 = draw, 1 = screen).
     * Carts use `pal(0)` after silhouette drawing to reset the draw
     * palette. */
    if (n == 1 && lua_type(L, 1) == LUA_TNUMBER) {
        int p = (int)lua_tointeger(L, 1);
        if (p == 0) {
            for (int i = 0; i < 16; i++) {
                m->mem[P8_DS_DRAW_PAL + i] = (uint8_t)i;
            }
            m->mem[P8_DS_DRAW_PAL + 0] |= 0x10;  /* color 0 transparent */
        } else if (p == 1) {
            for (int i = 0; i < 16; i++) {
                m->mem[P8_DS_SCREEN_PAL + i] = (uint8_t)i;
            }
        }
        return 0;
    }
    /* Table form: first arg is a table, second (optional) is palette index. */
    if (lua_istable(L, 1)) {
        int p = argi(L, 2, 0);
        /* PICO-8 tables may be 0-indexed or 1-indexed for palette maps.
         * Check for [0] first; if present, use 0..15; otherwise 1..16. */
        /* PICO-8 pal(table): table index = color slot.
         * If table[0] exists → 0-indexed (table[0]→screen[0]).
         * If only table[1..] → 1-indexed (table[1]→screen[1]). */
        lua_rawgeti(L, 1, 0);
        int zero_based = !lua_isnil(L, -1);
        lua_pop(L, 1);
        if (zero_based) {
            for (int i = 0; i < 16; i++) {
                lua_rawgeti(L, 1, i);
                if (!lua_isnil(L, -1)) {
                    int c1 = (int)lua_tointeger(L, -1);
                    p8_pal_set(m, i, c1, p);
                }
                lua_pop(L, 1);
            }
        } else {
            /* 1-indexed: table[k] → screen[k], for k=1..15.
             * Screen[0] is left unchanged (keeps default). */
            for (int k = 1; k <= 15; k++) {
                lua_rawgeti(L, 1, k);
                if (!lua_isnil(L, -1)) {
                    int c1 = (int)lua_tointeger(L, -1);
                    p8_pal_set(m, k, c1, p);
                }
                lua_pop(L, 1);
            }
        }
        return 0;
    }
    int c0 = argi(L, 1, 0);
    int c1 = argi(L, 2, 0);
    int p  = argi(L, 3, 0);
    p8_pal_set(m, c0, c1, p);
    return 0;
}
static int l_palt(lua_State *L) {
    TRACE("palt");
    p8_machine *m = get_machine(L);
    if (lua_gettop(L) == 0) {
        /* reset transparency: only color 0 transparent */
        for (int i = 0; i < 16; i++) {
            if (i == 0) m->mem[P8_DS_DRAW_PAL + i] |= 0x10;
            else        m->mem[P8_DS_DRAW_PAL + i] &= ~0x10;
        }
        return 0;
    }
    /* Single-arg form: palt(bitmask) where bit N = color N transparent.
     * Two-arg form: palt(color, transparent_bool). */
    if (lua_gettop(L) == 1 && lua_isnumber(L, 1)) {
        unsigned int mask = (unsigned int)lua_tonumber(L, 1);
        for (int i = 0; i < 16; i++) {
            if (mask & (1u << (15 - i))) {
                m->mem[P8_DS_DRAW_PAL + i] |= 0x10;
            } else {
                m->mem[P8_DS_DRAW_PAL + i] &= ~0x10;
            }
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
    TRACE("spr");
    p8_machine *m = get_machine(L);
    int n  = argi(L, 1, 0);
    int x  = argi(L, 2, 0);
    int y  = argi(L, 3, 0);
    /* w/h can be fractional (e.g. 0.5 = 4 pixels). Convert to pixel
     * dimensions here rather than in p8_spr, to preserve precision. */
    lua_Number wf = lua_isnoneornil(L, 4) ? 1.0 : lua_tonumber(L, 4);
    lua_Number hf = lua_isnoneornil(L, 5) ? 1.0 : lua_tonumber(L, 5);
    int pw = (int)(wf * 8);  /* pixel width */
    int ph = (int)(hf * 8);  /* pixel height */
    int fx = lua_toboolean(L, 6);
    int fy = lua_toboolean(L, 7);
    p8_spr_px(m, n, x, y, pw, ph, fx, fy);
    return 0;
}
static int l_sspr(lua_State *L) {
    TRACE("sspr");
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
    TRACE("map");
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
    TRACE("mget");
    lua_pushinteger(L, p8_mget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0)));
    return 1;
}
static int l_mset(lua_State *L) {
    TRACE("mset");
    p8_mset(get_machine(L), argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, 0));
    return 0;
}
static int l_fget(lua_State *L) {
    TRACE("fget");
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
    TRACE("fset");
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
    TRACE("sget");
    lua_pushinteger(L, p8_sget(get_machine(L), argi(L, 1, 0), argi(L, 2, 0)));
    return 1;
}
static int l_sset(lua_State *L) {
    TRACE("sset");
    p8_machine *m = get_machine(L);
    p8_sset(m, argi(L, 1, 0), argi(L, 2, 0), argi(L, 3, p8_pen(m)));
    return 0;
}

/* --- input ----------------------------------------------------------- */

static int l_btn(lua_State *L) {
    TRACE("btn");
    if (lua_isnoneornil(L, 1)) {
        lua_pushinteger(L, get_input(L)->cur);
        return 1;
    }
    lua_pushboolean(L, p8_btn(get_input(L), argi(L, 1, 0)));
    return 1;
}
static int l_btnp(lua_State *L) {
    TRACE("btnp");
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
    TRACE("sin");
    lua_pushnumber(L, -sin(argn0(L, 1) * 2.0 * M_PI));
    return 1;
}
static int l_p8_cos(lua_State *L) {
    TRACE("cos");
    lua_pushnumber(L, cos(argn0(L, 1) * 2.0 * M_PI));
    return 1;
}
static int l_p8_atan2(lua_State *L) {
    TRACE("atan2");
    lua_Number dx = argn0(L, 1);
    lua_Number dy = argn0(L, 2);
    if (dx == 0 && dy == 0) { lua_pushnumber(L, 0.25); return 1; }
    /* PICO-8 anticlockwise screenspace: atan2(0,-1) -> 0.25 */
    lua_Number a = 1.0 - atan2(dy, dx) / (2.0 * M_PI);
    a = a - floor(a);  /* wrap to [0,1) */
    lua_pushnumber(L, a);
    return 1;
}
static int l_p8_flr(lua_State *L) {
    TRACE("flr");
    lua_pushnumber(L, floor(argn0(L, 1)));
    return 1;
}
static int l_p8_ceil(lua_State *L) { TRACE("ceil"); lua_pushnumber(L, ceil(argn0(L, 1)));  return 1; }
static int l_p8_abs(lua_State *L)  { TRACE("abs");  lua_pushnumber(L, fabs(argn0(L, 1)));  return 1; }
static int l_p8_min(lua_State *L) {
    TRACE("min");
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    lua_pushnumber(L, a < b ? a : b);
    return 1;
}
static int l_p8_max(lua_State *L) {
    TRACE("max");
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    lua_pushnumber(L, a > b ? a : b);
    return 1;
}
static int l_p8_mid(lua_State *L) {
    TRACE("mid");
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    lua_Number c = argn0(L, 3);
    lua_Number lo = a < b ? a : b;
    lua_Number hi = a > b ? a : b;
    if (c < lo) c = lo;
    if (c > hi) c = hi;
    lua_pushnumber(L, c);
    return 1;
}
static int l_p8_rnd(lua_State *L) {
    TRACE("rnd");
    /* No 1st arg → 0..1; numeric arg → 0..arg; table → random element */
    if (lua_isnoneornil(L, 1)) {
        lua_pushnumber(L, (lua_Number)rand() / (lua_Number)RAND_MAX);
        return 1;
    }
    if (lua_istable(L, 1)) {
        int len = (int)luaL_len(L, 1);
        if (len <= 0) { lua_pushnil(L); return 1; }
        int idx = (rand() % len) + 1;
        lua_rawgeti(L, 1, idx);
        return 1;
    }
    lua_Number top = luaL_checknumber(L, 1);
    lua_pushnumber(L, ((lua_Number)rand() / (lua_Number)RAND_MAX) * top);
    return 1;
}
static int l_p8_srand(lua_State *L) {
    TRACE("srand");
    /* PICO-8 srand() with no arg reseeds from the system frame
     * counter (effectively "time-based"). With an arg it sets a
     * deterministic seed. */
    if (lua_isnoneornil(L, 1)) {
        p8_machine *m = get_machine(L);
        uint32_t fc = (uint32_t)m->mem[P8_DRAWSTATE + 0x34]
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x35] << 8)
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x36] << 16)
                    | ((uint32_t)m->mem[P8_DRAWSTATE + 0x37] << 24);
        srand(fc ? fc : 1);
    } else {
        srand((unsigned)argn0(L, 1));
    }
    return 0;
}

/* sgn(x) → -1 if x<0, +1 otherwise (PICO-8: sgn(0) = 1). */
static int l_p8_sgn(lua_State *L) {
    TRACE("sgn");
    lua_Number x = argn0(L, 1);
    lua_pushnumber(L, x < 0 ? -1 : 1);
    return 1;
}

static int l_p8_sqrt(lua_State *L) {
    TRACE("sqrt");
    lua_Number x = argn0(L, 1);
    lua_pushnumber(L, x < 0 ? 0 : sqrt(x));
    return 1;
}
/* PICO-8 integer division: floor(a/b). Used by translator for the
 * \ operator, since Lua 5.2 has no // operator. */
static int l_p8_idiv(lua_State *L) {
    TRACE("p8idiv");
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    if (b == 0) { lua_pushnumber(L, 0); return 1; } /* PICO-8: div by 0 = 0 */
    lua_pushnumber(L, floor(a / b));
    return 1;
}

/* PICO-8 pre-0.2 bitwise functions (now usually expressed as << >>
 * & | ~ in newer carts, but old carts still call these by name). */
/* PICO-8 uses 16.16 fixed-point for all bitwise shift operations.
 * 0.5 in fixed-point is 0x00008000. Shifting works on the 32-bit
 * fixed-point representation, then the result is converted back.
 * This handles fractional values: 0.5 << 1 = 1.0, 0.5 >> 1 = 0.25. */
static int32_t to_fix16(lua_Number v) { return (int32_t)(v * 65536.0f); }
static void push_fix16(lua_State *L, int32_t v) {
    lua_pushnumber(L, (lua_Number)v / 65536.0f);
}

static int l_p8_shl(lua_State *L) {
    TRACE("shl");
    int32_t x = to_fix16(argn0(L, 1));
    int n = (int)argn0(L, 2);
    push_fix16(L, (int32_t)(((uint32_t)x) << (n & 31)));
    return 1;
}
static int l_p8_shr(lua_State *L) {
    TRACE("shr");
    int32_t x = to_fix16(argn0(L, 1));
    int n = (int)argn0(L, 2);
    /* Arithmetic right shift to match PICO-8's signed semantics. */
    push_fix16(L, x >> (n & 31));
    return 1;
}
static int l_p8_lshr(lua_State *L) {
    TRACE("lshr");
    uint32_t x = (uint32_t)to_fix16(argn0(L, 1));
    int n = (int)argn0(L, 2);
    push_fix16(L, (int32_t)(x >> (n & 31)));
    return 1;
}
static int l_p8_band(lua_State *L) {
    TRACE("band");
    int32_t a = to_fix16(argn0(L, 1));
    int32_t b = to_fix16(argn0(L, 2));
    push_fix16(L, a & b);
    return 1;
}
static int l_p8_bor(lua_State *L) {
    TRACE("bor");
    int32_t a = to_fix16(argn0(L, 1));
    int32_t b = to_fix16(argn0(L, 2));
    push_fix16(L, a | b);
    return 1;
}
static int l_p8_bxor(lua_State *L) {
    TRACE("bxor");
    int32_t a = to_fix16(argn0(L, 1));
    int32_t b = to_fix16(argn0(L, 2));
    push_fix16(L, a ^ b);
    return 1;
}
static int l_p8_bnot(lua_State *L) {
    TRACE("bnot");
    int32_t a = to_fix16(argn0(L, 1));
    push_fix16(L, ~a);
    return 1;
}

/* split(str, [sep], [convert_numbers]) → table of substrings.
 *
 * PICO-8: split("1,2,3", ",") → {1, 2, 3}.  Default sep is ",".
 * Default convert_numbers is true; numeric-looking pieces get
 * pushed as numbers, everything else as strings. Empty input
 * returns an empty table. A single-character separator is the
 * common case; multi-char and whitespace separators rarely matter
 * for cart code. We support either. */
static int l_p8_split(lua_State *L) {
    TRACE("split");
    if (lua_isnoneornil(L, 1)) { lua_newtable(L); return 1; }
    size_t slen;
    const char *s = lua_tolstring(L, 1, &slen);
    if (!s) { lua_newtable(L); return 1; }

    const char *sep = ",";
    size_t seplen = 1;
    if (!lua_isnoneornil(L, 2)) {
        sep = lua_tolstring(L, 2, &seplen);
        if (!sep) { sep = ","; seplen = 1; }
    }

    int convert = 1;
    if (lua_isboolean(L, 3)) convert = lua_toboolean(L, 3);

    lua_newtable(L);
    int idx = 1;
    size_t i = 0;
    while (i <= slen) {
        size_t j = i;
        if (seplen == 0) {
            /* Empty separator: split into individual characters. */
            if (i >= slen) break;
            j = i + 1;
        } else {
            while (j + seplen <= slen && memcmp(s + j, sep, seplen) != 0) j++;
        }
        /* Push the slice [i..j) as a value into the table. */
        if (convert) {
            char *end;
            double v = strtod(s + i, &end);
            if (end == s + j && j > i) {
                lua_pushnumber(L, v);
            } else {
                lua_pushlstring(L, s + i, j - i);
            }
        } else {
            lua_pushlstring(L, s + i, j - i);
        }
        lua_rawseti(L, -2, idx++);
        if (seplen == 0) {
            i = j;
        } else {
            if (j + seplen > slen) break;
            i = j + seplen;
        }
    }
    return 1;
}

/* ord(s, [i]) → byte value of s[i] (1-indexed). chr(n) → 1-byte string. */
/* ord(str, [index], [num_results]) — return ordinal(s) of character(s).
 * PICO-8 supports multi-return: ord("hello", 1, 3) → 104, 101, 108 */
static int l_p8_ord(lua_State *L) {
    TRACE("ord");
    size_t slen = 0;
    const char *s = luaL_checklstring(L, 1, &slen);
    int i = lua_isnoneornil(L, 2) ? 1 : (int)luaL_checknumber(L, 2);
    int n = lua_isnoneornil(L, 3) ? 1 : (int)luaL_checknumber(L, 3);
    if (n < 1) n = 1;
    int count = 0;
    for (int k = 0; k < n; k++) {
        int pos = i + k;
        if (pos < 1 || (size_t)pos > slen) {
            lua_pushnil(L);
        } else {
            lua_pushinteger(L, (unsigned char)s[pos - 1]);
        }
        count++;
    }
    return count;
}
/* chr(val0, [val1], ...) — convert ordinal(s) to string.
 * PICO-8 supports multi-arg: chr(104, 101, 108) → "hel" */
static int l_p8_chr(lua_State *L) {
    TRACE("chr");
    int nargs = lua_gettop(L);
    if (nargs <= 0) { lua_pushliteral(L, ""); return 1; }
    luaL_Buffer b;
    luaL_buffinit(L, &b);
    for (int i = 1; i <= nargs; i++) {
        int c = (int)luaL_checknumber(L, i) & 0xff;
        luaL_addchar(&b, (char)c);
    }
    luaL_pushresult(&b);
    return 1;
}

/* --- memory peek/poke ------------------------------------------------- */
/* peek(addr, [n]) — read n bytes (default 1), return n values */
static int l_peek(lua_State *L) {
    TRACE("peek");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    int n = lua_isnoneornil(L, 2) ? 1 : (int)lua_tonumber(L, 2);
    if (n < 1) n = 1;
    for (int i = 0; i < n; i++) {
        int a = addr + i;
        if ((unsigned)a < P8_MEM_SIZE)
            lua_pushinteger(L, m->mem[a]);
        else
            lua_pushinteger(L, 0);
    }
    return n;
}
/* poke(addr, val1, [val2], ...) — write multiple bytes */
static int l_poke(lua_State *L) {
    TRACE("poke");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    int nargs = lua_gettop(L);
    for (int i = 2; i <= nargs; i++) {
        int a = addr + (i - 2);
        int val = (int)lua_tonumber(L, i);
        if ((unsigned)a < P8_MEM_SIZE) m->mem[a] = (uint8_t)(val & 0xff);
    }
    return 0;
}

/* peek2/poke2 — 16-bit little-endian access. */
static int l_peek2(lua_State *L) {
    TRACE("peek2");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    if (addr < 0 || addr + 1 >= P8_MEM_SIZE) {
        lua_pushinteger(L, 0); return 1;
    }
    int v = m->mem[addr] | (m->mem[addr + 1] << 8);
    /* sign-extend 16-bit (PICO-8 numbers are signed) */
    if (v & 0x8000) v |= ~0xffff;
    lua_pushinteger(L, v);
    return 1;
}
static int l_poke2(lua_State *L) {
    TRACE("poke2");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    int val  = argi(L, 2, 0);
    if (addr < 0 || addr + 1 >= P8_MEM_SIZE) return 0;
    m->mem[addr]     = (uint8_t)(val & 0xff);
    m->mem[addr + 1] = (uint8_t)((val >> 8) & 0xff);
    return 0;
}

/* peek4/poke4 — 32-bit PICO-8 16.16 fixed-point access. The 32-bit
 * value is stored as signed fixed-point: top 16 bits = integer part,
 * bottom 16 bits = fractional. Convert to/from float (lua_Number). */
static int l_peek4(lua_State *L) {
    TRACE("peek4");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    if (addr < 0 || addr + 3 >= P8_MEM_SIZE) {
        lua_pushnumber(L, 0); return 1;
    }
    uint32_t v = (uint32_t)m->mem[addr]
               | ((uint32_t)m->mem[addr + 1] << 8)
               | ((uint32_t)m->mem[addr + 2] << 16)
               | ((uint32_t)m->mem[addr + 3] << 24);
    /* Interpret as signed 16.16 fixed-point */
    int32_t signed_v = (int32_t)v;
    lua_pushnumber(L, (lua_Number)signed_v / 65536.0);
    return 1;
}
static int l_poke4(lua_State *L) {
    TRACE("poke4");
    p8_machine *m = get_machine(L);
    int addr = argi(L, 1, 0);
    double val = lua_isnoneornil(L, 2) ? 0.0 : (double)lua_tonumber(L, 2);
    if (addr < 0 || addr + 3 >= P8_MEM_SIZE) return 0;
    /* Convert float to 16.16 fixed-point */
    int32_t fixed = (int32_t)(val * 65536.0);
    uint32_t u = (uint32_t)fixed;
    m->mem[addr]     = (uint8_t)(u & 0xff);
    m->mem[addr + 1] = (uint8_t)((u >> 8) & 0xff);
    m->mem[addr + 2] = (uint8_t)((u >> 16) & 0xff);
    m->mem[addr + 3] = (uint8_t)((u >> 24) & 0xff);
    return 0;
}

/* fillp(pat) — set the 16-bit fill pattern and transparency flag.
 * The pattern is a float where:
 *   - integer part = 16-bit bitfield (bit 15 = top-left pixel (0,0))
 *   - fractional .5 bit = transparency flag (second color is transparent)
 * PICO-8 uses 16.16 fixed-point internally; we approximate with float:
 * the transparency bit is set when (pat*2) is odd, i.e. when there's
 * a 0.5 component. Passing no args resets the pattern to 0. */
static int l_p8_fillp(lua_State *L) {
    TRACE("fillp");
    p8_machine *m = get_machine(L);
    if (lua_isnoneornil(L, 1)) {
        p8_fillp(m, 0, 0);
        return 0;
    }
    double pat = (double)lua_tonumber(L, 1);
    int pattern = (int)floor(pat);
    int transparent = 0;
    /* Transparency flag: bit 15 of the 16-bit fractional part.
     * In float terms, that's a 0.5 component in the fractional part. */
    double frac = pat - floor(pat);
    if (frac >= 0.5 - 1e-6) transparent = 1;
    p8_fillp(m, pattern & 0xffff, transparent);
    return 0;
}

/* flip() — explicit framebuffer flip. We always present once per
 * frame, so this is a no-op stub. */
static int l_p8_flip(lua_State *L)  { TRACE("flip");  (void)L; return 0; }

/* deli(t, [i]) — delete by index. Default i = #t (delete last). */
static int l_p8_deli(lua_State *L) {
    TRACE("deli");
    if (!lua_istable(L, 1)) { lua_pushnil(L); return 1; }
    lua_Integer len = luaL_len(L, 1);
    lua_Integer i = lua_isnoneornil(L, 2) ? len : (lua_Integer)argi(L, 2, (int)len);
    if (i < 1 || i > len) { lua_pushnil(L); return 1; }
    lua_rawgeti(L, 1, i);   /* return value */
    /* shift down */
    for (lua_Integer j = i; j < len; j++) {
        lua_rawgeti(L, 1, j + 1);
        lua_rawseti(L, 1, j);
    }
    lua_pushnil(L);
    lua_rawseti(L, 1, len);
    return 1;
}

/* oval / ovalfill — axis-aligned ellipse outline / fill drawn into
 * the framebuffer. Used by a fair few carts; midpoint algorithm. */
static int l_p8_oval(lua_State *L) {
    TRACE("oval");
    p8_machine *m = get_machine(L);
    int x0 = argi(L, 1, 0), y0 = argi(L, 2, 0);
    int x1 = argi(L, 3, 0), y1 = argi(L, 4, 0);
    int c  = argi(L, 5, p8_pen(m));
    if (x1 < x0) { int t = x0; x0 = x1; x1 = t; }
    if (y1 < y0) { int t = y0; y0 = y1; y1 = t; }
    int rx = (x1 - x0) / 2, ry = (y1 - y0) / 2;
    int cx = x0 + rx,        cy = y0 + ry;
    if (rx < 0 || ry < 0) return 0;
    /* Crude midpoint ellipse — good enough for most carts. */
    for (int t = 0; t < 360; t += 2) {
        double a = t * (3.14159265 / 180.0);
        int px = cx + (int)(rx * cos(a) + 0.5);
        int py = cy + (int)(ry * sin(a) + 0.5);
        p8_pset(m, px, py, c);
    }
    return 0;
}
static int l_p8_ovalfill(lua_State *L) {
    TRACE("ovalfill");
    p8_machine *m = get_machine(L);
    int x0 = argi(L, 1, 0), y0 = argi(L, 2, 0);
    int x1 = argi(L, 3, 0), y1 = argi(L, 4, 0);
    int c  = argi(L, 5, p8_pen(m));
    if (x1 < x0) { int t = x0; x0 = x1; x1 = t; }
    if (y1 < y0) { int t = y0; y0 = y1; y1 = t; }
    int rx = (x1 - x0) / 2, ry = (y1 - y0) / 2;
    int cx = x0 + rx,        cy = y0 + ry;
    if (rx < 0 || ry < 0) return 0;
    /* Scanline fill via midpoint formula. */
    for (int dy = -ry; dy <= ry; dy++) {
        if (ry == 0) continue;
        double r2 = 1.0 - (double)(dy * dy) / (double)(ry * ry);
        if (r2 < 0) continue;
        int dx = (int)(rx * sqrt(r2) + 0.5);
        for (int x = cx - dx; x <= cx + dx; x++) {
            p8_pset(m, x, cy + dy, c);
        }
    }
    return 0;
}

/* tline(x0,y0,x1,y1, mx,my, [mdx=1/8], [mdy=0], [layer=0]) —
 * textured line drawing for mode-7 floor effects. */
static int l_p8_tline(lua_State *L) {
    TRACE("tline");
    p8_machine *m = get_machine(L);
    int x0 = argi(L, 1, 0);
    int y0 = argi(L, 2, 0);
    int x1 = argi(L, 3, 0);
    int y1 = argi(L, 4, 0);
    double mx  = (double)argn0(L, 5);
    double my  = (double)argn0(L, 6);
    double mdx = lua_isnoneornil(L, 7) ? 0.125 : (double)lua_tonumber(L, 7);
    double mdy = lua_isnoneornil(L, 8) ? 0.0   : (double)lua_tonumber(L, 8);
    int layer  = argi(L, 9, 0);
    p8_tline(m, x0, y0, x1, y1, mx, my, mdx, mdy, layer);
    return 0;
}

/* mapdraw — alias for map (older PICO-8 API name). */
/* Already covered by the map binding; alias entry below. */

/* PICO-8 host-control stubs. None of these apply to a single-cart
 * embedded device; they exist so carts that call them don't crash. */
static int l_p8_extcmd(lua_State *L)   { TRACE("extcmd");   (void)L; return 0; }
static int l_p8_cstore(lua_State *L)   { TRACE("cstore");   (void)L; return 0; }
static int l_p8_serial(lua_State *L)   { TRACE("serial");   (void)L; return 0; }
static int l_p8_stop  (lua_State *L)   { TRACE("stop");     (void)L; return 0; }
static int l_p8_run   (lua_State *L)   { TRACE("run");      (void)L; return 0; }
static int l_p8_reset (lua_State *L)   { TRACE("reset");    (void)L; return 0; }
static int l_p8_ls    (lua_State *L)   { TRACE("ls");       (void)L; lua_newtable(L); return 1; }
static int l_p8_holdframe(lua_State *L){ TRACE("holdframe");(void)L; return 0; }
static int l_p8_set_fps(lua_State *L)  { TRACE("set_fps");  (void)L; return 0; }

/* Bitwise rotation helpers (PICO-8 pre-0.2 API). */
static int l_p8_rotl(lua_State *L) {
    TRACE("rotl");
    uint32_t x = (uint32_t)to_fix16(argn0(L, 1));
    int n = (int)argn0(L, 2) & 31;
    push_fix16(L, (int32_t)((x << n) | (x >> (32 - n))));
    return 1;
}
static int l_p8_rotr(lua_State *L) {
    TRACE("rotr");
    uint32_t x = (uint32_t)to_fix16(argn0(L, 1));
    int n = (int)argn0(L, 2) & 31;
    push_fix16(L, (int32_t)((x >> n) | (x << (32 - n))));
    return 1;
}

/* pack(...) — table.pack alias as a global. */
static int l_p8_pack(lua_State *L) {
    TRACE("pack");
    int n = lua_gettop(L);
    lua_createtable(L, n, 1);
    for (int i = 1; i <= n; i++) {
        lua_pushvalue(L, i);
        lua_rawseti(L, -2, i);
    }
    lua_pushinteger(L, n);
    lua_setfield(L, -2, "n");
    return 1;
}

/* unpack(t, [i], [j]) — PICO-8 exposes table.unpack as a global. */
static int l_p8_unpack(lua_State *L) {
    TRACE("unpack");
    if (!lua_istable(L, 1)) return 0;
    int i = lua_isnoneornil(L, 2) ? 1 : argi(L, 2, 1);
    int j = lua_isnoneornil(L, 3) ? (int)luaL_len(L, 1) : argi(L, 3, 0);
    int n = j - i + 1;
    if (n <= 0) return 0;
    luaL_checkstack(L, n, "too many results to unpack");
    for (int k = 0; k < n; k++) {
        lua_rawgeti(L, 1, i + k);
    }
    return n;
}

/* --- print(str, [x, y, [col]]) -------------------------------------- */
/* Draws `str` into the framebuffer using the built-in font.
 *
 * PICO-8 semantics:
 *  - With no x/y, advances a cursor stored in draw-state and wraps
 *    at the bottom of the screen.
 *  - With x/y, draws at the given position and does NOT update the
 *    cursor.
 *  - Color arg is optional; defaults to current pen color.
 *
 * The cursor lives at draw-state offsets 0x26 (x) and 0x27 (y),
 * which we already reserved in p8_machine.h. */
static int l_print(lua_State *L) {
    TRACE("print");
    p8_machine *m = get_machine(L);
    const char *s = luaL_optstring(L, 1, "");
    int has_xy = !lua_isnoneornil(L, 2) && !lua_isnoneornil(L, 3);
    int x, y;
    if (has_xy) {
        x = argi(L, 2, 0);
        y = argi(L, 3, 0);
    } else {
        x = m->mem[P8_DS_CURSOR_X];
        y = m->mem[P8_DS_CURSOR_Y];
    }
    int c;
    if (!lua_isnoneornil(L, 4)) {
        c = argi(L, 4, p8_pen(m));
        p8_set_pen(m, (uint8_t)(c & 0x0f));
    } else if (has_xy && !lua_isnoneornil(L, 4)) {
        c = argi(L, 4, p8_pen(m));
    } else {
        c = p8_pen(m);
    }
    int end_x = p8_font_draw(m, s, x, y, c);
    if (!has_xy) {
        int next_y = y + P8_FONT_CELL_H;
        if (next_y >= P8_SCREEN_H) next_y = P8_SCREEN_H - P8_FONT_CELL_H;
        m->mem[P8_DS_CURSOR_Y] = (uint8_t)next_y;
    }
    /* PICO-8 print() returns the pixel width of the rendered text.
     * Carts use this for centering: `local w = print(t, 0, -1000)`.
     * Drawing at y=-1000 is off-screen so nothing is visible, and
     * the cart just reads the return value. */
    lua_pushinteger(L, end_x - x);
    return 1;
}

/* cursor(x, y, [col]) — set the print cursor and optionally pen. */
static int l_cursor(lua_State *L) {
    TRACE("cursor");
    p8_machine *m = get_machine(L);
    int x = argi(L, 1, 0);
    int y = argi(L, 2, 0);
    m->mem[P8_DS_CURSOR_X] = (uint8_t)(x & 0xff);
    m->mem[P8_DS_CURSOR_Y] = (uint8_t)(y & 0xff);
    if (!lua_isnoneornil(L, 3)) p8_set_pen(m, (uint8_t)(argi(L, 3, 6) & 0x0f));
    return 0;
}

/* --- frame counter, string helpers, audio stubs --------------------- */
/* t() / time() return seconds since program start. The host/device
 * writes elapsed ms into P8_DS_ELAPSED_MS each frame from a real
 * hardware timer, so this is accurate regardless of target fps. */
static int l_p8_time(lua_State *L) {
    TRACE("time");
    p8_machine *m = get_machine(L);
    uint32_t ms = (uint32_t)m->mem[P8_DS_ELAPSED_MS]
                | ((uint32_t)m->mem[P8_DS_ELAPSED_MS + 1] << 8)
                | ((uint32_t)m->mem[P8_DS_ELAPSED_MS + 2] << 16)
                | ((uint32_t)m->mem[P8_DS_ELAPSED_MS + 3] << 24);
    lua_pushnumber(L, (lua_Number)ms / 1000.0);
    return 1;
}

/* sub(s, i, [j]) — 1-indexed, supports negatives. PICO-8 semantics
 * match Lua's string.sub exactly, so we just route there. */
static int l_p8_sub(lua_State *L) {
    TRACE("sub");
    lua_getglobal(L, "string");
    lua_getfield(L, -1, "sub");
    lua_remove(L, -2);
    lua_insert(L, 1);
    lua_call(L, lua_gettop(L) - 1, 1);
    return 1;
}

/* tostr(v, hex) / tonum(s) */
static int l_p8_tostr(lua_State *L) {
    TRACE("tostr");
    if (lua_isnoneornil(L, 1)) { lua_pushstring(L, ""); return 1; }
    if (lua_isnumber(L, 1)) {
        /* PICO-8 tostr: integers display without decimals.
         * Matches lua_number2str in luaconf.h. */
        char buf[32];
        lua_Number n = lua_tonumber(L, 1);
        lua_number2str(buf, n);
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
    TRACE("tonum");
    /* PICO-8 tonum is lenient: nil → nil, bool → nil, numbers
     * pass through, strings get parsed (returning nil if not
     * parseable). NEVER errors. Real carts call this on
     * arbitrary inputs and expect a graceful nil back.
     *
     * NOTE: use lua_type(L,1)==LUA_TNUMBER, NOT lua_isnumber.
     * lua_isnumber returns true for strings that look like
     * numbers (Lua's auto-coercion), and lua_pushvalue would
     * then push the original string unchanged. */
    if (lua_isnoneornil(L, 1)) { lua_pushnil(L); return 1; }
    if (lua_type(L, 1) == LUA_TNUMBER) { lua_pushvalue(L, 1); return 1; }
    if (lua_isboolean(L, 1))    { lua_pushnil(L); return 1; }
    const char *s = lua_tostring(L, 1);
    if (!s) { lua_pushnil(L); return 1; }
    char *end;
    double v = strtod(s, &end);
    if (end == s) { lua_pushnil(L); return 1; }
    lua_pushnumber(L, (lua_Number)v);
    return 1;
}

/* Phase 4 — real audio synth bindings.
 *
 * sfx(n, [channel], [offset], [length])
 *   n=-1 stops the channel; n=-2 stops sfx playing on the channel
 *   without disturbing the music slot. We treat both as stop. */
static int l_p8_sfx(lua_State *L) {
    TRACE("sfx");
    int n      = argi(L, 1, -1);
    int chan   = lua_isnoneornil(L, 2) ? -1 : argi(L, 2, -1);
    int offset = argi(L, 3, 0);
    int length = argi(L, 4, 0);
    p8_audio_sfx(n, chan, offset, length);
    return 0;
}

/* music(n, [fade_len], [channel_mask])
 *   n=-1 stops music. */
static int l_p8_music(lua_State *L) {
    TRACE("music");
    int n          = argi(L, 1, -1);
    int fade_len   = argi(L, 2, 0);
    int chan_mask  = argi(L, 3, 0);
    p8_audio_music(n, fade_len, chan_mask);
    return 0;
}

/* stat(n) — partial PICO-8 surface. The synth-related queries
 * (16..23) come from p8_audio_stat(); other ids return 0. */
static int l_p8_stat(lua_State *L) {
    TRACE("stat");
    int n = argi(L, 1, 0);
    if (n >= 16 && n <= 23) {
        /* Audio channel state */
        lua_pushinteger(L, p8_audio_stat(n));
    } else if (n == 4 || n == 6 || n == 13) {
        /* String-valued stats: clipboard, param string, cart filename.
         * Return empty string (not 0) so #stat(6) works. */
        lua_pushstring(L, "");
    } else {
        lua_pushinteger(L, 0);
    }
    return 1;
}

/* printh — PICO-8 debug print, routes to stdout. */
static int l_p8_printh(lua_State *L) {
    TRACE("printh");
    const char *s = luaL_optstring(L, 1, "");
    fputs(s, stdout);
    fputc('\n', stdout);
    return 0;
}

/* menuitem — not yet implemented (would add entries to pause menu).
 * No-op stub for now; carts that call it continue without errors. */
/* PICO-8 menuitem(index, [label], [callback])
 * Up to 5 custom items (index 1-5). Stored as Lua registry refs. */
#define P8_MAX_MENUITEMS 5
static struct {
    int   ref_cb;       /* LUA_NOREF if empty */
    char  label[32];
} g_menuitems[P8_MAX_MENUITEMS];
static int g_menuitems_inited = 0;

static void menuitems_init(void) {
    if (g_menuitems_inited) return;
    for (int i = 0; i < P8_MAX_MENUITEMS; i++)
        g_menuitems[i].ref_cb = LUA_NOREF;
    g_menuitems_inited = 1;
}

static int l_p8_menuitem(lua_State *L) {
    TRACE("menuitem");
    menuitems_init();
    if (lua_isnoneornil(L, 1)) {
        /* menuitem() — clear all */
        for (int i = 0; i < P8_MAX_MENUITEMS; i++) {
            if (g_menuitems[i].ref_cb != LUA_NOREF)
                luaL_unref(L, LUA_REGISTRYINDEX, g_menuitems[i].ref_cb);
            g_menuitems[i].ref_cb = LUA_NOREF;
            g_menuitems[i].label[0] = 0;
        }
        return 0;
    }
    int idx = (int)lua_tonumber(L, 1) - 1;  /* 1-based → 0-based */
    if (idx < 0 || idx >= P8_MAX_MENUITEMS) return 0;
    if (lua_isnoneornil(L, 2)) {
        /* menuitem(index) — clear this slot */
        if (g_menuitems[idx].ref_cb != LUA_NOREF)
            luaL_unref(L, LUA_REGISTRYINDEX, g_menuitems[idx].ref_cb);
        g_menuitems[idx].ref_cb = LUA_NOREF;
        g_menuitems[idx].label[0] = 0;
        return 0;
    }
    /* menuitem(index, label, callback) — set */
    const char *label = lua_tostring(L, 2);
    if (label) {
        strncpy(g_menuitems[idx].label, label, sizeof(g_menuitems[idx].label) - 1);
        g_menuitems[idx].label[sizeof(g_menuitems[idx].label) - 1] = 0;
    }
    if (g_menuitems[idx].ref_cb != LUA_NOREF)
        luaL_unref(L, LUA_REGISTRYINDEX, g_menuitems[idx].ref_cb);
    if (lua_isfunction(L, 3)) {
        lua_pushvalue(L, 3);
        g_menuitems[idx].ref_cb = luaL_ref(L, LUA_REGISTRYINDEX);
    } else {
        g_menuitems[idx].ref_cb = LUA_NOREF;
    }
    return 0;
}

/* cartdata(name) — open persistent storage slot identified by name.
 * The 256-byte region at 0x5e00-0x5eff is loaded with any previously
 * saved data. Host overrides p8_cartdata_open to implement loading. */
__attribute__((weak)) void p8_cartdata_open(p8_machine *m, const char *name) {
    /* Default: zero the cartdata region. Device build overrides. */
    (void)name;
    memset(&m->mem[0x5e00], 0, 256);
}
__attribute__((weak)) void p8_cartdata_save(p8_machine *m) {
    /* Default: no-op. Device build overrides to flush to flash. */
    (void)m;
}

static int l_p8_cartdata(lua_State *L) {
    TRACE("cartdata");
    p8_machine *m = get_machine(L);
    const char *name = lua_tostring(L, 1);
    if (!name || !*name) { lua_pushboolean(L, 0); return 1; }
    p8_cartdata_open(m, name);
    lua_pushboolean(L, 1);
    return 1;
}

/* dget(idx) — read slot 0-63 as 16.16 fixed-point (float in Lua 5.2). */
static int l_p8_dget(lua_State *L) {
    TRACE("dget");
    p8_machine *m = get_machine(L);
    int idx = argi(L, 1, 0);
    if (idx < 0 || idx >= 64) { lua_pushnumber(L, 0); return 1; }
    int addr = 0x5e00 + idx * 4;
    uint32_t v = (uint32_t)m->mem[addr]
               | ((uint32_t)m->mem[addr + 1] << 8)
               | ((uint32_t)m->mem[addr + 2] << 16)
               | ((uint32_t)m->mem[addr + 3] << 24);
    int32_t sv = (int32_t)v;
    lua_pushnumber(L, (lua_Number)sv / 65536.0);
    return 1;
}

/* dset(idx, val) — write slot 0-63, triggers save. */
static int l_p8_dset(lua_State *L) {
    TRACE("dset");
    p8_machine *m = get_machine(L);
    int idx = argi(L, 1, 0);
    if (idx < 0 || idx >= 64) return 0;
    double val = lua_isnoneornil(L, 2) ? 0.0 : (double)lua_tonumber(L, 2);
    int32_t fixed = (int32_t)(val * 65536.0);
    uint32_t u = (uint32_t)fixed;
    int addr = 0x5e00 + idx * 4;
    m->mem[addr]     = (uint8_t)(u & 0xff);
    m->mem[addr + 1] = (uint8_t)((u >> 8) & 0xff);
    m->mem[addr + 2] = (uint8_t)((u >> 16) & 0xff);
    m->mem[addr + 3] = (uint8_t)((u >> 24) & 0xff);
    p8_cartdata_save(m);
    return 0;
}

/* reload(dest_addr, src_addr, len, [filename]) — copy bytes from
 * the cart's read-only ROM image into runtime memory. Real PICO-8
 * keeps the cart and a separate working copy; we don't (cart and
 * runtime memory are the same buffer at machine.mem) so the typical
 * use case (`reload(0, 0, 0x4300)` to "reset graphics back to the
 * cart's original sprites") is conceptually a no-op for us — the
 * sprites/map/sfx never get modified at runtime unless the cart
 * does so explicitly. A no-op stub is correct for the vast
 * majority of carts. */
/* reload(dst, src, len, [filename]) — copy bytes from the cart's
 * read-only ROM image into runtime memory. The filename argument
 * (cross-cart reload) is ignored; we only have one cart at a time. */
static int l_p8_reload(lua_State *L) {
    TRACE("reload");
    p8_machine *m = get_machine(L);
    if (!m->rom) return 0;  /* no ROM loaded */
    size_t rom_max = m->rom_len ? m->rom_len : P8_ROM_SIZE;
    /* reload() with no args = reload full ROM region */
    if (lua_isnoneornil(L, 1) && lua_isnoneornil(L, 2) && lua_isnoneornil(L, 3)) {
        memcpy(m->mem, m->rom, rom_max);
        return 0;
    }
    int dst = argi(L, 1, 0);
    int src = argi(L, 2, 0);
    int len = argi(L, 3, 0);
    if (len <= 0) return 0;
    if (dst < 0 || src < 0) return 0;
    if ((size_t)src + (size_t)len > rom_max) {
        len = (int)rom_max - src;
    }
    if (len <= 0) return 0;
    if ((size_t)dst + (size_t)len > P8_MEM_SIZE) {
        len = P8_MEM_SIZE - dst;
    }
    if (len <= 0) return 0;
    memcpy(&m->mem[dst], &m->rom[src], (size_t)len);
    return 0;
}

/* memcpy(dest, src, len) — copy bytes within machine memory. PICO-8
 * carts use this for cheap blitting and animation tricks. */
static int l_p8_memcpy(lua_State *L) {
    TRACE("memcpy");
    p8_machine *m = get_machine(L);
    int dest = argi(L, 1, 0);
    int src  = argi(L, 2, 0);
    int len  = argi(L, 3, 0);
    if (len <= 0) return 0;
    if (dest < 0 || src < 0) return 0;
    if (dest + len > P8_MEM_SIZE) len = P8_MEM_SIZE - dest;
    if (src  + len > P8_MEM_SIZE) len = P8_MEM_SIZE - src;
    if (len <= 0) return 0;
    memmove(&m->mem[dest], &m->mem[src], (size_t)len);
    return 0;
}

/* memset(dest, val, len) — fill bytes in machine memory. */
static int l_p8_memset(lua_State *L) {
    TRACE("memset");
    p8_machine *m = get_machine(L);
    int dest = argi(L, 1, 0);
    int val  = argi(L, 2, 0);
    int len  = argi(L, 3, 0);
    if (len <= 0 || dest < 0) return 0;
    if (dest + len > P8_MEM_SIZE) len = P8_MEM_SIZE - dest;
    if (len <= 0) return 0;
    memset(&m->mem[dest], val & 0xff, (size_t)len);
    return 0;
}

/* --- table helpers (add/del/foreach/count + all iterator) ----------- */
/* PICO-8 ships these as built-in globals on top of the Lua tables. */

/* all(t): same del-during-iteration safety as foreach above. We
 * stash the last value we returned in upvalue 3 so the next call
 * can detect whether the slot was shifted (deleted) and re-read
 * the same index. */
static int all_iter(lua_State *L) {
    /* upvalues: 1=table, 2=last_index, 3=last_value */
    lua_Integer i = (lua_Integer)lua_tointeger(L, lua_upvalueindex(2));
    if (i > 0) {
        lua_rawgeti(L, lua_upvalueindex(1), i);
        int eq = lua_rawequal(L, -1, lua_upvalueindex(3));
        lua_pop(L, 1);
        if (eq) i++;        /* normal advance */
        /* else: slot was emptied — re-process slot i */
    } else {
        i = 1;
    }
    lua_Integer len = luaL_len(L, lua_upvalueindex(1));
    while (i <= len) {
        lua_rawgeti(L, lua_upvalueindex(1), i);
        if (!lua_isnil(L, -1)) {
            /* NOTE: do NOT set _ENV metatable here. all() just yields
             * values — setting __index=_G on them would make every
             * missing field resolve to a global (e.g. s.spr finding
             * the global spr function). _ENV metatable is only for
             * foreach() callbacks using function(_ENV) pattern. */
            /* Update upvalues for next call */
            lua_pushinteger(L, i);
            lua_replace(L, lua_upvalueindex(2));
            lua_pushvalue(L, -1);
            lua_replace(L, lua_upvalueindex(3));
            return 1;
        }
        lua_pop(L, 1);
        i++;
    }
    return 0;  /* exhausted */
}
static int l_p8_all(lua_State *L) {
    TRACE("all");
    if (lua_isnoneornil(L, 1) || !lua_istable(L, 1)) {
        lua_newtable(L);
        lua_pushinteger(L, 0);
        lua_pushnil(L);
        lua_pushcclosure(L, all_iter, 3);
        return 1;
    }
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 0);
    lua_pushnil(L);
    lua_pushcclosure(L, all_iter, 3);
    return 1;
}

/* PICO-8 add/del/count/foreach are LENIENT — they accept nil
 * tables and silently no-op or return nil. Real PICO-8 carts
 * (Delunky's level-init code in particular) call add(table, x)
 * before the table has been initialised; PICO-8 just returns nil,
 * Lua's strict luaL_checktype errors. We match PICO-8 here. */
static int l_add(lua_State *L) {
    TRACE("add");
    if (!lua_istable(L, 1)) { lua_pushnil(L); return 1; }
    lua_Integer len = luaL_len(L, 1);
    if (!lua_isnoneornil(L, 3)) {
        /* add(tbl, val, index) — insert at index, shifting others up */
        lua_Integer idx = (lua_Integer)lua_tonumber(L, 3);
        if (idx < 1) idx = 1;
        if (idx > len + 1) idx = len + 1;
        for (lua_Integer i = len; i >= idx; i--) {
            lua_rawgeti(L, 1, i);
            lua_rawseti(L, 1, i + 1);
        }
        lua_pushvalue(L, 2);
        lua_rawseti(L, 1, idx);
    } else {
        /* add(tbl, val) — append */
        lua_pushvalue(L, 2);
        lua_rawseti(L, 1, len + 1);
    }
    lua_pushvalue(L, 2);
    return 1;
}
static int l_del(lua_State *L) {
    TRACE("del");
    if (!lua_istable(L, 1)) { lua_pushnil(L); return 1; }
    lua_Integer len = luaL_len(L, 1);
    for (lua_Integer i = 1; i <= len; i++) {
        lua_rawgeti(L, 1, i);
        int eq = lua_rawequal(L, -1, 2);
        lua_pop(L, 1);
        if (eq) {
            /* shift down */
            for (lua_Integer j = i; j < len; j++) {
                lua_rawgeti(L, 1, j + 1);
                lua_rawseti(L, 1, j);
            }
            lua_pushnil(L);
            lua_rawseti(L, 1, len);
            lua_pushvalue(L, 2);
            return 1;
        }
    }
    lua_pushnil(L);
    return 1;
}
static int l_count(lua_State *L) {
    TRACE("count");
    if (!lua_istable(L, 1)) { lua_pushinteger(L, 0); return 1; }
    if (lua_isnoneornil(L, 2)) {
        /* count(tbl) — return length */
        lua_pushinteger(L, luaL_len(L, 1));
    } else {
        /* count(tbl, val) — count occurrences of val */
        lua_Integer len = luaL_len(L, 1);
        int n = 0;
        for (lua_Integer i = 1; i <= len; i++) {
            lua_rawgeti(L, 1, i);
            if (lua_rawequal(L, -1, 2)) n++;
            lua_pop(L, 1);
        }
        lua_pushinteger(L, n);
    }
    return 1;
}
/* foreach must survive del()-during-iteration. PICO-8 carts (Celeste
 * Classic in particular) routinely call `del(t, o)` from inside the
 * callback, which shifts later items down by one slot. We detect a
 * shift by stashing the value we just dispatched and re-reading t[i]
 * after the callback: if it changed, the slot was emptied → don't
 * advance i, so next iteration picks up the new occupant of slot i.
 * Also re-evaluates #t each step so add() during iter is honored. */
static int l_foreach(lua_State *L) {
    TRACE("foreach");
    if (!lua_istable(L, 1) || !lua_isfunction(L, 2)) return 0;
    lua_Integer i = 1;
    for (;;) {
        lua_Integer len = luaL_len(L, 1);
        if (i > len) break;
        lua_rawgeti(L, 1, i);              /* stack: value */
        if (lua_isnil(L, -1)) {
            lua_pop(L, 1);
            i++;
            continue;
        }
        /* Just pass the value through untouched — matching real PICO-8.
         * Carts using the `function(_ENV) ... end` pattern are
         * responsible for setting up their own metatable with
         * setmetatable(obj, {__index=_ENV}); the engine does not
         * do it automatically. */
        /* Call fn(value), keeping a duplicate for shift detection. */
        lua_pushvalue(L, -1);            /* stack: value, value */
        lua_pushvalue(L, 2);             /* stack: value, value, fn */
        lua_insert(L, -2);               /* stack: value, fn, value */
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) return lua_error(L);
        /* stack: value (saved) */
        lua_rawgeti(L, 1, i);               /* stack: value, cur */
        int eq = lua_rawequal(L, -1, -2);
        lua_pop(L, 2);
        if (eq) i++;
        /* else: leave i — next iter re-reads the shifted-in slot. */
    }
    return 0;
}

/* PICO-8 compat: pairs(nil) returns an empty iterator instead of erroring. */
static int p8_pairs_empty_next(lua_State *L) {
    lua_pushnil(L);
    return 1;
}
static int l_p8_pairs(lua_State *L) {
    if (lua_isnil(L, 1) || lua_isnone(L, 1)) {
        lua_pushcfunction(L, p8_pairs_empty_next);
        lua_pushnil(L);
        lua_pushnil(L);
        return 3;
    }
    /* Delegate to standard pairs() — call the original saved in registry */
    lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
    lua_getfield(L, -1, "__orig_pairs");
    lua_remove(L, -2);
    lua_pushvalue(L, 1);
    lua_call(L, 1, 3);
    return 3;
}

/* --- registration ---------------------------------------------------- */

/* px9_decomp(x0, y0, src, vget, vset) — C implementation of the
 * standard PICO-8 PX9 decompressor. Uses uint32_t for the bit cache
 * to avoid float precision loss (lua_Number is single-precision float,
 * which only has 24 bits of mantissa — not enough for 32-bit bitwise
 * operations that PX9 relies on). */
static int l_px9_decomp(lua_State *L) {
    TRACE("px9_decomp");
    p8_machine *m = get_machine(L);
    int x0 = argi(L, 1, 0);
    int y0 = argi(L, 2, 0);
    int src_addr = argi(L, 3, 0);
    /* args 4,5 = vget(x,y), vset(x,y,v) Lua callbacks */
    fprintf(stderr, "[px9] x0=%d y0=%d src=0x%x b=%02x%02x%02x%02x\n",
            x0, y0, src_addr,
            m->mem[src_addr & 0xffff], m->mem[(src_addr+1) & 0xffff],
            m->mem[(src_addr+2) & 0xffff], m->mem[(src_addr+3) & 0xffff]);

    /* --- bit cache (uint32_t for full 32-bit precision) --- */
    uint32_t cache = 0;
    int cache_bits = 0;

    /* peek2 from machine memory (little-endian, unsigned) */
    #define PX9_PEEK2(addr) ((uint32_t)m->mem[(addr) & 0xffff] | \
                             ((uint32_t)m->mem[((addr)+1) & 0xffff] << 8))

    #define PX9_GETVAL(bits, out) do { \
        if (cache_bits < 16) { \
            cache += PX9_PEEK2(src_addr) << cache_bits; \
            cache_bits += 16; \
            src_addr += 2; \
        } \
        (out) = (cache << (32 - (bits))) >> (32 - (bits)); \
        cache >>= (bits); \
        cache_bits -= (bits); \
    } while(0)

    /* gnp: read gamma-like number, starting from init_n */
    #define PX9_GNP(init_n, out) do { \
        uint32_t _n = (init_n), _bits = 0, _vv; \
        do { \
            _bits++; \
            PX9_GETVAL(_bits, _vv); \
            _n += _vv; \
        } while (_vv >= (1u << _bits) - 1); \
        (out) = _n; \
    } while(0)

    /* --- decode header --- */
    uint32_t w, h_1, eb, el_count;
    PX9_GNP(1, w);
    PX9_GNP(0, h_1);
    PX9_GNP(1, eb);

    /* element list + prediction lists. Static to avoid blowing
     * the 16KB device stack. */
    #define PX9_MAX_CONTEXTS 64
    #define PX9_MAX_EL 64
    static uint8_t el8[PX9_MAX_EL];
    static uint8_t pr_key[PX9_MAX_CONTEXTS];
    static uint8_t pr_list[PX9_MAX_CONTEXTS][PX9_MAX_EL];
    static int pr_count;

    PX9_GNP(1, el_count);
    fprintf(stderr, "[px9] w=%u h_1=%u eb=%u el_count=%u\n", w, h_1, eb, el_count);
    if (el_count > PX9_MAX_EL) el_count = PX9_MAX_EL;
    { uint32_t el_tmp;
      for (uint32_t i = 0; i < el_count; i++) {
        PX9_GETVAL(eb, el_tmp);
        el8[i] = (uint8_t)el_tmp;
    } }
    pr_count = 0;
    uint32_t elc = el_count;

    /* vlist_val: move val to front of list of length elc */
    #define PX9_VLIST_VAL(list, val) do { \
        for (uint32_t _i = 0; _i < elc; _i++) { \
            if ((list)[_i] == (uint8_t)(val)) { \
                for (uint32_t _j = _i; _j > 0; _j--) \
                    (list)[_j] = (list)[_j-1]; \
                (list)[0] = (uint8_t)(val); \
                break; \
            } \
        } \
    } while(0)

    /* --- main decode loop --- */
    uint32_t splen = 0;
    int predict = 0;
    int x = 0, y = 0;

    for (int yy = y0; yy <= y0 + (int)h_1; yy++) {
        for (int xx = x0; xx < x0 + (int)w; xx++) {
            if (splen < 1) {
                PX9_GNP(1, splen);
                predict = !predict;
            }
            splen--;

            /* a = vget(xx, yy-1): read from 0x4300 + x + y*w directly
             * instead of calling Lua callback — avoids stack pressure
             * on device from thousands of lua_call invocations. */
            uint32_t a = 0;
            if (yy > y0) {
                int addr = 0x4300 + xx + (yy - 1) * (int)w;
                if ((unsigned)addr < P8_MEM_SIZE)
                    a = m->mem[addr];
            }

            /* find or create prediction list for context 'a' */
            uint8_t *l = NULL;
            for (int pi = 0; pi < pr_count; pi++) {
                if (pr_key[pi] == (uint8_t)a) { l = pr_list[pi]; break; }
            }
            if (!l && pr_count < PX9_MAX_CONTEXTS) {
                pr_key[pr_count] = (uint8_t)a;
                l = pr_list[pr_count];
                memcpy(l, el8, elc);
                pr_count++;
            }
            if (!l) l = pr_list[0]; /* fallback if too many contexts */

            /* read value */
            uint32_t v;
            if (predict) {
                v = l[0];
            } else {
                uint32_t idx;
                PX9_GNP(2, idx);
                /* idx is 1-based (Lua convention); convert to 0-based */
                v = (idx >= 1 && idx - 1 < elc) ? l[idx - 1] : 0;
            }

            PX9_VLIST_VAL(l, v);
            PX9_VLIST_VAL(el8, v);

            /* vset(xx, yy, v): write directly to machine memory */
            {
                int addr = 0x4300 + xx + yy * (int)w;
                if ((unsigned)addr < P8_MEM_SIZE)
                    m->mem[addr] = (uint8_t)v;
            }

            /* advance x,y through the grid (Lua version does this
             * but the for loops already handle it — the Lua version
             * has a quirk where x,y are modified mid-loop. We skip
             * this since our for loops handle iteration correctly.) */
        }
    }

    #undef PX9_PEEK2
    #undef PX9_GETVAL
    #undef PX9_GNP
    #undef PX9_VLIST_VAL
    #undef PX9_MAX_CONTEXTS
    #undef PX9_MAX_EL
    return 0;
}

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
    { "rrect",    l_rrect },
    { "rrectfill",l_rrectfill },
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
    { "sgn",      l_p8_sgn },
    { "sqrt",     l_p8_sqrt },
    { "p8idiv",   l_p8_idiv },
    { "shl",      l_p8_shl },
    { "shr",      l_p8_shr },
    { "lshr",     l_p8_lshr },
    { "band",     l_p8_band },
    { "bor",      l_p8_bor },
    { "bxor",     l_p8_bxor },
    { "bnot",     l_p8_bnot },
    { "ord",      l_p8_ord },
    { "chr",      l_p8_chr },
    { "split",    l_p8_split },
    /* memory */
    { "peek",     l_peek },
    { "poke",     l_poke },
    { "peek2",    l_peek2 },
    { "poke2",    l_poke2 },
    { "peek4",    l_peek4 },
    { "poke4",    l_poke4 },
    { "unpack",   l_p8_unpack },
    { "pack",     l_p8_pack },
    /* drawing extras */
    { "fillp",    l_p8_fillp },
    { "flip",     l_p8_flip },
    { "oval",     l_p8_oval },
    { "ovalfill", l_p8_ovalfill },
    { "tline",    l_p8_tline },
    { "mapdraw",  l_map },
    /* table extras */
    { "deli",     l_p8_deli },
    /* bitwise rotates */
    { "rotl",     l_p8_rotl },
    { "rotr",     l_p8_rotr },
    /* host-control no-op stubs */
    { "extcmd",   l_p8_extcmd },
    { "cstore",   l_p8_cstore },
    { "serial",   l_p8_serial },
    { "stop",     l_p8_stop },
    { "run",      l_p8_run },
    { "reset",    l_p8_reset },
    { "ls",       l_p8_ls },
    { "holdframe", l_p8_holdframe },
    { "_set_fps", l_p8_set_fps },
    /* text + cursor */
    { "print",    l_print },
    { "cursor",   l_cursor },
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
    /* audio + persistence (Phase 4 = real, Phase 6 stubs) */
    { "sfx",      l_p8_sfx },
    { "music",    l_p8_music },
    { "stat",     l_p8_stat },
    { "printh",   l_p8_printh },
    { "menuitem", l_p8_menuitem },
    { "cartdata", l_p8_cartdata },
    { "dget",     l_p8_dget },
    { "dset",     l_p8_dset },
    { "reload",   l_p8_reload },
    { "memcpy",   l_p8_memcpy },
    { "memset",   l_p8_memset },
    { "px9_decomp", l_px9_decomp },
    { NULL, NULL }
};

/* Universal trace wrapper.
 *
 * Each PICO-8 binding is registered as a C closure with a single
 * integer upvalue — the binding's index in g_bind_table[]. The
 * wrapper looks up the real function and name via the index,
 * calls the trace hook if set, and forwards.
 *
 * We use an integer table instead of stuffing function pointers
 * into lightuserdata because storing a function pointer in a void*
 * is technically UB per C99/C11, and on Cortex-M Thumb mode the
 * LSB of a function pointer is the mode bit, which makes round-
 * tripping through `void *` particularly fragile. Indices are
 * portable. */
#define P8_MAX_BINDINGS 128
static lua_CFunction g_bind_func[P8_MAX_BINDINGS];
static const char   *g_bind_name[P8_MAX_BINDINGS];
static int           g_bind_count = 0;

static int p8_trace_wrap(lua_State *L) {
    int idx = (int)lua_tointeger(L, lua_upvalueindex(1));
    if (idx < 0 || idx >= g_bind_count) return 0;
    if (p8_trace_hook) p8_trace_hook(g_bind_name[idx]);
    return g_bind_func[idx](L);
}

/* PICO-8 string[i] → character at index i (1-indexed).
 * Upvalue 1 is the original string library __index table. */
static int p8_string_index(lua_State *L) {
    if (lua_isnumber(L, 2)) {
        int i = (int)lua_tointeger(L, 2);
        size_t slen;
        const char *s = lua_tolstring(L, 1, &slen);
        if (s && i >= 1 && (size_t)i <= slen) {
            /* PICO-8's str[i] returns the ordinal value (number) */
            lua_pushinteger(L, (unsigned char)s[i - 1]);
        } else {
            lua_pushnil(L);
        }
        return 1;
    }
    /* Non-numeric key: delegate to the string library table. */
    lua_pushvalue(L, 2);
    lua_gettable(L, lua_upvalueindex(1));
    return 1;
}

void p8_api_install(p8_vm *vm, p8_machine *machine, p8_input *input) {
    lua_State *L = vm->L;

    /* Bind the synth to this machine — the audio Lua functions
     * will route into it. */
    p8_audio_init(machine);

    /* Stash machine + input pointers in registry. */
    lua_pushlightuserdata(L, (void *)&k_machine_key);
    lua_pushlightuserdata(L, machine);
    lua_rawset(L, LUA_REGISTRYINDEX);

    lua_pushlightuserdata(L, (void *)&k_input_key);
    lua_pushlightuserdata(L, input);
    lua_rawset(L, LUA_REGISTRYINDEX);

    /* PICO-8 allows string[i] to access individual characters
     * (1-indexed). Standard Lua doesn't — strings aren't tables.
     * Set up the string metatable's __index to support numeric
     * indexing: str[1] → first char, str[2] → second, etc.
     * Non-numeric keys fall through to the string library. */
    {
        lua_pushliteral(L, "");              /* stack: "" */
        if (lua_getmetatable(L, -1)) {       /* stack: "", mt */
            lua_getfield(L, -1, "__index");  /* stack: "", mt, old_idx */
            lua_pushcclosure(L, p8_string_index, 1); /* pops old_idx as upvalue; stack: "", mt, closure */
            lua_setfield(L, -2, "__index");  /* mt.__index = closure; stack: "", mt */
            lua_pop(L, 1);                   /* pop mt; stack: "" */
        }
        lua_pop(L, 1);                       /* pop ""; stack clean */
    }

    /* Register every binding directly. The universal-wrapper
     * approach (closure with index upvalue) was tried but broke
     * cart load on device with no usable diagnostic — the failure
     * mode was a fault before any trace event fired. Revert to
     * direct registration; per-binding TRACE() calls cover the
     * functions we care about. */
    for (const luaL_Reg *r = p8_funcs; r->name; r++) {
        lua_pushcfunction(L, r->func);
        lua_setglobal(L, r->name);
    }

    /* PICO-8 compat: pairs(nil) → empty iterator. Save original
     * pairs to __orig_pairs in _G, then override with our wrapper. */
    lua_getglobal(L, "pairs");
    lua_setglobal(L, "__orig_pairs");
    lua_pushcfunction(L, l_p8_pairs);
    lua_setglobal(L, "pairs");
}

int p8_api_get_menuitems(const char **labels, int max) {
    menuitems_init();
    int count = 0;
    for (int i = 0; i < P8_MAX_MENUITEMS && count < max; i++) {
        if (g_menuitems[i].ref_cb != LUA_NOREF && g_menuitems[i].label[0]) {
            labels[count++] = g_menuitems[i].label;
        }
    }
    return count;
}

int p8_api_menuitem_invoke(p8_vm *vm, int idx, int buttons) {
    menuitems_init();
    /* Map display index back to slot index (skip empty slots) */
    int slot = -1, count = 0;
    for (int i = 0; i < P8_MAX_MENUITEMS; i++) {
        if (g_menuitems[i].ref_cb != LUA_NOREF && g_menuitems[i].label[0]) {
            if (count == idx) { slot = i; break; }
            count++;
        }
    }
    if (slot < 0) return 0;
    lua_State *L = vm->L;
    lua_rawgeti(L, LUA_REGISTRYINDEX, g_menuitems[slot].ref_cb);
    lua_pushinteger(L, buttons);
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        lua_pop(L, 1);
        return 0;
    }
    int keep_open = lua_toboolean(L, -1);
    lua_pop(L, 1);
    return keep_open;
}

void p8_api_post_load(p8_vm *vm) {
    lua_State *L = vm->L;
    /* Override px9_decomp with C version — the Lua version loses
     * precision due to float lua_Number (24-bit mantissa can't hold
     * the 32-bit bit cache that PX9 decompression requires). */
    lua_pushcfunction(L, l_px9_decomp);
    lua_setglobal(L, "px9_decomp");
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
