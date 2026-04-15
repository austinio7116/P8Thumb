/*
 * ThumbyP8 — Thumby Color device runtime entry point.
 *
 * Boots the chip at 250 MHz, brings up display + audio + filesystem
 * + USB MSC, ensures /carts/ has at least one cart (the embedded
 * celeste fallback if the disk is empty), runs the picker, and
 * launches the selected cart in the main update/draw loop.
 *
 * The Thumby Color appears as a USB removable drive — drop .p8.png
 * carts onto it from the host, eject, reboot, and they show up in
 * the picker on next boot.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "pico/stdlib.h"
#include "pico/time.h"
#include "hardware/clocks.h"
#include "hardware/watchdog.h"
#include "tusb.h"
#include "ff.h"

#include "p8.h"
#include "p8_machine.h"
#include "p8_input.h"
#include "p8_api.h"
#include "p8_cart.h"
#include "p8_audio.h"

#include "p8_lcd_gc9107.h"
#include "p8_buttons.h"
#include "p8_audio_pwm.h"
#include "p8_flash_disk.h"
#include "p8_picker.h"
#include "p8_cart_flash.h"
#include "p8_draw.h"
#include "p8_font.h"
#include "p8_log.h"
#include "p8_p8png.h"
#include "p8_translate.h"
#include "p8_bmp.h"
#include "p8_menu.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

/* Set by boot_filesystem(): 1 if we ran f_mkfs at boot (label
 * mismatch / no FS / MENU forced), 0 if the existing FS was kept.
 * Surfaced in the lobby so we can tell on the next boot whether
 * the previous session's writes survived. */
static int g_boot_reformatted = 0;

/* Current cart stem — set by the launcher before running the cart,
 * used by cartdata save/load to build the .sav path. */
static char g_cart_stem[64] = {0};
static int  g_cartdata_active = 0;   /* 1 once cartdata() has been called */

/* cartdata save/load — device implementation. Stores the 256 bytes
 * at 0x5e00-0x5eff in /carts/<stem>.sav. */
void p8_cartdata_open(p8_machine *m, const char *name) {
    (void)name;  /* PICO-8 uses name as a namespace; we key by cart stem */
    g_cartdata_active = 1;
    /* Zero first */
    memset(&m->mem[0x5e00], 0, 256);
    if (g_cart_stem[0] == 0) return;
    char path[96];
    snprintf(path, sizeof(path), "/carts/%s.sav", g_cart_stem);
    FIL f;
    if (f_open(&f, path, FA_READ) == FR_OK) {
        UINT br = 0;
        f_read(&f, &m->mem[0x5e00], 256, &br);
        f_close(&f);
    }
}

void p8_cartdata_save(p8_machine *m) {
    if (!g_cartdata_active || g_cart_stem[0] == 0) return;
    char path[96];
    snprintf(path, sizeof(path), "/carts/%s.sav", g_cart_stem);
    FIL f;
    if (f_open(&f, path, FA_WRITE | FA_CREATE_ALWAYS) == FR_OK) {
        UINT bw = 0;
        f_write(&f, &m->mem[0x5e00], 256, &bw);
        f_close(&f);
        /* Rate-limit flash flushes to at most once per second to
         * reduce wear and avoid FAT corruption from rapid writes. */
        static uint32_t last_flush_ms = 0;
        uint32_t now = (uint32_t)(time_us_64() / 1000);
        if (now - last_flush_ms >= 1000) {
            p8_flash_disk_flush();
            last_flush_ms = now;
        }
    }
}

/* Forward decl — `scanline` is defined later in this file. */
static uint16_t scanline[128 * 128];

/* HardFault handler — invoked by the Cortex-M when a memory or
 * usage fault fires (typically a NULL deref, unaligned access, or
 * stack overflow). Without this, the chip just hangs silently
 * and the user sees a frozen screen. With this, we paint the
 * screen red and write a log entry so the next boot's log file
 * shows the cause. */
void __not_in_flash_func(isr_hardfault)(void) {
    /* Do NOT repaint the screen — leave whatever was on the LCD
     * so on-screen diagnostic logs remain visible. Just hang. */
    while (1) tight_loop_contents();
}

/* Static memory: machine + scanline DMA buffer + cart entry table.
 * `scanline` was forward-declared above so the hardfault handler
 * can write to it. */
static p8_machine     machine;
static p8_input       input;
static p8_cart_entry  cart_entries[P8_PICKER_MAX_CARTS];
static FATFS          fs;

/* Draw text at 2× scale using the P8 font. Each pixel becomes a 2×2 block. */
extern const uint16_t font_lo[128];
extern const uint8_t  font_hi[128][5];

static void font_draw_2x(p8_machine *m, const char *text, int x, int y, int c) {
    for (; *text; text++) {
        unsigned char ch = (unsigned char)*text;
        if (ch >= 128) {
            const uint8_t *g = font_hi[ch - 128];
            for (int row = 0; row < 5; row++) {
                uint8_t bits = g[row];
                for (int col = 0; col < 7; col++) {
                    if (bits & (1 << col)) {
                        p8_pset(m, x + col*2,   y + row*2,   c);
                        p8_pset(m, x + col*2+1, y + row*2,   c);
                        p8_pset(m, x + col*2,   y + row*2+1, c);
                        p8_pset(m, x + col*2+1, y + row*2+1, c);
                    }
                }
            }
            x += 16;
        } else {
            uint16_t g = font_lo[ch];
            for (int row = 0; row < 5; row++) {
                int bits = (g >> (row * 3)) & 0x7;
                for (int col = 0; col < 3; col++) {
                    if (bits & (1 << col)) {
                        p8_pset(m, x + col*2,   y + row*2,   c);
                        p8_pset(m, x + col*2+1, y + row*2,   c);
                        p8_pset(m, x + col*2,   y + row*2+1, c);
                        p8_pset(m, x + col*2+1, y + row*2+1, c);
                    }
                }
            }
            x += 8;  /* 4px char × 2 = 8px */
        }
    }
}

/* Load a 128×128 BMP from a file path into a uint16_t scanline buffer.
 * Returns 0 on success, -1 on failure. */
#include "p8_bmp.h"
static int load_bmp_file(const char *path, uint16_t *out) {
    FIL f;
    if (f_open(&f, path, FA_READ) != FR_OK) return -1;
    UINT sz = (UINT)f_size(&f);
    if (sz > 65536 || sz < 70) { f_close(&f); return -1; }
    unsigned char *buf = (unsigned char *)malloc(sz);
    if (!buf) { f_close(&f); return -1; }
    UINT br = 0;
    f_read(&f, buf, sz, &br);
    f_close(&f);
    int rc = p8_bmp_load_128(buf, (size_t)br, out);
    free(buf);
    return rc;
}

/* --- Persistent settings --------------------------------------------- */
#define VOL_MIN   0
#define VOL_UNITY 15
#define VOL_MAX   30

static int master_volume   = VOL_MAX;
static int show_fps_toggle = 0;

#define SETTINGS_PATH "/settings.dat"

typedef struct {
    uint8_t  magic[4];       /* "P8S\0" */
    uint8_t  version;
    uint8_t  volume;         /* 0..30 */
    uint8_t  show_fps;       /* 0 or 1 */
    uint8_t  _pad;
} p8_settings_t;

static void settings_load(void) {
    FIL f;
    if (f_open(&f, SETTINGS_PATH, FA_READ) != FR_OK) return;
    p8_settings_t s;
    UINT br = 0;
    f_read(&f, &s, sizeof(s), &br);
    f_close(&f);
    if (br < sizeof(s)) return;
    if (s.magic[0] != 'P' || s.magic[1] != '8' ||
        s.magic[2] != 'S' || s.magic[3] != 0) return;
    if (s.volume <= VOL_MAX) master_volume = s.volume;
    show_fps_toggle = s.show_fps ? 1 : 0;
}

static void settings_save(void) {
    p8_settings_t s = {
        .magic = {'P', '8', 'S', 0},
        .version = 1,
        .volume = (uint8_t)master_volume,
        .show_fps = (uint8_t)show_fps_toggle,
    };
    FIL f;
    if (f_open(&f, SETTINGS_PATH, FA_WRITE | FA_CREATE_ALWAYS) != FR_OK) return;
    UINT bw = 0;
    f_write(&f, &s, sizeof(s), &bw);
    f_close(&f);
    p8_flash_disk_flush();
}

static void write_frame_count(p8_machine *m, uint32_t fc) {
    m->mem[P8_DRAWSTATE + 0x34] = (uint8_t)(fc & 0xff);
    m->mem[P8_DRAWSTATE + 0x35] = (uint8_t)((fc >> 8) & 0xff);
    m->mem[P8_DRAWSTATE + 0x36] = (uint8_t)((fc >> 16) & 0xff);
    m->mem[P8_DRAWSTATE + 0x37] = (uint8_t)((fc >> 24) & 0xff);
}

static void write_elapsed_ms(p8_machine *m, uint32_t ms) {
    m->mem[P8_DS_ELAPSED_MS + 0] = (uint8_t)(ms & 0xff);
    m->mem[P8_DS_ELAPSED_MS + 1] = (uint8_t)((ms >> 8) & 0xff);
    m->mem[P8_DS_ELAPSED_MS + 2] = (uint8_t)((ms >> 16) & 0xff);
    m->mem[P8_DS_ELAPSED_MS + 3] = (uint8_t)((ms >> 24) & 0xff);
}

/* Solid-color "boot status" splash. Used for early-stage debug
 * because we don't have a serial console anymore in MSC mode. */
static void splash(uint16_t color) {
    for (int i = 0; i < 128 * 128; i++) scanline[i] = color;
    p8_lcd_present(scanline);
    p8_lcd_wait_idle();
}

/* Mount the flash disk. Only reformat if f_mount actually fails —
 * any other heuristic (like checking the volume label) is unsafe
 * because Windows happily edits BPB fields on mount, which would
 * make us think the disk was foreign and wipe it on every boot.
 * If FatFs can read the FS, we keep it. */
static int boot_filesystem(void) {
    /* Force-reformat rescue: hold MENU at boot to nuke whatever is
     * on the disk and start clean. Useful if a cart upload corrupted
     * the FS or a future firmware update changed the layout. */
    int force = p8_buttons_menu_pressed();

    int needs_format = force;
    FRESULT r = f_mount(&fs, "", 1);
    if (r != FR_OK) {
        /* No filesystem, or one we can't parse — format. */
        needs_format = 1;
    }
    /* Otherwise: keep whatever is on the disk. Don't second-guess
     * with label / metadata checks — Windows mutates them. */

    if (needs_format) {
        g_boot_reformatted = 1;

        f_unmount("");
        /* Wipe in-memory FS state so the next mount sees fresh disk. */
        memset(&fs, 0, sizeof(fs));

        BYTE work[FF_MAX_SS * 4];
        /* FM_FAT (no FM_SFD) → MBR-partitioned FAT volume.
         * au_size = 1024 → 1 KB clusters → 12 MB / 1 KB = 12288
         * clusters, well into FAT16 range (FAT12 caps at 4084).
         * Forcing FAT16 sidesteps quirks Windows has with FAT12 on
         * removable drives larger than 8 MB. */
        MKFS_PARM opt = { FM_FAT, 1, 0, 0, 1024 };
        if (f_mkfs("", &opt, work, sizeof(work)) != FR_OK) {
            splash(0xf800);   /* red = mkfs failed */
            return -1;
        }
        /* Force everything from cache to flash before re-mounting,
         * so f_mount reads the freshly-written sectors and not stale
         * cache entries. */
        p8_flash_disk_flush();

        if (f_mount(&fs, "", 1) != FR_OK) {
            splash(0xfa00);   /* dark red = remount failed */
            return -1;
        }
        f_setlabel("P8THUMBv1");
        p8_flash_disk_flush();
    }

    f_mkdir("/carts");   /* harmless if already present */
    p8_flash_disk_flush();
    return 0;
}

/* ------------------------------------------------------------------ */
/* On-device .p8.png → .luac conversion                               */
/*                                                                     */
/* Scans /carts/ for .p8.png files that don't have a matching .luac.   */
/* For each, loads the PNG, decodes steganographic cart bytes,          */
/* decompresses Lua source, runs the full C dialect translator,        */
/* compiles to bytecode via luaL_loadbuffer + lua_dump, and saves      */
/* .luac + .rom + .bmp to /carts/.                                     */
/*                                                                     */
/* Runs once at boot, before USB comes up. Takes 5-15 seconds per      */
/* cart depending on Lua source size. Shows a progress screen.         */
/* ------------------------------------------------------------------ */

/* lua_dump writer callback — writes directly to a FIL* (FatFs file).
 * Avoids allocating a large heap buffer that competes with the Lua VM. */
/* FatFs IO callbacks for stb_image — reads PNG directly from file,
 * avoiding the need to hold the entire compressed PNG in heap. */
static int fat_io_read(void *user, char *data, int size) {
    FIL *f = (FIL *)user;
    UINT br = 0;
    f_read(f, data, (UINT)size, &br);
    return (int)br;
}
static void fat_io_skip(void *user, int n) {
    FIL *f = (FIL *)user;
    f_lseek(f, f_tell(f) + (FSIZE_t)n);
}
static int fat_io_eof(void *user) {
    FIL *f = (FIL *)user;
    return f_eof(f);
}
static const p8_png_io g_fat_io = { fat_io_read, fat_io_skip, fat_io_eof };

/* lua_dump writer: writes directly to a FIL* (FatFs file).
 * Zero heap allocation — the Lua VM keeps all its memory. */
static int dump_file_writer(lua_State *L, const void *p, size_t sz, void *ud) {
    FIL *f = (FIL *)ud;
    (void)L;
    UINT bw;
    if (f_write(f, p, (UINT)sz, &bw) != FR_OK || bw != (UINT)sz)
        return 1;
    return 0;
}

/* Conversion progress display: animated spinner + filling progress bar.
 * Each screen_log call advances the progress one step. */
static int g_progress_step = 0;
static int g_progress_max  = 10;
static const char *g_progress_stem = "";
static const char g_spinner[] = "|/-\\";

/* bg_sl: if non-NULL, used as dimmed thumbnail background. The
 * text is drawn in the 4bpp framebuffer, present'd, then composited
 * onto the background where text pixels are non-black. */
static uint16_t *g_progress_bg = NULL;

static void screen_log(p8_machine *m, uint16_t *sl, const char *stage) {
    /* Don't call p8_machine_reset — it zeros ALL of machine.mem
     * including 0x8000 where we stashed the thumbnail. Just clear
     * the framebuffer and reset all drawing state manually. */
    p8_camera(m, 0, 0);
    p8_clip(m, 0, 0, 128, 128, 1);
    p8_pal_reset(m);
    p8_fillp(m, 0, 0);  /* clear fill pattern */
    p8_cls(m, 0);

    /* Cart name */
    p8_font_draw(m, g_progress_stem, 4, 4, 7);

    /* Stage with spinner */
    char spin_line[48];
    snprintf(spin_line, sizeof(spin_line), "%c %s",
             g_spinner[g_progress_step % 4], stage);
    p8_font_draw(m, spin_line, 4, 14, 10);

    /* Progress bar */
    p8_rect(m, 14, 112, 113, 120, 5);
    int fill = (g_progress_step * 96) / g_progress_max;
    if (fill > 96) fill = 96;
    if (fill > 0) {
        p8_rectfill(m, 16, 114, 15 + fill, 118, 11);
    }

    /* Present 4bpp framebuffer (text + progress bar) to RGB565.
     * Then composite onto thumbnail: replace black pixels (cls
     * background) with the dimmed thumbnail. All colored text and
     * progress bar pixels are preserved. */
    p8_machine_present(m, sl);
    if (g_progress_bg) {
        for (int px = 0; px < 128 * 128; px++) {
            if (sl[px] == 0x0000) {
                sl[px] = g_progress_bg[px];
            }
        }
    }

    p8_lcd_wait_idle();
    p8_lcd_present(sl);
    g_progress_step++;
}

static int convert_one_cart(const char *stem, p8_machine *m,
                             uint16_t *sl) {
    char png_path[80], luac_path[80], rom_path[80], bmp_path[80];
    snprintf(png_path,  sizeof(png_path),  "/carts/%s.p8.png", stem);
    snprintf(luac_path, sizeof(luac_path), "/carts/%s.luac", stem);
    snprintf(rom_path,  sizeof(rom_path),  "/carts/%s.rom", stem);
    snprintf(bmp_path,  sizeof(bmp_path),  "/carts/%s.bmp", stem);

    g_progress_step = 0;
    g_progress_stem = stem;
    g_progress_bg = NULL;  /* no thumbnail yet */
    screen_log(m, sl, stem);
    screen_log(m, sl, "opening file...");

    /* ---- Phase A: PNG → cart bytes + Lua source ---- */
    /* Open the PNG file and decode via IO callbacks — stb_image reads
     * directly from the FAT file, so we never hold the full compressed
     * PNG (~70KB) in our heap. Peak is stb_image internals only. */
    FIL f;
    if (f_open(&f, png_path, FA_READ) != FR_OK) {
        screen_log(m, sl, "ERR: can't open");
        p8_log_to_file("convert: can't open png");
        return -1;
    }
    {
        char info[40];
        snprintf(info, sizeof(info), "size: %lu", (unsigned long)f_size(&f));
        screen_log(m, sl, info);
    }

    screen_log(m, sl, "decoding png...");
    p8_log_to_file("convert: decoding png");

    char *lua_src = NULL;
    size_t lua_len = 0;
    int rc = p8_p8png_load_io(m, (p8_png_io *)&g_fat_io, &f,
                               &lua_src, &lua_len, sl);
    f_close(&f);
    if (rc != 0 || !lua_src) {
        if (lua_src) free(lua_src);
        screen_log(m, sl, "ERR: png decode fail");
        p8_log_to_file("convert: png decode failed");
        return -4;
    }

    /* Save BMP FIRST — sl still has the thumbnail from p8_p8png_load */
    p8_bmp_save_128(bmp_path, sl);

    /* Extract title + author from first two comment lines of Lua source.
     * PICO-8 convention: first `-- title` then `-- by author`. Save to
     * a .meta file for the picker to display. */
    {
        char meta_path[80];
        snprintf(meta_path, sizeof(meta_path), "/carts/%s.meta", stem);
        char title[64] = {0}, author[64] = {0};
        const char *p = lua_src;
        /* Skip leading whitespace/newlines */
        while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
        /* First comment line = title */
        if (p[0] == '-' && p[1] == '-') {
            p += 2;
            while (*p == ' ' || *p == '\t') p++;
            int ti = 0;
            while (*p && *p != '\n' && *p != '\r' && ti < 62) title[ti++] = *p++;
            title[ti] = 0;
            /* Trim trailing whitespace */
            while (ti > 0 && (title[ti-1] == ' ' || title[ti-1] == '\t')) title[--ti] = 0;
        }
        /* Skip to next line */
        while (*p && *p != '\n') p++;
        if (*p == '\n') p++;
        /* Second comment line = author */
        if (p[0] == '-' && p[1] == '-') {
            p += 2;
            while (*p == ' ' || *p == '\t') p++;
            int ai = 0;
            while (*p && *p != '\n' && *p != '\r' && ai < 62) author[ai++] = *p++;
            author[ai] = 0;
            while (ai > 0 && (author[ai-1] == ' ' || author[ai-1] == '\t')) author[--ai] = 0;
        }
        /* Write meta file */
        FIL mf;
        if (f_open(&mf, meta_path, FA_WRITE | FA_CREATE_ALWAYS) == FR_OK) {
            UINT bw;
            f_write(&mf, title, strlen(title), &bw);
            f_write(&mf, "\n", 1, &bw);
            f_write(&mf, author, strlen(author), &bw);
            f_write(&mf, "\n", 1, &bw);
            f_close(&mf);
        }
        /* Use title as progress label if available */
        if (title[0]) {
            static char title_buf[64];
            strncpy(title_buf, title, sizeof(title_buf) - 1);
            g_progress_stem = title_buf;
        }
    }

    /* Save ROM — m->mem has the cart data from p8_p8png_load */
    if (f_open(&f, rom_path, FA_WRITE | FA_CREATE_ALWAYS) == FR_OK) {
        UINT bw;
        f_write(&f, m->mem, 0x4300, &bw);
        f_close(&f);
    }

    /* sl currently holds the thumbnail (RGB565) from p8_p8png_load.
     * Copy it to machine.mem[0x8000] and dim it for use as progress
     * background. No file I/O needed — data is already in memory. */
    {
        uint16_t *bg = (uint16_t *)&m->mem[0x8000];
        memcpy(bg, sl, 128 * 128 * 2);
        for (int px = 0; px < 128*128; px++) {
            uint16_t c = bg[px];
            bg[px] = ((c >> 1) & 0x7BEF);  /* 50% brightness */
        }
        g_progress_bg = bg;
    }

    {
        char info[40];
        snprintf(info, sizeof(info), "lua: %d bytes", (int)lua_len);
        screen_log(m, sl, info);
    }
    screen_log(m, sl, "rom+bmp saved");

    screen_log(m, sl, "translating...");
    p8_log_to_file("convert: translating");

    /* p8_translate_full takes ownership of lua_src and frees it */
    size_t translated_len = 0;
    char *translated = p8_translate_full(lua_src, lua_len, &translated_len);
    lua_src = NULL;  /* already freed inside p8_translate_full */

    if (!translated) {
        screen_log(m, sl, "ERR: translate OOM");
        p8_log_to_file("convert: translate OOM");
        return -5;
    }
    {
        char info[40];
        snprintf(info, sizeof(info), "translated: %d b", (int)translated_len);
        screen_log(m, sl, info);
    }

    screen_log(m, sl, "compiling...");
    p8_log_to_file("convert: compiling");

    lua_State *L = luaL_newstate();
    if (!L) {
        free(translated);
        screen_log(m, sl, "ERR: VM OOM");
        p8_log_to_file("convert: lua VM OOM");
        return -6;
    }
    screen_log(m, sl, "vm created");

    rc = luaL_loadbuffer(L, translated, translated_len, "=cart");
    free(translated);
    translated = NULL;

    if (rc != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        char buf[160];
        snprintf(buf, sizeof(buf), "compile: %s",
                 err ? err : "(no msg)");
        screen_log(m, sl, "ERR: compile fail");
        screen_log(m, sl, buf);
        p8_log_to_file(buf);
        sleep_ms(5000);
        lua_close(L);
        return -7;
    }
    screen_log(m, sl, "compiled ok");

    /* Dump bytecode directly to file — no heap buffer needed.
     * This is critical for large carts where the Lua VM already
     * occupies most of the available heap after compilation. */
    screen_log(m, sl, "saving luac...");
    p8_log_to_file("convert: saving luac");

    int dump_ok = 0;
    if (f_open(&f, luac_path, FA_WRITE | FA_CREATE_ALWAYS) == FR_OK) {
        int drc = lua_dump(L, dump_file_writer, &f);
        f_close(&f);
        dump_ok = (drc == 0);
    }
    lua_close(L);

    if (!dump_ok) {
        f_unlink(luac_path);  /* remove partial file */
        screen_log(m, sl, "ERR: dump fail");
        p8_log_to_file("convert: dump failed");
        return -8;
    }

    p8_flash_disk_flush();
    screen_log(m, sl, "DONE OK");

    {
        char buf[80];
        snprintf(buf, sizeof(buf), "convert: ok %s", stem);
        p8_log_to_file(buf);
    }
    return 0;
}

/* Scan /carts/ for .p8.png files without matching .luac and convert. */
static int convert_pending_carts(p8_machine *m, uint16_t *sl) {
    DIR dir;
    FILINFO info;
    if (f_opendir(&dir, "/carts") != FR_OK) return 0;

    /* Scan for the FIRST .p8.png that lacks a matching .luac.
     * Convert it and reboot. On next boot, it's skipped (has .luac)
     * and the next unconverted cart gets processed. No array needed —
     * just find one, close the directory, convert, reboot. */
    char stem[40];
    int found = 0;

    while (f_readdir(&dir, &info) == FR_OK) {
        if (info.fname[0] == 0) break;
        if (info.fattrib & AM_DIR) continue;
        size_t L = strlen(info.fname);
        if (L < 8) continue;
        if (strcasecmp(info.fname + L - 7, ".p8.png") != 0) continue;

        /* Extract stem */
        size_t stem_len = L - 7;
        if (stem_len >= sizeof(stem)) stem_len = sizeof(stem) - 1;
        memcpy(stem, info.fname, stem_len);
        stem[stem_len] = 0;

        /* Check if .luac exists */
        char luac_path[80];
        snprintf(luac_path, sizeof(luac_path), "/carts/%s.luac", stem);
        FILINFO fi;
        if (f_stat(luac_path, &fi) == FR_OK) continue; /* already done */

        found = 1;
        break;
    }
    f_closedir(&dir);

    if (!found) return 0;

    /* Initialize machine ONCE before conversion starts. screen_log
     * doesn't call p8_machine_reset (to preserve thumbnail in
     * machine.mem[0x8000]), so we must do it here. */
    p8_machine_reset(m);

    int rc = convert_one_cart(stem, m, sl);
    if (rc != 0) {
        char buf[80];
        snprintf(buf, sizeof(buf), "convert: FAIL %s rc=%d", stem, rc);
        p8_log_to_file(buf);
        /* Write empty .luac stub so this cart is skipped next boot */
        char fail_path[80];
        snprintf(fail_path, sizeof(fail_path), "/carts/%s.luac", stem);
        FIL ff;
        if (f_open(&ff, fail_path, FA_WRITE | FA_CREATE_ALWAYS) == FR_OK)
            f_close(&ff);
    }

    /* Reboot to reclaim heap for next cart. Final status already shown
     * by the last screen_log ("DONE OK" or error) on the thumbnail bg. */
    p8_flash_disk_flush();
    sleep_ms(1000);  /* brief pause so user sees the final status */

    watchdog_reboot(0, 0, 0);
    while (1) tight_loop_contents();

    return 1; /* unreachable */
}

/* "Drop carts onto USB drive" wait screen. Holds until at least one
 * cart shows up under /carts/. Continues to service USB MSC so the
 * host can actually write the file. */
extern volatile int      g_msc_ejected;
extern volatile uint64_t g_msc_last_op_us;

/* Home / lobby screen — state machine:
 *
 *   MOUNTED  : host is attached and actively using the drive.
 *              Writes go into RAM cache, nothing touches flash.
 *              Transitions on: eject signal from host OR 5 s of
 *              write-idle (host looks quiescent).
 *   FLUSHING : we're committing the cache to flash. USB is still
 *              nominally up but we don't care if it stalls.
 *              Transitions to READY when cache is empty.
 *   READY    : disk is stable on flash, at least one cart exists.
 *              Press A to enter the picker.
 *
 * The entire point of this state machine is to NEVER do a flash
 * erase while the host thinks it owns the drive. Erase blocks IRQs
 * for ~50 ms per sector, and USB MSC can't survive that under any
 * Windows workload heavier than "sit there doing nothing". */
enum { LOBBY_MOUNTED, LOBBY_FLUSHING, LOBBY_READY };

static void wait_for_carts(void) {
    int state  = LOBBY_MOUNTED;
    int n_carts = 0;
    int blink  = 0;
    absolute_time_t next_scan   = make_timeout_time_ms(0);
    absolute_time_t next_redraw = make_timeout_time_ms(0);

    g_msc_ejected = 0;

    while (1) {
        tud_task();                   /* keep USB alive in every state */

        /* --- continuous background drain --------------------------
         *
         * Commit one dirty block per iteration whenever MSC has
         * been quiet for >300 ms. This works in every state — no
         * eject needed, no state machine acrobatics. The host
         * naturally pauses between commands and we exploit those
         * gaps. Each commit is ~66 ms with IRQs off, but since
         * MSC has been quiet for >300 ms we won't be starving any
         * in-flight transfer.
         *
         * The state variable still drives the *display* (mounted /
         * flushing / ready) but the drain logic itself is uniform. */
        {
            uint64_t now = (uint64_t)time_us_64();
            uint64_t since_op = now - g_msc_last_op_us;
            int may_drain = since_op > 300000;
            if (may_drain && p8_flash_disk_dirty()) {
                p8_flash_disk_commit_one();
            }
        }

        /* --- display state machine --------------------------------
         *
         * Display state is purely cosmetic now. It shows what the
         * lobby is *doing* so the user knows when it's safe to
         * press A. The transition rules:
         *
         *   MOUNTED  → FLUSHING when dirty (we're committing)
         *   FLUSHING → READY    when clean
         *   READY    → FLUSHING when dirty again (Windows touched it)
         *   READY    → MOUNTED  never (only via power cycle)
         */
        if (state == LOBBY_MOUNTED && p8_flash_disk_dirty()) {
            state = LOBBY_FLUSHING;
        }
        if (state == LOBBY_FLUSHING && !p8_flash_disk_dirty()) {
            state = LOBBY_READY;
        }
        if (state == LOBBY_READY && p8_flash_disk_dirty()) {
            state = LOBBY_FLUSHING;
        }

        /* --- button input ----------------------------------------- */
        p8_input_begin_frame(&input, p8_buttons_read());
        /* A: always go to picker if there are playable carts.
         * Conversion happens automatically on boot — the lobby is
         * for USB access, not for gating conversion. */
        if ((p8_btnp(&input, P8_BTN_X) || p8_btnp(&input, P8_BTN_O))
            && n_carts > 0 && !p8_flash_disk_dirty()) {
            return;
        }

        /* --- periodic disk rescan --------------------------------- */
        if (time_reached(next_scan)) {
            n_carts = p8_picker_scan(cart_entries, P8_PICKER_MAX_CARTS);
            next_scan = make_timeout_time_ms(500);
        }

        /* --- redraw ----------------------------------------------- */
        if (time_reached(next_redraw)) {
            blink++;
            p8_machine_reset(&machine);
            p8_camera(&machine, 0, 0);
            p8_cls(&machine, 0);

            /* Clean layout: double-size title, orange accents */

            /* Title — 2× size, centered, orange */
            font_draw_2x(&machine, "ThumbyP8", 16, 6, 9);
            p8_line(&machine, 0, 18, 127, 18, 9);

            /* Footer line — raised to fit 2× text below */
            p8_line(&machine, 0, 113, 127, 113, 9);

            int busy = p8_flash_disk_dirty();

            /* Helper: center 1× text */
            #define CTX(s) ((128 - (int)strlen(s) * P8_FONT_CELL_W) / 2)
            /* Helper: center 2× text (each char = 8px wide) */
            #define CTX2(s) ((128 - (int)strlen(s) * 8) / 2)

            /* USB icon macro (centered at x=57..70) */
            #define DRAW_USB_ICON(iy) do { \
                p8_rectfill(&machine, 57, (iy), 70, (iy)+18, 6); \
                p8_rectfill(&machine, 60, (iy)-4, 67, (iy), 6); \
                p8_rectfill(&machine, 62, (iy)-6, 65, (iy)-4, 7); \
                p8_rectfill(&machine, 61, (iy)+4, 62, (iy)+8, 0); \
                p8_rectfill(&machine, 65, (iy)+4, 66, (iy)+8, 0); \
                p8_line(&machine, 63, (iy)+18, 63, (iy)+22, 6); \
                p8_line(&machine, 64, (iy)+18, 64, (iy)+22, 6); \
            } while (0)

            switch (state) {
            case LOBBY_MOUNTED:
            case LOBBY_FLUSHING: {
                if (busy) {
                    int on = (blink & 1);
                    font_draw_2x(&machine, "saving", CTX2("saving"), 40, on ? 9 : 2);
                    p8_font_draw(&machine, "please wait...", CTX("please wait..."), 62, 6);
                    p8_font_draw(&machine, "do not power off", CTX("do not power off"), 74, 8);
                } else if (n_carts > 0) {
                    int iy = 30;  /* icon top */
                    if (tud_mounted()) {
                        p8_font_draw(&machine, "pc connected", CTX("pc connected"), 24, 6);
                        iy = 36;  /* push icon down */
                    }
                    DRAW_USB_ICON(iy);
                    char line[40];
                    snprintf(line, sizeof(line), "%d game%s loaded",
                             n_carts, n_carts == 1 ? "" : "s");
                    p8_font_draw(&machine, line, CTX(line), iy + 30, 11);
                    p8_font_draw(&machine, "add more via usb", CTX("add more via usb"), iy + 44, 5);
                    font_draw_2x(&machine, "A to play", CTX2("A to play"), 116, 10);
                } else {
                    font_draw_2x(&machine, "welcome", CTX2("welcome"), 30, 7);
                    p8_line(&machine, 20, 48, 108, 48, 5);
                    if (tud_mounted()) {
                        p8_font_draw(&machine, "pc connected!", CTX("pc connected!"), 58, 11);
                    } else {
                        p8_font_draw(&machine, "connect to a pc", CTX("connect to a pc"), 58, 7);
                    }
                    p8_font_draw(&machine, "drop .p8.png game", CTX("drop .p8.png game"), 70, 7);
                    p8_font_draw(&machine, "files onto the drive", CTX("files onto the drive"), 80, 7);
                    p8_font_draw(&machine, "then eject or reboot", CTX("then eject or reboot"), 96, 5);
                }
                break;
            }
            case LOBBY_READY: {
                if (n_carts > 0) {
                    DRAW_USB_ICON(28);
                    char line[40];
                    snprintf(line, sizeof(line), "%d game%s loaded",
                             n_carts, n_carts == 1 ? "" : "s");
                    p8_font_draw(&machine, line, CTX(line), 58, 11);
                    p8_font_draw(&machine, "connect usb to add more", CTX("connect usb to add more"), 72, 5);
                    font_draw_2x(&machine, "A to play", CTX2("A to play"), 116, 10);
                } else {
                    font_draw_2x(&machine, "no games", CTX2("no games"), 38, 8);
                    p8_line(&machine, 20, 56, 108, 56, 5);
                    p8_font_draw(&machine, "connect usb cable", CTX("connect usb cable"), 66, 7);
                    p8_font_draw(&machine, "drop .p8.png files", CTX("drop .p8.png files"), 76, 7);
                    p8_font_draw(&machine, "into /carts/ folder", CTX("into /carts/ folder"), 86, 7);
                }
                break;
            }
            }

            #undef CTX
            #undef CTX2
            #undef DRAW_USB_ICON

            p8_machine_present(&machine, scanline);
            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
            next_redraw = make_timeout_time_ms(200);
        }
    }
}

int main(void) {
    /* Overclock to 250 MHz BEFORE stdio_init_all so the USB PLL
     * comes up at the right divider. */
    set_sys_clock_khz(250000, true);

    stdio_init_all();
    setvbuf(stdout, NULL, _IONBF, 0);

    /* Hardware bring-up */
    p8_buttons_init();
    p8_lcd_init();
    p8_audio_pwm_init();

    /* Clear screen immediately so the LCD doesn't show uninitialised RAM. */
    memset(scanline, 0, sizeof(scanline));
    p8_lcd_present(scanline);
    p8_lcd_wait_idle();

    /* Filesystem comes up FIRST — before USB. */
    p8_flash_disk_init();
    if (boot_filesystem() != 0) {
        splash(0xf800);   /* red = mount/format failed (fatal) */
        while (1) tight_loop_contents();
    }
    /* Force any cached writes (from mkfs) out to flash before the
     * USB host gets a chance to see the disk. */
    p8_flash_disk_flush();

    /* Load persistent settings (volume, FPS toggle). */
    settings_load();

    /* Always log a boot marker so the user has *something* in
     * /thumbyp8.log even when no cart errors fire. Helpful for
     * confirming the log path is alive. */
    p8_log_to_file("--- thumbyp8 boot ---");
    p8_log_to_file(g_boot_reformatted ? "fs: reformatted at boot"
                                       : "fs: kept existing volume");

    /* Stage 2.5: on-device cart conversion. Scan /carts/ for .p8.png
     * files without a matching .luac and convert them. Runs BEFORE
     * USB so the host sees the generated .luac files immediately.
     * Takes 5-15s per cart; shows a progress screen on the LCD.
     *
     * Hold B at boot to skip conversion (recovery escape hatch). */
    if (p8_buttons_read() & (1 << P8_BTN_O)) {
        p8_log_to_file("convert: skipped (B held)");
    } else {
        int nc = convert_pending_carts(&machine, scanline);
        if (nc > 0) {
            char buf[40];
            snprintf(buf, sizeof(buf), "converted %d cart(s)", nc);
            p8_log_to_file(buf);
            p8_flash_disk_flush();
        }
    }

    /* USB stack. */
    tusb_init();
    {
        absolute_time_t until = make_timeout_time_ms(1000);
        while (!time_reached(until)) {
            tud_task();
            sleep_us(100);
        }
    }

    /* Pre-fill audio ring with silence so the IRQ has something
     * to chew on while picker + cart load run. */
    {
        int16_t silence[1024] = {0};
        p8_audio_pwm_push(silence, 1024);
    }

    /* --- main outer loop: lobby → pick → run → repick on game exit -- */
    /* Always start USB so users can add new carts. If carts already
     * exist, auto-proceed to the picker after 3 seconds unless the
     * user interacts (gives time to connect USB if needed). */
    wait_for_carts();
    /* Defensive: drain any leftover cache before going offline. */
    p8_flash_disk_flush();

    while (1) {
        int n_carts = p8_picker_scan(cart_entries, P8_PICKER_MAX_CARTS);
        if (n_carts <= 0) {
            /* Shouldn't happen — wait_for_carts only returns when
             * there's at least one cart. But guard anyway. */
            wait_for_carts();
            p8_flash_disk_flush();
            n_carts = p8_picker_scan(cart_entries, P8_PICKER_MAX_CARTS);
        }

        p8_machine_reset(&machine);
        p8_input_reset(&input);

        int chosen = p8_picker_run(&machine, &input, scanline,
                                    cart_entries, n_carts,
                                    &master_volume, &show_fps_toggle);
        if (chosen < 0 || chosen >= n_carts) chosen = 0;

        /* Persist the cart we're about to launch so the log file
         * always shows what was running just before any hang. */
        {
            char line[80];
            snprintf(line, sizeof(line), "launch: %s",
                     cart_entries[chosen].name);
            p8_log_to_file(line);
            /* Record stem (strip .luac extension) for cartdata paths */
            const char *cn = cart_entries[chosen].name;
            strncpy(g_cart_stem, cn, sizeof(g_cart_stem) - 1);
            g_cart_stem[sizeof(g_cart_stem) - 1] = 0;
            size_t sl = strlen(g_cart_stem);
            if (sl >= 5 && strcasecmp(g_cart_stem + sl - 5, ".luac") == 0)
                g_cart_stem[sl - 5] = 0;
            g_cartdata_active = 0;  /* reset for new cart */
        }

        p8_machine_reset(&machine);
        p8_input_reset(&input);

        /* Arm the panic longjmp BEFORE any Lua operation. If the
         * compiler, _init, or any frame hits an unrecoverable OOM,
         * the panic handler longjmps back here and we show a clean
         * error instead of hardfaulting. */
        if (p8_vm_panic_arm() != 0) {
            /* Panic was caught! VM is invalid — leak it. */
            char buf[120];
            snprintf(buf, sizeof(buf), "PANIC: %s", g_panic_msg);
            p8_log_to_file(buf);
            p8_log_ring("PANIC caught");

            p8_machine_reset(&machine);
            p8_camera(&machine, 0, 0);
            p8_cls(&machine, 2);   /* dark purple */
            p8_font_draw(&machine, "lua panic (oom?)", 8, 4, 7);
            p8_font_draw(&machine, cart_entries[chosen].name, 4, 14, 7);
            int y = 28;
            int plen = (int)strlen(g_panic_msg);
            for (int s = 0; s < plen && y < 110; s += 30) {
                char line[32] = {0};
                int chunk = (plen - s > 30) ? 30 : (plen - s);
                memcpy(line, g_panic_msg + s, chunk);
                p8_font_draw(&machine, line, 2, y, 7);
                y += 8;
            }
            p8_font_draw(&machine, "MENU = picker", 20, 116, 10);
            p8_machine_present(&machine, scanline);
            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
            while (!p8_buttons_menu_pressed()) sleep_ms(50);
            p8_vm_panic_disarm();
            continue;
        }

        /* Dim the picker's current display and overlay "loading..." */
        {
            for (int px = 0; px < 128*128; px++)
                scanline[px] = ((scanline[px] >> 1) & 0x7BEF);
            p8_machine_reset(&machine);
            p8_camera(&machine, 0, 0);
            p8_cls(&machine, 0);
            p8_font_draw(&machine, "loading...", 36, 58, 7);
            const uint8_t *fb = &machine.mem[P8_FB_BASE];
            for (int y = 54; y < 68; y++) {
                for (int x = 32; x < 96; x++) {
                    uint8_t c = (x & 1) ? (fb[(y<<6)+(x>>1)] >> 4)
                                        : (fb[(y<<6)+(x>>1)] & 0x0f);
                    if (c == 7) scanline[y * 128 + x] = 0xFFFF;
                }
            }
            p8_lcd_wait_idle();
            p8_lcd_present(scanline);
        }

        p8_vm vm;
        if (p8_vm_init(&vm, 0) != 0) {
            p8_log_to_file("load: lua VM init OOM");
            continue;
        }
        p8_api_install(&vm, &machine, &input);
        /* Seed libc RNG from hardware timer — varies by microseconds
         * depending on when the user navigated to this cart. Without
         * this, rand() starts from seed 1 every boot (same levels). */
        srand((unsigned)time_us_32());
        /* Route every traced binding into our RAM ring buffer so a
         * hardfault dump shows the last few bindings the cart called. */
        p8_trace_hook = p8_log_ring;

        /* --- Bytecode execution path (.luac + .rom) ---
         *
         * Cart conversion (dialect translation + compilation) happens
         * either on the host via tools/p8png_extract.py, or on-device
         * at boot via convert_pending_carts(). By this point the
         * .luac + .rom files already exist on disk.
         */
        {
            /* cart_entries[chosen].name is already "<stem>.luac".
             * Derive .rom name by replacing the extension. */
            const char *cart_name = cart_entries[chosen].name;
            char rom_name[P8_PICKER_NAME_MAX];
            strncpy(rom_name, cart_name, sizeof(rom_name) - 1);
            rom_name[sizeof(rom_name) - 1] = 0;
            size_t nL = strlen(rom_name);
            if (nL >= 5 && strcasecmp(rom_name + nL - 5, ".luac") == 0) {
                rom_name[nL - 5] = 0;
            }
            strncat(rom_name, ".rom",
                    sizeof(rom_name) - strlen(rom_name) - 1);
            const char *luac_name = cart_name;

            size_t luac_len = 0, rom_len = 0;
            unsigned char *luac_data = p8_picker_load_cart(luac_name,
                                                           &luac_len);
            unsigned char *rom_data  = p8_picker_load_cart(rom_name,
                                                           &rom_len);

            if (!luac_data || !rom_data || luac_len < 4 || rom_len == 0) {
                if (luac_data) free(luac_data);
                if (rom_data)  free(rom_data);
                char buf[80];
                snprintf(buf, sizeof(buf), "load: missing %s or %s",
                         luac_name, rom_name);
                p8_log_to_file(buf);
                p8_machine_reset(&machine);
                p8_camera(&machine, 0, 0);
                p8_cls(&machine, 2);
                p8_font_draw(&machine, "missing .luac/.rom", 4, 20, 7);
                p8_font_draw(&machine, "conversion failed?", 4, 36, 6);
                p8_font_draw(&machine, "MENU = picker", 20, 116, 10);
                p8_machine_present(&machine, scanline);
                p8_lcd_wait_idle();
                p8_lcd_present(scanline);
                while (!p8_buttons_menu_pressed()) sleep_ms(50);
                continue;
            }

            /* Erase active-cart flash region + program ROM + bytecode. */
            p8_cart_flash_erase_all();

            size_t rom_padded = (rom_len + 255) & ~255u;
            const void *rom_xip = p8_cart_flash_program(
                rom_data, rom_len, 0);
            const void *bc_xip = p8_cart_flash_program(
                luac_data, luac_len, rom_padded);

            free(rom_data);  rom_data = NULL;
            free(luac_data); luac_data = NULL;

            if (!rom_xip || !bc_xip) {
                p8_log_to_file("load: flash program failed");
                continue;
            }

            /* Copy ROM from XIP flash into machine.mem. Also point
             * machine.rom to the XIP flash copy so reload() can read
             * back the original without any SRAM cost. */
            size_t rom_copy = rom_len;
            if (rom_copy > 0x4300) rom_copy = 0x4300;
            memcpy(machine.mem, rom_xip, rom_copy);
            machine.rom = (const uint8_t *)rom_xip;
            machine.rom_len = rom_copy;

            /* Load bytecode from XIP. Patched lundump.c detects
             * IS_XIP_ADDR(Z->p) → Proto.code[] stays in flash. */
            if (luaL_loadbuffer(vm.L, (const char *)bc_xip,
                                luac_len, "=cart") != LUA_OK) {
                const char *m = lua_tostring(vm.L, -1);
                char buf[160];
                snprintf(buf, sizeof(buf), "load: bytecode: %s",
                         m ? m : "(no msg)");
                p8_log_to_file(buf);
                lua_pop(vm.L, 1);
                continue;
            }
            /* Execute top-level cart code. */
            if (lua_pcall(vm.L, 0, 0, 0) != LUA_OK) {
                const char *m = lua_tostring(vm.L, -1);
                char buf[160];
                snprintf(buf, sizeof(buf), "load: top-level: %s",
                         m ? m : "(no msg)");
                p8_log_to_file(buf);
                lua_pop(vm.L, 1);
                continue;
            }
            p8_log_to_file("load: ok");
        }

        /* Override any Lua-defined functions with C native versions
         * (e.g. px9_decomp needs uint32_t precision). */
        p8_api_post_load(&vm);

        /* Force a GC cycle to reclaim compile/load transients. */
        lua_gc(vm.L, LUA_GCCOLLECT, 0);

        /* Run _init and capture any error explicitly so we can
         * surface and log it the same way as _update/_draw errors. */
        p8_log_ring("_init enter");
        {
            lua_getglobal(vm.L, "_init");
            if (lua_isfunction(vm.L, -1)) {
                if (lua_pcall(vm.L, 0, 0, 0) != LUA_OK) {
                    const char *m = lua_tostring(vm.L, -1);
                    char buf[160];
                    snprintf(buf, sizeof(buf), "_init: %s",
                             m ? m : "(no msg)");
                    p8_log_to_file(buf);
                    /* Show error and wait for MENU. */
                    p8_machine_reset(&machine);
                    p8_camera(&machine, 0, 0);
                    p8_cls(&machine, 8);
                    p8_font_draw(&machine, "_init error",       28,  4, 7);
                    p8_font_draw(&machine, cart_entries[chosen].name,
                                 4, 14, 7);
                    int y = 28;
                    int len = (int)strlen(buf);
                    for (int s = 0; s < len && y < 110; s += 30) {
                        char line[32] = {0};
                        int chunk = (len - s > 30) ? 30 : (len - s);
                        memcpy(line, buf + s, chunk);
                        p8_font_draw(&machine, line, 2, y, 7);
                        y += 8;
                    }
                    p8_font_draw(&machine, "MENU = picker", 20, 116, 10);
                    p8_machine_present(&machine, scanline);
                    p8_lcd_wait_idle();
                    p8_lcd_present(scanline);
                    while (!p8_buttons_menu_pressed()) sleep_ms(50);
                    /* Leak VM — lua_close can panic on OOM. */
                    continue;
                }
            } else {
                lua_pop(vm.L, 1);
            }
        }
        p8_log_to_file("_init: ok");
        p8_log_ring("_init ok");

        int has_update60 = 0;
        {
            lua_getglobal(vm.L, "_update60");
            has_update60 = lua_isfunction(vm.L, -1);
            lua_pop(vm.L, 1);
        }
        const char *update_fn = has_update60 ? "_update60" : "_update";
        int target_fps = has_update60 ? 60 : 30;
        uint32_t frame_us = 1000000u / (uint32_t)target_fps;

        uint32_t frame = 0;
        absolute_time_t next = make_timeout_time_us(frame_us);
        /* Record cart start time so time()/t() returns accurate seconds. */
        uint64_t cart_start_us = time_us_64();

        /* Run until the user exits via menu, or a Lua error fires. */
        int return_to_picker = 0;
        char err_msg[160] = {0};
        uint32_t menu_hold_start = 0;
        int menu_was_pressed = 0;

        while (!return_to_picker) {
            write_frame_count(&machine, frame);
            write_elapsed_ms(&machine,
                (uint32_t)((time_us_64() - cart_start_us) / 1000));

            uint8_t btn = p8_buttons_read();
            p8_input_begin_frame(&input, btn);

            /* MENU button: long press (>400ms) opens the pause menu. */
            if (p8_buttons_menu_pressed()) {
                if (!menu_was_pressed) {
                    menu_hold_start = (uint32_t)time_us_64();
                    menu_was_pressed = 1;
                }
                uint32_t held_ms = ((uint32_t)time_us_64() - menu_hold_start) / 1000;
                if (held_ms > 400) {
                    /* Build menu items */
                    #define P8_MENU_ACT_CUSTOM_BASE 100
                    p8_menu_item_t items[16];
                    int ni = 0;

                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_ACTION, .label = "Resume",
                        .enabled = true, .action_id = P8_MENU_ACT_RESUME };

                    /* Cart-registered custom menu items */
                    {
                        const char *mi_labels[5];
                        int mi_count = p8_api_get_menuitems(mi_labels, 5);
                        for (int mi = 0; mi < mi_count; mi++) {
                            items[ni++] = (p8_menu_item_t){
                                .kind = P8_MENU_KIND_ACTION,
                                .label = mi_labels[mi],
                                .enabled = true,
                                .action_id = P8_MENU_ACT_CUSTOM_BASE + mi };
                        }
                    }

                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_SLIDER, .label = "Volume",
                        .value_ptr = &master_volume,
                        .min = VOL_MIN, .max = VOL_MAX, .enabled = true };

                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_TOGGLE, .label = "Show FPS",
                        .value_ptr = &show_fps_toggle, .enabled = true };

                    /* Disk space */
                    static int disk_used_pct = 0;
                    static char disk_text[24];
                    {
                        DWORD free_clust = 0;
                        FATFS *fsp = NULL;
                        if (f_getfree("", &free_clust, &fsp) == FR_OK && fsp) {
                            DWORD total = (fsp->n_fatent - 2) * fsp->csize;
                            DWORD free_sect = free_clust * fsp->csize;
                            DWORD used = total - free_sect;
                            /* Sector size is 512 bytes */
                            int used_kb = (int)(used / 2);
                            int total_kb = (int)(total / 2);
                            disk_used_pct = total > 0 ? (int)(used * 100 / total) : 0;
                            snprintf(disk_text, sizeof(disk_text), "%dK/%dK",
                                     used_kb, total_kb);
                        } else {
                            disk_used_pct = 0;
                            snprintf(disk_text, sizeof(disk_text), "?");
                        }
                    }
                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_INFO, .label = "Disk",
                        .info_text = disk_text, .value_ptr = &disk_used_pct,
                        .min = 0, .max = 100, .enabled = true };

                    /* Battery info */
                    static int batt_pct = 0;
                    static char batt_text[16];
                    float bv = 3.7f; /* placeholder — no ADC on emulator */
                    batt_pct = (int)((bv - 3.0f) / (4.2f - 3.0f) * 100);
                    if (batt_pct < 0) batt_pct = 0;
                    if (batt_pct > 100) batt_pct = 100;
                    snprintf(batt_text, sizeof(batt_text), "%d%%", batt_pct);
                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_INFO, .label = "Battery",
                        .info_text = batt_text, .value_ptr = &batt_pct,
                        .min = 0, .max = 100, .enabled = true };

                    items[ni++] = (p8_menu_item_t){
                        .kind = P8_MENU_KIND_ACTION, .label = "Quit to picker",
                        .enabled = true, .action_id = P8_MENU_ACT_QUIT };

                    /* Present the last game frame to scanline for the menu overlay */
                    p8_machine_present(&machine, scanline);

                    p8_menu_result_t mr = p8_menu_run(scanline,
                        (uint16_t *)&machine.mem[0x8000],
                        "ThumbyP8",
                        cart_entries[chosen].name, items, ni);

                    if (mr.kind == P8_MENU_ACTION && mr.action_id == P8_MENU_ACT_QUIT) {
                        /* Save settings, flush, and reboot to fully
                         * reclaim heap (lua_close can panic on OOM). */
                        settings_save();
                        p8_flash_disk_flush();
                        watchdog_reboot(0, 0, 0);
                        while (1) tight_loop_contents();
                    }
                    /* Handle cart-registered custom menu items */
                    if (mr.kind == P8_MENU_ACTION &&
                        mr.action_id >= P8_MENU_ACT_CUSTOM_BASE) {
                        int ci = mr.action_id - P8_MENU_ACT_CUSTOM_BASE;
                        /* Button bitmask: A was pressed = bits 4+5+6 */
                        p8_api_menuitem_invoke(&vm, ci, 0x70);
                    }
                    /* Save settings in case volume/FPS changed. */
                    settings_save();
                    /* Resume — reset frame timer so the game doesn't
                     * fast-forward to catch up with elapsed real time. */
                    while (p8_buttons_menu_pressed()) sleep_ms(10);
                    next = make_timeout_time_us(frame_us);
                    menu_was_pressed = 0;
                    continue;
                }
            } else {
                menu_was_pressed = 0;
            }

            /* Single update + single draw per cycle. */
            for (int phase = 0; phase < 2; phase++) {
                const char *fn = (phase == 0) ? update_fn : "_draw";
                lua_getglobal(vm.L, fn);
                if (!lua_isfunction(vm.L, -1)) {
                    lua_pop(vm.L, 1);
                    continue;
                }
                if ((frame % 30) == 0 && phase == 0) {
                    char tag[32];
                    snprintf(tag, sizeof(tag), "frame %lu",
                             (unsigned long)frame);
                    p8_log_ring(tag);
                }
                if (lua_pcall(vm.L, 0, 0, 0) != LUA_OK) {
                    const char *m = lua_tostring(vm.L, -1);
                    snprintf(err_msg, sizeof(err_msg),
                             "%s: %s", fn, m ? m : "(no msg)");
                    lua_pop(vm.L, 1);
                    p8_log_to_file(err_msg);
                    goto cart_error;
                }
            }

            /* Audio: fill in 512-sample chunks to keep BSS small. */
            {
                static int16_t audio_buf[512];
                int room = p8_audio_pwm_room();
                while (room > 0) {
                    int n = room < 512 ? room : 512;
                    p8_audio_render(audio_buf, n);
                    if (master_volume != VOL_UNITY) {
                        if (master_volume <= 0) {
                            for (int i2 = 0; i2 < n; i2++) audio_buf[i2] = 0;
                        } else {
                            for (int i2 = 0; i2 < n; i2++) {
                                int32_t s2 = (int32_t)audio_buf[i2] * master_volume / VOL_UNITY;
                                if (s2 >  32767) s2 =  32767;
                                if (s2 < -32768) s2 = -32768;
                                audio_buf[i2] = (int16_t)s2;
                            }
                        }
                    }
                    p8_audio_pwm_push(audio_buf, n);
                    room -= n;
                }
            }

            /* FPS counter overlay — toggled via pause menu. */
            if (show_fps_toggle) {
                static uint32_t fps_last_us = 0;
                static int fps_display = 0;
                static int fps_count = 0;
                uint32_t now_us = (uint32_t)time_us_64();
                fps_count++;
                if (now_us - fps_last_us >= 1000000) {
                    fps_display = fps_count;
                    fps_count = 0;
                    fps_last_us = now_us;
                }
                int16_t saved_cx = p8_camera_x(&machine);
                int16_t saved_cy = p8_camera_y(&machine);
                p8_camera(&machine, 0, 0);
                char fps_str[8];
                snprintf(fps_str, sizeof(fps_str), "%d", fps_display);
                int fw = (int)strlen(fps_str) * P8_FONT_CELL_W;
                p8_font_draw(&machine, fps_str, 127 - fw, 1, 11);
                p8_set_camera(&machine, saved_cx, saved_cy);
            }

            p8_lcd_wait_idle();
            p8_machine_present(&machine, scanline);
            p8_lcd_present(scanline);

            sleep_until(next);
            next = delayed_by_us(next, frame_us);
            frame++;
        }
        goto after_cart;

cart_error:
        /* Show the error on screen and wait for MENU to return. */
        {
            p8_machine_reset(&machine);
            p8_camera(&machine, 0, 0);
            p8_cls(&machine, 8);   /* red */
            p8_font_draw(&machine, "lua error",          32,  4, 7);
            p8_font_draw(&machine, cart_entries[chosen].name, 4, 14, 7);
            /* Wrap the error text across lines (~30 chars per line). */
            int y = 28;
            int len = (int)strlen(err_msg);
            for (int s = 0; s < len && y < 110; s += 30) {
                char line[32] = {0};
                int chunk = (len - s > 30) ? 30 : (len - s);
                memcpy(line, err_msg + s, chunk);
                p8_font_draw(&machine, line, 2, y, 7);
                y += 8;
            }
            p8_font_draw(&machine, "MENU = picker", 20, 116, 10);
            p8_machine_present(&machine, scanline);
            p8_lcd_wait_idle();
            p8_lcd_present(scanline);

            /* Idle until MENU pressed. Don't service USB. */
            while (!p8_buttons_menu_pressed()) {
                sleep_ms(50);
            }
        }
after_cart: ;

        /* DO NOT call p8_vm_free / lua_close here. lua_close runs
         * GC finalizers which may try to allocate (e.g. to resize
         * internal buffers during sweep). If the Lua heap is near
         * the cap, that allocation hits the cap → lua_atpanic →
         * abort() → hardfault. We just leak the VM — the outer
         * loop is about to create a new one for the next cart, and
         * malloc doesn't care about unreferenced heap blocks.
         *
         * For extra safety, NULL out the trace hook so stale
         * pointers from this VM cycle don't fire into freed ring
         * slots. */
        p8_trace_hook = NULL;
        if (g_cartdata_active) {
            p8_flash_disk_flush();  /* flush any pending save data */
            g_cartdata_active = 0;
        }
    }
    return 0;
}
