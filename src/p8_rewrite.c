/*
 * ThumbyP8 — PICO-8 Lua dialect rewriter.
 *
 * Line-by-line pass with block-comment / long-string state carried
 * across lines. Each line is rewritten with a small state machine
 * that tracks strings and line comments inside the line.
 *
 * The three transforms are applied in this order per line:
 *
 *   1. `!=`            → `~=`                  (char-level, code state only)
 *   2. `op=` compounds → `lhs = lhs op (rhs)`  (first occurrence per line,
 *                                               code state, paren depth 0)
 *   3. `if (cond) stmt` without `then`         → `if cond then stmt end`
 *
 * Doing this in line order (rather than whole-file) keeps the
 * implementation tractable and matches the reality of hand-written
 * PICO-8 carts, where these shortcuts never span physical lines.
 */
#include "p8_rewrite.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------- growable output buffer ----------------------------------- */
typedef struct buf {
    char  *data;
    size_t len;
    size_t cap;
} buf;

static int buf_reserve(buf *b, size_t extra) {
    if (b->len + extra + 1 <= b->cap) return 0;
    size_t nc = b->cap ? b->cap : 256;
    while (nc < b->len + extra + 1) nc *= 2;
    char *nd = (char *)realloc(b->data, nc);
    if (!nd) return -1;
    b->data = nd;
    b->cap = nc;
    return 0;
}
static void buf_put(buf *b, char c) {
    if (buf_reserve(b, 1) == 0) b->data[b->len++] = c;
}
static void buf_append(buf *b, const char *s, size_t n) {
    if (buf_reserve(b, n) == 0) { memcpy(b->data + b->len, s, n); b->len += n; }
}
static void buf_append_cstr(buf *b, const char *s) { buf_append(b, s, strlen(s)); }

/* ---------- per-line scan state -------------------------------------- */
enum { S_CODE, S_SQ, S_DQ, S_LCOMMENT };

static int is_ident_char(int c) {
    return c == '_' || isalnum((unsigned char)c);
}

/* Walk backwards from `pos` (exclusive) in `line` to find the start
 * of an lvalue: an identifier, possibly suffixed with `.field` or
 * `[expr]`. Returns the index of the first lvalue char, or `pos` if
 * no lvalue is present. Does not validate the lvalue — we rely on
 * the fact that real carts only use simple cases.
 *
 * This walks a stringified line, NOT the original buffer, so it
 * ignores string/comment state (caller has already established
 * we're in CODE state at `pos`). */
static int scan_lvalue_start(const char *line, int pos) {
    int i = pos;
    /* Skip trailing whitespace between lvalue and op */
    while (i > 0 && (line[i-1] == ' ' || line[i-1] == '\t')) i--;
    int end = i;
    /* Walk back through lvalue chars */
    while (i > 0) {
        char c = line[i-1];
        if (is_ident_char(c) || c == '.') { i--; continue; }
        if (c == ']') {
            /* match back to '[' */
            int depth = 1;
            i--;
            while (i > 0 && depth > 0) {
                if (line[i-1] == ']') depth++;
                else if (line[i-1] == '[') depth--;
                i--;
            }
            continue;
        }
        break;
    }
    /* Skip any whitespace we may have landed on */
    while (i < end && (line[i] == ' ' || line[i] == '\t')) i++;
    return i;
}

/* Scan a line to build a parallel state-per-char table (S_CODE / S_SQ /
 * S_DQ / S_LCOMMENT). Returns 0 if line ends in code state, or 1 if
 * it ends inside a single-line comment (which doesn't leak). Does NOT
 * handle block comments — the caller skips whole lines when inside
 * a block comment. */
static void classify_line(const char *line, size_t n, int *state_at) {
    int s = S_CODE;
    for (size_t i = 0; i < n; i++) {
        state_at[i] = s;
        char c = line[i];
        switch (s) {
        case S_CODE:
            if (c == '\'') s = S_SQ;
            else if (c == '"') s = S_DQ;
            else if (c == '-' && i + 1 < n && line[i+1] == '-') {
                s = S_LCOMMENT;
                state_at[i] = s;   /* '-' itself is already in-comment */
            }
            break;
        case S_SQ:
            if (c == '\\' && i + 1 < n) {
                state_at[i+1] = s; i++;   /* skip escaped char */
            } else if (c == '\'') {
                s = S_CODE;
            }
            break;
        case S_DQ:
            if (c == '\\' && i + 1 < n) {
                state_at[i+1] = s; i++;
            } else if (c == '"') {
                s = S_CODE;
            }
            break;
        case S_LCOMMENT:
            /* runs to end of line */
            break;
        }
    }
}

/* ---------- transform 1: != → ~= ------------------------------------- */
static void apply_not_equal(char *line, size_t n, const int *state) {
    for (size_t i = 0; i + 1 < n; i++) {
        if (state[i] != S_CODE) continue;
        if (line[i] == '!' && line[i+1] == '=') {
            line[i] = '~';
        }
    }
}

/* ---------- transform 2: compound assigns ---------------------------- */
/* Find first compound op at code-state, depth-0. Returns index of op
 * char, or -1 if none. `op_out` receives the operator char. */
static int find_compound(const char *line, size_t n, const int *state, char *op_out) {
    int depth = 0;
    for (size_t i = 0; i < n; i++) {
        if (state[i] != S_CODE) continue;
        char c = line[i];
        if (c == '(' || c == '[' || c == '{') depth++;
        else if (c == ')' || c == ']' || c == '}') { if (depth > 0) depth--; }
        else if (depth == 0 &&
                 (c == '+' || c == '-' || c == '*' || c == '/' || c == '%') &&
                 i + 1 < n && line[i+1] == '=') {
            /* Guard: not `//=` — but Lua doesn't have that anyway,
             * and a standalone `//` is int divide. If we see `/` we
             * also need to ensure it's not preceded by `/`. */
            if (c == '/' && i > 0 && line[i-1] == '/') continue;
            /* Guard: `==`, `~=`, `<=`, `>=` already impossible because
             * their first char is not in our set. */
            /* Guard: inside of == test (e.g. `a==b`): our op chars
             * aren't `=`, so fine. */
            *op_out = c;
            return (int)i;
        }
    }
    return -1;
}

/* Is [s..s+len) a Lua reserved word that terminates an expression?
 * (i.e. starts a new statement, or closes a block) */
static int is_stmt_terminator_keyword(const char *s, size_t len) {
    static const char *kws[] = {
        "return","break","end","else","elseif","then","do","while",
        "if","for","local","function","repeat","until","goto","in",NULL
    };
    for (const char **k = kws; *k; k++) {
        size_t kl = strlen(*k);
        if (kl == len && memcmp(s, *k, kl) == 0) return 1;
    }
    return 0;
}

/* Find the end of an expression starting at `rhs_start` within a
 * line. Tracks paren/bracket depth and string state; stops at:
 *   - end of line
 *   - `;` at depth 0
 *   - a statement-keyword at depth 0 (e.g. `return`, `end`)
 *   - start of a line comment */
static int find_expr_end(const char *line, size_t n, int rhs_start) {
    int depth = 0;
    int s = S_CODE;
    int i = rhs_start;
    while (i < (int)n) {
        char c = line[i];
        if (s == S_CODE) {
            if (c == '\'') { s = S_SQ; i++; continue; }
            if (c == '"')  { s = S_DQ; i++; continue; }
            if (c == '-' && i + 1 < (int)n && line[i+1] == '-') return i;
            if (c == '(' || c == '[' || c == '{') { depth++; i++; continue; }
            if (c == ')' || c == ']' || c == '}') {
                if (depth == 0) return i;  /* unmatched close — outer block ends */
                depth--; i++; continue;
            }
            if (depth == 0 && c == ';') return i;
            if (depth == 0 && (c == ' ' || c == '\t')) {
                /* Peek at next non-whitespace word; if it's a
                 * statement-terminator keyword, stop here. */
                int j = i;
                while (j < (int)n && (line[j] == ' ' || line[j] == '\t')) j++;
                int wstart = j;
                while (j < (int)n && is_ident_char((unsigned char)line[j])) j++;
                int wlen = j - wstart;
                if (wlen > 0 &&
                    is_stmt_terminator_keyword(line + wstart, (size_t)wlen)) {
                    return i;
                }
                i++;
                continue;
            }
            i++;
        } else if (s == S_SQ) {
            if (c == '\\' && i + 1 < (int)n) i += 2;
            else if (c == '\'') { s = S_CODE; i++; }
            else i++;
        } else if (s == S_DQ) {
            if (c == '\\' && i + 1 < (int)n) i += 2;
            else if (c == '"') { s = S_CODE; i++; }
            else i++;
        } else i++;
    }
    return (int)n;
}

/* Apply compound-assign rewrite into `out`. `line` is the raw line
 * (without trailing newline); `n` is length. */
static void apply_compound(buf *out, const char *line, size_t n, const int *state) {
    char op;
    int op_pos = find_compound(line, n, state, &op);
    if (op_pos < 0) {
        buf_append(out, line, n);
        return;
    }
    int lhs_start = scan_lvalue_start(line, op_pos);
    if (lhs_start >= op_pos) {
        /* Couldn't find an lvalue — bail. */
        buf_append(out, line, n);
        return;
    }
    /* RHS: from after the `=` to the end of the expression (honoring
     * paren depth, strings, statement keywords, `;`, and comments). */
    int rhs_start = op_pos + 2;
    int rhs_end   = find_expr_end(line, n, rhs_start);
    /* Trim trailing whitespace on RHS */
    while (rhs_end > rhs_start && (line[rhs_end-1] == ' ' || line[rhs_end-1] == '\t'))
        rhs_end--;
    /* Trim leading whitespace on RHS to avoid `= 1` → `= ( 1)`. */
    while (rhs_start < rhs_end && (line[rhs_start] == ' ' || line[rhs_start] == '\t'))
        rhs_start++;
    (void)state;

    /* Emit: prefix [0..lhs_start) + lhs + " = " + lhs + " " + op + " (" + rhs + ")" + tail */
    buf_append(out, line, lhs_start);
    buf_append(out, line + lhs_start, op_pos - lhs_start);
    buf_append_cstr(out, " = ");
    buf_append(out, line + lhs_start, op_pos - lhs_start);
    buf_put(out, ' ');
    buf_put(out, op);
    buf_append_cstr(out, " (");
    buf_append(out, line + rhs_start, rhs_end - rhs_start);
    buf_put(out, ')');
    /* Tail: everything after the RHS, including any trailing
     * statement keywords the expression-end scan stopped at. */
    if (rhs_end < (int)n) {
        buf_append(out, line + rhs_end, n - rhs_end);
    }
}

/* ---------- transform 3: if (cond) stmt ------------------------------ */
/* If the line starts (after whitespace) with `if (`, scan for the
 * matching `)`, check what follows. If non-`then` non-empty code
 * follows, rewrite to `if cond then stmt end`.
 *
 * Note: line has already been passed through compound-assign rewrite,
 * so `line` here is the post-compound version. We re-classify it. */
static void apply_shorthand_if(buf *out, const char *line, size_t n) {
    /* Skip leading whitespace */
    size_t i = 0;
    while (i < n && (line[i] == ' ' || line[i] == '\t')) i++;
    if (i + 3 > n) { buf_append(out, line, n); return; }
    if (!(line[i] == 'i' && line[i+1] == 'f' &&
          (i + 2 == n || line[i+2] == ' ' || line[i+2] == '\t' || line[i+2] == '('))) {
        buf_append(out, line, n);
        return;
    }
    /* Walk past "if" and any whitespace */
    size_t p = i + 2;
    while (p < n && (line[p] == ' ' || line[p] == '\t')) p++;
    if (p >= n || line[p] != '(') { buf_append(out, line, n); return; }

    /* Find matching ')' — track strings + nesting */
    int depth = 1;
    size_t q = p + 1;
    int s = S_CODE;
    while (q < n && depth > 0) {
        char c = line[q];
        if (s == S_CODE) {
            if (c == '\'') s = S_SQ;
            else if (c == '"') s = S_DQ;
            else if (c == '(') depth++;
            else if (c == ')') { depth--; if (depth == 0) break; }
            else if (c == '-' && q + 1 < n && line[q+1] == '-') {
                /* comment inside condition — bail, leave line alone */
                buf_append(out, line, n);
                return;
            }
        } else if (s == S_SQ) {
            if (c == '\\' && q + 1 < n) q++;
            else if (c == '\'') s = S_CODE;
        } else if (s == S_DQ) {
            if (c == '\\' && q + 1 < n) q++;
            else if (c == '"') s = S_CODE;
        }
        q++;
    }
    if (depth != 0) { buf_append(out, line, n); return; }
    /* q now points at the matching ')' */

    /* What follows the ')'? Skip whitespace. */
    size_t r = q + 1;
    while (r < n && (line[r] == ' ' || line[r] == '\t')) r++;

    /* If we hit end-of-line, or a comment, or 'then' → regular if. */
    if (r >= n) { buf_append(out, line, n); return; }
    if (r + 1 < n && line[r] == '-' && line[r+1] == '-') {
        buf_append(out, line, n); return;
    }
    if (r + 4 <= n && !memcmp(line + r, "then", 4) &&
        (r + 4 == n || !is_ident_char((unsigned char)line[r+4]))) {
        buf_append(out, line, n); return;
    }

    /* Shorthand detected. Find the statement end: either end of line
     * or start of a trailing comment. */
    size_t stmt_start = r;
    size_t stmt_end = n;
    /* Scan for a comment start in code state from stmt_start */
    int ss = S_CODE;
    for (size_t k = stmt_start; k < n; k++) {
        char c = line[k];
        if (ss == S_CODE) {
            if (c == '\'') ss = S_SQ;
            else if (c == '"') ss = S_DQ;
            else if (c == '-' && k + 1 < n && line[k+1] == '-') {
                stmt_end = k;
                break;
            }
        } else if (ss == S_SQ) {
            if (c == '\\' && k + 1 < n) k++;
            else if (c == '\'') ss = S_CODE;
        } else if (ss == S_DQ) {
            if (c == '\\' && k + 1 < n) k++;
            else if (c == '"') ss = S_CODE;
        }
    }
    /* Trim trailing whitespace on the statement */
    while (stmt_end > stmt_start &&
           (line[stmt_end-1] == ' ' || line[stmt_end-1] == '\t'))
        stmt_end--;
    if (stmt_end == stmt_start) {
        /* No actual statement. Treat like regular empty if. */
        buf_append(out, line, n); return;
    }

    /* Emit: [0..q+1)  " then "  [stmt_start..stmt_end)  " end"  [stmt_end..n) */
    buf_append(out, line, q + 1);
    buf_append_cstr(out, " then ");
    buf_append(out, line + stmt_start, stmt_end - stmt_start);
    buf_append_cstr(out, " end");
    if (stmt_end < n) buf_append(out, line + stmt_end, n - stmt_end);
}

/* ---------- full-file driver ----------------------------------------- */
/* Simple block-comment / long-string tracker across lines. We don't
 * honor `[===[` bracket levels — PICO-8 carts almost never use long
 * strings at all. If you need them, extend here. */

char *p8_rewrite_lua(const char *src, size_t len, size_t *out_len) {
    buf out = {0};

    /* Very small state across lines: inside block comment (`--[[`). */
    int in_bcomment = 0;

    size_t i = 0;
    while (i < len) {
        /* find end of line */
        size_t j = i;
        while (j < len && src[j] != '\n') j++;
        size_t ll = j - i;        /* line length (not counting \n) */
        const char *line = src + i;

        if (in_bcomment) {
            /* Look for `]]` to close. If found, mark end position and
             * append the first portion verbatim, then rewrite the rest
             * of the line as code. For simplicity: if the close isn't
             * on this line, emit the whole line unchanged. */
            const char *close = NULL;
            for (size_t k = 0; k + 1 < ll; k++) {
                if (line[k] == ']' && line[k+1] == ']') { close = line + k + 2; break; }
            }
            if (!close) {
                buf_append(&out, line, ll);
                if (j < len) buf_put(&out, '\n');
                i = j + (j < len);
                continue;
            }
            /* Emit up to & including `]]`, then process the remainder
             * as a normal code line. */
            size_t consumed = close - line;
            buf_append(&out, line, consumed);
            in_bcomment = 0;
            /* Temporarily replace the line with its remainder and fall
             * through to normal handling. */
            line += consumed;
            ll   -= consumed;
            if (ll == 0) {
                if (j < len) buf_put(&out, '\n');
                i = j + (j < len);
                continue;
            }
        }

        /* Detect a block comment that OPENS on this line. Simple heuristic:
         * if the line (in code state) contains `--[[`, start block state
         * after that position. We handle this in a post-pass over the
         * final emitted line below. */

        /* Build a working copy of the line we can mutate (for != → ~=)  */
        char *work = (char *)malloc(ll + 1);
        if (!work) break;
        memcpy(work, line, ll);
        work[ll] = 0;

        /* Classify (for != and compound-op state). */
        int *state = (int *)calloc(ll + 1, sizeof(int));
        if (!state) { free(work); break; }
        classify_line(work, ll, state);

        /* 1. != → ~= (in-place on work) */
        apply_not_equal(work, ll, state);

        /* 2. compound assign — emit to a temp buffer */
        buf tmp = {0};
        apply_compound(&tmp, work, ll, state);
        free(state);
        free(work);

        /* 3. shorthand if — re-scan tmp and emit to out */
        apply_shorthand_if(&out, tmp.data ? tmp.data : "", tmp.len);

        /* Did a block comment open on this emitted line? Walk the
         * emitted portion of `out` since we last started the line. */
        /* (For robustness we look at the final pre-newline chunk.) */
        /* Simple scan: look for `--[[` in code state. */
        {
            const char *ln = out.data + (out.len - (out.len - (out.len > 0 ? (out.len) : 0)));
            /* Actually just scan the `tmp` content we just emitted. */
            const char *scan = tmp.data ? tmp.data : "";
            size_t sl = tmp.len;
            int s = S_CODE;
            for (size_t k = 0; k + 3 < sl; k++) {
                if (s == S_CODE) {
                    char c = scan[k];
                    if (c == '\'') s = S_SQ;
                    else if (c == '"') s = S_DQ;
                    else if (c == '-' && scan[k+1] == '-' &&
                             scan[k+2] == '[' && scan[k+3] == '[') {
                        in_bcomment = 1;
                        break;
                    } else if (c == '-' && scan[k+1] == '-') {
                        break; /* line comment — rest of line is comment */
                    }
                } else if (s == S_SQ) {
                    if (scan[k] == '\\') k++;
                    else if (scan[k] == '\'') s = S_CODE;
                } else if (s == S_DQ) {
                    if (scan[k] == '\\') k++;
                    else if (scan[k] == '"') s = S_CODE;
                }
            }
            (void)ln;
        }
        free(tmp.data);

        if (j < len) buf_put(&out, '\n');
        i = j + (j < len);
    }

    if (!out.data) {
        out.data = (char *)malloc(1);
        if (!out.data) return NULL;
        out.data[0] = 0;
    } else {
        if (buf_reserve(&out, 1) == 0) out.data[out.len] = 0;
    }
    if (out_len) *out_len = out.len;
    return out.data;
}
