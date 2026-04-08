/*
 * ThumbyP8 — diagnostic logging helpers.
 *
 * p8_log_stage(): repaint the screen with a status line at the
 * bottom and push it to the LCD immediately. Used to show progress
 * through slow operations (cart load, PNG decode, Lua compile).
 * If something hangs, the last stage shown is the one that's stuck.
 *
 * p8_log_to_file(): append a single line to /thumbyp8.log on the
 * mounted FAT filesystem and force a flush. The user can read the
 * file via USB after a hang to see what was logged. NOTE: this
 * blocks for a flash write (~50 ms) so don't use it inside any
 * USB callback path.
 */
#ifndef THUMBYP8_LOG_H
#define THUMBYP8_LOG_H

#include <stdint.h>
#include "p8_machine.h"

void p8_log_stage   (p8_machine *m, uint16_t *scanline, const char *msg);
void p8_log_to_file (const char *msg);

#endif
