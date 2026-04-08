/*
 * ThumbyP8 — diagnostic logging implementation.
 */
#include "p8_log.h"
#include "p8_lcd_gc9107.h"
#include "p8_flash_disk.h"
#include "p8_draw.h"
#include "p8_font.h"

#include <string.h>
#include <stdio.h>
#include <malloc.h>
#include "ff.h"

/* Approximate free heap. newlib's mallinfo returns 'fordblks' which
 * is the total free space in the currently extended malloc arena. */
static unsigned free_heap_bytes(void) {
    struct mallinfo mi = mallinfo();
    return (unsigned)mi.fordblks;
}

/* Scrollback ring of recent stage messages so we can see the history
 * of where the loader got, not just the most recent line. */
#define STAGE_LINES 6
#define STAGE_LEN   28
static char     stage_ring[STAGE_LINES][STAGE_LEN];
static int      stage_count = 0;

static void stage_push(const char *msg) {
    if (stage_count < STAGE_LINES) {
        strncpy(stage_ring[stage_count], msg, STAGE_LEN - 1);
        stage_ring[stage_count][STAGE_LEN - 1] = 0;
        stage_count++;
    } else {
        /* shift up */
        for (int i = 0; i < STAGE_LINES - 1; i++) {
            memcpy(stage_ring[i], stage_ring[i+1], STAGE_LEN);
        }
        strncpy(stage_ring[STAGE_LINES - 1], msg, STAGE_LEN - 1);
        stage_ring[STAGE_LINES - 1][STAGE_LEN - 1] = 0;
    }
}

void p8_log_stage(p8_machine *m, uint16_t *scanline, const char *msg) {
    if (!m || !scanline || !msg) return;
    stage_push(msg);

    /* Clear the bottom half and redraw the scrollback. */
    p8_rectfill(m, 0, 48, 127, 117, 0);
    for (int i = 0; i < stage_count; i++) {
        p8_font_draw(m, stage_ring[i], 2, 50 + i * 7, 10);
    }
    char heap[40];
    snprintf(heap, sizeof(heap), "heap free: %u", free_heap_bytes());
    p8_font_draw(m, heap, 2, 100, 9);
    p8_font_draw(m, "decoding takes 30-60s", 0, 110, 8);
    p8_machine_present(m, scanline);
    p8_lcd_wait_idle();
    p8_lcd_present(scanline);
}

void p8_log_to_file(const char *msg) {
    if (!msg) return;
    FIL f;
    /* Open in append mode, creating if necessary. */
    if (f_open(&f, "/thumbyp8.log", FA_WRITE | FA_OPEN_APPEND) != FR_OK) {
        return;
    }
    UINT bw;
    f_write(&f, msg, (UINT)strlen(msg), &bw);
    f_write(&f, "\n", 1, &bw);
    f_close(&f);
    /* Force the cache to flash so a subsequent crash doesn't lose
     * the line we just wrote. */
    p8_flash_disk_flush();
}
