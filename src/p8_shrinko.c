/*
 * ThumbyP8 — PICO-8 tokenizer, parser, and unminifier (C port of shrinko8).
 *
 * STREAMING implementation: tokenize, parse, and emit formatted output in a
 * single pass.  No token array, no AST nodes, no arena allocator.
 *
 * Faithful port of:
 *   tools/shrinko8/pico_tokenize.py  — tokenize()
 *   tools/shrinko8/pico_parse.py     — parse()
 *   tools/shrinko8/pico_unminify.py  — unminify_code()
 *
 * PICO-8 only (no Picotron code paths). No scope/variable tracking.
 * Memory budget: ~60-80KB peak (source + output buffer + small scratch).
 */

#include "p8_shrinko.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include <ctype.h>

/* ================================================================
 *  Growable output buffer
 * ================================================================ */
typedef struct {
    char  *data;
    size_t len;
    size_t cap;
} Buf;

static void buf_init(Buf *b) {
    b->data = NULL; b->len = 0; b->cap = 0;
}

static bool buf_grow(Buf *b, size_t need) {
    if (b->len + need <= b->cap) return true;
    size_t nc = b->cap ? b->cap * 2 : 256;
    while (nc < b->len + need) nc *= 2;
    char *p = (char *)realloc(b->data, nc);
    if (!p) return false;
    b->data = p; b->cap = nc;
    return true;
}

static bool buf_append(Buf *b, const char *s, size_t n) {
    if (!buf_grow(b, n)) return false;
    memcpy(b->data + b->len, s, n); b->len += n;
    return true;
}
static bool buf_appends(Buf *b, const char *s) { return buf_append(b, s, strlen(s)); }
static bool buf_appendc(Buf *b, char c) { return buf_append(b, &c, 1); }
static bool buf_appendn(Buf *b, const char *s, int n) { return buf_append(b, s, (size_t)n); }
static void buf_free(Buf *b) { free(b->data); b->data = NULL; b->len = b->cap = 0; }

/* ================================================================
 *  Token types
 * ================================================================ */
typedef enum {
    TT_NONE = 0, TT_NUMBER, TT_STRING, TT_IDENT, TT_KEYWORD, TT_PUNCT,
} TokenType;

/* Token: a slice of the source string */
typedef struct {
    TokenType type;
    int       off;    /* offset into source */
    int       len;
    int       vline;
} Token;

static bool tok_eq(const Token *t, const char *src, const char *val) {
    int vl = (int)strlen(val);
    return t->len == vl && memcmp(src + t->off, val, (size_t)vl) == 0;
}

/* ================================================================
 *  Character / keyword helpers
 * ================================================================ */
static bool is_ident_char(unsigned char ch) {
    return (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'z') ||
           (ch >= 'A' && ch <= 'Z') || ch == '_' ||
           ch == 0x1e || ch == 0x1f || ch >= 0x80;
}

static bool is_wspace(char ch) {
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
}

static bool is_keyword_n(const char *s, int len) {
    static const char *kw[] = {
        "and","break","do","else","elseif","end","false","for","function",
        "goto","if","in","local","nil","not","or","repeat","return","then",
        "true","until","while",NULL
    };
    for (int i = 0; kw[i]; i++) {
        int kl = (int)strlen(kw[i]);
        if (kl == len && memcmp(s, kw[i], (size_t)len) == 0) return true;
    }
    return false;
}

/* Binary operator precedence */
static int get_binop_prec(const char *s, int off, int len) {
    static const struct { const char *op; int prec; } t[] = {
        {"or",1},{"and",2},{"!=",3},{"~=",3},{"==",3},{"<",3},{"<=",3},{">",3},{">=",3},
        {"|",4},{"^^",5},{"~",5},{"&",6},{"<<",7},{">>",7},{">>>",7},{">><",7},{"<<>",7},
        {"..",8},{"+",9},{"-",9},{"*",10},{"/",10},{"//",10},{"\\",10},{"%",10},{"^",12},{NULL,0}
    };
    for (int i = 0; t[i].op; i++) {
        int ol = (int)strlen(t[i].op);
        if (ol == len && memcmp(s + off, t[i].op, (size_t)len) == 0) return t[i].prec;
    }
    return -1;
}

static bool is_right_binop(const char *s, int off, int len) {
    return (len == 1 && s[off] == '^') || (len == 2 && s[off] == '.' && s[off+1] == '.');
}

#define K_UNARY_OPS_PREC 11

static bool is_unary_op(const char *s, int off, int len) {
    if (len == 1) { char c = s[off]; return c=='-'||c=='~'||c=='#'||c=='@'||c=='%'||c=='$'; }
    if (len == 3 && memcmp(s+off,"not",3)==0) return true;
    return false;
}

static bool is_block_end(const char *s, int off, int len) {
    if (len==3 && memcmp(s+off,"end",3)==0) return true;
    if (len==4 && memcmp(s+off,"else",4)==0) return true;
    if (len==6 && memcmp(s+off,"elseif",6)==0) return true;
    if (len==5 && memcmp(s+off,"until",5)==0) return true;
    return false;
}

/* ================================================================
 *  Streaming Tokenizer (2-token lookahead ring buffer)
 * ================================================================ */
#define TOK_BUF_SIZE 2

typedef struct {
    const char *src;
    int         src_len, pos, vline;
    Token       buf[TOK_BUF_SIZE];
    int         buf_count, buf_start;
} Lexer;

static void lex_init(Lexer *L, const char *src, int src_len) {
    memset(L, 0, sizeof(*L));
    L->src = src; L->src_len = src_len;
}

static char lch(Lexer *L) { return (L->pos < L->src_len) ? L->src[L->pos] : '\0'; }
/* lch_at removed — not needed in current implementation */
static char ltake(Lexer *L) { return (L->pos < L->src_len) ? L->src[L->pos++] : '\0'; }
static bool lacc(Lexer *L, char ch) { if (lch(L)==ch){L->pos++;return true;} return false; }
static bool lacc1(Lexer *L, const char *s) { char c=lch(L); if(c&&strchr(s,c)){L->pos++;return true;} return false; }

static void lex_line_comment(Lexer *L) {
    while (true) { char c=ltake(L); if(c=='\n'||c=='\0') break; }
    L->vline++;
}

static bool lex_long_brackets(Lexer *L, int off) {
    L->pos += off;
    int orig = L->pos;
    if (!lacc(L,'[')) { L->pos=orig; return false; }
    int ps = L->pos;
    while (lacc(L,'=')) {}
    int pl = L->pos - ps;
    if (!lacc(L,'[')) { L->pos=orig; return false; }

    char cp[66]; if(pl>62)pl=62;
    cp[0]=']'; for(int i=0;i<pl;i++)cp[1+i]='='; cp[1+pl]=']'; cp[2+pl]='\0';
    const char *f = strstr(L->src + L->pos, cp);
    if (f) {
        int ei = (int)(f - L->src);
        for (int i=L->pos; i<ei; i++) if(L->src[i]=='\n') L->vline++;
        L->pos = ei + 2 + pl;
        return true;
    }
    L->pos = orig;
    return false;
}

static bool lex_long_comment(Lexer *L) {
    int s=L->pos; if(lex_long_brackets(L,0)) return true; L->pos=s; return false;
}

static bool lex_read_one(Lexer *L, Token *out) {
    out->type=TT_NONE; out->off=0; out->len=0; out->vline=0;
    while (L->pos < L->src_len) {
        char ch = ltake(L);

        if (is_wspace(ch)) { if(ch=='\n') L->vline++; continue; }

        /* Number */
        if ((ch>='0'&&ch<='9') || (ch=='.'&&lch(L)>='0'&&lch(L)<='9')) {
            int orig=L->pos-1;
            const char *digits;
            if (ch=='0'&&(lch(L)=='b'||lch(L)=='B')) { L->pos++; digits="01"; }
            else if (ch=='0'&&(lch(L)=='x'||lch(L)=='X')) { L->pos++; digits="0123456789aAbBcCdDeEfF"; }
            else digits="0123456789";
            while(true){char c=lch(L);if(c&&strchr(digits,c))L->pos++;else if(c=='.')L->pos++;else break;}
            out->type=TT_NUMBER; out->off=orig; out->len=L->pos-orig; out->vline=L->vline; return true;
        }

        /* Ident/keyword */
        if (is_ident_char((unsigned char)ch)) {
            int orig=L->pos-1;
            while(is_ident_char((unsigned char)lch(L))) L->pos++;
            int len=L->pos-orig;
            out->off=orig; out->len=len; out->vline=L->vline;
            out->type = is_keyword_n(L->src+orig,len) ? TT_KEYWORD : TT_IDENT;
            return true;
        }

        /* String */
        if (ch=='"'||ch=='\'') {
            int orig=L->pos-1; char q=ch;
            while(true) {
                char c=ltake(L);
                if(c=='\n'||c=='\0') break;
                if(c=='\\') {
                    if(lacc(L,'z')) { while(is_wspace(lch(L))){if(lch(L)=='\n')L->vline++;ltake(L);} }
                    else ltake(L);
                } else if(c==q) break;
            }
            out->type=TT_STRING; out->off=orig; out->len=L->pos-orig; out->vline=L->vline; return true;
        }

        /* Long string */
        if (ch=='[' && lacc1(L,"=[")) {
            int orig=L->pos-2, save=L->pos;
            if (lex_long_brackets(L,-2)) {
                out->type=TT_STRING; out->off=orig; out->len=L->pos-orig; out->vline=L->vline; return true;
            }
            L->pos=save;
            /* treat as single '[' punct */
            L->pos=orig+1;
            out->type=TT_PUNCT; out->off=orig; out->len=1; out->vline=L->vline; return true;
        }

        /* -- comment */
        if (ch=='-' && lacc(L,'-')) { if(!lex_long_comment(L)) lex_line_comment(L); continue; }
        /* // comment */
        if (ch=='/' && lacc(L,'/')) { lex_line_comment(L); continue; }

        /* Punctuation */
        if (strchr("+-*/\\%&|^<>=~#()[]{};,?@$.:!",ch)) {
            int orig=L->pos-1;
            if (ch=='!'&&lacc(L,'=')) { out->type=TT_PUNCT; out->off=orig; out->len=L->pos-orig; out->vline=L->vline; return true; }
            if (ch=='!') continue;
            if (strchr(".:/^<>",ch)&&lacc(L,ch)) {
                if (strchr(".>",ch)&&lacc(L,ch)) { if(ch=='>') lacc(L,'='); }
                else if (ch=='<'&&lacc(L,'>')) { lacc(L,'='); }
                else if (ch=='>'&&lacc(L,'<')) { lacc(L,'='); }
                else if (strchr("./^<>",ch)) { lacc(L,'='); }
            } else if (strchr("+-*/\\%&|^<>=~",ch)) { lacc(L,'='); }
            out->type=TT_PUNCT; out->off=orig; out->len=L->pos-orig; out->vline=L->vline; return true;
        }
        /* Unknown — skip */
    }
    return false;
}

static void lex_fill(Lexer *L) {
    while (L->buf_count < TOK_BUF_SIZE) {
        int idx = (L->buf_start + L->buf_count) % TOK_BUF_SIZE;
        if (lex_read_one(L, &L->buf[idx])) L->buf_count++;
        else break;
    }
}

static const Token *lex_peek(Lexer *L, int off) {
    static const Token sentinel = {TT_NONE,0,0,0};
    lex_fill(L);
    return (off < L->buf_count) ? &L->buf[(L->buf_start+off)%TOK_BUF_SIZE] : &sentinel;
}

static Token lex_take(Lexer *L) {
    static const Token sentinel = {TT_NONE,0,0,0};
    lex_fill(L);
    if (L->buf_count > 0) {
        Token t = L->buf[L->buf_start];
        L->buf_start = (L->buf_start+1)%TOK_BUF_SIZE;
        L->buf_count--;
        return t;
    }
    return sentinel;
}

/* ================================================================
 *  Node types (for context tracking during emission only)
 * ================================================================ */
typedef enum {
    NT_NONE=0, NT_VAR, NT_INDEX, NT_MEMBER, NT_CONST, NT_GROUP,
    NT_UNARY_OP, NT_BINARY_OP, NT_CALL,
    NT_TABLE, NT_TABLE_INDEX, NT_TABLE_MEMBER, NT_VARARGS,
    NT_ASSIGN, NT_OP_ASSIGN, NT_LOCAL, NT_FUNCTION,
    NT_IF, NT_ELSEIF, NT_ELSE, NT_WHILE, NT_REPEAT, NT_UNTIL,
    NT_FOR, NT_FOR_IN, NT_RETURN, NT_BREAK, NT_GOTO, NT_LABEL,
    NT_BLOCK, NT_DO,
} NodeType;

static bool is_prefix_type(NodeType nt) {
    return nt==NT_VAR||nt==NT_MEMBER||nt==NT_INDEX||nt==NT_CALL||nt==NT_GROUP;
}

/* ================================================================
 *  Emitter: combined parser + output emitter
 * ================================================================ */
#define PREV_VAL_MAX 16

typedef struct {
    Lexer      *lex;
    Buf        *out;
    const char *src;
    int         indent;

    /* Previous emitted token for spacing rules */
    char        pv[PREV_VAL_MAX]; /* prev value text */
    int         pvl;              /* prev value length */
    TokenType   pt;               /* prev type */
    bool        ptight;           /* prev was "tight" (non-whitespace preceded it) */
    NodeType    pnt;              /* prev parent node type */

    bool        failed;
    Token       last_taken;       /* most recently consumed token */
} Em;

static void em_init(Em *E, Lexer *lex, Buf *out) {
    memset(E, 0, sizeof(*E));
    E->lex=lex; E->out=out; E->src=lex->src;
}

/* Spacing helper checks */
static bool pv_eq(const Em *E, const char *s) {
    int sl=(int)strlen(s); return E->pvl==sl && memcmp(E->pv,s,(size_t)sl)==0;
}
static bool pv_is_tight_prefix(const Em *E) {
    if (E->pvl==1) { char c=E->pv[0]; return c=='('||c=='['||c=='{'||c=='?'||c=='.'||c==':'; }
    if (E->pvl==2 && E->pv[0]==':' && E->pv[1]==':') return true;
    return false;
}
static bool is_tight_suffix(const char *v, int vl) {
    if (vl==1) { char c=v[0]; return c==')'||c==']'||c=='}'||c==','||c==';'||c=='.'||c==':'; }
    if (vl==2 && v[0]==':' && v[1]==':') return true;
    return false;
}

/* Emit a token with spacing */
static void em_token(Em *E, const char *v, int vl, TokenType type, NodeType pnt) {
    if (E->ptight &&
        !pv_is_tight_prefix(E) &&
        !is_tight_suffix(v, vl) &&
        !((vl==1 && (v[0]=='('||v[0]=='[')) &&
          (E->pt==TT_IDENT || pv_eq(E,"function") || pv_eq(E,")") || pv_eq(E,"]") || pv_eq(E,"}"))) &&
        !(E->pt==TT_PUNCT && E->pnt==NT_UNARY_OP)) {
        buf_appendc(E->out, ' ');
    }
    buf_appendn(E->out, v, vl);
    if (vl < PREV_VAL_MAX) { memcpy(E->pv,v,(size_t)vl); E->pvl=vl; }
    else E->pvl=0;
    E->pt=type; E->ptight=true; E->pnt=pnt;
}

/* Emit from a Token struct */
static void em_tok(Em *E, const Token *t, NodeType pnt) { em_token(E, E->src+t->off, t->len, t->type, pnt); }
/* Emit a literal string */
static void em_str(Em *E, const char *s, TokenType type, NodeType pnt) { em_token(E, s, (int)strlen(s), type, pnt); }

/* Emit indent */
static void em_indent(Em *E) {
    for(int i=0;i<E->indent;i++) buf_appends(E->out,"  ");
    E->ptight=false;
}
/* Emit newline */
static void em_nl(Em *E) { buf_appendc(E->out,'\n'); E->ptight=false; }

/* ---- Lexer wrappers ---- */
static const Token *em_peek(Em *E, int off) { return lex_peek(E->lex, off); }
static Token em_take(Em *E) { Token t=lex_take(E->lex); E->last_taken=t; return t; }
static bool em_accept(Em *E, const char *val) {
    const Token *t=em_peek(E,0);
    if (t->type!=TT_NONE && tok_eq(t,E->src,val)) { E->last_taken=lex_take(E->lex); return true; }
    return false;
}
static bool em_require(Em *E, const char *val) { if(!em_accept(E,val)){E->failed=true;return false;} return true; }
static bool em_peq(Em *E, int off, const char *v) { const Token *t=em_peek(E,off); return t->type!=TT_NONE && tok_eq(t,E->src,v); }
static bool em_pis(Em *E, int off, TokenType tp) { return em_peek(E,off)->type==tp; }
static bool em_eof(Em *E) { return em_peek(E,0)->type==TT_NONE; }

/* ================================================================
 *  Forward declarations
 * ================================================================ */
#define VLINE_NONE (-1)

static NodeType parse_expr(Em *E, int prec);
static NodeType parse_core_expr(Em *E);
static void parse_block(Em *E, int vline);
static void parse_if(Em *E);
static void parse_while(Em *E);
/* parse_repeat is handled inline in parse_block */
static void parse_for(Em *E);
static void parse_return(Em *E, int vline);
static NodeType parse_print(Em *E);
static void parse_local(Em *E);
static NodeType parse_function(Em *E, bool stmt, bool local);
static NodeType parse_table(Em *E);
static void parse_call_args(Em *E);

/* ================================================================
 *  Expression parsing
 * ================================================================ */
static NodeType parse_core_expr(Em *E) {
    if (E->failed || em_eof(E)) { E->failed=true; return NT_NONE; }
    const Token *pk = em_peek(E,0);

    if (tok_eq(pk,E->src,"nil")||tok_eq(pk,E->src,"true")||tok_eq(pk,E->src,"false")||pk->type==TT_NUMBER||pk->type==TT_STRING) {
        Token t=em_take(E); em_tok(E,&t,NT_CONST); return NT_CONST;
    }
    if (tok_eq(pk,E->src,"{")) return parse_table(E);
    if (tok_eq(pk,E->src,"(")) {
        Token o=em_take(E); em_tok(E,&o,NT_GROUP);
        parse_expr(E,-1); if(E->failed) return NT_NONE;
        if(!em_require(E,")")) return NT_NONE;
        em_tok(E,&E->last_taken,NT_GROUP); return NT_GROUP;
    }
    if (is_unary_op(E->src,pk->off,pk->len)) {
        Token t=em_take(E); em_tok(E,&t,NT_UNARY_OP);
        parse_expr(E,K_UNARY_OPS_PREC); return NT_UNARY_OP;
    }
    if (tok_eq(pk,E->src,"?")) return parse_print(E);
    if (tok_eq(pk,E->src,"function")) return parse_function(E,false,false);
    if (tok_eq(pk,E->src,"...")) { Token t=em_take(E); em_tok(E,&t,NT_VARARGS); return NT_VARARGS; }
    if (pk->type==TT_IDENT) { Token t=em_take(E); em_tok(E,&t,NT_VAR); return NT_VAR; }
    E->failed=true; return NT_NONE;
}

static NodeType parse_expr(Em *E, int prec) {
    if (E->failed) return NT_NONE;
    NodeType et = parse_core_expr(E);
    if (E->failed) return NT_NONE;
    while (!E->failed) {
        const Token *pk=em_peek(E,0);
        if (pk->type==TT_NONE) break;
        /* . member */
        if (tok_eq(pk,E->src,".") && is_prefix_type(et)) {
            Token d=em_take(E); em_tok(E,&d,NT_MEMBER);
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
            Token id=em_take(E); em_tok(E,&id,NT_MEMBER); et=NT_MEMBER; continue;
        }
        /* [ ] */
        if (tok_eq(pk,E->src,"[") && is_prefix_type(et)) {
            Token o=em_take(E); em_tok(E,&o,NT_INDEX);
            parse_expr(E,-1); if(E->failed)return NT_NONE;
            if(!em_require(E,"]"))return NT_NONE;
            em_tok(E,&E->last_taken,NT_INDEX); et=NT_INDEX; continue;
        }
        /* ( call ) */
        if (tok_eq(pk,E->src,"(") && is_prefix_type(et)) {
            Token o=em_take(E); em_tok(E,&o,NT_CALL);
            parse_call_args(E); et=NT_CALL; continue;
        }
        /* { or string as single-arg call */
        if ((tok_eq(pk,E->src,"{")||pk->type==TT_STRING) && is_prefix_type(et)) {
            parse_core_expr(E); et=NT_CALL; continue;
        }
        /* : method */
        if (tok_eq(pk,E->src,":") && is_prefix_type(et)) {
            Token c=em_take(E); em_tok(E,&c,NT_MEMBER);
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
            Token m=em_take(E); em_tok(E,&m,NT_MEMBER);
            const Token *nx=em_peek(E,0);
            if (tok_eq(nx,E->src,"{")||nx->type==TT_STRING) parse_core_expr(E);
            else { if(!em_require(E,"("))return NT_NONE; em_tok(E,&E->last_taken,NT_CALL); parse_call_args(E); }
            et=NT_CALL; continue;
        }
        /* Binary op */
        int bp=get_binop_prec(E->src,pk->off,pk->len);
        if (bp>=0) {
            bool ok;
            if (prec<0) ok=true;
            else if (is_right_binop(E->src,pk->off,pk->len)) ok=(prec<=bp);
            else ok=(prec<bp);
            if (ok) {
                Token op=em_take(E); em_tok(E,&op,NT_BINARY_OP);
                parse_expr(E,bp); et=NT_BINARY_OP; continue;
            }
        }
        break;
    }
    return et;
}

static void parse_call_args(Em *E) {
    if (E->failed) return;
    if (em_accept(E,")")) { em_tok(E,&E->last_taken,NT_CALL); return; }
    while (!E->failed) {
        parse_expr(E,-1); if(E->failed) return;
        if (em_accept(E,")")) { em_tok(E,&E->last_taken,NT_CALL); return; }
        if (!em_require(E,",")) return;
        em_tok(E,&E->last_taken,NT_CALL);
    }
}

static NodeType parse_table(Em *E) {
    if (E->failed) return NT_NONE;
    Token o=em_take(E); em_tok(E,&o,NT_TABLE); /* { */
    while (!E->failed && !em_accept(E,"}")) {
        if (em_peq(E,0,"[")) {
            Token b=em_take(E); em_tok(E,&b,NT_TABLE_INDEX);
            parse_expr(E,-1); if(E->failed) return NT_NONE;
            if(!em_require(E,"]"))return NT_NONE; em_tok(E,&E->last_taken,NT_TABLE_INDEX);
            if(!em_require(E,"="))return NT_NONE; em_tok(E,&E->last_taken,NT_TABLE_INDEX);
            parse_expr(E,-1);
        } else if (em_pis(E,0,TT_IDENT) && em_peq(E,1,"=")) {
            Token k=em_take(E); em_tok(E,&k,NT_TABLE_MEMBER);
            Token eq=em_take(E); em_tok(E,&eq,NT_TABLE_MEMBER);
            parse_expr(E,-1);
        } else {
            parse_expr(E,-1);
        }
        if (E->failed) return NT_NONE;
        if (em_accept(E,"}")) { em_tok(E,&E->last_taken,NT_TABLE); return NT_TABLE; }
        if (em_accept(E,",")) em_tok(E,&E->last_taken,NT_TABLE);
        else if (em_accept(E,";")) em_tok(E,&E->last_taken,NT_TABLE);
        else if (!em_peq(E,0,"}")) { E->failed=true; return NT_NONE; }
    }
    if (!E->failed) em_tok(E,&E->last_taken,NT_TABLE); /* } */
    return NT_TABLE;
}

static NodeType parse_print(Em *E) {
    if (E->failed) return NT_NONE;
    em_take(E); /* consume ? */
    /* Match old AST version: unconditionally emit space before print( if prev_tight.
     * This bypasses the standard spacing rules (which would correctly suppress the
     * space after tight-prefix tokens like '('). */
    if (E->ptight) buf_appendc(E->out, ' ');
    buf_appends(E->out, "print(");
    /* Update prev state to reflect the "(" we just emitted */
    E->pv[0]='('; E->pvl=1; E->pt=TT_PUNCT; E->ptight=true; E->pnt=NT_CALL;

    /* Parse args */
    bool first=true;
    while (!E->failed) {
        if (!first) em_str(E,",",TT_PUNCT,NT_CALL);
        parse_expr(E,-1); if(E->failed) return NT_NONE;
        first=false;
        if (!em_peq(E,0,",")) break;
        em_take(E); /* consume comma from source */
    }

    /* Emit closing ) — use standard spacing (no space before ')') */
    buf_appendc(E->out, ')');
    E->pv[0]=')'; E->pvl=1; E->pt=TT_PUNCT; E->ptight=true; E->pnt=NT_CALL;
    return NT_CALL;
}

/* parse_function: the 'function' keyword has NOT been consumed yet when
 * stmt=false (expression form). For stmt=true, the keyword was consumed
 * and emitted by parse_stmt BEFORE calling this. For local=true, both
 * 'local' and 'function' have been consumed and emitted. */
static NodeType parse_function(Em *E, bool stmt, bool local) {
    if (E->failed) return NT_NONE;

    if (!stmt && !local) {
        /* Expression form: consume 'function' */
        Token fk=em_take(E); em_tok(E,&fk,NT_FUNCTION);
    }
    /* For stmt forms, keywords already consumed and emitted by caller */

    if (stmt) {
        if (local) {
            /* local function name */
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
            Token n=em_take(E); em_tok(E,&n,NT_FUNCTION);
        } else {
            /* function name.key:method */
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
            Token n=em_take(E); em_tok(E,&n,NT_FUNCTION);
            while (em_peq(E,0,".")) {
                Token d=em_take(E); em_tok(E,&d,NT_MEMBER);
                if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
                Token m=em_take(E); em_tok(E,&m,NT_MEMBER);
            }
            if (em_peq(E,0,":")) {
                Token c=em_take(E); em_tok(E,&c,NT_MEMBER);
                if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
                Token m=em_take(E); em_tok(E,&m,NT_MEMBER);
            }
        }
    }

    /* Parameters */
    if (!em_require(E,"(")) return NT_NONE;
    em_tok(E,&E->last_taken,NT_FUNCTION);
    if (!em_accept(E,")")) {
        while (!E->failed) {
            if (em_accept(E,"...")) em_tok(E,&E->last_taken,NT_FUNCTION);
            else {
                if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return NT_NONE;}
                Token p=em_take(E); em_tok(E,&p,NT_FUNCTION);
            }
            if (em_accept(E,")")) { em_tok(E,&E->last_taken,NT_FUNCTION); break; }
            if (!em_require(E,",")) return NT_NONE;
            em_tok(E,&E->last_taken,NT_FUNCTION);
        }
    } else em_tok(E,&E->last_taken,NT_FUNCTION);

    /* Body block */
    em_nl(E); E->indent++;
    parse_block(E,VLINE_NONE);
    E->indent--;
    em_indent(E);

    /* end */
    if (!em_require(E,"end")) return NT_NONE;
    em_tok(E,&E->last_taken,NT_FUNCTION);
    return NT_FUNCTION;
}

/* ================================================================
 *  Block and statement parsing with emission
 * ================================================================ */

/*
 * parse_block: parse statements until block-end/vline exceeded.
 * Does NOT handle its own enter/leave formatting — that's the caller's job.
 * (The root uses parse_root which handles the root case.)
 */
static void parse_block(Em *E, int vline) {
    if (E->failed) return;

    bool prev_func = false;
    bool first = true;

    while (!E->failed) {
        const Token *pk = em_peek(E,0);
        if (pk->type==TT_NONE) break;
        if (vline!=VLINE_NONE && pk->vline > vline) break;
        if (is_block_end(E->src,pk->off,pk->len)) break;

        /* Semicolons: skip */
        if (tok_eq(pk,E->src,";")) { em_take(E); continue; }

        /* Detect function statement */
        bool is_func = false;
        if (tok_eq(pk,E->src,"function") && em_pis(E,1,TT_IDENT)) is_func=true;
        else if (tok_eq(pk,E->src,"local") && em_peq(E,1,"function")) is_func=true;

        /* Blank line before function stmt (if prev was not function) */
        if (is_func && !first && !prev_func) buf_appendc(E->out,'\n');

        /* Indent */
        em_indent(E);

        /* Parse the statement body */
        Token token = em_take(E);
        const char *v = E->src + token.off;
        int vl = token.len;

        if (vl==2 && memcmp(v,"do",2)==0) {
            em_tok(E,&token,NT_DO);
            em_nl(E); E->indent++;
            parse_block(E,VLINE_NONE);
            E->indent--; em_indent(E);
            if(!em_require(E,"end")) return;
            em_tok(E,&E->last_taken,NT_DO);
        }
        else if (vl==2 && memcmp(v,"if",2)==0) {
            em_tok(E,&token,NT_IF);
            parse_if(E);
        }
        else if (vl==5 && memcmp(v,"while",5)==0) {
            em_tok(E,&token,NT_WHILE);
            parse_while(E);
        }
        else if (vl==6 && memcmp(v,"repeat",6)==0) {
            em_tok(E,&token,NT_REPEAT);
            em_nl(E); E->indent++;
            parse_block(E,VLINE_NONE);
            E->indent--; em_indent(E);
            if (!em_require(E,"until")) return;
            em_tok(E,&E->last_taken,NT_UNTIL);
            parse_expr(E,-1);
        }
        else if (vl==3 && memcmp(v,"for",3)==0) {
            em_tok(E,&token,NT_FOR);
            parse_for(E);
        }
        else if (vl==5 && memcmp(v,"break",5)==0) {
            em_tok(E,&token,NT_BREAK);
        }
        else if (vl==6 && memcmp(v,"return",6)==0) {
            em_tok(E,&token,NT_RETURN);
            parse_return(E,vline);
        }
        else if (vl==5 && memcmp(v,"local",5)==0) {
            em_tok(E,&token,NT_LOCAL);
            if (em_accept(E,"function")) {
                em_tok(E,&E->last_taken,NT_FUNCTION);
                parse_function(E,true,true);
            } else {
                parse_local(E);
            }
        }
        else if (vl==4 && memcmp(v,"goto",4)==0) {
            em_tok(E,&token,NT_GOTO);
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
            Token lbl=em_take(E); em_tok(E,&lbl,NT_GOTO);
        }
        else if (vl==2 && memcmp(v,"::",2)==0) {
            em_tok(E,&token,NT_LABEL);
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
            Token lbl=em_take(E); em_tok(E,&lbl,NT_LABEL);
            if(!em_require(E,"::")) return;
            em_tok(E,&E->last_taken,NT_LABEL);
        }
        else if (vl==8 && memcmp(v,"function",8)==0) {
            em_tok(E,&token,NT_FUNCTION);
            parse_function(E,true,false);
        }
        else {
            /* Expression statement or assignment.
             * We've consumed the first token. Build the first expression
             * starting with this token, then check for assignment. */

            /* Begin: replicate parse_core_expr for the already-consumed token */
            NodeType et;
            if (tok_eq(&token,E->src,"nil")||tok_eq(&token,E->src,"true")||tok_eq(&token,E->src,"false")||
                token.type==TT_NUMBER||token.type==TT_STRING) {
                em_tok(E,&token,NT_CONST); et=NT_CONST;
            } else if (tok_eq(&token,E->src,"(")) {
                em_tok(E,&token,NT_GROUP); parse_expr(E,-1);
                if(E->failed)return;
                if(!em_require(E,")"))return; em_tok(E,&E->last_taken,NT_GROUP); et=NT_GROUP;
            } else if (is_unary_op(E->src,token.off,token.len)) {
                em_tok(E,&token,NT_UNARY_OP); parse_expr(E,K_UNARY_OPS_PREC); et=NT_UNARY_OP;
            } else if (tok_eq(&token,E->src,"?")) {
                /* print shorthand as statement — match old AST version */
                if (E->ptight) buf_appendc(E->out, ' ');
                buf_appends(E->out, "print(");
                E->pv[0]='('; E->pvl=1; E->pt=TT_PUNCT; E->ptight=true; E->pnt=NT_CALL;
                bool pf=true;
                while(!E->failed){
                    if(!pf) em_str(E,",",TT_PUNCT,NT_CALL);
                    parse_expr(E,-1); if(E->failed)return;
                    pf=false;
                    if(!em_peq(E,0,","))break; em_take(E);
                }
                buf_appendc(E->out, ')');
                E->pv[0]=')'; E->pvl=1; E->pt=TT_PUNCT; E->ptight=true; E->pnt=NT_CALL;
                et=NT_CALL;
            } else if (tok_eq(&token,E->src,"...")) {
                em_tok(E,&token,NT_VARARGS); et=NT_VARARGS;
            } else if (token.type==TT_IDENT) {
                em_tok(E,&token,NT_VAR); et=NT_VAR;
            } else { E->failed=true; return; }

            /* Continue with suffix / binary operators */
            while (!E->failed) {
                const Token *spk=em_peek(E,0);
                if(spk->type==TT_NONE) break;
                if(tok_eq(spk,E->src,".")&&is_prefix_type(et)){
                    Token d=em_take(E); em_tok(E,&d,NT_MEMBER);
                    if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
                    Token id=em_take(E); em_tok(E,&id,NT_MEMBER); et=NT_MEMBER; continue;
                }
                if(tok_eq(spk,E->src,"[")&&is_prefix_type(et)){
                    Token o=em_take(E); em_tok(E,&o,NT_INDEX);
                    parse_expr(E,-1); if(E->failed)return;
                    if(!em_require(E,"]"))return; em_tok(E,&E->last_taken,NT_INDEX); et=NT_INDEX; continue;
                }
                if(tok_eq(spk,E->src,"(")&&is_prefix_type(et)){
                    Token o=em_take(E); em_tok(E,&o,NT_CALL);
                    parse_call_args(E); et=NT_CALL; continue;
                }
                if((tok_eq(spk,E->src,"{")||spk->type==TT_STRING)&&is_prefix_type(et)){
                    parse_core_expr(E); et=NT_CALL; continue;
                }
                if(tok_eq(spk,E->src,":")&&is_prefix_type(et)){
                    Token c=em_take(E); em_tok(E,&c,NT_MEMBER);
                    if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
                    Token m=em_take(E); em_tok(E,&m,NT_MEMBER);
                    const Token *nx=em_peek(E,0);
                    if(tok_eq(nx,E->src,"{")||nx->type==TT_STRING) parse_core_expr(E);
                    else { if(!em_require(E,"("))return; em_tok(E,&E->last_taken,NT_CALL); parse_call_args(E); }
                    et=NT_CALL; continue;
                }
                { int bp=get_binop_prec(E->src,spk->off,spk->len);
                  if(bp>=0){
                    Token op=em_take(E); em_tok(E,&op,NT_BINARY_OP);
                    parse_expr(E,bp); et=NT_BINARY_OP; continue;
                  }
                }
                break;
            }

            /* Check for assign / compound assign */
            if (!E->failed) {
                const Token *apk=em_peek(E,0);
                if (tok_eq(apk,E->src,"=")||tok_eq(apk,E->src,",")) {
                    while(em_accept(E,",")){
                        em_tok(E,&E->last_taken,NT_ASSIGN);
                        parse_expr(E,-1); if(E->failed)return;
                    }
                    if(!em_require(E,"="))return;
                    em_tok(E,&E->last_taken,NT_ASSIGN);
                    while(!E->failed){
                        parse_expr(E,-1); if(E->failed)return;
                        if(!em_accept(E,","))break;
                        em_tok(E,&E->last_taken,NT_ASSIGN);
                    }
                } else if (apk->type!=TT_NONE && apk->len>=2 && E->src[apk->off+apk->len-1]=='=') {
                    Token op=em_take(E); em_tok(E,&op,NT_OP_ASSIGN);
                    parse_expr(E,-1);
                }
            }
        }

        /* Statement trailing newline */
        em_nl(E);
        /* Extra blank line after function stmts */
        if (is_func) buf_appendc(E->out,'\n');
        prev_func = is_func;
        first = false;
    }
}

/*
 * Strip outer parens from condition output for shorthand if/while.
 * `cond_start` is the output position right before the condition was emitted.
 * The condition output looks like: " (inner)" where the space comes from
 * the spacing rule. We strip the space + '(' at the front and ')' at end.
 */
static void strip_outer_parens(Em *E, size_t cond_start) {
    char *buf = E->out->data;
    size_t end = E->out->len;

    /* Find the '(' — it should be near cond_start */
    size_t paren_pos = cond_start;
    while (paren_pos < end && buf[paren_pos] != '(') paren_pos++;
    if (paren_pos >= end) return;

    /* Find the matching ')' at the end */
    size_t rparen = end - 1;
    while (rparen > paren_pos && buf[rparen] != ')') rparen--;
    if (buf[rparen] != ')') return;

    /* Remove just the '(' character. The space before it stays (it separates
     * the keyword from the condition). */
    memmove(buf + paren_pos, buf + paren_pos + 1, end - paren_pos - 1);
    end--;
    rparen--;

    /* Remove the ')' */
    memmove(buf + rparen, buf + rparen + 1, end - rparen - 1);
    end--;

    E->out->len = end;
}

/* ---- if ---- */
static void parse_if(Em *E) {
    if (E->failed) return;

    /* Save position before condition for potential shorthand paren stripping */
    size_t cond_start = E->out->len;

    parse_expr(E,-1);
    if (E->failed) return;

    if (em_accept(E,"then")) {
        em_tok(E,&E->last_taken,NT_IF);
        em_nl(E); E->indent++;
        parse_block(E,VLINE_NONE);
        E->indent--;

        if (em_accept(E,"else")) {
            em_indent(E);
            em_tok(E,&E->last_taken,NT_ELSE);
            em_nl(E); E->indent++;
            parse_block(E,VLINE_NONE);
            E->indent--; em_indent(E);
            if(!em_require(E,"end")) return;
            em_tok(E,&E->last_taken,NT_ELSE);
        } else if (em_accept(E,"elseif")) {
            em_indent(E);
            em_tok(E,&E->last_taken,NT_ELSEIF);
            parse_if(E); /* recursive for chain */
        } else {
            em_indent(E);
            if(!em_require(E,"end")) return;
            em_tok(E,&E->last_taken,NT_IF);
        }
    }
    else if (em_accept(E,"do")) {
        /* PICO-8 accepts 'do' in place of 'then'. Emit as "then". */
        em_str(E,"then",TT_KEYWORD,NT_IF);
        em_nl(E); E->indent++;
        parse_block(E,VLINE_NONE);
        E->indent--;

        if (em_accept(E,"else")) {
            em_indent(E);
            em_tok(E,&E->last_taken,NT_ELSE);
            em_nl(E); E->indent++;
            parse_block(E,VLINE_NONE);
            E->indent--; em_indent(E);
            if(!em_require(E,"end")) return;
            em_tok(E,&E->last_taken,NT_ELSE);
        } else if (em_accept(E,"elseif")) {
            em_indent(E);
            em_tok(E,&E->last_taken,NT_ELSEIF);
            parse_if(E);
        } else {
            em_indent(E);
            if(!em_require(E,"end")) return;
            em_tok(E,&E->last_taken,NT_IF);
        }
    }
    else {
        /* Shorthand if: condition ended with ')' */
        if (!pv_eq(E,")")) { E->failed=true; return; }
        int cvl = E->last_taken.vline;

        /* Strip outer parens from condition */
        strip_outer_parens(E, cond_start);

        /* Emit shorthand body: " then\n" + indented block + indent + "end" */
        buf_appends(E->out," then"); em_nl(E);
        E->indent++;
        parse_block(E,cvl);
        E->indent--;

        /* Check for shorthand else on same vline */
        const Token *pk = em_peek(E,0);
        if (pk->type!=TT_NONE && pk->vline==cvl && tok_eq(pk,E->src,"else")) {
            /* Don't emit "end" here — the else is part of the same if.
             * Only emit "end" after the else body. */
            em_indent(E);
            Token ek=em_take(E);
            em_tok(E,&ek,NT_ELSE);

            /* Shorthand else body */
            em_nl(E); E->indent++;
            parse_block(E,cvl);
            E->indent--;
            em_indent(E); buf_appends(E->out,"end");
            E->ptight=false;
        } else {
            em_indent(E); buf_appends(E->out,"end");
            E->ptight=false;
        }
    }
}

/* ---- while ---- */
static void parse_while(Em *E) {
    if (E->failed) return;
    size_t cond_start = E->out->len;
    parse_expr(E,-1);
    if (E->failed) return;

    if (em_accept(E,"do")) {
        em_tok(E,&E->last_taken,NT_WHILE);
        em_nl(E); E->indent++;
        parse_block(E,VLINE_NONE);
        E->indent--; em_indent(E);
        if(!em_require(E,"end")) return;
        em_tok(E,&E->last_taken,NT_WHILE);
    } else {
        /* Shorthand while */
        if (!pv_eq(E,")")) { E->failed=true; return; }
        int cvl = E->last_taken.vline;
        strip_outer_parens(E, cond_start);
        buf_appends(E->out," do"); em_nl(E);
        E->indent++;
        parse_block(E,cvl);
        E->indent--;
        em_indent(E); buf_appends(E->out,"end");
        E->ptight=false;
    }
}

/* ---- for ---- */
static void parse_for(Em *E) {
    if (E->failed) return;
    if (em_peq(E,1,"=")) {
        /* Numeric for */
        if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
        Token n=em_take(E); em_tok(E,&n,NT_FOR);
        if(!em_require(E,"=")) return; em_tok(E,&E->last_taken,NT_FOR);
        parse_expr(E,-1); if(E->failed) return;
        if(!em_require(E,",")) return; em_tok(E,&E->last_taken,NT_FOR);
        parse_expr(E,-1); if(E->failed) return;
        if(em_accept(E,",")) { em_tok(E,&E->last_taken,NT_FOR); parse_expr(E,-1); if(E->failed)return; }
        if(!em_require(E,"do")) return; em_tok(E,&E->last_taken,NT_FOR);
        em_nl(E); E->indent++;
        parse_block(E,VLINE_NONE);
        E->indent--; em_indent(E);
        if(!em_require(E,"end")) return; em_tok(E,&E->last_taken,NT_FOR);
    } else {
        /* For-in */
        while(!E->failed) {
            if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
            Token n=em_take(E); em_tok(E,&n,NT_FOR_IN);
            if(!em_accept(E,",")) break;
            em_tok(E,&E->last_taken,NT_FOR_IN);
        }
        if(!em_require(E,"in")) return; em_tok(E,&E->last_taken,NT_FOR_IN);
        while(!E->failed) {
            parse_expr(E,-1); if(E->failed) return;
            if(!em_accept(E,",")) break;
            em_tok(E,&E->last_taken,NT_FOR_IN);
        }
        if(!em_require(E,"do")) return; em_tok(E,&E->last_taken,NT_FOR_IN);
        em_nl(E); E->indent++;
        parse_block(E,VLINE_NONE);
        E->indent--; em_indent(E);
        if(!em_require(E,"end")) return; em_tok(E,&E->last_taken,NT_FOR_IN);
    }
}

/* ---- return ---- */
static void parse_return(Em *E, int vline) {
    if (E->failed) return;
    const Token *pk=em_peek(E,0);
    if (pk->type==TT_NONE) return;
    if (is_block_end(E->src,pk->off,pk->len)) return;
    if (tok_eq(pk,E->src,";")) return;
    if (vline!=VLINE_NONE && pk->vline>vline) return;
    while(!E->failed) {
        parse_expr(E,-1); if(E->failed) return;
        if(!em_accept(E,",")) break;
        em_tok(E,&E->last_taken,NT_RETURN);
    }
}

/* ---- local ---- */
static void parse_local(Em *E) {
    if (E->failed) return;
    while(!E->failed) {
        if(em_eof(E)||em_peek(E,0)->type!=TT_IDENT){E->failed=true;return;}
        Token n=em_take(E); em_tok(E,&n,NT_LOCAL);
        if(!em_accept(E,",")) break;
        em_tok(E,&E->last_taken,NT_LOCAL);
    }
    if(em_accept(E,"=")) {
        em_tok(E,&E->last_taken,NT_LOCAL);
        while(!E->failed) {
            parse_expr(E,-1); if(E->failed) return;
            if(!em_accept(E,",")) break;
            em_tok(E,&E->last_taken,NT_LOCAL);
        }
    }
}

/* ================================================================
 *  Public API
 * ================================================================ */
char *p8_shrinko_unminify(const char *src, size_t len, size_t *out_len) {
    if (len == 0) {
        char *r=(char*)malloc(1); if(!r) return NULL;
        r[0]='\0'; if(out_len)*out_len=0; return r;
    }

    Lexer lex; lex_init(&lex,src,(int)len);
    Buf out; buf_init(&out);
    Em em; em_init(&em,&lex,&out);

    /* Root block: emit "\n" then parse statements at indent 0,
     * then emit indent (empty at 0). Matches Python's unminifier
     * which emits "\n" at the start of every block. */
    em_nl(&em);
    parse_block(&em, VLINE_NONE);
    em_indent(&em);

    if (em.failed) { buf_free(&out); return NULL; }
    if (!buf_appendc(&out,'\0')) { buf_free(&out); return NULL; }

    char *result = out.data;
    size_t result_len = out.len - 1;
    out.data = NULL;

    /* Trim leading newlines */
    size_t start=0;
    while(start<result_len && result[start]=='\n') start++;
    while(result_len>start && (result[result_len-1]=='\n'||result[result_len-1]==' ')) result_len--;
    if (start>0) { memmove(result,result+start,result_len-start); result_len-=start; }
    result[result_len]='\0';

    if(out_len) *out_len=result_len;
    return result;
}
