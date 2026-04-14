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
#include "p8_menu.h"
#include "p8_lcd_gc9107.h"
#include "hardware/gpio.h"
#include "ff.h"

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
    int dirty = 1;
    uint32_t menu_hold_start = 0;
    int menu_was_pressed = 0;
    static int picker_show_fps = 1;
    static int picker_volume = 15;  /* VOL_UNITY */

    while (1) {
        p8_input_begin_frame(in, p8_buttons_read());

        /* MENU long-press → settings menu (no Quit option) */
        if (p8_buttons_menu_pressed()) {
            if (!menu_was_pressed) {
                menu_hold_start = (uint32_t)time_us_64();
                menu_was_pressed = 1;
            }
            uint32_t held_ms = ((uint32_t)time_us_64() - menu_hold_start) / 1000;
            if (held_ms > 400) {
                p8_menu_item_t items[4];
                int ni = 0;
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_ACTION, .label = "Resume",
                    .enabled = true, .action_id = P8_MENU_ACT_RESUME };
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_SLIDER, .label = "Volume",
                    .value_ptr = &picker_volume, .min = 0, .max = 30,
                    .enabled = true };
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_TOGGLE, .label = "Show FPS",
                    .value_ptr = &picker_show_fps, .enabled = true };
                static int disk_pct = 0;
                static char disk_text[24];
                {
                    DWORD free_clust = 0; FATFS *fsp = NULL;
                    if (f_getfree("", &free_clust, &fsp) == FR_OK && fsp) {
                        DWORD total = (fsp->n_fatent - 2) * fsp->csize;
                        DWORD used = total - free_clust * fsp->csize;
                        disk_pct = total > 0 ? (int)(used * 100 / total) : 0;
                        snprintf(disk_text, sizeof(disk_text), "%dK/%dK",
                                 (int)(used/2), (int)(total/2));
                    }
                }
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_INFO, .label = "Disk",
                    .info_text = disk_text, .value_ptr = &disk_pct,
                    .min = 0, .max = 100, .enabled = true };

                p8_machine_present(m, scanline);
                p8_menu_run(scanline,
                            (uint16_t *)(m->mem + 0x8000),
                            "ThumbyP8", "settings",
                            items, ni);
                while (p8_buttons_menu_pressed()) sleep_ms(10);
                menu_was_pressed = 0;
                dirty = 1;
                continue;
            }
        } else {
            menu_was_pressed = 0;
        }

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
                 * it's 32KB and we overwrite it with p8_machine_present next. */
                if (p8_bmp_load_128(bmp_bytes, bmp_len, scanline) == 0) {
                    for (int y = 0; y < 128; y++) {
                        for (int x = 0; x < 128; x++) {
                            int pi = rgb565_to_p8_color(
                                scanline[y * 128 + x], m->rgb565_palette);
                            p8_pset(m, x, y, pi);
                        }
                    }
                    painted = 1;
                }
                free(bmp_bytes);
            }
            if (!painted) {
                p8_font_draw(m, "no preview", 32, 56, 7);
            }

            /* Present thumbnail first, then overlay on the RGB565 scanline. */
            p8_machine_present(m, scanline);

            /* DOOM-style overlay bars: black with orange divider lines */
            #define OVL_ORANGE 0xFD20
            #define OVL_GREEN  0x07E0
            #define OVL_WHITE  0xFFFF
            #define OVL_GREY   0xC618  /* PICO-8 light-grey */

            /* Top bar: 50% darken + orange accent line */
            for (int y = 0; y < 10; y++)
                for (int x = 0; x < 128; x++) {
                    int a = y * 128 + x;
                    scanline[a] = ((scanline[a] >> 1) & 0x7BEF);
                }
            for (int x = 0; x < 128; x++)
                scanline[9 * 128 + x] = OVL_ORANGE;

            /* Bottom bar: orange accent + 50% darken */
            for (int x = 0; x < 128; x++)
                scanline[113 * 128 + x] = OVL_ORANGE;
            for (int y = 114; y < 128; y++)
                for (int x = 0; x < 128; x++) {
                    int a = y * 128 + x;
                    scanline[a] = ((scanline[a] >> 1) & 0x7BEF);
                }

            /* Draw text directly into RGB565 scanline using font data */
            extern const uint16_t font_lo[128];
            extern const uint8_t  font_hi[128][5];
            #define SCAN_TEXT(str, tx, ty, rgb565col) do { \
                const char *_s = (str); int _x = (tx); \
                for (; *_s; _s++) { \
                    unsigned char _ch = (unsigned char)*_s; \
                    if (_ch >= 128) { \
                        const uint8_t *_g = font_hi[_ch - 128]; \
                        for (int _r = 0; _r < 5; _r++) { \
                            uint8_t _bits = _g[_r]; \
                            for (int _c = 0; _c < 7; _c++) { \
                                if ((_bits & (1 << _c)) && \
                                    (unsigned)(_x+_c) < 128 && (unsigned)((ty)+_r) < 128) \
                                    scanline[((ty)+_r)*128+_x+_c] = (rgb565col); \
                            } \
                        } \
                        _x += 8; \
                    } else { \
                        uint16_t _g = font_lo[_ch]; \
                        for (int _r = 0; _r < 5; _r++) { \
                            int _bits = (_g >> (_r * 3)) & 0x7; \
                            for (int _c = 0; _c < 3; _c++) { \
                                if ((_bits & (1 << _c)) && \
                                    (unsigned)(_x+_c) < 128 && (unsigned)((ty)+_r) < 128) \
                                    scanline[((ty)+_r)*128+_x+_c] = (rgb565col); \
                            } \
                        } \
                        _x += P8_FONT_CELL_W; \
                    } \
                } \
            } while (0)

            /* Page counter (centered in top bar) */
            {
                char counter[16];
                snprintf(counter, sizeof(counter), "%d / %d", sel + 1, n_entries);
                int cw = (int)strlen(counter) * P8_FONT_CELL_W;
                SCAN_TEXT(counter, (128 - cw) / 2, 2, OVL_GREY);
            }

            /* Cart title + author from .meta file, or filename as fallback */
            {
                char title[64] = {0}, author[64] = {0};
                /* Build .meta path from cart name */
                char meta_path[80];
                char stem[P8_PICKER_NAME_MAX];
                strncpy(stem, entries[sel].name, sizeof(stem) - 1);
                stem[sizeof(stem) - 1] = 0;
                size_t sL = strlen(stem);
                if (sL >= 5 && strcasecmp(stem + sL - 5, ".luac") == 0)
                    stem[sL - 5] = 0;
                snprintf(meta_path, sizeof(meta_path), "/carts/%s.meta", stem);
                FIL mf;
                if (f_open(&mf, meta_path, FA_READ) == FR_OK) {
                    char buf[128];
                    UINT br = 0;
                    f_read(&mf, buf, sizeof(buf) - 1, &br);
                    f_close(&mf);
                    buf[br] = 0;
                    /* Line 1 = title, line 2 = author */
                    char *nl = strchr(buf, '\n');
                    if (nl) {
                        *nl = 0;
                        strncpy(title, buf, sizeof(title) - 1);
                        char *a = nl + 1;
                        char *nl2 = strchr(a, '\n');
                        if (nl2) *nl2 = 0;
                        strncpy(author, a, sizeof(author) - 1);
                    } else {
                        strncpy(title, buf, sizeof(title) - 1);
                    }
                }
                /* Fallback to filename if no meta */
                if (!title[0]) strncpy(title, stem, sizeof(title) - 1);

                /* Display: title on line 1, author (if any) on line 2 */
                int tw = (int)strlen(title) * P8_FONT_CELL_W;
                SCAN_TEXT(title, (128 - tw) / 2, 116, OVL_ORANGE);
                if (author[0]) {
                    int aw = (int)strlen(author) * P8_FONT_CELL_W;
                    SCAN_TEXT(author, (128 - aw) / 2, 122, OVL_GREY);
                }
            }

            /* Nav arrows on the middle edges */
            if (n_entries > 1) {
                SCAN_TEXT("\x8b", 1, 60, OVL_GREY);
                SCAN_TEXT("\x91", 119, 60, OVL_GREY);
            }

            #undef SCAN_TEXT

            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
            dirty = 0;
        }

        sleep_ms(16);
    }
}
