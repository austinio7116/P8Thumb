/*
 * ThumbyP8 — PICO-8 Lua dialect rewriter.
 *
 * PICO-8 extends Lua with a handful of syntax quirks. We translate
 * them to vanilla Lua 5.4 before handing the source to luaL_loadbuffer.
 *
 * Handled (Phase 3):
 *   !=                    → ~=
 *   x op= expr            → x = x op (expr)   for op ∈ + - * / %
 *   if (cond) stmt        → if cond then stmt end
 *                           (only when no `then` follows the close paren)
 *
 * Not yet handled:
 *   ?expr                 (print shorthand)
 *   0b10101               (binary literals)
 *   .1 (bare decimals)    — Lua 5.4 handles these natively, no rewrite needed
 *   <<= >>= ..=           (rarer compound ops)
 *   if (cond) stmt else s (shorthand with else)
 *
 * The rewriter is comment- and string-aware: block comments, line
 * comments, single-quoted strings, double-quoted strings, and long
 * strings all suppress substitutions. It does NOT attempt to parse
 * Lua — the transforms are pattern-level and rely on the fact that
 * compound assigns in real carts always sit on one physical line.
 */
#ifndef THUMBYP8_REWRITE_H
#define THUMBYP8_REWRITE_H

#include <stddef.h>

/* Rewrite a buffer of PICO-8 Lua source into vanilla Lua. Returns
 * a malloc'd, NUL-terminated buffer. Caller frees with free().
 * Returns NULL on allocation failure. */
char *p8_rewrite_lua(const char *src, size_t len, size_t *out_len);

#endif
