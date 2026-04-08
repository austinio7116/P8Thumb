/*
 * ThumbyP8 — Thumby Color device runtime entry point.
 *
 * Boots the chip at 250 MHz, brings up the LCD and buttons,
 * loads the embedded cart, and runs the PICO-8 update/draw loop
 * at 30 fps. The framebuffer is presented via DMA to the GC9107.
 *
 * The cart is baked into the firmware via tools/embed_cart.py.
 * No filesystem yet — Phase 6 territory.
 */
#include <stdio.h>
#include <string.h>

#include "pico/stdlib.h"
#include "pico/time.h"
#include "hardware/clocks.h"

#include "p8.h"
#include "p8_machine.h"
#include "p8_input.h"
#include "p8_api.h"
#include "p8_cart.h"
#include "p8_audio.h"

#include "p8_lcd_gc9107.h"
#include "p8_buttons.h"
#include "p8_audio_pwm.h"
#include "embedded_cart.h"

/* Static memory: machine + scanline DMA buffer. The framebuffer
 * lives inside p8_machine.mem at 0x6000; we expand it into this
 * RGB565 buffer once per frame for the LCD push. */
static p8_machine machine;
static p8_input   input;
static uint16_t   scanline[128 * 128];

static void write_frame_count(p8_machine *m, uint32_t fc) {
    m->mem[P8_DRAWSTATE + 0x34] = (uint8_t)(fc & 0xff);
    m->mem[P8_DRAWSTATE + 0x35] = (uint8_t)((fc >> 8) & 0xff);
    m->mem[P8_DRAWSTATE + 0x36] = (uint8_t)((fc >> 16) & 0xff);
    m->mem[P8_DRAWSTATE + 0x37] = (uint8_t)((fc >> 24) & 0xff);
}

int main(void) {
    /* Overclock to 250 MHz BEFORE stdio_init_all so the USB PLL
     * comes up at the right divider. Same as Phase 0.5 bench. */
    set_sys_clock_khz(250000, true);

    stdio_init_all();
    setvbuf(stdout, NULL, _IONBF, 0);

    /* Hardware bring-up */
    p8_buttons_init();
    p8_lcd_init();
    p8_audio_pwm_init();

    /* Splash: clear to PICO-8 dark blue so we can see the LCD is alive
     * even before the cart loads. */
    for (int i = 0; i < 128 * 128; i++) scanline[i] = 0x194a;
    p8_lcd_present(scanline);
    p8_lcd_wait_idle();

    /* VM + machine + cart */
    p8_machine_reset(&machine);
    p8_input_reset(&input);

    p8_vm vm;
    if (p8_vm_init(&vm, 0) != 0) {
        /* OOM at boot — flash red and idle. */
        for (int i = 0; i < 128 * 128; i++) scanline[i] = 0xf800;
        p8_lcd_present(scanline);
        while (1) tight_loop_contents();
    }
    p8_api_install(&vm, &machine, &input);

    p8_cart cart;
    if (p8_cart_load_from_memory(&cart, &machine,
            (const char *)embedded_cart, embedded_cart_len) != 0) {
        /* Magenta = cart parse failed. */
        for (int i = 0; i < 128 * 128; i++) scanline[i] = 0xf81f;
        p8_lcd_present(scanline);
        while (1) tight_loop_contents();
    }
    if (cart.lua_source && cart.lua_size > 0) {
        if (p8_vm_do_string(&vm, cart.lua_source, "=cart") != LUA_OK) {
            /* Yellow = Lua load error. We can't print to a screen
             * font yet, so signal with a solid color. */
            for (int i = 0; i < 128 * 128; i++) scanline[i] = 0xffe0;
            p8_lcd_present(scanline);
            while (1) tight_loop_contents();
        }
    }

    /* _init() once */
    p8_api_call_optional(&vm, "_init");

    /* Main loop — 30 fps. PICO-8 carts can use _update60 for 60 Hz;
     * we look it up once. */
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

    /* Pre-fill the audio ring with one frame of silence so the IRQ
     * has something to chew on while we boot the first cart frame. */
    {
        int16_t silence[1024] = {0};
        p8_audio_pwm_push(silence, 1024);
    }

    while (1) {
        write_frame_count(&machine, frame);

        /* Read physical buttons → input mask → frame begin */
        p8_input_begin_frame(&input, p8_buttons_read());

        /* Cart update + draw */
        p8_api_call_optional(&vm, update_fn);
        p8_api_call_optional(&vm, "_draw");

        /* Top up the audio ring buffer with this frame's worth of
         * synthesized samples. The IRQ pulls them at 22050 Hz. */
        {
            int n = P8_AUDIO_SAMPLE_RATE / target_fps;
            int16_t buf[1024];
            if (n > 1024) n = 1024;
            p8_audio_render(buf, n);
            p8_audio_pwm_push(buf, n);
        }

        /* Expand 4bpp framebuffer → RGB565 scanline → DMA to LCD */
        p8_lcd_wait_idle();
        p8_machine_present(&machine, scanline);
        p8_lcd_present(scanline);

        /* Pace the frame */
        sleep_until(next);
        next = delayed_by_us(next, frame_us);
        frame++;
    }
    return 0;
}
