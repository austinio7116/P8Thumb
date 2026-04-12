/*
 * ThumbyP8 — RP2350 PWM audio driver.
 *
 * Hardware path:
 *   GP23 = PWM audio output (9-bit, ~292 kHz carrier)
 *   GP20 = audio amplifier enable
 *   PWM slice 4 = sample-rate timer (22050 Hz IRQ)
 *
 * The IRQ handler is the synth's "consumer side": it pulls one sample
 * per fire from a small ring buffer that the main loop refills each
 * frame from p8_audio_render(). Buffer size is sized so a 30 fps
 * frame (735 samples) fits comfortably with margin.
 */
#ifndef THUMBYP8_AUDIO_PWM_H
#define THUMBYP8_AUDIO_PWM_H

#include <stdint.h>

void p8_audio_pwm_init(void);

/* Push `n_samples` of int16 mono PCM into the ring buffer. Drops
 * samples if the buffer is full (which would mean the producer is
 * outpacing the IRQ — should never happen at our rates). */
void p8_audio_pwm_push(const int16_t *samples, int n_samples);

/* How much room is currently in the ring buffer (in samples). */
int  p8_audio_pwm_room(void);

/* Master volume: 0 (mute) to 10 (full). Applied in push(). */
void p8_audio_pwm_set_volume(int vol);
int  p8_audio_pwm_get_volume(void);

#endif
