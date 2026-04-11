pico-8 cartridge // http://www.pico-8.com
version 17
__lua__

-- delunky
-- by @johanpeitz
-- a demake of spelunky created for demakejam 2018
-- special thanks to
-- * derek yu (@mossmouth) for creating spelunky
-- * matt hughson (@matthughson) for platformer starter kit
-- * darius kazemi (@tinysubversions) for great info on map generation
-- * frederic souchu (fsouchu) for pico-8 token optimisation help
--debug=false
--debug_at_top=false
function _init()
  --extcmd("rec")
  swap_state(title_state)
end

-->8
--------------------------------
-- play state 
--------------------------------
-- entity modes
-- 0 idle/ground/inair
-- 1 ladder
-- 2 ledge
-- 3 fainted
-- 4 dead
function init_play()
  menuitem(1, "accept defeat", function()
    damage_entity(pl, nil, 99)
  end)
  shake(0, 0)
  make_player(0, 0)
  level = 1
  start_next_level(level)
end

function start_next_level(level)
  max_jumps, jumps_left, ok_to_jump = 1, 1, false
  particles, items, new_items, entities = {}, {}, {}, {}
  -- ratios
  local snake_ratio = 0.1 + level * 0.05
  local bat_ratio = 0.1 + level * 0.1
  local spider_ratio = level * 0.1
  local spike_ratio = 0.3 + level * 0.2
  local trap_ratio = 0.1 + level * 0.15
  local treasure_ratio = 0.1 + level * 0.01
  local help_count = 2
  -- make map
  local m = make_map()
  -- build dungeon
  cls()
  local num_rooms = {12, 12, 12, 8}
  for y = 0, 3 do
    for x = 0, 3 do
      local room_type = m[x + 1][y + 1]
      -- copy room to screen
      local ry = room_type
      local rx = flr(rnd(num_rooms[1 + ry]))
      if ry == 0 and rx == 11 then
        num_rooms[1] = 11
      end
      -- only one idol room please
      if (room_type == 5) then
        -- dbl drop 
        rx, ry = 9 + flr(rnd(3)), 2
      end
      if (room_type == 6) then
        -- exit
        rx, ry = 9 + flr(rnd(3)), 3
      end
      if x + 1 ~= m[5] or y + 1 ~= m[6] then
        pal(7, 0)
      end
      sspr(0 + rx * 10, 96 + ry * 8, 10, 8, x * 10, y * 8, 10, 8, chance(0.3))
      pal()
    end
  end
  -- populate tilemap
  for x = 0, 41 do
    for y = 0, 33 do
      -- clear current data
      mset(x + 1, y + 1, 0)
      -- set new data
      local c = pget(x, y)
      if c == 4 then
        mset(x + 1, y + 1, 3)
      end
      -- stone
      if c == 9 and chance(0.5) then
        mset(x + 1, y + 1, 3)
      end
      -- rnd stone
      if (c == 8 and chance(trap_ratio)) then
        -- arrow trap
        local d = 1
        if pget(x - 1, y) == 0 then
          d = -1
        end
        mset(x + 1, y + 1, 16)
        make_arrow_trap(x + 1, y + 1, d)
      end
      if c == 12 and chance(spike_ratio) then
        mset(x + 1, y + 1, 35)
      end
      -- spikes
      if c == 7 then
        mset(x + 1, y + 1, 1)
      end
      -- entry
      if c == 6 then
        mset(x + 1, y + 1, 17)
      end
      -- exit
      if c == 13 then
        mset(x + 1, y + 1, 30)
      end
      -- ladder
      if c == 5 then
        mset(x + 1, y + 1, 14)
      end
      -- ladder floor
      if (c == 14 and chance(bat_ratio)) then
        -- bat
        local b = make_entity((x + 1) * 8 + 4, (y + 1) * 8 + 4, entities)
        add_params({spr = 85, fs = 8, name = "bat", update = bat_update, on_roofhit = bat_roofhit, ix = 0.5, iy = 0.5, mode = 0
        --hang
        }, b)
      end
      -- help(crate/damsel) or stone or gap
      if (c == 15 and help_count > 0) then
        if (chance(0.1)) then
          help_count = help_count + (1)
          if (chance(0.5)) then
            local help = make_item(x + 1, y, 57)
            help.y = help.y + (4)
            help.h, help.name, help.on_hit = 8, "crate", crate_break
          else
            make_damsel(x + 1, y)
          end
        elseif (chance(0.5)) then
          mset(x + 1, y + 1, 3)
        end
      end
      -- spider
      if c == 10 and chance(spider_ratio) then
        make_spider((x + 1) * 8 + 4, (y + 1) * 8 + 4, 0)
      end
      --snake
      if c == 11 and chance(snake_ratio) then
        make_snake((x + 1) * 8 + 4, (y + 1) * 8 + 4)
      end
      if (c == 3) then
        -- altar
        mset(x, y - 5, 78)
        mset(x + 1, y - 5, 79)
        mset(x, y - 4, 94)
        mset(x + 1, y - 4, 95)
        mset(x, y - 3, 0)
        mset(x + 1, y - 3, 0)
        mset(x, y - 2, 110)
        mset(x + 1, y - 2, 111)
        mset(x, y - 1, 127)
        mset(x + 1, y - 1, 127)
        mset(x, y + 1, 32)
        mset(x + 1, y + 1, 33)
        local idol = make_item(x, y, 44)
        idol.x = idol.x + (5)
        idol.y = idol.y - (4)
        add_params({name = "idol", h = 8, value = 100, on_grab = grab_idol, trap = true, big = true}, idol)
      end
    end
  end
  -- make frame
  for x = 0, 41 do
    mset(x, 0, 3)
    mset(x, 33, 3)
  end
  for y = 0, 33 do
    mset(0, y, 3)
    mset(41, y, 3)
  end
  -- place gold
  for x = 1, 40 do
    for y = 1, 32 do
      if (mget(x, y) == 3) then
        local n = is_free(mget(x, y - 1))
        local s = not is_dirt(mget(x, y + 1))
        -- can place item=
        if ((n and s) or (n and y > 0)) then
          if (chance(treasure_ratio)) then
            make_gold(x, y - 1, 62 + rnd(2))
          -- gold
          elseif (chance(0.02)) then
            if (chance(0.6)) then
              make_item(x, y - 1, 29)
            -- stone
            else
              local e = make_item(x, y - 1, 28)
              -- pot
              e.on_landed, e.on_sidecol, e.on_hit = pot_break, pot_break, pot_break
            end
          end
        end
        --have gold inside? 
        if (chance(0.1)) then
          mset(x, y, mget(x, y) + 16)
        elseif (chance(0.05) and not s) then
          -- place a block
          mset(x, y, 47)
        end
      end
      -- background tiles
      if (mget(x, y) == 0 and chance(0.2)) then
        mset(x, y, 48 + rnd(3))
      end
    end
  end
  -- fix tile look
  auto_tile(0, 0, 48, 34)
  -- parse level
  for x = 0, 41 do
    for y = 0, 33 do
      local tile = mget(x, y)
      -- player
      if (tile == 1) then
        pl.x, pl.y = x * 8 + 4, y * 8 + 4
        camx, camy = pl.x - 64, pl.y - 64
        add(entities, pl)
      end
      -- gold
      if (tile == 62 or tile == 63) then
        make_gold(x, y, tile)
        mset(x, y, 0)
      end
      -- item 
      if (tile == 28 or tile == 29) then
        make_item(x, y, tile)
        mset(x, y, 0)
      end
    end
  end
end

function make_spider(x, y, mode)
  local s = make_entity(x, y, entities)
  add_params({spr = 82, name = "spider", update = spider_update, on_landed = spider_landed, on_sidecol = spider_sidecol, mode = mode}, s)
  if mode == 1 then
    activate_spider(s)
  end
end

function make_snake(x, y)
  local s = make_entity(x, y, entities)
  add_params({name = "snake", fs = 8, spr = 80, frames = 2, delay = 5, dir = (chance(0.5) and 1 or -1), g = 0.5, update = snake_update, on_sidecol = snake_sidecol}, s)
  s.dx = s.dir / 2
end

function spider_sidecol(e)
  e.dx = e.odx
end

function shake(len, pwr)
  screenshake, screenshake_pwr = len, pwr
end

function is_free(tile)
  if tile == 0 or tile == 48 or tile == 49 then
    return true
  end
  return false
end

function is_dirt(tile)
  if (tile >= 2 and tile <= 5) or (tile >= 18 and tile <= 21) then
    return true
  end
  return false
end

function auto_tile(sx, sy, w, h)
  for x = sx, sx + w - 1 do
    for y = sy, sy + h - 1 do
      local tile = mget(x, y)
      if (is_dirt(tile)) then
        local n = not is_dirt(mget(x, y - 1))
        local s = not is_dirt(mget(x, y + 1))
        local has_gold = (tile > 15 and 16 or 0)
        if (n and s) then
          mset(x, y, 5 + has_gold)
        else
          if n then
            mset(x, y, 2 + has_gold)
          end
          if s then
            mset(x, y, 4 + has_gold)
          end
        end
      end
    end
  end
end

function make_player(tx, ty)
  pl = make_entity(tx * 8 + 4, ty * 8 + 4, entities)
  add_params({name = "player", jumpable = false, g = 0.5, spr = 64, frames = 2, fs = 8, mode = 0, draw = draw_player, on_landed = player_landed, on_air = player_fall, hits_from_above = true, collides_with_player = false, money = 0, health = 3, kills = 3, dead_timer = 0, grab_cooldown = 0, whip = 0, holding = 1, item = nil, stowed = nil, bombs = {}, ropes = {}}, pl)
  add_ropes(3)
  add_bombs(3)
end

function add_bombs(amnt)
  for i = 1, amnt do
    local b = make_bomb(0, 0)
    add(pl.bombs, b)
    del(items, b)
  end
end

function add_ropes(amnt)
  for i = 1, amnt do
    local b = make_rope(0, 0)
    add(pl.ropes, b)
    del(items, b)
  end
end

function crate_break(e)
  del(e.tbl, e)
  for i = 0, 6 do
    local e = make_entity(e.x, e.y, particles)
    add_params({spr = 104, ix = 1, g = 0.3, col = false, dir = sgn(rnd() - 0.5), dx = rnd(2) - 1, dy = -rnd(1), life = 5 + rnd(5)}, e)
  end
  local e = make_entity(e.x, e.y, items)
  e.spr = 39 + flr(rnd(2))
  e.g, e.can_take, e.value = 0.5, true, (e.spr == 39 and -1 or -2)
end

function pot_break(e, whipped)
  if (abs(e.odx) > 2 or abs(e.ody) > 2 or whipped) then
    del(e.tbl, e)
    local r = rnd()
    if (r < 0.2) then
      make_snake(e.x, e.y)
    elseif (r < 0.4) then
      make_spider(e.x, e.y, 1)
    elseif (r < 0.6) then
      make_gold(e.x / 8, e.y / 8, 60 + rnd(4))
    end
    for i = 0, 6 do
      local e = make_entity(e.x, e.y, particles)
      add_params({spr = 103, ix = 1, g = 0.3, col = false, dir = sgn(rnd() - 0.5), dx = rnd(2) - 1, dy = -1 - rnd(2), life = 5 + rnd(5)}, e)
    end
  end
end

function make_arrow_trap(tx, ty, d)
  local e = make_entity(tx * 8 + 4, ty * 8 + 4, entities)
  add_params({name = "arrow trap", spr = 34, dir = d, col = false, update = update_arrow_trap, ammo = 1}, e)
end

function is_triggering_arrow_trap(at, e)
  local dist = 48
  -- 6 tiles
  if (e.dx ~= 0 or e.dy ~= 0) then
    local in_range = false
    if at.dir > 0 and e.x > at.x and e.x < at.x + dist then
      in_range = true
    end
    if at.dir < 0 and e.x < at.x and e.x > at.x - dist then
      in_range = true
    end
    if (in_range) then
      if (e.y >= at.y - 5 and e.y <= at.y + 3) then
        return true
      -- fire!
      end
    end
  end
  return false
end

function update_arrow_trap(at)
  if at.ammo == 0 then
    return
  end
  --update_entity(e)
  for e in all(items) do
    if (is_triggering_arrow_trap(at, e)) then
      fire_arrow(at)
      return
    end
  end
  for e in all(entities) do
    if (is_triggering_arrow_trap(at, e)) then
      fire_arrow(at)
      return
    end
  end
end

function fire_arrow(at)
  sfx(3)
  at.ammo = at.ammo - (1)
  local e = make_entity(at.x + at.dir * 7, at.y, new_items)
  add_params({name = "arrow", spr = 43, h = 4, dir = at.dir, dy = -1, dx = 7 * at.dir, ix = 0.98, g = 0.5, knock_down = true, damage = 2, use = item_throw, drop = item_drop, on_landed = item_landed, on_sidecol = item_sidecol, can_grab = true}, e)
end

function spider_update(e)
  local dx = pl.x - e.x
  if (e.health > 0) then
    if (e.mode == 0) then
      if pl.y > e.y and abs(dx) < 8 then
        activate_spider(e)
      end
    else
      if e.jump_delay > 0 then
        e.jump_delay = e.jump_delay - (1)
      end
      if (e.jump_delay <= 0 and not e.inair) then
        e.spr = 84
        e.dx, e.dy = dx / 20, -rnd(3) - 3
      end
    end
  end
  update_entity(e)
end

function activate_spider(e)
  e.mode, e.spr = 1, 84
  e.g, e.ix, e.jump_delay = 0.5, 1, 5
end

function spider_landed(e)
  e.jump_delay = 5 + rnd(10)
  e.spr = 83
  e.dx = 0
end

function bat_update(e)
  local dx, dy = pl.x - e.x, pl.y - e.y + 4
  local d = sqrt(dx * dx + dy * dy)
  local a = atan2(dx, dy)
  if (e.health > 0) then
    if (e.mode == 0) then
      -- hang
      if (d < 48 and pl.health > 0 and e.y < pl.y + 1) then
        e.spr, e.frames, e.frame = 86, 2, 1
        e.mode = 1
      end
    elseif (e.mode == 1) then
      -- track
      e.dx, e.dy = 0.5 * cos(a), 0.5 * sin(a)
      e.dir = sgn(e.dx)
      if d > 80 or pl.health <= 0 then
        e.mode = 2
      end
    else
      -- return to ceiling
      e.dy = e.dy - (0.2)
    end
  end
  update_entity(e)
end

function bat_roofhit(e)
  if e.mode ~= 2 then
    return
  end
  e.spr = 85
  e.frame, e.frames = 0, 0
  e.mode = 0
  e.dx, e.dy = 0, 0
end

function snake_update(e)
  e.delay = e.delay - (1)
  if (e.bleed_timer > 0) then
    --e.dx=0
    e.fs, e.frames = 9999, 1
    e.spr = 102
    e.delay = 99
  end
  if (e.delay < 0) then
    if (chance(0.1)) then
      e.dx = 0
      e.delay = 15 + rnd(60)
    else
      e.dir = (chance(0.5) and 1 or -1)
      e.dx = 0.2 * e.dir
      e.ix = 1
      e.delay = 60 + rnd(60)
    end
  end
  if (not e.inair and fget(mget((e.x + e.dir * 2) / 8, e.y / 8 + 1)) == 0) then
    e.dir = -e.dir
    e.dx = -e.dx
  end
  update_entity(e)
end

function snake_sidecol(e)
  e.delay = 0
end

function check_item_exit(e)
  if (fget(mget(e.x / 8, (e.y - 4) / 8), 7)) then
    if e.name == "idol" then
      pl.money = pl.money + (e.value)
    end
    del(e.tbl, e)
    pl.item = nil
    switch_to_whip()
    sfx(7)
  end
end

function grab_idol(idol)
  if (idol.trap) then
    idol.trap = false
    -- make boulder
    local e = make_entity(-100, -100, entities)
    add_params({name = "boulder", flip_on_hit = false, knock_down = true, jumpable = false, spr = 74, fs = 2, frames = 2, tw = 2, th = 2, ix = 1, dy = 0, g = 1, damage = 99, health = 9999, w = 16, h = 16, spawnx = idol.x - 1, spawny = idol.y - 24, delay = 60, update = boulder_update, on_landed = boulder_landed}, e)
    shake(e.delay, 3)
  end
end

function boulder_update(e)
  if (e.delay > 0) then
    e.delay = e.delay - (1)
    if (e.delay == 0) then
      e.x, e.y = e.spawnx, e.spawny
      e.dy = 0.01
      e.dir = sgn(pl.x - e.x)
      shake(2, 6)
      e.dropped = false
    end
  else
    local bx = e.x / 8 + e.dir
    local by = e.y / 8
    local tiles = 0
    if (fget(mget(bx, by), 0)) then
      crush_tile(bx, by, e.dx)
      tiles = tiles + (1)
    end
    if (fget(mget(bx, by - 1), 0)) then
      crush_tile(bx, by - 1, e.dx)
      tiles = tiles + (1)
    end
    e.dx = e.dx - (0.20 * tiles * sgn(e.dx))
    update_entity(e)
    if (tiles > 0) then
      auto_tile(bx, by - 2, 1, 4)
      shake(3, 3)
      sfx(6)
    end
    if (abs(e.dx) < 0.6 and e.dy == 0) then
      local tx = e.x / 8
      local ty = e.y / 8 - 1
      mset(tx, ty, 74)
      mset(tx + 1, ty, 75)
      mset(tx, ty + 1, 90)
      mset(tx + 1, ty + 1, 91)
      del(e.tbl, e)
    end
  end
end

function crush_tile(tx, ty, v)
  -- check for gold
  local tile = mget(tx, ty)
  if tile >= 18 and tile <= 21 then
    make_gold_pieces(tx, ty)
  end
  -- remove tile
  mset(tx, ty, 0)
  -- particles
  local amnt = 3 + rnd(3)
  for i = 1, amnt do
    local p = make_entity(tx * 8, ty * 8, particles)
    add_params({spr = 120 + rnd(2), ix = 0.98, dx = v * (1 + rnd(1)), dy = -1 - rnd(1), g = 0.3, life = 20 + rnd(10), col = false}, p)
  end
end

function boulder_landed(e)
  if (not e.dropped) then
    e.dx = 3 * e.dir
    e.dropped = true
  end
  shake(6, 6)
  sfx(6)
end

function make_gold(tx, ty, tile)
  local e = make_entity(tx * 8 + 4, ty * 8 + 4, items)
  e.spr = flr(tile)
  e.g, e.value, e.can_take = 0.5, 5, true
  if e.spr == 60 or e.spr == 62 then
    e.value = e.value * (3)
  end
  return e
end

function make_item(tx, ty, tile)
  local e = make_entity(tx * 8 + 4, ty * 8 + 3, items)
  add_params({name = "#" .. tile, spr = tile, ix = 0.98, g = 0.5, h = 4, use = item_throw, drop = item_drop, on_landed = item_landed, on_sidecol = item_sidecol, can_grab = true}, e)
  e.y = e.y + (4)
  return e
end

function item_sidecol(e)
  e.dx = -e.odx * 0.5
  if abs(e.dx) < 0.1 then
    e.dx = 0
  end
end

function item_landed(e)
  e.dx = e.dx * (0.3)
  if abs(e.dx) < 0.2 then
    e.dx = 0
  end
  if (abs(e.ody) > 2) then
    e.dy = -e.ody * 0.3
  else
    e.dx = 0
  end
end

function item_throw(e)
  e.cooldown, e.damage = 3, 1
  e.dx = pl.dir * (pl.dy < 0 and 3 or 4)
  e.dy = (pl.dy < 0 and -5 or -2)
  pl.item = nil
  switch_to_whip()
  sfx(3)
end

function item_drop(e)
  e.cooldown, e.dy = 3, -1
  e.dx = pl.dir / 2
  pl.item = nil
  switch_to_whip()
  sfx(3)
end

function make_damsel(x, y)
  local di = make_item(x, y, 11)
  di.name = "damsel"
  di.y = di.y + (4)
  di.h, di.big = 8, true
  local de = make_entity(di.x, di.y, entities)
  de.name = "damsel"
  de.spr = 16
  de.collides_with_player = false
  de.update = damsel_e_update
  de.item = di
  de.health = 3
  de.damage = 0
  di.entity = de
  local p = {g = 0.5, ix = 0.98}
  add_params(p, di)
  add_params(p, de)
end

function damsel_e_update(e)
  update_entity(e)
  e.x = e.item.x
  e.y = e.item.y
  -- dead?
  if e.health < 1 then
    e.item.spr = 13
  end
  -- at gate?
  if (fget(mget(e.x / 8, (e.y - 4) / 8), 7)) then
    pl.health = pl.health + (1)
    del(e.tbl, e)
    del(e.item.tbl, e.item)
    pl.item = nil
    switch_to_whip()
    sfx(7)
  end
end

function make_bomb(tx, ty)
  local e = make_item(tx, ty, 25)
  add_params({name = "bomb", h = 4, use = bomb_throw, drop = bomb_drop, update = bomb_update, timer = 0}, e)
  return e
end

local hitarea = {{0, 0, 1, 0, 0}, {0, 1, 1, 1, 0}, {1, 1, 1, 1, 1}, {0, 1, 1, 1, 0}, {0, 0, 1, 0, 0}}

function bomb_update(e)
  if (e.timer > 0) then
    e.timer = e.timer - (1)
    e.spr = 26 + flr(e.timer / 2) % 2
    if (e.timer == 0) then
      e.life = 1
      -- explode
      shake(5, 6)
      make_explosion(e.x - 8, e.y - 8)
      -- destroy entities & tiles
      local ex = flr(e.x / 8)
      local ey = flr(e.y / 8)
      for x = 1, 5 do
        for y = 1, 5 do
          if (hitarea[x][y] == 1) then
            local tx = ex + x - 3
            local ty = ey + y - 3
            --entities
            for e2 in all(entities) do
              if abs(tx * 8 + 4 - e2.x) < 9 and abs(ty * 8 + 4 - e2.y) < 9 then
                damage_entity(e2, nil, 99, 0)
              end
            end
            --tile
            local tile = mget(tx, ty)
            if tile >= 2 and tile <= 5 then
              mset(tx, ty, 0)
            end
            if tile == 47 or tile == 35 or tile == 36 then
              mset(tx, ty, 0)
            end
            if (tile >= 18 and tile <= 21) then
              mset(tx, ty, 0)
              make_gold_pieces(tx, ty)
            end
          end
        end
      end
      auto_tile(ex - 2, ey - 3, 5, 7)
    end
  end
  update_entity(e)
end

function make_gold_pieces(tx, ty)
  local amnt = rnd(3) + 1
  for i = 1, amnt do
    local g = make_gold(tx, ty, 60 + rnd(2))
    add_params({dx = rnd(5) - 3, dy = rnd(5) - 3, g = 0.5, ix = 0.98, can_take = true, inair = true}, g)
  end
end

function bomb_throw(e)
  bomb_activate(e)
  item_throw(e)
end

function bomb_drop(e)
  bomb_activate(e)
  item_drop(e)
end

function bomb_activate(e)
  e.spr = 26
  e.timer = 60
  e.can_grab = false
end

function make_explosion(x, y)
  sfx(5)
  -- dirt
  local amnt = 8 + rnd(8)
  for i = 1, amnt do
    local e = make_entity(x + rnd(24), y - 8 + rnd(32), particles)
    add_params({spr = 118 + rnd(2), dir = sgn(rnd(2) - 1), dy = rnd(0.6) + 0.4, g = 0.1, life = 10 + rnd(4), col = false,}, e)
  end
  -- smalls
  amnt = 8 + rnd(8)
  for i = 1, amnt do
    local e = make_entity(x + 8, y + 8, particles)
    local a = rnd(0.7) - 0.1
    local f = 2 + rnd(2)
    add_params({spr = 112, dir = sgn(rnd(2) - 1), dx = f * cos(a), dy = f * sin(a), ix = 0.95, g = 0.3, fs = 2 + flr(rnd(3)), frames = 6, col = false}, e)
    e.life = e.fs * e.frames - 1
  end
  -- big
  local e = make_entity(x, y, particles)
  add_params({dir = sgn(rnd(2) - 1), spr = 144, tw = 3, th = 3, fs = 2, frames = 3, col = false}, e)
  e.life = e.fs * e.frames - 1
end

function make_rope(tx, ty)
  local e = make_item(tx, ty, 41)
  add_params({name = "rope", use = rope_throw, drop = rope_drop, activated = false, on_roofhit = rope_roof_hit, on_landed = rope_on_landed, update = rope_update, steps = 0, h = 8, flip_on_hit = false}, e)
  return e
end

function rope_update(e)
  if (e.activated) then
    local tx = flr(e.x / 8)
    local ty = flr(e.y / 8)
    if (mget(tx, ty) ~= 31 and mget(tx, ty) ~= 15) then
      if (e.steps == 0 and e.dy > 0) then
        mset(tx, ty, 15)
      else
        mset(tx, ty, 31)
      end
      e.steps = e.steps + (1)
      if (e.steps == 8) then
        e.on_roofhit(e)
      end
    end
  end
  update_entity(e)
end

function rope_drop(e)
  -- can drop?
  local tx = flr((e.x + pl.dir * 4) / 8) + pl.dir * 0
  local ty = flr(e.y / 8)
  local ty2 = flr(e.y / 8) + 1
  if (not is_solid(tx, ty) and not is_solid(tx, ty2)) then
    add_params({x = tx * 8 + 4, spr = 31, dy = 4, dir = 1, g = 0, activated = true}, e)
    pl.item = nil
    switch_to_whip()
  else
  -- do nothing. item_drop(e)
  end
end

function rope_throw(e)
  sfx(3)
  -- adjust position
  e.x = flr(e.x / 8) * 8 + 4
  e.y = e.y - (5)
  -- make sure there is nothing direcly on top
  if (fget(mget(e.x / 8, e.y / 8), 0)) then
    return
  end
  -- drop it
  e.spr = 15
  e.dy = -4
  e.dir = 1
  e.g = 0
  e.activated = true
  pl.item = nil
  switch_to_whip()
end

function rope_on_landed(e)
  del(items, e)
end

function rope_roof_hit(e)
  mset(flr(e.x / 8), flr(e.y / 8), (e.dy > 0 and 31 or 15))
  del(items, e)
end

function player_fall()
  jumps_left = max(0, jumps_left - 1)
end

function player_faint()
  pl.bleed_timer = (pl.health == 0 and 60 or 30)
  pl.faint_timer = pl.bleed_timer
  if pl.mode == 4 then
    return
  end
  pl.mode, pl.spr = 3, 68
  pl.frame, pl.frames = 0, 1
  if (pl.item ~= nil and pl.holding == 1) then
    pl.item.drop(pl.item)
    pl.item = nil
  end
end

function player_landed(e)
  jumps_left = max_jumps
  local impact = 0
  if pl.ody >= 8 then
    impact = impact + (1)
  end
  if pl.ody >= 11 then
    impact = impact + (1)
  end
  if pl.ody >= 13 then
    impact = impact + (97)
  end
  if (impact > 0) then
    damage_entity(pl, nil, impact)
    player_faint()
  end
  if (pl.mode == 3) then
    -- fainted
    -- bounce
    if (pl.ody > 3) then
      pl.dy = -0.3 * pl.ody
    end
  end
end

function drop_from_ledge()
  add_params({mode = 0, spr = 64, frames = 2, dx = -pl.dir, grab_cooldown = 5}, pl)
end

ok_to_jump, ok_to_crouch = true, true
maxdy = 0

function update_play()
  -- add for additional 18 tokens
  --if (btnp(0,1)) extcmd("rec") 
  --if (btnp(3,1)) extcmd("video")
  if not btn(2) then
    ok_to_jump = true
  end
  if not btn(3) then
    ok_to_crouch = true
  end
  -- mode 0 = idle/ground/jump
  if (pl.mode == 0) then
    if pl.item ~= nil and pl.item.name == "idol" then
      check_item_exit(pl.item)
    end
    if btnp(4) then
      switch_item()
    end
    if pl.grab_cooldown > 0 then
      pl.grab_cooldown = pl.grab_cooldown - (1)
    end
    pl.grab = false
    -- left/right
    if (btn(0)) then
      pl.dx = pl.dx - (2)
      pl.dir = -1
      pl.grab = true
    end
    if (btn(1)) then
      pl.dx = pl.dx + (2)
      pl.dir = 1
      pl.grab = true
    end
    -- whip?
    if (btnp(5) and pl.item == nil) then
      pl.whip = 10
      sfx(0)
    end
    if pl.whip > 0 then
      pl.whip = pl.whip - (1)
    end
    -- use item?
    if (btnp(5) and pl.item ~= nil) then
      if (btn(3)) then
        pl.item.drop(pl.item)
        ok_to_crouch = false
      else
        pl.item.use(pl.item)
      end
    end
    -- jump / grab climable
    if (btn(2)) then
      -- check for climbables
      if (fget(mget(pl.x / 8, pl.y / 8), 2)) then
        pl.mode = 1
        pl.dx = 0
      elseif (fget(mget(pl.x / 8, pl.y / 8), 7)) then
        --exit_level()
        level = level + (1)
        start_next_level(level)
      elseif (jumps_left > 0 and ok_to_jump) then
        -- regular jump
        pl.dy = -3.2
        jumps_left = jumps_left - (1)
        pl.inair = true
        ok_to_jump = false
        sfx(4)
      end
    end
    -- climb down
    if (btn(3)) then
      -- check for climbables
      if (fget(mget(pl.x / 8, (pl.y + 4) / 8), 2)) then
        pl.mode = 1
        pl.dx = 0
        pl.y = pl.y + (1)
      end
    end
  elseif (pl.mode == 1) then
    -- mode 1 = climbing
    pl.whip = 0
    pl.dy = 0
    pl.spr = 70
    pl.x = pl.x + ((8 * flr(pl.x / 8) + 4 - pl.x) * 0.4)
    if btn(2) then
      pl.dy = -1
    end
    if btn(3) then
      pl.dy = 1
    end
    local drop = false
    if (btn(0)) then
      pl.dx = pl.dx - (2)
      pl.dir = -1
      drop = true
    end
    if (btn(1)) then
      pl.dx = pl.dx + (2)
      pl.dir = 1
      drop = true
    end
    -- still on climbable?
    if not fget(mget(pl.x / 8, (pl.y - 2) / 8), 2) and not fget(mget(pl.x / 8, (pl.y + 3) / 8), 2) then
      drop = true
    end
    if (drop) then
      add_params({inair = true, mode = 0, spr = 64, frame = 0, frames = 2}, pl)
      ok_to_jump = false
    end
  elseif (pl.mode == 2) then
    -- mode 2 = ledge 
    -- drop big items om ledge
    --if (pl.item and pl.holding==1 and pl.item.big) then
    -- pl.item.drop(pl.item)
    -- pl.item=nil
    --end
    add_params({whip = 0, dx = 0, dy = 0, spr = 69, frame = 0, frames = 1}, pl)
    if (btn(2) and ok_to_jump) then
      add_params({mode = 0, spr = 64, frame = 0, frames = 2, dy = -1}, pl)
      ok_to_jump = false
    end
    if btn(3) then
      drop_from_ledge()
    end
  elseif (pl.mode == 3) then
    -- mode 3 = fainted
    pl.whip = 0
    pl.faint_timer = pl.faint_timer - (1)
    if (pl.faint_timer == 0) then
      if (pl.health > 0) then
        pl.spr = 64
        pl.frames = 2
        pl.ix = 0
        pl.mode = 0
      else
        --dead
        pl.mode = 4
      end
    end
  -- tears, not uses any more
  --[[
  if (pl.dy==0 and rnd()<0.99 and pl.health>0) then
   local e=make_entity(pl.x,pl.y+3,particles)
   add_params({
    spr=96+flr(rnd(3)),
    dy=-1,
    dx=(rnd()<0.5 and -1 or 1)/2,
    ix=1,
    g=0.2,
    life=7+flr(rnd(4)),
    col=false
   },e)
  end
  ]]
  --
  elseif (pl.mode == 4) then
    -- mode 4 = dead
    pl.dead_timer = pl.dead_timer + (1)
    if btnp(5) and pl.dead_timer > 15 then
      swap_state(title_state)
    end
  end
  -- idle anim
  --if (pl.mode==0) then
  -- pl.spr=64
  -- if (abs(pl.dx)==0) pl.spr=(pl.inair==false and 66 or 64)
  --end
  for e in all(items) do
    if (e.inair == true) then
      -- check for impact with entities
      for e2 in all(entities) do
        if (e.cooldown == 0 or e2 ~= pl) then
          local v = sqrt(e.dx * e.dx + e.dy * e.dy)
          if (v > 3 and abs(e2.x - e.x) < 5 and abs(e2.y - e.y) < 5) then
            if (not (e.name == "rope" and e2 == pl) and e.name ~= e2.name) then
              damage_entity(e2, e)
              if e.flip_on_hit then
                e.dx = -e2.dx / 2
              end
            end
          end
        end
      end
    end
    -- instant pickup?
    if (e.can_take) then
      if (abs(pl.x - e.x) < 4 and abs(pl.y - e.y) < 4) then
        if (e.value ~= nil) then
          sfx(7)
          if e.value == -2 then
            add_bombs(3)
          end
          if e.value == -1 then
            add_ropes(3)
          end
          if e.value > 0 then
            pl.money = pl.money + (e.value)
          end
        end
        del(items, e)
      end
    end
    if (e ~= pl.item) then
      -- pickup item?
      if (pl.mode == 0 and btn(3) and e.can_grab and not pl.inair and abs(pl.x - e.x) < 5 and abs(pl.y - e.y) < 5 and ok_to_crouch) then
        if (pl.stowed_item ~= nil) then
          add(items, pl.stowed_item)
          set_item_to_player_pos(pl.stowed_item)
          pl.stowed_item.inair = true
          pl.stowed_item = nil
        end
        if (pl.holding == 2) then
          del(items, pl.item)
          add(pl.bombs, pl.item)
        end
        if (pl.holding == 3) then
          del(items, pl.item)
          add(pl.ropes, pl.item)
        end
        pl.item = e
        pl.holding = 1
        ok_to_crouch = false
        if e.on_grab then
          e.on_grab(e)
        end
      end
      e.update(e)
    end
    -- check whip
    if (pl.whip > 0) then
      if (abs(pl.x + 8 * pl.dir - e.x) < 6 and abs(pl.y - e.y + 2) < 8 and e.on_hit) then
        e.on_hit(e, true)
        pl.whip = 0
      end
    end
  end
  for e1 in all(entities) do
    -- e2e collision
    for e2 in all(entities) do
      if (e1 ~= e2 and e1.damage >= 0 and (e1.collides_with_player or e2.collides_with_player)) then
        if (abs(e2.x - e1.x) < (e2.w + e1.w) / 2 - 2 and abs(e2.y - e1.y) < (e2.h + e1.h) / 2 - 2) then
          e2e_coll(e1, e2)
        end
      end
    end
    -- spikes?
    if (e1.inair and e1.health > 0 and e1.name ~= "bat") then
      local tx = flr(e1.x / 8)
      local ty = flr((e1.y + 3) / 8)
      if (e1.dy > 0 and fget(mget(tx, ty), 3)) then
        mset(tx, ty, 36)
        damage_entity(e1, nil, 99)
      end
    end
    -- check whip
    if (e1 ~= pl and pl.whip > 0) then
      if (abs(pl.x + 8 * pl.dir - e1.x) < 6 and abs(pl.y - e1.y) < 6 and e1.bleed_timer == 0) then
        damage_entity(e1, nil, 1, pl.dir, -1)
      end
    end
    -- update it
    e1.update(e1)
  end
  if (pl.item ~= nil) then
    set_item_to_player_pos(pl.item)
  end
  for e in all(particles) do
    e.update(e)
  end
  -- add new items
  for e in all(new_items) do
    add(items, e)
  end
  new_items = {}
end

function bleed(x, y)
  local e = make_entity(x, y, particles)
  add_params({spr = 99, dx = rnd(4) - 2, dy = -1 - rnd(), ix = 0.95, g = 0.5, fs = 3 + flr(rnd(3)), frames = 3, col = false}, e)
  e.life = e.fs * e.frames - 1
end

-- e1 hits e2
function e2e_coll(e1, e2)
  --debug_str=e1.name.."+"..e2.name
  -- no hit if already bleeding
  if e1.bleed_timer > 0 or e2.bleed_timer > 0 then
    return
  end
  local over, under = e1, e2
  if (e2.y < e1.y) then
    over = e2
    under = e1
  end
  -- if coming from above
  if (over.hits_from_above and over.inair and over.dy > 0 and under.jumpable) then
    damage_entity(under, over, 0, -3)
    if over.flip_on_hit then
      over.dy = -3
    end
  else
    -- regular hit only if player or boulder is involved
    if over == pl or over.name == "boulder" then
      damage_entity(over, under, 1 * sgn(over.x - under.x), -1)
    end
    if under == pl or over.name == "boulder" then
      damage_entity(under, over, 1 * sgn(under.x - over.x), -1)
    end
  end
end

function damage_entity(e1, e2, impact, dx, dy)
  if (e2 ~= nil) then
    e1.health = e1.health - (e2.damage)
    if e1.flip_on_hit then
      e1.dx = 3 * sgn(e1.x - e2.x)
    end
  else
    e1.health = e1.health - (impact)
  end
  if dx then
    e1.dx = e1.dx + (dx)
  end
  if (dy and e1.flip_on_hit) then
    e1.inair = true
    e1.dy = e1.dy + (dy)
  end
  if (e1.health <= 0 and e1 ~= pl) then
    e1.ix = 0.7
    pl.kills = pl.kills + (1)
  end
  e1.dy, e1.bleed_timer = -3, 30
  if (e1 == pl) then
    if ((e2 and e2.knock_down) or pl.health <= 0) then
      player_faint()
    elseif (pl.mode == 2) then
      drop_from_ledge()
    end
  end
  sfx(1)
end

function set_item_to_player_pos(e)
  e.x, e.y = pl.x + pl.dir * 3, pl.y + pl.frame - 1 - e.h / 2 + 4
  e.dir = pl.dir
end

function switch_to_whip()
  pl.holding = 1
  -- use stowed item if any
  if (pl.stowed_item ~= nil) then
    pl.item = pl.stowed_item
    pl.stowed_item = nil
    add(items, pl.item)
  else
    pl.item = nil
  end
end

function switch_item()
  if pl.item and pl.item.big then
    return
  end
  -- handle current item
  if (pl.holding == 1) then
    if (pl.item ~= nil) then
      -- stow away
      del(items, pl.item)
      pl.stowed_item = pl.item
      pl.item = nil
    end
  end
  if (pl.holding == 2) then
    add(pl.bombs, pl.item)
    del(items, pl.item)
    pl.item = nil
  end
  if (pl.holding == 3) then
    add(pl.ropes, pl.item)
    del(items, pl.item)
    pl.item = nil
  end
  -- check for next item
  pl.holding = pl.holding + (1)
  if pl.holding == 2 and #pl.bombs == 0 then
    pl.holding = pl.holding + (1)
  end
  if pl.holding == 3 and #pl.ropes == 0 then
    pl.holding = pl.holding + (1)
  end
  if pl.holding > 3 then
    pl.holding = pl.holding - (3)
  end
  -- set next item
  -- whip/item
  if (pl.holding == 1) then
    pl.item = nil
    switch_to_whip()
  end
  -- bombs
  if (pl.holding == 2) then
    pl.item = pl.bombs[1]
    add(items, pl.item)
    pl.item.tbl = items
    del(pl.bombs, pl.item)
  end
  --ropes
  if (pl.holding == 3) then
    pl.item = pl.ropes[1]
    add(items, pl.item)
    pl.item.tbl = items
    del(pl.ropes, pl.item)
  end
end

function die(tile)
  add_params({mode = 99, spr = 68, frame = 0, frames = 1, dy = 0.4, dx = 0, t = 0}, pl)
end

function draw_player()
  draw_entity(pl)
  if (pl.whip > 0) then
    local s = 122
    if pl.whip < 9 then
      s = 123
    end
    if pl.whip < 9 then
      s = 124
    end
    spr(s, pl.x + pl.dir * 6 - 4, pl.y - 4 + pl.frame % 2, 1, 1, pl.dir == -1)
  end
end

function draw_play()
  cls()
  local lx, ly = pl.x - camx, pl.y - camy
  -- pan camera but give player some room to move around in
  if lx < 48 then
    camx = camx - (2)
  end
  if lx > 80 then
    camx = camx + (2)
  end
  if ly < 48 then
    camy = camy + ((ly - 48) * 0.5)
  end
  if ly > 80 then
    camy = camy + ((ly - 80) * 0.5)
  end
  local sx, sy = 0, 0
  if (screenshake > 0) then
    screenshake = screenshake - (1)
    sx = rnd(screenshake_pwr) - screenshake_pwr / 2
    sy = rnd(screenshake_pwr) - screenshake_pwr / 2
  end
  -- lock camera inside map (and shake if needed)
  camera(min(208, max(camx, 0)) + sx, min(144, max(camy, 0)) + sy)
  --camera(camx+sx,camy+sy)
  map(0, 0, 0, 0, 50, 34)
  for e in all(entities) do
    e.draw(e)
  end
  for e in all(items) do
    e.draw(e)
  end
  for e in all(particles) do
    e.draw(e)
  end
  -- hud
  camera()
  spro(25, 0, 4, 0)
  printo(#pl.bombs, 11, 3, 7, 0)
  spro(41, 21, 0, 0)
  printo(#pl.ropes, 31, 3, 7, 0)
  spro(62, 45, 0, 0)
  printo(pl.money * 10, 56, 3, 7, 0)
  for i = 1, pl.health do
    spro(42, 128 - i * 9, 2, 0)
  end
  -- instructions, 10 seconds, first level
  if (pl.t < 300 and level == 1) then
    rectfill(0, 114, 127, 127, 1)
    print("arrows - move, jump, and climb", 4, 115, 7)
    print(" z / x - use and handle items", 4, 122, 7)
  end
  -- game over
  if (pl.mode == 4) then
    local y = max(44, 128 - pl.dead_timer)
    printo("game over", 46, y, 7, 1)
    printo("depth: " .. level, 42, y + 20, 7, 1)
    printo(" gold: " .. pl.money * 10, 42, y + 28, 7, 1)
    printo("kills: " .. pl.kills, 42, y + 36, 7, 1)
  end
end

function spro(id, dx, dy, oc)
  for i = 0, 15 do
    pal(i, oc)
  end
  for x = -1, 1 do
    for y = -1, 1 do
      spr(id, dx + x, dy + y)
    end
  end
  pal()
  spr(id, dx, dy)
end

play_state = {name = "play", init = init_play, update = update_play, draw = draw_play}

----
-- title screen
----
function init_title()
  bgy, t = 0, 0
  menuitem(1)
end

function update_title()
  bgy = bgy - (0.5)
  if bgy < -256 then
    bgy = 0
  end
  t = t + (1)
  if btnp(5) then
    swap_state(play_state)
  end
end

function draw_title()
  cls()
  map(112, 0, 0, bgy)
  map(112, 0, 0, bgy + 256)
  pal(4, 2)
  spr(185, 36, 33, 7, 1)
  pal()
  spr(185, 36, 32, 7, 1)
  prints("-endless descent-", 30, 42, 2, 1)
  prints("press 5", 48, 64, (t % 32 < 16 and 4 or 2), 1)
  prints("a demake by @johanpeitz", 18, 120, 2, 1)
end

title_state = {name = "title", init = init_title, update = update_title, draw = draw_title}
-->8
--------------------------------
-- core functions 
--------------------------------
--debug_str=""
--------------------------------
-- state swapping 
--------------------------------
state, next_state, change_state = {}, {}, false

function swap_state(s)
  next_state, change_state = s, true
end

--------------------------------
-- _base functions 
--------------------------------
function _update()
  if (change_state) then
    state, change_state = next_state, false
    state.init()
  end
  state.update()
end

function _draw()
  state.draw()
-- debug, 175 tokens
--[[
 if (debug) then
  camera()
  
  local str = state.name .. " "
    
  if (btn(0)) str = str .. "0"
  if (btn(1)) str = str .. "1"
  if (btn(2)) str = str .. "2"
  if (btn(3)) str = str .. "3"
  if (btn(4)) str = str .. "4"
  if (btn(5)) str = str .. "5"  

  str = str .. " " .. debug_str
  
  local mr = stat(0)/1024

  local ypos = 121
  if (debug_at_top) ypos=0
  rectfill(0,ypos,127,ypos+6,8)
  
  line(1, ypos+2, 8, ypos+2, 1)
  line(1, ypos+2, 1+min(7*stat(1),7), ypos+2, (stat(1)>1 and 8 or 12))
  
  line(1, ypos+4, 8, ypos+4, 2)
  line(1, ypos+4, 1+min(7*mr,7), ypos+4, (mr>1 and 8 or 14))
  print(str,10,ypos+1,15)

  debug_str = ""
 end
 ]]
--
end

-->8
--------------------------------
-- utilities
--------------------------------
function chance(a)
  return rnd() < a
end

function add_params(src, dst)
  for k, v in pairs(src) do
    dst[k] = v
  end
end

function is_solid(tx, ty)
  return fget(mget(tx, ty), 0)
end

--check if pushing into side tile and resolve.
--requires self.dx,self.x,self.y, and 
--assumes tile flag 0 == solid
--assumes sprite size of 8x8
function collide_side(self)
  local offset = 4
  --self.w/3
  local data = {}
  for i = -(self.h / 3), (self.h / 3), 2 do
    -- used to be .w???
    --if self.dx>0 then
    t = mget((self.x + (offset)) / 8, (self.y + i) / 8)
    if fget(t, 0) then
      self.odx = self.dx
      self.dx = 0
      self.x = (flr(((self.x + (offset)) / 8)) * 8) - (offset)
      data.tile = t
      data.tx = flr((self.x + (offset)) / 8)
      data.ty = flr((self.y + i) / 8)
      return data
    end
    --elseif self.dx<0 then
    t = mget((self.x - (offset)) / 8, (self.y + i) / 8)
    if fget(t, 0) then
      self.odx = self.dx
      self.dx = 0
      self.x = (flr((self.x - (offset)) / 8) * 8) + 8 + (offset)
      data.tile = t
      data.tx = flr((self.x - (offset)) / 8 - 1)
      data.ty = flr((self.y + i) / 8)
      return data
    end
  -- end
  end
  --didn't hit a solid tile.
  return nil
end

--check if standing on air
function should_fall(self)
  if self.inair then
    return true
  end
  local air = true
  for i = -(self.w / 3), (self.w / 3), 2 do
    local newty = flr((self.y + (self.h / 2) + 1) / 8)
    local tile = mget((self.x + i) / 8, newty)
    if (fget(tile, 0) or fget(tile, 1)) then
      air = false
    end
  end
  return air
end

--check if pushing into floor tile and resolve.
--requires self.dx,self.x,self.y,self
--assumes tile flag 0 or 1 == solid
function collide_floor(self)
  --only check for ground when falling.
  if self.dy < 0 then
    return false
  end
  local landed = false
  --check for collision at multiple points along the bottom
  --of the sprite: left, center, and right.
  for i = -(self.w / 3), (self.w / 3), 2 do
    local newty = flr((self.y + (self.h / 2)) / 8)
    local tile = mget((self.x + i) / 8, newty)
    if fget(tile, 0) then
      landed = true
    end
    if (fget(tile, 1) and pl.mode ~= 1) then
      if self.lastty < newty then
        landed = true
      end
    end
  end
  if (landed) then
    self.ody = self.dy
    self.dy = 0
    self.y = (flr((self.y + (self.h / 2)) / 8) * 8) - (self.h / 2)
  end
  return landed
end

--check if pushing into roof tile and resolve.
--requires self.dy,self.x,self.y, and 
--assumes tile flag 0 == solid
function collide_roof(self)
  --check for collision at multiple points along the top
  --of the sprite: left, center, and right.
  local collided = false
  for i = -(self.w / 3), (self.w / 3), 2 do
    if fget(mget((self.x + i) / 8, (self.y - (self.h / 2)) / 8), 0) then
      self.dy = 0
      self.y = flr((self.y - (self.h / 2)) / 8) * 8 + 8 + (self.h / 2)
      collided = true
    end
  end
  return collided
end

function prints(str, x, y, c1, c2)
  print(str, x, y + 1, c2)
  print(str, x, y, c1)
end

function printo(str, x, y, c1, c2)
  -- for i=-1,1 do
  --  for j=-1,1 do
  print(str, x + 1, y, c2)
  print(str, x, y + 1, c2)
  print(str, x - 1, y, c2)
  print(str, x, y - 1, c2)
  --  end
  -- end
  print(str, x, y, c1)
end

-->8
--------------------------------
-- entities 
--------------------------------
-- create and add entity
function make_entity(x, y, t)
  local e = {name = "unknown", x = x, y = y, dx = 0, dy = 0,
  -- delta movement
  ix = 0, iy = 1,
  -- inertia
  spr = 0, dir = 1, life = 0, col = true, lastty = -1, jumpable = true, hits_from_above = false, flip_on_hit = true, knock_down = false, collides_with_player = true, health = 1, damage = 1, cooldown = 0, bleed_timer = 0, faint_timer = 0, draw = draw_entity, update = update_entity, t = 0, w = 8, h = 8, g = 0, t = 0, tw = 1, th = 1, frame = 0, frames = 0, fs = 4, tbl = t}
  add(e.tbl, e)
  return e
end

function update_entity_x(e)
  e.x = e.x + (e.dx)
  e.dx = e.dx * (e.ix)
end

function update_entity_y(e)
  if (e.inair or not e.col) then
    e.y = e.y + (e.dy)
    e.dy = min(e.dy + e.g, 13)
    e.dy = e.dy * (e.iy)
  end
end

function update_entity(e)
  if e.cooldown > 0 then
    e.cooldown = e.cooldown - (1)
  end
  update_entity_x(e)
  if (e.col) then
    d = collide_side(e)
    if (d ~= nil) then
      -- stick to ledge?
      if (e.grab and e.mode == 0 and e.inair and e.dy > 0 and pl.grab_cooldown == 0) then
        local f = fget(mget(d.tx, d.ty - 1))
        local dist = abs(e.y - d.ty * 8)
        if ((band(f, 1) or band(f, 3)) and dist < 2) then
          e.y, e.dy, e.mode = d.ty * 8, 0, 2
        end
      end
      -- callback
      if e.on_sidecol ~= nil then
        e.on_sidecol(e)
      end
    end
  end
  -- store last tile y
  e.lastty = flr((e.y + (e.h / 2) - 0.01) / 8)
  update_entity_y(e)
  newty = flr((e.y + (e.h / 2)) / 8)
  if (e.col) then
    local ody = e.dy
    if (collide_floor(e)) then
      if (e.inair == true and e.on_landed ~= nil) then
        e.ody = ody
        e.on_landed(e)
      end
      e.inair = false
    else
      local toair = false
      if (e.inair == false and e.dy == 0) then
        if (should_fall(e)) then
          if e.inair == false and e.on_air ~= nil then
            e.on_air(e)
          end
          e.inair = true
        end
      else
        if e.inair == false and e.on_air ~= nil then
          e.on_air(e)
        end
        e.inair = true
      end
    end
    if (collide_roof(e)) then
      if e.on_roofhit then
        e.on_roofhit(e)
      end
    end
  end
  update_entity_a(e)
  if (e.bleed_timer > 0) then
    e.bleed_timer = e.bleed_timer - (1)
    if chance(0.5) then
      bleed(e.x, e.y + 4)
    end
    if (e.bleed_timer <= 0 and e.health <= 0) then
      del(e.tbl, e)
    end
  end
end

function update_entity_a(e)
  e.t = e.t + (1)
  if (e.frames > 0) then
    if e.t % e.fs == 0 then
      e.frame = e.frame + (1)
    end
    if e.frame == e.frames then
      e.frame = 0
    end
  end
  if (e.life > 0 and e.t > e.life) then
    del(e.tbl, e)
  end
end

function draw_entity(e)
  spr(e.spr + e.frame * e.tw, e.x - e.w / 2, e.y - e.h / 2, e.tw, e.th, e.dir == -1)
-- print(e.cooldown.."  "..e.life,e.x-3,e.y-5,7)
end

-->8
-- map generation
-- make map
function make_map()
  local rx, ry = 1 + flr(rnd(4)), 1
  local srx, sry = rx, ry
  local m = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, srx, sry}
  local done = false
  -- start room
  m[rx][ry] = 1
  while (not done) do
    local lrx = rx
    local lry = ry
    local down = false
    -- move to free spot
    local tryagain = true
    while (tryagain) do
      tryagain = false
      local r = flr(rnd(5))
      if r < 2 then
        rx = rx - (1)
      end
      -- 0&1
      if r > 2 then
        rx = rx + (1)
      end
      -- 3&4
      if (r == 2) then
        ry = ry + (1)
        down = true
      end
      if (rx < 1) then
        rx = 1
        ry = ry + (1)
        down = true
      end
      if (rx > 4) then
        rx = 4
        ry = ry + (1)
        down = true
      end
      if (m[rx][ry] ~= 0 and ry < 5) then
        rx, ry = lrx, lry
        tryagain = true
      end
    end
    if (down) then
      if (m[lrx][lry - 1] == 2 or m[lrx][lry - 1] == 5) then
        if ry < 5 then
          m[lrx][lry] = 5
        end
      else
        m[lrx][lry] = 2
      end
      m[rx][ry] = 3
    else
      m[rx][ry] = 1
    end
    if ry > 4 then
      done = true
    end
  end
  m[rx][4] = 6
  return m
end


__gfx__
0000000011111111994449942442244224422442994449940000000000000000000000000000000000000000009aaa0000000000000000004444444400066000
000000001555555144424444444222244442222444424444000000000000000000000000000000000000000009aaaaa0009aaa00000000002222222200655600
00700700151111114422244244244422442444224424224200000000000000000000000000000000000000000aaaaaa009aaaaa00000000006d006d000d22d00
00077000151110112224422222444442224444422244422200000000000000000000000000000000000000009aa191900aaaaaa0009aaa0006d006d000020000
0007700015111511424444224424442242244422422424440000000000000000000000000000000000000000aa9fff909aa1919009aaaaa006d006d000002000
00700700151011114424422444422224442222244422244200000000000000000000000000000000000000000a888900aa9fff900aaaaaa0066666d000042000
0000000015151111422224424422244242112222421122220000000000000000000000000000000000000000088880000a8889009aae9e9006d006d000042000
00000000151111112222444422224444210012212100122100000000000000000000000000000000000000000020200000202000889ffff406d006d000020000
0000000055555555994449942442249224422442994449940000000000000000009aaa00000dd040000dd0000008800001d66d100006600006d006d000002000
00000000500000054442444444422aa94a92222444424444000000000000000009aaaaa000d6d50400d6d500008982000015510000d76600066666d000042000
000000005000000544222442442449994999442244249a9200000000000000000aaaaaa000dd550000dd55000088220005d66d5000dd770006d006d000042000
0000000050000005292442229a9445522255494222a4499200000000000000009aa1919000055000000550000002200001dddd10000d550006d006d000020000
0000000050000005454aa4222994a9224224aa924aa925540000000000000000aa9fff90000000000000000000000000000000000000000006d006d000002000
00000000500000054429a92445529994442299944995244200000000000000000a8889000000000000000000000000000000000000000000066666d000042000
000000005000000542259942442255424211255242112222000000000000000008888000000000000000000000000000000000000000000006d006d000042000
000000005000000522225544222244442100122121001221000000000000000000202000000000000000000000000000000000000000000006d006d000020000
66666666666666661dd5d1dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006666660
65555555555555565115555d000000000000000000000000000000000000000000000000000006000082820080800060000000009a900000000000006dddddd6
6ddd5ddddddd5dd651155000000600000008000000000000000000000d60000000dd000000006d6008e888200444446d00000000a0aaaaaa00000000d555555d
6ddd5d55d55d5dd6555550000d070000020800000000000000000000002424000d6d5000000002000eee8820808000d0009a90009a90090900000000d5dddd5d
6dddd5ddddd5ddd65dd55dd60d57600d0d5e800200000000000000000011110005551dd00000400000e8820000000000097aa9000000000000000000d5dddd5d
6dddd5d5d5d5ddd6d55d555d7dd760d58ddee0250000000000000000024242400dd1d6d50002004000082000000000000a2a2a000000000000000000d5dddd5d
666666666666666655555dd607677dd50e6e7dd5000000000000000001111110d6d5dd5500040020000000000000000004a9a4000000000000000000d666666d
5555555555555555111155550076765000767650000000000000000024242424dd5505500000240000000000000000000092900000000000000000000dddddd0
11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10001100000110000000000000000000000000000000000000000000000000000000000000000000000000009a90000000000000000000000000000000000000
000010000011110000001000022224400ffff40000000000000000000000000000000000fffff44400000000a0aaaaaa00000000000000000000000000000000
0000000001110000000111000222242488884240000000000000000000000000000000004242442401d66d109a90090900000000000000000000000000000000
011000000110000000011000ffff4440ffff444000a9900000cdd00000b3300000e88000949494240015510000000000000aa0000000000000aaa90000000000
01000110000011000001000081184240811842400a7aaa000676cc000a7abb000f7fee009494942405666650000000000097aa00000000000099940000000000
000001000001100000000000888842408888424000a9900000cdd00000b3300000e88000949494240dd66dd000000000009977000007a0007aa97aa9007aa900
000000000001000000000000eeee4440eeee4440000a0000000c0000000b0000000e0000fffff44401dddd100000000000094400009940009994999400999400
0024440000000000002444000000000000000000000244400002200000022000000000000000000000000dddddd0000000000dddddd000000000011111100000
02442700002444000244270000244400000000000024427002444420024444200000000000000000000ddd66666dd000000ddddd666dd0000001111111111000
4eeeeee0024427004eeeeee0024427000000000004eeeeee9422224994222249000000000000000000ddddddd666dd0000dd66dddd66dd000011101111011100
009191004eeeeee0009191004eeeeee00024440000091910094444900944449000000000000000000d66d6666ddd66500d666d666dd6ddd00101110110111010
009fff0000919100009fff0000919100024427000009fff4009999f00f9999000000000000000000066d66ddddd666d00666d66dd6dd66d00000011111100000
04244000009fff0000444000009fff004eeeeee0000044400f222200002222f00000000000000000d66ddddddd6dddd5d66dddddddd666651000001111000001
0044420000444000004440000044400000944400000f244202444400004444200000000000000000d6dd66dd55ddddd5d6d666ddd556ddd51011000110001101
00200000020020000020200000202000049999400000020000000200002000000000000000000000d6d66dd555dd55d5dd66666d555dddd51010101111010101
00000000000000001001100100000000000000000002000000000000000000000000000000000000dd66ddddd55dd5d5d5d6ddddd55d55d51010000110000101
0000000000003800d011110d00000000000550000022000000020200000000000000000000000000d5d6ddd5d5dd55155555dd55d5d5d5551111011111101111
00003800000333305185581500000000015dd5100022200022082802000202000000000000000000555ddd55555d5515555dd55555d555551100010110100011
0003333000030000155dd551010550101585585100222000022222200008280000000000000000000555dd55555d511005ddd55555d551101000000000000001
000300000005300001055010155dd55150111105002220000020200002222220000000000000000005d5ddd55551115005d5dd55515511501000000000000001
00053000000053000000000051855815510110150020200000000000202020220000000000000000005dd5555111150000555555511115000000000000000000
030053000000530000000000d011110d1d0000d10000000000000000000000000000000000000000000555111115500000055111111550000000000000000000
03333300033335000000000010011001010000100000000000000000000000000000000000000000000005555550000000000555555000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000011
00000000000000000000000000888000000000000000000000000000000000000000000000000000000000000000000000000000000000001111000000001111
0000000000000000000000000088800000088000000800000000000000060000000f000000000000000000000000000000000000000000001011111111111101
00070000000c0000000d000000222000000220000000000000300300000d50000009400000000000000000000000000000000000000000000010101111010100
00000000000000000000000000000000000000000000000008300530000000000000000000000000000000000000000000000000000000000111000110001110
00000000000000000000000000000000000000000000000003350030000000000000000000000000000000000000000000000000000000000110001111000110
00000000000000000000000000000000000000000000000000333350000000000000000000000000000000000000000000000000000000000000011001100000
02999200000000000000000000000000000000000000000000040000000000000000000000000000020000000000000000000000000000000000000000000000
09aaa820009990000098200000200000000000000000000000440000000000000000000000000000042000000000000000000000000000000000000000000000
9a77a98209aaa20009a9980008998000002800000000000000440000000400000044200000044000004000000000000000000000000000000000000000000000
9a77aa988a77a9202a7a9900097a9800027980000008000000244000000240000444442000244400004000000000004000000000000000000000000000000000
8aaaa9989a77aa8289aa992009aa9800089920000000000000222000000220000244440000024200042000000000442000000024000000000000000000000000
29aa998829aaa9820899982002998200008200000000000000020000000200000022200000000000420000004444200044444420000000000000000000000000
02899882089a98200289820000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00028820002882000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30000000000000000000003030000000000000000000003030000000000000000000003030000000000000000000003000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000888888880000000000000000222222220000000000000000000000000000000000000000000000000000000000000000
00000077777777777700000000000088888888888800000000000022222222222200000000000000000000000000000000000000000000000000000000000000
00007777777777777777000000008888888888888888000000002222222222222222000000000000000000000000000000000000000000000000000000000000
00077777777777777777700000088888888888888888800000022222222222222222200000000000000000000000000000000000000000000000000000000000
00777777777777777777770000888888888888888888880000222222222222222222220000000000000000000000000000000000000000000000000000000000
00777777777777777777770000888888888888888888880000222222222222222222220000000000000000000000000000000000000000000000000000000000
07777777777777777777777008888888888888888888888002222222222222222222222000000000000000000000000000000000000000000000000000000000
07777777777777777777777008888888888888888888888002222222222222222222222000000000000000000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200000000000000000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200000000000000000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200000000000000000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200000000000000000000000000000000000000000000000000000000
777777777777777777777777888888888888888888888888222222222222222222222222000dd040000660000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200d6d50400d766000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200dd550000dd77000000000000000000000000000000000000000000
77777777777777777777777788888888888888888888888822222222222222222222222200055000000d55000000000000000000000000000000000000000000
07777777777777777777777008888888888888888888888002222222222222222222222044444400444424404440000044404440442444004440444044404440
07777777777777777777777008888888888888888888888002222222222222222222222044444440444444404440000044404440444444404440244044204440
00777777777777777777770000888888888888888888880000222222222222222222220024404420444000004440000024404440444044404440444044404440
00777777777777777777770000888888888888888888880000222222222222222222220042404440444400004420000044404440444044204444440044444440
00077777777777777777700000088888888888888888800000022222222222222222200044404440444400004240000044404420444044404444440004444420
00007777777777777777000000008888888888888888000000002222222222222222000044404440444000004440000044404240244044404420444000004440
00000077777777777700000000000088888888888800000000000022222222222200000044444440244444404444424044444440444044404440442004244440
00000000777777770000000000000000888888880000000000000000222222220000000042444400444442404444444004444400444044404440444004444400
11111c111149444444991111111144444444444444444444444444444444111b11c4441111111144111111111144111111444441119444111111111122222222
109944490010d4444d0010000c0d0f100e00e000099444499044499994441444444d0f1044800d0f1044000000440000f9444990094444100000000022000022
1000b00000445944f5441009444544490000009400944449004490e00f44190e099544109990054410990000404800004444e000844490100000000020022002
108449490044d4444d4410000a0d444490099944000999900044800004441000000d44100b000d44100004409044900094441009449a00100000000020022002
100000b00044d9449d441000000d444444444444000999900044f00009441000000d441084400d441000099000444c000a441094490000100000000020022002
109494490044d4444d441000400d444449e99444009444490044400008441400400d441099900044144000000044449000941444800000100000000020022002
10000b000010d00b0d0010944cc04449900009440994444990449000094414cc4cc044c000b0cc441990000440449e0000444449000994100000000022000022
444444444444444444444444444444f0000000944444444444444999944444444444444444444444100090099044000000444440000444444443444422222222
111111111144444444444444444444499111199911111111111111111111444444444444444444441111171111111111d1111111111111111ccc111133333333
10000000001944444490100b00000d100000000010d00c0d0010000d000044444444449444444449104044480010944459001000000000104444900033300333
10000000001099444900444444444510007000d0105444450010009d0700944444444a944444444910e00a0000100480d000100000000010e949000033000333
10000000001000e000001e000b000d144444445010d0700d001044454440194499449094444444491004404000100944d0001000070000100d00070033300333
1099070900100000000000844444441480000ad010544445001049ad084010000000000444444440100000e0001000a9d0001009449000100544440033300333
14444444801000000000109900000044009990d010d4444d0014400d0044179c00c90019999999901099900000100000d0001944444490100d44a00033300333
144444444010cc9cc9701007099990990cc440d010d4444d0014f00d0c944444444444100070000010444cc0b0199700d0004449a09444440d44004433000033
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444900000094990099009933333333
444444444444444444444444444444444444444411111111111111fb11114444994444444444444411110b111111110b111111111b11111111111b1155555555
4444444999994444444910a994444910e094444010009480001044444400499e000a9499a0990e99104444440010094490001004444490100004449055000055
444499a00019444449a01000000e00100004444010084f0000109e099900100000000010000000001090e99a001000e00000100400048010000a490050055005
499e0000001094449000100000b000109909449010944444001000000000100097000010000000001000000000100000000010d0070000100000000055555005
100000000010094400001008444480104400a9001944444400100000000010008400001000000000100000000010000000001054444490100000700055000055
100000000710009900001004900940194480000014449949001000000000100944900010000000001000000000108000000010d4494440109494440050055555
4900000094999700b9991000007000144440007010b0000700199000097049009900941b000000701990000997104c00097910d0004444100b0004c950000005
44000000444444004444990444444944444400444444004444444900944444000000444490000944444900944444440044444444404444444444044455555555
1111111111111111111111111111111111b111111111111111480111108411111111111111111111448011111111111111114491111111111111111144444444
100000000014440004001000000000144444444010000000004449009444100000000010000000009a90099c0010400944901a000099001099c0000044000044
10c0000000084440040010990099001a9e4494901000000000444900944410000949001000000000100008440010400944901000084400144448000040044004
104480000044444044001000000000100000000010008490001a00000000100944449910d99999001000000e001044044449100000e90010e000000044440044
1099900909100b0044001000b00000100008440010008440001099999b00199444444410544444801000060000604000b0001000060000100000000044440044
10000cc49414444444441099449900104049990010094449904444444444444444444410d0a04440100044400044444444901000444000100440009040044004
499994444419444444991094444900144cc0b0001094444440444444444444444444441cd00f44441b044444cc444444449c1b0c444c001b04600b4044000044
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
__map__
0303030303000000000003030303030000000000030303030300000000000303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031001f0000000000003000000011311e
0300000000030303030303000000000303030303030000000003030303030300000000030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f003000006e6f0000000202020e
0300000000000000000303000000000000000003030000000000000000030300000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f0030003100310000311404041e
030000003c3a0000000000000000000000000003000000000000000003030300000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000301f0000000000000000000000001e
0300000005050500232d00000000000000000000000000000000000000000300000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031000000000000000000aa301e
0300000000000005050502000a00000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050202
0300003900090000000004050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000413
0305050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030003104
0303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030003100000000000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000
030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f310000003100000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002005000000000000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003120500000000000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030000300000000000000000000000
0303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003040031000000000000000000000000
0303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003550000000000000000000000003100
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004003100000000000000000030000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000030
03000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000003100313e0212
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505051303
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000052000413
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031310000002c03
03030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a9000000000000000000003031000503
0303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000003100000000000000003004
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003003123000000000000000000000031
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003001505000000000000000000000000
0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003420f30300000000000000000000000
0300000000000000000000000300000000000000000000000300000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003021f12223100000000000000000000
0300000000000000000000030300000000000000000000030300000000000000000000030300000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003041f04130000003000000000000000
0300030300030300030300030300030300030300030300030300030300030300030300030300030300030300030300030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003301f000400314e4f00000000000000
0303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014001f000000005e5f00000000000000
__gff__
0000010101010000000000000000060401800101010100000000000000000404010101080800000000000000000000010000000000000000000000000000000000000000000000000000010100000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001d6100a6302d6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000222501e250192501725013250102500e2500d2500a2500925008250072500625006250062500625006250052500225000000000000000000000000000000000000000000000000000000000000000000
000500001265000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b0503b0503b0503b0503b0503b0503b0503b050000000000000000000000000000000
00000000151500e1500a1500815006150031500215000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000110501105012050130501505017050190501e05020050280502b050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002f6501c650306503c650316501d650326503a65030650196502b65028650246501f6501b65014650106500c6500c65006650036500a6500f6500f65006650086500e6500765002650056500565001650
000200000a670066700467004670066700d6700e67005670096701166005660036500f6400863007620176100c6100a6000560002600026000260000000000000000000000000000000000000000000000000000
000500002f55037550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000001000110000000000000000000000000000000004422222445529994
00000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000004211222244225542
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002100122122224444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024422442
00000000000000000000000000000000000000000000000000000000000000000000000000011000000110000000000000000000000000000000000044422224
00000000000000000000000000000000000000000000000000000000000000000000000000111100001111000000000000000000000000000000000044244422
0000000000000000000000000000000000000000000000000000000000000000000000000111000001110000000000000000000000000000009a900022444442
0000000000000000000000000000000000000000000000000000000000000000000000000110000001100000000000000000000000000000097aa90044244422
00000000000000000000000000000000000000000000000000000000000000000000000000001100000011000000000000000000000000000a2a2a0044422224
000000000000000000000000000000000000000000000000000000000000000000000000000110000001100000000000000000000000000004a9a40044222442
00000000000000000000000000000000000000000000000000000000000000000000000000010000000100000000000000000000000000000092900022224444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000009944499424422442
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000110000011000000000004442444444422224
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000111100000000004424224244244422
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000002244422222444442
000dd040000000000000000000000000000000000000000000000000000000000000000000000000000000000110000001100000000000004224244444244422
00d6d504000000000000000000000000000000000000000000000000000000000000000000000000000000000100011000001100000000004422244244422224
00dd5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000011000000000004211222244222442
00055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000002100122122224444
99444994000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000024422442
44424444000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000001000110044422224
44222442000000000000000000000000000000000011110000000000000000000000000000000000000000000000000000000000000000000000100044244422
22244222000000000000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000000000000000022444442
42444422000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000110000042244422
44244224000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000100011044222224
42222442000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000010042112222
22224444000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000021001221
24422442000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44422224000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000
44244422000000000011110000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100
2244444200000000011100000d070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000
4424442200000000011000000d57600d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000
4442222400000000000011007dd760d5000044444400444424404440000044404440442444004440444044404440000000000000000000000000000000001100
44222442000000000001100007677dd5000044444440444444404440000044404440444444404440244044204440000000000000000000000000000000011000
22224444000000000001000000767650000024424420444222204440000024404440444244404440444044404440000000000000000000000000000000010000
24422442000000009944499499444994000042404440444400004420000044404440444044204444442044444440000000000000000000000000000000000000
44422224000000004442444444424444000044404440444400004240000044404420444044404444440024444420000000000000000000000000000000000000
442444220000000044249a9244242242000044404440444200004440000044404240244044404422444002224440000000000000000000000000000000000000
224444420000000022a4499222444222000044444440244444404444424044444440444044404440442004244440000000000000000000000000000000000000
44244422000000004aa9255442242444000042444420444442404444444024444420444044404440444004444420000000000000000000000000000000000000
44422224000000004995244244222442000022222200222222202222222002222200222022202220222002222200000000000000000000000000000000000000
44222442000000004211222242112222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22224444000000002100122121001221000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24422442002444000006600011000000112220220022002000222002200220000022002220022022202220220022200000000000000000000000000000000000
44422224024427000065560010001122202211212021202000221021102110000021202210211021102210212012102220000000000000000000000000000000
442444224eeeeee000d22d0000001011102110202020202000210010201020000020202100102020002100202002001110000000000000000000000000000000
22444442009191000002000000000000002220202022102220222022102210000022102220221022202220202002000000000000000000000000000000000000
44244422009fff000000200001100000011110101011001110111011001100000011001110110011101110101001000000000000000000000000000000000000
44422224004440000004200001000110010001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44222442004440000004200000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22224444002020000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
244224429944499400002000994449941dd5d1dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
444222244442444400042000444244445115555d0001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
44244422442224420004200044222442511550000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
22444442222442220002000029244222555550000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000
442444224244442200002000454aa4225dd55dd60110000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4442222444244224000420004429a924d55d555d0000110000000000000000000000000000000000000000000000000000000000000000000000000000000000
4422244242222442000420004225994255555dd60001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
22224444222244440002000022225544111155550001000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24422442244224420000200024422442244224920000000000000000000000001100000000000000000000000000000000000000000000000000000000000000
4442222444422224000420004442222444422aa90000000000000000000000001000110000000000000000000000000000000000000000000000000000000000
44244422442444220004200044244422442449990000000000000000000000000000100000000000000000000000000000000000000000000000000000000000
224444422244444200020000224444429a9445520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
442444224224442200002000422444222994a9220000000000000000000000000110000000000000000000000000000000000000000000000000000000000000
44422224442222240004200044222224455299940000000000000000000000000100011002222200000000000000000000000000000000000000000000000000
44222442421122220004200042112222442255420000000022202220222002200220010022121220000000000000000000000000000000000000000000000000
22224444210012210002000021001221222244440000000021202120221021102110000022212220000000000000000000000000000000000000000000000000
24422442110000000000200000000000244224420000000022202210210011211120000022121220000000000000000000000000000000000000000000000000
44422224100011000004200000000000444222240000000021112120222122112211100012222210000000000000000000000000000000000000000000000000
44244422000010000004200000000000442444220000000010111110111111111101110001111100000000000000000000000000000000000000000000000000
22444442000000000002000000000000224444420000000001110000010111011011101000000000000000000000000000000000000000000000000000000000
44244422011000000000200000000000422444220000000001100000000001111110000000000000000000000000000000000000000000000000000000000000
44422224010001100004200000000000442222240000000000001100100000111100000100000000000000000000000000000000000000000000000000000000
44222442000001000004200000000000421122220000000000011000101100011000110100000000000000000000000000000000000000000000000000000000
22224444000000000002000000000000210012210000000000010000101010111101010100000000000000000000000000000000000000000000000000000000
24422442000000000000200000000000000000000000000000000000101000011000010100000000000000000000000000000000000000000000000000000000
4a922224000000000004200000000000000000000000000000000000111101111110111100000000000000000000000000000000000000000000000000000000
49994422000000000004200000000000000000000000000000000000110001011010001100000000000000000000000000000000000000000000000000000000
22554942000000000002000000000000000000000000000000000000100000000000000100000000000000000000000000000000000000000000000000000000
4224aa92000000000000200000000000000000000000000000000000100000000000000100000000000000000000000000000000000000000000000000000000
44229994000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42112552000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21001221000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000200000000000000000000000000000000000000000000000000011000000000000000000000000000000555555550000000006d006d0
000110000000000000042000000000000000000000000000000000000000000000000000100011000000000000000000000000005000000500011000066666d0
00111100000000000004200000000000000000000000000000000000000000000000000000001000000000000000000000000000500000050011110006d006d0
01110000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000050111000006d006d0
01100000000000000000200000000000000000000000000000000000000000000000000001100000000000000000000000000000500000050110000006d006d0
000011000000000000042000000000000000000000000000000000000000000000000000010001100000000000000000000000005000000500001100066666d0
00011000000000000004200000000000000000000000000000000000000000000000000000000100000000000000000000000000500000050001100006d006d0
00010000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000050001000006d006d0
00000000000000000000200000000000110000000000000000000000100000000000000100000000000000000000000099444994994449949944499444444444
00000000000000000004200000000000100011000000000000000000110000000000001100000000000000000000000044424444444244444442444422222222
00000000000000000004200000000000000010000000000000000000111100000000111100000000000000000000000044222442442224424422244206d006d0
00000000000000000002000000000000000000000000000000000000101111111111110100000000000000000000000022244222222442222224422206d006d0
00000000000000000000200000000000011000000000000000000000001010111101010000000000000000000000000042444422424444224244442206d006d0
000000000000000000042000000000000100011000000000000000000111000110001110000000000000000000000000442442244424422444244224066666d0
00000000000000000004200000000000000001000000000000000000011000111100011000000000000000000000000042222442422224424222244206d006d0
00000000000000000002000000000000000000000000000000000000000001100110000000000000000000000000000022224444222244442222444406d006d0
00000000000000000000200000000000110000000000000000000000000000000000000000000000000000000000000024422442244224422442244206d006d0
0000000000000000000420000000000010001100000000000001100000000000000110000000000000000000000110004a9222244442222444422224066666d0
00000000000000000004200000000000000010000000000000111100000000000011110000000000000000000011110049994422442444224424442206d006d0
00000000000000000002000000000000000000000000000001110000000000000111000000000000000000000111000022554942224444422244444206d006d0
0000000000000000000020000000000001100000000000000110000000000000011000000000000000000000011000004224aa92422444224224442206d006d0
000000000000000000042000000000000100011000000000000011000000000000001100000000000000000000001100442299944422222444222224066666d0
00000000000000000004200000000000000001000000000000011000000000000001100000000000000000000001100042112552421122224211222206d006d0
00000000000000000002000000000000000000000000000000010000000000000001000000000000000000000001000021001221210012212100122106d006d0
00000000110000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
000000001000110000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666d0
00000000000010000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
00000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
00000000011000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
000000000100011000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666d0
00000000000001000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
00000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000006d006d0
000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000010001100066666d0
00000000000000000000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000100006d006d0
00000000000000000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006d006d0
00000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000660000110000006d006d0
0000000000000000000000000000110000000000000000000000000000000000000200000000000000000000000000000000000000d7660001000110066666d0
00000000000000000022200000221022202220222020202220000022002020000021202220022020202220220022202220222022202227000000010006d006d0
00000000000000000021200000212022102220212022102210000022002220000020201210212020202120212021202210121012101125000000000006d006d0
00000000000000000022200000202021002120222021202100000021201120000020100200202022202220202022202100020002992419949944499499444994
00000000000000000021200000221022202020212020202220000022202220000012202200221021202120202021102220222002442224444442444444424444
00000000000000000010100000110011101010101010101110000011101110000001101100110010101010101010001110111001441112424422244244222442
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000224442222224422222244222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000422424444244442242444422
__meta:title__
delunky
by peek(johanpeitz)
