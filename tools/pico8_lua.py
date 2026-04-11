#!/usr/bin/env python3
"""
pico8_lua.py — token-based PICO-8 → Lua 5.4 source rewriter.

The algorithm has three layers:

  1. tokenize(src) → list[Token]
     A small Lua-style lexer that recognises identifiers, numbers
     (decimal/hex/binary), single-quoted/double-quoted/long strings,
     line and block comments, single- and multi-character operators,
     whitespace, and newlines. Keywords are just identifiers whose
     text matches a known set; the parser distinguishes them.

  2. Rewrites at the token level:
     - != → ~=                              (token text replacement)
     - 0b1010 → its decimal value           (NUMBER text replacement)
     - x op= rhs   →   x = x op (rhs)       (compound assignment)
     - if (cond) stmt   →   if (cond) then stmt end
     - while (cond) stmt → while (cond) do stmt end

  3. Emit by joining each token's text. Whitespace and comments are
     preserved as their own tokens so the output looks like the
     input plus the rewrites — line numbers don't shift, errors
     still point at the user's code, etc.

Why a tokenizer instead of regex/sed-style line passes:
- "0nC" is unambiguously the number 0 followed by the identifier
  nC at the token level; at the character level it looks like a
  malformed number until you know where the boundary is.
- "j-=1return" (shrinko8-minified Celeste) is the tokens
  j, -=, 1, return — finding the RHS expression end is just
  "first STMT_KEYWORD token at depth 0" instead of fragile
  prev-char/next-char heuristics.
- Strings, comments and long brackets are recognised exactly once
  during tokenization; later passes never have to second-guess
  whether they're inside a string.
"""

from dataclasses import dataclass
from typing import List, Tuple, Optional


# ----------------------------------------------------------------------
# Token types
# ----------------------------------------------------------------------
@dataclass
class Token:
    kind: str    # 'IDENT', 'NUMBER', 'STRING', 'OP', 'WS', 'NL', 'COMMENT', 'RAW'
    text: str

    def __repr__(self):
        return f"<{self.kind} {self.text!r}>"


KEYWORDS = {
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
    'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or',
    'repeat', 'return', 'then', 'true', 'until', 'while',
}

# Tokens that mark the end of an expression at depth 0 — when found
# inside the RHS of a compound assignment, the expression ends.
STMT_KEYWORDS = {
    'return', 'break', 'end', 'else', 'elseif', 'then', 'do',
    'while', 'if', 'for', 'local', 'function', 'repeat', 'until',
    'goto', 'in',
}

# Compound assignment operators (PICO-8 dialect extensions to Lua).
COMPOUND_OPS = {'+=', '-=', '*=', '/=', '%=', '^=', '..=', '//=',
                '|=', '&=', '<<=', '>>=', '^^='}

# Operators we need to recognise. Order matters — longer matches
# first so '..=' beats '..' beats '.', '==' beats '=', etc.
MULTI_CHAR_OPS = [
    # 3-char first (longest match wins)
    '..=', '...', '//=', '<<=', '>>=', '^^=',
    # 2-char
    '..', '//', '<<', '>>', '^^',
    '==', '~=', '!=', '<=', '>=', '::',
    '+=', '-=', '*=', '/=', '%=', '^=', '|=', '&=',
]


# ----------------------------------------------------------------------
# Tokenizer
# ----------------------------------------------------------------------
def _scan_long_bracket(src: str, i: int) -> Optional[int]:
    """If src[i:] starts a long bracket [[, [=[, [==[ etc., return the
    end-of-content index (the closing ]] / ]=] / etc., past the end).
    Otherwise return None."""
    if i >= len(src) or src[i] != '[':
        return None
    j = i + 1
    level = 0
    while j < len(src) and src[j] == '=':
        level += 1
        j += 1
    if j >= len(src) or src[j] != '[':
        return None
    # find matching close
    close = ']' + ('=' * level) + ']'
    end = src.find(close, j + 1)
    if end < 0:
        return len(src)
    return end + len(close)


def tokenize(src: str) -> List[Token]:
    tokens: List[Token] = []
    i = 0
    n = len(src)

    while i < n:
        c = src[i]

        # Whitespace (but not newlines — newlines are their own token).
        if c == ' ' or c == '\t':
            j = i
            while j < n and (src[j] == ' ' or src[j] == '\t'):
                j += 1
            tokens.append(Token('WS', src[i:j]))
            i = j
            continue

        # Newlines (\r, \n, \r\n) — significant for shorthand if's
        # "stops at end of line" semantics.
        if c == '\n' or c == '\r':
            j = i + 1
            if c == '\r' and j < n and src[j] == '\n':
                j += 1
            tokens.append(Token('NL', src[i:j]))
            i = j
            continue

        # Comments — line and block.
        if c == '-' and i + 1 < n and src[i + 1] == '-':
            # Long-bracket block comment? --[[, --[=[, etc.
            end = _scan_long_bracket(src, i + 2)
            if end is not None:
                tokens.append(Token('COMMENT', src[i:end]))
                i = end
                continue
            # Line comment.
            j = i
            while j < n and src[j] != '\n' and src[j] != '\r':
                j += 1
            tokens.append(Token('COMMENT', src[i:j]))
            i = j
            continue

        # Long-bracket strings.
        end = _scan_long_bracket(src, i)
        if end is not None:
            tokens.append(Token('STRING', src[i:end]))
            i = end
            continue

        # Quoted strings.
        if c == '"' or c == "'":
            quote = c
            j = i + 1
            while j < n:
                if src[j] == '\\' and j + 1 < n:
                    j += 2
                    continue
                if src[j] == quote:
                    j += 1
                    break
                if src[j] == '\n':   # invalid in Lua but bail gracefully
                    break
                j += 1
            tokens.append(Token('STRING', src[i:j]))
            i = j
            continue

        # Numbers.  Decimal, hex (0x...), or binary (0b... PICO-8 ext).
        if c.isdigit() or (c == '.' and i + 1 < n and src[i + 1].isdigit()):
            j = i
            if (c == '0' and i + 1 < n
                    and (src[i + 1] == 'x' or src[i + 1] == 'X')):
                # Hex literal: hex digits, '.', and optional pP exponent.
                j += 2
                while j < n and (src[j].isdigit()
                                  or src[j] in 'abcdefABCDEF.'):
                    j += 1
                if j < n and (src[j] == 'p' or src[j] == 'P'):
                    j += 1
                    if j < n and src[j] in '+-':
                        j += 1
                    while j < n and src[j].isdigit():
                        j += 1
            elif (c == '0' and i + 1 < n
                    and (src[i + 1] == 'b' or src[i + 1] == 'B')):
                # PICO-8 binary literal.
                j += 2
                while j < n and src[j] in '01':
                    j += 1
            else:
                while j < n and (src[j].isdigit() or src[j] == '.'):
                    j += 1
                # Exponent: only valid if followed by [+-]? digit.
                # Otherwise the `e` belongs to the next identifier.
                if j < n and (src[j] == 'e' or src[j] == 'E'):
                    k = j + 1
                    if k < n and src[k] in '+-':
                        k += 1
                    if k < n and src[k].isdigit():
                        j = k
                        while j < n and src[j].isdigit():
                            j += 1
                    # else: leave the e for the next token
            tokens.append(Token('NUMBER', src[i:j]))
            i = j
            continue

        # Identifiers / keywords.
        if c == '_' or c.isalpha():
            j = i + 1
            while j < n and (src[j] == '_' or src[j].isalnum()):
                j += 1
            tokens.append(Token('IDENT', src[i:j]))
            i = j
            continue

        # Operators (multi-char first, then single).
        matched = False
        for op in MULTI_CHAR_OPS:
            if src[i:i + len(op)] == op:
                tokens.append(Token('OP', op))
                i += len(op)
                matched = True
                break
        if matched:
            continue

        # Single-char punctuation / operator.
        tokens.append(Token('OP', c))
        i += 1

    return tokens


# ----------------------------------------------------------------------
# Pass 1: token-level normalisations.
# ----------------------------------------------------------------------
def normalise_tokens(tokens: List[Token]) -> List[Token]:
    out: List[Token] = []
    for t in tokens:
        if t.kind == 'OP' and t.text == '!=':
            out.append(Token('OP', '~='))
            continue
        if t.kind == 'NUMBER' and len(t.text) >= 3 and t.text[:2] in ('0b', '0B'):
            try:
                v = int(t.text[2:], 2)
                out.append(Token('NUMBER', str(v)))
                continue
            except ValueError:
                pass  # fall through
        out.append(t)
    return out


# ----------------------------------------------------------------------
# Helpers used by structural rewrites.
# ----------------------------------------------------------------------
def _skip_ws_fwd(tokens: List[Token], i: int) -> int:
    """Return the next index >= i whose token is not WS / COMMENT."""
    while i < len(tokens) and tokens[i].kind in ('WS', 'COMMENT'):
        i += 1
    return i


def _skip_ws_back(tokens: List[Token], i: int) -> int:
    """Return the previous index <= i whose token is not WS / COMMENT."""
    while i >= 0 and tokens[i].kind in ('WS', 'COMMENT'):
        i -= 1
    return i


def _find_lvalue_start(tokens: List[Token], op_idx: int) -> int:
    """
    Walk backwards from a compound-op token to find the start of the
    lvalue chain. An lvalue chain is one or more of:
        IDENT       (the leftmost token)
        . IDENT     (field access)
        [ expr ]    (subscript, balanced)
    Returns the index of the leftmost IDENT, or -1 if no chain found.
    """
    i = _skip_ws_back(tokens, op_idx - 1)
    if i < 0:
        return -1

    while i >= 0:
        t = tokens[i]

        # `]` → walk back to matching `[` and continue past it.
        if t.kind == 'OP' and t.text == ']':
            depth = 1
            i -= 1
            while i >= 0 and depth > 0:
                if tokens[i].kind == 'OP':
                    if tokens[i].text == ']':
                        depth += 1
                    elif tokens[i].text == '[':
                        depth -= 1
                if depth > 0:
                    i -= 1
            if i < 0:
                return -1
            i -= 1                                 # past the [
            i = _skip_ws_back(tokens, i)
            continue

        # IDENT → maybe leftmost, maybe more chain to the left.
        if t.kind == 'IDENT' and t.text not in KEYWORDS:
            ident_i = i
            prev = _skip_ws_back(tokens, i - 1)
            if prev >= 0 and tokens[prev].kind == 'OP' and tokens[prev].text == '.':
                # Field access — keep walking back.
                i = prev - 1
                i = _skip_ws_back(tokens, i)
                continue
            return ident_i

        return -1     # something we don't accept in an lvalue

    return -1


def _find_line_end(tokens: List[Token], start: int) -> int:
    """
    Simpler scanner used for shorthand-if BODY ranges. Tracks
    paren/bracket/brace depth only — does NOT do any rvalue/op
    state-tracking, so the body can contain anything (statement
    keywords, multiple statements, function calls, etc). Returns
    the index of the next NL token at depth 0 (or the index of
    an unmatched closing bracket, or end of input).
    """
    depth = 0
    i = start
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t.kind == 'NL' and depth == 0:
            return i
        if t.kind == 'OP':
            if t.text in ('(', '[', '{'):
                depth += 1
            elif t.text in (')', ']', '}'):
                if depth == 0:
                    return i
                depth -= 1
            elif depth == 0 and t.text == ';':
                return i
        i += 1
    return n


def _find_expr_end(tokens: List[Token], start: int,
                    stop_on_newline: bool = False,
                    stop_on_keywords: bool = True) -> int:
    """
    Find the end of a Lua expression starting at `start`. Returns
    the index of the FIRST token NOT in the expression.

    Tracks paren/bracket/brace depth + a tiny "rvalue / op /
    initial" state machine. At depth 0 the expression ends at:
      - a `;`
      - a statement-keyword identifier (return, end, ...)
          (only if stop_on_keywords is True)
      - an unmatched closing paren/bracket/brace
      - a newline (only if stop_on_newline is True)
      - any token that would start a NEW statement: another value
        token directly after a value, a compound-assign operator,
        or a `=` after a value
      - end of input.

    The state machine is what catches juxtaposed-statement
    minified PICO-8 like `nd-=30 q+=1 dset(6,q)` — after the
    `30` we'd otherwise greedily consume `q+=1 dset(6,q)` as
    part of the RHS expression. Tracking "after a value, the
    only legal next token is a binary operator or call/index"
    bounds the scan correctly.
    """
    # State: 'init' = expression hasn't started or just had a binary op,
    #        'value' = just consumed a value-end token (number, string,
    #                  closing bracket, identifier in rvalue context).
    state = 'init'
    depth = 0
    i = start
    n = len(tokens)

    BINARY_OPS = {
        '+', '-', '*', '/', '%', '^', '..', '//',
        '==', '~=', '<', '>', '<=', '>=',
        '<<', '>>', '&', '|',
    }
    UNARY_OPS = {'-', 'not', '#', '~'}     # unary minus shares text
    LITERALS = {'nil', 'true', 'false'}

    while i < n:
        t = tokens[i]
        if t.kind == 'NL':
            if depth == 0 and stop_on_newline:
                return i
            i += 1
            continue
        if t.kind in ('WS', 'COMMENT'):
            i += 1
            continue

        if t.kind == 'OP':
            # Brackets / braces / parens
            if t.text in ('(', '[', '{'):
                # `(` after a value is a function call → still a value
                depth += 1
                state = 'init'
                i += 1
                continue
            if t.text in (')', ']', '}'):
                if depth == 0:
                    return i
                depth -= 1
                state = 'value'
                i += 1
                continue
            if depth == 0 and t.text == ';':
                return i
            # Compound assign at depth 0 = new statement boundary.
            if depth == 0 and t.text in COMPOUND_OPS:
                return i
            # `=` (single) at depth 0 = assignment, also boundary.
            if depth == 0 and t.text == '=':
                return i
            # Field access `.` after a value continues the expression.
            if t.text == '.':
                state = 'init'
                i += 1
                continue
            # Other ops are binary or unary; either way the next thing
            # is supposed to be a value, so reset to init.
            state = 'init'
            i += 1
            continue

        if t.kind == 'IDENT':
            if depth == 0 and stop_on_keywords and t.text in STMT_KEYWORDS:
                return i
            # Logical operators and `not` count as binary/unary ops.
            if t.text in ('and', 'or'):
                state = 'init'
                i += 1
                continue
            if t.text == 'not':
                state = 'init'
                i += 1
                continue
            # Literal-keywords behave like values.
            if t.text in LITERALS:
                if depth == 0 and state == 'value':
                    return i
                state = 'value'
                i += 1
                continue
            # Regular identifier — a value reference.
            if depth == 0 and state == 'value':
                return i
            state = 'value'
            i += 1
            continue

        if t.kind in ('NUMBER', 'STRING'):
            if depth == 0 and state == 'value':
                return i
            state = 'value'
            i += 1
            continue

        if t.kind == 'RAW':
            # Pessimistic: treat a RAW chunk as a value end.
            state = 'value'
            i += 1
            continue

        i += 1
    return n


# ----------------------------------------------------------------------
# Pass 2: compound assignments.
# ----------------------------------------------------------------------
def rewrite_compound_assigns(tokens: List[Token]) -> List[Token]:
    """
    For each compound-op token at depth 0 of a statement, rewrite
    `LHS op= RHS` as `LHS = LHS op (RHS)`. Multiple compound assigns
    on the same line are handled left-to-right via repeated passes.
    """
    # Find all compound-op positions and their LHS/RHS bounds.
    edits: List[Tuple[int, int, str]] = []   # (start_idx, end_idx, new_text)
    for i, t in enumerate(tokens):
        if t.kind != 'OP' or t.text not in COMPOUND_OPS:
            continue
        lhs_start = _find_lvalue_start(tokens, i)
        if lhs_start < 0:
            continue
        op_text = t.text[:-1]                  # strip trailing '='
        if op_text == '..':
            op_text = '..'                     # ..= → ..
        elif op_text == '^^':
            op_text = '~'                      # ^^= → ~ (Lua XOR)
        rhs_start = i + 1
        rhs_end = _find_expr_end(tokens, rhs_start, stop_on_newline=True)
        # Build the LHS / RHS textual chunks.
        lhs_text = _join_tokens_spaced(tokens[lhs_start:i]).strip()
        rhs_text = _join_tokens_spaced(tokens[rhs_start:rhs_end]).strip()
        if not lhs_text or not rhs_text:
            continue
        new_text = f"{lhs_text} = {lhs_text} {op_text} ({rhs_text})"
        edits.append((lhs_start, rhs_end, new_text))

    if not edits:
        return tokens

    # Apply edits in reverse order so earlier indices stay valid.
    out = list(tokens)
    for start, end, new_text in sorted(edits, key=lambda e: e[0], reverse=True):
        out[start:end] = [Token('RAW', new_text)]
    return out


# ----------------------------------------------------------------------
# Pass 3: shorthand if / while.
# ----------------------------------------------------------------------
def _is_at_statement_position(tokens: List[Token], i: int) -> bool:
    """
    True if the token at i can begin a statement. Used to confirm
    that an `if` token is statement-context (so the shorthand rule
    might apply) rather than something weird embedded in an
    expression.

    Heuristic: walk back through WS/COMMENT/NL; the previous code
    token must be either start-of-input, a statement-terminator
    keyword (do/then/else/end/etc), `;`, or `(`/`,`/etc that closes
    a previous expression context. We err on the side of "yes,
    statement" because PICO-8 doesn't have if-expressions.
    """
    j = i - 1
    while j >= 0 and tokens[j].kind in ('WS', 'COMMENT', 'NL'):
        j -= 1
    if j < 0:
        return True
    pt = tokens[j]
    if pt.kind == 'IDENT' and pt.text in (
            'do', 'then', 'else', 'end', 'repeat', 'begin'):
        return True
    if pt.kind == 'OP' and pt.text in (';', '{'):
        return True
    # We default to True. False positives would only matter if Lua
    # allowed an `if` expression, which it doesn't.
    return True


def rewrite_if_do_blocks(tokens: List[Token]) -> List[Token]:
    """
    PICO-8 accepts both `if cond then ... end` and `if cond do ... end`.
    Standard Lua only accepts `then` after `if`. Walk through every
    `if` keyword at statement position and scan forward through the
    condition (any depth of parens/brackets) until we find a `then`
    or `do` at depth 0. If we find `do`, replace it with `then`.

    This handles BOTH parenthesised (`if (cond) do`) and bare
    (`if cond do`) forms — the shorthand-if pass only fires on
    parenthesised conditions, so this pass is needed for the bare
    form.
    """
    i = 0
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t.kind == 'IDENT' and t.text == 'if' \
                and _is_at_statement_position(tokens, i):
            depth = 0
            j = i + 1
            while j < n:
                tj = tokens[j]
                if tj.kind == 'OP':
                    if tj.text in ('(', '[', '{'):
                        depth += 1
                    elif tj.text in (')', ']', '}'):
                        if depth > 0:
                            depth -= 1
                if tj.kind == 'IDENT' and depth == 0:
                    if tj.text == 'then':
                        break  # already standard
                    if tj.text == 'do':
                        tokens[j] = Token('IDENT', 'then')
                        break
                    # Hit a different statement keyword without
                    # finding then/do — probably shorthand-if; let
                    # the shorthand pass deal with it.
                    if tj.text in ('end', 'else', 'elseif', 'return',
                                    'break', 'while', 'for', 'function',
                                    'local', 'goto', 'repeat', 'until'):
                        break
                if tj.kind == 'NL' and depth == 0:
                    break  # ran out of line; shorthand handles it
                j += 1
            i = j + 1
            continue
        i += 1
    return tokens


def rewrite_shorthand_if_while(tokens: List[Token]) -> List[Token]:
    """
    Rewrite `if (cond) stmt` (no `then`) to `if (cond) then stmt end`,
    and `while (cond) stmt` (no `do`) to `while (cond) do stmt end`.
    """
    edits: List[Tuple[int, int, str]] = []

    i = 0
    n = len(tokens)
    while i < n:
        t = tokens[i]
        if t.kind == 'IDENT' and t.text in ('if', 'while') \
                and _is_at_statement_position(tokens, i):
            kw = t.text
            j = _skip_ws_fwd(tokens, i + 1)
            if j >= n or not (tokens[j].kind == 'OP' and tokens[j].text == '('):
                i += 1
                continue
            # Find matching close paren.
            depth = 1
            k = j + 1
            while k < n and depth > 0:
                tk = tokens[k]
                if tk.kind == 'OP':
                    if tk.text == '(':
                        depth += 1
                    elif tk.text == ')':
                        depth -= 1
                        if depth == 0:
                            break
                k += 1
            if k >= n:
                i += 1
                continue
            close_paren = k
            # What's after the close paren?
            after = _skip_ws_fwd(tokens, close_paren + 1)
            if after < n and tokens[after].kind == 'IDENT' \
                    and tokens[after].text in ('then', 'do'):
                # Regular if/while, not shorthand. PICO-8 also accepts
                # `if cond do ... end` as a synonym for
                # `if cond then ... end`; Lua doesn't, so rewrite the
                # `do` to `then` in that specific case.
                if kw == 'if' and tokens[after].text == 'do':
                    tokens[after] = Token('IDENT', 'then')
                i = close_paren + 1
                continue
            # Find end of shorthand statement: end of line at depth
            # 0. Statement keywords (return, break, etc.) inside the
            # body are part of it, NOT terminators — that's the
            # whole point of the shorthand: `if (x) return` is "if
            # x then return end".
            stmt_end = _find_line_end(tokens, close_paren + 1)
            if stmt_end <= close_paren + 1:
                # Empty body — leave alone.
                i = close_paren + 1
                continue
            # Build the rewritten range. Reuse the original tokens
            # verbatim; just insert ` then `/` do ` after the `)` and
            # ` end` before the line end.
            keyword_to_block = 'then' if kw == 'if' else 'do'
            cond_text = _join_tokens_spaced(tokens[i:close_paren + 1])
            stmt_text = _join_tokens_spaced(tokens[close_paren + 1:stmt_end])
            stmt_text = stmt_text.rstrip()
            new_text = f"{cond_text} {keyword_to_block} {stmt_text} end"
            edits.append((i, stmt_end, new_text))
            i = stmt_end
            continue
        i += 1

    if not edits:
        return tokens

    out = list(tokens)
    for start, end, new_text in sorted(edits, key=lambda e: e[0], reverse=True):
        out[start:end] = [Token('RAW', new_text)]
    return out


# ----------------------------------------------------------------------
# Top-level entry point.
# ----------------------------------------------------------------------
def _join_tokens_spaced(tokens: List[Token]) -> str:
    """
    Join a token slice into source, inserting a single space between
    any two adjacent IDENT/NUMBER tokens that have no whitespace
    between them. PICO-8 minified code is full of `4do`, `3or`,
    `1return`, `0nC` patterns where Lua's lexer would otherwise
    treat the result as a single ill-formed token.
    """
    out = []
    last_kind = None
    for t in tokens:
        if last_kind is not None:
            cur_word = t.kind in ('IDENT', 'NUMBER')
            last_word = last_kind in ('IDENT', 'NUMBER')
            if cur_word and last_word:
                out.append(' ')
        out.append(t.text)
        if t.kind in ('WS', 'NL', 'COMMENT'):
            last_kind = None
        else:
            last_kind = t.kind
    return ''.join(out)


def _emit_with_spacing(tokens: List[Token]) -> str:
    return _join_tokens_spaced(tokens)


def rewrite_pico8_to_lua(src: str) -> str:
    tokens = tokenize(src)
    tokens = normalise_tokens(tokens)
    # Compound assigns first — shorthand if rewrites depend on the
    # already-expanded form so the inserted "end" doesn't truncate
    # an unfinished compound.
    tokens = rewrite_compound_assigns(tokens)
    # NOTE: rewrite_if_do_blocks and rewrite_shorthand_if_while are
    # DISABLED. shrinko8 -U already long-forms all if statements,
    # and post_fix_lua handles the residual `if cond do` → `then`.
    # The shorthand-if rewriter has a known false-positive on multi-
    # clause conditions like `if (a) or (b) then` where it treats
    # the first `)` as the end of the shorthand condition.
    return _emit_with_spacing(tokens)


# ----------------------------------------------------------------------
# CLI for testing.
# ----------------------------------------------------------------------
if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("usage: pico8_lua.py <source.lua>", file=sys.stderr)
        sys.exit(1)
    src = open(sys.argv[1]).read()
    print(rewrite_pico8_to_lua(src), end="")
