pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

-- phoenix 0.80
-- 2021 paul hammond
-- debug
--debug_stats=false
version = "0.80"
-- cartridge data
cartdata("phammond_phoenix_80_p8")
-- movement
d_none = 0
d_up = 1
d_right = 2
d_down = 3
d_left = 4
xinc = {[0] = 0, 0, 1, 0, -1}
yinc = {[0] = 0, -1, 0, 1, 0}
-- enums
gs_titles = 0
-- game state
gs_game = 3
tm_normal = 0
-- title mode
tm_scoring = 1
s_playing = 0
-- session state
s_lostlife = 1
s_levelstart = 2
s_levelcomplete = 3
s_gamecomplete = 4
s_gameover = 9
ps_normal = 0
-- player state
ps_dying = 1
bs_spawning = 0
-- bird state
bs_formation = 1
bs_diving = 2
phs_spawning = 0
-- phoenix state
phs_formation = 1
phs_egg = 2
phs_unspawning = 3
phs_hatching = 4
et_bird = 0
-- entity type
et_phoenix = 1
et_bullet = 2
et_bomb = 3
et_mothership = 10
-- sfx and music
sfx_shipexplode = 0
sfx_fire = 1
sfx_explode1 = 2
sfx_bonuslife = 3
sfx_levelcleared = 4
sfx_explode2 = 5
sfx_gameover = 6
sfx_winghit = 7
sfx_shield = 8
sfx_playerspawn = 9
sfx_swoop1 = 10
sfx_swoop2 = 11
sfx_swoop3 = 12
sfx_bird_m = 13
sfx_bird_d = 14
sfx_bird_w = 15
sfx_bird_s = 16
--sfx_bonuslife
music_titles = 0
music_levelintro1 = 56
music_levelintro2 = 40
-- other
hiscore = dget(0)
input = {}
-- titles
title_text = "2021 paul hammond (@paulhamx) \xe2\x97\x86 testing by finn \xe2\x97\x86 many thanks to paul niven (@nivz) for the logo \xe2\x97\x86 use 5 to fire 4 to raise your shields. shields take several seconds to recharge"

function _init()
  -- enable keyboard
  poke(24365, 1)
  -- palette
  poke(0x5f2e, 1)
  --[[
 pal(2,128+14,1)
 pal(3,128+10,1)
 pal(4,128+13,1)
 pal(5,128+1,1)
 pal(9,128+9,1)
 pal(11,138,1)
 --pal(8,136,1)
 pal(15,128+12,1)
 ]]
  --
  --palette_default={[0]=1,142,138,141,129,6,7,8,137,10,138,12,13,14,140}
  palette_default = {[0] = 0, 1, 142, 139, 141, 129, 6, 7, 8, 137, 10, 138, 12, 13, 14, 140}
  pal(palette_default, 1)
  palette_reset = {[0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
  -- initialise
  reset_titles()
  -- hi score
  if hiscore <= 0 then
    hiscore = 50
  end
  -- stars
  srand(14)
  stars = {}
  for i = 1, 100 do
    local fast = rnd(100) < 50
    local s = {x = rnd(128), y = rnd(128), speed = iif(fast, 0.5, 0.33), size = 1, c = iif(fast, 1, 5)}
    add(stars, s)
  end
  srand()
end

function reset_titles()
  flash = false
  state = gs_titles
  titlecounter = -40
  titlecounter2 = 0
  titlemode = tm_normal
  -- new hi score?
  if player and player.score > hiscore then
    hiscore = player.score
    -- save
    dset(0, hiscore)
  end
  -- initialise game so we can draw behind titles
  game_reset()
  -- sfx and music
  sfx(-1)
  music(music_titles)
  -- transition
  transition:start()
end

function _update60()
  -- counters
  flash = (time() * 3) % 2 < 1
  -- input (global just cos)
  input_update(input)
  -- update
  if state == gs_titles then
    -- titles
    update_titles()
  else
    -- game
    game_update()
    if gameover then
      reset_titles()
    end
  end
  -- transition
  transition:update()
  -- quit game?
  if kb("q") then
    gameover = true
  end
end

function _draw()
  if state == gs_titles then
    draw_titles()
  else
    game_draw()
  end
  -- transition
  transition:draw()
end

function update_titles()
  -- game in demo mode
  game_update()
  -- start game?
  if btnp(5) then
    state = gs_game
    game_reset()
  end
  -- counters
  titlecounter = (titlecounter + 1) % 1000
  titlecounter2 = titlecounter2 + (1)
  if btnp(4) then
    if titlemode == tm_scoring then
      titlemode = tm_normal
      titlecounter2 = 0
    else
      titlemode = tm_scoring
      titlecounter2 = 920
    end
  end
  -- switch title modes
  if titlecounter2 == 920 then
    titlemode = tm_scoring
    -- transition
    transition:start()
  elseif titlecounter2 == 1300 then
    titlemode = tm_normal
    titlecounter = -40
    titlecounter2 = 0
    -- reset demo
    game_reset()
    -- transition
    transition:start()
  end
end

function draw_titles()
  if titlemode == tm_normal then
    -- game in background
    game_draw()
  else
    -- scoring
    cls(0)
    -- stars
    stars_draw()
    -- entity scores
    local y = 34
    spr(140, 40, y, 2, 2)
    prints("20-80", 64, y + 5, 8)
    y = y + (18)
    spr(8, 33, y, 2, 2)
    spr(8, 44, y, 2, 2, true, false)
    prints("200", 64, y + 5, 8)
    y = y + (18)
    spr(106, 36, y, 3, 2)
    prints("100-800", 64, y + 5, 8)
    y = y + (18)
    spr(212, 44, y + 4)
    prints("1000-9000", 64, y + 5, 8)
  end
  -- high score
  if titlecounter2 > 60 then
    printc("hi " .. pad0(hiscore, 5) .. "0", 2, 8)
  end
  -- logo
  draw_logo()
  -- message
  if titlemode == tm_normal then
    prints(title_text, 128 - titlecounter, 121, 12)
  end
  -- controls
  if flash then
    printc("5 start", 108, 7, true)
  end
-- version
--if (time()<2) print(version,112,1,7)
end

function draw_logo()
  map(0, 5, 27, 6, 10, 3)
end

-->8
-- game
function game_reset()
  -- initialise
  gameover = false
  level = 0
  lives = 3
  -- demo?
  demo = state == gs_titles
  if demo then
    level = flr(rnd(4))
  end
  -- clear music
  if not demo then
    music(-1)
  end
  -- objects
  player = player_create()
  -- reset level
  game_resetlevel(true)
end

function game_resetlevel(advance)
  -- advance?
  if advance then
    level = level + (1)
    -- level properties
    birdspeedmultiplier = 1
    formationx = 0
    formationy = 0
    formationdir = 1
    formationspeed = 1 / 6
    formationcounter = 0
    mothership = nil
    -- objects
    entities = {}
  end
  levelresolved = 1 + (level - 1) % 5
  round = (level - 1) // 5
  maxformationspeed = 1
  phoenixnearbottom = false
  -- level properties
  countbirds = 0
  countbullets = 0
  countbombs = 0
  countdiving = 0
  counthatched = 0
  nextsfxtime = 0
  gamecompletebonus = 0
  phoenixlevel = levelresolved == 3 or levelresolved == 4
  mothershiplevel = levelresolved == 5
  formationdelaytime = 30
  maxbombs = 3 + min(round, 5)
  maxplayerbullets = iif(levelresolved == 2, 2, 1)
  message = ""
  -- objects
  particles = {}
  player_resetlevel(player)
  -- define formation and palette
  if levelresolved == 1 then
    -- birds 1
    if level > 5 then
      formation = {0, 5, 2, 4, 2, 6, 4, 3, 4, 5, 6, 2, 8, 1, 9, 0, -2, 4, -2, 6, -4, 3, -4, 5, -6, 2, -8, 1, -9, 0}
    else
      formation = {5, 0, 7, 1, 9, 2, 9, 3.5, 7, 4.5, 5, 5.5, 3, 6.5, 0, 6.5, 0, 4.5, -5, 0, -7, 1, -9, 2, -9, 3.5, -7, 4.5, -5, 5.5, -3, 6.5}
    end
    palette = {[10] = 10, [12] = 12, [14] = 14, [15] = 15}
  elseif levelresolved == 2 then
    -- birds 2
    if level > 5 then
      formation = {0, 0, 2, 1, 4, 2, 6, 3, 8, 4, 6, 5, 4, 6, 2, 7, 0, 7, -2, 1, -4, 2, -6, 3, -8, 4, -6, 5, -4, 6, -2, 7}
    else
      formation = {0, 1, 0, 2, 0, 4, 0, 5.5, 2, 0, 2, 3, 4, 2, 6, 1, 8, 2, 9, 4, -2, 0, -2, 3, -4, 2, -6, 1, -8, 2, -9, 4}
    end
    palette = {[10] = 14, [12] = 12, [14] = 3, [15] = 10}
  elseif levelresolved == 3 then
    -- phoenixes 1
    formation = {-6, 0, -4, 1.5, -2, 3, 0, 4.5, 2, 6, 4, 7.5, 6, 9}
    palette = {[10] = 10, [12] = 12, [14] = 14, [15] = 15}
  elseif levelresolved == 4 then
    -- phoenixes 2
    formation = {-6, 0, -6, 3, -6, 6, -6, 9, 6, 1.5, 6, 4.5, 6, 7.5, 6, 10.5}
    palette = {[10] = 10, [12] = 14, [14] = 14, [15] = 15}
  elseif levelresolved == 5 then
    -- mothership (with birds)
    formationdelaytime = 90
    if level > 5 then
      formation = {0, 0, 0, 6.5, 2, 0, 4, 1, 6, 2, 8, 3, 2, 6.5, 4, 6.5, 6, 6.5, -2, 0, -4, 1, -6, 2, -8, 3, -2, 6.5, -4, 6.5, -6, 6.5}
    else
      formation = {0, 0, 2, 0.5, 4, 1, 6, 1.5, 8, 2, -2, 0.5, -4, 1, -6, 1.5, -8, 2}
    end
    palette = {[10] = 14, [12] = 12, [14] = 3, [15] = 10}
  end
  -- add/ reset mothership
  if mothershiplevel and advance then
    mothership = mothership_create()
    add(entities, mothership)
  end
  -- reset formation?
  if not advance then
    -- do not recreate formation
    formationdelaytime = 0
    if phoenixlevel then
      game_formation_reset()
    end
  end
  -- finalise
  if advance and not demo then
    game_setstate(s_levelstart)
  else
    game_setstate(s_playing)
  end
  -- transition
  --if (advance and not demo) transition:start()
  -- sfx
  sfx(-1)
end

function game_formation_create()
  --[[
if false then
local b=bird_create(64,10+6.5*6.5)  
add(entities,b)
b=bird_create(64,10+0*6.5)  
add(entities,b)
return
end
]]
  --
  birdspeedmultiplier = 1
  formationx = 0
  formationdir = 1
  for i = 1, #formation, 2 do
    local fx, fy = formation[i], formation[i + 1]
    local b
    if phoenixlevel then
      b = phoenix_create(65 + fx * 5, -8 + fy * 7)
    else
      b = bird_create(64 + fx * 5, 10 + fy * 6.5)
    end
    add(entities, b)
  end
end

function game_formation_reset()
  --formationy=0
  formationdir = -1
  formationspeed = 0.5
  maxformationspeed = 1
  for e in all(entities) do
    if e.type == et_phoenix then
      if e.state ~= phs_egg then
        entity_setstate(e, phs_unspawning)
      end
    end
  end
end

function game_setstate(s, c)
  gamestate = s
  gstatecount = c or 0
end

function game_update()
  -- initialise
  bombdropped = false
  -- only one bomb can be dropped per cycle
  -- stars
  stars_update()
  -- #########
  -- formation
  -- #########
  if gamestate ~= s_levelstart then
    -- allow for double (or faster anyway) speed
    local loops = 1
    if birdspeedmultiplier == 2 and gstatecount % 2 == 0 then
      loops = 2
    end
    for i = 1, loops do
      -- formation position
      if formationdelaytime == 0 then
        if phoenixlevel then
          -- =============
          -- phoenix level
          -- =============
          formationy = formationy + (formationspeed)
          formationspeed = formationspeed + (formationdir / 20)
          if phoenixnearbottom then
            formationdir = 1
            formationspeed = 1.5
          elseif formationspeed >= maxformationspeed then
            formationdir = -1
          elseif formationspeed <= -1 then
            formationdir = 1
          end
          -- sfx
          if gamestate == s_playing and nextsfxtime <= 0 then
            local n = rnd(10)
            local se = sfx_swoop1
            nextsfxtime = 70
            if n > 8 then
              se = sfx_swoop2
              nextsfxtime = 50
            elseif n > 5 then
              se = sfx_swoop3
              nextsfxtime = 100
            end
            gsfx(se, 1)
          end
          -- gradually drop down
          if gstatecount > 400 and gstatecount % 45 == 1 then
            maxformationspeed = maxformationspeed + (0.1)
            if maxformationspeed >= 2 then
              maxformationspeed = 1
            end
          end
        else
          -- ==========
          -- bird level
          -- ==========
          formationx = formationx + (formationdir * formationspeed)
          -- prevent rounding errors since we must know that each complete formation cycle takes 339 game cycles
          if abs(formationx) < 0.1 and formationdir == 1 then
            --printh("formation return length="..formationcounter)
            formationx = 0
            formationcounter = 0
          else
            -- more of a debugging tool to prove that the formation takes 339 cycles
            formationcounter = formationcounter + (1)
          end
          -- note: these values give an exact formation return cycle of 339 moves
          if formationx <= -14 then
            formationdir = 1
          elseif formationx >= 14 then
            formationdir = -1
          end
          -- start dive?
          if gstatecount % 30 == 25 and rnd(10) < 3 + min(3, round) then
            birds_dive()
          end
        end
      end
      -- entities
      countbirds = 0
      countdiving = 0
      counthatched = 0
      phoenixnearbottom = false
      for e in all(entities) do
        -- allow for double-speed birds
        -- note: actually, slower than double speed
        if i == 1 or e.type == et_bird then
          e:update()
        end
        -- always test bullet hits otherwise when birds are double-speed, they may travel through the birds
        if e.type == et_bullet then
          e:testcollisions()
        end
        -- count/ flags
        if e.type == et_bird then
          countbirds = countbirds + (1)
          if e.state == bs_diving then
            countdiving = countdiving + (1)
          end
        elseif e.type == et_phoenix then
          if e.y > 100 or e.y < -10 then
            phoenixnearbottom = true
          end
          if e.state == phs_formation then
            counthatched = counthatched + (1)
          end
        end
        if not e.active then
          del(entities, e)
          -- counts
          if e.type == et_bullet then
            countbullets = countbullets - (1)
          elseif e.type == et_bomb then
            countbombs = countbombs - (1)
          end
        end
      end
    end
  end
  if gamestate == s_levelstart then
    -- ###########
    -- level start
    -- ###########
    if gstatecount == 1 then
      if levelresolved == 1 then
        -- scroll stars in from top
        for s in all(stars) do
          s.y = s.y - (140)
        end
        if level == 1 then
          message = "player 1"
        end
        -- music
        if round % 2 == 0 then
          music(music_levelintro1)
        else
          music(music_levelintro2)
        end
      elseif levelresolved == 2 then
        -- first wave cleared so start play immediatly
        game_setstate(s_playing)
      end
    elseif gstatecount == 200 or (levelresolved > 1 and gstatecount == 90) then
      game_setstate(s_playing)
    end
  elseif gamestate == s_playing then
    -- #######
    -- playing
    -- #######
    if gstatecount == 1 then
      message = ""
      -- sfx
      gsfx(sfx_playerspawn, 3)
    end
    -- player
    if not demo then
      player_update(player)
    end
    -- respawn birds if all dead on mothership level
    if mothershiplevel and countbirds == 0 and gamecompletebonus == 0 and formationdelaytime <= 0 then
      formationdelaytime = 60
    end
    -- add formation
    if formationdelaytime > 0 then
      formationdelaytime = formationdelaytime - (1)
      if formationdelaytime == 0 then
        game_formation_create()
        gstatecount = 1
      end
    end
    -- double bird speed?
    if (countbirds == 1 or (countbirds < 4 + round and gstatecount > 900)) and levelresolved ~= 5 then
      birdspeedmultiplier = 2
    end
    -- particles
    particles_update()
    -- level cleared?
    if formationdelaytime <= 0 and player.state == ps_normal and #entities == 0 and #particles == 0 then
      game_setstate(s_levelcomplete)
    end
  elseif gamestate == s_levelcomplete then
    -- ##############
    -- level complete
    -- ##############
    if gstatecount == 1 then
    -- sfx
    --sfx(sfx_levelcleared)
    elseif gstatecount == 30 then
      -- next level
      game_resetlevel(true)
    end
  elseif gamestate == s_gamecomplete then
    -- #############
    -- game complete
    -- #############
    if gstatecount == 1 then
      message = gamecompletebonus .. "0"
      -- bonus
      player_scoreadd(gamecompletebonus)
    -- sfx
    --sfx(sfx_levelcleared)
    elseif gstatecount == 120 then
      -- next level
      game_resetlevel(true)
    end
  elseif gamestate == s_lostlife then
    -- #########
    -- lost life
    -- #########
    if gstatecount >= 15 and not phoenixnearbottom then
      lives = lives - (1)
      if lives == 0 then
        game_setstate(s_gameover)
      else
        game_resetlevel(false)
      end
    end
  elseif gamestate == s_gameover then
    -- #########
    -- game over
    -- #########
    if gstatecount == 1 then
      message = "game over"
      -- sfx
      sfx(sfx_gameover)
    elseif gstatecount == 260 then
      gameover = true
    end
  end
  -- other
  player.displayscore = move(player.displayscore, player.score, 2)
  -- counters
  if nextsfxtime > 0 then
    nextsfxtime = nextsfxtime - (1)
  end
  gstatecount = gstatecount + (1)
end

function game_draw()
  cls(0)
  -- stars
  stars_draw()
  -- offset in demo mode to accomodate logo
  if demo then
    camera(0, -26)
  end
  if gamestate == s_levelstart then
    -- ###########
    -- level start
    -- ###########
    if phoenixlevel then
      -- asterisk fill as per arcade version
      local n = 1 + flr(gstatecount / 2)
      if n < 20 then
        clip(64 - 4 * n, 67 - 6 * n, 8 * n, 12 * n)
      end
      for y = 1, 22 do
        print("********************************", 0, 2 + y * 6, 12)
      end
      clip()
      if n > 20 then
        n = n - (20)
        rectfill(64 - n * 4, 3 + 64 - n * 6, 63 + n * 4, 3 + 64 + n * 6, 0)
      end
    end
  elseif gamestate == s_playing or gamestate == s_lostlife then
    -- #######
    -- playing
    -- #######
    -- entities
    pal(palette)
    for e in all(entities) do
      e:draw()
    end
    pal(palette_reset)
    -- player
    if not demo then
      player_draw(player)
    end
    -- particles
    pal(palette)
    particles_draw()
    pal(palette_reset)
  end
  -- score panel
  if not demo then
    game_draw_scorepanel()
  end
  -- message
  if message then
    printc(message, 52, 8)
  end
  pal(4, 4)
  camera()
end

function game_draw_scorepanel()
  pal(1, 0)
  -- score
  prints("p1", 1, 1, 12)
  if flash and player.score > hiscore then
  else
    prints(pad0(flr(player.displayscore), 5) .. "0", 10, 1, 8)
  end
  -- hi score
  prints("hi", 46, 1, 12)
  prints(pad0(hiscore, 5) .. "0", 56, 1, 8)
  -- level
  spr(2, 84, 0)
  prints(level, 93, 1, 9)
  -- shield available
  --if player.shieldtime<=-240 and flash then
  -- spr(3,100,0)
  --end
  -- lives
  for i = 1, lives do
    spr(1, 122 - i * 3, 0)
  end
  pal(1, 1)
end

-- player
function player_create()
  local s = {score = 0, displayscore = 0, frames = {202, 204, 206, 204}, speed = 0.75,}
  player_resetlevel(s)
  return s
end

function player_resetlevel(s)
  -- reset
  s.x = 64
  s.y = 119
  s.moved = false
  s.shieldtime = -210
  entity_setstate(s, ps_normal)
end

function player_update(s)
  -- dying?
  if s.state == ps_dying then
    s.statecount = s.statecount + (1)
    if s.statecount >= 120 and countdiving == 0 then
      game_setstate(s_lostlife)
    end
    return
  end
  -- speed
  local speed = s.speed
  if player.shieldtime > 0 then
    speed = speed * (0.33)
  end
  -- move
  local oldx = s.x
  if input.left then
    s.x = s.x - (speed)
  elseif input.right then
    s.x = s.x + (speed)
  end
  s.x = mid(5, s.x, 123)
  s.moved = s.x ~= oldx
  -- fire
  if input.fire2hit and countbullets < maxplayerbullets and player.shieldtime <= 0 then
    bullet_add(s)
    -- sfx
    sfx(sfx_fire, 3)
  end
  -- raise shield
  if input.fire1hit and s.shieldtime == -240 then
    s.shieldtime = 45
    -- sfx
    sfx(sfx_shield, 3)
  end
  -- hit rectangle (centred)
  if s.shieldtime > 0 then
    s.hitrect = rectc(s.x, s.y, 8, 8)
  else
    s.hitrect = rectc(s.x, s.y, 6, 6)
  end
  -- collision checks
  for e in all(entities) do
    if e.type == et_bomb or e.type == et_bird or e.type == et_phoenix then
      if rectsoverlap(e.hitrect, s.hitrect) then
        if s.shieldtime > 0 then
          -- destroy
          e:destroy()
          -- low score to discourage use of shiled as a weapon
          if e.type ~= et_bomb then
            player_scoreadd(2)
          end
        else
          -- destroy player
          entity_setstate(s, ps_dying)
        end
      end
    end
    -- mothership collision (i.e., too low)
    if mothershiplevel and mothership.y >= 109 then
      -- destroy player
      entity_setstate(s, ps_dying)
    end
    if s.state == ps_dying then
      -- particles
      particles_add(player.x, player.y, 18, 8, true, false)
      -- sfx
      sfx(sfx_shipexplode, 3)
      break
    end
  end
  -- counters
  s.statecount = s.statecount + (1)
  if s.shieldtime > -240 then
    s.shieldtime = s.shieldtime - (1)
  end
end

function player_draw(s)
  if s.state == ps_dying then
    return
  end
  -- ship
  local f = s.frames[1 + flr(s.x / 4) % #s.frames]
  if not s.moved then
    f = 202
  end
  spr(f, s.x - 7, s.y - 7, 2, 2)
  -- shield
  if s.shieldtime > 0 then
    local r = iif(s.shieldtime % 10 < 5, 9, 8)
    circ(s.x, s.y + 1, r - 2, 12)
  end
  -- spawning
  if s.state == ps_normal and s.statecount < 25 then
    --fillp(0b0101101001011010.1)
    local r = 50 - s.statecount * 2
    circfill(s.x, s.y, r, 8)
  --fillp()
  --circfill(s.x,s.y,r-2,8)
  end
--if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11) 
end

function player_scoreadd(v)
  local oldscore = player.score
  player.score = player.score + (v)
  if (player.score >= 1000 and oldscore < 1000) or (player.score >= 2000 and oldscore < 2000) then
    lives = lives + (1)
    -- sfx
    sfx(sfx_bonuslife)
  end
end

-- particles
function particles_add(x, y, count, colour, large, downward)
  for i = 1, count do
    if #particles > 100 then
      return
    end
    add(particles, {x = x - 4 + rnd(8), y = y - 4 + rnd(8), colour = colour, ttl = 80, dx = 0.5 - rnd(1), dy = -rnd(1) * iif(downward, 0.25, 1), r = iif(large, 2 + rnd(2), 1.5)})
  --add(particles,{x=x,y=y,colour=colour,ttl=60,dx=0.5-rnd(1),dy=-rnd(1),r=iif(large,1.5,0.5)})
  end
end

function particles_draw()
  for p in all(particles) do
    circfill(p.x, p.y, p.r, p.colour)
  end
end

function particles_update()
  for p in all(particles) do
    p.x = p.x + (p.dx)
    p.y = p.y + (p.dy)
    p.dy = p.dy + (0.03)
    --0.05
    p.r = p.r - (0.04)
    p.ttl = p.ttl - (1)
    if p.ttl <= 0 or p.r <= 0 then
      del(particles, p)
    end
  end
end

-- stars
function stars_draw()
  for s in all(stars) do
    if s.spr then
      spr(s.spr, s.x, s.y, s.size, s.size)
    else
      pset(s.x, s.y, s.c)
    end
  end
end

function stars_update()
  for s in all(stars) do
    s.y = s.y + (s.speed)
    if s.y > 148 then
      s.y = s.y - (168)
      if s.spr then
        s.x = rnd(112)
      end
    end
  end
end

-- entity
function entity_setstate(s, st, c)
  s.state = st
  s.statecount = c or 0
end

-- bird
function bird_create(x, y)
  local s = {type = et_bird, active = true, fx = x, fy = y, update = bird_update, draw = bird_draw, reset = bird_reset, destroy = bird_destroy}
  -- reset
  bird_reset(s)
  return s
end

function bird_reset(s)
  s.x = s.fx
  s.y = s.fy
  s.hitwidth = 1
  s.frame = -1
  s.framesize = 1
  s.rotation = 0
  s.soaring = false
  --s.divepattern=nil
  --s.divepatternpos=0
  --s.diveinstuction=nil
  --s.divepatterncounter=0
  entity_setstate(s, bs_spawning)
end

function bird_update(s)
  local walkingframe = 1 + flr(gstatecount / 10) % #anim_bird_formation
  local soaringframe = 1 + flr(s.statecount / 4) % #anim_bird_soaring
  if s.state == bs_spawning then
    -- ========
    -- spawning
    -- ========
    local i = 1 + flr((s.statecount / 2))
    hitwidth = 3
    if i > #anim_bird_spawning then
      entity_setstate(s, bs_formation)
    else
      -- animation
      s.frame = anim_bird_spawning[i]
    end
  end
  if s.state == bs_formation then
    -- =========
    -- formation
    -- =========
    s.x = s.fx + formationx
    s.y = s.fy
    -- animation
    s.framesize = 2
    s.frame = anim_bird_formation[walkingframe]
    s.rotation = 0
    -- hit width is based on frame
    s.hitwidth = bird_formation_hitwidths[walkingframe]
  elseif s.state == bs_diving then
    -- ======
    -- diving
    -- ======
    if s.statecount == 0 then
      s.hitwidth = 6
      s.framesize = 2
      -- reset for new dive
      s.divepatternpos = 0
      s.diveinstuction = nil
      s.divepatterncounter = 0
      s.rotation = 0
      s.divedebugcounter = 0
      s.divedebugstartx = s.x
      s.divedebugstarty = s.y
      s.divedebugpoints = {}
    --printh("dive start="..s.divedebugstartx..","..s.divedebugstarty)
    end
    -- initialise
    s.soaring = false
    -- next instruction?
    while (true) do
      if s.divepatterncounter == 0 then
        s.divepatternpos = s.divepatternpos + (1)
        if s.divepatternpos > #s.divepattern then
          -- back into formation
          entity_setstate(s, bs_formation)
          -- debug
          --printh("dive end="..s.x..","..s.y)
          --printh("difference="..(s.divedebugstartx-s.x)..","..(s.divedebugstarty-s.y))
          --printh("dive cycles="..s.divedebugcounter)
          break
        else
          -- next instruction
          local instruction = s.divepattern[s.divepatternpos]
          --printh("instruction="..instruction)
          -- parse
          local arr = split(instruction)
          s.diveinstuction = arr[1]
          s.divepatterncounter = tonum(arr[2])
          if #arr > 2 then
            s.diveparam1 = tonum(arr[3])
          else
            s.diveparam1 = nil
          end
          -- immediate action?
          if s.diveinstuction == "a" then
            -- -----------------------------
            -- angle (45 degree increments)
            -- -----------------------------
            s.rotation = s.divepatterncounter
            s.divepatterncounter = 0
          elseif s.diveinstuction == "r" then
            -- -----------------------------
            -- rotate (45 degree increments)
            -- -----------------------------
            s.rotation = flr((s.rotation + s.divepatterncounter) % 8)
            s.divepatterncounter = 0
          end
          -- sfx
          if nextsfxtime <= 0 then
            if s.diveinstuction == "m" then
              gsfx(sfx_bird_m, 2)
            elseif s.diveinstuction == "s" then
              gsfx(sfx_bird_s, 2)
            elseif s.diveinstuction == "d" then
              gsfx(sfx_bird_d, 2)
            elseif s.diveinstuction == "w" then
              gsfx(sfx_bird_w, 2)
            end
            nextsfxtime = 10
          end
        end
      end
      if s.divepatterncounter ~= 0 then
        break
      end
    end
    local rotation = 1 + flr(s.rotation % 8)
    -- handle dive instruction
    if s.state == bs_diving then
      -- soaring (worth extra points to shoot)
      s.soaring = s.diveinstuction == "s"
      if s.diveinstuction == "d" then
        -- ----
        -- drop
        -- ----
        local speed = 1
        s.y = s.y + (speed * sgn(s.divepatterncounter))
        -- animation
        s.frame = 32
        -- counter
        s.divepatterncounter = move(s.divepatterncounter, 0, speed)
        -- rotate?
        if s.divepatterncounter == 0 then
          -- finished so reset rotation
          s.rotation = 0
        else
          s.rotation = s.rotation + (0.25 * sgn(s.divepatterncounter))
        end
      elseif s.diveinstuction == "m" then
        -- ------------------------------------
        -- move (in current rotation direction)
        -- ------------------------------------
        dx = -sin(s.rotation / 8)
        dy = -cos(s.rotation / 8)
        local speed = 1
        s.x = s.x + (dx * speed)
        s.y = s.y + (dy * speed)
        -- animation
        s.frame = 32
        -- counter
        --printh("speed="..speed)
        --printh("s.divepatterncounter="..s.divepatterncounter)
        s.divepatterncounter = move(s.divepatterncounter, 0, speed)
        -- rotate?
        if s.diveparam1 then
          s.rotation = s.rotation + (s.diveparam1)
        end
      elseif s.diveinstuction == "s" then
        -- ----
        -- soar
        -- ----
        local speed = 1
        s.x = s.x + (speed * sgn(s.divepatterncounter))
        s.y = s.y - (speed)
        -- animation
        s.frame = anim_bird_soaring[soaringframe]
        -- set rotation in case we need to switch moves (and to assist with animation)
        if s.divepatterncounter < 0 then
          s.rotation = 7
        else
          s.rotation = 1
        end
        -- counter
        s.divepatterncounter = move(s.divepatterncounter, 0, speed)
      elseif s.diveinstuction == "w" then
        -- -----------------------------
        -- walking (as per in formation)
        -- -----------------------------
        s.x = s.x + (sgn(s.divepatterncounter) * formationspeed)
        -- animation
        s.frame = anim_bird_formation[walkingframe]
        -- counter
        s.divepatterncounter = move(s.divepatterncounter, 0, formationspeed)
      end
    end
    -- debug
    s.divedebugcounter = s.divedebugcounter + (1)
    add(s.divedebugpoints, {s.x, s.y})
  end
  -- drop bomb
  -- note: by using gstatecount, the same bird is more likely to drop multiple bombs, like in the arcade version
  local n = iif(s.state == bs_diving, 2, 20)
  if not demo and s.state ~= bs_spawning and gstatecount % 30 < 10 and rnd(n) < 1 then
    bomb_add(s, 2)
  end
  -- hit rectangle (centred)
  s.hitrect = rectc(s.x, s.y, s.hitwidth, 8)
  -- counters
  s.statecount = s.statecount + (1)
end

function bird_draw(s)
  local f = s.frame
  local flipx, flipy = false, false
  local rotation = 1 + flr((s.rotation + 0.5) % 8)
  -- rotation
  if f < 16 then
    -- soaring
    flipx = s.rotation == 1
  elseif f == 32 or f == 33 then
    -- rotated dive (1 or 2-frames)
    f = ({32, 36, 40, 36, 32, 36, 40, 36})[rotation]
    if s.frame == 33 then
      f = f + (2)
    end
    flipx = ({false, false, false, false, false, true, true, true})[rotation]
    flipy = ({false, false, false, true, true, true, false, false})[rotation]
  end
  spr(f, s.x - 4 * s.framesize, s.y - 4 * s.framesize, s.framesize, s.framesize, flipx, flipy)
-- debug
--[[
 if false then
  if s.divedebugpoints then
   for i in all(s.divedebugpoints) do
    pset(i[1],i[2],8)
   end
  end
  rect(s.fx+formationx-3,s.fy-3,s.fx+formationx+3,s.fy+3,9) 
  --if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11) 
 end
 ]]
--
end

-- birds
function birds_dive()
  if countdiving > level or player.state ~= ps_normal then
    return
  end
  -- initialise
  local added = 0
  local maxdivecount = 4 + min(5, round)
  -- get dive pattern (different set defined for each of the 3 bird levels)
  local patternset = dive_patterns[levelresolved]
  local pattern = patternset[1 + flr(rnd(#patternset))]
  -- dive
  for e in all(entities) do
    if countdiving >= maxdivecount then
      break
    elseif e.type == et_bird and e.state == bs_formation and (added == 0 or rnd(10) < 1) then
      -- dive
      entity_setstate(e, bs_diving)
      e.divepattern = pattern
      added = added + (1)
      countdiving = countdiving + (1)
      -- perfect circle (just for the hell of it)?
      if rnd(20) < 1 then
        e.divepattern = {"a,2", "m,339,0.02359"}
        break
      end
    end
  end
end

function bird_destroy(s)
  s.active = false
  -- particles
  particles_add(s.x, s.y, 12, 8, false)
  -- sfx
  sfx(sfx_explode1, 2)
end

-- phoenix
function phoenix_create(x, y)
  local s = {type = et_phoenix, index = #entities, active = true, fx = x, fy = y, update = phoenix_update, draw = phoenix_draw, reset = phoenix_reset, destroy = phoenix_destroy}
  -- reset
  phoenix_reset(s)
  return s
end

function phoenix_reset(s)
  s.x = s.fx
  s.y = s.fy
  s.hitwidth = 1
  s.speed = 0.1
  s.xdir = 1
  s.leftwingspawntime = 0
  s.rightwingspawntime = 0
  s.frame = -1
  entity_setstate(s, phs_spawning)
  -- ensure spawning and movement isn't quite in sync
  s.statecount = s.index * 10
  s.maxspeed = 1.5
--4+s.index/20 
end

function phoenix_update(s)
  local speed = s.speed
  if s.state == phs_spawning then
    -- ========
    -- spawning
    -- ========
    local i = 1 + flr((s.statecount / 20))
    if i > #anim_phoenix_spawning then
      entity_setstate(s, phs_egg)
    else
      -- animation
      s.spawnwidth = 1
      s.frame = anim_phoenix_spawning[i]
      -- hit rect is based on frame
      s.hitwidth = min(i / 4, 4)
    end
  elseif s.state == phs_egg then
    -- ===
    -- egg
    -- ===
    s.hitwidth = 4
    if s.statecount >= 90 and gamestate == s_playing then
      entity_setstate(s, phs_hatching)
    end
    -- animation
    s.spawnwidth = 1
    s.frame = 70 + flr((s.statecount / 2) % 2)
  elseif s.state == phs_hatching then
    -- ========
    -- hatching
    -- ========
    s.hitwidth = 4
    local i = 1 + flr((s.statecount / 10))
    if i > #anim_phoenix_hatching then
      entity_setstate(s, phs_formation)
    else
      -- slow down
      speed = speed * (0.15)
      -- animation
      s.spawnwidth = 2
      s.frame = anim_phoenix_hatching[i]
    end
  elseif s.state == phs_unspawning then
    -- ==========
    -- unspawning
    -- ==========
    s.hitwidth = 4
    local i = 1 + flr((s.statecount / 10))
    if i > #anim_phoenix_hatching then
      entity_setstate(s, phs_egg)
    else
      -- animation
      s.spawnwidth = 2
      s.frame = anim_phoenix_unspawning[i]
    end
  end
  if s.state == phs_formation then
    -- =========
    -- formation
    -- =========
    s.hitwidth = 24
    -- return to egg form?
    if s.leftwingspawntime == 0 and s.rightwingspawntime == 0 and s.statecount % 240 == 239 and rnd(1) < 0.5 then
      entity_setstate(s, phs_unspawning)
    end
    -- random change of direction
    if rnd(100) < 1 + round * 3 then
      s.xdir = s.xdir * (-1)
    end
    -- drop bomb
    -- note: by using gstatecount, the same bird is more likely to drop multiple bombs, like in the arcade version
    if gstatecount % 30 < 10 and rnd(2) < 1 then
      bomb_add(s, 2)
    end
    -- animation
    if s.statecount < 10 then
      s.frame = 100
    else
      s.frame = anim_phoenix_flapping[1 + flr((s.statecount / 9) % #anim_phoenix_flapping)]
    end
  end
  -- always moving side-to-side
  s.x = s.x + (speed)
  s.speed = s.speed + (s.xdir / 20)
  s.speed = mid(-s.maxspeed, s.speed, s.maxspeed)
  if s.x >= 110 - s.maxspeed * 10 then
    s.xdir = -1
  elseif s.x <= 16 + s.maxspeed * 10 then
    s.xdir = 1
  end
  -- y position is always fixed relative to start position
  s.y = s.fy + formationy
  while (s.y > 128) do
    s.y = s.y - (140)
  end
  -- hit rectangle
  if s.state == phs_formation then
    -- left aligned
    local sx, w = s.x - 10, 20
    if s.leftwingspawntime > 0 then
      sx = sx + (8)
      w = w - (8)
    end
    if s.rightwingspawntime > 0 then
      w = w - (8)
    end
    s.hitrect = rectl(sx, s.y - 4, w, 8)
  else
    -- centred
    s.hitrect = rectc(s.x, s.y, s.hitwidth, 8)
  end
  -- counters
  s.statecount = s.statecount + (1)
  if s.leftwingspawntime > 0 then
    s.leftwingspawntime = s.leftwingspawntime - (1)
  end
  if s.rightwingspawntime > 0 then
    s.rightwingspawntime = s.rightwingspawntime - (1)
  end
end

function phoenix_draw(s)
  if s.state == phs_formation then
    -- always draw in 3 parts
    local x, y = s.x - 11, s.y - 7
    local f, flipx
    -- left wing
    if s.leftwingspawntime == 0 then
      f = s.frame
    elseif s.leftwingspawntime < 60 then
      f = 96 + flr(s.leftwingspawntime / 20)
    else
      f = -1
    end
    if f ~= -1 then
      spr(f, x, y, 1, 2)
    end
    x = x + (8)
    -- body
    spr(s.frame + 1, x, y, 1, 2)
    x = x + (8)
    -- right wing
    if s.rightwingspawntime == 0 then
      f = s.frame + 2
    elseif s.rightwingspawntime < 60 then
      f = 96 + flr(s.rightwingspawntime / 20)
      flipx = true
    else
      f = -1
    end
    if f ~= -1 then
      spr(f, x, y, 1, 2, flipx, false)
    end
  elseif s.spawnwidth == 2 then
    spr(s.frame, s.x - 7, s.y - 3, 2, 1)
  else
    spr(s.frame, s.x - 3, s.y - 3)
  end
--if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11)
end

function phoenix_destroy(s)
  s.active = false
  -- particles
  particles_add(s.x, s.y, 8, 8, false)
  particles_add(s.x, s.y, 8, 9, false)
  -- sfx
  sfx(sfx_explode1)
end

-- bullet
function bullet_add(player)
  local s = {type = et_bullet, active = true, x = player.x, y = player.y - 1, speed = 5, collisionradius = 1, draw = bullet_draw, update = bullet_update, testcollisions = bullet_testcollisions}
  add(entities, s)
  -- count
  countbullets = countbullets + (1)
end

function bullet_update(s)
  s.y = s.y - (s.speed)
  -- hit rectangle (centred)
  s.hitrect = rectc(s.x, s.y, 2, 4)
  -- finished?
  if s.y < -12 then
    s.active = false
  end
end

function bullet_draw(s)
  line(s.x, s.y - 1, s.x, s.y + 1, 7)
--if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11) 
end

function bullet_testcollisions(s)
  -- entity collisions
  for e in all(entities) do
    if not e.hitrect then
    -- entity not yet fully initialised
    elseif e.type == et_bird then
      -- ====
      -- bird
      -- ====
      if rectsoverlap(s.hitrect, e.hitrect) then
        e:destroy()
        s.active = false
        -- calculate score based on distance from player
        local d = distance(e, player)
        local sc = mid(2, flr((110 - d) / 10), 8)
        if e.soaring then
          sc = 20
        end
        -- fireball
        if e.soaring then
          fireball_add(e, sc .. "0")
        end
        -- add score
        player_scoreadd(sc)
        break
      end
    elseif e.type == et_phoenix then
      -- =======
      -- phoenix
      -- =======
      if rectsoverlap(s.hitrect, e.hitrect) then
        -- calculate score
        local d = distance(e, player)
        local sc = mid(5, flr((110 - d) / 7), 10)
        -- body or wing hit?
        if s.x <= e.x - 4 then
          -- left wing
          if e.leftwingspawntime == 0 then
            e.leftwingspawntime = 180
            -- score
            player_scoreadd(sc)
            -- particles
            particles_add(e.x - 8, e.y, 8, 12, false)
            particles_add(e.x - 8, e.y, 4, 8, false)
            -- sfx
            sfx(sfx_winghit)
          end
        elseif s.x >= e.x + 4 then
          -- right wing
          if e.rightwingspawntime == 0 then
            e.rightwingspawntime = 180
            -- score
            player_scoreadd(sc)
            -- particles
            particles_add(e.x + 8, e.y, 8, 12, false)
            particles_add(e.x + 8, e.y, 4, 8, false)
            -- sfx
            sfx(sfx_winghit)
          end
        else
          -- body
          e:destroy()
          s.active = false
          -- fireball?
          if e.leftwingspawntime <= 0 and e.rightwingspawntime <= 0 then
            sc = sc * (8)
            fireball_add(e, sc .. "0")
          else
            sc = sc * (2)
          end
          -- score
          player_scoreadd(sc)
        end
        break
      end
    elseif e.type == et_mothership then
      -- ==========
      -- mothership
      -- ==========
      if rectsoverlap(s.hitrect, e.hitrect) then
        if e:hit(s) then
          s.active = false
        end
      end
    end
  end
end

-- fireball
function fireball_add(e, text)
  local s = {type = et_fireball, active = true, x = e.x, y = e.y, dist = 0, text = text, update = fireball_update, draw = fireball_draw}
  add(entities, s)
end

function fireball_update(s)
  s.dist = s.dist + (3)
  if s.dist > 130 then
    s.active = false
  end
  particles_add(s.x - s.dist + 8, s.y, 1, 8)
  particles_add(s.x - s.dist + 8, s.y, 1, 9)
  --particles_add(s.x-s.dist,s.y,2,7)
  particles_add(s.x + s.dist - 8, s.y, 1, 8)
  particles_add(s.x + s.dist - 8, s.y, 1, 9)
--particles_add(s.x+s.dist,s.y,2,7) 
end

function fireball_draw(s)
  -- text
  if s.text then
    print(s.text, s.x - #s.text * 2, s.y - 2, 8)
  end
  spr(4, s.x - s.dist, s.y - 7, 2, 2)
  spr(6, s.x + s.dist, s.y - 7, 2, 2)
end

-- mothership
function mothership_create()
  local s = {type = et_mothership, active = true, x = 64, y = -24, h = 48, alienactive = true, hitwidth = 104, columns = {}, belt = {}, beltpos = 0, statecount = 0, update = mothership_update, draw = mothership_draw, hit = mothership_hit}
  -- create destructible columns (the orange bottom of the ship)
  for x = 1, 26 do
    local c = {x = 8 + x * 4, y = 8, w = 4}
    c.h = ({2, 4, 7, 9, 11, 12, 13, 14, 15, 15, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 12, 11, 9, 7, 4, 2})[x]
    c.starth = c.h
    add(s.columns, c)
  end
  -- create centre belt
  for x = 0, 27 do
    local b = {active = true, frame = 192, x = 8 + x * 4, y = 2, w = 4, h = 4, hits = 0}
    if x % 2 < 1 then
      b.frame = 208
    end
    add(s.belt, b)
  end
  return s
end

function mothership_update(s)
  -- drop?
  if s.alienactive then
    if gamestate == s_playing then
      if s.statecount < 68 then
        s.y = s.y + (1)
      elseif s.statecount % 100 == 99 then
        s.y = s.y + (1)
      end
    elseif gamestate == s_lostlife then
      -- move up a bit if too low
      if s.y > 70 then
        s.y = s.y - (1)
      end
    end
  end
  -- centre belt
  if s.statecount % 3 == 0 then
    for b in all(s.belt) do
      b.x = b.x + (1)
      if b.x > 112 then
        b.x = b.x - (108)
      end
    end
  end
  -- alien drop bomb
  if s.alienactive and s.statecount > 80 and s.statecount % 30 < 10 and rnd(8) < 1 then
    bomb_add(s, 3)
  end
  -- alien destroyed
  if not s.alienactive then
    if s.statecount == 90 then
      game_setstate(s_gamecomplete)
    end
  end
  -- hit rectangles (centred)
  s.hitrect = rectc(s.x, s.y, s.hitwidth, s.h)
  s.alienhitrect = rectc(s.x, s.y - 2, 8, 12)
  -- counters
  s.statecount = s.statecount + (1)
end

function mothership_draw(s)
  -- top of ship
  map(0, 0, 20, s.y - 20, 14, 4)
  spr(231, 54, s.y - 16)
  spr(231, 65, s.y - 16)
  local f = flr(s.statecount / 10) % 6
  spr(232 + f, 54, s.y - 22)
  spr(232 + f, 66, s.y - 22, 1, 1, true, false)
  -- alien
  if s.alienactive then
    --spr(231+flr((s.statecount/10))%6,60,s.y-9,1,2)
    spr(195 + f, 60, s.y - 13, 1, 2)
  --spr(231,59,s.y-9,1,2)
  end
  -- destructible columns
  for c in all(s.columns) do
    if c.h > 0 then
      rectfill(c.x, s.y + c.y, c.x + c.w - 1, s.y + c.y + c.h - 1, 9)
      if c.h ~= c.starth then
        pset(c.x + 1, s.y + c.y + c.h - 1, 0)
        pset(c.x + 3, s.y + c.y + c.h - 1, 0)
      end
    end
  end
  -- centre belt
  clip(12, 0, 104, 128)
  for b in all(s.belt) do
    if b.active then
      spr(b.frame, b.x, s.y + b.y)
    end
  end
  clip()
--if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11) 
--if (s.alienhitrect) rect(s.alienhitrect.x,s.alienhitrect.y,s.alienhitrect.x+s.alienhitrect.w,s.alienhitrect.y+s.alienhitrect.h,11) 
-- finalise
--camera()
end

function mothership_hit(s, bullet)
  -- destructible columns
  for c in all(s.columns) do
    if c.h > 0 and bullet.x >= c.x and bullet.x < c.x + c.w and bullet.y <= s.y + c.y + c.h then
      c.h = c.h - (1)
      -- particles
      particles_add(bullet.x, bullet.y, 2, 9, false, true)
      -- sfx
      return true
    end
  end
  -- centre belt
  for b in all(s.belt) do
    if b.active and bullet.x >= b.x and bullet.x < b.x + b.w and bullet.y <= s.y + b.y + b.h then
      b.hits = b.hits + (1)
      if b.hits == 2 then
        b.active = false
      else
        b.frame = b.frame + (1)
      end
      -- particles
      particles_add(bullet.x, bullet.y, 2, 4, false, true)
      -- sfx
      return true
    end
  end
  -- alien
  if s.alienactive and rectsoverlap(s.alienhitrect, bullet.hitrect) then
    s.alienactive = false
    s.statecount = 0
    -- particles
    particles_add(s.x, s.y, 40, 4, true, false)
    -- calculate bonus
    gamecompletebonus = mid(1, mothership.y * 9, 900)
    -- sfx
    sfx(sfx_shipexplode)
    -- destroy all other entities
    for e in all(entities) do
      if e.type ~= et_mothership then
        e.active = false
        particles_add(e.x, e.y, 8, 7, false, false)
      end
    end
  end
  -- not hit
  return false
end

-- bomb
function bomb_add(entity, offsety)
  -- can we drop a bomb?
  if bombdropped or gamecompletebonus > 0 or gstatecount % 2 == 0 or gstatecount < 60 or gamestate ~= s_playing or player.state ~= ps_normal or countbombs >= maxbombs then
    return
  end
  local s = {type = et_bomb, active = true, x = entity.x, y = entity.y - 2 + (offsety or 0), speed = 1.6,
  --75,--1.5,
  draw = bomb_draw, update = bomb_update, destroy = bomb_destroy}
  add(entities, s)
  -- count
  countbombs = countbombs + (1)
  -- prevent multiple bombs being dropped per cycle
  bombdropped = true
end

function bomb_update(s)
  s.y = s.y + (s.speed)
  -- hit rectangle (centred)
  s.hitrect = rectc(s.x, s.y, 1, 3)
  -- finished?
  if s.y > 130 then
    s.active = false
  end
end

function bomb_draw(s)
  line(s.x, s.y - 1, s.x, s.y + 1, 7)
--if (s.hitrect) rect(s.hitrect.x,s.hitrect.y,s.hitrect.x+s.hitrect.w,s.hitrect.y+s.hitrect.h,11) 
end

function bomb_destroy(s)
  s.active = false
  particles_add(s.x, s.y, 4, 7, false, false)
end

-->8
-- helper
function gsfx(s, c)
  if not demo then
    sfx(s, c)
  end
end

function rectl(x, y, w, h)
  return {x = x, y = y, w = w, h = h}
end

function rectc(x, y, w, h)
  return {x = x - w / 2, y = y - h / 2, w = w, h = h}
end

function pad0(n, l)
  local s = "0000000000" .. n
  return sub(s, #s - l + 1)
end

function lerp(a, b, t)
  return a * (1 - t) + b * t
end

function kb(k)
  return stat(30) and stat(31) == k
end

function lerp(a, b, t)
  return a * (1 - t) + b * t
end

function iif(c, t, f)
  if c then
    return t
  else
    return f
  end
end

function move(c, d, s)
  if c < d then
    return min(c + s, d)
  end
  if c > d then
    return max(c - s, d)
  end
  return c
end

function printc(s, y, c, shad, sc)
  -- detect wide characters
  local offx = 0
  for i = 1, #s do
    if ord(sub(s, i, i)) > 134 then
      offx = offx + (2)
    end
  end
  local x = 64 - offx - #s * 2
  if shad then
    prints(s, x, y, c, sc)
  else
    print(s, x, y, c)
  end
end

function prints(s, x, y, c, sc)
  for y1 = -1, 1 do
    for x1 = -1, 1 do
      print(s, x + x1, y + y1, sc or 0)
    end
  end
  print(s, x, y, c)
end

function rectsoverlap(e1, e2, e1offsetx, e1offsety)
  if e1offsetx == nil then
    e1offsetx = 0
  end
  if e1offsety == nil then
    e1offsety = 0
  end
  return (e1.x + e1offsetx) < e2.x + e2.w and e2.x < e1.x + e1.w + e1offsetx and (e1.y + e1offsety) < e2.y + e2.h and e2.y < e1.y + e1.h + e1offsety
end

function distance(e1, e2)
  local dx = e1.x - e2.x
  local dy = e1.y - e2.y
  return sqrt(dx ^ 2 + dy ^ 2)
end

-- input
function input_update(s)
  s.moved = false
  local olddir = s.dir
  s.up = btn(2)
  s.down = btn(3)
  s.left = btn(0)
  s.right = btn(1)
  s.fire1 = btn(4)
  s.fire2 = btn(5)
  s.fire1hit = s.fire1 and not s.fire1old
  s.fire2hit = s.fire2 and not s.fire2old
  if s.up then
    s.dir = d_up
  elseif s.right then
    s.dir = d_right
  elseif s.down then
    s.dir = d_down
  elseif s.left then
    s.dir = d_left
  else
    s.dir = d_none
  end
  s.moved = s.dir ~= olddir
  s.fire1old = s.fire1
  s.fire2old = s.fire2
  -- fire 2 held down n/a if moving
  if s.fire2downtime == nil then
    s.fire2downtime = 0
  end
  if s.fire2 and s.dir == d_none then
    s.fire2downtime = s.fire2downtime + (1)
  else
    s.fire2downtime = 0
  end
end

-->8
-- effects
-- transition
transition = {start = function(self, colour)
  self.value = -8
end, draw = function(self)
  if self.value < 128 then
    fillp(23130.5)
    rectfill(0, self.value, 128, 128, 0)
    fillp()
    rectfill(0, self.value + 8, 128, 128, 0)
  end
end, update = function(self)
  if self.value < 128 then
    self.value = self.value + (3)
  end
end}
-->8
-- data
-- animation
anim_bird_spawning = {142, 143, 158, 159}
anim_bird_formation = {136, 138, 140, 138}
anim_bird_soaring = {8, 10, 12, 14, 12, 10}
bird_formation_hitwidths = {7, 9, 11, 9}
anim_phoenix_spawning = {64, 64, 64, 64, 65, 65, 66, 66, 67, 67, 68, 68, 68, 68, 68}
anim_phoenix_unspawning = {82, 80, 78, 76, 74}
anim_phoenix_hatching = {74, 76, 78, 80, 82}
anim_phoenix_flapping = {100, 103, 106, 109, 106, 103}
-- dive patterns (instruction, count)
--  * walk
--    * w,14          (walk 14px to the right, use a negative number for left)
--  * drop
--    * d,10          (drop 10 while spinning)
--  * move
--    * m,10          (move 10px in current rotation direction)
--    * m,10,0.1      (move 10px in current rotation direction while rotating 0.1 each cycle)
--  * rotate
--    * r,2           (rotate without moving where number is the number of 45 degree intervals)
--  * angle
--    * a,2           (like rotate but not relative to the current angle)
--  * soar
--    * s,-20         (soar 20 pixels up to the left)
--
-- note: each must return to start position (within 1px) after 339 cycles although anything from 300 is okay if soaring back and y position is pretty close
dive_patterns = {}
-- level 1
dive_patterns[1] = {
-- zig-zag
{"a,0", "m,20,0.2", "d,16", "a,5", "m,17", "a,3", "m,17", "a,5", "m,17", "a,3", "m,17", "m,20,-0.15", "w,-12", "d,8", "w,11", "s,-46", "s,20"},
-- loopy
{"a,2", "m,2", "a,7", "m,15,-0.025", "m,20,-0.2", "m,20,0.2", "m,60,-0.1", "m,32,-0.2", "m,40,-0.12", "m,40,0.15", "d,54", "a,2", "m,1", "s,20", "s,-17", "s,19"}, {"a,2", "m,12", "a,7", "m,120,-0.05", "m,40,0.2", "m,30,0.1", "m,20,0.01", "m,15,0.1", "m,15,0.2", "s,15", "s,-15", "s,12", "s,-24", "w,-3.4"},
-- weave along the bottom
{"d,20", "a,2", "m,80,0.1", "m,20,0.2", "m,20,-0.2", "m,20", "m,50,0.1", "m,-30,-0.075", "m,-45,0.125", "s,20", "s,-17", "s,18"},
-- harder patterns
{"a,1", "m,20,0.2", "a,4", "m,40,-0.2", "d,38", "a,3", "m,30,-0.1", "m,30,-0.2", "m,30,0.2", "m,40,-0.1", "m,20,-0.075", "w,-4", "s,20", "s,-20", "s,13", "s,-13"}, {"a,6", "m,10,-0.1", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "m,40,0.2", "d,13", "a,4", "m,50,-0.1", "s,-20", "m,40,0.15", "a,5", "m,20", "m,20,0.1", "s,-13", "s,40"}}
-- level 2
dive_patterns[2] = {{"a,0", "m,20,0.2", "d,16", "a,5", "m,17", "a,3", "m,17", "a,5", "m,17", "a,3", "m,17", "m,20,-0.15", "w,-12", "d,8", "w,11", "s,-46", "s,20"}, {"d,20", "a,2", "m,80,0.1", "m,20,0.2", "m,20,-0.2", "m,20", "m,50,0.1", "m,-30,-0.075", "m,-45,0.125", "s,20", "s,-17", "s,18"}, {"a,2", "m,90,0.0275", "m,60,0.15", "m,100,0.05", "m,40,0.25", "a,6", "m,-14", "s,-27"}, {"a,6", "m,90,-0.0275", "m,60,-0.15", "m,100,-0.05", "m,40,-0.25", "a,2", "m,14", "s,27"}, {"a,6", "m,20", "m,60,-0.075", "d,30", "w,10", "a,2", "m,50,-0.05", "w,8", "d,8", "w,-4", "s,-30", "s,6"}, {"a,2", "m,20", "m,60,0.075", "d,30", "w,-10", "a,6", "m,50,0.05", "w,-8", "d,8", "w,4", "s,30", "s,-6"}, {"a,1", "m,20,0.2", "a,4", "m,40,-0.2", "d,38", "a,3", "m,30,-0.1", "m,30,-0.2", "m,30,0.2", "m,40,-0.1", "m,20,-0.075", "w,-4", "s,20", "s,-20", "s,13", "s,-13"}, {"a,6", "m,10,-0.1", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "m,40,0.2", "d,13", "a,4", "m,50,-0.1", "s,-20", "m,40,0.15", "a,5", "m,20", "m,20,0.1", "s,-13", "s,40"}, {"a,6", "m,8,-0.1", "d,20", "a,4", "m,20,0.1", "m,30,-0.1", "m,20,0.3", "s,20", "a,2", "m,40,0.04", "m,30,0.1", "s,-20", "s,20", "m,40,0.125", "d,10", "s,-12", "s,12", "s,-12", "s,16", "s,-10"},}
-- level 5
dive_patterns[5] = {{"a,2", "m,90,0.0275", "m,60,0.15", "m,100,0.05", "m,40,0.25", "a,6", "m,-14", "s,-27"}, {"a,6", "m,10,-0.1", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "a,3", "m,12", "a,5", "m,12", "m,40,0.2", "d,13", "a,4", "m,50,-0.1", "s,-20", "m,40,0.15", "a,5", "m,20", "m,20,0.1", "s,-13", "s,40"}, {"a,6", "m,8,-0.1", "d,20", "a,4", "m,20,0.1", "m,30,-0.1", "m,20,0.3", "s,20", "a,2", "m,40,0.04", "m,30,0.1", "s,-20", "s,20", "m,40,0.125", "d,10", "s,-12", "s,12", "s,-12", "s,16", "s,-10"},
-- double length (680 cycles)
{"a,2", "m,12,0.1", "m,20,0.2", "m,60,-0.075", "m,80,0.055", "m,40,0.1", "s,20", "a,2", "m,40,0.05", "m,30,-0.08", "s,10", "s,-40", "a,6", "m,50,-0.05", "m,30,0.1", "s,-20", "a,0", "m,20,0.2", "m,60,0.08", "a,2", "m,41", "s,30", "s,-10", "s,14", "m,53,0.135"},}

__gfx__
00000000001010000001110000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001818100001bb71001bbb100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001888881001bbb7101b444b10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700018888810001bb7101b404b1000000999999990000009999999900000000000000aaa00000000000aaaa0000000000000000000000000000000000000
0007700001888100000117101b444b10000999998888000000008888999990000000000aa00000000000f0aaa00000000000f00aaa0000000000f00000000000
00700700001810000000171001bbb1000009998888000000000000888899900000000f0aa0000000000feeaa00000000000feeaaaaa00000000feeaa00000000
00000000000100000000010000111000009998888000000000000008888999000000feea000000000000eee0000000000000eeea00a000000000eeeaaa000000
000000000000000000000000000000000099988888800000000008888889990000000eee00000000000aaee0000000000000aee0000000000000aee00a000000
0000000000000000000000000000000000999888888000000000088888899900000aaaee0000000000aaa00e00000000000aaa0e000000000000aa0e00000000
0000000000000000000000000000000000999888800000000000000888899900000aa000e000000000aa000000000000000aa0000000000000000a0000000000
000000000000000000000000000000000009998888000000000000888899900000a000000000000000a0000000000000000aa0000000000000000aa000000000
000000000000000000000000000000000009999988880000000088889999900000a000000000000000a00000000000000000aa00000000000000000000000000
000000000000000000000000000000000000099999999000000999999990000000a0000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000a00000000000000a000000000000000000000000000000000000000000000000000000000000000000000000
0000000f0f0000000000000f0f0000000000000a0f000000000000a00f000000000000000000000000000aaaaa00000000000000000000000000000000000000
000000a0e0a0000000000a00e00a0000000000a0eef0000000000a00eef0000000000aaaaa0000000000000aa000000000000000000000000000000000000000
000000aeeea0000000000aaeeeaa000000000a0eee0a00000000a00eee00a0000000000ee0f000000000000ee0f0000000000000000000000000000000000000
000000aeeea0000000000aaeeeaa0000000000eee0a00000000000eee00a0000000000eeee000000000000eeee00000000000000000000000000000000000000
000000a0e0a0000000000a00e00a00000000000e0a0000000000000e00a000000000000ee0f000000000000ee0f0000000000000000000000000000000000000
000000a000a0000000000a00000a000000000000a0000000000000000a00000000000aaaaa0000000000000aa000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaa00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000010000000000000000000000000000000000000000000000000000000000000000000cc00000000000000cc00000000000000cc0000000
00000000000c0000000c0000000aa000000aa000000000000077700000ccc00000aaa00000000000000000cccc000000000000cccc000000000000cccc000000
000c000000c7c00001c7c10000aaaa0000aaaa0000000000071717000c8c8c000acaca000000000000000c8cc8c000000000cc8cc8cc0000000ccc8cc8ccc000
00000000000c0000000c0000000aa00000aaaa0000000000077777000ccccc000aaaaa000000000000000cccccc000000000cccccccc000000cccccccccccc00
00000000000000000001000000000000000aa000000000000077700000ccc00000aaa00000000000000000cccc0000000000c0cccc0c000000c0c0cccc0c0c00
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc00000000000000cc00000000000000cc0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000cc00000000000000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000cccc000000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc8cc8ccc0000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccccccccccc00000ccc8cc8ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccc0cccc0ccc0000cccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c000cc000c0c00cccc00cc00cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000c0c0c000000c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000cccc000000000000000000000cc00000000000000000000000000000000000000000000000000000000000
0000000c0000000c0000000c0000000000000000cccccccc00000000000000ccc0cccc0ccc00000000000cc0000cc0000cc00000000000000000000000000000
000000cc000000cc000000cc00000000000000cccc8cc8cccc00000000000cccccccccccccc00000000cccccc0cccc0cccccc000000ccccc000cc000ccccc000
00000ccc00000ccc000000cc00000000000000cccccccccccc0000000000cccccc8cc8cccccc000000cccccccc8cc8cccccccc00ccccccccc08cc80ccccccccc
0000ccc000000cc0000000000000000000000cccc09cc90cccc00000000ccc0c00c11c00c0ccc0000ccc0c00ccc11ccc00c0ccc0ccccccccccc11ccccccccccc
0000c00000000000000000000000000000000cc0c090090c0cc00000000c0000009cc9000000c0000c00000000c11c00000000c0c0c0c000ccc11ccc000c0c0c
0000000000000000000000000000000000000c000090090000c00000000c0000090000900000c00000000000009cc900000000000000000000c11c0000000000
0000000000000000000000000000000000000cc0000000000cc0000000000000090000900000000000000000090000900000000000000000099cc99000000000
0000000000000000000000000000000000000c000000000000c00000000000000000000000000000000000009000000900000000000000009000000900000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000eee000
00000000000000000000000000000000000000000000000000000000000000000000a0f0f0a000000000a0f0f0a00000000aa0f0f0aa000000000000000e0000
00000000000000000000000000000000000000000000000000000000000000000000aa0e0aa00000000aaa0e0aaa000000aaaa0e0aaaa0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000aaeeeaa00000000aa0eee0aa000000aa0aeeea0aa0000000000000000000
77777777777777770000000000000000000000000000000000000000000000000000aaeeeaa00000000aa0eee0aa000000a000e0e000a0000000000000000000
7bbbbbbbbbbbbbb700000000000000000000000000000000000000000000000000000a0e0a0000000000a0e0e0a0000000a00e000e00a0000000000000000000
7bbbbbbbbbbbbbb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000a000a0e0a00
7bb7777777777bb70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aeeea000aeeea00
7bb7000000007bb700000000000000000000000000000000000000007777000000000000000000000000000000000000000000000000000000eee0000aeeea00
7bb7007777077bb700000000000000000000000000000000000000007bb70000000000000000000000000000000000000000000000000000000e00000a0e0a00
7bb7007bb77bbbb700000000000000000000000000000000000000007bb700000000000000000000000000000000000000000000000000000000000000f0f000
7bb700777bbbb7770000000000000000000000000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000
7bb7777bbbb777000700000000000000000000000000000000000070000007770007770007770000000000000000000000000000000000000000000000000000
7bb77bbbb77700077707777777777707777777777707777000007770777707b77007770077b70000000000000000000000000000000000000000000000000000
7bbbbbb777000777b707bbbbbbbbb707bbbbbbbbb707bb7000777b707bb707bb770777077bb70000000000000000000000000000000000000000000000000000
7bbbb777b70777bbb707bbbbbbbbb707bbbbbbbbb707bb70777bbb707bb707bbb7707077bbb70000000000000000000000000000000000000000000000000000
7bb7777bb777bbbbb707bb77777bb707bb77777bb707bb777bbbbb707bb7077bbb77777bbb770000000000000000000000000000000000000000000000000000
7bb7007bb7bbbbbbb707bb70007bb707bb70077bb707bb7bbbbbbb707bb70077bbb777bbb7700000000000000000000000000000000000000000000000000000
7bb7007bbbbbb77bb707bb70007bb707bb7077bbb707bbbbbb77bb707bb700077bbb7bbb77000000000000000000000000000000000000000000000000000000
73b70073b3b77773b7073b70007b37073b777b3770073b3b77773b7073b70000773b3b3770000000000000000000000000000000000000000000000000000000
7b37007b3777007b3707b3700073b707b377b3770007b3777007b3707b37000077b3b3b770000000000000000000000000000000000000000000000000000000
73370073370000733707337000733707333337700007337000073370733700077333733377000000000000000000000000000000000000000000000000000000
73370073370000733707337000733707333337000007337000073370733700773337773337700000000000000000000000000000000000000000000000000000
73370073370000733707337777733707337777777707337000073370733707733377077333770000000000000000000000000000000000000000000000000000
73370073370000733707333333333707333333333707337000073370733707333770007733370000000000000000000000000000000000000000000000000000
73370073370000733707333333333707333333333707337000073370733707337700000773370000000000000000000000000000000000000000000000000000
77770077770000777707777777777707777777777707777000077770777707377000000077370000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007770000000007770000000070000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400000400000000000000000000000000000000000000000000000000000000000000000000000000080000000000000008000000000000000800000000
00444400000004000000000000000000000000000000000000000000000000000000000000000000000000888000000000000088800000000000008880000000
00000000000000000000000000000000000000000400004000400400000000000000000000000000000780898087000000007889887000000000078987000000
000000000000000000000000000000000000000000400400000440004400004400000000000000000007888a888700000000788a887000000000078a87000000
00000000000000000000000000000000440000440040040000044000004004004400004400000000000788888887000000007888887000000000078887000000
00000000000000000000000044000044004004000044440000444400004444000040040000000000000000898000000000000089800000000000008980000000
004444000044440000000000004444000044440004dccd40044cc44004dccd4000444400000000000007088a880700000000788a887000000000078a87000000
0040400000404000000000000c4444c004c44c4000444400004444000044440004c44c4000000000000788888887000000007888887000000000078887000000
00404000000000000000000000444400004444000009900000099000000990000044440000000000000780c2c0870000000070c2c0700000000007c2c7000000
00444400000004000000000000099000000990009090090909900990909009090009900000000000000000000000000000000000000000000000000000000000
00000000000000000000000000900900909009099090090990900909909009099090090900000000000000000000000000000000000000000000000000000000
00000000000000000000000099000099090000900900009009000090090000900900009000000000000000000000000000000000000000000000000000000000
00000bbbbbbbbbbbbbb0000000000000000000000000000000b44b00000000000000000000000000000000000000000000000000000000000000000000000000
0000bbbbbbbbbbbbbbbb000000000000000000000000000000b44b00000000000000000000000000000000000000000000000000000000000000000000000000
0000bbbbbbbbbbbbbbbb0000000000bbbbbbbbbbbb000000bbb44bbb090909090000099900000999000090990009090900090909000090990000000000000000
0000bbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbb0000bbb44bbb09b9b9b9000009990000099900009b990009b9b90009b9b900009b990000000000000000
0bbbbbbbbbbbbbbbbbbbbbb00bbbbbbbbbbbbbbbbbbbbbb000000000090909090000099900000999000090990009090900090909000090990000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbb000000000000000000b44b0000000000000000000bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbb000000000000000000b44b000000000000000000bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbbbbbbbbbbbb00b44b000000000000000000bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbbbbbbbbbbbb00b44b000000000000000000bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbb0000bbbbbb00b44b000bbbbbbbbbbbbbb0bbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbb0000bbbbbb00b44b00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbb0000bbbbbb00b44b00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
bbbbbb0000bbbbbbbbbbbb0000bbbbbb00b44b00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000
__map__
0000000000f400000000000000000000151c1c1c1c1c1c1c1c1c1c1c1c1c1c16c2c3cccdc0c145464344c8c9c4c5cecfc6c7cacb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000f5e4f2e6f3e4f600000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1ad2d3dcddd0d155565354d8d9d4d5dedfd6d7dadb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f5f7e1e1f000f1e1e1f8f60000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091000000000097ba00000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a1a2a3a4a5a6a7a8a9000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b1b2b3b4b5b6b7b8b9000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000c00191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000005c191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c000c000c000d000d000d000000005d191e1e1e1e1e1e1e1e1e1e1e1e1e1e1a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
63646566676867686566636400000000171b1b1b1b1b1b1b1b1b1b1b574c4718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7374757677787778757673740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4344454647484748454643440000000000000000000000003030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5354555657585758555653540000000000000000000000003030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
262728292a2b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
363738393a3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202123
20207c64642d2d245e3073202120207c685e202068236864202020732021687c685e2068782378682024682420202073202323202023687c68642d2d2d68782378682023232368202020732023242023687c685e2068782378680000000000000000000000000000000000000000000000000000000000000000000000642d20
20407868784020232323685e732023687c2323242020682020407868784063685e207373687c2323232420682020407868784020682d2d6864642d687c6124682020407868784020685e5e207c612368302040786878402068640000000000000000000000000000000000000000000000000000000000000000000000687840
206863684021237c63206820202026682020206863684021237c237c2123686864642d2d686821237c2168682020202d632d2020206868217c612368686320233030236320686861237c616868632d2061202d636868617c23230000000000000000000000000000000000000000000000000000000000000000000000686863
2d2061242461202d636868237c68685e21215e68687c367c23236868632d20212323202d63686823237c347c337c61236868632d632d63686861237c2168685e5e6868217c2123686830202020266330686821237c237c735e5e0000000000000000000000000000000000000000000000000000000000000000000000682323
73732373732323682020207c685e2368202368232068232024232024232020682020207c682026632023202023206823206823202023202020682020207c612363232320682320202320202363682020207c6323202020242320000000000000000000000000000000000000000000000000000000000000000000000023687c
2024232020202423202023686823202023232020785e687c232363232024232068232020232020232020236320687c232020202423202023206823202023632320202324202020687c6323202423206823202423202068232020000000000000000000000000000000000000000000000000000000000000000000000020687c
202023202423206823202023636820202324202320202320687c202320202320686863202420206820202023632023687c5e682121212020687c626262626240407363407c405e202020305e63207363407c4063682340232340402368405e207363407c4063685e736840234023234040237363407c40202323406863206873
68232023203023642d2d2d407c40242020206820202024736873232320232040235e24407c40636820202068736873232020232020235e30407c40682020206820202068736873232024232620235e23407c406820202068202020687340232320202323202363202423407c406862782340407340632023202363202323407c
406820646440642d23202320202420202023407c406863202420206863202323202363232323407c406820206840784040406840404023682320202320202024232020407c406820206840202020406840202023686178234023202420407c406820206840202020406840242023685e2020232340407c406820246840203020
406840612340402323234061407c6820302023235e636464647c6861235e202323685e5e7c6861235e202323682023402340234023402340237c6861235e202323682024202420242024202420247c6823232423235e202323682378237823782378237823787c68612320242020302020232368237823782378237823782378
__sfx__
0305000011670116701167011670116701267012670116701167012670126601166011660116601066010660116601166011650106500e6500d6300b630096300863006630046200362003620016100060000600
1902000027372293722d3622f362323523235231342303421e33623336223361f3361f326223261f3161e316003050030518305193051a3051a3051b305193050030500305023050130500305003050430501305
180300001735218372193621b3621c3621f362213622235224346263362632628326293162b3162c3162e3162e3162f3162d3162c3162a3160030600306003060030601306023060030600306003060430601306
d50800000c5720e5220c5720e5220c5720e5220c5720e5220c5620e5220c5520e5220c5420e5220c5320e51218552185151854218515185321851518522185150c5220c5150c5220c5150c7220c7150c7120c715
210a0000180520c032180220c012180520c032180220c0120c052180320c022180120c052180320c022180121c052100121c052100121c052100121c052100121805518055180551805518055180551805518055
0500002f640256601e6701a67014670116700e6700a660076500665007650076600a6500a640076400463003620026100161001610016000060000600006000060001600026000060000600007000470001700
451500000e0520d0510c0510b0510a051090510805107051060510505104051030410203101021000110700005000030000100000000000000200000000020000b0000c000030001b00019000000001500011000
0200001b643116630a673066730067300673006730066300653006530065300663006530064300643006330062300613006130061301603185020c502006030060301603026030060300603007030470301703
1d0400001055011550155501755010550115501555017550105501155015550175501055011550155501755010550115501555017550105501155015550175501050011500155001750010500115001550017500
7b0400001d5363a53637536325362c5362853625536215361c53619536175361452612526115260f5260d5260b5160a516055160351603516005160c5060b5060a50608506065060450602506005060050600506
a90700001c7511b761197711877115771147711476113761107510f7510e7410e7410d74109741067310473103721007110070134701187012f701007013670118701347013770137701347012d7010070100701
690600001755018561185711857118571175711656116561155511455113541115410f5410c5410953106531025210151101501355011950130501015013750119501355013850138501355012e5010150101501
c90b00001d550185611457111571105710e5710d5610b5610b5510a551095410754106541055410453103531015210051103501375011b5013250103501395011b501375013a5013a50137501305010350103501
010a1000245622555226542255322452224512245222353222542235522456223552215422253223522245120a502085020750205502045020350202502015020c50209502075020550204502015020050200502
01060b00300552d0552a0452904525045220351d0351a02515035120151101513005150051600517005190051c0051d0051f005210052300525005280052a0052c0052d005300053500537005380053b0053c005
910f080011555105550f5451054511535105350f525105152b505285052b505285052950526505295052650521505215052150521505215052150521505215052050520505205052150521505225052250521505
070400000d52311523155231a5231d53321533255432a5432d56331563375633b5733e573105000f5000f50010500115001350015500195001e50022500265002b5002e500285031d5031d503205032050324503
c9140000210550c0451c0351d015210450c0351c0251d015210450c0351c0251d015210350c0251c0251d0152b0552304524035280152b0452303524025280152b0452303524025280152b035230252402528015
010a00000c4500c4500c4500c450004500045000450004500c4010c4010c4010c401184011840118401184010540105401074010740109401094010a4010a4010c4010c4010a4010a40109401094010740107401
010a00000c5000c5000c5000c500185001850018500185000a5000a5000a5000a5000c5000c5000c5000c500055000550005500055000c5000c5000c5000c5000e5000e5000e5000e5001c5001c5001c5001c500
311818002a7702a7222a7702a7222a7702a7222a7702a72228770287222677026722267702672225770257222377023722237702372226770267222a7702a7220e7000e7000e7000e7001d700117001d70011700
311818002f7702f7502f7402f7302f7202f7122f7702f7202d7702d7202b7702b7222a7702a7502a7202a722287702872228770287222a7702a7222b7702b7220e7000e7000e7000e7001d700117001d70011700
311818002a7702a7102b7702b7102a7702a7102e7702e7102a7702a7102b7702b7102a7702a7102b7702b7102a7702a7102877028710267702671025770257101a700267001a700267001d700297001d70029700
31181800257702571025770257102577025710257702571026770267102577025710237702371026770267102a7702a7102f7702f7302f7202f7101f7002b7001c700287001c700287001f7002b7001f7002b700
911818001745017440174401743017420174101e4501e4401e4301e4201e4101e4101a4501a4301a4401a4201a4301a4201e4501e4401e4301e4201e4101e410214001d4001a4001d400214001d4001a4001d400
911818001745017430174501a4401e440234301744017430174201742017410174101f4501f4301f4501f4301c4501c4201c4501c4401c4301c4201c4101c410184001f4001c4001f400184001f4001c4001f400
911818001e4501e4401e4301e4201e4101e4101e4501e4401e4301e4201e4101e4101a4501a4401a4301a4201a4101a4101745017440174301742017410174101d4001d4001d4001d4001d4001d4001d4001d400
911818001945019440194301942019410194101f4501f4401f4301f4201a4501a42017450174201e4401e4201a4401a4201744017430174201741017410174101f4001f4001f4001f4001f4001f4001f4001f400
310c18002170021700287702873227770277322877028732277702773228770287322377023732267702673224770247322177021730217222171221712217122270022700227002270022700227002270022700
190c18001c7001c700207002070023700237002377023730237222371224700247001c7701c73220770207322377023732247702473024722247121f7001f7001f7001f7001f7001f7001a7001a7001870018700
190c18001c7701c732287702873227770277322877028732277702773228770287322377023732267702673224770247322177021730217222171221700217002270022700227002270026700267002470024700
190c18001c7001c700207002070023700237002377023730237222372223712237121c7701c732247702473223770237322177021730217222172221712217121f7001f7001f7001f7001a7001a7001870018700
190c18001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001d7001f7001f7000977009732107701073215770157321f7001f7001f7001f7001f7001f7001f7001f700
190c180018770187321c7701c7322177021732047700473210770107321477014730147221472214712147121a700197000977009732107701073215770157321a70013700147001370016700137001770011700
190c180024700287002b7003070024700287002b70030700187001c7001f70024700187001c7001f7002470022700247000975009732107501073215750157322270024700277002270022700247002770022700
210c0000187461c7461f74624746187461c7461f736247260c7461074613736187360c7261072613716187161a7461d7461f746237461a7461d7461f736237261a5461d5462b5362f5362652629526375163b516
190c0000247522471227750287500474328712247422471227740287500474328712267420e723277422771220752207322072220712187521873218722187152274022741227312273120031200222002220012
190c00001a3351a3151a3351a315193351931519335193151a3351a3351a3251a3151b3351b3351b3251b3151a335193251a335193251a3351b3251a335193251a33513325143351332516335133251732511315
010a00002971229712297122971229712297122971229712297122971229712297122971229712297122971229712297122971229712297122971229712297122971229712297122971229712297122971229712
010a00002b7122a7112b7112b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122b7122671226712267122671226712267122671226712
110c1800104501042209450094220c4500c422104401042209440094220c4400c422104301042209430094220c4300c422104201041209420094120c4200c41210402284002b4002b40030400304003040030400
110c1800114501142209450094220c4500c422114401142209440094220c4400c422114301142209430094220c4300c422114201141209420094120c4200c41228400284002b4002b40030400304003040030400
110c180011450114220b4500b4220e4500e42211440114220b4400b4220e4400e42211430114220b4300b4220e4300e42211420114120b4200b4120e4200e41228400284002b4002b40030400304003040030400
110c1800104501042209450094220c4500c422104401042209440094220c4400c4220e4300e42207430074220b4300b4220e4200e41207420074120b4200b41228400284002b4002b40030400304003040030400
190c1800245750c5751c57521575185751c575245650c5651c55521555185451c545245550c5551c54521545185351c535245450c5451c53521535185251c5251f5001f5001f5001f50018500185001350013500
190c18001a5750e57511575155750e575115751a5650e56511555155550e545115451a5550e55511545155450e535115351a5450e54511535155350e525115251f5001f5001f5001f50018500185001350013500
190c1800235751a5751d575215751a5751d575235651a5651d555215551a5451d545235551a5551d545215451a5351d535235451a5451d535215351a5251d5251f5001f5001f5001f50018500185001350013500
190c18001c57510575155751857510575155751c565105651555518555105451554523555175550e54513545175350e53523545175450e53513535175250e5251f5001f5001f5001f50018500185001350013500
1d0c18000446204452044520444109431094420945209462094720947209462094620945209452094420944209432094320942209422094120941209412094120040200402004020040200402004020040200402
1d0c1800054620545205452054410b4310b4420b4520b4620b4720b4720b4620b4620b4520b4520b4420b4420b4320b4320b4220b4220b4120b4120b4120b4120000000000000000000000000000000000000000
2d0c18000546205452054520544104431044420445204462044720447204462044620445204452044420444204432044320442204422044120441204412044121c4020c5000c5000c5000c5000c5000c5000c500
2d0c18000b4620b4520b4520b44109431094420945209462094720947209462094610546105452054520544207432074420745207462074720747207462074621750017500175001750017500175001750017500
2d0c18002d5522d5622d5422d5322856228552285422853228532285222d5622d5222f5622f5522f5422f532305623055230542305322f5622f5322d5622d5321650216502165021650216502165021650216502
2d0c0000325523256232542325322f5622f5522f5422f5422f5322f5212e5612e5412f5612f5522f5422f5322f5212d5412b53129531285212652124511235121550015500155001550015500155001550015500
2d0c180028362283422936229342263622634228362283422436224342263622634223362233422436224342213622134223362233421f3621f34221362213421130011300153001530018300183001c3001c300
2d0c1800283522836228352283422d3622d3522d3422d34228362283422d3622d3422f3622f3522f3422f33230362303613235134351353413533235322353122930029300293002930028300283002830028300
2d0c1800243522435224352243522335223352233522335221352213521f3521f3521c3521c3521c3521c3511a351183511735115351133511135110351103522930029300293002930028300283002830028300
011600002173221732217222172221712217121f7321f7321f7321f7321f7221f7221f7221f7221f7121f7121f7121f7121f7121f7121f7121f7121f7121f7121d7321d7221d7221d7121c7321d7221c7221c712
0116000018745187351872518725187351872518715187150c0250c0250c0150c0150c0150c0150c0150c01518705187051870518705187051870518705187051870518705187051870518705187051870518705
__music__
01 282c5844
00 292d5944
00 2a2e7044
00 2b2f7144
00 282c3044
00 292d3144
00 2a2e3244
00 2b2f3344
00 282c3044
00 292d3144
00 2a2e3244
00 2b2f3344
00 282c7034
00 292d7135
00 2a2e7236
00 2b2f7337
00 282c3034
00 292d3135
00 2a2e3236
00 2b2f3338
00 282c3044
00 292d3144
00 2a2e3244
00 2b2f3344
00 286c7044
00 296d7144
00 2a6e7244
02 2b6f7344
00 41424344
00 41424344
00 41424344
00 41424344
00 4c4f4344
00 4d504344
00 4c4f4344
00 4d504344
00 4c4f4344
00 4d504344
00 4c4f4344
00 4d504344
01 1c204344
00 1d214344
00 1e224344
04 1f214344
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 5456585c
00 41424344
00 41424344
01 14185a44
00 15195b44
00 161a4344
04 171b4344
00 41424344
00 41424344
00 41424344
00 44454344
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008080888000008880888088008880888088800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008080080000008080800008008000808080800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008880080000008080888008008880808080800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000008080080000008080008008000080808080800000000000000000000000000000000000000000000000
00000000000000000000000000077777777777777770008080888000008880888088808880888088800000000000000000000000000000000000000000000000
0000000000000000000000000007qqqqqqqqqqqqqq70000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007qqqqqqqqqqqqqq70000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007qq7777777777qq70000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000007qq7000000007qq70000000000000000000000000000000000000000777700000000000000000000000000000000000000000
0000000000000000000000000007qq7007777077qq700000000000000000000000000000000000000007qq700000000000000000000000000000000000000000
0000000000000000000000000007qq7007qq77qqqq700000000000000000000000000000000000000007qq700000000000000000000000000000000000000000
0000000000000000000000000007qq700777qqqq7770000000000000000000000000000000000000000777700000000700000000000000000000000000000000
0000000000000000000000000007qq7777qqqq777000700000000000000000000000000000000000070000007770007770007770000000000000000000000000
0000000000000000000000000007qq77qqqq77700077707777777777707777777777707777000007770777707q77007770077q70000000000000000000000000
0000000000000000000000000007qqqqqq777000777q707qqqqqqqqq707qqqqqqqqq707qq7000777q707qq707qq770777077qq70000000000000000000000000
0000000000000000000000000007qqqq777q70777qqq707qqqqqqqqq707qqqqqqqqq707qq70777qqq707qq707qqq7707077qqq70000000000000000000000000
0000000000000000000000000007qq7777qq777qqqqq707qq77777qq707qq77777qq707qq777qqqqq707qq7077qqq77777qqq770000000000000000000000000
0000000000000000000000000007qq7007qq7qqqqqqq707qq70007qq707qq70077qq707qq7qqqqqqq707qq70077qqq777qqq7700000000000000000000000000
0000000000000000000000000007qq7007qqqqqq77qq707qq70007qq707qq7077qqq707qqqqqq77qq707qq700077qqq7qqq77000000000000000000000000000
0000000000000000000000000007rq7007rqrq7777rq707rq70007qr707rq777qr77007rqrq7777rq707rq7000077rqrqr770000000000000000000000000000
0000000000000000000000000007qr7007qr777007qr707qr70007rq707qr77qr770007qr777007qr707qr7000077qrqrq770000000000000000000000000000
0000000000000000000000000007rr7007rr700007rr707rr70007rr707rrrrr7700007rr700007rr707rr700077rrr7rrr77000000000000000000000000000
0000000000000000000000000007rr7007rr700007rr707rr70007rr707rrrrr7000007rr700007rr707rr70077rrr777rrr7700000000000000000000000000
0000000000000000000000000007rr7007rr700007rr707rr77777rr707rr7777777707rr700007rr707rr7077rrr77077rrr770000000000000000000000000
0000000000000000000000000007rr7007rr700007rr707rrrrrrrrr707rrrrrrrrr707rr700007rr707rr707rrr7700077rrr70000000000000000000000000
0000000000000000000000000007rr7007rr700007rr707rrrrrrrrr707rrrrrrrrr707rr700007rr707rr707rr770000077rr70000000000000000000000000
00000000000000000000000000077770077770000777707777777777707777777777707777000077770777707r77000000077r70000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000h00000000000000000007770000000007770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000h0000000000
000000000000000000000000000000000000000000a0s0s0a0000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aa0e0aa0000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aaeeeaa0000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000aaeeeaa0000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000a0e0a00000000000000000000000000000000000000000000000000000h00000h00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000a0s0s0a000000000000000000000000000000000000000000000000000000000000000a0s0s0a0000000000000000000
00000000000000000000000000000000aa0e0aa000000000000000000000000000000000000000000000000000000000000000aa0e0aa0000000000000000000
00000000000000100000000000000000aaeeeaa000000000000000000000000000000000000000000000000000000000000000aaeeeaa0000000000000000000
00000000000000000000000000000000aaeeeaa000000000000000000000000000000000000000000000000000000000000000aaeeeaa0000000001000000000
000000000000000000000000000000000a0e0a00000000000000000000000000000000000000000000000000000000000000000a0e0a00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000
0000000000000000000000a0s0s0a0000000000000000000000000000000000000000000000000000100010000000000000000e0a0000000a0s0s0a000000000
0000000000000000000000aa0e0aa000000000000000000000000000000000000000000000000000000000000000000000000eee0a000000aa0e0aa000000000
0000000000000000000000aaeeeaa0000000000000000000000000h000000000000000000000000000000000000000000000a0eee0a00000aaeeeaa000000000
0000000000000000000000aaeeeaa000000000000000000000000000000000000000000000000000000000000000000010000a0ees000000aaeeeaa000000000
00000000000000000000000a0e0a00000000000000000000000000000000000000000000000000000000000000000000001000a0s00000000a0e0a0000001000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000
0000000000000000000000000000000000h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000
0000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000a0s0s0a000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0e0aa000000000
0000000000000001000000000000000000000000000000000000000000000000000000000000000000000h00000000000000000000000000aaeeeaa000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaeeeaa000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0e0a0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000a0s0s0a000000000000000000000000000000000000000000000000000000000000000a0s0s0a000000000000000000h
00000000000000000000000000000000aa0e0aa0000000000000000000000000000000000000000000h0000000000000000000aa0e0aa0000000000000000000
00000000000000000000000000000000aaeeeaa0000000000000000000000000000000000000000h0000000000000000000000aaeeeaa0000000000000000000
00000000000000000000000000000000aaeeeaa000000000000000000000000000000000000000000000000000000000000000aaeeeaa0000000000000000000
000000000000000000000000000000000a0e0a00000000000000000000010000000000000000000000000000000000000000000a0e0a00000000000000000000
000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000e0a0000000a0s0s0a0001000000000000000000000000000000000000000a0s0s0a00000000000000000000000000000
0000000000000000000000000000000eee0a000000aa0e0aa0000000000000000000000000000000100000000000aa0e0aa00000000000000000000000000000
000000000000000000000000000000a0eee0a00000aaeeeaa0000000000000000000000000000000000000000000aaeeeaa00000000000000000000000000000
0000000000000000000000000000000a0ees000000aaeeeaa0000000000000000000000000000000000000000000aaeeeaa00000000000000000000000000000
00000000000000000000000001000000a0s00000000a0e0a000000000000000000000000000000000000000000000a0e0a001000000000000000000000000000
000000000000000000000000000000000a000000000000h000000000000000000000000000000000000000000000000100000000000000000000000000000000
00000000000000000000000000000000h000000000000000000000000000010000000000000000a0000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000a0s0s0a000000000000000000e0a00a0s0s0a000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000aa0e0aa000000000h0000000eee0a0aa0e0aa000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000aaeeeaa0000000000000000a0eee0aaaeeeaa000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000aaeeeaa00000000000000000a0ees0aaeeeaa000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000a0e0a0000000000000000000a0s000a0e0a000000000000000000000000000000h000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000h0000000000000000000000000000000000000000000000000
000000h0000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000e0a000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000eee0a00000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000100000000000000000000000000a0eee0a0000000000000000000000000000000000000000100000
0000000000000000000000000000000000000000000000000000000000000000000000000000a0ees00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000a0s000000000000000000000000000000000000000000000000
000000000000000000000000000000000000001000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000h00000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000
0000000000000001h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000h000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000h00000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000h0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000h000000000000h000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000h00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc0ccc0ccc0cc000000ccc0ccc0c0c0c0000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000c00c000000c0c0c0c0c0c0c0000
000000000000000000010000000h000000000000000000000000000000000000000000000000000000000000000ccc0c0c0ccc00c000000ccc0ccc0c0c0c0000
00000000000000000000000000000000000000000000000000000000h0000000000000000000000000000000000c000c0c0c0000c000000c000c0c0c0c0c0000
0000000000000000000000100000000000000000000000000000100000000000000000000000000000000000000ccc0ccc0ccc0ccc00000c000c0c00cc0ccc00
00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__meta:title__
phoenix 0.80
2021 paul hammond
