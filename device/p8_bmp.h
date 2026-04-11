/*
 * ThumbyP8 — minimal 16-bit RGB565 BMP loader for picker thumbnails.
 *
 * Reads a 128×128 16-bit BMP (BI_BITFIELDS, RGB565 masks 0xF800/
 * 0x07E0/0x001F) directly into a 128×128 uint16_t buffer. Bottom-up
 * row order is flipped on load so the buffer is top-down ready to
 * draw. No malloc; runs in a few milliseconds.
 *
 * Returns 0 on success, nonzero on parse error.
 */
#ifndef THUMBYP8_BMP_H
#define THUMBYP8_BMP_H

#include <stdint.h>
#include <stddef.h>

int p8_bmp_load_128(const unsigned char *data, size_t len, uint16_t *out128x128);

/* Write a 128×128 RGB565 BMP to a file at `path` on the FAT filesystem.
 * The input buffer is top-down (row 0 = top of image). Returns 0 on
 * success, nonzero on error. */
int p8_bmp_save_128(const char *path, const uint16_t *rgb565_128x128);

#endif
