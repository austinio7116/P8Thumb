/*
 * ThumbyP8 — active-cart flash region management.
 */
#include "p8_cart_flash.h"
#include "../src/p8_xip.h"

#include "pico/stdlib.h"
#include "hardware/flash.h"
#include "hardware/sync.h"

#define REGION_OFFSET  P8_ACTIVE_CART_FLASH_OFFSET
#define REGION_SIZE    P8_ACTIVE_CART_FLASH_SIZE
#define XIP_ADDR(off)  ((const void *)(0x10000000u + (off)))

void p8_cart_flash_erase_all(void) {
    /* Erase the entire 256 KB region in 4 KB blocks. This takes
     * ~3 seconds with IRQs disabled per block (~50 ms × 64 blocks).
     * We re-enable IRQs between blocks so audio doesn't glitch
     * too badly (the cart hasn't started yet so there's no audio
     * playing; the lobby/picker isn't drawing). */
    for (size_t off = 0; off < REGION_SIZE; off += FLASH_SECTOR_SIZE) {
        uint32_t ints = save_and_disable_interrupts();
        flash_range_erase(REGION_OFFSET + off, FLASH_SECTOR_SIZE);
        restore_interrupts(ints);
    }
}

const void *p8_cart_flash_program(const void *data, size_t len,
                                   size_t offset_in_region) {
    if (offset_in_region + len > REGION_SIZE) return NULL;
    if (len == 0) return XIP_ADDR(REGION_OFFSET + offset_in_region);

    /* Program in 256-byte page chunks with IRQs re-enabled between
     * pages — same pattern as p8_flash_disk's commit_entry. */
    size_t flash_off = REGION_OFFSET + offset_in_region;
    const uint8_t *src = (const uint8_t *)data;
    size_t done = 0;
    while (done < len) {
        size_t chunk = len - done;
        if (chunk > FLASH_PAGE_SIZE) chunk = FLASH_PAGE_SIZE;
        /* flash_range_program requires `chunk` to be a multiple of
         * FLASH_PAGE_SIZE or the final partial page. The SDK handles
         * partial pages on most RP2 variants; pad with 0xFF if not. */
        uint32_t ints = save_and_disable_interrupts();
        flash_range_program(flash_off + done, src + done, chunk);
        restore_interrupts(ints);
        done += chunk;
    }
    return XIP_ADDR(flash_off);
}

const void *p8_cart_flash_xip_base(void) {
    return XIP_ADDR(REGION_OFFSET);
}
