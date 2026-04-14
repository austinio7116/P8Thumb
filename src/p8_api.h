/*
 * ThumbyP8 — Lua bindings for the PICO-8 API.
 *
 * Phase 1+2 surface: drawing primitives, sprites, map, input,
 * a few math helpers. We do NOT yet bind audio (Phase 4) or
 * persistent storage (Phase 6).
 *
 * The bindings need to know which `p8_machine` and `p8_input`
 * they're talking to. We stash pointers in the Lua registry
 * under fixed light-userdata keys when the API is installed.
 */
#ifndef THUMBYP8_API_H
#define THUMBYP8_API_H

#include "p8.h"
#include "p8_machine.h"
#include "p8_input.h"

void p8_api_install(p8_vm *vm, p8_machine *machine, p8_input *input);

/* Helper used by the host runner: invoke a global function `name`
 * with no args. Returns 0 if the function doesn't exist or returned
 * cleanly; nonzero on Lua error. Errors print to stderr. */
int p8_api_call_optional(p8_vm *vm, const char *name);

/* Force-register C native overrides that must shadow any Lua
 * definitions from the cart. Call after cart top-level code runs. */
void p8_api_post_load(p8_vm *vm);

/* Custom menu items registered by menuitem(). Returns count (0-5).
 * Labels are stored internally; pointers valid until next menuitem call. */
int p8_api_get_menuitems(const char **labels, int max);

/* Invoke menuitem callback for slot idx (0-based) with button bitmask.
 * Returns 1 if the callback returned true (keep menu open), 0 otherwise. */
int p8_api_menuitem_invoke(p8_vm *vm, int idx, int buttons);

/* Optional binding-call trace hook. If set to non-NULL, every
 * traced binding will call this with its name on entry. The device
 * firmware sets this to p8_log_ring so a hardfault dump shows
 * which binding was last called. Default NULL → tracing disabled. */
extern void (*p8_trace_hook)(const char *name);

#endif
