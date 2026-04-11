pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- mot's 8-ball pool
-- by mot
-->8
-- constants and data
ballrad, pocketrad, pocketstep = 4, 7.5, 0.125
tablew, tablel, tableh = 115, 225, 90
baulk, drad = tablel * 0.3, tablew / 6
rackjitter = 0.05
rackspacing = ballrad * 2 + rackjitter * 2
cuelen, cuerad1, cuerad2, cuemin, cuemax, cuedef, cuestep = 100, 1.25, 2, 1, 25, 10, 0.25
mode_aim, mode_sim, mode_postgame, mode_menu, mode_placeball = 1, 2, 3, 4, 5
etable, eball, friction = 0.7, 0.55, 0.05
allverts = {}
-- variables
fov, camang, cueang, camzoom, campitch, cuepow, centercamf = 128, 0, 0, 100, -0.135, cuedef, 0
xinp, yinp, xinpfactor, angf = 0, 0, 1, 1
-- misc
framect, tickerx, tickerqueue = 0, 0, {}
aligncirc, inputhints = 0, true

-- stats
--colbb=0		-- # ball-ball collisions
--colbt=0  -- # ball-table collisions
-->8
-- gameplay
function _update()
  framect = framect + (1)
  -- if framect==3 then
  -- 	 extcmd("rec")
  --	end
  if mode == mode_aim then
    updateaim()
  elseif mode == mode_sim then
    updatesim()
  elseif mode == mode_postgame then
    updatepostgame()
  elseif mode == mode_menu then
    updatemenu()
  elseif mode == mode_placeball then
    updateplaceball()
  end
  updateticker()
end

function updateticker()
  if tickermsg then
    tickerx = tickerx - (1)
    if tickerx < -#tickermsg * 4 then
      tickermsg = nil
      if #tickerqueue > 0 then
        tickermsg = tickerqueue[1]
        del(tickerqueue, tickermsg)
        tickerx = 129
      end
    end
  end
end

function showtickermsg(msg, clearqueue)
  if clearqueue then
    tickerqueue = {}
  end
  if not tickermsg then
    tickermsg, tickerx = msg, 129
  else
    add(tickerqueue, msg)
  end
end

function mainmenu()
  -- recreate balls
  makeballs()
  menuitem(1)
  initmenu()
  mode = mode_menu
end

function newgame(npc, npc2)
  -- recreate balls
  makeballs()
  -- setup game state
  players = {{name = npc2 and npc2.name or "player1", ballct = 0, npc = npc2}, {name = npc and npc.name or "player2", ballct = 0, npc = npc}}
  overct, underct = 7, 7
  player, otherplayer = unpack(players)
  if npc and rnd(2) >= 1 then
    swapplayers()
  end
  winner, freeball, isbreak = nil, false, true
  -- set cue to initial state
  cuepos, camang = white.pos, rnd(0.01) - 0.005
  angf = 0.15
  menuitem(1, "quit to menu", mainmenu)
  setupforplaceball()
end

function setupforshot()
  -- move cue to white ball
  cuepos, cuepow = white.pos, cuedef
  -- switch to aim mode
  mode = mode_aim
  -- ai
  if player.npc then
    player.co = cocreate(aiaim)
  end
end

function setupforplaceball()
  mode = mode_placeball
  -- ai
  if player.npc then
    player.co = cocreate(aiplaceball)
  end
end

function nextplayershot(sunkwhite)
  swapplayers()
  if not sunkwhite then
    setupforshot()
  else
    setupforplaceball()
  end
end

function swapplayers()
  -- swap players
  local temp = player
  player = otherplayer
  otherplayer = temp
end

function updateplaceball()
  if player.npc then
    -- npc logic
    assert(coresume(player.co))
    if costatus(player.co) == "dead" then
      resetcue()
      setupforshot()
    end
  else
    local p = white.pos
    if btn(0) then
      p[1] = p[1] - (1)
    end
    if btn(1) then
      p[1] = p[1] + (1)
    end
    if btn(2) then
      p[2] = p[2] - (1)
    end
    if btn(3) then
      p[2] = p[2] + (1)
    end
    local w = tablew / 2 - ballrad
    local l = tablel / 2 - ballrad
    -- limit to behind baulk line
    p[1] = clamp(p[1], -w, w)
    p[2] = clamp(p[2], baulk, l)
    if btnp(5) or btnp(4) then
      if isvalidwhitepos(p) then
        resetcue()
        setupforshot()
      else
        showtickermsg("cannot place ball here!", true)
      end
    end
  end
end

function isvalidwhitepos(p)
  for b in all(balls) do
    if b ~= white then
      local dif = b.pos - p
      -- must scale down to prevent numeric
      -- overflow in :length() 	 
      local dist = (dif / 16):length() * 16
      if (dist < ballrad * 2) then
        return false
      end
    end
  end
  return true
end

function updateaim()
  getinput()
  if player.npc then
    -- npc logic
    assert(coresume(player.co))
    if costatus(player.co) == "dead" then
      shoot()
    end
    campitch = campitch * 0.8 - 0.175 * 0.2
  -- player can move camera up/down
  --  campitch-=yinp*0.008
  else
    -- player logic
    -- aim/power
    cueang = cueang - (xinp * 0.01 * xinpfactor)
    if btn(4) then
      if btn(3) then
        cuepow = cuepow + (1)
      end
      if btn(2) then
        cuepow = cuepow - (1)
      end
    else
      campitch = campitch - (yinp * 0.008)
    end
    cuepow = clamp(cuepow, cuemin, cuemax)
    -- shoot
    if btnp(5) then
      shoot()
    end
  end
  -- common
  campitch = clamp(campitch, -0.22, 0)
end

function shoot()
  -- set cue ball velocity
  local t = -vec(sin(cueang), cos(cueang))
  local pow = cuepow * 1
  white.vel = t * cuepow * 1
  cushionsfx(pow)
  -- track sunk balls
  sunkwhite, sunkblack, sunkover, sunkunder = false, false, false, false
  firsthit, firstsunk = nil, nil
  prevoverct, prevunderct = overct, underct
  -- camera behaviour
  centercamf = 0
  -- run simulation
  mode = mode_sim
end

function updatesim()
  -- ball-ball collision count
  -- and intensity, for sfx
  local bbct, bbint = 0, 0
  -- likewise ball-table
  local btct, btint = 0, 0
  -- main simulation
  -- move balls forward one 
  -- timestep, then apply friction.
  -- shot ends when all balls are 
  -- stationary.
  local step = 1
  while step > 0 do
    -- find next collision
    local substep = step
    local colball, colball2, coln = nil, nil, nil
    -- find movement bounds
    -- use to discard corners,edges
    -- and other balls that cannot
    -- collide this frame.
    -- (also avoids numeric overflow)
    for ball in all(balls) do
      ball.bounds = makebounds(ball.pos, ballrad)
      addboundpt(ball.bounds, ball.pos + ball.vel * substep, ballrad)
    end
    local zonereduce = pocketrad / sqrt(2)
    local zonew = tablew / 2 - zonereduce
    local zonel = tablel / 2 - zonereduce
    for i = 1, #balls do
      local ball = balls[i]
      if isballmoving(ball) then
        -- edge collisions
        if ball.bounds.mn[1] <= -zonew or ball.bounds.mn[2] <= -zonel or ball.bounds.mx[1] >= zonew or ball.bounds.mx[2] >= zonel then
          -- corner collisions
          for corner in all(corners) do
            if ptinbounds(ball.bounds, corner) then
              local t, n = ballcorner(ball, corner)
              if t and t < substep then
                substep = t
                colball = ball
                colball2 = nil
                coln = n
              end
            end
          end
          -- cushion collisions
          for edge in all(edges) do
            if boundsintersect(ball.bounds, edge.bounds) then
              local t, n = balledge(ball, edge)
              if t and t < substep then
                substep = t
                colball = ball
                colball2 = nil
                coln = n
              end
            end
          end
          -- sink trigger edges
          for sink in all(sinks) do
            if boundsintersect(ball.bounds, sink.bounds) then
              local t = rayline(ball.pos, ball.vel, sink.p1, sink.p2)
              if t and t < substep then
                substep = t
                colball = ball
                colball2 = nil
                coln = nil
              end
            end
          end
        end
      end
      -- other ball collisions
      for j = 1, #balls do
        local ball2 = balls[j]
        if j ~= i and (j > i or not isballmoving(ball2)) then
          if boundsintersect(ball.bounds, ball2.bounds) then
            local t, n = ballball(ball, ball2)
            if t and t < substep then
              substep = t
              colball = ball
              colball2 = ball2
              coln = n
            end
          end
        end
      end
    end
    -- move balls forward
    for ball in all(balls) do
      ball.pos = ball.pos + (ball.vel * substep)
    end
    step = step - (substep)
    -- resolve collision
    if colball then
      if colball2 then
        -- ball-ball collision
        local i = coln * (colball.vel - colball2.vel) * (1 + eball)
        -- impulse vectors
        local iv1 = -coln * i / 2
        -- 			local iv2= coln*i/2
        -- update balls
        colball.vel = colball.vel + (iv1)
        colball2.vel = colball2.vel - (iv1)
        --+=iv2
        bbct = bbct + (1)
        bbint = bbint - (i)
        -- track first ball hit 
        if not firsthit then
          if colball == white then
            firsthit = colball2
          end
          if colball2 == white then
            firsthit = colball
          end
        end
      elseif coln then
        -- ball-table collision
        -- collision impulse
        local i = -coln * colball.vel * (1 + etable)
        -- impulse vector
        local iv = coln * i
        -- update ball
        colball.vel = colball.vel + (iv)
        btct = btct + (1)
        btint = btint + (i)
      else
        -- ball-sink edge collision
        del(balls, colball)
        sfx(20, 3)
        if colball == white then
          sunkwhite = true
        elseif colball == black then
          sunkblack = true
        else
          firstsunk = firstsunk or colball
          if colball.typ == "overs" then
            sunkover = true
            overct = overct - (1)
          else
            sunkunder = true
            underct = underct - (1)
          end
        end
      end
    end
  end
  -- apply friction
  for ball in all(balls) do
    if isballmoving(ball) then
      local v = ball.vel:length()
      local d = ball.vel / v
      v = max(v - friction, 0)
      ball.vel = d * v
    end
  end
  -- trigger sound effects
  if bbct > 0 then
    local s = bbint > 100 and 4 or bbint > 12 and 3 or bbint > 8 and 2 or bbint > 5 and 1 or 0
    -- choose sound effect based
    -- on intensity  
    sfx(s, min(4 - s, 1))
  end
  if btct > 0 then
    cushionsfx(btint)
  end
  -- switch back to aim once
  -- all balls finished moving
  if not isanyballmoving() then
    endshot()
  end
end

function endshot()
  isbreak = false
  -- determine if shot legal
  local foul
  -- must not sink the white
  if sunkwhite then
    foul = "white ball sunk"
  -- must strike a ball
  elseif not firsthit then
    foul = "no ball hit"
  -- must strike the correct type of ball (over/under)
  else
    local reqtyp = player.balltyp
    if reqtyp == "overs" and prevoverct == 0 or reqtyp == "unders" and prevunderct == 0 then
      reqtyp = "black"
    end
    if player.balltyp and firsthit.typ ~= reqtyp then
      foul = "hit wrong colour first"
    end
  end
  -- must not sink opponent's balls
  if not foul then
    if player.balltyp == "overs" and sunkunder or player.balltyp == "unders" and sunkover then
      foul = "sank wrong colour"
    end
  end
  -- game ends when black sunk
  if sunkblack then
    -- no balls sunk->loss
    if not player.balltyp then
      gamelost("black ball sunk")
      return
    end
    -- colour balls unsunk->loss
    local ct = player.balltyp == "overs" and overct or underct
    if ct > 0 then
      gamelost("black ball sunk")
      return
    end
    -- must not foul when sinking black
    if foul then
      gamelost("fouled on black", foul)
      return
    end
    -- otherwise game is won!
    gamewon()
    return
  end
  if foul then
    showtickermsg(player.name .. " fouled - " .. foul)
  end
  -- determine player's colour
  if not player.balltyp and firstsunk then
    player.balltyp = firstsunk.typ
    if player.balltyp == "overs" then
      otherplayer.balltyp = "unders"
    else
      otherplayer.balltyp = "overs"
    end
  end
  -- replace white if sunk
  if sunkwhite then
    -- place white back on table
    white.pos = vec(0, baulk)
    white.vel = vec()
    add(balls, white)
  end
  -- is player allowed to continue?
  -- can continue if they have a free ball.
  local continue = freeball
  freeball = false
  -- can continue if they sunk a ball
  if player.balltyp == "overs" and sunkover then
    continue = true
  end
  if player.balltyp == "unders" and sunkunder then
    continue = true
  end
  -- cannot continue after a foul
  if foul then
    continue = false
    freeball = true
  -- other player gets a free ball
  end
  if continue then
    setupforshot()
  else
    nextplayershot(sunkwhite)
  end
end

function isanyballmoving()
  for ball in all(balls) do
    if isballmoving(ball) then
      return true
    end
  end
  return false
end

function isballmoving(ball)
  return ball.vel:length() ~= 0
end

-- ball and corner collision
function ballcorner(ball, corner)
  -- ball pos rel to corner
  local l = ball.pos - corner
  -- ignore if ball moving away
  if (l * ball.vel) >= 0 then
    return
  end
  -- ball moving away
  -- line-circle intersection to
  -- find collision dist.
  local t = linecirc(l, ball.vel, ballrad)
  if not t then
    return
  end
  t = max(t, 0)
  -- calculate collision position
  local p = l + ball.vel * t
  -- calculate collision normal
  local n = p:normalised()
  return t, n
end

-- ball and edge collision
function balledge(ball, edge)
  -- line tangent and normal
  local p = (edge.p2 - edge.p1):normalised()
  local n = vec(-p[2], p[1])
  if n * ball.vel >= 0 then
    return
  end
  -- ball moving away from edige
  -- special case. 
  -- look for ball already penetrating
  -- wall.
  local t = rayline(ball.pos, -n * ballrad, edge.p1, edge.p2)
  if t and t < 1 then
    return 0, n
  end
  local t = rayline(ball.pos - n * ballrad, ball.vel, edge.p1, edge.p2)
  if not t then
    return
  end
  return t, n
end

-- ball and ball collision
function ballball(b1, b2)
  -- line circle intersection
  -- find ball 1 pos and vel
  -- relative to b2.
  -- find intersection with circle
  -- with twice the ball radius
  local p = b1.pos - b2.pos
  local v = b1.vel - b2.vel
  -- balls moving away?
  if p * v > 0 then
    return
  end
  -- line circle intersection
  local r = ballrad * 2
  -- need to scale down to avoid numeric overflow
  p = p / (8)
  v = v / (8)
  r = r / (8)
  local t = linecirc(p, v, r)
  if not t then
    return
  end
  t = max(t, 0)
  -- find ball collision positions
  local c1 = b1.pos + b1.vel * t
  local c2 = b2.pos + b2.vel * t
  -- calculate collision normal
  local n = (c1 - c2):normalised()
  return t, n
end

function getinput()
  local xi, yi = 0, 0
  if btn(0) then
    xi = xi - (1)
  end
  if btn(1) then
    xi = xi + (1)
  end
  if not btn(4) then
    if btn(2) then
      yi = yi - (1)
    end
    if btn(3) then
      yi = yi + (1)
    end
  end
  if (xinp < 0 and xi >= 0) or (xinp > 0 and xi <= 0) then
    xinp = 0
  else
    xinp = xinp + (xi * 0.04)
  end
  xinp = clamp(xinp, -1, 1)
  yinp = yinp * .9 + yi * .1
  if abs(xinp) < 0.001 then
    xinp = 0
  end
  if abs(yinp) < 0.001 then
    yinp = 0
  end
  return xinp, yinp
end

function gamewon()
  winner = player
  showtickermsg("congratulations " .. player.name)
  gamedone()
end

function gamelost(reason, foul)
  winner = otherplayer
  local msg = player.name .. " lost - " .. reason
  if foul then
    msg = msg .. (" (" .. foul .. ")")
  end
  showtickermsg(msg)
  gamedone()
end

function gamedone()
  -- switch back to main menu after demo
  if players[1].npc then
    mainmenu()
  else
    -- otherwise switch to post game mode
    initmenu()
    if players[1].npc then
      -- demo mode?
      mode = mode_menu
    else
      mode = mode_postgame
    end
  end
end

function updatepostgame()
  local option = domenu(2)
  if option == 1 then
    newgame(players[2].npc, players[1].npc)
  end
  if option == 2 then
    mainmenu()
  end
end

function updatemenu()
  -- demo game after 100s
  menutimer = menutimer + (1)
  if menutimer > 3000 then
    demo()
  end
  -- otherwise
  local option = domenu(3)
  if option == 1 then
    newgame(rnd(npctypes))
  end
  if option == 2 then
    newgame()
  end
  if option == 3 then
    demo()
  end
end

function demo()
  local npc1, npc2
  repeat
    npc1, npc2 = rnd(npctypes), rnd(npctypes)
  until npc1 ~= npc2
  newgame(npc1, npc2)
end

function domenu(ct)
  if btnp(2) and menuoption > 1 then
    menuoption = menuoption - (1)
    menutimer = 0
    sfx(11)
  end
  if btnp(3) and menuoption < ct then
    menuoption = menuoption + (1)
    menutimer = 0
    sfx(11)
  end
  -- animate ball
  menuy = moveto(menuy, menuoption, 1 / 6)
  if btnp(5) or btnp(4) then
    sfx(13)
    return menuoption
  end
end

-- play ball-hit-cushion sfx
-- for given intensity
function cushionsfx(i)
  local s = i > 25 and 13 or i > 10 and 12 or i > 5 and 11 or 10
  sfx(s, 2)
end

function resetcue()
  cuepos = white.pos
  cueang = rnd(0.01) - 0.005
  campitch = -0.15
end

-->8
-- rendering
function _draw()
  if mode == mode_aim then
    drawaim()
  elseif mode == mode_sim then
    drawsim()
    updatesimcam()
  elseif mode == mode_postgame then
    drawpostgame()
  elseif mode == mode_menu then
    drawmenu()
  elseif mode == mode_placeball then
    drawplaceball()
  end
  -- ticker is common across all modes
  drawtickermsg()
end

function drawaim()
  -- camera logic
  local targetfov = 53 - campitch * 500
  local targetang, targetcam = cueang, white.pos
  if campitch == 0 then
    targetang, targetcam = 0.25, vec()
    angf = 0.15
  else
    angf = min(angf + 0.02, 1)
  end
  smoothmovecam(targetcam, 100, targetfov, targetang)
  -- draw table  
  rendertable(true)
  -- draw ui
  camera()
  drawgameui()
  drawinputhints()
end

function smoothmovecam(targetcam, targetzoom, targetfov, targetang)
  if targetang then
    local delta = targetang - camang
    delta = delta - (flr(delta))
    if delta > 0.5 then
      delta = delta - (1)
    end
    camang = camang + (delta * angf)
  end
  if targetcam then
    cam = cam * 0.8 + targetcam * 0.2
  end
  if targetfov then
    fov = fov * 0.8 + targetfov * 0.2
  end
  if targetzoom then
    camzoom = camzoom * 0.95 + targetzoom * 0.05
  end
end

function drawplaceball()
  -- line up camera
  smoothmovecam(vec(0, tablel * 0.4, 0), 100, 100, 0)
  campitch = campitch * 0.95 + -0.138 * 0.05
  -- draw table  
  rendertable(false)
  -- draw ui
  camera()
  drawgameui()
  drawinputhints()
end

function drawsim()
  -- draw table  
  rendertable(true)
  -- draw ui
  camera()
  drawgameui()
  drawinputhints()
end

function updatesimcam()
  -- raise camera upwards if close to table
  if campitch < -0.175 then
    campitch = campitch * 0.95 - 0.175 * 0.05
  end
  -- widen field of view if necessary
  if fov > 120 then
    fov = fov * 0.99 + 120 * 0.01
  end
  -- zoom out if necessary to keep
  -- moving balls in view
  local zoom = min(camzoom, 150)
  local center, ct = vec(), 0
  for ball in all(balls) do
    if isballmoving(ball) then
      local p = ball.xfrm
      local ballzoom = (max(abs(p[1]), abs(p[2])) + 10) * fov / 55 - p[3] + camzoom
      zoom = max(zoom, ballzoom)
      center = center + (ball.pos)
      ct = ct + (1)
    end
  end
  -- move cam towards center if
  local centercam = false
  -- any balls are moving
  if ct > 0 then
    center = center / (ct)
    -- table center is closer to center of moving balls
    -- than the camera is.
    if center:length() < (cam - center):length() then
      -- not all balls in view
      if zoom > camzoom then
        centercam = true
      end
    end
  end
  -- move camera towards center
  -- with smoothing.
  if centercam then
    centercamf = centercamf + (0.02)
  else
    centercamf = centercamf - (0.02)
  end
  centercamf = clamp(centercamf, 0, 1)
  cam = cam * ((1 - centercamf * 0.1))
  -- adjust zoom
  -- zoom out fast. zoom back in slow.
  local zoomf = zoom > camzoom and 0.125 or 0.04
  camzoom = camzoom * (1 - zoomf) + zoom * zoomf
end

function drawpostgame()
  -- camera logic
  --targetcam,targetzoom,targetfov,targetang)
  smoothmovecam(vec(), 200, 80)
  campitch = campitch * 0.95 + -0.15 * 0.05
  camang = camang + (0.001)
  -- draw table
  rendertable(true)
  -- draw ui
  camera()
  drawgameui()
  -- win message
  if (framect & 16) == 16 then
    prettyprintcentered(winner.name .. " wins", 10, 7)
  end
  -- post game menu
  prettyprintcentered("rematch", 32, menuoption == 1 and 7 or 5)
  prettyprintcentered("main menu", 42, menuoption == 2 and 7 or 5)
  palt(3, true)
  spr(3, 32, (menuy - 1) * 10 + 32 - 2)
  palt(3, false)
end

function drawmenu()
  -- camera logic
  fov = fov * 0.975 + 80 * 0.025
  campitch = campitch * 0.95 + -0.19 * 0.05
  camzoom = camzoom * 0.95 + 200 * 0.05
  camang = camang + (0.001)
  cam = cam * 0.95
  -- draw table
  rendertable(false)
  -- draw ui
  camera()
  -- logo
  palt(1, true)
  spr(8, 32, 15, 8, 4)
  palt(1, false)
  prettyprintcentered("mOT'S 8-bALL", 11, 6)
  -- main menu
  prettyprintcentered("1-player vs cpu", 90, menuoption == 1 and 7 or 5)
  prettyprintcentered("2-player", 100, menuoption == 2 and 7 or 5)
  prettyprintcentered("demo", 110, menuoption == 3 and 7 or 5)
  palt(3, true)
  spr(3, 22, (menuy - 1) * 10 + 90 - 2)
  palt(3, false)
end

yoffs = 0

function rendertable(drawcue)
  cls(1)
  palt(0, false)
  camera(-64, -64)
  -- camera transform
  local tyoffs = campitch ~= 0 and (campitch + 0.22) * 275 or 0
  yoffs = yoffs * 0.7 + tyoffs * 0.3
  cammat = translate(0, yoffs, camzoom) * rotx(campitch) * rotz(-camang) * translate(-cam)
  -- camera pt in world space
  local camw = cammat:cheapinverse():transformpt(vec(0, 0, 0))
  -- transform and project vertices
  transformverts(allverts, cammat)
  -- render base
  rendermesh(basemesh)
  -- markings
  rendermesh(markingsmesh)
  -- render pockets
  for m in all(pocketmeshes) do
    rendermesh(m)
  end
  for m in all(cushionmeshes) do
    rendermesh(m)
  end
  -- draw cushion tops behind balls
  if camw[2] > -tablel / 2 then
    rendermesh(cushiontopmesht)
  end
  if camw[2] < tablel / 2 then
    rendermesh(cushiontopmeshb)
  end
  if camw[1] > -tablew / 2 then
    rendermesh(cushiontopmeshl)
  end
  if camw[1] < tablew / 2 then
    rendermesh(cushiontopmeshr)
  end
  rendermesh(cushionsidemesh)
  -- balls
  local vis = {}
  for b in all(balls) do
    -- transform into camera space
    b.xfrm = cammat:transformpt(b.pos)
    -- z clip
    if b.xfrm[3] >= 2 then
      local scale = fov / b.xfrm[3]
      b.proj = {b.xfrm[1] * scale, b.xfrm[2] * scale, scale}
      -- insert ball into visible array
      -- in back to front order.
      local i = 1
      while i <= #vis and b.xfrm[3] < vis[i].xfrm[3] do
        i = i + (1)
      end
      add(vis, b, i)
    end
  end
  local hoffs = vec(1, 1) * ballrad * -0.3
  for b in all(vis) do
    local scale = b.proj[3]
    -- circle
    color(b.col)
    rendercircle(b.proj[1], b.proj[2], ballrad * scale)
    -- highlight
    pset(b.proj[1] - 1.5 * scale + 0.5, b.proj[2] - 2 * scale + 0.5, 7)
  end
  -- draw cushion tops in front of balls
  if camw[2] <= -tablel / 2 then
    rendermesh(cushiontopmesht)
  end
  if camw[2] >= tablel / 2 then
    rendermesh(cushiontopmeshb)
  end
  if camw[1] <= -tablew / 2 then
    rendermesh(cushiontopmeshl)
  end
  if camw[1] >= tablew / 2 then
    rendermesh(cushiontopmeshr)
  end
  -- cue
  if mode == mode_aim then
    cuepos = white.pos
  end
  if drawcue then
    local d = ballrad
    if mode == mode_aim then
      d = d + (cuepow)
    end
    cammat = cammat * translate(cuepos) * rotz(cueang) * rotx(-0.02) * translate(0, d, 0)
    transformverts(cueverts, cammat)
    rendermesh(cuemesh)
  end
  fillp(0)
end

function drawgameui()
  palt(3, true)
  drawplayerui(players[1], true)
  drawplayerui(players[2], false)
  palt(3, false)
end

function drawtickermsg()
  if tickermsg then
    prettyprint(tickermsg, tickerx, 121, 9)
  end
end

function drawplayerui(p, left)
  -- player 1
  cursor(0, 0)
  local col = 7
  if p == player and (framect & 8) == 8 then
    col = 13
  end
  if left then
    prettyprint(p.name, 2, 112, col)
  else
    prettyprint(p.name, 127 - #p.name * 4, 112, col)
  end
  if p.balltyp then
    local s, ct
    if p.balltyp == "overs" then
      s = 1
      ct = 7 - overct
    else
      s = 2
      ct = 7 - underct
    end
    if mode ~= mode_sim then
      p.ballct = min(p.ballct + 1 / 8, ct)
    end
    local s2 = s
    if ct == 7 then
      s2 = 4
    end
    local offs = ceil(p.ballct) - p.ballct
    if left then
      spr(s2, #p.name * 4 + 3, 111)
      for i = 1, ceil(p.ballct) do
        spr(s, (i - offs) * 8 - 7, 102)
      end
    else
      spr(s2, 117 - #p.name * 4, 111)
      for i = 1, ceil(p.ballct) do
        spr(s, 127 - (i - offs) * 8, 102)
      end
    end
  end
  if freeball and p == player then
    if left then
      spr(3, #p.name * 4 + 12, 111)
    else
      spr(3, 124 - #p.name * 4 - 16, 111)
    end
  end
end

hinty = -10

function drawinputhints()
  if (mode == mode_aim or mode == mode_placeball) and inputhints and not player.npc then
    hinty = hinty + (2)
  else
    hinty = hinty - (2)
  end
  hinty = clamp(hinty, -10, 4)
  if hinty <= -10 then
    return
  end
  if mode == mode_aim or mode == mode_sim then
    if mode == mode_aim and btn(4) then
      print("2", 4, hinty - 3, 6)
      print("3", 4, hinty + 3, 6)
      local p = 55 * (cuepow / cuemax)
      rectfill(36, hinty, 36 + p, hinty + 4, 8)
      rect(35, hinty - 1, 92, hinty + 5, 0)
    else
      print("4", 4, hinty, 6)
    end
    prettyprint("power", 14, hinty, 7)
    print("5", 95, hinty, 6)
    prettyprint("shoot", 105, hinty, 7)
  elseif mode == mode_placeball then
    print("2", 10, hinty - 3, 6)
    print("3", 10, hinty + 7, 6)
    print("0 1", 4, hinty + 2, 6)
    prettyprint("move ball", 26, hinty + 2, 7)
    print("5/4", 86, hinty + 2, 6)
    prettyprint("done", 108, hinty + 2, 7)
  end
end

function transformverts(verts, mat)
  for p in all(verts) do
    p.xfrm = mat:transformpt(p.pt)
    if p.xfrm[3] >= 2 then
      local scale = fov / p.xfrm[3]
      p.proj = {p.xfrm[1] * scale, p.xfrm[2] * scale}
    else
      p.proj = nil
    end
  end
end

function rendermesh(mesh)
  for poly in all(mesh) do
    renderpoly(poly)
  end
end

function renderpoly(poly)
  -- camera space normal
  local n = cammat:transformvec(poly.n)
  -- skip back facing polys
  if (n * poly.verts[1].xfrm > 0) then
    return
  end
  fillp(poly.pat or 0)
  color(poly.col)
  -- build array of screen space verts
  local ssv = {}
  local pv = poly.verts[#poly.verts]
  for v in all(poly.verts) do
    -- if edge from pv to v crosses 
    -- nearz plane, insert a new
    -- vert at the intersection
    if pv.proj and not v.proj or not pv.proj and v.proj then
      -- find fractional distance to plane
      local d = v.xfrm - pv.xfrm
      local f = (2 - pv.xfrm[3]) / d[3]
      -- get intersection
      local p = pv.xfrm + d * f
      -- project
      local scale = fov / p[3]
      local pr = {p[1] * scale, p[2] * scale}
      add(ssv, pr)
    end
    -- add current vert
    if v.proj then
      add(ssv, v.proj)
    end
    pv = v
  end
  -- find index of topmost pt
  local top, topi
  for i, v in pairs(ssv) do
    if not top or v[2] < top[2] then
      top, topi = v, i
    end
  end
  if not top then
    return
  end
  -- trace left and right sides of poly
  local l, r, pl, pr = topi, topi
  local y = max(ceil(top[2]), -64)
  local firstl, firstr = true, true
  local lx, lxd, rx, rxd
  while y < 64 do
    if ssv[l][2] <= y then
      repeat
        if not firstl and l == r then
          return
        -- reached bottom of poly      
        end
        pl = l
        l = l + (1)
        if l > #ssv then
          l = 1
        end
        firstl = false
      until ssv[l][2] > y
      -- find left x and gradient
      local p1, p2 = ssv[pl], ssv[l]
      lxd = (p2[1] - p1[1]) / (p2[2] - p1[2])
      lx = p1[1] + lxd * (y - p1[2])
    end
    if ssv[r][2] <= y then
      repeat
        if not firstr and l == r then
          return
        -- reached bottom of poly
        end
        pr = r
        r = r - (1)
        if r <= 0 then
          r = #ssv
        end
        firstr = false
      until ssv[r][2] > y
      -- find right x and gradient
      local p1, p2 = ssv[pr], ssv[r]
      rxd = (p2[1] - p1[1]) / (p2[2] - p1[2])
      rx = p1[1] + rxd * (y - p1[2])
    end
    local lrx = ceil(lx)
    local rrx = flr(rx)
    if rrx >= lrx then
      rectfill(lrx, y, rrx, y)
    end
    lx = lx + (lxd)
    rx = rx + (rxd)
    y = y + (1)
  end
end

function rendercircle(x, y, rad)
  if aligncirc == 1 then
    x = flr(x + 0.5)
    y = flr(y + 0.5)
  elseif aligncirc == 2 then
    x = flr(x * 2 + 0.5) / 2
    y = flr(y * 2 + 0.5) / 2
  end
  local y0 = max(ceil(y - rad), -64)
  local y1 = min(ceil(y + rad), 64)
  if y1 <= y0 then
    return
  end
  local rad2 = rad * rad
  for ry = y0, y1 - 1, 1 do
    --(x0-x)^2+(ry-y)^2=rad^2
    --x0-x=sqrt(rad^2-(ry-y)^2)
    local s = rad2 - (ry - y) * (ry - y)
    if s > 0 then
      local dx = sqrt(s)
      local x0 = ceil(x - dx)
      local x1 = ceil(x + dx)
      if x1 > x0 then
        rectfill(x0, ry, x1 - 1, ry)
      end
    end
  end
end

-->8
-- routines
function makebounds(pt, size)
  size = size or 0
  return {mn = {pt[1] - size, pt[2] - size}, mx = {pt[1] + size, pt[2] + size}}
end

function addboundpt(bounds, pt, size)
  size = size or 0
  local mn, mx = bounds.mn, bounds.mx
  mn[1] = min(mn[1], pt[1] - size)
  mn[2] = min(mn[2], pt[2] - size)
  mx[1] = max(mx[1], pt[1] + size)
  mx[2] = max(mx[2], pt[2] + size)
end

function ptinbounds(bounds, pt)
  return bounds.mn[1] <= pt[1] and bounds.mn[2] <= pt[2] and bounds.mx[1] >= pt[1] and bounds.mx[2] >= pt[2]
end

function boundsintersect(b1, b2)
  return b1.mx[1] > b2.mn[1] and b1.mn[1] < b2.mx[1] and b1.mx[2] > b2.mn[2] and b1.mn[2] < b2.mx[2]
end

function clamp(v, mn, mx)
  return min(max(v, mn), mx)
end

function moveto(v, t, d)
  if abs(t - v) <= d then
    return t
  else
    return v + sgn(t - v) * d
  end
end

function prettyprint(text, x, y, c)
  for ox = -1, 1 do
    for oy = -1, 1 do
      print(text, x + ox, y + oy, 0)
    end
  end
  print(text, x, y, c)
end

function prettyprintcentered(text, y, c)
  prettyprint(text, 64 - #text * 2, y, c)
end

-->8
-- initialisation
function _init()
  poke(0x5f5c, 255)
  -- no btnp repeat
  loadsettings()
  makepooltable()
  makemeshes()
  -- set camera to initial state
  camzoom = 100
  cam = vec(0, 1000, -1000)
  initmenuitems()
  mainmenu()
end

function loadsettings()
  cartdata("mot_pool")
  if dget(0) > 0 then
    aligncirc = dget(1)
    inputhints = dget(2) ~= 0
    xinpfactor = sgn(dget(3))
  end
end

function savesettings()
  dset(0, 1)
  dset(1, aligncirc)
  dset(2, inputhints and 1 or 0)
  dset(3, xinpfactor)
end

function initmenuitems()
  menuitem(2, "show keys:" .. (inputhints and "on" or "off"), function()
    inputhints = not inputhints
    savesettings()
    initmenuitems()
  end)
  menuitem(3, "balls:" .. (aligncirc == 0 and "sub-pixel" or aligncirc == 1 and "snap" or "snap-half"), function()
    aligncirc = (aligncirc + 1) % 3
    savesettings()
    initmenuitems()
  end)
  menuitem(4, "invert x-axis", function()
    xinpfactor = -xinpfactor
    savesettings()
  end)
end

function initmenu()
  menuoption, menuy, menutimer = 1, 1, 0
end

function makepooltable()
  -- table outline
  table, pockets, sinks, corners, edges = {}, {}, {}, {}, {}
  addcornerpocket(1, -1)
  addsidepocket(1)
  addcornerpocket(1, 1)
  addcornerpocket(-1, 1)
  addsidepocket(-1)
  addcornerpocket(-1, -1)
  -- corners
  for t in all(table) do
    if t.sharp then
      add(corners, t.pt)
    end
  end
  -- edges
  local ii = #table
  for i = 1, #table do
    if table[i].sharp or table[ii].sharp then
      local edge = {p1 = table[ii].pt, p2 = table[i].pt}
      calcedgebounds(edge)
      add(edges, edge)
      ii = i
    end
  end
end

function makemeshes()
  -- table outer width and length
  -- (actually halved)
  local tw = tablew / 2 + 4 * ballrad
  local tl = tablel / 2 + 4 * ballrad
  basemesh = makebasemesh(tw, tl)
  markingsmesh = makemarkingsmesh()
  -- cushion height
  local ch = ballrad * 2 * 0.62
  -- pockets
  pocketmeshes = {}
  for p in all(pockets) do
    add(pocketmeshes, makepocketmesh(p, ch))
  end
  -- cushions
  cushionmeshes = {}
  local prevp = pockets[#pockets]
  for p in all(pockets) do
    add(cushionmeshes, makecushionmesh(prevp, p, ch))
    prevp = p
  end
  -- cushion top
  local ctverts = makecushiontopverts(tw, tl, ch)
  cushiontopmesht = makecushiontopmesh(ctverts, 6, 1)
  cushiontopmeshr = makecushiontopmesh(ctverts, 1, 3)
  cushiontopmeshb = makecushiontopmesh(ctverts, 3, 4)
  cushiontopmeshl = makecushiontopmesh(ctverts, 4, 6)
  -- cushion sides
  cushionsidemesh = makecushionsidemesh(tw, tl, ch)
  -- cue stick
  cuemesh = makecuemesh()
end

function makebasemesh(tw, tl)
  -- bottom outer width and length (halved)
  local bw = tw * 0.9
  local bl = tl * 0.9
  local bvecs = {vert(-tw, tl, ballrad), vert(tw, tl, ballrad), vert(tw, -tl, ballrad), vert(-tw, -tl, ballrad), vert(-bw, bl, tableh), vert(bw, bl, tableh), vert(bw, -bl, tableh), vert(-bw, -bl, tableh)}
  return makemesh(bvecs, {{col = 3, i = split "1,2,3,4"}, {col = 0, i = split "8,7,6,5"}, {col = 5, i = split "2,1,5,6"}, {col = 6, i = split "3,2,6,7"}, {col = 5, i = split "4,3,7,8"}, {col = 6, i = split "1,4,8,5"}})
end

function makemarkingsmesh()
  local tw = tablew / 2
  -- baulk line vertices
  local bvecs = {vert(-tw, baulk, ballrad), vert(tw, baulk, ballrad), vert(tw, baulk - 2, ballrad), vert(-tw, baulk - 2, ballrad)}
  local polys = {{col = 5, i = split "1,2,3,4"}}
  -- d
  add(bvecs, vert(0, baulk, ballrad))
  local di = #bvecs
  for i = 0, 0.5, 1 / 16 do
    local v = vert(cos(i) * drad, baulk - sin(i) * drad, ballrad)
    add(bvecs, v)
    if i > 0 then
      add(polys, {col = 0x35, pat = 0xa5a5, i = {di, #bvecs, #bvecs - 1}})
    end
  end
  return makemesh(bvecs, polys)
end

function makepocketmesh(pocket, ch)
  -- find vertices
  local verts = {}
  for i = pocket.from, pocket.to do
    local v = table[i].pt
    add(verts, vert(v + vec(0, 0, ballrad - ch)))
    -- rim vertex
    add(verts, vert(v + vec(0, 0, ballrad)))
  -- inside vertex
  end
  -- tesellate
  local polys = tesellatestrip(1, #verts, 5)
  -- make mesh
  return makemesh(verts, polys)
end

function makecushionmesh(pocket1, pocket2, ch)
  local v1 = table[pocket1.to].pt
  local v2 = table[pocket2.from].pt
  local verts = {vert(v1 + vec(0, 0, ballrad - ch)), vert(v1 + vec(0, 0, ballrad)), vert(v2 + vec(0, 0, ballrad - ch)), vert(v2 + vec(0, 0, ballrad))}
  return makemesh(verts, {{col = 0x3b, pat = 0xa5a5, i = {1, 2, 4, 3}}})
end

-- create cushion top mesh between 2 pockets
function makecushiontopmesh(verts, i1, i2)
  -- lookup pockets
  local p1, p2 = pockets[i1], pockets[i2]
  -- find pocket mid points.
  -- convert to corresponding indices
  -- in quad strip verts.
  local from = ((p1.from - 1 + p1.to - 1) // 2) * 2 + 1
  local to = ((p2.from - 1 + p2.to - 1) // 2) * 2 + 2
  -- tesellate quad strip range range
  local polys
  if from < to then
    polys = tesellatestrip(from, to, 4, nil)
  else
    polys = concat(tesellatestrip(from, #verts, 4, nil), tesellatestrip(1, to, 4, nil))
    add(polys, closestrippoly(1, #verts, 4, nil))
  end
  -- make mesh
  return makemesh(verts, polys)
end

function makecushiontopverts(tw, tl, ch)
  local verts = {}
  for i = 1, #table do
    local v1 = table[i].pt
    -- 2nd vertex is v1 projected out to table edge rectangle
    local dw = tw / abs(v1[1])
    local dl = tl / abs(v1[2])
    local d = min(dw, dl)
    local v2 = v1 * d
    if dw < dl + 0.1 then
      v2[1] = sgn(v2[1]) * tw
    end
    if dl < dw + 0.1 then
      v2[2] = sgn(v2[2]) * tl
    end
    add(verts, vert(v2 + vec(0, 0, ballrad - ch)))
    add(verts, vert(v1 + vec(0, 0, ballrad - ch)))
  end
  return verts
end

function makecushionsidemesh(tw, tl, ch)
  local vecs = {vert(-tw, tl, ballrad - ch), vert(tw, tl, ballrad - ch), vert(tw, -tl, ballrad - ch), vert(-tw, -tl, ballrad - ch), vert(-tw, tl, ballrad), vert(tw, tl, ballrad), vert(tw, -tl, ballrad), vert(-tw, -tl, ballrad),}
  return makemesh(vecs, {{col = 5, i = split "2,1,5,6"}, {col = 6, i = split "3,2,6,7"}, {col = 5, i = split "4,3,7,8"}, {col = 6, i = split "1,4,8,5"}})
end

function makecuemesh()
  -- vertices
  cueverts = {}
  for i = 0, 1, cuestep do
    local s, c = sin(i), cos(i)
    add(cueverts, {pt = vec(s * cuerad1, 0, c * cuerad1)})
    add(cueverts, {pt = vec(s * cuerad2, cuelen, c * cuerad2)})
  end
  -- body
  local polys = tesellatestrip(1, #cueverts, 0x04, 0xa5a5, true)
  -- cap at end
  local capi = {}
  for i = #cueverts, 2, -2 do
    add(capi, i)
  end
  add(polys, {col = 4, i = capi})
  return makemesh(cueverts, polys)
end

function vert(x, y, z)
  local v = {}
  if getmetatable(x) == tvec then
    v.pt = x
  else
    v.pt = vec(x, y, z)
  end
  for e in all(allverts) do
    if e.pt[1] == v.pt[1] and e.pt[2] == v.pt[2] and e.pt[3] == v.pt[3] then
      return e
    end
  end
  add(allverts, v)
  return v
end

function makemesh(verts, polys)
  local mesh = {}
  for p in all(polys) do
    -- create poly
    local poly = {col = p.col, pat = p.pat, verts = {}}
    -- add references to verts
    for i in all(p.i) do
      add(poly.verts, verts[i])
    end
    -- calculate normal
    local v1, v2, v3 = poly.verts[1].pt, poly.verts[2].pt, poly.verts[3].pt
    local e1, e2 = (v3 - v2) / 16, (v1 - v2) / 16
    local n = (e1:cross(e2)):normalised()
    poly.n = n
    add(mesh, poly)
  end
  return mesh
end

function tesellatestrip(from, to, col, pat, close)
  local polys = {}
  for i = from, to - 3, 2 do
    add(polys, {col = col, pat = pat, i = {i, i + 1, i + 3, i + 2}})
  end
  if close then
    add(polys, closestrippoly(from, to, col, pat))
  end
  return polys
end

function closestrippoly(from, to, col, pat)
  return {col = col, pat = pat, i = {to - 1, to, from + 1, from}}
end

function concat(a, b)
  local r = {}
  for e in all(a) do
    add(r, e)
  end
  for e in all(b) do
    add(r, e)
  end
  return r
end

function makeballs()
  balls = {}
  -- white ball
  white = {typ = "white", pos = vec(0, baulk), vel = vec(), col = 7}
  add(balls, white)
  -- rack
  local spacing = ballrad * 2.0625
  local pos = vec(0, -tablel / 4 + spacing * 3)
  local typs, i = split "1,2,1,1,0,2,2,1,2,1,1,2,1,2,2", 1
  for r = 0, 4 do
    for c = 0, r do
      -- create ball
      local ballpos = pos + vec(-r / 2 + c, -r) * rackspacing + vec(rnd(2) - 1, rnd(2) - 1) * rackjitter
      local ball = {pos = ballpos, vel = vec()}
      typ = typs[i]
      if typ == 0 then
        ball.typ = "black"
        ball.col = 0
        black = ball
      elseif typ == 1 then
        ball.typ = "overs"
        ball.col = 8
      else
        ball.typ = "unders"
        ball.col = 9
      end
      add(balls, ball)
      -- track the black ball
      if coll == 0 then
        black = ball
      end
      i = i + (1)
    end
  end
end

function addcornerpocket(x, y)
  -- create pocket object
  -- this is used later when 
  -- creating the mesh model to
  -- find the pocket vertices.
  local pocket = {from = #table + 1, x = x, y = y}
  -- create table vertices for pocket
  local d = 2 * sqrt(2) * pocketrad
  local p = vec(x * tablew / 2, y * tablel / 2)
  local a1, a2, step
  if sgn(x) == sgn(y) then
    a1, a2, step = 0.75, 0, -pocketstep
  else
    a1, a2, step = 0, 0.75, pocketstep
  end
  local firstpt, lastpt
  for a = a1, a2, step do
    local r = max(abs(a - 0.375) - 0.3, 0)
    local sharp = r > 0
    r = (r * r * 100 + 1) * pocketrad
    local pt = p - vec(cos(a) * x, sin(a) * y) * r
    local t = {pt = pt, sharp = true
    --sharp
    }
    add(table, t)
    -- track first and last pt for sink edge
    firstpt = firstpt or pt
    lastpt = pt
  end
  -- create "sink" edge
  local sink = {p1 = firstpt, p2 = lastpt, pm = (firstpt + lastpt) / 2}
  calcsinkprops(sink)
  add(sinks, sink)
  -- store pocket
  pocket.to = #table
  add(pockets, pocket)
end

function addsidepocket(x)
  -- create pocket object
  -- this is used later when 
  -- creating the mesh model to
  -- find the pocket vertices.
  local pocket = {from = #table + 1, x = x, y = 0}
  -- create table vertices for pocket
  local d = pocketrad
  local px = x * tablew / 2
  local firstpt = vec(px, -d * x)
  add(table, {pt = firstpt, sharp = true})
  for a = 0.25, 0.75, pocketstep do
    local r = 0
    --max(abs(a-0.5)-0.22,0)
    local sharp = r > 0
    r = (r * r * 100 + 1) * pocketrad
    local pt = vec(px + pocketrad / 2 * x - cos(a) * r * x, sin(a) * r * x)
    local t = {pt = pt, sharp = true
    --sharp
    }
    add(table, t)
  end
  local lastpt = vec(px, d * x)
  add(table, {pt = lastpt, sharp = true})
  -- create "sink" edge
  local sink = {p1 = firstpt, p2 = lastpt, pm = (firstpt + lastpt) / 2}
  calcsinkprops(sink)
  add(sinks, sink)
  -- store pocket
  pocket.to = #table
  add(pockets, pocket)
end

function calcedgebounds(edge)
  edge.bounds = makebounds(edge.p1)
  addboundpt(edge.bounds, edge.p2)
end

function calcsinkprops(sink)
  calcedgebounds(sink)
  local d = sink.p2 - sink.p1
  sink.w = d:length()
  sink.n = vec(d[2], -d[1]):normalised()
end

-->8
-- trig
-- intersection of line from 
-- l in direction d with 
-- circle at origin with radius r
function linecirc(l, d, r)
  -- basically solving for t:
  --   (l+td)^2=r^2
  -- =>d.dt^2+2l.dt+l.l-r^2=0
  -- then use quadratic formula
  -- with:
  -- a=d.d
  -- b=2l.d
  -- c=l.l-r^2
  local t1, t2 = quadratic(d * d, 2 * (l * d), l * l - r * r)
  return t1 and min(t1, t2)
end

function quadratic(a, b, c)
  -- square root term of quadratic formula
  local s = b * b - 4 * a * c
  if s < 0 then
    return nil
  end
  -- no solution
  local sqrts = sqrt(s)
  -- solve for first intersection
  -- using quadratic formula
  return (-b + sqrts) / (2 * a), (-b - sqrts) / (2 * a)
end

-- find distance to intersection
-- between ray at r, direction d
-- and line from l1-l2.
-- returns multiple of d, i.e.
-- r+d*result intersects l1-l2
function rayline(r, d, l1, l2)
  -- transform relative to l1
  r = r - (l1)
  l2 = l2 - (l1)
  -- line tangent and normal
  local p = l2:normalised()
  local n = vec(-p[2], p[1])
  -- dot products
  local nr, nd = r * n, d * n
  if sgn(nr) == sgn(nd) then
    return nil
  end
  -- ray facing away
  if sgn(nr) == sgn(nr + nd * 100) then
    return nil
  end
  -- ray doesn't reach line after 100 units
  -- nr+nd*t=0 => t=-nr/nd
  local t = -nr / nd
  -- intersection
  local i = r + d * t
  -- is point between 0-l2?
  local pi = i * p
  if pi < 0 or pi > l2 * p then
    return nil
  end
  -- intersection found
  return t
end

-->8
-- matrix and vector
------------------------------------------
-- 3d vector
tvec = {__add = function(a, b)
  return vec(a[1] + b[1], a[2] + b[2], a[3] + b[3])
end, __sub = function(a, b)
  return vec(a[1] - b[1], a[2] - b[2], a[3] - b[3])
end, __unm = function(a)
  return a * -1
--vec(-a[1],-a[2],-a[3])
end, __mul = function(a, b)
  if getmetatable(b) == tvec then
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
  else
    return vec(a[1] * b, a[2] * b, a[3] * b)
  end
end, __div = function(a, b)
  return a * (1 / b)
end, __tostring = function(s)
  return s:tostring()
end,
-- __concat=function(a,b)
--  if(getmetatable(a)==tvec)a=a:tostring()
--  if(getmetatable(b)==tvec)b=b:tostring()
--  return a..b
-- end,
__index = {length = function(s)
  return sqrt(s * s)
end, tostring = function(s)
  return "(" .. s[1] .. "," .. s[2] .. "," .. s[3] .. ")"
end, normalised = function(s)
  return s / s:length()
end, cross = function(a, b)
  return vec(a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
end}}

function vec(x, y, z)
  local v = {x or 0, y or 0, z or 0}
  setmetatable(v, tvec)
  return v
end

-- vector constants
--zerovec=vec(0,0,0)
unitx, unity, unitz = vec(1, 0, 0), vec(0, 1, 0), vec(0, 0, 1)
------------------------------------------
-- 3d matrix
tmat = {__mul = function(a, b)
  -- assume matrix * matrix
  local v = {vec(), vec(), vec(), vec()}
  for x = 1, 3 do
    for y = 1, 3 do
      v[x][y] = a[1][y] * b[x][1] + a[2][y] * b[x][2] + a[3][y] * b[x][3]
    end
  end
  v[4] = a:transformvec(b[4]) + a[4]
  return mat(unpack(v))
end, __tostring = function(s)
  return s:tostring()
end,
-- __concat=function(a,b)
--  if(getmetatable(a)==tmat)a=a:tostring()
--  if(getmetatable(b)==tmat)b=b:tostring()
--  return a..b
-- end,
__index = {transformvec = function(s, v)
  return s[1] * v[1] + s[2] * v[2] + s[3] * v[3]
end, transformpt = function(s, v)
  return s:transformvec(v) + s[4]
end, transposed = function(s)
  -- note: only x,y,z columns are transposed
  local v = {vec(), vec(), vec(), s[4]}
  for x = 1, 3 do
    for y = 1, 3 do
      v[x][y] = s[y][x]
    end
  end
  return mat(unpack(v))
end, cheapinverse = function(s)
  -- works only for matrices composed
  -- of rotations and translations
  local m = s:transposed()
  local w = -(m:transformvec(s[4]))
  return mat(m, w)
end, tostring = function(s)
  return "(" .. s[1] .. s[2] .. s[3] .. s[4] .. ")"
end}}

-- create matrix from basis vectors
function mat(x, y, z, w)
  if (getmetatable(x) == tmat) then
    return mat(x[1], x[2], x[3], y)
  else
    local m = {x or unitx, y or unity, z or unitz, w or vec()}
    setmetatable(m, tmat)
    return m
  end
end

-- identity matrix
--identity=mat()
-- scale matrix
--function scale(x,y,z)
-- return mat(
-- 	unitx*x,
-- 	unity*(y or x),
-- 	unitz*(z or x))
--end
function translate(x, y, z)
  if getmetatable(x) == tvec then
    return mat(unitx, unity, unitz, x)
  else
    return translate(vec(x, y, z))
  end
end

-- x axis rotation matrix
function rotx(ang)
  local s, c = sin(ang), cos(ang)
  return mat(vec(1, 0, 0), vec(0, c, -s), vec(0, s, c))
end

-- y axis rotation matrix
--function roty(ang)
-- local s,c=sin(ang),cos(ang)
-- return mat(
--  vec(c,0,-s),
--  vec(0,1,0),
--  vec(s,0,c))
--end
-- z axis rotation matrix
function rotz(ang)
  local s, c = sin(ang), cos(ang)
  return mat(vec(c, -s, 0), vec(s, c, 0), vec(0, 0, 1))
end

-- euler rotation matrix
--function euler(x,y,z)
-- return roty(y)*rotx(x)*rotz(z)
--end
-->8
-- ai
-- todo: ai params
npctypes = {{name = "q.bALLE", ac = 0.01, pow = {0.95, 2},}, {name = "i.bULLS", ac = 0.005, pow = {1, 1.2}, think = {1.5, 2.5}}, {name = "nOKOI", ac = 0.02, pow = {0.5, 2.0}, think = {0.25, 2.5}, rand = 0.5, ang = 0}, {name = "sPIDEY", ac = 0.0075, pow = {1, 1.1}, think = {2, 3}, ang = -0.1}, {name = "pkCYANIDE", ac = 0.01, pow = {1.5, 2.5}, rand = 0.015}, {name = "jIGGS", ac = 0.015, pow = {1.5, 2.0}, think = {0.5, 1}, rand = 0.01}, {name = "yOURYkIkI", ac = 0.0075, pow = {0.9, 1.4}, ang = -1}}

function wait(duration)
  for t = 0, duration, 1 / 30 do
    yield()
  end
end

function aiaim()
  local npc = player.npc
  -- table boundaries
  local tabw = tablew / 2 - ballrad + 0.01
  local tabl = tablel / 2 - ballrad + 0.01
  -- determine ball type to sink
  local reqtyp = player.balltyp
  if reqtyp == "overs" and overct == 0 or reqtyp == "unders" and underct == 0 then
    reqtyp = "black"
  end
  -- look for best ball and pocket combination
  local best, bestang, bestpow, a = 0, cueang, cuedef, white.pos
  for i, ball in ipairs(balls) do
    local b, wEIGHT = ball.pos
    -- skip balls player is not allowed to sink
    if ball == white then
      goto aiskipball
    end
    if reqtyp and reqtyp ~= ball.typ then
      goto aiskipball
    end
    if not reqtyp and ball == black then
      goto aiskipball
    end
    -- look for best sink edge (i.e. pocket)
    for sink in all(sinks) do
      -- calculate shot angle and 
      -- how "easy" it appears.
      -- where "easy" corresponds
      -- to how much the cue ball
      -- angle can vary and still
      -- expect to sink the ball.
      -- choose the "easiest" available shot.
      -- define:
      -- a =cue ball pos
      -- b =ball pos
      -- p =pocket pos
      -- x =where cue ball should strike ball
      -- nP=pocket normal
      -- wP=pocket width
      -- jP=pocket projected width
      -- cP=pocket clearance
      -- aB=ball angle range
      -- lB=ball distance to pocket
      -- dB=ball direction to pocket
      -- lA=cue ball distance to strike point
      -- dA=cue ball direction to strike point
      -- wX=target width
      -- jX=target projected width
      -- aX=target angle range
      -- sB=ball speed
      -- sX=cue ball speed at x
      -- sA=cue ball speed
      local p, wP, nP = sink.pm, sink.w, -sink.n
      local x, jP, cP, aB, lB, dB, lA, dA, wX, jX, aX, sA, s1, s2
      -- ball direction to pocket
      lB = ((p - b) / 4):length() * 4
      -- to avoid numeric overflow
      dB = (p - b) / lB
      -- dot product direction & pocket normal to calculate projected width
      jP = (nP * -dB) * wP
      -- subtract ball diameter to get clearance
      cP = jP - ballrad * 2
      -- impossible angle?
      if cP <= 0 then
        goto aiskippocket
      end
      -- angle range
      aB = cP / lB
      -- calculate strike point
      x = b - dB * ballrad * 2
      -- check if ball blocked
      --   if aiisblocked(a,x,ball)
      --   or aiisblocked(b,p,ball) then
      --   	goto aiskippocket
      --   end
      -- cue ball direction
      lA = ((x - a) / 4):length() * 4
      dA = (x - a) / lA
      -- dot product of cue ball direction
      -- and ball target direction must
      -- be positive. otherwise shot is 
      -- >=90 degrees, and impossible
      if dA * dB <= 0 then
        goto aiskippocket
      end
      -- target "width"
      wX = aB * ballrad
      -- projected target width
      jX = (dB * dA) * wX
      -- angle range
      aX = jX / lA
      -- target ball speed
      sB = sqrt(2 * friction * lB)
      -- required cue ball speed at collision
      sX = sB / (dB * dA) / eball
      -- initial cue ball speed
      s1, s2 = quadratic(1, 2 * sX, -2 * friction * lA)
      sA = s1 and max(s1, s2) + sX or cuedef
      -- prefer shots with greater angle range
      wEIGHT = aX * (npc.ang or 1)
      if abs(x[1]) <= tabw and abs(x[2]) <= tabl then
        wEIGHT += 8
      end
      if not aiisblocked(a, x, ball) then
        wEIGHT += 4
      end
      if not aiisblocked(b, p, ball) then
        wEIGHT += 2
      end
      if sA <= cuemax then
        wEIGHT += 1
      end
      wEIGHT += (rnd(2) - 1) * (npc.rand or 0)
      if wEIGHT > best then
        best = wEIGHT
        bestang = atan2(-dA[2], -dA[1])
        bestpow = sA
        -- add random offset based on 
        -- npc accuracy
        bestang += airandomang(npc)
      end
      ::aiskippocket::
      if best >= 15 or isbreak then
        aimovecue(bestang)
      end
      yield()
    end
    ::aiskipball::
    if best >= 15 or isbreak then
      aimovecue(bestang)
    end
    yield()
  end
  -- no best shot found
  -- (todo: something smarter?)
  if best == 0 then
    bestang = rnd(1)
  end
  -- make sure cue has finished
  -- moving to correct angle
  while not aimovecue(bestang) do
    yield()
  end
  -- fake "pondering"
  local th = npc.think or {1, 2}
  wait(th[1] + rnd(th[2] - th[1]))
  local pow = npc.pow
  cuepow = isbreak and cuemax or clamp(bestpow * (pow[1] + rnd(pow[2] - pow[1])), cuemin, cuemax)
end

function aimovecue(ang)
  -- find nearest equivalent angle
  local dif = ang - cueang
  dif -= flr(dif)
  if dif > 0.5 then
    dif -= 1
  end
  ang = cueang + dif
  -- move cue towards angle
  cueang = moveto(cueang, ang, 0.02)
  return cueang == ang
end

function aiplaceball()
  local w, l = tablew / 2 - ballrad, tablel / 2 - ballrad
  repeat
    wait(1)
    white.pos = vec(rnd(w * 2) - w, rnd(l - baulk) + baulk)
  until isvalidwhitepos(white.pos)
end

function aiisblocked(p, t, ignoreball)
  p /= 16
  -- avoid numeric overflow
  t /= 16
  local v = t - p
  for b in all(balls) do
    if b ~= white and b ~= ignoreball then
      local r = p - b.pos / 16
      -- position rel to ball
      -- must be moving towards ball
      if v * r < 0 then
        -- look for collision
        local d = linecirc(r, v, ballrad * 2 / 16)
        if d and d < 1 then
          return true
        end
      end
    end
  end
  return false
end

function airandomang(npc)
  local a = 0
  for i = 1, 10 do
    a += (rnd(2) - 1) * npc.ac / 10
  end
  return a
end

function disttospeed(d)
  return sqrt(2 * friction * d)
end


__gfx__
00000000330000333300003333000033330000330000000000000000000000001111110000000000000111111111111111111111111111111111111111111111
00000000302882033049940330577503300000030000000000000000000000001111110888888888882001111111111111111111111111111111111111111111
00700700028788200497994005777750000700000000000000000000000000001111110778888888888820111111111111111111111111111111111000011111
00077000088888800999999007777770000000000000000000000000000000001111102788882222288882011111111111111111111111111111111088200011
00077000088888800999999007777770000000000000000000000000000000001111108788880000022888011111111111111111111111111111111077888011
00700700028888200499994005777750000000000000000000000000000000001111108888880111100288201111111111111111111111111111111078888011
00000000302882033049940330577503300000030000000000000000000000001111108788880111111088801111100000111111111111111111110288888011
00000000330000333300003333000033330000330000000000000000000000001111028888820111111088801110028882001111111111111111110878882011
00000000000000000000000000000000000000000000000000000000000000001111088888801111111088801102888888820111110000011111110888880111
00000000000000000000000000000000000000000000000000000000000000001111088888801111110288801028877888882011002888200111110888880111
00000000000000000000000000000000000000000000000000000000000000001111088888800000002888201088877888888010288888882011110888880111
00000000000000000000000000000000000000000000000000000000000000001110288888888888888888010288888888888202887788888201110888880111
00000000000000000000000000000000000000000000000000000000000000001110888888888888888882010288888888888208887788888801110888880111
000000000000000000000000000000000000000000000000000000000000000011108888888888888882201102888888888e8028888888888820110888880111
00000000000000000000000000000000000000000000000000000000000000001110888888222222222001110288888888888028888888888820102888880111
00000000000000000000000000000000000000000000000000000000000000001102888888000000000111110228888888e8202888888888e820108888820111
0000000000000000000000000000000000000000000000000000000000000000110888888801111111111111102888888ee82028888888888820108888801111
00000000000000000000000000000000000000000000000000000000000000001108888888011111111111111022888ee88220228888888e8220108888801111
00000000000000000000000000000000000000000000000000000000000000001102222222011111111111111102228882220102888888ee8201108888801111
000000000000000000000000000000000000000000000000000000000000000010222222201111111111111111100222220011022888ee882201108888801111
00000000000000000000000000000000000000000000000000000000000000001000000000111111111111111111100000111110222888222011108888801111
00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111002222200111088888201111
00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111110000011111022888011111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111111111022222011111
00000000000000000000000000000000000000000000000000000000000000000444444444444444444444444444444400000000011111111111000022011111
00000000000000000000000000000000000000000000000000000000000000001044444444444444444444444444444444444444400000111111111100011111
00000000000000000000000000000000000000000000000000000000000000001104444444444444444444444444444444444444444444000000111111111111
00000000000000000000000000000000000000000000000000000000000000001110555555555555555555555555544444444444444444444444000111111111
00000000000000000000000000000000000000000000000000000000000000001110555555555555555555555555555555555554444444444444444000011111
00000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000555555555555555555554444400011
00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111000000000000000000055555555500
00000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111100000000000
__sfx__
000100003f6103f6003f6003f6003c6003c6003c6003c6003c6003460034600346000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100003f6203f6103f6003f6003c6003c6003c6003c6003c6003460034600346000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100003f6303f6103f6103f6103c6003c6003c6003c6003c6003460034600346000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0001000035640356303562035620356103561035610356103c6003460034600346000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000100002567025670256502565025640256402563025630256302562025620256202562025610256102561025610256000000000000000000000000000000000000000000000000000000000000000000000000
000800003470000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000912300105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500100
011000000913300100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011000000915300100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011000000917300100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0109000009173051730010000100041730010000100021630216302153021530214302143021330213302123021230211302113001000010000100001000010000100001000e1230010000100001000010000100
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111100000111111110001111111100000111000001111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111106660000000000601000011106660111066600000001000111111111111111111111111111111111111111111
11111111111111111111111111111111111111106660066066606000066011106060000060600660601060111111111111111111111111111111111111111111
11111111111111111111111111111111111111106060606006000010600011106660666066006060601060111111111111111111111111111111111111111111
11111111111111111111111111111111111111106060606006011110006011106060000060606660600060001111111111111111111111111111111111111111
11111111111111111111111111111111111111006060660006011110660011106660111066606060066006601111111111111111111111111111111111111111
11111111111111111111111111111111111111000000000800000110000111100000111000000000000000001111111111111111111111111111111111111111
11111111111111111111111111111111111111077888888888882011111111111111111111111111111111100001111111111111111111111111111111111111
11111111111111111111111111111111111110278888222228888201111111111111111111111111111111108820001111111111111111111111111111111111
11111111111111111111111111111111111110878888000002288801111111111111111111111111111111107788801111111111111111111111111111111111
11111111111111111111111111111111111110888888011110028820111111111111111111111111111111107888801111111111111111111111111111111111
11111111111111111111111111111111111110878888011111108880111110000011111111111111111111028888801111111111111111111111111111111111
11111111111111111111111111111111111102888882011111108880111002888200111111111111111111087888201111111111111111111111111111111111
11111111111111111111111111111111111108888880111111108880110288888882011111000001111111088888011111111111111111111111111111111111
11111111111111111111111111111111111108888880111111028880102887788888201100288820011111088888011111111111111111111111111111111111
11111111111111111111111111111111111108888880000000288820108887788888801028888888201111088888011111111111111111111111111111111111
11111111111111111111111111111111111028888888888888888801028888888888820288778888820111088888011111111111111111111111111111111111
11111111111111111111111111111111111088888888888888888201028888888888820888778888880111088888011111111111111111111111111111111111
1111111111111111111111111111111111108888888888888882201102888888888e802888888888882011088888011111111111111111111111111111111111
11111111111111111111111111111111111088888822222222200111028888888888802888888888882010288888011111111111111111111111111111111111
111111111111111111111111111111111102888888000000000111110228888888e8202888888888e82010888882011111111111111111111111111111111111
11111111111111111111111111111111110888888801111111111111102888888ee8202888888888882010888880111111111111111111111111111111111111
111111111111111111111111111111111108888888011111111111111022888ee88220228888888e822010888880111111111111111111111111111111111111
111111111111111111111111111111111102222222011111111111111102228882220102888888ee820110888880111111111111111111111111111111111111
1111111111111111111111111111111110222222201111111111111111100222220011022888ee88220110888880111111111111111111111111111111111111
11111111111111111111111111111111100000000011111111111111111110000011111022288822201110888880111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111100222220011108888820111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111000001111102288801111111111111111111111111111111111111
11111111111111111111111111111111000000000000000000000000000000001111111111111111111102222201111111111111111111111111111111111111
11111111111111111111111111111111044444444444444444444444444444440000000001111111111100002201111111111111111111111111111111111111
11111111111111111111111111111111104444444444444444444444444444444444444440000011111111110001111111111111111111111111111111111111
11111111111111111111111111111111110444444444444444444444444444444444444444444400000011111111111111111111111111111111111111111111
11111111111111111111111111111111111055555555555555555555555554444444444444444444444400011111111111111111111111111111111111111111
11111111111111111111111111111111111055555555555555555555555555555555555444444444444444400001111111111111111111111111111111111111
11111111111111111111111111111111110000000000000000000000000000000055555555555555555555444440001111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111100000000000000000005555555550011111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000011111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111444111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111444445554441111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111444444443b35533b444441111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111444444444b3b3b3b3333333b34444441111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111144444444b3b3b3b3b333333333333333b34444411111111111111111111111111111111111111111111111111111111
111111111111111111111111114444444443b3b3b3b33333333333333333333333b3b44444411111111111111111111111111111111111111111111111111111
111111111111111111111144445555553b3b3b3333333333333837978333333333333b3b44444411111111111111111111111111111111111111111111111111
111111111111111111111164444443333333333333333383798887979833333333333333b3444444111111111111111111111111111111111111111111111111
1111111111111111111111644444443333333333333338787978870789333333333333333b3b3444444111111111111111111111111111111111111111111111
1111111111111111111111164444444333333333333338889978879788333333333333333333b355555444111111111111111111111111111111111111111111
11111111111111111111111664444444333333333333333393888998783333333333333333333b55355444441111111111111111111111111111111111111111
1111111111111111111111166444444433333333333333333333399888333333333333333333333333b344444441111111111111111111111111111111111111
11111111111111111111111166444444433333333333333333333333333333333333333333333333333b3b444444441111111111111111111111111111111111
111111111111111111111111666444444433333333333333333333333333333333333333333333333333b3b3b444444411111111111111111111111111111111
111111111111111111111111666444444443333333333333333333333333333333333333333333333333333b3b34444444411111111111111111111111111111
111111111111111111111111166644444444333333333333333333333333333333333333333333333333333333b3b44444444111111111111111111111111111
1111111111111111111111111666444444444333333333333333333333333333333333333333333333333333333b3b3b44444444111111111111111111111111
1111111111111111111111111666644444444333333333333333333333333333333333333333333333333333333333b3b3444444444111111111111111111111
1111111111111111111111111166664444444433333333333333333333333333333333333333333333333333333333333b3b3444444441111111111111111111
11111111111111111111111111666644444455533333333333333333333333333333333333333333333333333333333333b3b3b4444444441111111111111111
11111111111111111111111111666664445555533333333333333333333333333333333333333333333333333333333333333b3b3b4444444441111111111111
11111111111111111111111111166666445533334333333333333333333333333333333333333333333333333333333335533333b3b344444444411111111111
111111111111111111111111111666664444444444333333333333333333333333333333333333333333333333333335333333333b3b3b444444444411111111
111111111111111111111111111666666444444444433333333333333333333333333333333333333333333333335533333333333333b3b3b444444444111111
1111111111111111111111111116666664444444444333333333333333333333333333333333333333333333335533333333333333333b3b3b34444444444111
1111111111111111111111111111666666444444444433333333333333333333333333333333333377773335533333333333333333333333b3b3b55444444444
1111111111111111111111111111666666644444444443333333333333333333333333333333333377773555353333333333333333333333333b555555544444
11111111111111111111111111116666666444444444443333333333333333333333333333333333777753535353333333333333333333333333355555555554
11111111111111111111111111111666666644444444444333333333333333333333333333333333577535353535333333333333333333333333333333355555
11111111111111111111111111111666666634444444444433333333333333333333333333333553535353535353333333333333333333333333333333333355
11111111111111111111111111111666666664444444444433333333333333333333333333355535353535353535333333333333333333333333333444444444
11111111111111111111111111111166666666444444444443333333333333333333333355535353535353535353333333333333333333333333334444444444
11111111111111111111111111111166666666444444444444333333333333333333335533353535353535353533333333333333333333333333444444444444
11111111111111111111111111111116666666644444444444433333333333333335533333333353535353535333333333333333333333333334444444444444
11111111111111111111111111111116666666664444444444443333333333333553333333333333353535333333333333333333333333333444444444444444
11111111111111111111111111111111666666664444444444444333333333555333333333333333333333333333333333333333333333344444444444444444
11111111111111111111111100001111666666666444444444444333333355333333333333333333333333333333333333333333333333444444444444444444
11111111111111111111111057750111600006666000000040000000000000000033300000000033330000000000003333333333333344444444444444444444
11111111111111111111110577775011107706666077707040777070707770777033307070077033300770777070703333333333334444444444444444444455
11111111111111111111110777777011100700000070707040707070707000707033307070700033307000707070703333333333344444444444444444444555
11111111111111111111110777777011110700777077707040777077707700770033307070777033307030777070703333333334444444444444444444445555
11111111111111111111110577775011100700000070007000707000707000707033307770007033307000700070703333333344444444444444444444455555
11111111111111111111111057750111107770666070607770707077707770707033300700770033300770703007703333334444444444444444444445555555
11111111111111111111111100001111100000666000600000000000000000000033330000000333330000003300003333444444444444444444444455555555
11111111111111111111111111111111111166666666664444444444444433333333333333333333333333333333333334444444444444444444444555555555
11111111111111111111111111111111111166666666663444444444444443333333333333333333333333333333333444444444444444444444455555555555
11111111111111111111111111111111111116666666666444444444444444333333333333333333333333333333344444444444444444444444555555555551
11111111111111111111111111111111111116666666666000004440000000400000000000000000333333333333444444444444444444444445555555555551
11111111111111111111111111111111111111666666666055504440555050405550505055505550333333333344444444444444444444444555555555555511
11111111111111111111111111111111111111666666666000500000505050405050505050005050333333333444444444444444444444445555555555555111
11111111111111111111111111111111111111166666666055505550555050405550555055005500333333344444444444444444444444455555555555555111
11111111111111111111111111111111111111166666666050000000500050005050005050005050333334444444444444444444444444555555555555551111
11111111111111111111111111111111111111166666666055504440504055505050555055505050333344444444444444444444444455555555555555511111
11111111111111111111111111111111111111116666666000004440004000000000000000000000334444444444444444444444444555555555555555511111
11111111111111111111111111111111111111116666666666664444444444444443333333333333344444444444444444444444445555555555555555111111
11111111111111111111111111111111111111111666666666666444444444444443333333333333444444444444444444444444555555555555555551111111
11111111111111111111111111111111111111111666666666666444444444444443333333333333444444444444444444444445555555555555555551111111
11111111111111111111111111111111111111111166666666666640000000000000000033333333444444444444444444444455555555555555555511111111
11111111111111111111111111111111111111111166666666666660550055505550055033333333444444444444444444444555555555555555555111111111
11111111111111111111111111111111111111111116666666666660505050005550505033333333444444444444444444455555555555555555555111111111
11111111111111111111111111111111111111111116666666666660505055005050505033333333444444444444444444555555555555555555551111111111
11111111111111111111111111111111111111111111666666666660505050005050505033333334444444444444444445555555555555555555511111111111
11111111111111111111111111111111111111111111666666666660555055505050550033333334444444444444444555555555555555555555511111111111
11111111111111111111111111111111111111111111166666666660000000000000000333333344444444444444445555555555555555555555111111111111
11111111111111111111111111111111111111111111166666666666664444444444443333333444444444444444455555555555555555555551111111111111
11111111111111111111111111111111111111111111116666666666666444444444444334444444444444444444555555555555555555555511111111111111
11111111111111111111111111111111111111111111116666666666666644444444444444444444444444444455555555555555555555555111111111111111
11111111111111111111111111111111111111111111111666666666666644444444444444444444444444444555555555555555555555551111111111111111
11111111111111111111111111111111111111111111111666666666666664444444444444444444444444445555555555555555555555511111111111111111
11111111111111111111111111111111111111111111111666666666666663444444444444444444444444555555555555555555555555111111111111111111
11111111111111111111111111111111111111111111111166666666666666444444444444444444444445555555555555555555555551111111111111111111
11111111111111111111111111111111111111111111111166666666666666644444444444444444444455555555555555555555555511111111111111111111
11111111111111111111111111111111111111111111111116666666666666634444444444444444445555555555555555555555555111111111111111111111
11111111111111111111111111111111111111111111111116666666666666664444444444444444455555555555555555555555551111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666444444444444444555555555555555555555555511111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666444444444444445555555555555555555555555111111111111111111111111
__meta:title__
mot's 8-ball pool
by mot
