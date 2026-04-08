/*
 * ThumbyP8 — cart picker UI.
 *
 * Scans the FAT filesystem mounted on the flash disk for *.p8.png
 * cart files under /carts/, decodes each cart's PNG label as a
 * 64×64 thumbnail, and displays a scrollable grid. Returns the
 * full path of the selected cart, or NULL if the user backed out.
 *
 * The grid layout is 2 columns × 2 rows per page. Each thumbnail
 * cell is 64×64 (downscaled from PICO-8's 128×128 label area)
 * with the cart name underneath.
 */
#ifndef THUMBYP8_PICKER_H
#define THUMBYP8_PICKER_H

#include "p8_machine.h"
#include "p8_input.h"
#include "p8_lcd_gc9107.h"

#define P8_PICKER_MAX_CARTS  64
#define P8_PICKER_NAME_MAX   48

typedef struct {
    char name[P8_PICKER_NAME_MAX];   /* base file name (no /carts/ prefix) */
} p8_cart_entry;

/* Scan /carts/ for *.p8.png; populates `out` and returns the count.
 * Returns 0 if no carts found (caller should fall back). */
int p8_picker_scan(p8_cart_entry *out, int max);

/* Run the picker UI. Reads buttons each frame, draws thumbnails into
 * the framebuffer, presents to LCD. Returns the index of the chosen
 * cart in `entries[]`, or -1 if cancelled. */
int p8_picker_run(p8_machine *m, p8_input *in, uint16_t *scanline,
                   const p8_cart_entry *entries, int n_entries);

/* Read a cart file fully into a malloc'd buffer. Caller frees. */
unsigned char *p8_picker_load_cart(const char *name, size_t *out_len);

#endif
