pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

dr = {1, 0, 0, 1, -1, 0, 0, -1}
bg_col = 0
bsc = 6
--fsh=12
levels = {10, 20, 50, 100}
shapes = {
-- base
16, 0, 1, 4, 17, 3, 3, 2, 17, 0, 2, 3, 19, 0, 2, 3, 21, 0, 2, 3, 23, 0, 2, 3,
-- level one 
20, 3, 1, 1,
-- planks
21, 1, 4, 2,
-- flat c
20, 0, 2, 2,
-- square
-- level two
16, 5, 5, 4,
-- small treasure
16, 4, 1, 1,
-- gob
28, 0, 3, 3,
-- small h						
-- level three
21, 5, 7, 5,
-- big treasure
20, 4, 1, 1,
-- spikes
28, 5, 4, 2,
-- side planks
-- level four
21, 3, 4, 1,
-- wall of spikes
25, 0, 4, 5,
-- big h
28, 7, 4, 2,
-- invasion
21, 4, 1, 1,
-- wall eye
--
}

function _init()
  t = 0
  _t = 0
  logs = {}
  init_menu()
--init_game()
end

function both()
  return btnp(4) or btnp(5)
end

function init_menu()
  t = 0
  music(0)
  go = nil
  lt = 0
  main_upd = function()
    if not go and both() then
      go = true
      lt = min(40, lt)
      sfx(18)
      music(-1)
    end
    if go then
      lt = lt - (1)
      if lt == -1 then
        init_game()
        upd_game()
      end
    else
      lt = lt + (1)
    end
  end
  main_dr = function()
    local t = lt
    local fd = max(5 - t / 8, 0)
    for i = 0, 15 do
      pal(i, sget(i, 19 + fd))
    end
    rectfill(0, 0, 127, 255, 0)
    local c = max(1 - t / 32, 0)
    c = c * c
    camera(0, c * 64)
    map(32, 0, 0, 0)
    local y = cos(t / 40) * 2 + .5
    print("----------------", 32, y + 4, 7)
    print("little architect", 32, y + 12, 7)
    print("----------------", 32, y + 20, 7)
    -- head
    spr(13, 32, 100)
    -- stars
    srand(96)
    for i = 0, 128 do
      local c = .1 + rnd()
      x = rnd(128)
      y = rnd(128) + t * 16 * c - c * rnd(512)
      x = (x - 64) * (1 + t * .05) + 64
      spr(96 + rnd(3), x, y)
    end
    if t % 16 < 8 and not go then
      local s = "press 5 to start"
      print(s, 33, 91, 0)
      print(s, 32, 90, 7)
    end
    --
    print("2019 alakajam", 68, 121, 13)
  end
end

function init_game()
  music(4)
  t = 0
  ents = {}
  blocks = {}
  monsters = {}
  curh = 64
  toth = 0
  diams = 0
  planks = 5
  hp = 3
  hpmax = 3
  -- clean
  reload()
  gmo = nil
  acid = 0
  --
  local hy = seek_height() * 8
  hero = mke(58, 64, hy - 8)
  hero.upd = upd_hero
  hero.phys = true
  hero.phys2 = true
  hero.head = 13
  hero.bnc = bnc_hero
  hero.ww = 6
  hero.hh = 7
  hero.drx = -1
  hero.dry = -1
  hero.resist_acid = true
  hero.upd(hero)
  wfr = 0
  main_upd = upd_game
  main_dr = dr_game
end

function morph_mon(e)
  e.mons = true
  e.splashable = true
  add(monsters, e)
end

function bnc_hero(e, v)
  if v then
    if e.vy < 0 then
      brk(e.px, e.py - 1, 0, -1)
    end
    e.vy = 0
  else
    e.gdi = sgn(e.vx)
    e.vx = 0
  end
end

function get_shape(n)
  if fsh then
    n = fsh
    fsh = nil
  end
  n = n * (4)
  local a = {}
  local sx = shapes[n + 1]
  local sy = shapes[n + 2]
  local ww = shapes[n + 3]
  local hh = shapes[n + 4]
  for dx = 0, ww - 1 do
    for dy = 0, hh - 1 do
      local tx = sx + dx
      local ty = sy + dy
      local tl = mget(tx, ty)
      if tl > 0 then
        add(a, {x = dx, y = dy, tl = tl})
      end
    end
  end
  return a
end

function pop_block()
  -- height
  local y = seek_height()
  y = y - (18)
  -- shape
  local smax = 6
  for l in all(levels) do
    if toth > l then
      smax = smax + (3)
    end
  end
  local n = rand(smax)
  local shp = get_shape(n)
  local turn = rand(4)
  if shapes[n * 4 + 1] > 4 then
    turn = 0
  end
  for d in all(shp) do
    for i = 1, turn do
      local x = d.x
      local y = d.y
      d.x = -y
      d.y = x
    end
    if rand(400) == 0 then
      d.tl = 55
    end
    if d.tl == 55 then
      if rand(5) == 0 then
        d.tl = 52
      end
      if rand(5) == 0 then
        d.tl = 123
      end
      if rand(5) == 0 then
        d.tl = 59
      end
    end
  end
  local a = {}
  for x = 1, 15 do
    local ok = true
    for d in all(shp) do
      local fx = x + d.x
      ok = ok and fx < 15 and fx > 0 and mget(fx, y + d.y) == 0
    end
    if ok then
      add(a, x)
    end
  end
  -- no space left
  if #a == 0 then
    return
  end
  local x = a[1 + rand(#a)]
  for d in all(shp) do
    mk_block(d.tl, x + d.x, y + d.y)
  end
  -- launch
  push(cgr[1], 0, 1, 4)
  cgr = nil
end

function mk_block(tl, px, py)
  b = mke(tl, px * 8, py * 8)
  b.resist_acid = true
  b.px = px
  b.py = py
  add(blocks, b)
  -- group
  if not cgr then
    cgr = {}
    b.gr = cgr
  end
  add(cgr, b)
  b.lead = cgr[1]
end

function gbcol(e, dx, dy)
  local tp = e.mdx == 0 and 4 or 5
  for b in all(e.gr) do
    if mcol2(b.px + dx, b.py + dy, tp) then
      return true
    end
  end
  return false
end

function push(e, dx, dy, spd)
  if not e.mv then
    e.mv = 0
  end
  e.mvs = spd
  e.mdx = dx
  e.mdy = dy
  -- check print
  local cl = gbcol(e, dx, dy)
  for e in all(e.gr) do
    if cl then
      print_block(e)
    else
      if dy == 1 then
        mset(e.px, e.py, 0)
      end
      e.px = e.px + (dx)
      e.py = e.py + (dy)
      if dy == 1 then
        msetf(e.px, e.py, 34)
      end
    end
  end
  if cl then
    lsfx(3, e)
    for e in all(e.gr) do
      msetf(e.px, e.py + 1, 0)
    end
  end
  ---
  -- check 
  if e.mono and is_out(e) then
    kl(e)
  end
end

function is_out(e, ma)
  local ma = ma or 32
  local left = min(-ma, cmx - ma)
  local right = min(128 + ma, cmx + 128 + ma)
  return e.x < left or e.x > right
end

function msetf(x, y, tl)
  if not mcol2(x, y, 4) and y < 64 then
    mset(x, y, tl)
    msetf(x, y + 1, tl)
  end
end

function grab(fr)
  if fr == 55 then
    diams = diams + (1)
    sfx(7)
  elseif fr == 59 then
    planks = planks + (2)
    sfx(20)
  elseif fr == 123 then
    hp = min(hp + 1, hpmax)
    sfx(21)
  end
end

function morph_item(a)
  a.float = 2
  a.hcol = function()
    if hero.cfull or a.t < 16 then
      return
    end
    if hp == 3 and a.fr == 123 then
      return
    end
    kl(a)
    hero.cfull = 2
    grab(a.fr)
  end
  a.mcol = function(m)
    if m.item then
      return
    end
    kl(a)
    m.item = a.fr
  end
end

function print_block(e)
  kl(e)
  local tl = e.fr
  if not fget(tl, 0) and not fget(tl, 5) then
    local a = mke(tl, e.px * 8, e.py * 8)
    if fget(tl, 7) then
      -- gem
      morph_item(a)
    end
    if tl == 52 then
      -- gob
      a.px = e.px
      a.py = e.py
      a.di = 1
      a.wlk = 2
      morph_mon(a)
      wait(4, run_gob, a)
    end
    tl = 6
  end
  mset(e.px, e.py, tl)
  -- blocks
  if tl == 42 then
    for i = 0, 3 do
      local px = e.px + dr[i * 2 + 1]
      local py = e.py + dr[i * 2 + 2]
      if not mcol(px, py) then
        mset(px, py, 119 + i)
      end
    end
  end
  if e.ghl then
    splash(e.ghl)
  end
end

function rand(n)
  return flr(rnd(n))
end

function seek_height()
  for y = 0, 63 do
    for x = 1, 14 do
      if not fget(mget(x, y), 4) then
        return y
      end
    end
  end
  return 63
end

function move(e, dx, dy, n, f)
  moveto(e, e.x + dx, e.y + dy, n, f)
end

function moveto(e, tx, ty, n, f)
  e.sx = e.x
  e.sy = e.y
  e.ex = tx
  e.ey = ty
  e.twc = 0
  e.tws = n
  e.twf = f
  if n < 0 then
    dx = e.ex - e.sx
    dy = e.ey - e.sy
    e.tws = -sqrt(dx ^ 2 + dy ^ 2) / n
  end
  if e.inv then
    e.flp = e.sx < e.ex
  end
end

function sbl_col(x, y)
  return x >= sbl.x and y >= sbl.y and x < sbl.x + 8 and y < sbl.y + 8
end

function blocks_col(x, y)
  for e in all(blocks) do
    local l = e.lead
    local bx = e.px * 8 + (l.mv - 8) * l.mdx
    local by = e.py * 8 + (l.mv - 8) * l.mdy
    if x >= bx and y >= by and x < bx + 8 and y < by + 8 then
      culp = e
      return true
    end
  end
  return false
end

function ecol(e, dx, dy, f)
  act = e
  f = f or pcol
  dx = dx or 0
  dy = dy or 0
  local a = {0, 0, 0, 1, 1, 1, 1, 0}
  for i = 0, 3 do
    local x = e.x + a[i * 2 + 1] * (e.ww - 1) + dx
    local y = e.y + a[i * 2 + 2] * (e.hh - 1) + dy
    if f(x, y, i) then
      return true
    end
  end
  return false
end

function pmov(e, vx, vy)
  e.gdi = nil
  if ecol(e) then
    return
  end
  local cf = e == hero and hpcol or pcol
  -- x
  e.x = e.x + (vx)
  cl = e.bnc
  while ecol(e) or ecol(e, 0, 0, blocks_col) do
    e.x = e.x - (sgn(vx))
    if cl then
      cl(e, false)
      cl = nil
    end
  end
  -- y
  e.y = e.y + (vy)
  cl = e.bnc
  while ecol(e, 0, 0, cf) or ecol(e, 0, 0, blocks_col) do
    e.y = e.y - (sgn(vy))
    if cl then
      cl(e, true)
      cl = nil
    end
  end
--
end

function mcol(x, y, fl)
  fl = fl or 0
  return y >= 64 or fget(mget(x, y), fl)
end

function mcol2(x, y, tp)
  return y >= 64 or not fget(mget(x, y), tp)
end

function hit(px, py, di)
  local tl = mget(px, py)
  if tl == 3 then
    -- recule
    hero.fvx = -hero.di * 2
    hero.cwj = 12
    if mcol(px + di, py) then
      brk(px, py, di, 0)
    else
      mk_block(tl, px, py)
      cgr[1].mono = true
      push(cgr[1], di, 0, 8)
      cgr = nil
      mset(px, py, 6)
      -- anim
      local e = mke(48, px * 8, py * 8)
      e.flp = di == -1
      sfx(2, -1, 0, 2)
    end
  else
    brk(px, py, di)
  end
end

function brk(px, py, dx, dy)
  dx = dx or 0
  dy = dy or 0
  local tl = mget(px, py)
  if tl ~= 3 then
    return
  end
  sfx(5)
  mset(px, py, 6)
  fx_stone(px, py)
--end
end

function fx_stone(px, py)
  local a = {0, 0, 1, 0, 0, 1, 1, 1}
  for i = 0, 3 do
    local e = mke(17 + i)
    local ddx = a[1 + i * 2]
    local ddy = a[2 + i * 2]
    e.x = px * 8 + 2 + ddx * 4 - 4
    e.y = py * 8 + 2 + ddy * 4 - 4
    e.life = 8 + rand(8)
    impulse(e, atan2(ddx - .5, ddy - .5), 1)
    e.we = .25
    e.frict = .97
    impulse(e, atan2(dx, dy), 1 + rnd(2))
    e.vy = e.vy - (1)
  end
end

function impulse(e, an, spd)
  e.vx = e.vx + (cos(an) * spd)
  e.vy = e.vy + (sin(an) * spd)
end

function get_fall(px, py)
  if mcol(px, py) then
    return 0
  else
    return get_fall(px, py + 1) + 1
  end
end

function run_gob(e)
  e.x = e.px * 8
  e.y = e.py * 8
  --log(e.t..":"..e.px.." "..e.py)
  local again = function()
    run_gob(e)
  end
  local spd = 8
  e.flp = e.di == -1
  -- check fall
  if not mcol(e.px, e.py + 1) then
    move(e, 0, 8, spd, again)
    e.py = e.py + (1)
    return
  end
  local clu = mcol(e.px, e.py - 1)
  local clf = mcol(e.px + e.di, e.py)
  local clfb = mcol(e.px + e.di, e.py + 1)
  local clfu = mcol(e.px + e.di, e.py - 1)

  function go()
    move(e, e.di * 8, 0, spd, again)
    e.px = e.px + (e.di)
  end

  if not clf and clfb then
    go()
  else
    if e.y <= hero.y and rand(3) == 0 and clf and clfb then
      brk(e.px + e.di, e.py)
      e.x = e.x + (e.di * 4)
      move(e, -e.di * 4, 0, 6, again)
    elseif e.y + 4 < hero.y and not clf and not clfb then
      if e.y + get_fall(e.px + e.di, e.py) * 8 <= hero.y then
        go()
      else
        e.di = -e.di
        wait(10, again)
      end
    elseif e.y - 4 > hero.y and clf and not clfu and not clu then
      move(e, e.di * 8, -8, spd * 2, again)
      e.jmp = 8
      e.px = e.px + (e.di)
      e.py = e.py - (1)
    else
      e.di = -e.di
      wait(10, again)
    end
  end
end

function upd_hero(e)
  if gmo then
    return
  end
  -- update pos
  e.px = flr((e.x + 3) / 8)
  e.py = flr((e.y + 3) / 8)
  if mcol(e.px, e.py, 6) then
    hurt_hero()
  end
  -- equi
  if e.vy < 0 then
    e.eq = false
  elseif not e.ceq and not e.eq and not ecol(e, 0, 0, eqcol) then
    e.eq = true
  end
  -- grav & ground
  gr = hpcol(e.x, e.y + e.hh) or hpcol(e.x + e.ww - 1, e.y + e.hh)
  lad = mcol(e.px, e.py, 2)
  --or mcol(e.px,(e.y+7)/8,2) 
  if lad then
    gr = true
  end
  if not gr then
    if e.vy < 4 then
      e.vy = e.vy + (.5)
    end
    if e.gdi and e.vy > 1 then
      e.vy = 1
    end
  else
    if e.vy > 0 then
      e.vy = 0
    end
  end
  -- move
  e.vx = 0
  e.di = 0
  local spd = 3

  function hmov(di)
    e.di = di
    e.vx = e.vx + (di * 2)
    if t % 4 == 0 then
      wfr = wfr + (1)
    end
  end

  look_up = btn(2)
  if btn(0) then
    hmov(-1)
  end
  if btn(1) then
    hmov(1)
  end
  -- ladder look up
  look_up = false
  if lad then
    hero.vy = 0
    if btn(2) then
      hero.vy = -1
    end
    if btn(3) then
      hero.vy = 1
    end
  else
    look_up = btn(2)
  end
  if not lad and btnp(3) and e.eq then
    e.eq = false
    e.ceq = 4
  end
  -- force look
  if e.cwj and not gr then
    e.di = sgn(e.fvx)
  end
  -- jump
  local wg = not gr and e.gdi and e.vy > 0
  if (gr or wg) and btnp(4) then
    if wg then
      e.fvx = -e.gdi * 3
      e.cwj = 16
    end
    e.vy = -5
    e.eq = false
    sfx(1, -1, 0, 1)
  end
  -- target
  floor_ready = not mcol(hero.px, hero.py + 1) and not mcol(hero.px, hero.py + 1, 1)
  ladder_ready = gr and look_up
  -- hit or use
  if btnp(5) then
    --hurt_hero()
    if e.gdi then
      hit(e.px + e.gdi, e.py, e.gdi)
    else
      use()
    end
  end
  -- acid
  local lim = 512 - acid
  if hero.y > lim then
    if hero.y > lim + 16 then
      hero.vy = hero.vy * (.5)
    end
    hurt_hero()
  end
  -- frame
  if gr then
    e.fr = 28
    if e.di ~= 0 then
      e.fr = e.fr + (wfr % 4)
    end
  else
    e.fr = 30
    if wg then
      e.fr = 45 + e.gdi
    end
  end
end

function use()
  if planks == 0 then
    hero.clack = 32
    sfx(10)
    return
  end
  if gr and look_up then
    planks = planks - (1)
    build_ladder()
  elseif floor_ready then
    planks = planks - (1)
    build_floor()
  end
end

function build_ladder()
  mset(hero.px, hero.py, 0)
  local e = dum(hero)
  e.fr = 0
  spread(e, 27)
end

function build_floor()
  mset(hero.px, hero.py + 1, 0)
  cap = dum(hero)
  cap.fr = 0
  cap.py = cap.py + (1)
  cap.ends = 0
  spread(cap, 7)
  sfx(22)
  hero.y = hero.py * 8
end

function dum(a)
  local b = mke(a.fr, a.x, a.y)
  b.px = a.px
  b.py = a.py
  return b
end

function spread(dm, tp, count)
  count = count or 0
  -- build
  local x = dm.px
  local y = dm.py
  kl(dm)
  if mcol(x, y) then
    if cap then
      cap.ends = cap.ends + (1)
      if cap.ends == 2 then
        diam_floor()
      end
    end
    return
  end
  local cur = mget(x, y)
  if cur == tp or cur == 27 then
    return
  end
  mset(x, y, tp)
  -- spread floor 
  if tp == 7 then
    sfx(2, -1, 2, 3)
    for i = -1, 1, 2 do
      local a = dum(dm)
      a.px = a.px + (i)
      local k = a.px >= 0 and a.px < 16
      local f = function()
        if k then
          spread(a, tp, count + 1)
        else
          sfx(10)
          rot(a, tp)
        end
      end
      wait(4, f)
    end
  elseif tp == 27 then
    sfx(2, -1, 2, 3)
    -- spawn diams
    if count > 2 then
      for i = -1, 1, 2 do
        if not mcol(x + i, y) and mcol(x + i, y + 1) then
          sfx(9, -1, 8, 15)
          make_item_at(55, x + i, y)
          return
        end
      end
    end
    -- again
    local a = dum(dm)
    a.py = a.py - (1)
    local f = function()
      if a.py >= 0 and count < 10 then
        spread(a, tp, count + 1)
      else
        sfx(10)
        rot(a, tp)
      end
    end
    wait(4, f)
  end
end

function diam_floor()
  local a = {}
  for k = 0, 8 do
    for i = -1, k == 0 and -1 or 1, 2 do
      local px = cap.px + i * k
      local py = cap.py - 1
      if not mcol(px, py) and mcol(px, py + 1, 1) then
        add(a, {x = px, y = py})
      end
    end
  end
  if #a < 5 then
    return
  end
  sfx(9, -1, 0, 7)
  for p in all(a) do
    make_item_at(55, p.x, p.y)
  end
end

function make_item_at(it, px, py)
  local e = mke(it, px * 8, py * 8)
  morph_item(e)
end

function rot(dm, tp)
  local x = dm.px
  local y = dm.py
  kl(dm)
  mset(x, y, 0)
  local e = mke(8 + rand(2), x * 8, y * 8)
  e.we = .1 + rnd(.2)
  e.vy = -rnd()
  e.vx = 1 - rnd(2)
  e.life = 16
  for i = 0, 3 do
    local dx = dr[i * 2 + 1]
    local dy = dr[i * 2 + 2]
    if mget(x + dx, y + dy) == tp then
      local a = dum(dm)
      a.px = a.px + (dx)
      a.py = a.py + (dy)
      wait(4, rot, a, tp)
    end
  end
--[[
 for i=-1,1,2 do
  if mget(x+i,y)==tp then
   local a=dum(dm)
   a.px+=i
   wait(4,rot,a,tp)
  end
 end
 --]]
end

function pcol(x, y)
  return mcol(x / 8, y / 8)
end

function hpcol(x, y)
  return mcol(x / 8, y / 8) or (hero.eq and mcol(x / 8, y / 8, 1))
end

function eqcol(x, y, i)
  return fget(mget(x / 8, y / 8), 1)
end

function mke(fr, x, y)
  local e = {fr = fr, x = x, y = y, vx = 0, vy = 0, ww = 8, hh = 8, drx = 0, dry = 0, flp = false, t = 0}
  add(ents, e)
  return e
end

function wait(t, f, a, b, c, d)
  local e = mke(0, 0, 0)
  e.life = t
  e.nxt = function()
    f(a, b, c, d)
  end
end

function sg(n)
  return n == 0 and 0 or sgn(n)
end

function upe(e)
  e.t = e.t + (1)
  if e.upd then
    e.upd(e)
  end
  -- phys
  if e.we then
    e.vy = e.vy + (e.we)
  end
  if e.frict then
    e.vx = e.vx * (e.frict)
    e.vy = e.vy * (e.frict)
  end
  -- col
  local vx = e.vx
  local vy = e.vy
  if e.cwj then
    local c = e.cwj / 16
    vx = e.fvx * c + vx * (1 - c)
  end
  if e.phys then
    pmov(e, vx, vy)
  else
    e.x = e.x + (vx)
    e.y = e.y + (vy)
  end
  -- monsters
  if e.mons then
    if ecole(e, hero, 8) then
      if hero.y < e.y and hero.vy > 0 then
        splash(e)
        hero.vy = -4
        return
      else
        hurt_hero()
      end
    end
  end
  -- blocks
  if e.gr then
    mvs = e.mvs
    --if btn(3) then mvs=32 end
    if look_up then
      mvs = .5
    end
    e.mv = e.mv + (mvs)
    while e.mv > 8 and not e.dead do
      e.mv = e.mv - (8)
      push(e, e.mdx, e.mdy, e.mvs)
    end
    for b in all(e.gr) do
      b.x = b.px * 8 + (e.mv - 8) * e.mdx
      b.y = b.py * 8 + (e.mv - 8) * e.mdy
      sbl = b
      while ecol(hero, 0, 0, sbl_col) do
        local dx = sg(e.mdx)
        local dy = sg(e.mdy)
        fset(7, 0, true)
        if ecol(hero, dx, dy) then
          hurt_hero()
          destroy_block(e.gr)
          fset(7, 0, false)
          return
        else
          hero.x = hero.x + (dx)
          hero.y = hero.y + (dy)
        end
        fset(7, 0, false)
      end
    end
  end
  -- hcol
  if e.hcol then
    if ecole(e, hero, 8) then
      e.hcol()
    end
  end
  -- mcol
  if e.mcol then
    for m in all(monsters) do
      if ecole(e, m, 8) then
        e.mcol(m)
      end
    end
  end
  -- splashable
  if e.splashable and ecol(e, 0, 0, blocks_col) then
    stick(e)
    return
  end
  -- counters
  for v, n in pairs(e) do
    if sub(v, 1, 1) == "c" then
      n = n - (1)
      e[v] = n > 0 and n or nil
    end
  end
  --  tweens
  if e.twc then
    local c = min(e.twc + 1 / e.tws, 1)
    cc = e.twcv and e.twcv(c) or c
    e.x = e.sx + (e.ex - e.sx) * cc
    e.y = e.sy + (e.ey - e.sy) * cc
    if e.jmp then
      e.y = e.y + (sin(c / 2) * e.jmp)
    end
    e.twc = c
    if c == 1 then
      e.twc = nil
      e.jmp = nil
      e.twcv = nil
      local f = e.twf
      if f then
        e.twf = nil
        f()
      end
    end
  end
  -- dissolve
  if e.y > 512 + 8 - acid and not e.resist_acid then
    kl(e)
    for i = 0, 2 do
      local p = mke(56 + i, e.x + rand(8), e.y + rand(8))
      p.resist_acid = true
      p.vy = e.vy
      p.vx = rnd(4) - 2
      p.frict = .9
      p.life = 10 + rand(100)
      p.we = -rnd(.5)
      p.upd = function()
        if p.y < 512 - acid - 2 then
          p.y = 512 - acid - 2
        end
      end
    end
  end
  -- life
  if e.life then
    e.life = e.life - (1)
    if e.life <= 0 then
      kl(e)
    end
  end
end

function stick(e)
  kl(e)
  lsfx(19, e)
  local b = nil
  for bl in all(blocks) do
    sbl = bl
    if ecol(e, 0, 0, sbl_col) then
      b = bl
    end
  end
  b.ghl = e
  b.ghx = e.x - b.x
  b.ghy = e.y - b.y
end

function ecole(a, b, ma)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return abs(dx) < ma and abs(dy) < ma
end

function hurt_hero()
  if gmo or hero.churt then
    return
  end
  --frz=16
  hero.churt = 40
  sfx(6)
  hp = hp - (1)
  if hp == 0 then
    game_over()
  end
end

function game_over()
  music(-1)
  hero.vx = 0
  hero.vy = 0
  wait(24, hexp)
  del(ents, hero)
  add(ents, hero)
  gmo = mke(0, 0, 0)
  gmo.dr = dr_gmo
end

function dr_gmo(e)
  if e.t < 24 then
    return
  end
  local t = e.t - 24
  camera()
  if gmo.diams then
    dt = dt + (1)
    local ma = 16
    local a = {0, 7, 0}
    for i = 1, 3 do
      rectfill(ma, ma, 127 - ma, 127 - ma, a[i])
      ma = ma + (1)
    end
    fcl = 9
    if gmo.hh > 0 then
      sfx(23)
      gmo.hh = gmo.hh - (1)
      gmo.score = gmo.score + (10)
    elseif gmo.diams > 0 then
      sfx(24)
      gmo.diams = gmo.diams - (1)
      gmo.score = gmo.score + (5)
    elseif gmo.planks > 0 then
      sfx(25)
      gmo.planks = gmo.planks - (1)
      gmo.score = gmo.score + (1)
    else
      fcl = 8 + _t % 8
    end

    function feat(a, b, c, y)
      sb = b .. ""
      print(a, 28, y, b == 0 and 1 or fcl)
      print(b, 92 - #sb * 4, y, b == 0 and 1 or 7)
      if c then
        print("x" .. c, 96, y, b == 0 and 1 or 13)
      end
    end

    feat("height", gmo.hh, 10, 32)
    feat("gems", gmo.diams, 5, 42)
    feat("planks", gmo.planks, 1, 52)
    feat("score", gmo.score, n, 80)
    return
  end
  for i = 0, 7 do
    for k = 0, 1 do
      local x = 32 + i * 9
      local y = 40
      local z = 1
      local c = max(1 - t / 40, 0)
      c = c * c
      local an = i / 7 + c
      z = 2.5 + cos(t / 40 + i / 7)
      x = x + (cos(an) * sin(c * .5) * 128)
      y = y + (sin(an) * sin(c * .5) * 128)
      local bx = 64 + cos(i / 7) * 48
      local by = 64 + sin(i / 7) * 48
      x = x + ((bx - x) * c)
      y = y + ((by - y) * c)
      if k == 0 then
        apal(1)
        x = x + (z)
        y = y + (z)
      else
        y = y - (z)
      end
      sspr(18 + i * 7, 40, 7, 8, x, y)
      pal()
    end
  end
  camera(cmx, cy)
end

function count_score()
end

function hexp()
  kl(hero)
  sfx(11)
  for i = 0, 8 do
    local p = mke(96, hero.x, hero.y)
    impulse(p, i / 8, 5)
    p.life = 32
    p.frict = .92
    p.cshk = 16
  end
  hero.chxp = 20
end

function destroy_block(gr)
  for e in all(gr) do
    msetf(e.px, e.py, 0)
    kl(e)
    fx_stone(e.px, e.py)
  end
end

function apal(n)
  for i = 0, 15 do
    pal(i, n)
  end
end

function mk_flyer()
  local e = mke(0, -128, hero.py * 8 - 16)
  morph_mon(e)
  e.nxt = function()
    wait(500, mk_flyer)
  end
  e.upd = function(e)
    if ecol(e) then
      splash(e)
      return
    end
    if ecol(e, e.vx, 0, f) then
      e.vx = -e.vx
    end
    local vx = e.x - cmx
    if vx < -32 or vx > 160 then
      local minx = min(-32, cmx - 32)
      local maxx = max(160, cmx + 160)
      --e.x=rand(2)*144-16
      e.x = minx + rand(2) * (maxx - minx)
      --e.y=(hero.py+rand(5)-2)*8
      e.y = (hero.py - 1 - rand(5)) * 8
      e.vx = sgn(64 - e.x) * 1
    --.5   
    end
  end
  e.dr = function(e)
    e.flp = e.vx < 0
    local y = e.y + cos(t / 40) * 2
    for i = 0, 1 do
      local x = e.x + i * 6 * (e.flp and 1 or -1)
      local fl = e.flp
      if i == 0 then
        fl = not fl
        apal(4)
      end
      spr(36 + cmod(16) * 6, x, y, 1, 1, fl)
      pal()
    end
    spr(35, e.x, y, 1, 1, e.flp)
  end
end

function lsfx(k, e)
  local ma = 16
  local x = e.x + e.ww / 2 - cmx
  local y = e.y + e.hh / 2 - cy
  if x >= -ma and y >= -ma and x < 128 + ma and y < 128 + ma then
    sfx(k)
  end
end

function splash(e)
  kl(e)
  lsfx(8, e)
  for i = 0, 3 do
    mke(21, e.x + rand(8) - 4, e.y + rand(8) - 4, 1, 1, rand(2) == 0, rand(2) == 0)
  end
end

function cmod(k)
  return (t / k) % 1
end

function kl(e)
  e.dead = true
  del(ents, e)
  del(monsters, e)
  del(blocks, e)
  if e.item then
    make_item_at(e.item, flr(e.x / 8), flr(e.y / 8))
  end
  if e.nxt then
    e.nxt(e)
    e.nxt = nil
  end
end

function dre(e)
  local fr = e.fr
  local x = e.x + e.drx
  local y = e.y + e.dry
  -- block slide
  --[[
 local l=e.lead
 if l then
  x=e.px*8+(l.mv-8)*l.mdx
  y=e.py*8+(l.mv-8)*l.mdy
 end
 --]]
  --
  local shk = e.cshk
  if shk then
    shk = shk / (4)
    x = x + (rand(shk * 2) - shk)
    y = y + (rand(shk * 2) - shk)
  end
  -- walk
  if e.wlk then
    fr = fr + (e.x / 4) % 2
  end
  -- float
  if e.float then
    y = y + (cos(e.t / 40) * e.float - .5)
  end
  -- jump
  if fget(fr, 0) then
    y = y - (1)
  end
  -- anim
  if fget(fr, 3) and t % 2 == 0 then
    fr = fr + 1
    e.fr = e.fr + 1
    if not fget(fr, 3) then
      kl(e)
      return
    end
  end
  -- pal
  if e.churt and _t % 8 < 4 then
    apal(8)
  end
  -- draw
  if fr > 0 then
    spr(fr, x, y, 1, 1, e.flp)
  end
  -- head
  if e.head and e.py then
    local dy = mcol(e.px, e.py - 1) and 2 or 0
    local hfr = e.head + e.di
    --if not e.eq then hfr=15 end
    if look_up then
      hfr = 15
    end
    if lad then
      hfr = 47
    end
    spr(hfr, x, y + dy - 3)
  end
  --
  if e.item then
    spr(e.item, x, y - 4)
  end
  -- specific
  if e.dr then
    e.dr(e)
  end
  -- reset pal
  pal()
  -- child
  local c = e.ghl
  if c then
    c.x = e.x + e.ghx
    c.y = e.y + e.ghy
    dre(c)
  end
end

function upd_game()
  -- acid
  if acid < bsc * 8 then
    acid = acid + ((bsc * 8 - acid) * .1)
  end
  if t % 4 == 0 and acid < 128 then
    acid = acid + (1)
  end
  -- spawn monster
  if t % 4000 == 10 then
    mk_flyer()
  end
  -- ents
  foreach(ents, upe)
  local y = seek_height()
  if y < 16 then
    --or btnp(5)
    --log("scroll_map"..(t%1000))
    scroll_map()
  end
  -- check block
  if #blocks < 4 and not hero.cblk and not gmo then
    pop_block()
    hero.cblk = 20
  end
  -- 
  if gmo and gmo.t > 40 and both() then
    if gmo.diams then
      reload()
      init_menu()
    else
      dt = 0
      gmo.hh = flr(toth + 64 - seek_height() - 16)
      gmo.diams = diams
      gmo.score = 0
      gmo.planks = planks
      gmo.diams = gmo.diams + (8 + rand(32))
      gmo.hh = gmo.hh + (16 + rand(32))
    end
  end
end

function _update()
  _t = _t + (1)
  -- freze
  if frz then
    frz = frz - (1)
    if frz <= 0 then
      frz = nil
    end
    return
  end
  -- builder
  --[[
 if builder then
  builder=btn(5)
  
  if btnp(2) then
   build_ladder()
  end
  
  return
 end
 --]]
  t = t + (1)
  main_upd()
end

function scroll_map()
  toth = toth + (bsc)
  curh = curh + (bsc)
  local dd = bsc * 8
  cy = cy + (dd)
  acid = acid - (dd)
  for e in all(ents) do
    e.y = e.y + (dd)
    if e.py then
      e.py = e.py + (bsc)
    end
    if e.tws then
      e.sx = e.sx + (dd)
      e.sy = e.sy + (dd)
      e.ex = e.ex + (dd)
      e.ey = e.ey + (dd)
    end
  end
  for y = 63, 0, -1 do
    for x = 0, 15 do
      local tl = mget(x, y - bsc)
      mset(x, y, tl)
    end
  end
end

function dr_game()
  -- camera
  if not cy then
    cy = hero.y - 64
  end
  local tcy = min(hero.y - 64, 512 - 128)
  cy = cy + ((tcy - cy) * .2)
  cmx = hero.x - 64
  camera(cmx, cy)
  -- line
  local y = seek_height()
  curh = curh + ((y - curh) * .25)
  local str = flr(toth + 64 - curh - 16)
  local h = curh * 8
  line(cmx, h, 127 + cmx, h, 1)
  print(str .. " meters", cmx, h - 6)
  -- main
  map(0, 0, 0, 0, 16, 64)
  foreach(ents, dre)
  -- target
  trg = nil
  if hero.gdi then
    local px = hero.px + hero.gdi
    if mcol(px, hero.py) then
      trg = 0
      if not mcol(px + hero.gdi, hero.py) then
        trg = 1
      end
      spr(112, px * 8, hero.py * 8)
    end
  end
  -- acid
  for ay = 0, acid do
    local y = 512 + ay - acid
    --local c=
    --local y=512+(ay/40-1)*acid 
    if y > cy + 130 then
      break
    end
    local pw = ay / 10
    local dx = cos(y / 40 + t / 100) * pw
    local k = {1, 3, 3, 3, 3, 3, 10, 10, 11, 11, 10, 11, 11, 11, 11, 10}
    for px = 0, 127 do
      --[[
   local x=px+cmx
   local c=pget(x+dx,y)
   local cx=ay==0 and 4 or 0
   c=sget(cx+c%4,1+c/4)
   --]]
      local x = px + cmx
      local c = k[pget(x + dx, y) + 1]
      pset(x, y - 1, c)
    end
  end
  -- inter
  camera()

  function print_score(x, n, fr)
    local s = n .. "x"
    print(s, x - #s * 4, 2, 7)
    spr(fr, x, 0)
  end

  print_score(120, diams, 55)
  if hero.clack and t % 4 < 2 then
    apal(8)
  end
  print_score(96, planks, 59)
  pal()
  -- life
  for i = 0, hpmax - 1 do
    local x = i < hp and 0 or 9
    sspr(x, 40, 9, 8, 16 + i * 10, 0)
  end
  -- tool
  rectfill(0, 0, 15, 14, 0)
  rect(1, 1, 13, 12, 7)
  fr = nil
  if trg then
    fr = 103 + trg
  elseif ladder_ready then
    fr = 105
  elseif floor_ready then
    fr = 7
  end
  if fr then
    spr(fr, 3, 3)
  end
  print("\xf0\x9f\x98\x90", 4, 14, 1)
  print("5", 4, 14, 7)
end

function _draw()
  cls(bg_col)
  --
  main_dr()
  -- log
  color(7)
  cursor(0, 0)
  for str in all(logs) do
    print(str)
  end
end

function log(str)
  add(logs, str)
  while #logs > 20 do
    del(logs, logs[1])
  end
end


__gfx__
77a942116d66d6d5bbb3bbb3d66666d5611d66d50000000011111110fffffff4ffff00000000fffffffffff4fffffff400000000000000000000000000000000
13333bbbd55555553b323b32ddddddd1d6ddddd10000000011111110f4444442f4444fffffff4442f4444442f4444442000ddf00f0dddd0f00fdd00000dddd00
33aabb77d556d5d543224322ddddddd1ddd11dd10000000011111110f4444442f4444442f4444442f4444442f444444200ddffd0fdd6dddf0dffdd000d1ff1d0
bbabba7a655d555544244424511111115111111100011000000000004222222242224442f444222242222222422222220dddf4d04fddddf40d4fddd00f1ff1f0
bbbaaaa7655555559444444466d5d66666d5d1d6000110001110111100011000000042222222000000111000000111000f1ff410141ff1410111f1f04ffffff4
00000000d5d5555544424944ddd1ddddddd1dd1d00000000111011111112201000000000000000000222001011002220ff1f11111f1ff1f10111f1ff1ffffff1
000000006555555542224442ddd1ddddddd1ddd1000000001110111111100010000000000000000044200110111002440fff111111ffff111111fff011ffff11
00000000555555554422242211115111111151110000000000000000000000000000000000000000440000000000004400000111000000001110000000000000
4422249400000000000000000000000000000000000000000000000000000000000000000000000000000000f40000f400000000000000000000000000000000
4249444400000000000000000000000000000000000000000000088000800008008000000000000000000000f42444f400000000000000000000000000000000
424442420d666dd0000d66d00000000000000000000088000088080000880000000000000000000000000000f40000f400055000000550000005500000055000
444422240ddddd1000dddd1000d6d10000000610008888000088000000000000000000000000000000000000f42444f400335500003355000033550000335500
9442224401ddd10000ddd10000ddd1000000d6d1088880008000000000000000000000000000000000000000f40000f403335550f3335554f3335554f3335554
44424944000000000000000000dd10000000dd11008880000008800000000000000000000000000000000000f42444f4f0335504003355000033550000335500
4222444200000000000000000000000000001110000000000000800000008800000000000000000000000000f40000f400335500003355500533555005335500
4422242200000000000000000000000000000000000000000000000000000000000008000000000000000000f42444f400500500050000000000000000000050
00000001001000011010101000000000009999000000000000000000000000000000000009999000666666650000000000000000000000000000000000000000
0000101d1141001200000000009999000099999000000000000000000000000000000000099999006666665100000000000000000005500000000000f0dddd0f
001151d62493112e01010101099977900000099090000000000000000000000000000000000999906655551100000000455000000033550000000554fdd6dddf
0123456789abcdef000000000997777000000099999999990000009900000099000999990000099966555511000000000055500000335500000555004dddddd4
138b9d77ea7a6ef710101010099775700000009909999999000009990000009909999999000000996655551100000000f333550000f354000033333f11dddd11
3beaa677f7777f770000000009947740000000000000000000009999000009999990000000000000665555110000000000555500005355000033550011111111
baf77777777777770101010100994400000000000000000009999990000999909000000000000000651111110000000003335500005005000033555011111111
a7777777777777770000000000000000000000000000000009999000099999000000000000000000511111110000000033355000000505000003355501111110
00cccc0000cccc0000000000000000000000000000000000000000000000000000000000000000000000000004444000d66666d5000000000000000000000000
000ccc60000cccc0000000000000000003000b0003000b00000000000077cc0000000000000770000000000004444240dd1111d1000000000000000000000000
000066660000cccc0000000000000000033bbbb0033bbbb0000000000777c7c00007700000700700000000000444424011d66d11000000000000000000000000
000066770000cccc00000000000000000337bb703b37bb7b0000000077777ccc0070070007070070000770000444424066611666000000000000000000000000
000077770000cccc00000ccc0000000005545b403b545b4b00000000ccc711cc00700700070000700007700004444240677dd776000000000000000000000000
000000000000cc660000cccc000000003b54454b05544540000000000c1c1cc000077000007007000000000004444240d677776d000000000000000000000000
00000000000c6660000cccc0000000003b55555b0555555b0000000000cc1c0000000000000770000000000002222240dd6666dd000000000000000000000000
00000000007777000077770000cccc00030000b03300000000000000000cc0000000000000000000000000000002222011115111000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000011111110000000001111111000000000000000000000000000000000
0077cc000077bb00007799000077880000000000000000000000000000000000000000001111111000000000111111100d555000000000000000000000007070
0777c7c00777b7b007779790077787800000000000000000000000000000000000000000111111100000000011111110d55555000d5555000000000000009090
77777ccc77777bbb7777799977777888000000000000000000000000000000000000000000000000000000000000000055d55550d55555500000000000009090
ccc711ccbbb733bb999744998887228800000000000000000000000000000000000011111110000011101111111011115d55555555d555500000000000009490
0c1c1cc00b3b3bb009494990082828800000000000000000000000000000000000001111111000001110111111101111555511155d5511100009999999999990
00cc1c0000bb3b000099490000882800000000000000000000000000000000000000111111100000111011111110111155511115555111100999999999999990
000cc000000bb0000009900000088000000000000000000000000000000000000000000000000000000000000000000005511110555111109999999999999900
00770770000770770007777700777770770007777777770777770770007777777777777770000000000000000000000000000000000000000000000000000000
07887887007007007077000777700077770007777000007700077770007777000007700077000000000000000000000000000000000000000000000000000000
78e88e82d7001101177700077770007777707777700000770007777000777700000770007700000000000000000000000000000000000000000000000d555707
78888882d701111117770000077777777707077777700077000770770770777700077777700000000000000000000000000000000000000000000000d5555959
0788882d007111117077007777700077770007777000007700077077077077000007700777000000000000000000000000000000000000000000000055d55959
007882d000071117007700077770007777000777700000770007707707707700000770007700000000000000000000000000000000000000000000005d551949
00072d00000071700077000777700077770007777000007700077007770077000007700077000000000000000000000000000000000000000000000955524999
00007000000007000007777707700077770007777777770777770007770077777777700077000000000000000000000000000000000000000000009955549994
00000000000000000000000000000000442224944422249444222494001141000111110001100011111111110000000000000000000000000000000000000000
00e7ab000000000000000000000000004249444447744444424944440177771001444100014111411ffffff40000000000000000000000000000000000000000
0ef77ab0000eb00000000000000001004244424242177242424442420177777101444100014444411f4444420000000000000000000000000000000000000000
0f7777a000e77b00000a7000030001004444222444221124444722240111411101444100014111411f4444420000000000000000000000000000000000000000
077777a000c779000007f00003000110944277249442224427712244000141000199911101444441142222220000000000000000000000000000000000000000
0c777aa0000ca0000000000013101103447712444442492777714944000141000144444101411141111111110000000000000000000000000000000000000000
00c7aa0000000000000000001331113042122442422fff7777174722000141000144444101444441000000000000000000000000000000000000000000000000
000000000000000000000000333113314422242244f1177771117f22000111000111111101411141000000000000000000000000000000000000000000000000
7070707000000000011410000000000000000000227227711722ff24dd000000777d777d000dd77700d000d0000f940000000000000000000000000000000000
000000070000000017777100000000000000000027ffff172247f144777dd000777d777ddd77777700d000d0000f940000000000000000000000000000000000
70000000000000001777771000055000000000002711ff11424ff242777777dd77707770000dd7770070007000071d0000000000000000000000000000000000
00000007000000001114111000335500000000002722ff1244ff1224777dd000d7d0d7d0000000dd0d7d0d7d0071116000000000000000000000000000000000
70000000000000000014100003335550000000002f77f422fff12244dd000000d7d0d7d0000dd7770d7d0d7d072f882600000000000000000000000000000000
000000070000000000141000f03355040000000022ff4ffffff24944777dd00007000700dd77777707770777072f222d00000000000000000000000000000000
7000000000000000001410000033550000000000422f2fffff124442777777dd0d000d00000dd777d777d7770722222d00000000000000000000000000000000
07070707000000000001000000500500000000004422111111222422777dd0000d000d00000000ddd777d777007dddd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
36362020203636363600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20200101202020202020360036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01015666010101010101202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01015767010101460101014601363636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010120202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01460101010101010101460101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101014601010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101460101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000003030000030300000303000003000300034900000000000000000000000048030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003030303030300000303000003030300030600000000000000000000000006030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003000303000303030303030303000300030649000000000000000000484a06030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000030303033b2a2a2a2a03000003000000034900000600000000000000000606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000340003002a3c00000003000003000000030000064900000000000000004806030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003030303030303030303030300003b00030606060600000000000000484a06030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000030606060303060606060603030303030306064a490000000000004a060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003063706030306063706060334373406030600000000000000000048060648030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003030303030306373737060303030303030606000000000000000606063706030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000003030303030303000000000306064a0606064a4a06061b373737030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003060606484806060606061b030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003060606060606060606061b060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003060606060606060606061b060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030606067306064a0606061b060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030707070707070707070707070707030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030606060606060606060606060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030606064806060606060606060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000306060606060606060606064b0606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000003064a060606064806060606060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030606060606060606060606060606030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000030606060606060606060606060648030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
3001010101012002010103030000000001010000000808080800002400010100000030000000000000000100010001000808080800010080000000800100000000000000000000002020202000000000000000000000000000000000000000000000003001010100000002000000000000000000000101404040408000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800003772100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f051130511c6250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000741307605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003747000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000013670136201f6101361007610076100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001f13300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003047037420374203741037410371020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01060000247441f111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002b355302552d155242252d1152d10500000000001f7551f7252b75530755000000000000000000002b475304550000000000000000000000000000000000000000000000000000000000000000000000
010800000445524400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000074731f6651f2231f2131f2031f2030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001a050000001a0001a0501e050000002105000000280500000025000250500000000000210500000023050000000000023050250500000023050000001e050000001f050210501c050000001905000000
01100000170500000011000230002305000000210500000000000210501c050000001e0501f05000000000001a05000000000001c05000000000001e050000001c050000001e0001a05000000000001905000000
01100000170500000017050000001f050000001e05000000170500000017050000001f050000001e05000000170500000017050000001f050000001e05000000170500000017050170001f0501e0500000000000
01100000150500000015050000001e050000001c05000000150500000015050000001e050000001c05000000150500000015050000001e050000001c05000000150500000015050000001e0501c0500000000000
01100000150500000015050000001e050000001c05000000150500000015050000001e050000001c05000000150500000015050000001e050000001c050000001f0500000021050000001f050000001e05000000
011000001e0221e0221e0221e0221e0221e0221e0221e0221a0221a0221a0221a0221f0221f0221f0221f0221e0221e0221e0221e0221e0221e0221e0221e0221a0221a0221a0221a0221a0221a0221a0221a022
011000002157526745215252671521505265050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f55113511000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f6541f655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000717313153000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003765437615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001f05500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001815500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001545500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0c424344
00 0c424344
00 0d424344
02 0d424344
01 0e424344
00 0e114344
00 0f424344
02 10424344
__label__
000000000000000000770770000077077000007707700000d66666d5d66666d5d66666d5d66666d5000000000000000004444000000000000000000000000000
077777777777770007887887000700700700070070070000ddddddd1ddddddd1ddddddd1ddddddd100000000000000000444424000000000000000000077cc00
070000000000070078e88e82d07001101170700110117000ddddddd1ddddddd1ddddddd1ddddddd100000000777070700444424000000000777070700777c7c0
070000000000070078888882d0701111117070111111700051111111511111115111111151111111000000007000707004444240000000007070707077777ccc
07000000000007000788882d00071111170007111117000066d5d66666d5d66666d5d66666d5d6660000000077700700044442400000000070700700ccc711cc
0700000000000700007882d0000071117000007111700000ddd1ddddddd1ddddddd1ddddddd1dddd00000000007070700444424000000000707070700c1c1cc0
070000000000070000072d00000007170000000717000000ddd1ddddddd1ddddddd1ddddddd1dddd000000007770707002222240000000007770707000cc1c00
070000000000070000007000000000700000000070000000111151111111511111115111111151110000000000000000000222200000000000000000000cc000
070000000000070000000000000000000000000000000000d66666d5d66666d5d66666d500000000000000000000000000000000000000000000000000000000
070000000000070000000000000000000000000000000000ddddddd1ddddddd1ddddddd100000000000000000000000000000000000000000000000000000000
070000000000070000000000000000000000000000000000ddddddd1ddddddd1ddddddd100000000000000000000000000000000000000000000000000000000
07000000000007000000000000000000000000000000000051111111511111115111111100000000000000000000000000000000000000000000000000000000
07777777777777000000000000000000000000000000000066d5d66666d5d66666d5d66600000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000ddd1ddddddd1ddddddd1dddd00000000000000000000000000000000000000000000000000000000
000017777710000000000000000000000000000000000000ddd1ddddddd1ddddddd1dddd00000000000000000000000000000000000000000000000000000000
00007717177000000000000000000000000000000000000011115111111151111111511100000000000000000000000000000000000000000000000000000000
00007771777000000000000000000000000000000000000000000000d66666d50000000000000000000000000000000000000000000000000000000000000000
00007707077000000000000000000000000000000000000000000000ddddddd10000000000000000000000000000000000000000000000000000000000000000
00001777771000000000000000000000000000000000000000000000ddddddd10000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000511111110000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000066d5d6660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ddd1dddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ddd1dddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000111151110000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1000000000000000000000000000000000000000000000000
00000000000000000000000051111111511111115111111151111111511111115111111151111111000000000000000000000000000000000000000000000000
00000000000000000000000066d5d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5d666000000000000000000000000000000000000000000000000
000000000000000000000000ddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1dddd000000000000000000000000000000000000000000000000
000000000000000000000000ddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1dddd000000000000000000000000000000000000000000000000
00000000000000000000000011115111111151111111511111115111111151111111511111115111000000000000000000000000000000000000000000000000
000000000000000000000000d66666d51111111011111110111111101111111011111110d66666d5000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd11111111011111110111111101111111011111110ddddddd1000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd11111111011111110111111101111111011111110ddddddd1000000000000000000000000000000000000000000000000
00000000000000000000000051111111000000000000000000000000000000000000000051111111000000000000000000000000000000000000000000000000
00000000000000000000000066d5d666111011111110111111101111111011111110111166d5d666000000000000000000000000000000000000000000000000
000000000000000000000000ddd1dddd1110111111101111111011111110111111101111ddd1dddd000000000000000000000000000000000000000000000000
000000000000000000000000ddd1dddd1110111111101111111f94111110111111101111ddd1dddd000000000000000000000000000000000000000000000000
000000000000000000000000111151110000000000000000000f9400000000000000000011115111000000000000000000000000000000000000000000000000
000000000000000000000000d66666d5111111101111111011171d101111111011111110d66666d5000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd11111111011111110117111601111111011111110ddddddd1000000000000000000000000000000000000000000000000
000000000000000000000000ddddddd11111111011111110172f88261111111011111110ddddddd1000000000000000000000000000000000000000000000000
000000000000000000000000511111110000000000000000072f222d000000000000000051111111000000000000000000000000000000000000000000000000
00000000000000000000000066d5d66611101111111011111722222d111011111110111166d5d666000000000000000000000000000000000000000000000000
000000000000000000000000ddd1dddd1110111111101111117dddd11110111111101111ddd1dddd000000000000000000000000000000000000000000000000
000000000000000000000000ddd1dddd1110111111101111111011111110111111101111ddd1dddd000000000000000000000000000000000000000000000000
00000000000000000000000011115111000000000000000000000000000000000000000011115111000000000000000000000000000000000000000000000000
00000000000000000000000011111110111111101111111011111110111111101111111011111110000000000000000000000000000000000000000000000000
0000000000000000000000001111111011111b101311111011111110111111101111111011111110000000000000000000000000000000000000000000000000
000000000000000000000000111111101111bbbb3311111011111110111111101111111011111110000000000000000000000000000000000000000000000000
0000000000000000000000000000000000007bb73300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000f94001110111111104b545510111111101111111011111110111111101111000000000000000000000000000000000000000000000000
0000000000000000000f940011101111111b45445b30111111101111111011111110111111101111000000000000000000000000000000000000000000000000
000000000000000000071d0011101111111b55555b30111111101111111011111110111111101111000000000000000000000000000000000000000000000000
000000000000000000711160000000000000b0000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000072f8826d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5000000000000000000000000d66666d50000000000000000
0000000000000000072f222dddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1000000000000000000000000ddddddd10000000000000000
00000000000000000722222dddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1000000000000000000000000ddddddd10000000000000000
0000000000000000077dddd051111111511111115111111151111111511111115111111151111111000000000000000000000000511111110000000000000000
000000000000000004b5455066d5d66666d5d66666d5d66666d5d66666d5d66666d5d66666d5d66600000000000000000000000066d5d6660000000000000000
0000000000000000b45445b3ddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1dddd000000000000000000000000ddd1dddd0000000000000000
0000000000000000b55555b3ddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1ddddddd1dddd000000000000000000000000ddd1dddd0000000000000000
00000000000000000b00003011115111111151111111511111115111111151111111511111115111000000000000000000000000111151110000000000000000
0000000000000000bbb3bbb3bbb3bbb3bbb3bbb300000000000000000000000f0dddd0f0000000000000000000000000d66666d5d66666d50000000000000000
00000000000000003b323b323b323b323b323b3200000000000000000000000fdd6dddf0000000000000000000000000ddddddd1ddddddd10000000000000000
0000010000000100432243224322432243224322000000000000000000000004fddddf40000000000000000000000000ddddddd1ddddddd10000000000000000
030001000300010044244424442444244424442400000000000000000000000141ff141000000000000000000000000051111111511111110000000000000000
0300011003000110944444449444444494444444000000000000000000000001f1ff1f1000000000000000000000000066d5d66666d5d6660000000000000000
13101103131011034442494444424944444249440000000000000000000000011ffff110000000000000000000000000ddd1ddddddd1dddd0000000000000000
133111301331113042224442422244424222444200000000000000000000000003355000000000000000000000000000ddd1ddddddd1dddd0000000000000000
33311331333113314422242244222422442224220000000000000000000000000500500000000000000000000000000011115111111151110000000000000000
bbb3bbb3bbb3bbb34422249444222494bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb30000000000000000d66666d5000000000000000000000000
3b323b323b323b3242494444424944443b323b323b323b323b323b323b323b323b323b323b323b320000000000000000ddddddd1000000000000000000000000
432243224322432242444242424442424322432243224322432243224322432243224322432243220000000000000000ddddddd1000000000000000000000000
44244424442444244444222444442224442444244424442444244424442444244424442444244424000000000000000051111111000000000000000000000000
94444444944444449442224494422244944444449444444494444444944444449444444494444444000000000000000066d5d666000000000000000000000000
444249444442494444424944444249444442494444424944444249444442494444424944444249440000000000000000ddd1dddd000000000000000000000000
422244424222444242224442422244424222444242224442422244424222444242224442422244420000000000000000ddd1dddd000000000000000000000000
44222422442224224422242244222422442224224422242244222422442224224422242244222422000000000000000011115111000000000000000000000000
44222494442224944422249444222494442224944422249444222494442224944422249444222494bbb3bbb3bbb3bbb3bbb3bbb3000000000000000000000000
424944444249444447744444424944444249444442494444424944444249444442494444424944443b323b323b323b323b323b32000000000000000000000000
42444242424442424217724242444242424442424244424242444242424442424244424242444242432243224322432243224322000000000000000000000000
44442224444422244422112444472224444422244444222444442224444422244444222444442224442444244424442444244424000000000000000000000000
94422244944222449442224427712244944222449442224494422244944222449442224494422244944444449444444494444444000000000000000000000000
44424944444249444442492777714944444249444442494444424944444249444442494444424944444249444442494444424944000000000000000000000000
4222444242224442422fff7777174722422244424222444242224442422244424222444242224442422244424222444242224442000000000000000000000000
442224224422242244f1177771117f22442224224422242244222422442224224422242244222422442224224422242244222422000000000000000000000000
4422249444222494227227711722ff24442224944422249444222494442224944422249444222494442224944422249444222494000000000000000000000000
424944444249444427ffff172247f144424944444249444442494444424944444249444442494444424944444249444442494444000000000000000000000000
42444242424442422711ff11424ff242424442424244424242444242424442424244424242444242424442424244424242444242000000000000010000000100
44442224444422242722ff1244ff1224444422244444222444442224444422244444222444442224444422244444222444442224000000000300010003000100
94422244944222442f77f422fff12244944222449442224494422244944277249442224494422244944222449442772494422244000000000300011003000110
444249444442494422ff4ffffff24944444249444442494444424944447712444442494444424944444249444477124444424944000000001310110313101103
4222444242224442422f2fffff124442422244424222444242224442421224424222444242224442422244424212244242224442000000001331113013311130
44222422442224224422111111222422442224224422242244222422442224224422242244222422442224224422242244222422000000003331133133311331
442224944422249444222494442224944422249444222494442224944422249444222494442224944422249444222494bbb3bbb3bbb3bbb3bbb3bbb3bbb3bbb3
4249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944443b323b323b323b323b323b323b323b32
42444242424442424244424242444242424442424244424242444242424442424244424242444242424442424244424243224322432243224322432243224322
44442224444422244444222444442224444422244444222444442224444422244444222444442224444422244444222444244424442444244424442444244424
94422244944222449442224494422244944222449442224494422244944222449442224494422244944222449442224494444444944444449444444494444444
44424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944
42224442422244424222444242224442422244424222444242224442422244424222444242224442422244424222444242224442422244424222444242224442
44222422442224224422242244222422442224224422242244222422442224224422242244222422442224224422242244222422442224224422242244222422
44222494442224944422249444222494442224944422249444222494442224944422249444222494442224944422249444222494442224944422249444222494
42494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444
42444242424442424244424242444242424442424244424242444242424442424244424242444242424442424244424242444242424442424244424242444242
44442224444422244444222444442224444422244444222444442224444422244444222444442224444422244444222444442224444422244444222444442224
94422244944222449442224494422244944222449442224494422244944222449442224494422244944222449442224494422244944222449442224494422244
44424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944
42224442422244424222444242224442422244424222444242224442422244424222444242224442422244424222444242224442422244424222444242224442
44222422442224224422242244222422442224224422242244222422442224224422242244222422442224224422242244222422442224224422242244222422
44222494442224944422249444222494442224944422249444222494442224944422249444222494442224944422249444222494442224944422249444222494
42494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444424944444249444442494444
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
1b3333333b333aa33b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333aa33b3333333b3333333b3333333b3333333b333333
133333b3333aa333333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333aa333333333b3333333b3333333b3333333b3333333b3
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
1333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b
1333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
1b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b333333
133333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3333333b3
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
13333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
