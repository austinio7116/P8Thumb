/*
 * ThumbyP8 — TinyUSB MSC class callbacks.
 *
 * Routes the host's SCSI sector R/W commands to our flash-backed
 * disk. The host sees a removable drive that it can read/write
 * via standard filesystem operations.
 */
#include "tusb.h"
#include "p8_flash_disk.h"
#include <string.h>

/* Eject signal: set by tud_msc_start_stop_cb, consumed by the
 * main loop so it knows when the host is done talking to the disk
 * and it's safe to commit the cache to flash. */
volatile int      g_msc_ejected      = 0;
/* Microsecond timestamp of the last MSC read/write call. The lobby
 * waits for this to go quiet (no SCSI activity for >1 s) after an
 * eject signal before it commits, so we don't starve any tail-end
 * MSC commands the host is still sending while the eject completes. */
volatile uint64_t g_msc_last_op_us   = 0;

#include "pico/time.h"
static inline void msc_touch(void) { g_msc_last_op_us = (uint64_t)time_us_64(); }

/* Inquiry: identify the device to the host. */
void tud_msc_inquiry_cb(uint8_t lun, uint8_t vendor_id[8],
                         uint8_t product_id[16], uint8_t product_rev[4]) {
    (void)lun;
    const char vid[] = "ThumbyP8";
    const char pid[] = "Cart Storage   ";
    const char rev[] = "1.0 ";
    memcpy(vendor_id,  vid, 8);
    memcpy(product_id, pid, 16);
    memcpy(product_rev, rev, 4);
}

bool tud_msc_test_unit_ready_cb(uint8_t lun) {
    (void)lun;
    return true;
}

void tud_msc_capacity_cb(uint8_t lun, uint32_t *block_count, uint16_t *block_size) {
    (void)lun;
    *block_count = p8_flash_disk_sector_count();
    *block_size  = (uint16_t)p8_flash_disk_sector_size();
}

bool tud_msc_start_stop_cb(uint8_t lun, uint8_t power_condition,
                            bool start, bool load_eject) {
    (void)lun; (void)power_condition; (void)start;
    /* Eject from host (Windows "Safely Remove" → SCSI Stop with
     * load_eject=1, or START_STOP with start=0). We just set a
     * flag; the main loop sees it and triggers the deferred flush
     * to flash. We can't flush here because this callback runs
     * inside tud_task() — flash erase blocks IRQs for ~50 ms per
     * sector and that would kill USB. */
    if (load_eject || !start) g_msc_ejected = 1;
    return true;
}

int32_t tud_msc_read10_cb(uint8_t lun, uint32_t lba, uint32_t offset,
                           void *buffer, uint32_t bufsize) {
    (void)lun;
    msc_touch();
    /* Sector-aligned read: bufsize is one or more full sectors. */
    if (offset != 0) return -1;
    uint32_t sector_size = p8_flash_disk_sector_size();
    if (bufsize % sector_size != 0) return -1;
    uint32_t count = bufsize / sector_size;
    if (p8_flash_disk_read((uint8_t *)buffer, lba, count) != 0) return -1;
    return (int32_t)bufsize;
}

bool tud_msc_is_writable_cb(uint8_t lun) {
    (void)lun;
    return true;
}

int32_t tud_msc_write10_cb(uint8_t lun, uint32_t lba, uint32_t offset,
                            uint8_t *buffer, uint32_t bufsize) {
    (void)lun;
    msc_touch();
    if (offset != 0) return -1;
    uint32_t sector_size = p8_flash_disk_sector_size();
    if (bufsize % sector_size != 0) return -1;
    uint32_t count = bufsize / sector_size;
    if (p8_flash_disk_write(buffer, lba, count) != 0) return -1;
    return (int32_t)bufsize;
}

/* Generic SCSI passthrough: respond to commands we don't otherwise
 * handle. SYNCHRONIZE_CACHE (0x35) is the host telling us "make sure
 * everything you accepted is on stable storage". This is the cleanest
 * trigger for our deferred flush. */
int32_t tud_msc_scsi_cb(uint8_t lun, uint8_t const scsi_cmd[16],
                         void *buffer, uint16_t bufsize) {
    (void)lun; (void)scsi_cmd; (void)buffer; (void)bufsize;
    /* SYNCHRONIZE_CACHE (0x35) used to flush here, but flushing
     * inside an MSC callback blocks tud_task() for ~1s and the
     * host disconnects mid-flush. The main loop drains the cache
     * continuously instead. */
    return 0;
}
