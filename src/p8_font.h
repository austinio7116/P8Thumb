/*
 * ThumbyP8 — built-in tiny font for print().
 *
 * 3×5 bitmap cells, 4×6 layout (1 px spacing column + 1 px spacing
 * row). Covers printable ASCII 32..127. Lowercase is folded to the
 * same glyph as uppercase — it's a placeholder font, not the real
 * PICO-8 font, so we keep it small.
 *
 * Each glyph is a 16-bit mask, 3 cols × 5 rows, row-major, LSB =
 * top-left. See p8_font.c for the table.
 */
#ifndef THUMBYP8_FONT_H
#define THUMBYP8_FONT_H

#include <stdint.h>
#include "p8_machine.h"

#define P8_FONT_CELL_W 4   /* char cell width in px (3 data + 1 gap) */
#define P8_FONT_CELL_H 6   /* char cell height in px (5 data + 1 gap) */

/* Draw `text` at (x,y) in color `c`. Returns the x position after
 * the last character drawn. Honors the machine's camera and clip. */
int p8_font_draw(p8_machine *m, const char *text, int x, int y, int c);

#endif
