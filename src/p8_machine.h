/*
 * ThumbyP8 — fantasy console "machine" state
 *
 * Mirrors the documented PICO-8 memory map. Single 64 KB byte
 * array; everything else is offsets into it. This is deliberate:
 * peek/poke, the framebuffer, sprite sheet, map, and the draw
 * state are all just regions of `mem`.
 *
 *  0x0000–0x0fff   sprite sheet (gfx) — 128×128 4bpp = 8 KB
 *  0x1000–0x1fff   shared lower-half map (overlaps gfx)
 *  0x2000–0x2fff   upper-half map
 *  0x3000–0x30ff   sprite flags (gff) — 256 bytes
 *  0x3100–0x31ff   music — 256 bytes (Phase 4)
 *  0x3200–0x42ff   sfx — 4352 bytes  (Phase 4)
 *  0x4300–0x5dff   user data
 *  0x5e00–0x5eff   persistent cart data (Phase 6)
 *  0x5f00–0x5fff   draw state / hardware regs
 *  0x6000–0x7fff   framebuffer — 128×128 4bpp = 8 KB
 *  0x8000–0xffff   general RAM
 *
 * Phase 1+2 only touches gfx, gff, map, draw state, and framebuffer.
 */
#ifndef THUMBYP8_MACHINE_H
#define THUMBYP8_MACHINE_H

#include <stdint.h>
#include <stddef.h>

#define P8_MEM_SIZE      0x10000
#define P8_GFX_BASE      0x0000
#define P8_MAP_BASE      0x1000   /* lower half (shared with gfx 0x1000–0x1fff) */
#define P8_GFF_BASE      0x3000   /* sprite flags */
#define P8_DRAWSTATE     0x5f00
#define P8_FB_BASE       0x6000

#define P8_SCREEN_W      128
#define P8_SCREEN_H      128
#define P8_FB_BYTES      (128 * 128 / 2)   /* 4bpp */

#define P8_MAP_W         128
#define P8_MAP_H         64

/* Draw-state offsets within 0x5f00 (subset we actually use) */
#define P8_DS_DRAW_PAL   (P8_DRAWSTATE + 0x00)  /* 16 bytes: draw palette remap */
#define P8_DS_SCREEN_PAL (P8_DRAWSTATE + 0x10)  /* 16 bytes: screen palette */
#define P8_DS_CLIP_X0    (P8_DRAWSTATE + 0x20)
#define P8_DS_CLIP_Y0    (P8_DRAWSTATE + 0x21)
#define P8_DS_CLIP_X1    (P8_DRAWSTATE + 0x22)
#define P8_DS_CLIP_Y1    (P8_DRAWSTATE + 0x23)
#define P8_DS_PEN        (P8_DRAWSTATE + 0x25)
#define P8_DS_CURSOR_X   (P8_DRAWSTATE + 0x26)
#define P8_DS_CURSOR_Y   (P8_DRAWSTATE + 0x27)
#define P8_DS_CAMERA_X   (P8_DRAWSTATE + 0x28)  /* int16 LE */
#define P8_DS_CAMERA_Y   (P8_DRAWSTATE + 0x2a)  /* int16 LE */
#define P8_DS_FILLPAT_LO (P8_DRAWSTATE + 0x31)  /* fill pattern byte 0 (rows 2-3) */
#define P8_DS_FILLPAT_HI (P8_DRAWSTATE + 0x32)  /* fill pattern byte 1 (rows 0-1) */
#define P8_DS_FILLPAT_T  (P8_DRAWSTATE + 0x33)  /* fill pattern transparency (bit 0) */
#define P8_DS_TLINE_W    (P8_DRAWSTATE + 0x38)  /* tline map width (0 = 256) */
#define P8_DS_TLINE_H    (P8_DRAWSTATE + 0x39)  /* tline map height (0 = 256) */
#define P8_DS_TLINE_X    (P8_DRAWSTATE + 0x3a)  /* tline map x offset */
#define P8_DS_TLINE_Y    (P8_DRAWSTATE + 0x3b)  /* tline map y offset */
/* Elapsed time since cart start, in milliseconds. uint32 LE.
 * Updated by the host/device runner each frame from a real timer. */
#define P8_DS_ELAPSED_MS (P8_DRAWSTATE + 0x3c)  /* 4 bytes */

/* Size of the cart ROM image — sprite sheet, map, sprite flags,
 * music/sfx sections. Anything above 0x4300 is runtime state. */
#define P8_ROM_SIZE 0x4300

typedef struct p8_machine {
    uint8_t mem[P8_MEM_SIZE];

    /* Frame counter — incremented by host/device runner each frame.
     * Used by srand() with no arg. Stored outside mem[] because
     * 0x5f34..0x5f37 is reserved for PICO-8 GFX flags (carts poke
     * bit 1 of 0x5f34 for inverted-circle mode, etc.). */
    uint32_t frame_count;

    /* Pointer to the original cart ROM, preserved for reload().
     * On device, this points into XIP flash (zero SRAM cost). On
     * host, it points to a malloc'd copy. NULL = no ROM loaded (
     * reload() becomes a no-op). */
    const uint8_t *rom;
    size_t         rom_len;

    /* PICO-8's 32-color system palette as RGB565. Indices 0..15 are
     * the official base colors, 128..143 are the secret palette.
     * Layout: [0..15] = base, [16..31] = secret (offset by -112 from
     * the 128..143 indices). See p8_machine_present() for the lookup:
     * a screen palette entry with bit 7 set maps to the secret range. */
    uint16_t rgb565_palette[32];
} p8_machine;

void p8_machine_reset(p8_machine *m);

/* --- draw state convenience accessors ---------------------------------- */
static inline int16_t p8_camera_x(const p8_machine *m) {
    return (int16_t)(m->mem[P8_DS_CAMERA_X] | (m->mem[P8_DS_CAMERA_X + 1] << 8));
}
static inline int16_t p8_camera_y(const p8_machine *m) {
    return (int16_t)(m->mem[P8_DS_CAMERA_Y] | (m->mem[P8_DS_CAMERA_Y + 1] << 8));
}
static inline void p8_set_camera(p8_machine *m, int16_t x, int16_t y) {
    m->mem[P8_DS_CAMERA_X]     = (uint8_t)(x & 0xff);
    m->mem[P8_DS_CAMERA_X + 1] = (uint8_t)((x >> 8) & 0xff);
    m->mem[P8_DS_CAMERA_Y]     = (uint8_t)(y & 0xff);
    m->mem[P8_DS_CAMERA_Y + 1] = (uint8_t)((y >> 8) & 0xff);
}

static inline uint8_t p8_pen(const p8_machine *m) { return m->mem[P8_DS_PEN]; }
/* Pen stores the full byte — low nibble is primary color, high nibble
 * is secondary color for fill patterns. */
static inline void    p8_set_pen(p8_machine *m, uint8_t c) { m->mem[P8_DS_PEN] = c; }

/* Apply the draw palette remap (used by drawing primitives). */
static inline uint8_t p8_draw_remap(const p8_machine *m, uint8_t c) {
    return m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] & 0x0f;
}

/* --- framebuffer pixel access ----------------------------------------- */
/* Both treat (x,y) as raw screen coordinates AFTER camera/clip handling. */
static inline void p8_fb_pset_raw(p8_machine *m, int x, int y, uint8_t c) {
    /* assumes 0 <= x < 128, 0 <= y < 128 */
    int addr = P8_FB_BASE + (y << 6) + (x >> 1);
    uint8_t b = m->mem[addr];
    if (x & 1) {
        m->mem[addr] = (b & 0x0f) | ((c & 0x0f) << 4);
    } else {
        m->mem[addr] = (b & 0xf0) | (c & 0x0f);
    }
}
static inline uint8_t p8_fb_pget_raw(const p8_machine *m, int x, int y) {
    int addr = P8_FB_BASE + (y << 6) + (x >> 1);
    uint8_t b = m->mem[addr];
    return (x & 1) ? (b >> 4) : (b & 0x0f);
}

/* --- sprite sheet pixel access (4bpp, same layout as fb) -------------- */
static inline uint8_t p8_sget(const p8_machine *m, int x, int y) {
    if ((unsigned)x >= 128 || (unsigned)y >= 128) return 0;
    int addr = P8_GFX_BASE + (y << 6) + (x >> 1);
    uint8_t b = m->mem[addr];
    return (x & 1) ? (b >> 4) : (b & 0x0f);
}
static inline void p8_sset(p8_machine *m, int x, int y, uint8_t c) {
    if ((unsigned)x >= 128 || (unsigned)y >= 128) return;
    int addr = P8_GFX_BASE + (y << 6) + (x >> 1);
    uint8_t b = m->mem[addr];
    if (x & 1) m->mem[addr] = (b & 0x0f) | ((c & 0x0f) << 4);
    else       m->mem[addr] = (b & 0xf0) | (c & 0x0f);
}

/* --- expand 4bpp framebuffer into RGB565 scanline buffer -------------- */
/* dst must hold 128*128 uint16_t. */
void p8_machine_present(const p8_machine *m, uint16_t *dst);

#endif /* THUMBYP8_MACHINE_H */
