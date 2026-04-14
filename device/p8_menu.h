/*
 * ThumbyP8 — generic in-game pause menu.
 *
 * Reusable UI module adapted from ThumbyNES. Takes a list of items
 * and runs a modal event loop on top of the existing 128×128
 * framebuffer. The frozen game frame stays visible behind a darkened
 * overlay.
 *
 * Triggered by long-pressing MENU during gameplay or from the picker.
 */
#ifndef THUMBYP8_MENU_H
#define THUMBYP8_MENU_H

#include <stdbool.h>
#include <stdint.h>

#define P8_MENU_MAX_ITEMS  16

typedef enum {
    P8_MENU_KIND_ACTION,    /* A activates; returns action_id to caller */
    P8_MENU_KIND_TOGGLE,    /* bool: LEFT/RIGHT or A flips           */
    P8_MENU_KIND_SLIDER,    /* int with min/max                       */
    P8_MENU_KIND_CHOICE,    /* int index into named choices array     */
    P8_MENU_KIND_INFO,      /* non-interactive: label + info_text;    *
                             * optional bar via value_ptr/min/max     */
} p8_menu_kind_t;

typedef struct {
    p8_menu_kind_t    kind;
    const char       *label;
    int              *value_ptr;       /* TOGGLE / SLIDER / CHOICE */
    int               min, max;        /* SLIDER */
    const char *const *choices;        /* CHOICE — array of label strings */
    int               num_choices;
    bool              enabled;         /* greyed-out + unselectable when false */
    int               action_id;       /* ACTION — returned to caller */
    const char       *suffix;          /* optional trailing hint */
    const char       *info_text;       /* INFO — value column text */
} p8_menu_item_t;

typedef enum {
    P8_MENU_RESUME = 0,
    P8_MENU_ACTION = 1,
} p8_menu_result_kind_t;

typedef struct {
    p8_menu_result_kind_t kind;
    int                   action_id;
} p8_menu_result_t;

/* Action IDs for ThumbyP8 menu items */
#define P8_MENU_ACT_RESUME    0
#define P8_MENU_ACT_QUIT      1

/* Run the modal menu loop. `fb` is the 128×128 RGB565 scanline buffer.
 * `scratch` is a 32KB buffer for the darkened backdrop (avoids malloc).
 * Returns when the user picks Resume / activates an Action / presses B. */
p8_menu_result_t p8_menu_run(uint16_t        *fb,
                              uint16_t        *scratch,
                              const char      *title,
                              const char      *subtitle,
                              p8_menu_item_t  *items,
                              int              n_items);

#endif
