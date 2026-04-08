/*
 * ThumbyP8 — SDL2 host runner.
 *
 * Loads a .p8 cart, runs the PICO-8 update/draw loop at 30 fps,
 * presents the framebuffer in a 4×-scaled SDL window. The host
 * is purely a stand-in for the eventual RP2350 main loop — the
 * runtime, machine, and API code is shared verbatim with the
 * device build.
 *
 * Keyboard mapping (PICO-8 standard):
 *   arrows         dpad
 *   Z              O button
 *   X              X button
 *   Esc / window X quit
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <SDL.h>

#include "p8.h"
#include "p8_machine.h"
#include "p8_input.h"
#include "p8_api.h"
#include "p8_cart.h"

#define WIN_SCALE 4
#define WIN_W (P8_SCREEN_W * WIN_SCALE)
#define WIN_H (P8_SCREEN_H * WIN_SCALE)

/* Read SDL keyboard state into the PICO-8 6-bit button mask. */
static uint8_t poll_buttons(void) {
    const Uint8 *k = SDL_GetKeyboardState(NULL);
    uint8_t b = 0;
    if (k[SDL_SCANCODE_LEFT])  b |= 1 << P8_BTN_LEFT;
    if (k[SDL_SCANCODE_RIGHT]) b |= 1 << P8_BTN_RIGHT;
    if (k[SDL_SCANCODE_UP])    b |= 1 << P8_BTN_UP;
    if (k[SDL_SCANCODE_DOWN])  b |= 1 << P8_BTN_DOWN;
    if (k[SDL_SCANCODE_Z] || k[SDL_SCANCODE_C])
        b |= 1 << P8_BTN_O;
    if (k[SDL_SCANCODE_X] || k[SDL_SCANCODE_V])
        b |= 1 << P8_BTN_X;
    return b;
}

/* Dump the current 4bpp framebuffer as a PPM (P6) image — small,
 * universal, no library needed. Used by --screenshot for headless
 * validation. */
static void dump_ppm(const p8_machine *m, const char *path) {
    static const uint8_t pal_rgb[16][3] = {
        {0x00,0x00,0x00},{0x1d,0x2b,0x53},{0x7e,0x25,0x53},{0x00,0x87,0x51},
        {0xab,0x52,0x36},{0x5f,0x57,0x4f},{0xc2,0xc3,0xc7},{0xff,0xf1,0xe8},
        {0xff,0x00,0x4d},{0xff,0xa3,0x00},{0xff,0xec,0x27},{0x00,0xe4,0x36},
        {0x29,0xad,0xff},{0x83,0x76,0x9c},{0xff,0x77,0xa8},{0xff,0xcc,0xaa},
    };
    FILE *f = fopen(path, "wb");
    if (!f) { perror(path); return; }
    fprintf(f, "P6\n128 128\n255\n");
    for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
            uint8_t c = p8_fb_pget_raw(m, x, y);
            uint8_t mapped = m->mem[P8_DS_SCREEN_PAL + c] & 0x0f;
            fwrite(pal_rgb[mapped], 3, 1, f);
        }
    }
    fclose(f);
    fprintf(stderr, "wrote %s\n", path);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr,
            "usage: %s <cart.p8> [--screenshot N out.ppm]\n", argv[0]);
        return 1;
    }
    int  shot_frames = 0;
    const char *shot_path = NULL;
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "--screenshot") && i + 2 < argc) {
            shot_frames = atoi(argv[i+1]);
            shot_path   = argv[i+2];
            i += 2;
        }
    }

    /* --- VM + machine + input + cart -------------------------------- */
    p8_vm vm;
    if (p8_vm_init(&vm, 0) != 0) {
        fprintf(stderr, "vm init failed\n");
        return 1;
    }

    static p8_machine machine;
    p8_machine_reset(&machine);

    p8_input input;
    p8_input_reset(&input);

    p8_api_install(&vm, &machine, &input);

    p8_cart cart;
    if (p8_cart_load(&cart, &machine, argv[1]) != 0) {
        return 1;
    }

    if (cart.lua_source && cart.lua_size > 0) {
        if (p8_vm_do_string(&vm, cart.lua_source, "=cart") != LUA_OK) {
            fprintf(stderr, "cart load error: %s\n",
                    p8_vm_last_error_msg(&vm));
            return 1;
        }
    }

    /* --- SDL window ------------------------------------------------- */
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *win = SDL_CreateWindow(
        "ThumbyP8",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIN_W, WIN_H,
        SDL_WINDOW_SHOWN);
    if (!win) { fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError()); return 1; }

    /* Prefer accelerated; fall back to software (needed under
     * SDL_VIDEODRIVER=dummy and on hosts without GL). */
    SDL_Renderer *ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!ren) ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    if (!ren) { fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError()); return 1; }

    SDL_Texture *tex = SDL_CreateTexture(ren,
        SDL_PIXELFORMAT_RGB565,
        SDL_TEXTUREACCESS_STREAMING,
        P8_SCREEN_W, P8_SCREEN_H);
    if (!tex) { fprintf(stderr, "SDL_CreateTexture: %s\n", SDL_GetError()); return 1; }

    /* --- run _init() once ------------------------------------------ */
    p8_api_call_optional(&vm, "_init");

    /* --- main loop -------------------------------------------------- */
    /* PICO-8 carts can choose 30 or 60 fps via _update/_update60.
     * Phase 1+2 picks: if _update60 exists call that at 60Hz, else
     * call _update at 30Hz. */
    int has_update60 = 0;
    {
        lua_getglobal(vm.L, "_update60");
        has_update60 = lua_isfunction(vm.L, -1);
        lua_pop(vm.L, 1);
    }
    const char *update_fn = has_update60 ? "_update60" : "_update";
    int target_fps = has_update60 ? 60 : 30;
    Uint32 frame_ms = 1000 / target_fps;

    static uint16_t scanline[P8_SCREEN_W * P8_SCREEN_H];

    int running = 1;
    int frame_count = 0;
    Uint32 next_tick = SDL_GetTicks();

    /* Write frame counter into draw-state memory so l_p8_time() can
     * read it without having to plumb a separate pointer. */
    #define WRITE_FRAMES(m, fc) do {                                  \
        (m).mem[P8_DRAWSTATE + 0x34] = (uint8_t)((fc) & 0xff);        \
        (m).mem[P8_DRAWSTATE + 0x35] = (uint8_t)(((fc) >> 8) & 0xff); \
        (m).mem[P8_DRAWSTATE + 0x36] = (uint8_t)(((fc) >> 16) & 0xff);\
        (m).mem[P8_DRAWSTATE + 0x37] = (uint8_t)(((fc) >> 24) & 0xff);\
    } while (0)

    while (running) {
        WRITE_FRAMES(machine, frame_count);
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE)
                running = 0;
        }

        /* Update input state from keyboard */
        p8_input_begin_frame(&input, poll_buttons());

        /* _update() then _draw() */
        if (p8_api_call_optional(&vm, update_fn) != 0) running = 0;
        if (p8_api_call_optional(&vm, "_draw")    != 0) running = 0;

        /* Present: expand 4bpp framebuffer to RGB565 then upload */
        p8_machine_present(&machine, scanline);
        SDL_UpdateTexture(tex, NULL, scanline, P8_SCREEN_W * sizeof(uint16_t));
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, NULL, NULL);
        SDL_RenderPresent(ren);

        /* Frame pace */
        Uint32 now = SDL_GetTicks();
        next_tick += frame_ms;
        if (next_tick > now) SDL_Delay(next_tick - now);
        else next_tick = now;  /* avoid catch-up storms after a stall */

        frame_count++;
        if (shot_frames > 0 && frame_count >= shot_frames) {
            dump_ppm(&machine, shot_path);
            running = 0;
        }
    }

    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();

    p8_cart_free(&cart);
    p8_vm_free(&vm);
    return 0;
}
