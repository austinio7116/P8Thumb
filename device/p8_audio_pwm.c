/*
 * ThumbyP8 — RP2350 PWM audio driver.
 *
 * Two PWM slices in use:
 *   - Slice for GP23: 9-bit PWM running at clk_sys / 512. The duty
 *     cycle IS the audio sample. At 250 MHz this gives a ~488 kHz
 *     carrier, well above audible range so the LPF on the amp can
 *     reconstruct cleanly.
 *   - Slice 4: configured as a hardware timer. Wrap at clk_sys /
 *     22050 so it fires an IRQ exactly once per audio sample.
 *
 * The IRQ pulls the next sample from a ring buffer and writes it
 * to GP23's duty register. The main loop tops the ring up each
 * game frame from p8_audio_render().
 */
#include "p8_audio_pwm.h"

#include "pico/stdlib.h"
#include "hardware/pwm.h"
#include "hardware/irq.h"
#include "hardware/clocks.h"
#include "hardware/gpio.h"

#define AUDIO_PWM_PIN     23
#define AUDIO_ENABLE_PIN  20
#define TIMER_SLICE        4
#define SAMPLE_RATE     22050
#define PWM_WRAP          512   /* 9-bit DAC */

/* Ring buffer: ~3 frames @ 30 fps worth of samples = 2205 frames.
 * Round up to a power of 2 for fast wrap. */
#define RING_SIZE 4096
#define RING_MASK (RING_SIZE - 1)

static volatile int16_t ring[RING_SIZE];
static volatile uint32_t ring_head = 0;   /* producer (main) */
static volatile uint32_t ring_tail = 0;   /* consumer (IRQ) */

/* IRQ handler: fires once per audio sample. Pull one sample from
 * the ring (or 0 if underflow), bias to 0..PWM_WRAP, write duty. */
static void __isr __not_in_flash_func(audio_irq) (void) {
    pwm_clear_irq(TIMER_SLICE);

    int16_t s = 0;
    uint32_t t = ring_tail;
    if (t != ring_head) {
        s = ring[t & RING_MASK];
        ring_tail = t + 1;
    }
    /* Map int16 [-32768..32767] → uint [0..PWM_WRAP-1].
     * Bias by half so silence sits in the middle of the swing. */
    int v = ((int)s + 32768) >> 7;        /* /128 → ~511 max */
    if (v < 0) v = 0;
    if (v >= PWM_WRAP) v = PWM_WRAP - 1;
    pwm_set_gpio_level(AUDIO_PWM_PIN, (uint32_t)v);
}

void p8_audio_pwm_init(void) {
    /* Audio amp off until carrier is stable. */
    gpio_init(AUDIO_ENABLE_PIN);
    gpio_set_dir(AUDIO_ENABLE_PIN, GPIO_OUT);
    gpio_put(AUDIO_ENABLE_PIN, 0);

    /* Audio output PWM on GP23: 9-bit DAC carrier. */
    gpio_set_function(AUDIO_PWM_PIN, GPIO_FUNC_PWM);
    uint pwm_slice = pwm_gpio_to_slice_num(AUDIO_PWM_PIN);
    pwm_config audio_cfg = pwm_get_default_config();
    pwm_config_set_clkdiv_int(&audio_cfg, 1);
    pwm_config_set_wrap(&audio_cfg, PWM_WRAP);
    pwm_init(pwm_slice, &audio_cfg, true);
    /* Start at silence (mid-rail). */
    pwm_set_gpio_level(AUDIO_PWM_PIN, PWM_WRAP / 2);

    /* Sample-rate timer on slice 4. Wrap at clk_sys / SAMPLE_RATE so
     * the WRAP IRQ fires SAMPLE_RATE times per second. */
    pwm_clear_irq(TIMER_SLICE);
    pwm_set_irq_enabled(TIMER_SLICE, true);
    irq_set_exclusive_handler(PWM_IRQ_WRAP, audio_irq);
    /* Audio IRQ priority: deliberately LOWER than USB so enumeration
     * isn't starved. The audio handler runs at 22050 Hz and is short,
     * but back-to-back PWM IRQs at higher priority can lock USB out
     * for whole control transfers. PICO_LOWEST_IRQ_PRIORITY pushes
     * us below the SDK default (which TinyUSB uses). */
    irq_set_priority(PWM_IRQ_WRAP, PICO_LOWEST_IRQ_PRIORITY);
    irq_set_enabled(PWM_IRQ_WRAP, true);

    pwm_config timer_cfg = pwm_get_default_config();
    pwm_config_set_clkdiv_int(&timer_cfg, 1);
    pwm_config_set_wrap(&timer_cfg,
        (uint16_t)((clock_get_hz(clk_sys) / SAMPLE_RATE) - 1));
    pwm_init(TIMER_SLICE, &timer_cfg, true);

    /* Enable amp. */
    gpio_put(AUDIO_ENABLE_PIN, 1);
}

void p8_audio_pwm_push(const int16_t *samples, int n_samples) {
    for (int i = 0; i < n_samples; i++) {
        uint32_t h = ring_head;
        if ((h - ring_tail) >= RING_SIZE) break;   /* ring full, drop */
        ring[h & RING_MASK] = samples[i];
        ring_head = h + 1;
    }
}

int p8_audio_pwm_room(void) {
    return RING_SIZE - (int)(ring_head - ring_tail);
}
