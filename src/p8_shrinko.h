/*
 * ThumbyP8 — PICO-8 tokenizer, parser, and unminifier (C port of shrinko8).
 *
 * Faithful port of:
 *   tools/shrinko8/pico_tokenize.py  (tokenizer)
 *   tools/shrinko8/pico_parse.py     (recursive descent parser)
 *   tools/shrinko8/pico_unminify.py  (AST → formatted Lua source)
 *
 * PICO-8 only (no Picotron). No scope/variable tracking, no minification.
 * Memory-efficient for RP2350 (~370KB free RAM).
 */
#ifndef THUMBYP8_SHRINKO_H
#define THUMBYP8_SHRINKO_H

#include <stddef.h>

/* Takes raw PICO-8 Lua source, returns malloc'd unminified Lua source.
 * Caller frees the result. Returns NULL on failure. */
char *p8_shrinko_unminify(const char *src, size_t len, size_t *out_len);

#endif
