pico-8 cartridge // http://www.pico-8.com
version 33
__lua__

--dominion ex 2
--extar 2019, 2020, 2021
version = "1.11"

function init_variables()
  has_collected_coin = false
  has_visited_hangar = false
  menu_cursor_y = 85
  boss_population = 0
  coins = {}
  coin_accumulator = 0
  --container for weapon cooldowns
  cooldown_machinegun = 0
  cooldown_machinegun_cooldown = 2
  cooldown_missile = 0
  cooldown_missile_cooldown = 25
  cooldown_weaponswitch = 0
  cooldown_weaponswitch_cooldown = 10
  cur_function = 'select_start'
  cur_menu_a = 1
  cur_upg = 1
  cur_upg_cost = 5
  difficulty = 'easy'
  enemies = {}
  --level 1 enemy population
  enemy_population = 100
  enemy_projectiles = {}
  enemies_on_screen = 0
  exhausts = {}
  explodes = {}
  explosions = {}
  game_state = 'splash_screen'
  hangar_c = 'select upgrade'
  heatbartime = 0
  level_state = 0
  mapscroll = -384
  max_enemies_on_screen = 5
  projectiles = {}
  pl_trail = {}
  player_sp = 1
  player_x = 64
  player_y = 96
  player_c1 = 12
  player_coins = 10
  player_currentweap = 1
  --player_exc=14
  --player_exdmg=2
  player_ext = 30
  player_ftl_charge = 0
  player_ftl_max = 30
  player_ftl_spd = 0
  player_heat = 0
  player_heatlock = false
  --player_hei=1
  player_invincibility = 0
  player_lives_max = 6
  player_lives = 6
  player_missile_damage = 20
  player_missile_exdmg = 4.5
  player_missile_ext = 18
  player_machinegun_damage = 3
  player_plasma_damage = 12
  --plasma wobble effect
  player_plasmax = -3
  player_plasmaxn = 1
  player_reactor_cooling = 21
  player_reactor_max = 100
  player_reactor_status = "core temp"
  player_show_coins = 0
  player_size = 1
  player_speed = 1
  player_weapon = 'missile'
  --player_wid=1
  score = 0
  stars = {}
  upg_repair_cost = 5
  upg_repair_value = 1
  upg_lives_max_cost = 5
  upg_lives_max_value = 1
  upg_cooling_cost = 5
  upg_cooling_value = 1
  upg_reactor_cost = 5
  upg_reactor_value = 10
  upg_speed_cost = 5
  upg_speed_value = 0.25
  upg_machinegun_damage_cost = 5
  upg_machinegun_damage_value = 1
  upg_missile_ext_cost = 5
  upg_missile_ext_value = 1
  upg_plasma_damage_cost = 5
  upg_plasma_damage_value = 1
  upg_ftl_max_cost = 5
  upg_ftl_max_value = -3
  upg_ftl_max_num = 0
  upg_ftl_max_max = 5
  game_time = 0
  --bugfix 04/03/2020
  you_win_music = nil
end

function _init()
  init_variables()
  high_score = 0
end

-->8
--function setup
--animates the ships engines
function delete_entities()
  for e in all(enemies) do
    del(enemies, e)
    if e.type == 'boss' then
      boss_population = boss_population - (1)
    else
      enemy_population = enemy_population + (1)
    end
  end
  enemy_projectiles = {}
  projectiles = {}
  exhausts = {}
  explodes = {}
  explosions = {}
  pl_trail = {}
end

function sprite_highlight(_colour, _spn, _spx, _spy, _spw, _swh, noclear)
  for i = 1, 15 do
    pal(i, _colour)
  end
  for xh = -1, 1 do
    for yh = -1, 1 do
      spr(_spn, _spx + xh, _spy + yh, _spw or 1, _swh or 1)
    end
  end
--if noclear=='noclear' then
--pal()
--end
end

function randint(_num)
  return flr(rnd(_num))
end

function animate_sprites()
  if btn(0) or btn(1) or btn(2) or btn(3) then
    if game_time % 2 == 0 then
      player_sp = player_sp + (16)
    end
    if player_sp > 17 then
      player_sp = 1
    end
    player_heat = player_heat + (2)
    --player ship exhaust
    create_player_exhaust()
  else
    player_sp = 1
  end
  for p in all(projectiles) do
    if p.name == 'missile' then
      p.sp = p.sp + (16)
      if p.sp > 18 then
        p.sp = 2
      end
    end
  end
end

--enemies bounce off the screen side
function side_bounce()
  for e in all(enemies) do
    if e.x > 128 - (e.w * 4) then
      e.lr = 0 - e.movespeed
    end
    if e.x < 0 - (e.w * 4) then
      e.lr = e.movespeed
    end
  end
end

function centre_print(_string, _y, _c)
  print(_string, 64 - #_string * 2, _y, _c)
end

--change current active weapon
function changeweapon()
  if cooldown_weaponswitch < game_time then
    player_currentweap = player_currentweap + (1)
    sfx(13)
    if player_currentweap > 4 then
      player_currentweap = 1
    end
    if player_currentweap == 1 then
      player_weapon = 'missile'
      player_c2 = 8
    elseif player_currentweap == 2 then
      player_weapon = 'machinegun'
      player_c2 = 10
    elseif player_currentweap == 3 then
      player_weapon = 'plasma'
      player_c2 = 13
    elseif player_currentweap == 4 then
      player_weapon = 'ftl'
      player_c2 = 2
    end
    cooldown_weaponswitch = game_time + cooldown_weaponswitch_cooldown
  end
end

function clear_trails()
  for trail in all(pl_trail) do
    del(pl_trail, trail)
  end
end

function coin_chance(cx, cy, cc)
  local coin_roll = rnd(99)
  if coin_roll < (cc or 0) + coin_accumulator then
    local coin = {x = cx, y = cy}
    --consider just making this a simple rnd(20)>19 if too many lives are given out with high max lives and low lives
    if player_lives < player_lives_max then
      if difficulty == 'easy' then
        if rnd(14 + player_lives_max) > 14 + player_lives then
          coin.special = 'lifeup'
        end
      else
        if rnd(20) > 19 then
          coin.special = 'lifeup'
        end
      end
    end
    add(coins, coin)
    coin_accumulator = 0
  else
    coin_accumulator = coin_accumulator + (coin_roll)
  end
end

function collide(ax, ay, apxwid, bx, by, bhei, bwid)
  local pix = apxwid / 2
  if ax + 4 > bx - pix and ax + 4 < bx + (bwid * 8) + pix and ay + 4 > by - pix and ay + 4 < by + (bhei * 8) + pix then
    return true
  end
end

--used for explosion/radius-based collision
--pythagoras' theorem ftw
function pythagoras(ax, bx, ay, by, r)
  return sqrt((ax - bx) ^ 2 + (ay - by) ^ 2) < r
end

--collision detection. damage and keeping player on screen.
function collision()
  --keeps player on screen unless player is going to game over
  if game_over_wait == nil then
    if player_x < 0 then
      player_x = 0
    end
    if player_y < 0 then
      player_y = 0
    end
    if player_x > 120 then
      player_x = 120
    end
    if player_y > 120 then
      player_y = 120
    end
  end
  --player collision with coins
  for coin in all(coins) do
    if collide(coin.x, coin.y, 4, player_x, player_y, player_size, player_size) then
      if coin.special == 'lifeup' then
        player_lives = player_lives + (1)
        sfx(25)
      else
        player_coins = player_coins + (1)
        score = score + (player_coins)
        player_show_coins = game_time
        sfx(4)
      end
      has_collected_coin = true
      del(coins, coin)
    end
  end
  --player collision
  if game_time > player_invincibility then
    for ep in all(enemy_projectiles) do
      if collide(ep.x, ep.y, 4, player_x, player_y, player_size, player_size) then
        kill_player()
        del(enemy_projectiles, ep)
      end
    end
    --player collision with bomber explosions
    for ex in all(explosions) do
      --pythagoras theorem ftw.
      --bomber explosion can kill the player
      --if sqrt(((player_x-ex.x)^2)+((player_y-ex.y)^2))-6<ex.r and ex.name=='bomber' then
      if pythagoras(player_x + 4, ex.x, player_y + 4, ex.y, ex.r) and ex.name == 'bomber' then
        ex.name = 'hit'
        kill_player()
      end
    end
  end
  --collision detection for enemies
  for e in all(enemies) do
    if collide(player_x, player_y, 8, e.x, e.y, e.h, e.w) and game_time > player_invincibility then
      kill_player()
    end
    --enemy collision with player projectiles
    for p in all(projectiles) do
      local process_damage = 0
      if collide(p.x, p.y, 2, e.x, e.y, e.h, e.w) then
        process_damage = 1
      end
      --projectile collision detection for multi-sprite-width enemies
      if p.x > e.x and p.x < (e.x + e.w * 8) and p.y > e.y and p.y < (e.y + e.h * 8) then
        process_damage = 1
      end
      if process_damage == 1 then
        if p.name == 'missile' then
          create_explosion(p.x + 4, p.y + 4, p.exc, 30)
          explode(p.x, p.y, p.ext, p.exc, p.exdmg, p.name)
          sfx(7)
        end
        if e.immune == p.name then
          sfx(5)
          e.draw_immune = true
        else
          e.hp = e.hp - (p.damage)
          e.flash = 1
        end
        if p.name == 'missile' or p.name == 'plasma' then
          create_explosion(p.x + 4, p.y + 4, p.exc, 7)
        end
        del(projectiles, p)
      end
    end
    --enemy collision detection with explosions
    for ex in all(explosions) do
      --pythagoras theorem ftw.
      if e.name == 'mega_purps' and pythagoras(e.x + 16, ex.x, e.y + 8, ex.y, ex.r) then
        do_hit = true
      elseif pythagoras(e.x + e.w * 4, ex.x, e.y + e.h * 4, ex.y, ex.r) then
        do_hit = true
      end
      if do_hit == true then
        if e.name == 'res' or e.name == 'comans' and ex.name == 'missile' then
          sfx(5)
          e.draw_immune = true
        else
          e.hp = e.hp - (ex.damage)
          e.flash = 1
        end
        do_hit = false
      end
    end
    --kill enemies
    if e.hp <= 0 then
      if e.name ~= 'grees_child' then
        coin_chance(e.x, e.y, e.coin_chance)
        enemies_on_screen = enemies_on_screen - (1)
      end
      if e.type == 'boss' then
        boss_population = boss_population - (1)
      end
      score = score + (e.points)
      sfx(3)
      if e.w == 4 then
        for i = 1, 8 do
          explode(e.x + rnd(32), e.y + rnd(32), e.ext, e.exc, 4, e.name)
        end
      else
        explode(e.x + e.w * 4, e.y + e.h * 4, e.w * 6, e.exc, 1, e.name)
      end
      create_explosion(e.x + e.w * 4, e.y + e.h * 4, e.exc, 20)
      del(enemies, e)
    end
  end
  --enemy projectiles collision detection with death nova explosions
  for ep in all(enemy_projectiles) do
    for ex in all(explosions) do
      if pythagoras(ep.x + 4, ex.x, ep.y + 4, ex.y, ex.r) and ex.name == 'player' then
        del(enemy_projectiles, ep)
      end
    end
  end
end

function cool_print(_string, _x, _y, _c)
  for x = -1, 1 do
    for y = -1, 1 do
      print(_string, _x + x, _y + y, 0)
    end
  end
  print(_string, _x, _y, _c)
end

function upg_update(upg_cost)
  player_coins = player_coins - (upg_cost)
  sfx(8)
end

function do_upg(cur_upg)
  if cur_upg == 1 then
    if player_lives >= player_lives_max and player_coins >= upg_lives_max_cost then
      player_lives_max = player_lives_max + (upg_lives_max_value)
      player_lives = player_lives + (1)
      player_coins = player_coins - (upg_lives_max_cost)
      upg_lives_max_cost = upg_lives_max_cost + (1)
      sfx(8)
      cur_upg_cost = upg_lives_max_cost
    elseif player_lives < player_lives_max and player_coins >= upg_repair_cost then
      player_lives = player_lives + (upg_repair_value)
      player_coins = player_coins - (upg_repair_cost)
      sfx(8)
      cur_upg_cost = upg_repair_cost
    else
      sfx(9)
    end
  elseif cur_upg == 2 then
    if player_coins >= upg_speed_cost then
      player_speed = player_speed + (upg_speed_value)
      upg_update(upg_speed_cost)
      upg_speed_cost = upg_speed_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 3 then
    if player_coins >= upg_cooling_cost then
      player_reactor_cooling = player_reactor_cooling + (upg_cooling_value)
      upg_update(upg_cooling_cost)
      upg_cooling_cost = upg_cooling_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 4 then
    if player_coins >= upg_reactor_cost then
      player_reactor_max = player_reactor_max + (upg_reactor_value)
      player_ext = player_ext + (3)
      upg_update(upg_reactor_cost)
      upg_reactor_cost = upg_reactor_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 5 then
    if player_coins >= upg_missile_ext_cost then
      player_missile_ext = player_missile_ext + (upg_missile_ext_value)
      upg_update(upg_missile_ext_cost)
      upg_missile_ext_cost = upg_missile_ext_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 6 then
    if player_coins >= upg_machinegun_damage_cost then
      player_machinegun_damage = player_machinegun_damage + (upg_machinegun_damage_value)
      upg_update(upg_machinegun_damage_cost)
      upg_machinegun_damage_cost = upg_machinegun_damage_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 7 then
    if player_coins >= upg_plasma_damage_cost then
      player_plasma_damage = player_plasma_damage + (upg_plasma_damage_value)
      upg_update(upg_plasma_damage_cost)
      upg_plasma_damage_cost = upg_plasma_damage_cost + (1)
    else
      sfx(9)
    end
  elseif cur_upg == 8 then
    if player_coins >= upg_ftl_max_cost and upg_ftl_max_num < upg_ftl_max_max then
      player_ftl_max = player_ftl_max + (upg_ftl_max_value)
      upg_update(upg_ftl_max_cost)
      upg_ftl_max_cost = upg_ftl_max_cost + (1)
      upg_ftl_max_num = upg_ftl_max_num + (1)
    else
      sfx(9)
    end
  end
end

--lr is orans projectiles
--plr is for yels projectiles
function enemy_fire(x, y, name, _c, lr, plr)
  ep = {x = x, y = y, name = name, c = _c}
  if name == 'grees' then
    ep.sp = 5
    ep.dy = 1
    sfx(12)
    add(enemy_projectiles, ep)
  elseif name == 'purps' then
    ep.sp = 6
    ep.dy = 2
    sfx(16)
    add(enemy_projectiles, ep)
  --if statement for super_purps firing
  elseif name == 'super_purps' then
    if game_time % 120 < 90 then
      ep.sp = 6
      ep.dy = 2
      ep.x = x + 4
      ep.y = y + 4
      sfx(16)
      add(enemy_projectiles, ep)
    end
  --if statement for orans firing
  elseif name == 'orans' or name == 'super_orans' then
    --left firing projectile
    ep.sp = 7
    ep.lr = -0.6
    ep.dy = 2
    ep.x = x
    ep.y = y
    ep.lr = lr
    ep2 = ep
    add(enemy_projectiles, ep)
    sfx(15)
  --if statement for mega_purps firing
  elseif name == 'mega_purps' then
    if game_time % 120 < 75 then
      ep.sp = 25
      ep.x = x + 24
      ep.y = y + 15
      ep.dy = 2
      sfx(19)
      add(enemy_projectiles, ep)
    end
  --if statement for yels firing
  elseif name == 'yels' then
    ep.sp = 22
    ep.x = x + 4
    ep.y = y + 4
    ep.lr = 0
    ep.plr = plr
    ep.dy = 0
    sfx(14)
    add(enemy_projectiles, ep)
  --if statement for azurs firing
  elseif name == 'azurs' then
    ep.sp = 20
    ep.x = x + 4
    ep.y = y + 4
    ep.dy = 2
    sfx(21)
    add(enemy_projectiles, ep)
  --if statement for bomber firing
  elseif name == 'bomber' then
    ep.sp = 23
    ep.x = x + 4
    ep.y = y + 4
    ep.age = game_time
    ep.dy = 0.5
    sfx(24)
    add(enemy_projectiles, ep)
  --super_grees doesn't fire projectiles so has no entry here
  elseif name == 'grees_child' then
    ep.sp = 5
    ep.dy = 1
    sfx(12)
    add(enemy_projectiles, ep)
  --if statement for comans firing
  elseif name == 'comans_mis' then
    if game_time % 120 < 90 then
      ep.sp = 50
      ep.lr = rnd(1) - 0.5
      ep.dy = 1.5
      sfx(20)
      add(enemy_projectiles, ep)
    end
  elseif name == 'comans_las' then
    if game_time % 120 < 90 then
      ep.sp = 8
      ep.dy = 3.5
      sfx(19)
      add(enemy_projectiles, ep)
    end
  elseif name == 'masts_las' then
    if game_time % 160 < 120 then
      ep.sp = 8
      ep.dy = 3.5
      sfx(19)
      add(enemy_projectiles, ep)
    end
  elseif name == 'masts_lasran' then
    if game_time % 160 > 150 then
      ep.sp = 8
      ep.dy = 3.5
      ep.ran = rnd(2) - 1
      sfx(19)
      add(enemy_projectiles, ep)
    end
  end
end

--adds enemies to the screen
function enemy_manager()
  --level 1 enemy sequence
  if enemy_population > 0 and level_state == 0 and enemies_on_screen < max_enemies_on_screen then
    if game_time % 61 == 0 and enemy_population > 20 then
      --debug test crap
      --add_enemy('brain')
      add_enemy('grees')
    end
    if game_time % 127 == 0 and enemy_population < 75 then
      add_enemy('purps')
    end
    if game_time % 241 == 0 and enemy_population < 15 then
      add_enemy('orans')
    end
    if game_time % 401 == 0 and enemy_population < 33 then
      add_enemy('res')
    end
  end
  --level 1 boss
  if game_state == 'main' and enemy_population < 1 and enemies_on_screen < 1 and level_state == 0 then
    add_enemy('super_purps', 64, -32, 'boss')
    add_enemy('yels', 0, -32, 'boss')
    add_enemy('yels', 108, -32, 'boss')
    level_state = 1
    music(19)
  end
  if boss_population < 1 and level_state == 1 then
    level_state = 2
    hard_difficulty_bonus()
  end
  --level 2 enemy sequence
  if level_state == 3 and enemy_population > 0 and enemies_on_screen < max_enemies_on_screen then
    if game_time % 61 == 0 and enemy_population > 20 then
      add_enemy('grees')
    end
    if game_time % 83 == 0 and enemy_population < 90 then
      add_enemy('purps')
    end
    if game_time % 353 == 0 and enemy_population > 50 and enemy_population < 80 then
      add_enemy('orans')
    end
    if game_time % 409 == 0 and enemy_population < 50 and enemy_population > 25 then
      add_enemy('azurs')
    end
    if game_time % 257 == 0 and enemy_population < 30 and enemy_population > 10 then
      if rnd(2) < 1 then
        add_enemy('res')
      else
        add_enemy('yels')
      end
    end
    if game_time % 509 == 0 and enemy_population < 20 and enemy_population > 10 then
      add_enemy('super_purps')
    end
  end
  --level 2 boss
  if enemy_population < 1 and enemies_on_screen < 1 and game_state == 'main' and level_state == 3 then
    add_enemy('comans', 64, -32, 'boss')
    add_enemy('super_grees', 0, -16, 'boss')
    add_enemy('super_grees', 112, -16, 'boss')
    level_state = 4
    music(19)
  end
  if boss_population < 1 and level_state == 4 then
    level_state = 5
    hard_difficulty_bonus()
  end
  --level 3 enemy sequence
  if level_state == 6 and enemy_population > 0 and enemies_on_screen < max_enemies_on_screen then
    if game_time % 127 == 0 and enemy_population > 20 and enemies_on_screen < max_enemies_on_screen - 2 then
      add_enemy('grees', 16, nil, group)
      add_enemy('grees', 112, nil, group)
    end
    if game_time % 151 == 0 and enemy_population < 90 then
      add_enemy('purps')
    end
    if game_time % 257 == 0 and enemy_population < 80 and enemy_population > 10 then
      if rnd(2) < 1 then
        add_enemy('super_orans')
      else
        add_enemy('yels')
      end
    end
    if game_time % 307 == 0 and enemy_population < 70 and enemy_population > 30 then
      if rnd(2) < 1 then
        add_enemy('azurs')
      else
        add_enemy('bomber')
      end
    end
    if game_time % 409 == 0 and enemy_population < 60 and enemy_population > 15 then
      add_enemy('super_grees')
    end
    if game_time % 409 == 0 and enemy_population < 20 then
      if rnd(2) < 1 then
        add_enemy('brain')
      else
        add_enemy('super_purps')
      end
    end
    if game_time % 521 == 0 and enemy_population < 10 then
      add_enemy('mega_purps')
    end
  end
  --level 3 boss
  if enemy_population < 1 and enemies_on_screen < 1 and game_state == 'main' and level_state == 6 then
    add_enemy('masts', 64, nil, 'boss')
    level_state = 7
    music(19)
  end
  if boss_population < 1 and level_state == 7 then
    level_state = 8
    hard_difficulty_bonus()
  end
  if level_state == 7 and game_time % 90 == 0 and enemies_on_screen < max_enemies_on_screen then
    max_enemies_on_screen = 4
    if rnd(2) < 1 then
      add_enemy('grees')
    else
      add_enemy('purps')
    end
  end
end

function enemy_into_table(_e)
  if _e.name ~= 'grees_child' then
    enemy_population = enemy_population - (1)
    enemies_on_screen = enemies_on_screen + (1)
  end
  add(enemies, _e)
end

--x and y co-ordinates only used when enemies should be spawned in a specific place, e.g. bosses
function add_enemy(name, specific_x, specific_y, type)
  --green enemy
  --advances slowly, slowly fires slow shots. slow.
  if name == 'grees' then
    local e = {sp = 33, x = randint(120), y = -8, name = 'grees', age = game_time, coin_chance = 10, exc = 11, firspd = 120, firstp = 120, hp = 10, lr = 0, movespeed = 0.5, points = 5, target_y = randint(64) + 32, h = 1, w = 1}
    enemy_into_table(e)
  --		add (enemies,e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  end
  --purple enemy
  if name == 'purps' then
    local e = {sp = 34, x = randint(120), y = -8, name = 'purps', coin_chance = 20, exc = 2, firspd = 45, firstp = 45, hp = 20, lr = 0, movespeed = 0.5, points = 15, h = 1, w = 1, target_y = randint(32) + 32,}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --orange enemy
  if name == 'orans' then
    local e = {sp = 35, x = randint(120), y = -8, name = 'orans', coin_chance = 30, exc = 9, firspd = 60, firstp = 60, hp = 30, lr = 0, movespeed = 1, points = 25, h = 1, w = 1, target_y = randint(64)}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --red enemy
  --hangs back and tries to charge player immune to missiles.
  if name == 'res' then
    local e = {sp = 36, x = randint(112), y = -16, name = 'res', charging = 0, coin_chance = 40, exc = 8, hp = 60, immune = 'missile', lr = 0, movespeed = 0.5, points = 50, h = 2, w = 2, target_y = randint(16) + 32}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --super purple enemy
  --hangs back and fires long salvoes
  if name == 'super_purps' then
    local e = {sp = 44, x = randint(112), y = -16, name = 'super_purps', age = game_time, coin_chance = 50, exc = 2, firspd = 5, firstp = 5, hp = 480, lr = 0, movespeed = 0.5, points = 250, h = 2, w = 2, target_y = randint(32) + 32}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --yellow enemy
  --fires sideways, immune to mgun
  if name == 'yels' then
    local e = {sp = 38, x = randint(112), y = -16, name = 'yels', age = game_time, coin_chance = 40, exc = 10, firspd = 45, firstp = 45, hp = 180, immune = 'machinegun', lr = 0, movespeed = 1.5, plr = 1, points = 50, h = 2, w = 2}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --azurs squid enemy	
  if name == 'azurs' then
    local e = {sp = 40, x = randint(112), y = -16, name = 'azurs', coin_chance = 40, exc = 1, firspd = 60, firstp = 60, hp = 120, lr = 0, movespeed = 1, points = 60, h = 2, w = 2, target_y = randint(16)}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --super grees enemy
  --hangs back and spawns grees children
  if name == 'super_grees' then
    local e = {sp = 42, x = randint(112), y = -16, name = 'super_grees', age = game_time, coin_chance = 40, exc = 11, firspd = 30, firstp = 30, hp = 360, lr = 0, movespeed = 0.5, points = 100, h = 2, w = 2, target_y = randint(32) + 8,}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --green child enemy
  if name == 'grees_child' then
    local e = {sp = 49, x = randint(120), y = -8, name = 'grees_child', age = game_time, exc = 11, firspd = 130, firstp = 130, hp = 10, lr = 0, movespeed = 0.5, points = 1, h = 1, w = 1, target_y = randint(56) + 40}
    enemy_into_table(e)
  --		add (enemies,e)
  end
  --bomber
  --drops special bombs, teleports from bottom of screen to top
  if name == 'bomber' then
    local e = {sp = 10, x = randint(112), y = -16, name = 'bomber', coin_chance = 20, exc = 3, firspd = 40, firstp = 40, hp = 120, lr = 0, movespeed = 1.5, points = 75, h = 2, w = 2}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --red boss enemy
  --hangs back and fires long salvoes
  if name == 'comans' then
    local e = {sp = 136, x = randint(96), y = -32, name = 'comans', age = game_time, exc = 8, ext = 96, firepoint = 1, firspd = 7, firstp = 7, hp = 1000, immune = 'missile', lr = 0, movespeed = 0.5, points = 1000, h = 4, w = 4, target_y = 8,}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --brain enemy	
  if name == 'brain' then
    local e = {sp = 12, x = randint(112), y = -16, name = 'brain', coin_chance = 10, exc = 14, firspd = 14, firstp = 14, hp = 200, immune = 'plasma', lr = 0, movespeed = 0.5, points = 80, h = 2, w = 2, target_y = 16}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --purple end boss enemy
  --twin plasma bastard
  if name == 'masts' then
    local e = {sp = 140, x = 64, y = -32, name = 'masts', age = game_time, exc = 13, ext = 192, firepoint = 1, firspd = 6, firstp = 6, hp = 1500, immune = 'plasma', lr = 0, movespeed = 0.5, points = 2500, h = 4, w = 4, target_y = 8}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --super orange enemy
  if name == 'super_orans' then
    local e = {sp = 46, x = randint(112), y = -16, name = 'super_orans', coin_chance = 100, exc = 9, firspd = 10, firstp = 10, hp = 120, lr = 0, movespeed = 1, points = 85, h = 2, w = 2, target_y = randint(64)}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  --mega purple enemy
  --hangs back and fires long salvoes
  if name == 'mega_purps' then
    local e = {sp = 200, x = randint(96), y = -16, name = 'mega_purps', coin_chance = 50, exc = 2, firspd = 1, firstp = 1, hp = 480, lr = 0, movespeed = 0.5, points = 275, h = 2, w = 4, target_y = randint(32) + 32}
    enemy_into_table(e)
  --		enemy_population-=1
  --		enemies_on_screen+=1
  --		add (enemies,e)
  end
  for e in all(enemies) do
    if e.age == game_time and e.unique == nil then
      if specific_x ~= nil then
        e.x = specific_x
        e.unique = 1
      end
      if specific_y ~= nil then
        e.y = specific_y
        e.unique = 1
      end
      if type ~= nil then
        e.type = type
        e.unique = 1
      end
      if e.type == 'boss' then
        boss_population = boss_population + (1)
      end
    end
  end
end

--draws explosions
-- t - explosion time
-- c - explosion colour
function explode(x, y, t, c, damage, name)
  local ex = {x = x, y = y, r = 4, t = (t or 0) + rnd(4), c = c or 1, damage = damage, name = name}
  add(explosions, ex)
end

function fire(weapon)
  if player_heatlock == false then
    if weapon == 'missile' and cooldown_missile < game_time then
      local p = {name = 'missile', sp = 2, x = player_x, y = player_y, damage = player_missile_damage, ext = player_missile_ext, exc = 8, exdmg = player_missile_exdmg}
      player_heat = player_heat + (6)
      add(projectiles, p)
      sfx(1)
      cooldown_missile = game_time + cooldown_missile_cooldown
    end
    if weapon == 'machinegun' and cooldown_machinegun < game_time then
      local p = {name = 'machinegun', sp = 3, x = player_x, y = player_y, drift = 1 - (rnd(20) / 10), damage = player_machinegun_damage}
      player_heat = player_heat + (3)
      add(projectiles, p)
      sfx(0)
      cooldown_machinegun = game_time + cooldown_machinegun_cooldown
    end
    if weapon == 'plasma' then
      local p = {name = 'plasma', sp = 4, exc = 12, x = player_x + player_plasmax, y = player_y, damage = player_plasma_damage}
      player_plasmax = player_plasmax + player_plasmaxn
      if player_plasmax == 3 then
        player_plasmaxn = -1
      elseif player_plasmax == -3 then
        player_plasmaxn = 1
      end
      player_heat = player_heat + (5)
      add(projectiles, p)
      sfx(2)
    end
    if weapon == 'ftl' then
      player_ftl_charge = player_ftl_charge + (1)
      --cheats
      --player_lives+=1
      --player_coins+=10
      player_heat = player_heat + (4)
      if player_ftl_charge == player_ftl_max then
        hangar_c = 'select upgrade'
        time_since_ftl = game_time + 30
        sfx(10)
        cur_upg = 9
        --resets boss if not killed outright
        if level_state == 1 then
          level_state = 0
        end
        if level_state == 4 then
          level_state = 3
        end
        if level_state == 7 then
          level_state = 6
        end
        leave_main_screen()
        music(17)
        game_state = 'hangar'
        if level_state == 2 then
          level_state = 3
          enemy_population = 100
          mapscroll = -384
          for s in all(stars) do
            del(stars, s)
          end
        end
        if level_state == 5 then
          level_state = 6
          enemy_population = 100
          mapscroll = -384
        end
        if level_state == 8 then
          game_state = 'you_win'
        end
      end
    end
  end
end

--damage flicker effect
function flash()
  for i = 1, 15 do
    pal(i, 7)
  end
end

function hard_difficulty_bonus()
  if difficulty == 'hard' then
    score = flr(score * 1.5)
  end
end

function kill_player()
  player_lives = player_lives - (1)
  player_invincibility = game_time + 90
  sfx(6)
  explode(player_x, player_y, player_ext, 14, 2, 'player')
end

--takes player away from the main screen but doesn't reset the level
function leave_main_screen()
  player_x = 0
  player_y = 112
  delete_entities()
  --	for p in all (projectiles) do
  --		del (projectiles, p)
  --	end
  -- for e in all (enemies) do
  -- del (enemies, e)
  -- if e.type=='boss' then
  -- boss_population-=1
  -- else
  -- enemy_population+=1
  -- end
  -- end
  --	for ep in all(enemy_projectiles) do
  --		del (enemy_projectiles,ep)
  --	end
  -- enemy_projectiles={}
  -- projectiles={}
  -- exhausts={}
  -- explodes={}
  -- explosions={}
  -- pl_trail={}
  --clear_trails()
  --resets the boss if not killed outright
  if level_state == 1 then
    level_state = 0
  end
  if level_state == 4 then
    level_state = 3
  end
  if level_state == 7 then
    level_state = 6
  end
  player_ftl_charge = 0
  player_heat = 0
  enemies_on_screen = 0
  music(-1)
end

function player_trail(px, py)
  local trail = {x = px, y = py, age = game_time}
  add(pl_trail, trail)
  for trail in all(pl_trail) do
    if game_time - trail.age > 12 then
      del(pl_trail, trail)
    end
  end
end

function reset()
  init_variables()
  for p in all(projectiles) do
    del(projectiles, p)
  end
  for e in all(enemies) do
    del(enemies, e)
  end
  delete_entities()
--clear_trails()
end

--star field effect
function starfield(col1, col2)
  local s = {x = rnd(128), y = 0, col = 7, speed = (rnd(9) + 1) / 10}
  if game_time % 5 == 0 then
    add(stars, s)
  end
  for s in all(stars) do
    circ(s.x, s.y, 0, s.col)
    s.y = s.y + (s.speed)
    if 0.4 < s.speed and s.speed < 0.7 then
      s.col = col2
    elseif s.speed < 0.4 then
      s.col = col1
    end
  end
end

function toggle_difficulty()
  if difficulty == 'hard' then
    difficulty = 'easy'
    max_enemies_on_screen = 5
    player_lives_max = 6
    player_lives = 6
    player_coins = 10
    player_missile_exdmg = 4.5
    player_missile_ext = 18
    player_machinegun_damage = 3
    player_plasma_damage = 12
  elseif difficulty == 'easy' then
    difficulty = 'hard'
    max_enemies_on_screen = 10
    player_lives_max = 3
    player_lives = 3
    player_coins = 0
    player_missile_exdmg = 3
    player_missile_ext = 12
    player_machinegun_damage = 2
    player_plasma_damage = 8
  end
end

function toggle_upg(direction)
  if direction == 1 then
    cur_upg = cur_upg + (1)
  else
    cur_upg = cur_upg - (1)
  end
  if cur_upg > 9 then
    cur_upg = 1
  end
  if cur_upg < 1 then
    cur_upg = 9
  end
  if cur_upg == 1 then
    if player_lives >= player_lives_max then
      hangar_c = 'upgrade hull'
      cur_upg_cost = upg_lives_max_cost
    else
      hangar_c = 'repair ship'
      cur_upg_cost = upg_repair_cost
    end
  elseif cur_upg == 2 then
    hangar_c = 'upgrade ship engines'
    cur_upg_cost = upg_speed_cost
  elseif cur_upg == 3 then
    hangar_c = 'upgrade cooling'
    cur_upg_cost = upg_cooling_cost
  elseif cur_upg == 4 then
    hangar_c = 'upgrade reactor'
    cur_upg_cost = upg_reactor_cost
  elseif cur_upg == 5 then
    hangar_c = 'upgrade missile yield'
    cur_upg_cost = upg_missile_ext_cost
  elseif cur_upg == 6 then
    hangar_c = 'upgrade vulcan cannon'
    cur_upg_cost = upg_machinegun_damage_cost
  elseif cur_upg == 7 then
    hangar_c = 'upgrade plasma'
    cur_upg_cost = upg_plasma_damage_cost
  elseif cur_upg == 8 then
    hangar_c = 'upgrade ftl'
    cur_upg_cost = upg_ftl_max_cost
  elseif cur_upg == 9 then
    hangar_c = 'leave hangar'
  end
end

-->8
--update section
function _update()
  game_time = (game_time + 1) % 32000
  if game_time % 4 == 0 then
    player_trail(player_x, player_y)
  end
  if score > high_score then
    high_score = score
  end
  if game_state == 'main' then
    if player_heat > 0 then
      player_heat = player_heat - (player_reactor_cooling / 10)
    elseif player_heat < 0 then
      player_heat = 0
    end
    --heatlock
    if player_heat > player_reactor_max then
      player_heatlock = true
      player_heat = player_reactor_max
      player_reactor_status = " overheat"
    end
    if player_heat < player_reactor_max / 2 and player_heatlock == true then
      player_heatlock = false
      player_reactor_status = "core temp"
    end
    --overheat klaxon
    if player_heatlock == true then
      if stat(19) ~= 26 then
        sfx(26, 3)
      end
      player_c1 = 9
      create_player_exhaust()
    else
      sfx(-2, 3)
      player_c1 = 12
    end
    --ftl update stuff
    if (player_ftl_charge > 0 and player_weapon ~= 'ftl') or player_ftl_charge < 0 then
      player_ftl_charge = 0
    end
    if not btn(4) and game_time % 2 == 0 then
      player_ftl_charge = player_ftl_charge - (1)
    end
    --ship controls
    if player_lives > 0 then
      if player_weapon == 'ftl' then
        sfx(11, -1, player_ftl_charge, 1)
        player_ftl_spd = 1
      else
        player_ftl_spd = 0
      end
      if btn(0) then
        player_x = player_x - (player_speed + player_ftl_spd)
      end
      if btn(1) then
        player_x = player_x + (player_speed + player_ftl_spd)
      end
      if btn(2) then
        player_y = player_y - (player_speed + player_ftl_spd)
      end
      if btn(3) then
        player_y = player_y + (player_speed + player_ftl_spd)
      end
      if btn(4) then
        fire(player_weapon)
      end
      if btnp(5) then
        changeweapon()
      end
    else
      if game_over_wait == nil then
        --player level bounding in collision is switched off by this too
        game_over_wait = game_time + 90
        player_x = -8
        player_y = -8
      end
      if game_time > game_over_wait then
        game_state = 'game_over'
        game_over_wait = nil
      --dramatic_music=nil
      end
    end
    enemy_manager()
    collision()
    animate_sprites()
    update_particles()
  end
  for coin in all(coins) do
    if coin.y < 128 then
      coin.y = coin.y + (0.5)
    else
      del(coins, coin)
    end
  end
  --projectiles update stuff
  for p in all(projectiles) do
    if p.name == 'missile' then
      p.y = p.y - (5)
      create_exhaust(p.x + 4, p.y + 4, 8, 12)
    elseif p.name == 'machinegun' then
      p.y = p.y - (7)
      p.x = p.x + (p.drift)
    elseif p.name == 'plasma' then
      p.y = p.y - (5)
      create_exhaust(p.x + 4, p.y + 4, 13, 12, 0, 1)
    end
    if p.y > 136 or p.y < -8 or p.x > 136 or p.x < -8 then
      del(projectiles, p)
    end
  end
  --enemy projectiles update stuff
  for ep in all(enemy_projectiles) do
    if ep.name == 'grees' or 'grees_child' then
      en_pr_ex_spd = -0.5
    else
      en_pr_ex_spd = 0
    end
    if ep.name == 'yels' or ep.name == 'mega_purps' then
    else
      create_exhaust(ep.x + 4, ep.y + 4, ep.c, ep.c, en_pr_ex_spd, 1)
    end
    --enemy projectile flipping animation
    if game_time % 2 == 0 then
      ep.x_flip = true
    else
      ep.x_flip = false
    end
    ep.y = ep.y + (ep.dy)
    if ep.name == 'orans' or ep.name == 'super_orans' then
      ep.x = ep.x + (ep.lr)
    end
    --yels projectiles go sideways
    if ep.name == 'yels' then
      ep.x = ep.x + (ep.plr)
    end
    if ep.name == 'azurs' then
      if ep.y < 96 then
        if player_x < ep.x then
          ep.x = ep.x - (0.5)
        else
          ep.x = ep.x + (0.5)
        end
      end
    end
    if ep.name == 'comans_mis' then
      ep.x = ep.x + (ep.lr)
    end
    if ep.name == 'masts_lasran' then
      ep.x = ep.x + (ep.ran)
    end
    --deletes off-screen projectiles
    if ep.y > 128 or ep.y < 0 or ep.x < 0 or ep.x > 128 and ep.name ~= 'bomber' then
      del(enemy_projectiles, ep)
    end
    --bomber bombs explode
    if ep.name == 'bomber' and game_time - ep.age > 30 then
      del(enemy_projectiles, ep)
      explode(ep.x, ep.y, 24, 11, 1, 'bomber')
    end
  end
  --enemy behaviour
  for e in all(enemies) do
    --res movement behaviour
    if e.name == 'res' then
      if e.lr == 0 then
        if player_x < 64 then
          e.lr = e.movespeed
        else
          e.lr = 0 - e.movespeed
        end
      end
      if e.x > 128 - (e.w * 8) then
        e.lr = 0 - e.movespeed
      end
      if e.x < 0 then
        e.lr = e.movespeed
      end
      if e.y < e.target_y and e.charging == 0 then
        e.y = e.y + (e.movespeed)
      end
      if e.charging == 0 and e.y == e.target_y then
        e.x = e.x + (e.lr)
      end
      if e.y == e.target_y and abs(e.x - player_x) < 6 then
        e.charging = 1
        sfx(23)
      end
      if e.y <= 128 - (e.h * 8) and e.charging == 1 then
        e.y = e.y + (3)
      end
      if e.y > 128 - (e.h * 8) and e.charging == 1 then
        e.charging = 2
      end
      if e.charging == 2 and e.y > e.target_y then
        e.y = e.y - (0.5)
      end
      if e.charging == 2 and e.y == e.target_y then
        e.charging = 0
      end
    --end
    --yels movement/firing behaviour
    elseif e.name == 'yels' then
      e.y = e.y + (e.movespeed)
      e.firstp = e.firstp - (1)
      if e.y > 116 then
        e.movespeed = -1
      end
      if e.y < 0 then
        e.movespeed = 1
      end
      --yels only fires when it's lined up with the player
      if abs(e.y + 8 - player_y) < 2 and e.firstp < 1 then
        if player_x > e.x then
          e.plr = 1.5
        else
          e.plr = -1.5
        end
        enemy_fire(e.x, e.y, e.name, e.exc, e.lr, e.plr)
        e.firstp = e.firspd
      end
    --end
    --standard movement/firing for other enemies
    elseif e.name == 'grees' or e.name == 'purps' or e.name == 'orans' or e.name == 'super_purps' or e.name == 'azurs' or e.name == 'super_grees' or e.name == 'grees_child' or e.name == 'comans' or e.name == 'brain' or e.name == 'masts' or e.name == 'super_orans' or e.name == 'mega_purps' then
      if e.lr == 0 then
        if e.x < player_x then
          e.lr = e.movespeed
        else
          e.lr = 0 - e.movespeed
        end
      end
      --enemies reach target y coord then move side to side.
      side_bounce()
      if e.y < e.target_y then
        e.y = e.y + (e.movespeed)
      --then they move side-to-side			
      else
        e.x = e.x + (e.lr)
      end
      --enemy firing countdown.
      if e.firspd > 0 then
        e.firstp = e.firstp - (1)
        --only yels uses plr
        if e.firstp < 1 then
          --red boss fire sequence
          if e.name == 'comans' then
            e.firepoint = e.firepoint + (1)
            if e.firepoint == 3 then
              e.firepoint = 1
            end
            if e.firepoint == 1 then
              enemy_fire(e.x + 4, e.y + 24, 'comans_mis', e.exc, lr, plr)
            else
              enemy_fire(e.x + 28, e.y + 24, 'comans_mis', e.expx, lr, plr)
            end
            if player_x > e.x and player_x < e.x + 32 then
              enemy_fire(e.x + 12, e.y, 'comans_las', e.exc)
            end
          --end
          elseif e.name == 'orans' or e.name == 'super_orans' then
            enemy_fire(e.x, e.y, e.name, e.exc, -0.4)
            enemy_fire(e.x, e.y, e.name, e.exc, 0.4)
          --purple end boss fire sequence
          elseif e.name == 'masts' then
            enemy_fire(e.x, e.y + 24, 'masts_las', e.exc)
            enemy_fire(e.x + 24, e.y + 24, 'masts_las', e.exc)
            for i = 1, 8 do
              enemy_fire(e.x + 16, e.y + 16, 'masts_lasran', e.exc)
            end
          --end
          --brain fire sequence
          elseif e.name == 'brain' then
            if player_x > e.x - 8 and player_x < e.x + 24 then
              enemy_fire(e.x + 4, e.y, 'comans_las', e.exc)
            end
          --end
          --super_grees don't fire projectiles, but spawn grees_childs
          elseif e.name == 'super_grees' and (e.age + game_time) % 150 < 90 and e.y == e.target_y then
            add_enemy('grees_child', e.x, e.y, 'grees_child')
            sfx(22)
          else
            enemy_fire(e.x, e.y, e.name, e.exc, e.lr, e.plr)
          end
          e.firstp = e.firspd
        end
      end
      if e.name == 'orans' and abs(e.x - player_x) < 6 then
        e.firstp = e.firstp - (2)
      end
    --end
    --grees child movement/firing behavior
    elseif e.name == 'grees_child' then
      if game_time - e.age > 300 then
        e.y = e.y + (2)
        if player_x < e.x then
          e.x = e.x - (0.5)
        else
          e.x = e.x + (0.5)
        end
      end
      if e.y > 128 then
        del(enemies, e)
      end
      if level_state == 5 then
        del(enemies, e)
        explode(e.x + e.w * 4, e.y + e.h * 4, e.w * 6, e.exc, 1, e.name)
        sfx(3)
      end
    --end
    --movement and firing for bomber	
    elseif e.name == 'bomber' then
      if e.lr == 0 then
        if e.x < player_x then
          e.lr = 1
        else
          e.lr = -1
        end
      end
      --bomber always moves side to side.
      side_bounce()
      e.y = e.y + (e.movespeed)
      if e.y > 128 then
        e.y = -64
      end
      e.x = e.x + (e.lr / 4)
      if e.firspd > 0 then
        e.firstp = e.firstp - (1)
        if e.firstp < 1 then
          enemy_fire(e.x, e.y, e.name, e.exc, lr, plr)
          e.firstp = e.firspd
        end
      end
    end
  end
  for ex in all(explosions) do
    ex.r = ex.r + (1)
    ex.t = ex.t - (1)
    if ex.t < 0 then
      del(explosions, ex)
    end
    if ex.name == 'player' then
      ex.r = ex.r + (1)
    end
  end
  if level_state < 3 then
    starfield(1, 13)
  elseif level_state < 6 then
    starfield(4, 9)
  else
    starfield(3, 11)
  end
end

-->8
--draw section
function _draw()
  cls()
  --splash screen
  if game_state == 'splash_screen' then
    splash()
    if game_time > 59 or (btn() > 0 and btn() < 16) then
      game_state = 'title_screen'
    end
  end
  if game_state == 'title_screen' then
    title()
  end
  if game_state == 'hangar' then
    hangar()
  end
  if game_state == 'game_over' then
    game_over()
  end
  if game_state == 'you_win' then
    you_win()
  end
  if game_state == 'main' then
    for s in all(stars) do
      circ(s.x, s.y, s.speed, s.col)
    end
    --map scrolls based on enemy population
    if level_state > 2 then
      if enemy_population * 3 < abs(mapscroll) and game_time % 10 == 0 and mapscroll < 0 then
        mapscroll = mapscroll + (1)
      end
      if level_state > 2 and level_state < 6 then
        pal(1, 2)
        pal(3, 4)
        pal(9, 2)
        pal(10, 8)
        map(0, 0, 0, mapscroll, 16, 64)
        pal()
      end
      if level_state > 5 then
        if level_state > 6 then
          pal(1, 2)
          pal(3, 8)
          pal(9, 14)
          pal(10, 15)
        end
        map(16, 0, 0, mapscroll, 16, 64)
        pal()
      end
    end
    for ex in all(explosions) do
      circ(ex.x, ex.y, ex.r, ex.c)
    end
    if player_weapon == 'ftl' then
      for trail in all(pl_trail) do
        if game_time % 4 < 2 then
          spr(16, trail.x, trail.y)
        end
      end
    end
    --particles
    draw_particles()
    --draw player
    pal()
    if player_lives > 0 and game_time < player_invincibility then
      if game_time % 2 == 0 then
        spr(player_sp, player_x, player_y)
      end
    else
      spr(player_sp, player_x, player_y)
    end
    --ftl charge effect
    if player_ftl_charge > 0 and game_time % 2 == 0 then
      circ(player_x + 4, player_y + 4, player_ftl_charge * 0.7, 2)
      circ(player_x + 4, player_y + 4, player_ftl_charge * 0.5, 14)
      circ(player_x + 4, player_y + 4, player_ftl_charge * 0.3, 15)
    end
    for p in all(projectiles) do
      spr(p.sp, p.x, p.y)
    end
    for coin in all(coins) do
      if game_time % 30 < 6 then
        sprite_highlight(7, 9, coin.x, coin.y)
      end
      if coin.special == 'lifeup' then
        if game_time % 30 < 15 then
          pal(10, 8)
          pal(9, 2)
          pal(7, 14)
        else
          pal(10, 14)
          pal(9, 8)
          pal(7, 7)
        end
      else
        pal()
      end
      --tutorial
      if has_collected_coin == false then
        print("collect", min(100, coin.x + 7), coin.y, 9)
      end
      spr(9, coin.x, coin.y)
    --pal()
    end
    --draw enemy projectiles
    for ep in all(enemy_projectiles) do
      if ep.name == 'comans_las' or ep.name == 'masts_las' or ep.name == 'masts_lasran' then
        spr(ep.sp, ep.x, ep.y, 1, 2, ep.x_flip)
      else
        spr(ep.sp, ep.x, ep.y, 1, 1, ep.x_flip)
      end
    end
    for e in all(enemies) do
      if e.draw_immune == true then
        -- for i=1,15 do
        -- pal(i,12)
        -- end
        -- for x=-1,1 do
        -- for y=-1,1 do
        -- spr(e.sp,e.x+x,e.y+y,e.w,e.h)
        -- end
        -- end
        sprite_highlight(12, e.sp, e.x, e.y, e.w, e.h)
        e.draw_immune = false
      end
      pal()
      if e.flash == 1 then
        flash()
        e.flash = 0
      end
      if e.name == 'masts' and game_time % 160 > 120 and game_time % 4 < 3 then
        pal(3, 8)
        pal(11, 14)
      end
      if e.name == 'masts' and e.hp < 500 and game_time % 4 < 3 then
        pal(13, 6)
        pal(2, 5)
      end
      spr(e.sp, e.x, e.y, e.w, e.h)
    end
    pal()
    --player ui section
    if player_coins > 0 and game_time - player_show_coins < 60 then
      spr(9, 112, 0)
      print(player_coins, 121, 1, 10)
    end
    if player_heat > 1 then
      heatbartime = game_time + 15
    end
    --player_heat=min(player_heat,player_reactor_max)
    if player_heat >= player_reactor_cooling or game_time < heatbartime then
      rect(125, 125 - (player_reactor_max / 2), 127, 127, 1)
      if player_heat < player_reactor_max * 0.8 then
        line(126, flr(126 - (player_heat / 2)), 126, 126, 10)
      -- elseif player_heat>player_reactor_max*0.8 and player_heat<player_reactor_max then
      -- line(126,flr(126-(player_heat/2)),126,126,8)
      else
        line(126, 126 - min(player_heat / 2, player_reactor_max / 2), 126, 126, 8)
        line(126, 126 - player_reactor_max / 2 * 0.8, 126, 126, 10)
      end
      if player_heatlock == true then
        heatlockcolour = (game_time % 2) + 8
        rect(125, 125 - (player_reactor_max / 2), 127, 127, heatlockcolour)
      else
        heatlockcolour = 1
      end
      print(player_reactor_status, 89, 123, heatlockcolour)
    end
    --ftl display
    if player_lives > 0 then
      if player_ftl_charge > 0 then
        rectfill(122, 120 - player_ftl_charge, 122, 120, 14)
      end
      if player_weapon == 'ftl' then
        rect(121, 121 - player_ftl_max, 123, 121, 2)
        print("drive", 101, 117, 2)
      end
    end
    cool_print('score: ' .. score, 0, 0, 0)
    print('score: ' .. score, 0, 0, 10)
    --tutorial
    if score < 10 then
      print("4/z shoot\n5/x change weapon\n2301 move", 1, 109, 9)
    else
      if player_weapon == 'ftl' and has_visited_hangar == false then
        print("charge ftl to warp to\nupgrade hangar", 1, 115, 9)
      end
    end
    --current weapon hud
    if player_weapon == 'missile' then
      hud_weapon_sprite = 2
    elseif player_weapon == 'machinegun' then
      hud_weapon_sprite = 3
    elseif player_weapon == 'plasma' then
      hud_weapon_sprite = 4
    elseif player_weapon == 'ftl' then
      hud_weapon_sprite = 32
    end
    rectfill(0, 6, 7, 13, 1)
    --		for i=0,15 do
    --			pal(i,0)
    --		end
    --		for x=-1,1 do
    --			for y=-1,1 do
    --				spr(hud_weapon_sprite,0+x,6+y)
    --			end
    --		end
    --		pal()
    spr(hud_weapon_sprite, 0, 6)
    rectfill(0, 15, 7, 22, 1)
    -- for i=0,15 do
    -- pal(i,0)
    -- end
    -- for x=-1,1 do
    -- for y=-1,1 do
    -- spr(16,0+x,15+y)
    -- end
    -- end
    -- pal()
    spr(16, 0, 15)
    print(player_lives, 3, 17, 7)
    if enemy_population > 97 then
      print("sector " .. level_state / 3 + 1, 48, 48, 10)
      if level_state == 0 then
        print("outer solar system", 28, 54, 7)
      elseif level_state == 3 then
        print("asteroid base", 38, 54, 7)
      elseif level_state == 6 then
        print("dyson sphere", 40, 54, 7)
      end
    end
    clear_messages = {}
    if level_state == 2 then
      clear_messages = {'sector 1 clear', 'use ftl to leave area'}
    end
    if level_state == 5 then
      clear_messages = {'sector 2 clear', 'use ftl to leave area'}
    end
    if level_state == 8 then
      clear_messages = {'sector 3 clear', 'ex-tar is defeated', 'use ftl to return to earth'}
    end
    for i = 1, #clear_messages do
      if i == 1 then
        clear_line_colour = 10
      else
        clear_line_colour = 7
      end
      centre_print(clear_messages[i], 42 + i * 6, clear_line_colour)
    end
  end
--debug stuff
end

-->8
--particles
function create_exhaust(x, y, c1, c2, speed, number)
  for i = 1, number or 3 do
    local exhaust = {x = x, y = y, c = c1, c1 = c1, c2 = c2, age = ceil(rnd(10)) + 5, speed = speed or 0}
    add(exhausts, exhaust)
  end
end

function create_player_exhaust()
  create_exhaust(player_x + 2 + ceil(rnd(2)), player_y + 6, player_c1, player_c2, player_speed)
end

function create_explosion(x, y, c1, size)
  for i = 1, size or 10 do
    local explode = {x = x, y = y, c = c1, age = ceil(rnd(20)) + 10, dx = 1 - rnd(2), dy = 1 - rnd(2),}
    add(explodes, explode)
  end
end

function update_particles()
  for exhaust in all(exhausts) do
    exhaust.y = exhaust.y + (1 + exhaust.speed)
    exhaust.x = exhaust.x + (0.6 - rnd(1.2))
    exhaust.age = exhaust.age - (1)
    if exhaust.age % 3 == 0 then
      exhaust.c = exhaust.c2
    else
      exhaust.c = exhaust.c1
    end
    if exhaust.age < 0 then
      del(exhausts, exhaust)
    end
  end
  for explode in all(explodes) do
    explode.x = explode.x + (explode.dx)
    explode.y = explode.y + (explode.dy)
    explode.age = explode.age - (1)
    if explode.age < 0 then
      del(explodes, explode)
    end
  end
end

function draw_particles()
  for exhaust in all(exhausts) do
    pset(exhaust.x, exhaust.y, exhaust.c)
  end
  for explode in all(explodes) do
    pset(explode.x, explode.y, explode.c)
  end
end

-->8
--screens
function game_over()
  enemies = {}
  enemy_projectiles = {}
  starfield(1, 13)
  spr(44, 56, 8, 2, 2)
  for i = 1, 5 do
    spr(34, 24 + (i * 12), 24)
  end
  for i = 1, 7 do
    spr(33, 12 + (i * 12), 32)
  end
  dramatic_music = nil
  if game_over_music == nil then
    music(18)
    game_over_music = 1
  end
  cursor(22, 48, 7)
  print('game over\n')
  color(6)
  print('with our last ship\ndestroyed there is\nnothing to stop ex-tar\nfrom galactic tyranny.\n\nyour score: ' .. score .. '\nhigh score: ' .. high_score)
  color(7)
  print('\npress 4+5 to restart')
  if btnp(4) and btn(5) then
    reset()
    game_time = 0
    game_state = 'splash_screen'
    game_over_music = nil
  end
end

function hangar()
  has_visited_hangar = true
  pal(4, 1)
  pal(15, 4)
  pal(9, 13)
  pal(10, 12)
  pal(3, 9)
  pal(11, 10)
  map(112, 48, 0, 0, 16, 16)
  pal()
  hangar_a = '23: select system'
  hangar_b = '4: upgrade system'
  hangar_d = 'upgrade cost: '
  rectfill(15, 64, 113, 116, 1)
  rect(15, 64, 113, 116, 5)
  rectfill(0, 121, 36, 128, 1)
  rectfill(1, 1, 66, 55, 5)
  rectfill(2, 2, 5, 54, 1)
  print('ship hull\nship engines\nreactor cooling\nreactor output\nmissile yield\nvulcan cannon\nplasma\nftl charge\nleave hangar', 7, 2, 7)
  spr(9, 0, (cur_upg * 6) - 5)
  if cur_upg == 1 then
    if player_lives >= player_lives_max then
      cur_upg_tex1 = 'ship strength: ' .. player_lives .. '/' .. player_lives_max
      cur_upg_tex2 = 'increase by ' .. upg_lives_max_value
      cur_upg_cost = upg_lives_max_cost
    else
      cur_upg_tex1 = 'ship strength: ' .. player_lives .. '/' .. player_lives_max
      cur_upg_tex2 = 'repair by ' .. upg_repair_value
      cur_upg_cost = upg_repair_cost
    end
  elseif cur_upg == 2 then
    cur_upg_tex1 = 'ship speed: ' .. player_speed * 100
    cur_upg_tex2 = 'improve by ' .. upg_speed_value * 100
    cur_upg_cost = upg_speed_cost
  elseif cur_upg == 3 then
    cur_upg_tex1 = 'cooling rate: ' .. player_reactor_cooling .. "gw"
    cur_upg_tex2 = 'improve by ' .. upg_cooling_value .. "gw"
    cur_upg_cost = upg_cooling_cost
  elseif cur_upg == 4 then
    cur_upg_tex1 = 'reactor output: ' .. (player_reactor_max * 8) .. 'gw'
    cur_upg_tex2 = 'improve by ' .. (upg_reactor_value * 8) .. 'gw'
    cur_upg_cost = upg_reactor_cost
  elseif cur_upg == 5 then
    cur_upg_tex1 = 'missile yield: ' .. player_missile_ext .. 'mt'
    cur_upg_tex2 = 'improve by ' .. upg_missile_ext_value .. 'mt'
    cur_upg_cost = upg_missile_ext_cost
  elseif cur_upg == 6 then
    cur_upg_tex1 = 'vulcan damage: ' .. player_machinegun_damage
    cur_upg_tex2 = 'improve by ' .. upg_machinegun_damage_value
    cur_upg_cost = upg_machinegun_damage_cost
  elseif cur_upg == 7 then
    cur_upg_tex1 = 'plasma power: ' .. (player_plasma_damage * 5) .. 'gw'
    cur_upg_tex2 = 'improve by ' .. (upg_plasma_damage_value * 5) .. 'gw'
    cur_upg_cost = upg_plasma_damage_cost
  elseif cur_upg == 8 then
    cur_upg_tex1 = 'ftl charge rate: ' .. player_ftl_max
    cur_upg_tex2 = 'improve by ' .. upg_ftl_max_value
    cur_upg_cost = upg_ftl_max_cost
  elseif cur_upg == 9 then
    cur_upg_tex1 = ''
    cur_upg_tex2 = ''
    cur_upg_cost = ''
  end
  print(cur_upg_tex1, 17, 66, 6)
  print(cur_upg_tex2, 17, 72, 6)
  centre_print(hangar_a, 84, 7)
  centre_print(hangar_b, 90, 6)
  centre_print(hangar_c, 102, 7)
  centre_print(hangar_d .. cur_upg_cost, 110, 7)
  print('coins: ' .. player_coins, 1, 122, 10)
  if btnp(2) then
    toggle_upg(-1)
    sfx(18)
  end
  if btnp(3) then
    toggle_upg(1)
    sfx(18)
  end
  if game_time > time_since_ftl then
    if btnp(4) then
      if cur_upg < 9 then
        do_upg(cur_upg)
      --returns player to game. leave hangar
      elseif cur_upg == 9 then
        game_state = 'main'
        --clear_trails()
        delete_entities()
        player_x = 64
        player_y = 96
        if mapscroll < -384 then
          mapscroll = -384
        end
        if level_state == 0 then
          music(8)
        elseif level_state == 3 then
          music(41)
        elseif level_state == 6 then
          music(29)
        end
      end
    end
  end
end

function splash()
  --draw
  if splash_music == nil then
    music(0)
    splash_music = 1
  end
  rect(51, 56, 73, 81, 4)
  rectfill(52, 55, 74, 79, 5)
  rect(52, 55, 74, 80, 9)
  spr(14, 55, 56, 2, 2)
  print('extar', 53, 74, 4)
  print('extar', 54, 73, 9)
end

function title()
  --draw
  --title splash graphics
  if view_story == 1 then
    for i = 1, 7 do
      pal(i, 0)
    end
    for i = 8, 15 do
      pal(i, 1)
    end
  end
  sspr(0, 32, 64, 32, 0, 16, 128, 64)
  pal()
  print("start game\ndifficulty:" .. difficulty .. "\nview story", 32, 86, 7)
  print("23 select option\n4 or 5 to select", 32, 110, 1)
  print("V" .. version, 0, 122, 1)
  if game_time % 20 < 10 then
    spr(9, 24, menu_cursor_y)
  end
  if btnp(2) then
    view_story = 0
    menu_cursor_y = menu_cursor_y - (6)
    if menu_cursor_y < 85 then
      menu_cursor_y = 97
    end
  end
  if btnp(3) then
    view_story = 0
    menu_cursor_y = menu_cursor_y + (6)
    if menu_cursor_y > 97 then
      menu_cursor_y = 85
    end
  end
  if btnp() > 0 then
    sfx(18)
  end
  if view_story == 1 then
    --rectfill(3,3,127,45,5)
    --rectfill(2,2,126,44,1)
    if story_screen == 1 then
      cool_print('our fleet has been destroyed \nby the extarians.\nall that remains is the\nprototype ship: red venom\nyou are our best pilot. you\nmust defeat ex-tar', 3, 19, 7)
      cool_print('for great justice!', 3, 59, 8)
    elseif story_screen == 2 then
      cool_print('ship name: red venom', 3, 19, 8)
      cool_print('reactor: twin super-cold-fusion\npower output: 800gw (estimated)\nmain weapon: atomic missile\nsecondary: vulcan cannon\nspecial: multi-phase plasma\nftl drive: experimental', 3, 34, 7)
    end
    cool_print(story_screen .. "/2", 3, 77, 6)
  end
  if btnp(4) or btnp(5) then
    if menu_cursor_y == 85 then
      game_state = 'main'
      music(8)
      splash_music = nil
      cooldown_missile = game_time + cooldown_missile_cooldown
    elseif menu_cursor_y == 91 then
      toggle_difficulty()
    elseif menu_cursor_y == 97 then
      if view_story == 0 then
        story_screen = 0
      end
      view_story = 1
      story_screen = story_screen + (1)
      if story_screen > 2 then
        story_screen = 1
      end
    end
  end
  if btnp(2) or btnp(3) then
    view_story = 0
    story_screen = 0
  end
end

function you_win()
  starfield(1, 13)
  spr(44, 24, 4, 2, 2)
  spr(140, 48, 4, 4, 4)
  spr(44, 88, 4, 2, 2)
  if you_win_music == nil then
    music(23)
    you_win_music = 1
  end
  you_win_1 = 'victory!'
  centre_print(you_win_1, 38, 7)
  cursor(0, 50, 7)
  color(6)
  print('with the evil mastermind\ndefeated, the remnants of the\nalien fleet scatter.\nearth is saved.\nfor now...\n')
  color(10)
  print('your score: ' .. score .. '\nhigh score: ' .. high_score)
  color(7)
  print('\npress 4 or 5 to restart')
  if btnp(5) or btnp(4) then
    game_time = 0
    game_state = 'splash_screen'
    game_over_music = nil
    init_variables()
  end
end


__gfx__
00000000000880000000000000000000000000000000000000000000000000000000c00000000000000333300333300000deed0000eded000000000090000000
000000000086c800000000000000000000000000000000000000100000000000000c00000000000000b3b33bb33b3b000eeededededffdd00000009949900000
000000000086c8000008800000000000000000000000000000010000000440000000c000000aa000063b3b3333b3b360ddfdfedfdefddfe00000994494499000
000000000086c80000088000000aa000000cc0000003b000000210000049a400000c000000aa9a003760003333000673deefefdedc7cdefe0099440090044990
000000000e8888e00006600000099000000dd00000bbb3000021210000499400000dc00000a97a00b550000b3000055befedd6dfec7cedde0944000090000449
00000000e88ee88e0008800000000000000c00000033bb000012120000044000000cd000000aa0003760000330000673dddcd5defe6efede0999440090044999
000000008880088800800800000000000000d000000b300000e22e0000000000000dc0000000000006500003b0000560ed6ddfdded5dedde0940994494499049
00000000806006080000000000000000000d000000000000000ee00000000000000cd000000000000550006336000550ed5d5ef5fefed5ee0940009949900049
00022000000880000000000005888e0000111100055555500007a000035675300006c0002ef77fe20550556b36550550dfef6dd5dd5dd6dd0940000494000049
002512000086c80000000000058dd770000cc000502dd2050a0a700000055000000c60002ef77fe20655000330005560ded6dfe6ff6d6eee0940099494990049
002512000086c800000880000888d7700011110052dddd250000a0a0000670000006c0002ef77fe205500003b00005500ee6dee6616e5ed00949944090449949
002512000086c80000088000088888e0000cc0005dddddd50007000000667600000c60002ef77fe206500b3333b0056000d5e115515e55000944400090004449
012222100e8888e00006600000666600000110002d9dd9d20a0a7000005355000007c0002ef77fe207600eb33be0067006665556655566600099440090044990
12211221e88ee88e000880000688786000cccc00d000000d0000a0a000553500000c70002ef77fe206600b3333b006600776661cc16667700000994494499000
22200222888cc888008cc8000688880001c11c10d000000d00070000006676000007c0002ef77fe2056500ebbe005650000771c7cc1777000000009999900000
20500502806cc608000cc00000500500000cc000525005250a0a700000067000000770002ef77fe20676000bb00067600000001cc10000000000000090000000
777000000000000000566500005665000020082280208200000000944900000000000000000000000000b3b3b3b0000000055565655550000056749949476500
70000000003bb30005566550055665500082080562808200000009aaaa9000000000001d10000000003b3b3b3b3b300000566676766665002556677777766552
7707770003bbbb30056776500567765000822806728280001100019aa9100011000005d1d500000003bbbb3bb3b3b30001556777777655002244949999449422
700070000bbbbbb002677620096776900008288568828000660005aaaa5000660000051d150000000b3bb3a33a3b3b3002566667766665106555686446865556
0ff070703babbab312a22a2149a99a9402028886788800205565511991165655000005d1d5000000b3b3339339333bb0215528eee82555200655586446855550
fff07070b000000b200000029099990928828885688828825606511aa115606500000518150000003b3a933bb339a3b312566667676665210756569229656570
eeee0070b000000b200000026700007680882886788288089500651991560059000051d1d1500000bb393bbbbbb393bb22566222222665220076624944266700
222220770300003001000010560000658008282562828008a10006aaaa60001a00005d818d5000003bb3bb7b7bbb3bb3125622e2e22265210049774949779400
003bb30000000000000880005550000500558826728855007100079449700017000051ccc1500000bb0bb0606bb00bbb220220e0e26602220499004949009940
03bbbb3000000000008ee800080555500566588568856650a10006aaaa60001a0000dc1cddc000003b00bb0000b000b365002200002000650999044949909990
00cffc000333333008e00e80e8e8e8e856776526725677659500056776500059000ddcd1d0cd0000bbb00bb00bb000bb65555220022555560490000940000940
00ff0f000b3333b08e08e0e8e8e8e8e806775556655577605609aa6776aa906501d11cd1d0cd10003bb000b0bb0000b356666520225666650990009004000990
773333303babbab38e0e80e8e8e8e8e80676885665886760770a19a99a91a0771d0001c0dd1cdd000bb0007070000bbb56e765707056e7650556000000006550
663bb330b033330b08e00e80e8e8e8e80676a257752a6760660aaa1aa1aaa066100010c01d1c01d10bb000606000bbb0562e656060562e650575600000065750
36dddd3030000003008ee8000805555000672257752276000000aaa99aa9000000010ddc0100c01000bb00000007b00056666500005666650076570000756700
005005000000000000088000555000050006666776666000000009a44a9000000000001c0000c010000760000006000005555000000555500077757007577700
00020202e2e2e2e07702e2e2e2e2e2efefefefefefefefefefefe2e2e2e2e2020555555555555555555555500000000000000540000000004454544545545454
0000202e2e2e2e2077702e2e2e2e2e2efefefefefefefefefefefe2e2e2e20205500000000000000000000550000054504400554005454005545545554455454
0000020202e2e2e0222702e2e2e2e2e2efefefefefefefefefefefe2e2e200005055533301055533010555050004545444554455545555404455454445544545
00000000000e2e20700700000000000000000000000000000efefe2e202000005050500010350503103505050045454544545445455554505455455454554545
000000000000e2e0700707770707070707007070777070070fefe2e2020200005055533000355503003555050054545454444444545454405545445445445554
1000000000000020700707270777770707707070727077070efe2e20202000005003333003330003033300050055455544455445454555404554554044554545
0000000000000000200707070727270707277070707072770fefe2e2020000005010103103000103030001050454555545444545445454505455440005455555
0000007700000000777207070707070707027070707070270efe2e20200000005000003333010003330100050545445444454444544545004544554004544544
0000000000000000772007770707070707007070777070070fe2e202000000005000100105555550010101050455555455554545544445405454540000455555
ccccccccccccc000220002220202020202002020222020020efe2020000000005003333355000055335550050454544545545454555545404545554005455454
000000000000000000000aa00000000000000000000000000fe20200000000005013000350331005035051054545455545454545545454544454545444555445
000000000000000000000aaaaa0020202efefefefefefefefefe2000000000005055501350055505005550055454545554455554454555455455454545554454
0777700000000000000009999902020202e2efefefefefefefe20000000010005050533350350505000301054555445445554454454454544555455454555545
0000001000cccccc00000a000000000000202e2e2efefefefe202000000000005055510050055505330300054445544554455444545545445455445454545454
000000000000000000000aaa000a000a02020202e2e2efefe2020000000000005003000055000055031033050544545544545545455454504544545445555454
000100000000000000000a990009a0a90020202020202efe2e200000cccccc005333003305555550030103050054455445454455445554004455455554454545
00000000000000000000090000009a9002000202020202efe2020000000000005000100100100100310000050044544454454545545445403100003010001001
000000000777777000000aaaaa00a9a0000000002020202e20200000000000005003333305550333333333050004554554545554554554003333333033333333
000000000000000000000aa9990a909a000000000202020202000000000000005013000305051310030010050044454455454555545445000300103130130003
000cccccccc000000000099000090009000000000000002020000cc0007777005055501305550333030555050055454454545545454545000305550030555013
00000000000000000000000000000000000000000000000200000000000000005050533310301300033505050005455445445454545555000335055555505333
00000000000000000000e888ee000000000010000000000000000000000000005055510000300301010555050000044454554545455450000105550550555130
000000000000001000000e8888ee0000000000000000000ccccccccccccc00005500000000033333000000550000000045555400000000000000500500050030
0000000000000000000000e88888ee00000000000000000000000000000000000555555555555555555555500000000004550000000000003330550555550330
0000cccccccccccccccc6588888888eeeeeeeeee7d70000000000000000000005500005555000055550990555555555554545454554444550030555550550300
cccccccccccccccc7777656666688888888888eed7d7d00001000000000000005055500550555005500aa0054454445449455994545445453330500050050301
cccccccc7777777777776666555665688888888e7d7d7d000000000000000000059a950505000505555995555555555554500545455445540105550550555333
cccccccc7777777777776565655555655666688888eeeee0000077777000000059aa795550000055500aa00545444544450005544449a4441035055555505000
cccccccccccccccc7777655556666568888888888888888e0000ccccccccccc059a7a95550000055500990055555555559500045444994440035550550555330
0000cccccccccccccccc658888888888ee555500000000000000000000000000059a950505000505555aa5555444544445450054455445540333000550033330
001000000000000000000e888888ee00000000000000000000000000000000005055500550555005500990055555555554545945545445450300010550101031
00000000000000000000eeeeee000000ccccc0001000777777777777700000005500005555000055550aa0554445444545454454554444553301000550000033
b7b7339700000000000000000000b7c7e7a400000000000000000000000084f7000056000444444444444400000000000000000000deed0000eded0000000000
000000000000000000000000000000000000000000000000000000000000000000005600488888888888884000000000000000000eeededededffdd000000000
b7b7b7b7b7b79797979797979700b7b700e7a497978494949494a4979784f700000567688844444444444888000000000000000dddfdfedfdefddfe000000000
000000000000000000000000000000000000000000000000000000000000000000056765656548888888842888800000000000dddeefefdedb7bdefeddd00000
c5c5c5c5c7b70000000000009797f4b700e6a600008696969696a6000086f600000567656565444444448822288800000000ddd2efedd6dfeb7bedde2ddd0000
000000000000000000000000000000000000000000000000000000000000000000056762884488888888488822888000000ddd22dddbd5defe6efede22ddd000
c5c7c5c5c5b70000000000000000f5b7e6a600000000000000000000000086f60085675288888444444888888222880000ddd222ed6ddfdded5dedded222dd00
0000000000000000000000000000000000000000000000000000000000000000088567588288488888848228882228800ddd222ded5d5ef5fefed5eedd222dd0
b7b7b7b7b7b79797000000000000b7b7a600000000000000000000000000008688856758824484444448822888822288ddd222dddfef6dd5dd5dd6ddddd222dd
000000000000000000000000000000000000000000000000000000000000000088256755656548888884822288882228dd222dddded6dfe6ff6d6eeedddd222d
b7b7000000970000000000000000b7c700000000000000000000000000000000222567556565444444488822288888222222ddd22ee6dee6636e5ed22d555522
00000000000000000000000000000000000000000000000000000000000000002556667568444888888488822288888822dddd2222d5e335535e55222565667d
b7b7000000970000000000000000b7b700000000000000000000000000000000856dddd7588888444488888822228888dddd22222666555665556662255b767d
0000000000000000000000000000000000000000000000000000000000000000856dccd6588284888848228866222228ddd5622d2776663bb36667726563b67d
b7b7b7d40000000000000000b4b7b7b700000000000000000000000000000000855dccd5522288844888222555682228dd5676dd222773b7bb3777225556677d
00000000000000000000000000000000000000000000000000000000000000000222cc442228884884888256dc568880025676dd2222223bb32222223b777770
b7d7b7d50000000000000000b5c7b7b7000000000000000000000000000000000084444888888848888888856658880065666666ddddddddddddddd565666666
00000000000000000000000000000000000000000000000000000000000000000884844488848444444848885588448055577755dd00d2dd2dd2dd0d55577755
b7b7b7d50000000000000000b5c7b7b784a4979784a49797979784a4979784a4088884484844444444444484484844800506605000dddd22dd2dd0d005066050
00000000000000000000000000000000000000000000000000000000000000000848848888556666566666684844848005056050dd5566665666666d05056050
b7d7b7d50000000000000000b6f4b7b786a6000086a60000000086a6000086a60848484845655555555555564804848005066050456555555555555605066050
00000000000000000000000000000000000000000000000000000000000000000848488446d6555555555556480484880605606046d655555555555006056060
b7b7b7d5000000000000000000b6f4b7000000009700000000000097000000000848448856d7535353535356480484880606606056d753535050505006066060
00000000000000000000000000000000000000000000000000000000000000000650848457c75b5b5b5b5b56484844800705607007c75b5b5050505007056070
b7d7b7d500000000000000000000b5b7000000009700000000000097000000000660848457c6555555555555484844800706607057c655555555555007066070
00000000000000000000000000000000000000000000000000000000000000000550848456d6666666666656484844800005600056d666666066665600056000
b7b7b7d500000000000000000000b5b7000000009700000000000097000000000660848456d6555555555656048845600006600056d625552055565600066000
00000000000000000000000000000000000000000000000000000000000000000000658455655444444456560488466000556700556004402004565000556700
b7b7e4d600000000000000000000b5b7000000009700000000000097000000000000668404444555566645400560455000067000240045500202454000067000
0000000000000000000000000000000000000000000000000000000000000000000055840084444444444480466006600055670020d44440000202d000556700
b7e4d60000000000000000000000b5b7000000009700000000000097000000000000660400084488444888004550000000067000200d40dd000d020000067000
000000000000000000000000000000000000000000000000000000000000000000000000000080808808040086600000005567000200d0d0000d040000556700
b7d5000000000000000000000000b5c5a484a484a497979797979784a484a4840000000000055565655550000500000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000005666767666650005000050b6f4c5c5c5c5c5c5c5c5c5c5c5c5c5c5
b7d5000000000000000000000000b5c595959595a500000000000085959595950767676767556777777655767676767000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005656565656566667766665156565656500b6c6c6c6c6c6c6c6c6c6c6a7a7a700
b7d5000000000000000000000000b5c595959595a5000000000000859595959576050500655528eee82555200050506700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007600500056566667676665210005006700d7a7a7d70000a797a70000a7a7a700
b7d6000000000000000000000000b5c795959595a500000000000085959595957605050066566222222665220056667000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000007666500565622e22e2265210055567500d7a7a7d70000a700a70000a787a700
b7d4000000000000000000000000b5c5959595e6a600000000000086f695959557655550650220e00e0220220056667500000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000500000506500220000220021005556750000a7a7000000a797a700008e9eaebe
b7d5000000000000000000000000b5c59595e6a6000000000000000086f695950000000006500220022005600056677500000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000076000200200067005555550d4009797000000a700a700008f9fafbf
b7d5000000000000000000000000b6c595e6a60000000000000000000086f6950000000000e7007007007e005566665500000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000002e00600600e20066777766d5000000000000a797a7979797979797
e4d600000000000000000000000000f4e6a600000000000000000000000086f6000000000000000000000000effffffe00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee0d5000000000000a700a7000000000000
d50000000000000000000000000000b5a60000000000000000000000000000865509900556055555506690600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005009aa9a9a9599995055a56500000000d5000000000000a797a7000000000000
d50000000000000000000000000000b5a4000000000000000000000000000084500a9a9a9a955a755066a5600070000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000550000066705a7a95055506507d00000d5000000000000a700a7000000000000
d500000000000000000000000000b4f5a50000000000000000000000000000855500000556005555006600600d70000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005000e8866700000600550065d7d00000d6000000000000a797a7000000000000
d500000000000000000000000000b5c5a500000000000000000000000000008550000e8556ee0006006600607d70000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000550000e66788ee0600550065d7d0000031030000000000a700a7000000000000
d500000000000000000000000000b5c5a500000000000000000000000000008555006585568888e6eeeeee6e0000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000050006566666888888888886556000000b7b70000000000a797a700000000b4c4
e5d4000000000000000000000000b6f495a400000000000000000000000084f750006666555665688888886e5566600000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000055006565655555655666686588eeeee0b7b70000000000a700a7000000b4f5c5
c5d500000000000000000000000000b595a500000000000000000000000085955500655556666568888888688888888e00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005000658888888888ee55006500006500b7b7c4d4000000a797a7000000b5c7c7
c5d5000000000000000000000000b4f595a5000000000000000000000000859550000e888888ee00650000600000560000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000005555eeeeee0000005655556500556555b7b7c5d5000000a700a700b4c4f5c5c5
__map__
7d7d4b7d7d7d7d6e6f7d7d7d7d4d7d7d796e697a69786978786978697a696f79000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7d7d6b6c6c686a7e7f686a6c6c6d7d7d005a007a15000000000000157a005800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a7a4a00000000000000000000487a7a005a007a78000000000000787a005800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a7a6a00000000000000000000687a7a005a007a15000000000000157a005800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b005a007a78000000000000787a005800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b005a007a15000000000000157a005800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333333333333333333336e6a007a78000000000000787a00686f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b5a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b5a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
333333333333333333333333333333335a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b5a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b4d000000000000000000004b7b7b5a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a7a5d000000000000000000005b7a7a5a00007a00000000000000007a000058000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d000000000000000000005b7b7b6a00007a00000000000000007a000068000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d000000000000000000005b7b7b0000007a00000000000000007a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a7a5d000000000000000000005b7b7b494a007a00000000000000007a004849000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d000000000000000000005b7b7b6e6a007a00000000000000007a00686f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d000000000000000000005b7c7c59005979000000000000000079000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c5c5d000000000000000000006b7c7c00000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c5c5d0000000000000000000000787859005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d0000000000000000000000787800000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b5d0000000000000000000000787959005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c5c5d0000000000000000000000797900000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c5c5d0000000000000000000000787959005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b6d00000000000000000000007b7b00000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b59005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b7979790000000000007979797b7b00000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b59005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b3333000000000000333333337b7b00000000000000000000000000005979000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b0000000000000000000000007b7b59005900000000000000000000000059000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7b7b3300000000000000000000337b7b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c7b7979000000000000000000007b7b4a787978797879787978797879787948000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000126500e150070500000001100021000210000100001000010001100011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000000000256501d15018150191501415013150111500e1500c15008150041500215005100041000310002100216000010000000000000000000000000000000000000000000000000000000000000000000
0001000018650216500c050150501e05010050090001d000190001300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000f4711247313471114710d47324673136730b6730a6730865303673016730065300673006730067300603006030060300603006030060300603006030060300603006030060300603006030060300603
00030000095500d5502005020050241502c1503325039250004003d2003e2003e2000c20000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000001357063570235700350207500f7500975015750017501175006700000000475001700000000a75000000037500000000000000000375000000000000175000750000000000002750000000a75000003
000a00003b4731f473194731447312473296731867213673136721265312672106730d6520b673086720767305652046530365203653036520265302652026530165201653006520065300652006020060200602
000600002c6711967313461114410d4432467313673176730a67308653036730a6730065300673006730067300603006030060300603006030060300603006030060300603006030060300603006030060300603
01030000035500b55013550195501c45021450264502a4502f40034400384003e4003f4000b600096000a60009600086000760006600036000360002600016000160000600006000060000600000000000000000
000400000335003350033500335003350000000030003350033500335003350033500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000005201552020520355204052055520605206552090520d5520d052256501b6530c6530a6530864306643056330463304633036330362303623026230162301623006230061300613006130060000000
01030000005500105002550030500455005050065500705008550090500a5500b0500c5500d0500e5500f050105501105012550130501455015050165501705018550190501a5501b0501c5501d0501e5501f050
0003000026600266501d75018750197501475013750117500e7500c75008750047500275005100041000310002100216000010000000000000000000000000000000000000000000000000000000000000000000
000500001e3542135421354263000c1030c0530b0530a053000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000063500b35013340163401e33024330263202832025310233101f300173000730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000004550545510455174551a455204550140501400004540545410454174541a45420454014050140000005000050000500005000050000500005000050000500005000050000500005000050000500000
01030000261531d75618756197561475613756117560e7560c7560875604756027560510004100031000210021600001000000000000000000000000000000000000000000000000000000000000000000000000
0103000000550000500155001050025500205003550030500455004050055500505006550060500755007050085500805009550090500a5500a0500b5500b0500c5500c0500d5500d0500e5500e0500f5500f050
00080000001520c355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000034521a4522f6522a65229652254532045319453104530540302601036010360103601036010360102601036010060100601026010060103601036010060104601006010000100001000010000100001
000400001e6531465319550205540b254062540025400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000115740906511554150451a564000551d5442006522554210451f5641e0551c54414065115540804501564000550004400005000050000500005000050000400004000040000400004000040000400004
01050000295732d063295532d0432656324053295432c0632e5532d0432b5632a053285432c063295532c04325563240532404324003240032400324003240032400324003000032400324003240032400324003
010500000145105451074510b4510d4510d4510d4510d4510d4510d4510c4510a4510945107451054510445101451004510040200402004020040200402004010000100001000010000100001000010000100001
000300003f0513e0513d0513c0513a0513905138051370513505134051310512f0512e0512c0512b051290512605125051210511e0511c0511a0511605114051100510e0510c0510905107051050510305100051
0103000000252023520445206252093520a4520f2521135214452172521b3522045223252273522a4523025200000000000000000000000000000000000000000000000000000000000000000000000000000000
01081000184300c4300c4300061000610184300c4300c430006100061000610006100061000610006100061000300003000030000300003000030000300000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0003b6000c0003b6000c0003b6000c0003b6000c600000000c600000000c600000000c600000000c000000000c000000000c000000000c000000000c000000000c000000000c000000000c00000000
01100000184351843200400184351843200400184350c4320c4320c4320c4220c4220c4220c4120c4120c412004000040000400004000040000400004000040000400004000040000400004000c4321243512432
011000000c1530c153000000c15313670000000c1530c153000000c1530c15300000136700000000000000000c1530c153000000c15313670000000c1530c153000000c1530c1530000013670000001367513670
011000000021000210002100021000210002100021000210062100621006210062100621006210062100621005210052100521005210052100521005210052100421004210042100421004210042100421004210
01100000182350c2350c235182350c2350c235182350c2350c235182350c2350c235182350c235182350c235182350c2350c235182350c2350c235182350c2350c235182350c2350c235182350c235182350c235
010e000024441274412d4412c4412c4422c4422c4422c4422c4422c4422c4422c4422c4422c4422c4422c44224441274412f4412c4412c4422c4422c4422c442244402a440374403c442244422a440384403c442
010e00002445518455194551845524455184551945518455244551845519455184552445518455194551845524455184551945518455244551845519455184552445518455194551845524455184551945518455
010e00000c3530c3531f6750c3530c3530c3531f6750c3530c3530c3531f6750c3530c3530c3531f6750c3530c3530c3531f6750c3530c3530c3531f6750c3531f6751f6750c3530c3531f6751f6750c3530c353
010e00000045500455004550145501455004550045500455004550045500455014550145503455094550945500455004550045501455014550045500455004550045500455004550045501455034550945500455
010e00000c4550c4550c4550d4550d4550c4550c4550c4550c4550c4550c4550d4550d4550f45515455154550c4550c4550c4550d4550d4550c4550c4550c4550c4550c4550c4550c4550d4550f455154550c455
011000002415524155241552415024155241552215522150221552215522155221501f1551f1551f1551f1501f1551d1551a155181501f1551d1551a155181501f1551d1551a155181501f1551d1551a15518150
011000001f054180541f054180541f054180541f054180541f054180541f054180541f054180541f054180541d054180541d054180541d054180541d054180542205418054220541805422054180542205418054
011000000c25300003000030c25313653000030c253000030c253000030c25300003136530000300003000030c253000030c25300003136530000300003000030c253000030c2530000313653000030c6530c653
011000001f1551f1551f1551f1501f1551f1551f1551f1501f1501d1501f15022150241552415524155001002415524155241550010024150221501f1501d15024150221501f1501d15024150221501f1501d150
011000001335513355134550040513355133551345500405133551335513455004051335513355134550040511355113551145500405113551135511455004051635516355164550040516355163551645500705
01100020242112433124411242312431124431242112433124412272322b3122f432242122f3322b4122723224312184320c21224332184120c23224312184320c21224332184120c23224312184320c21224332
010800000c143000000c1430c0000c143000000c1003c6003c615003000c1430c000111431110011143111000c143000000c1430c0000c143000000c0003c6003c615000000c1430c000111433c600111433c600
010800000c150000000c150000000c15000000000000000013150000001615000000181501815018150181500c150000000c150000000c1500000013100000001115000000131500000016150161501615016150
01080000004400c400004500740000450000000000000000004500000000450000000045000000000000000000450000000045000000004500000000000000000045000000004500000000450000000000000000
011800000c043000000c0000c0433c615000000c0433c6000c043000000c0000c0433c615000003c6153c6150c043000000c0000c0433c615000000c0433c6003c615000000c0430c0003c615000003c6153c615
011800000c0500c050110501305016050180501805018050000000c050000000c05000000180501805018050160501605013050130500c050140500c050110500c0500f0500c0500f05011050000001105000000
011000000c153000000c153000003c61530000000000c1533c6003c6150c153000003c615000000c1003c6000c153000000c153000003c61530000000000c1533c6003c6150c153000003c615000000c1003c600
01100020242112433124411242312431124431242112433124412272322b3122f432242122f3322b412272323031130431302113033130411302313031130431242122f3322b41227232243122f4322b21227332
01100020180321803218032180321803218032180321f0312403124032240322403224032240322403224032240322403224032240322403224032240322b0313003130032300323003230032300323003230032
011000001803218032180321803218032180321803219032180321803218032180321803218032180321903218032180321803218032180321803218032190321803218032180321803218032180321803219032
0110002018032180321d0321b0321b032180321a0321803218032180321d0321b0321b032180321a0321803218032180321d0321b0321b032180321a0321803218032180321d0321b0321b032180321a03218032
010800201f0321f032000001f0321f032000001f0321f0321d0321d032000001d0321d032000001d0321d0321b0321b032000001b0321b032000001b0321b0321a0321a0321b0321a0321a0321b0321a0321a032
011000001f7001f7001f7001f7001d7001d7001d7001d7001b7001b7001b7001b7001a7001a7001a7001a7001f7551f7551f7551f7551d7551d7551d7551d7551b7551b7551b7551b7551a7551a7551a7551a755
011000001302513025140251302513025110251302513025140251302513025110251302513025110251102513025130251402513025130251102513025130251402513025130251102513025130251102511025
0110000013755130551375513055117551105511755110550f7550f0550f7550f0550e7550e0550e7550e05513755130551375513055117551105511755110550f7550f0550f7550f0550e7550e0550e7550e055
011000000715507155071550715509155071550715509155071550715508155071550715507155081550715507155071550715507155091550715507155091550715507155081550715507155071550815507155
011000000c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c1330c1330c1333c6150c133
011000000c0550c055130550c0550c055140550c0550c055110550c0550c055130550c0550c05513055140550c0550c055130550c0550c055140550c0550c055110550c0550c055130550c0550c0551305514055
011000000015500155011550015500155031550015500155011550015500155031550015500155011550015500155001550115500155001550315500155001550115500155001550315500155001550115500155
__music__
00 3f3d3e7c
00 3f3d3e36
00 3f3d3c37
00 3f3d3c35
00 3c3d393b
00 3c3d383b
00 3f33787b
02 3f3d7479
01 3d7e3f79
00 3d3e3f79
00 3d3e3c79
00 3d3e3f79
00 3d373c79
02 3d353c79
03 3d3e3f74
01 3d3e3f34
02 3d3e3f2d
03 3e333a79
03 31324344
01 2e6f3036
00 2e2f3036
00 2e6f3035
02 2e2f3034
01 2a6c6b29
00 2a2c6b29
00 2a2c2b29
00 2a2c2b29
00 2a2b2829
02 2a2b2829
01 65662467
00 65262467
00 25262467
00 25262427
00 25262427
00 25232427
00 25232427
00 25262427
00 25262427
00 65266427
00 65262327
02 24262327
01 21204344
00 21204344
00 21201f44
00 21201f44
00 21202244
00 21202244
00 2120221f
00 2120221f
00 2160221f
00 2160221f
00 21202260
02 2120225f
00 62604344
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002200220022ee22ee22ee22ee0077770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee22ee22ee220022
0000002200220022ee22ee22ee22ee0077770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee22ee22ee220022
00000000220022ee22ee22ee22ee22007777770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee22ee22002200
00000000220022ee22ee22ee22ee22007777770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee22ee22002200
00000000002200220022ee22ee22ee00222222770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee2200000000
00000000002200220022ee22ee22ee00222222770022ee22ee22ee22ee22ee22eeffeeffeeffeeffeeffeeffeeffeeffeeffeeffeeffee22ee22ee2200000000
0000000000000000000000ee22ee2200770000770000000000000000000000000000000000000000000000000000000000eeffeeffee22ee2200220000000000
0000000000000000000000ee22ee2200770000770000000000000000000000000000000000000000000000000000000000eeffeeffee22ee2200220000000000
000000000000000000000000ee22ee00770000770077777700770077007700770077000077007700777777007700007700ffeeffee22ee220022002200000000
000000000000000000000000ee22ee00770000770077777700770077007700770077000077007700777777007700007700ffeeffee22ee220022002200000000
11000000000000000000000000002200770000770077227700777777777700770077770077007700772277007777007700eeffee22ee22002200220000000000
11000000000000000000000000002200770000770077227700777777777700770077770077007700772277007777007700eeffee22ee22002200220000000000
00000000000000000000000000000000220000770077007700772277227700770077227777007700770077007722777700ffeeffee22ee220022000000000000
00000000000000000000000000000000220000770077007700772277227700770077227777007700770077007722777700ffeeffee22ee220022000000000000
00000000000077770000000000000000777777220077007700770077007700770077002277007700770077007700227700eeffee22ee22002200000000000000
00000000000077770000000000000000777777220077007700770077007700770077002277007700770077007700227700eeffee22ee22002200000000000000
00000000000000000000000000000000777722000077777700770077007700770077000077007700777777007700007700ffee22ee2200220000000000000000
00000000000000000000000000000000777722000077777700770077007700770077000077007700777777007700007700ffee22ee2200220000000000000000
cccccccccccccccccccccccccc000000222200000022222200220022002200220022000022002200222222002200002200eeffee220022000000000000000000
cccccccccccccccccccccccccc000000222200000022222200220022002200220022000022002200222222002200002200eeffee220022000000000000000000
000000000000000000000000000000000000000000aaaa0000000000000000000000000000000000000000000000000000ffee22002200000000000000000000
000000000000000000000000000000000000000000aaaa0000000000000000000000000000000000000000000000000000ffee22002200000000000000000000
000000000000000000000000000000000000000000aaaaaaaaaa00002200220022eeffeeffeeffeeffeeffeeffeeffeeffeeffee220000000000000000000000
000000000000000000000000000000000000000000aaaaaaaaaa00002200220022eeffeeffeeffeeffeeffeeffeeffeeffeeffee220000000000000000000000
00777777770000000000000000000000000000000099999999990022002200220022ee22eeffeeffeeffeeffeeffeeffeeffee22000000000000000011000000
00777777770000000000000000000000000000000099999999990022002200220022ee22eeffeeffeeffeeffeeffeeffeeffee22000000000000000011000000
00000000000011000000cccccccccccc0000000000aa000000000000000000000000220022ee22ee22eeffeeffeeffeeffee2200220000000000000000000000
00000000000011000000cccccccccccc0000000000aa000000000000000000000000220022ee22ee22eeffeeffeeffeeffee2200220000000000000000000000
000000000000000000000000000000000000000000aaaaaa000000aa000000aa0022002200220022ee22ee22eeffeeffee220022000000000000000000000000
000000000000000000000000000000000000000000aaaaaa000000aa000000aa0022002200220022ee22ee22eeffeeffee220022000000000000000000000000
000000110000000000000000000000000000000000aa999900000099aa00aa9900002200220022002200220022eeffee22ee220000000000cccccccccccc0000
000000110000000000000000000000000000000000aa999900000099aa00aa9900002200220022002200220022eeffee22ee220000000000cccccccccccc0000
0000000000000000000000000000000000000000009900000000000099aa99000022000000220022002200220022eeffee220022000000000000000000000000
0000000000000000000000000000000000000000009900000000000099aa99000022000000220022002200220022eeffee220022000000000000000000000000
000000000000000000777777777777000000000000aaaaaaaaaa0000aa99aa00000000000000000022002200220022ee22002200000000000000000000000000
000000000000000000777777777777000000000000aaaaaaaaaa0000aa99aa00000000000000000022002200220022ee22002200000000000000000000000000
000000000000000000000000000000000000000000aaaa99999900aa990099aa0000000000000000002200220022002200220000000000000000000000000000
000000000000000000000000000000000000000000aaaa99999900aa990099aa0000000000000000002200220022002200220000000000000000000000000000
000000cccccccccccccccc000000000000000000009999000000009900000099000000000000000000000000000022002200000000cccc000000777777770000
000000cccccccccccccccc000000000000000000009999000000009900000099000000000000000000000000000022002200000000cccc000000777777770000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000
0000000000000000000000000000000000000000ee888888eeee0000000000000000000011000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000ee888888eeee0000000000000000000011000000000000000000000000000000000000000000000000000000
000000000000000000000000000011000000000000ee88888888eeee00000000000000000000000000000000000000cccccccccccccccccccccccccc00000000
000000000000000000000000000011000000000000ee88888888eeee00000000000000000000000000000000000000cccccccccccccccccccccccccc00000000
00000000000000000000000000000000000000000000ee8888888888eeee00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000ee8888888888eeee00000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccccccccccccccccccc66558888888888888888eeeeeeeeeeeeeeeeeeee77dd77000000000000000000000000000000000000000000
00000000cccccccccccccccccccccccccccccccc66558888888888888888eeeeeeeeeeeeeeeeeeee77dd77000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc77777777665566666666668888888888888888888888eeeedd77dd77dd00000000110000000000000000000000000000
cccccccccccccccccccccccccccccccc77777777665566666666668888888888888888888888eeeedd77dd77dd00000000110000000000000000000000000000
cccccccccccccccc77777777777777777777777766666666555555666655668888888888888888ee77dd77dd77dd000000000000000000000000000000000000
cccccccccccccccc77777777777777777777777766666666555555666655668888888888888888ee77dd77dd77dd000000000000000000000000000000000000
cccccccccccccccc77777777777777777777777766556655665555555555665555666666668888888888eeeeeeeeee0000000000777777777700000000000000
cccccccccccccccc77777777777777777777777766556655665555555555665555666666668888888888eeeeeeeeee0000000000777777777700000000000000
cccccccccccccccccccccccccccccccc77777777665555555566666666556688888888888888888888888888888888ee00000000cccccccccccccccccccccc00
cccccccccccccccccccccccccccccccc77777777665555555566666666556688888888888888888888888888888888ee00000000cccccccccccccccccccccc00
00000000cccccccccccccccccccccccccccccccc665588888888888888888888eeee555555550000000000000000000000000000000000000000000000000000
00000000cccccccccccccccccccccccccccccccc665588888888888888888888eeee555555550000000000000000000000000000000000000000000000000000
000011000000000000000000000000000000000000ee888888888888eeee00000000000000000000000000000000000000000000000000000000000000000000
000011000000000000000000000000000000000000ee888888888888eeee00000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000eeeeeeeeeeee000000000000cccccccccc000000110000007777777777777777777777777700000000000000
0000000000000000000000000000000000000000eeeeeeeeeeee000000000000cccccccccc000000110000007777777777777777777777777700000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__meta:title__
dominion ex 2
extar 2019, 2020, 2021
