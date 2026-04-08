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
#include "p8_draw.h"
#include "p8_font.h"
#include "p8_log.h"

/* Set by boot_filesystem(): 1 if we ran f_mkfs at boot (label
 * mismatch / no FS / MENU forced), 0 if the existing FS was kept.
 * Surfaced in the lobby so we can tell on the next boot whether
 * the previous session's writes survived. */
static int g_boot_reformatted = 0;

/* Static memory: machine + scanline DMA buffer + cart entry table. */
static p8_machine     machine;
static p8_input       input;
static uint16_t       scanline[128 * 128];
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
     * USB host gets a chance to see the disk. This is essential —
     * skipping it leaves the cache and XIP in different states and
     * Windows reads garbage. */
    p8_flash_disk_flush();

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

        /* Load + run the chosen cart. */
        size_t cart_len = 0;
        unsigned char *cart_bytes = p8_picker_load_cart(
            cart_entries[chosen].name, &cart_len);
        if (!cart_bytes) {
            splash(0xf800);
            sleep_ms(1500);
            continue;
        }

        p8_machine_reset(&machine);
        p8_input_reset(&input);

        p8_vm vm;
        if (p8_vm_init(&vm, 0) != 0) {
            free(cart_bytes);
            splash(0xf800);
            sleep_ms(1500);
            continue;
        }
        p8_api_install(&vm, &machine, &input);

        p8_cart cart;
        if (p8_cart_load_from_memory(&cart, &machine,
                (const char *)cart_bytes, cart_len) != 0) {
            free(cart_bytes);
            p8_vm_free(&vm);
            splash(0xf81f);
            sleep_ms(1500);
            continue;
        }
        free(cart_bytes);

        if (cart.lua_source && cart.lua_size > 0) {
            if (p8_vm_do_string(&vm, cart.lua_source, "=cart") != LUA_OK) {
                p8_cart_free(&cart);
                p8_vm_free(&vm);
                splash(0xffe0);
                sleep_ms(1500);
                continue;
            }
        }

        p8_api_call_optional(&vm, "_init");

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
             * any Lua runtime error gets surfaced to the user
             * (instead of silently producing a black screen). */
            for (int phase = 0; phase < 2; phase++) {
                const char *fn = (phase == 0) ? update_fn : "_draw";
                lua_getglobal(vm.L, fn);
                if (!lua_isfunction(vm.L, -1)) {
                    lua_pop(vm.L, 1);
                    continue;
                }
                if (lua_pcall(vm.L, 0, 0, 0) != LUA_OK) {
                    const char *m = lua_tostring(vm.L, -1);
                    snprintf(err_msg, sizeof(err_msg),
                             "%s: %s", fn, m ? m : "(no msg)");
                    lua_pop(vm.L, 1);
                    /* Persist for post-mortem inspection. */
                    p8_log_to_file(err_msg);
                    goto cart_error;
                }
            }

            int n = P8_AUDIO_SAMPLE_RATE / target_fps;
            int16_t audio_buf[1024];
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

        p8_cart_free(&cart);
        p8_vm_free(&vm);
    }
    return 0;
}
