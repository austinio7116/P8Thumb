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
#include "p8_audio.h"

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
    /* Route through p8_machine_present so screenshots match exactly
     * what the device LCD displays — including secret palette (128+)
     * mappings. Convert RGB565 → RGB888 per pixel. */
    static uint16_t scan[128 * 128];
    p8_machine_present(m, scan);
    FILE *f = fopen(path, "wb");
    if (!f) { perror(path); return; }
    fprintf(f, "P6\n128 128\n255\n");
    for (int i = 0; i < 128 * 128; i++) {
        uint16_t px = scan[i];
        uint8_t r = (uint8_t)(((px >> 11) & 0x1f) << 3);
        uint8_t g = (uint8_t)(((px >>  5) & 0x3f) << 2);
        uint8_t b = (uint8_t)(( px        & 0x1f) << 3);
        /* Replicate high bits into low bits for accuracy */
        r |= r >> 5;  g |= g >> 6;  b |= b >> 5;
        fputc(r, f); fputc(g, f); fputc(b, f);
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
        if (getenv("P8_DUMP_LUA")) {
            FILE *df = fopen(getenv("P8_DUMP_LUA"), "w");
            if (df) { fwrite(cart.lua_source, 1, cart.lua_size, df); fclose(df); }
        }
        if (p8_vm_do_string(&vm, cart.lua_source, "=cart") != LUA_OK) {
            fprintf(stderr, "cart load error: %s\n",
                    p8_vm_last_error_msg(&vm));
            return 1;
        }
    }

    /* --- SDL window + audio ----------------------------------------- */
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    /* Audio callback: SDL asks for `len` bytes of audio whenever its
     * ring buffer is half-empty. We render directly from p8_audio. */
    SDL_AudioSpec want = {0}, have = {0};
    want.freq = P8_AUDIO_SAMPLE_RATE;
    want.format = AUDIO_S16SYS;
    want.channels = 1;
    want.samples = 512;
    want.callback = NULL;   /* we'll use SDL_QueueAudio in the main loop */
    SDL_AudioDeviceID audio_dev = SDL_OpenAudioDevice(NULL, 0, &want, &have, 0);
    if (audio_dev == 0) {
        fprintf(stderr, "SDL_OpenAudioDevice: %s\n", SDL_GetError());
        /* Non-fatal: silent host run still works. */
    } else {
        SDL_PauseAudioDevice(audio_dev, 0);
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
    Uint32 start_ms  = SDL_GetTicks();

    /* Write frame counter (legacy, used by some code) and accurate
     * elapsed ms (used by time()/t()) into draw-state memory. */
    #define WRITE_TIME(m, fc, ms) do {                                       \
        (m).mem[P8_DRAWSTATE + 0x34] = (uint8_t)((fc) & 0xff);               \
        (m).mem[P8_DRAWSTATE + 0x35] = (uint8_t)(((fc) >> 8) & 0xff);        \
        (m).mem[P8_DRAWSTATE + 0x36] = (uint8_t)(((fc) >> 16) & 0xff);       \
        (m).mem[P8_DRAWSTATE + 0x37] = (uint8_t)(((fc) >> 24) & 0xff);       \
        (m).mem[P8_DS_ELAPSED_MS + 0] = (uint8_t)((ms) & 0xff);              \
        (m).mem[P8_DS_ELAPSED_MS + 1] = (uint8_t)(((ms) >> 8) & 0xff);       \
        (m).mem[P8_DS_ELAPSED_MS + 2] = (uint8_t)(((ms) >> 16) & 0xff);      \
        (m).mem[P8_DS_ELAPSED_MS + 3] = (uint8_t)(((ms) >> 24) & 0xff);      \
    } while (0)

    while (running) {
        uint32_t elapsed_ms = (uint32_t)(SDL_GetTicks() - start_ms);
        WRITE_TIME(machine, frame_count, elapsed_ms);
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE)
                running = 0;
        }

        /* Update input state from keyboard, or random input if
         * P8_FUZZ_INPUT=1 (used by fuzz harness to exercise more
         * code paths than just the title screen). */
        uint8_t btns = poll_buttons();
        if (getenv("P8_FUZZ_INPUT")) {
            /* Random buttons biased toward A (button 4) so we get
             * past title screens and into actual gameplay. Press A
             * pulse-style every ~30 frames; other buttons random. */
            unsigned r = (unsigned)(frame_count * 2654435761u);
            uint8_t fuzz_btns = 0;
            /* Button 4 (A/O): hold for 5 frames every 30 frames */
            if ((frame_count % 30) < 5) fuzz_btns |= (1 << 4);
            /* Other buttons: 25% per frame */
            for (int b = 0; b < 6; b++) {
                if (b == 4) continue;
                r = r * 2654435761u + 1;
                if ((r % 100) < 25) fuzz_btns |= (1 << b);
            }
            btns |= fuzz_btns;
        }
        p8_input_begin_frame(&input, btns);

        /* _update() then _draw() */
        if (p8_api_call_optional(&vm, update_fn) != 0) running = 0;
        if (p8_api_call_optional(&vm, "_draw")    != 0) running = 0;

        /* Audio: always queue enough samples to keep the output fed.
         * Render based on what SDL has consumed rather than a fixed
         * count, to avoid underruns on slow frames. Cap the queue
         * at ~200ms to limit latency. */
        if (audio_dev != 0) {
            Uint32 queued = SDL_GetQueuedAudioSize(audio_dev);
            Uint32 max_bytes = P8_AUDIO_SAMPLE_RATE * sizeof(int16_t) / 5; /* 200ms */
            if (queued < max_bytes) {
                int need = (int)(max_bytes - queued) / (int)sizeof(int16_t);
                if (need > 2048) need = 2048;
                int16_t buf[2048];
                p8_audio_render(buf, need);
                SDL_QueueAudio(audio_dev, buf, need * sizeof(int16_t));
            }
        }

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

        /* Periodic screenshot mode for fuzz harness:
         *   P8_SCREENSHOT_INTERVAL=N (frames between shots)
         *   P8_SCREENSHOT_PREFIX=path  (output basename, "_NNNN.ppm" appended)
         *   P8_SCREENSHOT_LIMIT=K (stop after K shots; 0 = no limit) */
        {
            static int interval = -1;
            static const char *prefix = NULL;
            static int limit = 0;
            static int taken = 0;
            if (interval < 0) {
                const char *iv = getenv("P8_SCREENSHOT_INTERVAL");
                interval = iv ? atoi(iv) : 0;
                prefix = getenv("P8_SCREENSHOT_PREFIX");
                const char *lm = getenv("P8_SCREENSHOT_LIMIT");
                limit = lm ? atoi(lm) : 0;
            }
            if (interval > 0 && prefix && (frame_count % interval) == 0) {
                char path[512];
                snprintf(path, sizeof(path), "%s_%04d.ppm", prefix, taken);
                dump_ppm(&machine, path);
                taken++;
                if (limit > 0 && taken >= limit) running = 0;
            }
        }
    }

    if (audio_dev != 0) SDL_CloseAudioDevice(audio_dev);
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();

    p8_cart_free(&cart);
    p8_vm_free(&vm);
    return 0;
}
