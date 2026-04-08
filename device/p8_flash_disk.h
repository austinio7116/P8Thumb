/*
 * ThumbyP8 — flash-backed disk for FatFs and TinyUSB MSC.
 *
 * The Thumby Color carries a 16 MB QSPI flash. We reserve the
 * bottom 1 MB for firmware growth and give the next 12 MB to the
 * FAT filesystem for cart storage. Three MB on the top end is
 * left as a safety margin.
 *
 *   0x10000000 .. 0x10100000   firmware (1 MB room — currently ~700 KB)
 *   0x10100000 .. 0x10D00000   FAT FS for carts (12 MB)
 *   0x10D00000 .. 0x11000000   reserved / future
 *
 * 12 MB at 4 KB clusters → 3072 clusters → well under the FAT12
 * 4084-cluster cap. Holds ~180 typical .p8.png carts.
 *
 * Sector size: 512 bytes. Erase block: 4 KB. Reads pull from the
 * XIP-mapped region directly; writes erase the containing 4 KB
 * block then program it back.
 */
#ifndef THUMBYP8_FLASH_DISK_H
#define THUMBYP8_FLASH_DISK_H

#include <stdint.h>
#include <stddef.h>

#define FLASH_DISK_OFFSET   (1u * 1024u * 1024u)    /* 1 MB into flash  */
#define FLASH_DISK_SIZE     (12u * 1024u * 1024u)   /* 12 MB usable     */
#define FLASH_DISK_SECTOR_SIZE 512
#define FLASH_DISK_SECTORS  (FLASH_DISK_SIZE / FLASH_DISK_SECTOR_SIZE)
#define FLASH_DISK_ERASE    4096

void p8_flash_disk_init(void);

/* Sector-level R/W (matches TinyUSB MSC + FatFs diskio signatures). */
int  p8_flash_disk_read (uint8_t *dst, uint32_t sector, uint32_t count);
int  p8_flash_disk_write(const uint8_t *src, uint32_t sector, uint32_t count);

uint32_t p8_flash_disk_sector_count(void);
uint32_t p8_flash_disk_sector_size(void);

/* Commit AT MOST ONE dirty cache entry to flash. Returns 1 if a
 * block was committed, 0 if there was nothing dirty. Designed to
 * be called from the main loop between tud_task() invocations so
 * USB stays responsive across a multi-block flush. Each call
 * blocks IRQs only for ~50 ms erase + 16 × ~1 ms program chunks. */
int  p8_flash_disk_commit_one(void);

/* Drain the entire cache to flash. NEVER call this from inside an
 * MSC callback or any other USB context — it can take a full
 * second of mostly-IRQ-off time and the host will disconnect.
 * Safe from boot, from a quiescent main loop, or after USB has
 * already been torn down. */
void p8_flash_disk_flush(void);

/* Returns 1 if there's at least one dirty cache entry. */
int  p8_flash_disk_dirty(void);

/* Diagnostic counters, reset at boot. */
uint32_t p8_flash_disk_stat_writes        (void);  /* MSC write_10 calls  */
uint32_t p8_flash_disk_stat_commits       (void);  /* successful block commits */
uint32_t p8_flash_disk_stat_commit_errors (void);  /* read-back mismatches */
uint32_t p8_flash_disk_stat_dirty_n       (void);  /* current dirty block count */

/* Microseconds since the last write came in. The main loop polls
 * this and calls flush() when no write has happened for a while. */
uint32_t p8_flash_disk_idle_us(void);

#endif
