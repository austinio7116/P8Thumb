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
    lua_pushnumber(L, -sin(argn0(L, 1) * 2.0 * M_PI));
    return 1;
}
static int l_p8_cos(lua_State *L) {
    lua_pushnumber(L, cos(argn0(L, 1) * 2.0 * M_PI));
    return 1;
}
static int l_p8_atan2(lua_State *L) {
    lua_Number dx = argn0(L, 1);
    lua_Number dy = argn0(L, 2);
    if (dx == 0 && dy == 0) { lua_pushnumber(L, 0.25); return 1; }
    /* PICO-8 anticlockwise screenspace: atan2(0,-1) -> 0.25 */
    lua_Number a = 1.0 - atan2(dy, dx) / (2.0 * M_PI);
    a = a - floor(a);  /* wrap to [0,1) */
    lua_pushnumber(L, a);
    return 1;
}
static int l_p8_flr(lua_State *L)  { lua_pushnumber(L, floor(argn0(L, 1))); return 1; }
static int l_p8_ceil(lua_State *L) { lua_pushnumber(L, ceil(argn0(L, 1)));  return 1; }
static int l_p8_abs(lua_State *L)  { lua_pushnumber(L, fabs(argn0(L, 1)));  return 1; }
static int l_p8_min(lua_State *L) {
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    lua_pushnumber(L, a < b ? a : b);
    return 1;
}
static int l_p8_max(lua_State *L) {
    lua_Number a = argn0(L, 1);
    lua_Number b = argn0(L, 2);
    lua_pushnumber(L, a > b ? a : b);
    return 1;
}
static int l_p8_mid(lua_State *L) {
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

/* sgn(x) → -1 if x<0, +1 otherwise (PICO-8: sgn(0) = 1). */
static int l_p8_sgn(lua_State *L) {
    lua_Number x = argn0(L, 1);
    lua_pushnumber(L, x < 0 ? -1 : 1);
    return 1;
}

static int l_p8_sqrt(lua_State *L) {
    lua_Number x = argn0(L, 1);
    lua_pushnumber(L, x < 0 ? 0 : sqrt(x));
    return 1;
}

/* PICO-8 pre-0.2 bitwise functions (now usually expressed as << >>
 * & | ~ in newer carts, but old carts still call these by name). */
static int l_p8_shl(lua_State *L) {
    int x = (int)argn0(L, 1);
    int n = (int)argn0(L, 2);
    lua_pushinteger(L, ((unsigned)x) << (n & 31));
    return 1;
}
static int l_p8_shr(lua_State *L) {
    int x = (int)argn0(L, 1);
    int n = (int)argn0(L, 2);
    /* Arithmetic right shift to match PICO-8's signed semantics. */
    lua_pushinteger(L, x >> (n & 31));
    return 1;
}
static int l_p8_lshr(lua_State *L) {
    unsigned x = (unsigned)argn0(L, 1);
    int n = (int)argn0(L, 2);
    lua_pushinteger(L, x >> (n & 31));
    return 1;
}
static int l_p8_band(lua_State *L) {
    int a = (int)argn0(L, 1);
    int b = (int)argn0(L, 2);
    lua_pushinteger(L, a & b);
    return 1;
}
static int l_p8_bor(lua_State *L) {
    int a = (int)argn0(L, 1);
    int b = (int)argn0(L, 2);
    lua_pushinteger(L, a | b);
    return 1;
}
static int l_p8_bxor(lua_State *L) {
    int a = (int)argn0(L, 1);
    int b = (int)argn0(L, 2);
    lua_pushinteger(L, a ^ b);
    return 1;
}
static int l_p8_bnot(lua_State *L) {
    int a = (int)argn0(L, 1);
    lua_pushinteger(L, ~a);
    return 1;
}

/* ord(s, [i]) → byte value of s[i] (1-indexed). chr(n) → 1-byte string. */
static int l_p8_ord(lua_State *L) {
    size_t L_str = 0;
    const char *s = luaL_checklstring(L, 1, &L_str);
    int i = lua_isnoneornil(L, 2) ? 1 : (int)luaL_checknumber(L, 2);
    if (i < 1 || (size_t)i > L_str) { lua_pushnil(L); return 1; }
    lua_pushinteger(L, (unsigned char)s[i - 1]);
    return 1;
}
static int l_p8_chr(lua_State *L) {
    int n = (int)luaL_checknumber(L, 1);
    char buf[2] = { (char)(n & 0xff), 0 };
    lua_pushlstring(L, buf, 1);
    return 1;
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
    p8_font_draw(m, s, x, y, c);
    if (!has_xy) {
        /* Advance cursor: PICO-8 increments y by 6 and wraps;
         * x resets to the original cursor x. */
        int next_y = y + P8_FONT_CELL_H;
        if (next_y >= P8_SCREEN_H) next_y = P8_SCREEN_H - P8_FONT_CELL_H;
        m->mem[P8_DS_CURSOR_Y] = (uint8_t)next_y;
    }
    return 0;
}

/* cursor(x, y, [col]) — set the print cursor and optionally pen. */
static int l_cursor(lua_State *L) {
    p8_machine *m = get_machine(L);
    int x = argi(L, 1, 0);
    int y = argi(L, 2, 0);
    m->mem[P8_DS_CURSOR_X] = (uint8_t)(x & 0xff);
    m->mem[P8_DS_CURSOR_Y] = (uint8_t)(y & 0xff);
    if (!lua_isnoneornil(L, 3)) p8_set_pen(m, (uint8_t)(argi(L, 3, 6) & 0x0f));
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

/* Phase 4 — real audio synth bindings.
 *
 * sfx(n, [channel], [offset], [length])
 *   n=-1 stops the channel; n=-2 stops sfx playing on the channel
 *   without disturbing the music slot. We treat both as stop. */
static int l_p8_sfx(lua_State *L) {
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
    int n          = argi(L, 1, -1);
    int fade_len   = argi(L, 2, 0);
    int chan_mask  = argi(L, 3, 0);
    p8_audio_music(n, fade_len, chan_mask);
    return 0;
}

/* stat(n) — partial PICO-8 surface. The synth-related queries
 * (16..23) come from p8_audio_stat(); other ids return 0. */
static int l_p8_stat(lua_State *L) {
    int n = argi(L, 1, 0);
    if (n >= 16 && n <= 23) {
        lua_pushinteger(L, p8_audio_stat(n));
    } else {
        lua_pushinteger(L, 0);
    }
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

/* reload(dest_addr, src_addr, len, [filename]) — copy bytes from
 * the cart's read-only ROM image into runtime memory. Real PICO-8
 * keeps the cart and a separate working copy; we don't (cart and
 * runtime memory are the same buffer at machine.mem) so the typical
 * use case (`reload(0, 0, 0x4300)` to "reset graphics back to the
 * cart's original sprites") is conceptually a no-op for us — the
 * sprites/map/sfx never get modified at runtime unless the cart
 * does so explicitly. A no-op stub is correct for the vast
 * majority of carts. */
static int l_p8_reload(lua_State *L) {
    (void)L;
    return 0;
}

/* memcpy(dest, src, len) — copy bytes within machine memory. PICO-8
 * carts use this for cheap blitting and animation tricks. */
static int l_p8_memcpy(lua_State *L) {
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
        lua_geti(L, lua_upvalueindex(1), i);
        int eq = lua_rawequal(L, -1, lua_upvalueindex(3));
        lua_pop(L, 1);
        if (eq) i++;        /* normal advance */
        /* else: slot was emptied — re-process slot i */
    } else {
        i = 1;
    }
    lua_Integer len = luaL_len(L, lua_upvalueindex(1));
    while (i <= len) {
        lua_geti(L, lua_upvalueindex(1), i);
        if (!lua_isnil(L, -1)) {
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
    if (!lua_istable(L, 1)) { lua_pushnil(L); return 1; }
    /* PICO-8 add returns the inserted value */
    lua_Integer len = luaL_len(L, 1);
    lua_pushvalue(L, 2);
    lua_seti(L, 1, len + 1);
    lua_pushvalue(L, 2);
    return 1;
}
static int l_del(lua_State *L) {
    if (!lua_istable(L, 1)) { lua_pushnil(L); return 1; }
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
    if (!lua_istable(L, 1)) { lua_pushinteger(L, 0); return 1; }
    lua_pushinteger(L, luaL_len(L, 1));
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
    if (!lua_istable(L, 1) || !lua_isfunction(L, 2)) return 0;
    lua_Integer i = 1;
    for (;;) {
        lua_Integer len = luaL_len(L, 1);
        if (i > len) break;
        lua_geti(L, 1, i);              /* stack: value */
        if (lua_isnil(L, -1)) {
            lua_pop(L, 1);
            i++;
            continue;
        }
        /* Call fn(value), keeping a duplicate for shift detection. */
        lua_pushvalue(L, -1);            /* stack: value, value */
        lua_pushvalue(L, 2);             /* stack: value, value, fn */
        lua_insert(L, -2);               /* stack: value, fn, value */
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) return lua_error(L);
        /* stack: value (saved) */
        lua_geti(L, 1, i);               /* stack: value, cur */
        int eq = lua_rawequal(L, -1, -2);
        lua_pop(L, 2);
        if (eq) i++;
        /* else: leave i — next iter re-reads the shifted-in slot. */
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
    { "sgn",      l_p8_sgn },
    { "sqrt",     l_p8_sqrt },
    { "shl",      l_p8_shl },
    { "shr",      l_p8_shr },
    { "lshr",     l_p8_lshr },
    { "band",     l_p8_band },
    { "bor",      l_p8_bor },
    { "bxor",     l_p8_bxor },
    { "bnot",     l_p8_bnot },
    { "ord",      l_p8_ord },
    { "chr",      l_p8_chr },
    /* memory */
    { "peek",     l_peek },
    { "poke",     l_poke },
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
    { NULL, NULL }
};

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
