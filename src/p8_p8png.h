/*
 * ThumbyP8 — .p8.png cart loader.
 *
 * PICO-8's PNG cart format steganographically encodes 32 KB of cart
 * bytes in the low 2 bits of each pixel's RGBA channels of a 160×205
 * PNG. The visible PNG image IS the cart label — we get both the
 * runtime ROM and the picker thumbnail from the same file.
 *
 * Cart byte layout:
 *   0x0000..0x4300   ROM (gfx, gff, map, sfx, music)
 *   0x4300..0x8000   compressed Lua source
 *
 * Lua compression has three forms over PICO-8 history:
 *   - raw (no header)         small carts only
 *   - old (b":c:\0" header)   PICO-8 < 0.2.0
 *   - PXA (b"\0pxa" header)   PICO-8 ≥ 0.2.0
 *
 * We handle all three. ROM is parsed directly into machine memory.
 *
 * Decoded thumbnail: callers can request the visible PNG decoded as
 * a 128×128 RGB565 buffer for the cart picker.
 */
#ifndef THUMBYP8_P8PNG_H
#define THUMBYP8_P8PNG_H

#include <stddef.h>
#include <stdint.h>
#include "p8_machine.h"

/* Detect: is this a .p8.png file? Returns 1 if header looks like PNG. */
int p8_p8png_is_png(const unsigned char *data, size_t len);

/* Load a .p8.png cart from a memory buffer.
 *
 * On success: ROM bytes have been written into m->mem at the canonical
 * offsets, and *out_lua_src is a malloc'd, NUL-terminated Lua source
 * string (caller frees with free()) of *out_lua_len bytes.
 *
 * Returns 0 on success, nonzero on parse / decompress error. Error
 * messages go to stderr. */
/* out_label_4bpp: if non-NULL, receives a malloc'd 8KB buffer with the
 * cart's label framebuffer (4bpp, 128×128, PICO-8 palette indices).
 * Caller frees. Used to generate BMP thumbnails without a second
 * PNG decode. Pass NULL if you don't need it. */
int p8_p8png_load(p8_machine *m,
                  const unsigned char *png_data, size_t png_len,
                  char **out_lua_src, size_t *out_lua_len,
                  uint8_t **out_label_4bpp);

/* Decode the visible PNG to a 128×128 RGB565 thumbnail. The PNG is
 * 160×205; we crop the central 128×128 (PICO-8's standard label area
 * sits at offset 16,24 in the PNG). out_thumb must hold 128*128 u16. */
int p8_p8png_decode_thumbnail(const unsigned char *png_data, size_t png_len,
                               uint16_t *out_thumb);

#endif
