pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

function _init()
  cartdata "lootslime"
  nB()
  n3()
end

function n3()
  P = 0
  nC()
  nD()
  n4()
  nE()
  nF()
  nG()
  nH()
  nI()
  ns()
  nJ()
  palt(0, false)
  palt(15, true)
  n6()
  nK()
  nL()
end

function _update()
  if Q then
    nM()
    return
  end
  nN()
  if j > 0 then
    j = j - (1)
    return
  end
  nO()
  nP()
  nQ()
  nR()
  nS()
  nT()
  for n in all(u) do
    nU(n)
  end
  nV()
  nW()
  nX()
  nY()
  nZ()
  en()
end

function _draw()
  if Q then
    ee()
    return
  end
  cls()
  ed()
  eo()
  local n, e = ef()
  camera(n7 + n, n9 + e)
  map()
  map(0, 0, 0, 0, 128, 64, 128)
  et()
  nb()
  for n in all(u) do
    e1(n)
  end
  el()
  map(0, 0, 0, 0, 128, 64, 127)
  ei()
  e0()
  ea()
  ec()
  er()
  e2()
  eh()
  eu()
  np()
  e8()
  e5(l.x - 8, l.y)
end

n7 = 0
n9 = 0
i = 0
a = 0

function nR()
  local e, n = flr((l.x + 2) / 128), flr((l.y + 4) / 128)
  if e ~= i or n ~= a then
    if n > 3 or n < 0 then
      return
    end
    i = e
    a = n
    n6()
    e3()
    nn = false
    e4()
    es()
    e6()
    e7()
    if i == 3 and a == 1 and F >= 50 and not ne then
      ny()
    end
    if l.x >= 376 and l.x <= 384 and l.y >= 168 and l.y <= 216 and ne then
      e9()
    end
  end
  i = e
  a = n
  n7 = i * 128
  n9 = a * 128
end

function k(n, e)
  return n.x + 1 < e.x + 8 and n.x + 7 > e.x and n.y + 5 < e.y + 8 and n.y + 8 > e.y
end

function e7()
  if a < 4 then
    for n = 1, #g do
      local n = g[n]
      if n.x == i and n.y == a then
        n.visited = true
        eb()
        break
      end
    end
  end
end

function nC()
  nd = 0
  q = 0
  z = 0
  R = 0
end

function nN()
  nd = nd + (1)
  if nd >= 30 then
    nd = nd - (30)
    q = q + (1)
    dset(6, q)
  end
  if q >= 60 then
    q = q - (60)
    z = z + (1)
    dset(7, z)
  end
  if z >= 60 then
    z = z - (60)
    R = R + (1)
    dset(8, R)
  end
end

function nI()
  l = {sprite = 1, x = 181, y = 184, prev_x = 0, prev_y = 0, vely = 0, prev_vely = 0, velx = 0, prev_velx = 0, hit_bottom = false, hit_left = false, hit_right = false, hit_top = false, grounded = false, facing = "right", jumpting = false, falling = true, wall_jump_timer_left = 0, wall_jump_timer_right = 0, jumps = 0, outline = false, last_safe = {x = 0, y = 0}, on_ladder = false, dead = false, coyote = 3}
end

function nS()
  if l.dead then
    return
  end
  if not l.grounded and l.coyote > 0 then
    l.coyote = l.coyote - (1)
  elseif l.grounded and not l.hit_left and not l.hit_right then
    l.coyote = 3
  end
  l.prev_vely = l.vely
  if l.wall_jump_timer_left > 0 or l.wall_jump_timer_right > 0 then
    l.wall_jump_timer_left = l.wall_jump_timer_left - (1)
    l.wall_jump_timer_right = l.wall_jump_timer_right - (1)
  end
  ep()
  if (l.hit_left or l.hit_right) and l.vely > 0 then
    l.vely = l.vely + (.1)
    if l.vely > 1.5 then
      l.vely = 1.5
    end
  else
    l.vely = l.vely + (.3)
  end
  if l.on_ladder then
    l.vely = 0
  end
  ey()
  em()
  if l.velx < .4 and l.velx > -.4 then
    l.velx = 0
  elseif l.velx < 0 then
    if l.grounded then
      l.velx = l.velx + (.3)
    else
      l.velx = l.velx + (.2)
    end
  elseif l.velx > 0 then
    if l.grounded then
      l.velx = l.velx - (.3)
    else
      l.velx = l.velx - (.2)
    end
  end
  if l.prev_vely - l.vely > 2 then
    ek()
  end
  if abs(l.velx) > 1.5 then
    l.velx = sgn(l.velx) * 1.5
  end
  l.prev_x = l.x
  l.prev_y = l.y
  eg()
end

function ew(n)
  local e = max(1, ceil(abs(n)))
  local n = n / e
  for e = 1, e do
    if not l.grounded then
      l.y = l.y + (n)
    elseif l.vely < 0 then
      l.y = l.y + (n)
    end
    no()
  end
end

function ev()
  if fget(mget(l.x / 8, l.y / 8), 1) then
    return false
  end
  local n, e = l.x, l.y + 8
  local d, n = mget((n + 1) / 8, e / 8), mget((n - 1) / 8, e / 8)
  if not fget(d, 2) and not fget(n, 2) and fget(d, 0) and fget(n, 0) and l.grounded then
    return true
  end
  return false
end

function em()
  if ev() then
    l.last_safe.x = l.x
    l.last_safe.y = l.y
    dset(20, l.last_safe.x / 8)
    dset(21, l.last_safe.y / 8)
  end
  ew(l.vely)
  no()
  if l.grounded and l.hit_top then
    if mget(l.x / 8, (l.y - 1) / 8) == 0 then
      l.y = l.y - (1)
    else
      l.x = l.x + (1)
      l.vely = 0
    end
  end
  if l.grounded and l.vely > 0 then
    l.y = l.y - ((l.y + 8) % 8)
    l.vely = 0
  elseif l.hit_top and l.vely < 0 then
    l.y = l.y + ((4 - l.y % 8) % 8)
  end
  e_()
end

function e_()
  l.x = l.x + (l.velx)
  no()
  if l.hit_left then
    local n = flr(l.x / 8)
    l.x = n * 8 + 7
    l.velx = 0
    l.sprite = 1
  elseif l.hit_right then
    local n = flr((l.x + 8) / 8)
    l.x = n * 8 - 6
    if l.velx > 0 then
      l.velx = 0
    end
    l.sprite = 2
  end
end

function nb()
  if l.dead then
    return
  end
  ej()
  if not l.on_ladder then
    spr(l.sprite, l.x, l.y)
  end
end

function ep()
  if l.velx < 0 then
    l.facing = "left"
  elseif l.velx > 0 then
    l.facing = "right"
  end
end

function ey()
  if l.on_ladder then
    ex()
    return
  end
  if btn(0) and l.wall_jump_timer_left <= 0 then
    l.sprite = 2
    l.velx = l.velx - (1)
    w = 0
  end
  if btn(1) and l.wall_jump_timer_right <= 0 then
    l.sprite = 1
    l.velx = l.velx + (1)
    w = 0
  end
  if btnp(3) and nf then
    r = true
    nm()
  end
  if btnp(5) and nt == true and b.f > 6 then
    nm()
  end
  if btnp(4) then
    w = 0
    if l.grounded or l.coyote > 0 then
      l.grounded = false
      l.vely = -3
      sfx(0)
      l.coyote = 0
    elseif l.hit_left and S then
      l.vely = -3
      l.velx = 3
      l.wall_jump_timer_left = 16
      l.wall_jump_timer_right = 0
      sfx(0)
    elseif l.hit_right and S then
      l.vely = -3
      l.velx = -3
      l.wall_jump_timer_right = 16
      l.wall_jump_timer_left = 0
      sfx(0)
    elseif l.jumps > 0 then
      l.vely = -2.5
      l.jumps = 0
      sfx(0)
    end
  end
  if l.jumps == 0 then
    l.outline = false
  end
  if l.grounded then
    l.outline = false
    l.jumps = 0
  end
  if btn(2) or btn(3) then
    local n, e = flr(l.x / 8), flr(l.y / 8)
    if mget(n, e) == 103 or mget(n + 1, e) == 103 or mget(n, e + 1) == 103 or mget(n + 1, e + 1) == 103 then
      l.on_ladder = true
      l.velx = 0
      l.vely = 0
    end
  end
end

function no()
  local n, e = l.x, l.y
  l.grounded = p(n + 4, e + 8, 0) or p(n + 2, e + 8, 0) or p(n + 4, e + 8, 3) or p(n + 2, e + 8, 3)
  l.hit_top = p(n + 4, e + 4, 0) or p(n + 1, e + 4, 0)
  l.hit_left = p(n, e + 4, 0)
  l.hit_right = p(n + 7, e + 4, 0)
end

function p(n, e, d)
  eq = mget(flr(n / 8), flr(e / 8))
  return fget(eq, d)
end

function eg()
  local n, e = l.x + 3, l.y + 5
  if l.y > 512 then
    n1()
    return
  end
  local d, n, o, e = n - .5, n + .5, e - .5, e + .5
  if fget(mget(flr(d / 8), flr(o / 8)), 1) or fget(mget(flr(n / 8), flr(o / 8)), 1) or fget(mget(flr(d / 8), flr(e / 8)), 1) or fget(mget(flr(n / 8), flr(e / 8)), 1) then
    n1()
  end
end

G = {}

function n1()
  sfx(9)
  if not Q then
    P = P + (1)
  end
  dset(5, P)
  l.dead = true
  l.velx = 0
  l.vely = 0
  G = {}
  for n = 0, 35 do
    local n = n / 8
    add(G, {x = l.x + 3, y = l.y + 4, vx = cos(n) * .5, vy = sin(n) * .5, t = 0})
  end
end

function np()
  if not l.dead then
    return
  end
  for n in all(G) do
    n.x = n.x + (n.vx)
    n.y = n.y + (n.vy)
    n.t = n.t + (1)
    if n.t < 12 then
      circfill(n.x, n.y, 1, H)
    elseif n.t < 18 then
      circfill(n.x, n.y, .5, H)
    else
      G = {}
      l.x = l.last_safe.x
      l.y = l.last_safe.y
      l.dead = false
      y = {}
    end
  end
end

y = {}
ez = 3
I = 0
nl = 6
H = 3

function eA()
  local n, e = l.x + 3 - l.velx * .01, l.y + nl - l.vely * .01
  add(y, {x = n, y = e})
  if l.hit_left then
    I = -1
  elseif l.hit_right then
    I = 1
  else
    I = 0
  end
  while #y > ez do
    del(y, y[1])
  end
  if btn(2) and btnp(5) then
    H = (H + 1) % 15
  end
end

function ej()
  if l.grounded then
    nl = 6
  else
    nl = 6
  end
  eA()
  for e = 1, #y - 1 do
    local n, d = y[e], y[e + 1]
    for o = 0, 1, .2 do
      local f, n, e = n.x + (d.x - n.x) * o, n.y + (d.y - n.y) * o, e
      if l.outline then
        circfill(f + I, n, e + 1, 7)
      end
      circfill(f + I, n, e, H)
    end
  end
end

x = {}

function ek()
  for n = 1, 10 do
    add(x, {x = l.x + 3, y = l.y + 8, spdx = rnd(1) - .5, spdy = rnd(.5) - .5, radius = rnd(3), life = rnd(20), colour = 6})
    if rnd() < .5 then
      x[n].colour = 5
    end
  end
end

function nT()
  for n in all(x) do
    n.x = n.x + (n.spdx)
    n.y = n.y + (n.spdy)
    n.life = n.life - (1)
    if n.life <= 3 then
      n.radius = .5
    end
    if n.life <= 0 then
      del(x, n)
    end
  end
end

function ea()
  for n in all(x) do
    circfill(n.x, n.y, n.radius, n.colour)
  end
end

v = {}

function nJ()
  for n in all(v) do
    del(v, n)
  end
  for n = 1, 100 do
    add(v, {x = flr(rnd(128)), y = flr(rnd(128)), spdx = rnd(.1) - .05, spdy = rnd(.1) - .05, colour = 1})
    local e = flr(rnd(4))
    if e == 1 then
      v[n].colour = 5
    elseif e == 2 then
      v[n].colour = 6
    end
  end
end

function nQ()
  for n in all(v) do
    n.x = n.x + (n.spdx)
    n.y = n.y + (n.spdy)
    n.x = (n.x + 135) % 135
    n.y = (n.y + 135) % 135
  end
end

function ed()
  for n in all(v) do
    pset(n.x + i * 128, n.y + a * 128, n.colour)
  end
end

T = {}

function e6()
  for n in all(T) do
    mset(n.x, n.y, 98)
  end
  T = {}
  for e = 0, 15 do
    for n = 0, 15 do
      local n, e = i * 16 + n, a * 16 + e
      if mget(n, e) == 98 then
        add(T, {x = n, y = e, f = 0, fading = false})
      end
    end
  end
end

function nZ()
  for n in all(T) do
    local e, d = n.x * 8, n.y * 8
    if k({x = l.x, y = l.y + 1}, {x = e, y = d}) or k({x = l.x - 1, y = l.y - 2}, {x = e, y = d}) then
      n.fading = true
    end
    if n.fading and n.f == 0 then
      sfx(6)
    end
    if n.fading then
      n.f = n.f + (.2)
    end
    if n.f >= 0 then
      if n.f < 4 then
        mset(n.x, n.y, 98 + flr(n.f))
      else
        mset(n.x, n.y, 0)
      end
    end
    if n.f > 20 then
      n.f = 0
      n.fading = false
    end
  end
end

m = {}

function es()
  for n in all(m) do
    mset(n.x, n.y, n.c == "red" and 92 or 108)
  end
  m = {}
  for e = 0, 15 do
    for n = 0, 15 do
      local n, e = i * 16 + n, a * 16 + e
      local d = mget(n, e)
      if d == 92 then
        add(m, {x = n, y = e, c = "red", timer = 0})
        mset(n, e, 0)
      elseif d == 108 then
        add(m, {x = n, y = e, c = "blue", timer = 0})
        mset(n, e, 0)
      end
    end
  end
end

function nY()
  if #m > 1 and (m[1].timer == 0 or m[1].timer == 30) then
    sfx(6)
  end
  for n in all(m) do
    if n.c == "red" and n.timer < 30 then
      mset(n.x, n.y, 92)
    elseif n.c == "blue" and n.timer > 30 then
      mset(n.x, n.y, 108)
    else
      mset(n.x, n.y, 0)
    end
    n.timer = (n.timer + 1) % 60
  end
end

function ex()
  w = 0
  if l.grounded then
    l.on_ladder = false
  end
  local n, e = flr(l.x / 8), flr(l.y / 8)
  if not (mget(n, e) == 103 or mget(n + 1, e) == 103 or mget(n, e + 1) == 103 or mget(n + 1, e + 1) == 103) then
    l.on_ladder = false
  end
  if btn(0) then
    if l.hit_top then
      l.y = l.y + (1)
    end
    l.velx = l.velx - (.5)
  end
  if btn(1) then
    if l.hit_top then
      l.y = l.y + (1)
    end
    l.velx = l.velx + (.5)
  end
  if btn(2) and not l.hit_top then
    l.y = l.y - (1)
  end
  if btn(3) and not l.grounded then
    l.y = l.y + (1)
  end
  if btnp(4) then
    sfx(0)
    l.on_ladder = false
    l.vely = -3
  end
end

u = {seg = {}}

function n6()
  u = {}
  local n, e = i * 16, a * 16
  for d = 0, 15 do
    for o = 0, 15 do
      local n, e = n + o, e + d
      local d = mget(n, e)
      if d == 8 then
        add(u, J(n * 8 + 1, e * 8, 5, 4))
        add(u, J(n * 8 + 3, e * 8, 5, 7))
        add(u, J(n * 8 + 6, e * 8, 5, 2))
      elseif d == 9 then
        add(u, J(n * 8 + 4, e * 8, 6, 4))
        add(u, J(n * 8 + 6, e * 8, 5, 3))
      end
    end
  end
end

function J(e, d, n, f)
  local o = {seg = {}, len = n, falling = false}
  for f = 1, f do
    add(o.seg, {x = e, y = d + (f - 1) * n, px = e, py = d + (f - 1) * n})
  end
  return o
end

function nU(n)
  if n.falling then
    for n in all(n.seg) do
      local e, d = (n.x - n.px) * .95, (n.y - n.py) * .95
      n.px = n.x
      n.py = n.y
      n.x = n.x + (e)
      n.y = n.y + (d + .2)
    end
    return
  end
  for e = 2, #n.seg do
    local n = n.seg[e]
    local e, d = (n.x - n.px) * .95, (n.y - n.py) * .95
    n.px = n.x
    n.py = n.y
    n.x = n.x + (e)
    n.y = n.y + (d + .1)
  end
  for e = 1, 3 do
    for t = 2, #n.seg do
      local e, d = n.seg[t - 1], n.seg[t]
      local o, f = d.x - e.x, d.y - e.y
      local l = sqrt(o * o + f * f)
      local n = (l - n.len) / l
      if t > 2 then
        e.x = e.x + (o * n * .5)
        e.y = e.y + (f * n * .5)
      end
      d.x = d.x - (o * n * .5)
      d.y = d.y - (f * n * .5)
    end
  end
  eB(n, l.x + 4, l.y + 4)
end

function eB(n, e, d)
  for o = 2, #n.seg do
    local n = n.seg[o]
    local e, d = n.x - e, n.y - d
    local o = e * e + d * d
    if o < 8 then
      n.x = n.x + (e * .3)
      n.y = n.y + (d * .3)
    end
  end
end

function e1(n)
  for e = 2, #n.seg do
    local d, n = n.seg[e - 1], n.seg[e]
    line(d.x, d.y, n.x, n.y, 3)
  end
end

function nk(l, i, d)
  local o = {}
  for n in all(u) do
    for e = #n.seg, 2, -1 do
      local f, t = n.seg[e - 1], n.seg[e]
      local a, f = (f.x + t.x) / 2, (f.y + t.y) / 2
      if (a - l) ^ 2 + (f - i) ^ 2 < d * d then
        add(o, {v = n, i = e})
        break
      end
    end
  end
  for n in all(o) do
    eC(n.v, n.i)
  end
end

function eC(n, e)
  if #n.seg - e + 1 < 2 then
    return
  end
  local d = {seg = {}, len = n.len, falling = true}
  for e = e, #n.seg do
    add(d.seg, n.seg[e])
  end
  for e = #n.seg, e, -1 do
    deli(n.seg, e)
  end
  add(u, d)
end

s = {}
A = 1

function ni(n, e, d)
  add(s, {x = n * 8, y = e * 8, f = 0, collected = false, collectedf = 0, kind = d or A})
  A = A % 5 + 1
end

function nF()
  s = {}
  for n = 0, 63 do
    for e = 0, 127 do
      local d = mget(e, n)
      if d == 64 then
        ni(e, n)
        mset(e, n, 0)
      end
    end
  end
  for n in all(c) do
    n.kind = A
    A = A % 5 + 1
  end
end

function nV()
  if F >= 50 and not n0 then
    if i == 3 and a == 1 then
      n0 = true
      ny()
    else
      n0 = true
      ng()
    end
  end
  for n in all(s) do
    n.f = (n.f + .2) % 4
    if k(l, n) then
      if not n.collected then
        sfx(1)
        n.collected = true
        U[n.kind] = U[n.kind] + (1)
        F = F + (1)
        eD()
        for e = 1, #c do
          local e = c[e]
          if n.x / 8 == e[3] and n.y / 8 == e[4] then
            e.coin_found = true
            break
          end
        end
        eE()
      end
    end
    if n.collected and n.collectedf < 5 then
      n.collectedf = n.collectedf + (.4)
    end
  end
end

eF = {{14, 2}, {12, 1}, {9, 4}, {11, 3}}

function el()
  for n in all(s) do
    if n.collected then
      if n.collectedf < 5 then
        spr(68 + flr(n.collectedf), n.x, n.y)
      end
    else
      local e = eF[n.kind]
      if e then
        pal(7, e[1])
        pal(6, e[2])
      end
      spr(64 + flr(n.f), n.x, n.y)
      pal(7, 7)
      pal(6, 6)
    end
  end
end

function na(n)
  local d = {}
  for n in all(split(n, ";")) do
    local n, e = split(n, ","), {}
    if #n == 2 then
      e = {x = tonum(n[1]), y = tonum(n[2])}
    else
      for d = 1, #n do
        e[d] = tonum(n[d])
      end
    end
    add(d, e)
  end
  return d
end

eG = "17,62,18,62;15,18,11,26;26,18,22,17;39,30,37,30;80,29,81,22;58,2,61,3;50,10,51,10;111,23,108,20;119,14,119,27;119,6,121,2;34,9,38,9;15,12,7,14;29,6,28,9;93,58,91,58;72,23,72,26;29,48,31,52;120,36,118,35;106,52,109,53;98,1,100,1;99,17,96,16;41,62,43,59"

function nD()
  c = na(eG)
  for n in all(c) do
    n.found = false
    n.coin_found = false
  end
end

function nW()
  for n in all(c) do
    if k(l, {x = n[1] * 8, y = n[2] * 8}) and not n.found then
      sfx(5)
      mset(n[1], n[2], 0)
      j = 33
      ni(n[3], n[4], n.kind)
      n.found = true
      eH()
    end
  end
end

S = false
nt = false
nf = false
nw = {{x = 72, y = 27, sprx = 10, spry = 5, reward = function()
  S = true
  dset(0, 1)
end, found = false, message = {"you found climbing boots!", "now you can wall jump!"}}, {x = 97, y = 30, sprx = 7, spry = 5, reward = function()
  nc = true
  nv()
  dset(1, 1)
end, found = false, message = {"you found the map!", "stand still to have a look", "at it!"}}, {x = 124, y = 18, sprx = 11, spry = 4, reward = function()
  nt = true
  dset(2, 1)
end, found = false, message = {"you found the machete!", "press 5 to slash!"}}, {x = 8, y = 33, sprx = 10, spry = 4, reward = function()
  nf = true
  dset(3, 1)
end, found = false, message = {"you found the shovel!", "press 3 to dig!"}}, {x = 84, y = 5, sprx = 8, spry = 5, reward = function()
  nr = true
  dset(4, 1)
end, found = false, message = {"you found the compass!", "it shows treasure on the map!"}}}
K = {active = false, message = "press 2 to open chest"}

function nX()
  local e = false
  for n in all(nw) do
    if n.found then
      mset(n.x, n.y, 89)
    else
      mset(n.x, n.y, 73)
    end
    if not n.found then
      if k(l, {x = n.x * 8, y = n.y * 8}) then
        K.active = true
        e = true
      end
      if k(l, {x = n.x * 8, y = n.y * 8}) and btnp(2) then
        sfx(5)
        n.reward()
        n.found = true
        nn = true
        V = n.message
        o.showing = true
        o.x = n.sprx
        o.y = n.spry
        o.dx = n.x * 8
        o.dy = n.y * 8
        o.timer = 0
        o.timer2 = 0
      end
    end
  end
  if not e then
    K.active = false
  end
end

function eh()
  if K.active then
    local e, d, o = #K.message * 4, i * 128 + 6, i * 128 + 128 - 6
    local n = l.x - e / 2
    n = mid(d, n, o - e)
    n2(K.message, n, l.y + 10, 7, 3)
  end
end

j = 0
o = {}

function ei()
  if o.showing then
    local n = flr(o.timer)
    for e = 0, n do
      local d, n = e, o.dy + 8 - 1 - (n - e) - 6
      if d < 8 then
        sspr(o.x * 8, o.y * 8 + d, 8, 1, o.dx, n)
      end
    end
    if o.timer < 8 then
      o.timer = o.timer + (.2)
    end
    o.timer2 = o.timer2 + (.2)
    if o.timer2 > 30 then
      o.showing = false
    end
  end
end

function nE()
  U = {0, 0, 0, 0, 0}
  F = 0
  n0 = false
  eI = na "51,20;57,22;51,29;55,27;60,29"
  n_ = na "3,4;3,8;3,12;7,1;7,5;7,9;7,13;11,4;11,8;11,12"
end

eJ = {16, 18, 20, 22, 16}
eK = {40, 40, 40, 40, 42}

function e0()
  for n = 1, 5 do
    local e = eI[n]
    for d = 1, U[n] do
      sspr(eJ[n], eK[n], 2, 2, e.x * 8 + n_[d].x, e.y * 8 + n_[d].y)
    end
  end
end

b = {f = 5.9}
B = 3
r = false

function nm()
  b.f = 0
  sfx(3)
end

function eL()
  local d, o = flr(l.x / 8 + B / 4), flr(l.y / 8)
  if r then
    d = flr(l.x / 8)
    o = flr(l.y / 8) + 1
  end
  for f = 1, 2 do
    local n, e = d, o - 1 + f
    if r then
      n = d - 1 + f
      e = o
    end
    local d = mget(n, e)
    if not r and (d == 25 or d == 42) or r and d == 10 then
      mset(n, e, 0)
      sfx(4)
      if r then
        for d = 1, #C do
          local d = C[d]
          if d.x == n and d.y == e then
            d.cleared = true
            eM()
            break
          end
        end
      end
      for d = 1, 20 do
        local d = 3
        if rnd() < .5 then
          d = 11
        end
        if r then
          d = 4
          if rnd() < .5 then
            d = 2
          end
        end
        add(x, {x = n * 8 + 4, y = e * 8 + 4, spdx = rnd(1) - .5, spdy = rnd(1) - .5, radius = rnd(3), life = rnd(20), colour = d})
      end
    end
  end
end

function nP()
  if l.facing == "right" then
    B = 3
  elseif l.facing == "left" then
    B = -3
  elseif r then
    B = 0
  end
  if not r and b.f < 4 then
    nk(l.x + B, l.y, 10)
    nk(l.x + 5, l.y, 10)
  end
  if b.f < 3 then
    eL()
  end
  if b.f < 6 then
    b.f = b.f + (.4)
  else
    r = false
  end
end

function ec()
  if b.f < 4 then
    if r then
      spr(76 + b.f, l.x, l.y + 4)
    else
      spr(83 + b.f, l.x + B, l.y + 2, 1, 1, l.facing == "left")
    end
  end
end

nn = false
V = {"test"}

function e2()
  if nn then
    local e, d, o, n, f, n, n = i * 128 + 10, a * 128 + 30, i * 128 + 117, a * 128 + 97, #V * 6, l.y % 128
    if i == 7 and a == 1 or i == 5 and a == 0 then
      n = d + 100
    else
      n = d + 30
    end
    local f, t = n - f / 2, sin(time() * .2)
    for n = 1, #V do
      local d = V[n]
      local l = #d * 4
      local e, n = e + (o - e) / 2 - l / 2, f + (n - 1) * 6 - 30 + t
      n2(d, e, n, 7, 3)
    end
  end
end

function n2(n, e, d, o, t)
  for o = -1, 1 do
    for f = -1, 1 do
      if o ~= 0 or f ~= 0 then
        print(n, e + o, d + f, t)
      end
    end
  end
  print(n, e, d, o)
end

function nj(n, e, d)
  return {x = n, y = e, spdx = rnd(1) - .5, spdy = rnd(1) - 1, r = rnd(2), life = d or 0, colour = 8 + flr(rnd(3))}
end

function nx(e, d)
  for n in all(e) do
    n.x = n.x + (n.spdx / 2)
    n.y = n.y + (n.spdy)
    n.life = n.life + (.2)
    if n.life > 3.4 then
      n.r = .5
    end
    if n.life > 4 then
      del(e, n)
    end
    circfill(n.x, n.y + d, n.r, n.colour)
  end
end

function e3()
  nq = {}
  local n, e = i * 16, a * 16
  for d = 0, 15 do
    for o = 0, 15 do
      local f = mget(n + o, e + d)
      if f == 47 then
        add(nq, {x = (n + o) * 8, y = (e + d) * 8, f = rnd(1), active = true, timer = 0, particles = {}, fade = false})
      end
    end
  end
end

function et()
  for n in all(nq) do
    spr(51, n.x, n.y)
    if not n.active then
      n.timer = n.timer + (1)
      if n.timer > 60 then
        n.active = true
      end
      if not n.fade then
        n.fade = true
        n.particles = {}
        for e = 1, 10 do
          add(n.particles, nj(n.x + 4 + rnd(2) - 1, n.y + 4 + rnd(2) - 1))
        end
      end
      nx(n.particles, 0)
    else
      n.timer = n.timer + (.01)
      local e = sin(n.timer + n.f) * 2
      spr(47, n.x, n.y + e)
      if k(l, n) then
        l.jumps = 1
        n.active = false
        n.timer = 0
        l.outline = true
        sfx(4)
      end
      while #n.particles < 15 do
        add(n.particles, nj(n.x + 4 + rnd(2) - 1, n.y + 4 + rnd(2) - 1, rnd(3)))
      end
      nx(n.particles, e)
    end
  end
end

nc = false
nr = false
w = 0
W = 0
Y = true

function nG()
  g = {}
  for n = 0, 3 do
    for e = 0, 7 do
      add(g, {x = e, y = n, treasure = true, visited = false})
    end
  end
end

function nv()
  menuitem(2, "map " .. (Y and "enabled" or "disabled"), function()
    Y = not Y
    nv()
    return true
  end)
end

function e4()
  for e in all(g) do
    if e.treasure then
      local n, d, o = false, e.x * 16, e.y * 16
      if not n then
        for e in all(c) do
          if e[3] >= d and e[3] < d + 16 and e[4] >= o and e[4] < o + 16 and not e.coin_found then
            n = true
            break
          end
        end
      end
      if not n then
        for e in all(s) do
          if e.x / 8 >= d and e.x / 8 < d + 16 and e.y / 8 >= o and e.y / 8 < o + 16 and not e.collected then
            n = true
            break
          end
        end
      end
      if not n then
        e.treasure = false
      end
    end
  end
end

function en()
  if w < 65 then
    w = w + (1)
  end
  W = (W + 1) % 30
end

function er()
  if not nc or not Y then
    return
  end
  if w < 60 then
    return
  end
  local n, e = 4 + i * 128, 2 + a * 128
  rectfill(n, e, n + 34, e + 18, 5)
  rectfill(n + 1, e + 1, n + 33, e + 17, 0)
  for d in all(g) do
    if d.visited then
      rectfill(2 + n + d.x * 4, 2 + e + d.y * 4, 4 + n + d.x * 4, 4 + e + d.y * 4, 5)
      if W < 15 and nr and d.treasure then
        rectfill(2 + n + d.x * 4, 2 + e + d.y * 4, 4 + n + d.x * 4, 4 + e + d.y * 4, 6)
      end
    end
  end
  if W < 15 then
    rectfill(2 + n + i * 4, 2 + e + a * 4, 4 + n + i * 4, 4 + e + a * 4, 11)
  end
end

nh = {}
eN = {["0,2"] = true, ["0,3"] = true, ["1,2"] = true, ["1,3"] = true, ["2,2"] = true, ["2,3"] = true, ["6,2"] = true}

function eO()
  return eN[i .. "," .. a]
end

function nK()
  nh = {}
  for n = 1, 100 do
    add(nh, {x = rnd(128), y = rnd(128), spdx = rnd(2) - 1, spdy = rnd(1), vx = 0, vy = 0, r = rnd(2)})
  end
end

function eu()
  if not eO() then
    return
  end
  local d, o, e, f = i * 128, a * 128, (l.prev_x or l.x) + 3, (l.prev_y or l.y) + 5
  for n in all(nh) do
    local e, f = n.x - e, n.y - f
    local f = sqrt(e * e + f * f)
    if f < 10 then
      local d = (10 - f) / 10
      if l.velx ~= 0 and e * l.velx < 0 then
        n.vx = n.vx + (l.velx * d * .6)
        n.vy = n.vy + (l.vely * d * .2)
      end
      n.vy = n.vy - (d * .2)
    end
    n.vx = n.vx * (.92)
    n.vy = n.vy * (.92)
    if e * l.velx > 0 then
      n.vx = n.vx * (.8)
    end
    n.vx = mid(-1.2, n.vx, 1.2)
    n.x = n.x + (n.spdx + n.vx)
    n.y = n.y + (n.spdy + n.vy)
    n.x = d + (n.x - d) % 128
    n.y = o + (n.y - o) % 128
    circfill(n.x, n.y, n.r, 7)
  end
end

nu = {}

function nL()
  nu = {}
  for n = 1, 300 do
    add(nu, {angle = rnd(1), dist = 22 + rnd(10), speed = .025 + rnd(.05), col = 6 + rnd(2), r = .5 + rnd(1)})
  end
end

function nz(f, d, l)
  for n in all(nu) do
    local e = n.angle + t() * n.speed
    local o, e = cos(e) * n.dist, sin(e) * n.dist * .35
    local f, e = f + o, d + e + o * .35
    if l then
      if e > d then
        circfill(f, e, n.r, n.col)
      end
    else
      if e <= d then
        circfill(f, e, n.r, n.col)
      end
    end
  end
end

function eo()
  local n = 448 + sin(t() / 30) * 2 + sin(t() / 25) * .5
  nz(576, n, false)
  circfill(576, n, 15, 1)
  circfill(574, n - 2, 14, 0)
  nz(576, n, true)
end

Q = false
n = {x = -50, y = 65, sprite = 94, flip_x = false}

function eP()
  spr(n.sprite, n.x, n.y, 2, 3, n.flip_x)
end

function e9()
  Q = true
  l.x = 200
  l.y = 80
  l.sprite = 2
  camera(0, 0)
  for n = 0, 15 do
    for e = 0, 15 do
      mset(e, n, 0)
    end
  end
  for n = 0, 15 do
    mset(n, 11, 58)
  end
end

f = 0
d = 0

function nM()
  cls()
  d = d + (1)
  if n.x % 8 > 4 then
    n.y = 63
  else
    n.y = 64
  end
  if f == 0 then
    if l.x > 97 then
      l.x = l.x - (1.5)
    elseif n.x < 27 then
      n.x = n.x + (1)
    end
    if n.x == -30 then
      sfx(7)
    end
    if n.x == 26 and f == 0 then
      h()
    end
  end
  if f == 1 then
    if d == 70 then
      sfx(8)
      e = {x = 38, y = 78, particles = {}}
      eQ()
    end
    if d > 70 then
      e.x = e.x + (4)
      e.y = e.y + (.25)
    end
    if e.x > 97 then
      e.x = -10
      e.y = -10
      h()
      n1()
    end
  end
  if f == 2 then
    np()
    if G[1].t == 17 then
      h()
    end
  end
  if f == 3 then
    if d == 30 then
      music(0)
      h()
    end
  end
  if f == 4 then
    print("+3 xp", X.x, X.y, 3)
    if X.y > 68 then
      X.y = X.y - (.2)
    end
    if d > 120 then
      h()
    end
  end
  if f == 5 then
    if d == 0 then
      sfx(7)
      n.flip_x = true
    end
    n.x = n.x - (1)
    if d == 180 then
      h()
    end
  end
  if f == 6 then
    if d == 0 then
      music(1)
    end
    if d == 224 then
      h()
    end
  end
  local n = "lootslime"
  if f == 7 then
    print(n, 64 - #n * 2, 56, 7)
    if d == 112 then
      h()
    end
  end
  if f == 8 then
    print(n, 64 - #n * 2, 56, 7)
    local n = "by patrick callaghan"
    print(n, 64 - #n * 2, 64, 5)
    if d == 112 then
      h()
    end
  end
  if f == 9 then
    local n = "thank you for playing!"
    print(n, 64 - #n * 2, 56, 7)
    if d == 224 then
      h()
    end
  end
  if f == 10 then
    local n = "deaths: " .. P
    print(n, 64 - #n * 2, 56, 7)
    if d == 224 then
      h()
    end
  end
  if f == 11 then
    function n8(n)
      return n < 10 and "0" .. n or n
    end

    local n = "time: " .. n8(R) .. ":" .. n8(z) .. ":" .. n8(q)
    print(n, 64 - #n * 2, 56, 7)
    if d >= 224 then
      local n = "now see if you can do it faster!"
      print(n, 64 - #n * 2, 64, 7)
    end
  end
end

e = {x = -10, y = -10}
X = {x = 88, y = 76}

function eQ()
  for n = 0, 50 do
    add(e.particles, {x = e.x, y = e.y, spdx = rnd(1) - .5, spdy = rnd(2) - 2, r = rnd(2), t = rnd(10)})
  end
end

function h()
  f = f + (1)
  d = 0
end

function ee()
  nb()
  eP()
  map()
  spr(91, e.x, e.y)
  for n in all(e.particles) do
    n.x = n.x + (n.spdx)
    n.y = n.y + (n.spdy)
    circfill(n.x, n.y, n.r, 8 + rnd(2))
    n.t = n.t + (1)
    if e.x > 0 then
      if n.t > 6 then
        n.x = e.x + rnd(7)
        n.y = e.y + rnd(6)
        n.t = 0
      end
    else
      if n.t > 50 then
        del(e.particles, n)
      end
    end
  end
end

Z = {}
D = 0
ne = false

function eR()
  for n = 0, 100 do
    add(Z, {x = 384 + rnd(8), y = 168 + rnd(64), r = rnd(3), c = 5 + rnd(2), spdy = rnd(), spdx = rnd()})
  end
end

function eS()
  for n = 21, 26 do
    for e = 48, 49 do
      mset(e, n, 0)
    end
  end
  mset(48, 20, 53)
  mset(48, 27, 21)
end

function e8()
  if #Z == 0 then
    return
  end
  if D == 2 then
    D = D - (1)
    eS()
  elseif D > 0 then
    D = D - (1)
  end
  for n in all(Z) do
    if D < 2 then
      n.r = n.r - (rnd(.2))
      if n.r < 0 then
        del(Z, n)
      end
    else
      n.r = (n.r + rnd(.5)) % 3
    end
    circfill(n.x, n.y, n.r, n.c)
  end
end

function ny()
  eR()
  D = 115
  ng()
  ne = true
end

function ng()
  eT(4, 115)
  sfx(2)
end

L = 0
E = 0

function eT(n, e)
  E = n
  L = e
end

function nO()
  if L > 0 then
    L = L - (1)
    if L <= 0 then
      E = 0
    end
  end
end

function ef()
  if L > 0 then
    return rnd(E * 2) - E, rnd(E * 2) - E
  end
  return 0, 0
end

M = "secret!"
nA = 0
_ = 0

function e5(e, d)
  if j <= 0 and _ <= 0 then
    return
  end
  nA = nA + (.1)
  local n = #M * 4
  e = mid(i * 128 + 4, e, i * 128 + 128 - n - 4)
  d = mid(a * 128 + 4, d, a * 128 + 128 - 6 - 4)
  if j > 0 then
    _ = min(_ + .5, #M)
  else
    _ = max(_ - .5, 0)
  end
  local n, o = 1, flr(_)
  if j <= 0 then
    n = #M - flr(_) + 1
    o = #M
  end
  for n = n, o do
    local o, e, n = sub(M, n, n), e + (n - 1) * 4, d + sin(nA / 1.5 + n * .8) * 2
    n2(o, e, n, 7, 13)
  end
end

function ns()
  S = dget(0) ~= 0
  nc = dget(1) ~= 0
  nt = dget(2) ~= 0
  nf = dget(3) ~= 0
  nr = dget(4) ~= 0
  P = dget(5)
  q = dget(6)
  z = dget(7)
  R = dget(8)
  eU()
  eV()
  eW()
  eX()
  eY()
  eZ()
  l.last_safe.x = dget(20) * 8
  l.last_safe.y = dget(21) * 8
  if not (dget(20) == 0 and dget(21) == 0) then
    l.x = l.last_safe.x
    l.y = l.last_safe.y
  end
end

function nH()
  C = {}
  for n = 0, 63 do
    for e = 0, 127 do
      if mget(e, n) == 10 then
        add(C, {x = e, y = n, cleared = false})
      end
    end
  end
end

function eM()
  N(C, "cleared", 22, 23)
end

function eY()
  O(C, "cleared", 22, 23)
  for n in all(C) do
    if n.cleared then
      mset(n.x, n.y, 0)
    end
  end
end

function eU()
  for n = 1, 5 do
    nw[n].found = dget(n - 1) ~= 0
  end
end

function N(e, f, n, t)
  local d, o = 0, 0
  for n = 1, #e do
    if e[n][f] then
      if n <= 16 then
        d = d | (1 << n - 1)
      else
        o = o | (1 << n - 17)
      end
    end
  end
  dset(n, d)
  dset(t, o)
end

function O(e, d, n, o)
  local o, f = dget(n), dget(o)
  for n = 1, #e do
    if n <= 16 then
      e[n][d] = o & 1 << n - 1 ~= 0
    else
      e[n][d] = f & 1 << n - 17 ~= 0
    end
  end
end

function eH()
  N(c, "found", 10, 13)
end

function eV()
  O(c, "found", 10, 13)
  for n in all(c) do
    if n.found then
      mset(n[1], n[2], 0)
    end
  end
end

function eE()
  N(c, "coin_found", 11, 14)
end

function eX()
  O(c, "coin_found", 11, 14)
  for n in all(c) do
    if n.found and not n.coin_found then
      ni(n[3], n[4], n.kind)
    end
    if n.coin_found then
      U[n.kind] = U[n.kind] + (1)
      F = F + (1)
    end
  end
end

function eD()
  N(s, "collected", 12, 15)
end

function eW()
  O(s, "collected", 12, 15)
  for n = 1, #s do
    if s[n].collected then
      U[s[n].kind] = U[s[n].kind] + (1)
      F = F + (1)
    end
  end
end

function eb()
  N(g, "visited", 16, 17)
end

function eZ()
  O(g, "visited", 16, 17)
end

function n4()
  menuitem(1, "reset save", function()
    menuitem(1, "are you sure?", function()
      for n = 0, 63 do
        dset(n, 0)
      end
      ns()
      n4()
      reset()
      dn()
      n3()
      return true
    end)
    return true
  end)
end

n5 = {}

function nB()
  for n = 0, 127 do
    n5[n] = {}
    for e = 0, 127 do
      n5[n][e] = mget(n, e)
    end
  end
end

function dn()
  for n = 0, 127 do
    for e = 0, 127 do
      mset(n, e, n5[n][e])
    end
  end
end


__gfx__
00000000fffffffffffffffff33f3f3ff33f3f33f336f3f60000000000000000f3f33f3f8f3f3c33fffffffff7777777777777777777777fffffffffffffffff
00000000fffffffffffffffff8ff3f8fff3f1f3fff3ff9ff0220000000000220ffff9fffff8ffffcff42004f776776777767766677677677ffffffffffffffff
00700700ffffffffffffffffffff8fffff6fff3fff6fffff0400040000000040ffffffffffffffff00000242766666666666666666666667ffffffffffffffff
00077000ffffffffffffffffffffffffffffffcfffffffff0440440000000440ffffffffffffffff44000020776666066066660060666667ffffffffffffffff
00077000ffffffffffffffffffffffffffffffffffffffff0000000000220000ffffffffffffffff24404000770000000000000000000077ffffffffffffffff
00700700ff7ff7fff7ff7fffffffffffffffffffffffffff3004222002400003ffffffffffffffff042044427f5555005055055500550077ffcffffcfff9ffff
00000000ff0ff0fff0ff0fffffffffffffffffffffffffff3300444204440033ffffffffffffffff00002420ff5055555555055055550ff7fc5cfff6f9f6ff9f
00000000ffffffffffffffffffffffffffffffffffffffffb33000000000033bffffffffffffffff00000000fffff05005500000050ffffff6cffcf6f6f6f96f
ffffffffffffffffffffffffdd003bbbfbbbbbbbbbbbbbbfb33000000000033b00333bbfffff3b3f04440000f77777777777777f05500000ffffffffffffffff
ffffffffffffffffffffffff0006333bbbb3bbbb3bbb3bbb33004442044400334003bbfffff33b3b24000440777667777776677755550550ffffffffffffffff
ffffffffffffffffffffffff6606333bbb3333b333b333bb300422200240000342033bffffb3ffbf02200224766666677666666750550555ffffffffffffffff
ffffffffffffffffffffffff660dd3bbbb3303330333333b000000000022000000033bffff3ff3bf30033033776666666666667700000000ffffffffffffffff
ffffffffffffffcfffffffffdd00333bb3300000030003bb044044000000044004033bffffff33ffb333b333776600000000667760666600ffffffffffffffff
ffff8fffff6fff3fff6fffff000663bbbb3304440000033b04000400000000404403bbfffb3333b3bbbbbbbb766605555550666766666666f8ffffffffffffff
f8ff3f8fff3f1f3fff3ff9ff6606633bbbb300422440033b022000000000022040033bbfffff33ffbbfffffb776000555500067777677666878fff8ffbffbfbf
f33f3f3ff33f3f33f336f3f6660d33bbbb333000024033bb0000000000000000203333bff3bff33fbfffffff776600000000667777777777f86f6f6ff6ff6b6f
fbbbbbbbbbbbbbbbbbbbbbbf04440000bbb33040000333bbefffffffcffffffffffffffcfffffffef3b3ffff76600500005006677660555005550667ffffffff
bbb33b3b3bb33b3b3bb3b3bb24000440bb3300420400333bffffffffffffffffffffffffffffffffb3b33fff76600550055006676600555005550066ff9999ff
b3b3333333b3333333b3333b02200224b33330200420033bf8ffffff1ffffffffffffff1ffffff8ffbff3bff76660550055066676000005005000006f99aa99f
b333333003333330033333bb00000002bb330000000003bbf3fffffffcffffffffffffcfffffff3ffb3ff3ff77660000000066770050500000050500f9aaaa9f
b33f4034034040340340433b30033000b33004400040333b33fffffff31ffffffffff13fffffff33ff33ffff77660550055066775550550000550555f8a77a8f
b3ffff44044000440440f33b3333b3bbbb330200044003bbffffffffc3ffffffffffff3cffffffff3b3333bf76660555555066670500000000000050f887788f
33ffffff00240022002fff33bb3bb33bbbb300040420033b8fffffff33ffffffffffff33fffffff8ff33ffff77600055550006770000000000000000ff8888ff
ffffffff00020000ffffffffbbbbbbbbbb333042022033bbfffffffffffffffffffffffffffffffff33ffb3f77660550055066770000000000000000ffffffff
fffffffff000033bffffffff00000000bbb33044000333bbf9ffffffffffffffffffffffffffff9f0000000077660000000066770000000000000000fbb33300
fffffffff04333bb002fffff00000000bb3300420400333b339fffff6ffffffffffffff6fffff9330000000077600055550006770000000000000000ffbb3004
ffffff44f2443bbb0440ffff00000000b33330200420033b93ffffff3ffffffffffffff3ffffff390000000076660555555066670500000000000050ffb33024
ffff4034ff00333b03404fff00000000bb330000000003bbffffffffffffffffffffffffffffffff0000000077660000000066775550550000550555ffb33000
ff333330fff4333b033333ff00000000b33003033003333b9ffffffff6ffffffffffff6ffffffff90000000077666666666666770050500000050500ffb33040
f3b33333ffff33bb33b3333f00000000bb3333333333b3bbffffffff63ffffffffffff36ffffffff0000000076666667766666676000005005000006ffbb3044
3bb33b3bfffff33b3bb33b3b00000000bbbb33bbbb3bb33b9fffffff3ffffffffffffff3fffffff90000000077766777777667776600555005550066fbb33004
bbbbbbbbffffffbbbbbbbbbb00000000fbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffff00000000f77777777777777f7660555005550667fb333302
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ffffff77ffffff7ffffffffff4444ffffff6dffffffffffffffffffffffffffffffffff
ff6666fffff66ffffff66ffffff66ffffffffffffffffffff7ffff7ff7ffff7fffffffffffffffffff4ff2ffffff6ddfffffffffffffffffffffffffffffffff
f677776fff6776fffff66fffff6776ffffffffffff7ff7ffff7ff7fffffffffffffffffff444444fff4442ffffff66dfffffffffffffffffffffffffffffffff
f677676fff6676fffff66fffff6766fffff77ffffff77fffffffffffffffffffffffffff4447a444fff42ffffff666dfffffffffffffffffffffffffffffffff
f676676fff6676fffff66fffff6766fffff77ffffff77fffffffffffffffffffffffffff22299222fff22ffffff66ddfffffffffffffffffffffffffffffffff
f677776fff6776fffff66fffff6776ffffffffffff7ff7ffff7ff7ffffffffffffffffff44422444ff6666ffff466dffffffff77ffffff7777ffff7667ffffff
ff6666fffff66ffffff66ffffff66ffffffffffffffffffff7ffff7ff7ffff7fffffffff24944482ffd66dfff444dffffffffff7ffff777777777776677fffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ffffff77ffffff732332232fffddfffff22fffffffffffffff7777ff777776fffffffff
fff6655005555fff7e7c797bfffff77ffffff77ffffff66fffffffff5666666fff99999fffffffff555fffffff9ff9fff222222f05500000ff00ffffffffffff
ff655506d05555ffeecc99bbfffff7fffffff777fffff776fffffffff6868666f9998999f222222f5dd5fffff99f999f2288882255550550f04400ffffffffff
f655550d5055555f77ffffffffffffffffffff77ffffff77fffffffff66666864999899922222222566d5fff89999a98288ee88250550555f024440fffffffff
f65005500550055f77ffffffffffffffffffff77ffffff77fffffffff666666649998999222222225666d55f89aaaa9828eeee8200000000ff024440ffffffff
6506d0500506d055fffffffffffffffffffffff7ffffff77fffffffff666668649999799222992225666666589a77a9828eeee8260666600ff02224400ffffff
550d5006d00d5055ffffffffffffffffffffffffffffff77ffffff7ff686866649999979444224445555555588977988288ee88266777766fff022244400000f
5550050d50500555fffffffffffffffffffffffffffff777fffff77ff66866664499999f24944482fdfdfdfdf888888f2288882277ffff76fff0222444444440
5550055005500555fffffffffffffffffffffffffffff77ffffff66f5686866ff444444f32332232fffffffffffffffff222222f7ffffff7fff022442222220f
5506d0500506d055f555555ff555555ff555555ff555555fffffffff4444444406660666ffffffff7660050000500667f111111fffffffffffff0222200000ff
550d5006d00d505555666655556666555566665555ffff55fffffffff4ffff4f05650565fffffffff76005500550067f11cccc11fff8877ffff022200000ffff
5550050d505005555667766556677665566ff6655ffffff5ffffffff4444444405550555fffffff9ff760550055067ff1cc66cc1ff88887fff022000000a0fff
555005500550055556777765567ff76556ffff655ffffff5ff7777fff4ffff4f00000000fffffff6ff760000000067ff1c6666c1f7887888f0222000a00a00ff
5506d0500506d05556777765567ff76556ffff655ffffff5f707707f4444444466606660ffffffffff760550055067ff1c6666c1f77888870220c000a0000c0f
550d5006d00d50555667766556677665566ff6655ffffff5f777977ff4ffff4f56505650fffffff9ff760555555067ff1cc66cc18f22772ff00c0000000000c0
5550050d5050053555666655556666555566665555ffff55f770077f4444444455505550ffffff96f76000555500067f11cccc1188ff77ffff0cccccc000ccc0
3355335005533539f555555ff555555ff555555ff555555fff7777fff4ffff4f00000000ffffffff7766055005506677f111111f73f77f3ffff0cc0cccccc00f
fffffffffffff66dd66fffffddddddddf7cf17cf71777177f787878ffcffffffffffffffffffffffffffffff444444444444444444444444ff0cccc00ccc0aa0
fff76ffffff6676dd6766fff66666667fc1f17cf7177c17177778877c7cfffff8fffffffffffffbffffffffff4f4f4ffff4f4f4f4f4f4f4fff0cccc000cc0aa0
ff7776ffff67776dd67776ff67777777f1ff1c1f1f17c11f777777876cffffff68fffffffffffb7bff78ffff4444444ff444444444444444ff0cccc0aaccc00f
f777776ff677776dd677776ff677777fffff1c1fff1cc1ff77777877ffffffffffffffffffffffb6f7788fff222222444422222222222222ff0cccc0aacc0c0f
f777776ff777776dd677777ff677777fffff11ffff1c1fff77777787fcffffffffffffffffffffff888887ffffffff2442fffffffffffffffff0ccc000cc0c0f
77777776ff77776dd67777ffff6777ffffff1fffff1c1fff77777777c6ffffff8ffffffffffffffbf2772f87fffffff22ffffffffffffffffff00c0cccc0cc0f
76666666fff7776dd6777ffffff67ffffffffffffff1ffff6777777666ffffff6fffffffffffffb6ff77f888ffffffffffffffffffffffffff0cc0ccc00cccc0
ddddddddfffff77dd77ffffffffffffffffffffffffffffff666666fffffffffffffffffffffffff377f3f77fffffffffffffffffffffffffff000000000000f
e3d1d1d1d1d333e3d1d1d1d1d1d1d3333333c27796b2c2f1e0f0f1e1e1f0f1e0e1e0000000f0e0b2c20092868686868686868686868686868686724270323232
3232323232323232323232323232323270323260a37032539342337032323260e3d1d1d1d1d1d1d1d1d1d1d1d1d1d1d3e3c3834360a3a3a3a3a3527293423333
c287575704b233c2940000475797b3d33333c27797b2e2c0c0c0c0c0c0c0c0c0c0c1870497b1c0d2c20121869030214030869001308690113086824252504050
5040308086405040504086304030308652308242335290809242335240903042c27704040000475747000000570097b2c2470093423333333333526283436033
c2770096b1d233e2c100c60000c617b2e3d1c38797b23333333333e3d1d1d1d1d1c3a0a0a0b3d1d1c38686867217866392866286838693866286724353730021
1111009286620000009286620000928652629343605263048242335272009342c2e00404f1f1e1f1e0f0f1e1f0f000b2c2770092423333337032537200174360
c2870096b2333333c227c60000c617b2c257470096b23333e3d1d1c3004757f1e0f0e1e19386475700809086628286011111118621112186112121a230009386
8686628286730007009386720007928652720090425201112142705362049243e2c0c0c0c0c0c0c0c0c0c0c0c0c177b2c2770093423333335272500000001742
c2270097b3d33333c227c60000c617b2c277000097b3d1d1c3475700000096b1c0c0c0c192867204000083866292868686868686868686868686868686738386
8672009286639286629286738286928652620492427112121261528686278286e3d1d1d1d1d1d1d1d1d1d1d1d1c387b2c2000092423333338100000000001742
c277000096b23333c227c60000c517b2c20000000000574747000000000097b2333333c287861111210083866292863090805080903050305030409080009286
8672000090008286720040009286638652620092427032326033525086739286c277c65700c6570057c5004757c597b2c2870093436033335263000000001742
c287000097b3d333c227c50000c517b2c28700000000e1e0f1f10000000097b2333333c293868686866283862783867201000100000000000001000000009386
8662000000009286620000009286738652720082425250804332539286629386c287c60000c6000000c5000000c596b2c2870000804332325363000000001743
c20000000097b233c227c50000c517b2c20000000000b0c0c0d00000000096b2333333c277408050866383866292868686728673000000009386630000008386
8672000000009386730000008286938652630093435372005080309286738286c287c6c6c6c6000000c5000000c596b2c2e1000000408090500000000096b1c0
c22700000096b3d3c227c50000c517b2c28700000000000047000000000097b2333333c287000092867283867282868686b78673000000008386730000009386
8607070707070786070707070786728652720000904000000000009286279286c20007070707070707070707070707b2e2c1870000000000000000000096b233
c2870000000037b2c227c50000c517b2c2770000000000f1e1e00000000096b2333333c287000092866292866292868686728663000000000040000000009286
8686868686868686868686868686828652620000000000000000008286739286c296b1c0c0c0c0c0c0c0c0c0c0c0c0d2a3c27700000000f1f1e1e0e10097b233
c2000000000096b2c227c60000c617b2c2870000000000b0c0d000000000f0b2333333c277000093866383867217868686928662000000070707070707008386
8673304030408090864090505050928671516300000021211121008386628286c297b3d1d1d1d1d1d1d1d1d1d1d1d1d3a3c28700000000b0c0c0c0d00096b233
c2870000000097b2c227c60000c617b2c20000000000000057000000f0e1b1d23333e3c387000092866283867292868686628607000707868686868686070786
8672000000070082866300070000938633527300000002121222009286739386c277c50000c5474757c60000004757b2a3c27700f1e10000000000000097b233
c2270000000097b2c227c60000c617b3c37700000000000000000096b1c0d2333333c25700000092866292866282868686838686638686865080509286868686
8663000082866200900082866300938633527200000000000000008386279286c287c50000c5000000c60000000000b3d1c3a0a0b1c1f100000000000096b3d3
c2770066000096b3c327c60000000057570000000000000000000097b23333333333c28700000083867283867393868686734001110150867200000080903086
8673000092867200000092866200828633526200000000000000008386739386c277c5c5c5c5000000c6c6c600e0f10047910097b2e2c18700000400000047b2
c2f1e067f0e00000e1e0f0e0e1e0f0f1e1e1f0e1e0f1f0f1e0e1f1e1b2a3a3a3a333c27700000093866392866282868686838686868683867200070000009386
8672070707860707070707860707078633526300000001211121009286728286c2070707070707070707070707b1c1e1e091e1e1b233c2f1e1000000e0f0f0b2
e2c0c0c0c0c1a0b1c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0d2333333a333c27700000093867292867392868686838662768093866293866200009286
8673868686868686868686868686868633527200009286868686628286629286e2c0c0c0c0c0c0c0c0c0c0c0c0d2e2c0c0c0c0c0d233e2c0c1870097b1c0c0d2
e3d1d1d1d3c200b3d1d1d1d1d3e3d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d5d333a333c28700000092866292867392868686728662760083867283866200009386
8663864332323232323232603333333333526300000086868686009286729386e3d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d333c2770096b2333333
c2275717b2c2000000475700b2c257000057000000570057470047004796b233a333c27700000092867383867393868686828662760092866392867200009286
8672905030405030404080433232323232536200000040903040009286639386c25747e1f1e0f0e147e0f0f157f0e0e1e0f000475797b233c2870097b2333333
c2270417b2c2260000000097b2c287f1e1f0e1f1e0e0e1f0f0e0e1000097b233a333c28700000083867300900092868686628673760000800083866200008386
866200f20000f200000000904050405090900000000000000000000080009286c28796b1c0c0c0c0c0c0c0c0c0c0c0c0c0c127000096b3d1c3870096b3d1d1d3
c227f217b2c2070000000096b2c287b1c0c0c0c0c0c0c0c0c0c0c1770096b233a333c28700000082867200000093868686938663760000000092866300009386
866300000000000000f20000112111012101000000002101110100000000f186c27797b2e3d1d1d1d1d1d3333333333333c227000000005791006600a25797b2
c2270017b2e2c18700000097b2c277b2d1d1d3e3d1d1d1d1d1d1c3870017b233a333c27700000083867200000092868686838673760000070707867200008386
867200000000000000000092868686868686620000000212122200000096b1c0c27797b2c24700574700a6333333333333c22700f200000091e067e1a20096b2
c227f217b3d3c28700000000b2c297b25747b2c287574700574700000017b233a333c28700000082860707070707868686b78662000017868686867200009286
866200000000000000000000508090403080000000000000000000000097b233c28796b2c2870004f097b2333333333333c2270000000000b1c0c0c0c10000b2
c227000017b2c20700000096b2c287b20496b2c277000000f1e000000017b233a333c28700000093868686868686868686938607070707865030800000008386
866300000000000000000000000000000000000000000000000000000096b233c27797b2c2c7b7b1c177b2333333333333e2c10707070707b2333333c22797b2
c227f20097b2e2c187000097b2c297b20097b2c287000096b1c107070707b233a333c28700000000308050868090405040838686868686867200000000008386
866200000000000000000000000000000000000000000000000000e0f1e0b233c27796b3c38797b2c287b2e3d1d1d1d33333e2c0c0c0c0c0d2333333c27796b2
c227000097b3d3c200000097b2c277b20097b3c377000097b2e2c0c0c0c0d233a333c2770000000000e0e18604f1000000005090308630900000000700009286
8662000000000000000000000000000000000000000000000000f0b1c0c0d233c2870057570097b2c296b2c2574796b2333333333333333333333333c20097b2
c22700f20017b2c207000096b2c296b20000574700000097b3d1d1d1d1d1d3a3a333c2870000000096b1c0c0c0c1112111010100838672000000928607070786
8663000000000000000000000000000000000000000000000096b1d233e3d1d1c3870000000096b3c397b2c2870497b3d1d1d1d1d1d1d1d1d1d1d333c28700b2
c22700000017b2e2c1870000b2c287b20000000000000000570047004796b3d33333c2870000000096b2a3a3a3c2868686868662009000000000938686868686
8662000000000000000000000000000000000001210121000097b23333b647570000f200000000004797b2c2e1e0f1f1e0570000474700f25796b3d3c28717b2
c22700f20017b3d3c2770097b2c296b2000000000000000000e1e000000097b23333c2770000000097b2333333c2508090408663000000070707078640308090
9000000000000000000000000000000000000002121222000096b23333c2770000000000000000000096b2e2c0c0c0c0c0c1770000000000000097b3c37797b2
c2270000000017b2c2770096b2c287b200e0f0f10000000096b1c177000096b3d1d1c3870000000096b2333333c2870000928662000092868686868672040000
0000012111212101010121110121000000000000000000000097b2a3e3c387000000f200000000000096b3d1d1d1d1d1d1c327000000000000f20000000096b2
c2270000f20017b3c3000097b2c204b296b1c0c17700000097b2c27700000047004757000000000097b2333333c2870000838663000083863080408663000000
0093868686868686868686868686620000000000000000000096b233c2870000000000000000000000000047000057005700000000000000000000f2000097b2
c227e0f1e0e1e1e0f0f0e0f1b2c207b200a633c28700000097b3c3770000f0e1e0e100000000000000a6333333c2770000928607070707866200928601110121
1121865030908030503050903086110111210121112111012111b233c277000000000000000000000000000000000000000000000000000000000000000007b2
e2c0c0c0c0c0c0c0c0c0c0c0d2e2c0d297b2a3c287000000000000000097b1c0c0c187000000000096b2a3a3a3c2870000838686868686866300828686868686
8686866200000000000000008286868686868686868686868686b233c2870000000000000000000000000000000000000000000000000000000000000000b1d2
__map__
072323232323232323232323232323233a3a0723232306333333330723232323232323232323230633330723232323232306333333333333333a3a3a3a3a3a3a07232306072323232323230633333333072323232323232323230633072323232323063a3a3a3a3a072323232323232323232323063a3a3a3a3a3a0723232306
250810031205090411040510031204033a332508050434232323233503050303040803050309053423233504090409040934232323232323230633333333333a254004242526040309030434230633332527030903042a03090824332504080409053f3333072323350805670904670309030504342323063333332505090824
252668686868686868686868686868363a07353700000305030404030000121210000000000000040409030000000000000905040904050905341a063333333a253738242527000000000009033423233526004000002a0040282433253700000028342323350967000000670000670000000000030803243333332537403924
25266809041104120905100311086838073509006262626262626262620014211527002f0000000000002f00002f00121010111040111200000838243333333a2527292425266c005c5c006c6c0309040511120000002a1211102433253740000000086709040067000000670000671210100000000038243333332526002924
2539682768686868686868686827682725090000707070707070707070122433253600000000002f00000000000000202121212121211527000028243333333a2526383435376c00000000006c0028142121150a0a0a142121211633253600000000006700000067707070707070142121151000000038243333332537001124
252668386809100411081205682668292527000020212121212121212114163325707070700000000070707070707070707005050908313700002934232306332537000409006c000000000000002924333325124912243333333333251210121012006700007070142121212121163333171536000029243333073526281416
25376826682868686868682968396829253600000000000000090810103f333317212121157070707014212121212121211512100000000000000005080924332526000000006c0000000000000028243333172121211633333333331721212121157070707014211633333333333333330025270000113f3333250800292433
25296838682668360508682868266827255c5c006c6c005c5c00281421163333333a3333172121212116333333333333331721152600001210120000003924332537005c5c0000000000000000002924072323232323232323232323232323230617212121211633333333333333333333073526003814163a07352600392433
2537682668266840682668266839682925707070707070707000392433333333333a33333333333333333333072323232323062510000020212200000028243325720000000000000000000000002824250309737373737373737373737373082400072323232323232323232323063333250900002924333325090000283406
252668286836686868296826682668382521212121212121220039243307232323231a23063333330723232335040908050424171536000008000000003824332572006c6c0000000000000000002824252700626262626262626262626262393423350508040905030803090305342323350000001124333325370000000924
25296827681205110410683968386827252709000000000000002924073505050908000334232323350304080000000000003f3325260000000000000028342335720000000000000000000000002924253600626262626262626262626262000509040000000000000000000000030908050000391416333325360000002924
253768286868686868686837683968382526005c6c5c6c5c6c5c6c24250900000000000005040809030000000000000000112407353700001012101211000409000000000000005c5c00000000002834352700626262626262626262626262000000002f0000002f0000002f0000000000000000382433333325270000003924
2539681103120304120411126826682735270070707070707070702425272f000000000000000000121012111000000029141625260000002021212122000000000000000000000000000000000000000900006262626262626262626262621211100000000000000000000000000000002f000039243a072335370000002924
252668686868686868686868682768680400002021212121212121242536000000000000000000002021212122000000382407352700000000000809000000000000000000121211121110000000000000111062626262626262626262626214211570707070707070707070700000000000000029243325092a000000003824
252609030405100403040510101210041010111112101112101110242512121011000000121100000000090000000010112425090012101112111011121011121211000011142121212115111210101110141570707070707070707070707024331721212121212121212121157070707070707070243318102a110000003924
2537000020212121212121212121212121212121212121212121211617212121152700291415370000000000000028142116252739142121212121212121212121210a0a211633333333172121212121211617212121212121212121212121163333333333333333333333331721212121212121211633172121152700002824
2c7800793b1d1d1d1d3d3333333e1d3c333333333a3a3a3a3a3a3a3a3a3a3a332537002924253600121211100000292433332537292400333333333333333333333a333333333333333333333a333a33333333330723232323063333333333333333330723232323063333072323232323232323063333333307353700003824
2c780000741e0e74753b1d1d1d3c75143a3a33333a3333333333333a33333a33251000292425370020212122000039243307352628342306330723232323063307232323230633333333330723232323232323233509090809342323230633333333331808090305342323350309040304090804243333333325360000003824
2c7700000b0c0d00007400757410113f330723230633333333071a2323063333171527141625360000080900000029240735040000090434233504080904243325080409053406333333073505040305030409080900000000000508053423063307233500000000080309111012101012110039243333333325271249103824
2c00000000000000000011101014211633250809342323232335000928243333332537340625120000000040000010242508000000000008090400000029342335370000000324333307350900000000000000000000000000000000000509240735090400000000000029142121212121152738243333333325262021222824
2c77001e0f0e0000003814212116333333253600030904090805000038243333332537082417153600001110113814162536005051000000000000000000080505000000003824333325040000001211121112000000000000000000000028242505000000000000002f28243333333333253728243333333325270009007124
2c00000b0c0d0000002824333333333333252600000000000010111229340633332536392433252600002021222924331337116061100000000000000000000000000000003924333325270000381421212115260000001011100000000039242526000000000000000038342306333333252739243333333325262f00711416
2c1e000074000000001124330723232307352600000000000020212200092433073527292433252711101109381416331336202121220000005051000000101112000000002834063325360000392433333325271012101421152600000028343537000000000000002f00083834230633253629340633333325360000712433
2e1c000000000000381416332509040519090000000000000000090000292433250900383406253620212200293406331327000009000000126061100039142115370000000029243325270000292433333317212121211607353600000000090900000000000000000000000009053f33253700092433333325272f00712433
332c770000000000393406332526400019000000001114151000000000282433253600000934352600090000000824331337000000000000202121220029243325110000000028342335360000392433072323232323232335050000000000111210000000000000000000000000282433253700382433333325360000712433
3e3c00000e1e0f00000824332512101219120000111416171512000000383406252700000008090000000000003824331327001210000000000009000028243317153600000000080509000000382433250908030504050409000000001011142115370000000000000000002f00141607352600282433330735260000713406
2c7500000b0c0d00003824331721212117151210142121212115370000000334353600000000000000000000003824331336002022000000000000000039243333252600000000000000000000112433252700000010401200000000291421163325111212000000000000000000340625080000393406332509000000007124
2c77000000740000003934232323063a33172121160723230625260000000004090000101112111010000000002924332526000000000050510000000029340633252700000011104912100039141633252600000020212200000000382433333317212115260000000000002f000924253600000038243325362f0000007124
2c7800000000000000000509050434233a3a3a3a3a2504093435370000000000000029142121212115260000002934233537000000001160611000000000092433251212002914212121152729243333252700000000090000000000283423232323230625120000000000000000382425370000002834062527000000007124
2c000066000000000000001f0f1f091f3333333333253600050311121110111211121224333333073536000000101104121200505129142121152600505128243317211511112a1240111912102433331811126d7a11101112100000002a03080505092417152600000000000000292425260000000038343526000000007124
2c1f0f761f0f0e1f0f0e1f1b0c0c0c0c3a3a3a3333171526281421212121212121212116333333182a101211101421212115116061112433332527126061112433333317212121212121212121163333172121212121212121151110122a101211491224332510111012111210112824253700116d7a10041011110000111416
2e0c0c0c0c0c0c0c0c0c0c2d3a3a3a3a333a3a33333a170a0a16333333333333333333333a3a3a172121212121163333331721212121163333250a142121211633333333333333333333333333333333000000000000000000172121212121212121211633172121212121212121211617153814212121212121152628141633
__gff__
0000000000000101000005010101000000000001010101010001000101010000010101010101000000000101010101800101018001010000000001010101010000000000000000000000000000000000010100000000000000000000050000000101050505058000010000000500000002020202000080000000000808080000
0000000000000000000000000000000000000000000000000000000000000000000000002b01780048000000000000000000ffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
9101000008550095500b5500c55010550175500d5001050012500155001a5000a5000a5000a5000b5000d50010500135000e5001350019500085000750007500095000a5000c5000e5001150014500185001c500
c102000030557345573a5573c5073c5071c5071e50732557365573a557275072f50738507355073350731507315073350735507395073a507395073950739507305073450736507385073b5073e5073f50700500
c50e00000065400154006540015400654001540065400154006540015400654001540065400154006540015400654001540065400154006540015400654001540065400154006540015400654001540065400155
c001000021420214201d4201a42015420114201b40017400154001440000400004001840018400004000040018400184000040000400184001840018400004000040000400004000040000400004000040000400
580400000d05011050140501705022000200002a000250002200000000200001c0001a000100000d0000c00018000180001800018000180001800018000180000000000000000000000000000000000000000000
490600000c0400d00010040140001304011000170401700018040120001c040190001f04001000210401f0002404024040240401f000000000000000000000000000000000000000000000000000000000000000
40010000035500355003550035500255006550065500655006550005000050000500005000050000500005001a5001a5001a5001a5001a5001a5001a5001a5000050000500005000050000500005000050000500
911000000575502705057550270505755027050575502705057550270505755027050575502705057550470500705000000000000000000000000000000000000000000000000000000000000000000000000000
0104000002616056160c6160f61615616196161b6161f61621616256162761629616296162961628616276162661624616226161e6161b6161861616616146161261611616106161061610616106161061610615
000300000a15008150051500115000150001500015000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
110a00001812000100181200010018120001001812018120181201812000100141201412014120141200010016120161201612016120001001812018120181251612016120181201812018120181201812018125
010a0000247202470024720247002472024700247202472024720247200c700207202072020720207200c700227202272022720227200c7002472024720247202272022720247202472024720247202472024725
110a00001f120001001f120001001f120001001f1201f1201f1201f120001001b1201b1201b1201b120001001d1201d1201d1201d120001001f1201f1201f1251d1201d1201f1201f1201f1201f1201f1201f125
411c00000c7551075513755177551775513755107550c7550c7551075513755177551775513755107550c7550e75511755157551a7551a75515755117550e7550e75511755157551a7551a75515755117550e755
311c00002b7322b7322b7322b73228732287322873228735000000000026732267322873228732287322873226732267322673226732247322473224732247350000000000247322473226732267322673226732
311c00002b7322b7322b7322b73228732287322873228735000000000028732287322b7322b7322b7322b7322d7322d7322d7322d732297322973229732297350000000000297322973228732287322873228732
411c00001f0321f0321f0321f0321c0321c0321c0321c03518000180001a0321a0321c0321c0321c0321c0321a0321a0321a0321a03218032180321803218035180001800018032180321a0321a0321a0321a032
411c00001f0321f0321f0321f0321c0321c0321c0321c03518002180021c0321c0321f0321f0321f0321f032210322103221032210321d0321d0321d0321d03518000180001d0321d0321c0321c0321c0321c032
411c0000187551875518755187551875518755187551875518755187551875518755187551875518755187551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a7551a755
411c00001c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551c7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d7551d755
411000001805218052180521805218052180521805218055000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
__music__
05 0a4b0c44
01 0d4e4344
01 0d0e4344
00 0d0f4344
00 0d0e1044
00 0d0f1144
04 144e4344
00 130f4344
04 14424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 04050607
02 04050608
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000888888000000888888880000888888880088888888888888888888888888888888000088888888888888000088888888888888888800000000000
00000000008877778000008877777780008877777780887777777777778877777777778877778000887777778877778000887777887777777777800000000000
00000000088377778000088377777788888377777788837777777777778377777777778377778008837777778377778888837777837777777777800000000000
0000000008b377778000887777777777887777777777b3777777777777b37733333333b377778008b3777777b377777788777777b37777333338800000000000
0000000008b377778008837777777777837777777777b3777777777777b377bbbbbbbbb377778008b3777777b377777783777777b37777bbbb88000000000000
0000000008b377778008b37777337777b37777337777b3333377773338b37777777777b377778008b3333333b377777777777777b37777777780000000000000
0000000008b377778008b37777337777b37777337777bbbbb37777bb88b37777777777b377778008bbbbbbbbb377777777777777b37777777780000000000000
0000000008b377778008b37777337777b377773377778888b377778888b33333333377b37777800888777777b377773377337777b37777333880000000000000
0000000008b377778888b37777337777b377773377778008b377778008bbbbbbbbb377b37777888883777777b37777b377b37777b37777bb8888800000000000
0000000008b377777777b37777777777b377777777778008b377778008887777777777b377777777b3777777b37777b338b37777b37777777777800000000000
0000000008b377777777b37777777777b377777777778008b377778008837777777777b377777777b3777777b37777bb88b37777b37777777777800000000000
0000000008b377777777b33377777738b333777777388008b377778008b37777777777b377777777b3777777b377778888b37777b37777777777800000000000
0000000008b377777777bbb377777788bbb3777777880008b377778008b37777777777b377777777b3777777b377778008b37777b37777777777800000000000
0000000008b33333333888b33333388888b3333338800008b333388008b33333333338b333333338b3333338b333388008b33338b33333333338800000000000
0000000008bbbbbbbb8808bbbbbb880008bbbbbb88000008bbbb880008bbbbbbbbbb88bbbbbbbb88bbbbbb88bbbb880008bbbb88bbbbbbbbbb88000000000000
00000000088888888880088888888000088888888000000888888000088888888888888888888888888888888888800008888888888888888880000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000444000004440000000000000000000000000000000000000000000000000000044400000444000004440000000000000000000000000000
00000000000002202400044024000440022000000000000000000000000000000000000000000220240004402400044024000440022000000000000000000000
00000000000000400220022402200224040004000000000000000000000000000000000000000040022002240220022402200224040004000000000000000000
00000000000004400000000200000002044044000000000000000000000000000000000000000440300330330000000200000002044044000000000000000000
00000000002200003003300030033000000000000000000000000000000000000000000000220000b333b3333003300030033000000000000000000000000000
00000000024000033333b3bb3333b3bb300422200000000000000000000000000000000002400003bbbbbbbb3333b3bb3333b3bb300422200000000000000000
0000000004440033bb3bb33bbb3bb33b330044420000000000000000000000000000000004440033bb00000bbb3bb33bbb3bb33b330044420000000000000000
000000000000033bbbbbbbbbbbbbbbbbb3300000000000000000000000000000000000000000033bb0000000bbbbbbbbbbbbbbbbb33000000000000000000000
00000000000333bb0303303080303c33bbb3304404440000044400000444000004440000000333bb0000000080303c330000000cbbb330400000000000000000
000000000400333b030390300080303cbb330042240004402400044024000440240004400400333b000000000080303c00000000bb3300420000000000000000
000000000420033b0303003000003030b3333020022002240220022402200224022002240420033b000000000000303000000001b33330200000000000000000
00000000000003bb0303003000003030bb33000000000002000000020000000200000002000003bb0000000000003030000000c0bb3300000000000000000000
000000000040333b0303003000003030b3300303300330003003300030033000300330003003333b000000000000303000000130b33004400000000000000000
00000000044003bb0303003000003030bb3333333333b3bb3333b3bb3333b3bb3333b3bb3333b3bb00000000000030300000003cbb3302000000000000000000
000000000420033b0303000000003030bbbb33bbbb3bb33bbb3bb33bbb3bb33bbb3bb33bbb3bb33b000000000000303000000033bbb300040000000000000000
00000000022033bb03030000000030300bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000303000000000bb3330420000000000000000
00000000000333bb03030000000030300330303080303c330330303380303c330303303003360306000000000000303000000000bbb330440000000000000000
000000000400333b3393000000003030080030800080303c003010300080303c0303903000300900000000000000303000000006bb3300420220000000000000
000000000420033b9303000000003030000080000000303000600030000030300303003000600000000000000000303000000003b33330200400040000000000
00000000000003bb03030000000030000000000100003030000000c0000030300303003000000005000000000000300000000000bb3300000440440000000000
000000000040333b9303000000003000000000000000303000000000000030300303003000000000000000000000300000000060b33003030000000000000000
00000000044003bb0303000000003000000000000000303000000000000030300303003000000000000000000000300000000036bb3333333004222000000000
000000000420033b9303000000003000000000000000303000000000000030300303000000000001000000000000300000000003bbbb33bb3300444200000000
00000000022033bb03030000000030000000000000003030000000000000303003030000000000000000000000003000000000000bbbbbbbb330000000000000
00000000000333bbe00300000000300000000000100030300000000000003030030300000bbbbbbbbbbbbbbbbbbbbbb00000000680303c33bbb3304000000000
000002200400333b00030000000030000000000000003030000000000000303003030000bbb33b3b3bb33b3b3bb3b3bb050000000080303cbb33004200000000
000000400420033b08035000000030000000000000003030000000000000303003030000b3b3333333b3333333b3333b0000000000003030b333302000000000
00000440000003bb03030000000005000000000000003000000000000000300003030000b333333003333330033333bb0000000000003030bb33000000000000
002200003003333b33030000000000000000000000003000000000000000300003030000b3304034034040340340433b0000000000003030b330044000000000
024000033333b3bb00030000000000000000000000003000000000000000300003030000b3000044044000440440033b0000000000003030bb33020000000000
04440033bb3bb33b800300000000000000000000000030000000000000003000030300003300000000240022002000330000000000003030bbb3000400000000
0000033bbbbbbbb0000300000000000000000000000030000000000000003000030300000000000000020000000000000000000000003030bb33304200000000
000333bb80303c33000300000000000000000000000030000000000000003000000300000000000080303c3300000000000000000000303ebbb3304000000000
0400333b0080303c00030000000000000000000000003000600000000000300000030000000000000080303c000000000000000000003030bb33004200000000
0420033b00003030000300000000000000000000000030050000000000003000000300000000010000003030000000000000000000003030b333302000000000
000003bb00003030000300000000000000000000000000000000000000000000000300000000000000003030000000000000000000003030bb33000000000000
0040333b00003030000300000000000000000000000000000000000333000000000300000000000000003030000050000000000000003033b330044000000000
044003bb00003030000300000000000000000000000000000000003733700000000350000000000000003030060000000000000000003000bb33020000000000
0420033b00003030000300000000000000000000000001000000003033000000000300000000000000003030000000000000000000003008bbb3000400000000
022033bb00003030000000000000000000000000000000000000003333300000000300000000000000003030000000000000000000003000bb33304200000000
000333bbe0003030000000000000000000000000000000000bbbbbbbbbbbbbb000030000000000000000303000000000000000000000300cbbb3304000000000
0400333b0000303000000000000000000000000000000000bbb3bbbb3bbb3bbb000300000000000000003030000000000000000000003000bb33004200000000
0420033b0800303000000000000000000000000000000000bb3333b333b333bb000300000000000000003030000000000000000000003001b333302000000000
000003bb0300300000000000000000000000000000000000bb3303330333333b0003000000000000000030000000000000000000000000c0bb33000000000000
0040333b33003000000000000000000000000000000000c0b3300000030003bb000300000000000000003000000000000000000000000130b330044000000000
044003bb0006300000000000000000000000000000600030bb3304440000033b00038000000000000000300000000000000010000000003cbb33020000000000
0420033b8000300000000000000000000000000000301030bbb300422440033b080330800000050000003000000000000000000000000033bbb3000400000000
022033bb0000300000010000000000000000000003303033bb333000024033bb033030300000000000003000000000000005000000100000bb33304200000000
000333bb000030000000000000000000000000000bbbbbbbb33000000000033bbbbbbbb00000000000003000000000000000000000000000bbb3304400000000
0400333b00003000000000000000000000000000bbb3bbbb33004442044400333bbb3bbb0000000005003000000000000000000000000006bb33004202200000
0420033b00003000000000000000000000000000bb3333b3300422200240000333b333bb0000000000003000000000000000000000000003b333302004000400
000003bb00000000000000000000000000000000bb33033300000000002200000333333b0000000000000000000000000000000000000000bb33000004404400
0040333b000000000000000000000000000000c0b33000000440440000000440030003bb0000000000000000000000000000000000000060b330030300000000
044003bb00600000000000000000000000600030bb33044404000400000000400000033b0060000000000000000000000000000000000036bb33333330042220
0420033b00300900000000000000000000301030bbb3004202200000000002202440033b0030090000000000000000000000000000000003bbbb33bb33004442
022033bb03360306000000000000000003303033bb3330000000000000000000024033bb03360306000000000000000000000000000000000bbbbbbbb3300000
0000033bbbbbbbb000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000080303c33bbb33040
044400333bbb3bbb0000000000000000bbb3bbbb3bb33b3b3bb33b3b3bb33b3b3bb33b3b3bbb3bbb600000000000000000000000000000000080303cbb330042
0240000333b333bb0000000000000000bb3333b333b3333333b3333333b3333333b3333333b333bb3000000000000000000000000000000000003030b3333020
002200000333333b0000000000000000bb330333033333300333333003333330033333300333333b0000000000000000000000000000000000003030bb330000
00000440030003bb0000000000000000b330000003404034034040340340403403404034030003bb0600000000000000000000000000000000003030b3300440
000000400000033b0060000000008000bb330444044000440440004404400044044000440000033b6300010000000000000000000000000000003030bb330200
000002202440033b0030090008003080bbb30042002400220024002200240022002400222440033b3000006000000000000000000000000000003030bbb30004
00000000024033bb0336030603303030bb33300000020000000200000002000000020000024033bb0000000000000005000000000000000000003030bb333042
000000000000033bbbbbbbbbbbbbbbbbb330000000000000044400000444000000000000000333bbe000000000000000000000000000000000003030bbb33040
00000000044400333bb33b3b3bb33b3b33004442000002202400044024000440022000000400333b0000000000000000000000000000000000003933bb330042
000000000240000333b3333333b3333330042220000000400220022402200224040004000420033b0800000100000000000000000000000000003039b3333020
000000000022000003333330033333300000000000000440000000020000000204404400000003bb0300000000000000000000000000000000003000bb330000
0000000000000440034040340340403404404400002200003003300030033000000000000040333b3300000000000000000000000000000000003009b3300440
0000000000000040044000440440004404000400024000033333b3bb3333b3bb30042220044003bb0000000000000000000000000000000000003000bb330200
000000000000022000240022002400220220000004440033bb3bb33bbb3bb33b330044420420033b8000000000000000000000000000000000003009bbb30004
00000000000000000002000000020000000000000000033bbbbbbbbbbbbbbbbbb3300000022033bb0000000050000000000000000000000000003000bb333042
0000000000000000000000000000000000000000000333bb0330303380303c33bbb33044000333bb000000000000000000000000000000000000300cbbb33040
00000000000000000000000000000000000000000400333b003010300080303cbb3300420400333b6000000000000000000000000000000000003000bb330042
00000000000000000000000000000000000000000420033b0060003000003030b33330200420033b3000000000000000000000000000000000003001b3333020
0000000000000000000000000000000000000000000003bb000000c000003030bb330000000003bb00000000000000000000000000000000000000c0bb330000
00000000000000000000000000000000000000000040333b0000000000003030b33003033003333b0600000000000000000000000000000000000130b3300440
0000000000000000000000000000000000000000044003bb0000000000003030bb3333333333b3bb630000000000000000000000000000000000003cbb330200
00000000000000000000000000000000000000000420033b0000000000003030bbbb33bbbb3bb33b3000000000000000000000000000000000000033bbb30004
0000000000000000000000000000000000000000022033bb00000000010030300bbbbbbbbbbbbbb00000000000000000000000000000000000000000bb333042
0000000000000000000000000000000000000000000333bb090000000000303003360306033030300000000000000000000000000000000000000000bbb33040
00000000000000000000000000000000000000000400333b339000000000303000300900080030800000000000000000000000000000000000000000bb330042
00000000000000000000000000000000000000000420033b930000000000303000600000000080000000000000000000000000000000000000000000b3333020
0000000000000000000000000000000000000000000003bb000000000000300000000000000000000000000000000000000000000000000000000000bb330000
00000000000000000000000000000000000000000040333b90000000000030000000000000000000000000c000000000000000c000000000000000c0b3300440
0000000000000000000000000000000000000000044003bb000000000000300000000000000000000060003000600001006000300000800000600030bb330200
00000000000000000000000000000000000000000420033b900000000000300000000000000000000030103000300900003010300800308000301030bbb30004
0000000000000000000000000000000000000000022033bb000000000000300000000000000000000330303303360306033030330330303003303033bb333042
00000000000000000000000000000000000000000000033bbbbbbbb0e00030000000000c0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3300000
0000000000000000000000000000000000000000044400333bbb3bbb0000300000000000bbb3bbbb3bb33b3b3bb33b3b3bb33b3b3bb33b3b3bb33b3b33004442
00000000000000000000000000000000000000000240000333b333bb0800300000000001bb3333b333b3333333b3333333b3333333b3333333b3333330042220
0000000000000000000000000000000000000000002200000333333b03000000000000c0bb330333033333300333333003333330033333300333333000000000
000000000000000000000000000000000000000000000440030003bb3300000000000130b3300000034040340340403403404034034040340340403404404400
0000000000000000000000000000000000000000000000400000033b000000000000003cbb330444044000440440004404400044044000440440004404000400
0000000000000000000000000000000000000000000002202440033b8000000000000033bbb30042002400220024002200240022002400220024002202200000
000000000000000000000000000000000000000000000000024033bb0100000000000000bb333000000200000002000000020000000200000002000000000000
0000000000000000000000000000000000000000000000000000033b0000000000000000b3300000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000004440033004200400042004033004442000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000002400003000002420000024230042220000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000220000440000204400002000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000440244040002440400004404400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000040042044420420444204000400000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000220000024200000242002200000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
