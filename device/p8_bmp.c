/*
 * ThumbyP8 — 16-bit RGB565 BMP loader.
 *
 * Tight, no-frills parser tied to the exact BMP variant our
 * Python preprocessor (tools/p8png_extract.py) emits:
 *
 *   - 128×128 pixels
 *   - 16 bpp, BI_BITFIELDS compression
 *   - Masks: R=0xF800, G=0x07E0, B=0x001F  (RGB565)
 *   - Bottom-up row order (positive height in info header)
 *
 * Anything that doesn't match these is rejected with a parse error
 * — no need to handle the rest of the BMP zoo for our use case.
 */
#include "p8_bmp.h"
#include <string.h>

static uint16_t rd16(const unsigned char *p) {
    return (uint16_t)(p[0] | (p[1] << 8));
}
static uint32_t rd32(const unsigned char *p) {
    return (uint32_t)(p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24));
}

int p8_bmp_load_128(const unsigned char *data, size_t len, uint16_t *out128x128) {
    if (!data || !out128x128) return -1;
    if (len < 14 + 40) return -2;                /* file + info header */
    if (data[0] != 'B' || data[1] != 'M') return -3;

    uint32_t pix_off    = rd32(data + 10);
    uint32_t info_size  = rd32(data + 14);
    int32_t  width      = (int32_t)rd32(data + 18);
    int32_t  height     = (int32_t)rd32(data + 22);
    uint16_t bpp        = rd16(data + 28);
    uint32_t compression= rd32(data + 30);

    if (info_size < 40)         return -4;
    if (width != 128)           return -5;
    if (height != 128)          return -6;       /* positive = bottom-up */
    if (bpp != 16)              return -7;
    if (compression != 3)       return -8;       /* BI_BITFIELDS */
    if (pix_off + 128 * 128 * 2 > len) return -9;

    const unsigned char *src = data + pix_off;
    /* Row stride = width*2, padded to multiple of 4. For 128 cols
     * that's already 256 bytes — no padding needed. */
    const int stride = 128 * 2;
    for (int y = 0; y < 128; y++) {
        /* BMP rows go bottom-up; flip into top-down. */
        const unsigned char *row = src + (127 - y) * stride;
        uint16_t *dst = out128x128 + y * 128;
        for (int x = 0; x < 128; x++) {
            dst[x] = (uint16_t)(row[x*2] | (row[x*2 + 1] << 8));
        }
    }
    return 0;
}
