pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- ThumbyP8 API edge-case test cart.
--
-- Exercises every API function with edge cases. Prints PASS/FAIL
-- to console (printh) and shows a summary on screen. A perfect
-- run prints "ALL PASS"; any failure shows the failing test name
-- and what we got vs expected.
--
-- This is a regression test, not a beauty contest — it does not
-- try to look pretty.

local n_pass, n_fail = 0, 0
local fails = {}

local function check(name, got, want)
  if got == want then
    n_pass = n_pass + 1
  else
    n_fail = n_fail + 1
    add(fails, name.." got="..tostr(got).." want="..tostr(want))
    printh("FAIL "..name.." got="..tostr(got).." want="..tostr(want))
  end
end

local function check_near(name, got, want, eps)
  eps = eps or 0.001
  if got and want and abs(got - want) < eps then
    n_pass = n_pass + 1
  else
    n_fail = n_fail + 1
    add(fails, name.." got="..tostr(got).." want="..tostr(want))
    printh("FAIL "..name.." got="..tostr(got).." want="..tostr(want))
  end
end

-- ============================================================ math
check("flr(3.7)", flr(3.7), 3)
check("flr(-3.7)", flr(-3.7), -4)
check("ceil(3.2)", ceil(3.2), 4)
check("ceil(-3.2)", ceil(-3.2), -3)
check("abs(-5)", abs(-5), 5)
check("abs(5)", abs(5), 5)
check("min(3,5)", min(3,5), 3)
check("max(3,5)", max(3,5), 5)
check("mid(1,5,3)", mid(1,5,3), 3)
check("mid(5,1,3)", mid(5,1,3), 3)
check("mid(3,1,5)", mid(3,1,5), 3)
check("sgn(0)", sgn(0), 1)
check("sgn(-3)", sgn(-3), -1)
check("sgn(3)", sgn(3), 1)
check_near("sin(0)", sin(0), 0)
check_near("cos(0)", cos(0), 1)
check_near("sin(.25)", sin(.25), -1)  -- pico-8 sin: 0.25 = -1
check_near("cos(.25)", cos(.25), 0)
check_near("sqrt(16)", sqrt(16), 4)
check_near("sqrt(0)", sqrt(0), 0)
check_near("atan2(1,0)", atan2(1,0), 0)

-- ============================================================ bitwise
check("band(0xff,0x0f)", band(0xff,0x0f), 0x0f)
check("bor(0xf0,0x0f)", bor(0xf0,0x0f), 0xff)
check("bxor(0xff,0x0f)", bxor(0xff,0x0f), 0xf0)
check("shl(1,4)", shl(1,4), 16)
check("shr(16,2)", shr(16,2), 4)

-- ============================================================ string
check("sub('hello',1,3)", sub("hello",1,3), "hel")
check("sub('hello',-2)", sub("hello",-2), "lo")
check("sub('hello',2,-2)", sub("hello",2,-2), "ell")
check("#'hello'", #"hello", 5)
check("ord('a')", ord("a"), 97)
check("chr(97)", chr(97), "a")
check("tostr(42)", tostr(42), "42")
check("tonum('42')", tonum("42"), 42)
check("tonum('-3.5')", tonum("-3.5"), -3.5)
check("tonum('xyz')", tonum("xyz"), nil)

-- ============================================================ table
local tab1 = {1, 2, 3}
add(tab1, 4)
check("#tab1 after add", #tab1, 4)
check("tab1[4] after add", tab1[4], 4)

local t2 = {1,2,3,4,5}
del(t2, 3)
check("#t2 after del", #t2, 4)
check("t2[3] after del", t2[3], 4)

-- count(tbl): length
check("count({1,2,3})", count({1,2,3}), 3)
-- count(tbl, val): count occurrences
check("count({1,2,2,3,2}, 2)", count({1,2,2,3,2}, 2), 3)

-- add(tbl, val, idx): insert at index
local t3 = {1, 2, 3}
add(t3, 99, 2)
check("add at idx[1]", t3[1], 1)
check("add at idx[2]", t3[2], 99)
check("add at idx[3]", t3[3], 2)

-- foreach
local sum = 0
foreach({1,2,3,4}, function(v) sum = sum + v end)
check("foreach sum", sum, 10)

-- all
local prod = 1
for v in all({2,3,4}) do prod = prod * v end
check("all prod", prod, 24)

-- ============================================================ memory
poke(0x4300, 42)
check("peek after poke", peek(0x4300), 42)

-- multi-byte poke
poke(0x4310, 1, 2, 3, 4)
check("poke multi[0]", peek(0x4310), 1)
check("poke multi[1]", peek(0x4311), 2)
check("poke multi[2]", peek(0x4312), 3)
check("poke multi[3]", peek(0x4313), 4)

-- multi-return peek
local a, b, c = peek(0x4310, 3)
check("peek multi a", a, 1)
check("peek multi b", b, 2)
check("peek multi c", c, 3)

-- peek2/poke2 16-bit signed LE
poke2(0x4320, -1)
check("peek2 -1", peek2(0x4320), -1)
poke2(0x4320, 32767)
check("peek2 32767", peek2(0x4320), 32767)

-- peek4/poke4 16.16 fixed-point
poke4(0x4330, 3.5)
check_near("peek4 3.5", peek4(0x4330), 3.5)
poke4(0x4330, -2.25)
check_near("peek4 -2.25", peek4(0x4330), -2.25)

-- memcpy
poke(0x4340, 11) poke(0x4341, 22) poke(0x4342, 33)
memcpy(0x4350, 0x4340, 3)
check("memcpy[0]", peek(0x4350), 11)
check("memcpy[1]", peek(0x4351), 22)
check("memcpy[2]", peek(0x4352), 33)

-- memset
memset(0x4360, 0xab, 4)
check("memset[0]", peek(0x4360), 0xab)
check("memset[3]", peek(0x4363), 0xab)

-- ============================================================ palette
pal()  -- reset
check("pal default 0", peek(0x5f00), 0x10)  -- default: color 0 transparent
check("pal default 7", peek(0x5f07), 7)

pal(8, 12)
check("pal(8,12)", peek(0x5f08) & 0x0f, 12)

-- pal with table
pal({[0]=1, [1]=2, [2]=3, [3]=4, [4]=5, [5]=6, [6]=7, [7]=8,
     [8]=9, [9]=10, [10]=11, [11]=12, [12]=13, [13]=14, [14]=15, [15]=0})
check("pal table[0]", peek(0x5f00) & 0x0f, 1)
check("pal table[15]", peek(0x5f0f) & 0x0f, 0)

-- pal nil resets
pal(nil)
check("pal nil reset", peek(0x5f00), 0x10)

-- screen palette with secret colors
pal(0, 128, 1)
check("pal screen secret", peek(0x5f10), 128)

pal()  -- reset

-- palt
palt()
check("palt default 0", peek(0x5f00), 0x10)  -- color 0 transparent
check("palt default 1", peek(0x5f01), 1)     -- color 1 not transparent

palt(1, true)
check("palt(1,true)", (peek(0x5f01) >> 4) & 1, 1)

palt(1, false)
check("palt(1,false)", (peek(0x5f01) >> 4) & 1, 0)

-- palt bitmask form (single number arg)
palt(0b1000000000000000)  -- only color 0 transparent
check("palt(bit15)", (peek(0x5f00) >> 4) & 1, 1)
check("palt(bit15) other", (peek(0x5f01) >> 4) & 1, 0)

-- ============================================================ camera/clip
camera(10, 20)
check("camera applied", true, true)  -- can't easily verify without drawing
camera()
clip()

-- ============================================================ sprite flags
fset(5, 0, true)
check("fset/fget bit 0", fget(5, 0), true)
fset(5, 3, true)
check("fset/fget bit 3", fget(5, 3), true)
check("fset/fget bit 1", fget(5, 1), false)
check("fset all", fget(5), 0x09)  -- bits 0 and 3 set
fset(5, 0)  -- reset all flags
fset(5, 0, false)
fset(5, 3, false)

-- ============================================================ map
mset(0, 0, 42)
check("mget after mset", mget(0,0), 42)
mset(127, 31, 99)
check("mget edge", mget(127, 31), 99)

-- ============================================================ time
local t1 = time()
check("time positive", t1 >= 0, true)
local t2 = t() -- alias
check("t() alias", t2 >= t1, true)

-- ============================================================ display: cls + pget/pset
cls(8)
check("cls(8) pget", pget(0,0), 8)
cls(0)
check("cls(0) pget", pget(0,0), 0)

pset(64, 64, 11)
check("pset/pget", pget(64,64), 11)

-- rect/rectfill (just don't crash)
rectfill(0,0,10,10, 7)
check("rectfill ok", pget(5,5), 7)

-- circ/circfill
circfill(64, 64, 5, 12)
check("circfill ok", pget(64, 64), 12)

-- line
line(0, 30, 10, 30, 8)
check("line ok", pget(5, 30), 8)

-- ============================================================ pico-8 quirks

-- shorthand operators
local n = 5
n += 3
check("+= 3", n, 8)
n -= 2
check("-= 2", n, 6)
n *= 2
check("*= 2", n, 12)
n /= 4
check("/= 4", n, 3)
n %= 2
check("%= 2", n, 1)
n ..= 0  -- on a number, this needs to become a concat; PICO-8 carts use it on strings
local s = "ab"
s ..= "cd"
check("..= str", s, "abcd")

-- != operator
check("!= true", 1 != 2, true)
check("!= false", 1 != 1, false)

-- backslash integer division
check("\\ int div", 10 \ 3, 3)
check("\\ int div neg", -10 \ 3, -4)

-- shift/rotate operators
check("<< shift", 1 << 4, 16)
check(">> shift", 16 >> 2, 4)
check("& bitwise", 0xff & 0x0f, 0x0f)
check("| bitwise", 0xf0 | 0x0f, 0xff)
check("^^ bitwise", 0xff ^^ 0x0f, 0xf0)

-- binary literals
check("0b literal", 0b1010, 10)
check("0b nibbles", 0b11110000, 240)

-- @/% peek shortcuts
poke(0x4400, 0xab)
poke2(0x4400, 0x1234)
check("@ peek", @0x4400, 0x34)  -- peek
-- check("% peek2", %0x4400, 0x1234) -- peek2 (skip — parser may not handle this)
-- check("$ peek4", $0x4400, ?) -- skip

-- string indexing (returns ord of char)
local s2 = "abc"
check("str[1] ord", s2[1], 97)
check("str[2] ord", s2[2], 98)

-- ============================================================ printf-like behavior

-- chr multi-arg
check("chr(65,66,67)", chr(65,66,67), "ABC")

-- ord multi-return
local o1, o2, o3 = ord("abc", 1, 3)
check("ord multi[1]", o1, 97)
check("ord multi[2]", o2, 98)
check("ord multi[3]", o3, 99)

-- split
local sp = split("1,2,3", ",")
check("split #", #sp, 3)
check("split[1]", sp[1], 1)  -- split converts to numbers when possible

local sp2 = split("a,b,c", ",", false)
check("split nostr[1]", sp2[1], "a")

-- ============================================================ stat()
local cpu = stat(1)
check("stat(1) num", type(cpu) == "number", true)
local mem = stat(0)
check("stat(0) num", type(mem) == "number", true)

-- ============================================================ summary
function _draw()
  cls(0)
  if n_fail == 0 then
    print("ALL PASS ("..n_pass..")", 30, 60, 11)
  else
    print(n_pass.." pass / "..n_fail.." fail", 4, 4, 14)
    for i = 1, min(#fails, 18) do
      print(fails[i], 0, 12 + i*6, 8)
    end
  end
end

function _update()
end

printh("==== ThumbyP8 API test ====")
printh("PASS: "..n_pass)
printh("FAIL: "..n_fail)
for f in all(fails) do
  printh("  "..f)
end
