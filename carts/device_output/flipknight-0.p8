pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

--Flip Knight
--by st33d
--globals
--flags
f_player = shl(1, 0)
--us
f_wall = shl(1, 1)
--hard surface
f_trap = shl(1, 2)
--area we scan for ids
f_up = shl(1, 3)
--hard surface only when going down
f_down = shl(1, 4)
--hard surface only when going up
f_crate = shl(1, 5)
--pushable box, causes bugs
f_enemy = shl(1, 6)
--baddies
--pico 8 doesn't use flags this high, so it works for out-of-bounds
f_outside = shl(1, 8)
f_out = f_outside
the_end_y = -256

function boring(...)
  local args, n = {...}, 0
  for f in all(args) do
    n = bor(n, f)
  end
  return n
end

f_char_thru = boring(f_player, f_enemy, f_trap, f_up, f_down)
f_down_thru = boring(f_player, f_enemy, f_trap, f_down)
f_up_thru = boring(f_player, f_enemy, f_trap, f_up)
--physical objects
blox = {}
--physics list
spawned = {}
--new objects
graveyard = {}
--waiting to be reanimated
dropdamp = 0.98
--default falling friction
grav = 0.37
--set g on a blok to simulate gravity
gravdir = 1
--current gravity direction
minmove = 0.1
--avoid micro-sliding, floating point error can lead to phasing
speedlimit = 8
--arcade gravity
stars = {}
--heat map to push the chasers apart
enemyhot = {}
hotdelay = 10
us = nil
--the player
them = {}
--enemies
fx = {}
--add to print out debug
debug = {}
-- prev room offset, used only when wrapping the map
prevroomx, prevroomy = 0, 0
-- the coordinates of the upper left corner of the camera
cam_x, cam_y = 0, 0
frames = 0
-- screen shake offset
shkx, shky = 0, 0
-- screen shake speed
shkdelay, shkxt, shkyt = 2, 2, 2
-- CLASSES
-- based on https://github.com/jonstoler/class.lua
-- i removed the getter setters, no idea if that
-- broke it but it seems to still work
classdef = {}

-- default (empty) constructor
function classdef:init(...)
end

-- create a subclass
function classdef:extend(obj)
  local obj = obj or {}

  local function copytable(table, destination)
    local table = table or {}
    local result = destination or {}
    for k, v in pairs(table) do
      if not result[k] then
        if type(v) == "table" and k ~= "__index" and k ~= "__newindex" then
          result[k] = copytable(v)
        else
          result[k] = v
        end
      end
    end
    return result
  end

  copytable(self, obj)
  obj._ = obj._ or {}
  local mt = {}
  -- create new objects directly, like o = object()
  mt.__call = function(self, ...)
    return self:new(...)
  end
  setmetatable(obj, mt)
  return obj
end

-- create an instance of an object with constructor parameters
function classdef:new(...)
  local obj = self:extend({})
  if obj.init then
    obj:init(...)
  end
  return obj
end

function class(attr)
  attr = attr or {}
  return classdef:extend(attr)
end

-- Utilities
-- for when you need to send a list of stuff to print
function joinstr(...)
  local args = {...}
  local s = ""
  for i in all(args) do
    if type(i) == "boolean" then
      i = i and "true" or "false"
    end
    if s == "" then
      s = i
    else
      s = s .. "," .. i
    end
  end
  return s
end

--print to debug
function debugp(...)
  add(debug, joinstr(...))
end

-- method is a function(c,r)
function forinrect(x, y, w, h, method)
  for c = x, (x + w) - 1 do
    for r = y, (y + h) - 1 do
      method(c, r)
    end
  end
end

function allmap(method)
  forinrect(0, 0, 16 * 8, 16 * 4, method)
end

function add2(obj, ...)
  local args = {...}
  for table in all(args) do
    add(table, obj)
  end
end

function pick1(a, b)
  if rnd(2) > 1 then
    return a
  end
  return b
end

--tween a position - used for camera pans
tween = class()

-- sx,sy: start tx,ty:target, method:easing function, delay:total frames
function tween:init(sx, sy, tx, ty, method, delay)
  self.x, self.y, self.sx, self.sy = sx, sy, sx, sy
  self.cx, self.cy, self.method, self.t, self.delay = tx - sx, ty - sy, method, 0, delay
  self.done = false
end

function tween:main()
  self.x, self.y = self.method(self.t, self.sx, self.cx, self.delay), self.method(self.t, self.sy, self.cy, self.delay)
  --add(debug,self.x)
  self.t = self.t + (1)
  if self.t >= self.delay then
    self.done = true
  end
end

--http://gizma.com/easing/
--time,startvalue,change,duration
function ease_linear(t, b, c, d)
  return c * t / d + b
end

function ease_incubic(t, b, c, d)
  t = t / (d)
  return c * t * t * t + b
end

function ease_outcubic(t, b, c, d)
  t = t / (d)
  t = t - (1)
  return c * (t * t * t + 1) + b
end

--map sections (rooms)
rooms = {}

function getroom(c, r)
  --escape
  if r < 0 and rooms[c .. "," .. r] then
    return rooms[c .. "," .. r]
  end
  --wrap
  if c < 0 then
    c = 7
  end
  --we wrap at 8 rooms
  if c > 7 then
    c = 0
  end
  if r < 0 then
    r = 3
  end
  --we wrap at 4 rooms
  if r > 3 then
    r = 0
  end
  local k = c .. "," .. r
  if rooms[k] then
    return rooms[k]
  end
  return nil
end

currentroom = nil
prevroom = nil

--init----------------------
function _init()
  -- find and spawn player
  local usc, usr = 0, 0

  local function makeus(x, y, force)
    local look = mget(x, y)
    --sword player, nosword, egg
    if look == 1 or look == 4 or look == 54 or look == 98 or force then
      if look == 98 then
        look = 1
        gravdir = -1
      end
      us = player(x, y, look == 4, look == 54)
      mset(x, y, 0)
      usc, usr = flr(x / 16), flr(y / 16)
    end
  end

  allmap(makeus)
  --spawn at the starting room if i left no player on the map
  -- if(not us) makeus(10,36,true)
  add(blox, us)
  --rooms are defined by tile 96, there are 128x64 tiles to search
  local roomfind, roomrpl = 16, 3

  local function makerooms(x, y)
    if (mget(x, y) == roomfind) then
      --got a corner of a room
      local c, r, w, h = flr(x / 16), flr(y / 16), 1, 1
      --get the width, look for next room or end of this one
      for lx = x + 16, x + 128, 16 do
        if mget(lx, y) == roomfind or mget(lx - 1, y) == roomfind then
          break
        end
        w = w + (1)
      end
      --get the height
      for ly = y + 16, y + 64, 16 do
        if mget(x, ly) == roomfind or mget(x, ly - 1) == roomfind then
          break
        end
        h = h + (1)
      end
      room(c, r, w, h)
      --tile roomfind is for me to look at, change the corners to roomrpl
      mset(x, y, roomrpl)
      mset(x + w * 16 - 1, y, roomrpl)
      mset(x + w * 16 - 1, y + h * 16 - 1, roomrpl)
      mset(x, y + h * 16 - 1, roomrpl)
    end
  end

  allmap(makerooms)
  -- set currentroom
  currentroom = getroom(usc, usr)
  cam_x, cam_y = usc * 128, usr * 128
  --currentroom = getroom(0,0)
  currentroom:enter()
  us.coyote = 1
  us:movey(gravdir * 2)
  --exit room
  exitroom = room(3, -10, 1, 10)
end

--update----------------------
function _update()
  --end flight
  if ending and us.y < -4 * 64 then
    us.y = us.y + (128)
    cam_y = cam_y + (128)
  end
  -- clear colision data
  for a in all(blox) do
    a.touchx, a.touchy = nil, nil
  end
  -- simulate
  us:upd()
  --player 1st for feels
  if us.goroom then
    prevroom = currentroom
    prevroom:exit()
    prevroom:movephantoms(prevroomx, prevroomy)
    currentroom = us.goroom
    us.goroom = nil
    if prevroom == currentroom then
      prevroom:resetspawned()
    end
    currentroom:enter()
    camtween = tween(cam_x + (prevroomx * 8), cam_y + (prevroomy * 8), us.goroomc * 128, us.goroomr * 128, ease_linear, 30)
  --cam_go_x,cam_go_y = ship.goroomc*128,ship.goroomr*128
  end
  for a in all(blox) do
    if a ~= us and a.active then
      a:upd()
    end
  end
  -- garbage collect
  local good, i = {}, 1
  for a in all(blox) do
    if a.active then
      good[i] = a
      i = i + (1)
    end
  end
  -- add spawned
  for a in all(spawned) do
    if a.active then
      good[i] = a
      i = i + (1)
    end
  end
  blox, spawned = good, {}
  frames = frames + (1)
end

--draw----------------------
function _draw()
  cls()
  -- update camera position
  if camtween then
    camtween:main()
    cam_x, cam_y = camtween.x, camtween.y
    if camtween.done then
      camtween = nil
      if prevroom then
        if prevroom ~= currentroom then
          prevroom:resetspawned()
        end
        prevroom:clearphantoms()
        prevroom = nil
      end
    end
  else
    local x, y = us:cam()
    local f = 0.5
    local scroll_x, scroll_y = (x - cam_x) * f, (y - cam_y) * f
    cam_x = cam_x + (scroll_x)
    cam_y = cam_y + (scroll_y)
  end
  camera(cam_x + shkx, cam_y + shky)
  if ending then
    drawstars()
    rectfill(cam_x, 0, cam_x + 128, 128, 0)
  end
  -- camera(0,0)
  -- map(0,0,0,0,16,16)
  -- draw room
  currentroom:draw()
  if prevroom then
    prevroom:draw(prevroomx, prevroomy)
  end
  -- draw backfx
  -- backfx = draw_active(backfx)
  -- draw actors
  -- bullets = draw_active(bullets)
  -- respawn warnings
  if us.respawncount > 0 then
    for a in all(graveyard) do
      local ax, ay = centertile(a.sc, a.sr)
      circ(ax, ay, us.respawncount / 2, 8)
    end
    local x, y = centertile(us.sc, us.sr)
    circ(x, y, us.respawncount + 2, 11)
    circ(x, y, us.respawncount, 10)
  end
  --debug heat map
  -- currentroom:iterate(function(c,r)
  --   local h = enemyhot[c..","..r] or -hotdelay
  --   if frames-h < hotdelay then
  --     local tall = hotdelay - (frames-h)
  --     rectfill(c*8+1,(r+1)*8-tall,c*8+5,r*8+7,2)
  --   end
  -- end)
  them = draw_active(them)
  -- player
  if us.active then
    us:draw()
  end
  -- us:drawdbg()
  -- draw fx
  fx = draw_active(fx)
  --update screen shake
  if shkxt > 0 then
    shkxt = shkxt - (1)
    if shkxt == 0 then
      local sn = sgn(shkx)
      if sn > 0 then
        shkx = -shkx
      else
        shkx = -(shkx + 1)
      end
      shkxt = shkdelay
    end
  end
  if shkyt > 0 then
    shkyt = shkyt - (1)
    if shkyt == 0 then
      local sn = sgn(shky)
      if sn > 0 then
        shky = -shky
      else
        shky = -(shky + 1)
      end
      shkyt = shkdelay
    end
  end
  if ending then
    print("the end", cam_x + 64 - 12, us.y + the_end_y, 7)
    if the_end_y < -24 then
      the_end_y = the_end_y + (1)
    end
  end
  -- print out values added to debug
  local total, ty, good = #debug, 0, {}
  for i = 1, total do
    local s = debug[i]
    print(s, 1 + cam_x, 1 + cam_y + ty, 7)
    ty = ty + (8)
    if i > total - 15 then
      add(good, s)
    end
  end
  debug = good
-- -- draw blox
-- for a in all(blox) do
--   if a.active then a:draw() end
-- end
-- -- print out values added to debug
-- local total,ty,good=#debug,0,{}
-- for i=1,total do
--   local s = debug[i]
--   print(s,1+cam_x,1+cam_y+ty,7)
--   ty += 8
--   if(i > total-15) add(good, s)
-- end
-- debug = good
end

-- garbage collect drawings on the fly
function draw_active(table)
  local good, i = {}, 1
  for a in all(table) do
    if a.active then
      a:draw()
      -- if(a.drawdbg) a:drawdbg()
      good[i] = a
      i = i + (1)
    end
  end
  return good
end

-- set screen shake
function shake(x, y)
  if abs(x) > abs(shkx) then
    shkx, shkxt = x, shkdelay + 1
  end
  if abs(y) > abs(shky) then
    shky, shkyt = y, shkdelay + 1
  end
end

-- draw stars
function drawstars()
  for st in all(stars) do
    local x, y, v, c = st.x, st.y, st.v, st.c
    y = y + (v)
    if x < cam_x + 0 then
      x = x + (128)
    end
    if x > cam_x + 127 then
      x = x - (128)
    end
    if y < cam_y + 0 then
      y = y + (128)
    end
    if y > cam_y + 127 then
      y = y - (128)
    end
    pset(x, y, c)
    st.x, st.y = x, y
  end
end

--Engine
-- aabb recursive moving entity
blok = class()
blokn = 0

--track instances of blok for debugging
-- x,y,w,h: bounds
-- flag: a pico 8 map flag
-- ignore: flags we want this blok to ignore
-- sp: sprite
function blok:init(x, y, w, h, flag, ignore, sp)
  self.active, self.x, self.y, self.w, self.h, self.flag, self.ignore, self.sp = true, x or 0, y or 0, w or 8, h or 8, flag or 0, ignore or 0, sp or 1
  self.vx, self.vy, self.dx, self.dy, self.touchx, self.touchy = 0, 0, 0, 0, nil, nil
  --up/downignore is set by the player object to allow it to jump thru ledges
  self.downignore, self.upignore = nil, nil
  --mom = floor, g = gravity, coyote = read as being on floor
  self.mom, self.g, self.coyote = nil, 0, 0
  blokn = blokn + (1)
  self.n = blokn
end

--update
function blok:upd()
  --move x, then y, allowing us to slide off walls
  --avoid micro-sliding, floating point error can cause phasing
  if abs(self.vx) > 0.1 then
    self:movex(self.vx)
  end
  if abs(self.vy) > 0.1 then
    self:movey(self.vy)
  end
  --apply damping
  self.vx = self.vx * (self.dx)
  self.vy = self.vy * (self.dy)
  --fall
  if abs(self.g) ~= 0 then
    if not self.mom then
      self.vy = self.vy + (self.g)
      if abs(self.vy) > speedlimit then
        self.vy = sgn(self.vy) * speedlimit
      end
      if self.coyote > 0 then
        self.coyote = self.coyote - (1)
      end
    else
      if self.coyote == 0 and band(self.mom.flag, f_outside) == 0 then
        self:dustflr(self.w + 4)
        sfx(0)
      end
      self.coyote = 3
    end
  end
end

function blok:movex(v)
  local x, y, w, h = self.x, self.y, self.w, self.h
  local edge, obstacles = v > 0 and x + w or x, {}
  if v > 0 then
    obstacles = getobstacles(x + w, y, v, h, self.ignore, self)
    sort(obstacles, rightwards)
  elseif v < 0 then
    obstacles = getobstacles(x + v, y, abs(v), h, self.ignore, self)
    sort(obstacles, leftwards)
  end
  if #obstacles > 0 then
    ob = obstacles[1]
    local obedge = v > 0 and ob.x or ob.x + ob.w
    local shdmove = (edge + v) - obedge
    --how far should it move?
    self.touchx = ob
    v = v - (shdmove)
  end
  self.x = self.x + (v)
  --have i lost a parent?
  if self.mom then
    local p = self.mom
    if self.x >= p.x + p.w or self.x + self.w <= p.x then
      self.mom = nil
    end
  end
  return v
end

--jumping up thru ledges and moving plaforms
--makes this bit very hacky
function blok:movey(v)
  local x, y, w, h = self.x, self.y, self.w, self.h
  local edge, obstacles = v > 0 and y + h or y, {}
  if v > 0 then
    --ledge landing hack when moving down
    obstacles = getobstacles(x, y + h, w, v, self.downignore or self.ignore, self)
    sort(obstacles, downwards)
  elseif v < 0 then
    --ledge landing hack when moving up
    obstacles = getobstacles(x, y + v, w, abs(v), self.upignore or self.ignore, self)
    sort(obstacles, upwards)
  end
  if #obstacles > 0 then
    for ob in all(obstacles) do
      local obedge = v > 0 and ob.y or ob.y + ob.h
      --break if v reduced to no overlap
      if (v > 0 and obedge > edge + v) or (v < 0 and obedge < edge + v) then
        break
      end
      --how far should it move?
      local shdmove, skip = (edge + v) - obedge, false
      --is there a special rule for landing on it?
      if v > 0 and self.downignore then
        --skip this block if we were below its top
        if y + h > ob.y then
          skip = true
        end
      end
      if v < 0 and self.upignore then
        --skip this block if we were above its bottom
        if y < ob.y + ob.h then
          skip = true
        end
      end
      if not skip then
        self.touchy = ob
        v = v - (shdmove)
        --floor?
        if shdmove > 0 and self.g > 0 then
          self.mom = ob
          self.vy = 0
        --cancel velocity
        end
        if shdmove < 0 and self.g < 0 then
          self.mom = ob
          self.vy = 0
        --cancel velocity
        end
        --quit or shdmove will work in reverse
        if abs(v) < 000.1 then
          break
        end
      end
    end
  end
  self.y = self.y + (v)
  --have i lost a parent?
  if self.mom then
    if self.g > 0 and self.y + self.h < self.mom.y then
      self.mom = nil
    end
    if self.g < 0 and self.mom.y + self.mom.h < self.y then
      self.mom = nil
    end
  end
  return v
end

function blok:death(src)
  --source of death
  self.active = false
end

function blok:draw(sp, offx, offy)
  local sp, offx, offy = sp or self.sp, offx or -4, offy or -4
  local x, y = offx + self.x + self.w * 0.5, offy + self.y + self.h * 0.5
  spr(sp, x, y, 1, 1, self.flipx, self.flipy)
end

function blok:drawdbg()
  rect(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, 3)
  if self.mom then
    local m = self.mom
    line(self.x + self.w / 2, self.y + self.h / 2, m.x + m.w / 2, m.y + m.h / 2, 3)
  end
  print(self.n, self.x, self.y - 8, 7)
end

function blok:center()
  return self.x + self.w * 0.5, self.y + self.h * 0.5
end

-- function blok:intersectsblok(a)
--   return not (a.x>=self.x+self.w or a.y>=self.y+self.h or self.x>=a.x+a.w or self.y>=a.y+a.h)
-- end
function blok:intersects(x, y, w, h)
  return not (x >= self.x + self.w or y >= self.y + self.h or self.x >= x + w or self.y >= y + h)
end

-- function blok:contains(x,y)
--   return x>=self.x and y>=self.y and x<self.x+self.w or y<self.y+self.h
-- end
--this fails at long distance
--the overflow causes 0,0,0 to be returned, watch for it
-- function blok:normalto(bx,by)
--   local ax,ay = self:center()
--   local vx,vy = (bx-ax),(by-ay)
--   local len = sqrt(vx*vx+vy*vy)
--   if(len > 0) return vx/len,vy/len,len
--   return 0,0,0
-- end
--x,y:position or x is an blok, v:speed, d:damping
-- function blok:moveto(x,y,v,d)
--   local tx,ty,len = self:normalto(x,y)
--   if(v > len) v = len
--   self.vx,self.vy,self.dx,self.dy = tx*v,ty*v,d,d
-- end
function blok:phantom()
  return spcopy(self.x + self.w * 0.5, self.y + self.h * 0.5, self.sp, fx, 0, self.flipx, self.flipy)
end

function blok:dustflr(w)
  for i = 1, w do
    dust(-w * 0.5 + self.x + self.w * 0.5 + rnd(w), self.y + ((self.g > 0) and self.h - 1 or -1) + rnd(2), 2, pick1(6, 7))
  end
end

-- function blok:dustx()
--   dust((self.flipx and self.x+self.w or self.x),
--           self.y+self.h/2+rnd(self.h/2),
--           2,pick1(6,7))
-- end
-- function blok:dusty()
--   dust(self.x+self.w/2,self.y+self.h,2,pick1(6,7))
-- end
-- collision utils
function cemterintile(x, y, c, r)
  return flr(x * 0.125) == c and flr(y * 0.125) == r
end

function intile(o, c, r)
  return o.x >= c * 8 and o.y >= r * 8 and o.x + o.w <= (c + 1) * 8 and o.y + o.h <= (r + 1) * 8
end

function centertile(c, r, w, h)
  w, h = (w or 0), (h or 0)
  return (4 + c * 8) - w * 0.5, (4 + r * 8) - h * 0.5
end

function gettile(x, y)
  return flr(x * 0.125), flr(y * 0.125)
end

-- function intersectsmap(x,y,w,h)
--   local xmin, ymin = flr(x/8),flr(y/8)
--   local xmax, ymax = flr((x+w-0.0001)/8),flr((y+h-0.0001)/8)
--   for c=xmin,xmax do
--     for r=ymin,ymax do
--       if (fget(mget(c,r))>0) then
--         return true
--       end
--     end
--   end
--   return false
-- end
--return a table of objects describing tiles on the map
--ignore: do not return anything with this flag
--result: a table of results to add to
function mapobjects(x, y, w, h, ignore, result)
  result, ignore = result or {}, ignore or 0
  local xmin, ymin = flr(x / 8), flr(y / 8)
  -- have to deduct a tiny amount, or we end up looking at a neighbour
  local xmax, ymax = flr((x + w - 0.0001) / 8), flr((y + h - 0.0001) / 8)
  local rxmin, rymin, rxmax, rymax = currentroom.x, currentroom.y, currentroom.x + currentroom.w - 1, currentroom.y + currentroom.h - 1
  for c = xmin, xmax do
    for r = ymin, ymax do
      --bounds check
      if c < rxmin or r < rymin or c > rxmax or r > rymax then
        add(result, {x = c * 8, y = r * 8, w = 8, h = 8, flag = f_out, sp = 0})
      else
        local sp = mget(c, r)
        local f = fget(sp)
        if f > 0 and band(f, ignore) == 0 then
          add(result, {x = c * 8, y = r * 8, w = 8, h = 8, flag = f, sp = sp})
        end
      end
    end
  end
  return result
end

--return all blox or tiles in an area,
--excluding source from the list and anything with a flag it ignores
--tiles returned are basic versions of blox
function getobstacles(x, y, w, h, ignore, source)
  local result = {}
  ignore = ignore or 0
  mapobjects(x, y, w, h, ignore, result)
  for a in all(blox) do
    if a ~= source and a.active then
      if band(ignore, a.flag) == 0 and a:intersects(x, y, w, h) then
        add(result, a)
      end
    end
  end
  return result
end

-- sorting comparators
function rightwards(a, b)
  return a.x > b.x
end

function leftwards(a, b)
  return a.x < b.x
end

function downwards(a, b)
  return a.y > b.y
end

function upwards(a, b)
  return a.y < b.y
end

--insertion sort
function sort(a, cmp)
  for i = 1, #a do
    local j = i
    while j > 1 and cmp(a[j - 1], a[j]) do
      a[j], a[j - 1] = a[j - 1], a[j]
      j = j - 1
    end
  end
end

--it's you murphy
player = blok:extend()

function player:init(c, r, nosword, egg)
  self.sc, self.sr = c, r
  -- spawn column & row
  c, r = c * 8, r * 8 + 1
  blok.init(self, c, r, 6, 6, f_player, f_char_thru, 1)
  self.dx, self.dy, self.speed, self.g = 0.5, dropdamp, 1, grav * gravdir
  self.goroom, self.goroomc, self.goroomr = nil, 0, 0
  self.enterroomwait, self.respawncount = 0, 0
  self.flipy, self.sword, self.lockjump, self.nosword, self.egg = false, false, false, nosword or egg, egg
  self.sg, self.sflipy, self.ssword = self.g, self.flipy, self.sword
  --spawn settings
  self.camlook, self.flipignore, self.getsword = 0, 0, 0
  self.downignore, self.upignore = f_down_thru, f_up_thru
  self.cangravswitch = true
  if egg then
    self.eggcount = 4
  end
end

function player:upd()
  if self.enterroomwait > 0 then
    self.enterroomwait = self.enterroomwait - (1)
    return
  end
  if self.respawncount > 0 then
    self.respawncount = self.respawncount - (1)
    if self.respawncount == 0 then
      self:respawn()
      debrisblok(self, 80, 5, 1)
      debrisblok(self, 81, 3, 2)
      squode(self.x + self.w * 0.5, self.y + self.h * 0.5, 4, 11)
      debrisblok(self, 68, 7, 3)
      for a in all(them) do
        a:respawn(true)
      --reset all
      end
      for a in all(graveyard) do
        a:respawn()
      --and all the dead come back too!
      end
      frames = 0
      enemyhot = {}
      graveyard = {}
      sfx(9)
    else
      return
    end
  end
  if self.getsword > 0 then
    self.getsword = self.getsword - (1)
    if self.getsword == 0 then
      splode(self.x + self.w * 0.5, self.y + self.h * 0.5, 8, 9, fx, 10)
      self.nosword = false
      shake(0, 2)
      sfx(12)
    end
    return
  end
  --sword check
  if self.sword then
    local chk = getobstacles(self.x, (self.g > 0) and (self.y + self.h) - 2 or self.y - 8, self.w, 10, f_player)
    --found a trap
    for o in all(chk) do
      local c, r, sp = flr(o.x * 0.125), flr(o.y * 0.125), o.sp
      --destructible
      if sp == 19 or sp == 20 then
        mset(c, r, sp + 64)
        debristile(c, r, 80, 3, 2)
        debristile(c, r, 81, 3, 1)
        squode(c * 8 + 4, r * 8 + 4, 4, 3, fx, 11)
        shake(0, 1)
        sfx(3)
      --enemies
      elseif sp == 21 or sp == 23 or sp == 61 then
        o:death()
      --flip grav switch
      elseif (sp == 34 or sp == 50) and self.cangravswitch then
        if (sp == 34 and self.g < 0) or (sp == 50 and self.g > 0) then
          squode(c * 8 + 4, r * 8 + 4, 4, 12)
          sfx(2)
          gravdir = -gravdir
          --flip g for all
          for b in all(blox) do
            if b ~= us and b.g ~= 0 then
              b.g, b.flipy, b.mom, b.vy = -b.g, b.g > 0, nil, 0
            elseif b.sp == 23 then
              --flyer
              b.flipy = gravdir < 0
            end
          end
          --change all grav switch
          local nsp = (sp == 34) and 50 or 34
          allmap(function(c, r)
            local s = mget(c, r)
            if s == sp then
              mset(c, r, nsp)
            end
          end)
          --no gravswitching till next jump
          self.cangravswitch = false
        end
      end
    end
  end
  --trap check
  local traps = getobstacles(self.x, self.y, self.w, self.h, bnot(bor(f_trap, f_enemy)))
  -- found a trap
  for o in all(traps) do
    local c, r, sp = flr(o.x * 0.125), flr(o.y * 0.125), o.sp
    local x, y = self:center()
    --spikes
    if sp == 14 or sp == 15 or sp == 30 or sp == 31 then
      if cemterintile(x, y, c, r) then
        self:death(o)
      end
    --enemies
    elseif band(o.flag, f_enemy) > 0 then
      --sword pickup is special enemy
      if o.sp == 6 then
        self.getsword = 60
        o.active = false
        sfx(11)
        --overwrite respawn of sword with empty
        add(currentroom.spawned, {c = o.sc, r = o.sr, sp = 0})
        return
      else
        if not self.sword or o.sp == 40 or o.sp == 25 then
          self:death(o)
        end
      end
    --flip line
    elseif sp == 38 then
      if self.flipignore == 0 and not self.mom and cemterintile(x, y, c, r) then
        self.g = -self.g
        self.flipy = not self.flipy
        self.vy = self.g * 3
        self.flipignore = 4
        --need to escape trap collision
        sfx(8)
      end
    elseif sp == 53 then
      ending = true
      speedlimit = 4
    end
  end
  --EGG!!-------------------------
  if self.egg then
    if btnp(0) or btnp(1) or btnp(4) or btnp(5) then
      local strong = 5 - self.eggcount
      shake(strong * ((self.eggcount % 2) == 0 and -1 or 1), 0)
      debrisrect(self.x - 3, self.y - 11, 10, 10, 81, strong * 2, strong * 0.25)
      debrisrect(self.x - 3, self.y - 11, 10, 10, 80, strong, strong * 0.5)
      self.eggcount = self.eggcount - (1)
      sfx(5)
      if self.eggcount == 0 then
        self.egg = nil
        self.vy = -self.g * 8
        self.mom, self.coyote = nil, 0
        sfx(3)
      end
    end
  else
    -- move
    if btn(0) then
      self.vx = self.vx - (self.speed)
      self.flipx = true
    end
    if btn(1) then
      self.vx = self.vx + (self.speed)
      self.flipx = false
    end
    --jump!
    local jumppress = (btn(4) or btn(5))
    if not jumppress or abs(self.vy) > 3 then
      self.lockjump = false
    end
    if self.coyote > 0 and jumppress and not self.lockjump then
      if self.nosword then
        self.vy = -self.g * 8
        sfx(10)
      else
        self:dustflr(self.w + 6)
        self.g = -self.g
        self.vy = self.g * 3
        self.sword = true
        self.cangravswitch = true
        sfx(1)
      end
      self.mom, self.coyote, self.lockjump = nil, 0, true
    end
  end
  --simulate
  blok.upd(self)
  -- collision
  --player moves diagonally so we need to check both axes
  self:reacttouch(self.touchx)
  if self.goroom then
    return
  end
  self:reacttouch(self.touchy)
  if self.goroom then
    self.mom = nil
    return
  end
  --cancel accumulated speed when pushing
  if self.touchx then
    self.vx = 0
  end
  if self.touchy then
    self.vy = 0
    self.sword = false
    self.flipy = self.g < 0
  end
  --call crumble
  if self.mom and self.mom.crumble then
    self.mom:crumble()
  end
  if self.flipignore > 0 then
    self.flipignore = self.flipignore - (1)
  end
end

function player:respawn(touch)
  self.x, self.y, self.active = self.sc * 8, self.sr * 8, true
  self.touchx, self.touchy, self.mom = nil, nil, nil
  self.g, self.flipy, self.sword = self.sg, self.sflipy, self.ssword
  self.vx, self.vy, self.camlook = 0, 0, 0
  add(blox, self)
end

--can we beat up the player?
function player:ready()
  return self.enterroomwait == 0 and self.active
end

--where does the camera go?
function player:cam()
  local x, y = self:center()
  if not self.active then
    x, y = centertile(self.sc, self.sr)
  end
  self.camlook = self.camlook + (sgn(self.g) * 2)
  if abs(self.camlook) > 12 then
    self.camlook = 12 * sgn(self.camlook)
  end
  y = y + (self.camlook)
  --if(abs(self.vy)>0) y+=sgn(self.g)*4
  --handle any size room of 128px units
  x = min(max(x - 64, currentroom.x * 8), -128 + (currentroom.x + currentroom.w) * 8)
  y = min(max(y - 64, currentroom.y * 8), -128 + (currentroom.y + currentroom.h) * 8)
  return x, y
end

--get wrecked
function player:death(src)
  if not self.active then
    return
  end
  self.respawncount, self.active = 30, false
  local x, y = self:center()
  -- burst(scirc,x,y,2,{8,9,10},20,3,0.8)
  debrisblok(self, 69, 7, 2)
  debrisblok(self, 68, 5, 1)
  splode(x, y, 8, 10)
  shake(0, 4)
  sfx(7)
  -- sfx(-1,0)
  -- sfx(10)
  x, y = self:cam()
  camtween = tween(cam_x, cam_y, x, y, ease_outcubic, 30)
end

--called after movement to react to each axis
function player:reacttouch(touch)
  if touch then
    -- trigger exit
    -- not prevroom: not animating the previous room
    if band(touch.flag, f_outside) > 0 and not prevroom then
      local tc, tr = gettile(touch.x + touch.w * 0.5, touch.y + touch.h * 0.5)
      local c, r = flr(tc * 0.0625), flr(tr * 0.0625)
      --n/16
      local room = getroom(c, r)
      if ending then
        f_out = f_wall
        --generate the stars
        for i = 1, 100 do
          local v, c = rnd(0.75), 1
          if v > 0.5 then
            c = 5
          end
          add(stars, {x = cam_x + rnd(127), y = -128 + cam_y + rnd(127), v = v, c = c})
        end
      end
      if room then
        prevroomx, prevroomy = 0, 0
        -- push into next room
        if touch.x >= self.x + self.w then
          self.x = self.x + (self.w)
        end
        if touch.x + touch.w <= self.x then
          self.x = self.x - (self.w)
        end
        if touch.y >= self.y + self.h then
          self.y = self.y + (self.h)
        end
        if touch.y + touch.h <= self.y then
          self.y = self.y - (self.h)
        end
        -- map wrap
        if self.x >= 1024 then
          --8 rooms
          self.x = self.x - (1024)
          c = c - (8)
          tc = tc - (128)
          prevroomx = -128
        end
        if self.x + self.w <= 0 then
          self.x = self.x + (1024)
          c = c + (8)
          tc = tc + (128)
          prevroomx = 128
        end
        if self.y >= 512 then
          --4 rooms
          self.y = self.y - (512)
          r = r - (4)
          tr = tr - (64)
          prevroomy = -64
        end
        if self.y + self.h <= 0 and room ~= exitroom then
          self.y = self.y + (512)
          r = r + (4)
          tr = tr + (64)
          prevroomy = 64
        end
        self.goroomc, self.goroomr, self.sc, self.sr = c, r, tc, tr
        self.sg, self.sflipy, self.ssword = self.g, self.flipy, self.sword
        -- reset frames/blokn to avoid overflow
        self.goroom, self.enterroomwait, frames, blokn = room, 30, 0, 1
        enemyhot = {}
        self.touch, self.touchx, self.touchy, self.camlook = nil, nil, nil, 0
        -- sfx(-1,0)--stop shooting sound
        return
      end
    elseif band(touch.flag, f_wall) == 0 and band(touch.flag, f_enemy) > 0 then
      --add(debug, joinstr(touch.flag,f_wall,band(touch.flag,f_player_shot)))
      self:death(touch)
      return
    end
  end
end

function player:draw(sp)
  local x, y = self:center()
  if self.egg then
    x = x + (-shkx)
    spr(54, x - 8, y - 4)
    spr(55, x, y - 4)
    spr(48, x - 8, y - 12)
    spr(49, x, y - 12)
    return
  end
  local framen = ((frames / 2) % 2)
  if self.getsword > 0 then
    circfill(x - 1, y - 1, 7 + framen, 4)
    circfill(x - 1, y - 1, 5 + framen, 9)
    circ(x, y, self.getsword, 10)
    circ(x, y, self.getsword + 2, 9)
  end
  sp = sp or self.sp
  local offx, offy, flipy = -4, -3, self.flipy
  if self.nosword then
    sp = 4
  end
  if self.sword then
    if flipy then
      offy = offy - (2)
    end
    blok.draw(self, 32 + framen, offx, offy + (flipy and 8 or -8))
    blok.draw(self, 17 + framen, offx, offy)
  else
    if not flipy then
      offy = offy - (2)
    end
    local f = ((abs(self.vx) > 0.1) and framen or 0)
    if self.coyote == 0 then
      f = 1
    end
    blok.draw(self, sp + f, offx, offy)
  end
end

--enemies
enemy = blok:extend()

function enemy:init(c, r, sp, dirx, diry)
  self.sc, self.sr = c, r
  -- spawn column & row
  c, r = c * 8, r * 8
  self.speed = 1
  blok.init(self, c, r, 6, 6, f_enemy, f_char_thru, sp)
  self.dx, self.dy, self.speed, self.g = 0, dropdamp, 1, grav * gravdir
  self.dirx, self.diry, self.sdirx, self.sdiry = dirx, diry, dirx, diry
  self.flipy = (self.g < 0)
  self.downignore, self.upignore = f_down_thru, f_up_thru
  if sp == 21 or sp == 25 or sp == 61 then
    --walker
    self.flipx, self.coyote = dirx < 0, 2
    self:movey(gravdir * 2)
  elseif sp == 23 or sp == 40 or sp == 6 then
    --flyer
    self.g, self.dy = 0, 0
  end
end

function enemy:upd()
  if not us:ready() then
    return
  end
  local cx, cy = self:center()
  if self.sp == 61 then
    --chaser
    local c, r = gettile(cx, cy)
    local k = c .. "," .. r
    local h = enemyhot[k] or -hotdelay
    if frames - h > hotdelay then
      if us.x + us.w < self.x then
        self.dirx = -1
        self.flipx = true
      elseif us.x > self.x + self.w then
        self.dirx = 1
        self.flipx = false
      end
    end
    enemyhot[k] = frames
  else
    --direction command check
    local floor = mapobjects(self.x, self.y, self.w, self.h, bnot(f_trap))
    if #floor > 0 then
      -- found a trap
      local f = floor[1]
      local c, r, s = flr(f.x / 8), flr(f.y / 8), f.sp
      -- is it a dir command?
      if s >= 8 and s <= 11 then
        -- dir commands start at 8
        local x, y, n = 0, 0, s - 8
        if n == 0 then
          x = -1
        elseif n == 1 then
          x = 1
        elseif n == 2 then
          y = -1
        elseif n == 3 then
          y = 1
        end
        if intile(self, c, r) then
          if self.g == 0 then
            --flyer
            self.dirx, self.diry = x, y
          else
            if dirx ~= 0 then
              --walker
              self.dirx = x
              self.flipx = (x < 0)
            end
          end
        end
      end
    end
  end
  -- move
  local sp, speed = self.sp, self.speed
  self.vx = speed * self.dirx
  if self.g == 0 then
    self.vy = speed * self.diry
  end
  blok.upd(self)
  -- turn around when bump
  if self.touchx then
    if sgn(self.touchx.x + self.touchx.w * 0.5 - cx) == self.dirx then
      self.dirx = -self.dirx
      if self.g ~= 0 then
        self.flipx = (self.dirx < 0)
      end
    end
  elseif self.touchy then
    if self.g == 0 then
      if sgn(self.touchy.y + self.touchy.h * 0.5 - cy) == self.diry then
        self.diry = -self.diry
      end
    else
      --kill on outside
      if band(self.touchy.flag, f_outside) > 0 then
        self:death()
      end
    end
  end
end

--can use this to reset an enemy as well
function enemy:respawn(just_reset)
  if self.sp == 6 then
    return
  end
  --sword pickup
  if just_reset then
    splode(self.x + self.w * 0.5, self.y + self.h * 0.5, 4, 2, fx, 8)
  end
  self.active, self.touch, self.touchx, self.touchy, self.mom = true, nil, nil, nil, nil
  self.x, self.y = centertile(self.sc, self.sr, self.w, self.h)
  self.dirx, self.diry = self.sdirx, self.sdiry
  if self.g ~= 0 then
    self.g = abs(self.g) * gravdir
    self.flipy = (self.g < 0)
  end
  if not just_reset then
    add2(self, blox, them)
  end
  squode(self.x + self.w * 0.5, self.y + self.h * 0.5, 4, 14)
end

function enemy:death(src)
  self.active = false
  debrisblok(self, 96, 7, 2)
  debrisblok(self, 97, 5, 1)
  local x, y = self:center()
  splode(x, y, 6, 8)
  sfx(4)
  shake(0, 2)
  add(graveyard, self)
end

function enemy:draw(sp)
  sp = sp or self.sp
  local offx, offy, flipy = -4, -3, self.flipy
  local f = (frames / 3) % 2
  if self.g == 0 then
    if sp == 40 then
      blok.draw(self, sp + (flr(frames / 2) % 4))
    else
      blok.draw(self, sp + f, offx, offy)
    end
  else
    if self.g > 0 then
      offy = offy - (2)
    end
    if self.coyote == 0 then
      f = 1
    end
    blok.draw(self, sp + f, offx, offy)
  end
end

crumbleflr = blok:extend()

function crumbleflr:init(c, r, sp, w)
  self.sc, self.sr = c, r
  blok.init(self, c * 8, r * 8, w, 8, f_wall, 0, sp)
  self.crumbling = false
  self.count = 30
end

function crumbleflr:crumble()
  if not self.crumbling then
    self.crumbling = true
  end
end

function crumbleflr:upd()
  if self.crumbling then
    self.count = self.count - (1)
    if self.count == 28 then
      debrisblok(self, 64, self.w / 4)
      debrisblok(self, 80, self.w / 8)
      sfx(5)
    end
    if self.count <= 0 then
      self.flag = f_trap
      for b in all(blox) do
        if b.mom == self then
          b.mom = nil
        end
      end
      self.count, self.crumbling = -60, false
      debrisblok(self, 64, self.w / 2)
      debrisblok(self, 80, self.w / 8)
      sfx(6)
    end
  elseif self.count < 0 then
    self.count = self.count + (1)
    if self.count >= 0 then
      local obs = getobstacles(self.x, self.y, self.w, self.h)
      if #obs == 1 then
        self:respawn()
      else
        self.count = -1
      end
    end
  end
end

function crumbleflr:phantom()
  if self.w == 8 then
    return blok.phantom(self)
  else
    local temp, sp = {islist = true}, self.sp
    if self.count <= 28 then
      sp = sp + (1)
    end
    if self.count <= 0 then
      sp = sp + (1)
      if self.count > -5 then
        sp = sp - (1)
      end
    end
    for x = self.x, self.x + self.w - 8, 8 do
      add(temp, spcopy(x + 4, self.y + 4, sp, fx, 0))
    end
    return temp
  end
end

function crumbleflr:respawn(just_reset)
  self.flag, self.count = f_wall, 30
end

function crumbleflr:draw(sp)
  local sp, y = self.sp, self.y
  if self.count <= 28 then
    sp = sp + (1)
  end
  if self.count <= 0 then
    sp = sp + (1)
    if self.count > -5 then
      sp = sp - (1)
    end
  end
  for x = flr(self.x), self.x + self.w - 8, 8 do
    spr(sp, x, y)
  end
--line(self.x,self.y,0,0)
end

--gravity affected slab
slab = blok:extend()

function slab:init(c, r, sp)
  self.sc, self.sr = c, r
  c, r = c * 8, r * 8
  blok.init(self, c, r, 8, 8, f_wall, boring(f_trap, f_up, f_down), sp)
  self.dx, self.dy, self.g = 0, dropdamp, grav * gravdir
  self.downignore = bor(f_trap, f_down)
  self.upignore = bor(f_trap, f_up)
  self.flipy = (self.g < 0)
  self.coyote = 1
end

function slab:mergeslab(o)
  if o.y < self.y then
    self.y = o.y
  end
  self.h = self.h + (o.h)
  o.active = false
-- debugp(self.y,self.h,self.n,o.n)
end

function slab:pushslab(vy)
  self:movey(vy)
  if self.touchy then
    self:chkkill()
  end
end

function slab:upd()
  blok.upd(self)
  if self.touchy then
    self:chkkill()
  end
end

function slab:chkkill()
  if self.touchy.death then
    if band(self.touchy.flag, bor(f_wall, f_ledge_thru)) == 0 then
      self.touchy:death(self)
      self.touchy, self.mom = nil, nil
    elseif self.touchy.mergeslab then
      self:mergeslab(self.touchy)
      self.touchy, self.mom = nil, nil
    end
  end
end

function slab:respawn(just_reset)
--does not respawn
end

function slab:phantom()
  if self.h == 8 then
    return blok.phantom(self)
  else
    local temp = {islist = true}
    for y = flr(self.y), self.y + self.h - 8, 8 do
      add(temp, spcopy(self.x + 4, y + 4, self.sp, fx, 0, self.flipx, self.flipy))
    end
    return temp
  end
end

function slab:draw(sp)
  local sp, y = self.sp, self.y
  if not self.mom then
    sp = sp + (1)
  end
  for y = flr(self.y), self.y + self.h - 8, 8 do
    spr(sp, self.x, y, 1, 1, self.flipx, self.flipy)
  end
--line(self.x,self.y,0,0)
end

room = class()

-- default room size is 16x16 tiles, there are 8x4 rooms, 128x64 tiles
function room:init(c, r, cw, ch)
  -- c,r,cw,ch is the room slot position and size
  c, r, cw, ch = c or 0, r or 0, cw or 1, ch or 1
  -- x,y,w,h are measurements in tiles
  local x, y, w, h = c * 16, r * 16, cw * 16, ch * 16
  self.c, self.r, self.x, self.y, self.w, self.h, self.cw, self.ch = c, r, x, y, w, h, cw, ch
  for i = c, c + (cw - 1) do
    for j = r, r + (ch - 1) do
      rooms[i .. "," .. j] = self
    end
  end
  self.spawned, self.phantoms = {}, {}
end

function room:enter()
  local function create(c, r)
    local sp = mget(c, r)
    local flag = fget(sp)
    --enemies
    if band(flag, f_enemy) > 0 then
      self:to_reset(c, r, sp)
      local x, y = 0, 0
      if inrange(sp, 44, 46) then
        if sp == 44 then
          x = -1
        end
        if sp == 45 then
          y = -1
        end
        if sp == 46 then
          y = 1
        end
        sp = 40
      elseif inrange(sp, 58, 60) then
        if sp == 58 then
          x = -1
        end
        if sp == 59 then
          y = -1
        end
        if sp == 60 then
          y = 1
        end
        sp = 23
      elseif sp == 56 then
        x = -1
        sp = 21
      elseif sp == 57 then
        x = -1
        sp = 25
      elseif sp == 6 then
      --sword pickup
      else
        x = 1
      end
      add2(enemy(c, r, sp, x, y), blox, them)
    -- mset(c,r,114)
    --grav slab
    elseif sp == 36 then
      self:to_reset(c, r, sp)
      add2(slab(c, r, sp), blox, them)
    --flip line
    elseif sp == 38 then
      blinky(c, r, sp, 39, fx, 10, self)
    --crumble floor
    elseif sp == 27 then
      --expand by reading ahead rightwards
      local x, w = c, 0
      while (mget(x, r) == sp) do
        self:to_reset(x, r, sp)
        x = x + (1)
        w = w + (8)
      end
      add2(crumbleflr(c, r, sp, w), blox, them)
    end
  end

  self:iterate(create)
  --dock slabs to floor
  for b in all(blox) do
    if b.pushslab and b.active then
      while (not b.mom) do
        b:pushslab(16 * 8 * gravdir)
      end
    end
  end
end

function inrange(n, a, b)
  return n >= a and n <= b
end

function room:to_reset(c, r, sp)
  mset(c, r, 0)
  add(self.spawned, {c = c, r = r, sp = sp})
end

function room:exit()
  fx = {}
  --create images of spawned monsters
  local p = self.phantoms
  for a in all(them) do
    a.active = false
    local phantom = a:phantom()
    if phantom.islist then
      del(phantom, true)
      for o in all(phantom) do
        add(p, o)
      end
    else
      add(p, phantom)
    end
  end
  graveyard = {}
--empty for new respawns
end

--when wrapping we fake the room position, so phantoms come too
function room:movephantoms(c, r)
  c = c * (8)
  r = r * (8)
  for a in all(self.phantoms) do
    a.x = a.x + (c)
    a.y = a.y + (r)
  end
end

function room:clearphantoms()
  for a in all(self.phantoms) do
    a.active = false
  end
  self.phantoms = {}
end

function room:resetspawned()
  for a in all(self.spawned) do
    mset(a.c, a.r, a.sp)
  end
  self.spawned = {}
end

-- method is a function(c,r)
function room:iterate(method)
  local x, y, w, h = self.x, self.y, self.w, self.h
  for c = x, (x + w) - 1 do
    for r = y, (y + h) - 1 do
      method(c, r)
    end
  end
end

--change all a tiles to b tiles
-- function room:swapsp(a,b)
--   self:iterate(function(c,r)
--     local sp = mget(c,r)
--     if(sp==a) mset(c,r,b)
--   end)
-- end
function room:draw(offx, offy)
  --offset, for when faking wrap
  offx, offy = offx or 0, offy or 0
  map(self.x, self.y, (self.x + offx) * 8, (self.y + offy) * 8, self.w, self.h)
end

-- function room:contains(x,y,w,h)
--   local rx,ry,rw,rh = self.x*8,self.y*8,self.w*8,self.h*8
--   return not (x + w <= rx or y + h <= ry or rx + rw <= x or ry + rh <= y)
-- end
-- function room:inside(x,y,w,h)
--   local rx,ry,rw,rh = self.x*8,self.y*8,self.w*8,self.h*8
--   return x >= rx and y >= ry and x + w <= rx + rw and y + h <= ry + rh
-- end
-- function room:onborder(x,y)
--   local rx,ry,rw,rh = self.x,self.y,self.w,self.h
--   return x == rx or y == ry or x == rx+rw-1 or y == ry+rh-1
-- end
-- just a sprite from the sheet
spcopy = class()

function spcopy:init(x, y, sp, table, t, flipx, flipy)
  self.active, self.x, self.y, self.sp, table, self.t, self.flipx, self.flipy = true, x or 64, y or 64, sp or 1, table or fx, t or 0, flipx, flipy
  -- add to a list for drawing
  add(table, self)
end

function spcopy:draw(sp)
  sp = sp or self.sp
  spr(self.sp, -4 + self.x, -4 + self.y, 1, 1, self.flipx, self.flipy)
  if self.t > 0 then
    self.t = self.t - (1)
    if self.t == 0 then
      self.active = false
    end
  end
end

--for flashing map tiles
blinky = spcopy:extend()

function blinky:init(c, r, spa, spb, table, t, room)
  self.c, self.r, self.spa, self.spb, self.delay, self.room = c, r, spa, spb, t, room or currentroom
  spcopy.init(self, c * 8, r * 8, spa, table, t)
end

function blinky:draw()
  --6733
  if self.t <= 0 then
    self.t = self.delay
  end
  if self.t > self.delay * 0.5 then
    spr(self.spa, self.x, self.y)
  else
    spr(self.spb, self.x, self.y)
  end
  self.t = self.t - (1)
  --garbage collect when room changes or spa ~= mget(c,r)
  if self.room ~= currentroom or mget(self.c, self.r) ~= self.spa then
    self.active = false
  end
end

dust = class()

function dust:init(x, y, r, c)
  self.active, self.x, self.y, self.r, self.c = true, x, y, r, c
  add(fx, self)
end

function dust:draw()
  circfill(self.x, self.y, self.r, self.c)
  self.r = self.r - (0.2)
  self.y = self.y + (0.1)
  if self.r <= 0 then
    self.active = false
  end
end

-- bang
splode = class()

function splode:init(x, y, r, col, table, colw)
  self.active, self.x, self.y, self.r, self.t, self.col, self.colw, table = true, x or 64, y or 64, r or 8, 0, col or 7, colw or 7, table or fx
  -- add to a list for drawing
  add(table, self)
end

function splode:draw()
  local t, x, y, r, col, colw = flr(self.t * 0.5), self.x, self.y, self.r, self.col, self.colw
  if t == 0 then
    --black frame to make it pop
    circfill(x, y, r, colw)
    circfill(x, y, r - 1, 0)
  elseif t < 2 then
    --full
    circfill(x, y, r, col)
    circfill(x, y, r - 1, colw)
  else
    --shrink
    if t <= r then
      for rf = t, r do
        if rf == r then
          circ(x, y, rf, col)
        else
          circ(x, y, rf, colw)
        end
      end
    else
      self.active = false
    end
  end
  self.t = self.t + (1)
end

--square splode
squode = splode:extend()

function squode:init(x, y, r, col, table, colw)
  splode.init(self, x, y, r, col, table, colw)
end

function squode:draw()
  local t, x, y, r, col, colw = flr(self.t * 0.5), self.x, self.y, self.r, self.col, self.colw
  if t == 0 then
    --black frame to make it pop
    squarfill(x, y, r, colw)
    squarfill(x, y, r - 1, 0)
  elseif t < 2 then
    --full
    squarfill(x, y, r, col)
    squarfill(x, y, r - 1, colw)
  else
    --shrink
    if t <= r then
      for rf = t, r do
        if rf == r then
          squar(x, y, rf, col)
        else
          squar(x, y, rf, colw)
        end
      end
    else
      self.active = false
    end
  end
  self.t = self.t + (1)
end

function squar(x, y, s, c)
  rect(x - s, y - s, x + s, y + s, c)
end

function squarfill(x, y, s, c)
  rectfill(x - s, y - s, x + s, y + s, c)
end

debris = class()

function debris:init(x, y, sp, vx, vy)
  self.active, self.x, self.y, self.sp, self.vx, self.vy, self.flipx = true, x, y, sp, vx, vy, (rnd(2) > 1 and true or false)
end

function debris:draw()
  spr(self.sp, self.x, self.y, 1, 1, self.flipx)
  self.x = self.x + (self.vx)
  self.y = self.y + (self.vy)
  --apply damping
  self.vx = self.vx * (dropdamp)
  self.vy = self.vy * (dropdamp)
  self.vy = self.vy + (grav * gravdir)
  if gravdir > 0 and self.y > cam_y + 128 or gravdir < 0 and self.y < cam_y then
    self.active = false
  end
end

function debristile(c, r, sp, num, pwr)
  debrisrect(c * 8, r * 8, 8, 8, sp, num, pwr)
end

function debrisblok(b, sp, num, pwr)
  debrisrect(b.x, b.y, b.w, b.h, sp, num, pwr)
end

function debrisrect(x, y, w, h, sp, num, pwr)
  pwr = pwr or 1
  for i = 1, num do
    add(fx, debris(x + rnd(w), y + rnd(h), sp, -2 + rnd(4), (1 + rnd(1)) * -gravdir * pwr))
  end
end


__gfx__
0000000000000000009aaa00ddddd5dd00000000003bbb00000070000040704000000000000000000000000000000000000000000000000000000000777d777d
00000000009aaa00099aaa90d1111115003bbb0003bb3b3000407040000a7a0000002000000200000000000000000000021002100210021000d000d067656765
00700700099aaa90011ccc10d150105103bb3bb00117171000007000040a7a0400022000000220000002200000000000011001100110011000500050d750d750
00077000011ccc1039aaaaa0d101010501171710333bbb3000407040000a7a000022200000022200002222000222222000011000000110000d650d65d650d650
00077000b9aaaaa0b39aaa90d1101051b33bbb30b3bbbbb000007000040777040022200000022200022222200022220000011000000110000d650d65d650d650
00700700b39aaa90b039a93051010105b3bbbbb0b15b1b500409990400999990000220000002200000000000000220000d2002100d200d200d750d7505000500
000000000339a93000033300d1505051015b1b5000030300000010000400c004000020000002000000000000000000000220011002200220d676d6760d000d00
000000000bb090bb000b0b00d51515150bb000bb000b0b000040004000009000000000000000000000000000000000000000000000000000d777d77700000000
dddddddd00a7770000a7770013535353315351530000000000ee880060000006560e80650700000d0700000dddddddddd5d5d5d5510101010007500000075000
d111111d0aa777a00aa77770351515153515151500ee88000ee88880560e806565e888560075056000750560d111111551010101100000000057500000565000
d1bbbb1d011ccc10011ccc1051555351515353510ee88880011c1c1005e88850001cc100005756500057565051331d31103005000000010005d7d50005d65d00
d1bbbb1d09aaaaa009aaaaa035515b3515b1b535011c1c100eee8888001cc1000eee888000557550005575500030500000001000000000007777665676667657
d1bbbb1d0b9aaa900b9aaa905115535151135151feee8888fee888880eee88800ee88880dd77d66ddd77d66d00003000000030000000000005d6ddd0055755d0
d1bbb11d0b39a9300b39a930353b3b3535353535fee88888f08888800ee888800088880001111110221c1c123000d0d030005050000010100056d00000565000
d111111d000b3b00003b3b3051535351515b51510088888000f000f00088880000f00f00221c1c1288888888d151515150151510100101000055d00000d5d000
ddddddd0000b0b0000b000b035151515351515150ff000ff00f000f000f00f00000000008f88888f00f000f0d5d5d5d5d1d1d1d1500000000006000000070000
000070000000700015d00d5015d00d50ddddd55dddddd55d00000000000000000007000000007000700000d00070000000070000000700000007000000000000
000a7a00000070001110011111100111d0101015d01010150000000000000000005750000005700007505600007500000057100000515000011111000d200210
000a7a0000007000ccccccccc777777c5101010151010101101010100101010105d7d50077d7d0000575650000d7d6d005d1b100051b15001bbbbb1002200110
000a7a00000070001c7777c11c7777c1d6c11c65c677776c1c1c1c1cc1c1c1c1777766d0057765000057500005776500771bb1d071bbb1d071bbb1d000011000
0007770000007000d1c77c13d1c77c13516cc6011c6776c1010101011010101005d6d50000d6d6d00565d50077d6d00001bbb1001bbbbb10051b150000011000
0099999000099900d51cc155db1cc1b5d0166015d1c66c150000000000000000005650000065000006505d0000056000001bb10001111100005150000d200d20
0000c000000010000351153003b11b3051010101511cc1010000000000000000000d000000d00000d00000d00000d0000001b100000d0000000d000002200220
000090000000000051d00d1151d00d11d5151515d511151500000000000000000000000000000000000000000000000000001000000000000000000000000000
000000000000000015d00d5015d00d501010101000100010005bd53bd5131510000000000700000d700000077000000770000007000000000eee888000000000
00000000000000000351153003b11b30015101000151010100bd31bd3b515350008e1e0000751560570e10755701e075570ee0750eee8880eee888880d200d20
0000000000000000d51cc153db1cc1b30010151000100010005b31115d1bd1100881b1800051b1500581b150051b1e5001111150eee888880111c1c002200220
000000bd5bd00000d1c77c15d1c77c15000101000000000000bd331bd1113500011bb110001bb150001bb10001bbb1001bbbbb100111c1c0eee8888800011000
0000bb3bd1bd00001c7777c11c7777c1001010001000100000d51d5d11bd1300f1bbb182d1bbb16d01bbb1201bbbbb1001bbb120eee88888eee8111800011000
000bd3bd35d35000ccccccccc777777c0001000001000100000bd313b1d33500f81bb1e8011bb110081bb1e0011111e0081b1ee0eee81118eee811180d200d20
000dbbdb5135100011100111111001110000100010101510000d3515dd3510000481b1848811b1184081b104408eee044081ee04eee88888eee8888802200220
000535b53351500051d00d1151d00d11000000005151010100515151115115000ff010ff4f4e1e4f00f01f0000f00f0000f00f000f00000f00f000f000000000
0000000000000000d5dddddd0000000000000000000000000000000015dddddddddddddddddddd51000000000000000000000000000000000000000000000000
0000000000000000101d5d1100000000000000000000000000000000011d5d5dd1d5d1d1d5d511000ddddd000d0000000ddddd000ddddd000d000d000d000d00
00000000000dd00000015110000000000000000000000000000ab000000011d1011d11101d110000011111000d0000000111110001111100010001000dd00d00
000d100000dd15000001d1000005000000000000000ab00000abb3000000015100151000151000000ddd00000d000000000d00000ddddd000ddd000001100100
0001500000d15100000010000005000000000000000b300000bb330000000010000100000100000001110000010000000001000001111100011100000d00dd00
000000000005100000000000000510000051000000000000000330000000000000000000000000000d0000000ddddd000ddddd000d0000000d000d000d001d00
00000000000000000000000000051000005100000000000000000000000000000000000000000000010000000111110001111100010000000100010001000100
00000000000000000000000000511100005111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000005151515501510150000000000000000000000000000000000000000d11101000010115100000000000000000000000000000000
000000000000000000000000500000015000000100000000000d00000000000000000000000000005d511000010111150ddddd000d000d000ddddd000d000000
00000000000bd0000000000010111500100510000000000000010000000000000000000000000000d11101000000115101111100010001000111110001000000
000b300000bd35000000000050100501005001010ddddd000ddddd00000000000010000000000000d1111000001015d50d00dd000ddddd00000d000000000000
0003500000d351000011100010000500100000000111110001111100000011100151000001100000d5110000000011510100110001111100000d000000000000
0000000000051000015d51005055550150015001000d00000000000000015d5105d511101d511000d1100100001011150ddddd000d000d00000d000000000d00
000000000000000001d5d510100000001000000000010000000000000115d5d51d5d5d51d5d5d110d51100000001110001111100010001000001000000000100
00000000000000005d5d5d5d510101015101010100000000000000001d5d5d5dd5d5d5d55d5d5d51511110000101111000000000000000000000000000000000
0000000000000000000000000051110000551110ddddd5dddddddddd000000000000000000000000d111110000101151dddddddddddddddd0000000000000000
0000000000000000009aaa000051110000111110d1111115d1111115000000000000000000000000d111100000011115d1111111111111150000000000000000
00000000000e800009911a900000510000051000d1155d51d15ddd510000000000000000000020005511010000101151d1515151111111510000010110100000
000e800000e88200011bb1100000510000051000d15000d5d1dd051502202020020002200200200011511010010105d5d1111501010115150001101001011000
0008200000882200b1bbbb100000510000051000d1501051d1d050110200222002020020022020205511010000101151d1515010001011510001010110101000
00000000000220001bbbbbb1005511000005100051d000d5d1d50515000000000000000000002000d111100000011515d1150100000101150010101511010100
0000000000000000011111100051000000551000d15d5d51d1511111000000000000000000000000d111010000105d51d1501000000010510001015151101000
00000000000000000bb090bb0051000000511000d5151515d5151515000000000000000000000000d511100000011515d1110000000001150010151515110100
ddddd505d5000151000000000051110000510000ddddddddddd5d5ddd1000111d515ddddddddd5dd0000000000000000d1510000000011510010115151110100
51111151511015d5000100000051110000510000d11111155111511151101115515151111d1511510101000101010001d1111000000101150001011511101000
01010101d1000151001510000005100000510000d1551d5101010101d50005d111151101151111111010101010101010d1150100001011510010101111010100
00000000d1101515000101000005100000550000d15050d5000000005110111511111010111111111111110111011111dd515010010515150001010110101000
01015101d5005d51001010000005000000050000d1155d5101010101d500015111111101111101111111511151115111d115115110115d510001101001011000
1515d5155d501515000100000001000000050000d1d0d0d51515115151101110101010101010101015151515d515d515511115151115d1d50000010110100000
5d51515115000151000010000000000000000000d15d5d51505151d1d100015001010000010101005d51505151515151d151515151515d510000000000000000
1515150551101515000000000000000000000000d515151500051515d11011150000010000000000151500051515151555151515151515150000000000000000
00000000b6e100000000f1a60000000001000000c6f70000000000000000e70101a7a7a7a7a7a7a7a7a7f600e6b7a7b7b7f600000000e797d6000000a600e701
01b7b7a7a7b7b7a7b756a7b7d700000101000077c7b7a7a7b7b7a730b7a7b7b7a7a7b7a7a7b7a7f6656565e6b7a7d70101c7b7a7a7b7a7a7f60000000000e701
00000000b6e100000000e1a500000000d6003400a600000000000000000000e7d6f0f0f0f0f0f0f0f0f0a656b6f0f0f0f0a6270000000065b5000000a66500e7
d60036460000000000770035000000c6d600007700d300d3003400770000d3d3d3004400343030c7222222d730000000000000f0f0f00000a600000000e6f6e7
000000e6d7e100000000e1c7f6000000b5003500c7a7a7b7a7a7f60000000000b6000000000000000000c7a7d700000000c7a7f6e6f60000b6000000a5000000
b50046369096008300770046008585a6b5000077b1b1b1b1b1b1b166b1b1b1b1b1b1b1b1b1770000000000007700000000440076d0960034a500000000e7f700
000000b5e1f100000000e1f1a6000000b5003600450000000000a600e6f60000b5252500008525000000004700000000003600a6e7f70000b6000000a5000000
b6343546c656676730560036003600a5b50075663700000037000000000000000000370000300000000000001700003030b1b1b1b1b1b1b1a500000027000000
000000b5f1000000000000e1a5000000b5444600360000003400a600b5a50000b5314100000000000000000000000000004700a600000055b5000000a6550000
e7d63141a6170046c7d74141313131a6b60031340000d3000000000000340000300000000000000000000000770000a6b600000000370047a600e6b7a7a7a7f6
000000b6e1000000000000f1a6000000b5364663460000003500a500b5a50000b6313600000000000000909600000000000000c7a7b7a7b7d7000000c7a7b7f6
e6d73141c717003600363141354141a6b6413131314141564131306730414131770000000000000000000000770000a5b682000082000000a600b5f0f0f0f0a6
0000e6d7f1000000000000e1c7f6000066314131413000004600a500e7f70000b6360000000000000000565700510086800000560000000037006000470000a5
b54141314130344600354135454131a5b531414500373100d3004400003100441700d3d30030000000000000170000a5b500000000003400a500b600000000a5
0000b5e1f1000000000000e1e1a60000b545305666d784944600a60000000000b6470000000000007484779424947484940000170000003400003400000044a5
b5414131413031414141560767070757b54731666707676707663141313007673007308797d600d3d3d30000170000a6b5b1b1b1b1b1b1b1c7a7d7b1b1b1b1a5
0000b6f10000000000000000e1a60000b547a6b6000000003600a5000000e6b7d7000000000074940000170000000000000000170000003500447494340045a6
b63646374741413131410037364600a6b600377700d3004100d300373100d300340066a7b756076767070767300000a6b600000037000000f0000000000000a6
0000b5f1000000e1e1000000f1a50000b600a6b6000000748484c7b7a7b7d757660000249400000000007700009076d0960083170000003600c697d6940046a6
b54647340000414131310000463700a5b5000077314131414131306707673041413177000000000000000000000000a5b50091000091000000000000000000a5
00e6d7e1000000f1e1000000e1c7f600b600a6b6249400000000004600004400340000000000748494006600005607676707675600007457c687878797d666a6
b63634360034413141410000363400a5b500007700d30047004100d300000031003777000000000034004400000000a5b507676707076707076766b1b1b1b1a5
00b6f1e1000000e1f1000000f1e1a600b600a6b60000000044000047000035003600000000000074240017000000000000000000748424c6f700656500e7d6a6
b69441317484248484947494314174a6b500007731414131666707304141313007073000003030314141313067676766b5f0f0f0f0f0f0f0f0f07700003700a5
00b5f100000000f1e100000000f1a600b500a6b60024004446000000000036004500000000000000007417000000000000000000007484a600a4b4c4d400b6a5
b54131314131005666000041314131a6b600007700d30000340000444100d3000000770000d3000000410000000000a6b60000000000000034001782000000a6
00b6f1000000e1e1e1f1000000e1a500b500a5e79797d64536000074c69797d65624560000742494000077842494000024240024847484a6e4f4c4c5d5e5b6a5
b64741410031416656413131310041a5b6000030076707574141413130314141314130670707076767670767300000a5b6b1b1b1b1b1b1b1b1b17700000000a5
00b6e1000000e1c6d6e1000000e1a600d744a5000000b53545007484a60000d7170017e0e0e0e0e0e0e077e0e0e0e0e0e0e0e0e0e0e0e0a6550000000055b6a6
b50047000036000000364600460046c7d70096d000440000004100d3000037300000000000d300d30000007686d096a6b500370000000000000017b1b1b1b1a6
56b5e1000000f1a6b5f1000000f1a5560194c7f60000e78797879787f700e601010057c69787978797875697978787979787879797878756f6e6a7b7f6e63001
b64434000045000000464600360046c60197878797978797978787978787979787978787979787979787879787879701b50000000000000000441700000000a5
57b5f1000000e1a5b6e1000000f1a657010066c7a7a7b7a7b7b7b7a7b7b7a7010100c6f7e6b7b7b7b7b7b756b7a7a7b7b7a7b7a7a7b76630a7a7b7b7a7b76701
b64646003446000000463600460036a601a7a7a7a7b7a7b7a7a7a7a7b7f6550101e6a7b7b7a7a7b7b7a7b7a7a7b7b701b5b1b1b1b1b1308494461782000000a5
00b6e1000000e1a6b5f1000000f1a600d60077454146004446000000000046a6b600a500b50035453545007700000000000000000000665600000000000000a6
b54646004136003400364600450046a6b562626262f162626262626262c7a7a7a7d762626262626262626262626262a6b60000009300170034457700000034a6
e6d7f1000000f1a5b5e1000000e1c7f6b54477413131003637000000000036a6b600a600b63545003535456600000000908651000000000000008696800000a6
b63641313030414131316666413141a5b60000000000000000000000000000000000000000000000b0000000000000a6b5b1b1b1b1b16641313177b1b1b1b1a5
b5e1f1000000f1a5b6e1000000e1e1a5b54566314636444600000000000036a5b600a500b5453600000035000000000030c68797d656670767670707570000a5
b54141317717413131411777413131a5b5000000000000000000000000000000000000000000000076000000000000a5b53700009300774141311700000000a5
b5f1000000f1e0a5b6e0f1000000f1a5b53141353646314544000000000031a5b500a600b6003600250046000000000017c7a7b7d700000000000000660000a5
56670707575730414130575767076766b50000f1626262626262626262626230666262626262626262626262300000a5b6b1b1b1b1b1303131411782000000a6
b5e1000000f166c7d756e1000000e1a5b53141314737366656340000004441a5b500c7b7d70047000000470000000075170000003600000000000000450000a6
b54537414100363131000041313547a5b60000000000000000000000000000c6d600000000000000d2000000000000a5b60034009300173500007700000000a5
b6e1000000e1f0e1e1f0f1000000e1a5b54137470000477766302222223066a6b6009071800000000000000000759500770000004600000000000000370000a6
b62525313100474141000031412525a5b50000000000000000000000000000a5b50000000000b000a0000000000000a6b5b1b1b1b1b166b1b1b130b1b1b1b1a5
b634000000e100f1e100e100000000a5b53600000000007756a6555555b656a5b5000000000000004200000000000000170000003500000000000000000000a5
b64131000031310000314100473131a6b50000000000000000000000000000a6b60000566262626262626262626262a6b50000000000770000470000370000a6
b6464400000000e1f1000000000000a5b53600000000006630c7a7a7a7d730c7d7000000000000004200000000000000175151516600510000000000000000a5
b54131252531418525413125254141a5b60000000000000000000000000000a5b5000000000086000000b000000000a5b60000000000170000000000009300a5
b6364600000000f1e1000000000034a5b54600000000000000313100003007075784940000000000420000000000000017848484c697d6566707076767076757
b6004631413700413100003534c687f7b66262626262626262626262f10000a6b50000000000d20000009600000000a6b5006607676767075707676767070730
b5313500000000e100000000000036c7d73700000000000000313100005607073025000000000042420000000000004277000000c7b7d70000360037453600a6
b5003741413400414100004545c7b7f6b50000000000000000000000000000a6b56262626262626262626262300000a6b50000000000000077000000000000a5
b6313100000000000000000034004656560000000000000000000042420045c6d6350000000000424200000000000042660000000000000000460000474535a5
d74131000041414700354500000047a5b60000000000000000000000000000a5b60000000000a0000000d200000000a5b50000000000930017340000930034a6
b5314100000000000000000036414100000000000000000000000042420000c7d737000000000042420000000042424200000000000000000047000000354556
663141000041318585454500000000c7d79424847430000000000000000000a6b6000000000000000000a000000000a5b6b1b1b1b1b1b1b130b1b1b1b1b1b157
b6414131000000000000000041413100000000000000005756424231314242000042000000000042420000000042424200000000000000000000003545000045
45000041414500413100003141424200000000000017000000000000000000a5b50000e00000000000000000000000a6b60037000000000000470000000000a5
b5413145000000000000000031313600000096c0968600177742423131424200004290515176804242905196804242429086c076510000000056664545003445
350000413100003141000041414242000086c0768017000000f10000000000c7d70000306262626262626262626262c7d70000000076c096000000e0000000a6
01c6d600000000000000000041c6d60101c697979797d65630c6d65630c6d6010187979787878787878797978797875656979787879797879787878797978701
018787979787879797979787879787010187979797568797878797979787970101000077c6979797878797978797d60101c68787979787979787d63000000001
__map__
107c7d430000000000000000007c7d10107c7b7b7b7a7a7b7a7b7b7a6f000010107b7b7a7b6f00000000000000007e1010353535353535353535353535353510107a7b7a7a7b7a7a7a7b7a7a7b7a7b10107a7b7a7a7b7a7a7b7b7a7a7b7a7d10100000657c7b7a7b037a7b7b7b7a7d1010000000000000000000006600000010
5b13131400000000000000000000006a5b00000000096900170068087c7b6f006b0f0f0f0f6a0000000000000000007e6d34343434343434343434343434346c6d0000141300005300000000000000000000000009680000006708141354006c6d000003000000673f6800000000006c6d657b667a757a657b667a650000006c
6b13141300000000000000000000007c7d000000000917693f68000877007c6f6b000000006a0000000000000000000075007200720072007200720072006c5a5b0000141300006400000000000000000000096715000069080000141353005a6b00000000000043000000000000006a5b0f0f0f0f0f0f0f0f0f0f770000005a
5b1414540000000000000000002424000024000000096917006969087100006a5b000000005a6e5656566f00000000005b720072007200720072007200757f6a5b0000141400007300000000000000030376767670767670030000541403007c7d00000000150054003a00000000006a5b00000044000000000044710000005a
5b1313630000000000000000002424000024000000000000000000006500005a5b000000006a652222226600000000006500720072007200720072006c7f037c7d00001314000000000000000000006a6b0000000000006808000074137700030370031314141313141303435400005a6b1b1b1b1b1b1b1b1b1b1b650000006a
6b6414730000000000000000006c7878796d002400000000000000000000005a6b000000005a5b0000005a00000000006b72000000720000007200037f0300000024240000242400000000000000005a6b000000150015000000000073710000000077537400000000007713147576035b006300000000640000000f0000005a
6b5354000000000000000000005a6600725b242400000000000000000000006a5b000000007c7d0000007c7b7b7a6f00750072007200720072006c7f006b00000024240000242400000000000000005a5b0000757070767670766600007576030300667300000000000077730000005a5b00730000000053000000000000005a
6b6463000000000000000000007c7a6f005b246500000000000000000000006a5b000000000f0f0000000f0f0f0f7c6f5b0000000000000000757f00005b00000024240000242400000000000000006a5b00000967000000000071000000006c6d00540000000000000071001500005a5b00000000000063000009683f69396a
6b73740000000000000000000000005a007e796d24000000000000000000006a6b002400000000000000000000000f5a03007200720072006c7f5600005b00000024240000242400000000000000006a6b00001500156808000077156908006a6b00530000000015003a03760314145a6b0000031b1b1b1b1b1b756c7979787f
6b1e00000000001e1f00000000001e5a0000725b24000000000000000000005a5b00240000000000000000000000006a5b720000007200667f000000005b006c78796d2424131400000000000000005a0370767676707603000003767003005a0376767076707670767603000000745a5b0000710e0e0e0e0e0e776a72000000
6b1e00000000001e1e00000000001f5a0000007e6d000000000000000024006a5b24242400000000000000000024006a660000006579797f55005600555b005a00006b2424141300000000000000005a5b00000000000077000009680077005a5b00000000000000003a77430015006a5b000066767076767070657c7a7a7a6f
5b1f00000000001f1e00000000001e5a000000725b000000000000000024245a6b24242424000000000024000024005a5b0000006a6e7a7b7b7a7a7b6f6b006a00005b2424131400000000000000005a5b00693f68000071156908000071005a6b0000000000000000000313140376035b0000770f0f0f0f0f0f71000000006a
5b1e1e0000001e1e1f1f0000001f1e5a000000006b000000000000000024247c7d24242424240000000024002424245a5b0000007c7d0000000000007c7d006a00005b2424141343000000000000006a6b00006600000066767003000077006a6b00000000000000000013540000005a6b0000031b1b1b1b1b1b031b1b1b1b6a
7e6d1f0000001e6c6d1e0000001e6c7f000000005b00000000000000242424000024246c6d242400000024246c6d246a6b00000000000000000000000000005a00007e7978796d64440000000000005a6b00007100000009696808000077005a5b00000003000000000000640000005a6b00000000007300000064000000005a
006b1e0000001f7c7d1e0000001f6a6e6f0000005b0000093f683a08242424000024246a5b242400000024246a5b246a5b000000000000006c6d00000000007c6f00000000006b63540000000000006a5b00007700150000150000150077006a5b00000077000015000000741500005a5b0000000e0000000e0074000e00006a
666b1e0000001f1e1e1e0000001e6a65106f0000650000757879797878796d101079797f7e796d673f696c787f7e6d1010787979787879797f7e797879797810106f000000007e7979787879787879101000006c797878797979787978030010100000006c797878797979787879781010797878797978797978787903000010
765b1e1f0000001e1f0000001f1e5a66107f0000750000030000000000007e10107a7b7a7b7a7d0000006a0000007e10107f000000000000000000006e7a7b10107b7a7a7a7b7a7b757a7b7b7a7a66101000007c7a7b7b7b7a7a7b7a7a030010100000007c7b7a7a7b7b7a7a7b7a7b7a7b7a7b7a7a7b7a7a7b7b7a7a03000010
007e6d1f0000001e1f0000001e6c7f7e7f0000005b00006a000000000000007e6d0000000000750000005a006e6f007e7f7200006e7b7a7b7a6f00005b00000000000000000000001e00000000001f6c6b00000928670000002800000077006a6b00000003000000000000006600000067686900000003750f0f0f131400006a
00006b1e0000001e1e0000001f5a0000000000006b00005a00000000000000006b00000000000f0000006a007e7f0000000000006b0f0f0f0f6a00006b0000000000000000000000000000000000005a5b00000000000000000000000077005a5b0000000f00000000000000000000000000000000000000000000141300005a
00005b1e00000000000000001e6a00006e7b7a7b7d00007c7b7b7a7a7a7b7a6f6b0000000000000000005a00000000006e7a7b7b7d000000007c7a7b7d0000000000000000000000000000000000006a5b00000000000000000000000071005a5b0000000000000e00000000000000000000000000000000000000141300005a
00005b1f1f0000000000001e1e5a00005b00000000000000091700006808006a5b00000000037670767670767670666f5b0000000000000000000000000000667676766500000065766600000000005a6b2626262626262626261e000071006a6b00000000682f0300003900750019170000001917006500000000145300436a
00007e6d1e0000000000001e6c7f00006b00000000000000000000000000005a6b00000000096900002800000067085a6b00000000000000000000000000006c6d0f0f0f0000000f0f0f00000000006a6b00000000000000000000000071005a657670707676767076767676707670707676707076760300000000135444645a
0000005b1e0000000000001f6a0000006b00000000000000000000000000005a5b00000000000000000000000000006a5b00000000000000000000000000005a6b0000000e0e0e0000000e0e0e00006a5b00000000000000000000000077005a5b0000000000000000000300000000000300000000000300000000141363635a
0000006b1f0000000000001e5a0000005b00000000000000000000000000006a6b09682800000000006908000000006a6b00000000000000000000000000006a5b00000065766600000065766600006a5b00000928670000002800000077006a5b0000000000000000000000000000000000000000000000000000131464636a
0000006b1e1f000000001f1e6a0000006b00096900000000000000170800006a6b65787878787878787866000000006a5b00000376767676766500006c79797f6b00000000000000000000000000005a6b0000001e262626262626262671006a6b0000000019007500001900000300001900000300170017000000141364646a
0000007e6d1e000000001f6c7f0000007e787978796d0000006c78796d00005a5b757a7b7a7b7b7a7b7b75000000005a5b00000f0f0f0f0f0f0f1f1e6a7200006b00000000000000000000000000006a5b00000000000000000000000071435a5b0000757670767076707676767070767676707676707676767065135463645a
000000005b1e000000001e6a000000006e7b7a7a7b7d0000005a00006b00005a6b09670000280000006808000000005a6b00000000000057585900005a0000005b00000000000000000000000000006a5b00000000000000000000000077545a5b000077000000000000000071000000000000000000672f680000535454145a
000000005b1f000000001e5a000000005b63430074000000006a00005b00006a5b00000000000000000000000000005a5b00000000000000000000006a0000005b0000001f1e1f6576661e1f1e65665a5b2626262626262626261e000077135a5b0000770000000000000000770000000000000000000000000000545353545a
000000006b1e000000001e6a000000005b64530054000000005a00005b00007c7d00000000000000000000000000005a5b00000000000000005757596a0000005b00000000000000000000004400546a6b00000000000000000000000003146a6b0000030000000300000000030000091900000068080000000000131300536a
000000005b1e000000001e6a000000005b49424775000000005a00006b0000000000000075000000000000000000006a6b00000000000000000000006a6e6f006b00000000000000000000006400645a6b00000000000000000000000000145a6b0000000000007700000000000000656d2222226c750000002424145400545a
000000005b1f000000001f6a000000005b00000077001769676a00005b682f69692f680077096800002800000069086a6b00000000000000000000006a7e7f6e7d1f0000000000001f0044545300637c5b000000092800000000282f6708137c7d0000000000007719000000000000710055555500771900002424141454146a
000000005b1e000000001e6a0000000010000000656c7879797f00007e786d10107878786578787979787879787878101078787978796d75656968676a006e101075787979797878757879786d007410100047036c79787979787879787879101079787879797879797878797879797878797878797978797978787979787910
__gff__
0001010201014000040404040000040402010102024040404040400202000404000002020202040440404040404040000000020204040000404040404040400002020800000202080808020202020202020210000000001010100202020202000202010000020200000002020202020202020000000202020202020202020202
__sfx__
000100000011004120001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000000610006100361005610086100b6100f620156201c620226102a6102b6100060000610006100061000620006200060000610006100061000620006200060000000000000000000000000000000000000
00020000290202623022440206301d6301862014620116200e6200b62008610066100561001600016100161001600016000061000610006000060000610006100060000610006100000000000000000000000000
000100001f6301e630000001464012640000000000018630156300000000000086300463000000000000462001620006000060000610006100061000610006100061000610006000060000600006000000000000
0001000023230222401e2401923011230092300823005620046200262000620006200062001620016100161000610006000000000000000000000000000000000000000000000000000000000000000000000000
000100002462023620000002362000000296300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002a630226301e600236401760013630116000e6200c6200960007620066100461003610016000062000620006100060000610006100000000610006100000000610006100061000000000000000000000
0002000025140281302b1302c1202d2202c2302923025220202201963014630106400f62010720137101772018730197301873015720116100c6100a610086100561004610026100061000610006100061000610
000100001d1201813014120111200f1100c1100b1100d1101011014120171201c1302213029120007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000e0300d00010120180001c130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000044100541005720067300a73011720187101c410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007000032f4031f4030f302ff302df302cf302af3029f3027f3025f3023f3022f2021f201ff201ef201df201cf201bf1019f1018f1017f1016f1015f1014f1012f1011f1010f100ff100ef100df100cf100bf10
0103000015c3017c301ec4024c402ec0036c002dc000ef400ef4014f0016f0016f0015f4015f4013f0014f001df301c20024f401d2002af401d20024f401ef002df3029f0021200222002420026200282002b200
0110000018022180210c00300005180250c003180250c0031f025000050c0030c0031c025000051a0250000515022150210c00300000150250c003150250c0031a025000000c0030c003000000c0030c00300000
0110000018022180210c01300005180250c013180250c0131f025000050c0130c0131c0350c6051a0250c60515022150210c01300000150250c013150250c0131a025000000c0130c0130c6050c0130c0130c605
0110000018022180210c01300005180250c013180250c0131f025000050c0230c0131c0250c6151a0250c61515022150210c01300000150250c013150250c0131a025000000c0130c0130c6150c0130c0130c615
0110000018022180210c013180251a0251c025180250c0131f0250c0130c0131f0251d025180251a0250c01315022150210c01315025180251c0251d0250c0131d0250c0130c0030c013000000c0030c01300000
011000000c0130c0030c01300005180050c013180050c0130c013000050c0030c0131c0050c6051a0050c6050c0130c0030c01300000150050c013150050c0130c013000000c0130c0130c6050c0130c0130c605
011000000c0130c0030c013000050c6050c0130c0050c0130c013000050c6050c0131c0050c6151a0050c6050c0130c0030c01300000150050c013150050c0130c013000000c0130c0130c6150c0130c0130c615
0110000018022180210c013180251a0251c025180250c0131f0250c0130c6151f0251d025180251a0250c01315022150210c01315025180251c0251d0250c0131d0250c0130c6150c013000000c615000000c615
__music__
01 0d424344
00 0d424344
00 0e424344
00 0e424344
00 10424344
00 10424344
00 0d424344
00 11424344
00 12424344
00 0f424344
00 0f424344
00 13424344
02 13424344
00 4f424344
00 514f4344
02 51424344
__label__
ddddd5dd000000000000000000000000dddddddd51110100000000000000000000000000000000000000000000000000000000000000000000101151ddddd5dd
d1111115000000000000000000000000d111111111101000000000000000000000000000000000000000000000000000000000000000000000010115d1111115
d1501051000000000000000000000000d151515111010100000000000000000000000000000000000000000000000000000000000000000000101011d1501051
d1010105000000000000000000000000d111150110101000000000000000000000000000000000000000000000000000000000000000000000010101d1010105
d1101051000000000000000000000000d151501001011000000000000000000000000000000000000000000000000000000000000000000000011010d1101051
51010105000000000000000000000000d11501001010000000000000000000000000000000000000000000000000000000000000000000000000010151010105
d1505051000000000000000000000000d150100000000000000000000000000000000000000000000000000000000000000000000000000000000000d1505051
d5151515000000000000000000000000d111000000000000000000000000000000000000000000000000000000000000000000000000000000000000d5151515
dddddddd000000000000000000000000d11111000000000000000000000000000000000000000000000000000000000000000000000000000000000000101151
11111115000000000000000000000000d11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000010115
11111151000000000000000000000000551101000000000000000000000000000000000000000000000000000000000000000000000000000000000000101011
01011515000000000005000000000000115110100000000000000000000000000000000000000000000000000000000000000000000000000000000000010101
00101151000000000005000000000000551101000000000000000000000000000000000000000000000000000000000000000000000000000000000000011010
00010115000000000005100000000000d11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101
00001051000000000005100000000000d11101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000115000000000051110000000000d51110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00101151000000000515151500000000d15100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011115000000005000000100000000d11110000101000101010001010100010101000101010001000000000000000000000000000000000000000000000000
00001151000000001011150000000000d11501001010101010101010101010101010101010101010101000000000000000000000000000000000000000000000
001015d5000000005010050100000000dd5150101111110111111101110111111111110111111101010110000000000000000000000000000000000000000000
00001151000000001000050000000000d11511511111511111115111511151111111511111115111101010000000000000000000000000000000000000000000
00101115000000005055550100000000511115151515151515151515d515d5151515151515151515110101000000000000000000000000000000000000000000
00011100000000001000000000000000d15151515d5150515d515051515151515d5150515d515051511010000000000000000000000000000000000000000000
01011110000000005101010100000000551515151515000515150005151515151515000515150005151101000000000000000000000000000000000000000000
00101151000000000051110000000000501510150000000000000000000000000000000000000000d11111000000000000000000000000000000000000000000
01011115000000000051110000000000500000010000000000000000000000000000000000000000d11110000000000000000000000000000000000000000000
00001151000000000000510000000000100510000000000000000000000000000000000000000000551101000000000000000101101000000000000000000000
001015d5000000000000510000000000005001010000000000000000000000000000000000000000115110100000000000011010010110000000000000000000
00001151000000000000510000000000100000000000000000000000000000000000000000000000551101000000000000010101101010000000000000000000
00101115000000000055110000000000500150010000000000000000000000000000000000000000d11110000000000000101015110101000000000000000000
00011100000000000051000000000000100000000000000000000000000000000000000000000000d11101000000000000010151511010000000000000000000
01011110000000000051000000000000510101010000000000000000000000000000000000000000d51110000000000000101515151101000000000000000000
00101151000000000055111000000000005111000000000000000000000000000000000000000000d11111000000000000101151d11101000000000000000000
01011115000000000011111000000000005111000000000000000000000000000000000000000000d111100000000000010111155d5110000000000000000000
00001151000000000005100000000000000051000000000000000000000000000000000000000000551101000000000000001151d11101000000000000000000
001015d50000000000051000000000000000510000000000000000000000000000050000000000001151101000000000001015d5d11110000000000000000000
0000115100000000000510000bd5bd00000051000000000000000000000000000005000000000000551101000000000000001151d51100000000000000000000
00101115005100000005100bb3bd1bd0005511000000000000000000000000000005100000000000d11110000000000000101115d11001000000000000000000
0001110000510000005510bd3bd35d35005100000000000000000000000000000005100000000000d11101000000000000011100d51100000000000000000000
0101111000511100005110dbbdb51351005100000000000000000000000000000051110000000000d51110000000000001011110511110000000000000000000
0010115100511100005511535b533515005511100000000000000000000000000515151500000000d11101000000000000101151d11101000000000000000000
0101111500511100001115bd53bd51315111111000000000000000000000000050000001000000005d51100000000000010111155d5110000000000000000000
000011510000510000051bd31bd3b515350510000000000000000000000000001011150000000000d11101000000000000001151d11101000000000000000000
001015d500005100000515b31115d1bd110510000000000000000000000000005010050100000000d111100000000000001015d5d11110000000000000000000
000011510000510000051bd331bd1113500510000000000000000000000000001000050000000000d51100000000000000001151d51100000000000000000000
001011150055110000051d51d5d11bd1300510000000000000000000000000005055550100000000d11001000000000000101115d11001000000000000000000
0001110000510000005510bd313b1d33505510000000000000000000000000001000000000000000d51100000000000000011100d51100000000000000000000
0101111000510000005110d3515dd351005110000000000000000000000000005101010100000000511110000000000001011110511110000000000000000000
dddddddd13535353315355151511151151535153ddddd5dd00000000000000000055111000000000d11101000000000000101151511101000000000000000000
d111111535151515351515153515151535151515d1111115000000000000000000111110000000005d5110000000000000010115111010000000000000000000
d15ddd5151555351515353515155535151535351d150105100000000000000000005100000000000d11101000000000000101011110101000000000000000000
d1dd051535515b3515b1b53535515b3515b1b535d101010500000000000000000005100000000000d11110000000000000010101101010000000000000000000
d1d0501151155351511351515115535151135151d110105100000000000000000005100000000000d51100000000000000011010010110000000000000000000
d1d50515353b3b3535353535353b3b35353535355101010500000000000000000005100000000000d11001000000000000000101101000000000000000000000
d151111151535351515b515151535351515b5151d150505100000000000000000055100000000000d51100000000000000000000000000000000000000000000
d515151535151515351515153515151535151515d515151500000000000000000051100000000000511110000000000000000000000000000000000000000000
0010115150151015ddddd5ddddddd5dddddddddd00001151dddddddddddddd510055111000000000d11111000000000000000000000000000000000000000000
0101111550000001d1111115d1111115d111111500010115d1d5d1d1d5d511000011111000000000d11110000000000000000000000000000000000000000000
0000115110051000d1501051d1155d51d15ddd5100101151011d11101d1100000005100000000000551101000000000000000000000000000000000000000000
001015d500500101d1010105d15000d5d1dd05150105151500151000151000000005100000000000115110100000000000000000000000000000000000000000
0000115110000000d1101051d1501051d1d0501110115d5100010000010000000005100000000000551101000000000000000000000000000000000000000000
00101115500150015101010551d000d5d1d505151115d1d500000000000000000005100000000000d11110000000000000000000000000000000000000000000
0001110010000000d1505051d15d5d51d151111151515d5100000000000000000055100000000000d11101000000000000000000000000000000000000000000
0101111051010101d5151515d5151515d51515151515151500000000000000000051100000000000d51110000000000000000000000000000000000000000000
0010115100510000d111110000101151000000000000000000000000000000000051110000000000d11101000000000000000000000000000000000000000000
0101111500510000d1111000000111150000000000000000000000000000000000511100000000005d5110000000000000000000000000000000000001010001
00001151005100005511010000101151000000000000000000000000000000000000510000000000d11101000000000000000000000000000000010110101010
001015d50055000011511010010105d5000000000000000000000000000000000000510000000000d11110000000000000000000000000000001101011011111
00001151000500005511010000101151000000000000000000000000000000000000510000000000d51100000000000000000000000000000001010151115111
0010111500050000d111100000011515000000000000000000000000000000000055110000000000d110010000000000000000000000000000101015d515d515
0001110000000000d111010000105d51000000000000000000000000000000000051000000000000d51100000000000000000000000000000001015151515151
0101111000000000d511100000011515000000000000000000000000000000000051000000000000511110000000000000000000000000000010151515151515
0010115100000000d11111000010115100000000000000000000000015ddddddddddddddddddddddd151000000000000000000000000000000001151dddddddd
0001111500000000d111100000011115000000000000000000000000011d5d5dd1d5d1d1d1d5d1d1d111100001010001010100010101000100010115d1111115
00101151000000005511010000101151000000000000000000000000000011d1011d1110011d1110d115010010101010101010101010101000101151d1551d51
010105d50000000011511010010105d5000000000000000000000000000001510015100000151000dd51501011011111111111011101111101051515d15050d5
00101151000000005511010000101151000000000000000000000000000000100001000000010000d115115151115111111151115111511110115d51d1155d51
0001151500000000d11110000001151500000000000000000000000000000000000000000000000051111515d515d51515151515d515d5151115d1d5d1d0d0d5
00105d5100000000d111010000105d51000000000000000000000000000000000000000000000000d1515151515151515d5150515151515151515d51d15d5d51
0001151500000000d5111000000115150000000000000000000000000000000000000000000000005515151515151515151500051515151515151515d5151515
0010115100000000d111110000101151d5dddddddddddd5100000000000000000000000000000000000000000055111000000000000000000000000000000000
0001111500000000d111100000011115101d5d11d5d5110000000000000000000000000000000000000000000011111000000000000000000000000000000000
00101151000000005511010000101151000151101d11000000000000000000000000000000000000000000000005100000000000000000000000000000000000
010105d50000000011511010010105d50001d1001510000000000000000000000000000000000000000000000005100000000000000000000000000000000000
00101151000000005511010000101151000010000100000000000000000000000000000000000000000000000005100000000000000000000000000000000000
0001151500000000d111100000011515000000000000000000000000000000000000000000000000000000000005100000000000000000000051000000000000
00105d5100000000d111010000105d51000000000000000000000000000000000000000000000000000000000055100000000000000000000051000000000000
0001151500000000d511100000011515000000000000000000000000000000000000000000000000000000000051100000000000000000000051110000000000
0010115100000000d111110000101151000000000000000000000000000000000000000000000000000000000051000000000000000000000515151500000000
0001111500000000d111100000011115000000000000000000000000000000000000000000000000000000000051000000000000000000005000000100000000
00101151000000005511010000101151000000000000000000000000000000000000000000000000000000000051000000000000000000001011150000000000
010105d50000000011511010010105d5000000000000000000000000000000000000000000000000000000000055000000000000000000005010050100000000
00101151000000005511010000101151000000000000000000000000000000000000000000000000000000000005000000000000000000001000050000000000
0001151500000000d111100000011515000000000000000000000000000000000051000000000000000000000005000000000000000000005055550100000000
00105d5100000000d111010000105d51000000000000000000000000000000000051000000000000000000000000000000000000000000001000000000000000
0001151500000000d511100000011515000000000000000000000000000000000051110000000000000000000000000000000000000000005101010100000000
0010115100000000d11111000010115100000000d5dddddd00000000000000000055111000000000000000000000000000000000000000000051110000000000
0101111500000000d11110000001111500000000101d5d1100000000000000000011111000000000000000000000000000000000000000000051110000000000
00001151000000005511010000101151000000000001511000000000000000000005100000000000000000000000000000000000000000000000510000000000
001015d50000000011511010010105d5000000000001d10000000000000000000005100000000000000000000000000000000000000000000000510000000000
00001151000000005511010000101151000000000000100000000000000000000005100000000000000000000000000000000000000000000000510000000000
0010111500000000d111100000011515000000000000000000000000005100000005100000000000000000000000000000000000000000000055110000000000
0001110000000000d111010000105d51000000000000000000000000005100000055100000000000000000000000000000000000000000000051000000000000
0101111000000000d511100000011515000000000000000000000000005111000051100000000000000000000000000000000000000000000051000000000000
0010115100000000d111010000101151ddddd5ddddddd5dddddddddd5015101500511100000000000000000015ddddddddddddddddddd5ddddddd5dddddddddd
01011115000000005d511000000101151d1511511d1511511111111550000001005111000000000000000000011d5d5dd11111111d1511511d15115111111115
0000115100000000d11101000010101115111111151111111111115110051000000051000000000000000000000011d1d1515151151111111511111111111151
001015d500000000d1111000000101011111111111111111010115150050010100005100000000000000000000000151d1111501111111111111111101011515
0000115100000000d5110000000110101111011111110111001011511000000000005100000000000000000000000010d1515010111101111111011100101151
0010111500000000d1100100000001011010101010101010000101155001500100551100000000000000000000000000d1150100101010101010101000010115
0001110000000000d5110000000000000101010001010100000010511000000000510000000000000000000000000000d1501000010101000101010000001051
010111100000000051111000000000000000000000000000000001155101010100510000000000000000000000000000d1110000000000000000000000000115
0000115100000000d11101000000000000000000000000000010115105151515501510150000000015ddddddddddddddd1111100000000000000000000001151
00010115000000005d51100000000000000000000000000001011115500000015000000100000000011d5d5dd1d5d1d1d1111000000000000000000000010115
0010115100000000d111010000000000000000000000000000001151101115001005100000000000000011d1011d111055110100000000000000000000101151
0105151500000000d1111000000000000000000000000000001015d5501005010050010100000000000001510015100011511010000000000000000001051515
10115d5100000000d511000000000000000000000000000000001151100005001000000000000000000000100001000055110100000000000000000010115d51
1115d1d500510000d1100100000000000000000000000000001011155055550150015001000000000000000000000000d111100000000000000000001115d1d5
51515d5100510000d5110000000000000000000000000000000111001000000010000000000000000000000000000000d1110100000000000000000051515d51
151515150051110051111000000000000000000000000000010111105101010151010101000000000000000000000000d5111000000000000000000015151515
ddddd5dddddddd51d151000000000000000000000000000000101151d515ddddddddd5ddd515ddddddddd5ddd515dddd511101000000000000000000ddddd5dd
d1111115d5d51100d111100000000000000000000000000000010115515151111d151151515151111d15115151515111111010000000000000000000d1111115
d15010511d110000d1150100101000000000000000000000001010111115110115111111111511011511111111151101110101000000000000000101d1501051
d101010515100000dd515010010110000000000000000000000101011111101011111111111110101111111111111010101010000000000000011010d1010105
d110105101000000d1151151101010000000000000000000000110101111110111110111111111011111011111111101010110000000000000010101d1101051
51010105000000005111151511010100000000000000000000000101101010101010101010101010101010101010101010100000000000000010101551010105
d150505100000000d1515151511010000000000000000000000000000101000001010100010100000101010001010000000000000000000000010151d1505051
d51515150000000055151515151101000000000000000000000000000000010000000000000001000000000000000100000000000000000000101515d5151515
__meta:title__
Flip Knight
by st33d
