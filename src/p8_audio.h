/*
 * ThumbyP8 — PICO-8-compatible audio synth.
 *
 * 4 channels, each playing one SFX (32 notes). Music is a
 * sequence of patterns; each pattern assigns up to 4 SFX to
 * channels and may flag loop start / loop end / stop.
 *
 * Synth model is subtractive-ish with 8 fixed waveform shapes
 * (triangle, tilted-triangle, sawtooth, square, pulse, organ,
 * noise, phaser). Per-note effects: slide, vibrato, drop,
 * fade-in, fade-out, arpeggio fast/slow.
 *
 * Output: signed 16-bit mono samples at P8_AUDIO_SAMPLE_RATE.
 * The host runner pulls samples via p8_audio_render(); the
 * device main pushes them out via PWM/DMA.
 *
 * SFX/music data live inside p8_machine.mem at:
 *   0x3100..0x31ff   music: 64 patterns * 4 bytes
 *   0x3200..0x42ff   sfx:   64 sfx * 68 bytes
 */
#ifndef THUMBYP8_AUDIO_H
#define THUMBYP8_AUDIO_H

#include <stdint.h>
#include "p8_machine.h"

#define P8_AUDIO_SAMPLE_RATE 22050
#define P8_AUDIO_CHANNELS    4

/* Bind the synth to a machine. Must be called before render(). */
void p8_audio_init(p8_machine *m);

/* Start playing SFX `n` on `channel` (or auto-pick a free one
 * if channel < 0). offset/length in notes (0/0 = whole sfx). */
void p8_audio_sfx(int n, int channel, int offset, int length);

/* Start (or stop, if n<0) music pattern `n`. fade_len in ms,
 * channel_mask: bitfield 0..15 of channels to use; 0 = default. */
void p8_audio_music(int n, int fade_len, int channel_mask);

/* Render `n_samples` mono int16 frames into out. Advances synth
 * state by n_samples. Mixes all 4 channels with equal weight. */
void p8_audio_render(int16_t *out, int n_samples);

/* PICO-8 stat() queries the synth: 16..19 = current SFX on each
 * channel (-1 = none), 20..23 = current note within that SFX. */
int p8_audio_stat(int n);

#endif
