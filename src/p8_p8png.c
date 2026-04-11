/*
 * ThumbyP8 — .p8.png cart loader implementation.
 *
 * Three responsibilities:
 *   1. Decode the PNG to RGBA pixels (via stb_image, vendored).
 *   2. Extract 32 KB of cart bytes from the low 2 bits of RGBA.
 *   3. Decompress the Lua section (raw / "old" / PXA formats) and
 *      copy ROM bytes into machine memory.
 *
 * The PXA bitstream decoder is implemented from the publicly-
 * documented algorithm: 1-bit literal/back-ref flag, MTF dictionary
 * for literals with Golomb-style index encoding, 2-bit offset width
 * selector for back-refs, 3-bit unary length encoding.
 */
#include "p8_p8png.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* stb_image needs ONE source file to define STB_IMAGE_IMPLEMENTATION
 * before #include. We're that file. We also restrict it to PNG-only
 * to keep the code-size cost down. */
#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_NO_STDIO          /* keeps fopen out of the device build */
#define STBI_NO_HDR
#define STBI_NO_LINEAR
#define STBI_NO_THREAD_LOCALS  /* drops __aeabi_read_tp on bare-metal */
#define STBI_ASSERT(x) ((void)0)
#include "lib/stb_image.h"

/* ---------- header detection ---------------------------------------- */

int p8_p8png_is_png(const unsigned char *data, size_t len) {
    if (len < 8) return 0;
    static const unsigned char png_magic[8] = {137,80,78,71,13,10,26,10};
    return memcmp(data, png_magic, 8) == 0;
}

/* ---------- pixel → cart bytes -------------------------------------- */
/* PICO-8 packs one cart byte into the low 2 bits of each pixel's
 * (A, R, G, B): byte = (a&3)<<6 | (r&3)<<4 | (g&3)<<2 | (b&3). */
static void unpack_cart_bytes(const unsigned char *rgba, int w, int h,
                               unsigned char *out, size_t out_max) {
    size_t n = (size_t)w * (size_t)h;
    if (n > out_max) n = out_max;
    for (size_t i = 0; i < n; i++) {
        unsigned char r = rgba[i*4 + 0];
        unsigned char g = rgba[i*4 + 1];
        unsigned char b = rgba[i*4 + 2];
        unsigned char a = rgba[i*4 + 3];
        out[i] = (unsigned char)(((a & 3) << 6) | ((r & 3) << 4)
                                | ((g & 3) << 2) | (b & 3));
    }
}

/* ---------- ROM → machine memory ------------------------------------ */
/* The ROM region of a .p8.png cart maps 1:1 to PICO-8 RAM addresses
 * 0x0000..0x42ff:
 *   0x0000..0x1fff  gfx (sprite sheet, 4bpp)
 *   0x1000..0x1fff  shared lower-half map (overlaps gfx)
 *   0x2000..0x2fff  upper-half map
 *   0x3000..0x30ff  gff (sprite flags)
 *   0x3100..0x31ff  music
 *   0x3200..0x42ff  sfx
 *
 * Our cart memory layout matches PICO-8's exactly (we deliberately
 * use the same offsets), so this is just a memcpy. */
static void rom_to_machine(p8_machine *m, const unsigned char *cart) {
    /* Copy ROM (gfx, gff, map, sfx, music). */
    memcpy(&m->mem[0x0000], cart, 0x4300);
}

/* ---------- "old" compression (`:c:\0`) ----------------------------- */
/* Header: ":c:\0" + 2 bytes raw_len (big-endian) + 2 bytes unused.
 * Stream: 0x00 → next byte is literal; 0x01..0x3b → dictionary index;
 * 0x3c..0xff → 2-byte back-reference. Dictionary is the canonical
 * 60-char PICO-8 charset. */
static const char k_old_dict[60] =
    "\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_";

static int decompress_old(const unsigned char *src, size_t src_len,
                           char *out, size_t out_max) {
    if (src_len < 8) return -1;
    int raw_len = (src[4] << 8) | src[5];
    if (raw_len < 0 || (size_t)raw_len > out_max) return -1;
    size_t i = 8;
    int oi = 0;
    while (oi < raw_len && i < src_len) {
        unsigned char b = src[i++];
        if (b == 0) {
            if (i >= src_len) break;
            out[oi++] = (char)src[i++];
        } else if (b <= 0x3b) {
            out[oi++] = k_old_dict[b - 1];
        } else {
            if (i >= src_len) break;
            unsigned char b2 = src[i++];
            int offset = (b - 0x3c) * 16 + (b2 & 0x0f);
            int clen   = (b2 >> 4) + 2;
            if (offset == 0 || offset > oi) break;
            int start = oi - offset;
            for (int k = 0; k < clen && oi < raw_len; k++) {
                out[oi] = out[start + k];
                oi++;
            }
        }
    }
    return oi;
}

/* ---------- PXA compression (`\0pxa`) ------------------------------- */
/* Algorithm (paraphrased from the publicly-documented format):
 *
 *   header (8 bytes):
 *     "\0pxa"               (4)
 *     decompressed_len      (2, big-endian)
 *     compressed_len        (2, big-endian, including header)
 *
 *   bitstream (LSB-first within each byte):
 *     1-bit flag:
 *       1 → LITERAL: read variable-length MTF index, output the
 *           character at that index, move it to front.
 *       0 → BACK-REF: read 2-bit offset-width selector, read offset
 *           bits + 1, read length (3-bit chunks with escape value 7,
 *           base 3), copy `length` bytes from `output[pos - offset]`.
 *
 *   MTF dictionary: starts as the identity (0..255).
 *   Literal index: read 4 bits; while value == 15 read 4 more bits
 *     and add 15 (Golomb-style with chunk = 4).
 *   Back-ref offset selector: 2 bits → {00:15-bit, 01:10-bit, 10:5-bit}.
 *   Back-ref length: 3-bit chunks, base 3, escape 7.
 */
typedef struct bitr {
    const unsigned char *data;
    size_t pos;     /* bit position from start of `data` */
    size_t lim;     /* total bits available */
} bitr;

static int br_read(bitr *r, int n) {
    int v = 0;
    for (int i = 0; i < n; i++) {
        if (r->pos >= r->lim) return v;
        size_t bi = r->pos >> 3;
        int    bo = r->pos & 7;
        v |= ((r->data[bi] >> bo) & 1) << i;
        r->pos++;
    }
    return v;
}

static int decompress_pxa(const unsigned char *src, size_t src_len,
                           char *out, size_t out_max) {
    if (src_len < 8) return -1;
    int raw_len  = (src[4] << 8) | src[5];
    int comp_len = (src[6] << 8) | src[7];
    (void)comp_len;
    if (raw_len < 0 || (size_t)raw_len > out_max) return -1;

    /* Bit reader starts after the 8-byte header. */
    bitr r;
    r.data = src + 8;
    r.pos  = 0;
    r.lim  = (src_len > 8 ? (src_len - 8) * 8 : 0);

    /* Move-to-front dictionary, identity start. */
    unsigned char mtf[256];
    for (int i = 0; i < 256; i++) mtf[i] = (unsigned char)i;

    int oi = 0;
    int safety = 0;
    while (oi < raw_len) {
        if (++safety > raw_len * 50) break;   /* runaway guard */
        int flag = br_read(&r, 1);
        if (flag == 1) {
            /* LITERAL — variable-bit-width MTF index.
             *
             * Width selector:  start at 4 bits, then read 1-bit
             * continuations. Each continuation bit set means "add
             * 1 to nbits". Then read nbits bits and offset by
             * (1 << nbits) - 16, which biases each width range
             * to start where the previous one ended:
             *
             *   nbits=4 → idx ∈ [ 0..15]   (no continuation bits)
             *   nbits=5 → idx ∈ [16..47]   (one  continuation)
             *   nbits=6 → idx ∈ [48..111]  (two  continuations)
             *   ...
             */
            int nbits = 4;
            while (br_read(&r, 1)) {
                nbits++;
                if (nbits > 16) break;       /* sanity */
            }
            int idx = br_read(&r, nbits) + (1 << nbits) - 16;
            if (idx < 0 || idx >= 256) break;
            unsigned char c = mtf[idx];
            out[oi++] = (char)c;
            /* Move-to-front: shift [0..idx-1] down, put c at 0. */
            for (int k = idx; k > 0; k--) mtf[k] = mtf[k-1];
            mtf[0] = c;
        } else {
            /* BACK-REFERENCE — 1-or-2 bit offset-width selector:
             *    0   → 15-bit offset
             *    1 0 → 10-bit offset
             *    1 1 →  5-bit offset
             */
            int off_bits;
            int s0 = br_read(&r, 1);
            if (s0 == 0) {
                off_bits = 15;
            } else {
                int s1 = br_read(&r, 1);
                off_bits = s1 ? 5 : 10;
            }
            int offset = br_read(&r, off_bits) + 1;

            /* Special signal: nbits == 10 && offset == 1 means
             * "embedded raw byte stream until zero terminator". */
            if (off_bits == 10 && offset == 1) {
                while (oi < raw_len) {
                    int byte = br_read(&r, 8);
                    if (byte == 0) break;
                    out[oi++] = (char)byte;
                }
                continue;
            }

            /* Length: base 3, accumulate 3-bit chunks while chunk == 7. */
            int length = 3;
            while (1) {
                int chunk = br_read(&r, 3);
                length += chunk;
                if (chunk != 7) break;
            }
            if (offset > oi || offset == 0) break;
            int start = oi - offset;
            for (int k = 0; k < length && oi < raw_len; k++) {
                out[oi] = out[start + k];
                oi++;
            }
        }
    }
    return oi;
}

/* ---------- Lua section dispatch ------------------------------------ */
/* Cart bytes 0x4300..0x8000 hold the Lua source, possibly compressed. */
static char *extract_lua(const unsigned char *cart, size_t *out_len) {
    const unsigned char *code = cart + 0x4300;
    size_t code_max = 0x8000 - 0x4300;
    char *buf = (char *)malloc(0x10000);  /* generous; Lua cap is 64KB */
    if (!buf) return NULL;

    if (code[0] == ':' && code[1] == 'c' && code[2] == ':' && code[3] == 0) {
        int n = decompress_old(code, code_max, buf, 0x10000 - 1);
        if (n < 0) { free(buf); return NULL; }
        buf[n] = 0;
        if (out_len) *out_len = (size_t)n;
        return buf;
    }
    if (code[0] == 0 && code[1] == 'p' && code[2] == 'x' && code[3] == 'a') {
        int n = decompress_pxa(code, code_max, buf, 0x10000 - 1);
        if (n < 0) { free(buf); return NULL; }
        buf[n] = 0;
        if (out_len) *out_len = (size_t)n;
        return buf;
    }
    /* Raw — read until first NUL (or end of region). */
    size_t n = 0;
    while (n < code_max && code[n] != 0) {
        buf[n] = (char)code[n];
        n++;
    }
    buf[n] = 0;
    if (out_len) *out_len = n;
    return buf;
}

/* ---------- public API ---------------------------------------------- */

int p8_p8png_load(p8_machine *m,
                  unsigned char *png_data, size_t png_len,
                  char **out_lua_src, size_t *out_lua_len,
                  uint16_t *out_thumb) {
    if (out_lua_src) *out_lua_src = NULL;
    if (out_lua_len) *out_lua_len = 0;

    int w = 0, h = 0, ch = 0;
    unsigned char *rgba = stbi_load_from_memory(png_data, (int)png_len,
                                                 &w, &h, &ch, 4);
    /* Free the compressed PNG immediately — stb_image has finished
     * reading it. This frees 40-70KB before we allocate cart bytes. */
    free(png_data);

    if (!rgba) {
        fprintf(stderr, "[ThumbyP8] p8.png: PNG decode failed: %s\n",
                stbi_failure_reason() ? stbi_failure_reason() : "(?)");
        return -1;
    }

    /* Extract thumbnail from the visible PNG image BEFORE freeing RGBA.
     * The PICO-8 label area sits at (16,24) in the 160×205 PNG.
     * Crop and convert to RGB565 in the caller's buffer. */
    if (out_thumb) {
        int x0 = (w >= 144) ? 16 : 0;
        int y0 = (h >= 152) ? 24 : 0;
        int cw = (w >= 144) ? 128 : (w < 128 ? w : 128);
        int chh = (h >= 152) ? 128 : (h < 128 ? h : 128);
        memset(out_thumb, 0, 128 * 128 * sizeof(uint16_t));
        for (int y = 0; y < chh; y++) {
            const unsigned char *row = rgba + ((y0 + y) * w + x0) * 4;
            uint16_t *dst = out_thumb + y * 128;
            for (int x = 0; x < cw; x++) {
                unsigned char r = row[x*4 + 0];
                unsigned char g = row[x*4 + 1];
                unsigned char b = row[x*4 + 2];
                dst[x] = (uint16_t)(((r & 0xf8) << 8) | ((g & 0xfc) << 3) | (b >> 3));
            }
        }
    }

    /* Extract 32 KB of cart bytes from low 2 bits of each pixel.
     * Heap-allocated — 32 KB on the stack would blow the 16 KB device stack. */
    unsigned char *cart = (unsigned char *)malloc(0x8000);
    if (!cart) {
        stbi_image_free(rgba);
        return -1;
    }
    memset(cart, 0, 0x8000);
    unpack_cart_bytes(rgba, w, h, cart, 0x8000);
    stbi_image_free(rgba);

    /* Copy ROM region into machine memory. */
    rom_to_machine(m, cart);

    /* Decompress Lua section. */
    size_t lua_len = 0;
    char *lua = extract_lua(cart, &lua_len);
    free(cart);
    if (!lua) {
        fprintf(stderr, "[ThumbyP8] p8.png: Lua section decode failed\n");
        return -1;
    }
    if (out_lua_src) *out_lua_src = lua;
    else free(lua);
    if (out_lua_len) *out_lua_len = lua_len;
    return 0;
}

/* --- IO-based loader: reads PNG from callbacks, no input buffer --- */

int p8_p8png_load_io(p8_machine *m,
                     p8_png_io *io, void *io_user,
                     char **out_lua_src, size_t *out_lua_len,
                     uint16_t *out_thumb) {
    if (out_lua_src) *out_lua_src = NULL;
    if (out_lua_len) *out_lua_len = 0;

    /* stbi_io_callbacks matches our p8_png_io layout exactly */
    stbi_io_callbacks cb;
    cb.read = io->read;
    cb.skip = io->skip;
    cb.eof  = io->eof;

    int w = 0, h = 0, ch = 0;
    unsigned char *rgba = stbi_load_from_callbacks(&cb, io_user,
                                                    &w, &h, &ch, 4);
    if (!rgba) {
        fprintf(stderr, "[ThumbyP8] p8.png io: decode failed: %s\n",
                stbi_failure_reason() ? stbi_failure_reason() : "(?)");
        return -1;
    }

    /* Thumbnail */
    if (out_thumb) {
        int x0 = (w >= 144) ? 16 : 0;
        int y0 = (h >= 152) ? 24 : 0;
        int cw2 = (w >= 144) ? 128 : (w < 128 ? w : 128);
        int ch2 = (h >= 152) ? 128 : (h < 128 ? h : 128);
        memset(out_thumb, 0, 128 * 128 * sizeof(uint16_t));
        for (int y = 0; y < ch2; y++) {
            const unsigned char *row = rgba + ((y0 + y) * w + x0) * 4;
            uint16_t *dst = out_thumb + y * 128;
            for (int x = 0; x < cw2; x++) {
                unsigned char r = row[x*4+0], g = row[x*4+1], b = row[x*4+2];
                dst[x] = (uint16_t)(((r&0xf8)<<8)|((g&0xfc)<<3)|(b>>3));
            }
        }
    }

    /* Cart bytes */
    unsigned char *cart = (unsigned char *)malloc(0x8000);
    if (!cart) { stbi_image_free(rgba); return -1; }
    memset(cart, 0, 0x8000);
    unpack_cart_bytes(rgba, w, h, cart, 0x8000);
    stbi_image_free(rgba);

    rom_to_machine(m, cart);

    size_t lua_len = 0;
    char *lua = extract_lua(cart, &lua_len);
    free(cart);
    if (!lua) return -1;

    if (out_lua_src) *out_lua_src = lua;
    else free(lua);
    if (out_lua_len) *out_lua_len = lua_len;
    return 0;
}

int p8_p8png_decode_thumbnail(const unsigned char *png_data, size_t png_len,
                               uint16_t *out_thumb) {
    int w = 0, h = 0, ch = 0;
    unsigned char *rgba = stbi_load_from_memory(png_data, (int)png_len,
                                                 &w, &h, &ch, 4);
    if (!rgba) return -1;

    /* PICO-8 PNG carts are 160x205. The visible label area sits at
     * x=16, y=24 spanning 128×128. Crop and convert to RGB565. */
    int x0 = (w  >= 144) ? 16 : 0;
    int y0 = (h  >= 152) ? 24 : 0;
    int cw = (w  >= 144) ? 128 : (w  < 128 ? w  : 128);
    int chh = (h >= 152) ? 128 : (h  < 128 ? h  : 128);
    /* Zero out target then fill the cropped region. */
    memset(out_thumb, 0, 128 * 128 * sizeof(uint16_t));
    for (int y = 0; y < chh; y++) {
        const unsigned char *row = rgba + ((y0 + y) * w + x0) * 4;
        uint16_t *dst = out_thumb + y * 128;
        for (int x = 0; x < cw; x++) {
            unsigned char r = row[x*4 + 0];
            unsigned char g = row[x*4 + 1];
            unsigned char b = row[x*4 + 2];
            dst[x] = (uint16_t)(((r & 0xf8) << 8) | ((g & 0xfc) << 3) | (b >> 3));
        }
    }
    stbi_image_free(rgba);
    return 0;
}
