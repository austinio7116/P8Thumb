/*
 * ThumbyP8 — Thumby Color physical button reader.
 *
 * GPIO map (active low, internal pull-ups):
 *   GP0  LEFT     GP1  UP       GP2  RIGHT     GP3  DOWN
 *   GP21 A        GP25 B        GP6  LB        GP22 RB
 *   GP26 MENU
 *
 * Mapping to PICO-8 6-bit button mask:
 *   bit 0 LEFT  ← LEFT
 *   bit 1 RIGHT ← RIGHT
 *   bit 2 UP    ← UP
 *   bit 3 DOWN  ← DOWN
 *   bit 4 O     ← B (or LB)
 *   bit 5 X     ← A (or RB)
 *
 * The Thumby Color labels A on the right and B on the left, but
 * PICO-8's idiomatic mapping is X = jump (right button), O = action
 * (left button). We follow that convention so PICO-8 muscle memory
 * works with the physical layout.
 */
#include "p8_buttons.h"

#include "pico/stdlib.h"
#include "hardware/gpio.h"

#define BTN_LEFT_GP   0
#define BTN_UP_GP     1
#define BTN_RIGHT_GP  2
#define BTN_DOWN_GP   3
#define BTN_LB_GP     6
#define BTN_A_GP     21
#define BTN_RB_GP    22
#define BTN_B_GP     25
#define BTN_MENU_GP  26

static void init_pull_up(uint pin) {
    gpio_init(pin);
    gpio_set_dir(pin, GPIO_IN);
    gpio_pull_up(pin);
}

void p8_buttons_init(void) {
    init_pull_up(BTN_LEFT_GP);
    init_pull_up(BTN_UP_GP);
    init_pull_up(BTN_RIGHT_GP);
    init_pull_up(BTN_DOWN_GP);
    init_pull_up(BTN_LB_GP);
    init_pull_up(BTN_A_GP);
    init_pull_up(BTN_RB_GP);
    init_pull_up(BTN_B_GP);
    init_pull_up(BTN_MENU_GP);
}

/* Diagonal-assist input coalescing.
 *
 * The Thumby Color d-pad is a single rocker over a pivot — pressing
 * LEFT+UP simultaneously requires landing on an exact corner that
 * the physical geometry actively resists. Real PICO-8 carts (Celeste
 * especially) assume the player can hit diagonals trivially, so we
 * "smear" direction-bit history forward by P8_DIAG_FRAMES frames.
 *
 * Effect: a rapid LEFT-then-UP within (P8_DIAG_FRAMES / fps) seconds
 * is reported to the cart as both held simultaneously, which is
 * what the player meant. Action buttons (O/X) are never coalesced
 * — that would feel sticky on rapid jump presses.
 *
 * P8_DIAG_FRAMES = 3 → ~100 ms at 30 fps, ~50 ms at 60 fps. Small
 * enough that intentionally separate L then U presses still feel
 * separate. Bumpable at compile time if you want more lenience.
 */
#ifndef P8_DIAG_FRAMES
#define P8_DIAG_FRAMES 5
#endif

static uint8_t dir_history[P8_DIAG_FRAMES];
static int     dir_hist_idx = 0;

static uint8_t read_raw(void) {
    uint8_t b = 0;
    if (!gpio_get(BTN_LEFT_GP))  b |= 1 << 0;
    if (!gpio_get(BTN_RIGHT_GP)) b |= 1 << 1;
    if (!gpio_get(BTN_UP_GP))    b |= 1 << 2;
    if (!gpio_get(BTN_DOWN_GP))  b |= 1 << 3;
    if (!gpio_get(BTN_B_GP))     b |= 1 << 4;  /* O */
    if (!gpio_get(BTN_A_GP))     b |= 1 << 5;  /* X */

    /* Triggers as instant up-diagonal chords. The d-pad rocker is
     * mechanically hostile to corner presses, so the most useful
     * shoulder-button mapping is "give me a perfect up-diagonal".
     * LB = UP+LEFT, RB = UP+RIGHT — ideal for Celeste wall-jumps. */
    if (!gpio_get(BTN_LB_GP)) b |= (1 << 0) | (1 << 2);  /* L+U */
    if (!gpio_get(BTN_RB_GP)) b |= (1 << 1) | (1 << 2);  /* R+U */

    return b;
}

uint8_t p8_buttons_read(void) {
    uint8_t cur = read_raw();

    /* Push current direction bits into history ring */
    dir_history[dir_hist_idx] = cur & 0x0f;
    dir_hist_idx = (dir_hist_idx + 1) % P8_DIAG_FRAMES;

    /* OR direction bits across the window */
    uint8_t dirs = 0;
    for (int i = 0; i < P8_DIAG_FRAMES; i++) dirs |= dir_history[i];

    /* Action bits straight from current frame, no smearing. */
    return dirs | (cur & 0x30);
}

int p8_buttons_menu_pressed(void) {
    return !gpio_get(BTN_MENU_GP);
}
