pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

--province
--by perfoon
function init_data()
  progress = 64
  dec_progress_frames = 10
  knight_progress_inc = 8
  knight_pop_cost = 3
  pop_per_house = 1
  frames = 0
  items = {{n = "gold", c = 100, sp = 64, change = 0}, {n = "wood", c = 600, sp = 65, change = 0}, {n = "food", c = 260, sp = 66, change = 0}, {n = "pop", c = 0, sp = 67, change = 0, maxc = 0}}
  buildings = {{n = "remove", sp = 16}, {n = "road", sp = 79, r1 = "wood", c1 = 1, desc = "connects buildings"}, {n = "house", sp = 23, con = 1, r1 = "wood", c1 = 5, desc = "increases population", prog = 100, o = "pop", oi = "food", oic = 1, oicr = 1}, {n = "field", sp = 37, gtime = 300, gstages = 6, r1 = "wood", c1 = 2, desc = "produces food"}, {n = "windmill", sp = 44, con = 1, r1 = "wood", c1 = 7, desc = "harvests fields", prog = 300, customsp = 46}, {n = "market", sp = 26, con = 1, r1 = "wood", c1 = 10, desc = "trades food for money", prog = 300, o = "gold", oi = "food", oic = 10, oicr = 12}, {n = "fort", sp = 29, con = 1, r1 = "wood", c1 = 20, desc = "hires knights", prog = 300, oi = "gold", oic = 3, oicr = 3}, {n = "sapling", sp = 53, gtime = 200, gstages = 4, r1 = "gold", c1 = 1}, {n = "berry", sp = 73, gtime = 200, gstages = 4, hidden = true},}
  hidden_buildings = 1
  sapling_data = buildings[8]
  berry_data = buildings[9]
end

function _init()
  state = "menu"
  init_data()
  buildings[3].prog = 40
  init_roads()
  init_rivers()
  init_map()
  init_ui()
  init_cur()
  init_fx()
  init_scenario()
  init_menu()
  prepare_map()
  --reset_game()
  music(-1)
  music(0, 10000, 0, 1)
--music(0,100)
end

function _update()
  frames = frames + (1)
  update_map()
  update_items()
  update_people()
  update_messages()
  update_fading()
  update_overlay()
  if state == "menu" then
    update_menu()
  else
    if game_running then
      update_game()
    end
  end
end

function reset_game()
  frames = 0
  buildings[3].prog = 100
  init_map()
  init_ui()
  init_cur()
  init_fx()
  set_item("pop", 0, 0)
  generate_map()
  init_roads()
  init_rivers()
end

function update_menu()
  update_menu_panel()
end

function update_game()
  update_ui()
  update_scenario()
end

function _draw()
  if state == "menu" then
    draw_menu()
  else
    draw_game()
  end
end

function draw_menu()
  cls(0)
  camera(0, -28 - menu_fade_time * 0.5)
  draw_map(false)
  camera(0, -menu_fade_time)
  draw_menu_panel()
--print(stat(1))
end

function draw_game()
  cls(0)
  --draw_ui()
  camera(0, -17 - panel_open * 2 + game_fade_time)
  draw_map(true)
  draw_cur_top()
  pal()
  draw_fx()
  camera(0, game_fade_time)
  draw_ui()
  camera(0, 0)
  draw_progress()
  draw_messages()
  draw_overlay()
end

function draw_map(show_cursor)
  --background
  for y = 0, 19 do
    map(0 + 48, y, 0, y * 5, 16, 1)
  end
  --rivers
  for y = 0, 19 do
    for col = 7, 10 do
      local ncol = flr((-frames) / 6 + col + y) % 20 < 2 and 7 or 12
      pal(col, ncol)
    end
    map(0, y, 0, y * 5, 16, 1, 0x8)
    pal()
  end
  if panel_open > 0 or not game_running then
    darken()
  end
  if show_cursor then
    draw_cur_bottom()
  end
  --normal layer
  for y = 0, 19 do
    map(0, y, 0, y * 5, 16, 1, 2)
    draw_people(y - 1)
    map(0, y, 0, y * 5, 16, 1, 4)
    map(16, y, 0, y * 5 - 8, 16, 1)
    for x = 0, 16 do
      local con = get_con(x, y)
      if con and con.b.n == "windmill" then
        local f = (con.tick / 4) % 5
        spr(58 + f, x * 8, y * 5 - 4)
      end
    end
  end
  draw_people(19)
end

function darken()
  local ftb = {0, 0, 1, 5, 5, 5, 5, 2, 2, 4, 4, 3, 13, 5, 13, 13}
  for c = 0, 15 do
    pal(c, ftb[c + 1])
  end
end

-->8
--cursor / scenario
function init_cur()
  cur = {x = 7, y = 7, tile = 0}
  dirx = {-1, 1, 0, 0}
  diry = {0, 0, -1, 1}
  dirxy = {-1, 1, -1, 1}
  diryx = {-1, 1, 1, -1}
  hold = {x = -1, y = -1}
end

function contains(tbl, val)
  for i in all(tbl) do
    if val == i then
      return true
    end
  end
  return false
end

function update_cur()
  local moved = false
  for i = 0, 3 do
    if btn(i) then
      moved = true
      --local delay = max(2, 5 - flr(cur.movefrm/10))
      local frms = {0, 5, 10, 14, 18, 21, 24}
      local larger = cur.movefrm > 24 and cur.movefrm % 2 == 0
      if contains(frms, cur.movefrm) or larger then
        sfx(7)
        cur.x = cur.x + (dirx[i + 1])
        cur.y = cur.y + (diry[i + 1])
      end
    end
  end
  if moved == false then
    cur.movefrm = 0
  else
    cur.movefrm = cur.movefrm + (1)
  end
  cur.x = mid(0, 15, cur.x)
  cur.y = mid(0, 19, cur.y)
  cur.tile = mget(cur.x, cur.y)
  if btn(5) then
    build()
  else
    hold = {x = -1, y = -1}
  end
end

function build()
  building = buildings[selected]
  local tile = building.sp
  local x, y = cur.x, cur.y
  local curtile = mget(x, y)
  if tile ~= 16 and fget(curtile, 1) then
    if hold.x < 0 then
      sfx(2)
    end
    hold = {x = x, y = y}
    return
  end
  if tile == 16 and not fget(curtile, 1) then
    return
  end
  if fget(curtile, 3) then
    return
  end
  if hold.x == x and hold.y == y then
    return
  end
  hold = {x = x, y = y}
  if building.r1 then
    if has_item(building.r1, building.c1) then
      add_item(building.r1, -building.c1)
    else
      sfx(2)
      return
    end
  end
  sfx(1)
  if tile == 79 then
    tile = get_road(x, y)
  end
  for i = 0, 1 do
    mset(x + i * 16, y, 0)
  end
  if curtile >= 49 and curtile <= 51 then
    add_item_tile("wood", 2, x, y)
    tut_check("wood")
  end
  if curtile == 77 then
    add_item_tile("food", 2, x, y)
  end
  fx_explode(x * 8 + 4, y * 5 + 4)
  build_building(x, y, tile, building)
end

function build_building(x, y, tile, building)
  mset(x, y, tile)
  tut_check(building.n)
  rem_con(x, y)
  if building.con ~= nil then
    add_con(x, y, building)
  end
  for i = 1, 4 do
    update_road(x + dirx[i], y + diry[i])
  end
  rem_growing(x, y)
  if building.gtime ~= nil then
    add_growing(x, y, building)
  end
  update_connect()
end

function draw_cur_bottom()
  if fget(cur.tile, 1) == false then
    spr(18, cur.x * 8, cur.y * 5)
  end
end

function draw_cur_top()
  if fget(cur.tile, 1) == true then
    if fget(cur.tile, 7) == true then
      spr(4, cur.x * 8, cur.y * 5 - 8, 1, 2)
    else
      spr(19, cur.x * 8, cur.y * 5)
    end
    building = buildings[selected]
    if building.sp == 16 then
      spr(16, cur.x * 8, cur.y * 5)
    end
  end
end

--scenario
function init_scenario()
  frames = 0
  game_running = true
  overlay_h = 0
  overlay_mh = 0
  overlay_open = 0
  tut = nil
  tut_timeout = 0
end

function start_game(difficulty)
  state = "game"
  music(-1)
  if difficulty < 4 then
    music(7, 10000)
  else
    music(10, 10000)
  end
  game_fade_time = 128
  fading_game = 22
  if difficulty == 1 then
    --tutorial
    set_scenario(64, 0, 12, 0, 10)
    tut = 0
    tut_timeout = 80
  elseif difficulty == 2 then
    --normal
    set_scenario(127, 200, 8, 5, 5)
  elseif difficulty == 3 then
    --hard
    set_scenario(80, 100, 8, 0, 2)
  elseif difficulty == 4 then
    --nightmare
    set_scenario(65, 80, 5)
  end
  reset_game()
end

function set_scenario(prog, pfrms, kinc, wood, food, gold)
  progress = prog
  dec_progress_frames = pfrms
  knight_progress_inc = kinc
  set_item("wood", wood or 0)
  set_item("food", food or 0)
  set_item("gold", gold or 0)
end

function update_scenario()
  if tut_timeout > 0 then
    tut_timeout = tut_timeout - (1)
    if tut_timeout == 0 then
      show_next_tut()
    end
  end
  if game_running then
    if progress < 5 and frames % (5) == 0 or progress < 10 and frames % (10) == 0 or progress < 20 and frames % (20) == 0 then
      sfx(11)
    end
    if dec_progress_frames > 0 and frames % dec_progress_frames == 0 then
      progress = progress - (1)
    end
    if progress < 0 then
      game_over()
    elseif progress > 127 then
      game_won()
    end
  end
end

function game_over()
  open_overlay(6, overlay_lose, back_to_menu)
end

function game_won()
  open_overlay(10, overlay_win, back_to_menu)
end

function open_overlay(sound, draw_fun, fun)
  sfx(sound)
  game_running = false
  overlay_open = 1
  overlay_h = 0
  overlay_mh = 32
  overlay_fun = fun
  overlay_draw_fun = draw_fun
  overlay_breleased = false
end

function overlay_win(x, y)
  printbor("game over", x + 30, x + 33, 7)
  printbor("victory", x + 34, x + 44, 10)
end

function overlay_lose(x, y)
  printbor("game over", x + 30, x + 33, 7)
  printbor("you lost", x + 32, x + 44, 8)
end

function update_overlay()
  if overlay_h == overlay_mh and overlay_open >= 0 then
    if btn(5) or btn(4) then
      if overlay_breleased then
        overlay_open = -1
        sfx(3)
      end
    else
      overlay_breleased = true
    end
  end
end

function draw_overlay()
  if game_running or overlay_h < 0 then
    return
  end
  if overlay_open > 0 then
    overlay_h = overlay_h + (overlay_open)
    overlay_open = overlay_open + (overlay_open * 0.2)
    if overlay_h > overlay_mh then
      overlay_h = overlay_mh
      overlay_open = 0
      sfx(4)
    end
  elseif overlay_open < 0 then
    overlay_h = overlay_h + (overlay_open)
    overlay_open = overlay_open + (overlay_open * 0.2)
    if overlay_h < 0 then
      overlay_h = -1
      overlay_open = 0
      overlay_fun()
    end
  end
  local mx, my, bx, by = 17, 64 - overlay_h
  local bx, by = 127 - mx, 127 - my
  rectfill(mx, my, bx, by, 1)
  rect(mx, my, bx, by, 2)
  rect(mx + 1, my + 1, bx - 1, by - 1, 0)
  if overlay_h == overlay_mh then
    ot_x, ot_y = mx, my
    overlay_draw_fun(mx, my)
    printbor("press    to continue", 24, by - 11, 6)
    rectfill(47, by - 12, 55, by - 6, 0)
    spr(17, 48, by - 13)
  end
end

function back_to_menu()
  fading_game = -22
end

function continue_game()
  game_running = true
end

-->8
--ui
function init_ui()
  selected = 1
  breleased = true
  panel_open = 0
  panel_opening = -1
end

function init_menu()
  fading_menu = nil
  menu_fade_time = 0
  fading_game = nil
  game_fade_time = 0
  menuselected = 1
  menuoptions = {"tutorial", "normal", "hard", "nightmare"}
end

function update_ui()
  panel_open = mid(0, 5, panel_open + panel_opening)
  if btnp(4) then
    panel_opening = -panel_opening
    if panel_opening < 0 then
      sfx(4)
    else
      sfx(3)
    end
  end
  if btnp(5) and panel_open > 4 then
    panel_opening = -1
    sfx(4)
  end
  if panel_open == 0 or panel_opening < 0 then
    update_cur()
  else
    update_panel()
  end
end

function update_panel()
  local pselected = selected
  selected = update_select(0, 1, selected, #buildings - hidden_buildings)
  if pselected ~= selected then
    local b = buildings[selected]
    text(b.n, 2, 7, b.desc)
  end
end

function update_select(keyp, keyn, sel, maxsel)
  if btn(keyp) or btn(keyn) then
    if breleased then
      if btn(keyn) then
        sel = sel + (1)
        sfx(8)
        if sel > maxsel then
          sel = 1
        end
      end
      if btn(keyp) then
        sel = sel - (1)
        sfx(8)
        if sel < 1 then
          sel = maxsel
        end
      end
    end
    breleased = false
  else
    breleased = true
  end
  return sel
end

function draw_ui()
  local px = min(panel_open * 3, 13)
  fillp(0)
  rectfill(0, 0, 127, 9 + px, 0)
  fillp(0)
  rectfill(0, 6, 127, 8, 1)
  fillp(0)
  rectfill(0, 9, 127, 9 + px, 1)
  print(#items)
  for i, v in ipairs(items) do
    draw_item(i - 1, v)
  end
  --panel	
  if panel_open > 4 then
    rect(0, 9, 127, 9 + px, 13)
  end
  fillp(0)
  for i, v in ipairs(buildings) do
    if not v.hidden then
      draw_building(i - 1, v, selected)
    end
  end
end

function draw_building(ix, b, sel)
  local x = ix * 14 + 8
  local y = 5 + max(3, panel_open)
  local bcol = 1
  local hide = (5 - panel_open) * 2
  if ix + 1 == sel then
    bcol = 6
    hide = 0
  end
  if hide < 10 then
    rectfill(x, y, x + 11, y + 11 - hide, 0)
    rect(x, y, x + 11, y + 11 - hide, bcol)
  end
  local hasmoney = not b.r1 or has_item(b.r1, b.c1)
  if not hasmoney then
    for c = 2, 15 do
      pal(c, 1)
    end
  end
  --spr(b.sp,x+2,y+2)
  local sp = b.customsp or b.sp
  local sx = sp % 16
  local sy = flr(sp / 16)
  sspr(sx * 8, sy * 8, 8, 8 - hide, x + 2, y + 2)
  pal()
  --cost
  if ix + 1 == sel then
    if b.r1 then
      local item = get_item(b.r1)
      x, y = x + 1, y + 12
      spr(item.sp, x + 3, y)
      local fcol = has_item(b.r1, b.c1) and 7 or 8
      printbor(b.c1, x, y, fcol)
    end
  end
end

function draw_progress()
  if not tut or tut > 7 then
    local md = progress / 128
    md = flr(md * 127)
    md = mid(-1, 127, md)
    rectfill(0, 124, 127, 127, 1)
    if md >= 2 then
      rectfill(1, 125, md - 1, 127, 8)
    end
    if md <= 124 then
      rectfill(md + 2, 125, 126, 127, 5)
    end
    spr(69, md - 3, 120)
  end
end

--menu
function update_menu_panel()
  if not fading_menu then
    menuselected = update_select(2, 3, menuselected, #menuoptions)
    if btnp(5) or btnp(4) or btnp(0) or btn(1) then
      fading_menu = 1
      menu_fade_time = 0
      sfx(9)
    end
  end
end

function draw_menu_panel()
  spr(128, 25, 16, 10, 4)
  --if (true) return
  local px, py = 14, 40
  for i, opt in pairs(menuoptions) do
    local col, tb, sx = 6, "  ", px
    if fading_menu then
      col = 13
    end
    if menuselected == i then
      col, tb = 10, " - "
      if fading_menu then
        col, sx = 7, px + 2
      end
    end
    printbor(tb .. opt, sx, py + i * 10, col)
  end
  printbor("by perfoon", 88, 123, 6)
end

-->8
--map
function init_map()
  growing = {}
  set_play_area()
  saplingtime = 0
end

function prepare_map()
  prepare_trees()
  prepare_buildings()
end

function generate_map()
  clear_map()
  generate_trees()
  generate_road()
  generate_river()
  prepare_trees()
end

function clear_map()
  for x = 0, 15 do
    for y = 0, 19 do
      mset(x, y, 0)
      mset(x + 16, y, 0)
    end
  end
end

function prepare_buildings()
  for x = 0, 15 do
    for y = 0, 19 do
      local v = mget(x, y)
      for b in all(buildings) do
        if b.sp == v then
          --mset(x,y,41)
          build_building(x, y, v, b)
        end
      end
    end
  end
end

function generate_road()
  local r2, mir = rnd(15) + 3, flr(rnd(2)) * 12
  for i = 0, 3 do
    mset(i + mir, r2, 80)
  end
  mset(mir, r2 - 1, 78)
end

function generate_river()
  local r2, brid = rnd(12) + 3, flr(rnd(10)) + 4
  for i = 0, 19 do
    local mx, dx = max(0, rnd(11) - 6), sgn(rnd(2) - 1)
    if i == brid then
      for bx = r2 - 1, r2 + 1 do
        mset(bx, i, 80)
      end
      mset(r2, i, 122)
    elseif mget(r2, i) ~= 80 then
      for k = 0, mx do
        mset(r2, i, 96)
        if mget(r2 + dx, i - 1) == 96 then
          break
        end
        if k < mx - 1 then
          r2 = mid(r2 + dx, 1, 14)
        end
      end
    end
  end
end

function generate_trees()
  for x = 0, 15 do
    for y = 0, 19 do
      local dist = (x - 8) ^ 2 + (y - 9) ^ 2
      if rnd(dist) > 20 then
        if rnd(dist) > 12 then
          if rnd(dist) > 50 then
            mset(x, y, 50)
          else
            mset(x, y, 49)
          end
        end
      end
    end
  end
  for i = 0, 10 do
    local rx, ry = rnd(8), rnd(10)
    mset(rx + 3, ry + 4, 49)
  end
  for i = 0, 10 do
    local rx, ry = rnd(14), rnd(15)
    for x = 1, 2 do
      for y = 1, 2 do
        mset(rx + x, rx + y, 0)
      end
    end
  end
end

function prepare_trees()
  for x = 0, 15 do
    for y = 0, 19 do
      local tile = mget(x, y)
      if fget(tile, 7) then
        local btile = mget(x + 48, y)
        if btile < 9 then
          tile = tile + (1)
          mset(x, y, tile)
        end
        mset(x + 16, y, tile - 16)
      end
    end
  end
end

function set_play_area()
  for x = 0, 16 do
    for y = 0, 19 do
      local x2 = x + 48
      mset(x2, y, 0)
      local dist = (x - 8) ^ 2 + (y - 9) ^ 2
      dist = dist + (0 + rnd(30))
      if dist < 50 then
        mset(x2, y, 13)
      elseif dist < 60 then
        mset(x2, y, 11 + rnd(2))
      elseif dist < 80 then
        mset(x2, y, 9 + rnd(2))
      elseif dist < 110 then
        mset(x2, y, 7 + rnd(2))
      end
    end
  end
end

function add_growing(x, y, building)
  local new = {x = x, y = y, t = 0, b = building, tile = building.sp}
  add(growing, new)
end

function rem_growing(x, y)
  for g in all(growing) do
    if g.x == x and g.y == y then
      del(growing, g)
    end
  end
end

function is_tree(x, y)
  local t = mget(x, y)
  return t >= 49 and t <= 51
end

function count_range(v1, v2)
  local cnt = 0
  for x = 0, 16 do
    for y = 0, 19 do
      if mget(x, y) >= v1 and mget(x, y) <= v2 then
        cnt = cnt + (1)
      end
    end
  end
  return cnt
end

function update_map()
  --spawn sapling and berry
  if saplingtime < time() then
    local rx, ry = flr(rnd(16)), flr(rnd(20))
    if not fget(mget(rx, ry), 1) and not fget(mget(rx, ry), 3) then
      if is_tree(rx - 1, ry) or is_tree(rx + 1, ry) or is_tree(rx, ry - 1) or is_tree(rx, ry + 1) then
        if rnd() > 0.2 then
          mset(rx, ry, 52)
          add_growing(rx, ry, sapling_data)
        else
          mset(rx, ry, 73)
          add_growing(rx, ry, berry_data)
        end
        local treecount = count_range(49, 51)
        saplingtime = time() + rnd(4) + max(2, 6 - treecount * 0.2)
      end
    end
  end
  --update growing
  for g in all(growing) do
    g.t = g.t + (1)
    local b = g.b
    if g.t < b.gtime then
      local sdur = flr(b.gtime / (b.gstages + 1))
      if g.t % sdur == 1 then
        local frmadd = flr(g.t / sdur)
        frmadd = min(frmadd, b.gstages)
        mset(g.x, g.y, g.tile + frmadd)
      end
    else
      --growing done
      if b.n == "sapling" then
        local tile = 49
        mset(g.x, g.y, tile)
        mset(g.x + 16, g.y, tile - 16)
        del(growing, g)
      end
    end
  end
  update_buildings()
end

function update_buildings()
  for k, v in pairs(cons) do
    local b = v.b
    if b.prog and v.c then
      v.tick = v.tick + (1)
      if v.tick > b.prog then
        if b.oi and has_item_room(b.o) then
          if has_item(b.oi, b.oicr) then
            if b.n == "fort" then
              if has_item("pop", knight_pop_cost + 2) then
                add_item("pop", -knight_pop_cost)
              else
                float_item_missing(v.x, v.y, "pop")
                v.tick = 0
                return
              end
            end
            add_item(b.oi, -b.oic)
            if b.o then
              add_item_tile(b.o, 1, v.x, v.y)
            end
            if b.o == "pop" then
              add_people(v.x, v.y)
            end
            if b.n == "fort" then
              add_people(v.x, v.y, true)
            end
          else
            float_item_missing(v.x, v.y, b.oi)
          end
        end
        v.tick = 0
        if b.n == "windmill" then
          if has_item("pop", 2) then
            local cnt = harvest(v.x, v.y)
            if cnt > 0 then
              add_item("pop", -2)
            end
          else
            float_item_missing(v.x, v.y, "pop")
          end
        end
      end
    end
  end
end

function harvest(x, y)
  local c = 0
  for g in all(growing) do
    local d = (x - g.x) ^ 2 + (y - g.y) ^ 2
    if g.b.n == "field" and d < 3 and g.t >= g.b.gtime then
      g.t = 0
      add_item_tile("food", 1, g.x, g.y)
      c = c + (1)
    end
  end
  return c
end

-->8
--roads / rivers
function init_roads()
  init_path_tiles(80, get_road)
end

function init_path_tiles(td, fn)
  cons = {}
  for x = 0, 16 do
    for y = 0, 19 do
      if mget(x, y) == td then
        mset(x, y, fn(x, y))
      end
    end
  end
end

function get_road(x, y)
  local mask = 0
  if is_road_or_edge(x, y - 1) then
    mask = mask + (1)
  end
  if is_road_or_edge(x, y + 1) then
    mask = mask + (2)
  end
  if is_road_or_con(x - 1, y) then
    mask = mask + (4)
  end
  if is_road_or_con(x + 1, y) then
    mask = mask + (8)
  end
  return 80 + mask
end

function is_edge(x, y)
  return x < 0 or y < 0 or x > 15 or y > 19
end

function is_road(x, y)
  local t = mget(x, y)
  return t >= 80 and t <= 95 or t == 122
end

function is_road_or_edge(x, y)
  return is_edge(x, y) or is_road(x, y)
end

function is_road_or_con(x, y)
  if get_con(x, y) then
    return true
  end
  return is_road_or_edge(x, y)
end

function update_road(x, y)
  if is_road(x, y) and x < 16 and y < 20 then
    mset(x, y, get_road(x, y))
  end
end

--rivers
function init_rivers()
  init_path_tiles(96, get_river)
end

function get_river(x, y)
  local mask = 0
  if is_river_or_edge(x, y - 1) then
    mask = mask + (1)
  end
  if is_river_or_edge(x, y + 1) then
    mask = mask + (2)
  end
  if is_river_or_edge(x - 1, y) then
    mask = mask + (4)
  end
  if is_river_or_edge(x + 1, y) then
    mask = mask + (8)
  end
  return 96 + mask
end

function is_river(x, y)
  local t = mget(x, y)
  return t >= 96 and t <= 111
end

function is_river_or_edge(x, y)
  return is_edge(x, y) or is_river(x, y)
end

--connections
function update_connect()
  for x = 0, 15 do
    for y = 0, 19 do
      mset(x + 32, y, 0)
    end
  end
  for v, k in pairs(cons) do
    mset(k.x, k.y, k.b.sp)
    k.cp = k.c
    k.c = false
  end
  for x = 0, 15 do
    connect(x, 0, 1)
    connect(x, 19, 1)
  end
  for y = 0, 19 do
    connect(0, y, 1)
    connect(15, y, 1)
  end
  --update connected houses
  for v, k in pairs(cons) do
    if k.cp ~= k.c then
      local px, py = k.x * 8, k.y * 5 - 4
      if k.c then
        fx_float(px, py, 71, -0.1)
        if k.b.n == "house" then
          add_item_max("pop", pop_per_house)
        end
      else
        fx_float(px, py, 72, 0.1)
        if k.b.n == "house" then
          add_item_max("pop", -pop_per_house)
        end
      end
    end
  end
end

function connect(x, y, dir)
  if x < 0 or y < 0 or x > 15 or y > 19 then
    return
  end
  local tile = mget(x, y)
  local ctile = mget(x + 32, y)
  if ctile < 1 then
    if is_road_or_edge(x, y) then
      mset(x + 32, y, dir)
      connect(x, y - 1, 5)
      connect(x, y + 1, 4)
      connect(x - 1, y, 3)
      connect(x + 1, y, 2)
    end
    local con = get_con(x, y)
    if con then
      mset(x, y, con.b.sp + 1)
      con.c = true
    end
  end
end

function get_con_dir(x, y)
  local ctile = mget(x + 32, y)
  if ctile > 0 then
    return ctile - 1
  end
  for i = 1, 4 do
    local dx, dy = x + dirx[i], y + diry[i]
    if is_road(dx, dy) and mget(dx + 32, dy) > 0 then
      return i
    end
  end
end

function add_con(x, y, building)
  local new = {x = x, y = y, b = building, c = false, cp = false, tick = 0}
  cons[x .. "," .. y] = new
end

function get_con(x, y)
  return cons[x .. "," .. y]
end

function rem_con(x, y)
  local con = get_con(x, y)
  if con then
    if con.b.n == "house" and con.c then
      add_item_max("pop", -pop_per_house)
    end
    cons[x .. "," .. y] = nil
  end
end

-->8
--effects / people / messages
function init_fx()
  particles = {}
  floaters = {}
  people = {}
  message = {t = "", tout = 0, col = 7, open = 0}
end

function animate_sp(sp, nr, delay)
  return sp + flr(frames / delay) % nr
end

function update_messages()
  if message.tout < time() then
    message.tout = 0
  elseif message.tout < time() + 0.2 then
    message.open = message.open - (2)
  elseif message.open < 12 then
    message.open = message.open + (2)
  end
end

function draw_messages()
  if message.tout > 0 then
    print(message.t, 4 + 1, 127 + 1 - message.open, 0)
    local pos = print(message.t, 4, 127 - message.open, message.col)
    if message.desc then
      print(" - " .. message.desc, pos + 1, 127 + 1 - message.open, 0)
      print(" - " .. message.desc, pos, 127 - message.open, 6)
    end
  end
end

function text(msg, dur, col, desc)
  message.t = msg
  message.tout = time() + (dur or 2)
  message.col = col or 7
  message.open = max(0, message.open)
  message.desc = desc
end

--effects
function draw_fx()
  for p in all(particles) do
    p.x = p.x + (p.vx)
    p.y = p.y + (p.vy)
    p.t = p.t + (1)
    local f = p.t / p.dur
    local r = p.r * (1.5 - f)
    if f > 0.9 then
      fillp(0)
    elseif f > 0.8 then
      fillp(0)
    end
    local col = p.cols[flr(#p.cols * f)]
    circfill(p.x, p.y, r, col)
    if p.t > p.dur then
      del(particles, p)
    end
    fillp(0)
  end
  for f in all(floaters) do
    f.t = f.t + (1)
    f.y = f.y + (f.my)
    spr(f.sp, f.x, f.y)
    if f.t > 40 then
      del(floaters, f)
    end
  end
end

function fx_float(x, y, sp, my)
  local f = {x = x, y = y, sp = sp, t = 0, my = my}
  add(floaters, f)
end

function fx_explode(x, y)
  local cols = {7, 9, 6, 6, 5, 5, 2, 1}
  for i = 0, 10 do
    add_particle(x, y, 0.6, 1, 10, cols)
  end
  add_particle(x, y, 0.0, 3, 5, cols)
end

function add_particle(x, y, vel, s, dur, cols)
  local p = {x = x, y = y, r = rnd(s) + s, cols = cols, dur = dur, t = 0}
  local dir = rnd(3.14)
  p.vx = -sin(dir) * vel
  p.vy = cos(dir) * vel
  add(particles, p)
end

--people
function add_people(x, y, knight)
  local p = {x = x, y = y, cx = x * 8, cy = y * 5, wx = -1, wy = -1, wcx = -1, wcy = -1, t = 0, t2 = 3, knight = knight}
  p.hx = p.x
  p.hy = p.y
  add(people, p)
end

function update_people()
  local pop = get_item("pop").c
  for i, p in pairs(people) do
    p.t = p.t + (0.2)
    p.t2 = p.t2 + (1)
    if p.t2 % 6 == 0 or p.knight and p.t2 % 3 == 0 then
      if p.knight then
        pop = max(i, pop)
      end
      if pop < i then
        p.wx = p.hx
        p.wy = p.hy
        p.wcx = p.hx * 8
        p.wcy = p.hy * 5
      end
      if p.wx >= 0 and p.wy >= 0 then
        if p.wcx ~= p.cx then
          p.cx = p.cx + (sgn(p.wcx - p.cx))
        end
        if p.wcy ~= p.cy then
          p.cy = p.cy + (sgn(p.wcy - p.cy))
        end
        --text(p.wcx.."_"..p.cx..":"..p.wcy.."_"..p.cy)
        if p.wcx == p.cx and p.wcy == p.cy then
          p.x = p.wx
          p.y = p.wy
          p.wx = -1
          --new point
          if pop < i then
            del(people, p)
          end
        end
      else
        local wx, wy = p.x, p.y
        if p.knight then
          local dir = get_con_dir(p.x, p.y)
          if dir > 0 then
            wx = wx + (dirx[dir])
            wy = wy + (diry[dir])
          else
            del(people, p)
            fx_float(p.cx, p.cy, 69, -0.2)
            if state == "game" then
              progress = progress + (knight_progress_inc)
              sfx(5)
            end
          end
        else
          local dir = flr(rnd(4)) + 1
          wx = wx + (dirx[dir])
          wy = wy + (diry[dir])
        end
        if is_road(wx, wy) then
          --text(p.x,0.4)
          p.wx = wx
          p.wy = wy
          p.wcx = wx * 8
          p.wcy = wy * 5
        end
      end
    end
  end
end

function draw_people(y)
  --print(#people,50,50)
  for p in all(people) do
    if p.y == y then
      local flipx = p.wcx <= p.cx
      local sp = p.knight and 112 or 124
      spr(sp + flr(p.t) % 4, p.cx, p.cy, 1, 1, flipx)
    end
  end
end

function printbor(t, x, y, col)
  for i = 1, 4 do
    print(t, x + dirx[i], y + diry[i], 0)
    print(t, x + dirxy[i], y + diryx[i], 0)
  end
  print(t, x, y, col)
end

--fading
function update_fading()
  --fading
  if fading_game then
    game_fade_time = game_fade_time - (fading_game)
    fading_game = fading_game - (2)
    if fading_game > 0 then
      if game_fade_time <= 0 then
        game_fade_time = 0
        fading_game = nil
      end
    else
      if game_fade_time >= 128 then
        fading_game = nil
        fading_menu = -28
        menu_fade_time = 128
        state = "menu"
        game_running = true
      end
    end
  end
  --fading menu
  if fading_menu then
    menu_fade_time = menu_fade_time + (fading_menu)
    if fading_menu > 0 then
      fading_menu = fading_menu + (fading_menu * 0.2)
      if menu_fade_time > 256 then
        start_game(menuselected)
        fading_menu = nil
      end
    else
      fading_menu = fading_menu - (fading_menu * 0.2)
      if menu_fade_time < 0 then
        menu_fade_time = 0
        fading_menu = nil
      end
    end
  end
end

-->8
--items / tutorial
function update_items()
  for item in all(items) do
    if item.change > 0 then
      item.change = item.change - (1)
    end
    if item.change < 0 then
      item.change = item.change + (1)
    end
  end
end

function get_item(name)
  return items[get_item_id(name)]
end

function get_item_id(name)
  for i, v in pairs(items) do
    if v.n == name then
      return i
    end
  end
  return 0
end

function has_item(name, val)
  return get_item(name).c >= val
end

function add_item(name, val, x, y)
  local item = get_item(name)
  if x and y and val > 0 then
    fx_float(x, y, item.sp, -0.1)
  end
  item.c = item.c + (val)
  item.change = mid(-7, 7, val * 7)
end

function set_item(name, val, maxval)
  local item = items[get_item_id(name)]
  item.c = val
  if maxval then
    item.maxc = maxval
  end
end

function add_item_max(name, val)
  local item = get_item(name)
  item.maxc = item.maxc + (val)
  if item.c > item.maxc then
    item.c = item.maxc
  end
  tut_check("max" .. name, val)
end

function has_item_room(name)
  if not name then
    return true
  end
  local item = get_item(name)
  return not item.maxc or item.c < item.maxc
end

function add_item_tile(name, val, tx, ty)
  add_item(name, val, tx * 8, ty * 5 - 4)
end

function draw_item(ix, item)
  local tcol = 6
  if item.change > 0 then
    tcol = 7
  elseif item.change < 0 then
    tcol = 8
  end
  spr(item.sp, ix * 24 + 1, 1)
  local sx = print(item.c, ix * 24 + 10, 2, tcol)
  if item.maxc then
    print("/" .. item.maxc, sx, 2, tcol)
  end
end

function float_item_missing(x, y, item)
  fx_float(x * 8, y * 5 - 4, get_item(item).sp, -0.1)
  fx_float(x * 8, y * 5 - 4, 2, -0.1)
end

--tutorial
function show_next_tut()
  tut = tut + 1
  local ovs = {overlay_tut1, overlay_tut2, overlay_tut3, overlay_tut4, overlay_tut5, overlay_tut6, overlay_tut7, overlay_tut8}
  for i = 1, 8 do
    if tut == i then
      open_overlay(12, ovs[i], continue_game)
    end
  end
end

function tut_check(bname)
  if tut and tut_timeout <= 0 then
    local nss = {"wood", "road", "maxpop", "field", "windmill", "market", "fort"}
    for i = 1, 7 do
      if tut == i and bname == nss[i] then
        tut_timeout = 100
      end
    end
  end
end

function otp(txt, x, y)
  --global ot_x,ot_y
  print(txt, ot_x + x, ot_y + y, 7)
end

function ots(sp, x, y)
  spr(sp, ot_x + x, ot_y + y)
end

function ott(txt, x)
  printbor(txt, ot_x + x, ot_y + 4, 7)
end

function otr(sp, x, y)
  rectfill(ot_x + x - 1, ot_y + y - 1, ot_x + x + 8, ot_y + y + 8, 0)
  ots(sp, x, y)
end

function overlay_tut1(x, y)
  ott("cut trees", 30)
  otp("press   to use  tool", 5, 16)
  ots(17, 28, 14)
  ots(16, 61, 14)
  spr(33, x + 30, y + 20, 1, 2)
  ots(16, 30, 26)
  ots(3, 40, 25)
  ots(65, 50, 25)
end

function overlay_tut2(x, y)
  ott("build roads", 30)
  otp("press   to open tools", 5, 16)
  ots(48, 28, 14)
  otp("choose roads ", 5, 26)
  otr(79, 56, 24)
  otp("extend from map edge", 5, 36)
  ots(78, 26, 42)
  ots(88, 34, 42)
  ots(92, 42, 42)
  ots(85, 50, 42)
end

function overlay_tut3(x, y)
  ott("build houses", 23)
  otp("connect houses ", 5, 16)
  otr(23, 68, 14)
  otp("to roads ", 27, 26)
  otr(24, 8, 24)
  otr(93, 16, 24)
  ots(24, 8, 24)
  otp("they produce", 5, 39)
  ots(66, 55, 38)
  ots(3, 65, 38)
  ots(67, 75, 38)
end

function overlay_tut4(x, y)
  ott("build fields", 23)
  otp("fields grow over time", 5, 26)
  otr(37, 28, 14)
  otr(40, 38, 14)
  otr(42, 48, 14)
  otr(43, 58, 14)
end

function overlay_tut5(x, y)
  ott("build windmill", 21)
  ots(43, 44, 15)
  ots(43, 36, 15)
  ots(43, 52, 15)
  ots(43, 36, 20)
  ots(43, 52, 20)
  ots(43, 36, 25)
  ots(43, 52, 25)
  ots(83, 44, 25)
  ots(44, 44, 20)
  ots(animate_sp(58, 5, 2), 44, 16)
  otp("harvests fields", 18, 34)
  ots(67, 28, 41)
  ots(67, 35, 41)
  ots(3, 45, 41)
  ots(66, 55, 41)
end

function overlay_tut6(x, y)
  ott("build market", 23)
  otr(27, 11, 19)
  otp("sells wheat", 25, 21)
  otp("10X", 15, 33)
  ots(66, 27, 33)
  ots(66, 31, 33)
  ots(66, 35, 33)
  ots(3, 45, 33)
  ots(64, 55, 33)
end

function overlay_tut7(x, y)
  ott("build fort", 23)
  otr(30, 11, 19)
  otp("trains knights", 25, 21)
  ots(67, 14, 33)
  ots(5, 20, 33)
  ots(66, 27, 33)
  ots(66, 31, 33)
  ots(66, 35, 33)
  ots(3, 45, 33)
  ots(animate_sp(112, 4, 5), 55, 33)
end

function overlay_tut8(x, y)
  ott("call to arms!", 23)
  otp("the king summons", 15, 14)
  rectfill(x + 24, y + 28, x + 47, y + 30, 8)
  rectfill(x + 48, y + 28, x + 72, y + 30, 5)
  otp("bring glory to red!", 10, 34)
  ots(69, 44, 23)
  for i = 0, 6 do
    ots(animate_sp(112, 4, 5), 7 + i * 12, 41)
  end
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000088880000060000000000000006600000000000000000110000110000011001101011001110011010111000110011000000000000000000
00700700022222200800088000066000000000000006600000000000011000000000000011110011101111111111111111011111111111110000000000000000
00077000200000020800808006666600770000770666666000000000000000000000000001110011110011111111111111111111111111110000000000000000
0007700020000002080800800ddddd00700000070dddddd000000000000000000000000000011111111100111111111111111111111111110000000000000000
007007002000000208800080000dd00000000000000dd00000000000000000000000001111111000111100011111100111111111111111110000000000000000
000000002000000200888800000d000000000000000dd00000000000000110001100000001111000001111111111111111001111111111110000000000000000
00000000022222200000000000000000000000000000000000000000000000000000000000111111001110101111111111111111111111110000000000000000
000000000000000000000000770000770000000000000000000000000554511005544550000000000000000000000000000000000dd22dd00dd588d000000000
00000800000000000000000070000007000000000000000000000000444455554444444400000000008f8f8f008f8f8f00000000d511112dd511412d00000000
08808800077777000000000000000000000000000000000000000000444455554444444400000000558f8f8f558f8f8f00000000d111111dd111411d00000000
00888000770707700660066000000000000000000000000000000000444515554445544400000000458f8f8f458f8f8f0000000055dddd2255dddd2200000000
0008880077707770060000600000000000000000000000000000000055555111455555540000000041411114414aaaa400000000515222125a5222a200000000
008808807707077006000060000000000000000000000000000000005f4114f55f4aa4f500000000554544545549449400000000515552125955529200000000
008000000777770006600660700000077000000700000000000000005f4ff4f55f4994f500000000055511500555115000000000055522200555222000000000
00000000000000000000000077000077770000770000000000000000555555555555555500000000005555000055550000000000005552000055520000000000
09999990000000000000000000000000000000000000000000000000000000000000000003b3bb300baabab00a99a9a005511550055115506665550000000000
999999990000000000000000000000000000000000000000000000000000000003b3b3303bbb3bb3babaaaaba99999aa54444445544444450055566600000000
999999990000000000000000000000000000000004444440033333300bb33bb03bbbb3b3bbbb3bbbaaaaaaaaa99a99a955555555555555555556556600000000
9999999900000000000000000000000000000000555555555555555533bb3b33b3b3bbbb3b3bbbbbababaaba99a9999954444445544444455456444600000000
99999999000b00000003000000010000000000004444444433333333bb33b3b333bbb3b3bb3b3b3bbaaaabab9999a99a5f4114f55f4aa4f55566555500000000
99999999000b000000030000000100000000000055555555555555553b3b333b3bb3b333b3bbbb3bbbbaabbba9a9a9aa5f4114f55f4aa4f55466444500000000
33333333000b3000000310000001100000000000444444443333333333333333333333333333333333333333333333335f4114f55f4994f55f4114f500000000
03333330000b30000003100000011000000000000555555005555550033333300333333003333330033333300333333055555555555555555f4114f500000000
00000000000330000001100000011000000000000000000000000000000000000000000000030000050000600650000000650000000065000000665000000000
0000000000bbb3000033310000111100000000000000000000000000000b0000000b0000000bb000665006650665006600665000000665005000650000000000
077777000bbbb33003333110011111100000000000000000000b0000000b000000bbb00000bbb300066506500065066500065066550650006550650000000000
7700077000333300001111000011110000000000000b000000030000000330000033300000333000000555000005555005555665665556606665500000000000
770707700bb333300331111001111110000000000003000000b3300000b330000bb333000bb33300005550000555500056655550066555660005566600000000
77000770bb3333333311111111111111000b000000b33000003333000b3333000b3333300b333330056056605660560066056000000560550056055600000000
07777700000450000001100000011000003300000004000000040000000450000004500000045000566005666600566000056600005660000056000500000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000060000500000056000005600005600000566000000000000
000000000000040000000a0000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000
0aaa990000004440000a0a9000066000000000000000000000000000000000000000000000000000000000000000000000000000000bb0000004444000055000
0aaa9900000444540009a9aa00055000000000009a0a90a900000000000aa0000000000000000000000000000000000000bb300000bb83000444445000555500
00aaaa9000ff45440a094a0000616500000000009aaaaaa90000000000aaaa0008800880000000000000000000bbb3000bbbb3300b8bb3300044500055555555
00aaa99004ff544009aa900006156500000000009aaaaaa9000000000aa00aa00088880000000000000b00000bb333300bb33330bbb333830004500055555555
aa9aaaa9ff5ff400004aa000000660000000000099999999000000000000000000088000000b00000bbb33000bbb33300bbb33300bb833300004500000555500
a99aaaa9ff5ff0000490000000606000000000000000000000000000000000000000000000bb330000bb330000bb330000bb330000bb33000004500000055000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000
00000000005555000000000000555500000000000055550000000000005555000000000000555500000000000055550000000000005555000000000000555500
00000000005555000000000000555500000000000055550000000000005555000000000000555500000000000055550000000000005555000000000000555500
00000000005555000000000000555500000000000555550000000000055555000000000000555550000000000055555000000000055555500000000005555550
00055000005555000005500000555500555550005555550055555000555555000005555500555555000555550055555555555555555555555555555555555555
00555500005555000055550000555500555555005555550055555500555555000055555500555555005555550055555555555555555555555555555555555555
00555500005555000055550000555500555555005555550055555500555555000055555500555555005555550055555555555555555555555555555555555555
00055000000550000055550000555500555550005555500055555500555555000005555500055555005555550055555555555555555555555555555555555555
00000000000000000055550000555500000000000000000005555500055555000000000000000000005555500055555000000000000000000555555005555550
000000000cccccc0000000000cccccc0000000000cccccc0000000000cccccc0000000000cccccc0000000000cccccc0000000000cccccc0000000000ccc9780
000000000cccccc0000000000cccccc0000000000ccc9cc0000000000ccca9c0000000000cccccc0000000000cccccc0000000000cccccc0000000000ccc78a0
000550000cc98cc0000550000cccccc0555550005cc97cc0555550005ccc98c0000555550cc78cc5000555550cccccc5555555555cccccc5555555555cccccc5
005cc5000cc79cc0005985000c899cc0cc8ac500ccc78cc0789cc500ccccccc0005ccccc0c997ccc005ccccc0cccccccccccc7cccccccccccccccc99cccccccc
05cc78500ccc7cc0059a7c500c9accc0c897cc50ccccccc0a78ccc50ccccccc005ccca780ccccccc05cccccc0ccccccccccc7accccccccccccccc87ccccccccc
0ccca9c00cccccc00ca7ccc00c7cccc0c97ccc50ccccccc0ccccccc0cc89acc00ccccca70ccccccc0cccc8790cc798ccccccccccccc78cccccccc7cccccccccc
00cccc0000cccc000cccccc00cccccc0cccccc00cccccc00ccccccc0cc9a7cc000cccccc00cccccc0ccccc870ccc7ccccccccccccc78accccccccccccccccccc
000cc000000cc0000cccccc00cccccc0ccccc000ccccc000ccccccc0ccccccc0000ccccc000ccccc0ccccccc0ccccccccccccccccccccccccccccccccccccccc
000000000085000000857000008500000000000000000000000000000000000000000000000000000c4444c00000000000000000000000000000000000000000
00857000888570008885700088857000000000000000000000000000000000000000000000000000044444400000000000077000000077000000770000077000
88857000000574400005000000057000000000000000000000000000000000000000000000000000441111440000000000077000000077000000770000077000
00050440000504440045744000050440000000000000000000000000000000000000000000000000115555110000000000000000000000000000000000000000
00457444004574000445744400457444000000000000000000000000000000000000000000000000554444550000000000077000000770000007700000077000
04457400044770404044740044447400000000000000000000000000000000000000000000000000544444450000000000077000000770000007770000077000
44470400440070400400004000047040000000000000000000000000000000000000000000000000441111440000000000007000007070000007000000700700
00400400040000000000000400040040000000000000000000000000000000000000000000000000415cc5140000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222200000000000000000000000000000002a92000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2aaaa999220000000000000000000000000000002992000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a999999920000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29922299920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29920229922222222000022222000222200022202222022220022220022222200022222200000000000000000000000000000000000000000000000000000000
29922299922aa99920002aa9992002aa2002a9202a2202aa9202a92022aaa99222aa999200000000000000000000000000000000000000000000000000000000
29999999922a22229202a992299202a9200299202a9202a99922a9202a92229922a9222200000000000000000000000000000000000000000000000000000000
29999999202920029202992029920299222299202992029929929922a92000222299222200000000000000000000000000000000000000000000000000000000
29922222002922292202992029920029922992002992029922999922992000000299992000000000000000000000000000000000000000000000000000000000
29920000002999992002992029920029922992002992029920299922992000222299222000000000000000000000000000000000000000000000000000000000
29920000002922992002992029920002992920002992029920099920299222992299222200000000000000000000000000000000000000000000000000000000
19910000001911199101999119910001999910001991019910019910199999910199999100000000000000000000000000000000000000000000000000000000
14410000001411114100144444100000144100001441014410014410014444100144444100000000000000000000000000000000000000000000000000000000
11110000001110011100011111000000011000001111011110011110001111000111111100000000000000000000000000000000000000000000000000000000
__map__
3232003100323132310032003231323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100310000310000000000000000313200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031312525252525253100003100313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
323131252c25252c310000000000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031312550252550313100310060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525250050000050171700006060003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
252c5050505050505050501d6000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525502c25001750000031006000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000502525006060606060606000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505050001717601a500050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4e00503131006000501750252525003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000505050006031501750252c25003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000311750507a50500050255025310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3100000060606000505050505000313200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000606060310017502525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
313160001717000050252c253100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031600050505050502550253100003200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031603131313131505050000031320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3200606000003131000050313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32320060323132000032504e3231323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000000000000000000000000000000000000060600060600060600060000000002020606060606060606000086860686868686868606060606060000000000000000000006060606060602020202020202020202020202020202020808080808080808080808080808080800000000000000000000020000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001003305013030130200300003010030400307003070030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
000900000b73005710047000270001700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000400000d61216622176220d6120a612086120161201612006120060200602006020060200602006020060200602006020060200602006020060200602006020060200602006020060200602006020060200602
000300000761207622046320363202622026220361203612016120061200612006120061200612006020060200602006020060200602006020060200602006020060200602006020060200602006020060200602
000300001671520535135451a75510735237451d725147250e71519755247752c745117050f7050e7050c7050a70509705087050670506705057050470504705037050370502705027050770507705077051c305
0006000016041160511605114055000511305113051130511305111051000550f0510f0510f0510f0510d055000510a0510a0510a0510a0540a0550a0510a0550a0410a0450a0310a0240a0150a0140901500035
000400000452500705007050070500705007050070500705007050050500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
001000000453500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000400000b5130d5330e5430f54210553115521355214552165521655216552165421653516532165221652516512165151651516515000020000200002000020000200002000020000200002000020000200002
000600000955409550095520e5520e5500e5521555215550155521a5501a5501a5501a5501a5501a5501a5401a5401a5351a5301a5251a5251a5151a5152b5002b5002b500015000150000500005000050000500
000500000154501505005050154501505000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000b5350b555195451950500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000112002130031300000500055061050000500055051050000500055031050000500055011050000501105000050000500055031050005500005000050005500005000050005500005000050005500005
001800000110000005000550000500055061050000500055051050000500055031050000500055011050000501105000050000500055031050005500005000050005500005000050005500005000050005500005
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00141d00110550505507005000050c0550c055070050700507055070550a0550a0550a0050a005050050305503055070050700507055070550a002050050c0550c05507055070550000507005030050300503005
021400000a1120a1120c1120c1120f1121111211112131121311213112161121611218112181121811218112181121811218112181121611216112131121311211112111120f1120f1120c1120a1120a1120a112
001000000c1120c1120c1120c1120c1120f11211112111121111211112111120f1120c11207112071120c1120f1120f1120c1120c1120c1120c1120c1120c1120c1120c1120c1120c1120c1120c1120a1120a112
021400000a1120c1120f1120f112111120c1120c1120c1120c1120711207112071120c1120c1120c1120c1120c11207112071120c1120f1120f1120f1120f11211112111120f1120a11207112071120a11207112
021400000a1120c1120f11211112131121311213112071120511205112071120a1120a112071120a1120c1120c1120f1121111211112111120f1120c1120a11207112071120a1120a1120a1120c1120c1120c112
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000000b0550b05500005000050605500005000050a0550a0550000500005030550000501005080550805500005040050605500005070050805508055000050500503055060550305502055040550605508055
00200000097150971509715097150971508715077150771507715077150771507715097150d7150f7150f7150f7150f7150f7150f7150f7150f7150f7150f7150e7150a7150a7150a7150a7150a7150a7150a715
00200000077350775506755000050873506735000050a7350a7550775500005037350273501005087350875505755040050b73509735070050873508755067550500505725067350774509745097350672505715
__music__
01 20614344
00 20624644
00 20634344
00 20634344
06 20644344
00 41424344
00 41424344
01 10424344
00 11424344
04 11424344
01 28696a44
00 28296a44
00 28292a44
04 28696a44
__label__
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
00000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000
00010000000100000000000002222222220b000000010000000300000001000002a9200000000000000100000000000000010000000300000001000000010000
00010000000100000000000002aaaa99922b00000001000000030000000100000299200000000000000100000000000000010000000300000001000000010000
00011000000110000000000002a99999992b30000001100000031000000110000022100000000000000110000000000000011000000310000001100000011000
00011000000110000000000002992229992b30000001100000031000000110000003100000000000000110000000000000011000000310000001100000011000
00011000000110000000000002992022992222222201102222211022220112220222202222002222002222220002222220011000000110000001100000011000
00131100001b110000030000029922299922aa99921312aa9992312aa21b2a9202a2212aa9202a92022aaa99222aa99920111111003331000013110000111100
01131110011b111000030000029999999922a22229232a992299212a921b299202a9212a99922a9202a92229922a922221111110033331100113111001111110
00131100001b310000031000029999999232920029232992029921299222299202992129929929922a9211022229922220111100001111000013110000111100
01131110011b311000031000029922222bb292229223299202992112992299200299212992299992299211100029999201111110033111100113111001111110
11111111111331110001100032992111bb3299999211299232992112992299213299212992029992299211122229922211111111331111111111111111111111
0033310000b3b30000333100029920001102922992332992129923002992921102992029920b99921299222992299222200b1011000b10110033310000131100
033331100bb3b33003333110019910000111911199131999119913311999913011991319911b19911199999911199999111b0000011b00000333311001131110
001111000033130000131100014410000001411114111144444133110144130001441314411b14411114444100144444100b3000000b30000013110000131100
033111100bb3133003331110011110000001110011111111111333310b113330b1111311110b11111111111100111111100b3000000b30000333111001131110
33111111bb3113333311111103b3bb3003b3bb3033b3bb31b3b3bb33b3b3bb3313b3bb3011133000111100010000000000033000000330003311111111111111
0001100000333100003331003bbb3bb33bbb65b33bbb3bb33bbb3bb33bbb65b33bbb3bb301bbb30110111111000b100100bbb30100bbb3000033311100333100
000100000333311003333110bbbb3bbbbbb665bbbbbb3bbbbbbb3bbbbbb665bbbbbb3bbb1bbbb33111111111111b00111bbbb3310bbbb3300333311003333110
0001100000131100001311003b3bbbbb55365bbb3b3bbbbb3b3bbbbb55365bbb3b3b3bbb0133331111111111011b3011013b3311003333000011110000111100
000110000333111003331110bb3b3b3b6655566bbb3b3b3bbb3b3b3b6655566bbb3b3b3b0bb3333111111111000b31110bbb33310bb333300331111003311110
000110003311111133111111b3b3bb3bb6655566b3b3bb3bb3b3bb3bb6655566b3b33b3bbb3333331111111111133000bb333333bb3333333311111133111111
001b110011333100113b31003bbb3bb3544564553bbb3bb33bbb3bb35445645533bbb333111b50001101111111bbb30011bbb300110451000001101100011011
011b111003333110033b3110bbbb3bbb55566555bbbb3bbbbbbb3bbb555665551bbbb331111b1111111111111bbbb3311bbbb331000000000115555555555555
001b310000131100001b31003b3bbbbb545644453b3bbbbb3b3bbbbb54564445013b3311111b311101110011113b33111133331100000000005ccccccccccccc
011b311003331110033b3110bb3b3b3b5f4aa4f5bb3b3b3bbb3b3b3b5f4aa4f50bbb3331111b3111000111111bbb33311bb333310000000005cccccccccccccc
111331113311111133133111b3b3bb3b5f4aa4f5b3b3bb3bb3b3bb3b5f4aa4f5bb3333331113311111111000bb333333bb333333000000110ccccccccccccccc
11bbb3001133310011bbb3013bbb3bb35f4994f53bbb3bb33bbb3bb35f4994f511bbb30011bbb3111111110010bbb31111145111110110010ccbcccccccbcccc
0bbbb330033331101bbbb331bbbb3bbb55555555bbbb3bbbbbbb3bbb555555551bbbb3311bbbb331111111111bbbb33111111111111555555ccbcccccccbcccc
0033330000111100013333113b3bbbbb111551113b3bbbbb3b3bbbbb11155111113333111133331111111111113b331111111111015ccccccccb3cc0000b3000
0bb33330033111100bb33331bb3b3b3b11555511bb3b3b3bbb3b3b3b115555111bb333311bb33331111111111bbb33311111111105cccccccccb3cc0000b3000
ba99a9a33a99a9a1ba99a9a3b3bbbb3b11555511b3bbbb3bb3bbbb3b11555511b5544553b554455311111111bb333333111111111cccccccccc33cc000033011
a99999aaa99965aaa99999aa333333331155551133333333333333331155551144444444444444441111111111bbb311111011111cccccccccbbb30011bbb300
a99a99a9a99665a9a99a99a913333331115555111333333113333331115555514444444444444444111111111bbbb331111555555ccccccccbbbb3311bbbb331
99a9999955a6599999a99999111111111155551111111111111111111155555544455444444554441111111111333311115cccccccccccc1113b3311113b3311
9999a99a6655566a9999a99a11111111115555111111111111111111115555554555555445555554111111111bb3333115ccccccccccccc11bbb33311bbb3331
aa99a9aaa6655566a9a9a9aa11111111115555011758111111111111115555555f4aa4f55f4aa4f511111111bdd588d31cccccccccccccc1bb333333bb333333
a99999aa544564553333333311116511115555111758881111111111115555555f4994f55f4994f5111b1111d511412d1ccccccccccbbc1111bbb31100bbb311
a99a99a9555665551333333111166511155555511151111111111111155555515555555555555555111b1111d111411d1cccccccccbb83111bbbb3311bbbb331
99a99999545644455555555555565555555555544754555555555555555555555555555555555555555b355555dddd221cccccc11b8bb33111333311013b3311
9999a99a5f4aa4f55555555566555665555555444754455555555555555555555555555555555555555b35555a5222a21cccccc1bbb333831bb333310bbb3331
aa99a9aa5a99a9a555555555566555665a99a9a5474454555554455555555555555555555555555555533555595552921cccccc11bb83331bb333333bb333333
a99999aaa99999aa5555555554456455a99999aa555545554444444455555555555555555555555555bbb355155522211cccccc111bb3311111b511111bbb300
a99a99a9a99a99a91555555155566555a99a99a911111111444444441555555111111111111111111bbbb331115552111cccccc1111b1111111b11111bbbb331
99a9999999a99999115555555456444599a99999111111114445544455555511111111111111111111333311111111111cccccc1111b3111111b311111333311
9999a99a9999a99a115555555f4aa4f59999a99a11111111455555545555551111111111111111111bb33331111111111cccccc1111b3111111b31111bb33331
a9a9a9aaa9a9a9aa115555555a99a9a5aa99a9aa111111115f4aa4f5555555111111111111111111bb333333111111111cccccc11113311111133001bb333333
333333333333333310555555a99999aaa99999aa111111115f4994f555555111111111111111111111145111111111111cccccc111bbb31111bbb31111145111
033333301333333111555551a99a99a9a99a99a9111111115555555555555555555555555555555555555555555555555cccccc11bbbb3311bbbb33111111111
00000000111111111155551199a9999999a9999911111111115cccccccccccccccccccccccccccccccccccccccccccccccccccc1113333111133331111001111
0000000011111111115555119999a99a9999a99a1111111115ccccccccccccccccccccccccccccccccccccccccccccccccccccc11bb333311bb3333111110011
000000111111100111555511a9a9a9aaa554511a155451111cccccccccccccccccccccccccccccccccccccccccccccccccccccc1bb333333bb33333311110001
110000111111111111555511333b3333444b5555444b55551ccccccccc8f8f8fcccccccccccccccccccccccccccccccccccccc11111451111114511110131111
011000001111111115555511133b3331444b5555444b55551ccccccc558f8f8fccccccccccccccccccccccccccccccccccccc111111111111111111111131111
555555555555555555555511111b3111444b3555444b35551cccccc1458f8f8f5555511111111111111555555555555555555555555555555555511111131111
555555555555555555555511111b3111555b3111555b31111cccccc1414aaaa45557751111111111115555555555555555555555555555555555551111b31111
555555555555555555555501111331115f4334f55f4334f51cccccc15549449455577511155445511155555553b3bb3553b3bb3553b3bb35555555111b311311
55544445555555555555551111bbb3115fbbb3f55fbbb3f51cccccc1155b11515555551144444444117755553bbb3bb33bbb65b33bbb3bb355555111113b3111
1444445111111111155555111bbbb3315bbbb3355bbbb3351cccccc1115b5511155775514444444415775551bbbb3bbbbbb665bbbbbb3bbb11111111133b3111
1144511111111111115555111133331111333311113333111cccccc1111b31111157755544455444555555113b3bbbbb55365bbb3b3bbbbb11111111011b3111
1114501111111111115555111bb333311bb333311bb333311cccccc1111b3111115755554555555455577511bb3b3b3b6655566bbb3b3b3b11111111033b3111
111450011111100111555501bb333333bb333333bb3333331cccccc111133111115555555554455555777511b3b3bb3bb6655566b3b3bb3b1111100133133111
0014511111111111005b55111104511111145111111451111cccccc111bbb3111177555544444444555575113bbb3bb3544564553bbb3bb3111b111111bbb300
0111101011111111115b55511111111111111111111111111cccccc11bbbb331117755514444444415577511bbbb3bbb55566555bbbb3bbb111b11111bbbb331
0000000001110011015b35555555555555555111111111111cccccc1113333111155555544455444555775113b3bbbbb545644453b3bbbbb110b311111333311
0000000000011111005b35555555555555555511111111111cccccc11bb33331115775554555555455555511bb3b3b3b5f4aa4f5bb3b3b3b111b30111bb33331
0000000011111000115335555554455555555511111111111c444857bb333333117775555f4aa4f555577511b3b3bb3b5f4aa4f5b3b3bb3b11133001bb333333
10131100111b110011bbb3554444444455555511111111111448885711145111115575555f4994f5555775113bbb3bb35f4994f53bbb3bb311bbb31100115111
10131111101b11111bbbb3314444444415555551111111114411115411111111155555515555555515755711bbbb3bbb55555555bbbb3bbb1bbbb33111111011
11031111110b31111133331144455444555555555555555511555457445555555555551111111111115555113b3bbbbb111551113b3b3bbb113b331101111011
11131011111b30111bb333314555555455555555555555555544445744455555555555111111111111555511bb3b3b3b11555511bb3b3b3b1bbb333100011111
1111100111133001bb3333335f4aa4f555555555555555555444444745555555555555111111111111555511b3bbbb3b11555511b3b33b3bbb33333311111000
0033311110bbb311101451115f4994f555555555555b55554411414454555555557755111111111111555511333333331155551133bbb33311bbb31101111111
033331101bbbb331101111115555555511155555555b5555415cc5141141111115775551111111111555555113333331155555111bbbb3311bbbb33101111111
00111100113333111100111111111111115ccccccccb3ccccc7cc51111111111115555555555555555555555555555555555551111333311013b331100111100
033111101bb33331111100111111111115cccccccccb3cccc77ccc511111111111577555555555555555555555555555555555111bb333310bbb333101111110
33111111bb33333311110001111111111cccccc7ccc33cccc7cccc5115544551117775555a99a9a55a99a9a55a99a9a555555511bb333333bb33333311111111
110311000013511110111111111111111cccccccccbbb3cccccccc114444477411557555a99999aaa99965aaa99999aa555b51111114511111bbb30000011100
000300000013101010155555555555555ccc7ccccbbbb33cccccc1114444477415555551a99a99a9a99665a9a99a99a9111b1111111111111bbbb33100000000
0003100000031000115cccccccccc7ccccc77cc11133331111111111444554445555551199a9999955a6599999a99999111b3111111111111133331100000000
000310000003100015cccccccccc7cccccccccc11bb333311111111145555774555555119999a99a6655566a9999a99a111b3111111111111bb3333100000000
00011011000110111cccccccccccccccc5544550b5544553111111115f4aa77555555511aa99a9aaa6655566aa99a9aa1113311111111111bb33333300000011
113b3100113331000cccccc7cccccccc4444444444444444111111115f49947555555511a99999aa54456455a99999aa11b3b311111011110014511111010000
033b3110033331100ccccccccccccccc4444444444444444111111115555555515555511a99a99a955566555a99a99a91bb3b331111111110111101000010000
001b3100001311000cccccc000000000444554444445544411001111111111111155551199a999995456444599a9999911331311110011110000000000011000
033b3110033311100cccccc00000000045555554455555541111001111111111115555119999a99a5f4aa4f59999a99a1bb31331111100110000000000011000
33133111331111110cccccc0000000115f4aa4f55f4aa4f5111100011111111111555511aa99a9aa5f4aa4f5aa99a9aabb311333111100010000000000011000
00bbb300113331110cccccc0110300115f4394f55f4b94f5101311111103111111555511a99999aa5f4994f5a99999aa11333111001311110001110000111100
0bbbb330033331100cccccc00113000055535555555b5555101311111113111115555511a99a99a955555555a99a99a913333111011310100001000001111110
003b3300001311000cccccc00003100011031555555b355555531555555315555555551199a999991105511199a9999900111100000310000001100000111100
0bbb3330033311100cccccc00003100011531555555b35555553155555531555555555119999a99a115555119999a99a03311110000310000001100001111110
bb333333331111110cccccc1000110001151155555533555555115555551155555555511a9a9a9aa11555501a9a9a9aa33111111000110000001101111111111
00b1b300003331001cccccc0003331000033315555bbb355553331555533315555555511333b3333105555113333333311031011003331001113110000031000
0bb1b330033331100cccccc003333110033331101bbbb331033331100333311115555551133b3331155555110333333001130000033331100113111000030000
00311300001111000cccccc0001111000011110011333311001311000013110001555555555b3555555555110003100000031000001311000013110000031000
0bb11330033111100cccccc003311110033111101bb33331033311100333111000555555555b3555555555110003100000031000033311100113111000031000
bb311333331111110cccccc13311111133111111bb33333333111111331111111155555555533555555555010001100000011000331111111111111100011000
00111100000110001ccbccc011011000000110000013511111313111113331000115555555b1b355555555110033311100313100003331000031310000313100
01111110000100000ccbccc55555500000010000001310100331311003333110011111110bb1b330055555100333311003313110033331100331311003313110
00111100000110000ccb3cccccccc500000110000003100000111100001111000000000000311300005555000011110000111100001311000011110000111100
01111110000110000ccb3ccccccccc5000011000000310000331111003311110000000000bb11330005555000331111003311110033311100331111003311110
11111111000110000cc33cccccccccc00001100000011011331111113311111100000000bb311333005555003311111133111111331111113311111133111111
001111000011110000bbb3ccccccccc0001111001133310000111100110110000001100011111100005555000004444000111100003331000011110000111100
01111110011111100bbbb33cccccccc0011111100333311001111110000000000000000001111110005555000444445001111110033331100111111001111110
0011110000111100003333000cccccc0001111000011110000111100000000000000000000111100005555000044500000111100001111000011110000111100
01111110011111100bb333300cccccc0011111100331111001111110000000000000000001111110005555000004500001111110033111100111111001111110
__meta:title__
province
by perfoon
