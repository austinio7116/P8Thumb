/*
 * ThumbyP8 — XIP (execute-in-place) flash address detection.
 *
 * On RP2350, QSPI flash is memory-mapped at 0x10000000–0x10FFFFFF
 * (16 MB). Code and data at these addresses are served via the XIP
 * cache with no SRAM copy. We use this to keep Lua bytecode in
 * flash — Proto.code[] arrays point directly into the XIP region
 * instead of being heap-allocated copies.
 *
 * On host builds (x86/ARM desktop), IS_XIP_ADDR is always false
 * so the code falls back to normal heap allocation.
 */
#ifndef THUMBYP8_XIP_H
#define THUMBYP8_XIP_H

#include <stdint.h>

#ifdef PICO_ON_DEVICE
  #define XIP_BASE  0x10000000u
  #define XIP_END   0x11000000u
  #define IS_XIP_ADDR(p) \
      ((uintptr_t)(p) >= XIP_BASE && (uintptr_t)(p) < XIP_END)
#else
  #define IS_XIP_ADDR(p) (0)
#endif

/*
 * "Active cart" flash region: 256 KB at offset 13 MB.
 * Used to hold the current cart's .luac bytecode and .rom data
 * in flash so the Lua VM can execute bytecode via XIP.
 *
 *   13 MB .. 13.25 MB   active cart bytecode (.luac)
 *   (cart ROM is stored at the beginning of this region,
 *    bytecode immediately after)
 *
 * This region is OUTSIDE the FAT filesystem (which lives at
 * 1–13 MB). It's erased and reprogrammed each time a new cart
 * is launched.
 */
#define P8_ACTIVE_CART_FLASH_OFFSET  (13u * 1024u * 1024u)
#define P8_ACTIVE_CART_FLASH_SIZE    (256u * 1024u)

#endif /* THUMBYP8_XIP_H */
