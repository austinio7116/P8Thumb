/*
 * ThumbyP8 — PICO-8 audio synth implementation.
 *
 * Reference: fake-08 Audio.cpp/synth.cpp (MIT, jtothebell) and
 * zepto-8 synth.cpp. Bit formats verified against shrinko8's
 * pico_cart.py and picotool.
 *
 * Key format details:
 *   SFX note (16-bit LE at 0x3200 + sfx*68 + note*2):
 *     byte0: [w1 w0 p5 p4 p3 p2 p1 p0]
 *     byte1: [c  e2 e1 e0 v2 v1 v0 w2]
 *     pitch  = byte0 & 0x3f          (0-63)
 *     wave   = ((byte0>>6)&3) | ((byte1&1)<<2)  (0-7)
 *     volume = (byte1>>1) & 7        (0-7)
 *     effect = (byte1>>4) & 7        (0-7)
 *     custom = (byte1>>7) & 1
 *
 *   SFX header (at offset +64..+67 within 68-byte entry):
 *     +64: filters/editor  +65: speed  +66: loop_start  +67: loop_end
 *
 *   Music pattern (4 bytes at 0x3100 + pat*4):
 *     Each byte: bits 0-6 = SFX index, bit 7 = flag
 *     byte0 bit7 = loop-start, byte1 bit7 = loop-back,
 *     byte2 bit7 = stop. Channel disabled when (byte & 0x7f) >= 64.
 */
#include "p8_audio.h"
#include <math.h>
#include <string.h>
#include <stdlib.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846f
#endif

#define SR        P8_AUDIO_SAMPLE_RATE   /* 22050 */
#define NCH       P8_AUDIO_CHANNELS      /* 4 */
#define NOTES_PER_SFX 32
#define TICKS_PER_SPEED 183   /* samples per note at speed=1 */

/* Per-channel synth state. */
typedef struct {
    int   sfx;              /* current SFX index, -1 = idle */
    int   note_id;          /* current note index 0..31 */
    int   end_note;         /* note index where SFX stops (exclusive) */
    int   samples_left;     /* remaining samples in current note */
    int   note_samples;     /* total samples for current note */
    int   is_music;         /* 1 = this channel is playing for music */

    /* Cached note data */
    uint8_t cur_pitch, cur_wave, cur_vol, cur_effect;
    uint8_t prev_pitch, prev_vol;

    /* Phase accumulator (float, wraps at 1.0) */
    float phase;

    /* Noise state: low-pass filtered random */
    float noise_sample;     /* last noise output */
    float noise_advance;    /* accumulated phase for noise */

    /* SFX loop range */
    int loop_start, loop_end;
} p8_channel;

static p8_machine *g_machine = NULL;
static p8_channel  ch[NCH];

/* Music state */
static int music_pat = -1;
static int music_mask = 0;     /* channel mask from music() call */
static float music_offset = 0; /* global music clock (in speed-1 note units) */
static float music_length = 0; /* pattern length in same units */

/* Fade state. fade_volume goes from 0..1 as the amplitude multiplier
 * for all music channels. fade_step is added per sample (+ for fade
 * in, - for fade out). When fade_step < 0 and fade_volume hits 0,
 * music stops entirely. */
static float music_fade_volume = 1.0f;
static float music_fade_step   = 0.0f;
static int   music_fade_stop_at_zero = 0;

/* --------- helpers --------------------------------------------------- */

/* Pre-computed pitch → frequency table. Only 64 possible pitches (0-63).
 * Key 33 = A4 = 440 Hz. Avoids calling expf() at runtime. */
static float pitch_freq_lut[64];

static void init_pitch_lut(void) {
    for (int i = 0; i < 64; i++) {
        pitch_freq_lut[i] = 440.0f * expf(((float)i - 33.0f) / 12.0f * 0.6931471805599453f);
    }
}

static inline float pitch_to_freq(float pitch) {
    int p = (int)pitch;
    if (p < 0) p = 0; if (p > 63) p = 63;
    /* Interpolate for fractional pitches (effects like slide/vibrato) */
    float frac = pitch - (float)p;
    if (frac < 0.001f || p >= 63) return pitch_freq_lut[p];
    return pitch_freq_lut[p] + (pitch_freq_lut[p + 1] - pitch_freq_lut[p]) * frac;
}

/* Read a 16-bit note word and unpack fields. */
static void read_note(int sfx, int note,
                      uint8_t *pitch, uint8_t *wave,
                      uint8_t *vol, uint8_t *effect) {
    int addr = 0x3200 + sfx * 68 + note * 2;
    uint8_t b0 = g_machine->mem[addr];
    uint8_t b1 = g_machine->mem[addr + 1];
    *pitch  = b0 & 0x3f;
    *wave   = ((b0 >> 6) & 3) | ((b1 & 1) << 2);
    *vol    = (b1 >> 1) & 7;
    *effect = (b1 >> 4) & 7;
}

static int sfx_speed(int sfx) {
    int s = g_machine->mem[0x3200 + sfx * 68 + 65];
    return s < 1 ? 1 : s;
}
static int sfx_loop_start(int sfx) {
    return g_machine->mem[0x3200 + sfx * 68 + 66];
}
static int sfx_loop_end(int sfx) {
    return g_machine->mem[0x3200 + sfx * 68 + 67];
}

/* Waveform sample. `t` is phase position 0..1, `advance` is total
 * accumulated phase (for phaser detuning). Returns ~[-0.5, +0.5]. */
static float wave_sample(uint8_t wave, float t, float advance,
                          float *noise_sample, float pitch) {
    switch (wave & 7) {
    case 0: { /* triangle */
        return (1.0f - fabsf(4.0f * t - 2.0f)) * 0.5f;
    }
    case 1: { /* tilted saw (asymmetric triangle, 87.5% rise) */
        float a = 0.875f;
        float ret = t < a ? (2.0f * t / a - 1.0f)
                          : (2.0f * (1.0f - t) / (1.0f - a) - 1.0f);
        return ret * 0.5f;
    }
    case 2: { /* sawtooth */
        float ret = t < 0.5f ? t : (t - 1.0f);
        return 0.653f * ret;
    }
    case 3: { /* square 50% duty */
        return t < 0.5f ? 0.25f : -0.25f;
    }
    case 4: { /* pulse ~31.6% duty */
        return t < 0.316f ? 0.25f : -0.25f;
    }
    case 5: { /* organ (harmonic-rich dual triangle) */
        float ret = t < 0.5f
            ? (3.0f - fabsf(24.0f * t - 6.0f))
            : (1.0f - fabsf(16.0f * t - 12.0f));
        return ret / 9.0f;
    }
    case 6: { /* noise — low-pass filtered random.
              * Pitch controls cutoff: high pitch = bright, low = dark. */
        float tscale = (float)SR / pitch_to_freq(63);
        float freq = pitch_to_freq(pitch);
        float scale = (freq / (float)SR) * tscale;
        /* Random float in [-1, 1] */
        float r = ((float)(rand() % 65536) / 32768.0f) - 1.0f;
        float ns = (*noise_sample + scale * r) / (1.0f + scale);
        *noise_sample = ns;
        /* Volume compensation for low pitches */
        float factor = 1.0f - pitch / 63.0f;
        return ns * 1.5f * (1.0f + factor * factor) * 0.25f;
    }
    case 7: { /* phaser — two detuned triangles beating together */
        float ret = 2.0f - fabsf(8.0f * t - 4.0f);
        float t2 = fmodf(advance * 109.0f / 110.0f, 1.0f);
        ret += 1.0f - fabsf(4.0f * t2 - 2.0f);
        return ret / 6.0f;
    }
    }
    return 0.0f;
}

/* --------- music helpers --------------------------------------------- */

static int pat_flag_start(int pat) {
    return (g_machine->mem[0x3100 + pat * 4 + 0] >> 7) & 1;
}
static int pat_flag_loop(int pat) {
    return (g_machine->mem[0x3100 + pat * 4 + 1] >> 7) & 1;
}
static int pat_flag_stop(int pat) {
    return (g_machine->mem[0x3100 + pat * 4 + 2] >> 7) & 1;
}

static void start_note(int chan);
static void music_start_pattern(int pat);

/* --------- public API ------------------------------------------------ */

void p8_audio_init(p8_machine *m) {
    g_machine = m;
    init_pitch_lut();
    memset(ch, 0, sizeof(ch));
    for (int i = 0; i < NCH; i++) {
        ch[i].sfx = -1;
    }
    music_pat = -1;
    music_mask = 0;
    music_offset = 0;
    music_length = 0;
    music_fade_volume = 1.0f;
    music_fade_step = 0.0f;
    music_fade_stop_at_zero = 0;
}

static void start_note(int chan) {
    p8_channel *c = &ch[chan];
    if (c->note_id >= c->end_note) {
        /* Check SFX loop */
        if (c->loop_end > c->loop_start) {
            c->note_id = c->loop_start;
            c->end_note = c->loop_end;
        } else {
            c->sfx = -1;
            return;
        }
    }
    c->prev_pitch = c->cur_pitch;
    c->prev_vol   = c->cur_vol;
    read_note(c->sfx, c->note_id,
              &c->cur_pitch, &c->cur_wave, &c->cur_vol, &c->cur_effect);
    int spd = sfx_speed(c->sfx);
    c->note_samples = TICKS_PER_SPEED * spd;
    c->samples_left = c->note_samples;
}

void p8_audio_sfx(int n, int channel, int offset, int length) {
    if (!g_machine) return;
    if (n < 0) {
        /* sfx(-1, ch) or sfx(-2, ch) → stop */
        if (channel >= 0 && channel < NCH) {
            if (!ch[channel].is_music)
                ch[channel].sfx = -1;
        }
        return;
    }
    if (n >= 64) return;

    /* Deduplicate: stop any channel already playing this SFX */
    for (int i = 0; i < NCH; i++) {
        if (ch[i].sfx == n) ch[i].sfx = -1;
    }

    int chan = channel;
    if (chan < 0 || chan >= NCH) {
        /* Auto-pick: find idle non-masked channel */
        chan = -1;
        for (int i = 0; i < NCH; i++) {
            if ((music_mask & (1 << i)) && ch[i].is_music) continue;
            if (ch[i].sfx < 0) { chan = i; break; }
        }
        /* If none idle, steal first non-masked channel */
        if (chan < 0) {
            for (int i = 0; i < NCH; i++) {
                if ((music_mask & (1 << i)) && ch[i].is_music) continue;
                chan = i; break;
            }
        }
        if (chan < 0) return;  /* all channels masked, can't play */
    }

    p8_channel *c = &ch[chan];
    c->sfx = n;
    c->note_id = (offset > 0) ? offset : 0;
    c->end_note = (length > 0) ? (c->note_id + length) : NOTES_PER_SFX;
    if (c->end_note > NOTES_PER_SFX) c->end_note = NOTES_PER_SFX;
    c->loop_start = sfx_loop_start(n);
    c->loop_end   = sfx_loop_end(n);
    /* If loop_end == 0 and loop_start > 0, treat loop_start as note count */
    if (c->loop_end == 0 && c->loop_start > 0 && !c->is_music) {
        c->end_note = c->loop_start;
        c->loop_start = 0;  /* no actual looping */
    }
    c->phase = 0;
    c->noise_sample = 0;
    c->noise_advance = 0;
    c->cur_pitch = c->prev_pitch = 24;  /* default prev = C2 */
    c->cur_vol   = c->prev_vol   = 0;
    c->is_music  = 0;
    start_note(chan);
}

/* Compute pattern length in speed-1-note units. */
static float compute_pattern_length(int pat) {
    float len = 32.0f;  /* default */
    int found_nonloop = 0;
    float max_loop_len = 0;

    for (int i = 0; i < NCH; i++) {
        uint8_t b = g_machine->mem[0x3100 + pat * 4 + i];
        int sfx_idx = b & 0x7f;
        if (sfx_idx >= 64) continue;  /* channel disabled */

        int spd = sfx_speed(sfx_idx);
        int ls = sfx_loop_start(sfx_idx);
        int le = sfx_loop_end(sfx_idx);

        if (le > ls) {
            /* Looping SFX */
            float l = 32.0f * spd;
            if (l > max_loop_len) max_loop_len = l;
        } else {
            /* Non-looping SFX — its length determines pattern duration */
            if (!found_nonloop) {
                int end = 32;
                if (le == 0 && ls > 0) end = ls;  /* ls = note count */
                len = (float)(end * spd);
                found_nonloop = 1;
            }
        }
    }
    if (!found_nonloop && max_loop_len > 0) len = max_loop_len;
    return len;
}

static void music_start_pattern(int pat) {
    if (pat < 0 || pat >= 64) {
        music_pat = -1;
        for (int i = 0; i < NCH; i++) {
            if (ch[i].is_music) { ch[i].sfx = -1; ch[i].is_music = 0; }
        }
        return;
    }
    music_pat = pat;
    music_offset = 0;
    music_length = compute_pattern_length(pat);

    for (int i = 0; i < NCH; i++) {
        uint8_t b = g_machine->mem[0x3100 + pat * 4 + i];
        int sfx_idx = b & 0x7f;
        if (sfx_idx >= 64) {
            if (ch[i].is_music) { ch[i].sfx = -1; ch[i].is_music = 0; }
            continue;
        }
        /* Only start on channel if it's not currently playing a user SFX */
        if (ch[i].sfx >= 0 && !ch[i].is_music) {
            /* Channel busy with sfx() call — defer */
            continue;
        }
        p8_channel *c = &ch[i];
        c->sfx = sfx_idx;
        c->note_id = 0;
        c->end_note = NOTES_PER_SFX;
        c->loop_start = sfx_loop_start(sfx_idx);
        c->loop_end   = sfx_loop_end(sfx_idx);
        c->phase = 0;
        c->noise_sample = 0;
        c->noise_advance = 0;
        c->cur_pitch = c->prev_pitch = 24;
        c->cur_vol   = c->prev_vol   = 0;
        c->is_music  = 1;
        start_note(i);
    }
}

static void music_advance(void) {
    if (music_pat < 0) return;
    if (pat_flag_stop(music_pat)) {
        music_start_pattern(-1);
        return;
    }
    if (pat_flag_loop(music_pat)) {
        int target = music_pat;
        while (--target > 0 && !pat_flag_start(target)) ;
        if (target < 0) target = 0;
        music_start_pattern(target);
        return;
    }
    music_start_pattern(music_pat + 1);
}

void p8_audio_music(int n, int fade_len, int channel_mask) {
    if (!g_machine) return;
    music_mask = channel_mask;

    if (n < 0) {
        /* Stop request. With fade: ramp volume to 0, stop when done. */
        if (fade_len > 0) {
            /* Compute per-sample step: we go from current volume to 0
             * over fade_len ms, which is fade_len * SR / 1000 samples. */
            float n_samples = (float)fade_len * (float)SR / 1000.0f;
            if (n_samples < 1.0f) n_samples = 1.0f;
            music_fade_step = -music_fade_volume / n_samples;
            music_fade_stop_at_zero = 1;
        } else {
            music_fade_volume = 1.0f;
            music_fade_step = 0;
            music_fade_stop_at_zero = 0;
            music_start_pattern(-1);
        }
        return;
    }
    if (n >= 64) return;

    /* Start request. With fade: start pattern at volume 0 and ramp up. */
    if (fade_len > 0) {
        music_fade_volume = 0.0f;
        float n_samples = (float)fade_len * (float)SR / 1000.0f;
        if (n_samples < 1.0f) n_samples = 1.0f;
        music_fade_step = 1.0f / n_samples;
        music_fade_stop_at_zero = 0;
    } else {
        music_fade_volume = 1.0f;
        music_fade_step = 0;
        music_fade_stop_at_zero = 0;
    }
    music_start_pattern(n);
}

/* Per-sample effect: modifies pitch and volume based on effect type. */
static void apply_effect(const p8_channel *c, float frac,
                          float *out_freq, float *out_vol) {
    float freq = pitch_to_freq((float)c->cur_pitch);
    float vol  = (float)c->cur_vol / 7.0f;

    switch (c->cur_effect) {
    case 0: break;  /* none */
    case 1: { /* slide from previous pitch/vol */
        float prev_freq = pitch_to_freq((float)c->prev_pitch);
        freq = prev_freq + (freq - prev_freq) * frac;
        if (c->prev_vol > 0) {
            float pv = (float)c->prev_vol / 7.0f;
            vol = pv + (vol - pv) * frac;
        }
        break;
    }
    case 2: { /* vibrato — ±0.5 semitone at ~7.5 Hz */
        int spd = c->note_samples > 0 ? c->note_samples / TICKS_PER_SPEED : 1;
        float ofs_per_sec = (float)SR / (float)(TICKS_PER_SPEED * spd);
        float note_offset = frac;  /* 0..1 within note */
        float abs_offset = (float)c->note_id + note_offset;
        float t = fabsf(fmodf(7.5f * abs_offset / ofs_per_sec, 1.0f) - 0.5f) - 0.25f;
        freq = freq + (freq * 1.059463094359f - freq) * t;
        break;
    }
    case 3: { /* drop to 0 */
        freq *= (1.0f - frac);
        break;
    }
    case 4: { /* fade in */
        vol *= frac;
        break;
    }
    case 5: { /* fade out */
        vol *= (1.0f - frac);
        break;
    }
    case 6: /* arpeggio fast */
    case 7: { /* arpeggio slow */
        int spd = c->note_samples > 0 ? c->note_samples / TICKS_PER_SPEED : 1;
        float ofs_per_sec = (float)SR / (float)(TICKS_PER_SPEED * spd);
        int m = (spd <= 8 ? 32 : 16) / (c->cur_effect == 6 ? 4 : 8);
        if (m < 1) m = 1;
        float abs_offset = (float)c->note_id + frac;
        int n = (int)((float)m * 7.5f * abs_offset / ofs_per_sec);
        int base = c->note_id & ~3;
        int arp_note = base | (n & 3);
        if (arp_note >= NOTES_PER_SFX) arp_note = NOTES_PER_SFX - 1;
        uint8_t ap, aw, av, ae;
        read_note(c->sfx, arp_note, &ap, &aw, &av, &ae);
        freq = pitch_to_freq((float)ap);
        break;
    }
    }
    *out_freq = freq;
    *out_vol  = vol;
}

void p8_audio_render(int16_t *out, int n_samples) {
    float music_inc = 1.0f / (float)TICKS_PER_SPEED;  /* per-sample music clock advance */

    for (int i = 0; i < n_samples; i++) {
        /* Advance music fade */
        if (music_fade_step != 0.0f) {
            music_fade_volume += music_fade_step;
            if (music_fade_step > 0 && music_fade_volume >= 1.0f) {
                music_fade_volume = 1.0f;
                music_fade_step = 0;
            } else if (music_fade_step < 0 && music_fade_volume <= 0.0f) {
                music_fade_volume = 0.0f;
                music_fade_step = 0;
                if (music_fade_stop_at_zero) {
                    music_start_pattern(-1);
                    music_fade_stop_at_zero = 0;
                    music_fade_volume = 1.0f;  /* reset for next play */
                }
            }
        }

        /* Advance music clock */
        if (music_pat >= 0) {
            music_offset += music_inc;
            if (music_offset >= music_length) {
                music_advance();
            }
        }

        float mix = 0.0f;
        for (int k = 0; k < NCH; k++) {
            p8_channel *c = &ch[k];
            if (c->sfx < 0) continue;
            if (c->samples_left <= 0) {
                c->note_id++;
                start_note(k);
                if (c->sfx < 0) continue;
            }

            float frac = 1.0f - (float)c->samples_left / (float)c->note_samples;
            float freq, vol;
            apply_effect(c, frac, &freq, &vol);

            /* Music channels respect fade volume */
            if (c->is_music) vol *= music_fade_volume;

            /* Advance phase */
            float phase_inc = freq / (float)SR;
            c->phase += phase_inc;
            if (c->phase >= 1.0f) c->phase -= (int)c->phase;
            c->noise_advance += phase_inc;

            float s = wave_sample(c->cur_wave, c->phase, c->noise_advance,
                                   &c->noise_sample, (float)c->cur_pitch);
            mix += s * vol;
            c->samples_left--;
        }
        /* 4 channels at ~±0.5 peak each * vol ≤1.0 → mix can reach ±2.0.
         * Scale by 0.5 to keep in [-1,1] range. */
        mix *= 0.5f;
        if (mix >  1.0f) mix =  1.0f;
        if (mix < -1.0f) mix = -1.0f;
        out[i] = (int16_t)(mix * 32767.0f);
    }
}

int p8_audio_stat(int n) {
    if (n >= 16 && n <= 19) return ch[n - 16].sfx;
    if (n >= 20 && n <= 23) {
        return ch[n - 20].sfx >= 0 ? ch[n - 20].note_id : -1;
    }
    if (n == 24) return music_pat;
    if (n == 25) return (music_pat >= 0) ? (int)music_offset : 0;
    if (n == 26) return (music_pat >= 0) ? 1 : 0;  /* music playing flag */
    return 0;
}
