pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

--age of ants
--eeooty
--commented code on bbs!
music(63, 2000)

function co(f, g)
  return function(...)
    return f(g(...))
  end
end

function a(v, ...)
  _ENV[v] = {}, ... and a(...)
end

local pspl, rs, us, cp, fm, sfx, foreach, gl = co(pal, split), co(rnd, split), co(unpack, split), co(camera, pal), co(fget, mget), sfx, foreach, _ENV
local unl, unspr, aspl, typs, stp, pc, hlt, diff, title, ls, cx, cy, cvx, cvy, spdr = co(line, us), co(spr, us), co(a, us), {}, split "-9:-20,263:-20,263:148,-9:148", split "1,2,0,3,1,0,2,1,3,0", us "-10,0,63,0,0,30,1,1"

local function p(str, typ, x, y, ...)
  local p1 = {...}
  aspl "p2,p3"
  local obj = {p1, p2, p3, p2, p1 = p1, p2 = p2, p3 = p3, typ = typ, x = x, y = y}
  foreach(split(str, "\n"), function(l)
    local k, v = us(l, "=")
    if v then
      foreach(obj, function(o)
        obj[k], o[k] = v, v
      end)
    end
  end)
  typs[obj.idx or ""], _ENV[obj.var or ""] = obj, obj
  return obj
end

function _update()
  lclk, rclk, llclk, lrclk = llclk and not btn "5", lrclk and not btn "4", btn "5", btn "4", stat "121" and lg()
  if dget "0" > 1 and not ls then
    lclk, rclk = btnp "5", btnp "4"
  end
  if title then
    cx = cx + (cvx)
    cy = cy + (cvy)
    if cx % 256 == 0 then
      cvx = cvx * (-1)
    end
    if cy % 127 == 0 then
      cvy = cvy * (-1)
    end
    if btnp "0" or btnp "1" then
      diff = diff + (btnp() ~ -2)
      diff = diff % (5)
      sfx "18"
    end
    add(pc, deli(btnp "4" and pc, 1))
    if lclk then
      init()
      for k = 1, 3 do
        local r = res[k]
        r.pos, r.col, r.npl, r.diff = del(pi, rnd(pi)), pc[k], us(split "2:1,2:2,2:3,3:2,3:3" [diff + 1], ":")
      end
      foreach(split([[7,64,64
1,49,64
1,77,59
1,59,52
5,61,76]], "\n"), function(s)
        for ply = 1, res1.npl do
          local u, x, y = us(s)
          local dx, dy = us(stp[res[ply].pos], ":")
          res.p2.newg = unit(u, x + dx, y + dy, ply)
        end
      end)
      start()
    else
      pspl "1,5,13,13,13,13,6,2,6,5,3,13,13,0,5"
      return
    end
  end
  cf = cf + (1)
  cf = cf % (60)
  ip()
  if ls then
    poke "0x5f2d"
    if lclk and stat "54" > 56 then
      title, cx, cy = us "1,5,35"
      music "63"
    end
    if rclk then
      ban = ban ~ (240)
    end
    return
  end
  dmap()
  z = split "5,10,15,30,30,60,60,60,60,60,60" [tot // 50]
  aspl "pos,asc,sele"
  upc, hbld, selh, selb, hunit, idl, idlm = cf % z, g(bldgs, mx8, my8, {})
  res1.t = res1.t + (.03333)
  if cf % 30 == 19 then
    for tx = 0, 19 do
      for ty = 0, 12 do
        local x, y = tx // .39585, ty // .37505
        sset(109 + tx, 72 + ty, g(exp, x, y) and rc[g(viz, x, y, "e") .. fm(x, y)] or 14)
      end
    end
  end
  if upc == 0 then
    viz, nviz = nviz, {}
    for k in next, exp do
      if mid(k, 8191) == k and k % 256 < 48 then
        local x, y = k & 255, k // 256
        mset(x + 48, y, viz[k] or mget(x, y))
      end
    end
  end
  foreach(prj, function(b)
    local typ = b.typ
    if norm(b.p1, b, typ.ps) then
      del(prj, b)
      for u in all(units) do
        if u.ap ~= b.p1[3] and int(u.r, {b.x, b.y, b.x, b.y}, typ.aoe) then
          dmg(typ, u)
          if typ.aoe == 0 then
            break
          end
          if hlv.var then
            hi(p([[f=2
c=13]], b.x, b.y))
          end
        end
      end
    end
  end)
  foreach(units, tick)
  if selx then
    sel = selh or selb or sele
  end
  sel1, nsel, st = sel[1], #sel
  fsel(function(s)
    st = (not st or s.idx == st.idx) and s.typ or {}
  end)
  for i = 2, npl do
    if upc == i and units[i].a then
      aif(ais[i])
    end
  end
end

function bnr(a, t, st, cx)
  camera(cx)
  local s = res1.t // 1 % 60
  rectfill(us "0,88,128,107,9")
  line(?split ",\xe2\x81\xb6j2l\xe2\x81\xb5fk\xc2\xb29 \xe2\x81\xb5dc\xe2\x81\xb4e\xc2\xb29\xe1\xb6\x9c5 ,\xe2\x81\xb6j2l\xe2\x81\xb5fk\xc2\xb29 \xe2\x81\xb5dc\xe2\x81\xb4e\xc2\xb29\xe1\xb6\x9c0 2X " [res1.npl] .. split "easy ai \xe2\x81\xb6y0\xe2\x81\xb5dm\xc2\xb29 ,normal ai \xe2\x81\xb4m\xe2\x81\xb6x1 \xe2\x81\xb6y0\xe2\x81\xb5dm\xc2\xb29 ,hard ai \xe2\x81\xb6y0\xe2\x81\xb5dm\xc2\xb29 " [res1.diff] - 3, us "80,8,80,9")
  print("\xe2\x81\xb6jll\xc2\xb29\xe2\x81\xb4e \xe2\x81\xb5df\xe2\x81\xb6xz \xe2\x81\xb6x4\xe2\x81\xb6jll\xe2\x81\xb5ke\xe1\xb6\x9c5\xe2\xa7\x97\xc2\xb3h" .. (res1.t < 600 and "0" or "") .. res1.t // 60 .. (s < 10 and ":0" or ":") .. s .. " \xe2\x81\xb6y0\xe2\x81\xb5dm\xc2\xb29 \xe2\x81\xb6jll\xe2\x81\xb5fk\xc2\xb29 ")
  pspl(res1.col .. ",2,3,4,5,6,7,8,9,10,11,12,13,0")
  sspr(64 + pack(48, cf // 5 % 3 * 16)[a], us "0,16,8,12,90,32,16")
  print("\xe2\x81\xb6j7r\xe2\x81\xb6y0\xe2\x81\xb5eh\xc2\xb29 \xe2\x81\xb6jqr\xe2\x81\xb5eh \xe2\x81\xb6j7r\xe2\x81\xb4i\xe2\x81\xb6y7\xc2\xb29\xe2\x81\xb5ff\xe1\xb6\x9c4\xe2\x81\xb6x1\xe2\x81\xb4f \xe2\x81\xb4h\xe2\x81\xb6x4 " .. st)
  print("\xe2\x81\xb6jdn\xe2\x81\xb4h\xe2\x81\xb6w\xe2\x81\xb6t\xe1\xb6\x9ca" .. t)
  cp()
end

function draw_map(o)
  camera(cx % 8, cy % 8)
  map(cx / 8 + o, cy / 8, us(ls and "0,0,17,17" or "0,0,17,15"))
end

function _draw()
  draw_map "0"
  if title then
    camera()
    local x = 64 + t() // .5 % 2 * 16
    pspl "0,5,0,0,0,0,0,0,0,0,0,0,0,5"
    sspr(x, us "0,16,8,25,18,32,16")
    sspr(x, us "0,16,8,74,18,32,16,1")
    pspl "1,14,3,4,4,6,7,8,9,10,11,12,5,0,2"
    pal {pc[1]}
    sspr(x, us "0,16,8,25,17,32,16")
    pal {pc[2]}
    sspr(x, us "0,16,8,74,17,32,16,1")
    print("\xe2\x81\xb6j79\xe2\x81\xb5jj\xe2\x81\xb6w\xe2\x81\xb6t\xe1\xb6\x9c0age  ants\xe2\x81\xb6j99\xc2\xb3j\xe2\x81\xb6-w\xe2\x81\xb6-t\xe2\x81\xb6y7.         \xe2\x81\xb6x3 .\xe2\x81\xb6x2     .\xe2\x81\xb6joa\xe2\x81\xb5ij\xe2\x81\xb6x4\xe2\x81\xb6y6.\xe2\x81\xb6j79\xe2\x81\xb5ii\xe2\x81\xb6w\xe2\x81\xb6t\xe1\xb6\x9c7age  ants\xe2\x81\xb6joa\xe2\x81\xb5hi\xe2\x81\xb6-w\xe2\x81\xb6-t.\xe2\x81\xb6j98\xe2\x81\xb5ij\xe2\x81\xb6y7.         \xe2\x81\xb6x3 .\xe2\x81\xb6x2     .\xe2\x81\xb6jea\xe2\x81\xb5ih\xe1\xb6\x9c0\xe2\x81\xb6x4\xe2\x81\xb6y6\xe2\x81\xb6:0060123515120800\xe2\x81\xb6jea\xc2\xb3i\xe1\xb6\x9c7\xe2\x81\xb6:0060123515120800\xe2\x81\xb6jh8\xe2\x81\xb5hi\xe1\xb6\x9cd\xe2\x81\xb6x2.\xe2\x81\xb6x3 \xe2\x81\xb6x2.\xe2\x81\xb6j78\xe2\x81\xb5hi.\xe2\x81\xb6x3 \xe2\x81\xb6x2.\xe2\x81\xb6jbf\xc2\xb3i\xe1\xb6\x9c0\xe2\x81\xb6x4difficulty:\xe2\x81\xb6jbe\xe2\x81\xb5ij\xe1\xb6\x9ccdifficulty:\xe2\x81\xb6j8m\xe1\xb6\x9c0press 5 to start\xe2\x81\xb6j8l\xe2\x81\xb4j\xe1\xb6\x9c9press 5 to start\xe2\x81\xb6jqt\xe2\x81\xb4h\xe1\xb6\x9c0V1.9\xe2\x81\xb6jqt\xe1\xb6\x9c6V1.9\xe2\x81\xb6j2t\xe2\x81\xb4h\xe1\xb6\x9c0EEOOTY\xe2\x81\xb6j2t\xe1\xb6\x9c6EEOOTY\xe2\x81\xb6j8p\xe1\xb6\x9c0PAUSE FOR OPTIONS\xe2\x81\xb6j8o\xe2\x81\xb4j\xe1\xb6\x9caPAUSE FOR OPTIONS\xe2\x81\xb6jeh\xe2\x81\xb5ji\xe1\xb6\x9c6\0")
    print(split "\xc2\xb38\xe1\xb6\x9c0\xe2\x97\x80\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x97\x80\xe2\x81\xb4h \xe1\xb6\x9c0easy\xe2\x81\xb50f\xe1\xb6\x9cbeasy \xe2\x81\xb4h\xe1\xb6\x9c0\xe2\x96\xb6\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x96\xb6,\xc2\xb34\xe1\xb6\x9c0\xe2\x97\x80\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x97\x80\xe2\x81\xb4h \xe1\xb6\x9c0normal\xc2\xb30\xe2\x81\xb58f\xe1\xb6\x9canormal \xe2\x81\xb4h\xe1\xb6\x9c0\xe2\x96\xb6\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x96\xb6,\xc2\xb38\xe1\xb6\x9c0\xe2\x97\x80\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x97\x80\xe2\x81\xb4h \xe1\xb6\x9c0hard\xe2\x81\xb50f\xe1\xb6\x9c9hard \xe2\x81\xb4h\xe1\xb6\x9c0\xe2\x96\xb6\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x96\xb6,\xc2\xb30\xc2\xb3e\xe1\xb6\x9c0\xe2\x97\x80\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x97\x80\xe2\x81\xb4h \xe1\xb6\x9c02 normals\xc2\xb30\xc2\xb30\xe2\x81\xb5cf\xe1\xb6\x9c22 normals \xe2\x81\xb4h\xe1\xb6\x9c0\xe2\x96\xb6\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x96\xb6,\xc2\xb32\xe1\xb6\x9c0\xe2\x97\x80\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x97\x80\xe2\x81\xb4h \xe1\xb6\x9c02 hards\xc2\xb30\xe2\x81\xb54f\xe1\xb6\x9c82 hards \xe2\x81\xb4h\xe1\xb6\x9c0\xe2\x96\xb6\xe2\x81\xb5cf\xe1\xb6\x9c7\xe2\x96\xb6" [diff + 1])
    return
  end
  aspl "bfog,afog,btns"
  for u in all(units) do
    if u.on or ls then
      if not ls and not g(viz, u.x8, u.y8) and u.disc then
        add(afog, u)
      elseif u.bldg or u.dead then
        du(u)
      else
        add(bfog, u)
      end
    end
  end
  foreach(bfog, du)
  local cf5, dt = cf // 5, t() - hlt
  camera(cx, cy)
  foreach(prj, function(_ENV)
    sspr(typ.s + cf5 % 2 * 2, 96, 2, 2, x, y)
  end)
  if ls then
    br()
    bnr(ls, split "defeat\xe2\x81\xb6x2....\xe2\x81\xb6x4\xe2\x81\xb6jdn\xe1\xb6\x9c1defeat\xe2\x81\xb6x2....,victory!\xe2\x81\xb6jdn\xe1\xb6\x9c1victory!" [ls], stat "54" > 56 and "press 5 for menu \xe2\x81\xb4f\xe2\x81\xb6x1 " or "thx for playing\xe1\xb6\x9c8\xe2\x99\xa5 \xe2\x81\xb4f\xe2\x81\xb6x1 ", ban)
    return
  end
  pspl "0,5,13,13,13,13,6,2,6,6,13,13,13,0,5"
  draw_map "48"
  _pal, pal = pal, max
  foreach(afog, du)
  pal = _pal
  pal()
  fillp "23130.5"
  for x = cx // 8, cx // 8 + 16 do
    for y = cy // 8, cy // 8 + 13 do
      local i = x | y << 8

      local function b(a, col)
        color(col)
        camera(cx - x * 8, cy - y * 8)
        return a[i - 1] and unl "-1,0,-1,7", a[i - 256] and unl "0,-1,7,-1", a[i + 256] and unl "0,8,7,8", a[i + 1] and unl "8,0,8,7"
      end

      if not exp[i] then
        b(exp)
      elseif not viz[i] then
        b(viz, fm(x, y) >= 128 or 5)
      end
    end
  end
  camera(cx, cy)
  fillp(selx and rect(unpack(sb)), sel1 and sel1.rx and spr(64 + cf5 % 3, sel1.rx - 2, sel1.ry - 5))
  if dt > .5 then
    p "var=hlv"
  elseif hlv.f then
    circ(hlv.typ, hlv.x, min(hlv.f / dt, 4), hlv.c)
  elseif mid(dt, .1, .25) ~= dt and hlv.r then
    rect(unpack(hlv.r))
  end
  dm()
  cp()
  if not hlv.p1 then
    circ(unpack(hlv))
  end
  if to_bld then
    camera(cx - mx8 * 8, cy - my8 * 8)
    pspl(bd() or "8,8,8,8,8,8,8,8,8,8,8,8,8,8,8")
    if amy >= 104 then
      camera(4 - amx, 4 - amy)
    else
      fillp "23130.5"
      rect(to_bld.fw, to_bld.h, us "-1,-1,3")
      fillp()
    end
    local _ENV = to_bld
    sspr(rt_x, rt_y, fw, h)
    pal()
  end
  camera(-amx, -amy)
  if dget "0" > 1 then
    spr(hbtn and pset(us "-1,4,5") and 188 or amy < 104 and sel1 and sel1.hu and ((to_bld or cbl() or cr "1") and 190 or cgt() and 189 or cdr() and 191 or ctk() and (st.mnk and 185 or 187)) or 186)
  end
end

local function rt(_ENV)
  st, disc = p [[t=rt
agg=1
idl=1]], bldg and disc
end

function cpy(typ, _ENV)
  typ.reqs = reqs | typ.bq == reqs
  return r >= typ.r and g >= typ.g and b >= typ.b and (not typ.unit or pop < min(pl, 99)) and typ.reqs
end

local function pay(typ, dir, _ENV)
  r = r - (typ.r * dir)
  g = g - (typ.g * dir)
  b = b - (typ.b * dir)
  if typ.unit then
    pop = pop + (dir)
  end
end

local function rb(b)
  local x, y = b.x8, b.y8

  local function reg(xx, yy)
    s(bldgs, xx, yy, b.a and b)
    if b.dead then
      s(exp, xx, yy, 1, b.typ.f and y == yy and mset(xx, yy, 69))
      s(dms.d, xx, yy)
    elseif b.drop then
      s(dms.d, xx, yy, {xx, yy})
    end
  end

  reg(x, y, b.h8 or reg(x, y - 1), b.w8 or reg(x + 1, y, b.h8 or reg(x + 1, y - 1)))
  if not b.ct and not b.farm then
    qdm "d"
    b.pres.reqs = b.pres.reqs | (b.bmap)
  end
end

function g(a, x, y, def)
  return a[x | y << 8] or def
end

function s(a, x, y, v)
  a[x | y << 8] = v
end

function hi(v)
  hlt, hlv = t(), v
end

function int(r1, r2, p)
  return r1[1] - p < r2[3] and r1[3] + p > r2[1] and r1[2] - p < r2[4] and r1[4] + p > r2[2]
end

local function box(_ENV)
  r, x8, y8, dmgd, ai, ap, pres = {x - w / 2 - 1, y - h / 2 - 1, x + w / 2, y + h / 2, 8}, x // 8, y // 8, hp < mh, gl.ais[ply], ply | 9, gl.res[ply]
  k, hu = x8 | y8 << 8, not ai
  if not ct then
    hp = hp + (typ.hp - mh)
    mh = typ.hp
  end
  return _ENV
end

function tu(tx, ty)
  return box(p([[ply=0
ais=
hp=0
mh=0
ct=1
w=8
h=8]], nil, tx * 8 + 4, ty * 8 + 4))
end

local function dist(dx, dy)
  local x, y = dx >> 31, dy >> 31
  local a0, b0 = dx + x ~ x, dy + y ~ y
  return a0 > b0 and a0 * .9609 + b0 * .3984 or b0 * .9609 + a0 * .3984
end

local function sr(fn, x, y, n, na)
  local n, e = n or 1
  for dx = -n, n do
    for dy = -n, n do
      local xx, yy = x + dx, y + dy
      if min(xx, yy) >= 0 and xx < 48 and yy < 32 and (na or acc(xx, yy)) then
        e = e or dx | dy ~= 0
        if fn then
          fn {xx, yy, d = dx & dy ~= 0 and 1.4 or 1, k = xx | yy << 8}
        end
      end
    end
  end
  return e
end

function afarm()
  local _ENV = hbld
  return farm and not exp and not fmr and not ct
end

function cgt()
  local t = mget(mx8, my8)
  return (st.ant and (rq[t] or afarm()) or st.mnk == t) and g(exp, mx8, my8) and sr(nil, mx8, my8)
end

function ctk()
  return sel1.atk and hunit and (not hunit.hu or st.mnk and hunit.dmgd and not hunit.bldg) and g(viz, mx8, my8, hunit.disc)
end

function cbl()
  return hbld.hu and hbld.hp < hbld.typ.hp and (st.ant or hbld.web and st.sp)
end

function norm(it, _ENV, f)
  local dx, dy = it[1] - x, it[2] - y
  _d, dir = dist(dx, dy) + .0001, gl.sgn(dx)
  x = x + (dx * f / _d)
  y = y + (dy * f / _d)
  return _d < 1
end

function acc(x, y, strict)
  local _ENV = g(bldgs, x, y)
  return not fget(mget(x, y), 0) and (not _ENV or web and spdr or not strict and (ct or farm))
end

function bd()
  return acc(mx8, my8, 1) and (to_bld.h8 or acc(mx8, my8 + 1, 1)) and (to_bld.w8 or acc(mx8 + 1, my8, 1) and acc(mx8 + 1, my8 + 1, 1))
end

function dmg(typ, to)
  to.hp = to.hp - (typ.atk * dmt[typ.atk_typ .. to.def])
  if to.st.idl or to.st.y then
    w(to)
  end
  to.conv = to.conv + (typ.conv)
  if to.ai and to.grp ~= "atk" then
    to.ai.deft = t()
    mvg(to.ai.p1, to.x, to.y, "atk")
  end
  if to.on then
    poke(13480, rnd "32", rnd "32")
    sfx(typ.sfx)
    alert = t()
  elseif to.hu and t() - alert > 10 then
    sfx "34"
    hi {105 + to.x / 20.21, 107 + to.y / 21.33, 3, 14}
    alert = hlt
    hlt = hlt + (2.5)
  end
end

function cdr()
  for u in all(sel) do
    if u.res then
      return hbld.hu and hbld.drop
    end
  end
end

function cr(t)
  if hbld.exp and st.ant then
    pres(ren, 10, 2)
    rect(us "8,0,18,8,4")
    return t or cpy(ren, res1)
  end
end

function prod(_ENV, b, m)
  pay(b, 1, pres)
  q = q or p("qty=0", b, b.t * m)
  q.qty = q.qty + (1)
end

function unit(t, _x, _y, _ply, _ct, _disc, _hp)
  tot = tot + (1)
  local _typ = typs[t] or t
  local _ENV = add(units, p([[dir=1
lp=1
sproff=0
cyc=0
fres=0
conv=0
a=1
bop=101]], _typ[_ply], rnd "60" // 1))
  foreach(gl.split "w8,h8,bldg,unit,farm,idx,qn,web,ant,mnk,w,h,atk,def,drop,sp,sg,bldrs,bmap,hpr,l", function(k)
    _ENV[k] = typ[k]
  end)
  mh = _ct and _ct > 0 and _ct * hpr or typ.hp
  id, x, y, ply, hp, ct, disc, prod = x, _x, _y, _ply, min(_hp or 9999, mh), max(_ct) > 0 and _ct, _disc == 1, _typ.prod or {}
  rt(box(_ENV))
  return _ENV, bldg and rb(_ENV)
end

function start()
  npl, hq, cx, cy = res1.npl, units[1], us(stp[res1.pos], ":")
  qdm "d"
end

function init()
  poke(24365, 3)
  reload()
  music(us "0,0,7")
  menuitem(3, "\xe2\x8c\x82 save", save)
  menuitem(4, "\xe2\x88\xa7 resign", function()
    hq.hp = 0
  end)
  p [[var=res
r=20
g=10
b=20
pop=4
pl=10
tot=4
reqs=0
diff=0
techs=0
t=0
npl=0]]
  aspl "dq,exp,vc,dmaps,units,rtiles,sel,prj,bldgs,nviz,ais,dms"
  res1, dms.d, pi, ptr, cf, selt, alert, ban, amx, amy, tot, ls, title = res.p1, {}, split "1,2,3,4", us "0x9004,59,0,0,0,64,64,50"
  for i = 2, 4 do
    ais[i] = p([[boi=0
deft=0]], i)
  end
  p [[var=heal
qty=.00083]]
  p [[var=ren
r=0
g=0
b=6
bq=0]]
  p [[var=ant
txt=⁶h²5ᶜ9worker ant: ᶜ7gathers resources,⁶g⁴mbuilds and repairs.
idx=1
spd=.286
los=20
hp=6
rng=0
atk_freq=30
atk=.38
conv=0
def=ant
atk_typ=ant
gr=3
cap=6

t=10
r=5
g=0
b=0
bq=0
pop=

w=4
fw=4
h=4
rt_x=0
rt_y=8
rt_fr=2
rt_fps=30
drop_x=0
drop_y=8
drop_fr=2
drop_fps=30
mv_x=8
mv_y=8
mv_fr=2
mv_fps=15
gth_x=8
gth_y=8
gth_fr=2
gth_fps=15
bld_x=40
bld_y=8
bld_fr=2
bld_fps=15
frm_x=32
frm_y=8
frm_fr=2
frm_fps=15
atk_x=40
atk_y=12
atk_fr=4
atk_fps=3.75
dead_x=32
dead_y=12
ptx=0
pty=72
sdir=1
unit=1
ds=62
sfx=10
ant=1
ct=1
tmap=-1
hl=1
d=0]]
  p [[var=beetle
txt=⁶h²5ᶜ9beetle: ᶜ7slow and melee unit but⁶g⁴mstrong vs buildings.
idx=2
spd=.19
los=20
hp=20
rng=0
atk_freq=30
atk=.75
conv=0
def=sg
atk_typ=sg
sg=1

t=13
r=0
g=10
b=10
bq=0
pop=

ct=1
w=8
fw=8
h=6
rt_x=8
rt_y=0
rt_fr=2
rt_fps=30
mv_x=16
mv_y=0
mv_fr=2
mv_fps=10
atk_x=40
atk_y=0
atk_fr=3
atk_fps=10
dead_x=32
dead_y=0
ptx=27
pty=72
unit=1
ds=62
sfx=10
sdir=1
tmap=-1
hl=1
d=0]]
  p [[var=spider
txt=⁶h²5ᶜ9spider: ᶜ7fastest unit, low def.⁶g⁴mbut good vs ants.
idx=3
spd=.482
los=30
hp=15
rng=0
atk_freq=30
atk=1.667
conv=0
def=sp
atk_typ=sp

t=13
r=8
g=8
b=0
bq=0
pop=

ct=1
w=8
fw=8
h=5
rt_x=8
rt_y=16
rt_fr=2
rt_fps=30
atk_x=64
atk_y=16
atk_fr=3
atk_fps=10
mv_x=16
mv_y=16
mv_fr=6
mv_fps=2
bld_x=64
bld_y=16
bld_fr=2
bld_fps=15
dead_x=56
dead_y=8
ptx=18
pty=72
sp=1
unit=1
ds=62
sfx=10
sdir=1
tmap=-1
hl=1
d=0]].prod = {p [[var=web
txt=⁶h²5ᶜbspider web:ᶜ7 a wall that your⁶g⁴mspiders can cross.
idx=29
los=5
hp=50
ct=5
hpr=10
def=bld

r=0
g=3
b=0
bq=0

w=8
fw=8
h=8
w8=1
h8=1
rt_x=0
rt_y=64
mv_x=0
mv_y=64
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
ptx=96
pty=80
bldg=1
ds=17
bldrs=1
bmap=128
sdir=-1
tmap=-1
web=1
d=0]]}
  p [[var=archer
txt=⁶h²5ᶜ9acid-spitting ant: ᶜ7ranged unit,⁶g⁴mgood vs spiders.
idx=4
spd=.343
los=33
hp=5
rng=28
atk=.667
conv=0
atk_freq=30
aoe=0
ps=1
atk_typ=acid
def=ant

t=14
r=3
g=0
b=5
bq=0
pop=

ct=1
w=7
fw=8
h=6
rt_x=0
rt_y=25
rt_fr=2
rt_fps=30
mv_x=8
mv_y=24
mv_fr=2
mv_fps=10
atk_x=32
atk_y=24
atk_fr=2
atk_fps=10
dead_x=24
dead_y=25
ptx=45
pty=72
unit=1
ds=62
sfx=10
sdir=1
px=-2
py=0
s=52
tmap=-1
hl=1
d=0]]
  p [[var=warant
txt=⁶h²5ᶜ9army ant:ᶜ7 basic army unit. good⁶g⁴mvs beetles+catrplrs.
idx=5
spd=.33
los=25
hp=10
rng=0
atk_freq=30
atk=1
conv=0
def=ant
atk_typ=ant

t=10
r=6
g=2
b=0
bq=0
pop=

ct=1
w=8
fw=8
h=6
rt_x=48
rt_y=64
rt_fr=2
rt_fps=30
mv_x=56
mv_y=64
mv_fr=2
mv_fps=10
atk_x=80
atk_y=64
atk_fr=2
atk_fps=10
dead_x=72
dead_y=64
ptx=36
pty=72
unit=1
ds=62
sfx=10
sdir=1
tmap=-1
hl=1
d=0]]
  p [[var=queen
idx=7
los=25
hp=400
rng=25
atk=1.5
conv=0
atk_freq=30
aoe=0
ps=1
atk_typ=acid
def=qn

ct=1
w=16
h=8
h8=1
fw=16
rt_x=64
rt_y=-1
rt_fr=2
rt_fps=30
mv_x=64
mv_y=-1
mv_fr=2
mv_fps=30
atk_x=80
atk_y=-1
atk_fr=2
atk_fps=15
dead_x=112
dead_y=0
ptx=9
pty=72
drop=0
bldg=1
ds=17
bldrs=15
sfx=10
px=-4
py=2
s=52
bmap=0
units=1
qn=1
ap=1
sdir=-1
tmap=-1
hl=1
d=61]].prod = {ant, nil, nil, nil, nil, p([[t=25
r=20
g=0
b=20
bq=0
tmap=1
up=-1
idx=15
txt=⁶h²5ᶜabaskets:ᶜ7 increase worker⁶g⁴mgathering efficiency.
ptx=24
pty=80]], ant, function(_ENV)
    cap = cap // (.72)
    spd = spd * (1.12)
    gr = gr * (.9)
  end), p([[t=10
r=10
g=10
b=10
bq=2
tmap=2
idx=24
txt=⁶h²5ᶜaegg deposit:ᶜ7 let mounds⁶g⁴mproduce worker ants.
req=⁶h²5ᶜ6egg depositᶜd⁶g⁴m[requires mound]
ptx=33
pty=80]], {}, function()
    mound.p1.units = add(mound.prod, ant)
  end)}
  p [[idx=14
spd=.21
los=18
hp=8
rng=0
atk_freq=30
atk=.47
conv=0
l=1
def=ant
atk_typ=ant

ct=1
w=8
fw=8
h=6
rt_x=88
rt_y=16
rt_fr=2
rt_fps=40
mv_x=96
mv_y=16
mv_fr=2
mv_fps=10
atk_x=96
atk_y=64
atk_fr=3
atk_fps=10
ptx=63
pty=72
unit=1
ds=62
sfx=10
sdir=-1
tmap=-1
d=59]]
  p [[var=monk
txt=⁶h²5ᶜ9mantis:ᶜ7 converts enemy units,⁶g⁴mheals yours, prays.
idx=26
spd=.25
los=45
hp=6
rng=42
atk_freq=60
atk=0
conv=2
atk_typ=ant
def=ant
mnk=74

t=30
r=0
g=12
b=0
pop=
bq=0

ct=1
w=8
fw=8
h=8
rt_x=48
rt_y=112
rt_fr=2
rt_fps=30
mv_x=56
mv_y=112
mv_fr=2
mv_fps=15
atk_x=0
atk_y=80
atk_fr=2
atk_fps=15
gth_x=0
gth_y=80
gth_fr=2
gth_fps=15
dead_x=72
dead_y=112
ptx=87
pty=80
unit=1
ds=62
sfx=63
sdir=-1
tmap=-1
d=0]]
  ant.prod = {p [[var=mound
txt=⁶h²5ᶜbmound:ᶜ7 drop-off for resources,⁶g⁴m+5 population limit.
idx=9
los=5
hp=100
ct=10
hpr=10
def=bld
ap=1

r=0
g=0
b=6
bq=0

w=8
fw=8
h=8
w8=1
h8=1
rt_x=16
rt_y=104
mv_x=16
mv_y=104
ptx=15
pty=103
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
bldg=1
ds=17
bldrs=1
drop=5
bmap=2
sdir=-1
tmap=-1
d=0]], p [[var=farm
txt=⁶h²5ᶜbfarm:ᶜ7 grows food for harvesting.⁶g⁴mlimited lifespan.
req=⁶h²5ᶜ6farmᶜd⁶g⁴m[requires mound]
idx=12
los=1
hp=48
ct=8
hpr=8
def=bld
mcyc=5
gr=.5

r=0
g=3
b=3
bq=2

w=8
fw=8
h=8
w8=1
h8=1
rt_x=16
rt_y=120
mv_x=16
mv_y=120
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
ptx=52
pty=88
farm=1
bldg=farm
bldrs=1
bmap=16
sdir=-1
tmap=-1
d=0]], p [[var=brks
txt=⁶h²5ᶜbbarracks:ᶜ7 trains army ants and⁶g⁴mranged ants.
idx=11
los=10
hp=200
ct=20
hpr=10
def=bld

r=0
g=4
b=15
bq=0

w=8
fw=8
h=8
w8=1
h8=1
rt_x=16
rt_y=112
mv_x=16
mv_y=112
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
ptx=15
pty=111
bldg=1
ds=17
bldrs=1
bmap=8
units=2
idl=1
mil=1
mb=100
sdir=-1
tmap=-1
d=0]], p [[var=den
txt=⁶h²5ᶜbnest:ᶜ7 trains spiders and⁶g⁴mbeetles.
req=⁶h²5ᶜ6nestᶜd⁶g⁴m[requires barracks]
idx=10
los=10
hp=250
ct=25
hpr=10
def=bld

r=0
g=4
b=20
bq=8

w=8
fw=8
h=8
w8=1
h8=1
rt_x=16
rt_y=96
mv_x=16
mv_y=96
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
ptx=99
pty=72
bldg=1
ds=17
bldrs=2
bmap=4
units=2
idl=1
mil=1
mb=100
sdir=-1
tmap=-1
d=0]], p [[var=mon
txt=⁶h²5ᶜbmantis nest:ᶜ7 trains mantises.
req=⁶h²5ᶜ6mantis nestᶜd⁶g⁴m[requires nest]
idx=25
los=25
hp=300
ct=16
hpr=8
def=bld
mon=74

r=0
g=10
b=15
bq=4

w=8
fw=8
h=8
w8=1
h8=1
rt_x=40
rt_y=112
mv_x=40
mv_y=112
f=1
dead_x=64
dead_y=104
dead_fr=8
dead_fps=7.5
ptx=39
pty=111
bldg=1
ds=17
bldrs=2
units=1
bmap=64
mil=1
mb=100
sdir=-1
tmap=-1
d=0]], p [[var=tower
txt=⁶h²5ᶜeguardtower:ᶜ7 basic defensive⁶g⁴mstructure with good vision.
idx=8
los=30
hp=352
ct=32
hpr=11
rng=30
atk=1.2
conv=0
atk_freq=30
aoe=0
ps=.9
atk_typ=bld
def=bld

r=0
g=5
b=15
bq=0

w=8
w8=1
fw=8
h=16
rt_x=40
rt_y=96
mv_x=40
mv_y=96
atk_x=40
atk_y=96
f=1
dead_x=64
dead_y=96
dead_fr=8
dead_fps=7.5
ptx=-1
pty=16
bldg=1
ds=17
bldrs=2
sfx=10
py=-2
px=-1
s=48
bmap=1
sdir=-1
tmap=-1
d=0]], p [[var=castle
txt=⁶h²5ᶜecastle:ᶜ7 very defensive building,⁶g⁴mtrains caterpillars.
req=⁶h²5ᶜ6castleᶜd⁶g⁴m[requires nest+guardtower]
idx=13
los=45
hp=640
ct=80
hpr=8
rng=40
atk=1.8
conv=0
atk_freq=15
aoe=0
ps=.8
atk_typ=bld
def=bld

r=0
g=25
b=60
bq=13

w=15
fw=16
h=16
rt_x=112
rt_y=113
mv_x=112
mv_y=113
atk_x=112
atk_y=113
f=1
dead_x=64
dead_y=97
dead_fr=4
dead_fps=15
ptx=42
pty=80
bldg=1
ds=17
bldrs=3
sfx=10
py=0
px=0
s=48
bmap=32
units=1
mil=1
mb=42
sdir=-1
tmap=-1
d=0]]}
  mon.prod = {monk, nil, nil, nil, nil, p([[t=30
r=10
g=20
b=0
bq=0
tmap=1024
up=-1
idx=27
txt=⁶h²5ᶜamantis upgr.:ᶜ7 increase mantis⁶g⁴mconversion rate and hp by 25%
ptx=62
pty=88]], monk, function(_ENV)
    spd = .286
    hp = hp * (1.25)
    conv = conv * (1.25)
  end), p([[t=40
r=20
g=0
b=0
bq=0
tmap=256
idx=22
txt=⁶h²5ᶜaregeneration:ᶜ7 all your units⁶g⁴mpassively heal.
ptx=16
pty=80]], heal, function(_ENV)
    qty = .0062
  end)}
  den.prod = {beetle, spider, nil, nil, nil, p([[t=20
r=0
g=20
b=0
bq=0
tmap=4
up=-1
idx=16
txt=⁶h²5ᶜabeetle upgr.:ᶜ7 increase beetle⁶g⁴mattack and hp by 15%
ptx=25
pty=88]], beetle, function(_ENV)
    atk = atk * (1.15)
    hp = hp * (1.15)
  end), p([[t=30
r=10
g=10
b=0
bq=0
tmap=8
up=-1
idx=17
txt=⁶h²5ᶜaspider upgr.:ᶜ7 increase spider⁶g⁴mattack and hp by 20%
ptx=16
pty=88]], spider, function(_ENV)
    atk = atk * (1.2)
    hp = hp * (1.2)
  end)}
  mound.prod = {p([[t=12
r=12
g=12
b=10
bq=0
tmap=16
up=-1
idx=18
txt=⁶h²5ᶜafarm upgr.:ᶜ7 increase farm growth⁶g⁴mrate and lifespan.
ptx=60
pty=80]], farm, function(_ENV)
    gr = gr * (1.15)
    mcyc = mcyc // (.6)
  end)}
  brks.prod = {warant, archer, p([[t=10
r=9
g=6
b=0
bq=0
tmap=32
idx=19
txt=⁶h²5ᶜaspray:ᶜ7 increase range for acid-⁶g⁴mspitting ants.
ptx=51
pty=80]], archer, function(_ENV)
    los, rng = 40, 35
  end), nil, nil, p([[t=18
r=15
g=7
b=0
bq=0
tmap=64
up=-1
idx=20
txt=⁶h²5ᶜaarmy ant upgr.:ᶜ7 increase army⁶g⁴mant hp+attack by 33%
ptx=43
pty=88]], warant, function(_ENV)
    atk = atk * (1.333)
    los = 30
    hp = hp * (1.333)
  end), p([[t=10
r=15
g=0
b=9
bq=0
tmap=128
up=-1
idx=21
txt=⁶h²5ᶜaacid-spitting ant upgr.:ᶜ7⁶g⁴mincrease its hp+attack by 25%
ptx=34
pty=88]], archer, function(_ENV)
    atk = atk * (1.25)
    hp = hp * (1.25)
  end)}
  castle.prod = {p [[var=cat
txt=⁶h²5ᶜ9caterpillar: ᶜ7ranged unit, very⁶g⁴mgood vs buildings.
idx=6
spd=.2
los=50
hp=15
rng=50
atk=1.5
conv=0
atk_freq=60
aoe=2
ps=.72
def=sg
atk_typ=sg
sg=1

t=18
r=2
g=14
b=14
bq=0
pop=

ct=1
w=16
fw=16
h=8
rt_x=48
rt_y=24
rt_fr=2
rt_fps=30
mv_x=64
mv_y=24
mv_fr=4
mv_fps=7.5
atk_x=64
atk_y=8
atk_fr=4
atk_fps=15
dead_x=112
dead_y=16
ptx=54
pty=72
unit=1
ds=62
sfx=10
sdir=1
px=1
py=-4
s=56
tmap=-1
hl=1
d=0]], nil, nil, nil, nil, p([[t=30
r=0
g=25
b=30
bq=0
tmap=2048
idx=28
txt=⁶h²5ᶜafireball:ᶜ7 increase castle⁶g⁴mattack, hit multiple units.
ptx=78
pty=80]], castle, function(_ENV)
    aoe, s, atk, atk_freq = 1, 60, 2, 20
  end), p([[t=10
r=0
g=10
b=20
bq=0
tmap=512
idx=23
txt=⁴m²5ᶜaspotters:ᶜ7 increase castle range.
ptx=69
pty=80]], castle, function(_ENV)
    los, rng = 55, 50
  end)}
end

p [[var=f2r
7=r
10=g
11=g
19=b
39=r]]
p [[var=rq
80=45
96=45
112=45

82=45
98=45
114=45

81=60
97=60
113=60

83=60
99=60
115=60

123=12

84=50
100=50
116=50

85=50
101=50
117=50

86=45
102=45
118=45

87=45
103=45
119=45]]
p [[var=pray
g=.00318
b=.00318
r=0]]
p [[var=rc
r=8
g=3
b=4
pop=1
v0=15
v1=15
v7=8
v39=8
v11=3
v19=4
v33=1
e0=5
e1=5
e7=8
e39=8
e11=3
e19=4
e33=1]]
p [[var=resx
_=0
r=16
g=0
b=16]]
p [[var=resy
_=0
r=0
g=4
b=4]]
p [[var=dmt
antant=1.1
antqn=.7
antsp=.8
antsg=1.5
antbld=.5

acidant=1
acidqn=.6
acidsp=1.5
acidsg=.95
acidbld=.25

spant=1.5
spqn=1.1
spsp=1
spsg=1.2
spbld=.1

sgant=.8
sgqn=3
sgsp=.7
sgsg=.9
sgbld=11

bldant=1
bldqn=.75
bldsp=1.25
bldsg=.95
bldbld=.1]]

local function mv(u, x, y, agg)
  u.st = p([[t=mv
mv=1]], path(u, x, y, 0))
  u.st.agg = agg
end

function mvg(units, x, y, agg, frc)
  local l = 999
  foreach(units, function(_ENV)
    if frc or st.idl then
      mv(_ENV, x, y, agg)
    end
    l = min(typ.spd, l)
  end)
  foreach(units, function(_ENV)
    st.spd, grp = l, agg
  end)
end

local function gb(u, b)
  if u.st.farm and b.farm then
    return
  end
  u.st, u.res = p([[t=bld
in_bld=1
ez_adj=1]], path(u, b.x, b.y), b)
end

local function gogth(u, tx, ty, wp, r)
  local t = tu(tx, ty)
  u.st = p([[t=gth
gth=1
ez_adj=1]], wp or path(u, t.x, t.y), t, r or f2r[fm(tx, ty)], tx, ty)
end

local function gd(u, r, dr)
  local wayp
  if not dr then
    wayp, x, y = dpath(u, "d")
    dr = (not wayp or g(bldgs, x, y, {}).ply ~= u.ply) and units[u.ply]
  end
  u.st = p([[t=drop
drop=1
in_bld=1
ez_adj=1]], dr and path(u, dr.x, dr.y) or wayp, dr or tu(x, y), r)
end

function ga(u, e)
  if e then
    u.st, u.res = p([[t=atk
ac=1
k=]] .. e.k, path(u, e.x, e.y, 0, u.typ.rng / 10), e)
  end
end

local function gf(u, f)
  f.fmr, u.st, u.res = u, p([[t=frm
in_bld=1]], path(u, f.x + rs "-2,-1,0,1,2", f.y + rs "-2,-1,0,1,2"))
  u.st.farm = f
end

function tick(u)
  u.on, u.upd, wayp, ut = int(box(u).r, {cx, cy, cx + 128, cy + 104}, 0), u.id % z == upc, u.st.typ, u.typ
  if u.hp <= 0 and u.a then
    tot = tot - (1)
    u.st, u.dead, u.fmr, u.a = p "t=dead", ut.d
    del(sel, u, u.bldg and rb(u), u.on and sfx(ut.ds))
    if ut.l then
      local t = nr(u.x, u.y)
      mset(t[1], t[2], 82 + u.dir)
      dms.r[t.k] = t
      qdm "r"
    elseif u.qn then
      npl = npl - (1)
      if npl == 1 or u == hq then
        ls, sel = min(u.ply, 2), {}
        music "56"
        if ls > 10 and res.p2.newg then
          scoresub(res1.npl - 1 .. split "_easy,_normal,_hard" [res1.diff], -res1.t)
        end
      end
    elseif ut.drop and not u.ct then
      u.pres.pl = u.pres.pl - (ut.drop)
    elseif u.unit then
      u.pres.pop = u.pres.pop - (1)
    end
  end
  if u.dead then
    u.dead = u.dead + (1)
    del(u.dead == 60 and units, u)
    return
  end
  if wayp then
    if norm(wayp[1], u, u.st.spd or ut.spd) then
      deli(wayp, 1)
      u.st.typ, u.disc = wayp[1] and wayp
    end
  elseif u.st.mv then
    rt(u)
  elseif u.st.farm then
    u.st.ac = 1
  end
  local ux, uy, t, los, agg_d, agg_u = u.x, u.y, u.st.x, ut.los, 9999, u.q and pr(u)
  if u.farm then
    local _ENV = u
    if fmr and fmr.st.farm ~= u or exp then
      fmr = nil
    end
  end
  if t then
    if t.dead then
      u.st.agg = 1, wayp or rt(u), u.ant and t.l and gogth(u, t.x8, t.y8)
    elseif int(t.r, u.r, -2) then
      u.st.ac, u.st.typ = 1
    elseif u.st.gth and not wayp then
      gogth(u, t.x8, t.y8)
    end
    if not wayp then
      u.dir = sgn(t.x - ux)
    end
  end
  if u.st.ac then
    _ENV[u.st.t](u)
  end
  if ut.hl and u.dmgd then
    u.hp = u.hp + (heal[u.ply].qty)
  end
  if int(u.r, {mx, my, mx, my}, 1) and (not hunit or hunit.hu) then
    hunit = u
  end
  if g(viz, u.x8, u.y8, u.disc) then
    if selx and int(u.r, sb, 0) then
      if not u.hu then
        sele = {u}
      elseif u.unit then
        selh = selh or {}
        add(selh, u)
      else
        selb = {u}
      end
    end
    sset(109 + ux / 20.21, 72 + uy / 21.33, u.ap)
  end
  if u.ct then
    return
  end
  if u.st.idl then
    if ut.l and time() % 6 < 1 then
      w(u)
    end
    u.disc = u.bldg and u.disc
    if u.hu then
      if u.ant then
        if u.st.idl > 10 then
          idl = u
        end
        u.st.idl = u.st.idl + (1)
      elseif ut.idl and not u.q then
        idlm = u
      end
    end
  end
  if u.upd then
    if u.hu then
      local xo, yo, l = ux % 8 // 2, uy % 8 // 2, ceil(los / 8)
      local k = xo | yo * 16 | los * 256
      if not vc[k] then
        vc[k] = {}
        for dx = -l, l do
          for dy = -l, l do
            add(dist(xo * 2 - dx * 8 - 4, yo * 2 - dy * 8 - 4) < los and vc[k], dx + dy * 256)
          end
        end
      end
      foreach(vc[k], function(t)
        local k = u.k + t
        (bldgs[k] or {}).disc, exp[k], nviz[k] = 1, 128, "v"
      end)
    end
    if u.st.agg and u.atk then
      for _ENV in all(units) do
        if ap ~= u.ap or u.mnk and dmgd and not bldg then
          local d = dist(ux - x, uy - y)
          if a and d <= los then
            if bldg then
              d = d + (u.sg and bldg == 1 and -999 or 999)
            end
            if d < agg_d then
              agg_u, agg_d = _ENV, d
            end
          end
        end
      end
      ga(u, agg_u)
    end
  end
  if u.unit and not u.st.typ then
    local fr, v = {{ux, uy}}, {}
    for i, t in next, fr do
      ux, uy = unpack(t)
      local a = u.st.ez_adj or acc(ux // 8, uy // 8)
      if a or i == 1 then
        if a and not g(pos, ux // 4, uy // 4) then
          u.st.typ = i > 1 and {t}
          break
        end
        for nx = max(ux - 2), min(ux + 2, 382), 2 do
          for ny = max(uy - 2), min(uy + 2, 253), 2 do
            s(v, nx // 2, ny // 2, add(g(v, nx // 2, ny // 2, fr), {nx, ny}))
          end
        end
      end
    end
    s(pos, ux // 4, uy // 4, 1)
  end
end

function du(_ENV)
  local cry, stt, ihp, ux, uy = res and res.typ or "_", st.typ and "mv" or st.t, mh / hp, gl.unpack(r)
  local fw, sx, sy, ufps, fr, f, selc = typ.fw, typ[stt .. "_x"] + gl.resx[cry] + sproff // 8 * 8, typ[stt .. "_y"] + gl.resy[cry], typ[stt .. "_fps"], typ[stt .. "_fr"], dead or (gl.cf - id) % 60, gl.count(gl.sel, _ENV) == 1 and 9
  gl.camera(cx - ux, cy - uy)
  if ct and a then
    fillp "23130.5"
    rect(0, 0, w, h, selc or 12)
    fillp()
    local bar = ct / typ.ct
    line(fw - 1, us "0,0,0,5")
    line(fw * bar, 0, 14)
    sx = sx + (bar // -.5 * fw)
    if bar <= .15 then
      return
    end
  elseif ufps then
    sx = sx + (f // ufps % fr * fw)
  end
  pal {selc or pres.col, 2, 3, 4, farm and selc or 5, us "6,7,8,9,10,11,12,13,0"}
  sspr(sx, sy, w, h, 1, 1, w, h, not typ.f and dir == typ.sdir)
  pal()
  if a and ihp >= 2 then
    spr(typ.f and 247 + f / 20, w // 3)
    line(w, us "-1,0,-1,8")
    line(w // ihp, -1, 11)
  end
end

local function mn(u, res)
  local wp, x, y = dpath(u, res)
  if wp then
    gogth(u, x, y, wp, res)
    return res
  end
end

local function collect(_ENV, r)
  if res and res.typ == r then
    res.qty = res.qty + (1)
  else
    res = p("qty=1", r)
  end
  if res.qty >= typ.cap then
    gd(_ENV, r)
  end
end

function drop(_ENV)
  if res then
    pres[res.typ] = pres[res.typ] + (res.qty / typ.gr)
  end
  st.idl, res = 11
  if st.farm then
    gf(_ENV, st.farm)
  elseif st.y then
    mn(_ENV, st.y)
  else
    rt(_ENV)
  end
end

function frm(u)
  local _ENV = u.st.farm
  if not fmr then
    rt(u)
  elseif gl.cf == 0 then
    if ready then
      fres = fres - (1)
      sproff = sproff + (1)
      collect(u, "r")
      if fres < 1 then
        gd(u)
        cyc = cyc + (1)
        exp, ready = cyc >= typ.mcyc
        if exp and ai then
          cyc, exp = 0, pay(gl.ren, 1, pres)
        end
        sproff = exp and (sfx "36" and 32) or 0
      end
      u.st.farm = _ENV
    else
      fres = fres + (typ.gr)
      sproff, ready = fres * 2, fres >= 9
    end
  end
end

function atk(u)
  local typ, e = u.typ, u.st.x
  if u.upd then
    local d = dist(e.x - u.x, e.y - u.y)
    if typ.rng >= d or int(u.r, e.r, 0) then
      u.st.typ = nil
      if cf % typ.atk_freq == u.id % typ.atk_freq then
        if e.ap == u.ap then
          if typ.mnk and e.dmgd then
            e.hp = e.hp + (1)
            if u.on then
              sfx "20"
            end
          else
            rt(u)
          end
        else
          u.disc = u.disc or e.hu
          add(prj, typ.s and p("", typ, u.x - u.dir * typ.px, u.y + typ.py, e.x, e.y, u.ap) or dmg(typ, e))
          if e.conv >= e.mh then
            if e.qn then
              e.hp = 0
            else
              e.pres.pop = e.pres.pop - (1)
              u.pres.pop = u.pres.pop + (1)
              e.ply, e.conv = u.ply, 0
            end
            del(e.sqd, e)
            sfx "38"
          end
        end
      end
    elseif u.hu and viz[e.k] or typ.los >= d or e.disc then
      ga(u, e.k ~= u.st.k and e)
    elseif not u.st.typ then
      rt(u)
    end
  end
end

function bld(u)
  if cf % 30 == 0 then
    local _ENV = u.st.x
    if ct then
      ct = ct + (1)
      mh = mh + (hpr)
      hp = hp + (hpr)
      if ct >= typ.ct then
        ct = nil
        rb(_ENV, u.hu and sfx "26")
        if drop then
          pres.pl = pres.pl + (5)
        elseif farm then
          gf(u, _ENV)
        end
      end
    elseif dmgd and pres.b >= 1 then
      hp = hp + (2)
      pres.b = pres.b - (.1)
    else
      rt(u)
      sr(function(t)
        local _ENV = gl.bldgs[t.k]
        if _ENV and hu and ct and (u.ant or web) then
          gb(u, _ENV)
        end
      end, x8, y8, 4)
    end
  end
end

function gth(u)
  local r, x, y = u.st.y, unpack(u.st.p1)
  local t = mget(x, y)
  local f = rq[t]
  if not f then
    if u.mnk then
      pay(pray, -1, res1)
    elseif not mn(u, r) then
      gd(u, r)
    end
  elseif cf == u.id then
    f = f + (res1.diff * u.ap // 33 * 5)
    local n = g(rtiles, x, y, f) - 1
    collect(u, r)
    if t < 112 and (n == f // 3 or n == f // 1.25) then
      mset(x, y, t + 16)
    elseif n == 0 then
      mset(x, y, 68)
      s(dms[r], x, y)
      s(dmaps[r], x, y, .55)
      n = qdm(r)
    end
    s(rtiles, x, y, n)
  end
end

function pr(_ENV)
  local bld = q.typ
  q.x = q.x - (.03333)
  if q.x <= 0 then
    if bld.x then
      local _ENV = bld
      gl.res1.techs = gl.res1.techs | (tmap)
      x(typ.p1)
      sfx "33"
      if up and up < 1 then
        up = up + (1)
        r = r * (1.75)
        g = g * (2)
        b = b * (2)
        t = t * (1.5)
        done = nil
      end
    else
      local new, t = gl.unit(bld, x, y, ply), mget(rtx, rty), on and hu and sfx "19"
      if bld.ant and rtx and gl.rq[t] or bld.mnk == t then
        gogth(new, rtx, rty)
      else
        mv(new, rx or x + 5, ry or y + 5)
      end
    end
    if q.qty > 1 then
      q.qty = q.qty - (1)
      q.x = bld.t
    else
      q = nil
    end
  end
end

function w(_ENV)
  mv(_ENV, x + rs "-6,-5,-4,-3,3,4,5,6", y + rs "-6,-5,-4,-3,3,4,5,6", 1)
end

function cam()
  local b = btn()
  if b > 255 then
    b = b >> (8)
  end
  local dx, dy = (b & 2) - (b & 1) * 2, (b & 8) / 4 - (b & 4) / 2
  if dget "0" ~= 2 or ls then
    amx, amy = stat "32", stat "33"
  else
    amx = amx + (dx)
    amy = amy + (dy)
    dx, dy = amx // 128 * 2, amy // 128 * 2
  end
  cx, cy, amx, amy = mid(cx + dx, 256), mid(cy + dy, ls and 128 or 151), mid(amx, 126), mid(amy, 126)
  mx, my, hbtn = amx + cx, amy + cy
  mx8, my8 = mx // 8, my // 8
end

function fsel(func, ...)
  for u in all(sel) do
    func(u, ...)
  end
end

function ip()
  cam()
  foreach(btns, function(b)
    if int(b.r, {amx, amy, amx, amy}, 1) then
      hbtn = b
    end
  end)
  local htile, atkmov, clk, tile = tu(mx8, my8), axn and dget "0" > 1, lclk or rclk, mget(mx8, my8)
  if clk and hbtn then
    axn = hbtn.fn(rclk)
    return
  end
  if lclk and axn then
    rclk, axn, llclk = 1
  end
  if amy > 104 and not selx then
    local x, y = amx * 20.21 - 2101.84, amy * 21.33 - 2260.98
    if mid(x, 384) == x and mid(y, 256) == y then
      if rclk and sel1 then
        sfx "1"
        fsel(mv, x, y, atkmov)
        hi {amx, amy, 2, 8}
      elseif not axn and llclk then
        cx, cy = x - 64, y - 64
        cam()
      end
    end
    if clk then
      to_bld = nil
    end
  elseif to_bld then
    if clk and bd() then
      local b = unit(to_bld, mx8 * 8 + to_bld.w // 2, my8 * 8 + to_bld.h // 2, us "1,1,1")
      fsel(gb, b)
      sfx "1"
      selx = pay(to_bld, 1, res1)
      to_bld = rclk and cpy(to_bld, res1) and to_bld
    end
  elseif btnp "5" and sel1 and sel1.unit and t() - selt < .2 then
    sel, selx = {}
    foreach(units, function(_ENV)
      add(on and hu and idx == gl.sel1.idx and gl.sel, _ENV)
    end)
  elseif rclk and sel1 and sel1.hu then
    if cr() then
      sfx "0"
      hi(hbld)
      hbld.sproff, hbld.cyc, hbld.exp = 0, 0
      pay(ren, 1, res1)
      gf(sel1, hbld)
    elseif cgt() then
      sfx "0"
      hi(htile)
      if afarm() then
        gf(sel1, hbld)
      else
        fsel(gogth, mx8, my8)
      end
    elseif cbl() then
      sfx "0"
      fsel(gb, hbld)
      hi(hbld)
    elseif ctk() then
      sfx "4"
      fsel(ga, hunit)
      hi(hunit)
    elseif cdr() then
      sfx "0"
      fsel(gd, nil, hbld)
      hi(hbld)
    elseif sel1.unit then
      sfx "1"
      mvg(sel, mx, my, atkmov, 1)
      hi(p([[f=.5
c=8]], mx, my))
    elseif sel1.typ.units then
      sfx "3"
      sel1.rx, sel1.ry, sel1.rtx, sel1.rty = mx, my, mx8, my8, (st.ap and rq[tile] or st.mon == tile) and hi(htile)
    end
  elseif not axn then
    if btnp "5" and not selx then
      selx, sely, selt = mx, my, t()
    end
    if llclk and selx then
      sb = {min(selx, mx), min(sely, my), max(selx, mx), max(sely, my), 7}
    else
      selx = nil
    end
  end
end

function dpath(u, k)
  local x, y, dmap, pth, l = u.x8, u.y8, dmaps[k] or {}, {}, 9
  while l >= .5 do
    local none = 1
    sr(function(t)
      local w = (dmap[t.k] or 9) + t.d - 1
      if w < l and (u.ai or exp[t.k]) then
        l, x, y, none = w, unpack(t)
      end
    end, x, y, 1, 1)
    if none then
      s(dmap, x, y, min(l + 1, 9))
      return
    end
    add(pth, {x * 8 + 3, y * 8 + 3})
  end
  return pth, x, y
end

function qdm(k)
  dq = split(p [[r=d,b,g,r
g=d,b,r,g
b=d,r,g,b
d=b,g,r,d]] [k])
end

function dmap()
  if cdq then
    for i = 1, #cdq.typ do
      if i > 20 then
        return
      end
      local pt = deli(cdq.typ)
      cdq.p1[pt.k] = cdq.c
      if cdq.c < 8 then
        sr(function(t)
          cdq.p3[t.k] = cdq.p3[t.k] or add(cdq.p2, t)
        end, unpack(pt))
      end
    end
    cdq.c = cdq.c + (1)
    cdq.typ, cdq.p2 = cdq.p2, {}
    if cdq.c == 9 then
      dmaps[cdq.x], cdq = cdq.p1
    end
  else
    local k, o = deli(dq), {}
    if k then
      if not dms[k] then
        dms[k] = {}
        for x = 0, 47 do
          for y = 0, 31 do
            if f2r[fm(x, y)] == k then
              s(dms[k], x, y, {x, y})
            end
          end
        end
      end
      for i, t in next, dms[k] do
        if sr(nil, unpack(t)) then
          add(o, t).k = i
        end
      end
      cdq = p("c=0", o, k)
    end
  end
end

function nr(gx, gy)
  for n = 0, 16 do
    local best_d, best_t = 32767
    sr(function(t)
      local d = dist(t[1] * 8 + 4 - gx, t[2] * 8 + 4 - gy)
      if d < best_d then
        best_t, best_d = t, d
      end
    end, gx // 8, gy // 8, n)
    if best_t then
      return best_t, n
    end
  end
end

function path(u, x, y, tol, r)
  if u.unit then
    spdr, dest, dest_d = u.sp, nr(x, y)
    wayp, e, spdr = as(nr(u.x, u.y), dest, r)
    if e and not r and dest_d <= (tol or 1) then
      deli(wayp)
      add(wayp, {x, y})
    end
    return wayp[1] and wayp
  end
end

function as(st, g, d)
  local gk, t = g.k >> 16, {[st.k] = p([[var=sh
y=0
x=32767]], st)}

  local function path(s, f, e)
    while s.typ ~= st do
      add(f, {s.typ[1] * 8 + 4, s.typ[2] * 8 + 4}, 1)
      asc[s.typ.k | gk], s = {e = e, unpack(f)}, t[s.p.k]
    end
    return f, e
  end

  local fr, frl, cl = {sh}, 1, sh
  while frl > 0 do
    local c, m = 32767
    for i = 1, frl do
      local q = fr[i].y + fr[i].x
      if q <= c then
        m, c = i, q
      end
    end
    sh = fr[m]
    fr[m], sh.d = fr[frl], 1
    frl = frl - (1)
    local pt = sh.typ
    local f = asc[pt.k | gk] or (pt.k == g.k or sh.x <= max(d)) and {e = 1}
    if f then
      return path(sh, {unpack(f)}, f.e)
    end
    sr(function(n)
      local ob, x = t[n.k], sh.y + n.d
      if not ob then
        ob = {y = 32767, typ = n, x = dist(n[1] - g[1], n[2] - g[2])}
        frl = frl + (1)
        fr[frl], t[n.k] = ob, ob
      end
      if not ob.d and ob.y > x then
        ob.y, ob.p = x, pt
      end
      if ob.x < cl.x then
        cl = ob
      end
    end, unpack(pt))
  end
  return path(cl, {})
end

function pres(r, x, y, z)
  local oop = res1.pop >= res1.pl
  for i, k in inext, split "r,g,b,pop" do
    local newx, v = 0, i ~= 4 and min(r[k] // 1, 99) or z and "\xc2\xb3b \xc2\xb3i" .. res1.pop .. "/\xe2\x81\xb6x9 \xe2\x81\xb6-#\xe2\x81\xb6x1.\xe2\x81\xb4h\xc2\xb25\xe2\x81\xb6x0 \xe2\x81\xb6x4\xe2\x81\xb6-#\xe2\x81\xb56f" .. min(res1.pl, 99) or oop and r[k] or 0
    if z and i == 3 then
      newx = -2
      v = v .. (" \xc2\xb3c\xe2\x81\xb6t\xe2\x81\xb4f\xe1\xb6\x9c5\xe2\x81\xb6-#|")
    end
    pspl((i == 4 and oop and r.pop or res1[k] < flr(v)) and "1,2,3,4,5,6,10")
    if v ~= 0 or z then
      newx = newx + (?"\xc2\xb27 " .. v, x, y, rc[k])
      spr(129 + i, x, y)
      x = newx + (z or 1)
    end
  end
  return x - 1
end

function dp(typ, fn, x, y, r, bg, fg, u, cost)
  camera(-x, -y)
  local nopay, axnsel = cost and not cpy(typ, res1), typ.portf and axn
  rect(0, 0, 10, 9, u and u.pres.col or nopay and 6 or cost and 3 or axnsel and 10 or typ.porto or 1)
  rectfill(1, 1, 9, 8, nopay and 7 or cost and cost.x and 10 or axnsel and 9 or typ.portf or 6)
  pspl(nopay and "5,5,5,5,5,6,6,13,6,6,6,6,13,6,0,5" or "1,2,3,4,5,7,7,8,9,10,11,12,13,0")
  sspr(typ.ptx, typ.pty, us "9,8,1,1")
  sspr((typ.up or -1) * 8, us "88,8,8,2,1")
  add(fn and btns, {r = {x, y, x + 10, y + 8}, fn = fn, cost = cost})
  if fg then
    color(bg)
    unl "10,11,0,11"
    line(10 * r, 11, fg)
  end
  cp()
end

function sp(x)
  fsel(function(u)
    x = x + (13)
    if x > 100 then
      unspr "133,84,121"
      print("\xe2\x81\xb6jmu\xe2\x81\xb4f\xe1\xb6\x9c1\xe2\x81\xb6x2...\0")
    else
      dp(u.typ, nsel > 1 and function(r)
        del(sel, u)
        if r then
          sel = {u}
        end
      end, x, 107, max(u.hp) / u.mh, 8, 11, u)
    end
  end)
end

function dm()
  local x, hc = 0, hbtn and hbtn.cost
  for i, sec in inext, split(sel1 and sel1.hu and (sel1.bldg and "17,24,61,26" or "17,17,68,26") or "102,26") do
    pspl(i % 2 ~= 0 and "1,2,3,15")
    palt(5, not (hc and dget "1" == 0 or cy == 151))
    camera(x)
    unspr "129,0,104"
    spr(129, sec - 8, 104)
    line(sec - 4, us "105,3,105,7")
    rectfill(sec - 4, us "106,3,108,4")
    rectfill(sec, us "108,0,128")
    x = x - (sec)
    cp()
  end
  if sel1 then
    if sel1.hu then
      if sel1.unit then
        dp(p([[pty=72
porto=2
portf=13
ptx=]] .. split "90,81,81" [dget "0"]), function()
          axn = not axn
          return axn
        end, 20, 108)
      end
      if st.ant or nsel == 1 then
        if sel1.ct then
          dp(p [[ptx=72
pty=72
porto=8
portf=9]], function()
            pay(st, -1, res1)
            sel1.hp = 0
          end, 24, 107, sel1.ct / st.ct, 5, 12)
        else
          local q = sel1.q, sel1.farm and ?"\xe1\xb6\x9c4\xe2\x81\xb6jbr\xe2\x81\xb4i" .. sel1.cyc .. "/" .. st.mcyc .. "\xe2\x81\xb5he\xe2\x81\xb6:040c1e0d05010706\xe2\x81\xb5ch\xe2\x81\xb6:0c1c1014160f0604"
          for i, b in next, sel1.prod do
            if not b.done then
              dp(b, function()
                if cpy(b, res1) and (not q or q.typ == b and q.qty < 9) then
                  sfx "2"
                  if b.bldg then
                    to_bld = b ~= to_bld and b
                    return
                  end
                  prod(sel1, b, 1)
                  b.done = b.x
                else
                  sfx "16"
                end
              end, split "88,76,64,52,40,88,76,64" [i], split "106,106,106,106,106,117,117,117" [i], nil, nil, nil, nil, b)
            end
          end
          if q then
            local b = q.typ
            dp(b, function()
              b.done = pay(b, -1, res1)
              if q.qty == 1 then
                sel1.q = nil
              else
                q.qty = q.qty - (1)
              end
              sfx "18"
            end, b.x and 24 or ?"\xe1\xb6\x9c7\xe2\x81\xb6j8r\xe2\x81\xb4iX" .. q.qty and 20, 107, q.x / b.t, 5, 12)
          end
          if sel1.typ.units then
            dp(p [[ptx=120
pty=64
porto=15
portf=15]], function()
              axn = not axn
              return axn
            end, 42, 108)
          end
        end
      else
        sp "24"
      end
    end
    if nsel == 1 then
      sp "-10"
    else
      camera(nsel < 10 and -2)
      print("\xe1\xb6\x9c1\xe2\x81\xb6j1r\xe2\x81\xb5hjX" .. nsel)
      unspr "133,1,111"
      add(btns, {r = split "0,110,14,119", fn = function()
        deli(sel)
      end})
    end
  end
  camera()
  sspr(add(btns, idl and {r = split "116,121,125,128", fn = function()
    sfx "1"
    hi(idl)
    sel, cx, cy = {idl}, idl.x - 64, idl.y - 64
    cam()
  end}) and 48 or 56, us "105,8,6,116,121")
  sspr(add(btns, idlm and {r = split "105,121,112,128", fn = function()
    hi(idlm)
    sel = {idlm}
  end}) and 48 or 56, us "98,8,6,105,121")
  pspl "1,2,3,4,5,6,7,8,9,10,14,12,8,0,15"
  sspr(us "109,72,19,12,105,107")
  camera(cx // -20.21, cy // -21.33)
  rect(us "104,106,112,114,10")
  br()
  if hc then
    cursor(dget "1" & 61440 | 1, 93)
    if hc.reqs then
      print(hc.txt)
      local l = pres(hc, 0, 150)
      camera(l / 2 - 4 - hbtn.r[1], 8 - hbtn.r[2])
      pres(hc, 2, 2)
      rect(l + 2, us "0,0,8,1")
    else
      print(hc.req)
    end
  end
end

function br()
  camera()
  rectfill(us "0,120,30,128,7")
  camera(-pres(res1, us "1,122,2"))
  unl "-128,120,-4,120,5"
  unl "-3,121"
  cp()
end

function save()
  local ptr = 0
  bnr(2, "savefile\xe2\x81\xb6jdn\xe1\xb6\x9c1savefile", "drag+drop to load \xe2\x81\xb4f\xe2\x81\xb6x1 ")

  local function draw(v)
    for i = 0, 8, 4 do
      pset(ptr % 128, ptr // 128, v >> i & 15)
      ptr = ptr + (1)
    end
  end

  for x = 0, 47 do
    for y = 0, 31 do
      draw(mget(x, y) | g(exp, x, y, 0))
    end
  end
  foreach(split "r,g,b,pop,pl,reqs,tot,diff,techs,t,pos,npl,col", function(k)
    foreach(res, function(r)
      draw(r[k])
    end)
  end)
  draw(#units)
  foreach(units, function(_ENV)
    foreach({idx, x, y, ply, max(ct), max(disc), hp}, draw)
  end)
  extcmd("screen", 1)
end

function lg()
  init()
  pal()
  serial(us "0x802,0x9000,0x4000")

  local function px(n)
    n = n - (1)
    if n >= 0 then
      local v1, v2, v3 = peek(ptr, 3)
      ptr = ptr + (3)
      return v1 | v2 << 4 | v3 << 8, px(n)
    end
  end

  for x = 0, 47 do
    for y = 0, 31 do
      local v = px "1"
      mset(x, y, v & 127, v > 127 and s(exp, x, y, 128))
    end
  end
  foreach(split "r,g,b,pop,pl,reqs,tot,diff,techs,t,pos,npl,col", function(k)
    foreach(res, function(r)
      r[k] = px "1"
    end)
  end)
  for i = 1, px "1" do
    unit(px "7")
  end
  local techs = res1.techs
  foreach(typs, function(_ENV)
    if techs | tmap == techs then
      x(typ.p1)
      up, done = up and 0, not up
    end
  end)
  start()
end

function aif(ai)
  aspl "av,nxt,miners,aiu"
  local safe, ants, bgrat, res, hold = t() - ai.deft > 5, 0, 2.75, res[ai.typ]

  local function miner(u, r)
    u.rs = mn(u, r)
    if not u.rs and nxt[r] then
      mv(u, unpack(nxt[r]))
    end
  end

  for i = 0, ai.boi, 2 do
    local off = 8288 + i % 32 + i // 32 * 128
    local x, y = peek(off + res.pos * 768, 2)
    local adv, ux, uy, pop, pid = ai.boi == i, x * 8, y * 8, peek(off, 2)
    local r, b, bld = chr(pid), ant.prod[pid], g(bldgs, x, y)
    if res.tot >= pop then
      if b then
        if bld then
          bld.bop = pop
        elseif safe then
          if cpy(b, res) then
            pay(b, 1, res)
            unit(b, ux + b.w / 2, uy + b.h / 2, ai.typ, 1)
          else
            hold = b
          end
        end
      else
        if pid > 90 then
          if res.diff == x then
            bgrat = 2
            break
          end
          nxt[r] = nxt[r] or g(dmaps[r] or {}, x, y) and {ux, uy}
        elseif adv then
          if pid == 10 then
            if res.newg then
              unit(14, ux, uy, 4)
            end
          elseif res.diff >= x then
            hold = typs[pid]
            if y == 0 or cpy(hold, res) then
              hold.x(hold.typ[ai.typ])
              hold = pay(hold, y, res)
            end
          end
        end
      end
      if adv and not hold then
        ai.boi = ai.boi + (2)
      end
    end
  end
  for u in all(units) do
    if u.ai == ai then
      if add(aiu, u).ant then
        ants = ants + (1)
        if u.st.idl then
          miner(u, bgnxt and "b" or "r")
          bgnxt = not bgnxt
        end
        del(u.bld and not u.st.in_bld and u.bld.p1, u)
        add(add(miners, u.rs) and not u.res and av, u)
      elseif u.unit then
        if u.dead then
          del(u.sqd, u)
        elseif not u.sqd then
          u.sqd = (#ai.p1 > #ai.p2 or u.sg) and ai.p2 or ai.p1
          add(u.sqd, u)
        end
      end
    end
  end
  local bal = (#miners - count(miners, "r")) // bgrat - count(miners, "g")
  for u in all(aiu) do
    local ut, r = u.typ, bal > 0 and "g" or bal < 0 and "b"

    local function send(fn)
      if #u.p1 < ut.bldrs then
        local w = add(u.p1, deli(av))
        if w then
          w.bld, w.rs = u, fn(w, u)
        end
      end
    end

    if u.rs ~= r and r and del(av, u) then
      bal = 0
      miner(u, r)
    end
    if u.bldg and u.dmgd or u.ct then
      send(gb)
    elseif u.farm and not u.fmr then
      send(gf)
    elseif u.qn and ants < res.diff * 13.5 or ut.mil and u.bop < ut.mb and res.pop < res.diff * 26 then
      local b, h = u.prod[u.lp]
      foreach(split "r,g,b", function(k)
        h = h or hold and b[k] ~= 0 and res[k] - b[k] < hold[k]
      end)
      if not u.q and not h and cpy(b, res) then
        prod(u, b, split "5,1,1" [res.diff])
        u.lp = u.lp % (ut.units)
        u.lp = u.lp + (1)
        res.tot = res.tot + (1)
      end
    end
  end
  if ai.p2[res.diff * 5] and safe then
    while ai.p2[1] do
      add(ai.p3, deli(ai.p2))
    end
  end
  mvg(ai.p3, hq.x, hq.y, "atk")
end

cartdata "age_of_ants"

function mode()
  dset(0, dget "0" % 3 + 1)
  menuitem(1, split "\xe2\x97\x8f mode:touch,\xe2\x97\x8f mode:handheld,\xe2\x97\x8f mode:desktop" [dget "0"], mode)
  return true
end

menuitem(2, "\xe2\x96\xa4 toggle help", function()
  dset(1, ~dget "1")
end)
foreach(split ",,", mode)

__gfx__
00000000d000000000000000000000000000000000d0000000000000000000000000000000100010000000000000000000000000011000110000000000000000
000000000d000000d00000000000000000000000000d00000d011100000000000011000000010100000000000110001100000000000101000000000000000000
00000000005111000d000000dd0000000000000000005110d05111100d0000000111100000010100001110000001010000111000004444000000000000001010
000000000051111000511100005111000000000000005111005d1110d01111000111101110444400011110111044440001111011104e4e000011000111014441
000000000001111000511110005111100d51110000000d11000000d005111d0001101441144e4e0001101441144e4e000110144114044000011111441141e4e1
00000000000d1d10000d1d100001d1d0d051d1d00000000d0000000005d110000000544005044000011054400504400001105440505005000115054450504400
00000000000000000000000000000000000000000000000000000000000000000005050050500500000505005050050000050500000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000800000008000080000000000000000000000000000000000000000010050000000000000000000000000000000000000000000000000000
000000000000000088000800880008800000000050000000000080000000000000000000115000000000000000000000000000000000000000d0000000000000
11000000110001101100880011000110110001100110511081101100000000000000000003300000000000000000000000d00000000000000d00000000000000
0011111100110011001111110011001180110811001100110011001100505000000000000011500000d00000000000100d000000000000003310000000000000
0b0000b004000000040000400000000000000000000000000515150000000000001300000d0000000001131133100000000000003311310000000000
bb000b00bb000bb04400040044000440000000000000110000000000000000000dd1311331350000331131131131135033113113113113100011311311311310
1100bb00110001101100440011000110000000000110001011101100000000003311311331105000331131131130500000113113113113110505001311311311
00111111001100110011111100110011015500000011000100010011000000003305005050500000050500505050000000505050505050500000005050505050
000b0000000000000000000000000000000000000000000000000000000000000005050000505000000000000000000000000000000000000000000000000000
00b33000050505000000000000000000000000000000000000000000000000000550151005015150005050500888800008888000008888000000000000000000
0b33330050151050050505000050505000505050005050500505050005050500500d15150501515005015105888e8800888e8800088e88800000000000000000
b4444450501510505015105005015105050511050505115050151500501150500000d50550d0d005050151058e88e8008e88e8ee08e8e8ee0000000000000000
0411d40050050050501510505001510550051105050511505015150050115050000000050000000505dd0005888888ee8888887e0888887e0000000000000000
0411d400000000000000000000000000000000000000000000000000000000000000000000000000000000005050507e50505000050505000000000000000000
04444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d11311311311310
004440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033d1515351515351
0000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000000000000000000000000000000dd0000000d00000000d0000000000000000000000000000000d000000000000000000000000000000000000000000000
d00001100d0000000dd000000000000000310011003100110d0000000000000000d00000000000000d0000000000000000d00000000000000000000000000000
31000110d0000110d00001100000000005d1001105d1001133000000000000000d0000000000000033100000000000000d000000000000000000000000000000
0d11110031111110311111100d000110505d1110000d111033100000000000013310000000000000331131000000000033100013113000000dd0000000011310
001d1d000d1d1d0001d1d1d0d3d1d1100000d1d00050d1d001113113113113113311311311311310001131131131131033113113113113103311311311311311
00000000000000000000000000000000000000000000000000513113113113500011311311311311050500131131131100113105050113113311311311350505
00000000000000000000000000000000000000000000000005005050505050000050505050505050000000505050505000505000000050500050505050500000
000000000000000000000000eeeeeeeefffffffffffffffffffffffffff666ffffffffffffffff5fffffffff113331dd11111dd1ffffffffffffffffffffffff
004880000048008000400880eeeeeeeeffff6fffffff6ffffffffffff67cc76ffffffdff6f555ffffff33fff1338311111511151ffffffffffffffffffffffff
004888800048888000488880eeeeeeeefffffffffffff5ffff2ffffff6c11c7fffffd6dff55555f5ff3993ff3bfbfb1111154511ffffffffffffffffffffffff
004888800048888000488880eeeeeeeef6fffffff6f5fffff292ffff6c1111c6fffffd3ff555565fffbaabff33bbb33311114111ffffffffffffafffffffffff
004008800040880000488000eeeeeeeeffffff6ffffff5fff32fffff6c1dd1c6ffffff3ff565555fffbaabff33bbb33311154511ffafffffffffffffffffffff
004000000040000000400000eeeeeeeeffffffffff5fff6ff3ffffff67c111c6ffaffffff566555fffbbbbff33bbb33311514151ffffffffffffffffffffffff
014100000141000001410000eeeeeeeefff6fffffff6ffffffffaffff6ccc76fffffffffff5555f6f333333f1b333b3111121211ffffffffffffffff7fffffff
011100000111000001110000eeeeeeeeffffffffffffffffffffffffff6666fffffffffff6ffffffffffffff11333311dd1111ddffffffffffffffffffffffff
fff88fffffffffffffffff8fffffffffffff333fffffffffffffffffffffffffffffffffffffffffffffffff1111d111111d1111ffffffffffffffffffffffff
f887888ffffffffff8fff888fffffffffff33b3ffbbfffffffff44ffff444ffffffffff6776fff766fffffff1dd1111111111dd1ffffffffffffffffffffffff
87887878fff888ff888ff888ff888fffff33b33ffb3bffbbf4f4444fff444ffffffff7666cc666cc667fffff1111111cc1111111ffffffffffffffffffffffaf
88788788ff88188f888f8fdff88188ffff3b33dffb33bb3bff44454ff4494fffffff67cccccccccccc76ffff1111cccccccc1111fffff7ffffffffffffffffff
fff77fff1181881ffdf888dff1881811ff333dffffb3b33bf444544fff544ffffff76ccccc6cc6ccccc67fff111cccccccccc111fffffffffffffaffffffffff
ff7777ff1685858ffdd888dff8585861fff3dffffffb33bf499544ffff9444fffff6cccc6ccc6ccccccc6fff1d1cccccccccc1d1ffffffffffffffffffffffff
fff77fffffffffffffdfdfdffffffffffff3ffffffff3bff49944fffff5444ffff66cccc7cccc11ccccc66ff111ccc6666ccc111ffffffffffffffffffffffff
fff77fffffffffffffffdffffffffffffff3ffffffff3ffff444ffffff445ffff6c7ccc1111111111ccc7c6f11ccc667766ccc11ffffffffffffffffffffffff
fff88ffffffffffffffffffffffffffffffff3fffffffffffffffffffffffffff66ccc111111111111ccc66f11ccc667766ccc11ffffffffffffffffffffffff
f887888ffffffffff8fff88fffffffffffff3bfffffffffffffff4fffff4fffff6ccc6111dd11111116ccc6f111ccc6666ccc111fffffffffffffffff7ffffff
ff8878f8fffffffff88ff888ffffffffffffb33ffffbfffffff4f44ffff44ffff7cccc111166111111cccc7f1d1cccccccccc1d1ffffffffffffffffffffffff
f8788fffff8815ff888f8fdfff5188ffff3bf3fffb33fbffff44454fff494ffff6c6cc111111111111cc6c6f111cccccccccc111ffffffffff7fffffffffffff
fff77ffff121885ffdff88dff588121fff3333ffffb3b3fbff4454ffff544ffff66ccc1111111dd111ccc66f1111cccccccc1111fffaffffffffffffffffffff
ff77ffff1585858fffd88fdff8585851fff3dffffffb33bff495ffffff9444ffff6c6cc1111111111cc6c6ff1111111cc1111111ffffffffffffffffffffffff
fff7ffffffffffffffdfdffffffffffffff3ffffffff3bff49944ffffff44fffff6cccc111dd111111ccc6ff1dd1111111111dd1ffffffffffffffffffffafff
fff77fffffffffffffffdffffffffffffff3ffffffff3ffff444fffffffffffff76c6c111111111111c6c67f1111d111111d1111ffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6c7ccc1111111111ccc7c6ffffffffffffffff5ffffffffffffffffffffffff
ffff8ffffffffffffffff8ffffffffffffff3fffffffffffffffffffffffffffff66ccccc11cccc7cccc66ffffffffaf6f5555ffffffffffffffffffffffffff
ff88f8fffffffffff8ffff8fffffffffffffb33ffffffffffff4f4fffff44ffffff6ccccccc6ccc6cccc6fffffbffffff533555fffffffffffffffffffffffff
f8788ffffff884fff88fffdfff488fffff3bf3fffff3fffffff4444fff494ffffff76ccccc6cc6ccccc67ffffffbf3fff535535fffffffffffffffff7fffffff
ffff7fffff21825ffdff8ffff52812ffffff33ffffbff3bfff4454fffff44fffffff67cccccccccccc76fffffffb3ffff555555ff7ffffffffffffffffffffff
fff7fffff285258fffd88fdff852582ffff3fffffff3bbfff4944ffffff45ffffffff766cc666cc6667ffffffffb3ffff53555f6ffffffffffffffffffffffff
fff7ffffffffffffffdfdffffffffffffff3ffffffff3fffff4ffffffff4fffffffffff667fff6776fffffffffffffffff555fffffffffffffffffffffffffff
fff77fffffffffffffffffffffffffffffffffffffff3fffffffffffffffffffffffffffffffffffffffffffffffffff6fffff5fffffffffffffffffffffffff
00d00d0000000000080000000330000004000000101000000000000000000000000000000000000000000000dd00000000000000008880000000000000000000
d010100d55777755888000003330000044000000101000000d000000000000000000000000000000dd600000060000000888000008e88ee00088800000488000
0d0dd0d057444475888000003300000004000000c1c00000600006600d0000000dd0000000000000005100610510001688e88ee0888e87e0088e880000488880
d0d00d00744444470d0000000300000004400000c1c000005100016060000660600006600000000005d100665d1000668e8e87e08e8850000888e8ee00488880
00d00d10444444440d0000000300000004000000111000000d16610051166160511661600d000660505d661000d1661088885000885000000505887e00400880
d10dd00d4444444400000000000000000000000000000000001d1d000d1d1d0001d1d1d061d6d1600000d1d005001d1050500000500000000000050000400000
00d10d00444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000
0d0000d0444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005000005000000000000000d0000000000000000000000000000008800550880000005550000000000000000000eeeeeeeeeeeeeeeeeee
00220002202909092050500050500005000500d00d00d220002200000d0000d08e8880000885778800000057750070888806000060600eeeeeeeeeeeeeeeeeee
000020200002999200505555505000005050000d777d00020200000000d00d08888e88000088788500005577f50077000080744447000eeeeeeeeeeeeeeeeeee
000044400404444000055e5e55002222505000075557000444000b0000333308ee888ee5057888500088845f507777788087441144000eeeeeeeeeeeeeeeeeee
440474740444e4e0005055555052622dddd0d0054445044e4e0b000000b33b08ee8e87ee5778884008004845000077088084411114400eeeeeeeeeeeeeeeeeee
4040444004504400005050005052266d5d507d04e4e4040444b0001331333308888887ee0588488408084805000078000084715511470eeeeeeeeeeeeeeeeeee
0505040505050050005005050052222dddd0444044400050b050b01331110005050505000885048858005800000000888807415514600eeeeeeeeeeeeeeeeeee
0000000000000000000500000505050505000505040500000b00000505000000000000008800005880888000000000000000741144070eeeeeeeeeeeeeeeeeee
000dd0dd00dd0dd00000000000000000000002000200000000000000080000000000000000080000077000000dd000dd0050005000000eeeeeeeeeeeeeeeeeee
0003252000325200009909900005558000000020200005050500000008800000008000000088805050676000000d0d005010010050000eeeeeeeeeeeeeeeeeee
0013050001305000098898890050088800000044400004040408080888885334588850011888884040406600002232000505550500000eeeeeeeeeeeeeeeeeee
0130b0000130bbb0098888890500888880000474740b004440000000088033458888801555180004440699600b2232005050005000000eeeeeeeeeeeeeeeeeee
013b0bb0013b000b0988888905d8db850004004440b350414000030008003453348331d5e5d8000414069890b533300000500051000000000000000000000000
1350b00b1300b0bb009888900549498500411004003335414004300b000b453345834015551800041400988b35bb0bb051055500500000000000000000000000
3350b0b0335bb00000098900054949850541140000515044400430000b0053345384500111000004440000033300b00b00501050000000000000000000000000
350b000035050000000090000055555004545440004545444440030000003345334530000000004444440003500bb0bb05050005000000000000000000000000
0000ccc00001ccc100005000000050000000000000000d00d0000000000000d000dd000000333033050000005550000000500000005555000000500000555500
000cc0cc001cc0cc500500800505000800000220800d777d080000087000000d0d00800003bbb3b3575000005775000005750000057777500005750005777750
00cc000c01cc000c555508880505228880202008880755578880087887800022320888003bb3bbb3577500005677500005755550574755000057775057555575
00c0000001c00000e5e588888dddd88888444088888544488888078888800022328888803b303b30577750000567755055757575577440000577775055000055
00ccc0cc01ccc0cc5555008005d5d66820e4eb008004e4e40800343775334033300080003b303b30577775000056540075777775575444005777740054555545
0000c0c00011c0c1000500800dddd2282044400b8000444008004537733450bb0bb080003b300300577550000005444057777775575044400577444054944945
0000c0c00001c0c15050008000505008505b05008b0504050800532772453000b00b800003b30000055750000005044505577750050004450055044554944945
0000ccc00001ccc100000000000000000000b00000000000000034222253400bb0bb000000300000000500000000005000055500000000500000005005555550
000000000000000060000606000000000000000000000000509030b0505599880000000000000000000000000000000000000000000000000000000000000000
0000000000000000074444700000000000000000000b000000000000550599880000000000000000000000000000000000000060000000000000000000000000
007440700000000074411440000000000000000000b3300009999990055555500000000000000000000000000000000000000000000006000000000000000000
07411400000000004411114400000000000000000b33330099799799556556550000000000000000000006000006000000000000000000000000000000000000
0415114000047000471551140000000000000000b444445097d77d79565665650000000000000000000000000000000000000005000000000000000000000000
04111140004144007415514600000000000000000411d40099411499554114550000000000000000000050000000050000000060000000500000000000000000
07411400004444000741144005000500000000000411d40099444499554444550000000000000000000000600000000000000000000000000000000000000000
00000000000000000000000004444400000000000444440009999990055555500000000000000000000600000000000000000000000000000000000000000000
00000000000000000000000004111400000000000411d40000000000000000000000006000060060000506000005605000000605000005000000000000000000
00000000000000000000000004444400005050000444440009999990055555500006060000056506005605000000056500006060000000060000000000000000
00000000000000000004000000414000004140000041400099299299552552550005656000505050000056500060600000000000000000000000000000000000
00040000000000000041100000444000004140000044400099299299552552550050555000a00500006060000000000000000000000000000000000000000000
00411000000400000451140000414000004140000041400099d44d9955d44d5500a0aa000aaa0aa000a00a0000a0050000000500000000000000000000000000
04511400004110004554454000414000004040000041400099444499554444550a9aa9a50a99a9950a95a9a5059a59a505a65a65007505000075050000750500
45544540045114005454545000000000000000000000000009999990055555505989989559899895598998955a89a895569a69a5057657600576576005765760
00000000000000000000000000000000000000000000000000000000000000002822282228828822228282822522852255285252565765755657657556576575
00000000000000000500050000000000000000000000000000000d0d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005750575000000000000000000b030b0000000d0d00000d0d0000000000000000000000000000000000000000000000000000000000000000
0500050000000000747074700000000000000000b03330b00001325200000d0d0000d0d000000000000000000000000000000000000000005050500000505050
0400040000000000040004000b030b0000000000b11311b0001330500011325200000d0d00000000000000000000000000000000000000004040400000404040
01111100001110004111114004111400000b0000041114000133bb00013330500113325200000000005000000000000000000000000000000444000b00044400
4d111d40501110504d111d4040111040001110004011104013300b001333b0001333305001113d0d05150000000000000000000000000000041400b350041400
4d404d40404040404d404d404040404004404400404040401350b00013500b003535b0000353b2520414000300000000000000000000000004140b3335041400
000000000000000000000000000000000000000000000000350500003505bb00505bb000353bb050044403313300000000000000000000000444b33133544400
434b4043434040b03453345334533453345334533453345303033450000600000006050000050006041405111505000000000000000000000414051115041400
554355b343b300004533453345334533453875334533453343434345000006000005606000006050041455555554050000000000000000000414555555541400
34435343044043b05334533453345334587887845338733455435533000060000050500000a00000044454545454440000000505050000000444545454544400
3b0b40550300b0b4334533453347884538888885338888453443534000a00a0000a0a000000a0a00044444444444450000000444444005000444444544444500
455b3453b0b0044034533453345888533437745334537453033443550099a0000a9aa9000099a900045444414444440000005441444055000454445154444400
454445b3b04b400045334533453375334537753345374533455334530a889000098890000a899000044444111444540005004411144044000444451115445400
05335540030033b05334533453347334534773345347733445444533009200000029000000280000044544111444440004404411144044000445451115444400
00000000000000003345334533453345335333453353334505035540000000000000000000000000000000000000000000000000000000000000000000000000
__map__
7f5757577f4e5d4d6e4d55544d57575656497c4749494a4749686969696a5657575756565d7b47486d56575757575757434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343000a000a000a000a000a000a000a000a00620062006200620062006200670067
5756575756575d5d48555454544d565757567c7c49477c47586c69695b7a55525656565d4e5f7b5f5d7e5757575257564343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430067006700670067000f00160014001500100011001b00120501080108030b01
5757525757576e6f6d545055545d4e57575d6d5249474949684c694b6a55556d6e6f7d6d5d464d7d7d5d5656575757574343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430c060f02100110021002100210021501150f160417011702180219011a070099
56575657577d7e507d545555554d4f4d5d5f55555454497c6869695b7a5554547e7f4e7d4e7d4f504d5d6d6e7d5756574343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343431f011f051f151f131f16200322042401270728012b012b072b172c112d122d06
575756564d5d4e4f4d4d55544f4f4d5d7e5d54555454547b7879797a5554544f4d4d4e4f7e4d5f5d5d6d5d52526d575743434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434330013103320634043501350639013a173c1c3e15401642114412461b48024802
7f57575f5d5d7e5f5d5d5e5f7e5d7e486e6d5d55554d4d5d4e555554545f7e5d5e5f485d4e5d5d6d6d6e6f5f7d7d57564343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434802480200994a0f4b074b015007009900000000000000000000000000000000
4f4e6e52526d6e6f7e6d6e4d5d4e46477b4d4d5d7e7d6f6d7d7e4d4d4e4f4d4d4d4f6f7e6d6d7f6d7d7e7f7f555555574343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430f0518071e0517101d181116280f081004050d020b09140716111f0908031105
4d5d7e5e5f7d7e7f527e7f5d7e5e7e7b7e5d5f7e7e7d4d567f6f5d5d5e5f5d7c5e5f7e7f6d7d7e7f7d507e555550545543434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434312090a0d17121d06030003000300030003000300030003000404080209070904
6f7f4e5d5e7e7d4f4d4e4f7e6d6e4f4d5d6d7e6e6f5756575657524d6e7e486d6e4d564d4f4d4e4f4d4d4e55555555554343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430b0606060b0a0604070405050506010802010906030505040804050308090100
7d545455467d7e5f5d5e5f7d4d5757574d7d7d7e7f565757575757564e4f7d7d4f56575756485e5f5d5d7e7e5455556d4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430e0207070201020102010808070800050d051104100904080201020102010c08
5755555859595a6f6d6e6f5e5756575657554f4d4d7b56575757577e5e7e4d4e5757565757565d4d4e4f4e6f6d6d6f6e4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430a0e0f0711060f051607070c0900020102010201020102010201020107060805
575747684c696a7f7d7e7f57575756575754544f7f7e4d575757566d6e5d54545757575757576d5d5e465e4f5d5d5e5f43434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434308060603020003011207050f080c030000000000000000000000000000000000
5d575768695b7a4f4d4e4f5657575859595a54547e4e4f4d564e7d7d7e55555455575658595a506d6e7e6e5f5454507b4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430f0518071e0517101d181116280f08102a03240722021c0825141b152a072004
5d4e5578797a525f5d5e5f4d46526869696b5a54555e5f5d5d5f7e4d7d5455555548586c696b5a7b7e7f7e54555859594343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343431d0a271115061711030003000300030003000300030003002b032b0626062c03
4d5d5d55554d6d6f6d6e6f5458596c694c696a467c4d7f5d5d5e6f466e55585959596c694b696a4d4e4f4d55586c696943434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434324052904240828042a042a0529062002020126052d05270527042d0a27080100
5d505e54547b7d7e7d7e55546869696969696a476e7e4d5f7b487f4e4d5468694c696969695b7a5d5e5f5d55684c4c694343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343431f0a2604020102010201250725041d0522052a0c271026020201020102012a08
7d7d5447554d7e4f4d4d555468694b69695b7a487e4e5d7b4a7d7d4d545568694b69695b797a554d4e4f6d5468694c6943434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434329032908200627061a08290c2b05020102010201020102010201020128062a06
4d55505454524e5f5d5d5554785c6969696a54544e5e5d4e7f7b7f5f5455785c69694c6a5455555d5e5f7d50785c69694343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343432803290202000301280a24032103030000000000000000000000000000000000
4d565859595a484d4e4f4d5756787979797a55545e4f487d467e4d7f4d5547787979797a54546d6d6e6f4d57577879794343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430f0518071e0517101d181116280f0810291c22172a131b16190d260a2917201d
575768694b6a4d5d4d4d5757565657505555556d6e5f7f4f5d5e5d4d7f55555657575750544d4e4f7b4f5d5d4657575643434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434326132a0e16121b0e030003000300030003000300030003002a182a1c25192117
57557879797a5d6d5d5d56575757577d49547d4d6d7d575657566d5d4d525757565757575d5d5e7e5e5f6d55555456564343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343432319291b241d2a1a2a1b2a1929192c1a0201251a2a142819281b1f1d27150000
56575755554d7e7d6d7e4d575657564d4d7f7d5d4d57575756575d4d7d5d5757575756567e6d6e6f6e6f55545555557f43434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434325132619020102010201251724171b1721192a0f2a1f26170201020102011d19
565656545d7b7d4d7d7e6e4d57575f5d7e7e4e6d4e5657575757576e4d4d4e565756577e4d7e4f7e4e7e55545054556f4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343432f1624152811221b1b132719161a0201020102010201020102010201271b2918
574d4e7e7d7d5d7e4d4d5d7e6d6d6e4d5d5d5e7e5e5757565757565f5d4e7d5e564d4e5d5d5e7e7f7e7d545554554f7f4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343432b182b1902000301241b1e161e19030000000000000000000000000000000000
7d6f5e5d4d4d7e6d5d5d5e5f7d7d7e7b494d7e4d6e6f565757566d6f6d6d6e4d4d4e4f6d486e7e504d4d4e7e4f4d4e4f4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430f0518071e0517101d181116280f0810061c0a16041714160a0d170d0a1b121b
6d4e6e52525d4d7d4d504d4d4e4f4d4d7b7d7e7e4d7f5e4e7d7d7e7f7d4e5e5d7b485f7e7d7e7f5f5d5d5e7e6d4f5e5f43434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434312150a12190e181b03000300030003000300030003000300091b041b09170217
7d567e4d5d6d6e4d7d7d5d5d5e5f5d5d6d466e6f4e4f6e4e7b7e4d4f4d4d5d46477b6f5d5e5f7e6f4d4e6e504d5657564343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430c18051a0a15051906190719051b051c02010a17021a061b071b0e1c07140000
565757567d7d7e5d5e5f5d7e6e7e6d6d7d7d6d7e5554557c6d6d6e5d4d5d5d6d7e4e7e6d6e6f7e7f7d7d7e4d575756574343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430f15091802010201020107160717121c0e19091112140a190201020102010515
57565757574d4d524f545455557e7d7d7e7f7d555454545859595a555554487d7d5d4d7d7e7f52524d4e4f575757575743434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434305100c1a07110d171518081915140201020102010201020102010201081b041a
5757525757565d5e5f55555054555d4e7e7f4e555458596c694c6b5a5555547e5e7d7e7f4e4f5e5d5d5e565757525757434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343031a0218020003010517051f0812030000000000000000000000000000000000
5757575657566d6e7b6d555454554f7e5d6d5055586c69694b69696a55505d6d6e4d5454544e5d6d6d6e5757565757574343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430000000000000000000000000000000000000000000000000000000000000000
7d565757577d7d4d7f7d4e5555547e7f485859596c6969696969696b595a4d7d4655545555546d7d7b7e7f575657567f4343434343434343434343434343434343434343434343434343434343434343434343434343434343434343434343430000000000000000000000000000000000000000000000000000000000000000
__gff__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000141a1a1000000072707270b0b13130121012121000000072707270b0b131321a1212121000000072707270b0b13130121010a01000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000098000000000000000000000000000000ff000000000000000000000000000000
__sfx__
010400000e043260431f003200032604326043260432603329003290032800327003250032200320003200031f0031e0031e0031f00320003220032400324003210031d0031b0031900317003170030000300003
010400002604326043260331770013700127001270012700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
4d0300001a5502655026550005001a5001a5001a500005001a5001a5001a500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000000000
490900001a63432625180001a0001a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d040000260532605332043320330e6000e6000960000300091000000037600091000e6000e6000960000300091000030032600266000e6000e60002600026030910000300376030030037600376003f60000000
79170000091430010032502266000263002611096010030309143000003760009100026300261109601003000914300300326002660002630026110260102603091430030037603003002b6132b6113f60100000
79170000091531d0301c0201a0200263002611096011d02209153180200e532105300263002611096011802009153210201d0202102002630026110260102603091531800028732297312b6132b6113f6011f022
7917000009153185301a5311a5220263002611096011d53009153175301853118522026300261109601135300915317530185301a5320263002611026011d530091531a5301d530215322b6132b6113f60121000
411700000205002050020520205202052020500205002050020500205002052020520205002050020520205002050020500205002052020520205202050020500205202052020500205002052020520205202050
391200000e5000e5000e5000e5000e5000e5000e50000000155001550015500155001550015500155000000013500135001350013500135001350013500135001150011500115001350013500135001550015500
9105000028063286431c0531c60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011700000e5500e5500e5520e5451555015550155401554213550135401354213532135350000011550105500e5500e5420e535105500e5500c55011550135501855018550185421853217550135501055010540
011700000e5500e5520e5520e5400e535000001155011540105501054010535000000e5500e5520e5400c5500e550105501155011540105501055210545105001355013550155611555215545135001155010550
011700001113010137131300e1300e1300e1320c1300c11511130101311012513130131371113011130101310e1301113710130131301313011130111300c1310e1300e1300e1250010011137101300e1370c130
011700000e1301013711130131300e1300e1321513015130131301113011115131301313711130101301813118130151301513015135131371513011130181311813017130171351310011137101300e1370c130
011700000e1501015711150131500e1500e152151501515013150111501b100131501315711150111501015115152151521513015125131571515011150181511815015150001000010011157101500e1570c150
050600001107100001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000052670061710267006171236700617123570161712357016170a157006170d147006170d147006170b047006170b037006170a037006170a727006170b727006170c717006170b117006170811700617
010600000e5511a555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
91040000154400e4501a4600e4201a4600e4501a4400e433164001f400174001440018400154001940016400114001a4001e4001b40018400214001940022400144001d400154001e400164001f4001740020400
010a00000e7140e7120e7220e7220e7320e7320e7420e7420e7420e7420e7320e7320e7220e7220e7120e715147000c7000870005700027000170000700007000070000700007000070000700007000070000700
191700000e5600e5600e5620e555180001800018000131300e130111301313015130151321513213130111301313013132131321313511130101300e1370c1300e1300e1320e1320e13511564115601156211555
191700000e5600e5600e5620e55518000180000c0000c1300e1301113013130151301513215132131301113018130181321813218135101301313715130171301a1301a1321a1221a11311564115601156211555
411700000e5600e5600e5620e555180001800018000131300e130111301313015130151321513213130111301313013132131321313511130101300e1370c1300e1300e1320e1320e13511564115601156211555
4117000010552115570e5400e5400e5420e5450c0000c1400e1301113013130151301514215142131401114018140181421814218145101401314715140171401a1401a1421a1421a1421a1321a1230b5500c550
79170000091530e1000e1300e13302630026110960100303091530e1450e1450e14502630026110960111100091530e1450e1450e1450263002611026010e700091530e1450e1450e1452b6132b6110c11100000
49040000131500e140131500e14011150151401a1501a1401a100261001a100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
031300001511617126181461a15718167171571514717143111330e1130e100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
49190000091430010000000376002b613001002b61300303091530000037600000000263002611376000000009153003002b6132660000000026300261102603091530030037603003002b6132b6102b61500000
01190000020700207002072020720207202070020700207010061100601006210062100601006010062100600c0610c0600c0600c0620c0620c0620c0600c0600b0620b0620b0600b0600b0620b0520b0420b030
b91900000e254102500e257102520e242102400e2300e220152541524015242152421524215230152301523513254132401524217232172321023613230102200c2400c2400e2401324013240132471524015245
011900000207002070020720207202072020700207002070100611006010062100621006010060100621006013051130501305013052110521105212050120500e0520e0520e0500e0500c0520c0520e0620e050
b91900000e254102500e250102520e242102400e2300e2201525415240152421523217227172201722515200132541324015242182361d2321d2321e2301e2200c2400c2400e2401724017247172401524215245
490900001a5561c556265561f55600500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
110b00001f077190771d0771a0671f067210671805719057297002970000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000000000000000000
c51700000216502165001000010000100001000015000150021650216500100001000010000100001000010002165021650216500100051650210000150001500216502165001000010000100001000010000100
490900001a644326351a644326350960000300091000000037600091000e6000e6000960000300091001f60013600026000e6000e600026000260009100003001f6002b6001f6001f6003f600000000000000000
01170000091530010037500375000263002625026350e6000915300000375000910002630026250960137500091531f625136003750002630026250260137500091530e6340e6350e6000e600026351f62300000
110500002b5462b54609503005002b5462b546095030050037500375000950000500005000050000500005001f000210001d000180001f000210001d000180000050000500005000050000500005000050000500
0117000000000000000e050110501505015052150521505215045000001305011050130500e056110501105211052110450c050100501004011050130500e056100500c0500e0500e0500e0520e0520e0500e045
c51700000216502165001000515004150041450015000150021650216500100001000015004155041550010002165021650216500100051650210000150001500216502165001000010000000021550515507155
1117000000000000000e050110501505015052150521505215045000001305011050130500e056110501105211052110450c050100501004011050130500e056100500c0500e0500e0500e0520e0520e0500e045
2917000010552115570e5400e5400e5420e5350c0000c1300e1301113013130151301513215132131301113018130181321813218125101301313715130171301a1301a1321a1321a1221a1121a1131104411052
0d1700001d0401c0471f0401a0401a0401a04218040180251d0401c0411c0351f0401f0471d0401d0401c0411a0401d0471c0401f0401f0401d0401d040180411a0401a0401a035180001d0471c0401a04718040
0d1700001a0401c0471d0401f0401a0401a04221040210401f0401d0401d0251f0401f0471d0401c0401804118040150401504015045210401c0401d0401804118040170401704500000210401c0401f0411f042
191700000e5000e5000e5000e500180001800018000131300e130111301313015130151321513213130111301313013132131321313511130101300e1370c1300e1300e1320e1320e13511564115601156211555
7d1700001105010000130500e0500e0500e0520c0500c045110501005110055130000e0550e0550e055100000e0501105710050130501305011050110500c0510e0500e0500e0450c0000c0550c0550c0000c055
7d1700000e05510000130500e0520e055000021505015052130501105011045130000e0750e075100000c0401005110050100550e0000e0750e000180000c050110511105211055110000e0000e0000e00000000
0117000000000000000e0601106015060150621506215062150550000013060110601806017066150601306213062130650c060100601005011060130601506115062100600e0600e0600e0620e0520e0500e045
1517000000000000000e0501105015050150521505215052150450000013050110501805017056150501305213052130550c050100501004011050130501505115052100500e0500e0500e0520e0420e0400e035
011700000915318060110001500002630026250263518050091531a0500c0500e05002630026251505215052091531f6251360013050026300262517050110500915302644026450c0600b070026350907007070
01170000091530c0503750037500026300262518030180350915300000100500e04002630026250c0500c045091531f62513600130500263002625026010c0000915302634026350c0600b070026350707009070
111700000977318060110001500002630026250264518050097731a0500c0500e05002630026251505215052097731f6251360013050026300262517050110500977302634026350c0600b070026350907007070
11170000097730c0503750037500026300262518030180300977300000100500e04002630026250c0500c045097731f62513600130500263002625026010c0000977302644026450c0600b070026350707009070
791700000e5500e5400e5420e5451554015540155401554213540135401354213532135350050011540105400e5400e5320e525105500e5500c55011550135501855018550185421853217550135501055010540
791700000e5500e5520e5520e54000500005001155011540105501054010535005000e5500e5520e5400c5500e550105501155011540105501055210545105001355013550155611555215545135001156010560
791700000e500025000e500025000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e536105460e55602566
1517000000000000000e0501105015050150521505215055390130000113050110501805017056150501305213053000010c050100501004011050130501505115052100500e0500e0500e0520e0420e0400e035
c5170000021650216500100051501903426031260222602202165021653952300501001500415521042210420216502165021651804218042180221802200150021650216500100025643c001021550515507155
c517000002165021650010005150160041803118022180220216502165395230050100150041552103221032021650216502165180421f0421f0321f03500150021650216500100025643c001021550515507155
a91900000e244102400e247102420e232102300e2200e210152341523015232152321523215220152250020013244132301523217221172221722013220132250c2300c2300e2301323113232132321522015220
a91900000e244102400e240102420e232102300e2200e2101524415230152321522217217172101721515200132441323015232182201d2211d2221d2221d2100c2300c2300e2301a23017231172301723217235
05060000230531d0510e1710e073003000e0730e07300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a90600001f7601f760007001f7601f760007001c7601c7601c7621c7621c7621c7621c7621c7601c7601c76500700007000070000700007000070000700007000070000700007000070000700007000000000000
__music__
00 05084c44
01 05080b44
00 05080c44
00 19080b44
00 19080c44
00 05081544
00 05081644
00 05081744
00 05081844
00 06080b44
00 07080c44
00 06080b44
00 07080c44
00 05080d44
00 05080e44
00 19080d44
00 19080e44
00 19082d44
00 05081644
00 19081744
00 05082a44
00 19082b44
00 19082c44
00 25082e44
00 25082f44
00 25234344
00 25284344
00 25232744
00 25282944
00 25233044
00 25283144
00 25237244
00 25284344
00 32232744
00 33283044
00 34232944
00 35283144
00 343b2944
00 353a3944
00 19237244
00 19283844
00 05233644
02 05283744
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 1b1c5844
01 1c5e1d44
00 1c481f44
00 1c3c1d44
00 1c3d1f44
00 1c1e1d44
02 1c201f44
03 08484b44
__label__
fffffffffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff67777777f7fffff6ffff7ffff6fffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6677aa577fffff7fffff6ff7f6fffff7fffffffffff
fffffffffffffff5fffff5ffffffffffffffffffffff7fffffdffffafffff7ffffffffff7ffffbfffffffff66777757ffffff6ffffffffffffffffffffffffff
ffff7fdfffffff5f5fff5f5fffffffffff7ffffffffffffffdadffffffffffffffffffffffffbf3fffffff7f66a6776766f77ff6ff76ffffffffffffffffffff
fffdffdffdffff5f55555f5ffffffaffffffffffffffffffffd3ffffffffffffffffffffff3fb3ffffffffff7656566576656ff656561f11ffffd11ffff11f11
ffffd777dfaffff5505055fffffffffffffffbfffffffffffff33ffffffffffffffffffffaf3b3faffffffff776565a666a656ff6a646f55ffff511111f55f55
ffff75557fffff5f55555f5fffffffffffffafbf37fffffffff3ffffffffaffffff7fffffff3b3fffffffffff766a656a66655656965af44ffff511111f44f44
fdff54445fffff565666565ffffffffffffff3b3ff5111affffffffffffff11111111111ffff111111111111111165a56566655a9a5a4f44ffff5ff111f44444
d7df40404ffff65665656656ffff7ffffffff3b3501d91fffffffffff5111d999999999d1f50199999999999999d1559aa5665aaaa564444ffff5ffffff44444
4444f444fffff66566666566fffffffffffffff501d99d1ffffffff501d9999999999999d1001d99999999999999165aaaa566a99a595454ffff5ffffff44444
565656465fffff666666666ffffffffffffffff01d99991fffffff501d9999d111111d9991000111199111111d991565598aaaa9aa96a54fffffbbffffff4444
6666666666fffffffffffffffffff5fff5ff7f50199999d1fffff501d9999d100000011d910000001991000001d917765aa999899a9594fffffbbbbffffff444
666666666fffffff7fffffffffffff5f5fffff0019999991ff7ff00d9999d10000000001915000001991000000191f6759aa99a998a6a5fffffbbb3fffffff44
fffffffffaffffffffffffffff22225f5fffff01d99d999dffff501d999d1fffff50000111ffff001991fff500111ff6665aa998a9aa96ffffbbb3335fffff44
fffffffffffffffffffffffff2622ddddffff50199d1999d1fff001999d1ffffffff5000ffffff001991ffff111ffffff669aa988999a6fffbbb333b35ffff44
ffffffbffffffffffffffffff2266d0d0ffff0019911d9991fff001999dffffffffff500ffffff001991fff0191fffffff668a888899a96fbbb333b33b5fff44
fffffffbf3fffffffffffffff2222ddddfff501d99101999d1ff0019991fffffffffffff7fffff0019911111d91ffffffff6699822289a6bbbb33b33b335ff44
fffff33b3fffffddffffddff656565656fff50199d001d9991ff0019991ffffffffff7ffffffff0019999999991ffafffffff69822289abbbb333b33b3355f44
ffff7f3b3fffffffdffdffff666666666fff00d9910001999d1f0019991fffffffffffffffffaf0019999999991ffffffffff6698228aabbb333111b33335544
ffffffffffffffff3333fffff6666666fff50199911111d9991f001999dfff7ff11111111111ff0019911111d91fffff7ffff46a9888a63bb331111133335544
ffffffffffffffffb33bf7fffffffffffff01d999999999999d1001999d1fff0019999999991ff0019910000191f7ffffffff446a99a6ff55511111115555f44
ff311331133113313333ffffffffffafff50199999999999999100199991fff0011d999999d1ff0019910000111ffffffffff4456aa64ff5551111111555ff44
f33113311331133111ffffffffffffffff00d999d111111d999d100d999d1ff000011d999d1fff001991ff500ffffffffffff444114445555555111555555f44
f66565665656656566fffffffff7fffff501d99d10000001999910019999d17f5000019991ffff001991ffffff111ffffffff444114445554555545555455544
f66666666666666666fffffffffffffff00d999100000001d9991001d9999d11ff00019991ffff001991fffff1d91ffffffff444114445544455444554445544
fff6666666666666ffffffffffffffff501d9991ffff5001d999d1101d99999d11111d9991ff5011199111111d991aff7ffff444554445541455414554145544
ffffff7fffffffffffffffffffffff511dd9999d11fff11d999999d101d9999999999999d1ff01d99999999999991ffffffff444444445541455414554145544
ffffffffffffffffffff7ffffffff5019999999991f50199999999910011d999999999d11111119999999999999d1ffffffff444444444445444454444544444
ffff2ffffffffffffffffffffffff0011111111111f0011111111111000011111111111d99999111111111111111fffffffff554444444444444444444444444
f7f292fffffdddfffdddfffffffff000000000005ff00000000000f5000000000000011995599100000000000005fffffffff444444554444444555444444444
fbf32fffffffffdfdffffffffffff50000000005fff50000000005fff500000000001d995111110000000000005ffffffffff444444444444445595544444444
ffb3fffffffff2232fffaffffffffffffffffffffffffffffffffffffff11111ff0119951ffffffffffffffffffffffffff7f444444444444455999554444445
ffb3ffffffffb2232fffffff333fffffffffffffffffffffffffffff111d9995111d995111f7fffffffffffff7fffffffffff444554444444551111155444445
fffffffffffb5333fffffff33333ffffffffffffffffffff7fffff01d99999999119999991ffffffffffaffffffffffffffff444444444445591515195544445
ffffffffffb35bbfbbff7f3399933ffafffffffffffafffffffff501999d1159959991111ffffffffffffffffffffffffffdd444444444445511111115544444
fffffffffb333fb3fb3fff3999993ffffffffffffffffffffffff00199d11999599951fffffffffffffffffffffaffff7cdcd554444444455511515115554444
fffffaffb335ffb3fb3fff33aaa33ffff2ffffffffffffffffaff001d999991199951fffffaffffffffbfffffffffffdcd6d1554444444455591111195554444
fffb5b5b53556b33b33fffb3aaa3bfff292fffaffffffffffffff000111111599911ffffffffffffff37bfffffffffdc11111444445544455511515115554444
fd3353535356b36b37ffff3baaab3ffff23fbfffff7ffffffffff50000001599951ffff7fffffffffff3bf3fffffffdc11176444445544455511111115554444
66656565656666666fffffbbbbbbbfffff31111fffffffffffffff500001599511fffffffffffffafff3b3fff111111111111444444444455591515195554444
66666666666666666ffff3b99999b3fff001991ffffffafff111111ff50011111111111111111111111113501d9999999999d1d4444444455999111999554444
ff6666666666666fffff63bbbbbbb36f501d99d1fffffff0019999d1ff001999999119999999999999991501d9999999999991cdddddddddd22566525ddddddd
ffffffffffffffffffff63333333336501d99991fffffff001d99991ff0011999d11199d1d99999d1d99101d999d11111d999117c7c7c7c7c26655225ddddddd
f333ff33ffff7fffffff6333333333600199999d1ffffff5001d999d1ff00199d100199101d999d101d9101999d0000000d991c11111111122566625c7c7c7c7
33bbfbb3f33fffffffff6666666666501d9999991ffff7ff5001999911f00199100019d100199910001911d999d05f50001d91ddc7cc7c11266552251c1c1c1c
fbbbbbbff3b33ff33ffff6666666660019999999d1fffffff0019999d1f001991f00191000199910001111999915fff5000191ffddddddc22566625c11111111
ffbbbffff3bbb3bbbffffffffffff501d99dd99991fffffff0019999911001991f001115001999150000019999d1ffff500111fffffaffd266552257c1c11116
33ff33333ff33bbffffffffafffff001999119999dfffffff00199999d1001991f0005ff0019991f50000199999d1ffff5000fffffafa944446625717c1c116d
bb3bb33bbfbb3bfaffffffffffff501d99d11d999d1fff7ff00199d999d101991f005faf0019991fffff01d99999d15fff505ffffffa944f4444257717c1c11d
3bbb33bbbbbbfbfffaffffffffff501d99d00d99991ffffff001991d999111991fffffff0019991fffff001d99999d11ffffffffffa9444444445567777c1c11
34b3345bbb538853fff7ffffffff00d99910019999d1affff0019911999d11991fffffff0019991fffff5001d999999d1ffffffaff94f4433344337767ccc1c1
45b345334b88788843ff33fffff500d99d1001d99991fffff0019911d999d1991f7fffff0019991fffff50001d999999d15ffffffa444433bb4bb377c7cc1c11
53345334587887878bffbb3ffff501d99df000d9999d1ffff00199101d9991991fffffff0019991fff7ff50001d999999d11ffffff94444bbbbbb7677cccc111
334333453887887883bbbbb33ff0019991f0001d999d1ff7f001991001999d991fffffff0019991fffffff50001d9999999d1ffffa444887bbbdd677c7cc1c11
3431133333117753345bbbbb7f500d99d111111d9999dffff001991000d999991fffff7f0019991ffffffff50001d9999999d1ffff98787878bd66777cccc111
4533313331377773453fffffff501d99999999999999d1fff0019910001d99991ffaffff0019991fffffffff5000059999999d5fa948878888bdd677c7cc1c11
5333331313337734533bfaffff00199999999999999991fff0019910000199991fffffff0019991ffffffffff500001d9999991ffa44433744dd66777cccc111
33333444433d77d5334bfffff501d999d1111111d9999dfaf01d99150000d9991fffffff01d999d1ffffffffff500001d999991ff94443b334d33677c7cc1c11
11333414133dddd3333333b33001999d100000001d999d1f11d9991110001d9917fffff11d99999d11fff111fff500001999991fa44943bbb3bbb6777cc1c111
11144444433345334bbb3bb3501d99910000000001999d1019999999150001991ffff5019999999991f50191ffff50001999991fa9444773bbbd6777c7cc111d
11145d9493345334533bbb3f0019991dfffff500019999d1111111111f0001111ffff0011111111111f0019d1ffff50019999d1fa44444444bd667777cc1c11d
d5d5d5a9a84533453345bfff00d9991fffffff5001d999910000000fff50000ffffff00000000000fff0019d1ffff501d999913a94449444db6d6777cccc111d
d5d5ddd8785338873453faf51d9999d1fffffff001d9999d110005fffff5005ffffff50000000005fff00199d11111d99999d14a44444444d6d6677c7cc11111
dddddd38453387888533ff11d999999d11fffff11d9999999d1ffffffffffffffffffffffffffffffff0019999999999999d1fff8883344dd6677777cc1c1111
5334533453347888733450199999999991fff50199999999991fffffffffffffffaffffffffffffffff001d99999999999d13ff8803bbb3b3367777cccc11111
3345334533453777334300111111111111fff00111111111111fffffffffffffdffffffffffffffffff0001111111111111335008883bbbbb37777cccc1c111d
345788783453d777d453000000000000fffff000000000000ffffffffffffffdadfffffffffffffffff5000000000000005ff007808008bd6677c7ccccc111d6
458878887533ddddd533500000000005fffff500000000005fffffffffffffffdbfffffffffffbffffff50000000000005fff007888888b6677c7ccccc1111d6
578788878834533453345fbfffffffffffffffffffffffffffffff3ffbfffffffbffffffffffafbf3fffffffffffffffffffffd5d5bbd5bd6777c7ccc1c111d6
33457775334533433345333ff333fffffffffffffffffffffffffbf3bffffffffbffffffffffffb3fffffffffffffffffffffffddbbbbdd66777c7cccc1111d6
3457777734533433bb5333fbbb33ffffffffffffffffffffffffffb3bffffffffff7ffffffffffb3ffffffffffffffffffffffff9b33bbdd677c7cccccc111dd
453377734533453bbbbb4fbbbbbfffffffffffffffffffffffffffb3bfffffffffffffffffffffffffffffffffffffffffffefffabb33bb6d7777ccccc11111d
533d777d87845334b3bb5bb333bfffffffffff3ffffffafffffffffffffffffffffffffffffffffffffffffffffffffffffe7eff94bb33b88777c7ccc1c11111
334ddddd88853345bb3bbb33bbbffffff7fffff3fbffffffffffffffffffffffffffffffffffffffffffffffffffffaffffbefffa44bb88788877ccccc111111
34533453d7d3b4533bb3bbbbbbfffffffffffff3bffff111ffffafffff111fffff222ffffafffff222faffff7fffffffffbbfffff94487887878c7ccccc11111
45334533dddb3bbb45bbbbffffffffaffffffff3bffff11111fffffff1111ffaff2222fffffff22222fffffffffff7fffffbfffffa4488788788bbb3bc1c1111
53378334533bb33bb3bb3afffffffffffffffaffffffffff1111fff111fffffffffff222fff2222ffffffffffffffffffffbff7fffa944477d6bb33bbcc1cc11
338888453345bb33b3bb3fafffffffffffffffffffffffffff11ff111fffffffffffff222ff22fffffff7ffffffffffffaffffffffa4447777b33bbbccccc1c1
3457745334533bbb88808afffff7fffff111ffffff7ffffff4444444fffffffff7fffff4444444fffffffffffaf222fffffffffffff9444776bbbbb7ccccccc1
45d7333333334338808888fffffffff111111fffffffffff44444444f7fffffffffffff44444444fffffffffff222222ffffffffffaf94d77db677b3bccccccc
533d3d3453333500888008affffff111111111fff1111fff44d144d1fffffefffffffffd244d244fff2222fff222222222fffffafffa44ddddb66b3333cbbbbc
333533333bbb4007808008afafff1111111111ff111111f444114411ffffe7efffaffff224422444f222222ff2222222222ff7ffffff944444dd67bbbb7b33bb
34bb3344bb3b40078888884affff111111f1114441111144f4444444ffffbefffffffff4444444f4422222444222f222222fffffffaf8088844dd67bb7cb3b33
4b3bb494bb3b4445d5d5d53bfaff111111ff114444111144fff94449fffbbffffffffff94449fff442222444422ff222222ffffffff888808844b33bbbbbbb3b
4bb3bb44b3b4334ddddddd33afff11111ff5554444ff55ff55fa949affffbfffffdffffa949af55ff55ff4444555ff22222ffffffaf800888005bbb6b33bbbbb
44bb3b44bbb43b333d3333b3bfaff111ff55ff55fff5f5fff5ffffffffffbffffdadfffffffff5fff5f5fff55ff55ff222ffffffffb80080870043b3bb3b33bb
44b4b4494b443bbb3bbb33333affffffff5dddd5dd5ddd5dd5ffffffffffffffffdbf3fffffff5dd5ddd5dd5dddd5ffffffffffafab88888870094bbd6bbb77b
94b444444b44943bbb333b3b3bfaffff6d5dddd5dd5ddd5ddd5d6fffffffffff7ffb3fffff6d5ddd5ddd5dd5dddd5d6fffffffffabd5d5d5d5d344b4dddbbbbb
44b4333443344433b333333333afaff6d6ddddddddddddddddd6d6ffffbfffff7ffb3ffff6d6ddddddddddddddddd6d6fffffafab3bddddddd3344b944dbbb7b
44433bb3bb344333b333333b3b3afaf66d6d6d6d6d6d6d6d6d6d66fffffbf3fffffffffff66d6d6d6d6d6d6d6d6d6d66ffffffab3b33333333333444444ddb7b
b44bbbbbbb44333333b33b3333b3afaf6666d6d6d6d6d6d6d6666ffffffb3fffffffffffff6666d6d6d6d6d6d6d6666ffffafa53b33b36333b3333444444db6b
bb434bbb44333333333333333333bafaff66666666666666666fffafafab3ffafafaffffffff66666666666666666fffffffa3b3333333333333333449444bd6
3bb4444b4333333333333333b3b33bafafff6666666666666ffafafafafafaafafafafffffffff6666666666666fafafafab3b333b3353333333b33334449bdd
33bb444b333b333333333333333333bafafafafafafafafaffafabb3b3b3b33b3b3b3baffafafafffaffafaffafafafa3b33563533333363333333333344444d
b33b443333333333333b3333333b3333b3afafafafafafafaa3bb3333b334443b3b3333bafafafafafaa3b3b3bb3b3b3b3333356533633333333333333344444
bbbbb333333333333333344433333b333bb33b3b3b3b333b33b33333333444443333b333bb3b3b3bb3b3b3b3b33b3b3333363633633536333b33333333334494
444bb34444333b333333444443333333333333b3394333333333b3334344445433b3333b33b3b3b3b33b33333333333b63633565365635333333333333333444
4944b3444433333334344445433333333b3333333443334443333333344445443333333333333333333333b33b33b33356565353533356533333b33333b33334
4443b34995333333334444544333333344433334444434444433333349995443333333333b333b33b33b3333333333353555a335336363333333333333333333
43333444943333333499954433333334444433b3594434544443433349994433b333333333333333333333333333333a3aaaaa3aa3a33a333333333333333333
433334444433b33334999443333333345444434399453445444433334994433333333333333333333333333b333333a9aa9a99a99a95a9a533333333b3333333
33b3335544433333349944333333b334454444334445334454994333344433333333b3333333333333b3333333333598998989989989989553333333333b3333
333333994443333b3344433334433333445994433333333449994333333333b3444333333333b3333333333333355282228882882282828225333b3333333333
333333994553333333333333444433b334499943344443334499433833333334444433333333333333333333335355222222222222222225535333333b33b333
3333b3444533333333334333449543333344994334444333344433888333833454444343333333333b3333b33335355555555555555555553533333333333333
33333333333333333354443334994333333444333594433b333333888338883445444433333333333333333333335353535353535353535353333333333b3b3b
33333333b3333443355444334444444333b3333334944433333333363838883344599443333333333333333333333535353535353535353533333b3333b3bfaf
b334443333334444344455333445444333333333344444333444433688836333344999433b33333333333333b33333333333333333333b3b3b3b333b3bfafafa
33454433b34449443444444333544453344443b34445533334444336888663333344994333333333333333333333333333b33333b3b3b3b3b3b3b3b3bfafafff
334544433334995433449443b3394453344443334449433b34445333363633333334443333333b3333333333333b33b3333333b33bfafafbfafafafafaaff5ff
334544333355444333349943333443333449533355444333444443333633344443333333333333333b3333b3333333333b3b3333bfafafaaafaaafffffffff55
344544333994443333354443333333334499433b354443334444433b36333444433333b3333311333333331133333333b3b3bb3baaf5556ffffffffff7ff5666
34994433344444333b3444433b3333b3444443333333333335544433333334495333311333b31333333311111b33b33bfbfbfaffaf555555fff7ffaff7ff5666
3499934334454333333333433333333335544433333338333994443333334449433b33311331333333311111133b3bbfafafaffffff56655ffffffffffff5655
34994333333333b333444333333b3333344444338333888339445533b333444443333333344443111444111dddb3bffaffffff7fffff555f65ffffff5ff55555
3344333b33333333344444443335444334445538883388833444533333333554443333333141444114445dddd33bfafffffffffff5fff7ffff555555ff655555
333333333b33333344544944435549933444533888383633333333333383349444333333344445315d5d55dd3bffaffff6f55555fffffff5f53335555fff5555
3b333333334443333444544443444993333333336388863333333833388834445533b33339495ddd5d5ddd33bfafffff5f5555555ff5fffff53355555ffffff5
333444333444443333444444334445533333333366888634444388833888344453333333889a5dd5dddd333bfaffafffff55555655fffffff53555555ff5ffff
3344443334544443433333333334444433b3554336363334444388838363333333333338888ddddddd3333bfafffff7fff56555555ffaffff55555355fffffff
3344943b34454444333b34443334944433344444333633344953363888633b333333b3366833dddddb333bfaffffffffff56655555fffff5f5555555ff555f5f
33444433334454994333344543354443333444443336334449433668886333333b3336663333b333333bffffff555555ff56665555ffffff6f55555ff55555ff
3344444333344999433344454334444333344544433333444443336363333333333336333333333b33bfaff5f56665555ff555555ff6555fffffffff5555335f
b3359443b3334444433b344543344443333334495433333554443333633333b33333b33333b333333bfafffff56655555f5ffffff5ff555555fff5f55555335f
333994533b33344433333445443333333b3334444433b334944433b3633b333333333333333333b3faff7faff56555555ffffff7fff5655555ff5ff555555355
33344453333333333333344994333333333334444433333444553333333333333b33333333333333aafffffff555556556fffaff5f5565555555fff553555555
3b3333333333333333b3439994333b3333333334433333b4445333333333b3333333333333b333bfffffaff5f5555555fff7ffffff5665555555f7ff5555555f
33333333333b3333333333499433333b3333b33333333333333333333333333333333333333333faffffffff6f55555f5ffffffffff56555555fffff555555ff
__meta:title__
age of ants
eeooty
