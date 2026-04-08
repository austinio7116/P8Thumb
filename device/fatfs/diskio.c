/*
 * ThumbyP8 — FatFs glue layer.
 *
 * Single physical drive (pdrv = 0) backed by p8_flash_disk.
 */
#include "ff.h"
#include "diskio.h"
#include "../p8_flash_disk.h"

DSTATUS disk_status(BYTE pdrv) {
    return (pdrv == 0) ? 0 : STA_NOINIT;
}

DSTATUS disk_initialize(BYTE pdrv) {
    if (pdrv != 0) return STA_NOINIT;
    p8_flash_disk_init();
    return 0;
}

DRESULT disk_read(BYTE pdrv, BYTE *buff, LBA_t sector, UINT count) {
    if (pdrv != 0) return RES_PARERR;
    return p8_flash_disk_read(buff, (uint32_t)sector, count) == 0 ? RES_OK : RES_ERROR;
}

#if FF_FS_READONLY == 0
DRESULT disk_write(BYTE pdrv, const BYTE *buff, LBA_t sector, UINT count) {
    if (pdrv != 0) return RES_PARERR;
    return p8_flash_disk_write(buff, (uint32_t)sector, count) == 0 ? RES_OK : RES_ERROR;
}
#endif

DRESULT disk_ioctl(BYTE pdrv, BYTE cmd, void *buff) {
    if (pdrv != 0) return RES_PARERR;
    switch (cmd) {
    case CTRL_SYNC:
        return RES_OK;
    case GET_SECTOR_COUNT:
        *(LBA_t *)buff = (LBA_t)p8_flash_disk_sector_count();
        return RES_OK;
    case GET_SECTOR_SIZE:
        *(WORD *)buff = (WORD)p8_flash_disk_sector_size();
        return RES_OK;
    case GET_BLOCK_SIZE:
        *(DWORD *)buff = 8;   /* erase block / sector size = 4096/512 */
        return RES_OK;
    }
    return RES_PARERR;
}

/* Real-time clock stub: FatFs uses this for file timestamps. We
 * don't have an RTC for this firmware, so return a fixed sane date. */
DWORD get_fattime(void) {
    /* 2026-01-01 00:00:00, packed FAT format */
    return ((DWORD)(2026 - 1980) << 25) | ((DWORD)1 << 21) | ((DWORD)1 << 16);
}
