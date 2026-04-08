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
    SEC_SFX,
    SEC_MUSIC,
    SEC_OTHER  /* known but unhandled (label, etc.) */
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

/* __sfx__: 64 lines, 168 hex chars each.
 *   chars 0..1 = editor mode (1 byte)
 *   chars 2..3 = note duration / speed (1 byte)
 *   chars 4..5 = loop start (1 byte)
 *   chars 6..7 = loop end (1 byte)
 *   chars 8..167 = 32 notes, each 5 hex chars
 *
 * Per-note 5-char encoding (PICO-8 wiki, decoded into 16 bits):
 *   c0 = pitch high 2 bits + waveform low 2 bits  ?? format varies
 *
 * The pragmatic decode that matches what real carts produce: each
 * 5-char block packs into 2 cart-memory bytes as
 *   pitch  = chars 0..1 → byte 0 low 6 bits
 *   waveform = char 2 low 3 bits → byte 0 bit 6 + byte 1 bits 0..1
 *   volume = char 3 low 3 bits → byte 1 bits 1..3
 *   effect = char 4 low 3 bits → byte 1 bits 4..6
 * which is exactly the PICO-8 in-memory layout we synth from. */
static void decode_sfx_line(p8_machine *m, int row, const char *line) {
    if (row < 0 || row >= 64) return;
    int base = 0x3200 + row * 68;
    /* header */
    if (strlen(line) < 8) return;
    int ed   = (hexval(line[0]) << 4) | hexval(line[1]);
    int spd  = (hexval(line[2]) << 4) | hexval(line[3]);
    int ls   = (hexval(line[4]) << 4) | hexval(line[5]);
    int le   = (hexval(line[6]) << 4) | hexval(line[7]);
    m->mem[base + 0] = (uint8_t)ed;
    m->mem[base + 1] = (uint8_t)spd;
    m->mem[base + 2] = (uint8_t)ls;
    m->mem[base + 3] = (uint8_t)le;
    /* 32 notes */
    for (int n = 0; n < 32; n++) {
        const char *p = line + 8 + n * 5;
        int v0 = hexval(p[0]); int v1 = hexval(p[1]);
        int v2 = hexval(p[2]); int v3 = hexval(p[3]);
        int v4 = hexval(p[4]);
        if (v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 || v4 < 0) break;
        int pitch    = (v0 << 4) | v1;        /* 0..255, mask to 0..63 */
        int waveform = v2 & 0x7;
        int volume   = v3 & 0x7;
        int effect   = v4 & 0x7;
        uint16_t word = (uint16_t)((pitch & 0x3f)
                                   | (waveform << 6)
                                   | (volume   << 9)
                                   | (effect   << 12));
        m->mem[base + 4 + n * 2 + 0] = (uint8_t)(word & 0xff);
        m->mem[base + 4 + n * 2 + 1] = (uint8_t)((word >> 8) & 0xff);
    }
}

/* __music__: up to 64 lines, format `FL XX XX XX XX` where FL is
 * a 2-hex flag byte and XX XX XX XX are the 4 channel SFX ids.
 * The pattern's 4 cart-memory bytes encode:
 *   byte i = sfx_id, with high bit (0x80) = "channel disabled".
 *   Pattern flag bits (loop start / loop end / stop) live in the
 *   high bits of bytes 0..2; we store them but don't yet honor
 *   loops at the music engine level — Phase 4 covers per-sfx
 *   looping which is enough for most carts including Celeste. */
static void decode_music_line(p8_machine *m, int row, const char *line) {
    if (row < 0 || row >= 64) return;
    int base = 0x3100 + row * 4;
    /* parse "FF SSSSSSSS" → 1 + 4 bytes */
    if (strlen(line) < 11) return;
    int flag = (hexval(line[0]) << 4) | hexval(line[1]);
    /* 4 sfx ids, separated by spaces */
    const char *p = line + 3;
    for (int i = 0; i < 4; i++) {
        if (!p[0] || !p[1]) break;
        int v = (hexval(p[0]) << 4) | hexval(p[1]);
        m->mem[base + i] = (uint8_t)v;
        p += 2;
    }
    /* Stash flag bits into the high bits of byte 0 (our convention). */
    m->mem[base + 0] |= (uint8_t)(flag << 6);
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
    if (!strcmp(s, "__sfx__"))   return SEC_SFX;
    if (!strcmp(s, "__music__")) return SEC_MUSIC;
    if (!strcmp(s, "__label__")) return SEC_OTHER;
    return -1;
}

/* --- in-memory loader -------------------------------------------------
 * Walks the cart text directly out of `src`, no FILE* required.
 * Same parsing logic as the original line-oriented loader, just
 * driven by manual line slicing so it works on bare-metal.
 */
int p8_cart_load_from_memory(p8_cart *cart, p8_machine *m,
                              const char *src, size_t src_len) {
    cart->lua_source = NULL;
    cart->lua_size = 0;

    size_t lua_cap = 4096;
    size_t lua_len = 0;
    char *lua_buf = (char *)malloc(lua_cap);
    if (!lua_buf) return -1;
    lua_buf[0] = 0;

    int section = SEC_NONE;
    int gfx_row = 0, gff_row = 0, map_row = 0;
    int sfx_row = 0, music_row = 0;

    /* Reusable scratch line buffer for binary-section decoders that
     * want a NUL-terminated string. */
    char line[1024];

    size_t i = 0;
    while (i < src_len) {
        size_t j = i;
        while (j < src_len && src[j] != '\n') j++;
        size_t ll = j - i;     /* length without newline */
        const char *lp = src + i;

        /* Section marker detection (must be the whole line). */
        if (ll >= 5 && lp[0] == '_' && lp[1] == '_') {
            char marker[64];
            size_t mlen = ll;
            if (mlen > sizeof(marker) - 1) mlen = sizeof(marker) - 1;
            /* strip trailing \r if present */
            while (mlen > 0 && lp[mlen-1] == '\r') mlen--;
            memcpy(marker, lp, mlen);
            marker[mlen] = 0;
            int s = section_from_marker(marker);
            if (s >= 0) {
                section = s;
                gfx_row = gff_row = map_row = 0;
                sfx_row = music_row = 0;
                i = j + 1;
                continue;
            }
        }

        switch (section) {
        case SEC_LUA: {
            /* Lua section: append the line including its trailing \n. */
            size_t add = ll + 1;  /* +1 for the newline we'll re-add */
            if (lua_len + add + 1 > lua_cap) {
                while (lua_len + add + 1 > lua_cap) lua_cap *= 2;
                char *nb = (char *)realloc(lua_buf, lua_cap);
                if (!nb) { free(lua_buf); return -1; }
                lua_buf = nb;
            }
            memcpy(lua_buf + lua_len, lp, ll);
            lua_len += ll;
            lua_buf[lua_len++] = '\n';
            lua_buf[lua_len] = 0;
            break;
        }
        case SEC_GFX:
        case SEC_GFF:
        case SEC_MAP:
        case SEC_SFX:
        case SEC_MUSIC: {
            size_t cl = ll;
            if (cl > sizeof(line) - 1) cl = sizeof(line) - 1;
            memcpy(line, lp, cl);
            line[cl] = 0;
            /* Strip trailing \r */
            while (cl > 0 && line[cl-1] == '\r') line[--cl] = 0;
            if      (section == SEC_GFX)   decode_gfx_line(m,   gfx_row++,   line);
            else if (section == SEC_GFF)   decode_gff_line(m,   gff_row++,   line);
            else if (section == SEC_MAP)   decode_map_line(m,   map_row++,   line);
            else if (section == SEC_SFX)   decode_sfx_line(m,   sfx_row++,   line);
            else                            decode_music_line(m, music_row++, line);
            break;
        }
        default: break;
        }
        i = j + 1;
    }

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

#ifndef PICO_ON_DEVICE
/* Host file loader: slurps the file into memory then delegates. */
int p8_cart_load(p8_cart *cart, p8_machine *m, const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "[ThumbyP8] cart: cannot open '%s'\n", path);
        return -1;
    }
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return -1; }
    fseek(f, 0, SEEK_SET);
    char *buf = (char *)malloc((size_t)sz);
    if (!buf) { fclose(f); return -1; }
    if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
        free(buf); fclose(f); return -1;
    }
    fclose(f);
    int rc = p8_cart_load_from_memory(cart, m, buf, (size_t)sz);
    free(buf);
    return rc;
}
#endif

void p8_cart_free(p8_cart *cart) {
    if (cart->lua_source) {
        free(cart->lua_source);
        cart->lua_source = NULL;
    }
    cart->lua_size = 0;
}
