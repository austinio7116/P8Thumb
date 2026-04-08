/*
 * ThumbyP8 — .p8 text cart loader.
 *
 * Streaming line-oriented parser. Maintains a "current section"
 * state and dispatches each non-marker line to the matching
 * decoder. Sections we don't understand (e.g. __label__, __sfx__,
 * __music__ in Phase 1+2) are silently skipped.
 */
#include "p8_cart.h"
#include "p8_rewrite.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Section IDs */
enum {
    SEC_NONE = 0,
    SEC_LUA,
    SEC_GFX,
    SEC_GFF,
    SEC_MAP,
    SEC_OTHER  /* known section we don't decode (sfx, music, label) */
};

static int hexval(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* The PICO-8 sprite sheet (__gfx__) is written one nibble per
 * character, left-to-right. In RAM, the layout is 4bpp little-nibble:
 * even-x pixels in the low nibble, odd-x in the high nibble. So we
 * pack pairs of input chars into one byte. */
static void decode_gfx_line(p8_machine *m, int row, const char *line) {
    if (row < 0 || row >= 128) return;
    for (int x = 0; x < 128; x++) {
        if (!line[x] || line[x] == '\n') return;
        int v = hexval((unsigned char)line[x]);
        if (v < 0) v = 0;
        int addr = P8_GFX_BASE + (row << 6) + (x >> 1);
        uint8_t b = m->mem[addr];
        if (x & 1) m->mem[addr] = (b & 0x0f) | ((v & 0x0f) << 4);
        else       m->mem[addr] = (b & 0xf0) | (v & 0x0f);
    }
}

/* __gff__ is 2 lines × 256 chars → 256 sprite-flag bytes (one byte
 * per pair). */
static void decode_gff_line(p8_machine *m, int row, const char *line) {
    if (row < 0 || row >= 2) return;
    for (int i = 0; i < 128; i++) {
        if (!line[i*2] || !line[i*2+1]) return;
        int hi = hexval((unsigned char)line[i*2]);
        int lo = hexval((unsigned char)line[i*2+1]);
        if (hi < 0 || lo < 0) return;
        m->mem[P8_GFF_BASE + row * 128 + i] = (uint8_t)((hi << 4) | lo);
    }
}

/* __map__ is 32 lines × 256 chars → 32 rows × 128 tiles. These are
 * the *upper* 32 rows of the map (rows 0..31). The lower 32 rows
 * (32..63) live in the shared half of the gfx region. PICO-8 cart
 * format only stores upper-rows in __map__; lower-rows are read out
 * of __gfx__ at addresses 0x1000..0x1fff which we already populated. */
static void decode_map_line(p8_machine *m, int row, const char *line) {
    if (row < 0 || row >= 32) return;
    int base = 0x2000 + row * 128;
    for (int i = 0; i < 128; i++) {
        if (!line[i*2] || !line[i*2+1]) return;
        int hi = hexval((unsigned char)line[i*2]);
        int lo = hexval((unsigned char)line[i*2+1]);
        if (hi < 0 || lo < 0) return;
        m->mem[base + i] = (uint8_t)((hi << 4) | lo);
    }
}

/* Strip a trailing \r and \n from a freshly-read line. */
static void rstrip(char *s) {
    size_t n = strlen(s);
    while (n > 0 && (s[n-1] == '\n' || s[n-1] == '\r')) s[--n] = 0;
}

static int section_from_marker(const char *s) {
    if (!strcmp(s, "__lua__"))   return SEC_LUA;
    if (!strcmp(s, "__gfx__"))   return SEC_GFX;
    if (!strcmp(s, "__gff__"))   return SEC_GFF;
    if (!strcmp(s, "__map__"))   return SEC_MAP;
    if (!strcmp(s, "__sfx__"))   return SEC_OTHER;
    if (!strcmp(s, "__music__")) return SEC_OTHER;
    if (!strcmp(s, "__label__")) return SEC_OTHER;
    return -1;
}

int p8_cart_load(p8_cart *cart, p8_machine *m, const char *path) {
    cart->lua_source = NULL;
    cart->lua_size = 0;

    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "[ThumbyP8] cart: cannot open '%s'\n", path);
        return -1;
    }

    /* Two passes is wasteful; instead, accumulate Lua source into a
     * growing buffer and decode binary sections inline. */
    size_t lua_cap = 4096;
    size_t lua_len = 0;
    char *lua_buf = (char *)malloc(lua_cap);
    if (!lua_buf) { fclose(f); return -1; }
    lua_buf[0] = 0;

    char line[1024];
    int section = SEC_NONE;
    int gfx_row = 0, gff_row = 0, map_row = 0;

    while (fgets(line, sizeof(line), f)) {
        /* Detect section markers (must be the whole line). */
        char trimmed[64];
        size_t tlen = 0;
        for (size_t i = 0; line[i] && line[i] != '\n' && line[i] != '\r' && tlen < sizeof(trimmed)-1; i++) {
            trimmed[tlen++] = line[i];
        }
        trimmed[tlen] = 0;

        if (tlen >= 5 && trimmed[0] == '_' && trimmed[1] == '_') {
            int s = section_from_marker(trimmed);
            if (s >= 0) {
                section = s;
                gfx_row = gff_row = map_row = 0;
                continue;
            }
        }

        switch (section) {
        case SEC_LUA: {
            size_t add = strlen(line);
            if (lua_len + add + 1 > lua_cap) {
                while (lua_len + add + 1 > lua_cap) lua_cap *= 2;
                char *nb = (char *)realloc(lua_buf, lua_cap);
                if (!nb) { free(lua_buf); fclose(f); return -1; }
                lua_buf = nb;
            }
            memcpy(lua_buf + lua_len, line, add);
            lua_len += add;
            lua_buf[lua_len] = 0;
            break;
        }
        case SEC_GFX: rstrip(line); decode_gfx_line(m, gfx_row++, line); break;
        case SEC_GFF: rstrip(line); decode_gff_line(m, gff_row++, line); break;
        case SEC_MAP: rstrip(line); decode_map_line(m, map_row++, line); break;
        case SEC_OTHER:
        case SEC_NONE:
        default:
            break;
        }
    }
    fclose(f);

    /* Rewrite PICO-8 dialect → vanilla Lua 5.4. */
    size_t rewritten_len = 0;
    char *rewritten = p8_rewrite_lua(lua_buf, lua_len, &rewritten_len);
    if (rewritten) {
        free(lua_buf);
        cart->lua_source = rewritten;
        cart->lua_size = rewritten_len;
    } else {
        cart->lua_source = lua_buf;
        cart->lua_size = lua_len;
    }
    return 0;
}

void p8_cart_free(p8_cart *cart) {
    if (cart->lua_source) {
        free(cart->lua_source);
        cart->lua_source = NULL;
    }
    cart->lua_size = 0;
}
