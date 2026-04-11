/*
 * ThumbyP8 — "active cart" flash region for XIP-resident bytecode.
 *
 * When a precompiled .luac cart is loaded, its bytecode is programmed
 * to a dedicated flash region (256 KB at 13 MB offset). The Lua VM
 * then loads bytecode via a reader that returns an XIP pointer into
 * this region. The patched lundump.c detects the XIP address and
 * stores Proto.code[] as a direct flash pointer — no heap copy.
 *
 * The .rom binary (17 KB of cart ROM: sprites, map, sfx, music) is
 * also stored in this region, immediately before the bytecode.
 *
 * The region is erased + reprogrammed each time a new cart launches.
 * Flash wear: ~100 KB per launch × 100K cycle rating = 10 billion
 * launches before wear-out. Not a concern.
 */
#ifndef THUMBYP8_CART_FLASH_H
#define THUMBYP8_CART_FLASH_H

#include <stdint.h>
#include <stddef.h>

/* Program raw bytes to the active-cart flash region and return the
 * XIP-mapped address of the programmed data. The region is erased
 * first (4 KB granularity). `offset` is relative to the start of
 * the active-cart region; `data` and `len` must be in SRAM.
 *
 * Returns the XIP pointer (0x10000000 + flash_offset) on success,
 * NULL on failure (data too large, etc). */
const void *p8_cart_flash_program(const void *data, size_t len,
                                   size_t offset_in_region);

/* Erase the entire active-cart region. Call once before programming
 * a new cart's data. */
void p8_cart_flash_erase_all(void);

/* Return the XIP-mapped base address of the active-cart region. */
const void *p8_cart_flash_xip_base(void);

#endif
