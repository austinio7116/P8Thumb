/*
 * ThumbyP8 — PICO-8 audio synth implementation.
 *
 * Per-channel state machine: each tick (one PICO-8 "note time")
 * we read the next note from the active SFX, set up frequency
 * + waveform + envelope + effect, and produce samples until the
 * tick expires. Effects modulate frequency or volume across the
 * tick.
 *
 * Sample loop is the hot path. Kept in plain C for portability;
 * optimized version with viper-style fixed-point integer hot
 * loop will land in a later phase if profiling demands.
 *
 * Format reference (PICO-8 cart memory layout):
 *
 *   SFX entry @ 0x3200 + n*68:
 *     +0    editor mode (ignored at runtime)
 *     +1    note duration (ticks per note, in 2.4ms units * speed)
 *     +2    loop start note
 *     +3    loop end note
 *     +4..  32 notes * 2 bytes:
 *           bits 0-5  pitch (0-63, semitones from C0)
 *           bits 6-8  waveform 0..7
 *           bits 9-11 volume 0..7
 *           bits 12-14 effect 0..7
 *           bit 15    custom-instrument flag (we ignore)
 *
 *   Music entry @ 0x3100 + n*4:
 *     bytes encode 4 sfx slot IDs, with high bit = "no sound";
 *     additional flag bits 6/7 of byte 0 = loop start / loop end
 *     / stop. We model the documented subset.
 */
#include "p8_audio.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define SR        P8_AUDIO_SAMPLE_RATE
#define NCH       P8_AUDIO_CHANNELS
#define NOTES_PER_SFX 32

/* Per-channel synth state. */
typedef struct {
    int   sfx;              /* current SFX index, -1 = idle */
    int   note;             /* current note index 0..31 */
    int   start_note;       /* SFX play offset */
    int   end_note;         /* exclusive */
    int   loop;             /* nonzero = music loops the sfx */
    int   samples_left;     /* in current note */
    int   note_samples;     /* samples per note (set per-note from sfx speed) */
    /* Cached note data */
    uint8_t cur_pitch, cur_wave, cur_vol, cur_effect;
    uint8_t prev_pitch, prev_vol;
    /* Phase accumulator (Q16.16 fractional samples per cycle) */
    uint32_t phase;
    uint32_t phase_inc;     /* current freq's phase increment */
    /* Noise state */
    uint32_t noise_lfsr;
} p8_channel;

static p8_machine *g_machine = NULL;
static p8_channel  ch[NCH];

/* Music state */
static int music_pat = -1;
static int music_loop_start = -1;

/* --------- helpers --------------------------------------------------- */

/* Pitch number → frequency in Hz. PICO-8 pitch 0 = C0 (≈ 16.35 Hz),
 * each step is one semitone. */
static double pitch_to_freq(int pitch) {
    return 16.351597831287414 * pow(2.0, (double)pitch / 12.0);
}

/* Compute phase increment for the given pitch, as Q16.16 of "cycles
 * per sample" — feed to the waveform LUT below. */
static uint32_t pitch_to_inc(int pitch) {
    double freq = pitch_to_freq(pitch);
    double cps  = freq / (double)SR;        /* cycles per sample */
    return (uint32_t)(cps * 65536.0 * 65536.0);   /* Q16.16 */
}

/* Read a 16-bit note word out of an SFX. */
static uint16_t sfx_note_word(int sfx, int note) {
    int addr = 0x3200 + sfx * 68 + 4 + note * 2;
    return (uint16_t)g_machine->mem[addr]
         | ((uint16_t)g_machine->mem[addr + 1] << 8);
}

static int sfx_speed(int sfx) {
    return g_machine->mem[0x3200 + sfx * 68 + 1];
}
static int sfx_loop_start(int sfx) {
    return g_machine->mem[0x3200 + sfx * 68 + 2];
}
static int sfx_loop_end(int sfx) {
    return g_machine->mem[0x3200 + sfx * 68 + 3];
}

/* Convert sfx speed (1..255, 1 = fastest) to samples per note.
 * PICO-8: tick = 183 samples per "speed unit" at 22050 Hz. */
static int speed_to_samples(int speed) {
    if (speed < 1) speed = 1;
    return speed * 183;
}

/* Waveform lookup: phase is the high 16 bits of the Q16.16
 * accumulator (0..65535). Returns sample in [-1.0, +1.0]. */
static float wave_sample(uint8_t wave, uint16_t phase, uint32_t *noise_lfsr) {
    float t = (float)phase / 65536.0f;       /* 0..1 */
    switch (wave & 7) {
    case 0: { /* triangle */
        return (t < 0.5f) ? (4.0f * t - 1.0f) : (3.0f - 4.0f * t);
    }
    case 1: { /* tilted triangle (asymmetric) */
        const float k = 0.875f;
        if (t < k) return (2.0f * t / k) - 1.0f;
        return 1.0f - 2.0f * (t - k) / (1.0f - k);
    }
    case 2: { /* sawtooth */
        return 2.0f * t - 1.0f;
    }
    case 3: { /* square */
        return (t < 0.5f) ? -1.0f : 1.0f;
    }
    case 4: { /* pulse (1/3 duty) */
        return (t < 0.333f) ? 1.0f : -1.0f;
    }
    case 5: { /* organ — sum of two saws an octave apart */
        float a = 2.0f * t - 1.0f;
        float t2 = t * 2.0f; if (t2 >= 1.0f) t2 -= 1.0f;
        float b = 2.0f * t2 - 1.0f;
        return 0.5f * (a + b);
    }
    case 6: { /* white noise — LFSR */
        uint32_t x = *noise_lfsr;
        x ^= x << 13; x ^= x >> 17; x ^= x << 5;
        *noise_lfsr = x;
        return ((int32_t)x / (float)INT32_MAX);
    }
    case 7: { /* phaser — square swept */
        float s = (t < 0.5f) ? -1.0f : 1.0f;
        float s2 = (t < 0.6f) ? -1.0f : 1.0f;
        return 0.5f * (s + s2);
    }
    }
    return 0.0f;
}

/* --------- public API ------------------------------------------------ */

void p8_audio_init(p8_machine *m) {
    g_machine = m;
    memset(ch, 0, sizeof(ch));
    for (int i = 0; i < NCH; i++) {
        ch[i].sfx = -1;
        ch[i].noise_lfsr = 0xACE1u + i;
    }
    music_pat = -1;
    music_loop_start = -1;
}

static void start_note(int chan) {
    p8_channel *c = &ch[chan];
    if (c->note >= c->end_note) {
        if (c->loop) {
            int ls = sfx_loop_start(c->sfx);
            int le = sfx_loop_end(c->sfx);
            if (le > ls) {
                c->note = ls;
                c->end_note = le;
            } else {
                c->note = c->start_note;
            }
        } else {
            c->sfx = -1;
            return;
        }
    }
    uint16_t w = sfx_note_word(c->sfx, c->note);
    c->prev_pitch = c->cur_pitch;
    c->prev_vol   = c->cur_vol;
    c->cur_pitch  = (uint8_t)(w & 0x3f);
    c->cur_wave   = (uint8_t)((w >> 6) & 0x7);
    c->cur_vol    = (uint8_t)((w >> 9) & 0x7);
    c->cur_effect = (uint8_t)((w >> 12) & 0x7);
    c->phase_inc  = pitch_to_inc(c->cur_pitch);
    c->note_samples = speed_to_samples(sfx_speed(c->sfx));
    c->samples_left = c->note_samples;
}

void p8_audio_sfx(int n, int channel, int offset, int length) {
    if (!g_machine) return;
    if (n < 0) {
        /* sfx(-1, ch) → stop the channel */
        if (channel >= 0 && channel < NCH) ch[channel].sfx = -1;
        return;
    }
    if (n >= 64) return;
    int chan = channel;
    if (chan < 0 || chan >= NCH) {
        /* auto: pick first idle channel */
        chan = -1;
        for (int i = 0; i < NCH; i++) if (ch[i].sfx < 0) { chan = i; break; }
        if (chan < 0) chan = 0;
    }
    p8_channel *c = &ch[chan];
    c->sfx = n;
    c->start_note = (offset > 0) ? offset : 0;
    c->end_note   = (length > 0) ? (c->start_note + length) : NOTES_PER_SFX;
    if (c->end_note > NOTES_PER_SFX) c->end_note = NOTES_PER_SFX;
    c->note = c->start_note;
    c->loop = 0;
    c->phase = 0;
    c->cur_pitch = c->prev_pitch = 0;
    c->cur_vol   = c->prev_vol   = 0;
    start_note(chan);
}

void p8_audio_music(int n, int fade_len, int channel_mask) {
    (void)fade_len; (void)channel_mask;
    if (!g_machine) {
        return;
    }
    if (n < 0) {
        /* music(-1) → stop */
        music_pat = -1;
        for (int i = 0; i < NCH; i++) ch[i].sfx = -1;
        return;
    }
    if (n >= 64) return;
    music_pat = n;
    /* Read pattern: 4 bytes, each = sfx index (& 0x3f). High bit = mute. */
    for (int i = 0; i < 4; i++) {
        uint8_t b = g_machine->mem[0x3100 + n * 4 + i];
        if (b & 0x40) { ch[i].sfx = -1; continue; }   /* slot disabled */
        int sfx = b & 0x3f;
        if (sfx >= 64) { ch[i].sfx = -1; continue; }
        p8_audio_sfx(sfx, i, 0, 0);
        ch[i].loop = 1;
    }
}

/* Per-sample effect adjustment: returns the effective pitch (float)
 * and volume (float 0..1) at the given fraction-through-note. */
static void apply_effect(const p8_channel *c, float frac,
                          float *out_pitch, float *out_vol) {
    float pitch = (float)c->cur_pitch;
    float vol   = (float)c->cur_vol / 7.0f;
    switch (c->cur_effect) {
    case 0: break;                      /* none */
    case 1: {                            /* slide from prev pitch */
        pitch = (1.0f - frac) * (float)c->prev_pitch + frac * (float)c->cur_pitch;
        break;
    }
    case 2: {                            /* vibrato — ±0.5 semitone @ ~8Hz */
        pitch += 0.5f * sinf(frac * 2.0f * (float)M_PI * 4.0f);
        break;
    }
    case 3: {                            /* drop to 0 over note */
        pitch = pitch * (1.0f - frac);
        break;
    }
    case 4: {                            /* fade in */
        vol *= frac;
        break;
    }
    case 5: {                            /* fade out */
        vol *= (1.0f - frac);
        break;
    }
    case 6:                              /* fast arp (4 notes/tick) */
    case 7: {                            /* slow arp (2 notes/tick) */
        /* arp not yet implemented — needs to look at next 3 notes */
        break;
    }
    }
    *out_pitch = pitch;
    *out_vol   = vol;
}

void p8_audio_render(int16_t *out, int n_samples) {
    for (int i = 0; i < n_samples; i++) {
        float mix = 0.0f;
        for (int k = 0; k < NCH; k++) {
            p8_channel *c = &ch[k];
            if (c->sfx < 0) continue;
            if (c->samples_left <= 0) {
                c->note++;
                start_note(k);
                if (c->sfx < 0) continue;
            }
            float frac = 1.0f - (float)c->samples_left / (float)c->note_samples;
            float p, v;
            apply_effect(c, frac, &p, &v);
            /* Re-derive phase increment for slid/dropped pitches.
             * Doing this every sample would be expensive; do every
             * 64 samples to amortize. */
            if ((c->samples_left & 63) == 0) {
                c->phase_inc = pitch_to_inc((int)p);
            }
            c->phase += c->phase_inc;
            uint16_t ph = (uint16_t)(c->phase >> 16);
            float s = wave_sample(c->cur_wave, ph, &c->noise_lfsr);
            mix += s * v * 0.25f;     /* per-channel gain */
            c->samples_left--;
        }
        if (mix >  1.0f) mix =  1.0f;
        if (mix < -1.0f) mix = -1.0f;
        out[i] = (int16_t)(mix * 30000.0f);
    }
}

int p8_audio_stat(int n) {
    if (n >= 16 && n <= 19) return ch[n - 16].sfx;
    if (n >= 20 && n <= 23) {
        return ch[n - 20].sfx >= 0 ? ch[n - 20].note : -1;
    }
    return 0;
}
