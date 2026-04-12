/*
 * ThumbyP8 — generic in-game pause menu.
 *
 * Adapted from ThumbyNES nes_menu.c. Uses ThumbyP8's own font
 * renderer (p8_font), LCD driver (p8_lcd_gc9107), and button
 * reader (p8_buttons).
 */
#include "p8_menu.h"
#include "p8_font.h"
#include "p8_lcd_gc9107.h"
#include "p8_buttons.h"
#include "p8_machine.h"
#include "p8_draw.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pico/stdlib.h"
#include "hardware/gpio.h"

#define FB_W 128
#define FB_H 128

/* GPIO pin numbers — same as p8_buttons.h */
#define BTN_LEFT_GP   0
#define BTN_UP_GP     1
#define BTN_RIGHT_GP  2
#define BTN_DOWN_GP   3
#define BTN_LB_GP     6
#define BTN_A_GP     21
#define BTN_RB_GP    22
#define BTN_B_GP     25
#define BTN_MENU_GP  26

/* Layout constants. */
#define TITLE_H      11
#define SUBTITLE_H   8
#define FOOTER_H     8
#define ROW_H        10
#define ITEMS_TOP    (TITLE_H + SUBTITLE_H + 1)
#define ITEMS_BOTTOM (FB_H - FOOTER_H - 1)
#define VISIBLE_ROWS ((ITEMS_BOTTOM - ITEMS_TOP) / ROW_H)

/* Colours (RGB565). */
#define COL_BG       0x0000
#define COL_FG       0xFFFF
#define COL_DIM      0x8410
#define COL_HIGHLT   0x07E0    /* green cursor row */
#define COL_TITLE    0xFD20    /* orange */
#define COL_DARK     0x4208    /* very dim grey */
#define COL_DISABLED 0x4208

/* --- font helper: draw text directly into RGB565 buffer --- */
/* p8_font_draw uses the PICO-8 machine framebuffer (4bpp). For the
 * menu we need to draw directly into an RGB565 buffer. Uses the same
 * packed uint16_t glyph format as p8_font.c:
 *   bit 0..2 = row 0 pixels (LSB = leftmost)
 *   bit 3..5 = row 1, etc. 5 rows × 3 bits = 15 bits per glyph. */

/* Import the font tables from p8_font.c */
extern const uint16_t font_lo[128];
extern const uint8_t  font_hi[128][5];

static void menu_text(uint16_t *fb, const char *text, int x, int y, uint16_t color) {
    for (const char *c = text; *c; c++) {
        unsigned char ch = (unsigned char)*c;
        if (ch == '\n') { x = 0; y += P8_FONT_CELL_H; continue; }
        if (ch >= 128) {
            const uint8_t *g = font_hi[ch - 128];
            for (int row = 0; row < 5; row++) {
                uint8_t bits = g[row];
                for (int col = 0; col < 7; col++) {
                    if (bits & (1 << col)) {
                        int px = x + col, py = y + row;
                        if ((unsigned)px < FB_W && (unsigned)py < FB_H)
                            fb[py * FB_W + px] = color;
                    }
                }
            }
            x += 8;
        } else {
            uint16_t g = font_lo[ch];
            for (int row = 0; row < 5; row++) {
                int bits = (g >> (row * 3)) & 0x7;
                for (int col = 0; col < 3; col++) {
                    if (bits & (1 << col)) {
                        int px = x + col, py = y + row;
                        if ((unsigned)px < FB_W && (unsigned)py < FB_H)
                            fb[py * FB_W + px] = color;
                    }
                }
            }
            x += P8_FONT_CELL_W;
        }
    }
}

static int menu_text_width(const char *text) {
    return (int)strlen(text) * P8_FONT_CELL_W;
}

/* --- helpers -------------------------------------------------------- */

static inline void put_pixel(uint16_t *fb, int x, int y, uint16_t c) {
    if ((unsigned)x < FB_W && (unsigned)y < FB_H) fb[y * FB_W + x] = c;
}

static void fill_rect(uint16_t *fb, int x, int y, int w, int h, uint16_t c) {
    for (int j = 0; j < h; j++) {
        int yy = y + j;
        if ((unsigned)yy >= FB_H) continue;
        for (int i = 0; i < w; i++) {
            int xx = x + i;
            if ((unsigned)xx >= FB_W) continue;
            fb[yy * FB_W + xx] = c;
        }
    }
}

static void darken_fb(uint16_t *fb) {
    for (int i = 0; i < FB_W * FB_H; i++) {
        uint16_t p = fb[i];
        uint32_t r = (p >> 11) & 0x1F;
        uint32_t g = (p >>  5) & 0x3F;
        uint32_t b = (p      ) & 0x1F;
        r >>= 2; g >>= 2; b >>= 2;
        fb[i] = (uint16_t)((r << 11) | (g << 5) | b);
    }
}

static void draw_thin_bar(uint16_t *fb, int x, int y, int w, int h,
                           int value, int vmin, int vmax,
                           uint16_t fg, uint16_t bg) {
    fill_rect(fb, x, y, w, h, bg);
    int span = vmax - vmin;
    if (span <= 0) return;
    int v = value - vmin;
    if (v < 0) v = 0; if (v > span) v = span;
    int fill_w = (w * v) / span;
    if (fill_w > 0) fill_rect(fb, x, y, fill_w, h, fg);
}

static void draw_slider(uint16_t *fb, int x, int y, int w, int h,
                         int value, int vmin, int vmax, uint16_t fg) {
    fill_rect(fb, x, y, w, h, COL_DARK);
    for (int i = 0; i < w; i++) { put_pixel(fb, x+i, y, fg); put_pixel(fb, x+i, y+h-1, fg); }
    for (int j = 0; j < h; j++) { put_pixel(fb, x, y+j, fg); put_pixel(fb, x+w-1, y+j, fg); }
    int span = vmax - vmin; if (span <= 0) return;
    int v = value - vmin;
    if (v < 0) v = 0; if (v > span) v = span;
    int fill_w = ((w - 2) * v) / span;
    fill_rect(fb, x + 1, y + 1, fill_w, h - 2, fg);
}

static int seek_selectable(const p8_menu_item_t *items, int n, int from, int dir) {
    int i = from;
    for (int tries = 0; tries < n; tries++) {
        i += dir;
        if (i < 0)  i = n - 1;
        if (i >= n) i = 0;
        if (items[i].enabled && items[i].kind != P8_MENU_KIND_INFO) return i;
    }
    return from;
}

/* --- draw ----------------------------------------------------------- */

static void draw_menu(uint16_t       *fb_dim,
                       uint16_t       *fb,
                       const char     *title,
                       const char     *subtitle,
                       const p8_menu_item_t *items,
                       int             n_items,
                       int             cursor,
                       int             scroll_top) {
    memcpy(fb, fb_dim, FB_W * FB_H * 2);

    /* Title bar */
    fill_rect(fb, 0, 0, FB_W, TITLE_H, COL_BG);
    fill_rect(fb, 0, TITLE_H - 1, FB_W, 1, COL_TITLE);
    if (title) menu_text(fb, title, 2, 2, COL_TITLE);

    if (scroll_top > 0)
        menu_text(fb, "^", FB_W - 14, 2, COL_TITLE);
    if (scroll_top + VISIBLE_ROWS < n_items)
        menu_text(fb, "v", FB_W - 7, 2, COL_TITLE);

    if (subtitle) {
        char buf[24];
        strncpy(buf, subtitle, sizeof(buf) - 1); buf[sizeof(buf)-1] = 0;
        if (strlen(buf) > 21) buf[21] = 0;
        menu_text(fb, buf, 2, TITLE_H, COL_DIM);
    }

    for (int row = 0; row < VISIBLE_ROWS; row++) {
        int idx = scroll_top + row;
        if (idx >= n_items) break;
        const p8_menu_item_t *it = &items[idx];
        int y = ITEMS_TOP + row * ROW_H;
        bool is_cursor = (idx == cursor);

        if (is_cursor) fill_rect(fb, 0, y - 1, FB_W, ROW_H, 0x0220);

        uint16_t fg = is_cursor ? COL_HIGHLT : !it->enabled ? COL_DISABLED : COL_FG;

        if (is_cursor) menu_text(fb, ">", 1, y + 1, fg);
        menu_text(fb, it->label, 7, y + 1, fg);

        char val[24] = {0};
        switch (it->kind) {
        case P8_MENU_KIND_ACTION: break;
        case P8_MENU_KIND_TOGGLE:
            snprintf(val, sizeof(val), (*it->value_ptr) ? "ON" : "OFF");
            break;
        case P8_MENU_KIND_SLIDER:
            draw_slider(fb, FB_W - 32, y + 1, 28, ROW_H - 2,
                         *it->value_ptr, it->min, it->max, fg);
            break;
        case P8_MENU_KIND_CHOICE:
            if (it->choices && *it->value_ptr >= 0 && *it->value_ptr < it->num_choices)
                snprintf(val, sizeof(val), "%s", it->choices[*it->value_ptr]);
            break;
        case P8_MENU_KIND_INFO:
            if (it->info_text) snprintf(val, sizeof(val), "%s", it->info_text);
            if (it->value_ptr && it->max > it->min)
                draw_thin_bar(fb, 8, y + ROW_H - 3, FB_W - 16, 2,
                               *it->value_ptr, it->min, it->max,
                               COL_HIGHLT, 0x39E7);
            break;
        }

        if (val[0] || it->suffix) {
            char combined[40];
            if (it->suffix) snprintf(combined, sizeof(combined), "%s %s", val, it->suffix);
            else snprintf(combined, sizeof(combined), "%s", val);
            int vw = menu_text_width(combined);
            menu_text(fb, combined, FB_W - vw - 2, y + 1, fg);
        }
    }

    /* Footer */
    fill_rect(fb, 0, FB_H - FOOTER_H, FB_W, FOOTER_H, COL_BG);
    fill_rect(fb, 0, FB_H - FOOTER_H, FB_W, 1, COL_TITLE);
    const p8_menu_item_t *cur = (cursor >= 0 && cursor < n_items) ? &items[cursor] : NULL;
    const char *hint =
        (!cur || cur->kind == P8_MENU_KIND_ACTION) ? "A select  B back" :
        (cur->kind == P8_MENU_KIND_TOGGLE)         ? "<> toggle  B back" :
        (cur->kind == P8_MENU_KIND_SLIDER)         ? "<> adjust  B back" :
                                                      "<> change  B back";
    int hw = menu_text_width(hint);
    menu_text(fb, hint, (FB_W - hw) / 2, FB_H - FOOTER_H + 1, COL_DIM);
}

/* --- main loop ------------------------------------------------------ */

p8_menu_result_t p8_menu_run(uint16_t        *fb,
                              const char      *title,
                              const char      *subtitle,
                              p8_menu_item_t  *items,
                              int              n_items) {
    p8_menu_result_t result = { .kind = P8_MENU_RESUME, .action_id = 0 };
    if (n_items == 0) return result;

    /* Allocate the dimmed backdrop on heap instead of BSS — saves 32KB
     * of permanent SRAM that's only used when the menu is open. */
    uint16_t *fb_dim = (uint16_t *)malloc(FB_W * FB_H * sizeof(uint16_t));
    if (!fb_dim) return result;  /* OOM — can't show menu */
    memcpy(fb_dim, fb, FB_W * FB_H * sizeof(uint16_t));
    darken_fb(fb_dim);

    int cursor = -1;
    for (int i = 0; i < n_items; i++) {
        if (items[i].enabled) { cursor = i; break; }
    }
    if (cursor < 0) { free(fb_dim); return result; }
    int scroll_top = 0;

    /* Wait for MENU release */
    while (!gpio_get(BTN_MENU_GP)) sleep_ms(10);

    int prev_lt=0, prev_rt=0, prev_up=0, prev_dn=0;
    int prev_a=0, prev_b=0, prev_menu=0;

    while (1) {
        int lt = !gpio_get(BTN_LEFT_GP);
        int rt = !gpio_get(BTN_RIGHT_GP);
        int up = !gpio_get(BTN_UP_GP);
        int dn = !gpio_get(BTN_DOWN_GP);
        int a  = !gpio_get(BTN_A_GP);
        int b  = !gpio_get(BTN_B_GP);
        int mn = !gpio_get(BTN_MENU_GP);

        int e_lt = lt && !prev_lt;
        int e_rt = rt && !prev_rt;
        int e_up = up && !prev_up;
        int e_dn = dn && !prev_dn;
        int e_a  = a  && !prev_a;
        int e_b  = b  && !prev_b;
        int e_mn = mn && !prev_menu;

        prev_lt=lt; prev_rt=rt; prev_up=up; prev_dn=dn;
        prev_a=a; prev_b=b; prev_menu=mn;

        /* B or MENU = close */
        if (e_b || e_mn) {
            while (!gpio_get(BTN_B_GP) || !gpio_get(BTN_MENU_GP)) sleep_ms(10);
            free(fb_dim);
            return result;
        }

        if (e_up) cursor = seek_selectable(items, n_items, cursor, -1);
        if (e_dn) cursor = seek_selectable(items, n_items, cursor, +1);

        if (cursor < scroll_top) scroll_top = cursor;
        if (cursor >= scroll_top + VISIBLE_ROWS) scroll_top = cursor - VISIBLE_ROWS + 1;
        if (scroll_top < 0) scroll_top = 0;
        if (scroll_top > n_items - VISIBLE_ROWS && n_items >= VISIBLE_ROWS)
            scroll_top = n_items - VISIBLE_ROWS;
        if (n_items < VISIBLE_ROWS) scroll_top = 0;

        p8_menu_item_t *it = &items[cursor];

        if (it->enabled) switch (it->kind) {
        case P8_MENU_KIND_TOGGLE:
            if (e_lt || e_rt || e_a) *it->value_ptr = !*it->value_ptr;
            break;
        case P8_MENU_KIND_SLIDER:
            if (e_lt && *it->value_ptr > it->min) (*it->value_ptr)--;
            if (e_rt && *it->value_ptr < it->max) (*it->value_ptr)++;
            break;
        case P8_MENU_KIND_CHOICE:
            if (e_lt) { if (*it->value_ptr > 0) (*it->value_ptr)--; else *it->value_ptr = it->num_choices - 1; }
            if (e_rt) { if (*it->value_ptr < it->num_choices - 1) (*it->value_ptr)++; else *it->value_ptr = 0; }
            break;
        case P8_MENU_KIND_ACTION:
            if (e_a) {
                result.kind = P8_MENU_ACTION;
                result.action_id = it->action_id;
                while (!gpio_get(BTN_A_GP)) sleep_ms(10);
                free(fb_dim);
                return result;
            }
            break;
        default: break;
        }

        draw_menu(fb_dim, fb, title, subtitle, items, n_items, cursor, scroll_top);
        p8_lcd_wait_idle();
        p8_lcd_present(fb);
        sleep_ms(16);
    }
}
