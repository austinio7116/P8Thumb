/*
 * ThumbyP8 — full PICO-8 dialect → Lua 5.4 translator (C).
 *
 * On-device equivalent of the Python pipeline (post_fix_lua +
 * pico8_lua.py). Takes raw PXA-decompressed PICO-8 source and
 * produces valid Lua 5.4 that luaL_loadbuffer can compile.
 *
 * The translator runs in two phases:
 *   Phase 1 (p8_translate_chars): character-level transforms with
 *     string/comment state tracking — operators, escapes, glyphs,
 *     binary literals, comments, peek shorthands.
 *   Phase 2 (p8_rewrite_lua from p8_rewrite.c): token-level
 *     transforms — compound assigns, !=, number separation.
 *
 * Memory: allocates a new buffer (~1.5× input size). Caller frees.
 * Runs once per cart at conversion time, not per frame.
 */
#ifndef THUMBYP8_TRANSLATE_H
#define THUMBYP8_TRANSLATE_H

#include <stddef.h>

/* Full translation: PICO-8 source → Lua 5.4 source.
 * Returns malloc'd NUL-terminated buffer. Caller frees. */
char *p8_translate_full(const char *src, size_t len, size_t *out_len);

#endif
