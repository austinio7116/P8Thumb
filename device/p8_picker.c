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
#include "hardware/watchdog.h"
#include "p8_flash_disk.h"
#include "ff.h"

/* --- favorites store ------------------------------------------------ */

/* /.favs is a newline-separated list of cart stems (no .luac suffix).
 * Kept entirely in RAM, flushed on picker exit if dirty. */
#define FAVS_PATH      "/.favs"
#define FAVS_BUF_SIZE  2048

static char   favs_buf[FAVS_BUF_SIZE];
static size_t favs_len   = 0;
static int    favs_dirty = 0;

static void favs_load(void) {
    favs_len = 0;
    favs_dirty = 0;
    FIL f;
    if (f_open(&f, FAVS_PATH, FA_READ) != FR_OK) return;
    UINT br = 0;
    f_read(&f, favs_buf, FAVS_BUF_SIZE - 1, &br);
    f_close(&f);
    favs_len = br;
    favs_buf[favs_len] = 0;
}

static void favs_save(void) {
    if (!favs_dirty) return;
    FIL f;
    if (f_open(&f, FAVS_PATH, FA_WRITE | FA_CREATE_ALWAYS) != FR_OK) return;
    UINT bw = 0;
    f_write(&f, favs_buf, (UINT)favs_len, &bw);
    f_close(&f);
    favs_dirty = 0;
}

static int favs_find(const char *stem) {
    size_t name_len = strlen(stem);
    size_t i = 0;
    while (i < favs_len) {
        size_t j = i;
        while (j < favs_len && favs_buf[j] != '\n') j++;
        size_t line_len = j - i;
        if (line_len == name_len && memcmp(&favs_buf[i], stem, name_len) == 0)
            return (int)i;
        i = j + 1;
    }
    return -1;
}

static int is_favorite(const char *stem) {
    return favs_find(stem) >= 0;
}

static void favs_toggle(const char *stem) {
    int off = favs_find(stem);
    if (off >= 0) {
        size_t end = (size_t)off;
        while (end < favs_len && favs_buf[end] != '\n') end++;
        if (end < favs_len) end++;
        size_t remove_len = end - (size_t)off;
        memmove(&favs_buf[off], &favs_buf[end], favs_len - end);
        favs_len -= remove_len;
        favs_buf[favs_len] = 0;
    } else {
        size_t name_len = strlen(stem);
        if (favs_len + name_len + 2 >= FAVS_BUF_SIZE) return;
        memcpy(&favs_buf[favs_len], stem, name_len);
        favs_len += name_len;
        favs_buf[favs_len++] = '\n';
        favs_buf[favs_len] = 0;
    }
    favs_dirty = 1;
}

static void favs_remove(const char *stem) {
    if (is_favorite(stem)) favs_toggle(stem);
}

/* --- play count store ----------------------------------------------- */

/* /.plays is "stem=count" lines. Max 64 entries to match picker cap. */
#define PLAYS_PATH "/.plays"
#define PLAYS_MAX  P8_PICKER_MAX_CARTS

static struct {
    char     stem[P8_PICKER_NAME_MAX];
    uint32_t count;
} plays[PLAYS_MAX];
static int plays_n = 0;
static int plays_dirty = 0;

static void plays_load(void) {
    plays_n = 0;
    plays_dirty = 0;
    FIL f;
    if (f_open(&f, PLAYS_PATH, FA_READ) != FR_OK) return;
    char buf[1024];
    UINT br = 0;
    f_read(&f, buf, sizeof(buf) - 1, &br);
    f_close(&f);
    buf[br] = 0;
    char *line = buf;
    while (*line && plays_n < PLAYS_MAX) {
        char *nl = strchr(line, '\n');
        if (nl) *nl = 0;
        char *eq = strchr(line, '=');
        if (eq) {
            *eq = 0;
            strncpy(plays[plays_n].stem, line, P8_PICKER_NAME_MAX - 1);
            plays[plays_n].stem[P8_PICKER_NAME_MAX - 1] = 0;
            plays[plays_n].count = (uint32_t)strtoul(eq + 1, NULL, 10);
            plays_n++;
        }
        if (!nl) break;
        line = nl + 1;
    }
}

static void plays_save(void) {
    if (!plays_dirty) return;
    FIL f;
    if (f_open(&f, PLAYS_PATH, FA_WRITE | FA_CREATE_ALWAYS) != FR_OK) return;
    char buf[32];
    for (int i = 0; i < plays_n; i++) {
        UINT bw = 0;
        int n = snprintf(buf, sizeof(buf), "%s=%u\n",
                         plays[i].stem, plays[i].count);
        f_write(&f, buf, n, &bw);
    }
    f_close(&f);
    plays_dirty = 0;
}

static uint32_t plays_get(const char *stem) {
    for (int i = 0; i < plays_n; i++) {
        if (strcmp(plays[i].stem, stem) == 0) return plays[i].count;
    }
    return 0;
}

static void plays_inc(const char *stem) {
    for (int i = 0; i < plays_n; i++) {
        if (strcmp(plays[i].stem, stem) == 0) {
            plays[i].count++;
            plays_dirty = 1;
            return;
        }
    }
    if (plays_n >= PLAYS_MAX) return;
    strncpy(plays[plays_n].stem, stem, P8_PICKER_NAME_MAX - 1);
    plays[plays_n].stem[P8_PICKER_NAME_MAX - 1] = 0;
    plays[plays_n].count = 1;
    plays_n++;
    plays_dirty = 1;
}

static void plays_remove(const char *stem) {
    for (int i = 0; i < plays_n; i++) {
        if (strcmp(plays[i].stem, stem) == 0) {
            memmove(&plays[i], &plays[i + 1],
                    (plays_n - i - 1) * sizeof(plays[0]));
            plays_n--;
            plays_dirty = 1;
            return;
        }
    }
}

/* --- preferences ---------------------------------------------------- */

#define PICKER_PREF_PATH "/.picker_pref"
#define P8_SORT_ALPHA    0
#define P8_SORT_FAV      1
#define P8_SORT_PLAYED   2
#define P8_SORT_COUNT    3

typedef struct {
    uint8_t show_favs_only;
    uint8_t sort_mode;
    uint8_t _pad[2];
    char    last_sel[P8_PICKER_NAME_MAX];
} p8_picker_pref_t;

static p8_picker_pref_t g_pref;

static void pref_load(void) {
    memset(&g_pref, 0, sizeof(g_pref));
    g_pref.sort_mode = P8_SORT_ALPHA;
    FIL f;
    if (f_open(&f, PICKER_PREF_PATH, FA_READ) != FR_OK) return;
    UINT br = 0;
    f_read(&f, &g_pref, sizeof(g_pref), &br);
    f_close(&f);
    if (g_pref.sort_mode >= P8_SORT_COUNT) g_pref.sort_mode = P8_SORT_ALPHA;
    g_pref.last_sel[P8_PICKER_NAME_MAX - 1] = 0;
}

static void pref_save(void) {
    FIL f;
    if (f_open(&f, PICKER_PREF_PATH, FA_WRITE | FA_CREATE_ALWAYS) != FR_OK) return;
    UINT bw = 0;
    f_write(&f, &g_pref, sizeof(g_pref), &bw);
    f_close(&f);
}

/* Convert a cart filename ("celeste.luac") to its stem ("celeste"). */
static void stem_of(char *out, size_t outsz, const char *fname) {
    strncpy(out, fname, outsz - 1);
    out[outsz - 1] = 0;
    size_t L = strlen(out);
    if (L >= 5 && strcasecmp(out + L - 5, ".luac") == 0) out[L - 5] = 0;
}

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

/* --- view (filter + sort) ------------------------------------------ */

static const p8_cart_entry *g_sort_entries;

static int cmp_alpha(const void *a, const void *b) {
    int ai = *(const int *)a, bi = *(const int *)b;
    return strcasecmp(g_sort_entries[ai].name, g_sort_entries[bi].name);
}
static int cmp_fav(const void *a, const void *b) {
    int ai = *(const int *)a, bi = *(const int *)b;
    char sa[P8_PICKER_NAME_MAX], sb[P8_PICKER_NAME_MAX];
    stem_of(sa, sizeof(sa), g_sort_entries[ai].name);
    stem_of(sb, sizeof(sb), g_sort_entries[bi].name);
    int fa = is_favorite(sa) ? 0 : 1;
    int fb = is_favorite(sb) ? 0 : 1;
    if (fa != fb) return fa - fb;
    return strcasecmp(g_sort_entries[ai].name, g_sort_entries[bi].name);
}
static int cmp_played(const void *a, const void *b) {
    int ai = *(const int *)a, bi = *(const int *)b;
    char sa[P8_PICKER_NAME_MAX], sb[P8_PICKER_NAME_MAX];
    stem_of(sa, sizeof(sa), g_sort_entries[ai].name);
    stem_of(sb, sizeof(sb), g_sort_entries[bi].name);
    uint32_t pa = plays_get(sa), pb = plays_get(sb);
    if (pa != pb) return pa < pb ? 1 : -1;  /* descending */
    return strcasecmp(g_sort_entries[ai].name, g_sort_entries[bi].name);
}

/* Build ordered view indices based on filter + sort. Returns count. */
static int build_view(const p8_cart_entry *entries, int n_entries,
                       int *view, int show_favs_only, int sort_mode) {
    g_sort_entries = entries;
    int n = 0;
    for (int i = 0; i < n_entries; i++) {
        if (show_favs_only) {
            char stem[P8_PICKER_NAME_MAX];
            stem_of(stem, sizeof(stem), entries[i].name);
            if (!is_favorite(stem)) continue;
        }
        view[n++] = i;
    }
    int (*cmp)(const void *, const void *) = cmp_alpha;
    if (sort_mode == P8_SORT_FAV)    cmp = cmp_fav;
    if (sort_mode == P8_SORT_PLAYED) cmp = cmp_played;
    qsort(view, n, sizeof(int), cmp);
    return n;
}

/* Delete a cart and all sidecars (.luac .rom .bmp .meta .sav). */
static void delete_cart_and_sidecars(const char *fname) {
    char stem[P8_PICKER_NAME_MAX];
    stem_of(stem, sizeof(stem), fname);

    char path[80];
    snprintf(path, sizeof(path), "/carts/%s.luac", stem); f_unlink(path);
    snprintf(path, sizeof(path), "/carts/%s.rom",  stem); f_unlink(path);
    snprintf(path, sizeof(path), "/carts/%s.bmp",  stem); f_unlink(path);
    snprintf(path, sizeof(path), "/carts/%s.meta", stem); f_unlink(path);
    snprintf(path, sizeof(path), "/carts/%s.sav",  stem); f_unlink(path);
    /* Don't delete the source .p8.png — the user can re-add if they
     * want to keep it. Actually, delete it too so the game disappears
     * completely. */
    snprintf(path, sizeof(path), "/carts/%s.p8.png", stem); f_unlink(path);

    favs_remove(stem);
    plays_remove(stem);

    p8_flash_disk_flush();
}

/* Draw a 5×5 star at (x, y) in RGB565. Simple filled-star shape. */
static void draw_star(uint16_t *fb, int x, int y, uint16_t col) {
    /* Star shape, 7×7 */
    static const uint8_t star[7] = {
        0b0001000,
        0b0001000,
        0b1111111,
        0b0111110,
        0b0011100,
        0b0111110,
        0b0110110,
    };
    for (int dy = 0; dy < 7; dy++) {
        uint8_t row = star[dy];
        for (int dx = 0; dx < 7; dx++) {
            if (row & (1 << (6 - dx))) {
                int sx = x + dx, sy = y + dy;
                if ((unsigned)sx < 128 && (unsigned)sy < 128)
                    fb[sy * 128 + sx] = col;
            }
        }
    }
}

/* Find view[] index whose entry name matches `name`. Returns 0 if
 * not found (safe default — first entry). */
static int view_index_of(const p8_cart_entry *entries, const int *view,
                          int n_view, const char *name) {
    if (!name || !*name) return 0;
    for (int i = 0; i < n_view; i++) {
        if (strcmp(entries[view[i]].name, name) == 0) return i;
    }
    return 0;
}

/* --- main picker loop ----------------------------------------------- */

int p8_picker_run(p8_machine *m, p8_input *in, uint16_t *scanline,
                   const p8_cart_entry *entries, int n_entries,
                   int *volume_ptr, int *show_fps_ptr) {
    if (n_entries <= 0) return -1;

    /* Load favorites, play counts, and preferences. */
    favs_load();
    plays_load();
    pref_load();

    /* Build the filtered + sorted view. If favs-only filter yields no
     * results, fall back to showing all carts. */
    static int view[P8_PICKER_MAX_CARTS];
    int n_view = build_view(entries, n_entries, view,
                             g_pref.show_favs_only, g_pref.sort_mode);
    if (n_view == 0) {
        g_pref.show_favs_only = 0;
        n_view = build_view(entries, n_entries, view, 0, g_pref.sort_mode);
    }

    /* Restore last-selected cart if still present in the view. */
    int sel = view_index_of(entries, view, n_view, g_pref.last_sel);

    int dirty = 1;
    uint32_t menu_hold_start = 0;
    int menu_was_pressed = 0;

    /* B button: short tap = toggle favorite, long hold = delete warning */
    uint32_t b_press_ms = 0;
    int b_consumed = 0;
    int b_was_held = 0;

    /* Brief on-screen confirmation message */
    char osd[24] = {0};
    int  osd_ms  = 0;

    while (1) {
        p8_input_begin_frame(in, p8_buttons_read());

        /* MENU long-press → settings menu */
        if (p8_buttons_menu_pressed()) {
            if (!menu_was_pressed) {
                menu_hold_start = (uint32_t)time_us_64();
                menu_was_pressed = 1;
            }
            uint32_t held_ms = ((uint32_t)time_us_64() - menu_hold_start) / 1000;
            if (held_ms > 400) {
                p8_menu_item_t items[8];
                int ni = 0;
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_ACTION, .label = "Resume",
                    .enabled = true, .action_id = P8_MENU_ACT_RESUME };
                int show_favs = g_pref.show_favs_only;
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_TOGGLE, .label = "Favs only",
                    .value_ptr = &show_favs, .enabled = true };
                int sort_mode = g_pref.sort_mode;
                static const char *sort_choices[P8_SORT_COUNT] = {
                    "alphabetical", "favorites", "most played"
                };
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_CHOICE, .label = "Sort",
                    .value_ptr = &sort_mode,
                    .choices = sort_choices, .num_choices = P8_SORT_COUNT,
                    .enabled = true };
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_SLIDER, .label = "Volume",
                    .value_ptr = volume_ptr, .min = 0, .max = 30,
                    .enabled = true };
                items[ni++] = (p8_menu_item_t){
                    .kind = P8_MENU_KIND_TOGGLE, .label = "Show FPS",
                    .value_ptr = show_fps_ptr, .enabled = true };
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
                /* Apply any changes to filter / sort and rebuild view. */
                if (show_favs != g_pref.show_favs_only ||
                    sort_mode != g_pref.sort_mode) {
                    /* Remember the cart we were on so we can re-seat. */
                    if (n_view > 0) {
                        strncpy(g_pref.last_sel, entries[view[sel]].name,
                                sizeof(g_pref.last_sel) - 1);
                        g_pref.last_sel[sizeof(g_pref.last_sel) - 1] = 0;
                    }
                    g_pref.show_favs_only = show_favs;
                    g_pref.sort_mode = sort_mode;
                    n_view = build_view(entries, n_entries, view,
                                         g_pref.show_favs_only, g_pref.sort_mode);
                    if (n_view == 0) {
                        g_pref.show_favs_only = 0;
                        n_view = build_view(entries, n_entries, view,
                                             0, g_pref.sort_mode);
                    }
                    sel = view_index_of(entries, view, n_view, g_pref.last_sel);
                }
                while (p8_buttons_menu_pressed()) sleep_ms(10);
                menu_was_pressed = 0;
                dirty = 1;
                continue;
            }
        } else {
            menu_was_pressed = 0;
        }

        /* Thumby B button (= PICO-8 O, bit 4): short tap = toggle fav,
         * long hold = delete. A button (= PICO-8 X, bit 5) launches. */
        int b_held = p8_btn(in, P8_BTN_O);
        if (b_held && n_view > 0) {
            b_press_ms += 16;
            if (b_press_ms >= 10000 && !b_consumed) {
                /* Delete the highlighted cart + sidecars. */
                char doomed[P8_PICKER_NAME_MAX];
                strncpy(doomed, entries[view[sel]].name, sizeof(doomed) - 1);
                doomed[sizeof(doomed) - 1] = 0;
                delete_cart_and_sidecars(doomed);
                b_consumed = 1;
                snprintf(osd, sizeof(osd), "deleted");
                osd_ms = 900;
                /* Cart list and view are now stale. Best to reboot to
                 * rescan the filesystem cleanly. Save state first. */
                favs_save();
                plays_save();
                pref_save();
                p8_flash_disk_flush();
                watchdog_reboot(0, 0, 0);
                while (1) tight_loop_contents();
            }
        } else {
            if (b_was_held && b_press_ms > 0 && !b_consumed && b_press_ms < 400) {
                /* Short tap on release: toggle favorite */
                if (n_view > 0) {
                    char stem[P8_PICKER_NAME_MAX];
                    stem_of(stem, sizeof(stem), entries[view[sel]].name);
                    favs_toggle(stem);
                    snprintf(osd, sizeof(osd),
                             is_favorite(stem) ? "favorite added" : "favorite removed");
                    osd_ms = 900;
                    dirty = 1;
                    /* If favs-only filter is on, rebuild view. */
                    if (g_pref.show_favs_only) {
                        strncpy(g_pref.last_sel, entries[view[sel]].name,
                                sizeof(g_pref.last_sel) - 1);
                        g_pref.last_sel[sizeof(g_pref.last_sel) - 1] = 0;
                        n_view = build_view(entries, n_entries, view,
                                             g_pref.show_favs_only, g_pref.sort_mode);
                        if (n_view == 0) {
                            g_pref.show_favs_only = 0;
                            n_view = build_view(entries, n_entries, view,
                                                 0, g_pref.sort_mode);
                        }
                        sel = view_index_of(entries, view, n_view, g_pref.last_sel);
                    }
                }
            }
            b_press_ms = 0;
            b_consumed = 0;
        }
        b_was_held = b_held;

        if (p8_btnp(in, P8_BTN_LEFT) && n_view > 0) {
            sel = (sel - 1 + n_view) % n_view;
            dirty = 1;
        }
        if (p8_btnp(in, P8_BTN_RIGHT) && n_view > 0) {
            sel = (sel + 1) % n_view;
            dirty = 1;
        }
        if (p8_btnp(in, P8_BTN_X) && n_view > 0) {
            /* Remember this cart for next time + bump play count. */
            strncpy(g_pref.last_sel, entries[view[sel]].name,
                    sizeof(g_pref.last_sel) - 1);
            g_pref.last_sel[sizeof(g_pref.last_sel) - 1] = 0;
            char stem[P8_PICKER_NAME_MAX];
            stem_of(stem, sizeof(stem), entries[view[sel]].name);
            plays_inc(stem);
            /* Persist state before returning. */
            favs_save();
            plays_save();
            pref_save();
            p8_flash_disk_flush();
            return view[sel];
        }

        if (dirty) {
            /* Build the .bmp thumbnail filename next to the .p8 */
            char bmp_name[P8_PICKER_NAME_MAX];
            if (n_view == 0) {
                /* No carts match filter — show placeholder */
                memset(scanline, 0, 128 * 128 * 2);
                p8_lcd_wait_idle();
                p8_lcd_present(scanline);
                dirty = 0;
                sleep_ms(16);
                continue;
            }
            strncpy(bmp_name, entries[view[sel]].name, sizeof(bmp_name) - 1);
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
                snprintf(counter, sizeof(counter), "%d / %d", sel + 1, n_view);
                int cw = (int)strlen(counter) * P8_FONT_CELL_W;
                SCAN_TEXT(counter, (128 - cw) / 2, 2, OVL_GREY);
            }

            /* Cart title + author from .meta file, or filename as fallback */
            {
                char title[64] = {0}, author[64] = {0};
                /* Build .meta path from cart name */
                char meta_path[80];
                char stem[P8_PICKER_NAME_MAX];
                strncpy(stem, entries[view[sel]].name, sizeof(stem) - 1);
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
            if (n_view > 1) {
                SCAN_TEXT("\x8b", 1, 60, OVL_GREY);
                SCAN_TEXT("\x91", 119, 60, OVL_GREY);
            }

            /* Star icon in top-left for favorites (yellow) */
            {
                char stem[P8_PICKER_NAME_MAX];
                stem_of(stem, sizeof(stem), entries[view[sel]].name);
                if (is_favorite(stem)) {
                    draw_star(scanline, 2, 1, 0xFFE0);  /* yellow */
                }
            }

            /* Play count in top-right if > 0 */
            {
                char stem[P8_PICKER_NAME_MAX];
                stem_of(stem, sizeof(stem), entries[view[sel]].name);
                uint32_t pc = plays_get(stem);
                if (pc > 0) {
                    char pt[16];
                    snprintf(pt, sizeof(pt), "%up", (unsigned)pc);
                    int pw = (int)strlen(pt) * P8_FONT_CELL_W;
                    SCAN_TEXT(pt, 126 - pw, 2, OVL_GREY);
                }
            }

            #undef SCAN_TEXT

            /* Delete-confirmation overlay (after B held >= 5s). */
            if (b_held && b_press_ms >= 5000 && !b_consumed) {
                int remaining = (10000 - (int)b_press_ms + 999) / 1000;
                if (remaining < 0) remaining = 0;
                /* Dark backdrop band */
                for (int y = 40; y < 88; y++)
                    for (int x = 0; x < 128; x++)
                        scanline[y * 128 + x] = 0x3800;  /* dark red */
                /* Top + bottom accent lines */
                for (int x = 0; x < 128; x++) {
                    scanline[40 * 128 + x] = 0xF800;  /* red */
                    scanline[87 * 128 + x] = 0xF800;
                }
                /* Messages - draw directly via font */
                extern const uint16_t font_lo[128];
                const char *line1 = "DELETE CART?";
                const char *line2 = "release B to cancel";
                char cd[16];
                snprintf(cd, sizeof(cd), "deleting in %d...", remaining);
                #define STXT(str, tx, ty, rgb) do { \
                    const char *_s = (str); int _x = (tx); \
                    for (; *_s; _s++) { \
                        unsigned char _ch = (unsigned char)*_s; \
                        uint16_t _g = font_lo[_ch]; \
                        for (int _r = 0; _r < 5; _r++) { \
                            int _bits = (_g >> (_r * 3)) & 0x7; \
                            for (int _c = 0; _c < 3; _c++) { \
                                if ((_bits & (1 << _c)) && \
                                    (unsigned)(_x+_c) < 128 && (unsigned)((ty)+_r) < 128) \
                                    scanline[((ty)+_r)*128+_x+_c] = (rgb); \
                            } \
                        } \
                        _x += P8_FONT_CELL_W; \
                    } \
                } while (0)
                int w1 = (int)strlen(line1) * P8_FONT_CELL_W;
                int w2 = (int)strlen(line2) * P8_FONT_CELL_W;
                int w3 = (int)strlen(cd) * P8_FONT_CELL_W;
                STXT(line1, (128 - w1) / 2, 48, 0xFFFF);
                STXT(line2, (128 - w2) / 2, 60, 0xC618);
                STXT(cd, (128 - w3) / 2, 74, 0xFFE0);
                #undef STXT
            }

            /* OSD toast message */
            if (osd_ms > 0 && osd[0]) {
                extern const uint16_t font_lo[128];
                int ow = (int)strlen(osd) * P8_FONT_CELL_W;
                int ox = (128 - ow) / 2;
                int oy = 45;
                /* Dark background */
                for (int y = oy - 2; y < oy + 8; y++)
                    for (int x = ox - 2; x < ox + ow + 2; x++)
                        if ((unsigned)x < 128 && (unsigned)y < 128)
                            scanline[y * 128 + x] = 0x0000;
                const char *_s = osd; int _x = ox;
                for (; *_s; _s++) {
                    unsigned char _ch = (unsigned char)*_s;
                    uint16_t _g = font_lo[_ch];
                    for (int _r = 0; _r < 5; _r++) {
                        int _bits = (_g >> (_r * 3)) & 0x7;
                        for (int _c = 0; _c < 3; _c++) {
                            if ((_bits & (1 << _c)) &&
                                (unsigned)(_x+_c) < 128 && (unsigned)(oy+_r) < 128)
                                scanline[(oy+_r)*128+_x+_c] = 0xFFE0;
                        }
                    }
                    _x += P8_FONT_CELL_W;
                }
                osd_ms -= 16;
            } else if (osd_ms <= 0) {
                osd[0] = 0;
            }

            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
            dirty = 0;
        } else {
            /* Even if "not dirty", redraw when we have a delete countdown
             * or OSD to animate. */
            if ((b_held && b_press_ms >= 5000) || osd_ms > 0) {
                dirty = 1;
            }
        }

        sleep_ms(16);
    }
}
