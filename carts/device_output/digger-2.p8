pico-8 cartridge // http://www.pico-8.com
version 39
__lua__

-- digger 1.1
-- by paranoid cactus
cartdata("digger")
left, right, up, down = 0, 1, 2, 3

function _init()
  -- screen palette
  bonuspal = split "130,133,136,139,137,4,15,7,142,9,135,138,14,13,10,135"
  normalpal = split "0,1,132,3,4,5,6,7,8,9,10,11,12,140,143,15"
  scrpal = normalpal
  titles = split "nobbin,10,4,hobbin,26,4,digger,0,5,gold,49,1,emerald,48,1,bonus,14,1"
  titlecols = split "9,10,7,10,9,8,8"
  tileft = 38
  tracki = -1
  trackm = 0
  musicon = peek(0x5e00) == 0
  readscoreboard()
  menu = {{str = "new game", f = newgame}, {str = musicon and "music on" or "music off", f = function()
    musicon = not musicon
    poke(0x5e00, musicon and 0 or 1)
    menu[2].str = musicon and "music on" or "music off"
    menuitem(1, musicon and "music: on" or "music: off", menu[2].f)
    if musicon then
      playmusic(tracki, trackm)
    else
      music(-1)
    end
  end}}
  menuitem(1, musicon and "music: on" or "music: off", menu[2].f)
  menusel = 1
  -- retain palette after exit
  poke(0x5f2e, 1)
  -- prevent button repeats
  poke(0x5f5c, 255)
  -- font
  poke(0x5600, unpack(split "6,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,2,3,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,7,7,0,0,0,0,7,7,7,0,0,0,0,0,7,5,7,0,0,0,0,0,5,2,5,0,0,0,0,0,5,0,5,0,0,0,0,0,5,5,5,0,0,0,0,4,6,7,6,4,0,0,0,1,3,7,3,1,0,0,0,7,1,1,1,0,0,0,0,0,4,4,4,7,0,0,0,5,7,2,7,2,0,0,0,0,0,6,6,0,0,0,0,0,0,0,1,2,0,0,0,0,0,0,3,3,0,0,0,10,10,0,0,0,0,0,0,2,5,2,0,0,0,0,0,0,0,0,0,0,0,0,0,6,6,6,0,6,6,0,0,10,10,0,0,0,0,0,0,0,10,31,10,31,10,0,0,4,31,7,28,31,4,0,0,19,27,12,6,27,25,0,0,14,10,6,27,11,23,0,0,6,6,2,0,0,0,0,0,12,6,6,6,6,12,0,0,6,12,12,12,12,6,0,0,21,14,31,14,21,0,0,0,0,4,14,4,0,0,0,0,0,0,0,0,6,6,2,0,0,0,14,0,0,0,0,0,0,0,0,0,6,6,0,0,12,12,6,6,3,3,0,0,31,17,17,25,25,31,0,0,6,4,4,6,6,6,0,0,30,16,31,3,3,31,0,0,14,8,30,24,24,31,0,0,17,17,17,31,24,24,0,0,15,1,31,24,24,31,0,0,15,1,31,25,25,31,0,0,31,16,16,24,24,24,0,0,14,10,31,25,25,31,0,0,31,25,25,31,24,24,0,0,0,6,6,0,6,6,0,0,0,6,6,0,6,6,2,0,4,2,1,2,4,0,0,0,0,0,14,0,14,0,0,0,1,2,4,2,1,0,0,0,31,24,30,0,6,6,0,0,31,17,29,13,1,31,0,0,0,30,16,31,25,31,0,0,1,31,17,25,25,31,0,0,0,31,1,3,3,31,0,0,16,31,17,25,25,31,0,0,0,31,17,31,3,31,0,0,31,17,7,3,3,3,0,0,0,31,17,25,25,31,24,30,1,31,17,25,25,25,0,0,12,0,8,12,12,12,0,0,12,0,8,12,12,12,14,0,1,9,15,25,25,25,0,0,6,6,6,6,6,14,0,0,0,31,23,21,21,17,0,0,0,31,17,19,19,19,0,0,0,31,17,25,25,31,0,0,0,31,17,25,25,31,1,0,0,31,17,25,25,31,24,0,0,31,17,3,3,3,0,0,0,15,1,31,24,31,0,0,2,14,2,6,6,30,0,0,0,17,17,25,25,31,0,0,0,17,17,25,26,28,0,0,0,21,21,21,29,31,0,0,0,25,25,14,25,25,0,0,0,17,17,25,25,31,24,30,0,30,16,31,3,31,0,0,14,6,6,6,6,14,0,0,3,3,6,6,12,12,0,0,14,12,12,12,12,14,0,0,2,5,0,0,0,0,0,0,0,0,0,0,0,31,0,0,2,4,0,0,0,0,0,0,14,10,31,25,25,25,0,0,15,9,31,25,25,31,0,0,31,17,1,3,19,31,0,0,7,9,17,19,19,31,0,0,15,1,7,3,3,31,0,0,31,1,7,3,3,3,0,0,31,17,1,27,19,31,0,0,17,17,31,25,25,25,0,0,8,8,8,12,12,12,0,0,28,16,16,24,25,31,0,0,9,9,31,19,19,19,0,0,1,1,1,3,19,31,0,0,31,23,21,21,21,17,0,0,31,17,17,19,19,19,0,0,31,17,17,25,25,31,0,0,31,17,17,31,3,3,0,0,31,17,17,25,25,31,24,0,31,17,17,31,11,27,0,0,15,1,31,24,24,31,0,0,31,4,4,6,6,6,0,0,17,17,17,25,25,31,0,0,17,17,17,25,26,28,0,0,21,21,21,21,29,31,0,0,17,17,14,25,25,25,0,0,17,17,31,24,24,30,0,0,30,16,31,3,3,31,0,0,14,6,3,3,6,14,0,0,4,4,4,4,4,4,0,0,14,12,24,24,12,14,0,0,0,0,22,13,0,0,0,0,0,2,5,2,0,0,0,0"))
  -- always use custom font
  poke(0x5f58, 0x81)
  showtitle()
end

function playmusic(i, m)
  if i ~= 0 and i ~= 22 then
    tracki = i
  else
    tracki = -1
  end
  trackm = m and m or 0
  if i == -1 then
    music(i, 1500)
  elseif musicon then
    music(i, 0, trackm)
  end
end

function readscoreboard()
  local addr = 0x5e01
  scoreboard = {}
  for i = 0, 9 do
    local name = ""
    name, addr = readname(addr)
    add(scoreboard, {name = name, hi = peek4(addr), lo = peek4(addr + 4)})
    addr = addr + (8)
  end
  prevname = readname(addr)
end

function readname(addr)
  local name = ""
  for j = 0, 2 do
    local c = peek(addr)
    name = name .. chr(c < 16 and 97 or c)
    addr = addr + (1)
  end
  return name, addr
end

function writescoreboard()
  local addr = 0x5e01
  for i = 1, 10 do
    local s = scoreboard[i]
    addr = writename(s.name, addr)
    poke4(addr, s.hi)
    poke4(addr + 4, s.lo)
    addr = addr + (8)
  end
  writename(prevname, addr)
end

function writename(name, addr)
  for j = 0, 2 do
    poke(addr, ord(sub(name, j + 1, j + 1)))
    addr = addr + (1)
  end
  return addr
end

function showtitle()
  titleitems, titletime, ti, tinext, update, draw = {}, 0, 0, 0, updatemenu, drawmenu
end

function _update60()
  update()
end

function _draw()
  draw()
  poke(0x5f10, unpack(scrpal))
end

function updatemenu()
  if titletime == tinext and ti < 6 then
    local i, chara = ti * 3 + 1, #titleitems < 3
    tinext = titletime + 60
    if chara then
      tinext = tinext + (#titleitems == 2 and 140 or 70)
    end
    add(titleitems, {str = titles[i], s = titles[i + 1], smax = titles[i + 2], x = chara and 128 or tileft, y = #titleitems * 12 + 34, f = 0, ft = 5, sb = chara and 0 or 0.5, c = #titlecols})
    ti = ti + (1)
  end
  for t in all(titleitems) do
    t.ft = t.ft - (1)
    if t.ft == 0 then
      t.f = (t.f + 1) % t.smax
      t.ft = 5
    end
    if t.x <= tileft then
      t.sb = max(0, t.sb - 0.025)
      if t.sb == 0 then
        t.c = max(1, t.c - 0.5)
      end
    else
      t.x = t.x - (0.5)
    end
  end
  titletime = titletime + (1)
  if titletime >= 1200 then
    titletime, titleitems, ti, tinext = 0, {}, 0, 0
  end
  if btnp(0) or btnp(2) then
    menusel = (menusel + #menu - 2) % #menu + 1
    sfx(49)
  end
  if btnp(1) or btnp(3) then
    menusel = menusel % #menu + 1
    sfx(49)
  end
  if btnp(4) or btnp(5) then
    menu[menusel].f()
    sfx(48)
  end
end

function drawmenu()
  cls()
  sspr(0, 32, 76, 19, 26, 5)
  if titletime < 800 then
    for t in all(titleitems) do
      spr(t.s + t.f, t.x, t.y + sin(t.sb) * 4)
      if t.x == tileft and t.sb == 0 then
        printf(t.str, t.x + 14, t.y + 1, titlecols[t.c // 1])
      end
    end
  else
    for i = 1, #scoreboard do
      local s = scoreboard[i]
      print(s.name, 26, 21 + i * 8, 8)
      printscr(s.hi, s.lo, 49, 21 + i * 8)
    end
  end
  for i = 1, #menu do
    local m = menu[i]
    rectfill(-53 + i * 59, 112, 3 + i * 59, 121, i == menusel and 3 or 1)
    print(m.str, -24 + i * 59 - #m.str * 3, 114, i == menusel and 7 or 13)
  end
  scrpal = normalpal
end

function updatescores()
  if btnp(0) then
    namechri = max(namechri - 1, 1)
    sfx(49)
  end
  if btnp(1) then
    namechri = min(namechri + 1, 3)
    sfx(49)
  end
  local namechrs = {97, 97, 97}
  for i = 1, 3 do
    namechrs[i] = ord(sub(scoreboard[newscorei].name, i, i))
  end
  if btnp(2) then
    namechrs[namechri] = namechrs[namechri] - (1)
    if namechrs[namechri] == 96 then
      namechrs[namechri] = 122
    end
    sfx(49)
  end
  if btnp(3) then
    namechrs[namechri] = namechrs[namechri] + (1)
    if namechrs[namechri] == 123 then
      namechrs[namechri] = 97
    end
    sfx(49)
  end
  prevname = ""
  for i = 1, 3 do
    prevname = prevname .. chr(namechrs[i])
  end
  scoreboard[newscorei].name = prevname
  if btnp(4) or btnp(5) then
    namechri = namechri + (1)
    if namechri == 4 then
      writescoreboard()
      sfx(48)
      update, draw = updatemenu, drawmenu
    end
  end
end

function drawscores()
  cls()
  printf("new high score", 22, 11, 8)
  for i = 1, #scoreboard do
    local s = scoreboard[i]
    print(s.name, 26, 21 + i * 8, 8)
    printscr(s.hi, s.lo, 49, 21 + i * 8)
  end
  local ns = scoreboard[newscorei]
  for i = 1, 3 do
    printf(sub(ns.name, i, i), 20 + i * 6, 21 + newscorei * 8, i == namechri and 7 or 9)
  end
  printscr(ns.hi, ns.lo, 49, 21 + newscorei * 8)
end

function checkscore()
  newscorei = #scoreboard + 1
  for i = 1, #scoreboard do
    local s = scoreboard[i]
    if s.hi <= scorehi then
      if s.lo <= scorelo then
        newscorei = i
        break
      end
    end
  end
  if newscorei <= #scoreboard then
    if newscorei < #scoreboard then
      for i = #scoreboard, newscorei + 1, -1 do
        scoreboard[i] = scoreboard[i - 1]
      end
    end
    scoreboard[newscorei] = {name = prevname, hi = scorehi, lo = scorelo}
    namechri, update, draw = 1, updatescores, drawscores
  else
    update, draw = updatemenu, drawmenu
  end
end

function updategame()
  if wint then
    wint = wint - (1)
    if wint <= 0 then
      -- end level
      level = level + (1)
      initlevel(level)
    end
  else
    -- increment player animation frame
    player.ft = player.ft - (1)
    if player.ft <= 0 then
      player.f = (player.f + 1) % 5
      player.ft = 5
    end
    bugsdelay = max(0, bugsdelay - 1)
    if bugsdelay == 0 then
      -- spawn bugs
      if bugscreated < bugstotal and #bugs < maxbugs and (not bonus and bonustime == 0) then
        add(bugs, {x = 120, y = 32, f = 0, ft = 5, dir = left, type = 0, stuck = 0, delay = 60, start = true})
        bugsdelay = max(8, 120 - level * 2)
        bugscreated = bugscreated + (1)
      end
      if bonusready and bugscreated == bugstotal and bugsdelay == 0 then
        bonus, bonusready, bonusscore = {x = 116, y = 28}, false, 200
        bugstotal = bugstotal + (1)
      end
    end
    for bug in all(bugs) do
      -- animate bug
      bug.ft = bug.ft - (1)
      if bug.ft <= 0 then
        bug.f = (bug.f + 1) % 4
        bug.ft = 6
      end
      bug.delay = max(bug.delay - 1, 0)
      if bug.delay == 0 and not dying then
        bug.start = false
        -- check for direction change when grid aligned
        if bug.dircheck and bug.x % 8 == 0 and bug.y % 8 == 0 then
          -- check if advancing bug should change back to normal
          if bug.stuck > (30 + level * 2) and bug.type == 1 then
            bug.stuck, bug.type = 0, 0
          end
          -- find best move dir
          local dirs = {left, up, down, right}
          if player.x > bug.x then
            dirs[1], dirs[4] = dirs[4], dirs[1]
          end
          if player.y > bug.y then
            dirs[2], dirs[3] = dirs[3], dirs[2]
          end
          if abs(player.y - bug.y) > abs(player.x - bug.x) then
            dirs[1], dirs[4], dirs[2], dirs[3] = dirs[2], dirs[3], dirs[1], dirs[4]
          end
          -- backtrack direction
          local revdir = (bug.dir + 1) % 2
          revdir = bug.dir > 1 and revdir + 2 or revdir
          -- invert dir if in bonus mode
          if bonustime > 0 then
            dirs[1], dirs[4], dirs[2], dirs[3] = dirs[4], dirs[1], dirs[3], dirs[2]
          else
            -- make backtracking last choice unless player had bonus
            add(dirs, del(dirs, revdir))
          end
          -- add randomness to movement
          if bug.type == 0 and rnd(5 + min(level, 10)) // 1 == 1 and level < 6 then
            dirs[1], dirs[3] = dirs[3], dirs[1]
          end
          -- make sure bug can't go off screen
          if bug.x == 8 then
            del(dirs, left)
          elseif bug.x == 120 then
            del(dirs, right)
          end
          if bug.y == 32 then
            del(dirs, up)
          elseif bug.y == 104 then
            del(dirs, down)
          end
          local prevdir = bug.dir
          if bug.type == 1 then
            -- advancing bug always goes best direction and digs path
            bug.dir = dirs[1]
          else
            for i = 1, 4 do
              -- check dir for clear path
              local dir = dirs[i]
              local cx, cy = dir < up and dir * 2 - 1 or 0, dir > right and (dir - 2) * 2 - 1 or 0
              if not issolid(bug.x + cx * 5, bug.y + cy * 5) then
                bug.dir = dir
                break
              end
            end
          end
          -- if changing direction
          if bug.dir ~= prevdir then
            -- flip sprite if needed
            if bug.dir < 2 then
              bug.flip = bug.dir == 1
            end
            bug.delay = bug.delay + (2)
            if bug.dir == revdir then
              bug.stuck = bug.stuck + (1)
            end
          end
          -- prevent direction check after delay
          bug.dircheck = nil
          for bug2 in all(bugs) do
            if bug.x < bug2.x + 6 and bug.x + 6 > bug2.x and bug.y < bug2.y + 6 and bug.y + 6 > bug2.y then
              bug.stuck = bug.stuck + (1)
            end
          end
          if bug.type == 0 and bug.stuck > 60 - level * 2 then
            bug.type, bug.stuck, bug.spd = 1, 0, 0.25
          elseif bug.type == 1 and bug.stuck > 60 - level * 3 then
            bug.type, bug.stuck = 0, 0
          end
        end
        if bug.delay == 0 then
          local cx, cy = bug.dir < up and bug.dir * 2 - 1 or 0, bug.dir > right and (bug.dir - 2) * 2 - 1 or 0
          bug.x = bug.x + (cx * 0.25)
          bug.y = bug.y + (cy * 0.25)
          if bug.type == 0 and not (bug.x % 8 == 0 and bug.y % 8 == 0) and max(0, rnd(15 - level) // 1) == 0 then
            bug.x = bug.x + (cx * 0.25)
            bug.y = bug.y + (cy * 0.25)
          end
          bug.dircheck = true
        end
      end
      local died
      if bullet then
        if bug.x + 3 > bullet.x and bug.x - 3 < bullet.x and bug.y + 3 > bullet.y and bug.y - 3 < bullet.y then
          killbug(bug)
          addscore(250)
          bullet, died = nil, true
        end
      end
      if not dying and not died and not bug.start and bug.x < player.x + 7 and bug.x + 7 > player.x and bug.y < player.y + 7 and bug.y + 7 > player.y then
        if bonustime > 0 then
          killbug(bug)
          addscore(bonusscore)
          bonusscore = bonusscore * (2)
        else
          killplayer()
        end
      end
    end
    local vx = 0
    local vy = 0
    if dying then
      dying = dying - (1)
      if dying == 450 then
        playmusic(0)
      end
      if dying == 0 or (dying < 400 and btnp(3) or btnp(4)) then
        dying = nil
        lives = lives - (1)
        if lives == 0 then
          checkscore()
        else
          resetlevel()
        end
      end
    else
      -- check if player is grid aligned
      local ox, oy = player.x % 8, player.y % 8
      -- check for button presses
      vx = btn(0) and -0.5 or (btn(1) and 0.5 or 0)
      vy = btn(2) and -0.5 or (btn(3) and 0.5 or 0)
      -- calculate movement direction
      if vy ~= 0 then
        -- slide left or right until grid aligned
        if ox ~= 0 then
          vy = 0
          if vx == 0 then
            vx = ox < 4.5 and -0.5 or 0.5
          end
        else
          vx = 0
        end
      elseif vx ~= 0 then
        -- slide up or down until grid aligned
        if oy ~= 0 then
          vx = 0
          if vy == 0 then
            vy = oy < 4.5 and -0.5 or 0.5
          end
        else
          vy = 0
        end
      end
      -- calculate facing direction
      player.dir = vy < 0 and up or (vy > 0 and down or (vx < 0 and left or (vx > 0 and right or player.dir)))
      -- shoot
      shootdelay = max(shootdelay - 1, 0)
      if (btnp(4) or btnp(5)) and shootdelay == 0 then
        local cx, cy = player.dir < up and player.dir * 2 - 1 or 0, player.dir > right and (player.dir - 2) * 2 - 1 or 0
        bullet, shootdelay = {x = player.x - 2 + cx * 4, y = player.y + cy * 4, vx = cx, vy = cy}, 480
        sfx(52)
      end
    end
    -- gem bonus timer
    gemt = max(0, gemt - 1)
    if gemt == 0 then
      gemc = 0
    end
    if bullet then
      bullet.x = bullet.x + (bullet.vx)
      bullet.y = bullet.y + (bullet.vy)
      if issolid(flr(bullet.x), flr(bullet.y)) then
        add(flashes, {x = bullet.x, y = bullet.y, t = 40, ft = 10})
        bullet = nil
      end
    end
    for b in all(bags) do
      -- check if bugs collide with bag
      for bug in all(bugs) do
        if bug.x + 3 > b.x and bug.x - 5 < b.x + 7 and bug.y + 3 > b.y and bug.y - 6 < b.y then
          if b.falling then
            -- kill bug if bag falls on it
            addscore(250)
            killbug(bug)
          elseif not b.money then
            -- break bag if bug runs through it
            b.money = 0
            sfx(53)
          end
        end
      end
      local pushed, playerhit = false, player.x + 3 > b.x and player.x - 5 < b.x + 7 and player.y + 3 > b.y and player.y - 3 < b.y + 7
      -- if player hit the bag
      if playerhit and not dying then
        if b.falling then
          -- if player was under falling bag
          if b.falling == 0 and b.y < player.y - 4 and b.x > player.x - 11 and b.x < player.x then
            -- do player death
            killplayer()
          end
        elseif b.money then
          -- it's money so give player score and delete money
          del(bags, b)
          sfx(55)
          addscore(500)
        elseif vx ~= 0 and ((player.dir == 1 and player.x + 2 < b.x) or (player.dir == 0 and player.x - 2 > b.x + 9)) then
          -- push bag
          pushed = true
          local blocked = false
          -- collide with other bags
          for b2 in all(bags) do
            if b2 ~= b and not b2.falling and not b2.money and b2.x + 8.5 > b.x and b2.x < b.x + 8.5 and b2.y + 7 > b.y and b2.y < b.y + 7 then
              -- collide with world
              b2.x = mid(b2.x + vx, 3, 115)
              if b2.x == 3 or b2.x == 115 then
                vx = 0
                blocked = true
              end
              break
            end
          end
          -- collide with world
          if not blocked then
            b.x = mid(b.x + vx, 3, 115)
            if b.x == 3 or b.x == 115 then
              vx = 0
            end
          end
        end
      end
      if b.money then
        -- don't count down money timeout if player is dying
        if not dying then
          -- delete money after timeout
          b.money = b.money + 0.25
          if b.money >= 180 then
            del(bags, b)
          end
        end
      elseif b.x % 8 == 3 then
        -- check for ground beneath bag
        local yaddr = 0x1b80 + (b.y - 19) * 64
        local solid = b.y >= 100 or peek(yaddr + b.x // 2 + 2) & 0xf0 ~= 0
        if solid and b.falling then
          -- double check solid ground in case there's a 1 pixel deep floor
          solid = b.y >= 100 or peek(0x1b80 + (b.y - 20) * 64 + b.x // 2 + 2) & 0xf0 ~= 0
        end
        if not solid then
          -- no ground so fall if not already doing so
          if not b.falling then
            b.falling = pushed and 0 or 60
            b.fally = b.y
            -- flag bag to leave a hole in the map
            add(delthings, b)
            if not pushed then
              -- bag shaking sound
              sfx(50)
            end
          end
        elseif b.falling then
          -- hit ground
          b.falling = nil
          -- break bag if fall distance was far enough
          if b.y >= 100 or b.y - b.fally > 9 then
            b.money = 0
            sfx(53)
          end
        end
      end
      if b.falling then
        -- count down to drop
        b.falling = max(0, b.falling - 1)
        if b.falling == 1 then
          -- drop sound
          sfx(54)
        end
        if b.falling == 0 then
          -- fall
          b.y = b.y + (1)
        end
      end
    end
    bonustime = max(0, bonustime - 1)
    if bonustime == 90 then
      playmusic(-1)
    elseif bonustime == 1 then
      if musicon then
        playmusic(1, 3)
      end
    end
    if bonus then
      -- pick up bonus
      if player.x + 3 > bonus.x and player.x - 3 < bonus.x + 7 and player.y + 3 > bonus.y and player.y - 3 < bonus.y + 7 then
        addscore(1000)
        bonustime = max(840 - level * 60, 360)
        bonus = nil
        if musicon then
          playmusic(13, 7)
        end
      end
    end
    for g in all(gems) do
      -- pick up gem
      if player.x + 3 > g.x and player.x - 3 < g.x + 7 and player.y + 3 > g.y and player.y - 3 < g.y + 7 then
        del(gems, g)
        add(delthings, g)
        sfx(56 + gemc)
        gemc = gemc + (1)
        gemt = 70
        addscore(25)
        if gemc == 8 then
          gemc, gemt = 0, 0
          --250 point bonus for 8 consecutive gems
          addscore(250)
        end
      end
    end
    player.vx = vx
    player.vy = vy
    player.x = mid(player.x + vx, 8, 120)
    player.y = mid(player.y + vy, 32, 104)
    if #gems == 0 or deadbugs == bugstotal then
      wint = 270
      playmusic(22)
    end
  end
  for s in all(scoredisplay) do
    if s.y > 12 then
      s.y = s.y - (0.5)
    end
    s.t = s.t - (1)
    if s.t == 0 then
      del(scoredisplay, s)
    end
  end
end

function drawgame()
  drawtiles()
  -- copy map back buffer to screen
  memcpy(0x6700, 0x1b80, 0x1440)
  -- set full draw pal to 0
  memset(0x5f01, 0, 15)
  -- carve hole where player is
  circfill(player.x - 1 + player.vx * 2, player.y + player.vy * 2, 3, 0)
  for bug in all(bugs) do
    circfill(bug.x - 1, bug.y, 3, 0)
  end
  -- carve holes for removed bags/gems
  for dt in all(delthings) do
    for ox = -1, 1 do
      spr(dt.s, dt.x + ox, dt.y)
      spr(dt.s, dt.x, dt.y + ox)
    end
    del(delthings, dt)
  end
  -- copy modified map back from screen
  memcpy(0x1b80, 0x6700, 0x1440)
  for g in all(gems) do
    olspr(48, g.x, g.y)
  end
  for b in all(bags) do
    local bx, s = b.x, b.falling and 50 or (b.money and 51 + flr(min(2, b.money)) or 49)
    if b.falling and b.falling > 0 then
      -- wiggle bag that's about to fall
      s = 49
      bx = bx - sin(b.falling / 12)
    end
    olspr(s, bx, b.y)
  end
  if bonus then
    spr(14, bonus.x, bonus.y)
  end
  if bullet then
    spr(42, bullet.x - 3, bullet.y - 3)
  end
  for bug in all(bugs) do
    if not (bug.start and bug.delay // 10 % 2 == 0) then
      spr(10 + bug.f + (bug.type == 1 and 16 or 0), bug.x - 4, bug.y - 4, 1, 1, bug.flip)
    end
  end
  if dying then
    if dying > 440 then
      spr(2, player.x - 4, player.y - 4 + sin((dying - 450) / 60) * 4, 1, 1, false, true)
    else
      local at = min(max(dying - 240, 0) // -30 + 10, 8)
      sspr(48, 24, 8, at, player.x - 5, player.y + 3 - at)
      spr(55, player.x - 5, player.y - 4)
      if lives == 1 then
        printf("game over", 36, 60, 10)
      end
    end
  else
    local flpx, flpy = player.dir % 2 == 1, player.dir == 3
    spr(player.f + (player.dir > 1 and 16 or 0) + (shootdelay > 0 and 5 or 0), player.x - 4 - (flpy and 0 or 1), player.y - 4, 1, 1, flpx, flpy)
  end
  for f in all(flashes) do
    f.t = f.t - (1)
    spr(47 - f.t // f.ft, f.x - 3, f.y - 3)
    if f.t <= 0 then
      del(flashes, f)
    end
  end
  local ls = "level " .. level + 1
  print(ls, 126 - #ls * 6, 3, 9)
  printscr(scorehi, scorelo, 4, 3)
  for i = 2, lives do
    spr(2, i * 10 - 16, 11, 1, 1, 1)
  end
  for s in all(scoredisplay) do
    printf(s.str, s.x, s.y, s.c)
  end
  if wint then
    printf("level", 49, 52, 7)
    printf("complete", 39, 61, 7)
  end
  if bonustime > 0 then
    scrpal = (bonustime > 120 or bonustime // 20 % 2 == 0) and bonuspal or normalpal
  else
    scrpal = normalpal
  end
end

function olspr(n, x, y)
  memset(0x5f01, 2, 15)
  for ox = x - 1, x + 1 do
    spr(n, ox, y)
  end
  spr(n, x, y - 1)
  memset(0x5f01, 1, 15)
  spr(n, x, y + 1)
  pal()
  spr(n, x, y)
end

function printscr(hi, lo, x, y)
  local ss = tostr(lo)
  print(sub("0000", 0, 4 - #ss) .. ss, x + 30, y, 11)
  ss = tostr(hi)
  print(sub("00000", 0, 5 - #ss) .. ss, x, y, 11)
end

function printf(str, x, y, c)
  for i = 11, 0, -1 do
    print(str, x - 1 + i % 3, y - 1 + i // 3, i > 8 and 0 or mid(3 - (i // 3 + i % 3), 1, 2))
  end
  print(str, x, y, c)
end

function addscore(n)
  scorelo = scorelo + (n)
  if scorelo >= 10000 then
    if scorehi == 32767 then
      scorehi = 0
    end
    scorehi = scorehi + (1)
    scorelo = scorelo - (10000)
    if scorehi % 2 == 0 and lives < 5 then
      lives = lives + (1)
    end
  end
  -- set colour for score display
  local c = 8
  if n > 800 then
    c = 13
  elseif n > 500 then
    c = 12
  elseif n > 300 then
    c = 11
  elseif n > 100 then
    c = 10
  elseif n > 25 then
    c = 9
  end
  add(scoredisplay, {x = 63 - #tostr(n) * 3 - 3, y = 24, str = "+" .. n, t = 60, c = c})
end

function killplayer()
  dying = 480
  playmusic(-1)
  music(-1)
  sfx(47)
end

function killbug(bug)
  del(bugs, bug)
  deadbugs = deadbugs + (1)
  add(flashes, {x = bug.x, y = bug.y, t = 80, ft = 20})
  sfx(51)
end

function issolid(x, y)
  local yaddr = 0x1b80 + (y - 28) * 64
  return y < 28 or y > 108 or x < 6 or x > 122 or peek(yaddr + x // 2) ~= 0
--&0xf0
end

-->8
-- levels
levels = {"s   b     hhhhsv  cc  c  v b  vb cc  c  v    v  ccb cb v cccv  cc  c  v ccchh cc  c  v ccc v    b b v     hhhh     v    c   v     v   ccc  hhhhhhh  cc", "shhhhh  b b  hs cc  v       v  cc  v ccccc v bccb v ccccc v cccc v       v cccc v b  hhhh  cc  v cc v     bb  vccccv cc c    v cc v cc cc   hhhhhh    ", "shhhhb b bhhhhscc  v c c v bb c   v c c v cc  bb v c c vccccccccv c c vcccccccchhhhhhh cc  cc  c v c  cc  cc  c v c     c    c v c    ccc   c h c   cc", "shbccccbccccbhscv  ccccccc  vcchhh ccccc hhhcc  v  ccc  v  c   hhh c hhh     b  v b v  b    c  vcccv  c   ccc hhhhh ccc ccccc cvc cccccccccc chc ccccc", "shhhhhhhhhhhhhsvbccccbvccccccvvccccccv ccbc vv cccc vccbcccvvccccccv cccc vv cccc vbcccccvvccbcccv cccc vv ccbc vccccccvvccccccvccccccvhhhhhhhhhhhhhhh", "shhhhhhhhhhhhhsvcbccv v vccbcvvccc vbvbv cccvvccchh v hhcccvvcc v cvc v ccvvcchh cvc hhccvvc v ccvcc v cvvchhbccvccbhhcvvcvccccvccccvcvhhhhhhhhhhhhhhh", "shcccccvccccchs vcbcbcvcbcbcv bvcccccvcccccvbchhccccvcccchhcccv cccvccc vcccchhhccvcchhhccccccv cvc vcccccccchh v hhcccccccccv v vcccccccccchhhhhccccc", "hhhhhhhhhhhhhhsv ccbcccccbcc vhhhccccbcccchhhvbv ccccccc vbvvchhhccccchhhcvvccbv ccc vbccvvccchhhchhhcccvvcccc v v ccccvvcccccv vcccccvhhhhhhhhhhhhhhh"}
levelfuncs = {s = function(x, y)
  circfill(x + 4, y + 4, 4, 0)
end, v = function(x, y)
  rectfill(x + 1, y - 1, x + 7, y + 8, 0)
end, h = function(x, y)
  rectfill(x, y + 1, x + 8, y + 7, 0)
end, c = function(x, y)
  add(gems, {x = x, y = y, s = 48})
end, b = function(x, y)
  add(bags, {x = x, y = y, s = 49})
end}

function updateload()
  if levelix < 16 then
    for y = leveliy, min(leveliy + 6, 9) do
      -- carve map tile
      local pos = y * 15 + levelix
      local c = sub(levels[leveli], pos, pos)
      if c ~= " " then
        levelfuncs[c](levelix * 8 - 5, y * 8 + 28)
      end
    end
    -- copy modified map back from screen
    memcpy(0x1b80, 0x6700, 0x1440)
  end
  loadtime = loadtime - (1)
  leveliy = leveliy + (6)
  if leveliy > 9 then
    leveliy = 0
    levelix = levelix + (1)
  end
  if loadtime == 0 then
    resetlevel()
    update, draw = updategame, drawgame
  end
end

function drawload()
end

function drawtiles()
  cls()
  for x = 0, 16 do
    for y = 0, 11 do
      spr(maptile, x * 8, y * 8 + 21)
    end
  end
end

function newgame()
  scorehi, scorelo, lives, level = 0, 0, 3, 0
  initlevel(level)
end

function initlevel(n)
  if n > 7 then
    n = n + (1)
  end
  leveli = n > 7 and max(5, n % 4 + 5) or n + 1
  bugstotal, maxbugs, deadbugs, delthings, flashes, bonusready, scoredisplay, wint = 5 + n, 3, 0, {}, {}, true, {}
  if n > 7 then
    maxbugs = 5
  elseif n > 1 then
    maxbugs = 4
  end
  maptile, gems, bags, gemc, gemt = 56 + n % 8, {}, {}, 0, 0
  levelix, leveliy, loadtime = 1, 0, 40
  update, draw = updateload, drawload
  -- lay down background tiles
  drawtiles()
  -- copy modified map back from screen
  memcpy(0x1b80, 0x6700, 0x1440)
end

function resetlevel()
  -- if bonus has appeared but not picked up then make it a truthy
  bonusready = bonusready or bonus
  bugscreated, bugsdelay, bonus, shootdelay, bonustime = deadbugs, 90 - level * 2, nil, 0, 0
  bugs = {}
  player = {x = 64, y = 104, vx = 0, vy = 0, f = 1, ft = 3, dir = right}
  if musicon then
    playmusic(1, 3)
  end
end


__gfx__
00049400000494000004940000049400000494000000000000000000000000000000000000000000676006766760067667600676676006760000000000000000
000909000009090000090900b309090000090900000000000000000000049400b30494000000000027733277727337277723377272733727000b300000000000
0009090000090900b38888800b888880b30909000004940000049400b38888800b888880b3049400676bb676676bb676676bb676676bb67600b0300000000000
b3888880b38888800b8888820b8888820b888880b3888880b38888800b8888820b8888820b88888003bbbb3003bbbb3003b11b3003b11b300880030000000000
0b8888820b888882b32888220b2888220b8888820b8888820b888882b32888220b2888220b888882003113000031130000311300003113008782088000000000
b3288822b3a9882200a922a9b32222a90b2888a9b3288822b3a9882200a922a9b32222a90b288822088bb820028bb82002311380028bb8208882878200000000
00a922a9009422a90094009400a90094b3a9229400a922a9009422a90094009400a90094b3a922a98800008008000080080bb088080000800220888200000000
00940094000000940000000000940000009400000094009400000094000000000094000000940094000000888800008888000000880000880000022000000000
000b0b00000b0b0000b0b0000b000b0000b000b0000b0b00000b0b0000b0b0000b000b0000b000b0006769000067690009676900006769000000000000000000
0003b3000003b300003b300003bbb300003bbb300003b3000003b300003b300003bbb300003bbb3000772a9009727a908a277a9009727a900000000000000000
000882a900088a9000882a90008822a9000882a9000882a900088a9000882a90008822a9000882a909777a948a777a9408777a948a777a940000000000000000
499888944998894049888940498882944998889400488894004889400488894004888294004888949aaaaa9408aaaa94008aaa9408aaaa940000000000000000
90088820900888209088820090888200900888200098882000988820098882000988820000988820888aa994008aa994008aa994008aa9940000000000000000
49988820499888204988820049888200499888200048882000488820048882000488820000488820009999400899994000899940089999400000000000000000
000882a9000882a900882a9000882a9000088a90000882a9000882a900882a9000882a90000882a900000110000dd10008011000000011000000000000000000
000022940000229400022940000229400000294000002294000022940002294000022940000022940000dd100000000000dd1000000dd1000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000098000000800000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000002882000000000009000090080000800000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000029aa9200090090000800800000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000008a77a800008800000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000008a77a800008800000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000029aa9200090090000800800000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000002882000000000009000090080000800000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000098000000800000000
0000000000f7f90000f7f9000007a000000000000000000000000000000000004455444433553355222555224444433455522525335555534444445545524552
00000000000e9000000e900000a44a000007a0000000000000d77600000000004544544435533553555552224444344452555555553335555544444524525545
0067cc0000fdde0000fdde000094990000a44a000007a0000d766660000000005444454455335533555222554443444455525552555553355555444424542554
06776cc00f7dff900f7dff90000997a00094990000a449000d755560000000004444445535533553522255554443444455555255555555535555544425442454
00ccdd000f7fdf900f7ddf900a94744a0a9997a00a9497a00d666660000000004554444433553355222555524443444425255552355555554555554442555245
000cd0000efdde900fffde907449a49a7449744a7449744a0d65556000000b005445444435533553555552224434444425555252533555554555554454245425
0000000000eee9000efdde90a4990aa0a499a49aa499a49a0d666660b0b00b0b4444544555335533555222254344444455555555555335554455555444255442
000000000000000000eee9000a9000000a900aa00a900aa00d6666603bb3bb334444455435533553552255553444444325522555555553354444555445524542
777777aa900000777a900077777777aa900077777777aa90007777777aa900777777777a90000000000000000000000000000000000000000000000000000000
7a9999999900007a999007a9999999999907a9999999999907a999999999007a9999999999000000000000000000000000000000000000000000000000000000
a9999999999000a999900a999999a999990a999999a999990a999999999400a999999a9999000000000000000000000000000000000000000000000000000000
a999911a999900a999900a9999111aa9940a9999111aa9940a999911111200a9999114a999000000000000000000000000000000000000000000000000000000
a9999111a99990a999900a9999111dd1120a9999111dd1120a999911111200a9999111a999000000000000000000000000000000000000000000000000000000
a99991211a9990a999900a9999111d11120a9999111d11120a999911112200a99991127999000000000000000000000000000000000000000000000000000000
a99990011a9990a999900a9999000111200a9999000111200a9999aa790000a99990007999000000000000000000000000000000000000000000000000000000
a99990001a9990a999900a9999000000000a9999000000000a999999990000a99999a77999700000000000000000000000000000000000000000000000000000
a99994000a9990a999940a999940077aa90a999940077aa90a999999940000a999999999999a0000000000000000000000000000000000000000000000000000
a99999000a9990a999990a9999900a99990a9999900a99990a999991120000a99999999999990000000000000000000000000000000000000000000000000000
a99999000a9990a999990a9999900aa9990a9999900aa9990a999991120000a99999114999990000000000000000000000000000000000000000000000000000
a9999900079990a999990a99999000a9990a99999000a9990a999991220000a99999111a99990000000000000000000000000000000000000000000000000000
a9999900079990a999990a9999900079990a9999900079990a999990000000a99999112a99990000000000000000000000000000000000000000000000000000
a999999a799990a999990a999999aa79990a999999aa79990a999999a77a90a99999001a99990000000000000000000000000000000000000000000000000000
a9999999999940a999990a9999999999990a9999999999990a999999999990a99999000a99990000000000000000000000000000000000000000000000000000
aa999999999420aa99940ca999999999940ca999999999940ca99999999940aa9994000aa9940000000000000000000000000000000000000000000000000000
cd111111111220cd11120dcd11111111120dcd11111111120dcd1111111120cd1112000cd1120000000000000000000000000000000000000000000000000000
d1111111111220d1111201d1111111111201d1111111111201d11111111120d11112000d11120000000000000000000000000000000000000000000000000000
11111111112200111122001111111111200011111111112000111111111200111120000111200000000000000000000000000000000000000000000000000000
__sfx__
790210180c1240c2310c2410c2510c2610c2500c2510c2500c2500c2410c2400c2400c2400c2400c2400c2400c2310c2300c2300c2300c2300c2300c2300c2300000000000000000000000000000000000000000
4d0400000c1500c1410c1310c1210c1110c1100c11500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001854518525180701806118051180501804118040180311803018021180201801118010180101801518514185151802418020180111801018010180150000000000000000000000000000000000000000
11040d100c5500c5700c5610c5510c5410c5400c5400c5400c5310c5300c5300c5300c5210c5200c5200c52000500005000050000500005000050000500005000050000500005000050000500005000050000500
01030d101805018071180411803118031180411804018040180311803018030180301802118020180201802000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011a00202486024871248702487024873248702487024873248732487024871248612784027861278312685026863268612685124850248532487124861238502486024871248612485124841248312482124811
011a00000c8100c8310c8410c8400f8200f8410f8400f8400c8200c8410c8400c8400f8200f8410f8400f8400c8200c8410c8400c8400f8200f8410f8400f8400c8200c8410c8310c8300c8210c8200c8110c815
451a00000751007521075310754108540085400854008540075400754007540075400854008540085400854007540075400754007540085400854008540085400754007531075210752007520075110751007515
010d00000e9400e9401a9401594009940099401a940159400e9400e9401a940159400e94009940119401a9400e9400e9401a9401594009940099401a940159400e9400e9401a940159400e94009940119401a940
010d000000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0000a0026a4026a4024a4024a40
010d000026a4026a4021a4021a401da401da4021a4021a401aa401aa401aa401aa4026a4026a4024a4024a4026a4026a4021a4021a401da401da4021a4021a401aa401aa401aa401aa4026a4026a4028a4028a40
010d000029a4029a4028a4028a4029a4029a4026a4026a4028a4028a4026a4026a4028a4028a4024a4024a4026a4026a4024a4024a4026a4026a4022a4022a4026a4026a4026a4026a4026a4326a4024a4024a40
010d00000e9400e9401a940159400e94011940159401a9400c9400c94018940139400c9401094013940189400a9400a94016940119400a9400e94011940169400e9400e9401a940159400e94011940159401a940
010d000029a4029a4028a4028a4029a4029a4026a4026a4028a4028a4026a4026a4028a4028a4024a4024a4026a4026a4024a4024a4026a4026a4028a4028a4029a4029a4029a4029a402da402da402ba402ba40
010d00002da402da4029a4029a4024a4024a4029a4029a4021a4021a4021a4021a402da402da402ba402ba402da402da4029a4029a4024a4024a4029a4029a4021a4021a4021a4021a402da402da402fa402fa40
010d000030a4030a402fa402fa4030a4030a402da402da402fa402fa402da402da402fa402fa402ba402ba402da402da402ba402ba402da402da4029a4029a402da402da402da402da402da432da402ba402ba40
010d000030a4030a402fa402fa4030a4030a402da402da402fa402fa402da402da402fa402fa402ba402ba402da402da402ba402ba402da402da4029a4029a402da402da402da402da4032a4032a4030a4030a40
010d000030a4030a402fa402fa4030a4030a402da402da402fa402fa402da402da402fa402fa402ba402ba402da402da402ba402ba402da402da4029a4029a402da402da402da402da4026a4026a4024a4024a40
010d000011940119401d940189400c9400c9401d9401894011940119401d940189400c94015940189401d94011940119401d940189400c9400c9401d9401894011940119401d940189400c94015940189401d940
010d00001594015940219401c94015940189401c9402194013940139401f9401a94013940179401a9401f94011940119401d940189401194015940189401d94011940119401d940189401194015940189401d940
010c000010b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb210bb500bb2117b5017b210bb500bb2117b5017b21
010c020023c4023c53000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c020020c4020c53000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000023c500000023c4023c5323c530000023c4023c5328c50000002ac30000002cc400000023c4023c5323c530000023c4023c5328c50000002cc402cc532ac500000027c400000023c500000023c4023c53
010c000020c500000020c4020c5320c530000020c4020c5320c530000021c400000023c500000020c4320c5320c500000020c4320c5320c500000023c4323c5323c500000023c400000021c30000001ec431ec53
010c000010b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb2110b5010b211cb501cb210bb500bb2117b5017b210bb500bb2117b5017b2110b5010b211cb501cb2110b5010b211cb501cb21
010c000023c500000023c4023c5323c530000023c4023c5328c50000002ac30000002cc400000028c302cc402fc502fc502fc502fc502fc502dc502cc402ac3028c50000002cc400000028c50000002fc402fc53
010c000020c500000020c4020c5320c530000020c4020c5320c530000021c400000023c5000000000000000027c4027c5127c5027c4127c3127c25000000000020c500000023c500000020c50000002cc402cc53
010c00002fc500c0002fc402fc532fc530c0002fc402fc5334c500c00036c300c00038c400c0002fc402fc532fc530c0002fc402fc5334c500c00038c4038c5336c500c00033c400c0002fc500c0002fc402fc53
010c00002cc500c0002cc402cc532cc530c0002cc402cc532cc530c0002dc400c0002fc500c0002cc432cc532cc500c0002cc432cc532cc500c0002fc432fc532fc500c0002fc400c0002dc300c0002ac432ac53
010c00002fc500c0002fc402fc532fc530c0002fc402fc5334c500c00036c300c00038c400c00034c3038c403bc503bc503bc503bc503bc5039c5038c4036c3034c500c00038c400c00034c500c00038c4038c53
010c00002cc500c0002cc402cc532cc530c0002cc402cc532cc530c0002dc400c0002fc500c0000c0000c00033c4033c5133c5033c4133c3133c250c0000c0002cc500c0002fc500c0002cc500c00034c4034c53
010c00000db700db500db410db310db730db500db410db310db730db500db410db310db730db500db410db310db730db500db410db310db730db5008b7008b500db700db5008b7008b500db700db500db410db31
010c000038c500c00038c4038c5338c530c00038c4038c5338c430c0003dc500c00038c400c0003dc500c00038c400c0003dc500c00038c400c00036c400c00034c300c00033c300c00031c400c00038c3038c43
010c000034c500c00034c4034c5334c530c00034c4034c5334c430c00034c500c00034c400c00034c500c00034c400c00034c500c00034c400c00033c400c00031c300c0002cc300c00028c200c00034c3034c43
010c00000db700db500db410db310db730db500db410db310db730db500db410db310db730db500db410db310db730db500db410db3106b7006b5006b7306b500bb700bb500bb730bb5008b7008b5008b4108b31
010c000038c500c00038c4038c5338c530c00038c4038c5338c430c0003dc500c00038c400c0003dc500c00038c400c0003dc400c0003bc400c0003ac400c0003bc403bc513bc503bc503bc413bc4038c3038c43
010c000034c500c00034c4034c5334c530c00034c4034c5334c430c00034c500c00034c400c00034c500c00034c400c00034c400c00036c400c00034c400c00033c4033c5133c5033c5033c4133c4034c3034c43
010c00000db700db500db410db310db730db500db410db310db730db500db410db310db730db500db410db310db730db500db410db3106b7006b5006b7306b500bb700bb410bb210bb1500000000002ab402ab53
010c000038c500c00038c4038c5338c530c00038c4038c5338c430c0003dc500c00038c400c0003dc500c00038c400c0003dc400c0003bc400c0003ac400c0003bc303dc203bc203ac303bc303dc203bc203ac30
010c000034c500c00034c4034c5334c530c00034c4034c5334c430c00034c500c00034c400c00034c500c00034c400c00034c400c00036c400c00034c400c00000000000000000000000000000000027b4027b53
4110000024350283502b35026350293502d350283502b3502f3503035030341303403033130330303213032030311303103031030310303150000000000000000000000000000000000000000000000000000000
351000001c3501f350243501d350213502635021350283502b3502835028341283402833128330283212832028311283102831028310283150000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110600001b3301e3402035021350203401e3401b3301833015320123200f3100c3150c3000c3000c3000030000300003000030000300003000030000300003000030000000000000000000000000000000000000
0104000018320183101c3201c3111f3301f3112433024320243112431124315000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001f3201f311243202431124311243150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910600002434000000000001d34000000000002434000000000001d34000000000002433000000000001d33000000000002433000000000001d32000000000000000000000000000000000000000000000000000
01030000133601304418370180441a3601a0441c3501c0341e3401e02420330200242233522024243352401500000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001354330340243502b3401f34024330183301f32013320183100c310183150c315133150731513314073140c314003140c314003140000000000000000000000000000000000000000000000000000000
310200000c373001700014138420385253a0243a515383053e0203c5253c3243c3113c31500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002972428731277412675125741247412373123731227212271121711217112171500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000263441a4202d350214303236026440393602d4403e36032440263601a4403236026440393602d440393302d410393202d415393102d41500000000000000000000000000000000000000000000000000
010500003837020440383602043038350204203834020410383302041038320204103831020410383100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500003937021440393602143039350214203934021410393302141039320214103931021410393100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500003a370224403a360224303a350224203a340224103a330224103a320224103a310224103a3100100001000010000100001000010000100001000010000100001000010000100001000010000100001000
010500003b370234403b360234303b350234203b340234103b330234103b320234103b310234103b3100200002000020000200002000020000200002000020000200002000020000200002000020000200002000
010500003c370244403c360244303c350244203c340244103c330244103c320244103c310244103c3100300003000030000300003000030000300003000030000300003000030000300003000030000300003000
010500003d370254403d360254303d350254203d340254103d330254103d320254103d310254103d3100400004000040000400004000040000400004000040000400004000040000400004000040000400004000
010500003e370264403e360264303e350264203e340264103e330264103e320264103e310264103e3100500005000050000500005000050000500005000050000500005000050000500005000050000500005000
010500003f370274403f360274303f350274203f340274103f330274103f320274103f310274103f3100600006000060000600006000060000600006000060000600006000060000600006000060000600006000
__music__
04 08090a44
00 4c0b4d44
00 0c0b4d44
01 0d0b4344
00 0e0f4344
00 0d0b4344
00 100f4344
00 11154344
00 12164344
00 11154344
00 13164344
00 11154344
02 14164344
00 18194344
01 171a1b44
00 1c1d1e44
00 171f2044
00 1c212244
00 23242544
00 26272844
00 23242544
02 292a2b44
04 2c2d4344
__label__
45445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444
54444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544
44444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455
45544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444
54454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444
44445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445
44444554444445544444455440000000000045500000005000000000000040000000000000400000000000000000000000004554444445544444455444444554
44554444445544444455444400000000000004000000000000000000000000000000000000000000000000000000000000000444445544444455444444554444
45445444454454444544544400777777aa900000777a900077777777aa900077777777aa90007777777aa900777777777a900044454454444544544445445444
544445445444454454444544007a9999999900007a999007a9999999999907a9999999999907a999999999007a99999999990044544445445444454454444544
44444455444444554444445500a9999999999000a999900a999999a999990a999999a999990a999999999400a999999a99990055444444554444445544444455
45544444455444444554444400a999911a999900a999900a9999111aa9940a9999111aa9940a999911111200a9999114a9990044455444444554444445544444
54454444544544445445444400a9999111a99990a999900a9999111dd1120a9999111dd1120a999911111200a9999111a9990044544544445445444454454444
44445445444454454444544500a99991211a9990a999900a9999111d11120a9999111d11120a999911112200a999911279990045444454454444544544445445
44444554444445544444455400a99990011a9990a999900a9999000111200a9999000111200a9999aa790000a999900079990004444445544444455444444554
44554444445544444455444400a99990001a9990a999900a9999000000000a9999000000000a999999990000a99999a779997000445544444455444444554444
45445444454454444544544400a99994000a9990a999940a999940077aa90a999940077aa90a999999940000a999999999999a00454454444544544445445444
54444544544445445444454400a99999000a9990a999990a9999900a99990a9999900a99990a999991120000a999999999999900544445445444454454444544
44444455444444554444445500a99999000a9990a999990a9999900aa9990a9999900aa9990a999991120000a999991149999900444444554444445544444455
45544444455444444554444400a9999900079990a999990a99999000a9990a99999000a9990a999991220000a99999111a999900455444444554444445544444
54454444544544445445444400a9999900079990a999990a9999900079990a9999900079990a999990000000a99999112a999900544544445445444454454444
44445445444454454444544500a999999a799990a999990a999999aa79990a999999aa79990a999999a77a90a99999001a999900444454454444544544445445
44444554444445544444455400a9999999999940a999990a9999999999990a9999999999990a999999999990a99999000a999900444445544444455444444554
44554444445544444455444400aa999999999420aa99940ca999999999940ca999999999940ca99999999940aa9994000aa99400445544444455444444554444
45445444454454444544544400cd111111111220cd11120dcd11111111120dcd11111111120dcd1111111120cd1112000cd11200454454444544544445445444
54444544544445445444454400d1111111111220d1111201d1111111111201d1111111111201d11111111120d11112000d111200544445445444454454444544
44444455444444554444445500111111111122001111220011111111112000111111111120001111111112001111200001112000444444554444445544444455
45544444455444444554444400000000000000000000000000000000000000000000000000000000000000000000000000000000455444444554444445544444
54454444544544445445444400000000000000000000000000000000000000000000000000000000000000000000000000000000544544445445444454454444
44445445444454454444544540000000000000000000000000000000000050000000000000400000000000000000000500000005444454454444544544445445
44444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554
44554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444
45445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444
54444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544
44444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455
45544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444
54454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444
44445445444454454444544544445445444452222444544544445445444454454444544544445445444454454444544544445445444454454444544544445445
4444450004444554444445544444455444442f7f9244455444444554444445544444455444444554444445544444455444444554444445544444450004444554
44550000000544444455444444554444445541691455444444554444445544444455444444554444445000000000000000000000000000000000000000054444
4544000000045444454454444544544445442fdd6244544445445444454454444544544445445444454000000000000000000000000000000000000000045444
544000000000454454444544544445445442f7dff924454454444544544445445444454454444544544000000000000000000000000000000000000000004544
444000000000445544444455444444554442f7fdf924445544444455444444554444445544444455444000000000000000000000000000000000000000004455
4550000000004444455444444554444445526fdd6924444445544444455444444554444445544444455000000000000000000000000000000000000000004444
54450000000544445445444454454444544516669145444454454444544544445445444454454444544000000000000000000000000000000000000000054444
44440000000454454444544544445445444451111444544544445445444454454444544544445445444000000000000000000222200000000000000000045445
44440000000445544444455444444554444445544444455444444554444445544444455444444554444400000004455444442f7f924445544444450004444554
44550000000544444455444444554222245542222455444444554444445542222455444444554444445500000005444444554169145544444455444444554444
4544000000045444454454444544267cc244267cc2445444454454444544267cc244544445445444454400000004544445442fdd624454444544544445445444
54440000000445445444454454426776cc226776cc2445445444454454426776cc2445445444454454440000000445445442f7dff92445445444454454444544
44440000000444554444445544441ccdd1441ccdd14444554444445544441ccdd14444554444445544440000000444554442f7fdf92444554444445544444455
455400000004444445544444455441cd155441cd1554444445544444455441cd1554444445544444455400000004444445526fdd692444444554444445544444
54450000000544445445444454454411544544115445444454454444544544115445444454454444544500000005444454451666914544445445444454454444
44440000000452222444544544445445444454454444544544445445444454454444544544445445444400000004544544445111144454454444544544445445
4444000000042f7f9244455444444554444445544444455444444554444445544444455444444554444400000004455444444554444445544444455444444554
44550000000541691455444444554222245542222455444444554444445542222455444444554444445500000005444444554444445544444455444444554444
4544000000042fdd624454444544267cc244267cc2445444454454444544267cc244544445445444454400000004544445445444454454444544544445445444
544400000002f7dff924454454426776cc226776cc2445445444454454426776cc24454454444544544400000004454454444544544445445444454454444544
444400000002f7fdf924445544441ccdd1441ccdd14444554444445544441ccdd144445544444455444400000004445544444455444444554444445544444455
4554000000026fdd69244444455441cd155441cd1554444445544444455441cd1554444445544444455400000004444445544444455444444554444445544444
54450000000516669145444454454411544544115445444454454444544544115445444454454444544500000005444454454444544544445445444454454444
44440000000451111444544544445445444454454444522224445445444454454444522224445445444400000004544544445445444454454444544544445445
444400000004455444444554444445544444455444442f7f924445544444455444442f7f92444554444400000004455444444554444445544444455444444554
44550000000544444455444444554222245542222455416914554444445542222455416914554444445500000005444444554222245542222455422224554444
4544000000045444454454444544267cc244267cc2442fdd624454444544267cc2442fdd6244544445440000000454444544267cc244267cc244267cc2445444
54440000000445445444454454426776cc226776cc22f7dff924454454426776cc22f7dff9244544544400000004454454426776cc226776cc226776cc244544
44440000000444554444445544441ccdd1441ccdd142f7fdf924445544441ccdd142f7fdf9244455444400000004445544441ccdd1441ccdd1441ccdd1444455
455400000004444445544444455441cd155441cd15526fdd69244444455441cd15526fdd692444444554000000044444455441cd155441cd155441cd15544444
54450000000544445445444454454411544544115445166691454444544544115445166691454444544500000005444454454411544544115445441154454444
44440000000454454444544544445445444454454444511114445445444454454444511114445445444400000004544544445445444454454444544544445445
44440000000445544444455444444554444445544444455444444554444445544444455444444554444400000004455444444554444445544444455444444554
44550000000544444455444444554222245542222455444444554444445542222455444444554444445500000005444444554222245542222455422224554444
4544000000045444454454444544267cc244267cc2445444454454444544267cc24454444544544445440000000454444544267cc244267cc244267cc2445444
54440000000445445444454454426776cc226776cc2445445444454454426776cc24454454444544544400000004454454426776cc226776cc226776cc244544
44440000000444554444445544441ccdd1441ccdd14444554444445544441ccdd144445544444455444400000004445544441ccdd1441ccdd1441ccdd1444455
455400000004444445544444455441cd155441cd1554444445544444455441cd15544444455444444554000000044444455441cd155441cd155441cd15544444
54450000000544445445444454454411544544115445444454454444544544115445444454454444544500000005444454454411544544115445441154454444
44440000000454454444544544445445444454454444544544445445444454454444544544445445444400000004544544445445444454454444544544445445
44440000000445544444455444444554444445544444455444444554444445544444455444444554444400000004455444444554444445544444455444444554
44500000000000000000444444554222245542222455444444554444445542222455444444554444445500000005444444554222245542222455422224554444
4540000000000000000054444544267cc244267cc2445444454454444544267cc24454444544544445440000000454444544267cc244267cc244267cc2445444
54400000000000000000454454426776cc226776cc2445445444454454426776cc24454454444544544400000004454454426776cc226776cc226776cc244544
44400000000000000000445544441ccdd1441ccdd14444554444445544441ccdd144445544444455444400000004445544441ccdd1441ccdd1441ccdd1444455
455000000000000000004444455441cd155441cd1554444445544444455441cd15544444455444444554000000044444455441cd155441cd155441cd15544444
54400000000000000000444454454411544544115445444454454444544544115445444454454444544500000005444454454411544544115445441154454444
44400000000000000000544544445445444454454444544544445222244454454444522224445445444400000004544544445445444454454444544544445445
44444554444400000004455444444554444445544444455444442f7f9244455444442f7f92444554444400000004455444444554444445544444455444444554
44554444445500000005444444554444445544444455444444554169145544444455416914554444445500000005444444554444445544444455444444554444
45445444454400000004544445445444454454444544544445442fdd6244544445442fdd62445444454400000004544445445444454454444544544445445444
5444454454440000000445445444454454444544544445445442f7dff92445445442f7dff9244544544400000004454454444544544445445444454454444544
4444445544440000000444554444445544444455444444554442f7fdf92444554442f7fdf9244455444400000004445544444455444444554444445544444455
45544444455400000004444445544444455444444554444445526fdd6924444445526fdd69244444455400000004444445544444455444444554444445544444
54454444544500000005444454454444544544445445444454451666914544445445166691454444544500000005444454454444544544445445444454454444
44445445444400000004544544445445444454454444544544445111144454454444511114445445444400000004544544445445444454454444544544445445
44444554444400000004455444444554444445544444455444444554444445544444455444444554444400000004455444444554444445544444455444444554
44554444445000000000000000000000000000000000444444554444445544444455444444554444445500000005444444554444445544444455444444554444
45445444454000000000000000000000000000000000544445445444454454444544544445445444454400000004544445445444454454444544544445445444
54444544544000000000000000000000000000000000454454444544544445445444454454444544544400000004454454444544544445445444454454444544
44444455444000000000000000000000000000000000445544444455444444554444445544444455444400000004445544444455444444554444445544444455
45544444455000000000000000000000000000000000444445544444455444444554444445544444455400000004444445544444455444444554444445544444
54454444544000000000000000000000000000000000444454454444544544445445444454454444544500000005444454454444544544445445444454454444
44445445444000000000000000000000000000000000544544445445444454454444544544445445444400000004544544445445444454454444544544445445
44444554444445544444455444444554444400000004455444444554444445544444455444444554444400000004455444444554444445544444455444444554
44554222245544444455444444554444445500000005444444554444445544444455444444554444445500000005444444554444445544444455422224554444
4544267cc24454444544544445445444454400000004544445445444454454444544544445445444454400000004544445445444454454444544267cc2445444
54426776cc24454454444544544445445444000000044544544445445444454454444544544445445444000000044544544445445444454454426776cc244544
44441ccdd144445544444455444444554444000000044455444444554444445544444455444444554444000000044455444444554444445544441ccdd1444455
455441cd15544444455444444554444445540000000444444554444445544444455444444554444445540000000444444554444445544444455441cd15544444
54454411544544445445444454454444544500000005444454454444544544445445444454454444544500000005444454454444544544445445441154454444
44445445444454454444544544445445444400000004544544445445444454454444544544445445444400000004544544445445444454454444544544445445
44444554444445544444455444444554444400000004455444444554444444944444455444444554444400000004455444444554444445544444455444444554
44554222245542222455444444554444445000000000000000000000000009090000000000000000000000000000444444554444445542222455422224554444
4544267cc244267cc2445444454454444540000000000000000000000000090900000000000000000000000000005444454454444544267cc244267cc2445444
54426776cc226776cc244544544445445440000000000000000000000000888883b000000000000000000000000045445444454454426776cc226776cc244544
44441ccdd1441ccdd144445544444455444000000000000000000000000288888b0000000000000000000000000044554444445544441ccdd1441ccdd1444455
455441cd155441cd155444444554444445500000000000000000000000022889a3b0000000000000000000000000444445544444455441cd155441cd15544444
544544115445441154454444544544445440000000000000000000000009a2249000000000000000000000000000444454454444544544115445441154454444
44445445444454454444544544445445444000000000000000000000000490000000000000000000000000000000544544445445444454454444544544445445
44444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554
44554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444
45445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444
54444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544
44444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455
45544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444
54454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444
44445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445444454454444544544445445
44444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554
44554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444445544444455444444554444
__meta:title__
digger 1.1
by paranoid cactus
