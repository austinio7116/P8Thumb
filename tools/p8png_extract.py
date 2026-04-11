#!/usr/bin/env python3
"""
p8png_extract.py — convert a folder of .p8.png cart files into
plain .p8 text carts (in shrinko8-unminified form) plus matching
128×128 .bmp label images, suitable for uploading to the ThumbyP8
device.

Usage:
    p8png_extract.py <input_dir> <output_dir>

For every <name>.p8.png in input_dir, writes:
    <output_dir>/<name>.p8     plain text cart, dialect-friendly
    <output_dir>/<name>.bmp    128×128 16-bit RGB565 BMP label

Heavy lifting (PNG decode, PXA decompression, full Lua tokenize/
parse/unminify) is delegated to vendored shrinko8
(https://github.com/thisismypassport/shrinko8, MIT license — see
tools/shrinko8/LICENSE). Trying to reimplement shrinko8's parser
in this script is a bottomless rabbit hole; shrinko8 already
handles every PICO-8 dialect quirk we kept tripping over.

The .bmp label is built from the visible PNG via PIL — that part
we don't need shrinko8 for.
"""

import os
import re
import struct
import subprocess
import sys
from pathlib import Path

SHRINKO8 = Path(__file__).resolve().parent / "shrinko8" / "shrinko8.py"

try:
    from PIL import Image
except ImportError:
    print("This script needs Pillow: pip install Pillow", file=sys.stderr)
    sys.exit(1)

# Token-based PICO-8 → vanilla Lua 5.4 rewriter, in this same dir.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from pico8_lua import rewrite_pico8_to_lua

LUAC54 = Path(__file__).resolve().parent / "luac54"


# -----------------------------------------------------------------------
# 1. PNG → 32 KB cart bytes (steganographic decode)
# -----------------------------------------------------------------------
def png_to_cart_bytes(png_path: Path) -> bytes:
    im = Image.open(png_path).convert("RGBA")
    w, h = im.size
    if (w, h) != (160, 205):
        print(f"warn: {png_path.name} is {w}x{h}, expected 160x205",
              file=sys.stderr)
    px = im.load()
    out = bytearray()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            out.append(((a & 3) << 6) | ((r & 3) << 4)
                       | ((g & 3) << 2) | (b & 3))
    return bytes(out)


# -----------------------------------------------------------------------
# 2. Decompress the Lua region.
# Cart bytes 0x4300..0x8000 hold the Lua source. Three header types:
#     b":c:\0" — old format
#     b"\0pxa" — PXA bitstream
#     anything else — raw, NUL-terminated
# -----------------------------------------------------------------------
DICT_OLD = "\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_"


def decompress_old(src: bytes) -> str:
    raw_len = (src[4] << 8) | src[5]
    out = bytearray()
    i = 8
    while len(out) < raw_len and i < len(src):
        b = src[i]; i += 1
        if b == 0:
            if i >= len(src): break
            out.append(src[i]); i += 1
        elif b <= 0x3b:
            out.append(ord(DICT_OLD[b - 1]))
        else:
            if i >= len(src): break
            b2 = src[i]; i += 1
            offset = (b - 0x3c) * 16 + (b2 & 0x0f)
            length = (b2 >> 4) + 2
            if offset == 0 or offset > len(out):
                break
            start = len(out) - offset
            for k in range(length):
                if len(out) >= raw_len: break
                out.append(out[start + k])
    return out.decode("latin-1")


class _BitReader:
    def __init__(self, data, start_byte):
        self.d = data
        self.p = start_byte * 8

    def read(self, n):
        v = 0
        for i in range(n):
            byte_idx = self.p >> 3
            bit_idx  = self.p & 7
            if byte_idx >= len(self.d):
                bit = 0
            else:
                bit = (self.d[byte_idx] >> bit_idx) & 1
            v |= bit << i
            self.p += 1
        return v


def decompress_pxa(src: bytes) -> str:
    raw_len = (src[4] << 8) | src[5]
    br = _BitReader(src, 8)
    mtf = list(range(256))
    out = bytearray()
    safety = 0
    while len(out) < raw_len:
        safety += 1
        if safety > raw_len * 50:
            break
        flag = br.read(1)
        if flag == 1:
            nbits = 4
            while br.read(1):
                nbits += 1
                if nbits > 16: break
            idx = br.read(nbits) + (1 << nbits) - 16
            if idx < 0 or idx >= 256: break
            c = mtf[idx]
            out.append(c)
            mtf.pop(idx)
            mtf.insert(0, c)
        else:
            s0 = br.read(1)
            if s0 == 0:
                off_bits = 15
            else:
                s1 = br.read(1)
                off_bits = 5 if s1 else 10
            offset = br.read(off_bits) + 1
            if off_bits == 10 and offset == 1:
                # Embedded raw byte stream until zero terminator.
                while len(out) < raw_len:
                    by = br.read(8)
                    if by == 0: break
                    out.append(by)
                continue
            length = 3
            while True:
                chunk = br.read(3)
                length += chunk
                if chunk != 7: break
            if offset == 0 or offset > len(out): break
            start = len(out) - offset
            for k in range(length):
                if len(out) >= raw_len: break
                out.append(out[start + k])
    return out.decode("latin-1")


def extract_lua(cart: bytes) -> str:
    code = cart[0x4300:0x8000]
    if code[:4] == b":c:\0":
        return decompress_old(code)
    if code[:4] == b"\0pxa":
        return decompress_pxa(code)
    nul = code.find(b"\0")
    if nul < 0: nul = len(code)
    return code[:nul].decode("latin-1")


# -----------------------------------------------------------------------
# 3. Build the .p8 text cart from cart bytes + Lua source.
# Sections:
#   __lua__   raw lua text
#   __gfx__   128 lines, 128 hex chars (4bpp pixels, low nibble first)
#   __gff__   2 lines, 256 hex chars
#   __label__ 128 lines, 128 hex chars (lifted from 0x6000 framebuffer)
#   __map__   32 lines, 256 hex chars
#   __sfx__   64 lines, 168 hex chars each
#   __music__ 64 lines, "FL XX XX XX XX"
# -----------------------------------------------------------------------
def gfx_section(rom: bytes) -> list:
    """0x0000..0x1fff = 128*128 4bpp pixels, low nibble first."""
    lines = []
    for row in range(128):
        chars = []
        for col in range(0, 128, 2):
            b = rom[row * 64 + (col >> 1)]
            chars.append("%x" % (b & 0x0f))
            chars.append("%x" % ((b >> 4) & 0x0f))
        lines.append("".join(chars))
    return lines


def gff_section(gff: bytes) -> list:
    return [gff[i*128:(i+1)*128].hex() for i in range(2)]


def map_section(mapmem: bytes) -> list:
    """upper-half map at 0x2000..0x2fff: 32 rows of 128 bytes."""
    return [mapmem[i*128:(i+1)*128].hex() for i in range(32)]


def label_section(fb: bytes) -> list:
    """The label is the framebuffer at 0x6000..0x7fff (4bpp 128x128)."""
    lines = []
    for row in range(128):
        chars = []
        for col in range(0, 128, 2):
            b = fb[row * 64 + (col >> 1)]
            chars.append("%x" % (b & 0x0f))
            chars.append("%x" % ((b >> 4) & 0x0f))
        lines.append("".join(chars))
    return lines


def sfx_section(sfx: bytes) -> list:
    """64 lines, 168 hex chars each: 4-byte header + 32 notes × 5 chars."""
    lines = []
    for i in range(64):
        entry = sfx[i*68:(i+1)*68]
        if len(entry) < 68:
            entry = entry + bytes(68 - len(entry))
        ed   = entry[0]
        spd  = entry[1]
        ls   = entry[2]
        le   = entry[3]
        head = "%02x%02x%02x%02x" % (ed, spd, ls, le)
        notes = []
        for n in range(32):
            lo = entry[4 + n*2]
            hi = entry[4 + n*2 + 1]
            word = lo | (hi << 8)
            pitch    = word & 0x3f
            waveform = (word >> 6) & 0x7
            volume   = (word >> 9) & 0x7
            effect   = (word >> 12) & 0x7
            # 5 hex chars: 2 for pitch + 1 each for waveform/volume/effect
            notes.append("%02x%x%x%x" % (pitch, waveform, volume, effect))
        lines.append(head + "".join(notes))
    return lines


def music_section(music: bytes) -> list:
    out = []
    for i in range(64):
        chunk = music[i*4:(i+1)*4]
        if len(chunk) < 4:
            chunk = chunk + bytes(4 - len(chunk))
        # Flag is the high bits of byte 0 in our convention; for the
        # text export we just store all four bytes verbatim under flag 00.
        out.append("00 %02x%02x%02x%02x" % (chunk[0] & 0x3f, chunk[1], chunk[2], chunk[3]))
    return out


def write_p8_text(out_path: Path, cart: bytes, lua: str):
    rom   = cart[0x0000:0x3000]
    gff   = cart[0x3000:0x3100]
    music = cart[0x3100:0x3200]
    sfx   = cart[0x3200:0x4300]
    fb    = cart[0x6000:0x8000]   # label is the framebuffer dump

    lines = ["pico-8 cartridge // http://www.pico-8.com",
             "version 42",
             "__lua__"]
    lines.extend(lua.splitlines())

    lines.append("__gfx__")
    lines.extend(gfx_section(rom))

    lines.append("__label__")
    lines.extend(label_section(fb))

    lines.append("__gff__")
    lines.extend(gff_section(gff))

    lines.append("__map__")
    map_upper = rom[0x2000:0x3000] if len(rom) >= 0x3000 else bytes(0x1000)
    lines.extend(map_section(map_upper))

    lines.append("__sfx__")
    lines.extend(sfx_section(sfx))

    lines.append("__music__")
    lines.extend(music_section(music))

    out_path.write_text("\n".join(lines) + "\n")


# -----------------------------------------------------------------------
# 4. Save a 128×128 BMP label image cropped from the visible PNG.
# We write 16-bit RGB565 with the bitfield masks set, which is what
# the device's BMP loader expects (it can blit straight to the LCD).
# -----------------------------------------------------------------------
def write_label_bmp(out_path: Path, png_path: Path):
    im = Image.open(png_path).convert("RGB")
    w, h = im.size
    # PICO-8 PNG cart label area sits at (16, 24)..(143, 151) in the
    # 160×205 PNG. Fall back to a centred crop for non-standard sizes.
    if (w, h) == (160, 205):
        crop = im.crop((16, 24, 16 + 128, 24 + 128))
    else:
        cx = (w - 128) // 2 if w >= 128 else 0
        cy = (h - 128) // 2 if h >= 128 else 0
        crop = im.crop((cx, cy, cx + min(128, w), cy + min(128, h)))
        if crop.size != (128, 128):
            new = Image.new("RGB", (128, 128), (0, 0, 0))
            new.paste(crop, (0, 0))
            crop = new

    # Pack 16-bit RGB565, row-major bottom-up (BMP convention).
    data = bytearray()
    pix = crop.load()
    for y in range(127, -1, -1):
        for x in range(128):
            r, g, b = pix[x, y]
            v = ((r & 0xf8) << 8) | ((g & 0xfc) << 3) | (b >> 3)
            data.append(v & 0xff)
            data.append((v >> 8) & 0xff)

    # BMPv4 header with bitfields, BI_BITFIELDS compression (3).
    bf_off = 14 + 40 + 12       # file hdr + info hdr + 3 bitfield masks
    file_size = bf_off + len(data)
    info_hdr = struct.pack(
        "<IiiHHIIiiII",
        40,                # biSize
        128,               # biWidth
        128,               # biHeight (positive = bottom-up)
        1,                 # biPlanes
        16,                # biBitCount
        3,                 # biCompression = BI_BITFIELDS
        len(data),         # biSizeImage
        2835, 2835,        # ppm x/y
        0, 0,              # clrUsed/important
    )
    file_hdr = b"BM" + struct.pack("<IHHI", file_size, 0, 0, bf_off)
    masks = struct.pack("<III", 0xF800, 0x07E0, 0x001F)

    out_path.write_bytes(file_hdr + info_hdr + masks + data)


# -----------------------------------------------------------------------
# 5. Post-process shrinko8's unminified output for the leftover quirks
#    it doesn't translate (rare in practice but real).
# -----------------------------------------------------------------------
_IF_DO_RE = re.compile(r'^(\s*if\b.*\S)\s+do(\s*)$', re.MULTILINE)

# PICO-8 supports `//` as a single-line comment alternative to `--`.
# Only when it appears at the start of a line (after whitespace);
# `x // y` mid-expression remains Lua's integer divide.
_LINE_COMMENT_SLASH_RE = re.compile(r'^(\s*)//', re.MULTILINE)

# `?expr1,expr2,...` at the start of a line is PICO-8 shorthand
# for `print(expr1,expr2,...)`. shrinko8 -U leaves it as-is.
_PRINT_SHORTHAND_RE = re.compile(r'^(\s*)\?(.+)$', re.MULTILINE)

# PICO-8 source uses Unicode arrow / button glyphs as identifiers
# for button constants. Standard Lua's identifier rules forbid
# non-ASCII bytes, so substitute each glyph (UTF-8 encoded) with
# its numeric button index. Stripping any U+FE0F variation
# selector that may follow.
_GLYPH_SUBS = [
    # arrows
    (b'\xe2\xac\x85', b'0'),                            # ⬅  (U+2B05)
    (b'\xe2\x9e\xa1', b'1'),                            # ➡  (U+27A1)
    (b'\xe2\xac\x86', b'2'),                            # ⬆  (U+2B06)
    (b'\xe2\xac\x87', b'3'),                            # ⬇  (U+2B07)
    # buttons
    (b'\xf0\x9f\x85\xbe', b'4'),                        # 🅾  (U+1F17E)
    (b'\xe2\x9d\x8e',     b'5'),                        # ❎  (U+274E)
    # strip the variation selector that often follows the glyph
    (b'\xef\xb8\x8f', b''),                             # ︎  (U+FE0F)
]

def _translate_string_content(src: str) -> str:
    """
    Walk source and rewrite the *content* of every string literal
    so that Lua's lexer will accept it. Two transforms:

    1. PICO-8 P8SCII escape sequences (`\\^`, `\\-`, `\\|`, `\\#`, `\\*`,
       `\\+`, `\\.`, `\\:`) are not valid Lua escapes. Convert each
       to a literal char escape `\\xHH` (the byte value of the symbol
       itself), so the string parses and the bytes survive. The
       cart's print() interpreter sees the literal symbol bytes
       instead of the P8SCII control byte, so visual formatting
       is degraded but text is readable.

    2. Any byte >= 0x80 inside a string literal (e.g. UTF-8 multi-
       byte sequences for special glyphs) is replaced with `\\xHH`.
       Lua's lexer rejects raw high bytes inside `"..."` literals
       in strict mode; the hex escape is always accepted.

    3. Decimal escape `\\NNN` with NNN > 255 is rewritten to `\\x` +
       the byte value modulo 256. Some carts have leftover
       4-digit decimals from older PICO-8 versions.

    Strings: handles `'...'`, `"..."`, and long brackets `[[...]]`
    (which don't process escapes at all — passed through verbatim).
    """
    out = []
    i = 0
    n = len(src)

    # Process raw bytes so we don't have to wrestle with Python's
    # unicode handling for arbitrary cart byte sequences.
    raw = src.encode('latin-1', errors='replace')

    def emit(b):
        out.append(b)

    i = 0
    n = len(raw)
    while i < n:
        c = raw[i:i+1]

        # Line comment — passthrough until newline
        if c == b'-' and i + 1 < n and raw[i+1:i+2] == b'-':
            # Block comment?
            if i + 3 < n and raw[i+2:i+4] == b'[[':
                end = raw.find(b']]', i + 4)
                if end < 0:
                    out.append(raw[i:]); break
                out.append(raw[i:end+2])
                i = end + 2
                continue
            end = raw.find(b'\n', i)
            if end < 0:
                out.append(raw[i:]); break
            out.append(raw[i:end])
            i = end
            continue

        # Long bracket string — no escape processing
        if c == b'[' and i + 1 < n and raw[i+1:i+2] == b'[':
            end = raw.find(b']]', i + 2)
            if end < 0:
                out.append(raw[i:]); break
            out.append(raw[i:end+2])
            i = end + 2
            continue

        # Quoted string — content gets rewritten
        if c == b'"' or c == b"'":
            quote = c
            out.append(quote)
            i += 1
            while i < n:
                ch = raw[i:i+1]
                if ch == quote:
                    out.append(quote)
                    i += 1
                    break
                if ch == b'\n':
                    # Unterminated string — bail and let Lua complain
                    break
                if ch == b'\\' and i + 1 < n:
                    nxt = raw[i+1:i+2]
                    nb  = raw[i+1]
                    # Lua-standard single-char escapes pass through
                    if nxt in (b'a', b'b', b'f', b'n', b'r', b't',
                                b'v', b'\\', b'"', b"'", b'\n', b'0',
                                b'1', b'2', b'3', b'4', b'5', b'6',
                                b'7', b'8', b'9', b'x', b'z'):
                        # For decimal escapes, validate the value.
                        if nxt.isdigit():
                            # Read up to 3 digits
                            j = i + 1
                            digs = b''
                            while j < n and len(digs) < 3 and raw[j:j+1].isdigit():
                                digs += raw[j:j+1]
                                j += 1
                            v = int(digs)
                            if v > 255:
                                # Truncate to byte
                                v = v & 0xff
                                out.append(b'\\x' + ('%02x' % v).encode('ascii'))
                            else:
                                out.append(raw[i:j])
                            i = j
                            continue
                        out.append(raw[i:i+2])
                        i += 2
                        continue
                    # PICO-8 P8SCII escapes — convert to literal char
                    out.append(b'\\x' + ('%02x' % nb).encode('ascii'))
                    i += 2
                    continue
                # Raw high byte → hex escape
                if raw[i] >= 0x80:
                    out.append(b'\\x' + ('%02x' % raw[i]).encode('ascii'))
                    i += 1
                    continue
                out.append(ch)
                i += 1
            continue

        out.append(c)
        i += 1

    return b''.join(out).decode('latin-1')


def _strip_code_highbytes(src: str) -> str:
    """
    Walk source and replace any UTF-8 multi-byte sequence (any
    byte >= 0x80) in CODE state with `0`. PICO-8 source can use
    special-character glyphs as inline integer constants (e.g.
    `fillp(▒)` where `▒` is P8SCII byte 0x97 = 151). Lua's lexer
    rejects raw high bytes outside strings entirely. Replacing
    with `0` parses cleanly but loses the constant's value, so
    fill patterns / glyph-driven logic will visually degrade.

    Strings and comments are passed through unchanged — those are
    handled by _translate_string_content.
    """
    raw = src.encode('latin-1', errors='replace')
    out = bytearray()
    i = 0
    n = len(raw)
    while i < n:
        b = raw[i]
        # Line comment: passthrough
        if b == 0x2d and i + 1 < n and raw[i+1] == 0x2d:  # --
            if i + 3 < n and raw[i+2] == 0x5b and raw[i+3] == 0x5b:  # --[[
                end = raw.find(b']]', i + 4)
                if end < 0:
                    out += raw[i:]; break
                out += raw[i:end+2]
                i = end + 2
                continue
            end = raw.find(b'\n', i)
            if end < 0:
                out += raw[i:]; break
            out += raw[i:end]
            i = end
            continue
        # Long bracket string
        if b == 0x5b and i + 1 < n and raw[i+1] == 0x5b:  # [[
            end = raw.find(b']]', i + 2)
            if end < 0:
                out += raw[i:]; break
            out += raw[i:end+2]
            i = end + 2
            continue
        # Quoted string
        if b == 0x22 or b == 0x27:                         # " or '
            quote = b
            out.append(b)
            i += 1
            while i < n:
                if raw[i] == 0x5c and i + 1 < n:           # \
                    out += raw[i:i+2]
                    i += 2
                    continue
                if raw[i] == quote:
                    out.append(quote)
                    i += 1
                    break
                if raw[i] == 0x0a:
                    break
                out.append(raw[i])
                i += 1
            continue
        # Code state: high byte → numeric 0
        if b >= 0x80:
            # Skip the entire UTF-8 sequence (1-4 bytes)
            if   b < 0xc0: skip = 1
            elif b < 0xe0: skip = 2
            elif b < 0xf0: skip = 3
            else:          skip = 4
            out += b'0'
            i += skip
            continue
        out.append(b)
        i += 1
    return out.decode('latin-1')


def _translate_dialect_operators(src: str) -> str:
    """
    Walk source character by character with a string/comment state
    machine and translate PICO-8-only operators to their Lua 5.4
    equivalents:
      - `\\`     PICO-8 integer divide   → `//`
      - `^^`    PICO-8 binary XOR        → `~`  (Lua 5.4 bitwise XOR)
      - `@addr` PICO-8 peek shorthand    → `peek(addr)`
      - `%addr` PICO-8 peek2 shorthand   → `peek2(addr)`
      - `$addr` PICO-8 peek4 shorthand   → `peek4(addr)`
    Substitutions are skipped inside string literals (`'...'`,
    `"..."`, `[[...]]`) and comments (`--...`, `--[[...]]`).
    """
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]

        # Line comment
        if c == '-' and i + 1 < n and src[i + 1] == '-':
            # Maybe block comment --[[
            if i + 3 < n and src[i + 2] == '[' and src[i + 3] == '[':
                end = src.find(']]', i + 4)
                if end < 0:
                    out.append(src[i:])
                    break
                out.append(src[i:end + 2])
                i = end + 2
                continue
            # Line comment to end of line
            end = src.find('\n', i)
            if end < 0:
                out.append(src[i:])
                break
            out.append(src[i:end])
            i = end
            continue

        # Long-bracket string [[ ... ]]
        if c == '[' and i + 1 < n and src[i + 1] == '[':
            end = src.find(']]', i + 2)
            if end < 0:
                out.append(src[i:])
                break
            out.append(src[i:end + 2])
            i = end + 2
            continue

        # Quoted strings — preserve verbatim, including escapes
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
                if src[j] == '\n':
                    break
                j += 1
            out.append(src[i:j])
            i = j
            continue

        # Code-state substitutions
        # 0. PICO-8 binary literals: `0b1010`, `0b1010.1010` (fixed
        #    point with 1/2-power fractional bits), and `_` digit
        #    separators. Lua 5.4 has no binary literal syntax at all,
        #    so emit a decimal value. Standard hex literals (`0x...`)
        #    are passed through verbatim — Lua handles them.
        if c == '0' and i + 1 < n and (src[i + 1] == 'b' or src[i + 1] == 'B'):
            # Make sure the previous char isn't an identifier char,
            # otherwise we might be inside a longer identifier name.
            prev_id = i > 0 and (src[i - 1].isalnum() or src[i - 1] == '_')
            if not prev_id:
                j = i + 2
                int_bits = []
                while j < n and (src[j] in '01_'):
                    if src[j] != '_':
                        int_bits.append(src[j])
                    j += 1
                frac_bits = []
                if j < n and src[j] == '.' and j + 1 < n and src[j + 1] in '01':
                    j += 1
                    while j < n and (src[j] in '01_'):
                        if src[j] != '_':
                            frac_bits.append(src[j])
                        j += 1
                if int_bits or frac_bits:
                    int_val  = int(''.join(int_bits) or '0', 2)
                    frac_val = 0.0
                    if frac_bits:
                        frac_val = sum(int(b) * (2.0 ** -(k + 1))
                                       for k, b in enumerate(frac_bits))
                    if frac_bits:
                        out.append(repr(int_val + frac_val))
                    else:
                        out.append(str(int_val))
                    i = j
                    continue

        # 1. `\` integer divide → `//`. Make sure we don't grab a
        #    backslash that's part of an unrecognised escape inside a
        #    string — but we already handled strings above, so any
        #    backslash here is in code.
        if c == '\\':
            out.append('//')
            i += 1
            continue

        # 2. `^^` XOR → `~` (Lua 5.4 bitwise XOR).
        # Don't touch `^^=` — that's PICO-8's XOR compound assign,
        # left in place for the C-side compound rewriter to expand
        # into `lhs = lhs ~ (rhs)`. Translating `^^` here would
        # leave `~=` which Lua reads as "not equal".
        if c == '^' and i + 1 < n and src[i + 1] == '^':
            if i + 2 < n and src[i + 2] == '=':
                out.append('^^=')
                i += 3
                continue
            out.append('~')
            i += 2
            continue

        # PICO-8 rotate / logical-shift operators (`>>>`, `<<>`,
        # `>><`) need expression-level rewriting (LHS op RHS →
        # func(LHS, RHS)), which a forward character scan can't do
        # cleanly. Only rtype uses these in our test set, so
        # they're queued for a future token-level pass and we just
        # let the file fail to parse for now.

        # 3. `@expr` peek shorthand → `peek(expr)` for one byte. The
        #    expression is a simple primary: identifier, number, or
        #    parenthesised group. We grab the smallest expression
        #    that makes sense.
        if c == '@' or c == '%' or c == '$':
            # Skip standalone uses of @ in invalid contexts — only
            # rewrite when followed by identifier/number/(.
            if i + 1 < n and (src[i + 1].isalnum() or src[i + 1] in '_('):
                func = {'@': 'peek', '%': 'peek2', '$': 'peek4'}[c]
                out.append(f'{func}(')
                # Find end of primary expression
                j = i + 1
                if src[j] == '(':
                    # Balanced paren group
                    depth = 1
                    j += 1
                    while j < n and depth > 0:
                        if src[j] == '(': depth += 1
                        elif src[j] == ')': depth -= 1
                        if depth > 0: j += 1
                    out.append(src[i + 2:j])  # inside the parens
                    out.append(')')
                    i = j + 1
                else:
                    # Identifier / number / dotted chain
                    while j < n and (src[j].isalnum() or src[j] in '_.'):
                        j += 1
                    out.append(src[i + 1:j])
                    out.append(')')
                    i = j
                continue

        out.append(c)
        i += 1
    return ''.join(out)


def post_fix_lua(text: str) -> str:
    """
    Translate the PICO-8 dialect bits that shrinko8 -U leaves
    behind:
      - `if cond do ... end` → `if cond then ... end`
      - `?expr` print shorthand → `print(expr)`
      - PICO-8 operators (\\ ^^ @ % $) → Lua equivalents
      - Unicode button glyph identifiers → numeric button indices
    """
    # 1. PICO-8 `//` line comments → Lua `--` (only at start of
    #    line; mid-expression `//` is Lua's integer divide).
    text = _LINE_COMMENT_SLASH_RE.sub(lambda m: m.group(1) + '--', text)

    # 2. if cond do → if cond then
    def _if_do_sub(m):
        return f"{m.group(1)} then{m.group(2)}"
    text = _IF_DO_RE.sub(_if_do_sub, text)

    # 2. `?expr` → `print(expr)`
    def _print_sub(m):
        return f"{m.group(1)}print({m.group(2)})"
    text = _PRINT_SHORTHAND_RE.sub(_print_sub, text)

    # 3. UTF-8 button glyphs → numeric indices (must run BEFORE
    #    string content translation, so the in-code identifier
    #    glyphs get rewritten before we touch any string contents).
    raw = text.encode('latin-1', errors='replace')
    for needle, replacement in _GLYPH_SUBS:
        raw = raw.replace(needle, replacement)
    text = raw.decode('latin-1')

    # 4. PICO-8-only operators → Lua equivalents
    text = _translate_dialect_operators(text)

    # 5. String literal contents — convert P8SCII escapes and high
    #    bytes to \xHH so Lua's lexer accepts them
    text = _translate_string_content(text)

    # 6. Any high-byte UTF-8 sequence still in CODE positions
    #    becomes the number 0 — see _strip_code_highbytes for the
    #    rationale and limitations.
    text = _strip_code_highbytes(text)

    return text


# -----------------------------------------------------------------------
# 6. Driver
# -----------------------------------------------------------------------
def shrinko8_unminify(png_path: Path, out_p8: Path) -> None:
    """Run shrinko8 -U on the .p8.png and write the unminified .p8."""
    if not SHRINKO8.exists():
        raise FileNotFoundError(
            f"vendored shrinko8 not found at {SHRINKO8}. "
            "tools/shrinko8/ should contain the MIT-licensed sources.")
    result = subprocess.run(
        [sys.executable, str(SHRINKO8), "-U", str(png_path), str(out_p8)],
        capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"shrinko8 failed: {result.stderr.strip() or result.stdout.strip()}")


def main():
    if len(sys.argv) != 3:
        print("usage: p8png_extract.py <input_dir> <output_dir>",
              file=sys.stderr)
        sys.exit(1)

    src_dir = Path(sys.argv[1])
    dst_dir = Path(sys.argv[2])
    dst_dir.mkdir(parents=True, exist_ok=True)

    n_ok = n_fail = 0
    has_luac = LUAC54.exists()
    if not has_luac:
        print("warn: tools/luac54 not found — skipping bytecode "
              "precompilation. Build it with: gcc -O2 -DLUA_32BITS=1 "
              "-Ilua lua/luac.c lua/*.c -lm -o tools/luac54",
              file=sys.stderr)

    for png in sorted(src_dir.glob("*.p8.png")):
        stem = png.name[:-len(".p8.png")]
        out_p8  = dst_dir / f"{stem}.p8"
        out_bmp = dst_dir / f"{stem}.bmp"
        out_luac = dst_dir / f"{stem}.luac"
        out_rom  = dst_dir / f"{stem}.rom"
        try:
            # 1. shrinko8 unminify → .p8
            shrinko8_unminify(png, out_p8)

            # 2. Post-fix dialect operators + string escapes
            text = out_p8.read_text(encoding="latin-1")
            text = post_fix_lua(text)

            # 3. Extract the __lua__ section for further rewriting.
            # Section markers are specific names on their own line —
            # NOT any line starting with `__` (that would catch Lua
            # metamethods like `__index`, `__tostring`, etc).
            _SECTIONS = {'__lua__', '__gfx__', '__gff__', '__map__',
                         '__sfx__', '__music__', '__label__'}
            lines = text.split('\n')
            lua_lines = []
            in_lua = False
            for line in lines:
                stripped = line.strip()
                if stripped == '__lua__':
                    in_lua = True
                    continue
                if stripped in _SECTIONS and in_lua:
                    in_lua = False
                    continue
                if in_lua:
                    lua_lines.append(line)
            lua_src = '\n'.join(lua_lines)

            # 4. Token-based rewrite: != → ~=, compound assigns, binary literals
            lua_clean = rewrite_pico8_to_lua(lua_src)

            # 5. Precompile to bytecode (required — device only accepts .luac)
            if not has_luac:
                raise FileNotFoundError(
                    "tools/luac54 not found — required for precompilation")
            tmp_lua = dst_dir / f"{stem}_tmp.lua"
            tmp_lua.write_text(lua_clean, encoding="latin-1")
            result = subprocess.run(
                [str(LUAC54), "-o", str(out_luac), str(tmp_lua)],
                capture_output=True, text=True)
            tmp_lua.unlink()
            if result.returncode != 0:
                err = result.stderr.strip() or result.stdout.strip()
                print(f"  WARN luac: {stem}: {err}", file=sys.stderr)
                out_luac.unlink(missing_ok=True)

            # 7. Extract binary ROM (17 KB: gfx + gff + map + sfx + music)
            # from the cart bytes via the PNG steganography
            cart_bytes = png_to_cart_bytes(png)
            out_rom.write_bytes(cart_bytes[:0x4300])

            # 8. BMP label thumbnail
            write_label_bmp(out_bmp, png)

            # Clean up intermediate .p8 — device only needs .luac + .rom + .bmp
            out_p8.unlink(missing_ok=True)

            luac_ok = out_luac.exists()
            print(f"  ok  {png.name}"
                  f"  [luac:{'✓' if luac_ok else '✗'}]")
            n_ok += 1
        except Exception as e:
            print(f"  ERR {png.name}: {e}", file=sys.stderr)
            import traceback; traceback.print_exc()
            n_fail += 1

    print(f"\n{n_ok} ok, {n_fail} failed", file=sys.stderr)
    sys.exit(0 if n_fail == 0 else 2)


if __name__ == "__main__":
    main()
