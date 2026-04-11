pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

--beam--
--by rupees
function _init()
  hbj = 4
  multi_sfx [[-1]]
  game = {}
  p_init()
  door_o = tfnsplit "-f-,-f-,-f-,-f-,-f-,-f-,-f-,-f-,-f-,-f-"
  rect_y, menu_glow, fxply, em, ldd = unpack_tfnsplit "127,-f-,-f-,302,-f-"
  beam_charges = tfnsplit "-f-,-f-,-f-,-f-,-f-,-f-"
  beam_go = tfnsplit "-f-,-f-,-f-,-f-,-f-,-f-"
  b2b_go, allbeam_go, mtn_bridge, mtn_door, numdroplets, wspr = unpack_tfnsplit "-f-,-f-,-f-,-f-,30,238"
  danim, rips, sparkles, waterfall, fly, bird_pos, bird_freed = {}, {}, {}, {}, {}, {}, {}
  wfall_init(504)
  b_list()
  birds, birdboss, wtime, t, d, grow, b3 = unpack_tfnsplit "50,-t-,0,0,0,0,-f-"
  bt = split "1,1,1,1,1,1"
  cave, cave2, cave3, woods1, gameover, vidx, vidy = unpack_tfnsplit "-f-,-f-,-f-,-f-,-f-,-600,0"
  mirror, key, shoes, ftsteps, xangle, throb, sho, pbird, trans, max_sparkles = unpack_tfnsplit "-f-,-f-,-f-,-t-,2.5,0,1,-f-,0,2"
  for i = 1, max_sparkles do
    add_sparkle()
  end
  poke(24412, 255)
  cartdata "beam_rupees"
  menuitem(1, "reset progress", function()
    dset(0, 0)
    run()
  end)
  init_birds()
  ld()
  if not game.upd then
    show_menu(-540, -9)
  end
end

function _update60()
  maplimit()
  if not intro then
    p_inputs()
    p_anim()
  end
  update_sparkles()
  game.upd()
  camera(vidx, vidy)
  if is "cave,cave2,cave3,mtn" then
    if p.y < -4 then
      if max_sparkles < 100 then
        max_sparkles = 30 + abs(p.y)
      end
    else
      max_sparkles = 30
    end
  elseif intro == nil then
    max_sparkles = 3
  elseif p.x < -24 then
    if max_sparkles < 150 then
      max_sparkles = abs(p.x) / 6.66
    else
      max_sparkles = 149
    end
  else
    max_sparkles = 8
  end
  wksnd()
  u_bird()
  u_ripple()
  allbeam_go = beam_go[1] and beam_go[2] and b2b_go and beam_go[3] and beam_go[4] and beam_go[5] and beam_go[6]
  if mtn and entcave_up "-8,2" then
    show_cave3(1000, 264)
  end
  if entcave_up "8,69" then
    show_woods1(672, 375)
  end
  sv()
end

function _draw()
  cls()
  if gameover then
    multi_darklight [[
    78,35,56,56]]
  elseif game1 then
    if keycave then
      multi_darklight [[
	  	78,35,56,22]]
    else
      multi_darklight [[
	  	78,35,56,26]]
    end
  end
  upd_doors()
  game.drw()
  chk_bridge()
  multi_darklight [[36,5,18,251
   115,10,0,209
   53,18,0,225
         58,21,218,207
         62,41,251,18
         78,34,54,235     
         63,8,0,113
         64,8,0,113
         8,24,251,18
         55,15,18,251 
         55,22,00,225
         69,8,18,219
         69,9,18,54
         69,10,18,251
         30,11,7,209
         36,30,18,56
       1,26,53,251
          1,25,235,54
         ]]
  if cave4 then
    multi_mset [[0,15,255]]
  else
    multi_mset [[0,15,7]]
  end
  if mtn_door then
    multi_darklight [[95,23,223,206]]
  else
    multi_darklight [[95,23,223,26]]
    multi_mset [[95,24,25]]
  end
  if gameover then
    multi_mset [[95,24,45]]
  end
  if mg(55) then
    multi_mset [[  27,6,38]]
    shoes = true
    multi_sfx [[14]]
  end
  beam_all()
  if not mg(11) then
    d_bird()
  end
  if b3 then
    transfer()
  end
  if not gameover then
    info_1()
  end
  if d > 100 then
    d = 0
  end
  pal()
  hud()
end

function add_sparkle()
  local sparkle_x, sparkle_y, delay = vidx + rnd(144) - 8, vidy + rnd(144) - 8, rnd(1)
  add(sparkles, {x = sparkle_x, y = sparkle_y, t = -delay})
end

function update_sparkles()
  for i = #sparkles, 1, -1 do
    local s = sparkles[i]
    if s.t < 0 then
      s.t = s.t + (.05)
    else
      s.t = s.t + (rnd(.05))
      if s.t >= 1 then
        del(sparkles, s)
      end
    end
  end
  while #sparkles < max_sparkles do
    add_sparkle()
  end
end

function draw_sparkles()
  for s in all(sparkles) do
    if s.t >= 0 then
      local c
      if s.t < .33 then
        if grow > 0 or flash or mtn or intro == nil then
          c = 7
        else
          c = 6
        end
      elseif s.t < .66 then
        c = 6
      else
        if intro == nil or mtn then
          c = 6
        else
          c = 13
        end
      end
      pset(s.x, s.y, c)
    end
  end
end

function u_bird()
  local n = 0
  if woods1 and not birdboss then
    n = 10
  else
    n = 1
  end
  local px8, py8 = p.x // 8, p.y // 8
  for y = py8 + 1 - n, py8 + n do
    for x = px8 + 1 - n, px8 + n do
      local mxy = mget(x, y)
      if mxy == 39 or mxy == 19 then
        local bird_name = get_random_bird_name()
        add(fly, {ex = x * 8, ey = y * 8, sp = 39, d = rnd(.4) - .2, name = bird_name, age = 0})
        if mxy == 39 then
          mset(x, y, 0)
        else
          mset(x, y, 38)
        end
        mark_bird_freed(x, y)
        if birds > 0 then
          birds = birds - (1)
        end
        if is "cave,cave2,cave3" then
          multi_sfx [[61]]
        else
          multi_sfx [[11]]
        end
      end
    end
  end
  for e in all(fly) do
    e.ex = e.ex + (e.d)
    e.ey = e.ey - (e.d + .5)
    if e.age < 4 then
      e.age = e.age + (.01)
    end
    if is "cave,cave2,cave3" and e.age > 4 then
      e.sp = 0
    elseif e.sp < 43.8 and e.sp > 1 then
      e.sp = e.sp + (.2)
    else
      e.sp = 40
    end
    if e.age > 3 then
      if e.ex > 530 then
        if e.ey < -310 then
          e.ey = 492
          e.ex = rnd(536)
        elseif e.ex > 896 then
          e.ex = 640
        end
      elseif e.ex < 530 then
        if e.ey < -294 then
          e.ey = 384
          e.ex = rnd(256) + 640
        end
      end
    end
  end
end

function d_bird()
  if cave and not beam_go[3] or cave2 and not beam_go[4] or cave4 and not know_birds then
    multi_pal [[15,2
                  7,1
                  9,1]]
  end
  if not is "cave,cave2,cave3" then
    no_flash_pal()
  end
  for e in all(fly) do
    function p_name()
      print(e.name, e.ex + 9, e.ey + 1, 15)
    end

    if abs(e.ey - p.y) < 128 and abs(e.ex - p.x) < 128 then
      spr(e.sp, e.ex, e.ey)
      if know_birds then
        if p.x < 896 then
          p_name()
        end
      end
    end
    if not is "birdboss,mtn" and e.ey < 0 then
      del(fly, e)
    end
  end
end

function get_random_bird_name()
  return del(bird_names, rnd(bird_names)) or "\xe2\x99\xa5"
end

function bigbird(x, y)
  spr(32, x, y + 8, 1, 2)
  if p.x > x + 8 then
    flp = false
    sspr(0, 8, 8, 11, x, y, 8, 11, flp)
  elseif p.x < x - 16 then
    flp = true
    sspr(0, 8, 8, 11, x, y, 8, 11, flp)
  else
    spr(74, x, y, 1, 2)
  end
end

function b_list()
  bird_names = split "KISTE,SCOTTTROYER,SQUISHYAM,PUBJOE,kAMIkAT_2012,STUFF,lUKA TV,rEALsHADOWcASTER,\xe2\x99\xa5\xe2\x99\xa5lISE\xe2\x99\xa5\xe2\x99\xa5,MAXLE,JED,oRGLU,eLIAS,rASCAL,vERB,RYANU,pICOcODER,YAKY,lOOPSEEDER9999,bLOODBANE,fOCUS27,WOLFRAM,ANSEL,GODLANCE,MOZZARELLAMOON,THEpIXELxB_,dAN97,ANDREJTRINDADE,CCtOAD,uMMMM_OK,jromhACKS,KOZM0NAUT,sMELLYfISHSTIKS,FRINGD,jAMESwOODWRIGHT,AJORG,MARDEM1976,sEBAjk7,FUGUESOFT,dROODLE,PANCELOR,MICHEAL,nEONESQUE,rUPURTbUNNY,say sI,dUCKLOVER1,JASONDELAAT,cAPTNoBVIOUS,lORDzANNEN"
end

function show_game(gx, gy)
  be3()
  p_init()
  cave, cave2, cave3, mtn, gameover, game1, cave4 = unpack_tfnsplit "-f-,-f-,-f-,-f-,-f-,-t-,-f-"
  sm(game_update, game_draw, gx, gy)
  parts = {}
  if b2b_go then
    m_music [[40,3000,5]]
  elseif b3 and not b4 then
    m_music [[30,3000]]
  else
    m_music [[20,3000,5]]
  end
end

function game_update()
  if p.y < 147 then
    m_wfall_upd [[16,64,505,14]]
    wpart_update()
    w_rip_action(496, 24, 66)
  end
  if intro then
    intro_cam()
  else
    game_cam()
  end
  if game1 and p.x < 344 then
    if entcave_up "16,22" then
      m_show_cave1 [[968,79]]
    elseif entcave_up "0,3" then
      m_show_cave1 [[904,0]]
    elseif mg(43) then
      m_show_cave2 [[904,127]]
    end
  elseif game1 and p.x > 344 then
    if entcave_up "7,113" then
      m_show_cave3 [[960,359]]
    elseif entcave_up "16,53" then
      m_show_cave3 [[904,375]]
    elseif entcave_up "-8,23" then
      if p.y < 184 then
        m_show_cave2 [[912,152]]
      elseif p.y > 184 then
        m_show_cave2 [[944,144]]
      end
    elseif entcave_up "16,22" then
      if p.y > 344 then
        m_show_cave2 [[1000,246]]
      elseif p.y < 344 then
        m_show_cave2 [[1008,175]]
      end
    elseif entcave_up "16,6" then
      m_show_cave2 [[976,239]]
    end
  end
  if entcave_up "12,40" then
    m_show_cave1 [[952,-6]]
  end
  enter_dark_upd()
end

function game_draw()
  cls(1)
  reflect()
  draw_sparkles()
  multi_spr [[3,456,72]]
  map()
  beam_chg_group()
  plr()
  pal()
  danger()
  overlays()
  if p.y < 147 then
    multi_rectfill [[504,16,519,67,12]]
    wfall_draw()
    multi_spr [[204,501,55
                 202,516,49,1,2]]
    wpart_draw()
  end
  chest()
  multi_d_sign [[ 9,11,12,5,5,10,8,21
 14,5,15,11,5,5,52,42
 10,11,9,5,5,5,36,20]]
end

function show_game_over(gox, goy)
  be3()
  p_init()
  cave, cave2, cave3, gameover, game1, cave4 = unpack_tfnsplit "-f-,-f-,-f-,-t-,-f-,-f-"
  sm(game_over_update, game_over_draw, gox, goy)
  i_storm()
  if p.x < 640 then
    if birdboss then
      m_music [[31,7000]]
    else
      m_music [[30,7000,1]]
    end
  else
    m_music [[-1,3000]]
  end
  if allbeam_go and gameover then
    multi_mset [[95,28,50]]
  else
    multi_mset [[95,28,89]]
  end
end

function game_over_update()
  upd_storm()
  if mtn then
    mtn_cam()
    if mg(36) and btnp(4) then
      multi_sfx [[12]]
      if not pbird then
        pbird = true
      else
        pbird = false
      end
    elseif mg(36) then
      multi_sfx [[0]]
    end
    if mg(23) then
      multi_show_game_over [[376,0]]
      mtn = false
    end
  elseif not mtn then
    game_cam()
  end
  if entcave_up "9,81" then
    multi_show_game_over [[648,240]]
    mtn = true
  end
  upd_glow()
  if gameover and p.x < 344 then
    if entcave_up "0,3" then
      m_show_cave1 [[904,1]]
    elseif entcave_up "16,22" then
      m_show_cave1 [[968,79]]
    elseif entcave_up "16,53" then
      m_show_cave1 [[920,111]]
    end
  elseif p.x > 343 then
    if entcave_up "16,53" then
      m_show_cave3 [[904,375]]
    end
  end
  if entcave_up "12,40" then
    m_show_cave1 [[952,-6]]
  end
  fxbtn()
  if rect_y < vidy and mg(11) and gameover then
    b3 = false
    show_mtn(824, 204)
  end
  if allbeam_go and mg(50) and not mtn_bridge and btnp(4) then
    bbs()
    mtn_bridge = true
    chk_bridge()
  end
end

function chk_bridge()
  if mtn_bridge then
    multi_mset [[95,26,72
              95,25,72]]
  end
end

function game_over_draw()
  local mg11 = mg(11)
  if flash then
    cls(0)
  else
    cls(4)
  end
  if not mg11 then
    if not mtn then
      reflect()
    end
    no_flash_pal()
    if flash or grow > 0 then
      draw_sparkles()
    end
    multi_spr [[3,456,72]]
    map()
    if mg(36) or pbird then
      multi_pal [[15,7]]
      multi_spr [[255,648,192]]
      pal()
    end
    no_flash_pal()
    multi_spr [[223,752,184
      223,760,184
      223,768,184]]
  end
  if mg11 then
    draw_sparkles()
  end
  enter_dark_drw(142)
  if gameover and mg11 then
    palt(3, t)
    multi_spr [[11,696,208]]
    palt()
  end
  if allbeam_go and mg(50) or mtn_bridge and mtn then
    multi_pal [[13,14]]
    if not mg11 then
      multi_spr [[    50,760,224]]
    end
    pal()
    multi_sfx [[0]]
  end
  beam_chg_group()
  no_flash_pal()
  plr()
  danger()
  if not mg11 then
    overlays()
  end
  chest()
  pal()
  gameover_color()
  if flash then
    if rnd() < .06 then
      if not mtn then
        lightning(rnd(128) + vidx, vidy)
        if rnd() < .8 then
          multi_sfx [[8]]
        end
      end
    end
  end
end

function i_storm()
  flashdown = 100
end

function upd_storm()
  flash = false
  local n = 1
  if p.x < -454 then
    n = 3.5
  end
  flashdown = flashdown - (n)
  if flashdown <= 3 then
    if not is "cave,cave3" then
      flash = true
    end
    multi_sfx [[9]]
  end
  if flashdown <= 0 then
    flashdown = rnd() < .5 and rnd(200) or rnd(20)
  end
end

function lightning(x, y)
  local newx, newy, rndg = x + (rnd(2) - 1) * 16, y + (rnd(2) - .3) * 10, rnd(376) + rnd(376) + 143
  line(x, y, newx, newy, 7)
  if newy < rndg then
    lightning(newx, newy)
    if rnd() < .01 then
      lightning(newx, newy)
    end
  end
end

function p_init()
  p = {x = 0, y = 0, sp = 70, m_speed = .5, ac = .2, velocity_x = 0, velocity_y = 0, anim = 0, flp = false, rflp = false, spyup = 80, spdown = 96, d_right = false, d_left = false, d_up = false, d_down = false, idle = true, szx = 3, szy = 3}
end

function collide()
  if fg_slow(2) then
    hbj = 8
  else
    hbj = 7
  end
  local px1, px6, py4, py7 = (p.x + 1) / 8, (p.x + 6) / 8, (p.y + 4) / 8, (p.y + hbj) / 8
  if fget(mget(px1, py4), 0) or fget(mget(px6, py4), 0) or fget(mget(px1, py7), 0) or fget(mget(px6, py7), 0) or trans > 0 or grow > 0 then
    return true
  else
    return false
  end
end

function p_inputs()
  local lx, ly, i_x, i_y = p.x, p.y, 0, 0
  if btn(0) then
    i_x, p.flp, p.rflp = unpack_tfnsplit "-1,-t-,-t-"
  elseif btn(1) then
    i_x, p.flp, p.rflp = unpack_tfnsplit "1,-f-,-f-"
  end
  if btn(2) or time() < 1 and not ldd then
    i_y = -1
  elseif btn(3) then
    i_y = 1
  end
  p.velocity_x = p.velocity_x + (i_x * p.ac)
  p.velocity_y = p.velocity_y + (i_y * p.ac)
  p.velocity_x = p.velocity_x * (.8)
  p.velocity_y = p.velocity_y * (.8)
  local c_s = sqrt(p.velocity_x ^ 2 + p.velocity_y ^ 2)
  if c_s > p.m_speed then
    local ratio = p.m_speed / c_s
    p.velocity_x = p.velocity_x * (ratio)
    p.velocity_y = p.velocity_y * (ratio)
  end
  if shoes then
    if btn(5) and not p.idle then
      if sho < 1.6 then
        sho = sho + (.01)
      end
      p.velocity_x = p.velocity_x * (sho)
      p.velocity_y = p.velocity_y * (sho)
    else
      sho = 1
    end
  end
  p.x = p.x + (p.velocity_x)
  if collide() then
    p.x = lx
  end
  p.y = p.y + (p.velocity_y)
  if collide() then
    p.y = ly
  end
end

function p_anim()
  local t = time()
  if grow < 1 or trans > 1 then
    if btn(0) then
      p.d_left, p.d_right, p.d_up, p.d_down, p.idle = unpack_tfnsplit "-t-,-f-,-f-,-f-,-f-"
      if t - p.anim > .09 then
        p.anim = t
        p.sp = p.sp + (sho)
        if p.sp > 69 then
          p.sp = 64
        end
      end
    elseif btn(1) then
      p.d_right, p.d_up, p.d_down, p.d_left, p.idle = unpack_tfnsplit "-t-,-f-,-f-,-f-,-f-"
      if t - p.anim > .09 then
        p.anim = t
        p.sp = p.sp + (sho)
        if p.sp > 69 then
          p.sp = 64
        end
      end
    elseif btn(2) or t < 1 and not ldd then
      p.sp = p.spyup
      p.d_up, p.d_right, p.d_down, p.d_left, p.idle = unpack_tfnsplit "-t-,-f-,-f-,-f-,-f-"
      if t - p.anim > .09 then
        p.anim = t
        p.spyup = p.spyup + (sho)
        if p.spyup > 85 then
          p.spyup = 80
        end
      end
    elseif btn(3) then
      p.sp = p.spdown
      p.d_down, p.d_right, p.d_up, p.d_left, p.idle = unpack_tfnsplit "-t-,-f-,-f-,-f-,-f-"
      if t - p.anim > .09 then
        p.anim = t
        p.spdown = p.spdown + (sho)
        if p.spdown > 101 then
          p.spdown = 96
        end
      end
    else
      p.idle = true
    end
  end
  if p.idle and p.d_right then
    p.sp = 70
  elseif p.idle and p.d_left then
    p.sp, p.flp, p.rflp = unpack_tfnsplit "70,-t-,-t-"
  elseif p.idle and p.d_down then
    p.sp, p.flp, p.rflp = unpack_tfnsplit "70,-t-,-t-"
  elseif p.idle and p.d_up then
    p.sp = 80
  end
end

function maplimit()
  if mtn then
    if p.x < 641 then
      p.x = 641
    end
    maplimit_x(888)
    maplimit_y(248)
  elseif not is "cave,cave2,cave3,mtn,woods1" and intro ~= nil then
    if p.y < -3 then
      p.y = -3
    end
    maplimit_y(375)
    maplimit_x(631)
  elseif cave then
    maplimit_x(1016)
    maplimit_y(120)
  elseif cave2 then
    maplimit_x(1016)
    if p.y < 126 then
      p.y = 126
    end
  elseif cave3 then
    maplimit_y(376)
  elseif woods1 then
    if p.x < 640 then
      p.x = 640
    end
    maplimit_x(889)
    maplimit_y(376)
    if p.y < 257 then
      p.y = 257
    end
  end
  if cave4 then
    maplimit_x(64)
    maplimit_y(168)
    if p.x < -57 then
      p.x = -57
    end
    if p.y < 44 then
      p.y = 44
    end
  end
end

function maplimit_x(gate)
  if p.x > gate then
    p.x = gate
  end
end

function maplimit_y(gate)
  if p.y > gate then
    p.y = gate
  end
end

function danger()
  p.m_speed = .6
  if fg_slow(2) or p.y < -7 or p.x < 0 then
    sk = 1
    p.m_speed = .35
    if not p.idle then
      rip_action()
    end
    no_flash_pal()
    sspr(8, 60, 8, 4, p.x, p.y + 5)
    p.m_speed = .35
  else
    sk = 0
  end
  if fg_slow(3) then
    p.m_speed = .35
  end
end

function reflect()
  no_flash_pal()
  if not mtn then
    if beam_go[1] then
      if p.x < 272 and p.y < 146 then
        split_beam "1,1,132,86,90,13,1.2,-1"
      end
    end
    if beam_go[3] then
      if p.x < 272 and p.y < 224 then
        split_beam "3,13,124,174,70,4,2.5,-2.9"
      end
    end
    if beam_go[4] then
      if p.x > 382 then
        split_beam "4,3,612,364,200,13,-1.4,-2"
      end
    end
    if beam_go[5] then
      if p.x > 440 and p.y < 159 then
        split_beam "5,6,604,140,75,15,-1.5,-1"
      end
    end
    if beam_go[2] and not b2b_go then
      if p.x > 269 and p.x < 640 and p.y > 173 then
        split_beam "2,2,340,378,200,13,2,-2"
      end
    elseif b2b_go and beam_go[2] then
      if p.x > 269 and p.x < 640 and p.y > 112 then
        split_beam "2,2,340,378,73,13,1.5,-1.6"
        split_beam "2,2,452,252,84,13,-.9,-2"
      end
    end
    if beam_go[6] then
      if p.x < 336 and p.y < 280 then
        split_beam "6,6,212,238,148,13,.7,-2"
      end
    end
  end
  if not mg(11) then
    if mtn or intro == nil then
      multi_pal [[2,12
               4,12
               5,12
               9,6
               14,12
               15,6
               7,6]]
    elseif not beam_go[3] and cave or not beam_go[4] and cave2 or not know_birds and cave4 then
      multi_pal [[2,1
               4,1
               5,1
               9,1
               14,1
               15,1
               7,1
               12,1]]
    else
      multi_pal [[2,1
           4,1
           5,1
           9,13
           14,1
           15,13
           7,13
           12,13]]
    end
    if gameover and not flash then
      multi_pal [[2,1
           4,1
           5,1
           9,1
           14,1
           15,1
           7,1
           12,1]]
    end
    if not (mtn and p.y > 102) then
      if know_birds then
        if sho > 1.6 then
          spr(41, p.x, p.y + 11, 1, 1, false, true)
        end
        spr(39, p.x, p.y + 11, 1, 1, p.rflp, true)
      end
      spr(p.sp, p.x, p.y + 6, 1, 1, p.rflp, true)
    end
    for e in all(fly) do
      if abs(e.ey - p.y) < 192 and abs(e.ex - p.x) < 120 then
        if not (mtn and e.ey > 48) then
          spr(e.sp, e.ex, e.ey + 17 + e.age * 7)
        end
      end
    end
    multi_spr [[      8,-100,192
      8,-200,256
      8,-300,64 
  ]]
    pal()
    d_ripple()
  end
  if not birdboss then
    grow_light(864, 328, 6, 6)
  end
end

function wksnd()
  local pmg = mget((p.x + 1) / 8, (p.y + 4) / 8)
  if not p.idle and ftsteps and trans < 1 then
    if shoes and btn(5) then
      wtime = wtime + (1.4)
    else
      wtime = wtime + (1)
    end
    if wtime > 18 then
      if fget(pmg, 5) then
        if is "cave,cave2,cave3,cave4" then
          multi_sfx [[59,-1,0,4]]
        else
          multi_sfx [[16]]
        end
      elseif fget(pmg, 7) then
        if is "cave,cave2,cave3" then
          multi_sfx [[59,-1,8,5]]
        else
          multi_sfx [[58]]
        end
      elseif fg_slow(2) then
        if is "cave,cave2,cave3,cave4" then
          multi_sfx [[59,-1,16,6]]
        else
          multi_sfx [[13]]
        end
      elseif p.y < 0 or p.x < 0 then
        multi_sfx [[13]]
      end
      wtime = 0
    end
  end
end

sk = 0

function plr()
  if shoes then
    multi_pal [[4,14
              5,2]]
  end
  if cave then
    if not beam_go[3] then
      cave_color()
    end
  elseif cave2 then
    if not beam_go[4] then
      cave_color()
    end
  elseif cave4 then
    if not know_birds then
      cave_color()
    end
  end
  for e in all(danim) do
    e.age = e.age + (2)
    e.y = e.y - (.5)
    no_flash_pal()
    spr((cave or cave2) and 75 or 26, e.x, e.y)
    if e.age > 30 then
      del(danim, e)
    end
  end
  if know_birds then
    if sho > 1.6 then
      spr(41, p.x, p.y - 5 + sk, 1, 1, p.flp)
    end
    spr(39, p.x, p.y - 5 + sk, 1, 1, p.flp)
  end
  spr(p.sp, p.x, p.y + sk, 1, 1, p.flp)
  if p.d_up and know_birds then
    rect(p.x + 3, p.y - 2, p.x + 4, p.y, 15)
  end
  pal()
end

function u_ripple()
  for r in all(rips) do
    r.rad = r.rad + (.08)
    if r.rad > 10 then
      del(rips, r)
    end
  end
end

function d_ripple()
  for r in all(rips) do
    if r.rad > 6.5 then
      fillp(0)
    else
      fillp()
    end
    no_flash_pal()
    oval(r.x + 2 - r.rad, r.y + 6 - r.rad / 1.4, r.x + 5 + r.rad, r.y + 7 + r.rad / 1.4, r.col)
    if r.rad > 6 then
      r.col = 13
    elseif r.rad > 4 then
      r.col = 6
    end
  end
  pal()
  fillp()
end

function rip_action()
  local rn = rnd(2) - 1
  d = d + (1)
  if d > 22 then
    add(rips, {x = p.x + rn, y = p.y + (rn - .5), rad = 1, col = 7})
    d = 0
  end
end

cts = 0

function intro_cam()
  if cts < 256 then
    cts = cts + (.5)
  else
    intro = false
  end
  vidx, vidy = -312 + cts, 0 + cts
end

function game_cam()
  local vx, vy, px572, px_152 = p.x - 60, p.y - 60, p.x > 572, p.x < -152
  if px572 and p.x < 640 and p.y < 316 and p.y > 60 then
    vidx, vidy = 512, vy
  elseif p.x < 572 and p.y < 60 then
    vidx, vidy = vx, 0
  elseif px572 and p.x < 632 and p.y < 60 then
    vidx, vidy = 512, 0
  elseif px572 and p.x < 632 and p.y > 316 then
    vidx, vidy = 512, 256
  elseif p.x < 572 and p.y > 316 then
    vidx, vidy = vx, 256
  else
    vidx, vidy = vx, vy
  end
end

function mtn_cam()
  local vx, vy, px700, px640, py_196, py188 = p.x - 60, p.y - 60, p.x < 700, p.x > 640, p.y < -196, p.y > 188
  if woods1 then
    vidx, vidy = 640, 256
  elseif px640 and px700 and p.y > -196 and p.y < 188 then
    vidx, vidy = 640, vy
  elseif px640 and px700 and py188 then
    vidx, vidy = 640, 128
  elseif p.x > 828 and p.x < 896 and p.y < 188 and p.y > -196 then
    vidx, vidy = 768, vy
  elseif p.x > 828 and p.x < 896 and py188 then
    vidx, vidy = 768, 128
  elseif p.x > 700 and p.x < 828 and py188 then
    vidx, vidy = vx, 128
  elseif p.x > 700 and p.x < 828 and py_196 then
    vidx, vidy = vx, -256
  elseif p.x > 828 and p.x < 896 and py_196 then
    vidx, vidy = 768, -256
  elseif px640 and px700 and py_196 then
    vidx, vidy = 640, -256
  else
    vidx, vidy = vx, vy
  end
end

function show_menu(mx, my)
  p_init()
  sm(menu_update, menu_draw, mx, my)
  btimer = 100
end

function menu_update()
  if p.x < -609 then
    p.x = -473
  end
  if p.x > -472 then
    p.x = -608
  end
  if p.y < -9 then
    p.y = 127
  end
  if p.y > 127 then
    p.y = -8
  end
  fxbtn()
  if rect_y < vidy and not gameover then
    intro = true
    multi_show_game [[4,318]]
    multi_sfx [[-1]]
    m_music [[29]]
  end
end

function menu_draw()
  cls(12)
  reflect()
  draw_sparkles()
  enter_dark_drw(7)
  palt(2, t)
  if p.x > -561 and p.x < -550 and p.y > 24 and p.y < 32 then
    multi_pal [[1,7]]
    multi_spr [[37,-556,30]]
    multi_sfx [[3]]
    multi_print [[   hOLD,-584,31,1
   TO sTART,-559,31,1
   warning:tHIS GAME CONTAINS,-600,102,1
   FLASHING LIGHTS,-580,108,7
  ]]
    menu_glow = true
  else
    multi_spr [[37,-556,30]]
    menu_glow = false
  end
  pal()
  plr()
  danger()
end

function show_cave1(c1x, c1y)
  m_music [[-1,3000]]
  sm(cave1_update, cave1_draw, c1x, c1y)
  b3, trans, cave, cave2, cave3, cave4, game1, woods1 = unpack_tfnsplit "-t-,41,-t-,-f-,-f-,-f-,-f-,-f-"
end

function cave1_update()
  if entcave_up "-8,23" then
    if gameover then
      multi_show_game_over [[64,169]]
    else
      multi_show_game [[64,169]]
    end
  elseif p.y < -7 then
    if gameover then
      multi_show_game_over [[64,154]]
    else
      multi_show_game [[64,154]]
    end
  elseif entcave_up "16,3" then
    if gameover then
      multi_show_game_over [[112,79]]
    else
      multi_show_game [[112,79]]
    end
  elseif entcave_up "8,66" then
    multi_show_game_over [[8,200]]
  end
  if mg(50) then
    multi_sfx [[0]]
    if btnp(4) then
      multi_sfx [[12]]
      if not pbird2 then
        pbird2 = true
      else
        pbird2 = false
      end
    end
  end
  vidx, vidy = 896, 0
end

function cave1_draw()
  flash = false
  cls(1)
  reflect()
  if beam_go[3] then
    b4 = true
    draw_sparkles()
  end
  cave_color()
  map()
  multi_bm_chg [[37,992,88,1,3,3]]
  pal()
  if mg(50) or pbird2 then
    multi_spr [[255,936,88]]
  end
  plr()
  danger()
  overlays()
  if beam_go[3] then
    multi_d_sign [[14,11,12,5,10,5,113,0]]
    pal()
  else
    multi_pal [[8,1]]
  end
  multi_sspr [[48,112,4,8,938,49]]
  idol(pbird2, 939, 52, 14)
--if(gameover)gameover_color()
end

function show_mtn(mx, my)
  be3()
  sm(mtn_update, mtn_draw, mx, my)
  multi_sfx [[-1]]
  cave, cave2, cave3, mtn, woods1, gameover, cave4 = unpack_tfnsplit "-f-,-f-,-f-,-t-,-f-,-f-,-f-,-f-"
  multi_mset [[95,28,89]]
  if not gameover then
    if allbeam_go then
      m_music [[10,5]]
    else
      m_music [[2,6]]
    end
  end
end

function mtn_update()
  enter_dark_upd()
  m_wfall_upd [[104,178,664,23]]
  mtn_cam()
  if p.y < -264 then
    dset(0, 0)
    run()
  end
end

function mtn_draw()
  cls(12)
  multi_rectfill [[640,100,895,255,0]]
  local mg11 = mg(11)
  if mg11 or p.y < 102 then
    draw_sparkles()
  end
  if not mg11 then
    reflect()
    multi_rectfill [[663,104,687,181,12]]
    wfall_draw()
    map()
    multi_spr [[7,760,224
                                              8,760,-256]]
  end
  multi_print [[thanks for playing,732,-186,15]]
  enter_dark_drw(14)
  if menu_glow then
    palt(3, 1)
    multi_pal [[12,7]]
    multi_spr [[   11,696,208]]
    pal()
  end
  if mtn and mg(50) then
    multi_pal [[13,15]]
    multi_spr [[50,760,224]]
    pal()
    multi_sfx [[3]]
  end
  plr()
  pal()
  danger()
  if door_o[8] then
    mtn_door = true
  end
  if not mg11 then
    if pbird then
      multi_pal [[15,7]]
      multi_spr [[255,648,192]]
      pal()
    end
    overlays()
  end
  if not gameover then
    multi_pal [[7,13
                    15,5
                    14,15
                    9,15
                    4,1
                    2,1
                    6,13]]
    if shoes then
      shoelace(814, 26, 9)
      palt(3, t)
      multi_spr [[             55,808,40]]
      palt()
    end
    multi_sspr [[0,8,8,12,848,3]]
    if not birdboss then
      multi_sspr [[0,8,8,24,762,-13]]
    end
    if know_birds then
      multi_spr [[39,767,0,1,1,true]]
    end
    multi_spr [[70,767,5,1,1,true]]
    pal()
  end
end

function show_cave2(c2x, c2y)
  m_music [[-1,3000]]
  sm(cave2_update, cave2_draw, c2x, c2y)
  trans = 41
  cave, cave2, cave3, game1, woods1, cave4 = unpack_tfnsplit "-f-,-t-,-f-,-f-,-f-,-f-"
end

function cave2_update()
  if p.x < 960 then
    if entcave_up "16,22" then
      multi_show_game [[464,167]]
    elseif mg(98) then
      multi_show_game [[320,373]]
    elseif entcave_up "16,3" then
      multi_show_game [[480,263]]
    end
  else
    if entcave_up "-8,23" then
      multi_show_game [[416,336]]
    elseif entcave_up "-8,4" then
      multi_show_game [[608,352]]
    elseif entcave_up "-8,2" then
      multi_show_game [[624,272]]
    end
  end
  vidx, vidy = 896, 128
end

function cave2_draw()
  cls(1)
  reflect()
  if beam_go[4] then
    draw_sparkles()
  end
  cave_color()
  chest()
  map()
  pal()
  plr()
  danger()
  overlays()
  if beam_go[4] then
    multi_d_sign [[  5,5,15,11,9,5,118,18  
  14,12,5,5,5,5,114,19]]
  end
end

function show_cave3(c3x, c3y)
  m_music [[-1,3000]]
  sm(cave3_update, cave3_draw, c3x, c3y)
  trans, b3, flash = 41, true, false
  cave, cave2, cave3, mtn, game1, em, woods1, cave4 = unpack_tfnsplit "-f-,-f-,-t-,-f-,-f-,302,-f-,-f-"
end

function cave3_update()
  if gameover then
    if entcave_up "-8,2" then
      multi_show_game_over [[456,64]]
    elseif entcave_up "16,22" then
      multi_show_game_over [[760,247]]
      mtn, cave3 = true, false
    elseif mg(49) then
      multi_show_game_over [[264,0]]
    end
  else
    if entcave_up "-8,4" then
      multi_show_game [[508,65]]
    elseif entcave_up "-8,2" then
      multi_show_game [[456,64]]
    elseif p.x > 992 and entcave_up "16,22" then
      show_mtn(760, 246)
    elseif entcave_up "-8,23" then
      multi_show_game [[456,65]]
    end
  end
  vidx, vidy = 896, 256
end

function cave3_draw()
  cls(1)
  reflect()
  draw_sparkles()
  if not game1 then
    cave_color()
  end
  multi_pal [[5,2]]
  map()
  pal()
  plr()
  danger()
  overlays()
  chest()
end

function be3()
  if b3 then
    trans = 41
  end
end

function show_woods1(wx, wy)
  b3 = true
  m_music [[-1,3000]]
  sm(woods1_update, woods1_draw, wx, wy)
  trans, woods1, cave4 = 41, true, false
  multi_sfx [[10]]
  if gameover then
    i_storm()
  end
  if pbird2 and pbird then
    multi_mset [[            108,41,22
            108,42,104
            ]]
  else
    multi_mset [[            108,41,26
            108,42,25
            ]]
  end
  if gameover and birds < 1 and birdboss then
    multi_mset [[      106,39,39
      107,36,39
      108,33,39
      109,37,39
      110,38,39
      ]]
  else
    multi_mset [[      106,39,0
      107,36,0
      108,33,0
      109,37,0
      110,38,0
      ]]
  end
end

function woods1_update()
  if gameover then
    upd_storm()
  end
  if mg(25) and btnp(4) then
    multi_sfx [[15,-1,0,8]]
  end
  if p.x < 764 then
    vidx, vidy = 640, 256
  else
    vidx, vidy = 768, 256
  end
  if entcave_up "-8,2" then
    woods1 = false
    if gameover then
      multi_show_game_over [[616,0]]
    else
      multi_show_game [[616,0]]
    end
    multi_sfx [[-1]]
  elseif entcave_up "16,22" then
    if p.x > 764 then
      show_cave4(64, 154)
    end
  end
end

function woods1_draw()
  if not gameover then
    cls(1)
  else
    no_flash_pal()
    if flash then
      cls(0)
    else
      cls(4)
    end
  end
  reflect()
  no_flash_pal()
  if flash or grow > 0 or game1 then
    draw_sparkles()
  end
  map()
  plr()
  danger()
  overlays()
  no_flash_pal()
  if not gameover then
    multi_pal [[7,9
                15,2]]
  else
    multi_pal [[7,2
              15,1]]
  end
  if birds > 0 then
    multi_spr [[  117,688,259]]
    print(":" .. birds, 695, 261, 9)
  else
    multi_pal [[9,14
              6,9]]
    multi_sspr [[0,8,8,12,693,257]]
  end
  pal()
  if gameover and birdboss then
    no_flash_pal()
    multi_mset [[      108,34,4
      108,35,4
      108,36,4
      ]]
    bigbird(864, 272)
    if birds < 1 and mg(4) then
      grow = 100
      for i = 1, 14 do
        mset(97 + i, 33, 39)
      end
      multi_mset [[108,33,39
              108,34,39
              108,35,39]]
      birdboss = false
    end
  elseif not birdboss or not gameover then
    multi_mset [[      108,34,0
      108,35,0
      108,36,0
      ]]
  end
  no_flash_pal()
  grow_light(864, 264, 14, 14)
end

function show_cave4(c4x, c4y)
  m_music [[-1,3000]]
  sm(cave4_update, cave4_draw, c4x, c4y)
  mtn, trans = false, 41
  cave, cave2, cave3, game1, woods1, cave4 = unpack_tfnsplit "-f-,-f-,-f-,-f-,-f-,-t-"
end

function cave4_update()
  bg = false
  flash = true
  m_wfall_upd [[0,96,-40,96]]
  if mg(255) then
    bg = true
    multi_sfx [[0]]
  else
    bg = false
  end
  if bg and not know_birds and btnp(4) then
    know_birds = true
    bbs()
  elseif bg and know_birds and btnp(4) then
    know_birds = false
    multi_sfx [[63,3]]
  end
  if know_birds then
    multi_sfx [[3]]
    w_rip_action(-40, 98, 96)
  end
  if mg(40) then
    show_woods1(864, 320)
  end
  vidx, vidy = -56, 48
end

function cave4_draw()
  cls(1)
  reflect()
  cave_color()
  if not know_birds then
    multi_pal [[15,2
                         7,1
                         9,2
                     11,2
                     10,2]]
  else
    multi_pal [[5,2]]
  end
  map()
  pal()
  multi_pal [[15,2]]
  if bg or know_birds then
    multi_pal [[15,7]]
    multi_spr [[255,0,120]]
  end
  if know_birds then
    multi_print [[kN,-8,121,7 
W yOUR bIRDS,9,121,7]]
    draw_sparkles()
  end
  pal()
  plr()
  danger()
  if know_birds then
    wfall_draw()
  end
  overlays()
end

function overlays()
  no_flash_pal()
  if is "cave,cave2,cave3,cave4" then
    multi_pal [[13,2]]
    if cave3 then
      multi_pal [[5,2
      15,15]]
    else
      multi_pal [[5,1]]
    end
    multi_pal [[3,2
                 4,2
                 6,1]]
  end
  ovlfunc()
  multi_spr [[202,1016,264,1,2
             204,984,272
             223,992,264
              57,992,112
              56,992,104
             202,928,64      
             223,1008,264
             223,1000,256
                 59,936,200            
                 202,64,152
                 204,72,144,1,2
                 202,944,8        
                 244,720,376
                 207,920,112
                 56,920,120            
                 217,704,88
                 202,112,368
                 54,112,376        
             223,600,128
             204,1000,184
             57,992,184        
             215,752,24
             231,760,24
             231,760,16
             215,760,8
             217,768,8
             233,768,16
             223,768,24
             217,776,16
             233,776,24 
             220,976,328
             204,400,136
             232,336,200
             1,576,48
             1,576,56
             1,576,64
             54,272,0 
             1,432,56
             1,432,64
             1,432,72
             209,456,54
             201,449,54
             225,463,54
             229,616,0
                213,800,8
                202,888,-8
                218,856,304
                198,864,312
                198,856,8
                218,840,8
                204,720,-8
                202,752,40
                209,752,21
                225,761,31
             106,744,296
                 59,72,48
             106,72,56
             220,896,336
             220,304,0
                 57,312,0 
       220,312,8,1,2   
       202,264,32
       209,265,22 
                202,848,-8   
             202,624,256
             213,608,0
             229,624,0
             220,624,264
             198,16,192
             218,8,184
             223,328,200
             223,344,200 
             213,216,16
             108,240,16
             244,240,0
             244,240,8
             242,200,0
             242,200,8
             234,896,128
             204,904,328
             106,776,312
             203,864,293
       207,112,80  
                231,448,64,3,1
             235,64,168
                     5,600,112,1,2     
             219,328,376             
             106,352,152                     
             202,200,112                
                 21,208,216   
             243,760,264          
             ]]
  multi_sspr [[8,56,8,4,848,16     
      48,112,4,8,884,322      
      48,112,4,8,938,49      
      52,112,4,8,682,147
      52,112,4,8,855,329
      52,112,4,8,554,259
    ]]
  i_drawtree()
  if cave4 then
    multi_spr [[207,64,153
                    234,56,160
                    236,64,168]]
  end
  multi_rectfill [[     368,0,399,7,4
     800,0,831,7,4
     208,0,239,15,4
     752,272,775,279   
     ]]
  palt(3, t)
  multi_spr [[221,200,16     
     119,576,40
     119,432,48
     119,224,24
     119,760,288
     119,720,264    
                  86,216,24  
                     33,216,32,2,1
                    106,296,40
                     59,296,32
                      1,224,40
                    193,288,0
                 241,288,8
                 237,288,200                   
                  119,384,16     
                  254,392,8
                  254,384,8
                  254,376,8 
                  221,368,8
                  242,368,0
                  193,376,16
                  241,376,24
                          1,384,32
                       1,384,24
                 194,368,240,1,2  
        221,536,16
              229,568,32
              243,568,16
              243,568,24
                 211,568,0,1,2
                 253,608,208
                 249,320,216
                 247,352,216
                 199,320,198
                 201,352,198
                 247,312,208
                 249,360,208
                 209,329,190
                 225,340,191
                 209,359,198
                 220,280,304
                  59,344,16
                 246,344,24
                 229,432,40
                 229,424,40
                 221,416,40
                 242,416,32
                 194,416,0
                 222,448,40
                 244,472,16
                 222,472,24
                 243,424,32
                     56,408,24
                 194,792,-32,2,4
                 195,824,-32,2,4
                 221,792,8
                 222,832,8
                 244,832,0
                 242,792,0
                 195,816,-32,1,4
                 195,808,-32,1,4
                 119,816,16
                 119,816,16
                         1,816,24
                         1,816,32
                         1,816,40
      86,808,16
      33,808,24
      95,816,24
     193,800,16
                 241,800,24
                 194,888,192
                 221,888,232
                 202,776,184
            227,768,256,2,2
            226,744,256,2,2
            211,760,256
            242,744,272
            244,776,272
            221,744,280
            222,776,280
            222,656,168
                59,744,296
            193,728,264
            241,728,272
            193,768,288
            241,768,296
                91,668,56,2,2
                237,888,128
                59,888,120
            ]]
  if not shoes then
    shoelace(222, 34, 7)
  end
  palt()
  multi_spr [[209,640,85
       199,704,87
             204,744,176
       209,775,165
       204,688,120
       202,696,104
       229,640,168
       203,704,96
       204,880,200
       202,872,192
       204,872,232
       225,865,183
       216,888,176
       199,888,174
               9,752,136
                  9,768,136
              56,608,312
             218,608,304
               5,608,288,1,2
             195,640,240
             195,648,240
             195,656,240
             211,648,248
                 57,944,128
                 57,992,192
            ]]
  if gameover then
    multi_spr [[223,760,176]]
    multi_pal [[13,2
                     6,1]]
    multi_spr [[198,896,128]]
  else
    multi_spr [[232,760,176
        ]]
  end
  multi_d_sign [[14,5,15,11,5,9,42,32]]
  if pbird then
    multi_d_sign [[5,5,5,15,10,14,70,32]]
  end
  if p.x < -456 then
    print("pLEASE TURN BACK", vidx + 33, vidy + 50, 13)
  end
  pal()
  idol(pbird2, 885, 325, 8)
  idol(pbird, 683, 150, 9)
  idol(pbird, 856, 332, 9)
  idol(pbird, 555, 262, 9)
  if beam_charges[5] then
    multi_rect [[604,124,605,125,10]]
  end
  if beam_charges[1] then
    multi_rect [[132, 60,133, 61,12]]
  end
  if beam_charges[2] then
    multi_rect [[340,356,341,357,14]]
  end
  if beam_charges[4] then
    multi_rect [[612,300,613,301,11]]
  end
  if beam_charges[6] then
    multi_rect [[212,220,213,221,15]]
  end
  if wspr <= 239.6 then
    wspr = wspr + (.2)
  else
    wspr = 238
  end
  for i = 1, 3 do
    spr(wspr, 656 + i * 8, 96)
  end
end

function wfall_init(xy)
  for i = 1, numdroplets do
    waterfall[i] = {x = rnd(8) + 504, y = rnd(8) + 504, speed = rnd(.5) + .6}
  end
end

function wfall_update(ys, ye, xs, w)
  for i = 1, numdroplets do
    local drop = waterfall[i]
    drop.y = drop.y + drop.speed
    if drop.y > rnd(6) + ye then
      drop.y = ys
      drop.x = rnd(w) + xs
      drop.speed = rnd(.5) + .6
    end
  end
end

function wfall_draw()
  for i = 1, numdroplets do
    local drop = waterfall[i]
    pset(drop.x, drop.y, 7)
  end
end

function ovlfunc()
  local py8, px8 = p.y // 8, p.x // 8
  palt(3, t)
  palt(8, t)
  if beam_go[3] and cave or beam_go[4] and cave2 or cave4 and know_birds or cave3 then
    multi_pal [[5,2]]
    if gameover then
      multi_pal [[      15,15
      7,7
      9,9]]
    end
  elseif is "cave,cave2,cave3,cave4" then
    multi_pal [[      15,2
      7,1
      9,2
      5,1]]
  end
  for y = py8 - 1, py8 + 1 do
    for x = px8 - 1, px8 + 1 do
      local tile = mget(x, y)
      if fget(tile, 4) then
        spr(tile, x * 8, y * 8)
      end
    end
  end
  palt()
end

function wpart_update()
  for i = 1, 3 do
    add(parts, {x = 503 + rnd(18), y = 70 + rnd(2), r = rnd(4), c = 15, l = 3, speed = .3})
  end
  for p in all(parts) do
    p.y = p.y - (p.speed)
    p.l = p.l - (.1)
    p.r = p.r - (.03)
    if p.l < 2.8 then
      p.c = 7
    end
    if p.l < 0 then
      del(parts, p)
    end
  end
end

function wpart_draw()
  for p in all(parts) do
    circfill(p.x, p.y, p.r, p.c)
  end
end

r = 0

function w_rip_action(wx, ww, wy)
  local km = rnd(2) - 1
  r = r + (1)
  if r > 20 then
    add(rips, {x = rnd(ww) + wx, y = wy + km, rad = 2, col = 7})
    r = 0
  end
end

function idol(v, x, y, c)
  if v then
    pset(x, y, rnd {c, 7})
  end
end

function shoelace(x, y, c)
  line(x, y, x, y + 13, c)
  line(x - 3, y + 6, x - 3, y + 13, c)
end

function beam_all()
  local vx59, vx61, vx63, vx65, vx67, vx69, vy120, vy122, vy124, vy126, bt1, bt2, bt3, bt4, bt5, bt6 = vidx + 59, vidx + 61, vidx + 63, vidx + 65, vidx + 67, vidx + 69, vidy + 120, vidy + 122, vidy + 124, vidy + 126, bt[1], bt[2], bt[3], bt[4], bt[5], bt[6]
  if not mg(11) then
    if beam_go[3] then
      if p.x < 269 and p.y < 210 then
        split_beam "3,9,124,134,100,7,1.2,-2"
      end
      if mtn then
        split_beam "3,9,756,148,57,7,-1.15,1.9"
      end
      if bt3 < 21 then
        rect(vx59 - bt3, vy124 - bt3, vx61 + bt3, vy126 + bt3, 9)
      end
    end
    if beam_go[1] then
      if p.x < 217 then
        split_beam "1,12,132,46,20,7,1.8,-2.5"
      end
      if mtn then
        split_beam "1,12,756,132,58,7,-1.8,2.2"
      end
      if bt1 < 21 then
        rect(vx67 - bt1, vy124 - bt1, vx69 + bt1, vy126 + bt1, 12)
      end
    end
    if beam_go[4] then
      if p.x > 360 and not mtn then
        split_beam "4,11,612,286,200,7,-1.25,-2"
      end
      if mtn then
        split_beam "4,11,772,148,55,7,1.3,2"
      end
      if bt4 < 21 then
        rect(vx67 - bt4, vy120 - bt4, vx69 + bt4, vy122 + bt4, 11)
      end
    end
    if beam_go[5] then
      if p.x > 440 and p.y < 186 and not mtn then
        split_beam "5,10,604,110,75,7,-2,-2.2"
      end
      if mtn then
        split_beam "5,10,772,132,75,7,1.95,2"
      end
      if bt5 < 21 then
        rect(vx59 - bt5, vy120 - bt5, vx61 + bt5, vy122 + bt5, 10)
      end
    end
    if beam_go[6] then
      if p.x < 328 and p.y < 282 then
        split_beam "6,15,212,206,115,7,.48,-1.8"
      end
      if bt6 < 21 then
        rect(vx63 - bt6, vy120 - bt6, vx65 + bt6, vy122 + bt6, 15)
      end
      if mtn then
        split_beam "6,15,756,164,148,7,-.5,1.8"
      end
    end
    if beam_go[2] then
      if not is "b2b_go,mtn" and p.x > 269 then
        split_beam "2,14,340,342,200,7,1.5,-1.7"
      end
      if bt2 < 21 then
        rect(vx63 - bt2, vy124 - bt2, vx65 + bt2, vy126 + bt2, 14)
      end
    end
    if b2b_go and beam_go[2] then
      if p.x > 269 and not mtn then
        split_beam "2,14,340,342,73,7,1.5,-1.7"
        for i = 1, 84 do
          circfill(i * -.9 + 451, i * -2.6 + 213, rnd(throb), rnd {14, 7, 14})
        end
      end
      if mtn then
        split_beam "2,14,772,164,40,7,.9,2.5"
      end
    end
  end
end

function transfer()
  if trans > 0 then
    trans = trans - (.75)
    circfill(vidx + 64, vidy + 64, trans * 3, 1)
  end
end

function i_drawtree()
  trees = {}
  local fpx8, fpy8 = p.x // 8, p.y // 8
  for x = fpx8 - 14, fpx8 + 14 do
    for y = fpy8 - 12, fpy8 + 16 do
      if mget(x, y) == 71 then
        add(trees, {tx = x, ty = y})
      end
    end
  end
  for e in all(trees) do
    local m, f = e.tx * 8, e.ty * 8
    spr(91, m - 4, f - 24, 2, 2)
    spr(106, m, f - 8)
  end
end

function bbs()
  multi_sfx [[  1,0
  2,2]]
end

function beam(nm, col, xs, ys, pt, wh, xa, xy)
  if mtn then
    fillp(0)
    circfill(xs, ys, rnd(13), rnd {col, wh, col, wh})
    fillp()
    spr(49, xs - 4, ys - 4)
    rectfill(xs - 1, ys - 2, xs + 1, ys + 1, rnd {col, wh, col})
  end
  throb = throb - (.005)
  for i = 1, pt do
    circfill(i * xa + xs, i * xy + ys, rnd(throb), rnd {col, wh, col})
    if throb < 1 then
      throb = 3
    end
  end
  if not mtn then
    line(xs - 2, ys + 6, xs + 1, ys + 6, rnd {col, 7, col})
    rect(xs, ys + 14, xs + 1, ys + 15, col)
  end
  if beam_charges[nm] then
    grow_light(xs, ys, col, wh)
  end
end

function chest()
  local ch = false
  if mg(27) then
    key = true
    multi_sfx [[14]]
    multi_mset [[19,44,38]]
  end
  if cave3 and mg(126) and mirror == false then
    ch = true
    palt(3, t)
    spr(27, 960, 297)
    palt()
  end
  if ch and key and btnp(4) then
    multi_mset [[120,38,116]]
    multi_sfx [[  12
  14]]
    mirror = true
    ch = false
  elseif ch and not key and btnp(4) then
    mirror = false
    multi_sfx [[15,-1,0,8]]
  end
  if mirror then
    t = t + (1)
    if t <= 100 then
      em = em - (.2)
      spr(114, 960, em)
      if em < 288 then
        em = 288
      end
    else
      t = 101
    end
  end
  if mget((p.x + 4) / 8, p.y / 8) == 73 and btnp(4) then
    if mirror then
      m_music [[-1,200]]
      bbs()
      b2b_go = true
    elseif not mirror then
      multi_sfx [[15,-1,0,8]]
    end
  end
  if mirror and not gameover then
    multi_mset [[120,38,116]]
  elseif not is "mirror,gameover" then
    multi_mset [[120,38,115]]
  end
end

function mg(sp)
  local ix2, ix5, iy6, iy7 = (p.x + 2) / 8, (p.x + 6) / 8, (p.y + 6) / 8, (p.y + 7) / 8
  if mget(ix2, iy6) == sp or mget(ix5, iy6) == sp or mget(ix2, iy7) == sp or mget(ix5, iy7) == sp then
    return sp
  end
end

function entcave_up(s)
  local yp, sp = unpack(split(s))
  local y = (p.y + yp) / 8
  return mget((p.x + 2) / 8, y) == sp and mget((p.x + 6) / 8, y) == sp
end

function fg_slow(sp)
  if fget(mget((p.x + 2) / 8, (p.y + 4) / 8), sp) and fget(mget((p.x + 6) / 8, (p.y + 7) / 8), sp) then
    return sp
  end
end

function hud()
  if gameover then
    gameover_color()
  end
  if mirror and not b2b_go and t > 100 then
    spr(114, vidx + 117, vidy + 3 + 114)
    key = false
    t = 101
  elseif key then
    palt(3, t)
    spr(27, vidx + 117, vidy + 3 + 114)
    palt()
  end
  local vx59, vx61, vx63, vx65, vx67, vx69, vy120, vy122, vy124, vy126 = vidx + 59, vidx + 61, vidx + 63, vidx + 65, vidx + 67, vidx + 69, vidy + 120, vidy + 122, vidy + 124, vidy + 126
  if beam_go[1] then
    rectfill(vx67, vy124, vx69, vy126, 12)
  end
  if beam_go[2] then
    rectfill(vx63, vy124, vx65, vy126, 14)
  end
  if beam_go[3] then
    rectfill(vx59, vy124, vx61, vy126, 9)
  end
  if beam_go[4] then
    rectfill(vx67, vy120, vx69, vy122, 11)
  end
  if beam_go[5] then
    rectfill(vx59, vy120, vx61, vy122, 10)
  end
  if beam_go[6] then
    rectfill(vx63, vy120, vx65, vy122, 15)
  end
end

function d_sign(a, b, c, d, e, f, x, y)
  pal(a, 1)
  pal(b, 1)
  pal(c, 1)
  pal(d, 1)
  pal(e, 1)
  pal(f, 1)
  sspr(8, 56, 8, 4, x * 8, y * 8)
  pal()
end

function door_open(s, a, b, c, d, e, f, id, tx, ty, ts, bs)
  if id == 10 and birdboss or id == 3 and gameover then
    return
  end
  if door_o[id] then
    mset(tx, ty, ts)
    mset(tx, ty + 1, bs)
  else
    local g = mg(s)
    if g and beam_go[1] == a and beam_go[2] == b and beam_go[3] == c and beam_go[4] == d and beam_go[5] == e and beam_go[6] == f and btnp(4) then
      door_o[id] = true
      mset(tx, ty, ts)
      mset(tx, ty + 1, bs)
      add(danim, {age = 0, x = tx * 8, y = ty * 8})
      multi_sfx [[15,-1,16,15]]
      if id == 10 then
        b_list()
        for i = 1, 50 do
          local n = get_random_bird_name()
          add(fly, {ex = rnd(256) + 704, ey = rnd(16) + 132, sp = 39, d = rnd(.8) - .4, name = n, age = 0})
        end
      end
      if p.x < 24 then
        b3_door = true
      end
      if p.x > 616 and p.x < 632 then
        keycave = true
      end
    elseif g and btnp(4) then
      multi_sfx [[15,-1,0,8]]
    end
  end
end

function upd_doors()
  split_door_open "25,-f-,-t-,-f-,-f-,-f-,-t-,1,8,22,22,24"
  split_door_open "104,-t-,-t-,-f-,-f-,-f-,-t-,2,36,21,206,24"
  split_door_open "104,-t-,-f-,-t-,-t-,-f-,-f-,3,78,35,22,24"
  split_door_open "25,-t-,-f-,-t-,-f-,-t-,-f-,4,52,43,6,24"
  split_door_open "103,-f-,-f-,-t-,-f-,-f-,-t-,5,113,1,3,52"
  split_door_open "103,-t-,-t-,-f-,-f-,-t-,-f-,6,118,19,3,52"
  split_door_open "103,-f-,-f-,-t-,-t-,-t-,-t-,9,114,20,22,52"
  split_door_open "25,-t-,-f-,-f-,-f-,-t-,-f-,7,42,26,206,24"
  split_door_open "25,-t-,-t-,-t-,-t-,-t-,-t-,8,95,23,24,24"
  split_door_open "104,-t-,-t-,-t-,-t-,-t-,-t-,10,106,3,53,24"
end

function cave_color()
  multi_pal [[13,2
         11,9
         5 ,1
        3,2
        6,1
        4,2]]
  if cave then
    cave_col_sw(3)
  elseif cave2 then
    cave_col_sw(4)
  elseif cave4 then
    if not know_birds then
      multi_pal [[15,2
                     7,1
     9,2
   11,2
     10,2]]
    else
      multi_pal [[5,2]]
    end
  end
end

function cave_col_sw(nm)
  if not beam_go[nm] then
    multi_pal [[15,2
                     7,1
                     9,2
   11,2
    10,2]]
  else
    multi_pal [[5,2]]
    multi_sfx [[3,1]]
    if grow > 0 then
      grow = grow - (2)
    end
  end
end

function info_1()
  if mget((p.x + 4) / 8, p.y / 8) == 51 then
    d = d + (1)
    camera()
    multi_rectfill [[73, 13, 124, 48, 2]]
    multi_pal [[9,1
         10,1
     11,1
     12,1]]
    multi_spr [[5,78,19,1,2
     5,95,19,1,2
 234,78,35,1,1
 219,95,35,1,1]]
    if d > 50 then
      multi_spr [[4,112,27
        235,112,19
         52,112,35]]
      multi_rectfill [[82, 31, 83, 32, 14
      	99, 31, 100, 32, 15]]
    else
      multi_spr [[26,112,27
    235,112,19
    52,112,35]]
    end
    multi_sspr [[8,56,8,4,112,19]]
    camera(vidx, vidy)
  end
end

function enter_dark_upd()
  upd_glow()
  fxbtn()
  if rect_y < vidy and mg(11) and not gameover then
    b3 = false
    multi_sfx [[-1]]
    multi_show_game_over [[824,204]]
  end
end

function enter_dark_drw(c)
  if btn(4) and menu_glow then
    rect_y = rect_y - (1)
    rectfill(vidx, vidy + 127, vidx + 300, rect_y, c)
    max_sparkles = abs(vidy + 127 - rect_y) * 1.1
  else
    rect_y = vidy + 127
  end
end

function bm_indicator(num)
  if beam_charges[num] and beam_go[num] == false and btnp(4) then
    beam_go[num] = true
    if cave then
      bbs()
    else
      multi_sfx [[49,3]]
    end
    grow = 100
  elseif beam_charges[num] and beam_go[num] and btnp(4) then
    beam_go[num] = false
    bt[num] = 0
    multi_sfx [[63,3]]
  end
end

function bm_chg(sp, sx, sy, sc, chg_num)
  no_flash_pal()
  if mg(sp) then
    pal(sc, 7)
    spr(sp, sx, sy)
    multi_sfx [[0]]
    beam_charges[chg_num] = true
  else
    beam_charges[chg_num] = false
    pal()
  end
  if beam_go[chg_num] then
    pal(sc, 7)
    palt(3, t)
    palt(6, t)
    spr(sp, sx, sy)
    pal()
  end
  if beam_go[chg_num] and bt[chg_num] < 21 then
    bt[chg_num] = bt[chg_num] + (.5)
  end
  bm_indicator(chg_num)
end

function gameover_color()
  print("\xe2\x81\xb6!5f100\xe2\x96\x92\xf0\x9f\x90\xb13\xe2\x96\x88567\xe2\x98\x89\xec\x9b\x83:0\xf0\x9f\x98\x90\xe2\x99\xaa4\xe2\x97\x86")
  if not flash then
    print("\xe2\x81\xb6!5f100\xe2\x96\x92\xf0\x9f\x90\xb13\xe2\x96\x885=7\xe2\x98\x89\xec\x9b\x83:0\xf0\x9f\x98\x90\xe2\x99\xaa4\xe2\x97\x86")
  end
end

function no_flash_pal()
  if gameover and not flash then
    multi_pal [[0,4
              2,4
    3,2
      5,2
  6,2
              7,5
              8,2
              9,13
              10,2
              11,3
              12,2
              13,1
              15,6]]
  end
end

function beam_chg_group()
  if p.x < 300 then
    multi_bm_chg [[10,88,32,13,1]]
    multi_bm_chg [[50,208,264,13,6]]
  elseif p.x > 300 then
    multi_bm_chg [[10,552,40,13,5]]
  end
  multi_bm_chg [[245,320,320,5,2]]
  multi_bm_chg [[35,560,352,5,4]]
  if b2b_go then
    no_flash_pal()
    multi_spr [[114,448,212]]
  end
end

function dark_light(x, y, g, ng)
  if gameover then
    mset(x, y, g)
  else
    mset(x, y, ng)
  end
end

function grow_light(xs, ys, col, wh)
  grow = grow - (1.5)
  if grow > 0 then
    max_sparkles = 200
    if grow < 11 then
      fillp(0)
      wh = col
    end
    rectfill(xs - grow * 20, ys - grow / 5, xs + grow * 20, ys + grow / 5, wh)
    circfill(xs, ys, grow * 1.5, wh)
    fillp()
  end
end

function tfnsplit(s, sep, num)
  local a = {}
  sep = sep or ","
  if num == nil then
    num = true
  end
  foreach(split(s, sep, num), function(v)
    if v == "-t-" then
      v = true
    end
    if v == "-f-" then
      v = false
    end
    if v == "-n-" then
      v = nil
    end
    add(a, v)
  end)
  return a
end

function unpack_tfnsplit(...)
  return unpack(tfnsplit(...))
end

function unpack_split(...)
  return unpack(split(...))
end

function split_beam(s)
  beam(unpack(split(s)))
end

function split_door_open(s)
  door_open(unpack(tfnsplit(s)))
end

function string_caller(f, splitter)
  local c = {}
  return function(s)
    local t = c[s]
    if not t then
      t = {}
      local p = split(s, "\n")
      for i = 1, #p do
        add(t, splitter(p[i]))
      end
      c[s] = t
    end
    for i = 1, #t do
      f(unpack(t[i]))
    end
  end
end

function is(s)
  for v in all(split(s)) do
    if _ENV[v] then
      return true
    end
  end
end

function fxbtn()
  if btn(4) and menu_glow and not fxply then
    multi_sfx [[4]]
    fxply = true
  elseif not btn(4) and fxply then
    multi_sfx [[-1]]
    fxply = false
  end
end

function upd_glow()
  if mg(11) then
    multi_sfx [[3]]
    menu_glow = true
  else
    menu_glow = false
  end
end

multi_mset = string_caller(mset, split)
multi_pal = string_caller(pal, split)
multi_spr = string_caller(spr, split)
multi_sspr = string_caller(sspr, split)
multi_darklight = string_caller(dark_light, split)
multi_rectfill = string_caller(rectfill, split)
multi_d_sign = string_caller(d_sign, split)
multi_rect = string_caller(rect, split)
multi_print = string_caller(print, split)
multi_bm_chg = string_caller(bm_chg, split)
multi_sfx = string_caller(sfx, split)
multi_show_game = string_caller(show_game, split)
multi_show_game_over = string_caller(show_game_over, split)
m_show_cave1 = string_caller(show_cave1, split)
m_show_cave2 = string_caller(show_cave2, split)
m_show_cave3 = string_caller(show_cave3, split)
m_music = string_caller(music, split)
m_wfall_upd = string_caller(wfall_update, split)

function packb(a)
  local v, p = 0, 1
  for i = 1, #a do
    if a[i] then
      v = v + (p)
    end
    p = p * (2)
  end
  return v
end

function unpackb(v, c, a)
  for i = 1, c do
    a[i] = v % 2 > 0
    v = v // 2
  end
end

function init_birds()
  for y = 0, 127 do
    for x = 0, 127 do
      local t = mget(x, y)
      if t == 39 or t == 19 then
        add(bird_pos, {x = x, y = y, t = t})
        add(bird_freed, false)
      end
    end
  end
end

function mark_bird_freed(x, y)
  for i = 1, #bird_pos do
    local b = bird_pos[i]
    if b.x == x and b.y == y then
      bird_freed[i] = true
      return
    end
  end
end

function pack_birds(s)
  local v, p = 0, 1
  for i = s, s + 15 do
    if bird_freed[i] then
      v = v + (p)
    end
    p = p * (2)
  end
  return v
end

function unpack_birds(v, s)
  for i = s, s + 15 do
    bird_freed[i] = v % 2 > 0
    v = v // (2)
  end
end

function apply_freed_birds()
  for i = 1, #bird_pos do
    if bird_freed[i] then
      local b = bird_pos[i]
      if b.t == 39 then
        mset(b.x, b.y, 0)
      elseif b.t == 19 then
        mset(b.x, b.y, 38)
      end
    end
  end
end

svt = 0
rs = {show_game, show_cave1, show_cave2, show_cave3, show_woods1, show_cave4, show_mtn}

function sv()
  if intro or not is "game1,cave,cave2,cave3,cave4,woods1,mtn,gameover" then
    return
  end
  svt = svt + (1)
  if svt < 60 then
    return
  end
  svt = 0
  local r = cave and 2 or cave2 and 3 or cave3 and 4 or woods1 and 5 or cave4 and 6 or mtn and 7 or 1
  dset(0, r)
  dset(1, p.x)
  dset(2, p.y)
  dset(3, packb(beam_go))
  local a = {mirror, shoes, key, know_birds, pbird, pbird2, b2b_go, b3, b4, birdboss, gameover, mtn_bridge}
  dset(4, packb(a))
  dset(5, birds)
  dset(6, packb(door_o))
  dset(7, pack_birds(1))
  dset(8, pack_birds(17))
  dset(9, pack_birds(33))
  dset(10, pack_birds(49))
end

function ld()
  local r = dget(0)
  if r < 1 then
    return
  end
  ldd = true
  intro = false
  local x, y, a = dget(1), dget(2), {}
  unpackb(dget(4), 12, a)
  mirror, shoes, key, know_birds, pbird, pbird2, b2b_go, b3, b4, birdboss, gameover, mtn_bridge = unpack(a)
  if key then
    mset(19, 44, 38)
  end
  if mirror then
    mset(120, 38, 116)
  end
  if shoes then
    mset(27, 6, 38)
  end
  unpackb(dget(3), 6, beam_go)
  bt = split "21,21,21,21,21,21"
  birds = dget(5)
  unpackb(dget(6), 10, door_o)
  unpack_birds(dget(7), 1)
  unpack_birds(dget(8), 17)
  unpack_birds(dget(9), 33)
  unpack_birds(dget(10), 49)
  apply_freed_birds()
  if (r == 1 or r == 7) and gameover then
    mtn = r == 7
    show_game_over(x, y)
  else
    rs[r](x, y)
  end
  local f = 50 - birds
  for i = 1, f do
    local n = get_random_bird_name()
    add(fly, {ex = p.x + rnd(512) - 256, ey = p.y + rnd(1000) + 150, sp = 39, d = rnd(.4) - .2, name = n, age = 0})
  end
end

function sm(u, d, x, y)
  game.upd, game.drw, p.x, p.y = u, d, x, y
end


__gfx__
0000000004242220333333331111111100000000000fff0011111111000000e000000000f6d6dd55333333333333333300003300000000003300003000000030
000000000424222033333333111111110000000000f66600111111110e00000000b00000f6d6dd553dddddd33eeeeee30000330002200000330bb000000003b3
000000000424222033333333111111110000000000f66d0011111111eae0002000000000f6d6dd55dd3333dd3e3333e30033003302330033003bb03300330030
000000000424222033223333111122110000110000dddd00111155110e0002e200000000f6d6dd55dd3dd3dd3e3ee3e30bb30033003300330033003300330000
0000000004242220332233331111221100001100001155001111551100000b2000000300f6d6dd55dd3dd3dd3e3ee3e33bb03333333333333333330033003300
000000000424222033335533112211110022000000dddd00112211110000beb000003a30f6d6dd55dd3333dd3e3333e333022330333333333333322033003220
000000000424222031115513122222210122111000dddd00132233310e000b0000000300f6d6dd553dddddd33eeeeee300322333333333333333322333330220
00000000042422201111111122222222111111110fddddd0333333330000000000000000f6d6dd55333333333333333303333333333333333333333330330000
07777f00f6d6dd552444444233333333333333336fddd56d11111111333333333dd3333333333333111111113333333333003333333311331111333333333300
077fff70f6d6dd5521111112333773333dddddd36fdd556d111111113333333333333ddd366666631ddddddd3337aa3333003333333221331311333333333300
07777770f6d6dd552444444233777f333dddddd36f66666d11111111333333333ddd3ddd366666631d1d1d1d333aef3300333033331223111133113333330033
0777777055d6dd552111111233779f333dddddd36dddddd51111331133bb33333ddd333333333333d6161616333aff3300322333331133111133113333330223
077ffff06655556624444442337fff333dddddd36d2d55d51111331133bb33333333dd333333ddd3d66666663333a33300022333113311111211331133333220
77fe11f76666666621111112337fff333dddddd31ddd55d51122111133331133ddd33333ddd3ddd3d662e266333aff3303003333113313111111331133333300
77f11997ffffffff24444442337fff333dddddd3111dddd51322333131111113ddd3ddd3ddd33333d66666663333f33300333333331111111111111333300330
77f11997dddddddd2111111233399333333333331111111533333333111111113333ddd333333dd3d666666633aaaa3300333333331131111111111133300330
77ffff9700422200042222203333333333333333222222223333333300000000070000700000000000077000000000003300333333333333331133333333bb00
777666970042220004242220355555533dddddd32111111233333333000770007f00007f7007700700077000000770003300333333333333331223333333bb00
77f77997004222000422222055333355dd3333dd112222113333333300777f007f0770ff7ff77fff007fff000ff77ff000333303333333131112233333330033
777ff77f004242444444422055355355dd3dd3dd112112113333333300779f0077777fff777fffff0077ff00777fffff00333333133223331331333333330933
77eff77f004222222222422055355355dd3dd3dd1121121133333333007fff00077ffff0077ffff0077ffff0777fffff00003333331233111331333333339b90
77ee7fff004222222222222055333355dd3333dd1122221133333333007fff00007fff00000ff00007fffff0700ff00f033b3333331133111113313333333900
7e77eeff0002200022224220355555533dddddd32111111233333333007fff00000ff000000ff00007f00ff0000ff00003bfb033111111311113333333330033
7777ee7f00000000000022203333333333333333222222223333333300099000000ff0000000000000f0070000000000000b0033112111111111333333330033
77fe77ef000000006666666666666666222222220000000011111111322233731111111115101111110011000999999033003333333333333333333333333300
7eef77ff000777006dddddd676666666266666620000000015111111325e627211115111151111011100110099a9999433003333333333333333333333333220
ffe7efff00766610dd6666ddd222222d266666620000000015111111376e7e521111511115111111000000009999499400333033333333333333333333330220
ef77feef00766610dd6dd6ddd2d2d22d2222222200002200151111113eee7e76151151111100110000110010499999940032333332233333333333333b330000
77fffeef00766610dd6dd6ddd222dd2d222266620000220015111111376e7eee15115111110011000011000044444442002b23003220330033003300b9b03300
fffffffd00766610dd6666ddd22222256662666200bb00001111151133ee7e761511511111111111000000004944444200020bb033003300330032203b003300
0dddddd0000111006dddddd6dddd55556662222203bb33301111151133227ee31511111100110011000001002444444200000bb300030033b033022000330000
00999900000000006666666631333313222226623333333311111111333332231111111100110011000000000222222000000033000000330033000000330000
0999999009999990099999900999999009999990099999900999999033313333fffffff633333333007777001111111139999993fffffffffffffff633422233
9944449494444944444494449444494499444494999444444444944439422223f666666d33d7ad3307ffff701222222299994994f66666666666666d33422233
9994744499474474947444749947447499947444999947449474447434333323f666666d667e7e66077777701202020299999994f66666666666666d33422233
999444f499444f449444f44499444f44999444f4999944409444f44434333422f666666d67ee77e6077777701202020249999994f66666666666d66d33424244
099ffff009fffff00ffffff009fffff0099ffff00999fff009fffff044423432f666666d6677ee6607ffff701222222244444442f66666666666d66d33422222
0555550005555450f555455f05555400055555000555555f0555450025325232f666666ddd6666557fe11ef71221112244444242f66666666666d66d33422222
00f111f0f111110f41111110001f110001111f00511111000f1111f025523255f666666ddd2222557f1991f71222222224e44442f66666666666d66d33322111
00055400004005000000005000044500005004000000004000400500333255336dddddd5332222337f1991f71222222232222223f66666666666d66d33333333
09999990099999900999999009999990099999900999999033211133f6d6dd55000000006666666677f99f770049999999999400f66666666666d66d34222223
99999999999999999999999999999999999999999999999933211133f6d777d500000005666666667769967704999999999e9940f66666666666d66d34242223
99999999999999999999999999999999999999999999999933211133f67666150f500ff56666666677f79f770499999999999940f66666666666d66d34222223
99999999999999999999999999999999999999999999999933211133f6766615f6d5fdd566666666777ff77f0499999999999942f66666666666d66d44444223
09999990099999900999999009999990099999900999999033211133f6766615f6d5ddd56666666677eff77f0499944999999942f66ddddddddd566d22224223
099555909955559009955ff005995559059955590ff9559033211133f6766615f6d655556666666677ee7fff0499944999999942f66666666666666d22222223
0f11111f0055111f00551ff00f1111f00f1144100ff1441033211233f6d11155f6d6dd55666666667e77eeff0449999999999442f66666666666666d22224223
00554400005544000055440000554400005544000055440033422233f6d6ddd5f6d6dd55666666667777ee7f04444444444444426dddddddddddddd531112223
099999900999999009999990099999900999999009999990333333dd222222223333333333333333001001000444444944424442f66666666666d66d34242223
4444944444449444444494444449444444494444444944443dd333dd266666623dddddd333233323002002000499944444444442f66666666666d66d34242223
9474447494744474947444744744474947444749474447493d133311266666623dddddd332223333994222004999994442244442f66666666666d66d34242223
9444f4449444f4449444f444444f4449444f4449444f44493ddd33112222222233333333332333339440200049a9992442244442f66666666666d66d34242223
09fffff009fffff009fffff00fffff900fffff900fffff9031113dd1222266623333ddd333333233444020004499942444444242f66666666666d66d34242223
055545000555450005554ff0005455500ff45550005455503111311166626662ddd3ddd33b332223010020004444442444444442f66666666666d66d34242223
f01111f0004411f000441ff00f11110f0ff155000f1155003333311366622222ddd3333333333233022220002444442444444420f66666666666d66d34242223
004405000044050000445500004455000040550000445500333333332222266233333dd333333333000200000222224422222200f66666666666d66d34242223
3dd333331aaffbb10007a000666666666a9999a60000000032242223321211133b33333333333333fff2fffb33313333333b3333ffffffff66666666ddd3333d
33333ddd1aaffbb1007e77006666666694444449000990002224224232121113b9b333333b3333b3f6626bbd3322244333baba336666666666666666ddd333dd
3ddd3edd099eecc0007e77006a9999a6944444490099920094222222321211133b333b33bbb32333f6222bed422333433b3ba9a36666666666666666111d3311
3dddeae3099eecc007ee77709aaa7aa495555554009992004124224432121113333333333b333333f6242eae23234422bbb33a3366666666666666661ddd3dd1
3333de330000000007ee77709a9999a4911111140092220042222214321211133333223333333b33f6222ded232545523b33333366666666dddddddd11113dd3
ddd33333670000767eee777e494e5492494e5492009222004294222432121113333322333b33bbb3f66ddd6d5525253233933333666666666666666611513113
ddd3ddd36777777677ee77ee49955992499559920092220045412254341211133333333333333b33f666666d3355235539a93b33666666666666666631113113
3333ddd306666660007aee00424222224242222200099000334555333424222333333333333333336dddddd5333353333393333366666666dddddddd33333113
000000000000000000000000000000c297f200000000c06281d4d7e481626262816283bd8f9f62c4318183ec62662e3e3e3e4e626262c496bf6c8f9f717f83c4
b762f6626262839fc41c77961f31678f3e3d5c3e4e3f3f3f3f4fefefef0000000000000000000000000000000000000063bdce836c8383bfbf83bf7efdfdfdfd
000000000000000000000000000000c362f100000000c26281d623e681ec81814162cd63bdce9fb762ecbf8131622f3f3f3f4fc46262b762c483aebdfcbdcfb7
6281f6ec628fae83de1ff662627f66833f3f3f3f4f5d5e5e5ec600000000007000000072000000000000000000000000ad63bf83bfcf317f8fd27f7efd8efdfd
00000000000000000000000000000000c3f300000000c3c4ecd5e7e581c462628162af83bfdccf97878181ecc4622f3f3f3f4fde62ec62746fafbfdcbfcf7462
628167816283bf63b762f6c47fbdbebd3c5c4d3f4f1f657731e0108000007070700000ac00000000000000000000000083cf87317fd27f8c8c8c837e9e617efd
00000000000000000000000000000000000000000000c0de8181ec81626f6262ec6262aee2b787c7626262c4de62dd5e5e5eedb731816262b79662b7666287ec
31c4818162af41cf9662f6b7afbfa1bf3d3d4d5eedc4f4f5c487f6e00000efefef000063000000000000000000000000cef7627f83bfcff000007cce62768783
000000000000c0e0d0e0f00000000000000000000000c3a78762d3e3d3a7d3e3d3ec62afe1d27f8f746262b76f311f1c7731626262813162628181ec62628162
62de62626262074141416796626686f73d3d4e1c31de62f6b762f6c7e072000000001d8c1e00000000000000000000006c97626ccfd3c7e0f08000838f6262ad
0000000000c087666297f2000000000000000000000000c3e3f300000000000080c2879fafbfad6ce1d2d262b79f621cf6c462ec8141c4ec8181848181814162
626f62627f8f8f9f41414141414107d13f3f4f1cc4b762f66262676296f000100000000000000000000000ac6300000083e241ad0080c3d4d7e4c0cd839f4183
0000000000c2626262e3f300000000000000000000000000000000000000000000c3e3624196afbf83bfade17f83c41ff6b7819762626f6262ec81c462628162
62b7629fad838c837441418f6262d18c3f3f4f1fb76262676262319662b7e01080b30000000000000000000063cc0000cde18183ac0000d637e687afad8321ae
0000000000c3d3e3f3000000000000000000000000000000000000000000000000001d8cf7c762626287836c83cdb762f6ec879f74c4b77f6296c7de7462ec62
7497d1ce8c9c007ce1d27fbd8f9f9c005d5eed8181ecf7966262c431879697f6d0e000000000000000000063cd63cc00bdbf219c630000d5e7e531c783cd2183
c0f0008000000000000000000000000000000000000000000000000000000000000000c3d3e3c2975f62afbf8c83e28167817fad9fb77f839fd296b787d241d2
d2d18c8c1e00ac007c8c8ccd6c830000771c8184848484816262b7626231966796b7e0f0000000008000acbdbebd8c1e8387f31d8c1e8000c3977f976cce216c
c3f3000000000000000000000000000000acbccc00000000000000000000000072000000000000c3e3d3d3f380ae9fec81318363bd8f836cbfbfe1d2d1bf21bf
8c9c000000cc63007200ac83ae63cc1df61f8184800084ec81c481ec81c48181ec81ecf300000000001d8cbfbfcf1d00bdf380000000000080c36287af8362ae
00000000000000000000000000000000ac63bdbfccbc0000000000ac00000000b30000000000000000000000007c83e1d27fcdbdbebd63bff787afbfcf87ecf3
000000acbc6383bcacbcad6363836c00f662ec840072848162b76262c4b7626262e3f300000000000000c3f791f2000083630c00bc000000001d8cc3e36c6283
0000000000000000000000000000ccbc6383cf66bf63bccc00001d8c000e0000a60000bc00000000000050000000cd83bdae8383a1bfcf96d3e3d3e3d3e3f300
0000acbd83cebfbdad63836c63ae83cc6762818484848481629662746f966262f300000000000000000000c3d3f30000cebdbcacbd00000000000000ac8362ad
000000ac00000000000000000dac83bfbfcf87b196aebf8c1e00a6800d0f0c800e0e008c1e000e0000ac51000000836c63bdcf6691ecc7f30000000000000000
0000ae636ccf32afbf83cdbdbebdcd8396748181ec812c3c3c3c4c62b76662f3000000000000000000000000000000006383bfbfceccbccc40acbcbccdce6283
000000adccbc000000000000bccde141d27f8fd2d1cff300000d0d1d0072000d0f0f0c00000d0f0cacadbdbccc1d8c8c8c9cc3d3e3d3f300800000b300000000
00727c8c8ce1d27f9f96afbf61bfce8c3c3c4c6262622d5c3d3d4d87e3d3f3000000000000000000000000000072cc0083626287afae83bdfcbdae6cbfcf62ae
0000007c8c8ccc001dcc001d8cbfbf21bfbf83bfcff2800c00ac000000ac00000000000000ac801dbd6363aecdcc00720000800000000000000c0d0d001d0000
00ac0000007c8c8c8ce17f8fd2d19c005c3d4d2020202e3d3d3d4ef38000000000000000000000000000000000ac63006c207f8f62afbf8383bfbfcf87628f83
00000000001d8c1e008c1e0080c3d34181418f9f62f300000063ccbccc630000accc000eac63bcac63b26c8363cebccc00000000000000000000000000000d0c
1d8c1e0000000c0d1d8c8c8c8c8c1e003d3d3c3c3c3c2f3f3f3f0000000000000000000000000000000000801d8c8c1ebdfcbd839f8f9f8f9f7f8f8f8f7f83cd
dd00000033333133334444444444444444443333999999991111111111111111111111111ddd1111000ddd00000000000dddd0001999999133333333ee4444ee
0d00300033333443399999999999999999999433999999991ddddd1161111dd1111115111ddd1116000ddd00000000000dd110009999949433333dd3e111111e
0500309033333443949999a99999999999999943999222991ddddd1161dd1dd1511115111111dd1600d111ddddddddddd1111d0099e9999433333dd311111111
050e304033333233949999999999999999999943999222991111111161dd1111511115111511dd1601d111ddddddddddd1511d10499999943ddd33331151ddd1
0502304033339993949999999999999999999942999222991511ddd106111511511115111511111601ddddd11ddd11ddd1111d10444444423ddd33335151ddd1
6562664633339993949999999999999999999942449999991511ddd106116111111115111511516001111111111111dddddddd10444424423333333351511111
060600603333999394999999999999999999994244999999151111110611611166666111111611601151111115111111111111112444444233333dd351111151
00000000333332339499999999999999999999429999999911115111006606660000066666606600111111111511115111111111322222233333333351111111
00020000000000009499999999999999999999424444444400000000d555555555555555555555511dddddd111111111111dddd19444444444444442d66d6ff6
0002003300000dd09499999999999999999999424444444400000000f666666666666666666666651dddddd111111111151dddd19444444449444442d66d6ff6
0902d03000dd0dd09499999999999999999999424444224400000000f6ff666666666666666666651ddd111111dddd11151111119444444444444442d66d6666
0402503000dd01109499999999999999999999424444224400000000f6f666666666666666666d651ddd111111dddd11111111119442244444444442dddddddd
64625030061165109499999999999999999999424444444400000000f6666666666666666666dd651111dddd111111111dddddd1344224444444444266ffd66d
6662563606666116949999999999999999999942444e444400000000f666666666666666666666651511dddd115111111dddddd1324444444444444266ffd66d
000660660000666694999999999999999999994244444444000000007fffffffffffffffffffffd515111111115111111dddddd133224444444444436666d6fd
00000000000000009499999999999999999999422222222200000000fdddddddddddddddddddddd51111511111111111111111113333222222222233dddddddd
0002000000dd00d09499999999999999999999424444444400000000fd66d6ffd66d6ff6d66666d5111111111111151111111dd1333331330000000000000000
2002300000dd0010f499999999999999999999424444444408800990fd66d6ffd66d6ff6dff666d51111ddd111511511dddd1dd1399431330000000ff0000000
30d23000001106169499999999999999999999424444444422284449fd66d666d66d6666dff666d51111ddd111511511dddd111139943233f00f000ff0f00ff0
305230b00d11d666f499999999999999944999424444444421284149fdddddddddddddddddddddd51dd11111115111111111111134443233fffff0fffffffff0
305234300dddd000f499999999999999944999424444444422284449fdff666d6f66d66d666df6d51dd11ddd111111115111ddd1331332337f77f7777777777f
3042343401111000f499999999999999999999424444444488889999fdff6f6dee66d6ee6f6d66d511111dddee1111ee1111ddd133233233fcffcfcccfcffccf
d34d34d4611116009449999999999999999994424444444488889999fd66666de244442e666d66d515111111e244442e1111111133222233ccfccccccccccccf
53453e5466666600f444444444444444444444422222222208800990fddddddd24444442ddddddd511111511224444221111511133323333cccccccccccccccc
53424253333332339444444444444444444444423333333333313333333ddd33333333333dddd33311111111111111111ddd1113444400004444444400000000
53434253333332339444444444444444444444423555555394313333333ddd3333333333311dd33331111dd1151111111ddd111399999400444444440ffffff0
33e3432533334433944444444444444444444442553333554432394433d111ddddddddddd1111d3331dd1dd1151111111111dd139999994044444444ff0000ff
3d23432433334433944444444444444444444442553553553132344431d111ddddddddddd1151d1331dd1111151115111511dd139999994044444444ff0ff0ff
35234d2433333233944444444444444444444442553553553222344431ddddd11ddd11ddd1111d133311151115111511151111139999994244444444ff0ff0ff
3523452433333333944444444444444444444442553333553332331331111111111111dddddddd133351311115111511151151339999994244444444ff0000ff
6523652433333333944444444444444444444442355555533332222311511111151111111111111333113113111115111113113344999942444444440ffffff0
06660666333333339444444444444444444444423333333333323333111111111511115111111113333333333333311133333333449999422222222200000000
__map__
00000027000000000000d0c00000000000000000000000000000070707070027cada38fc14f71414eae7dfe9c6dce751dfe9f4e5e5c3c3c3d3d3d3e4f3f3f3f3f3f3f3f2f3f3d3dbd3c5d4e5fb45fbe2cc00e100000000cb0000c8e100000000000000000707070700cc36cb0000c036dbebdbeac8c8c900d1c8c8e1c7c8c8da
000000ca00000000000000ccd1000000000000000000ca2700000707070700ca36dbfc26ce38db14fae7dfe9fb38e712dfe9de69d2d3d3d3d4f3f3f4d5e5e5d5e5e5e5f2f3f3e2dbe3e3e4777b187bf236cbd00000ca003600000000000800070700000000fefefecb07360708ccd1c8da4bdcdbcbcc00cbcccbcacbcbca00c7
000000c8e10000000000cadb000000000000006a0000c6cc0000fe00fefe00dc38fc664726ea3814f9f7f82d1426e712dfe9f1f7e2c5d3d3e4f3f3e7dfe9dbda38ea38dbd5e5f2dbf3f3f46f261869f238c6cc08ca36d1c8ca000000ca000007070700cb000000cb36dbebdbcc36cb00c66738c6fb38fbfb38fbfbeadb39cb00
00000000000000000000db38cc0000c0d00000e0000836db00cb000000cacb3869d7d92626fa36c6dafbcdfb1ef8f7f9f8f8f726f2f3f3f3f4e5e5e7dfe9c63836fafbfc18f1f2dbf3f3f46f261426dddb38dbccc7c8e1003800ca0036cc07070707ca38cccbca36dafb1afbecdbc8ca3878da38f8f979f7f8f926fafb38c600
000000000000000000cbfc0adc0000000008d0f0c0cadc38cac6cacbca38fbfc26e7e91e141ddbcdfc47ed7bfafbfb383838eadbcdcdf3f3f413c1e7dfe9fcc6387f7826ce26dddbe5d5de6f2626264c38fbcddacb0800d1dbccc6ca38dbe7d7d9e938dceadbfbcd381e681d38c90036ec3f38dc38fb1238fbc6f9f8f9263827
0000000000000000c0db782638ca000000000000d1ea38dbec3838fb38fc26f91deae938fbfbfc7b26267b26264726266ffa38da3638c6d5f8f7f9f8f82d1deadb1e2df8260ac1dbf8f12676262626ed66267bea38ca000038ea38ecc8c8e7e7e9e9fbfbfbfc6f7bfaec18dcc900d1c83808ea36fc26697826faeadb3826eacc
00000000000000e0cadc14f9c63900000500000000c7c8c838fc26376f26f7dac8fc6626707b782626ce1818262613267626ea38c6dbc6db3838dbec38fbfc38da38dbc6f926f1c638f92669c2c3c3c34c4779fac8c8e100c7c8c8c90008c7e7e978472626697669f7fcce38cacb00d0dc00c7fb7f2679797826fa36ec26db38
0000000000d0c0f0dbfb12da36dbcc0015003b000008d0c0ea1e26697626c638d0082c472626ce187018481818ce4c262666fbdbea3836dcd7d8d9fc797c1dc8c8c63836dc14f738dbdcf926d2d3d3d3f678263fd0c00000000000000000003c3d3e3d7c792669f83818f7dadbc8e100eccc003c78f726787c6926fa3826fadc
0000000000000000ea7b14fa38fbfbca36006a00000000d1c8da1e2df7f838c900003c3d3e3d264c2618ce182626f626264c26facdfbea36e7e8e9f9781d38717138dcdb383538daecfbfc26d2d3d3d37b263f080000000000cc003b000000000000082c78262638ec1838c636cccbccdb36cc002cdcf8f9267826f7c62666ea
00000000000000d1c8f9262626f72638c6cce0000000000000c7c8c8c8c8eacb00ca000000003c7b2626182626267bf726ed26267b7ffafbe735e93812dcc90000c7c838c635dc3876264c26e2d3c5d3782f00006a000000cac60e6a000000000000000cf72626fafc14fafbfb38dbda36fbc900c73638c6f917f738fc262638
000027000000000000c71ef7f8db03db36ecf0c0d0000000000008cacb00c738ca3600000000001c7c261878264cf73826f6262626267669261478fa1238000000d100db3835fbcd6947f626f2f3f3f37c3f00087a08000cdc38f97b0d0ecc0e0d0e0df7382d26262626264c2669fafbdc3f27d13cfafbfbdbcfdbfc2626f7c6
0000ca00000000e10000dadbea3838c8c8c8e1ca00000000000000dcfbccd1c7c8c8e100d100003c3d4d7d4e697b38daf97b262626262626ce18ce4c26dbcc0000000038ec7026ed26267b26f2f3f3f3d8d8d9000800d7d866da381e2df7dbf92df7f838c6381e2d2df726f6262647f7c608ca0000323c3dc738dc262526eac9
000036000000000000d1c7c8c8c8c90000000038cbcc0000006aca38143808000000000000000000005d7e5e3c79fafbdc694c26262626ce184818edf7ea360000080cfa38ce267b26267926dde5d5e5dfdfe9d6d6d6e7dfe938db38dcdb3838dc38db3638ecdb38dbdaf87b4cce26fb3827c8000000ca08cbdadbf9f8f93800
00d1c8c00000000000000000000000000000d1c8c8c8e100e0e038fc26dc00000000000000ca000000000000003c3df738267b262626f970ce18ce7bc638c8e1000c4779dc26262626262626f1c15677c3c3c3fdd6d6e7e9363938c63936da3939c639da393938dc393938f97b1826f8dacacb00cb0036ccdbc836c638dbc8e1
000000e1000000000000000000000000000000000000d0c0f0f0da26f7c8e1000000002700360000000000000000ca36dbf9141414f73814f7f8f91ddbec0000002cf7f8382626262626262626264f5fd3d3c5d4d6d6e7ea38cc39363a39393a58393a393acc3939cc3a39381e14f73838c6db07db27c7c8c9d1c8c80736cb27
080000000000000000000000000000000000d0c008000000d1c83826ea000000000000cccbdbcc000000000000cb36da36ec14471438ecfbfb38fbc8c8c9000000cac638fc794726262626d72626266fe3d3d3e4d6d6e739db363a39d63a58d6093acc3ad639cacb38cc3aeafb1238c6ea36ec42dccccbcc0007cbca36da38cc
00000000000000000000000000c0d00000000000000000002700ea2efacbcc000000cac6ea38dacb00000000d1c8c8c8c8381e2d1ddbfc3d3e3d3fd0d1000000d1c838fc266926262626d726d9264c6ff3f3f3f4d6d6da3a3939d63ad6ca57cb57cb38cbd63ada3839dccbfc2614fafb6236cb2707cb00cccb00c614f7c1fadb
000000000000ca00000800000000000500000000000000003b00c71e78fa38cccacbdcfb38fbfb38cc0800000000d1cb27c7c8c8c8c900080000000000000000c01cda2626ce2626ce4de7dfe94eed76d3d3d4f4d60039cac6ccd6cbcadbfbfbfbfbcd36ccd639363a3638f82626267bdb38dbccca38dbda36ccc712dcf12638
00000000000036cb0c0f00000000001500000000000000006a0000c71e2d69fafb38fc692626f914ec4d7d4e00000038cccb36cbccd1080708000000000000270cf7381326182626185d7e7e7e5ec2c3c5d3d46cd600cafbfb38ca38fbfc5726577c7bdb38ca3a39d6dbda38f92d141ddcda3638eadbebdb3836cbcb38f826fa
0000000000cadadb792f270000000036000000000008c0d0d0c000d1c8c81e2df7f8f8f7f8f9dc12fc5d7e5e0fcacbda38cd38fbfbcc0008000c0d0e0d0e0fcaf738ec4c26141818ce1814141447d2d3e3e3e4d6d6cbdc142647fafc66260926092679fafbdacbcbcc36cdfb38ec123836dbebdb38fb4bfbdbdcea38fb382666
0000000000da36c636c6cc000000ca38cc00000000000000000000000000c7c8c8c8dadbebdbc6142626267947dcfbfbfc7bce1818fbcc0000f817f7f8f7f8da38dbfc7b261826264c2626264c26e2c5f3f3f4ccd63638f92d792626f92657265726f92626fafb38fbfc7b6978fa12dcc6384b387c796726fafbfc2669c626f7
00ca00000cfadcdb28db3608000036dac8e1000000000000000000000000006a00ca38ec1aea38f926261826f7387f1818cef72d141d3800cadbcfdb38fb38fbfbfc7f2626182626ed264cc2c3c3c3c3e5d5ea38d6eadb39dc1e2df738d711d811d938f92df7f8f9f72679262647143836fc67c67826262613f7f8f9f83802da
003600001c4c38fb1afbda0e0fd1c8c9000000000000ca0000000000000008d0c036c6fc68faec384726ce66eafc181818f738fb12fbc9d1c7fb3638142dce1818ce181818482626f6267bd2c5d3d3d3fbfbfb38cc36393a3938da38dbe7df26dfe9ea38ecdb3938da1e2df92626d7e738782638f9f82d26f738dc38c6dbcfdb
0000cc0c797bfa1e191dfc332f0000080000000000d136cc00000000000000cacbdb3869ce6938daf9261826c6ce13471838da3d3e3f0000003cfafb12fb1e262647262626ce26267b4c26d2d3d3d3d3261818fa38393acbcc39393839ece91ae7e939c63939cac63639c638d7d8e7dfdb3c3ec6ea38dc1238dc36dbc8c8c8c9
cadb262626267ffa12fc693e3f000000000000000000c7c8e10000000000ccdaea38fc264c26faea38d7d8d938f94c1818c638000008000000cc003c3e3edcf9c2c3c3c3c4ce264726f678e2e3e3e3e318241866dc3acafb38cc3a393a381e191d383a393a3a38fbfbcc39dce7dfdfdf380008c73836ec12c636dbeb0036cc00
db36dbf92678262614263f000000000000000000000000000000000000003638fbfc2618181866d7d9381838d7d97b18cefaec000000e100cb3600000800c7ead2d3d3d3d4692626267b26f2f3f3f3f3ce18cef739cafc2669dacb3ad639dc383939ca3ad6cafc18ce383936da38dfd236e10000c7c8fb12fbfb3808eadb3800
c7fbfbfc143d3e3d3e3f0000000000000000000000000000000805000000db2e18ce26187b1879e7e9e91ae7e7e91e2d141d38cc002700cafbdb00cacbcc0038e2e3e3e3e4ce264cc2c3c3c3f3f3f3f3472669da3aea2e0b26fadbcacbcc39393a3a38cccb38181418da3a39db39ece2da000000006a3c267826260efa38c900
003c3e3d3f08000000000000000000000000000000000027000c0d0e0d0e381e142df91818182638e9141914e7dcecfb12fbdc38cbccca384938cb36eadccbdbf2f3f3f3f418267bd2c5d3d3d4d5e5e51e141d39d6db1e2d2679fafb38fc4d7d4e47fafb38fcce18ce38d63a393a39f238cbd0c0007a083c3e4d7d4e79eae100
00070000000000000000000000000000000000000000003b0cf7eaf9794cfafb12fb38267026f7dcec141414ea36db471469fa3638ea38c669dc38fbfb38ea38f2f3f3f3f4142626e2d3d3d3e4567769c612dc3ad638fbfc26481814ce186d596ece1814ce482626c2c3c3c3fdd63af2ea36cc0000000000005d7e5ef7c90000
000800000000000000000000000000000000000000000cf678fafbfc66ed26261469dc1e141d38dbfc181818cdda3826ce2626facdfbda381238ec141414c6dcdde5e5e5de262613f2f3f3f3f44f5f4c3812ead6cb39f9c2c3c3c3c3c4265d7e5e26261326262626d2d3c5d3d4d6d63938c6dbd10000000000ca17f9ea000000
000000000000000000000000000000000000000000001c7a2626ce26267a79261826fadafb38c6387f18ce18ed38dcc3c3c3c426f66938ea12fbfc14471438fc4cf177c12626474cf2f3f3f3f4696f7bec1238fd393adcd2d3d3d3c5d40202020202c2c3c3c3c426e2d3d3d3e4ead63ada3638cc00cacacbcadbcfdb3804cc00
0000000000000000000000000000000c0e0f000000002c69ce181818ce692626ce26f73814fafbfc78cef7187bfafbd3d3d3d4267b66fafbf8f926267879c626ed266ff12626f77bdde5e5d5de266f69c517d3d43aca38d2d3d3d3d3d4d8d8d8d8d8d2d3c5d3d4c3f2f3f3f3f439d6d638dc36dbe1c738db38da3836dbcfdbd1
__gff__
0614202004142004041080202020202014108830801420208080010020202020141414202000201410142014202020201404800120001410050505142020202000201400000000018001140130808030000000000000301030801410108080300000000000000120802014101080803080100005051401302020010120808001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007303030303005050505141414158030070530303030013030300515053030011605303030300001300105100530212107303030308030303030050505301480
__sfx__
300400000776007760077600776007760077600776007750077500775007750077400774007740077400773007730077300773007730077200772007720077200772007710077100771007710077100770007700
460a00002567037660137141372113720137311373013741137401375113750137611376013771137701377013770137611376013751137501374113740137311373013730137211372013711137101371013715
460a0000046701b660107141072110720107311073010741107401075110750107611076010771107701077010770107611076010751107501075010741107401074010731107301073010721107201071110715
310400000074000740007400074000740007400074000740007400074000731007300073000730007300073000730007300072100720007200072000720007200072000711007100071000710007100071507700
61080000006140161102611036110461105621066210762108621096210a6310b6310c6310d6310e6410f64111641136511565117651196611b6611d661206712367126671296712c6712f671346613a6513f635
cd2d0020105141051010521105201053110530105301053010530105301053010521105211051110515005000c5140c5100c5210c5200c5310c5300c5300c5300c5300c5300c5300c5210c5200c5110c51505500
c92d00200a5140a5100a5210a5200a5310a5300a5300a5300a5300a5300a5300a5210a5210a5110a5151c5000951409510095210952009531095300953009530095300953009530095210952009511095150d500
782d0000280352902528025240251f01524025280352902528025240252b015240252803529025280252401528025290352802524025210152402528035290252802524025210152402528035290252802524025
01040000246403f670386602d650246501b660136500d650086400564003650026400164000630006300064000630006300062000620006300062000620006100062000610006150060000610006150060000600
010400000861019640126300d62009620086200661004610036200261002610016100060000610006100061001600006100061000600006100061500600006100061501600016150060000615006000060000600
903c00200a6100b6110c61110611156111b6111f611216111c61116611116110a61104611036110461106611086110d611146112061125611246111f611136110f6110b611096110861107611086110a6110b611
110300003962136620336350060000600306212f6102d6252a600006002862125610236251c6001b600056001e6211c6101b610186101662013625006000860007600252000f6110e6000c6210b6000a61107611
470a0000046701b660107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700107001070010700
910400001a7111f711257112b7110d7010b7010a70109701077010270100701007010070100701007010070100701007010070101701017010170100701007010070100701007010070100701007010070100701
1908000000106001060c136141361b13623136281362b1362f1362f1362f1362f1362f1262f1262f1262f1262f1162f1162f1162f1163b1063b1063b1063b1063b1063b1063b1063b1063b1063b1063b1063b106
3d0300000c0500a050080400603003030010200001000000000000000000000000000000000000000000000004670046751b6601b665023240232102331033310433106341093410b3410f351133411333113325
010300000972000700007000070000700007000070000700007000070000700007000070000700007000070004600046001b6001b600023000230002300033000430006300093000b3000f300133001330013300
892d00200051400510005210052000531005300053000530005300053000530005300052100520005110051505514055100552105520055310553005530055300553005530055300553005521055200551105515
792d0000280352902528025240251d01524025280352902528025240252b0152402528035290252802524015280352902528025240251d01524025280352902528025240252b0152402528035290252802524015
9122002000604006010160101600026000460007600096000f6001360017600196001b6001e60020600216000062400621016210362105631086310d631136311b63120621216211d62118611146110e6110a611
190b0020037300372103711037151b7301b7211b7111b715137301372013710137151673016721167111671516700167001670016700167001670016700167001670016700167001670016700007000070000700
190b00000a7300a7210a7110a7150e7300e7210e7110e715117301172111711117151873018721187111871018715277001870018700187001870018700187001673016721167111671016715167001670000700
190b00000573005721057110571511730117211171111715167301672116711167151873018721187111871518700187001870018700187001870018700187001870018700187001870018700187001870018700
810b00001d1211f110221102411124110241102411024110241102411024110241112411024110241102411024110241102411024111241102411024110241102212122120221202211222112221150000000000
810b00003460000100001000c10024121241122411224100346000c10024121241122411224100001000c10024121241102411024110241122411224112251112612126110261102611026110261102611026110
810b000026110261102611026110261102611226112261122412124110241102411024110241122411224112181110c1110011100115001000010018100181000c1000c1001d1111d1101d1101f1111f1101f110
c10b0000000000f0000f0300f0210f0110f0151b0301b0211b0111b01513030130211301113015160301602116011160151600016000160001600016000160001600016000160001600016000000000000000000
c10b00000c0000c0000a0300a0210a0110a0150e0300e0210e0110e01511030110211101111015180301802118011180101801527700187001870018700187001870018700160301602116010160150000000000
c10b00000500005000050300502105011050151103011021110111101516030160211601116015180301802118011180151800018000180001800018000180001800018000180001800018000180001800018000
c10b00001d0001d0211f0202202024021240202401124010240102401024010240102401024010240102401024010240102401024010240102401024010240102401022021220202202022012220122201500000
c10b00001d0001d0001f000220001d0111f0102201024011240102401024010240102401024010240102401124010240102401024010240102401024010240112401024010240102401022011220102201022012
810b000024110221101f1101d11011111051110511505100001000010000100001000010000100001000010034600001000010000100001000010000100001003460028600001000010000100001000010000100
010b0000001001812124120221201f1201d1201111105111051150010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
c10b00000000000000180002400024010220101f0101d010110110501105015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
190b00000a7300a7210c0300c0210e7300e7210e0300e021117301172111030110211873018721180301802118715277001801518700187001870018700187001673016721160301602116715167001601500700
c10b0000340000000000000000000000000000000000c00024011240122401224000340000c00024011240122401224000000000c000240112401024010240102401224012240122501126011260102601026010
190b00000573005721050300502111730117211103011021167301672116030160211873018721180301802118700187001870018700187001870018700187001870018700187001870018700187001870018700
c10b00000000000000000000000026020260112601026010260102601226012260122401124010240102401024010240122401224012180110c0110001100015001000010018100181000c1000c1001d1111d110
810b00000573005720050300502011730117201103011020291312912129120291202912029120291202912027131271212712027120261312612126110261102611026110261102611024131241302412124120
810b00002412024120241202412024120241202412024120241202412024120241202412024120241202411124111241152710027100261002213122121221112413124121241202412024120241102411024115
010b002003740037310f0300f0211b7401b7311b0301b021137401373113030130211674016731160301602116010160151670016700167001670016700167001670016700167001670016700007000070000700
8d0b00001b2141b2101b2211b2201b2311b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2211b2201b2111b215
8d0b00002b2142b2102b2212b2202b2312b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2302b2212b2202b2112b215
8d0b00001a2141a2101a2211a2201a2311a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2301a2211a2201a2111a215
8d0b00002221422210222212222022231222302223022230222302223022230222302223022230222302223022230222302223022230222302223022230222302223022230222302223022221222202221122215
8d0b00002421424210242212422024231242302423024230242302423024230242302423024230242302423024230242302423024230242302423024230242302423024230242302423024221242202421124215
d52200001d2141d2101d2211d2201d2311d2301d2301d2301d2301d2301d2301d2301d2301d2301d2301d2301c2311c2301c2301c2301c2301c2301c2301c2301c2301c2301c2301c2301c2211c2201c2111c215
8d0b00002921429210292212922029231292302923029230292302923029230292302923029230292302923021231212302123021230212302123021230212302123021230212302123021221212202121121215
8d0b00001b2141b2101b2211b2201b2311b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2301b2211b2201b2111b215
2f0a00002466036670020240b03110051130611306013051130501304113040130311303013021130201302013011130101301500000000011300113001130011300113001130011300113001130011300113001
c115000018030180251c0301c0251f0301f025180301802521030210251c0301c025210302102523030230251703017025230302302524030240251803018025260302602524030240251f0301f0252803028025
c11500001c0301c025260302602524030240251803018025230302302521030210251c0301c02521030210251f0301f025180301802524030240252303023025170301702523030230251f0301f0251a0301a025
c115000013030130251c0301c0251f0301f025130301302521030210251c0301c025210302102523030230251703017025230302302524030240251303013025260302602524030240251f0301f0252803028025
c11500001c0301c025260302602524030240251303013025230302302521030210251c0301c02521030210251f0301f025130301302524030240252303023025170301702523030230251f0301f0251a0301a025
a11500000c0140c0100c0210c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0200c0110c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c0100c015
a11500001c0141c0101c0211c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0201c0111c0101c0101c0101c0101c0101c0101c0101c0101c0101c0101c0101c015
d11500000701407010070210702007031070300703007030070300703007030070210702007020070200702007020070200702007011070100701007010070100701007010070100701007010070100701007015
411500001771417710177211772017731177301773017730177301773017730177211772017720177201772017720177201772017720177201771117710177101771017710177101771017710177101771017715
490200002df340f010007030050300503135030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
c103000009730007000970009710097000070000700007002df2409710007002df14007000070000700007001a7111e711237112b0110d7010070000700007000070000700007000070000700007000070000700
d52200002421424210242212422024231242302423024230242302423024230242302423024230242302423023231222312123121230212302123021230212302123021230212302123021221212202121121215
310300003962436630336450060000600306242f6302d6452a600006002861425610236251c6001b600056001e6141c6101b610186101662013625006000860007600256000f6110e6000c6110b6000a61407625
d52200001a2141a2101a2211a2201a2311a2301a2411a2401a2401a2401a2401a2401a2401a2401a2311a23019241182411724116241152411524015240152401524015240152311523015221152201521115215
2f0a0000146610467013020130511306113061100410b0210401102011000110e0010e0010e0010e0010e0010e0010e0010e0010e0010e0010e00113001130011300113001130011300113001130011300113001
__music__
03 05060743
03 05064744
01 53141a44
00 52151b44
00 51161c44
00 175d1e44
00 141a5844
00 22182344
00 24192544
02 1f216244
01 28292a44
00 222b2c44
00 242c2d44
00 262c2f44
01 27282a68
00 222b2c44
00 242c2d44
02 262c2f44
03 3e3f0744
00 41424344
01 327f4344
00 33424344
00 34383944
02 35424344
03 05460644
04 2e3c3e13
04 2e3c3e44
03 04424344
04 01420244
00 133c3e2e
03 0a424344
01 05440644
00 06441144
00 05440644
00 06441144
00 05440644
00 06441144
02 05441144
00 41424344
00 41424344
01 12060543
02 07051143
__label__
44444499494499999999affffffffffffffffffffffffffffffffffffffffffffff6666666666633333333333333333333333a99999944444999994999444999
44444499444499999999a77777fffffffffffffffffffffffffffffffffffffffff6666666666633333333333333333333333a9999994994a999994999444999
4444444444449999999997777777777f77ff7fffffffffffffffffffffff66666666666666666633333333333333333333333a99999949949999994999444444
999444999994999999999fffffffffffffffffffffffffffffffffffffff66666666666666666333533333333333333333333a99999944449999994444444444
999444999994999999999aaaafffffffffffffffffffffffffffffffffff66666666666666666333333333333533333333333a99999999949994444949999444
999444999994999999999999afffffffffffffffffffffffffffffffffff66666666666666666333333333333333333333333999999999949994444449999444
994444999994999999999999afffffffffffffffffffffffffffffffffff666666666666666663333333333333333333aaaa9aaaa99999949994999949999444
994444999994999999999999a99aa7ffffffffffffffffffffffffffffff666666666666666663333553333333333333a9999a99994444444444999949999444
994444999994444444449999999aaaffffffffffffffffffffffffffffffff6666666666666663333553333333333333a9999a999a9944499994999944444444
994444999994444449949999a99aaafffffffffffffffffffffffffffffffff666666666666663333333773333333333a9999a99999944499994444444444444
444444444444499949949999a99999ffffffffffffffffffffffffff7777777666666666666663333337777333333333a9999a99999944499994449444444444
499449999499499944449999999aa9fffffffffffffffffff7f77777777777766666666666666333333797f333333333a9999444499944499994444444499999
499449999499499944449999999aa9fffffffffffffffffffffffffffffffff66666666666666355535777f3337aaaa9a999aaa9444444444444999444499999
444449999499499949449999a99999fffffffffffffffffffffffffffffffff6666666666666635353377ff333a99999a999a99944a999999494999444499999
444449999499444444449999999999ffffffffffffffffffffffffffffffff6666666666666663555337fff333a9999944449999449999999444999444499999
444444444499449999949999999999ffffffffffffffffffffffffffffffff66666666666666333333339933339994494aaa9999449999999444444444499999
944444444499449999949999999999ffffffffffffffffffffffffffffffff6666666666666633333377a7aaa99994494a999444449999999444444444499999
444444444444449999944444499999999a99aaaaaffffffffffffffffffff666666666666666333333799999999999994a999494449944999444999994444444
4449999999999499999499494999999999999999affffffffffffffffffff666666666666ddd333333799999999944444a999444449944999994999994444444
44499999999994999994994449999999aa999999affffffffffffffffffff66666666666ddd3333333799999999949994a9994a9999999999994999994444444
44499999999994444444444449999999aa999999affffffffffffffffffff66666666666dddbb33333a999999999499949999499999944499994999994444444
4449999994449444499999994444999999999999affffffffffffff66666666666666666dddb3333337999999999499949999499999949499994999994444444
44444499949494994944999944449999999999999fffffffffffffff6f6f66666666666ddddb3333337999999999444444444499999944444444999994494444
4444449994449499494499994994949999999999afffffffffffffff666f66666666666ddddb333333a99999999947aaaa944499999949999994444444444444
44444499999994444999999949949999999999999fffffffffffffff6fff6666666666ddddd333333379999999994a9999944499999949999994444444444444
44444444444444444944499949944449999999999fffffffffffffff6ff66666666666dddddb333333a9999999994a9999944444444449999994444444444444
4444444499499aa74944499944444449449499999fffffffffffffff6ff66666666666ddddd3333333a9999999994a9999aaa999999444444444444444444444
444444449949999a494449494999aa49449999999fffffffffffffff6f66666666666dddd333333333a9999999994a9999a99999999444999944444442224444
444444444449999a4999999949999a49999999999fffffffffffffff666666666666ddddd333333333a9999999994a9999a99999999494999944444442224444
44444444444999994444999949499944444444449fffffffffffffff666666666666ddd3d333333333a9999999994a9999999494449444999949944442224224
4444444444444444444499994999994949999999999aaafffffffff6666666666666dddddd33333333a9999999994a9999999994449444999949944444444224
444444444449999949949999494499444999999999999afffffffff666666666666dddd33d33333333a999944999499999999994449444444444444444444444
444444444449999949944444494499444999999949449affffffff6666666666666dddd33d33333333a994944999444444999999999444444442442222222222
444444444449999949999944499999499999999999449afffffff66666666666666ddddd33333333339999999999444994997aa9999999444444442222244422
444444449449999949999944444444499999999999999afffff6666666666666666ddddd3bb3333333a9999a999994499444a999999999422444442222244422
444444444449449944444444444499aa7a77999999999afffff6666666666666666ddddd3b33333333999999999994444444a999999999422444442444244422
44444444444944994449999944449999999a999999999a997777777777777777777dbb333b33333333999999999994aa99449999999999422442222444244422
44411444444999994949999944449999999a999999999a49ccc7ccc7c77c77cc7ccdb3333333333333999444999994a999449999999999444442222444222222
44411444444222224449999949949999999949999999994977cc7cc7ccccc7ccccddb3533b333333339994449944949999444444444444444442222222222222
444444444442222244499949499499999999499999999a9aaaaacccc7ccc7cc77cddb33333333333359994449944949499442222222222222222211221222222
111111111111111114499999444499999999499999999a29999acccc7ccccc7ccdddb33333333333355599999999949999442944444444444422211222222222
2222222222211112144444444444444444444999999999999999cc7ccccccccccdddd3333333b333b35522244444449999442444499444444422222222222222
222222111111112212224444444499499999499999999a9999997ccc7ccc7ccccdddb33333bbb333355522244444244444442444499424444411111111111111
2222111111111122122222222442222999994999999999999999cccccccccc7cdddd33333bb3b333599999922224444442442444444444444421111111122222
2222111111112222122222222442222222224222222224999999cc7cccccccccdddd3333b3b33335599999922222222244442444444444444422211111122222
2222111111122222121112112442112422444444999444999999cccccccc7cccdddd3333b3b3335aa99999944442444222222444444444444422222111112222
2222111111222222121112112442112444444444999444444444cccccccccc7cddddbb3b3333355a999999944442444221122222222211222222222211112222
2222111122222221121112222222222444444444444499944449cccc7cccccccddddb33b33b359999999aaa99442222221122112122211222222242221112222
222212222222221112222222222222249944444449aaa7944449c7cccc7cccccdddd333b333559994444a9999444441122222112222211111222222222222222
222222222222211111111111111124449949999949999a944444ccccccccccccdddb333b337a99994444a9999444441111111111111111211112244222244222
222222222222111111111211222124449949999949999a44499aacccccccccccddd3333335a999aaa94499999499441111112222221111111111144222244222
222222222222111111111212221122249949444949999a444999acccccccccccddd3333b35a999a9994499999499444111111222222211111111114442222222
222222442221111111111222211122249949444949999a4449999ccccc7cccddddbb3355559999a9994444444444444441221112222222222111111444224222
222222442211111111112222111122244449444949999a4449999cccccccc66dddb3377a99944499994494499944444141221111112222222211111444222222
2242224422111111111122211111111222499999499999444444ccc7ccccd6ddddb3579999944944444444499944444444111111111122222221111144424222
222224444111111111122211121111111244494949999a444499ccccccccdddd6db35a999994444aa99994499944444444444112111211122222111144424222
2242244941111111114421111211111112444999499999244499ccccccccddddddb35a9999947a9a999994444444444444144444221112212222211124424222
2242244a411111111444411112211111122444444444222444997ccccccddddddb335a999994a999999994494444444444444422422212211442222124424222
2242244a41111114494411111122111111222442242444444444cccccccd66dd3b335a999994a999999994444449999444444422422221111544422224442222
2242244a4111114994211111121211112122244224411144444cccccccdd6d333333599999949999944444444449999444444444422222211554442224442222
2242244a41111494412111111212211121222222222121222d6cccccc66d6d333333399999949999944944444449999449944444422222222555944224442222
2222444a41444944112111112211211221ff11111111111ddd6ccc7cd6dd6d3337aaa99444449999944444994949999449949444444422222555594424442222
2242444a4149944111221112211222221fff71112211221ddddcccccdddd6d363a9999944444999994a994994449999444444422222422222255559444442222
222244494444421111221122112112211ff97122211221ddd66cccc66d6d6d333a99aaa994944444449994444449999444222422222422442255559444442222
222244494444222111441221142112111ff7714dddd4ddddd66cccc6dddd3d333a99a99994444444449994444444444444222422222422442255555944442222
222244494442dd44dd4422ddd4ddd4dddf7774dddd44ddddddddccc6dddd33333a99a999944aaa99944444444444444424222444444422222255555944442222
24224449942d33444d442ddd44ddd4dddf777dddd4ddd666d6ddccc6dd66333b3a999999944a999a999999424444222444444424444422222255555a44442222
22224444942d332d4444ddd44dddd4dddd994ddd4dddd6d6ddd66cc6dd6633333a99999444499999999999444444222422444444444422999445555944422422
24224444942ddd2dd494d444ddddd4dd44444444ddddd666d66d6c666ddd333bba99999499499999999999499444222422422222222222944445555a44422422
24224444942ddd2dd444444dddddd4944ddddddddddddddddd6d6c6ddd6d3ab33a99999499444449999999499444444444424442422222944445555a44422422
2422444494233d2dd2444ddddddd994ddddddddddddddddddd6d6d6d33d33b333a99999444422244444444444444494422224442222222944445555a44442422
2422444993223d22d249d33ddddd94dddddddddd3dddd333dd6d6ddd333bb3333a99449449422249944244442244444424424442222222444445555a44442422
2422444993323d22d249d33d3ddd44ddddd333ddddd3d333dd6ddddd333b33535a99449444422249944444442242222224422222442222444445555a44442422
2422444994322d22d249dddddddd44ddd3d3d3ddddddd333ddd33d33373b33335999999444444444444222444442222422221122442122215555559999442421
2222444999432223324993dd33d444ddddd333d33df6ddddd3d33d3d3733335555444444222422222222422222222222222211222222221155555a4444442221
24224444994431333249933d3344433d33ddddd33d666ddddddddd333bbbbbb53544444424242222222222221111111111122222111111555555594444442221
22224444993441333244993d99944d3d33d3dddddd66d5dd3333333bbb3b33555555522222241111111111111222211111111111111111555555594444424221
2224444499334493324449999444333dddddd3333366d5333333333b3b3333533555555511141121112121111222211111111111111115555555594444424221
22244444493334443222499444ffffffffff7ff777d6d577777f7ffb3b3b33533555555551199122112121111222211111111111111155533355594a44424221
2224224499333149222244443bb777c777cc77cc77dd577ccc77777b3b3333555555555555599111112221111242211111111115555155535355594944424221
2224224449333314211244333b3bccf7cc77cc7ccc7557cc77c7ccbb3b35355555555555bb545111111241111242211111111155555155533355594944424221
2424444499333314211244333333bccc7ccc7cc7cc757cc7cccccb333b333555bb55555533225551111141122244212115151555555555555555594944424221
2224444999333331221243333b333bccc7cc7cc7c7c7c7c7c7ccbb3b33335555b35555bb33225555551114442244212525252555555555553355594944424221
2424444a9933333122224333333bbbbbc7ccc7c7c7c7c7c7c7cb3b3b3bb35555b35575b333545555555555944444212525222555555555553355594944424221
2424444a9933333122244333333b333bccccc7c7c7ccc7c7cccb333b3bb35335335575b33354555555555559442422252222555555fff6555555594944422211
2424444a99333331122443333333bbb3bcc7cfc7ccc7c7cfccbb3b3333335335b355bbb33355533355555555942442222255555557666d555555594944422211
2424444999331331124943333333b3b3bccccfcfc7c7ccccccb33b3b333355553355b3b3355353535555555594244222255555555f666d555555594442222211
2424444499933331124943333333bbb3bcccccc7cccfccc7ccb333333b35555533bb33333555533353555555a4244222555555555666dd555555594449444211
24214444949311311249433333333333bccccfcfccccc7cccc333b3333355555bbb33353555555555555555599444225555533555d2221555559444444444211
242144444449113112499331133333bbbccccccfcccfccc7ccb333333335bbbbb3b333535555555555553355a94242255555335556666d515554444222222211
422114444444933112449131133333b3bcccccccccccccc7ccb333335535b333b3b355555533535555553355a94242255335555556666d555442222944222211
422114422424911112449333333333b3bcfccccfcccccccccc33333355353333b33355535533555555555555a94242255335155356666d554494442444222111
22221112244444911124911113333333bccccccccfccfcccccbbb3333335335333b335535555555555555555994442425555555556ee6d114244442222211131
111221111292224491244113131333b3bccc7ccfccccccccfcb3b33735553333333335555555515555555559994442222555555116ee6d444222222111111111
11111113112221114114441113333333bcccccfffcccfcccccbbb37775553555333535535555555555555594442442442221111116666d111111111111133333
11111111111113311111111111bb33b3bcc7cccfccccfccccc333337355535353333355555555111151554449992224422211511ff6ddd333333333333333333
33333333333333333b3bbbb3b33b13b3bc777cccc7ccccccccb3335535553555553555555555511515554494444922222222111f666d5553333333333dd33d33
333333333333333333333333333b13b33cc7cccfcccccccccc333355355555333555555335551111111924442244221111111116dddd5153333d3ddd3dd33333
33b3bbbbbbbbb335555533b3bb3b1113bcccccccc77ccccfcc777333353555353535555335111bbbbbb444222224113333333336dddd555333333ddd33333355
333333333333b33553353333bb3b13133c77cc77777777ccc77777555555553335555555551bb33333bbbbbbb333333333333336ddd55111dddd33333d335555
333333333bb33335533533333333111137777f77777777cc777777755f33555555551111111b333bb33333333333533333333366d555511111ddddd333335555
3333bbb33bbbbbb555555533333b3bbb7777fff777777fff77777775fff3553555151511bbb33b3bb333333333333335555dddddd5551111111111dddd555115
3333bbb3333333b555553533333333333bb77f777777ffff777777755f555555555511133333333333333533355355553576666ddddddddddddddddd55515115
33333333bbbbb3b555555535553333bb33b77777777ffffff77777555555555111111113bbbb33333333333335535555556dddd666666666dd55dd5d51155555
33333333bbb3b3b333333335553333bb333bbbb7777fffffff7777f7ffff7777f7ffffb3bbbb333333333333333357ddddddddd6dddddddddd55dddd51151111
3533553333bbb3b3bbbbbb35553533333b333337777fffffff77ccccfccffcfffffbbbb3333333333333355535555ddddddddddddddddddddddddd5555551155
333355333333333333333b33333333333333333bbbb33bbffcccccccccccccccbbbb33333333333335553555355666666dddddddddddd555d555555151111155
55533333553533b33bbb3b3bbbbb333333333333333333bfcfccffcff77ffccbb3333bb333335535353535553556ddddddddddd55dd5d555d555555551155155
55555553553333333bbb3b33333b33553333333bb3b3333bbbcccccccccccbb3333b3bb35333553335553333355dddddddddd5d55dddddddd5dd511151155111
53335553333555533bbb333bb33b33553555333bb333333555cccfffc7ccc555333333333333333555555555555ddd5d55dddddddd5555ddd5dd511151111111
535353555555335333333b3bb33b3333353555333335555555fcccccccccf55555555555555555555555556666666ddd55d55555555dd5555555511151111111
533355555555335555333333333bbbbbb55555555555555f6f71111111117f6f6666666666555555555666dddd55555dddd5d555dd5dd5d51511555551115111
55555553355555535555553333333555b5776f6ff666f6ffcccccccccccccccccccccccccc66ff6f666ccc676755555555555555555555555511515111111111
55555553355555555555555555555555576ccccccccccccccccc11111111111111111111ccccccccccc11ccccc77767666666666666666666655555111111111
5555555555555556666666666666767776cc11111111111111111111111111111111111111111111111111111ccccccccccccccccccccccccc66666666666661
6666666666666666cccccccccccccccccccccccccc1cc11c111c11cc1cccccccccccccccccccc1cc1c1111111111111111111111111111ccccccc1c111111111
cccccccccccccccccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111dddd1111111111111111111
111111111111111111111c1ccccccccccc1cc1c1111111111111111111111111111111111111111111111111111111111111111d1ddddd1dd111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111ddddd111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111c11cc1ccccccccccccccccccccccccccccccccc1cc11c11111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112211111111111111111111
cccccccccccccccccccccccccccccc1cc11c11111111111111111111111111111111111111111111111111111111111111111111212211111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111dd1d111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__meta:title__
beam--
by rupees
