/*
 * ThumbyP8 — fantasy console machine state.
 *
 * Just the boring bits: reset to a sensible default, the canonical
 * PICO-8 16-color palette in RGB565, and the framebuffer expand
 * routine that turns 4bpp packed pixels into a linear RGB565 buffer
 * the host or LCD driver can DMA out.
 */
#include "p8_machine.h"
#include <string.h>

/* --- canonical PICO-8 palette in RGB565 ------------------------------- */
/* Reference colors (RGB888):
 *  0 black     000000   1 dark-blue 1d2b53   2 dark-purple 7e2553
 *  3 dark-green 008751  4 brown    ab5236    5 dark-grey  5f574f
 *  6 light-grey c2c3c7  7 white    fff1e8    8 red        ff004d
 *  9 orange    ffa300   10 yellow  ffec27    11 green     00e436
 * 12 blue      29adff   13 lavender 83769c   14 pink      ff77a8
 * 15 peach     ffccaa
 * Converted to RGB565: ((R>>3)<<11) | ((G>>2)<<5) | (B>>3)
 */
/* PICO-8's 32-color system palette. [0..15] = official base,
 * [16..31] = undocumented secret palette (indices 128..143 in PICO-8). */
static const uint16_t k_p8_palette_rgb565[32] = {
    /* Base palette (indices 0-15) */
    0x0000, /*  0 #000000 black */
    0x194a, /*  1 #1d2b53 dark-blue */
    0x792a, /*  2 #7e2553 dark-purple */
    0x042a, /*  3 #008751 dark-green */
    0xaa86, /*  4 #ab5236 brown */
    0x5aa9, /*  5 #5f574f dark-grey */
    0xc618, /*  6 #c2c3c7 light-grey */
    0xff9d, /*  7 #fff1e8 white */
    0xf809, /*  8 #ff004d red */
    0xfd00, /*  9 #ffa300 orange */
    0xff64, /* 10 #ffec27 yellow */
    0x0726, /* 11 #00e436 green */
    0x2d7f, /* 12 #29adff blue */
    0x83b3, /* 13 #83769c lavender */
    0xfbb5, /* 14 #ff77a8 pink */
    0xfe75, /* 15 #ffccaa light-peach */
    /* Secret palette (indices 128-143, stored at offsets 16-31) */
    0x28c2, /* 128 #291814 brownish-black */
    0x10e6, /* 129 #111d35 darker-blue */
    0x4106, /* 130 #422136 darker-purple */
    0x128b, /* 131 #125359 blue-green */
    0x7165, /* 132 #742f29 dark-brown */
    0x4987, /* 133 #49333b darker-grey */
    0xa44f, /* 134 #a28879 medium-grey */
    0xf76f, /* 135 #f3ef7d light-yellow */
    0xb88a, /* 136 #be1250 dark-red */
    0xfb64, /* 137 #ff6c24 dark-orange */
    0xaf25, /* 138 #a8e72e lime-green */
    0x05a8, /* 139 #00b543 medium-green */
    0x02d6, /* 140 #065ab5 true-blue */
    0x722c, /* 141 #754665 mauve */
    0xfb6b, /* 142 #ff6e59 dark-peach */
    0xfcf0, /* 143 #ff9d81 peach */
};

void p8_machine_reset(p8_machine *m) {
    memset(m->mem, 0, sizeof(m->mem));

    /* Default draw palette: identity (color N → color N). */
    for (int i = 0; i < 16; i++) {
        m->mem[P8_DS_DRAW_PAL + i]   = (uint8_t)i;
        m->mem[P8_DS_SCREEN_PAL + i] = (uint8_t)i;
    }
    /* PICO-8 default: color 0 is transparent in pal/spr terms. We
     * track that as a separate transparency bitmask in 0x5f00 high
     * bits in real PICO-8; for now we use a side flag in the draw
     * palette: high bit set means "transparent in spr". Bind that
     * default by setting bit 4 of pal entry 0. */
    m->mem[P8_DS_DRAW_PAL + 0] |= 0x10;

    /* Default clip = full screen */
    m->mem[P8_DS_CLIP_X0] = 0;
    m->mem[P8_DS_CLIP_Y0] = 0;
    m->mem[P8_DS_CLIP_X1] = 128;
    m->mem[P8_DS_CLIP_Y1] = 128;

    /* Default pen = white-ish (color 6 — light-grey is PICO-8 default) */
    m->mem[P8_DS_PEN] = 6;

    /* Camera at origin */
    p8_set_camera(m, 0, 0);

    /* Cache RGB565 palette — both the 16 base colors and 16 secret. */
    for (int i = 0; i < 32; i++) {
        m->rgb565_palette[i] = k_p8_palette_rgb565[i];
    }
}

void p8_machine_present(const p8_machine *m, uint16_t *dst) {
    /* Walk the 8 KB framebuffer two pixels at a time. Each framebuffer
     * nibble indexes into the screen palette (16 bytes at 0x5f10).
     * Each screen palette entry is an 8-bit system-palette index:
     * PICO-8 masks it with 0x8f (docs say: "indices are masked with
     * 0x8f"), so bit 7 selects the secret palette range (128..143)
     * while bits 0..3 pick within the 16-color group. Bits 4..6 are
     * ignored. */
    const uint8_t *src = &m->mem[P8_FB_BASE];
    const uint8_t *spal = &m->mem[P8_DS_SCREEN_PAL];
    const uint16_t *pal565 = m->rgb565_palette;

    for (int i = 0; i < P8_FB_BYTES; i++) {
        uint8_t b = src[i];
        /* Map spal entry (masked to 0x8f) to our 0..31 layout:
         * bit 7 set → secret palette at offset 16. */
        uint8_t s_lo = spal[b & 0x0f] & 0x8f;
        uint8_t s_hi = spal[(b >> 4) & 0x0f] & 0x8f;
        uint8_t lo = (s_lo & 0x0f) | ((s_lo & 0x80) >> 3);  /* 0..15 or 16..31 */
        uint8_t hi = (s_hi & 0x0f) | ((s_hi & 0x80) >> 3);
        dst[i * 2 + 0] = pal565[lo];
        dst[i * 2 + 1] = pal565[hi];
    }
}
