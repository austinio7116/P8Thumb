/*
 * ThumbyP8 — drawing primitives implementation.
 *
 * Pixel hot path is `pset_clipped()`. Everything else (lines,
 * rects, circles, sprites, map) reduces to it. We deliberately
 * keep this simple — Phase 1+2 wants visible-and-correct first,
 * then we'll inline + viper-port the hot loops in a later pass.
 */
#include "p8_draw.h"
#include <math.h>
#include <stdint.h>

/* --- low-level pixel ops with camera + clip + draw palette ----------- */

/* Returns 1 if (sx,sy) is inside the clip rect. sx/sy are screen coords. */
static inline int in_clip(const p8_machine *m, int sx, int sy) {
    int x0 = m->mem[P8_DS_CLIP_X0];
    int y0 = m->mem[P8_DS_CLIP_Y0];
    int x1 = m->mem[P8_DS_CLIP_X1];
    int y1 = m->mem[P8_DS_CLIP_Y1];
    return sx >= x0 && sy >= y0 && sx < x1 && sy < y1
        && sx >= 0 && sy >= 0 && sx < P8_SCREEN_W && sy < P8_SCREEN_H;
}

/* Apply fillp pattern at screen position (sx, sy). Color arg `c` may
 * pack two colors: low nibble = primary (col0), high nibble = secondary
 * (col1). If pattern bit is 1 at this pixel, use col1 (or skip if
 * transparency flag is set). Returns -1 if pixel should be skipped,
 * otherwise returns the final color (0..15). */
static inline int resolve_fillp(const p8_machine *m, int sx, int sy, int c) {
    uint16_t pat = (uint16_t)m->mem[P8_DS_FILLPAT_LO]
                 | ((uint16_t)m->mem[P8_DS_FILLPAT_HI] << 8);
    if (pat == 0) return c & 0x0f;  /* no pattern: use primary */

    /* Bit 15 = pixel (0,0), bit 0 = pixel (3,3) */
    int bit = 15 - ((sx & 3) + 4 * (sy & 3));
    int alt = (pat >> bit) & 1;
    if (alt) {
        if (m->mem[P8_DS_FILLPAT_T] & 1) return -1;  /* transparent */
        return (c >> 4) & 0x0f;  /* secondary */
    }
    return c & 0x0f;  /* primary */
}

/* Plot at world (cart) coordinates with the given color. Applies
 * camera offset, clip rect, fill pattern, and draw palette remap. */
static inline void pset_world(p8_machine *m, int x, int y, int c) {
    int sx = x - p8_camera_x(m);
    int sy = y - p8_camera_y(m);
    if (!in_clip(m, sx, sy)) return;
    int col = resolve_fillp(m, sx, sy, c);
    if (col < 0) return;
    /* low nibble = remapped color; high bit of pal entry = transparent
     * (only used by sprite blit, ignored here). */
    uint8_t mapped = m->mem[P8_DS_DRAW_PAL + (col & 0x0f)] & 0x0f;
    p8_fb_pset_raw(m, sx, sy, mapped);
}

/* Plot at *screen* coordinates (used by sprite blit, which already
 * baked the camera transform). Still applies clip + draw palette.
 * Does NOT apply fill pattern — sprites don't use fillp. */
static inline void pset_screen_remapped(p8_machine *m, int sx, int sy, int c) {
    if (!in_clip(m, sx, sy)) return;
    uint8_t mapped = m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] & 0x0f;
    p8_fb_pset_raw(m, sx, sy, mapped);
}

/* --- public primitives ----------------------------------------------- */

void p8_cls(p8_machine *m, int c) {
    uint8_t cc = (uint8_t)(c & 0x0f);
    uint8_t byte = (uint8_t)(cc | (cc << 4));
    memset(&m->mem[P8_FB_BASE], byte, P8_FB_BYTES);
    m->mem[P8_DS_CURSOR_X] = 0;
    m->mem[P8_DS_CURSOR_Y] = 0;
}

void p8_pset(p8_machine *m, int x, int y, int c) {
    /* Pen stores both nibbles (primary + secondary for fill patterns). */
    p8_set_pen(m, (uint8_t)(c & 0xff));
    pset_world(m, x, y, c);
}

int p8_pget(const p8_machine *m, int x, int y) {
    int sx = x - p8_camera_x(m);
    int sy = y - p8_camera_y(m);
    if ((unsigned)sx >= P8_SCREEN_W || (unsigned)sy >= P8_SCREEN_H) return 0;
    return p8_fb_pget_raw(m, sx, sy);
}

void p8_color(p8_machine *m, int c) {
    p8_set_pen(m, (uint8_t)(c & 0xff));
}

void p8_camera(p8_machine *m, int x, int y) {
    p8_set_camera(m, (int16_t)x, (int16_t)y);
}

void p8_clip(p8_machine *m, int x, int y, int w, int h, int reset) {
    if (reset) {
        m->mem[P8_DS_CLIP_X0] = 0;
        m->mem[P8_DS_CLIP_Y0] = 0;
        m->mem[P8_DS_CLIP_X1] = P8_SCREEN_W;
        m->mem[P8_DS_CLIP_Y1] = P8_SCREEN_H;
        return;
    }
    int x0 = x < 0 ? 0 : (x > 128 ? 128 : x);
    int y0 = y < 0 ? 0 : (y > 128 ? 128 : y);
    int x1 = x + w; if (x1 < 0) x1 = 0; if (x1 > 128) x1 = 128;
    int y1 = y + h; if (y1 < 0) y1 = 0; if (y1 > 128) y1 = 128;
    m->mem[P8_DS_CLIP_X0] = (uint8_t)x0;
    m->mem[P8_DS_CLIP_Y0] = (uint8_t)y0;
    m->mem[P8_DS_CLIP_X1] = (uint8_t)x1;
    m->mem[P8_DS_CLIP_Y1] = (uint8_t)y1;
}

/* pal(c0,c1,p): remap color c0 → c1 in palette p (0=draw, 1=screen).
 * Phase 1+2 supports both. With no args (c0<0), reset palette. */
void p8_pal_set(p8_machine *m, int c0, int c1, int p) {
    if (p == 1) {
        /* Screen palette: full 8-bit index (masked to 0x8f per spec).
         * Bit 7 selects the secret palette; bits 0-3 pick within. */
        m->mem[P8_DS_SCREEN_PAL + (c0 & 0x0f)] = (uint8_t)(c1 & 0x8f);
    } else {
        /* Draw palette: preserve transparency bit (0x10), overwrite
         * low nibble. Draw palette can only pick from the 16 screen
         * palette slots, so only the low nibble is meaningful. */
        uint8_t old = m->mem[P8_DS_DRAW_PAL + (c0 & 0x0f)];
        m->mem[P8_DS_DRAW_PAL + (c0 & 0x0f)] = (uint8_t)((old & 0xf0) | (c1 & 0x0f));
    }
}

void p8_palt(p8_machine *m, int c, int t) {
    if (t) m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] |= 0x10;
    else   m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] &= ~0x10;
}

void p8_pal_reset(p8_machine *m) {
    for (int i = 0; i < 16; i++) {
        m->mem[P8_DS_DRAW_PAL + i]   = (uint8_t)i;
        m->mem[P8_DS_SCREEN_PAL + i] = (uint8_t)i;
    }
    m->mem[P8_DS_DRAW_PAL + 0] |= 0x10;  /* color 0 transparent */
}

/* fillp(pat, transparency) — set the 16-bit fill pattern and
 * transparency flag. Bits are tested per-pixel: bit 15 = top-left
 * pixel (0,0), bit 0 = bottom-right (3,3). */
void p8_fillp(p8_machine *m, int pattern, int transparent) {
    m->mem[P8_DS_FILLPAT_LO] = (uint8_t)(pattern & 0xff);
    m->mem[P8_DS_FILLPAT_HI] = (uint8_t)((pattern >> 8) & 0xff);
    m->mem[P8_DS_FILLPAT_T]  = (uint8_t)(transparent & 1);
}

/* --- line: classic Bresenham ----------------------------------------- */
void p8_line(p8_machine *m, int x0, int y0, int x1, int y1, int c) {
    p8_set_pen(m, (uint8_t)(c & 0xff));
    int dx =  (x1 > x0) ? (x1 - x0) : (x0 - x1);
    int dy = -((y1 > y0) ? (y1 - y0) : (y0 - y1));
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    int x = x0, y = y0;
    for (;;) {
        pset_world(m, x, y, c);
        if (x == x1 && y == y1) break;
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x += sx; }
        if (e2 <= dx) { err += dx; y += sy; }
    }
}

/* --- rect: outline only ---------------------------------------------- */
void p8_rect(p8_machine *m, int x0, int y0, int x1, int y1, int c) {
    if (x1 < x0) { int t = x0; x0 = x1; x1 = t; }
    if (y1 < y0) { int t = y0; y0 = y1; y1 = t; }
    for (int x = x0; x <= x1; x++) {
        pset_world(m, x, y0, c);
        pset_world(m, x, y1, c);
    }
    for (int y = y0 + 1; y < y1; y++) {
        pset_world(m, x0, y, c);
        pset_world(m, x1, y, c);
    }
}

void p8_rectfill(p8_machine *m, int x0, int y0, int x1, int y1, int c) {
    if (x1 < x0) { int t = x0; x0 = x1; x1 = t; }
    if (y1 < y0) { int t = y0; y0 = y1; y1 = t; }

    /* Pre-clip to visible region */
    int camx = p8_camera_x(m), camy = p8_camera_y(m);
    int sx0 = x0 - camx, sy0 = y0 - camy;
    int sx1 = x1 - camx, sy1 = y1 - camy;
    int cx0 = m->mem[P8_DS_CLIP_X0], cy0 = m->mem[P8_DS_CLIP_Y0];
    int cx1 = m->mem[P8_DS_CLIP_X1], cy1 = m->mem[P8_DS_CLIP_Y1];
    if (sx0 < cx0) sx0 = cx0;  if (sy0 < cy0) sy0 = cy0;
    if (sx1 >= cx1) sx1 = cx1 - 1;  if (sy1 >= cy1) sy1 = cy1 - 1;
    if (sx0 < 0) sx0 = 0;  if (sy0 < 0) sy0 = 0;
    if (sx1 >= P8_SCREEN_W) sx1 = P8_SCREEN_W - 1;
    if (sy1 >= P8_SCREEN_H) sy1 = P8_SCREEN_H - 1;
    if (sx0 > sx1 || sy0 > sy1) return;

    /* Check for fill pattern */
    uint16_t pat = (uint16_t)m->mem[P8_DS_FILLPAT_LO]
                 | ((uint16_t)m->mem[P8_DS_FILLPAT_HI] << 8);

    uint8_t *fb = &m->mem[P8_FB_BASE];

    if (pat == 0) {
        /* No pattern — solid fill. Apply draw palette once. */
        uint8_t mapped = m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] & 0x0f;
        for (int sy = sy0; sy <= sy1; sy++) {
            int row = sy << 6;
            for (int sx = sx0; sx <= sx1; sx++) {
                int addr = row + (sx >> 1);
                if (sx & 1)
                    fb[addr] = (fb[addr] & 0x0f) | (mapped << 4);
                else
                    fb[addr] = (fb[addr] & 0xf0) | mapped;
            }
        }
    } else {
        /* With pattern — per-pixel fillp check. */
        uint8_t col0 = m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] & 0x0f;
        uint8_t col1 = m->mem[P8_DS_DRAW_PAL + ((c >> 4) & 0x0f)] & 0x0f;
        int transp = m->mem[P8_DS_FILLPAT_T] & 1;
        for (int sy = sy0; sy <= sy1; sy++) {
            int row = sy << 6;
            for (int sx = sx0; sx <= sx1; sx++) {
                int bit = 15 - ((sx & 3) + 4 * (sy & 3));
                int alt = (pat >> bit) & 1;
                uint8_t mapped;
                if (alt) {
                    if (transp) continue;
                    mapped = col1;
                } else {
                    mapped = col0;
                }
                int addr = row + (sx >> 1);
                if (sx & 1)
                    fb[addr] = (fb[addr] & 0x0f) | (mapped << 4);
                else
                    fb[addr] = (fb[addr] & 0xf0) | mapped;
            }
        }
    }
}

/* --- circle: midpoint algorithm -------------------------------------- */
static inline void circ_octants(p8_machine *m, int cx, int cy, int x, int y, int c) {
    pset_world(m, cx + x, cy + y, c);
    pset_world(m, cx - x, cy + y, c);
    pset_world(m, cx + x, cy - y, c);
    pset_world(m, cx - x, cy - y, c);
    pset_world(m, cx + y, cy + x, c);
    pset_world(m, cx - y, cy + x, c);
    pset_world(m, cx + y, cy - x, c);
    pset_world(m, cx - y, cy - x, c);
}

void p8_circ(p8_machine *m, int cx, int cy, int r, int c) {
    if (r < 0) return;
    if (r == 0) { p8_pset(m, cx, cy, c); return; }
    int x = r, y = 0, err = 1 - r;
    while (x >= y) {
        circ_octants(m, cx, cy, x, y, c);
        y++;
        if (err < 0) err += 2 * y + 1;
        else { x--; err += 2 * (y - x) + 1; }
    }
}

/* rrect / rrectfill — rounded rectangle. Corners are quarter-circles
 * of radius r. The radius is clamped to min(w,h)/2.
 *
 * At row y within the corner region (0..r-1), the cut (number of
 * pixels removed from each side) is:
 *   cut = r - floor(sqrt(r² - (r - y)²))
 *
 * The arc's center is at (r, r) from the outside corner, so the arc
 * "bulges outward" — at y=0, the whole corner box is cut (cut=r),
 * and at y=r-1 only ~1 pixel is cut. */
static int rrect_cut_amount(int r, int row_from_outside) {
    if (r <= 0) return 0;
    /* b = distance from arc center to this row */
    int b = r - row_from_outside;
    /* max x-offset from arc center such that x² + b² <= r² */
    int rr = r * r;
    int a = 0;
    while ((a + 1) * (a + 1) + b * b <= rr) a++;
    return r - a;
}

void p8_rrectfill(p8_machine *m, int x, int y, int w, int h, int r, int c) {
    if (w <= 0 || h <= 0) return;
    int max_r = (w < h ? w : h) / 2;
    if (r > max_r) r = max_r;
    if (r <= 0) {
        p8_rectfill(m, x, y, x + w - 1, y + h - 1, c);
        return;
    }
    for (int row = 0; row < h; row++) {
        int cut = 0;
        if (row < r) {
            cut = rrect_cut_amount(r, row);
        } else if (row >= h - r) {
            cut = rrect_cut_amount(r, h - 1 - row);
        }
        if (cut < 0) cut = 0;
        if (cut * 2 >= w) cut = (w - 1) / 2;
        int xl = x + cut;
        int xr = x + w - 1 - cut;
        for (int xi = xl; xi <= xr; xi++) {
            pset_world(m, xi, y + row, c);
        }
    }
}

void p8_rrect(p8_machine *m, int x, int y, int w, int h, int r, int c) {
    if (w <= 0 || h <= 0) return;
    int max_r = (w < h ? w : h) / 2;
    if (r > max_r) r = max_r;
    if (r <= 0) {
        p8_rect(m, x, y, x + w - 1, y + h - 1, c);
        return;
    }
    /* Top and bottom straight edges (between the corners) */
    for (int xi = x + r; xi <= x + w - 1 - r; xi++) {
        pset_world(m, xi, y, c);
        pset_world(m, xi, y + h - 1, c);
    }
    /* Left and right straight edges (between the corners) */
    for (int yi = y + r; yi <= y + h - 1 - r; yi++) {
        pset_world(m, x, yi, c);
        pset_world(m, x + w - 1, yi, c);
    }
    /* Corner outlines: for each corner row, draw the two boundary
     * pixels (at x = cut and at the horizontal step where cut drops
     * to the previous row's value). */
    int prev_cut = r;  /* above row 0, effectively cut = r (nothing drawn) */
    for (int row = 0; row < r; row++) {
        int cut = rrect_cut_amount(r, row);
        if (cut < 0) cut = 0;
        if (cut >= w / 2) continue;  /* corners meet; nothing to draw */
        /* Pixel at the current row's edge */
        pset_world(m, x + cut, y + row, c);
        pset_world(m, x + w - 1 - cut, y + row, c);
        pset_world(m, x + cut, y + h - 1 - row, c);
        pset_world(m, x + w - 1 - cut, y + h - 1 - row, c);
        /* Horizontal step pixels between prev_cut (exclusive) and cut (exclusive) */
        for (int xi = cut + 1; xi < prev_cut; xi++) {
            pset_world(m, x + xi, y + row, c);
            pset_world(m, x + w - 1 - xi, y + row, c);
            pset_world(m, x + xi, y + h - 1 - row, c);
            pset_world(m, x + w - 1 - xi, y + h - 1 - row, c);
        }
        prev_cut = cut;
    }
}

void p8_circfill(p8_machine *m, int cx, int cy, int r, int c) {
    if (r < 0) return;
    if (r == 0) { pset_world(m, cx, cy, c); return; }

    int camx = p8_camera_x(m), camy = p8_camera_y(m);
    int clip_x0 = m->mem[P8_DS_CLIP_X0], clip_y0 = m->mem[P8_DS_CLIP_Y0];
    int clip_x1 = m->mem[P8_DS_CLIP_X1], clip_y1 = m->mem[P8_DS_CLIP_Y1];

    /* Check for fill pattern */
    uint16_t pat = (uint16_t)m->mem[P8_DS_FILLPAT_LO]
                 | ((uint16_t)m->mem[P8_DS_FILLPAT_HI] << 8);
    uint8_t col0 = m->mem[P8_DS_DRAW_PAL + (c & 0x0f)] & 0x0f;
    uint8_t col1 = m->mem[P8_DS_DRAW_PAL + ((c >> 4) & 0x0f)] & 0x0f;
    int transp = m->mem[P8_DS_FILLPAT_T] & 1;
    uint8_t *fb = &m->mem[P8_FB_BASE];

    for (int dy = -r; dy <= r; dy++) {
        int sy = (cy + dy) - camy;
        if (sy < clip_y0 || sy >= clip_y1 || sy < 0 || sy >= P8_SCREEN_H) continue;

        int rr = r * r - dy * dy;
        int dx = 0;
        while ((dx + 1) * (dx + 1) <= rr) dx++;

        int x0 = (cx - dx) - camx;
        int x1 = (cx + dx) - camx;
        if (x0 < clip_x0) x0 = clip_x0;
        if (x1 >= clip_x1) x1 = clip_x1 - 1;
        if (x0 < 0) x0 = 0;
        if (x1 >= P8_SCREEN_W) x1 = P8_SCREEN_W - 1;

        int fb_row = sy << 6;
        for (int sx = x0; sx <= x1; sx++) {
            uint8_t mapped;
            if (pat != 0) {
                int bit = 15 - ((sx & 3) + 4 * (sy & 3));
                if ((pat >> bit) & 1) {
                    if (transp) continue;
                    mapped = col1;
                } else {
                    mapped = col0;
                }
            } else {
                mapped = col0;
            }
            int faddr = fb_row + (sx >> 1);
            if (sx & 1)
                fb[faddr] = (fb[faddr] & 0x0f) | (mapped << 4);
            else
                fb[faddr] = (fb[faddr] & 0xf0) | mapped;
        }
    }
}

/* --- sprite blit ----------------------------------------------------- */
/* Pulls 8×8 cells from the sprite sheet at (n*8 % 128, n/16 * 8). */
void p8_spr(p8_machine *m, int n, int x, int y, int w, int h, int flip_x, int flip_y) {
    if (w <= 0 || h <= 0) return;
    int sheet_x = (n & 0x0f) * 8;
    int sheet_y = (n >> 4) * 8;
    int pw = w * 8;
    int ph = h * 8;
    int dx0 = x - p8_camera_x(m);
    int dy0 = y - p8_camera_y(m);

    /* Pre-clip: compute the visible sub-rect to avoid per-pixel checks */
    int cx0 = m->mem[P8_DS_CLIP_X0];
    int cy0 = m->mem[P8_DS_CLIP_Y0];
    int cx1 = m->mem[P8_DS_CLIP_X1];
    int cy1 = m->mem[P8_DS_CLIP_Y1];

    int vis_x0 = dx0 < cx0 ? cx0 - dx0 : 0;
    int vis_y0 = dy0 < cy0 ? cy0 - dy0 : 0;
    int vis_x1 = (dx0 + pw > cx1 ? cx1 - dx0 : pw);
    int vis_y1 = (dy0 + ph > cy1 ? cy1 - dy0 : ph);
    if (vis_x0 >= vis_x1 || vis_y0 >= vis_y1) return;

    /* Screen bounds */
    if (dx0 + vis_x1 > P8_SCREEN_W) vis_x1 = P8_SCREEN_W - dx0;
    if (dy0 + vis_y1 > P8_SCREEN_H) vis_y1 = P8_SCREEN_H - dy0;
    if (dx0 + vis_x0 < 0) vis_x0 = -dx0;
    if (dy0 + vis_y0 < 0) vis_y0 = -dy0;
    if (vis_x0 >= vis_x1 || vis_y0 >= vis_y1) return;

    /* Pre-build palette LUT: pal[c] = mapped color, or 0xff = transparent. */
    uint8_t pal_lut[16];
    for (int i = 0; i < 16; i++) {
        uint8_t e = m->mem[P8_DS_DRAW_PAL + i];
        pal_lut[i] = (e & 0x10) ? 0xff : (e & 0x0f);
    }

    uint8_t *gfx = &m->mem[P8_GFX_BASE];
    uint8_t *fb  = &m->mem[P8_FB_BASE];

    for (int py = vis_y0; py < vis_y1; py++) {
        int sy = sheet_y + (flip_y ? (ph - 1 - py) : py);
        int dy = dy0 + py;
        int fb_row = dy << 6;  /* dy * 64 (128 pixels / 2 nibbles per byte) */
        int gfx_row = sy << 6;

        for (int px = vis_x0; px < vis_x1; px++) {
            int sx = sheet_x + (flip_x ? (pw - 1 - px) : px);

            /* Inline 4bpp read from sprite sheet */
            int gaddr = gfx_row + (sx >> 1);
            uint8_t col = (sx & 1) ? (gfx[gaddr] >> 4) : (gfx[gaddr] & 0x0f);

            uint8_t mapped = pal_lut[col];
            if (mapped == 0xff) continue;  /* transparent */

            /* Inline 4bpp write to framebuffer */
            int dx = dx0 + px;
            int faddr = fb_row + (dx >> 1);
            if (dx & 1) {
                fb[faddr] = (fb[faddr] & 0x0f) | (mapped << 4);
            } else {
                fb[faddr] = (fb[faddr] & 0xf0) | mapped;
            }
        }
    }
}

void p8_sspr(p8_machine *m,
             int sx, int sy, int sw, int sh,
             int dx, int dy, int dw, int dh,
             int flip_x, int flip_y) {
    if (sw <= 0 || sh <= 0 || dw <= 0 || dh <= 0) return;
    int dx0 = dx - p8_camera_x(m);
    int dy0 = dy - p8_camera_y(m);

    /* Pre-clip */
    int cx0 = m->mem[P8_DS_CLIP_X0];
    int cy0 = m->mem[P8_DS_CLIP_Y0];
    int cx1 = m->mem[P8_DS_CLIP_X1];
    int cy1 = m->mem[P8_DS_CLIP_Y1];

    int vis_x0 = dx0 < cx0 ? cx0 - dx0 : 0;
    int vis_y0 = dy0 < cy0 ? cy0 - dy0 : 0;
    int vis_x1 = dx0 + dw > cx1 ? cx1 - dx0 : dw;
    int vis_y1 = dy0 + dh > cy1 ? cy1 - dy0 : dh;
    if (dx0 + vis_x1 > P8_SCREEN_W) vis_x1 = P8_SCREEN_W - dx0;
    if (dy0 + vis_y1 > P8_SCREEN_H) vis_y1 = P8_SCREEN_H - dy0;
    if (dx0 + vis_x0 < 0) vis_x0 = -dx0;
    if (dy0 + vis_y0 < 0) vis_y0 = -dy0;
    if (vis_x0 >= vis_x1 || vis_y0 >= vis_y1) return;

    /* Pre-build palette LUT */
    uint8_t pal_lut[16];
    for (int i = 0; i < 16; i++) {
        uint8_t e = m->mem[P8_DS_DRAW_PAL + i];
        pal_lut[i] = (e & 0x10) ? 0xff : (e & 0x0f);
    }

    uint8_t *gfx = &m->mem[P8_GFX_BASE];
    uint8_t *fb  = &m->mem[P8_FB_BASE];

    /* DDA (Bresenham) stepping: avoid per-pixel integer division.
     * Use fixed-point 16.16 source coordinates that step by
     * (sw<<16)/dw per destination pixel. */
    int32_t x_step = (sw << 16) / dw;
    int32_t y_step = (sh << 16) / dh;

    for (int py = vis_y0; py < vis_y1; py++) {
        int32_t src_y_fp;
        if (flip_y)
            src_y_fp = ((int32_t)sy << 16) + (int32_t)(dh - 1 - py) * y_step;
        else
            src_y_fp = ((int32_t)sy << 16) + (int32_t)py * y_step;
        int src_y = src_y_fp >> 16;
        if ((unsigned)src_y >= 128) continue;

        int ddy = dy0 + py;
        int fb_row = ddy << 6;
        int gfx_row = src_y << 6;

        int32_t src_x_fp;
        if (flip_x)
            src_x_fp = ((int32_t)sx << 16) + (int32_t)(dw - 1 - vis_x0) * x_step;
        else
            src_x_fp = ((int32_t)sx << 16) + (int32_t)vis_x0 * x_step;
        int32_t x_inc = flip_x ? -x_step : x_step;

        for (int px = vis_x0; px < vis_x1; px++) {
            int src_x = src_x_fp >> 16;
            src_x_fp += x_inc;
            if ((unsigned)src_x >= 128) continue;

            /* Inline 4bpp read */
            int gaddr = gfx_row + (src_x >> 1);
            uint8_t col = (src_x & 1) ? (gfx[gaddr] >> 4) : (gfx[gaddr] & 0x0f);

            uint8_t mapped = pal_lut[col];
            if (mapped == 0xff) continue;

            /* Inline 4bpp write */
            int ddx = dx0 + px;
            int faddr = fb_row + (ddx >> 1);
            if (ddx & 1) {
                fb[faddr] = (fb[faddr] & 0x0f) | (mapped << 4);
            } else {
                fb[faddr] = (fb[faddr] & 0xf0) | mapped;
            }
        }
    }
}

/* --- map ------------------------------------------------------------- */
/* PICO-8 map layout: 128 cells wide × 64 cells tall. Lower 32 rows
 * live at 0x1000–0x1fff (overlapping the lower half of gfx); upper
 * 32 rows live at 0x2000–0x2fff. We model this by offset arithmetic. */
static inline int map_addr(int x, int y) {
    if ((unsigned)x >= 128 || (unsigned)y >= 64) return -1;
    if (y < 32) return 0x2000 + y * 128 + x;  /* upper rows */
    /* lower rows live in shared region, but PICO-8 indexes them after
     * the upper rows in cart layout. We mirror real PICO-8: rows
     * 32..63 live at 0x1000–0x1fff. */
    return 0x1000 + (y - 32) * 128 + x;
}

int p8_mget(const p8_machine *m, int x, int y) {
    int a = map_addr(x, y);
    return a < 0 ? 0 : m->mem[a];
}
void p8_mset(p8_machine *m, int x, int y, int v) {
    int a = map_addr(x, y);
    if (a >= 0) m->mem[a] = (uint8_t)(v & 0xff);
}

void p8_map(p8_machine *m, int cx, int cy, int sx, int sy, int cw, int ch, int layer) {
    /* Pre-build palette LUT once for all tiles */
    uint8_t pal_lut[16];
    for (int i = 0; i < 16; i++) {
        uint8_t e = m->mem[P8_DS_DRAW_PAL + i];
        pal_lut[i] = (e & 0x10) ? 0xff : (e & 0x0f);
    }

    int camx = p8_camera_x(m), camy = p8_camera_y(m);
    int clip_x0 = m->mem[P8_DS_CLIP_X0], clip_y0 = m->mem[P8_DS_CLIP_Y0];
    int clip_x1 = m->mem[P8_DS_CLIP_X1], clip_y1 = m->mem[P8_DS_CLIP_Y1];
    uint8_t *gfx = &m->mem[P8_GFX_BASE];
    uint8_t *fb  = &m->mem[P8_FB_BASE];

    for (int j = 0; j < ch; j++) {
        for (int i = 0; i < cw; i++) {
            int n = p8_mget(m, cx + i, cy + j);
            if (n == 0) continue;
            if (layer != 0) {
                int flags = m->mem[P8_GFF_BASE + n];
                if ((flags & layer) == 0) continue;
            }
            /* Inline 8×8 tile blit (no flip, w=h=1) */
            int tile_sx = (n & 0x0f) * 8;
            int tile_sy = (n >> 4) * 8;
            int dx0 = sx + i * 8 - camx;
            int dy0 = sy + j * 8 - camy;

            /* Quick reject */
            if (dx0 + 8 <= clip_x0 || dx0 >= clip_x1 ||
                dy0 + 8 <= clip_y0 || dy0 >= clip_y1 ||
                dx0 + 8 <= 0 || dx0 >= P8_SCREEN_W ||
                dy0 + 8 <= 0 || dy0 >= P8_SCREEN_H) continue;

            for (int py = 0; py < 8; py++) {
                int screen_y = dy0 + py;
                if (screen_y < clip_y0 || screen_y >= clip_y1 ||
                    screen_y < 0 || screen_y >= P8_SCREEN_H) continue;
                int gfx_row = (tile_sy + py) << 6;
                int fb_row  = screen_y << 6;
                for (int px = 0; px < 8; px++) {
                    int screen_x = dx0 + px;
                    if (screen_x < clip_x0 || screen_x >= clip_x1 ||
                        screen_x < 0 || screen_x >= P8_SCREEN_W) continue;
                    int gx = tile_sx + px;
                    int gaddr = gfx_row + (gx >> 1);
                    uint8_t col = (gx & 1) ? (gfx[gaddr] >> 4) : (gfx[gaddr] & 0x0f);
                    uint8_t mapped = pal_lut[col];
                    if (mapped == 0xff) continue;
                    int faddr = fb_row + (screen_x >> 1);
                    if (screen_x & 1)
                        fb[faddr] = (fb[faddr] & 0x0f) | (mapped << 4);
                    else
                        fb[faddr] = (fb[faddr] & 0xf0) | mapped;
                }
            }
        }
    }
}

/* tline — textured line drawing (for mode-7 floor effects).
 *
 * Walks from (x0,y0) to (x1,y1) via Bresenham. At each pixel, reads
 * texture coords (mx,my) in tile-cell units:
 *   - int(mx), int(my) + tline map offset → lookup sprite via mget
 *   - (mx fractional * 8), (my fractional * 8) → pixel within sprite
 * After each pixel, advances mx += mdx, my += mdy.
 *
 * Wraps texture coords modulo tlineMapWidth/Height (0 = 256).
 * layer: only draw from tiles with matching sprite flags (0 = all). */
void p8_tline(p8_machine *m, int x0, int y0, int x1, int y1,
              double mx, double my, double mdx, double mdy, int layer) {
    uint8_t map_w   = m->mem[P8_DS_TLINE_W];
    uint8_t map_h   = m->mem[P8_DS_TLINE_H];
    uint8_t map_x   = m->mem[P8_DS_TLINE_X];
    uint8_t map_y   = m->mem[P8_DS_TLINE_Y];
    double xmask = (map_w == 0) ? 256.0 : (double)map_w;
    double ymask = (map_h == 0) ? 256.0 : (double)map_h;

    /* Bresenham walk. At each step, sample and advance texture coords. */
    int dx =  (x1 > x0) ? (x1 - x0) : (x0 - x1);
    int dy = -((y1 > y0) ? (y1 - y0) : (y0 - y1));
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;
    int x = x0, y = y0;
    int safety = 0;
    for (;;) {
        /* Wrap texture coords */
        double wrapped_mx = mx - floor(mx / xmask) * xmask;
        double wrapped_my = my - floor(my / ymask) * ymask;
        int tx = (int)floor(wrapped_mx);
        int ty = (int)floor(wrapped_my);
        int map_cx = ((int)map_x + tx) & 0x7f;  /* map is 128 wide */
        int map_cy = ((int)map_y + ty) & 0x3f;  /* map is 64 tall */
        int spr = p8_mget(m, map_cx, map_cy);
        if (spr != 0) {
            int skip = 0;
            if (layer != 0) {
                int flags = m->mem[P8_GFF_BASE + spr];
                if ((flags & layer) == 0) skip = 1;
            }
            if (!skip) {
                /* Pixel within the sprite (8x8 cell) */
                int px = (int)floor((wrapped_mx - tx) * 8.0) & 7;
                int py = (int)floor((wrapped_my - ty) * 8.0) & 7;
                int spr_x = (spr & 0x0f) * 8 + px;
                int spr_y = (spr >> 4) * 8 + py;
                uint8_t col = p8_sget(m, spr_x, spr_y);
                /* Transparency via draw palette high bit */
                uint8_t pal_entry = m->mem[P8_DS_DRAW_PAL + (col & 0x0f)];
                if (!(pal_entry & 0x10)) {
                    /* pset_world applies camera + clip + palette + fillp */
                    pset_world(m, x, y, col);
                }
            }
        }
        if (x == x1 && y == y1) break;
        if (++safety > 1024) break;  /* safety limit */
        int e2 = 2 * err;
        if (e2 >= dy) { err += dy; x += sx; }
        if (e2 <= dx) { err += dx; y += sy; }
        mx += mdx;
        my += mdy;
    }
}

/* --- sprite flags ---------------------------------------------------- */
int p8_fget(const p8_machine *m, int n, int f) {
    if ((unsigned)n >= 256) return 0;
    uint8_t flags = m->mem[P8_GFF_BASE + n];
    if (f < 0) return flags;
    return (flags >> f) & 1;
}
void p8_fset(p8_machine *m, int n, int f, int v) {
    if ((unsigned)n >= 256) return;
    if (f < 0) {
        m->mem[P8_GFF_BASE + n] = (uint8_t)(v & 0xff);
    } else {
        uint8_t b = m->mem[P8_GFF_BASE + n];
        if (v) b |= (1 << f);
        else   b &= ~(1 << f);
        m->mem[P8_GFF_BASE + n] = b;
    }
}
