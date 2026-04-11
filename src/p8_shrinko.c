/*
 * ThumbyP8 — PICO-8 tokenizer, parser, and unminifier (C port of shrinko8).
 *
 * Faithful line-by-line port of:
 *   tools/shrinko8/pico_tokenize.py  — tokenize()
 *   tools/shrinko8/pico_parse.py     — parse()
 *   tools/shrinko8/pico_unminify.py  — unminify_code()
 *
 * PICO-8 only (no Picotron code paths). No scope/variable tracking.
 */

#include "p8_shrinko.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <ctype.h>

/* ================================================================
 *  Forward declarations and type definitions
 * ================================================================ */

/* ---------- Token types ---------- */
typedef enum {
    TT_NONE = 0,   /* erased / dummy / end token */
    TT_NUMBER,
    TT_STRING,
    TT_IDENT,
    TT_KEYWORD,
    TT_PUNCT,
} TokenType;

/* ---------- Token ---------- */
typedef struct Token {
    TokenType type;
    char     *value;     /* malloc'd, NUL-terminated; NULL for dummy/erased */
    int       vline;     /* virtual line number */
} Token;

/* ---------- Node types ---------- */
typedef enum {
    NT_NONE = 0,
    NT_VAR,
    NT_INDEX,
    NT_MEMBER,
    NT_CONST,
    NT_GROUP,
    NT_UNARY_OP,
    NT_BINARY_OP,
    NT_CALL,
    NT_TABLE,
    NT_TABLE_INDEX,
    NT_TABLE_MEMBER,
    NT_VARARGS,
    NT_ASSIGN,
    NT_OP_ASSIGN,
    NT_LOCAL,
    NT_FUNCTION,
    NT_IF,
    NT_ELSEIF,
    NT_ELSE,
    NT_WHILE,
    NT_REPEAT,
    NT_UNTIL,
    NT_FOR,
    NT_FOR_IN,
    NT_RETURN,
    NT_BREAK,
    NT_GOTO,
    NT_LABEL,
    NT_BLOCK,
    NT_DO,
} NodeType;

/* ---------- Child: either a Token or a Node ---------- */
typedef enum { CHILD_TOKEN, CHILD_NODE } ChildTag;

typedef struct Child {
    ChildTag tag;
    union {
        int  token_idx;   /* index into token array */
        struct Node *node;
    };
} Child;

/* ---------- Node ---------- */
typedef struct Node {
    NodeType     type;
    Child       *children;
    int          num_children;
    int          cap_children;
    struct Node *parent;

    /* Type-specific fields: */
    int          short_flag;   /* 0=false, 1=true, SHORT_NESTED=2 */

    /* Pointers into children for named fields.
     * These point to the same Child nodes — not separate allocations. */
    struct Node *cond;         /* if_, elseif, until, while_ */
    struct Node *then_block;   /* if_, elseif */
    struct Node *else_node;    /* if_ */
    struct Node *body;         /* while_, repeat, for_, for_in, do, function */
    struct Node *until_node;   /* repeat */
    struct Node *target;       /* function */
} Node;

/* ================================================================
 *  Growable buffer
 * ================================================================ */
typedef struct {
    char  *data;
    size_t len;
    size_t cap;
} Buf;

static void buf_init(Buf *b) {
    b->data = NULL;
    b->len = 0;
    b->cap = 0;
}

static bool buf_grow(Buf *b, size_t need) {
    if (b->len + need <= b->cap) return true;
    size_t newcap = b->cap ? b->cap * 2 : 256;
    while (newcap < b->len + need) newcap *= 2;
    char *p = (char *)realloc(b->data, newcap);
    if (!p) return false;
    b->data = p;
    b->cap = newcap;
    return true;
}

static bool buf_append(Buf *b, const char *s, size_t n) {
    if (!buf_grow(b, n)) return false;
    memcpy(b->data + b->len, s, n);
    b->len += n;
    return true;
}

static bool buf_appends(Buf *b, const char *s) {
    return buf_append(b, s, strlen(s));
}

static bool buf_appendc(Buf *b, char c) {
    return buf_append(b, &c, 1);
}

static bool buf_append_repeat(Buf *b, const char *s, size_t slen, int count) {
    for (int i = 0; i < count; i++) {
        if (!buf_append(b, s, slen)) return false;
    }
    return true;
}

static void buf_free(Buf *b) {
    free(b->data);
    b->data = NULL;
    b->len = b->cap = 0;
}

/* ================================================================
 *  Dynamic arrays (generic via macros)
 * ================================================================ */
#define DA_INIT(arr, n, c) do { (arr) = NULL; (n) = 0; (c) = 0; } while(0)

#define DA_PUSH(arr, n, c, val, fail_label) do { \
    if ((n) >= (c)) { \
        int _nc = (c) ? (c) * 2 : 16; \
        void *_p = realloc((arr), (size_t)_nc * sizeof(*(arr))); \
        if (!_p) goto fail_label; \
        (arr) = _p; \
        (c) = _nc; \
    } \
    (arr)[(n)++] = (val); \
} while(0)

/* ================================================================
 *  Token array
 * ================================================================ */
typedef struct {
    Token *items;
    int    count;
    int    cap;
} TokenArray;

static void tkarr_init(TokenArray *a) {
    a->items = NULL;
    a->count = 0;
    a->cap = 0;
}

/* Add token with explicit length (not NUL-terminated source) */
static int tkarr_addn(TokenArray *a, TokenType type, const char *value, int vlen, int vline) {
    if (a->count >= a->cap) {
        int nc = a->cap ? a->cap * 2 : 64;
        Token *p = (Token *)realloc(a->items, (size_t)nc * sizeof(Token));
        if (!p) return -1;
        a->items = p;
        a->cap = nc;
    }
    int i = a->count++;
    a->items[i].type = type;
    a->items[i].vline = vline;
    if (value && vlen > 0) {
        a->items[i].value = (char *)malloc((size_t)vlen + 1);
        if (!a->items[i].value) return -1;
        memcpy(a->items[i].value, value, (size_t)vlen);
        a->items[i].value[vlen] = '\0';
    } else {
        a->items[i].value = NULL;
    }
    return i;
}

static void tkarr_free(TokenArray *a) {
    for (int i = 0; i < a->count; i++) {
        free(a->items[i].value);
    }
    free(a->items);
    a->items = NULL;
    a->count = a->cap = 0;
}

/* ================================================================
 *  Node arena (pool allocator for parse nodes)
 * ================================================================ */
#define NODE_ARENA_BLOCK 256

typedef struct NodeArenaBlock {
    Node nodes[NODE_ARENA_BLOCK];
    int  used;
    struct NodeArenaBlock *next;
} NodeArenaBlock;

typedef struct {
    NodeArenaBlock *head;
} NodeArena;

static void arena_init(NodeArena *a) {
    a->head = NULL;
}

static Node *arena_alloc(NodeArena *a) {
    if (!a->head || a->head->used >= NODE_ARENA_BLOCK) {
        NodeArenaBlock *b = (NodeArenaBlock *)calloc(1, sizeof(NodeArenaBlock));
        if (!b) return NULL;
        b->next = a->head;
        a->head = b;
    }
    Node *n = &a->head->nodes[a->head->used++];
    memset(n, 0, sizeof(Node));
    return n;
}

static void arena_free(NodeArena *a) {
    NodeArenaBlock *b = a->head;
    while (b) {
        /* Free children arrays for all nodes in this block */
        for (int i = 0; i < b->used; i++) {
            free(b->nodes[i].children);
        }
        NodeArenaBlock *next = b->next;
        free(b);
        b = next;
    }
    a->head = NULL;
}

/* ================================================================
 *  Node construction helpers
 * ================================================================ */

static bool node_add_child_token(Node *n, int token_idx) {
    if (n->num_children >= n->cap_children) {
        int nc = n->cap_children ? n->cap_children * 2 : 8;
        Child *p = (Child *)realloc(n->children, (size_t)nc * sizeof(Child));
        if (!p) return false;
        n->children = p;
        n->cap_children = nc;
    }
    Child *c = &n->children[n->num_children++];
    c->tag = CHILD_TOKEN;
    c->token_idx = token_idx;
    return true;
}

static bool node_add_child_node(Node *n, Node *child) {
    if (n->num_children >= n->cap_children) {
        int nc = n->cap_children ? n->cap_children * 2 : 8;
        Child *p = (Child *)realloc(n->children, (size_t)nc * sizeof(Child));
        if (!p) return false;
        n->children = p;
        n->cap_children = nc;
    }
    Child *c = &n->children[n->num_children++];
    c->tag = CHILD_NODE;
    c->node = child;
    child->parent = n;
    return true;
}

/* ================================================================
 *  Keyword / operator tables
 * ================================================================ */

static const char *k_keywords[] = {
    "and", "break", "do", "else", "elseif", "end", "false",
    "for", "function", "goto", "if", "in", "local", "nil",
    "not", "or", "repeat", "return", "then", "true", "until",
    "while", NULL
};

static bool is_keyword(const char *s) {
    for (int i = 0; k_keywords[i]; i++) {
        if (strcmp(s, k_keywords[i]) == 0) return true;
    }
    return false;
}

static bool is_ident_char(unsigned char ch) {
    return (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') ||
           (ch >= 'A' && ch <= 'Z') || ch == '_' ||
           ch == 0x1e || ch == 0x1f || ch >= 0x80;
}

static bool is_wspace(char ch) {
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
}

/* Binary operator precedence table */
typedef struct {
    const char *op;
    int         prec;
} BinOpPrec;

static const BinOpPrec k_binary_op_precs[] = {
    {"or",  1}, {"and", 2},
    {"!=",  3}, {"~=",  3}, {"==", 3}, {"<",  3}, {"<=", 3}, {">",  3}, {">=", 3},
    {"|",   4}, {"^^",  5}, {"~",  5}, {"&",  6},
    {"<<",  7}, {">>",  7}, {">>>",7}, {">><",7}, {"<<>",7},
    {"..",   8},
    {"+",   9}, {"-",   9},
    {"*",  10}, {"/",  10}, {"//", 10}, {"\\", 10}, {"%", 10},
    {"^",  12},
    {NULL,  0}
};

static int get_binop_prec(const char *op) {
    for (int i = 0; k_binary_op_precs[i].op; i++) {
        if (strcmp(k_binary_op_precs[i].op, op) == 0)
            return k_binary_op_precs[i].prec;
    }
    return -1;
}

static bool is_right_binop(const char *op) {
    return strcmp(op, "^") == 0 || strcmp(op, "..") == 0;
}

#define K_UNARY_OPS_PREC 11

static bool is_unary_op(const char *v) {
    return strcmp(v, "-") == 0 || strcmp(v, "~") == 0 || strcmp(v, "not") == 0 ||
           strcmp(v, "#") == 0 || strcmp(v, "@") == 0 || strcmp(v, "%") == 0 ||
           strcmp(v, "$") == 0;
    /* Note: "*" is Picotron-only, omitted */
}

static const char *k_block_ends[] = {"end", "else", "elseif", "until", NULL};

static bool is_block_end(const char *v) {
    for (int i = 0; k_block_ends[i]; i++) {
        if (strcmp(v, k_block_ends[i]) == 0) return true;
    }
    return false;
}

/* ================================================================
 *  TOKENIZER
 *  Port of tokenize() from pico_tokenize.py
 * ================================================================ */

typedef struct {
    const char *text;
    size_t      text_len;
    size_t      idx;
    int         vline;
    TokenArray *tokens;
} Tokenizer;

static char tk_peek0(Tokenizer *t) {
    return (t->idx < t->text_len) ? t->text[t->idx] : '\0';
}

static char tk_take(Tokenizer *t) {
    if (t->idx < t->text_len) return t->text[t->idx++];
    return '\0';
}

static bool tk_accept(Tokenizer *t, char ch) {
    if (tk_peek0(t) == ch) { t->idx++; return true; }
    return false;
}

static bool tk_accept_one_of(Tokenizer *t, const char *chs) {
    char ch = tk_peek0(t);
    if (ch && strchr(chs, ch)) { t->idx++; return true; }
    return false;
}

static int tk_add_token(Tokenizer *t, TokenType type, size_t start) {
    int vlen = (int)(t->idx - start);
    return tkarr_addn(t->tokens, type, t->text + start, vlen, t->vline);
}

/* Skip a line comment (// or -- style). Advances past the newline. */
static void tk_line_comment(Tokenizer *t) {
    while (true) {
        char ch = tk_take(t);
        if (ch == '\n' || ch == '\0') break;
    }
    t->vline++;
}

/* Try to match a long bracket: [=*[ ... ]=*]
 * 'off' is how many chars before t->idx the first '[' was (to rewind).
 * Returns true on success, sets *start_i and *end_i to content range. */
static bool tk_long_brackets(Tokenizer *t, int off, size_t *start_i, size_t *end_i) {
    t->idx += (size_t)off;
    size_t orig_idx = t->idx;

    if (!tk_accept(t, '[')) { t->idx = orig_idx; return false; }
    size_t pad_start = t->idx;
    while (tk_accept(t, '=')) {}
    int pad_len = (int)(t->idx - pad_start);
    if (!tk_accept(t, '[')) { t->idx = orig_idx; return false; }

    *start_i = t->idx;

    /* Build close pattern ]=*] */
    char close_pat[66]; /* max 63 '=' + ']' + ']' + '\0' */
    if (pad_len > 62) pad_len = 62;
    close_pat[0] = ']';
    for (int i = 0; i < pad_len; i++) close_pat[1 + i] = '=';
    close_pat[1 + pad_len] = ']';
    close_pat[2 + pad_len] = '\0';

    /* Search for close_pat */
    const char *found = strstr(t->text + t->idx, close_pat);
    if (found) {
        *end_i = (size_t)(found - t->text);
        t->idx = *end_i + (size_t)(2 + pad_len);
        return true;
    }

    /* Unterminated — rewind */
    t->idx = orig_idx;
    return false;
}

/* Try to parse a long comment (--[=*[...]=*]). Returns true on success. */
static bool tk_long_comment(Tokenizer *t) {
    size_t start_i, end_i;
    size_t save = t->idx;
    if (tk_long_brackets(t, 0, &start_i, &end_i)) {
        /* Count newlines inside the comment for vline tracking */
        for (size_t i = start_i; i < end_i; i++) {
            if (t->text[i] == '\n') t->vline++;
        }
        /* Also count newlines in the close bracket (just ] and =, none there) */
        return true;
    }
    t->idx = save;
    return false;
}

static void tk_number(Tokenizer *t) {
    size_t orig = t->idx - 1; /* we already consumed the first char */
    char first = t->text[orig];

    const char *digits;
    if (first == '0' && (tk_peek0(t) == 'b' || tk_peek0(t) == 'B')) {
        t->idx++;  /* skip 'b' */
        digits = "01";
    } else if (first == '0' && (tk_peek0(t) == 'x' || tk_peek0(t) == 'X')) {
        t->idx++;  /* skip 'x' */
        digits = "0123456789aAbBcCdDeEfF";
    } else {
        digits = "0123456789";
    }

    while (true) {
        char ch = tk_peek0(t);
        if (ch && strchr(digits, ch)) {
            t->idx++;
        } else if (ch == '.') {
            t->idx++;
        } else {
            break;
        }
    }

    int vlen = (int)(t->idx - orig);
    tkarr_addn(t->tokens, TT_NUMBER, t->text + orig, vlen, t->vline);
}

static void tk_ident(Tokenizer *t) {
    size_t orig = t->idx - 1;

    while (is_ident_char((unsigned char)tk_peek0(t))) {
        t->idx++;
    }

    int vlen = (int)(t->idx - orig);
    /* Check keyword */
    char tmp[64];
    if (vlen < (int)sizeof(tmp)) {
        memcpy(tmp, t->text + orig, (size_t)vlen);
        tmp[vlen] = '\0';
        if (is_keyword(tmp)) {
            tkarr_addn(t->tokens, TT_KEYWORD, t->text + orig, vlen, t->vline);
            return;
        }
    }
    tkarr_addn(t->tokens, TT_IDENT, t->text + orig, vlen, t->vline);
}

static void tk_string(Tokenizer *t) {
    size_t orig = t->idx - 1;
    char quote = t->text[orig];

    while (true) {
        char ch = tk_take(t);
        if (ch == '\n' || ch == '\0') {
            /* Unterminated string — create token anyway */
            break;
        } else if (ch == '\\') {
            if (tk_accept(t, 'z')) {
                /* \z: skip subsequent whitespace */
                while (is_wspace(tk_peek0(t))) {
                    if (tk_peek0(t) == '\n') t->vline++;
                    tk_take(t);
                }
            } else {
                tk_take(t); /* skip at least one char after backslash */
            }
        } else if (ch == quote) {
            break;
        }
    }

    int vlen = (int)(t->idx - orig);
    tkarr_addn(t->tokens, TT_STRING, t->text + orig, vlen, t->vline);
}

static void tk_long_string(Tokenizer *t) {
    size_t start_i, end_i;
    size_t save = t->idx;
    /* Rewind 2 chars (we consumed '[' and then accept saw '[' or '=') */
    if (tk_long_brackets(t, -2, &start_i, &end_i)) {
        /* Count newlines for vline */
        for (size_t i = start_i; i < end_i; i++) {
            if (t->text[i] == '\n') t->vline++;
        }
        /* The token spans from (save - 2) to t->idx */
        size_t orig = save - 2;
        int vlen = (int)(t->idx - orig);
        tkarr_addn(t->tokens, TT_STRING, t->text + orig, vlen, t->vline);
    }
    /* else: invalid long brackets, just ignore */
}

static bool tokenize(const char *text, size_t text_len, TokenArray *out) {
    Tokenizer t;
    t.text = text;
    t.text_len = text_len;
    t.idx = 0;
    t.vline = 0;
    t.tokens = out;

    while (t.idx < t.text_len) {
        char ch = tk_take(&t);

        /* Whitespace */
        if (is_wspace(ch)) {
            if (ch == '\n') t.vline++;
            continue;
        }

        /* Number: digit, or '.' followed by digit */
        if ((ch >= '0' && ch <= '9') || (ch == '.' && tk_peek0(&t) >= '0' && tk_peek0(&t) <= '9')) {
            tk_number(&t);
            continue;
        }

        /* Identifier */
        if (is_ident_char((unsigned char)ch)) {
            tk_ident(&t);
            continue;
        }

        /* String */
        if (ch == '"' || ch == '\'') {
            tk_string(&t);
            continue;
        }

        /* Long string: [[ or [=[ */
        if (ch == '[' && tk_accept_one_of(&t, "=[")) {
            tk_long_string(&t);
            continue;
        }

        /* Comment: -- */
        if (ch == '-' && tk_accept(&t, '-')) {
            if (!tk_long_comment(&t)) {
                tk_line_comment(&t);
            }
            continue;
        }

        /* C-style comment: // (PICO-8 only) */
        if (ch == '/' && tk_accept(&t, '/')) {
            tk_line_comment(&t);
            continue;
        }

        /* Punctuation (port of lines 592-606 of pico_tokenize.py) */
        if (strchr("+-*/\\%&|^<>=~#()[]{};,?@$.:!", ch)) {
            size_t orig = t.idx - 1;

            if (ch == '!' && tk_accept(&t, '=')) {
                /* != */
                tk_add_token(&t, TT_PUNCT, orig);
                continue;
            }

            if (ch == '!') {
                /* standalone ! is not valid, but we consumed it; skip */
                continue;
            }

            if (strchr("+-*/\\%&|^<>=~#()[]{};,?@$.:", ch)) {
                /* Multi-char punct matching, faithfully ported from Python */
                if (strchr(".:/^<>", ch) && tk_accept(&t, ch)) {
                    /* ch repeated twice: .., ::, //, ^^, <<, >> */
                    if (strchr(".>", ch) && tk_accept(&t, ch)) {
                        /* ... or >>> */
                        if (ch == '>') tk_accept(&t, '='); /* >>>= */
                    } else if (ch == '<' && tk_accept(&t, '>')) {
                        /* <<> */
                        tk_accept(&t, '='); /* <<>= */
                    } else if (ch == '>' && tk_accept(&t, '<')) {
                        /* >>< */
                        tk_accept(&t, '='); /* >><= */
                    } else if (strchr("./^<>", ch)) {
                        /* ..= //= ^^= <<= >>= */
                        tk_accept(&t, '=');
                    }
                } else if (strchr("+-*/\\%&|^<>=~", ch)) {
                    /* Single-char op followed by '=': +=, -=, etc */
                    tk_accept(&t, '=');
                }

                tk_add_token(&t, TT_PUNCT, orig);
                continue;
            }
        }

        /* Unknown character — skip */
    }

    return true;
}

/* ================================================================
 *  PARSER
 *  Port of parse() from pico_parse.py
 * ================================================================ */

/* A "vline" sentinel meaning "no vline constraint" */
#define VLINE_NONE (-1)
/* A sentinel meaning "nested" shorthand (k_nested in Python) */
#define SHORT_NESTED 2

typedef struct {
    TokenArray *tokens;
    NodeArena  *arena;
    int         idx;       /* current token index */
    bool        failed;    /* set true on parse error to bail */
} Parser;

/* Note: a sentinel token (TT_NONE, value=NULL) is appended to the
 * token array after tokenization. p_peek returns the sentinel for
 * out-of-bounds forward access; for negative out-of-bounds, returns
 * the sentinel too. p_take always increments but never past the sentinel. */

static Token *p_peek(Parser *p, int off) {
    int i = p->idx + off;
    if (i < 0) return &p->tokens->items[p->tokens->count - 1]; /* sentinel */
    if (i >= p->tokens->count) return &p->tokens->items[p->tokens->count - 1]; /* sentinel */
    return &p->tokens->items[i];
}

static Token *p_peek0(Parser *p) {
    return p_peek(p, 0);
}

static const char *p_peek_val(Parser *p, int off) {
    Token *t = p_peek(p, off);
    return t->value; /* NULL for sentinel */
}

static Token *p_take(Parser *p) {
    Token *t = p_peek0(p);
    if (p->idx < p->tokens->count - 1) p->idx++; /* don't go past sentinel */
    return t;
}

static bool p_accept(Parser *p, const char *value) {
    const char *v = p_peek_val(p, 0);
    if (v && strcmp(v, value) == 0) { p->idx++; return true; }
    return false;
}

static bool p_require(Parser *p, const char *value) {
    if (!p_accept(p, value)) {
        p->failed = true;
        return false;
    }
    return true;
}

static bool p_is_type(Parser *p, int off, TokenType type) {
    Token *t = p_peek(p, off);
    return t->type == type;
}

/* Helper: is the type a "prefix type" that can have . [] () : suffix? */
static bool is_prefix_type(NodeType nt) {
    return nt == NT_VAR || nt == NT_MEMBER || nt == NT_INDEX ||
           nt == NT_CALL || nt == NT_GROUP;
}

/* Forward declarations for the recursive descent parser */
static Node *parse_expr(Parser *p, int prec);
static Node *parse_core_expr(Parser *p);
static Node *parse_block(Parser *p, int vline, bool with_until, Node **until_out);
static Node *parse_stmt(Parser *p, int vline);
static Node *parse_if(Parser *p, NodeType type);
static Node *parse_while_stmt(Parser *p);
static Node *parse_repeat(Parser *p);
static Node *parse_for_stmt(Parser *p);
static Node *parse_return_stmt(Parser *p, int vline);
static Node *parse_print(Parser *p);
static Node *parse_local(Parser *p);
static Node *parse_function(Parser *p, bool stmt, bool local);
static Node *parse_table(Parser *p);
static Node *parse_call(Parser *p, Node *expr);
static Node *parse_assign(Parser *p, Node *first);
static Node *parse_opassign(Parser *p, Node *first);
static Node *parse_misc_stmt(Parser *p);

/* Create a node from the arena */
static Node *make_node(Parser *p, NodeType type) {
    Node *n = arena_alloc(p->arena);
    if (!n) { p->failed = true; return NULL; }
    n->type = type;
    return n;
}

/* Add the "current-1" token (just taken) as a child of node */
static bool add_prev_token(Parser *p, Node *n) {
    return node_add_child_token(n, p->idx - 1);
}

/* Add a specific token index as a child */
static bool add_token_idx(Node *n, int idx) {
    return node_add_child_token(n, idx);
}

/* ---- parse_expr: precedence climbing ---- */

static bool compare_prec(const char *op, int prec) {
    int op_prec = get_binop_prec(op);
    if (op_prec < 0) return false;
    if (prec < 0) return true;  /* prec == NONE means accept anything */
    if (is_right_binop(op))
        return prec <= op_prec;
    else
        return prec < op_prec;
}

/* parse_core_expr: port of parse_core_expr from pico_parse.py */
static Node *parse_core_expr(Parser *p) {
    if (p->failed) return NULL;

    Token *token = p_take(p);
    if (!token->value) {
        /* Hit sentinel/end of input */
        p->failed = true;
        return NULL;
    }
    const char *value = token->value;
    int tok_idx = p->idx - 1;

    /* nil, true, false, number, string → const node */
    if (strcmp(value, "nil") == 0 || strcmp(value, "true") == 0 || strcmp(value, "false") == 0 ||
        token->type == TT_NUMBER || token->type == TT_STRING) {
        Node *n = make_node(p, NT_CONST);
        if (!n) return NULL;
        add_token_idx(n, tok_idx);
        return n;
    }

    /* { → table */
    if (strcmp(value, "{") == 0) {
        return parse_table(p);
    }

    /* ( expr ) → group */
    if (strcmp(value, "(") == 0) {
        Node *expr = parse_expr(p, -1);
        if (p->failed) return NULL;
        if (!p_require(p, ")")) return NULL;
        Node *n = make_node(p, NT_GROUP);
        if (!n) return NULL;
        add_token_idx(n, tok_idx);       /* ( */
        node_add_child_node(n, expr);
        add_prev_token(p, n);            /* ) */
        return n;
    }

    /* Unary operators */
    if (is_unary_op(value)) {
        Node *expr = parse_expr(p, K_UNARY_OPS_PREC);
        if (p->failed) return NULL;
        Node *n = make_node(p, NT_UNARY_OP);
        if (!n) return NULL;
        add_token_idx(n, tok_idx);
        node_add_child_node(n, expr);
        return n;
    }

    /* ? → print shorthand */
    if (strcmp(value, "?") == 0) {
        return parse_print(p);
    }

    /* function (as expression, not statement) */
    if (strcmp(value, "function") == 0) {
        return parse_function(p, false, false);
    }

    /* ... → varargs */
    if (strcmp(value, "...") == 0) {
        Node *n = make_node(p, NT_VARARGS);
        if (!n) return NULL;
        add_token_idx(n, tok_idx);
        return n;
    }

    /* Identifier → var */
    if (token->type == TT_IDENT) {
        Node *n = make_node(p, NT_VAR);
        if (!n) return NULL;
        add_token_idx(n, tok_idx);
        return n;
    }

    /* Unknown expression */
    p->failed = true;
    return NULL;
}

/* parse_expr: precedence climbing, with suffix parsing (. [] () : {}) */
static Node *parse_expr(Parser *p, int prec) {
    if (p->failed) return NULL;
    Node *expr = parse_core_expr(p);
    if (p->failed || !expr) return NULL;

    while (!p->failed) {
        Token *token = p_take(p);
        if (!token->value) {
            /* Hit sentinel — don't put back, idx is clamped at sentinel */
            break;
        }
        const char *value = token->value;
        int tok_idx = p->idx - 1;

        /* . member access */
        if (strcmp(value, ".") == 0 && is_prefix_type(expr->type)) {
            Token *var_tok = p_take(p);
            if (!var_tok || var_tok->type != TT_IDENT) { p->failed = true; return NULL; }
            Node *var_node = make_node(p, NT_VAR);
            if (!var_node) return NULL;
            add_token_idx(var_node, p->idx - 1);

            Node *n = make_node(p, NT_MEMBER);
            if (!n) return NULL;
            node_add_child_node(n, expr);
            add_token_idx(n, tok_idx);     /* . */
            node_add_child_node(n, var_node);
            expr = n;
            continue;
        }

        /* [ index ] */
        if (strcmp(value, "[") == 0 && is_prefix_type(expr->type)) {
            Node *index = parse_expr(p, -1);
            if (p->failed) return NULL;
            if (!p_require(p, "]")) return NULL;
            Node *n = make_node(p, NT_INDEX);
            if (!n) return NULL;
            node_add_child_node(n, expr);
            add_token_idx(n, tok_idx);     /* [ */
            node_add_child_node(n, index);
            add_prev_token(p, n);          /* ] */
            expr = n;
            continue;
        }

        /* ( call ) */
        if (strcmp(value, "(") == 0 && is_prefix_type(expr->type)) {
            expr = parse_call(p, expr);
            continue;
        }

        /* { or string literal as single-arg call */
        if ((strcmp(value, "{") == 0 || token->type == TT_STRING) && is_prefix_type(expr->type)) {
            p->idx--; /* put back */
            Node *arg = parse_core_expr(p);
            if (p->failed) return NULL;
            Node *n = make_node(p, NT_CALL);
            if (!n) return NULL;
            node_add_child_node(n, expr);
            node_add_child_node(n, arg);
            expr = n;
            continue;
        }

        /* : method call */
        if (strcmp(value, ":") == 0 && is_prefix_type(expr->type)) {
            Token *var_tok = p_take(p);
            if (!var_tok || var_tok->type != TT_IDENT) { p->failed = true; return NULL; }
            Node *var_node = make_node(p, NT_VAR);
            if (!var_node) return NULL;
            add_token_idx(var_node, p->idx - 1);

            Node *member = make_node(p, NT_MEMBER);
            if (!member) return NULL;
            node_add_child_node(member, expr);
            add_token_idx(member, tok_idx);   /* : */
            node_add_child_node(member, var_node);

            /* Check for { or string shorthand call */
            const char *pv = p_peek_val(p, 0);
            if (pv && (strcmp(pv, "{") == 0 || p_is_type(p, 0, TT_STRING))) {
                Node *arg = parse_core_expr(p);
                if (p->failed) return NULL;
                Node *n = make_node(p, NT_CALL);
                if (!n) return NULL;
                node_add_child_node(n, member);
                node_add_child_node(n, arg);
                expr = n;
            } else {
                if (!p_require(p, "(")) return NULL;
                expr = parse_call(p, member);
            }
            continue;
        }

        /* Binary operator */
        if (get_binop_prec(value) >= 0 && compare_prec(value, prec)) {
            Node *other = parse_expr(p, get_binop_prec(value));
            if (p->failed) return NULL;
            Node *n = make_node(p, NT_BINARY_OP);
            if (!n) return NULL;
            node_add_child_node(n, expr);
            add_token_idx(n, tok_idx);
            node_add_child_node(n, other);
            expr = n;
            continue;
        }

        /* Nothing matched — put token back */
        p->idx--;
        break;
    }

    return expr;
}

/* parse_call: already consumed '(' — parse args until ')' */
static Node *parse_call(Parser *p, Node *func_expr) {
    if (p->failed) return NULL;
    Node *n = make_node(p, NT_CALL);
    if (!n) return NULL;
    node_add_child_node(n, func_expr);
    add_prev_token(p, n);  /* ( */

    if (!p_accept(p, ")")) {
        while (!p->failed) {
            Node *arg = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, arg);
            if (p_accept(p, ")")) {
                add_prev_token(p, n);
                break;
            }
            if (!p_require(p, ",")) return NULL;
            add_prev_token(p, n);
        }
    } else {
        add_prev_token(p, n);  /* ) */
    }

    return n;
}

/* parse_table: already consumed '{' */
static Node *parse_table(Parser *p) {
    if (p->failed) return NULL;
    Node *n = make_node(p, NT_TABLE);
    if (!n) return NULL;
    add_prev_token(p, n);  /* { */

    while (!p->failed && !p_accept(p, "}")) {
        /* [expr] = expr */
        if (p_accept(p, "[")) {
            Node *item = make_node(p, NT_TABLE_INDEX);
            if (!item) return NULL;
            add_prev_token(p, item);       /* [ */
            Node *key = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(item, key);
            if (!p_require(p, "]")) return NULL;
            add_prev_token(p, item);       /* ] */
            if (!p_require(p, "=")) return NULL;
            add_prev_token(p, item);       /* = */
            Node *val = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(item, val);
            node_add_child_node(n, item);

        /* key = expr (identifier key, detected by peek(1) == "=") */
        } else if (p_is_type(p, 0, TT_IDENT) && p_peek_val(p, 1) && strcmp(p_peek_val(p, 1), "=") == 0) {
            Node *item = make_node(p, NT_TABLE_MEMBER);
            if (!item) return NULL;
            p_take(p); /* consume ident */
            add_prev_token(p, item);       /* key ident */
            if (!p_require(p, "=")) return NULL;
            add_prev_token(p, item);       /* = */
            Node *val = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(item, val);
            node_add_child_node(n, item);

        /* expr (positional) */
        } else {
            Node *val = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, val);
        }

        /* Accept separator */
        if (p_accept(p, "}")) {
            add_prev_token(p, n); /* } */
            return n;
        }
        if (p_accept(p, ",") || p_accept(p, ";")) {
            add_prev_token(p, n);  /* , or ; */
        } else {
            /* If no separator and next isn't }, error */
            const char *v = p_peek_val(p, 0);
            if (!v || strcmp(v, "}") != 0) {
                p->failed = true;
                return NULL;
            }
        }
    }

    if (!p->failed) {
        add_prev_token(p, n); /* } */
    }
    return n;
}

/* parse_print: ? args → call to "print" */
static Node *parse_print(Parser *p) {
    if (p->failed) return NULL;
    int q_idx = p->idx - 1; /* the ? token */

    Node *n = make_node(p, NT_CALL);
    if (!n) return NULL;
    n->short_flag = true; /* marks this as print shorthand */

    add_token_idx(n, q_idx); /* ? */

    /* Parse comma-separated args */
    while (!p->failed) {
        Node *arg = parse_expr(p, -1);
        if (p->failed) return NULL;
        node_add_child_node(n, arg);
        if (!p_accept(p, ",")) break;
    }

    return n;
}

/* parse_function */
static Node *parse_function(Parser *p, bool stmt, bool local) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_FUNCTION);
    if (!n) return NULL;

    /* 'local' keyword token if present */
    if (local) {
        add_token_idx(n, p->idx - 2); /* 'local' */
    }
    /* 'function' keyword token */
    add_token_idx(n, p->idx - 1);

    /* Target for statement form */
    if (stmt) {
        if (local) {
            /* local function name — name is a simple ident */
            Token *name_tok = p_take(p);
            if (!name_tok || name_tok->type != TT_IDENT) { p->failed = true; return NULL; }
            Node *target = make_node(p, NT_VAR);
            if (!target) return NULL;
            add_token_idx(target, p->idx - 1);
            n->target = target;
            node_add_child_node(n, target);
        } else {
            /* function target.member:method */
            Token *name_tok = p_take(p);
            if (!name_tok || name_tok->type != TT_IDENT) { p->failed = true; return NULL; }
            Node *target = make_node(p, NT_VAR);
            if (!target) return NULL;
            add_token_idx(target, p->idx - 1);

            while (p_accept(p, ".")) {
                int dot_idx = p->idx - 1;
                Token *key_tok = p_take(p);
                if (!key_tok || key_tok->type != TT_IDENT) { p->failed = true; return NULL; }
                Node *key = make_node(p, NT_VAR);
                if (!key) return NULL;
                add_token_idx(key, p->idx - 1);
                Node *mem = make_node(p, NT_MEMBER);
                if (!mem) return NULL;
                node_add_child_node(mem, target);
                add_token_idx(mem, dot_idx);
                node_add_child_node(mem, key);
                target = mem;
            }

            if (p_accept(p, ":")) {
                int colon_idx = p->idx - 1;
                Token *key_tok = p_take(p);
                if (!key_tok || key_tok->type != TT_IDENT) { p->failed = true; return NULL; }
                Node *key = make_node(p, NT_VAR);
                if (!key) return NULL;
                add_token_idx(key, p->idx - 1);
                Node *mem = make_node(p, NT_MEMBER);
                if (!mem) return NULL;
                node_add_child_node(mem, target);
                add_token_idx(mem, colon_idx);
                node_add_child_node(mem, key);
                target = mem;
            }

            n->target = target;
            node_add_child_node(n, target);
        }
    }

    /* Parameters: ( ... ) */
    if (!p_require(p, "(")) return NULL;
    add_prev_token(p, n);

    if (!p_accept(p, ")")) {
        while (!p->failed) {
            if (p_accept(p, "...")) {
                Node *va = make_node(p, NT_VARARGS);
                if (!va) return NULL;
                add_prev_token(p, va);
                node_add_child_node(n, va);
            } else {
                Token *param = p_take(p);
                if (!param || param->type != TT_IDENT) { p->failed = true; return NULL; }
                Node *pn = make_node(p, NT_VAR);
                if (!pn) return NULL;
                add_token_idx(pn, p->idx - 1);
                node_add_child_node(n, pn);
            }
            if (p_accept(p, ")")) {
                add_prev_token(p, n);
                break;
            }
            if (!p_require(p, ",")) return NULL;
            add_prev_token(p, n);
        }
    } else {
        add_prev_token(p, n); /* ) */
    }

    /* Body */
    Node *body = parse_block(p, VLINE_NONE, false, NULL);
    if (p->failed) return NULL;
    n->body = body;
    node_add_child_node(n, body);

    /* end */
    if (!p_require(p, "end")) return NULL;
    add_prev_token(p, n);

    return n;
}

/* parse_if / parse_elseif */
static Node *parse_if(Parser *p, NodeType type) {
    if (p->failed) return NULL;

    Node *n = make_node(p, type);
    if (!n) return NULL;

    /* The 'if' or 'elseif' keyword was already consumed */
    add_token_idx(n, p->idx - 1);

    /* condition */
    Node *cond = parse_expr(p, -1);
    if (p->failed) return NULL;
    n->cond = cond;
    node_add_child_node(n, cond);

    n->else_node = NULL;
    n->short_flag = false;

    /* 'then' or 'do' (PICO-8 accepts 'do' as synonym for 'then' in if) */
    if (p_accept(p, "then") || p_accept(p, "do")) {
        add_prev_token(p, n);

        /* Long-form if */
        Node *then_block = parse_block(p, VLINE_NONE, false, NULL);
        if (p->failed) return NULL;
        n->then_block = then_block;
        node_add_child_node(n, then_block);

        if (p_accept(p, "else")) {
            int else_kw = p->idx - 1;
            Node *else_body = parse_block(p, VLINE_NONE, false, NULL);
            if (p->failed) return NULL;
            if (!p_require(p, "end")) return NULL;

            Node *else_node = make_node(p, NT_ELSE);
            if (!else_node) return NULL;
            add_token_idx(else_node, else_kw);
            else_node->body = else_body;
            node_add_child_node(else_node, else_body);
            add_prev_token(p, else_node); /* end */
            else_node->short_flag = false;

            n->else_node = else_node;
            node_add_child_node(n, else_node);

        } else if (p_accept(p, "elseif")) {
            Node *elseif = parse_if(p, NT_ELSEIF);
            if (p->failed) return NULL;
            n->else_node = elseif;
            node_add_child_node(n, elseif);

        } else {
            if (!p_require(p, "end")) return NULL;
            add_prev_token(p, n);
        }

    } else {
        /* Shorthand if: condition ended with ')' and we're on the same vline.
         * Check that the previous token (last of cond) was ')'. */
        Token *prev = p_peek(p, -1);
        if (prev && prev->value && strcmp(prev->value, ")") == 0) {
            int vline = prev->vline;

            Node *then_block = parse_block(p, vline, false, NULL);
            if (p->failed) return NULL;
            n->then_block = then_block;
            node_add_child_node(n, then_block);

            /* Check for shorthand else on same vline */
            Token *next = p_peek0(p);
            if (next && next->vline == vline && next->value && strcmp(next->value, "else") == 0) {
                p_take(p); /* consume 'else' */
                int else_kw = p->idx - 1;
                Node *else_body = parse_block(p, vline, false, NULL);
                if (p->failed) return NULL;

                Node *else_node = make_node(p, NT_ELSE);
                if (!else_node) return NULL;
                add_token_idx(else_node, else_kw);
                else_node->body = else_body;
                node_add_child_node(else_node, else_body);
                /* short_state: k_nested if peek().vline == vline, else true */
                Token *pnext = p_peek0(p);
                else_node->short_flag = (pnext && pnext->vline == vline) ? SHORT_NESTED : true;

                n->else_node = else_node;
                node_add_child_node(n, else_node);
            }

            /* short_state */
            Token *pnext = p_peek0(p);
            n->short_flag = (pnext && pnext->vline == vline) ? SHORT_NESTED : true;
        } else {
            /* Not a valid if — "then or shorthand required" */
            p->failed = true;
            return NULL;
        }
    }

    return n;
}

/* parse_while */
static Node *parse_while_stmt(Parser *p) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_WHILE);
    if (!n) return NULL;
    add_token_idx(n, p->idx - 1); /* 'while' keyword */

    Node *cond = parse_expr(p, -1);
    if (p->failed) return NULL;
    n->cond = cond;
    node_add_child_node(n, cond);
    n->short_flag = false;

    if (p_accept(p, "do")) {
        add_prev_token(p, n);
        Node *body = parse_block(p, VLINE_NONE, false, NULL);
        if (p->failed) return NULL;
        n->body = body;
        node_add_child_node(n, body);
        if (!p_require(p, "end")) return NULL;
        add_prev_token(p, n);
    } else {
        /* Shorthand while — condition must end with ')' */
        Token *prev = p_peek(p, -1);
        if (prev && prev->value && strcmp(prev->value, ")") == 0) {
            int vline = prev->vline;
            Node *body = parse_block(p, vline, false, NULL);
            if (p->failed) return NULL;
            n->body = body;
            node_add_child_node(n, body);
            Token *pnext = p_peek0(p);
            n->short_flag = (pnext && pnext->vline == vline) ? SHORT_NESTED : true;
        } else {
            p->failed = true;
            return NULL;
        }
    }

    return n;
}

/* parse_repeat */
static Node *parse_repeat(Parser *p) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_REPEAT);
    if (!n) return NULL;
    add_token_idx(n, p->idx - 1); /* 'repeat' */

    Node *until_node = NULL;
    Node *body = parse_block(p, VLINE_NONE, true, &until_node);
    if (p->failed) return NULL;
    n->body = body;
    n->until_node = until_node;
    node_add_child_node(n, body);
    if (until_node) node_add_child_node(n, until_node);

    return n;
}

/* parse_for */
static Node *parse_for_stmt(Parser *p) {
    if (p->failed) return NULL;

    int for_kw = p->idx - 1;

    /* Peek ahead: is it "name =" (numeric for) or "name, ..." / "name in" (for-in)? */
    const char *v1 = p_peek_val(p, 1);
    if (v1 && strcmp(v1, "=") == 0) {
        /* Numeric for: for name = min, max [, step] do ... end */
        Node *n = make_node(p, NT_FOR);
        if (!n) return NULL;
        add_token_idx(n, for_kw);

        /* target */
        Token *name = p_take(p);
        if (!name || name->type != TT_IDENT) { p->failed = true; return NULL; }
        Node *target_var = make_node(p, NT_VAR);
        if (!target_var) return NULL;
        add_token_idx(target_var, p->idx - 1);
        n->target = target_var;
        node_add_child_node(n, target_var);

        if (!p_require(p, "=")) return NULL;
        add_prev_token(p, n);

        /* min */
        Node *min_expr = parse_expr(p, -1);
        if (p->failed) return NULL;
        node_add_child_node(n, min_expr);

        if (!p_require(p, ",")) return NULL;
        add_prev_token(p, n);

        /* max */
        Node *max_expr = parse_expr(p, -1);
        if (p->failed) return NULL;
        node_add_child_node(n, max_expr);

        /* optional step */
        if (p_accept(p, ",")) {
            add_prev_token(p, n);
            Node *step = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, step);
        }

        if (!p_require(p, "do")) return NULL;
        add_prev_token(p, n);

        Node *body = parse_block(p, VLINE_NONE, false, NULL);
        if (p->failed) return NULL;
        n->body = body;
        node_add_child_node(n, body);

        if (!p_require(p, "end")) return NULL;
        add_prev_token(p, n);

        return n;
    } else {
        /* For-in: for name[, name...] in expr[, expr...] do ... end */
        Node *n = make_node(p, NT_FOR_IN);
        if (!n) return NULL;
        add_token_idx(n, for_kw);

        /* targets */
        while (!p->failed) {
            Token *name = p_take(p);
            if (!name || name->type != TT_IDENT) { p->failed = true; return NULL; }
            Node *var = make_node(p, NT_VAR);
            if (!var) return NULL;
            add_token_idx(var, p->idx - 1);
            node_add_child_node(n, var);
            if (!p_accept(p, ",")) break;
            add_prev_token(p, n);
        }

        if (!p_require(p, "in")) return NULL;
        add_prev_token(p, n);

        /* sources */
        while (!p->failed) {
            Node *src = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, src);
            if (!p_accept(p, ",")) break;
            add_prev_token(p, n);
        }

        if (!p_require(p, "do")) return NULL;
        add_prev_token(p, n);

        Node *body = parse_block(p, VLINE_NONE, false, NULL);
        if (p->failed) return NULL;
        n->body = body;
        node_add_child_node(n, body);

        if (!p_require(p, "end")) return NULL;
        add_prev_token(p, n);

        return n;
    }
}

/* parse_return */
static Node *parse_return_stmt(Parser *p, int vline) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_RETURN);
    if (!n) return NULL;
    add_token_idx(n, p->idx - 1); /* 'return' */

    /* Check if there are return values */
    const char *pv = p_peek_val(p, 0);
    bool at_block_end = false;
    if (!pv) {
        at_block_end = true;
    } else if (is_block_end(pv) || strcmp(pv, ";") == 0) {
        at_block_end = true;
    } else if (vline != VLINE_NONE) {
        Token *t = p_peek0(p);
        if (t && t->vline > vline) at_block_end = true;
    }

    if (!at_block_end) {
        /* Parse return values */
        while (!p->failed) {
            Node *val = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, val);
            if (!p_accept(p, ",")) break;
            add_prev_token(p, n);
        }
    }

    return n;
}

/* parse_local */
static Node *parse_local(Parser *p) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_LOCAL);
    if (!n) return NULL;
    add_token_idx(n, p->idx - 1); /* 'local' */

    /* targets */
    while (!p->failed) {
        Token *name = p_take(p);
        if (!name || name->type != TT_IDENT) { p->failed = true; return NULL; }
        Node *var = make_node(p, NT_VAR);
        if (!var) return NULL;
        add_token_idx(var, p->idx - 1);
        node_add_child_node(n, var);
        if (!p_accept(p, ",")) break;
        add_prev_token(p, n);
    }

    /* optional assignment */
    if (p_accept(p, "=")) {
        add_prev_token(p, n);
        while (!p->failed) {
            Node *val = parse_expr(p, -1);
            if (p->failed) return NULL;
            node_add_child_node(n, val);
            if (!p_accept(p, ",")) break;
            add_prev_token(p, n);
        }
    }

    return n;
}

/* parse_assign: first expr already parsed, saw ',' or '=' */
static Node *parse_assign(Parser *p, Node *first) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_ASSIGN);
    if (!n) return NULL;
    node_add_child_node(n, first);

    /* Additional targets */
    while (p_accept(p, ",")) {
        add_prev_token(p, n);
        Node *target = parse_expr(p, -1);
        if (p->failed) return NULL;
        node_add_child_node(n, target);
    }

    if (!p_require(p, "=")) return NULL;
    add_prev_token(p, n);

    /* sources */
    while (!p->failed) {
        Node *val = parse_expr(p, -1);
        if (p->failed) return NULL;
        node_add_child_node(n, val);
        if (!p_accept(p, ",")) break;
        add_prev_token(p, n);
    }

    return n;
}

/* parse_opassign: compound assign like +=, -=, etc. */
static Node *parse_opassign(Parser *p, Node *first) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_OP_ASSIGN);
    if (!n) return NULL;
    node_add_child_node(n, first);
    add_token_idx(n, p->idx);  /* the op= token */
    p->idx++;  /* consume it */

    Node *source = parse_expr(p, -1);
    if (p->failed) return NULL;
    node_add_child_node(n, source);

    return n;
}

/* parse_misc_stmt: expression statement or assignment */
static Node *parse_misc_stmt(Parser *p) {
    if (p->failed) return NULL;

    p->idx--;  /* put back the token we took in parse_stmt */
    Node *first = parse_expr(p, -1);
    if (p->failed) return NULL;

    const char *pv = p_peek_val(p, 0);
    if (pv && (strcmp(pv, ",") == 0 || strcmp(pv, "=") == 0)) {
        return parse_assign(p, first);
    }
    /* Check for compound assign: value ends with '=' */
    if (pv) {
        size_t pvlen = strlen(pv);
        if (pvlen >= 2 && pv[pvlen - 1] == '=') {
            return parse_opassign(p, first);
        }
    }

    /* Must be a call expression (expression statement) */
    if (first->type == NT_CALL) {
        return first;
    }

    /* Expression with no side effect — skip it but don't fail hard */
    return first;
}

/* parse_stmt */
static Node *parse_stmt(Parser *p, int vline) {
    if (p->failed) return NULL;

    Token *token = p_take(p);
    if (!token->value) return NULL;  /* sentinel — idx clamped, just return */
    const char *value = token->value;

    if (strcmp(value, ";") == 0) {
        /* Semicolon — we still need it in the tree for proper traversal,
         * but the unminifier will skip it. Return as a simple token-only node. */
        return NULL;  /* skip, like the Python */
    }

    if (strcmp(value, "do") == 0) {
        Node *n = make_node(p, NT_DO);
        if (!n) return NULL;
        add_token_idx(n, p->idx - 1);
        Node *body = parse_block(p, VLINE_NONE, false, NULL);
        if (p->failed) return NULL;
        n->body = body;
        node_add_child_node(n, body);
        if (!p_require(p, "end")) return NULL;
        add_prev_token(p, n);
        return n;
    }

    if (strcmp(value, "if") == 0) {
        return parse_if(p, NT_IF);
    }

    if (strcmp(value, "while") == 0) {
        return parse_while_stmt(p);
    }

    if (strcmp(value, "repeat") == 0) {
        return parse_repeat(p);
    }

    if (strcmp(value, "for") == 0) {
        return parse_for_stmt(p);
    }

    if (strcmp(value, "break") == 0) {
        Node *n = make_node(p, NT_BREAK);
        if (!n) return NULL;
        add_token_idx(n, p->idx - 1);
        return n;
    }

    if (strcmp(value, "return") == 0) {
        return parse_return_stmt(p, vline);
    }

    if (strcmp(value, "local") == 0) {
        if (p_accept(p, "function")) {
            return parse_function(p, true, true);
        }
        return parse_local(p);
    }

    if (strcmp(value, "goto") == 0) {
        Token *lbl = p_take(p);
        if (!lbl || lbl->type != TT_IDENT) { p->failed = true; return NULL; }
        Node *n = make_node(p, NT_GOTO);
        if (!n) return NULL;
        add_token_idx(n, p->idx - 2); /* goto */
        Node *label_var = make_node(p, NT_VAR);
        if (!label_var) return NULL;
        add_token_idx(label_var, p->idx - 1);
        node_add_child_node(n, label_var);
        return n;
    }

    if (strcmp(value, "::") == 0) {
        Token *lbl = p_take(p);
        if (!lbl || lbl->type != TT_IDENT) { p->failed = true; return NULL; }
        Node *n = make_node(p, NT_LABEL);
        if (!n) return NULL;
        add_token_idx(n, p->idx - 2); /* :: */
        Node *label_var = make_node(p, NT_VAR);
        if (!label_var) return NULL;
        add_token_idx(label_var, p->idx - 1);
        node_add_child_node(n, label_var);
        if (!p_require(p, "::")) return NULL;
        add_prev_token(p, n);
        return n;
    }

    if (strcmp(value, "function") == 0) {
        return parse_function(p, true, false);
    }

    return parse_misc_stmt(p);
}

/* parse_block */
static Node *parse_block(Parser *p, int vline, bool with_until, Node **until_out) {
    if (p->failed) return NULL;

    Node *n = make_node(p, NT_BLOCK);
    if (!n) return NULL;

    while (!p->failed) {
        Token *t = p_peek0(p);
        if (!t->value) break;       /* sentinel = end of input */

        /* If vline is set, stop when next token is on a later line */
        if (vline != VLINE_NONE && t->vline > vline) break;

        /* Stop at block-ending keywords */
        if (is_block_end(t->value)) break;

        Node *stmt = parse_stmt(p, vline);
        if (p->failed) return NULL;
        if (stmt) {
            node_add_child_node(n, stmt);
        }
        /* else: it was a semicolon or something we skip */
    }

    /* Handle 'until' for repeat..until */
    if (with_until && !p->failed) {
        if (!p_require(p, "until")) return NULL;
        Node *until = make_node(p, NT_UNTIL);
        if (!until) return NULL;
        add_prev_token(p, until); /* 'until' */
        Node *cond = parse_expr(p, -1);
        if (p->failed) return NULL;
        until->cond = cond;
        node_add_child_node(until, cond);
        if (until_out) *until_out = until;
    }

    return n;
}

/* ================================================================
 *  UNMINIFIER
 *  Port of unminify_code() from pico_unminify.py
 * ================================================================ */

/* Check if a node is a shorthand block stmt (if/else/while with short_flag) */
static bool is_short_block_stmt(Node *n) {
    if (!n) return false;
    return n->short_flag && (n->type == NT_IF || n->type == NT_ELSE ||
                             n->type == NT_WHILE || n->type == NT_ELSEIF);
}

/* Check if a node is a function statement (function with a target) */
static bool is_function_stmt_node(Node *n) {
    return n && n->type == NT_FUNCTION && n->target != NULL;
}

/* Tight token lists for whitespace rules */
static bool is_tight_prefix(const char *v) {
    return v && (strcmp(v, "(") == 0 || strcmp(v, "[") == 0 || strcmp(v, "{") == 0 ||
                 strcmp(v, "?") == 0 || strcmp(v, ".") == 0 || strcmp(v, ":") == 0 ||
                 strcmp(v, "::") == 0);
}

static bool is_tight_suffix(const char *v) {
    return v && (strcmp(v, ")") == 0 || strcmp(v, "]") == 0 || strcmp(v, "}") == 0 ||
                 strcmp(v, ",") == 0 || strcmp(v, ";") == 0 || strcmp(v, ".") == 0 ||
                 strcmp(v, ":") == 0 || strcmp(v, "::") == 0);
}

typedef struct {
    Buf         *out;
    TokenArray  *tokens;
    const char  *prev_value;
    TokenType    prev_type;
    bool         prev_tight;
    int          indent;
    const char  *indent_str;
    size_t       indent_str_len;

    /* Statement tracking for blank lines between functions */
    Node        *curr_stmt;
    Node       **stmt_stack;
    int          stmt_stack_count;
    int          stmt_stack_cap;

    /* Parent tracking for context-dependent output */
    Node        *parent_node; /* for unary_op check on prev token */
} Unminifier;

static void unmin_init(Unminifier *u, Buf *out, TokenArray *tokens) {
    memset(u, 0, sizeof(*u));
    u->out = out;
    u->tokens = tokens;
    u->prev_value = NULL;
    u->prev_type = TT_NONE;
    u->prev_tight = false;
    u->indent = 0;
    u->indent_str = "  ";
    u->indent_str_len = 2;
    u->curr_stmt = NULL;
    u->stmt_stack = NULL;
    u->stmt_stack_count = 0;
    u->stmt_stack_cap = 0;
    u->parent_node = NULL;
}

static void unmin_free(Unminifier *u) {
    free(u->stmt_stack);
}

static void unmin_emit_indent(Unminifier *u) {
    buf_append_repeat(u->out, u->indent_str, u->indent_str_len, u->indent);
}

/* Emit a token value, with proper whitespace before it.
 * Port of visit_token() from pico_unminify.py */
static void unmin_visit_token(Unminifier *u, int token_idx, Node *parent) {
    if (token_idx < 0 || token_idx >= u->tokens->count) return;
    Token *token = &u->tokens->items[token_idx];
    if (!token->value) return;

    const char *value = token->value;

    /* Ignore shorthand parens: if parent is a short if/while/elseif's cond,
     * skip the outer ( and ) to avoid inflating token count */
    if (parent && parent->parent) {
        Node *gparent = parent->parent;
        if (is_short_block_stmt(gparent) && parent == gparent->cond) {
            if (strcmp(value, "(") == 0 || strcmp(value, ")") == 0) {
                return;
            }
        }
    }

    /* Ignore semicolons inside blocks */
    if (parent && parent->type == NT_BLOCK && strcmp(value, ";") == 0) {
        return;
    }

    /* "do" in if/elseif → "then" */
    if (strcmp(value, "do") == 0 && parent &&
        (parent->type == NT_IF || parent->type == NT_ELSEIF)) {
        value = "then";
    }

    /* Whitespace insertion rules (lines 54-59 of pico_unminify.py) */
    if (u->prev_tight &&
        !is_tight_prefix(u->prev_value) &&
        !is_tight_suffix(value) &&
        !(  (strcmp(value, "(") == 0 || strcmp(value, "[") == 0) &&
            (u->prev_type == TT_IDENT || (u->prev_value &&
             (strcmp(u->prev_value, "function") == 0 ||
              strcmp(u->prev_value, ")") == 0 ||
              strcmp(u->prev_value, "]") == 0 ||
              strcmp(u->prev_value, "}") == 0)))) &&
        !(  u->prev_type == TT_PUNCT && u->parent_node &&
            u->parent_node->type == NT_UNARY_OP)) {
        buf_appendc(u->out, ' ');
    }

    buf_appends(u->out, value);
    u->prev_value = token->value; /* points into token's malloc'd string */
    u->prev_type = token->type;
    u->prev_tight = true;
    u->parent_node = parent;
}

/* Forward declarations for traversal */
static void unmin_traverse_node(Unminifier *u, Node *node);

/* visit_node: called before processing children */
static void unmin_visit_node(Unminifier *u, Node *node) {
    if (node->type == NT_BLOCK) {
        if (node->parent) {
            u->indent++;

            /* shorthand → longhand: insert "then" or "do" */
            if (is_short_block_stmt(node->parent) && node->parent->type != NT_ELSE) {
                if (node->parent->type == NT_IF || node->parent->type == NT_ELSEIF) {
                    buf_appends(u->out, " then");
                } else {
                    buf_appends(u->out, " do");
                }
            }
        }

        /* Push stmt_stack */
        DA_PUSH(u->stmt_stack, u->stmt_stack_count, u->stmt_stack_cap, u->curr_stmt, done);
done:
        u->curr_stmt = NULL;
        buf_appendc(u->out, '\n');
        u->prev_tight = false;
        return;
    }

    if (u->curr_stmt == NULL) {
        /* Blank line before function statements (if previous was not also a function) */
        if (is_function_stmt_node(node) && node->parent) {
            /* Find our index in parent's children */
            for (int i = 0; i < node->parent->num_children; i++) {
                if (node->parent->children[i].tag == CHILD_NODE &&
                    node->parent->children[i].node == node) {
                    if (i > 0) {
                        /* Check if previous sibling was a function stmt */
                        for (int j = i - 1; j >= 0; j--) {
                            if (node->parent->children[j].tag == CHILD_NODE) {
                                if (!is_function_stmt_node(node->parent->children[j].node)) {
                                    buf_appendc(u->out, '\n');
                                }
                                break;
                            }
                        }
                    }
                    break;
                }
            }
        }

        u->curr_stmt = node;
        unmin_emit_indent(u);
        u->prev_tight = false;
    }
}

/* end_visit_node: called after processing children */
static void unmin_end_visit_node(Unminifier *u, Node *node) {
    if (node->type == NT_BLOCK) {
        if (node->parent) {
            u->indent--;
        }

        /* Pop stmt_stack */
        if (u->stmt_stack_count > 0) {
            u->curr_stmt = u->stmt_stack[--u->stmt_stack_count];
        } else {
            u->curr_stmt = NULL;
        }

        unmin_emit_indent(u);
        u->prev_tight = false;

        /* shorthand → longhand: insert "end" if needed */
        if (node->parent && is_short_block_stmt(node->parent)) {
            /* Don't add "end" if this is an if with an else (else will have its own end) */
            if (node->parent->type == NT_IF && node->parent->else_node) {
                /* Don't emit end here — the else/elseif chain handles it */
            } else {
                buf_appends(u->out, "end");
            }
        }
        return;
    }

    if (node == u->curr_stmt) {
        u->curr_stmt = NULL;
        buf_appendc(u->out, '\n');
        u->prev_tight = false;

        if (is_function_stmt_node(node)) {
            buf_appendc(u->out, '\n');
        }
    }
}

/* Override traversal for special node types */
static void unmin_traverse_node(Unminifier *u, Node *node) {
    if (!node) return;

    /* Print shorthand: emit "print(" args ")" instead of "? args" */
    if (node->type == NT_CALL && node->short_flag) {
        unmin_visit_node(u, node);

        /* Emit "print(" */
        if (u->prev_tight) buf_appendc(u->out, ' ');
        buf_appends(u->out, "print(");
        u->prev_value = "(";
        u->prev_type = TT_PUNCT;
        u->prev_tight = true;

        /* Emit args with commas */
        bool first = true;
        for (int i = 0; i < node->num_children; i++) {
            Child *c = &node->children[i];
            if (c->tag == CHILD_TOKEN) continue; /* skip the ? token */
            if (c->tag == CHILD_NODE) {
                if (!first) {
                    buf_appends(u->out, ",");
                    u->prev_value = ",";
                    u->prev_type = TT_PUNCT;
                    u->prev_tight = true;
                }
                unmin_traverse_node(u, c->node);
                first = false;
            }
        }

        buf_appendc(u->out, ')');
        u->prev_value = ")";
        u->prev_type = TT_PUNCT;
        u->prev_tight = true;

        unmin_end_visit_node(u, node);
        return;
    }

    /* Default traversal */
    unmin_visit_node(u, node);

    for (int i = 0; i < node->num_children; i++) {
        Child *c = &node->children[i];
        if (c->tag == CHILD_TOKEN) {
            unmin_visit_token(u, c->token_idx, node);
        } else if (c->tag == CHILD_NODE) {
            unmin_traverse_node(u, c->node);
        }
    }

    unmin_end_visit_node(u, node);
}

/* ================================================================
 *  Public API
 * ================================================================ */
char *p8_shrinko_unminify(const char *src, size_t len, size_t *out_len) {
    TokenArray tokens;
    tkarr_init(&tokens);

    /* Phase 1: Tokenize */
    if (!tokenize(src, len, &tokens)) {
        tkarr_free(&tokens);
        return NULL;
    }

    if (tokens.count == 0) {
        /* Empty input → empty output */
        tkarr_free(&tokens);
        char *result = (char *)malloc(1);
        if (!result) return NULL;
        result[0] = '\0';
        if (out_len) *out_len = 0;
        return result;
    }

    /* Append sentinel token (TT_NONE, value=NULL) for safe parser access */
    tkarr_addn(&tokens, TT_NONE, NULL, 0, tokens.items[tokens.count - 1].vline);

    /* Phase 2: Parse */
    NodeArena arena;
    arena_init(&arena);

    Parser parser;
    parser.tokens = &tokens;
    parser.arena = &arena;
    parser.idx = 0;
    parser.failed = false;

    Node *root = parse_block(&parser, VLINE_NONE, false, NULL);

    if (parser.failed || !root) {
        arena_free(&arena);
        tkarr_free(&tokens);
        return NULL;
    }

    /* Phase 3: Unminify */
    Buf out;
    buf_init(&out);

    Unminifier unmin;
    unmin_init(&unmin, &out, &tokens);

    unmin_traverse_node(&unmin, root);

    unmin_free(&unmin);

    /* NUL-terminate */
    if (!buf_appendc(&out, '\0')) {
        buf_free(&out);
        arena_free(&arena);
        tkarr_free(&tokens);
        return NULL;
    }

    /* Transfer ownership of the buffer.
     * Strip leading and trailing whitespace for clean output. */
    char *result = out.data;
    size_t result_len = out.len - 1; /* exclude NUL */
    out.data = NULL; /* prevent buf_free from freeing it */

    arena_free(&arena);
    tkarr_free(&tokens);

    /* Trim leading newlines */
    size_t start = 0;
    while (start < result_len && result[start] == '\n') start++;
    /* Trim trailing whitespace */
    while (result_len > start && (result[result_len - 1] == '\n' || result[result_len - 1] == ' ')) result_len--;

    if (start > 0) {
        memmove(result, result + start, result_len - start);
        result_len -= start;
    }
    result[result_len] = '\0';

    if (out_len) *out_len = result_len;
    return result;
}
