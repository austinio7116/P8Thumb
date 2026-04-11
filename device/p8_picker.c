/*
 * ThumbyP8 — single-cart-per-page picker UI.
 *
 * One cart fills the screen as a full 128×128 PNG label (no scaling
 * needed — the cart's label area is already 128×128). Title and
 * pagination overlay on top/bottom in a translucent bar.
 *
 * Navigation:
 *   ← / →   prev / next cart
 *   A / X   launch
 */
#include "p8_picker.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pico/stdlib.h"
#include "ff.h"
#include "p8_draw.h"
#include "p8_font.h"
#include "p8_machine.h"
#include "p8_p8png.h"
#include "p8_buttons.h"
#include "p8_log.h"
#include "p8_bmp.h"

/* --- filesystem helpers --------------------------------------------- */

int p8_picker_scan(p8_cart_entry *out, int max) {
    DIR dir;
    FILINFO info;
    if (f_opendir(&dir, "/carts") != FR_OK) {
        f_mkdir("/carts");
        if (f_opendir(&dir, "/carts") != FR_OK) return 0;
    }
    int n = 0;
    while (n < max && f_readdir(&dir, &info) == FR_OK) {
        if (info.fname[0] == 0) break;
        if (info.fattrib & AM_DIR) continue;
        size_t L = strlen(info.fname);
        /* Scan for .luac files — the precompiled bytecode. The .rom
         * and .bmp siblings are loaded by replacing the extension. */
        if (L < 5) continue;
        if (strcasecmp(info.fname + L - 5, ".luac") != 0) continue;
        strncpy(out[n].name, info.fname, P8_PICKER_NAME_MAX - 1);
        out[n].name[P8_PICKER_NAME_MAX - 1] = 0;
        n++;
    }
    f_closedir(&dir);
    return n;
}

unsigned char *p8_picker_load_cart(const char *name, size_t *out_len) {
    char path[80];
    snprintf(path, sizeof(path), "/carts/%s", name);
    FIL f;
    if (f_open(&f, path, FA_READ) != FR_OK) return NULL;
    FSIZE_t sz = f_size(&f);
    if (sz == 0 || sz > 200 * 1024) { f_close(&f); return NULL; }
    unsigned char *buf = (unsigned char *)malloc((size_t)sz);
    if (!buf) { f_close(&f); return NULL; }
    UINT br;
    if (f_read(&f, buf, (UINT)sz, &br) != FR_OK || br != sz) {
        free(buf); f_close(&f); return NULL;
    }
    f_close(&f);
    if (out_len) *out_len = (size_t)sz;
    return buf;
}

/* --- thumbnail rendering -------------------------------------------- */

/* Cheap nearest-color match against the 16-entry PICO-8 RGB565 palette.
 * Exposed (non-static) so the staged loader in p8_picker_run() can
 * use it directly without going through paint_full_thumbnail(). */
int rgb565_to_p8_color(uint16_t c, const uint16_t *pal) {
    int r = ((c >> 11) & 0x1f) << 3;
    int g = ((c >> 5)  & 0x3f) << 2;
    int b =  (c        & 0x1f) << 3;
    int best = 0;
    int best_d = 1 << 30;
    for (int i = 0; i < 16; i++) {
        uint16_t p = pal[i];
        int pr = ((p >> 11) & 0x1f) << 3;
        int pg = ((p >> 5)  & 0x3f) << 2;
        int pb =  (p        & 0x1f) << 3;
        int dr = r - pr, dg = g - pg, db = b - pb;
        int d  = dr*dr + dg*dg + db*db;
        if (d < best_d) { best_d = d; best = i; }
    }
    return best;
}

/* Decode the cart's PNG label and write it 1:1 into the framebuffer
 * via PICO-8 palette quantization. Returns 1 on success. */
static int paint_full_thumbnail(p8_machine *m, const char *cart_name) {
    size_t len = 0;
    unsigned char *cart = p8_picker_load_cart(cart_name, &len);
    if (!cart) return 0;
    uint16_t *thumb = (uint16_t *)malloc(128 * 128 * sizeof(uint16_t));
    if (!thumb) return 0;
    int rc = p8_p8png_decode_thumbnail(cart, len, thumb);
    free(cart);
    if (rc != 0) { free(thumb); return 0; }
    for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
            int pi = rgb565_to_p8_color(thumb[y * 128 + x], m->rgb565_palette);
            p8_pset(m, x, y, pi);
        }
    }
    free(thumb);
    return 1;
}

/* --- main picker loop ----------------------------------------------- */

int p8_picker_run(p8_machine *m, p8_input *in, uint16_t *scanline,
                   const p8_cart_entry *entries, int n_entries) {
    if (n_entries <= 0) return -1;
    int sel = 0;
    int dirty = 1;       /* repaint when sel changes — saves PNG decode every frame */

    while (1) {
        p8_input_begin_frame(in, p8_buttons_read());

        if (p8_btnp(in, P8_BTN_LEFT)) {
            sel = (sel - 1 + n_entries) % n_entries;
            dirty = 1;
        }
        if (p8_btnp(in, P8_BTN_RIGHT)) {
            sel = (sel + 1) % n_entries;
            dirty = 1;
        }
        if (p8_btnp(in, P8_BTN_X) || p8_btnp(in, P8_BTN_O)) {
            return sel;
        }

        if (dirty) {
            /* Build the .bmp thumbnail filename next to the .p8 */
            char bmp_name[P8_PICKER_NAME_MAX];
            strncpy(bmp_name, entries[sel].name, sizeof(bmp_name) - 1);
            bmp_name[sizeof(bmp_name) - 1] = 0;
            size_t L = strlen(bmp_name);
            if (L >= 5 && strcasecmp(bmp_name + L - 5, ".luac") == 0) {
                bmp_name[L - 5] = 0;
            }
            strncat(bmp_name, ".bmp",
                    sizeof(bmp_name) - strlen(bmp_name) - 1);

            p8_camera(m, 0, 0);
            p8_cls(m, 1);

            /* Try to load and paint the BMP thumbnail. If absent or
             * malformed, just show a placeholder. */
            size_t bmp_len = 0;
            unsigned char *bmp_bytes = p8_picker_load_cart(bmp_name, &bmp_len);
            int painted = 0;
            if (bmp_bytes) {
                /* Dynamically allocated so it returns to the heap
                 * when the picker exits — saves 32 KB of BSS that
                 * would otherwise be wasted during gameplay. */
                uint16_t *thumb = (uint16_t *)malloc(128 * 128 * sizeof(uint16_t));
                if (thumb && p8_bmp_load_128(bmp_bytes, bmp_len, thumb) == 0) {
                    for (int y = 0; y < 128; y++) {
                        for (int x = 0; x < 128; x++) {
                            int pi = rgb565_to_p8_color(
                                thumb[y * 128 + x], m->rgb565_palette);
                            p8_pset(m, x, y, pi);
                        }
                    }
                    painted = 1;
                }
                if (thumb) free(thumb);
                free(bmp_bytes);
            }
            if (!painted) {
                p8_font_draw(m, "no preview", 32, 56, 7);
            }

            /* Title bar overlay */
            p8_rectfill(m, 0, 0, 127, 7, 0);
            char counter[16];
            snprintf(counter, sizeof(counter), "%d/%d", sel + 1, n_entries);
            p8_font_draw(m, counter, 2, 2, 7);

            /* Bottom bar: cart name (strip .p8) */
            p8_rectfill(m, 0, 119, 127, 127, 0);
            char display[P8_PICKER_NAME_MAX];
            strncpy(display, entries[sel].name, sizeof(display) - 1);
            display[sizeof(display) - 1] = 0;
            size_t dL = strlen(display);
            if (dL >= 5 && strcasecmp(display + dL - 5, ".luac") == 0) {
                display[dL - 5] = 0;
                dL -= 5;
            }
            int text_px = (int)dL * P8_FONT_CELL_W;
            int xp = (128 - text_px) / 2;
            if (xp < 1) xp = 1;
            p8_font_draw(m, display, xp, 121, 7);
            if (n_entries > 1) {
                p8_font_draw(m, "<", 0,   121, 6);
                p8_font_draw(m, ">", 124, 121, 6);
            }

            p8_machine_present(m, scanline);
            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
            dirty = 0;
        }

        sleep_ms(16);
    }
}
