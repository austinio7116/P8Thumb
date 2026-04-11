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

/* Set by boot_filesystem(): 1 if we ran f_mkfs at boot (label
 * mismatch / no FS / MENU forced), 0 if the existing FS was kept.
 * Surfaced in the lobby so we can tell on the next boot whether
 * the previous session's writes survived. */
static int g_boot_reformatted = 0;

/* Forward decl — `scanline` is defined later in this file. */
static uint16_t scanline[128 * 128];

/* HardFault handler — invoked by the Cortex-M when a memory or
 * usage fault fires (typically a NULL deref, unaligned access, or
 * stack overflow). Without this, the chip just hangs silently
 * and the user sees a frozen screen. With this, we paint the
 * screen red and write a log entry so the next boot's log file
 * shows the cause. */
void __not_in_flash_func(isr_hardfault)(void) {
    p8_log_to_file("!!! HARDFAULT — see ring dump for last events");
    p8_log_dump_ring();
    p8_flash_disk_flush();
    for (int i = 0; i < 128 * 128; i++) scanline[i] = 0xf800;
    p8_lcd_present(scanline);
    while (1) tight_loop_contents();
}

/* Static memory: machine + scanline DMA buffer + cart entry table.
 * `scanline` was forward-declared above so the hardfault handler
 * can write to it. */
static p8_machine     machine;
static p8_input       input;
static p8_cart_entry  cart_entries[P8_PICKER_MAX_CARTS];
static FATFS          fs;

static void write_frame_count(p8_machine *m, uint32_t fc) {
    m->mem[P8_DRAWSTATE + 0x34] = (uint8_t)(fc & 0xff);
    m->mem[P8_DRAWSTATE + 0x35] = (uint8_t)((fc >> 8) & 0xff);
    m->mem[P8_DRAWSTATE + 0x36] = (uint8_t)((fc >> 16) & 0xff);
    m->mem[P8_DRAWSTATE + 0x37] = (uint8_t)((fc >> 24) & 0xff);
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
        /* Yellow splash so we can tell from outside whether reformat
         * actually ran. */
        splash(0xffe0);

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
        /* A or B exits the lobby. Gated on (a) at least one cart
         * present and (b) cache fully drained — the on-screen
         * "drive idle" indicator tells the user when this is true.
         * No synchronous flush on press; the user waits for clean. */
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
            p8_cls(&machine, 1);
            p8_font_draw(&machine, "ThumbyP8", 40, 4, 7);

            char line[40];
            snprintf(line, sizeof(line), "%d cart%s on disk",
                     n_carts, n_carts == 1 ? "" : "s");
            int lx = (128 - (int)strlen(line) * P8_FONT_CELL_W) / 2;
            p8_font_draw(&machine, line, lx, 16, 6);

            /* Diagnostic line 1: w c d e i (write/commit/dirty/eject/idle-ms)
             * Diagnostic line 2: x v r b s (commit-errors/verify/reformat/boot-state/btn-mask) */
            uint64_t now2 = (uint64_t)time_us_64();
            uint32_t since_op_ms =
                (uint32_t)((now2 - g_msc_last_op_us) / 1000);
            if (since_op_ms > 9999) since_op_ms = 9999;
            char diag[40];
            snprintf(diag, sizeof(diag), "w%lu c%lu d%lu e%d i%lu",
                     (unsigned long)p8_flash_disk_stat_writes(),
                     (unsigned long)p8_flash_disk_stat_commits(),
                     (unsigned long)p8_flash_disk_stat_dirty_n(),
                     g_msc_ejected,
                     (unsigned long)since_op_ms);
            p8_font_draw(&machine, diag, 2, 24, 5);

            char diag2[40];
            snprintf(diag2, sizeof(diag2), "x%lu r%d s%d b%02x",
                     (unsigned long)p8_flash_disk_stat_commit_errors(),
                     g_boot_reformatted,
                     state,
                     (unsigned int)p8_buttons_read());
            p8_font_draw(&machine, diag2, 2, 32, 5);

            switch (state) {
            case LOBBY_MOUNTED: {
                int on = (blink & 1);
                p8_font_draw(&machine, "usb mounted",   30, 40, on ? 12 : 1);
                p8_circfill(&machine, 64, 52, 2, on ? 12 : 1);
                if (p8_flash_disk_dirty()) {
                    p8_font_draw(&machine, "writes pending", 20, 68, 9);
                } else {
                    p8_font_draw(&machine, "drive idle",     32, 68, 6);
                }
                p8_font_draw(&machine, "drag .p8.png files",  4,  88, 6);
                p8_font_draw(&machine, "onto p8thumbv1",     16,  96, 6);
                p8_font_draw(&machine, "then eject in os",   12, 104, 6);
                break;
            }
            case LOBBY_FLUSHING: {
                int on = (blink & 1);
                p8_font_draw(&machine, "writing to flash", 10, 52, on ? 8 : 2);
                p8_circfill(&machine, 64, 68, 3, on ? 8 : 2);
                p8_font_draw(&machine, "do not power off",  8, 88, 9);
                break;
            }
            case LOBBY_READY: {
                p8_font_draw(&machine, "ready", 52, 52, 11);
                p8_circfill(&machine, 64, 68, 3, 11);
                if (n_carts > 0) {
                    p8_font_draw(&machine, "press A to play", 16, 96, 7);
                } else {
                    p8_font_draw(&machine, "no carts yet", 24, 96, 6);
                    p8_font_draw(&machine, "power cycle to reset", 0, 104, 6);
                }
                break;
            }
            }

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

    /* Stage 1: blue splash — LCD alive */
    splash(0x194a);

    /* Stage 2: filesystem comes up FIRST — before USB. Doing it the
     * other way around means USB tries to enumerate while mkfs is
     * mid-flight, the host reads inconsistent BPB state, and File
     * Explorer crashes when it tries to traverse a half-written
     * directory tree. */
    splash(0xfd00);   /* orange = mounting / formatting */
    p8_flash_disk_init();
    if (boot_filesystem() != 0) {
        splash(0xf81f);   /* magenta = mount/format failed */
        while (1) tight_loop_contents();
    }
    /* Force any cached writes (from mkfs) out to flash before the
     * USB host gets a chance to see the disk. */
    p8_flash_disk_flush();

    /* Always log a boot marker so the user has *something* in
     * /thumbyp8.log even when no cart errors fire. Helpful for
     * confirming the log path is alive. */
    p8_log_to_file("--- thumbyp8 boot ---");
    p8_log_to_file(g_boot_reformatted ? "fs: reformatted at boot"
                                       : "fs: kept existing volume");

    /* Stage 3: USB stack. Now the disk is fully on flash and we can
     * let the host enumerate and read consistent contents. */
    splash(0x07ff);   /* cyan = USB stack starting */
    tusb_init();
    {
        absolute_time_t until = make_timeout_time_ms(1000);
        while (!time_reached(until)) {
            tud_task();
            sleep_us(100);
        }
    }
    splash(0x07e0);   /* green = ready */

    /* Pre-fill audio ring with silence so the IRQ has something
     * to chew on while picker + cart load run. */
    {
        int16_t silence[1024] = {0};
        p8_audio_pwm_push(silence, 1024);
    }

    /* --- main outer loop: lobby → pick → run → repick on game exit -- */
    /* The lobby screen is the only USB-active mode. Once we leave
     * it the picker and game run with USB inert (no tud_task calls).
     * The user power-cycles back into the lobby if they want to
     * upload more carts. */
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
                                    cart_entries, n_carts);
        if (chosen < 0 || chosen >= n_carts) chosen = 0;

        /* Persist the cart we're about to launch so the log file
         * always shows what was running just before any hang. */
        {
            char line[80];
            snprintf(line, sizeof(line), "launch: %s",
                     cart_entries[chosen].name);
            p8_log_to_file(line);
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

        p8_vm vm;
        if (p8_vm_init(&vm, 0) != 0) {
            p8_log_to_file("load: lua VM init OOM");
            splash(0xf800);
            sleep_ms(1500);
            continue;
        }
        p8_api_install(&vm, &machine, &input);
        /* Route every traced binding into our RAM ring buffer so a
         * hardfault dump shows the last few bindings the cart called. */
        p8_trace_hook = p8_log_ring;

        /* --- Precompiled path only (.luac + .rom) ---
         *
         * All dialect translation and compilation happens on the
         * host via tools/p8png_extract.py. The device is a pure
         * bytecode executor. No C-side rewriter, no on-device
         * compilation, no fallback.
         */
        {
            char luac_name[P8_PICKER_NAME_MAX];
            char rom_name[P8_PICKER_NAME_MAX];
            strncpy(luac_name, cart_entries[chosen].name,
                    sizeof(luac_name) - 1);
            luac_name[sizeof(luac_name) - 1] = 0;
            strncpy(rom_name, luac_name, sizeof(rom_name) - 1);
            rom_name[sizeof(rom_name) - 1] = 0;
            size_t nL = strlen(luac_name);
            if (nL >= 3 && strcasecmp(luac_name + nL - 3, ".p8") == 0) {
                luac_name[nL - 3] = 0;
                rom_name[nL - 3] = 0;
            }
            strncat(luac_name, ".luac",
                    sizeof(luac_name) - strlen(luac_name) - 1);
            strncat(rom_name, ".rom",
                    sizeof(rom_name) - strlen(rom_name) - 1);

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
                p8_font_draw(&machine, "preprocess on host", 4, 36, 6);
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
                splash(0xf800);
                sleep_ms(1500);
                continue;
            }

            /* Copy ROM from XIP flash into machine.mem. */
            size_t rom_copy = rom_len;
            if (rom_copy > 0x4300) rom_copy = 0x4300;
            memcpy(machine.mem, rom_xip, rom_copy);

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
                splash(0xffe0);
                sleep_ms(1500);
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
                splash(0xffe0);
                sleep_ms(1500);
                continue;
            }
            p8_log_to_file("load: ok");
        }

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

        /* Run until the user holds MENU, or a Lua error fires. */
        int return_to_picker = 0;
        char err_msg[160] = {0};
        while (!return_to_picker) {
            write_frame_count(&machine, frame);

            uint8_t btn = p8_buttons_read();
            p8_input_begin_frame(&input, btn);
            if (p8_buttons_menu_pressed()) {
                return_to_picker = 1;
                break;
            }

            /* Call _update / _draw with explicit error capture so
             * any Lua runtime error gets surfaced to the user.
             * Each phase pushes a ring entry before AND after the
             * call so a hardfault dump shows precisely which call
             * was in flight. The "post" entry only lands if the
             * call returned cleanly — its absence in the ring is
             * the smoking gun for the faulting phase. */
            for (int phase = 0; phase < 2; phase++) {
                const char *fn = (phase == 0) ? update_fn : "_draw";
                lua_getglobal(vm.L, fn);
                if (!lua_isfunction(vm.L, -1)) {
                    lua_pop(vm.L, 1);
                    continue;
                }
                /* Periodic frame marker so the ring shows progress. */
                if ((frame % 30) == 0 && phase == 0) {
                    char tag[32];
                    snprintf(tag, sizeof(tag), "frame %lu", (unsigned long)frame);
                    p8_log_ring(tag);
                }
                p8_log_ring(phase == 0 ? "update enter" : "draw enter");
                if (lua_pcall(vm.L, 0, 0, 0) != LUA_OK) {
                    const char *m = lua_tostring(vm.L, -1);
                    snprintf(err_msg, sizeof(err_msg),
                             "%s: %s", fn, m ? m : "(no msg)");
                    lua_pop(vm.L, 1);
                    p8_log_ring("LUA ERROR");
                    p8_log_to_file(err_msg);
                    goto cart_error;
                }
                p8_log_ring(phase == 0 ? "update ok" : "draw ok");
            }

            /* Audio scratch in BSS, NOT on the stack — at 2 KB it
             * was eating into the 4 KB Pico SDK default stack and
             * combined with deep Lua VM calls during _update/_draw
             * was causing hard-to-diagnose stack-overflow hardfaults
             * mid-game. */
            static int16_t audio_buf[1024];
            int n = P8_AUDIO_SAMPLE_RATE / target_fps;
            if (n > 1024) n = 1024;
            p8_audio_render(audio_buf, n);
            p8_audio_pwm_push(audio_buf, n);

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
    }
    return 0;
}
