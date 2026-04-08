/*
 * ThumbyP8 — flash-backed disk with write-back RAM cache.
 *
 * The MSC callback path runs at high priority and CANNOT block.
 * Flash erase + program disables interrupts for ~50–100 ms per
 * 4 KB block on this chip; doing that synchronously inside an
 * MSC write call starves USB and the host disconnects.
 *
 * Strategy: keep a small RAM cache of dirty erase-blocks. Writes
 * land in cache and return immediately. The main loop flushes the
 * cache when:
 *   - the host issues a SCSI SYNC_CACHE,
 *   - the host issues a START_STOP eject,
 *   - the cache has been idle (no writes) for more than ~750 ms,
 *   - the cache fills up (then we flush the oldest entry).
 *
 * Reads consult the cache before falling through to XIP-mapped
 * flash so the host always sees its own writes consistently even
 * before they're committed.
 */
#include "p8_flash_disk.h"

#include <string.h>
#include "pico/stdlib.h"
#include "pico/time.h"
#include "hardware/flash.h"
#include "hardware/sync.h"

#define XIP_BASE_ADDR 0x10000000u

/* Cache: 16 erase-blocks (64 KB). With the continuous-drain main
 * loop we no longer need to absorb a whole file at once — we just
 * need enough headroom to bridge the 300 ms USB-quiet windows
 * between host bursts. 64 KB returns 64 KB to the malloc heap so
 * stb_image's PNG decoder (~150 KB peak) actually fits. */
#define CACHE_BLOCKS 16

typedef struct {
    int32_t  block;     /* erase-block index, -1 = empty slot */
    uint32_t age;       /* monotonic, lower = older */
    uint8_t  dirty;
    uint8_t  data[FLASH_DISK_ERASE];
} cache_entry;

static cache_entry        cache[CACHE_BLOCKS];
static uint32_t           cache_clock = 0;
static absolute_time_t    last_write_time;

/* Diagnostic counters */
static uint32_t stat_writes        = 0;
static uint32_t stat_commits       = 0;
static uint32_t stat_commit_errors = 0;

void p8_flash_disk_init(void) {
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        cache[i].block = -1;
        cache[i].dirty = 0;
        cache[i].age   = 0;
    }
    cache_clock = 0;
    last_write_time = get_absolute_time();
}

uint32_t p8_flash_disk_sector_count(void) { return FLASH_DISK_SECTORS; }
uint32_t p8_flash_disk_sector_size (void) { return FLASH_DISK_SECTOR_SIZE; }

/* --- cache lookup ---------------------------------------------------- */
static int find_cache(int32_t block) {
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        if (cache[i].block == block) return i;
    }
    return -1;
}

/* Pick a slot to evict. Prefers empty, then oldest clean, then
 * oldest dirty (which forces a flush). */
static int __not_in_flash_func(pick_evict)(void) {
    int empty = -1;
    int oldest_clean = -1;
    int oldest_dirty = -1;
    uint32_t oc_age = 0xffffffffu;
    uint32_t od_age = 0xffffffffu;
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        if (cache[i].block < 0) { empty = i; break; }
        if (cache[i].dirty) {
            if (cache[i].age < od_age) { od_age = cache[i].age; oldest_dirty = i; }
        } else {
            if (cache[i].age < oc_age) { oc_age = cache[i].age; oldest_clean = i; }
        }
    }
    if (empty       >= 0) return empty;
    if (oldest_clean >= 0) return oldest_clean;
    return oldest_dirty;
}

/* Commit one cache entry to flash.
 *
 * Erase has to be atomic — the chip must be left undisturbed for
 * the ~50 ms it takes to wipe a 4 KB sector — so IRQs are off for
 * the full erase. There's no way around that on this hardware.
 *
 * Program, however, can be split. We drive it as 16 individual
 * 256-byte page programs, each ~1 ms with IRQs disabled, with IRQs
 * RE-ENABLED between pages. That gives the USB controller plenty
 * of opportunity to service incoming packets and ack outstanding
 * transfers. Without this split, a single commit_entry() would
 * keep IRQs off for ~66 ms straight, the host would NAK out, and
 * the device would disconnect mid-flush. */
#define PROG_CHUNK 256

static void __not_in_flash_func(commit_entry)(int idx) {
    if (idx < 0 || cache[idx].block < 0 || !cache[idx].dirty) return;
    uint32_t flash_off = FLASH_DISK_OFFSET +
        (uint32_t)cache[idx].block * FLASH_DISK_ERASE;

    /* Erase — atomic */
    {
        uint32_t ints = save_and_disable_interrupts();
        flash_range_erase(flash_off, FLASH_DISK_ERASE);
        restore_interrupts(ints);
    }

    /* Program — chunked, IRQs re-enabled between chunks */
    for (uint32_t off = 0; off < FLASH_DISK_ERASE; off += PROG_CHUNK) {
        uint32_t ints = save_and_disable_interrupts();
        flash_range_program(flash_off + off, cache[idx].data + off, PROG_CHUNK);
        restore_interrupts(ints);
        /* IRQs are now on — USB controller can service any pending
         * packets / endpoint transfers before we start the next page. */
    }

    /* Verify: read back through XIP and compare against the cache.
     * Any mismatch means flash didn't accept what we wrote (XIP
     * cache stale, wrong offset, programming failed). */
    {
        const uint8_t *xip = (const uint8_t *)(0x10000000u + flash_off);
        if (memcmp(xip, cache[idx].data, FLASH_DISK_ERASE) != 0) {
            stat_commit_errors++;
        }
    }
    cache[idx].dirty = 0;
}

/* Load a flash block into the cache (evicting another entry if
 * necessary), and return the slot index. */
static int __not_in_flash_func(load_block)(int32_t block) {
    int idx = find_cache(block);
    if (idx >= 0) {
        cache[idx].age = ++cache_clock;
        return idx;
    }
    idx = pick_evict();
    if (cache[idx].dirty) commit_entry(idx);
    /* Pull from XIP-mapped flash */
    const uint8_t *src = (const uint8_t *)
        (XIP_BASE_ADDR + FLASH_DISK_OFFSET + (uint32_t)block * FLASH_DISK_ERASE);
    memcpy(cache[idx].data, src, FLASH_DISK_ERASE);
    cache[idx].block = block;
    cache[idx].dirty = 0;
    cache[idx].age   = ++cache_clock;
    return idx;
}

/* --- read: consult cache then fall back to XIP ----------------------- */
int p8_flash_disk_read(uint8_t *dst, uint32_t sector, uint32_t count) {
    if (sector + count > FLASH_DISK_SECTORS) return -1;
    const uint32_t spb = FLASH_DISK_ERASE / FLASH_DISK_SECTOR_SIZE;
    const uint8_t *xip = (const uint8_t *)
        (XIP_BASE_ADDR + FLASH_DISK_OFFSET + sector * FLASH_DISK_SECTOR_SIZE);
    memcpy(dst, xip, count * FLASH_DISK_SECTOR_SIZE);

    /* Overlay any cached blocks that intersect the read range. */
    for (uint32_t i = 0; i < count; i++) {
        uint32_t sec = sector + i;
        int32_t  blk = (int32_t)(sec / spb);
        int      idx = find_cache(blk);
        if (idx >= 0) {
            uint32_t off = (sec % spb) * FLASH_DISK_SECTOR_SIZE;
            memcpy(dst + i * FLASH_DISK_SECTOR_SIZE,
                   cache[idx].data + off, FLASH_DISK_SECTOR_SIZE);
        }
    }
    return 0;
}

/* --- write: into cache only, no flash work ------------------------- */
int p8_flash_disk_write(const uint8_t *src, uint32_t sector, uint32_t count) {
    if (sector + count > FLASH_DISK_SECTORS) return -1;
    const uint32_t spb = FLASH_DISK_ERASE / FLASH_DISK_SECTOR_SIZE;
    for (uint32_t i = 0; i < count; i++) {
        uint32_t sec = sector + i;
        int32_t  blk = (int32_t)(sec / spb);
        uint32_t off = (sec % spb) * FLASH_DISK_SECTOR_SIZE;
        int      idx = load_block(blk);
        memcpy(cache[idx].data + off,
               src + i * FLASH_DISK_SECTOR_SIZE,
               FLASH_DISK_SECTOR_SIZE);
        cache[idx].dirty = 1;
    }
    stat_writes += count;
    last_write_time = get_absolute_time();
    return 0;
}

/* --- flush API ------------------------------------------------------ */

void __not_in_flash_func(p8_flash_disk_flush)(void) {
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        if (cache[i].dirty) commit_entry(i);
    }
}

/* Commit a single dirty entry, picking the oldest one so we drain
 * in roughly insertion order. Returns 1 if a commit happened, 0
 * otherwise. Intended for the main loop's cooperative drain. */
int __not_in_flash_func(p8_flash_disk_commit_one)(void) {
    int oldest = -1;
    uint32_t oldest_age = 0xffffffffu;
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        if (cache[i].dirty && cache[i].age < oldest_age) {
            oldest_age = cache[i].age;
            oldest = i;
        }
    }
    if (oldest < 0) return 0;
    commit_entry(oldest);
    stat_commits++;
    return 1;
}

uint32_t p8_flash_disk_stat_writes       (void) { return stat_writes;        }
uint32_t p8_flash_disk_stat_commits      (void) { return stat_commits;       }
uint32_t p8_flash_disk_stat_commit_errors(void) { return stat_commit_errors; }
uint32_t p8_flash_disk_stat_dirty_n(void) {
    uint32_t n = 0;
    for (int i = 0; i < CACHE_BLOCKS; i++) if (cache[i].dirty) n++;
    return n;
}

int p8_flash_disk_dirty(void) {
    for (int i = 0; i < CACHE_BLOCKS; i++) {
        if (cache[i].dirty) return 1;
    }
    return 0;
}

uint32_t p8_flash_disk_idle_us(void) {
    return (uint32_t)absolute_time_diff_us(last_write_time, get_absolute_time());
}
