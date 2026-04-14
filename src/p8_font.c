/*
 * ThumbyP8 — built-in font for print().
 *
 * ASCII 32..127: 3×5 glyphs in a 4×6 cell, packed as 16-bit bitmaps.
 * Transcribed from Pemsa (MIT license).
 *
 * P8SCII 128..255: 7×5 glyphs in an 8×6 cell, stored as 5 bytes
 * (one byte per row, LSB = leftmost pixel, 7 bits used).
 * Taken from fake-08's fontdata.cpp (MIT, jtothebell/tac08),
 * which contains the actual PICO-8 font bitmaps.
 */
#include "p8_font.h"
#include "p8_draw.h"

#include <ctype.h>
#include <string.h>

/* ASCII 32-127: 3×5 packed into 16 bits.
 * bit 0..2 = row 0 (LSB = leftmost), bit 3..5 = row 1, etc. */
const uint16_t font_lo[128] = {
    [' '] = 0x0000,
    [ 33] = 0x2092, [ 34] = 0x002d, [ 35] = 0x5f7d, [ 36] = 0x2f9f,
    [ 37] = 0x52a5, [ 38] = 0x7adb, [ 39] = 0x0012, [ 40] = 0x224a,
    [ 41] = 0x2922, [ 42] = 0x55d5, [ 43] = 0x05d0, [ 44] = 0x1400,
    [ 45] = 0x01c0, [ 46] = 0x2000, [ 47] = 0x1494,
    [ 48] = 0x7b6f, [ 49] = 0x7493, [ 50] = 0x73e7, [ 51] = 0x79a7,
    [ 52] = 0x49ed, [ 53] = 0x79cf, [ 54] = 0x7bc9, [ 55] = 0x4927,
    [ 56] = 0x7bef, [ 57] = 0x49ef,
    [ 58] = 0x0410, [ 59] = 0x1410, [ 60] = 0x4454, [ 61] = 0x0e38,
    [ 62] = 0x1511, [ 63] = 0x21a7, [ 64] = 0x636a,
    [ 65] = 0x5bef, [ 66] = 0x7aef, [ 67] = 0x624e, [ 68] = 0x7b6b,
    [ 69] = 0x72cf, [ 70] = 0x12cf, [ 71] = 0x7a4e, [ 72] = 0x5bed,
    [ 73] = 0x7497, [ 74] = 0x3497, [ 75] = 0x5aed, [ 76] = 0x7249,
    [ 77] = 0x5b7f, [ 78] = 0x5b6b, [ 79] = 0x3b6e, [ 80] = 0x13ef,
    [ 81] = 0x676a, [ 82] = 0x5aef, [ 83] = 0x39ce, [ 84] = 0x2497,
    [ 85] = 0x6b6d, [ 86] = 0x2b6d, [ 87] = 0x7f6d, [ 88] = 0x5aad,
    [ 89] = 0x79ed, [ 90] = 0x72a7,
    [ 91] = 0x324b, [ 92] = 0x4491, [ 93] = 0x6926, [ 94] = 0x002a,
    [ 95] = 0x7000, [ 96] = 0x0022,
    [ 97] = 0x5f78, [ 98] = 0x7ad8, [ 99] = 0x7278, [100] = 0x3b58,
    [101] = 0x72f8, [102] = 0x12f8, [103] = 0x7a78, [104] = 0x5f68,
    [105] = 0x74b8, [106] = 0x34b8, [107] = 0x5ae8, [108] = 0x7248,
    [109] = 0x5bf8, [110] = 0x5b58, [111] = 0x3b70, [112] = 0x1f78,
    [113] = 0x6750, [114] = 0x5778, [115] = 0x3870, [116] = 0x24b8,
    [117] = 0x6b68, [118] = 0x2f68, [119] = 0x7f68, [120] = 0x5aa8,
    [121] = 0x79e8, [122] = 0x7338,
    [123] = 0x64d6, [124] = 0x2492, [125] = 0x3593, [126] = 0x03e0,
    [127] = 0x0550,
};

/* P8SCII 128-255: 5 bytes per glyph, each byte is one row (7 bits,
 * LSB = leftmost pixel). From fake-08/tac08 (MIT license). */
const uint8_t font_hi[128][5] = {
    /* 128 */ {127, 127, 127, 127, 127},
    /* 129 */ { 85,  42,  85,  42,  85},
    /* 130 */ { 65, 127,  93,  93,  62},
    /* 131 */ { 62,  99,  99, 119,  62},
    /* 132 */ { 17,  68,  17,  68,  17},
    /* 133 */ {  4,  60,  28,  30,  16},
    /* 134 */ { 28,  46,  62,  62,  28},
    /* 135 */ { 54,  62,  62,  28,   8},
    /* 136 */ { 28,  54, 119,  54,  28},
    /* 137 */ { 28,  28,  62,  28,  20},
    /* 138 */ { 28,  62, 127,  42,  58},
    /* 139 */ { 62, 103,  99, 103,  62},
    /* 140 */ {127,  93, 127,  65, 127},
    /* 141 */ { 56,   8,   8,  14,  14},
    /* 142 */ { 62,  99, 107,  99,  62},
    /* 143 */ {  8,  28,  62,  28,   8},
    /* 144 */ {  0,   0,  85,   0,   0},
    /* 145 */ { 62, 115,  99, 115,  62},
    /* 146 */ {  8,  28, 127,  62,  34},
    /* 147 */ { 62,  28,   8,  28,  62},
    /* 148 */ { 62, 119,  99,  99,  62},
    /* 149 */ {  0,   5,  82,  32,   0},
    /* 150 */ {  0,  17,  42,  68,   0},
    /* 151 */ { 62, 107, 119, 107,  62},
    /* 152 */ {127,   0, 127,   0, 127},
    /* 153 */ { 85,  85,  85,  85,  85},
    /* 154 */ { 14,   4,  30,  45,  38},
    /* 155 */ {  1,  17,  33,  37,   2},
    /* 156 */ { 28,   0,  62,  32,  24},
    /* 157 */ {  8,  30,   8,  36,  26},
    /* 158 */ { 78,   4,  62,  69,  38},
    /* 159 */ { 34,  95,  18,  18,  10},
    /* 160 */ { 28,  62,  28,   2,  28},
    /* 161 */ { 48,  12,   2,  12,  48},
    /* 162 */ { 34, 122,  34,  34,  18},
    /* 163 */ { 14,  16,   0,   2,  60},
    /* 164 */ { 62,   8,  14,   1,  30},
    /* 165 */ {  2,   2,   2,  34,  28},
    /* 166 */ {  8,  62,   8,  12,   8},
    /* 167 */ { 18,  62,  18,   2,  28},
    /* 168 */ { 60,  16, 126,   8, 112},
    /* 169 */ {  4,  14,  52,   2, 114},
    /* 170 */ {  4,  63,  28,  48,  30},
    /* 171 */ { 60,  67,  64,  32,  24},
    /* 172 */ { 62,  16,   8,   8,  16},
    /* 173 */ {  8,  56,   4,   2,  60},
    /* 174 */ { 98,  15,  34,  57,  88},
    /* 175 */ {122,  66,   2,  10, 114},
    /* 176 */ {  9,  62,  75, 109, 102},
    /* 177 */ { 50,  75,  70,  99,  98},
    /* 178 */ { 60,  74,  73,  73,  38},
    /* 179 */ { 18,  58,  18,  58,  90},
    /* 180 */ { 35,  98,  34,  34,  28},
    /* 181 */ { 12,   0,   8,  42,  77},
    /* 182 */ {  0,  12,  18,  33,  64},
    /* 183 */ { 61,  17,  61,  25, 109},
    /* 184 */ { 28,  62,   8,  30,  44},
    /* 185 */ {  6,  36, 126,  38,  16},
    /* 186 */ { 36,  78,   4,  70,  60},
    /* 187 */ { 10,  60,  90,  70,  48},
    /* 188 */ { 30,   4,  30,  68,  56},
    /* 189 */ { 36, 126, 100,   8,   8},
    /* 190 */ { 58,  86,  82,  48,   8},
    /* 191 */ {  8,  56,   8,  30,  38},
    /* 192 */ {  8,   2,  62,  32,  28},
    /* 193 */ {  2,  34,  34,  36,  16},
    /* 194 */ { 60,  16, 124, 114,  48},
    /* 195 */ {  4,  54,  44,  38, 100},
    /* 196 */ { 60,  16, 124,  66,  48},
    /* 197 */ { 50,  75,  70,  35,  18},
    /* 198 */ { 14, 100,  28,  40, 120},
    /* 199 */ {  2,  14,  18,  81,  49},
    /* 200 */ {  0,   0,  14,  16,   8},
    /* 201 */ {  0,  10,  31,  26,   4},
    /* 202 */ {  0,   4,  15,  21,  13},
    /* 203 */ {  0,   2,  14,   2,  29},
    /* 204 */ { 62,  32,  20,   4,   2},
    /* 205 */ { 48,  14,   8,   8,   8},
    /* 206 */ {  8,  62,  32,  16,  12},
    /* 207 */ { 28,   8,   8,   8,  62},
    /* 208 */ { 16, 126,  24,  22,  24},
    /* 209 */ {  4,  62,  36,  34,  50},
    /* 210 */ {  4,  30,   8,  62,   8},
    /* 211 */ {  4,  60,  34,  16,   8},
    /* 212 */ {  4, 124,  18,  16,   8},
    /* 213 */ { 62,  32,  32,  32,  62},
    /* 214 */ { 36, 126,  36,  32,  16},
    /* 215 */ {  8,  18,   4,  96,  28},
    /* 216 */ { 62,  32,  16,  24,  38},
    /* 217 */ {  4, 126,  36,   4,  56},
    /* 218 */ { 34,  36,  32,  16,   8},
    /* 219 */ {124,  68,  82,  96,  16},
    /* 220 */ { 28,   8,  62,   8,   4},
    /* 221 */ { 74,  74,  32,  16,  12},
    /* 222 */ { 28,   0,  62,   8,   4},
    /* 223 */ {  4,   4,  28,  36,   4},
    /* 224 */ {  8,  62,   8,   8,   4},
    /* 225 */ {  0,  28,   0,   0,  62},
    /* 226 */ { 62,  32,  40,  48,  12},
    /* 227 */ {  8,  62,  32,  95,   8},
    /* 228 */ { 32,  32,  16,   8,   6},
    /* 229 */ { 16,  36,  36,  66,  66},
    /* 230 */ {  2,  50,  14,   2,  60},
    /* 231 */ { 62,  32,  32,  16,  12},
    /* 232 */ { 12,  18,  33,  64,   0},
    /* 233 */ {  8,  62,   8,  42,  77},
    /* 234 */ { 62,  32,  20,   8,  16},
    /* 235 */ { 60,   0,  62,   0,  30},
    /* 236 */ {  8,   4,  36,  98,  94},
    /* 237 */ { 64,  40,  16, 104,   6},
    /* 238 */ { 62,   8, 126,   8, 112},
    /* 239 */ {116,  78,  36,   8,   8},
    /* 240 */ {120,  64,  32,  32, 124},
    /* 241 */ { 30,  16,  62,  16,  30},
    /* 242 */ { 28,   0,  62,  32,  24},
    /* 243 */ { 36,  36,  36,  32,  24},
    /* 244 */ { 20,  20,  20,  84,  50},
    /* 245 */ {  2,   2,   2,  50,  14},
    /* 246 */ {126,  66,  66,  66, 126},
    /* 247 */ {  0,   0,   0,   0,   0},
    /* 248 */ {  0,   0,   0,   0,   0},
    /* 249 */ {  0,   0,   0,   0,   0},
    /* 250 */ {  0,   0,   0,   0,   0},
    /* 251 */ {  0,   0,   0,   0,   0},
    /* 252 */ {  0,   0,   0,   0,   0},
    /* 253 */ {  0,   0,   0,   0,   0},
    /* 254 */ {  0,   0,   0,   0,   0},
    /* 255 */ {  0,   0,   0,   0,   0},
};

/* Parse a P8SCII parameter value: '0'-'9'→0-9, 'a'+→10+ */
static int p8scii_param(const char **p) {
    unsigned char ch = (unsigned char)**p;
    (*p)++;
    if (ch >= '0' && ch <= '9') return ch - '0';
    if (ch >= 'a') return ch - 'a' + 10;
    return 0;
}

int p8_font_draw(p8_machine *m, const char *text, int x, int y, int c) {
    if (!text) return x;
    int cur_x = x;
    int cur_y = y;
    while (*text) {
        unsigned char ch = (unsigned char)*text++;

        /* 0x00: terminate */
        if (ch == 0x00) break;

        /* 0x01 \*: repeat next char P0 times */
        if (ch == 0x01) {
            if (!*text) break;
            int count = p8scii_param(&text);
            if (!*text) break;
            unsigned char rc = (unsigned char)*text++;
            for (int i = 0; i < count; i++) {
                /* Recursively render the repeated char would be complex;
                 * for now just advance the cursor as if printed. */
                if (rc >= 128) cur_x += 8;
                else cur_x += P8_FONT_CELL_W;
            }
            continue;
        }
        /* 0x02 \#: set background color — 1 param */
        if (ch == 0x02) { if (*text) p8scii_param(&text); continue; }

        /* 0x03 \-: shift cursor X by (P0-16) — 1 param */
        if (ch == 0x03) {
            if (*text) { int v = p8scii_param(&text); cur_x += v - 16; }
            continue;
        }
        /* 0x04 \|: shift cursor Y by (P0-16) — 1 param */
        if (ch == 0x04) {
            if (*text) { int v = p8scii_param(&text); cur_y += v - 16; }
            continue;
        }
        /* 0x05 \+: shift cursor by (P0-16, P1-16) — 2 params */
        if (ch == 0x05) {
            if (*text) { int h = p8scii_param(&text);
            if (*text) { int v = p8scii_param(&text);
                cur_x += h - 16; cur_y += v - 16; }}
            continue;
        }
        /* 0x06 \^: special command prefix — variable params */
        if (ch == 0x06) {
            if (!*text) break;
            unsigned char cmd = (unsigned char)*text++;
            /* Sub-commands with no extra params */
            if (cmd == 'g' || cmd == 'h') continue;
            /* Flag toggles: w,t,=,p,i,b,# — no extra params */
            if (cmd == 'w' || cmd == 't' || cmd == '=' ||
                cmd == 'p' || cmd == 'i' || cmd == 'b' || cmd == '#')
                continue;
            /* Skip digits 1-9 (frame delays) — no extra params */
            if (cmd >= '1' && cmd <= '9') continue;
            /* - (disable flag): consumes 1 more byte */
            if (cmd == '-') { if (*text) text++; continue; }
            /* c,d,s,x,y,r: 1 param */
            if (cmd == 'c' || cmd == 'd' || cmd == 's' ||
                cmd == 'x' || cmd == 'y' || cmd == 'r')
                { if (*text) p8scii_param(&text); continue; }
            /* j: 2 params */
            if (cmd == 'j') {
                if (*text) p8scii_param(&text);
                if (*text) p8scii_param(&text);
                continue;
            }
            /* . (inline 8x8 char): 8 raw bytes */
            if (cmd == '.') {
                for (int i = 0; i < 8 && *text; i++) text++;
                continue;
            }
            /* : (inline hex char): 16 hex chars */
            if (cmd == ':') {
                for (int i = 0; i < 16 && *text; i++) text++;
                continue;
            }
            /* @ (poke): 4 hex addr + 4 hex count + data — skip all */
            /* ! (poke remaining): skip rest of string */
            if (cmd == '!' || cmd == '@') break;
            continue;  /* unknown sub-command — skip */
        }
        /* 0x07 \a: audio — skip until space or end */
        if (ch == 0x07) {
            while (*text && *text != ' ' && *text != '\n') text++;
            if (*text == ' ') text++;  /* consume the terminating space */
            continue;
        }
        /* 0x08 \b: backspace */
        if (ch == 0x08) { cur_x -= P8_FONT_CELL_W; continue; }
        /* 0x09 \t: tab */
        if (ch == 0x09) { cur_x = ((cur_x / 16) + 1) * 16; continue; }
        /* 0x0A \n: newline */
        if (ch == 0x0A) { cur_x = x; cur_y += P8_FONT_CELL_H; continue; }
        /* 0x0B \v: decorate — 2 params (offset + char) */
        if (ch == 0x0B) {
            if (*text) text++;  /* P0 */
            if (*text) text++;  /* decoration char */
            continue;
        }
        /* 0x0C \f: set foreground color — 1 param */
        if (ch == 0x0C) {
            if (*text) c = p8scii_param(&text) & 0x0f;
            continue;
        }
        /* 0x0D \r: carriage return */
        if (ch == 0x0D) { cur_x = x; continue; }
        /* 0x0E: switch to custom font — skip */
        /* 0x0F: switch to default font — skip */
        if (ch == 0x0E || ch == 0x0F) continue;

        /* Printable characters */
        if (ch >= 128) {
            const uint8_t *g = font_hi[ch - 128];
            for (int row = 0; row < 5; row++) {
                uint8_t bits = g[row];
                for (int col = 0; col < 7; col++) {
                    if (bits & (1 << col))
                        p8_pset(m, cur_x + col, cur_y + row, c);
                }
            }
            cur_x += 8;
        } else if (ch >= 0x10) {
            uint16_t g = font_lo[ch];
            for (int row = 0; row < 5; row++) {
                int bits = (g >> (row * 3)) & 0x7;
                if (bits & 0x1) p8_pset(m, cur_x + 0, cur_y + row, c);
                if (bits & 0x2) p8_pset(m, cur_x + 1, cur_y + row, c);
                if (bits & 0x4) p8_pset(m, cur_x + 2, cur_y + row, c);
            }
            cur_x += P8_FONT_CELL_W;
        }
    }
    return cur_x;
}
