/*
 * ThumbyP8 — full PICO-8 dialect → Lua 5.2 translator (C).
 *
 * On-device equivalent of the Python pipeline (post_fix_lua +
 * pico8_lua.py). Takes raw PXA-decompressed PICO-8 source and
 * produces valid Lua 5.2 that luaL_loadbuffer can compile.
 *
 * Architecture:
 *   Phase 0 (pre_tokenize): character-level transforms that must
 *     happen before tokenization — // comments, P8SCII escapes,
 *     glyph substitution, ? print, ; before (, highbytes.
 *   Phase 1 (tokenize): proper lexer that splits even heavily
 *     minified PICO-8 source into discrete tokens. Ported from
 *     pico8_lua.py's tokenize(). This is the critical piece that
 *     handles `1return`, `0nC()`, `j-=1return` correctly.
 *   Phase 2 (token rewrites): normalise !=→~=, 0b→decimal,
 *     compound assigns, shorthand if/while, if-cond-do→then,
 *     \→//, ^^→~, @/%/$ peek shorthands.
 *   Phase 3 (emit): join tokens with whitespace insertion between
 *     adjacent IDENT/NUMBER to prevent re-merging.
 *
 * Memory: allocates working buffers. Caller frees the result.
 * Runs once per cart at conversion time, not per frame.
 */
#include "p8_translate.h"
#include "p8_shrinko.h"

#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ================================================================== */
/* Growable buffer                                                     */
/* ================================================================== */
typedef struct {
    char  *d;
    size_t len, cap;
} buf_t;

static void buf_grow(buf_t *b, size_t need) {
    if (b->len + need + 1 <= b->cap) return;
    size_t nc = b->cap ? b->cap : 256;
    while (nc < b->len + need + 1) nc *= 2;
    b->d = (char *)realloc(b->d, nc);
    b->cap = nc;
}
static void buf_putc(buf_t *b, char c) {
    buf_grow(b, 1); b->d[b->len++] = c;
}
static void buf_puts(buf_t *b, const char *s, size_t n) {
    if (!n || !s) return;
    buf_grow(b, n); memcpy(b->d + b->len, s, n); b->len += n;
}
static void buf_str(buf_t *b, const char *s) { buf_puts(b, s, strlen(s)); }
static void buf_int(buf_t *b, int v) {
    char tmp[16]; int n = snprintf(tmp, sizeof(tmp), "%d", v);
    buf_puts(b, tmp, n);
}
static char *buf_finish(buf_t *b, size_t *out_len) {
    buf_grow(b, 1); b->d[b->len] = 0;
    if (out_len) *out_len = b->len;
    return b->d;
}

/* ================================================================== */
/* Token types                                                         */
/* ================================================================== */
enum {
    T_IDENT = 1, T_NUMBER, T_STRING, T_OP, T_WS, T_NL, T_COMMENT, T_RAW
};

typedef struct {
    int   kind;
    char *text;
    int   len;
    int   vline;  /* virtual line number — for shorthand-if same-line check */
} tok_t;

/* Dynamic token array */
typedef struct {
    tok_t *items;
    int    count, cap;
} toklist_t;

static void tl_push(toklist_t *tl, int kind, const char *text, int len) {
    if (tl->count >= tl->cap) {
        tl->cap = tl->cap ? tl->cap * 2 : 128;
        tl->items = (tok_t *)realloc(tl->items, tl->cap * sizeof(tok_t));
    }
    tok_t *t = &tl->items[tl->count++];
    t->kind = kind;
    t->text = (char *)malloc(len + 1);
    memcpy(t->text, text, len);
    t->text[len] = 0;
    t->len = len;
    t->vline = 0;
}

static void tl_free(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) free(tl->items[i].text);
    free(tl->items);
    tl->items = NULL;
    tl->count = tl->cap = 0;
}

/* Replace a token's text */
static void tok_set(tok_t *t, int kind, const char *text, int len) {
    free(t->text);
    t->kind = kind;
    t->text = (char *)malloc(len + 1);
    memcpy(t->text, text, len);
    t->text[len] = 0;
    t->len = len;
}

/* ================================================================== */
/* P8SCII glyph table                                                  */
/* ================================================================== */
typedef struct { const char *seq; int slen, val; } glyph_t;
#define G(s, v) { s, sizeof(s)-1, v }
static const glyph_t g_glyphs[] = {
    G("\xf0\x9f\x90\xb1",131),
    G("\xf0\x9f\x85\xbe",4),     /* 🅾 → button O (index 4) */
    G("\xf0\x9f\x98\x90",141),
    G("\xe2\xac\x85",0),          /* ⬅ → button LEFT (index 0) */
    G("\xe2\x9e\xa1",1),          /* ➡ → button RIGHT (index 1) */
    G("\xe2\xac\x86",2),          /* ⬆ → button UP (index 2) */
    G("\xe2\xac\x87",3),          /* ⬇ → button DOWN (index 3) */
    G("\xe2\x9d\x8e",5),          /* ❎ → button X (index 5) */
    G("\xe2\x97\x8b",128),
    G("\xe2\x96\x88",129), G("\xe2\x96\x92",130),
    G("\xe2\x96\x91",133), G("\xe2\x9c\xbd",134),
    G("\xe2\x97\x8f",135), G("\xe2\x99\xa5",136),
    G("\xe2\x98\x89",137), G("\xec\x9b\x83",138),
    G("\xe2\x8c\x82",139), G("\xe2\x99\xaa",142),
    G("\xe2\x97\x86",144), G("\xe2\x80\xa6",145),
    G("\xe2\x98\x85",147), G("\xe2\xa7\x97",148),
    G("\xe2\x96\xae",16),  G("\xe2\x96\xa0",17),
    G("\xe2\x96\xa1",18),  G("\xe2\x81\x99",19),
    G("\xe2\x81\x98",20),  G("\xe2\x80\x96",21),
    G("\xe2\x97\x80",22),  G("\xe2\x96\xb6",23),
    G("\xe3\x80\x8c",24),  G("\xe3\x80\x8d",25),
    G("\xe2\x80\xa2",27),  G("\xe2\x96\xa4",153),
    G("\xe2\x96\xa5",154),
    G("\xc2\xb9",1), G("\xc2\xb2",2), G("\xc2\xb3",3),
    G("\xe2\x81\xb4",4), G("\xe2\x81\xb5",5), G("\xe2\x81\xb6",6),
    G("\xe2\x81\xb7",7), G("\xe2\x81\xb8",8),
    G("\xc2\xa5",26), G("\xcb\x87",150), G("\xe2\x88\xa7",151),
    G("\xe3\x80\x81",28), G("\xe3\x80\x82",29),
    G("\xe3\x82\x9b",30), G("\xe3\x82\x9c",31),
    G("\xef\xb8\x8f",-1),  /* variation selector — strip */
};
#define N_GLYPHS (sizeof(g_glyphs)/sizeof(g_glyphs[0]))

static int match_glyph(const unsigned char *s, size_t len, size_t i) {
    int best = -1, best_len = 0;
    for (int g = 0; g < (int)N_GLYPHS; g++) {
        if (g_glyphs[g].slen <= best_len) continue;
        if (i + (size_t)g_glyphs[g].slen > len) continue;
        if (memcmp(s + i, g_glyphs[g].seq, g_glyphs[g].slen) == 0) {
            best = g; best_len = g_glyphs[g].slen;
        }
    }
    return best;
}

/* ================================================================== */
/* Phase 0: pre-tokenize character transforms                          */
/*                                                                     */
/* These must happen before the tokenizer because they change the      */
/* character structure (// comments, glyph bytes, string escapes).     */
/* ================================================================== */
static int is_id(int c) { return c == '_' || isalnum((unsigned char)c) || (unsigned char)c >= 0x80; }

static char *pre_tokenize(const char *src, size_t len, size_t *out_len) {
    const unsigned char *s = (const unsigned char *)src;
    buf_t o = {0};
    buf_grow(&o, len + len / 2);

    size_t i = 0;
    int at_line_start = 1;

    while (i < len) {
        unsigned char c = s[i];

        /* ---- Block comment --[[ ... ]] ---- */
        if (c == '-' && i + 1 < len && s[i+1] == '-') {
            if (i + 2 < len && s[i+2] == '[') {
                size_t eq = 0, j = i + 3;
                while (j < len && s[j] == '=') { eq++; j++; }
                if (j < len && s[j] == '[') {
                    size_t start = i; j++;
                    while (j < len) {
                        if (s[j] == ']') {
                            size_t k = j+1, ceq = 0;
                            while (k < len && s[k] == '=') { ceq++; k++; }
                            if (ceq == eq && k < len && s[k] == ']') {
                                buf_puts(&o, (const char*)s+start, k+1-start);
                                i = k+1; goto next;
                            }
                        }
                        j++;
                    }
                    buf_puts(&o, (const char*)s+start, len-start);
                    i = len; goto done;
                }
            }
            /* Line comment -- */
            buf_puts(&o, "--", 2); i += 2;
            while (i < len && s[i] != '\n') { buf_putc(&o, s[i]); i++; }
            at_line_start = 0; goto next;
        }

        /* ---- // line comment at line start → -- ---- */
        if (c == '/' && i+1 < len && s[i+1] == '/' && at_line_start) {
            buf_puts(&o, "--", 2); i += 2;
            while (i < len && s[i] != '\n') { buf_putc(&o, s[i]); i++; }
            goto next;
        }

        /* ---- Long bracket string [[ ]] ---- */
        if (c == '[') {
            size_t eq = 0, j = i+1;
            while (j < len && s[j] == '=') { eq++; j++; }
            if (j < len && s[j] == '[') {
                size_t start = i; j++;
                while (j < len) {
                    if (s[j] == ']') {
                        size_t k = j+1, ceq = 0;
                        while (k < len && s[k] == '=') { ceq++; k++; }
                        if (ceq == eq && k < len && s[k] == ']') {
                            buf_puts(&o, (const char*)s+start, k+1-start);
                            i = k+1; at_line_start = 0; goto next;
                        }
                    }
                    j++;
                }
                buf_puts(&o, (const char*)s+start, len-start);
                i = len; goto done;
            }
        }

        /* ---- Quoted strings — rewrite escapes + highbytes ---- */
        if (c == '"' || c == '\'') {
            unsigned char q = c;
            buf_putc(&o, c); i++;
            while (i < len) {
                unsigned char ch = s[i];
                if (ch == q) { buf_putc(&o, ch); i++; break; }
                if (ch == '\n') break;
                if (ch == '\\' && i+1 < len) {
                    unsigned char nx = s[i+1];
                    if (nx=='a'||nx=='b'||nx=='f'||nx=='n'||nx=='r'||
                        nx=='t'||nx=='v'||nx=='\\'||nx=='"'||nx=='\''||
                        nx=='\n'||nx=='x'||nx=='z') {
                        buf_putc(&o,'\\'); buf_putc(&o,nx); i+=2; continue;
                    }
                    if (nx>='0' && nx<='9') {
                        size_t j2=i+1; int val=0, digs=0;
                        while (j2<len && digs<3 && s[j2]>='0' && s[j2]<='9') {
                            val = val*10+(s[j2]-'0'); j2++; digs++;
                        }
                        if (val > 255) {
                            char esc[5]; snprintf(esc,5,"\\x%02x",val&0xff);
                            buf_str(&o, esc);
                        } else {
                            buf_putc(&o,'\\');
                            buf_puts(&o,(const char*)s+i+1,j2-(i+1));
                        }
                        i = j2; continue;
                    }
                    /* P8SCII escape → \xHH */
                    { char esc[5]; snprintf(esc,5,"\\x%02x",(unsigned)nx);
                      buf_str(&o,esc); i+=2; continue; }
                }
                if (ch >= 0x80) {
                    char esc[5]; snprintf(esc,5,"\\x%02x",(unsigned)ch);
                    buf_str(&o,esc); i++; continue;
                }
                buf_putc(&o, ch); i++;
            }
            at_line_start = 0; goto next;
        }

        /* ---- Newlines ---- */
        if (c == '\n') {
            buf_putc(&o,'\n'); i++;
            at_line_start = 1; goto next;
        }
        if (c == '\r') {
            buf_putc(&o,'\n'); i++;
            if (i < len && s[i]=='\n') i++;
            at_line_start = 1; goto next;
        }

        /* ---- Whitespace at line start ---- */
        if ((c==' '||c=='\t') && at_line_start) {
            buf_putc(&o,c); i++; goto next;
        }

        /* ---- ? print shorthand at line start ---- */
        if (c == '?' && at_line_start) {
            buf_str(&o, "print("); i++;
            int depth = 0;
            while (i < len && s[i]!='\n' && s[i]!='\r') {
                unsigned char ac = s[i];
                if (ac=='"'||ac=='\'') {
                    unsigned char qq=ac; buf_putc(&o,ac); i++;
                    while (i<len && s[i]!='\n') {
                        if (s[i]=='\\' && i+1<len) { buf_putc(&o,s[i]); buf_putc(&o,s[i+1]); i+=2; continue; }
                        if (s[i]==qq) { buf_putc(&o,s[i]); i++; break; }
                        buf_putc(&o,s[i]); i++;
                    }
                    continue;
                }
                if (ac=='-' && i+1<len && s[i+1]=='-') break;
                if (ac=='('||ac=='['||ac=='{') depth++;
                if (ac==')'||ac==']'||ac=='}') depth--;
                buf_putc(&o,ac); i++;
            }
            while (o.len>0 && (o.d[o.len-1]==' '||o.d[o.len-1]=='\t')) o.len--;
            buf_putc(&o, ')');
            at_line_start = 0; goto next;
        }

        /* ---- ; before ( at line start ---- */
        /* Only insert ; if the previous line didn't end with a
         * continuation token (comma, operator, `and`, `or`).
         * Otherwise `f(a,\n(b))` becomes `f(a,\n;(b))` which breaks. */
        if (c == '(' && at_line_start) {
            int need_semi = 1;
            /* Scan back in output to find last significant char */
            size_t p = o.len;
            while (p > 0 && (o.d[p-1]==' '||o.d[p-1]=='\t'||o.d[p-1]=='\n'||o.d[p-1]=='\r')) p--;
            if (p > 0) {
                char lc = o.d[p-1];
                /* Continuation: comma, binary ops, open brackets */
                if (lc==',' || lc=='(' || lc=='[' || lc=='{' ||
                    lc=='+' || lc=='-' || lc=='*' || lc=='/' ||
                    lc=='%' || lc=='^' || lc=='=' || lc=='~' ||
                    lc=='<' || lc=='>' || lc=='&' || lc=='|' ||
                    lc=='.' || lc==':')
                    need_semi = 0;
                /* `and`, `or`, `not`, `return` etc at end of prev line */
                if (p >= 3 && memcmp(o.d+p-3, "and", 3) == 0 &&
                    (p < 4 || !is_id((unsigned char)o.d[p-4])))
                    need_semi = 0;
                if (p >= 2 && memcmp(o.d+p-2, "or", 2) == 0 &&
                    (p < 3 || !is_id((unsigned char)o.d[p-3])))
                    need_semi = 0;
                if (p >= 3 && memcmp(o.d+p-3, "not", 3) == 0 &&
                    (p < 4 || !is_id((unsigned char)o.d[p-4])))
                    need_semi = 0;
            }
            if (need_semi) buf_putc(&o, ';');
            buf_putc(&o,'('); i++;
            at_line_start = 0; goto next;
        }

        at_line_start = 0;

        /* ---- Binary literal 0b... → decimal ---- */
        if (c == '0' && i+1 < len &&
            (s[i+1] == 'b' || s[i+1] == 'B') &&
            (i == 0 || !is_id(s[i-1]))) {
            size_t j = i + 2;
            int val = 0; int has_bits = 0;
            while (j < len && (s[j]=='0'||s[j]=='1'||s[j]=='_')) {
                if (s[j] != '_') { val = (val<<1)|(s[j]-'0'); has_bits = 1; }
                j++;
            }
            double frac = 0.0; int has_frac = 0;
            if (j < len && s[j] == '.' && j+1 < len && (s[j+1]=='0'||s[j+1]=='1')) {
                j++; int bit = 1;
                while (j < len && (s[j]=='0'||s[j]=='1'||s[j]=='_')) {
                    if (s[j] != '_') { if (s[j]=='1') frac += 1.0/(1<<bit); bit++; has_frac=1; }
                    j++;
                }
            }
            if (has_bits || has_frac) {
                if (has_frac) {
                    char tmp[32]; int n2 = snprintf(tmp, sizeof(tmp), "%.10g", (double)val+frac);
                    buf_puts(&o, tmp, n2);
                } else {
                    buf_int(&o, val);
                }
                i = j; goto next;
            }
        }

        /* ---- \\ → // (integer divide), \\= → //= ---- */
        if (c == '\\') {
            if (i+1 < len && s[i+1] == '=') {
                buf_puts(&o, "//=", 3); i += 2;
            } else {
                buf_puts(&o, "//", 2); i++;
                if (i < len && s[i] == '\\') i++; /* skip doubled \\ */
            }
            goto next;
        }

        /* ---- ^^= kept for compound rewriter ---- */
        /* ^^ as binary XOR is now handled by p8_shrinko (→ bxor() call).
         * Only ^^= compound assign needs to pass through to rewrite step. */
        if (c == '^' && i+1 < len && s[i+1] == '^' && i+2 < len && s[i+2] == '=') {
            buf_puts(&o, "^^=", 3); i += 3;
            goto next;
        }

        /* ---- @/%/$ peek shorthands ---- */
        if ((c == '@' || c == '%' || c == '$') &&
            i+1 < len && (is_id(s[i+1]) || s[i+1] == '(')) {
            /* % and $ after a value are binary ops (modulo), not peek.
             * Check previous output char for value context. */
            if (c != '@' && o.len > 0) {
                unsigned char prev = (unsigned char)o.d[o.len-1];
                if (is_id(prev) || prev == ')' || prev == ']' ||
                    (prev >= '0' && prev <= '9')) {
                    buf_putc(&o, c); i++; goto next; /* binary op */
                }
            }
            const char *fn = (c=='@') ? "peek(" :
                             (c=='%') ? "peek2(" : "peek4(";
            buf_str(&o, fn);
            i++;
            if (s[i] == '(') {
                i++; /* skip ( — our fn( already has it */
            } else {
                size_t j = i;
                while (j < len && (is_id(s[j]) || s[j] == '.')) j++;
                buf_puts(&o, (const char*)s+i, j-i);
                buf_putc(&o, ')');
                i = j;
            }
            goto next;
        }

        /* NOTE: shift/rotate (<<, >>, >>>, <<>, >><) and bitwise ops
         * (&, |, ^^, ~) are now handled by p8_shrinko's streaming parser,
         * which converts them to function calls (shl, shr, lshr, rotl,
         * rotr, band, bor, bxor, bnot) during unminification. */

        /* ---- High bytes in code ---- */
        /* PXA-decompressed source has single-byte P8SCII values (0x80+).
         * PICO-8's Lua allows these as identifier characters, and carts
         * do use them as variable names (e.g. porklike uses 😐/0x8C).
         * We patched Lua 5.2's lctype.c to mark 0x80+ as alpha, so
         * most high bytes pass through unchanged.
         *
         * The 6 button/arrow glyphs are special: when they appear as
         * standalone values (not part of an identifier), they represent
         * button indices 0-5 for btn()/btnp(). We only convert these
         * when they're NOT adjacent to other identifier characters. */
        if (c >= 0x80) {
            /* Try UTF-8 multi-byte glyphs first (rare but possible) */
            int gi = match_glyph(s, len, i);
            if (gi >= 0) {
                if (g_glyphs[gi].val >= 0) buf_int(&o, g_glyphs[gi].val);
                i += g_glyphs[gi].slen; goto next;
            }
            /* Single-byte P8SCII: button/arrow glyphs → button index,
             * but ONLY when used as a standalone value (not part of an
             * identifier). Check surrounding characters. */
            int btn_val = -1;
            switch (c) {
                case 0x8B: btn_val = 0; break; /* ⬅ LEFT */
                case 0x91: btn_val = 1; break; /* ➡ RIGHT */
                case 0x94: btn_val = 2; break; /* ⬆ UP */
                case 0x83: btn_val = 3; break; /* ⬇ DOWN */
                case 0x8E: btn_val = 4; break; /* 🅾 O */
                case 0x97: btn_val = 5; break; /* ❎ X */
            }
            if (btn_val >= 0) {
                /* Check if this glyph is part of an identifier:
                 * preceded or followed by alnum/_ or another high byte */
                bool prev_id = (i > 0 && (isalnum(s[i-1]) || s[i-1] == '_' || s[i-1] >= 0x80));
                bool next_id = (i+1 < len && (isalnum(s[i+1]) || s[i+1] == '_' || s[i+1] >= 0x80));
                if (prev_id || next_id) {
                    /* Part of identifier — keep raw byte */
                    buf_putc(&o, c); i++; goto next;
                }
                /* Standalone → button index */
                buf_int(&o, btn_val);
                i++; goto next;
            }
            /* All other high bytes: pass through as-is (valid ident chars) */
            buf_putc(&o, c); i++;
            goto next;
        }

        buf_putc(&o, c); i++;
next: ;
    }
done:
    return buf_finish(&o, out_len);
}

/* ================================================================== */
/* Phase 1: Tokenizer                                                  */
/*                                                                     */
/* Faithful port of shrinko8's pico_tokenize.py tokenize().            */
/* Properly splits even heavily minified PICO-8 source into tokens.    */
/*                                                                     */
/* Key differences from a naive Lua tokenizer:                         */
/*   - Bytes 0x80+ are valid identifier characters (PICO-8 charset)    */
/*   - Binary numbers 0b with fractional parts (0b1010.1)              */
/*   - // is a line comment (in addition to --)                        */
/*   - Whitespace is DISCARDED, not emitted as tokens                  */
/*   - Newlines tracked via vline counter on each token                */
/*   - String \z escape skips subsequent whitespace                    */
/*   - Punctuation matching follows shrinko8's accept() pattern        */
/* ================================================================== */

/* PICO-8 identifier char: alphanumeric, _, or high byte (0x80+) */
static int p8_is_ident_char(unsigned char c) {
    return c == '_' || isalnum(c) || c >= 0x80;
}

static int scan_long_bracket(const char *s, int n, int i) {
    if (i >= n || s[i] != '[') return -1;
    int j = i + 1, level = 0;
    while (j < n && s[j] == '=') { level++; j++; }
    if (j >= n || s[j] != '[') return -1;
    j++;
    while (j < n) {
        if (s[j] == ']') {
            int k = j+1, cl = 0;
            while (k < n && s[k] == '=') { cl++; k++; }
            if (cl == level && k < n && s[k] == ']')
                return k + 1;
        }
        j++;
    }
    return n;  /* unterminated */
}

/* Each token carries a vline (virtual line number) so the shorthand-if
 * detector can check "same line" semantics. */
static int g_vline;

static void tl_push_v(toklist_t *tl, int kind, const char *text, int len) {
    tl_push(tl, kind, text, len);
    tl->items[tl->count - 1].vline = g_vline;
}

/* Tokenizer for step 3 of the pipeline. Ported from pico8_lua.py's
 * tokenize(), which preserves whitespace as WS tokens (unlike
 * shrinko8's tokenizer which discards them). Whitespace preservation
 * is critical to maintain the spacing that shrinko8's unminifier
 * carefully inserted (e.g. `60 ..` must keep the space). */
static void tokenize(const char *src, int n, toklist_t *tl) {
    int i = 0;
    g_vline = 0;

    while (i < n) {
        unsigned char c = (unsigned char)src[i];

        /* Whitespace — preserve as WS tokens (matching pico8_lua.py) */
        if (c == ' ' || c == '\t') {
            int j = i;
            while (j < n && ((unsigned char)src[j] == ' ' || (unsigned char)src[j] == '\t')) j++;
            tl_push_v(tl, T_WS, src+i, j-i);
            i = j; continue;
        }
        if (c == '\r') {
            i++; continue;  /* skip bare CR */
        }

        /* Newline — emit T_NL (needed by shorthand-if detector) */
        if (c == '\n') {
            tl_push_v(tl, T_NL, "\n", 1);
            g_vline++;
            i++; continue;
        }

        /* Number: digit, or `.` followed by digit */
        if ((c >= '0' && c <= '9') ||
            (c == '.' && i+1 < n && (unsigned char)src[i+1] >= '0' &&
             (unsigned char)src[i+1] <= '9')) {
            int j = i;
            unsigned char ch0 = c;
            if (ch0 == '0' && i+1 < n &&
                ((unsigned char)src[i+1] == 'b' || (unsigned char)src[i+1] == 'B')) {
                /* Binary: 0b digits and . */
                j += 2;
                while (j < n && ((unsigned char)src[j] == '0' ||
                                  (unsigned char)src[j] == '1' ||
                                  (unsigned char)src[j] == '.'))
                    j++;
            } else if (ch0 == '0' && i+1 < n &&
                       ((unsigned char)src[i+1] == 'x' || (unsigned char)src[i+1] == 'X')) {
                /* Hex: 0x hex-digits and . */
                j += 2;
                while (j < n) {
                    unsigned char hc = (unsigned char)src[j];
                    if ((hc >= '0' && hc <= '9') ||
                        (hc >= 'a' && hc <= 'f') ||
                        (hc >= 'A' && hc <= 'F') || hc == '.')
                        j++;
                    else break;
                }
                /* Optional pP exponent */
                if (j < n && ((unsigned char)src[j] == 'p' ||
                              (unsigned char)src[j] == 'P')) {
                    j++;
                    if (j < n && (src[j] == '+' || src[j] == '-')) j++;
                    while (j < n && (unsigned char)src[j] >= '0' &&
                           (unsigned char)src[j] <= '9') j++;
                }
            } else {
                /* Decimal: digits and . */
                while (j < n && ((unsigned char)src[j] >= '0' &&
                                  (unsigned char)src[j] <= '9' ||
                                  (unsigned char)src[j] == '.'))
                    j++;
                /* Optional eE exponent — only if followed by digit */
                if (j < n && ((unsigned char)src[j] == 'e' ||
                              (unsigned char)src[j] == 'E')) {
                    int k = j + 1;
                    if (k < n && (src[k] == '+' || src[k] == '-')) k++;
                    if (k < n && (unsigned char)src[k] >= '0' &&
                        (unsigned char)src[k] <= '9') {
                        j = k;
                        while (j < n && (unsigned char)src[j] >= '0' &&
                               (unsigned char)src[j] <= '9') j++;
                    }
                }
            }
            tl_push_v(tl, T_NUMBER, src+i, j-i);
            i = j; continue;
        }

        /* Identifier: _, alpha, or PICO-8 high byte */
        if (p8_is_ident_char(c) && !(c >= '0' && c <= '9')) {
            int j = i + 1;
            while (j < n && p8_is_ident_char((unsigned char)src[j])) j++;
            tl_push_v(tl, T_IDENT, src+i, j-i);
            i = j; continue;
        }

        /* String: "..." or '...' */
        if (c == '"' || c == '\'') {
            int j = i + 1;
            while (j < n) {
                unsigned char sc = (unsigned char)src[j];
                if (sc == '\n' || sc == '\0') break;  /* unterminated */
                if (sc == '\\') {
                    j++;
                    if (j < n && src[j] == 'z') {
                        /* \z — skip subsequent whitespace */
                        j++;
                        while (j < n && (src[j]==' '||src[j]=='\t'||
                                          src[j]=='\n'||src[j]=='\r'))
                            j++;
                    } else if (j < n) {
                        j++;  /* skip escaped char */
                    }
                    continue;
                }
                if (sc == c) { j++; break; }
                j++;
            }
            tl_push_v(tl, T_STRING, src+i, j-i);
            i = j; continue;
        }

        /* Long bracket string: [[ or [=[ */
        if (c == '[') {
            int end = scan_long_bracket(src, n, i);
            if (end >= 0) {
                tl_push_v(tl, T_STRING, src+i, end-i);
                i = end; continue;
            }
        }

        /* Comment: -- (line or block) */
        if (c == '-' && i+1 < n && src[i+1] == '-') {
            /* Try block comment --[[ */
            int end = scan_long_bracket(src, n, i+2);
            if (end >= 0) {
                tl_push_v(tl, T_COMMENT, src+i, end-i);
                i = end; continue;
            }
            /* Line comment — to end of line */
            int j = i;
            while (j < n && src[j] != '\n') j++;
            tl_push_v(tl, T_COMMENT, src+i, j-i);
            i = j; continue;
        }

        /* C-style comment: // (PICO-8 specific) */
        if (c == '/' && i+1 < n && src[i+1] == '/') {
            /* But NOT if it's //= (compound int-divide assign) or
             * part of a triple like ///. Check: is next char '='? */
            /* Actually shrinko8 only treats // as comment at line start
             * or when NOT preceded by an operator context. But the
             * simplest match: shrinko8 tokenizes // as comment ONLY
             * when the two // are consumed. Let me check the original...
             *
             * shrinko8 line 589: elif ch == '/' and is_pico8 and accept('/'):
             *   tokenize_line_comment()
             *
             * This means ANY // in code becomes a comment! That's how
             * PICO-8 works — // is always a comment, never int-divide.
             * PICO-8 uses \ for int-divide. Lua's // doesn't exist in P8.
             *
             * Our pre_tokenize already converted // comments → -- comments
             * and \ → //. So by the time we tokenize, // is Lua's int-divide
             * (from \ conversion) and should NOT be treated as comment.
             * Skip this rule since pre_tokenize already handled it. */
            /* Fall through to punctuation */
        }

        /* Punctuation — port of shrinko8 lines 592-606 */
        if (c && (c == '+' || c == '-' || c == '*' || c == '/' ||
                  c == '\\' || c == '%' || c == '&' || c == '|' ||
                  c == '^' || c == '<' || c == '>' || c == '=' ||
                  c == '~' || c == '#' || c == '(' || c == ')' ||
                  c == '[' || c == ']' || c == '{' || c == '}' ||
                  c == ';' || c == ',' || c == '?' || c == '@' ||
                  c == '$' || c == '.' || c == ':')) {
            int orig = i;
            i++;  /* consume first char */

            /* shrinko8 pattern: some chars can double then optionally
             * take '='. Others just take '='. */
            if ((c == '.' || c == ':' || c == '/' || c == '^' ||
                 c == '<' || c == '>') &&
                i < n && (unsigned char)src[i] == c) {
                i++;  /* doubled: .., ::, //, ^^, <<, >> */
                if ((c == '.' || c == '>') && i < n && (unsigned char)src[i] == c) {
                    i++;  /* tripled: ..., >>> */
                    if (c == '>') {
                        /* >>>= */
                        if (i < n && src[i] == '=') i++;
                    }
                } else if ((c == '<' || c == '>') &&
                           i < n && ((unsigned char)src[i] == (c == '<' ? '>' : '<'))) {
                    i++;  /* <<> or >>< */
                    if (i < n && src[i] == '=') i++;
                } else if (c == '.' || c == '/' || c == '^' || c == '<' || c == '>') {
                    if (i < n && src[i] == '=') i++;  /* ..=, //=, ^^=, <<=, >>= */
                }
            } else if (c == '+' || c == '-' || c == '*' || c == '/' ||
                       c == '\\' || c == '%' || c == '&' || c == '|' ||
                       c == '^' || c == '<' || c == '>' || c == '=' ||
                       c == '~') {
                if (i < n && src[i] == '=') i++;  /* +=, -=, etc */
            }

            tl_push_v(tl, T_OP, src+orig, i-orig);
            continue;
        }

        /* != alt punctuation */
        if (c == '!' && i+1 < n && src[i+1] == '=') {
            tl_push_v(tl, T_OP, src+i, 2);
            i += 2; continue;
        }

        /* Unknown char — skip */
        i++;
    }
}

/* ================================================================== */
/* Phase 2: Token-level rewrites                                       */
/* ================================================================== */

/* --- 2a: normalise (!=→~=, 0b→decimal, \\→//, ^^→~, @/%/$→peek) --- */
static void normalise_tokens(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        /* != → ~= */
        if (t->kind == T_OP && t->len == 2 && t->text[0] == '!' && t->text[1] == '=') {
            tok_set(t, T_OP, "~=", 2);
            continue;
        }
        /* 0b binary → decimal */
        if (t->kind == T_NUMBER && t->len >= 3 &&
            t->text[0] == '0' && (t->text[1] == 'b' || t->text[1] == 'B')) {
            int val = 0;
            for (int k = 2; k < t->len; k++) {
                if (t->text[k] == '0' || t->text[k] == '1')
                    val = (val << 1) | (t->text[k] - '0');
            }
            char tmp[16]; int nl = snprintf(tmp, 16, "%d", val);
            tok_set(t, T_NUMBER, tmp, nl);
            continue;
        }
        /* \ → //, \= → //= (integer divide / compound assign) */
        if (t->kind == T_OP && t->text[0] == '\\') {
            if (t->len == 2 && t->text[1] == '=')
                tok_set(t, T_OP, "//=", 3);
            else
                tok_set(t, T_OP, "//", 2);
            continue;
        }
        /* ^^ → ~ (XOR), but NOT ^^= */
        if (t->kind == T_OP && t->len == 2 &&
            t->text[0] == '^' && t->text[1] == '^') {
            tok_set(t, T_OP, "~", 1);
            continue;
        }
        /* ^^= → compound XOR assign — keep, rewrite op in compound pass */
    }
}

/* --- helper: is token text a keyword? --- */
static int is_keyword(const char *s, int len) {
    static const char *kws[] = {
        "and","break","do","else","elseif","end","false","for",
        "function","goto","if","in","local","nil","not","or",
        "repeat","return","then","true","until","while",NULL
    };
    for (const char **k = kws; *k; k++) {
        int kl = (int)strlen(*k);
        if (kl == len && memcmp(s, *k, kl) == 0) return 1;
    }
    return 0;
}

static int is_stmt_kw(const char *s, int len) {
    static const char *kws[] = {
        "return","break","end","else","elseif","then","do",
        "while","if","for","local","function","repeat","until","goto","in",NULL
    };
    for (const char **k = kws; *k; k++) {
        int kl = (int)strlen(*k);
        if (kl == len && memcmp(s, *k, kl) == 0) return 1;
    }
    return 0;
}

/* Skip non-code tokens (whitespace, newlines, comments) forward */
static int skip_ws(toklist_t *tl, int i) {
    while (i < tl->count && (tl->items[i].kind==T_WS||tl->items[i].kind==T_WS||tl->items[i].kind==T_NL||tl->items[i].kind==T_COMMENT))
        i++;
    return i;
}
/* Skip non-code tokens forward but stop at newlines (same-line only) */
static int skip_ws_sameline(toklist_t *tl, int i) {
    while (i < tl->count && tl->items[i].kind==T_COMMENT)
        i++;
    return i;
}

/* --- 2b: @/%/$ peek shorthands --- */
/* Must run AFTER normalise so \\ is already //. Scans for @/%/$ OP tokens
 * in unary position and rewrites them to peek/peek2/peek4 function calls. */
static void rewrite_peek_shorthands(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind != T_OP || t->len != 1) continue;
        char c = t->text[0];
        if (c != '@' && c != '%' && c != '$') continue;

        /* % and $ are only peek in unary position.
         * After a value (IDENT, NUMBER, ), ]) they're binary ops. */
        if (c != '@') {
            int p = i - 1;
            while (p >= 0 && (tl->items[p].kind==T_WS||tl->items[p].kind==T_NL||tl->items[p].kind==T_COMMENT)) p--;
            if (p >= 0) {
                tok_t *prev = &tl->items[p];
                if (prev->kind==T_IDENT || prev->kind==T_NUMBER ||
                    prev->kind==T_STRING ||
                    (prev->kind==T_OP && (prev->text[0]==')'||prev->text[0]==']')))
                    continue;  /* binary position */
            }
        }

        /* Next token must be IDENT, NUMBER, or ( */
        int nx = skip_ws(tl, i + 1);
        if (nx >= tl->count) continue;
        tok_t *nt = &tl->items[nx];
        if (nt->kind != T_IDENT && nt->kind != T_NUMBER &&
            !(nt->kind == T_OP && nt->text[0] == '('))
            continue;

        const char *fn = (c=='@') ? "peek" : (c=='%') ? "peek2" : "peek4";

        if (nt->kind == T_OP && nt->text[0] == '(') {
            /* @(expr) → peek(expr) — replace @ with `peek`, keep ( */
            tok_set(t, T_IDENT, fn, (int)strlen(fn));
        } else {
            /* @addr → peek(addr) — collect ident/number/dot chain */
            int end = nx;
            while (end < tl->count &&
                   (tl->items[end].kind==T_IDENT||tl->items[end].kind==T_NUMBER||
                    (tl->items[end].kind==T_OP && tl->items[end].text[0]=='.')))
                end++;
            /* Build replacement text */
            buf_t rb = {0};
            buf_str(&rb, fn); buf_putc(&rb, '(');
            for (int k = nx; k < end; k++)
                buf_puts(&rb, tl->items[k].text, tl->items[k].len);
            buf_putc(&rb, ')');
            tok_set(t, T_RAW, rb.d, (int)rb.len);
            free(rb.d);
            /* Remove consumed tokens */
            for (int k = nx; k < end; k++)
                free(tl->items[k].text);
            int rem = end - nx;
            memmove(&tl->items[nx], &tl->items[end],
                    (tl->count - end) * sizeof(tok_t));
            tl->count -= rem;
        }
    }
}

/* --- 2c: if (cond) do → if (cond) then --- */
static void rewrite_if_do(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind != T_IDENT ||
            (strcmp(t->text, "if") != 0 && strcmp(t->text, "elseif") != 0))
            continue;
        /* Scan forward for `then` or `do` at depth 0 */
        int depth = 0, j = i + 1;
        while (j < tl->count) {
            tok_t *tj = &tl->items[j];
            if (tj->kind == T_OP) {
                if (tj->text[0]=='('||tj->text[0]=='['||tj->text[0]=='{') depth++;
                else if (tj->text[0]==')'||tj->text[0]==']'||tj->text[0]=='}') {
                    if (depth > 0) depth--;
                }
            }
            if (tj->kind == T_IDENT && depth == 0) {
                if (strcmp(tj->text,"then")==0) break;
                if (strcmp(tj->text,"do")==0) {
                    tok_set(tj, T_IDENT, "then", 4);
                    break;
                }
                if (is_stmt_kw(tj->text,tj->len) && strcmp(tj->text,"and")!=0 &&
                    strcmp(tj->text,"or")!=0 && strcmp(tj->text,"not")!=0)
                    break;
            }
            if (tj->kind == T_NL && depth == 0) break;
            j++;
        }
    }
}

/* --- 2d: compound assigns --- */

/* Join tokens [start..end) into a string */
static char *join_range(toklist_t *tl, int start, int end, int *out_len) {
    buf_t b = {0};
    int last_word = 0;
    for (int i = start; i < end; i++) {
        tok_t *t = &tl->items[i];
        int cur_word = (t->kind==T_IDENT||t->kind==T_NUMBER||t->kind==T_RAW);
        if (last_word && cur_word) buf_putc(&b, ' ');
        buf_puts(&b, t->text, t->len);
        last_word = (t->kind!=T_WS && t->kind!=T_NL && t->kind!=T_COMMENT) ? cur_word : 0;
    }
    buf_finish(&b, NULL);
    if (out_len) *out_len = (int)b.len;
    return b.d;
}

static const char *COMPOUND_OPS[] = {
    "+=","-=","*=","/=","%=","^=","..=","//=",
    "|=","&=","<<=",">>=","^^=",NULL
};

static int is_compound_op(const char *s, int len) {
    for (const char **p = COMPOUND_OPS; *p; p++) {
        int pl = (int)strlen(*p);
        if (pl == len && memcmp(s, *p, pl) == 0) return 1;
    }
    return 0;
}

/* Find end of expression for RHS of compound assign */
static int find_expr_end(toklist_t *tl, int start) {
    int depth = 0, state = 0; /* 0=init, 1=value */
    for (int i = start; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind == T_NL && depth == 0) return i;
        /* Comments end the expression — otherwise `x += 1 -- comment`
         * becomes `x = x + (1 -- comment)` which eats the closing ). */
        if (t->kind == T_COMMENT && depth == 0) return i;
        if (t->kind == T_OP) {
            if (t->text[0]=='('||t->text[0]=='['||t->text[0]=='{') { depth++; state=0; continue; }
            if (t->text[0]==')'||t->text[0]==']'||t->text[0]=='}') {
                if (depth==0) return i;
                depth--; state=1; continue;
            }
            if (depth==0 && t->text[0]==';') return i;
            if (depth==0 && is_compound_op(t->text,t->len)) return i;
            if (depth==0 && t->len==1 && t->text[0]=='=') return i;
            state = 0; continue;
        }
        if (t->kind == T_IDENT) {
            if (depth==0 && is_stmt_kw(t->text,t->len) &&
                strcmp(t->text,"and")!=0 && strcmp(t->text,"or")!=0 &&
                strcmp(t->text,"not")!=0)
                return i;
            if (strcmp(t->text,"and")==0||strcmp(t->text,"or")==0||
                strcmp(t->text,"not")==0) { state=0; continue; }
            if (depth==0 && state==1) return i;
            state = 1; continue;
        }
        if (t->kind==T_NUMBER||t->kind==T_STRING||t->kind==T_RAW) {
            if (depth==0 && state==1) return i;
            state = 1; continue;
        }
        continue;
    }
    return tl->count;
}

/* Walk back from compound op to find LHS start */
static int find_lhs_start(toklist_t *tl, int op_idx) {
    int i = op_idx - 1;
    while (i >= 0 && (tl->items[i].kind==T_WS||tl->items[i].kind==T_NL||tl->items[i].kind==T_COMMENT)) i--;
    if (i < 0) return -1;
    while (i >= 0) {
        tok_t *t = &tl->items[i];
        if (t->kind == T_OP && t->text[0] == ']') {
            int depth = 1; i--;
            while (i >= 0 && depth > 0) {
                if (tl->items[i].kind==T_OP && tl->items[i].text[0]==']') depth++;
                if (tl->items[i].kind==T_OP && tl->items[i].text[0]=='[') depth--;
                if (depth > 0) i--;
            }
            if (i < 0) return -1;
            i--;
            while (i>=0 && (tl->items[i].kind==T_WS||tl->items[i].kind==T_NL||tl->items[i].kind==T_COMMENT)) i--;
            continue;
        }
        if (t->kind == T_IDENT && !is_keyword(t->text,t->len)) {
            int ii = i;
            int p = i - 1;
            while (p>=0 && (tl->items[p].kind==T_WS||tl->items[p].kind==T_NL||tl->items[p].kind==T_COMMENT)) p--;
            if (p>=0 && tl->items[p].kind==T_OP && tl->items[p].text[0]=='.') {
                i = p - 1;
                while (i>=0 && (tl->items[i].kind==T_WS||tl->items[i].kind==T_NL||tl->items[i].kind==T_COMMENT)) i--;
                continue;
            }
            return ii;
        }
        return -1;
    }
    return -1;
}

/* Matching Python: collect ALL edits, then apply in reverse order
 * so earlier token indices remain valid during splicing. */
typedef struct { int start, end; char *text; int len; } ca_edit_t;

static void rewrite_compound_assigns(toklist_t *tl) {
    /* Phase 1: collect edits */
    ca_edit_t edits[512];
    int n_edits = 0;

    for (int i = 0; i < tl->count && n_edits < 512; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind != T_OP || !is_compound_op(t->text, t->len)) continue;

        int lhs_start = find_lhs_start(tl, i);
        if (lhs_start < 0) continue;

        char op_text[4] = {0};
        int op_text_len = t->len - 1;
        memcpy(op_text, t->text, op_text_len);
        if (strcmp(op_text, "^^") == 0) { strcpy(op_text, "~"); op_text_len = 1; }

        int rhs_start = i + 1;
        int rhs_end = find_expr_end(tl, rhs_start);

        int lhs_len, rhs_len;
        char *lhs_text = join_range(tl, lhs_start, i, &lhs_len);
        char *rhs_raw = join_range(tl, rhs_start, rhs_end, &rhs_len);

        /* Trim without modifying the pointer */
        int rhs_off = 0;
        while (lhs_len > 0 && (lhs_text[lhs_len-1]==' '||lhs_text[lhs_len-1]=='\t')) lhs_len--;
        while (rhs_off < rhs_len && (rhs_raw[rhs_off]==' '||rhs_raw[rhs_off]=='\t')) rhs_off++;
        while (rhs_len > rhs_off && (rhs_raw[rhs_len-1]==' '||rhs_raw[rhs_len-1]=='\t')) rhs_len--;

        if (lhs_len == 0 || rhs_len <= rhs_off) {
            free(lhs_text); free(rhs_raw);
            continue;
        }

        buf_t nb = {0};
        buf_puts(&nb, lhs_text, lhs_len);
        buf_str(&nb, " = ");
        buf_puts(&nb, lhs_text, lhs_len);
        buf_putc(&nb, ' ');
        buf_puts(&nb, op_text, op_text_len);
        buf_str(&nb, " (");
        buf_puts(&nb, rhs_raw + rhs_off, rhs_len - rhs_off);
        buf_putc(&nb, ')');
        buf_finish(&nb, NULL);

        edits[n_edits].start = lhs_start;
        edits[n_edits].end = rhs_end;
        edits[n_edits].text = nb.d;
        edits[n_edits].len = (int)nb.len;
        n_edits++;

        free(lhs_text);
        free(rhs_raw);
    }

    if (n_edits == 0) return;

    /* Phase 2: apply in REVERSE order (matching Python line 528) */
    for (int e = n_edits - 1; e >= 0; e--) {
        int start = edits[e].start;
        int end = edits[e].end;
        for (int k = start; k < end; k++) free(tl->items[k].text);
        tok_t raw;
        raw.kind = T_RAW;
        raw.text = edits[e].text;
        raw.len = edits[e].len;
        raw.vline = 0;
        tl->items[start] = raw;
        int rem = end - start - 1;
        if (rem > 0) {
            memmove(&tl->items[start+1], &tl->items[end],
                    (tl->count - end) * sizeof(tok_t));
            tl->count -= rem;
        }
    }
}

/* --- 2e: shorthand if/while: if (cond) stmt → if (cond) then stmt end --- */
static void rewrite_shorthand_if(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind != T_IDENT) continue;
        int is_if = (strcmp(t->text,"if")==0);
        int is_while = (strcmp(t->text,"while")==0);
        if (!is_if && !is_while) continue;

        int j = skip_ws(tl, i + 1);
        if (j >= tl->count) continue;
        if (!(tl->items[j].kind==T_OP && tl->items[j].text[0]=='(')) continue;

        /* Find matching ) */
        int depth = 1, k = j + 1;
        while (k < tl->count && depth > 0) {
            if (tl->items[k].kind == T_OP) {
                if (tl->items[k].text[0]=='(') depth++;
                else if (tl->items[k].text[0]==')') { depth--; if (depth==0) break; }
            }
            k++;
        }
        if (k >= tl->count) continue;
        int close = k;

        /* What's after )? */
        int after = skip_ws(tl, close + 1);
        if (after >= tl->count) continue;
        tok_t *ta = &tl->items[after];

        /* `then` or `do` already present → standard form */
        if (ta->kind == T_IDENT &&
            (strcmp(ta->text,"then")==0 || strcmp(ta->text,"do")==0)) {
            /* Rewrite `do` to `then` for if */
            if (is_if && strcmp(ta->text,"do")==0)
                tok_set(ta, T_IDENT, "then", 4);
            continue;
        }

        /* `and`/`or` means condition continues — not shorthand */
        if (ta->kind == T_IDENT &&
            (strcmp(ta->text,"and")==0 || strcmp(ta->text,"or")==0 ||
             strcmp(ta->text,"not")==0))
            continue;

        /* Binary operator after ) means expression continues —
         * e.g. `if (px/8)/16>6 then` is NOT shorthand. */
        if (ta->kind == T_OP) {
            char fc = ta->text[0];
            if (fc=='/' || fc=='*' || fc=='+' || fc=='-' || fc=='%' ||
                fc=='^' || fc=='.' || fc=='<' || fc=='>' || fc=='=' ||
                fc=='~' || fc=='[' || fc=='&' || fc=='|' || fc==':')
                continue;
        }

        /* NL means empty body — skip */
        if (ta->kind == T_NL) continue;

        /* Shorthand: find end of statement body (to NL at depth 0) */
        int body_end = after;
        int bd = 0;
        while (body_end < tl->count) {
            tok_t *tb = &tl->items[body_end];
            if (tb->kind == T_NL && bd == 0) break;
            if (tb->kind == T_OP) {
                if (tb->text[0]=='('||tb->text[0]=='['||tb->text[0]=='{') bd++;
                else if (tb->text[0]==')'||tb->text[0]==']'||tb->text[0]=='}') {
                    if (bd == 0) break;
                    bd--;
                }
                if (bd == 0 && tb->text[0] == ';') break;
            }
            body_end++;
        }
        if (body_end <= after) continue;

        /* Build: if (cond) then body end  OR  while (cond) do body end */
        const char *block_kw = is_if ? " then " : " do ";
        int cond_len, body_len;
        char *cond_text = join_range(tl, i, close+1, &cond_len);
        char *body_text = join_range(tl, after, body_end, &body_len);

        buf_t nb = {0};
        buf_puts(&nb, cond_text, cond_len);
        buf_str(&nb, block_kw);
        buf_puts(&nb, body_text, body_len);
        buf_str(&nb, " end");

        free(cond_text); free(body_text);

        /* Replace tokens [i..body_end) */
        for (int r = i; r < body_end; r++) free(tl->items[r].text);
        tok_t raw;
        raw.kind = T_RAW;
        raw.text = nb.d;
        raw.len = (int)nb.len;
        tl->items[i] = raw;
        int rem = body_end - i - 1;
        memmove(&tl->items[i+1], &tl->items[body_end],
                (tl->count - body_end) * sizeof(tok_t));
        tl->count -= rem;
    }
}

/* --- 2f: shift/rotate ops: >>> → lshr, <<> → rotl, >>< → rotr --- */
static void rewrite_shift_rotate(toklist_t *tl) {
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        if (t->kind != T_OP) continue;
        const char *fn = NULL;
        if (strcmp(t->text,">>>")==0) fn = "lshr";
        else if (strcmp(t->text,"<<>")==0) fn = "rotl";
        else if (strcmp(t->text,">><")==0) fn = "rotr";
        if (!fn) continue;

        /* Find LHS start (walk back) and RHS end (walk forward) */
        /* Simple: walk back to nearest separator at depth 0 */
        int lhs_start = i;
        {
            int p = i - 1, depth = 0;
            while (p >= 0) {
                tok_t *tp = &tl->items[p];
                if (tp->kind==T_WS||tp->kind==T_NL||tp->kind==T_COMMENT) { p--; continue; }
                if (tp->kind==T_NL && depth==0) break;
                if (tp->kind==T_OP) {
                    if (tp->text[0]==')'||tp->text[0]==']'||tp->text[0]=='}') depth++;
                    else if (tp->text[0]=='('||tp->text[0]=='['||tp->text[0]=='{') {
                        if (depth==0) break;
                        depth--;
                    }
                    else if (depth==0 && (tp->text[0]==','||tp->text[0]=='='||tp->text[0]==';'))
                        break;
                }
                if (tp->kind==T_IDENT && depth==0 &&
                    is_stmt_kw(tp->text,tp->len) &&
                    strcmp(tp->text,"and")!=0 && strcmp(tp->text,"or")!=0)
                    break;
                lhs_start = p;
                p--;
            }
        }

        int rhs_end = i + 1;
        {
            int depth = 0;
            while (rhs_end < tl->count) {
                tok_t *tr = &tl->items[rhs_end];
                if (tr->kind==T_WS||tr->kind==T_NL||tr->kind==T_COMMENT) { rhs_end++; continue; }
                if (tr->kind==T_NL && depth==0) break;
                if (tr->kind==T_OP) {
                    if (tr->text[0]=='('||tr->text[0]=='['||tr->text[0]=='{') depth++;
                    else if (tr->text[0]==')'||tr->text[0]==']'||tr->text[0]=='}') {
                        if (depth==0) break;
                        depth--;
                    }
                    else if (depth==0 && (tr->text[0]==','||tr->text[0]==';'))
                        break;
                }
                if (tr->kind==T_IDENT && depth==0 &&
                    is_stmt_kw(tr->text,tr->len) &&
                    strcmp(tr->text,"and")!=0 && strcmp(tr->text,"or")!=0)
                    break;
                rhs_end++;
            }
        }

        int lhs_len, rhs_len;
        char *lhs_text = join_range(tl, lhs_start, i, &lhs_len);
        char *rhs_text = join_range(tl, i+1, rhs_end, &rhs_len);

        buf_t nb = {0};
        buf_str(&nb, fn); buf_putc(&nb, '(');
        buf_puts(&nb, lhs_text, lhs_len);
        buf_str(&nb, ", ");
        buf_puts(&nb, rhs_text, rhs_len);
        buf_putc(&nb, ')');
        free(lhs_text); free(rhs_text);

        for (int r = lhs_start; r < rhs_end; r++) free(tl->items[r].text);
        tok_t raw; raw.kind = T_RAW; raw.text = nb.d; raw.len = (int)nb.len;
        tl->items[lhs_start] = raw;
        int rem = rhs_end - lhs_start - 1;
        memmove(&tl->items[lhs_start+1], &tl->items[rhs_end],
                (tl->count - rhs_end) * sizeof(tok_t));
        tl->count -= rem;
        i = lhs_start;  /* rescan */
    }
}

/* ================================================================== */
/* Phase 3: Emit with spacing                                          */
/* ================================================================== */
static char *emit_tokens(toklist_t *tl, size_t *out_len) {
    buf_t o = {0};
    int last_word = 0;
    for (int i = 0; i < tl->count; i++) {
        tok_t *t = &tl->items[i];
        int cur_word = (t->kind==T_IDENT||t->kind==T_NUMBER);
        /* Insert space between adjacent IDENT/NUMBER tokens that
         * have no WS between them (matching pico8_lua.py's
         * _join_tokens_spaced, lines 698-719) */
        if (last_word && cur_word) buf_putc(&o, ' ');
        buf_puts(&o, t->text, t->len);
        if (t->kind==T_WS||t->kind==T_NL||t->kind==T_COMMENT)
            last_word = 0;
        else
            last_word = cur_word;
    }
    return buf_finish(&o, out_len);
}

/* ================================================================== */
/* Step 3: Compound assign expansion + != → ~=                         */
/*                                                                     */
/* Operates line-by-line on well-formatted shrinko8 output.            */
/* Single growable buffer, no token array, no per-token malloc.        */
/* ================================================================== */

/* Compound ops we recognise (sorted longest first) */
static const char *k_compound_ops[] = {
    "//=", "<<=", ">>=", "^^=", "..=",
    "+=", "-=", "*=", "/=", "%=", "^=", "|=", "&=",
    NULL
};

/* Match a compound op at position p in line of length n.
 * Returns the op length (2 or 3) or 0 if no match. */
static int match_compound(const char *line, size_t p, size_t n) {
    for (const char **op = k_compound_ops; *op; op++) {
        int ol = (int)strlen(*op);
        if (p + (size_t)ol <= n && memcmp(line + p, *op, ol) == 0)
            return ol;
    }
    return 0;
}

static char *rewrite_compounds(const char *src, size_t len, size_t *out_len) {
    buf_t o = {0};
    buf_grow(&o, len + len / 4);

    size_t i = 0;
    while (i < len) {
        /* Find end of line */
        size_t j = i;
        while (j < len && src[j] != '\n') j++;
        const char *line = src + i;
        size_t ll = j - i;

        /* Scan this line for != and compound assigns in code state.
         * String/comment aware. */
        int state = 0; /* 0=code, 1=sq, 2=dq, 3=comment */
        size_t compound_pos = 0;
        int compound_len = 0;
        int ne_found = 0;
        size_t ne_pos = 0;

        for (size_t k = 0; k < ll; k++) {
            char c = line[k];
            if (state == 0) {
                if (c == '\'') state = 1;
                else if (c == '"') state = 2;
                else if (c == '-' && k+1 < ll && line[k+1] == '-') { state = 3; break; }
                else if (c == '!' && k+1 < ll && line[k+1] == '=') {
                    ne_found = 1; ne_pos = k;
                } else if (!compound_len) {
                    int cl = match_compound(line, k, ll);
                    if (cl > 0) {
                        compound_pos = k;
                        compound_len = cl;
                    }
                }
            } else if (state == 1) {
                if (c == '\\' && k+1 < ll) k++;
                else if (c == '\'') state = 0;
            } else if (state == 2) {
                if (c == '\\' && k+1 < ll) k++;
                else if (c == '"') state = 0;
            }
        }

        if (!compound_len && !ne_found) {
            /* No transforms needed — emit line as-is */
            buf_puts(&o, line, ll);
        } else {
            /* First apply != → ~= */
            char *work = (char *)malloc(ll + 1);
            if (work) {
                memcpy(work, line, ll);
                work[ll] = 0;
                /* Replace ALL != → ~= in code state */
                {
                    int ws = 0;
                    for (size_t k = 0; k < ll; k++) {
                        if (ws == 0) {
                            if (work[k] == '\'') ws = 1;
                            else if (work[k] == '"') ws = 2;
                            else if (work[k] == '-' && k+1<ll && work[k+1]=='-') break;
                            else if (work[k] == '!' && k+1<ll && work[k+1]=='=')
                                work[k] = '~';
                        } else if (ws == 1) {
                            if (work[k] == '\\' && k+1<ll) k++;
                            else if (work[k] == '\'') ws = 0;
                        } else if (ws == 2) {
                            if (work[k] == '\\' && k+1<ll) k++;
                            else if (work[k] == '"') ws = 0;
                        }
                    }
                }

                if (compound_len) {
                    /* Expand compound assign.
                     * Find LHS: walk back from compound_pos.
                     * On clean shrinko8 output, the LHS is everything
                     * from the last statement boundary to the op. */
                    size_t lhs_end = compound_pos;
                    while (lhs_end > 0 && (work[lhs_end-1]==' '||work[lhs_end-1]=='\t'))
                        lhs_end--;
                    size_t lhs_start = lhs_end;
                    /* Walk back through identifier/index chain */
                    while (lhs_start > 0) {
                        char pc = work[lhs_start - 1];
                        if (is_id((unsigned char)pc) || pc == '.' || pc == ':') {
                            lhs_start--;
                        } else if (pc == ']') {
                            int d = 1; lhs_start--;
                            while (lhs_start > 0 && d > 0) {
                                if (work[lhs_start-1] == ']') d++;
                                if (work[lhs_start-1] == '[') d--;
                                lhs_start--;
                            }
                        } else if (pc == ' ' || pc == '\t') {
                            lhs_start--;
                        } else {
                            break;
                        }
                    }
                    /* Skip leading whitespace in LHS */
                    while (lhs_start < lhs_end &&
                           (work[lhs_start]==' '||work[lhs_start]=='\t'))
                        lhs_start++;

                    /* Get the Lua op (strip trailing =) and map PICO-8
                     * operators to function calls for Lua 5.2 compat.
                     * Lua 5.2 has NO bitwise operators (|, &, ~, <<, >>)
                     * and NO // floor division. */
                    char op_text[8] = {0};
                    int op_text_len = compound_len - 1;
                    memcpy(op_text, work + compound_pos, op_text_len);
                    const char *op_func = NULL;  /* non-NULL → emit as func call */
                    if (strcmp(op_text, "^^") == 0)  op_func = "bxor";
                    else if (strcmp(op_text, "//") == 0) op_func = "p8idiv";
                    else if (strcmp(op_text, "|") == 0)  op_func = "bor";
                    else if (strcmp(op_text, "&") == 0)  op_func = "band";
                    else if (strcmp(op_text, "<<") == 0) op_func = "shl";
                    else if (strcmp(op_text, ">>") == 0) op_func = "shr";

                    /* RHS: after the op= to end of line (or comment) */
                    size_t rhs_start = compound_pos + compound_len;
                    while (rhs_start < ll && (work[rhs_start]==' '||work[rhs_start]=='\t'))
                        rhs_start++;
                    size_t rhs_end = ll;
                    /* Trim trailing comment */
                    {
                        int rs = 0;
                        for (size_t k = rhs_start; k < rhs_end; k++) {
                            if (rs == 0) {
                                if (work[k]=='\'' ) rs = 1;
                                else if (work[k]=='"') rs = 2;
                                else if (work[k]=='-' && k+1<rhs_end && work[k+1]=='-') {
                                    rhs_end = k; break;
                                }
                            } else if (rs == 1) {
                                if (work[k]=='\\' && k+1<rhs_end) k++;
                                else if (work[k]=='\'') rs = 0;
                            } else if (rs == 2) {
                                if (work[k]=='\\' && k+1<rhs_end) k++;
                                else if (work[k]=='"') rs = 0;
                            }
                        }
                    }
                    while (rhs_end > rhs_start &&
                           (work[rhs_end-1]==' '||work[rhs_end-1]=='\t'))
                        rhs_end--;

                    /* Emit: prefix + lhs = func(lhs, rhs) or lhs op (rhs)
                     * Lua 5.2 has no bitwise ops or //, so PICO-8 operators
                     * that map to missing Lua operators use function calls. */
                    buf_puts(&o, work, lhs_start);  /* prefix (indentation) */
                    buf_puts(&o, work + lhs_start, lhs_end - lhs_start); /* lhs */
                    buf_str(&o, " = ");
                    if (op_func) {
                        buf_str(&o, op_func);
                        buf_putc(&o, '(');
                        buf_puts(&o, work + lhs_start, lhs_end - lhs_start);
                        buf_str(&o, ", ");
                        buf_puts(&o, work + rhs_start, rhs_end - rhs_start);
                        buf_putc(&o, ')');
                    } else {
                        buf_puts(&o, work + lhs_start, lhs_end - lhs_start); /* lhs again */
                        buf_putc(&o, ' ');
                        buf_puts(&o, op_text, op_text_len);
                        buf_str(&o, " (");
                        buf_puts(&o, work + rhs_start, rhs_end - rhs_start);
                        buf_putc(&o, ')');
                    }
                    /* Tail: comment etc */
                    if (rhs_end < ll) buf_puts(&o, work + rhs_end, ll - rhs_end);
                } else {
                    /* Just != → ~= applied */
                    buf_puts(&o, work, ll);
                }
                free(work);
            } else {
                buf_puts(&o, line, ll);
            }
        }

        if (j < len) buf_putc(&o, '\n');
        i = j + (j < len ? 1 : 0);
    }

    return buf_finish(&o, out_len);
}

/* ================================================================== */
/* Phase 4: _ENV compatibility                                         */
/*                                                                     */
/* PICO-8 carts often write `local _ENV = t` (or compound forms like
 * `local g, _ENV = _ENV, en`) to redirect bare identifier access to
 * t's fields (Lua 5.2 _ENV semantics), while still expecting global
 * functions like pal/spr/btn to be reachable. Real PICO-8 does this
 * implicitly. Our Lua 5.2 does not.
 *
 * Rewrite: in any `local LHS = RHS` where LHS contains `_ENV`, wrap
 * the corresponding RHS expression with __p8_env(…).
 *
 * Examples:
 *   local _ENV = X              →  local _ENV = __p8_env(X)
 *   local g, _ENV = _ENV, en    →  local g, _ENV = _ENV, __p8_env(en)
 *
 * The __p8_env helper (registered in p8.c) ensures the target has a
 * metatable with __index = _G so global lookups still work.
 * ================================================================== */

/* Find the end of an expression starting at p, respecting nesting of
 * parens/brackets/braces and string literals. Stops at top-level ',',
 * ';', '\n', or end-of-line-comment. Returns end offset (exclusive). */
static size_t scan_expr_end(const char *src, size_t len, size_t p) {
    int paren = 0, brack = 0, brace = 0;
    int rstate = 0;
    while (p < len) {
        char c = src[p];
        if (rstate == 0) {
            if (c == '\'') rstate = 1;
            else if (c == '"') rstate = 2;
            else if (c == '(') paren++;
            else if (c == ')') { if (paren > 0) paren--; else break; }
            else if (c == '[') brack++;
            else if (c == ']') { if (brack > 0) brack--; else break; }
            else if (c == '{') brace++;
            else if (c == '}') { if (brace > 0) brace--; else break; }
            else if (paren == 0 && brack == 0 && brace == 0 &&
                     (c == '\n' || c == ';' ||
                      (c == ',' && paren == 0 && brack == 0 && brace == 0))) break;
            else if (c == '-' && p+1 < len && src[p+1]=='-') break;
        } else if (rstate == 1) {
            if (c == '\\' && p+1 < len) p++;
            else if (c == '\'') rstate = 0;
        } else if (rstate == 2) {
            if (c == '\\' && p+1 < len) p++;
            else if (c == '"') rstate = 0;
        }
        p++;
    }
    return p;
}

static char *rewrite_env_locals(const char *src, size_t len, size_t *out_len) {
    buf_t o = {0};
    buf_grow(&o, len + 64);

    size_t i = 0;
    int state = 0;  /* 0=code, 1=single-quote str, 2=double-quote str, 3=line comment */
    while (i < len) {
        char c = src[i];
        if (state == 0) {
            if (c == '\'') { state = 1; buf_putc(&o, c); i++; continue; }
            if (c == '"')  { state = 2; buf_putc(&o, c); i++; continue; }
            if (c == '-' && i+1 < len && src[i+1] == '-') {
                state = 3; buf_puts(&o, "--", 2); i += 2; continue;
            }
            /* Match `local <idents> = <exprs>` — only at word boundary. */
            int at_boundary = (i == 0) || !is_id((unsigned char)src[i-1]);
            if (at_boundary &&
                i + 5 <= len &&
                src[i+0]=='l' && src[i+1]=='o' && src[i+2]=='c' &&
                src[i+3]=='a' && src[i+4]=='l' &&
                (i+5 == len || !is_id((unsigned char)src[i+5])) ) {
                /* Parse LHS idents, looking for _ENV. */
                size_t k = i + 5;
                while (k < len && (src[k]==' '||src[k]=='\t')) k++;
                int env_index = -1;   /* position of _ENV in LHS (0-based) */
                int n_idents = 0;
                size_t lhs_start = k;
                /* Walk identifiers + commas until we see '=' or something else. */
                for (;;) {
                    /* Must start with identifier char */
                    if (k >= len || !(is_id((unsigned char)src[k]) &&
                                      !(src[k] >= '0' && src[k] <= '9'))) {
                        /* Not a valid local declaration */
                        n_idents = 0; break;
                    }
                    size_t id_start = k;
                    while (k < len && is_id((unsigned char)src[k])) k++;
                    size_t id_len = k - id_start;
                    if (id_len == 4 && src[id_start]=='_' && src[id_start+1]=='E' &&
                        src[id_start+2]=='N' && src[id_start+3]=='V') {
                        if (env_index < 0) env_index = n_idents;
                    }
                    n_idents++;
                    /* Skip whitespace */
                    while (k < len && (src[k]==' '||src[k]=='\t')) k++;
                    if (k < len && src[k] == ',') {
                        k++;
                        while (k < len && (src[k]==' '||src[k]=='\t')) k++;
                        continue;
                    }
                    break;
                }
                if (env_index >= 0 && n_idents > 0 &&
                    k < len && src[k] == '=' &&
                    (k+1 == len || src[k+1] != '=')) {
                    /* We have `local ... _ENV ... = ...` — walk the
                     * RHS, wrapping the env_index-th expression with
                     * __p8_env(). */
                    /* Emit everything up to and including '=' */
                    buf_puts(&o, src + i, (k + 1) - i);
                    /* Walk RHS expressions */
                    size_t p = k + 1;
                    while (p < len && (src[p]==' '||src[p]=='\t')) p++;
                    for (int idx = 0; idx < n_idents; idx++) {
                        size_t e_end = scan_expr_end(src, len, p);
                        /* Trim trailing whitespace */
                        size_t e_trimmed = e_end;
                        while (e_trimmed > p &&
                               (src[e_trimmed-1]==' '||src[e_trimmed-1]=='\t'))
                            e_trimmed--;
                        /* Emit leading space */
                        buf_putc(&o, ' ');
                        if (idx == env_index) {
                            buf_str(&o, "__p8_env(");
                            buf_puts(&o, src + p, e_trimmed - p);
                            buf_putc(&o, ')');
                        } else {
                            buf_puts(&o, src + p, e_trimmed - p);
                        }
                        p = e_end;
                        /* Skip comma if present */
                        if (idx + 1 < n_idents) {
                            if (p < len && src[p] == ',') {
                                buf_putc(&o, ',');
                                p++;
                                while (p < len && (src[p]==' '||src[p]=='\t')) p++;
                            } else {
                                /* Fewer RHS values than LHS idents —
                                 * remaining get nil. Stop. */
                                break;
                            }
                        }
                    }
                    i = p;
                    (void)lhs_start;
                    continue;
                }
            }
        } else if (state == 1) {
            if (c == '\\' && i+1 < len) { buf_putc(&o, c); buf_putc(&o, src[i+1]); i += 2; continue; }
            if (c == '\'') state = 0;
        } else if (state == 2) {
            if (c == '\\' && i+1 < len) { buf_putc(&o, c); buf_putc(&o, src[i+1]); i += 2; continue; }
            if (c == '"') state = 0;
        } else if (state == 3) {
            if (c == '\n') state = 0;
        }
        buf_putc(&o, c);
        i++;
    }
    return buf_finish(&o, out_len);
}

/* ================================================================== */
/* Public API                                                          */
/* ================================================================== */
char *p8_translate_full(char *src, size_t len, size_t *out_len) {
    if (!src || len == 0) {
        free(src);
        char *e = (char *)malloc(1);
        if (e) e[0] = 0;
        if (out_len) *out_len = 0;
        return e;
    }

    /* Step 1: shrinko8 unminify. Free src FIRST — shrinko reads it
     * via streaming tokenizer and doesn't need it after returning.
     * Actually shrinko needs src alive during parsing, so we free
     * after. But we free it as soon as s1 is ready. */
    size_t s1_len = 0;
    char *s1 = p8_shrinko_unminify(src, len, &s1_len);
    free(src);  /* take ownership — free before next allocation */
    if (!s1) return NULL;

    /* Step 2: character-level transforms (post_fix_lua equivalent).
     * Handles: glyph substitution, string P8SCII escapes, highbytes
     * in code → numeric values, ; before ( at line start.
     * NOTE: // comments and ? print are already handled by shrinko8.
     * Operators (\\, ^^, @/%/$) are still in the source and need
     * conversion. */
    size_t s2_len = 0;
    char *s2 = pre_tokenize(s1, s1_len, &s2_len);
    free(s1);
    if (!s2) return NULL;

    /* Step 3: compound assign expansion.
     * On clean shrinko8 output, compound assigns are on their own lines
     * with proper whitespace. Scan for `op=` tokens and expand
     * `lhs op= rhs` → `lhs = lhs op (rhs)`. Also handle != → ~=.
     *
     * This is a single-buffer pass — no per-token mallocs. */
    size_t s3_len = 0;
    char *s3 = rewrite_compounds(s2, s2_len, &s3_len);
    free(s2);
    if (!s3) return NULL;

    /* Step 4: _ENV compatibility. Rewrite `local _ENV = X` so the
     * assigned table inherits _G for global function lookups. */
    size_t s4_len = 0;
    char *result = rewrite_env_locals(s3, s3_len, &s4_len);
    free(s3);
    if (!result) return NULL;

    if (out_len) *out_len = s4_len;
    return result;
}
