pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

debug = ""
version_id = "V1.02"

-- convert old format memory into new format
function move_data()
  dset(0, dget(0))
  dset(1, dget(1))
  local co_and_ship = "2" .. sub("000" .. min(dget(2), 999), -3)
  dset(2, co_and_ship)
  dset(3, dget(3))
  dset(4, dget(4))
  local co_and_ship = "2" .. sub("000" .. min(dget(5), 999), -3)
  dset(5, co_and_ship)
  dset(6, dget(6))
  dset(7, dget(7))
  local co_and_ship = "2" .. sub("000" .. min(dget(8), 999), -3)
  dset(8, co_and_ship)
  -- I HAVE TO DO IT BACKWARDS SO IT DOESNT OVERWRIGHT ITSELF
  dset(23, 2000)
  dset(22, dget(18))
  dset(21, dget(17))
  dset(20, 2000)
  dset(19, dget(16))
  dset(18, dget(15))
  dset(17, 2000)
  dset(16, dget(14))
  dset(15, dget(13))
  dset(14, 2000)
  dset(13, dget(12))
  dset(12, dget(11))
  dset(11, 2000)
  dset(10, dget(10))
  dset(9, dget(9))
end

function reset_data()
  local name_list = {14383, 2067, 11602, 19662, 339, 22766, 588, 5667, 3722, 2069, 3183}
  local default_data = {0.5238, 193, 81, 0.4117, del(name_list, rnd(name_list)), 92, 0.3086, del(name_list, rnd(name_list)), 10, 0.3065, del(name_list, rnd(name_list)), 0.2047, del(name_list, rnd(name_list)), 0.1039, del(name_list, rnd(name_list)), 0.1032, del(name_list, rnd(name_list)), 0.1021, del(name_list, rnd(name_list)),}
  --[[
	local default_data={
		0.5238,
		0b000000011000001,
		2981,

		0.4117,
		del(name_list,rnd(name_list)),
		2092,

		0.3086,
		del(name_list,rnd(name_list)),
		2010,

		0.3065,
		del(name_list,rnd(name_list)),
		2010,

		0.2047,
		del(name_list,rnd(name_list)),
		2399,
		
		0.1039,
		del(name_list,rnd(name_list)),
		2993,

		0.1032,
		del(name_list,rnd(name_list)),
		2111,

		0.1021,
		del(name_list,rnd(name_list)),
		2011,

	}
	]]
  --
  for i = 0, 64 do
    dset(i, default_data[i + 1])
  end
end

function _init()
  t = 0
  cartdata "kalika_v1_01"
  local menu_start_screen = "ramcheck"
  if dget(0) == 0 then
    reset_data()
  end
  -- reset_data()
  if dget(21) == 0 then
    move_data()
  end
  is_duplicate_load = dget(63) == 1
  -- the dget locations
  score_memory_locations = split "0,3,6,9,12,15,18,21"
  start_info = split(stat(6), "|")
  if start_info[1] == "died" and not is_duplicate_load then
    menu_start_screen = "highscores"
    prevrun_score = start_info[3]
    prevrun_maxhit = start_info[4]
    prevrun_type = start_info[5]
    new_score_position = score_spot_pos(prevrun_score)
    if new_score_position > 0 then
      menu_start_screen = "submit"
    end
    dset(63, 1)
  end
  alphabet_string = split "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z"
  add(alphabet_string, ".")
  poke4(0x5600, unpack(split "0x9.0908,0x.0100,0x1100,0x7.0700,0x.0070,0x700.7000,0,0,0,0x7.0070,0,0,0x.0007,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0x3f3f.3f3f,0x3f3f.3f3f,0x3f3f.3f00,0x3f.3f3f,0x333f.3f00,0x3f.3f33,0xc33.3300,0x33.330c,0x33.3300,0x33.3300,0x3333.3300,0x33.3333,0x3f3c.3000,0x30.3c3f,0x3f0f.0300,0x3.0f3f,0x303.0f0f,0,0,0x7878.6060,0x1e3f.3300,0xc3f.0c3f,0xc00,0x.000c,0,0x181c.0c0c,0,0xf0f.0f0f,0x66.7733,0,0x3e36.3e1c,0x.001c,0,0,0x1e3f.3f3f,0xc0c.001e,0x6677.3333,0,0x367f.7f36,0x367f.7f36,0x3f1b.7f7e,0x3f7f.6c7e,0x3873.6300,0x6367.0e1c,0x1f1b.1f0e,0x1e3f.737e,0xc1c.1818,0,0x307.7e7c,0x7c7e.0703,0x6070.3f1f,0x1f3f.7060,0x1c3e.3600,0x.363e,0x3f0c.0c00,0xc.0c3f,0,0xc1c.1818,0x7e00,0x.007e,0,0xc0c,0x3870.6000,0x307.0e1c,0x6b63.7f3e,0x3e7f.636b,0x181f.1f18,0x7f7f.1818,0x7e60.7f3f,0x7f7f.033f,0x7c60.7f3f,0x3f7f.603c,0x676e.7c78,0x6060.7f7f,0x3f03.7f7f,0x3f7f.607f,0x3f03.7f7e,0x3e7f.637f,0x3870.7f7f,0x307.0e1c,0x3e63.7f3e,0x3e7f.637f,0x7f63.7f3e,0x3f7f.607e,0x.1818,0x1818,0x.1818,0xc1c.1818,0x1f7c.7000,0x70.7c1f,0x7f.7f00,0x7f.7f00,0x7c1f.0700,0x7.1f7c,0x7c60.7f3f,0xc0c.003c,0x7b6b.7f3e,0x7e7f.037b,0x7e60.7e3e,0x7e7f.637f,0x3f03.0303,0x3f7f.637f,0x637f.3e00,0x3e7f.6303,0x7e60.6060,0x7e7f.637f,0x7f63.7f3e,0x7e7f.037f,0x1f66.7e3c,0x606.061f,0x3f33.7f7e,0x1f3f.381e,0x3f03.0303,0x6363.637f,0xc00.0c0c,0x181c.0c0c,0x6000.6060,0x3e7f.6360,0x7363.0303,0x6373.3f3f,0xc0c.0c0c,0x181c.0c0c,0x7f7f.3600,0x6363.636b,0x7f3f.0300,0x6363.6363,0x637f.3e00,0x3e7f.6363,0x637f.3f00,0x303.3f7f,0x637f.7e00,0x6060.7e7f,0x7f3f.0300,0x303.0363,0x77f.7e00,0x3f7f.703e,0x7f7f.0606,0x7c7e.0606,0x6363.6300,0x3e7f.6363,0x7763.6300,0x1c1c.3e3e,0x6363.6300,0x367f.7f6b,0x3e77.6300,0x6377.3e1c,0x7f63.6300,0x3f7f.607e,0x387f.7f00,0x7f7f.0e1c,0x303.7f7f,0x7f7f.0303,0xe07.0300,0x6070.381c,0x6060.7f7f,0x7f7f.6060,0x363e.1c08,0,0,0x7f7f,0x181c.0c0c,0,0x7f63.7f3e,0x6363.637f,0x3f63.7f3f,0x3f7f.637f,0x363.7f3e,0x3e7f.6303,0x6363.7f3f,0x3f7f.6363,0x3f03.7f7f,0x7f7f.033f,0x3f03.7f7f,0x303.033f,0x7b03.7f7e,0x3e7f.637b,0x7f63.6363,0x6363.637f,0xc0c.7f7f,0x7f7f.0c0c,0x3030.7e7e,0x1e3f.3330,0x1f3b.7363,0x6373.3b1f,0x303.0303,0x7f7f.0303,0x7f7f.3636,0x6363.636b,0x7f6f.6763,0x6363.737b,0x6363.7f3e,0x3e7f.6363,0x6363.7f3f,0x303.3f7f,0x6363.7f3e,0xfeff.7363,0x6363.7f3f,0x6373.3f7f,0x3f03.7f7e,0x3f7f.607e,0xc0c.7f7f,0xc0c.0c0c,0x6363.6363,0x3e7f.6363,0x3677.6363,0x81c.1c3e,0x6b63.6363,0x3636.7f7f,0x3e77.6363,0x6363.773e,0x7f63.6363,0x3f7f.607e,0x3870.7f7f,0x7f7f.0e1c,0x706.7e7c,0x7c7e.0607,0x1818.1818,0xc0c.0c0c,0x7030.3f1f,0x1f3f.3070,0x3b7f.7f6e,0,0x3e36.3e3e,0x.003e,0xffff.ffff,0xffff.ffff,0xcccc.3333,0xcccc.3333,0x497f.6300,0x3e63.777f,0x7777.3e00,0x3e77.6341,0x3030.0303,0x3030.0303,0xfcfc.0c0c,0x3030.3f3f,0x4f4f.3e00,0x3e7f.7f7f,0x7f7f.3600,0x81c.3e7f,0x7f7f.3e00,0x3e7f.7f77,0x7f1c.1c00,0x363e.1c7f,0x3e1c.0800,0x3636.3e7f,0x7377.3e00,0x3e77.7341,0x497f.3e00,0x3e63.417f,0x1818.7838,0xe1f.1f1e,0x637f.3e00,0x3e7f.6349,0x7f7f.3e00,0x3e7f.7f7f,0x3300,0x.0033,0x6777.3e00,0x3e77.6741,0x7f1c.0800,0x6377.3e7f,0x3e7f.7f00,0x7f7f.3e1c,0x6377.3e00,0x3e77.7741,0x40e.1f1b,0x2070.f8d8,0xeec7.8301,0x10.387c,0x6b5d.3e00,0x3e5d.6b77,0x.ffff,0x.ffff,0x3333.3333,0x3333.3333"))
  pal(split "-3,9,10,5,13,6,7,136,8,3,139,138,130,133,0,2", 1)
  -- poke(0x5f2e,1)
  palt(0, false)
  palt(11, true)
  _upd = nil
  _drw = nil
  button_drwdat = parse_data "0,0,12,10|12,0,12,10"
  time_since_input = 0
  is_idle = true
  highest_score = tostr(dget(0), 0x2) .. "0"
  lerp_objects = {}
  logo_obj = {}
  new_lerpobj(logo_obj, 28, 16)
  sides_obj = {}
  new_lerpobj(sides_obj, -4, 0)
  menu_goto(menu_start_screen)
end

function _update60()
  t = t + (1)
  swapped_this_frame = false
  time_since_input = time_since_input + (1)
  frame_progress = frame_progress + (1)
  foreach(lerp_objects, upd_lerpobj)
  if btnp_any() then
    time_since_input = 0
  end
  _upd()
end

function _draw()
  cls(13)
  _drw()
  print(debug, 1, 1, 7)
end

-->8
-- submit highscore
function init_submit()
  cursor = {cx = 0, cy = 0,}
  grid_x, grid_y = 15, 50
  grid_w, grid_h = 15, 15
  local x, y = index_2_pos(0, 0)
  new_lerpobj(cursor, x, y)
  selection_index = 1
  player_name = {0, 0, 0}
  submit_finished = false
end

function index_2_pos(_x, _y)
  return grid_x + _x * grid_w, grid_y + _y * grid_h
end

function submit_data(_pos)
  local char_a, char_b, char_c = convert_to_binary(player_name[1]), convert_to_binary(player_name[2]), convert_to_binary(player_name[3])
  local binary = "0b" .. char_a .. char_b .. char_c
  for i = #score_memory_locations - 1, _pos, -1 do
    local start_loc, end_loc = score_memory_locations[i], score_memory_locations[i + 1]
    dset(end_loc, dget(start_loc))
    dset(end_loc + 1, dget(start_loc + 1))
    dset(end_loc + 2, dget(start_loc + 2))
    if end_loc < 9 then
      dset(end_loc + 2, dget(start_loc + 2))
    end
  end
  dset(score_memory_locations[_pos], prevrun_score)
  dset(score_memory_locations[_pos] + 1, tonum(binary))
  local clamped_score = min(prevrun_maxhit, 999)
  local save_score = sub("000" .. clamped_score, -3)
  dset(score_memory_locations[_pos] + 2, tonum(prevrun_type .. save_score))
  highest_score = tostr(dget(0), 0x2) .. "0"
  menu_goto("highscores")
end

-- returns the index "position" that a players high score will be
function score_spot_pos(_number)
  local position = -1
  for i = #score_memory_locations, 1, -1 do
    if _number > dget(score_memory_locations[i]) then
      position = i
    end
  end
  return position
end

-- this is cringe please don't just me I wrote this when I was very tired
-- convert 0-31 number to 5 bit binary
function convert_to_binary(_num)
  local cur = _num
  local out = ""
  for i = 0, 5 do
    if cur > 0 then
      out = out .. (cur % 2)
      cur = flr(cur * 0.5)
    end
  end
  out = sub(out .. "00000", 1, 5)
  local n_out = ""
  for i = #out, 0, -1 do
    n_out = n_out .. (sub(out, i, i))
  end
  return n_out
end

function update_submit()
  local button_pressed = false
  local newx, newy = cursor.cx, cursor.cy
  if btnp "0" then
    newx = newx - (1)
    button_pressed = true
  end
  if btnp "1" then
    newx = newx + (1)
    button_pressed = true
  end
  if btnp "2" then
    newy = newy - (1)
    button_pressed = true
  end
  if btnp "3" then
    newy = newy + (1)
    button_pressed = true
  end
  cursor.cx = mid(0, newx, 6)
  cursor.cy = mid(0, newy, 3)
  if button_pressed then
    local nx, ny = index_2_pos(cursor.cx, cursor.cy)
    new_lerp(cursor, nx, ny, .2)
    submit_finished = false
  end
  if btnp(5) then
    if cursor.cx == 6 and cursor.cy == 3 then
      submit_data(new_score_position)
      return
    end
    if selection_index == 3 then
      player_name[selection_index] = min(cursor.cx + cursor.cy * 7, 26)
      cursor.cx, cursor.cy = 6, 3
      local nx, ny = index_2_pos(cursor.cx, cursor.cy)
      new_lerp(cursor, nx, ny, .2)
      submit_finished = true
      return
    end
    player_name[selection_index] = min(cursor.cx + cursor.cy * 7, 26)
    selection_index = min(selection_index + 1, 3)
  end
  if btnp(4) then
    player_name[selection_index] = min(cursor.cx + cursor.cy * 7, 26)
    selection_index = max(selection_index - 1, 1)
  end
end

function draw_submit()
  local letters = parse_data "a,b,c,d,e,f,g|h,i,j,k,l,m,n|o,p,q,r,s,t,u|v,w,x,y,z,.,"
  for i = 0, #letters - 1 do
    local row = letters[i + 1]
    for n = 0, #row - 1 do
      local x, y = grid_x + n * grid_w, grid_y + i * grid_h
      print("\014" .. row[n + 1], x, y + 1, 5)
      print("\014" .. row[n + 1], x, y, 7)
    end
  end
  sspr(8, 119, 9, 9, grid_x + 89, grid_y + 45)
  local curs_x, curs_y = cursor.cx * grid_w, cursor.cy * grid_h
  rect(grid_x - 3 + curs_x, grid_y - 3 + curs_y, grid_x + 9 + curs_x, grid_y + 11 + curs_y, 5)
  local curs_x, curs_y = cursor.x, cursor.y
  rect(curs_x - 3, curs_y - 3, curs_x + 9, curs_y + 11, 6)
  local topx, topy = 50, 20
  for i = 0, 2 do
    local _x = topx + i * 10
    local char = alphabet_string[player_name[i + 1] + 1]
    if not submit_finished and i + 1 == selection_index then
      char = alphabet_string[cursor.cx + cursor.cy * 7 + 1] or " "
    end
    print("\014" .. char, _x, topy + 1, 5)
    print("\014" .. char, _x, topy, 7)
  -- print(player_name[i+1],_x,topy,5)
  end
  local current_score = tostr(prevrun_score, 0x2) .. "0"
  print(hcentre(current_score, topy + 13, t % 8 < 4 and 5 or 4))
  print(hcentre(current_score, topy + 12, 7))
  local bx = topx - 2 + (selection_index - 1) * 10
  if not submit_finished then
    rect(bx, topy - 2, bx + 10, topy + 10, 5)
  end
-- line(63,0,63,128,8)
end

-->8
-- high scores
function init_highscores()
  fade_perc, fade_rate = 1, -0.03
  new_lerp(sides_obj, -6, 0, .05)
end

function update_highscores()
  if frame_progress > 1000 then
    menu_goto("basic")
  end
  if btnp(5) then
    menu_goto("basic")
    sfx(62)
  end
end

function draw_highscores()
  cls(13)
  do_fade(fade_perc)
  local _y = 4 + min(0, sin(frame_progress * .001 - .2) * 70)
  local oy = _y
  drw_hs_big(23, _y, 1, 6)
  _y = _y + (30)
  for i = 2, 3 do
    drw_hs_big(24, oy + 3 + (i - 1) * 32, i, 4)
    _y = _y + (28)
  end
  _y = _y + (0)
  for i = 4, 8 do
    drw_hs_small(24, _y + 2 + (i - 4) * 19, i, 4)
  end
  -- borders
  map(0, 0, 0 + sides_obj.x, 0, 2, 16)
  map(0, 0, 128 - 16 - sides_obj.x, 0, 2, 16)
end

function mem_2_string(_binary)
  -- five bytes each which is a max of 31
  -- 00000 00001 00010 = cba
  -- oh yeah its also backwards
  -- alphabet (26) + , . - 
  local z = _binary & 31
  local y = (_binary >> 5) & 31
  local x = (_binary >> 10) & 31
  local letter_a = alphabet_string[min(z, 26) + 1]
  local letter_b = alphabet_string[min(y, 26) + 1]
  local letter_c = alphabet_string[min(x, 26) + 1]
  return letter_c .. letter_b .. letter_a
end

function drw_hs_small(_x, _y, _num)
  local bg_col = 12
  local ox, oy = _x + 9, _y
  rndrect(ox, oy + 11, 80, 14 + 2, 3, 5)
  rndrect(ox, oy + 11, 80, 14, 3, 6)
  rrectfill(ox + 2, oy + 12 + 1, 80 - 4, 12 - 2, bg_col)
  -- score number
  local score_x, score_y = ox + 31, oy + 14
  rrectfill(score_x, score_y, 46, 8, 13)
  print("88888888888", score_x + 2, score_y + 2, 4)
  -- memory region
  local mem_region = 9 + (_num - 4) * 3
  -- high score
  local highscore = tostr(dget(mem_region), 0x2) .. "0"
  print(highscore, score_x + 46 - (#highscore * 4), score_y + 2, 7)
  -- area indicator
  local area_x, area_y = ox + 14, oy + 14
  rrectfill(area_x, area_y, 14, 8, 13)
  print("888", area_x + 2, area_y + 2, 4)
  print(mem_2_string(dget(mem_region + 1)), area_x + 2, area_y + 2, 7)
  --number
  local num_x, num_y = ox - 12, oy + 16
  sspr(6, 62, 10, 7, num_x, num_y)
  sspr(0, 62 + (_num - 4) * 7, 5, 7, num_x - 6, num_y)
  local combo = dget(mem_region + 2)
  local ship_index = tonum(sub(combo, 1, 1))
  if ship_index == 1 then
    palt(9, true)
    palt(11, false)
  end
  local sx, sy = unpack(split(ship_index == 1 and "0,110" or ship_index == 2 and "0,119"))
  sspr(sx, sy, 8, 9, ox + 4, oy + 14)
  if ship_index == 1 then
    palt(9, false)
    palt(11, true)
  end
-- print(dget(mem_region+1) .. " " .. ship_index,area_x+40,area_y-7,10)
end

function drw_hs_big(_x, _y, _num, _height)
  local bg_col = 12
  local border_col, shadow_col = unpack(split(_num == 1 and "3,2" or _num == 2 and "1,11" or "9,8"))
  local ox, oy = _x, _y
  rndrect(ox + 4, oy + 11, 89 - 4, 13 + _height, 3, shadow_col)
  rndrect(ox + 4, oy + 11, 89 - 4, 14, 3, border_col)
  rndrect(ox + 37, oy, 52, 23, 3, border_col)
  rrectfill(ox + 6, oy + 12 + 1, 89 - 4 - 6, 12 - 2, bg_col)
  rrectfill(ox + 38 + 1, oy + 2, 52 - 4, 23 - 2, bg_col)
  pal(7, border_col)
  sspr(72, 0, 4, 4, ox + 35, oy + 9)
  pal(7, 7)
  -- score number
  local score_x, score_y = ox + 40, oy + 3
  rrectfill(score_x, score_y, 46, 8, 13)
  print("88888888888", score_x + 2, score_y + 2, 4)
  local mem_location = (_num - 1) * 3
  local highscore = tostr(dget(mem_location), 0x2) .. "0"
  print(highscore, score_x + 46 - (#highscore * 4), score_y + 2, 7)
  -- area indicator
  local area_x, area_y = ox + 18, oy + 14
  rrectfill(area_x, area_y, 23, 8, 13)
  print("AREA", area_x + 2, area_y + 2, 7)
  print("8", area_x + 19, area_y + 2, 4)
  print("1", area_x + 19, area_y + 2, 7)
  -- max hit
  local area_x, area_y = ox + 44, oy + 14
  local combo = dget(mem_location + 2)
  local ship_index = tonum(sub(combo, 1, 1))
  local max_combo = tostr(tonum(sub(combo, 2, 4)))
  rrectfill(area_x, area_y, 42, 8, 13)
  print("MAX \x2deHIT", area_x + 2, area_y + 2, 7)
  print("888", area_x + 30, area_y + 2, 4)
  print(max_combo, area_x + 42 - tostr(#max_combo * 4), area_y + 2, 7)
  -- number and name
  local sx, sy, sw, sh = unpack(split(_num == 1 and "16,46,19,11" or _num == 2 and "16,57,21,10" or "16,67,21,10"))
  if _num == 2 then
    palt(11, false)
    palt(9, true)
  end
  local _x, number_y = ox - 11, oy - 1
  if _num == 1 then
    _x = _x + (2)
    number_y = number_y - (1)
  end
  sspr(sx, sy, sw, sh, _x, number_y)
  if _num == 2 then
    palt(11, true)
    palt(9, false)
  end
  -- sspr(35,46,23,11,ox+12,oy-1)
  print("\014" .. mem_2_string(dget(mem_location + 1)), ox + 12, oy + 1, 5)
  print("\014" .. mem_2_string(dget(mem_location + 1)), ox + 12, oy, 7)
  -- little ship icon
  if ship_index == 1 then
    palt(9, true)
    palt(11, false)
  end
  local sx, sy = unpack(split(ship_index == 1 and "0,110" or ship_index == 2 and "0,119"))
  sspr(sx, sy, 8, 9, ox + 8, oy + 14)
  if ship_index == 1 then
    palt(9, false)
    palt(11, true)
  end
end

function rndrect(_x, _y, _w, _h, _rad, _c)
  _x = _x + (_rad)
  _y = _y + (_rad)
  _w = _w - (_rad * 2)
  _h = _h - (_rad * 2)
  rectfill(_x, _y - _rad, _x + _w, _y + _h + _rad, _c)
  rectfill(_x - _rad, _y, _x + _w + _rad, _y + _h, _c)
  circfill(_x, _y, _rad, _c)
  circfill(_x + _w, _y, _rad, _c)
  circfill(_x, _y + _h, _rad, _c)
  circfill(_x + _w, _y + _h, _rad, _c)
end

-->8
-- basic menu
function menu_goto(_target)
  if swapped_this_frame then
    return
  end
  frame_progress = 0
  pal(split "-3,9,10,5,13,6,7,136,8,3,139,138,130,133,0,2", 1)
  -- poke(0x5f2e,1) -- keeps the colours on quit
  menu_mode = _target
  if _target == "basic" then
    init_bbasic()
    _upd, _drw = update_bbasic, draw_bbasic
  end
  if _target == "shipsel" then
    init_shipsel()
    _upd, _drw = update_shipsel, draw_shipsel
  end
  if _target == "ramcheck" then
    init_ramcheck()
    _upd, _drw = update_ramcheck, draw_ramcheck
  end
  if _target == "highscores" then
    init_highscores()
    _upd, _drw = update_highscores, draw_highscores
  end
  if _target == "submit" then
    init_submit()
    _upd, _drw = update_submit, draw_submit
  end
  swapped_this_frame = true
end

function init_bbasic()
  new_lerp(logo_obj, 28, 16, .03)
  new_lerp(sides_obj, -4, 0, .03)
  fade_perc, fade_rate = 1, -0.05
end

function update_bbasic()
  if btnp(5) then
    menu_goto("shipsel")
    sfx(61)
  end
  time_since_input = min(time_since_input + 1, 1000)
  is_idle = time_since_input > 600
  if frame_progress > 600 then
    menu_goto("highscores")
  end
  if btnp(4) then
    menu_goto("highscores")
    sfx(61)
  end
end

function draw_bbasic()
  do_fade(fade_perc)
  local width = 22
  rectfill(63 - width, 0, 64 + width - 1, 128, 8)
  drw_logo(logo_obj.x, logo_obj.y)
  drw_start_button(36, 78)
  local flash_length = 60
  if t % flash_length < (flash_length * .6666) then
    print_thick(hcentre(t % (flash_length * 4) < (flash_length * 2) and "please insert coin" or "press any button", 56, 7))
  end
  local text_y = 105
  print(hcentre("@0Xffb3/LOUIE 2023", text_y, 6))
  print(hcentre("SALE BY LOUIE", text_y + 6, 6))
  print(version_id, 14, 121, 0)
  map(0, 0, 0 + flr(sides_obj.x), 0, 2, 16)
  map(0, 0, 128 - 16 - flr(sides_obj.x), 0, 2, 16)
  print_thick(hcentre("HIGH " .. highest_score, 2, 6))
end

-->8
-- ship select
function init_shipsel()
  new_lerp(sides_obj, -16, 0, .04)
  fade_perc, fade_rate = 1, -0.05
  shipsel_frame_x, shipsel_frame_y = 7, 15
  ship_sel_ready = false
  shipsel_selection = 2
  shipsel_cursor = {}
  new_lerpobj(shipsel_cursor, shipsel_frame_x + 19, 19)
  type_a = {}
  new_lerpobj(type_a, shipsel_frame_x + 20, -10)
  type_b = {}
  new_lerpobj(type_b, shipsel_frame_x + 20, shipsel_frame_x + 55)
  type_c = {}
  new_lerpobj(type_c, shipsel_frame_x + 20, -10)
  ships = {type_a, type_b, type_c}
  text_draw = 0
  out_progress = -1
end

function update_shipsel()
  if out_progress >= 0 then
    out_progress = out_progress + (1)
  end
  if out_progress == 35 then
    sfx(60)
  end
  if out_progress and out_progress == 60 then
    fade_backwards, fade_perc, fade_rate = true, 0, .1
  end
  if out_progress and out_progress > 80 then
    start_game()
  end
  text_draw = text_draw + (1)
  if frame_progress > 1800 or out_progress >= 0 then
  elseif frame_progress > 1500 then
    if frame_progress % 15 == 0 then
      sfx(63)
    end
  elseif frame_progress > 1200 then
    if frame_progress % 30 == 0 then
      sfx(63)
    end
  else
    if frame_progress % 60 == 0 then
      sfx(63)
    end
  end
  if btnp(5) and shipsel_selection <= 2 and out_progress < 0 or frame_progress == 1800 then
    ship_sel_ready = true
    local ship = ships[shipsel_selection]
    new_lerp(ship, ship.x, -10, .02, "EaseInOvershoot")
    out_progress = 0
  end
  if btnp(4) then
    menu_goto("basic")
    sfx(62)
  end
  local new_pos = shipsel_selection
  if btnp(0) and out_progress < 0 then
    new_pos = new_pos - (1)
  end
  if btnp(1) and out_progress < 0 then
    new_pos = new_pos + (1)
  end
  if frame_progress > 1680 then
    new_pos = mid(1, new_pos, 2)
  end
  if mid(1, new_pos, 3) ~= shipsel_selection then
    local ship = ships[shipsel_selection]
    new_lerp(ship, ship.x, -10, .05)
    text_draw = 0
    shipsel_selection = new_pos
    ship_sel_ready = false
    local x_values = split "0,19,37"
    local height_values = split "21,19,22"
    new_lerp(shipsel_cursor, shipsel_frame_x + x_values[shipsel_selection], height_values[shipsel_selection], .1)
    local ship = ships[shipsel_selection]
    ship.y = 120
    new_lerp(ship, ship.x, shipsel_frame_x + 55, .05)
  end
end

function draw_shipsel()
  do_fade(fade_perc)
  local frame_x, frame_y = shipsel_frame_x, shipsel_frame_y
  drw_mapbackground(frame_x + 1)
  palt(11, false)
  palt(9, true)
  local sx, sy = type_a.x, type_a.y + sin(t * .005) * 3
  sspr(5, 77, 14, 19, sx + 1, sy - 2)
  palt(11, true)
  palt(9, false)
  -- rotors
  local rt = t // 4
  if rt % 3 == 2 then
    sspr(72, 72, 18, 16, sx - 1, sy - 3)
  end
  if rt % 3 == 1 then
    sspr(91, 72, 18, 16, sx - 1, sy - 3)
  end
  local sx, sy = type_b.x, type_b.y + sin(t * .005) * 3
  sspr(0, 46, 16, 16, sx, sy)
  local sx, sy = type_c.x, type_c.y + sin(t * .005) * 3
  sspr(47, 108, 14, 20, sx + 1, sy - 2)
  local bg_col = 8
  rectfill(0, 0, 128, frame_y, bg_col)
  rectfill(0, 0, frame_x, 128, bg_col)
  rectfill(frame_x + 8 * 7 - 1, 0, 128, 128, bg_col)
  rectfill(0, frame_y + 8 * 10 - 1, 128, 128, bg_col)
  map(4, 0, frame_x, frame_y, 7, 11)
  local text = "HIGH " .. highest_score
  print_thick(text, 127 - #text * 4, 2, 6)
  -- ship selection boxes
  local ox, oy = frame_x + 20, frame_y + 87
  local width = 19
  sspr(17, 108, 14, 20, ox - width + 1, oy)
  sspr(31, 108, 16, 18, ox, oy)
  sspr(47, 108, 14, 20, ox + width, oy)
  -- shipsel cursor thing
  oy = oy - (1)
  ox = ox - (1)
  local sox = sin(t * .01) * 1.1
  local width, height = 16, shipsel_cursor.y
  if ship_sel_ready == false then
    local cursor_ox, cursor_oy = shipsel_cursor.x, shipsel_frame_y + 85
    sspr(61, 120, 3, 4, cursor_ox + sox, cursor_oy + sox)
    sspr(64, 120, 3, 4, cursor_ox + width - sox, cursor_oy + sox)
    sspr(61, 124, 3, 4, cursor_ox + sox, cursor_oy + height - sox)
    sspr(64, 124, 3, 4, cursor_ox + width - sox, cursor_oy + height - sox)
  end
  -- counter
  local number = max(0, 30 - frame_progress // 60)
  show_nums = true
  if number <= 5 then
    if frame_progress % 30 > 15 then
      show_nums = false
    end
  elseif number <= 10 then
    if frame_progress % 60 > 30 then
      show_nums = false
    end
  end
  if show_nums then
    local text, x, y, c = hcentre("\014" .. sub("000" .. tostr(number), -2), 3, 7)
    x = x - (30)
    print(text, x, y + 1, t % 8 < 3 and 1 or 5)
    print(text, x, y, c)
  end
  -- ship data stuff
  local tx = shipsel_frame_x + 59
  local ty = 20
  local type, country, speed, options, secondary, cost = unpack(split(shipsel_selection == 1 and "type a,pERU,fAST,3,bURST,63.9B" or shipsel_selection == 2 and "type b,uNITED kINGDOM,mEDIUM,2,lASER,48.2B" or "type c,jAPAN,???,?,???,???"))
  print_text_slow(type, tx, ty, 7)
  -- drawn
  print("COUNTRY ORIGIN:", tx, ty + 10, 6)
  print_text_slow(country, tx + 5, ty + 16, 7, 3)
  -- drawn
  print("SPEED:", tx, ty + 26, 6)
  print_text_slow(speed, tx + 24, ty + 26, 7, 8)
  -- drawn
  print("OPTIONS:", tx, ty + 36, 6)
  print_text_slow(options, tx + 32, ty + 36, 7, 10)
  -- drawn
  print("SECONDARY FIRE:", tx, ty + 46, 6)
  print_text_slow(secondary, tx + 5, ty + 53, 7, 11)
  -- drawn
  print("COST:", tx, ty + 62, 6)
  print_text_slow(cost, tx + 5, ty + 68, 7, 14)
  -- drawn
  map(0, 0, 0 + sides_obj.x, 0, 2, 16)
  map(0, 0, 128 - 16 - sides_obj.x, 0, 2, 16)
end

function print_text_slow(_text, _x, _y, _c, _delay, _speed)
  local delay, speed = _delay or 0, _speed or 3
  local _text = sub(_text, 1, max(0, (text_draw // speed) - delay * speed))
  print(_text, _x, _y, _c)
-- drawn
end

function drw_mapbackground(_x)
  local celx, cely, sx, celw, celh, ry = 2, 0, _x, 2, 2, .5
  for y = -8 * celh, 128, celh * 8 do
    map(celx, cely, sx, y + (t * ry) % (celh * 8), celw, celh)
  end
  sx = sx + (38)
  for y = -8 * celh, 128, celh * 8 do
    map(celx, cely, sx, y + (t * ry) % (celh * 8), celw, celh)
  end
  celx, cely, sx, celw, celh, ry = 11, 0, sx - 35, 6, 8, .75
  for y = -8 * celh, 128, celh * 8 do
    map(celx, cely, sx, y + (t * ry) % (celh * 8), celw, celh)
  end
end

-->8
-- swag intro
function init_ramcheck()
  pal(split "0,7", 1)
end

function update_ramcheck()
  if frame_progress == 500 then
    menu_goto("highscores")
  end
end

function draw_ramcheck()
  cls(1)
  if frame_progress < 300 and rnd "10" > .2 then
    local width = 13
    for x = -1, min(t * 4, 128), width do
      for y = -1, 128, width do
        if t * 5 > x + y * 2 or rnd "10" < 2 then
          rect(x, y, x + width, y + width, 7)
        end
      end
    end
    rectfill(13, 26, 115, 63, 1)
    local text, x, y, col = hcentre(frame_progress < 150 and "checking memory....." or "checking ram....", 30, 7)
    print(text, x, y, col)
    print("code area " .. rnd(split "000b4000,000e4000,000f8000,000ffaa2,002ffa3a,fe0af000"), x, y + 10, col)
  -- print(intro_progress,1,1)
  end
  local hex = split "0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f"
  if frame_progress > 325 and frame_progress < 450 then
    local amount = frame_progress - 325
    for y = -3, min(amount * 2, 100), 6 do
      print("port:" .. tostr(y // 6) .. hex[1 + (y * 9) % 16] .. hex[1 + (y * 23) % 16], 4, y)
      if amount * 2 > y * 2 + 30 then
        print("success!", 50, y)
      end
    end
  end
--[[
	if(intro_progress>455 and intro_progress<460)rectfill(0,0,128,128,9)
	if(intro_progress>462 and intro_progress<480)rectfill(0,0,128,128,11)
	if(intro_progress>490 and intro_progress<510)rectfill(0,0,128,128,3)
	if(intro_progress==520)rectfill(0,0,128,128,9)
	]]
--
end

-->8
-- lerp stuff
function new_lerpobj(_table, _origin_x, _origin_y)
  _table.lerpt = 1
  _table.lerprate = .02
  _table.lerptype = "EaseInOutQuad"
  _table.lerpx1, _table.lerpy1 = _origin_x, _origin_y + 50
  _table.lerpx2, _table.lerpy2 = _origin_x, _origin_y
  add(lerp_objects, _table)
  upd_lerpobj(_table)
end

function upd_lerpobj(_table)
  _table.lerpt = mid(0, _table.lerpt + _table.lerprate, 1)
  local new_t = _table.lerpt
  if _table.lerptype == "EaseOutQuad" then
    new_t = easeoutquad(new_t)
  end
  if _table.lerptype == "EaseInOutQuad" then
    new_t = easeinoutquad(new_t)
  end
  if _table.lerptype == "EaseInOvershoot" then
    new_t = easeinovershoot(new_t)
  end
  _table.x = lerp(_table.lerpx1, _table.lerpx2, new_t)
  _table.y = lerp(_table.lerpy1, _table.lerpy2, new_t)
end

function new_lerp(_table, _tx, _ty, _speed, _type)
  _table.lerpt = 0
  _table.lerprate = _speed or 0.01
  _table.lerptype = _type or "EaseInOutQuad"
  _table.lerpx1, _table.lerpy1 = _table.x, _table.y
  _table.lerpx2, _table.lerpy2 = _tx, _ty
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function easeoutquad(t)
  t = t - (1)
  return 1 - t * t
end

function easeinoutquad(t)
  if t < .5 then
    return t * t * 2
  end
  t = t - (1)
  return 1 - t * t * 2
end

function easeinovershoot(t)
  return 2.7 * t * t * t - 1.7 * t * t
end

-- lerps to position , and then lerps back again - for explosion reaction
function easeoutovershoot(t)
  return 6.6 * t * (1 - t) ^ 2
end

-->8
-- grahipcs
function print_thick(_text, _x, _y, _c)
  print(_text, _x, _y + 1, t % 8 < 4 and 0 or 1)
  print(_text, _x, _y, _c or 7)
end

function hcentre(_text, _y, _c)
  return _text, 64 - (#_text * 2), _y, _c
end

function drw_logo(_x, _y)
  sspr(0, 10, 73, 29, _x, _y + sin(t * .01) * 1.5)
end

function drw_start_button(_x, _y)
  local sx, sy, sw, sh = unpack(button_drwdat[1 + (t // 60) % 2])
  local dx, dy = _x, _y
  sspr(sx, sy, sw, sh, dx, dy)
  sspr(24, 0, 36, 8, dx + 16, dy + 1)
  if (t // 60) % 2 == 0 then
    sspr(60, 0, 6, 8, dx + 3, dy - 9)
  end
end

function drw_demonstration(_x, _y)
  local x, y = _x, _y
  local shape_list = split "0,7,8,6,15,8,24,7,32,7,40,7,48,6,55,6,62,7,70,6,77,6,84,7,92,7"
  local colours = split "7,9,9,9,8,8,0"
  local width = 0
  for i = 1, #shape_list / 2 do
    pal(7, colours[1 + (i - t // 6) % #colours])
    local index = i * 2 - 1
    sspr(0 + shape_list[index], 39, shape_list[index + 1], 7, x + width, y)
    --+sin(t*.02+i*.1)*1.5)
    width = width + (shape_list[index + 1] + 1)
  end
  pal(7, 7)
  line(x + 2, y - 3, x + width - 4, y - 3, 6)
  line(x + 2, y + 9, x + width - 4, y + 9, 6)
end

-->8
function rrectfill(_x, _y, _w, _h, _c)
  rectfill(_x + 1, _y, _x + _w - 1, _y + _h, _c)
  rectfill(_x, _y + 1, _x + _w, _y + _h - 1, _c)
end

function do_fade(_amount)
  fade_perc = mid(0, fade_perc + fade_rate, 1)
  if fade_perc == 0 then
    if menu_mode == "highscores" then
      pal(split "138,9,10,5,13,6,7,136,8,3,139,134,133,4,0,2", 1)
    else
      pal(split "-3,9,10,5,13,6,7,136,8,3,139,138,130,133,0,2", 1)
    end
    return
  end
  local fade_table = {{2, 130, 128, 128, 0}, {141, 133, 130, 128, 128}, {9, 137, 4, 132, 128}, {138, 9, 137, 4, 128}, {5, 133, 130, 128, 128}, {13, 141, 133, 130, 128}, {143, 134, 5, 133, 128}, {6, 143, 134, 5, 130}, {136, 136, 128, 128, 0}, {8, 8, 128, 0, 0}, {3, 131, 133, 129, 128}, {3, 3, 5, 133, 128}, {142, 5, 133, 132, 128}, {130, 128, 128, 128, 0}, {130, 130, 128, 128, 0}, {0, 0, 0, 0, 0}}
  if menu_mode == "highscores" then
    fade_table = {{2, 130, 130, 128, 128}, {138, 138, 132, 128, 128}, {9, 9, 128, 128, 0}, {10, 138, 132, 128, 128}, {133, 133, 130, 128, 128}, {134, 141, 5, 130, 128}, {13, 134, 141, 133, 128}, {6, 13, 134, 5, 129}, {136, 132, 132, 128, 128}, {136, 132, 132, 128, 128}, {3, 129, 129, 128, 128}, {139, 139, 129, 128, 0}, {141, 5, 133, 130, 128}, {130, 130, 128, 128, 0}, {132, 132, 128, 128, 128}, {0, 0, 0, 0, 0}}
  end
  if fade_backwards then
    fade_table = {{2, 2, 133, 130, 130}, {141, 2, 2, 133, 133}, {9, 137, 4, 132, 132}, {10, 138, 4, 4, 133}, {5, 5, 133, 133, 133}, {13, 141, 141, 141, 133}, {6, 13, 134, 141, 5}, {6, 15, 13, 141, 5}, {136, 136, 2, 130, 130}, {8, 136, 136, 130, 130}, {3, 131, 131, 133, 133}, {139, 3, 3, 133, 133}, {134, 141, 5, 5, 133}, {130, 130, 130, 130, 130}, {133, 133, 130, 130, 130}, {0, 128, 128, 128, 130}}
  end
  local step = mid(0, _amount * #fade_table[1], #fade_table[1]) // 1
  for c = 0, 15 do
    if flr(step + 1) >= #fade_table[1] then
      pal(c, fade_backwards and 130 or 0, 1)
    else
      pal(c, fade_table[c + 1][flr(step + 1)], 1)
    end
  end
end

function parse_data(_data, _delimeter)
  local out, delimeter = {}, _delimeter or "|"
  for step in all(split(_data, delimeter)) do
    add(out, split(step))
  end
  return out
end

function btnp_any()
  for i = 0, 5 do
    if btnp(i) then
      return true
    end
  end
  return false
end

function start_game()
  if shipsel_selection == 1 then
    load("#kalikan_stage_1a")
  elseif shipsel_selection == 2 then
    load("#kalikan_stage_1b")
  end
end


__gfx__
bbbbbbbbbbbbbbb799999bbbb77777bb777777bb77777bb77777bb777777bb77bbffffffbb77ffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
bbb799999bbbbb79999999bb7755577b777777b7777777b777777b777777bb77bbffffffb777ffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
b8799999998bb8999999998b777bb55b557755b7755577b775577b557755bb77bbffffff7777ffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
809999999908809999999908577777bbbb77bbb77bbb77b77bb77bbb77bbbb77bbffffff777cffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
909999999909908999999809b555777bbb77bbb7777777b77777bbbb77bb777777ffffffffffffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
90899999980990888888880977bb577bbb77bbb7777777b777777bbb77bb777777ffffffffffffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
9908888880999908888880995777775bbb77bbb77bbb77b77b777bbb77bbb7777bffffffffffffffffffffffffffffffbbbbbbdeedbbbbbbeee4e4e44e4e4eee
099779996990099779999990b55555bbbb55bbb55bbb55b55b555bbb55bbbb77bbffffffffffffffffffffffffffffffbbbbbbdeedbbbbbbeeeeeee44eeeeeee
b0999999990bb0999999990bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
bb00000000bbbb00000000bbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe44ee44eeeeeeeee
bbbbbbbbbbbbbbbbbbbbbbbbbbb111bb111bb111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffe4ee444eeeeeeeee
b11111bbbbbbbbbbbbbbbbbbbb111111111111111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffeee444eeeeeeeeee
1111111bbbbbbb11111111bbb11171111711117111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffee444eeeeeeeeeee
1177711bbbbbb1111111111b1117711177711177111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffe444ee4eeeeeeeee
1177711bbb1111177777711111777117777711777111bbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffe44ee44eeeeeeeee
1177711bb1111177777777111777711977791177771111bbbb11111111bbbbbbbbbbbbbbbfffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeee
1177711bb11711779997777117777118979811777711111bb1111111111b1111111111bbbfffffffffffffffffffffffffffffffffffffffe44d45dddd54d44e
1177711bb11771998889777717779110898011977777711111177777711111111111111bbfffffffffffffffffffffffffffffffffffffffe44d445dd544d44e
117771111117778800087777177787777777118777777711117777777711177117777111bfffffffffffffffffffffffffffffffffffffffe44de445544ed44e
1177771111777700777777771777077777777107779777711177999777711771777777111fffffffffffffffffffffffffffffffffffffffe44dde4444edd44e
1177777117777907777777771777077777777707778977771199888977771777777777711fffffffffffffffffffffffffffffffffffffffe44ddd4e44ddd44e
1177777777779877779977771777177777777717770897777188000877771777777777711fffffffffffffffffffffffffffffffffffffffe44dd544445dd44e
1177777777798777798877771777177777777717770087777100777777771777799777711fffffffffffffffffffffffffffffffffffffffe44d544ee445d44e
1177777777780777780077771777177777777717777007777107777777771777788977711fffffffffffffffffffffffffffffffffffffffe44d44edde44d44e
1177777777700777700077771777177777777717777707779177799777771777700877711fffffffffffffffffffffffffffffffffffffff77bbbbbb77777777
1177777777770977700777771777177777777717777777798777788977771777700077711fffffffffffffffffffffffffffffffffffffff77bbbbbb77777777
1177797777777897777777771777177777777717777777780777700877771777711077711fffffffffffffffffffffffffffffffffffffff77bbbbbb55555555
1177789777777789777779971777177777777717777777700777700077771777711177711fffffffffffffffffffffffffffffffffffffff77bbbbbb55555555
1177708977777708999998891777177777777717779777770977770077771777711177711fffffffffffffffffffffffffffffffffffffff77bbbbbbbbbbbbbb
1177700897777700888880081777177777777717778977777897777777771777711177711fffffffffffffffffffffffffffffffffffffff77bbbbbbbbbbbbbb
1177710089777710000000001777197777777717770897777089777779971777711177711fffffffffffffffffffffffffffffffffffffff77bbbbbbbbbbbbbb
1177711008977711000001101777189777777717770087777008999998891777711177711fffffffffffffffffffffffffffffffffffffff77bbbbbbbbbbbbbb
1177711100897711111111111777108999999917771007777100888880081999911199911fffffffffffffffffffffffe454ede44ede454ebbbbbbbbbbbbbb77
1199911110089911111111111999100888888819991109999110000000001888811188811fffffffffffffffffffffffe454ede44ede454ebbbbbbbbbbbbbb77
1188811111008811bbbbbbb11888110000000018881118888111000001101000011100011fffffffffffffffffffffffee4eede44edee4eebbbbbbbbbbbbbb77
1100011b11100011bbbbbbb11000111000000010001110000111111111111000011100011fffffffffffffffffffffffe454eddee4de454ebbbbbbbbbbbbbb77
1100011bb1110011bbbbbbb11000111111111110001110000111111111111111111111111fffffffffffffffffffffffe454ede44ede454ebbbbbbbbbbbbbb77
1111111bbb111111bbbbbbb1111111111111111111111111111bbbbbbbbb111111111111bfffffffffffffffffffffffe454ede44ede454e77777777bbbbbb77
b11111bbbbb1111bbbbbbbbb11111bbbbbbbbb111111111111bbbbbbbbbbbbbbbbbbbbbbbfffffffffffffffffffffffe454ede44ede454e77777777bbbbbb77
777777bb777777bb77bb77bbb77777bb77bbb77bb77777bb777777b77777bbb77777bb777777b777ffffffffffffffffe454ede44ede454e55555555bbbbbb77
777bb77b777777b77777777b777bb77b777bb77b77bbb77b777777b777777b7777777b777777b777ffffffffffffffffe454ede44ede454ebb777777777777bb
77bbb77b77bbbbb77777777b77bbb77b7777b77b777bbbbbbb77bbb77bb77b77bbb77bbb77bbbbb7ffffffffffffffffe444edeeeede444eb77777777777777b
77bbb77b77777bb77b77b77b77bbb77b7777777bb77777bbbb77bbb77bb77b77bbb77bbb77bbbbb7ffffffffffffffffe46555eeee55564e7777555555557777
77bbb77b77bbbbb77bbbb77b77bbb77b77b7777bbbbb777bbb77bbb77777bb7777777bbb77bbbbb7ffffffffffffffffe56555444455565e7775555555555777
77bb777b777777b77bbbb77b77bb777b77bb777b77bbb77bbb77bbb777777b7777777bbb77bbb777ffffffffffffffff55eeee4dd4eeee557755bbbbbbbb5577
777777bb777777b77bbbb77bb77777bb77bbb77bb77777bbbb77bbb77b777b77bbb77bbb77bbb777ffffffffffffffff545444d44d444545775bbbbbbbbbb577
bbbbbbbddbbbbbbb333bbbbbbbbbbbbbbbbb77777bbb77777bb777777bffffffffffffffffffffffffffffffffffffff4e5ee4d44d4ee5e477bbbbbbbbbbbb77
bbbbbbd33dbbbbbb2333bbbbbbbbbbbbbbb7777777b7777777b7777777ffffffffffffffffffffffffffffffffffffffee54eed44dee45ee77bbbbbbbbbbbb77
bbbbbb0220bbbbbbb333bbbbbbbbbbbbbbb7744477b7744477b7744477ffffffffffffffffffffffffffffffffffffffde4456666665e4ed77bbbbbbbbbbbb77
bbbbbd3223dbbbbbb333bbbbbbbbbb333bb77bbb77b77bbb44b77bbb77ffffffffffffffffffffffffffffffffffffffde45566ee66544ed77bbbbbbbbbbbb77
bbbbb020020bbbbbb333bbb33333bb333bb77bbb77b777777bb77bbb77ffffffffffffffffffffffffffffffffffffffde456665566544ed77bbbbbbbbbbbb77
bbbbd320023dbbbbb333bb333222bb3333377bbb77b4777777b77bbb77ffffffffffffffffffffffffffffffffffffffde455665566544ed777bbbbbbbbbb777
bbbb02077020bbbbb333bb233333bb3332277bbb77bb444477b77bbb77ffffffffffffffffffffffffffffffffffffffde4e5665566544ed7777bbbbbbbb7777
bbbd52077025dbbbb333bbb222333b333bb77bbb77b77bbb77b77bbb77ffffffffffffffffffffffffffffffffffffffde445665566554ed5777777777777775
bbb0602dd2060bbb33333b3333332b233337777777b7777777b7777777ffffffffffffffffffffffffffffffffffffffde445665566654ed0577777777777750
bbd3dd2002dd3dbb22222b2222222b222224777774b4777774b7777774ffffffffffffffffffffffffffffffffffffffde445666666554ed0055555555555500
bd027740047720db22222b222222bbb2222b44444bbb44444bb444444bffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
d03266444466230d9111199999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00bbb000000000bb
d320d63dd36d023d1111119999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bbbbbbbb00000bb
dd00d022220d00dd11b1119999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bbbbbbbbbb00bbb
bdd0d3d00d3d0ddbbb91119999999999999111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbb0bbbb
bbbdd44dd44ddbbb99111b9999999999999111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbb0bbbb
66b66b66bbb66bbb9111b99111111999111111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
66b66b66bbb66bbb111b999111b1119111b111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
66b66b6666b6666b1119999111911191119111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000bb000bbbb
66666b6655b66566111111911191119b111111ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb00bbbbbbbbbbbb
55566b66bbb66b66bbbbbb9bbb9bbb99bbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
bbb66b5666b66b66b9999bbbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
bbb55bb555b55b55999999bbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
66666fffffffffff998899bbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
66555fffffffffff88b999bbbbbbbbbbbbb999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
6666bfffffffffffbbb998bbbbbbbbbbbbb999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbb
55566fffffffffffbbb899bb99999bbb999999ffffffffffffffffffffffffffffffffffbbbbbb777777bbbbbbbbbbbbb777777bbbbbbfffffffffffffffffff
bbb66fffffffffff99bb99b9998999b9998999ffffffffffffffffffffffffffffffffffbbbb77bbbbbb77bbbbbbbbb777bbbbb77bbbbfffffffffffffffffff
66665fffffffffff999999b999b999b999b999ffffffffffffffffffffffffffffffffffbbb77bbbbbbbbb7bbbbbbb77777bbbbbb7bbbfffffffffffffffffff
5555bfffffffffff899998b999b888b8999999ffffffffffffffffffffffffffffffffffbb7777bbbbbbbbb7bbbbb7bb777bbbbbbb7bbfffffffffffffffffff
b6666fffffffffffb8888bb888bbbbbb888888ffffffffffffffffffffffffffffffffffb77777bbbbbbbbbb7bbb7bbbbb7bbbbbbbb7bfffffffffffffffffff
66555999999dd999999fffffffffffffffffffffffffffffffffffffffffffffffffffffb7bbb77bbbbbbbbb7bbb7bbbbb7bbbbbbbb7bfffffffffffffffffff
6666b99999dccd99999fffffffffffffffffffffffffffffffffffffffffffffffffffff7bbbbbb7bbbbbbbbb7b7bbbbbbb7bbbbbbbb7fffffffffffffffffff
66566999990bb099999fffffffffffffffffffffffffffffffffffffffffffffffffffff7bbbbbbbbbbbbbbbb7b7bbbbbbbbbbbbbbbb7fffffffffffffffffff
66b669999dcbbcd9999fffffffffffffffffffffffffffffffffffffffffffffffffffff7bbbbbbbbbbbbbbbb7b7bbbbbbbbbbbbbbbb7fffffffffffffffffff
5666599990baab09999fffffffffffffffffffffffffffffffffffffffffffffffffffff7bbbbbbbbb7bbbbbb7b7bbbbbbbb7bbbbbbb7fffffffffffffffffff
b555b99d0abaaba0d99fffffffffffffffffffffffffffffffffffffffffffffffffffffb7bbbbbbbbb77bbb7bbb7bbbbbbbb7bbbbb7bfffffffffffffffffff
666669d775b77b577d9fffffffffffffffffffffffffffffffffffffffffffffffffffffb7bbbbbbbbbb77777bbb7bbbbbbbb7bbbbb7bfffffffffffffffffff
5556690664b77b46609fffffffffffffffffffffffffffffffffffffffffffffffffffffbb7bbbbbbbbbb777bbbbb7bbbbbbb777bb7bbfffffffffffffffffff
b6666dc764bddb467cdfffffffffffffffffffffffffffffffffffffffffffffffffffffbbb7bbbbbbbbb77bbbbbbb7bbbbbb77777bbbfffffffffffffffffff
66655db765a55a567bdfffffffffffffffffffffffffffffffffffffffffffffffffffffbbbb77bbbbbb77bbbbbbbbb77bbbbb777bbbbfffffffffffffffffff
665bbda550aaaa055adfffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbb777777bbbbbbbbbbbbb777777bbbbbbfffffffffffffffffff
66bbb9044ddaadd4409fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
55bbb99dddd55dddd99fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b666b99999d77d99999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
6656699990d66d09999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66666999d0b66b0d999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66566999daa44aad999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
66b669990cddddc0999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
5666599990999909999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b555bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbddbbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffbbbbbbddbbbbbbbbbbbbbddbbbbbbbbbbbbd44dbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
999dd999fffffffffbbbbbd44dbbbbbbbbbbbd44dbbbbbbbbbbbe44ebbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
99d11d99fffffffffbbbbbe44ebbbbbbbbbbbe44ebbbbbbbbbbbe44ebbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
90abba09fffffffffbbbbd4444dbbbbbbbbbd4444dbbbbbbbbbbe44ebbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
9d5775d9fffffffffbbbbe4ee4ebbbbbbbbbe4ee4ebbbbbbbbbd4444dbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
d657756dfffffffffbbdde4ee4eddbbbbbbd44ee44dbbbbbddbe4ee4ebddbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
d7baab7dfffffffffbd4ed4774de4dbbbbbe4e77e4ebbbbde4dee77eed4edfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
9d0660d9fffffffffbe4ed4774de4ebbbbd44e77e44dbbbde4ed4774de4edfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
90a55a09fffffffffd444d4dd4d444dbbbe4e4dd4e4ebbbde44e4dd4e44edfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
99d00d99fffffffffde444e44e444edbbd4dd4ee4dd4dbbde44e4ee4e44edfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbbddbbb777bbbbbbde44dedded44edbde4444ee4444edbd444de44ed444dfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bbd33dbb7bbbbbbbbbdeeddeeddeedbde444444444444edbe44d4444d44ebb7777bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb0220bb77bb77bbbbbdddd44ddddbbd44ed44dd44de44dbde4e4dd4e4edb755557fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bd3ee3db7bb6b7bbbbbbbbd44dbbbbbddeede4444edeeddbde4edeede4edb7bbbb7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b027720b7776b767bbbbbdd44ddbbbbbbded4deed4dedbbbbd4dbddbd4dbb5bbbb5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
d3e77e3dbbb6b76b7bbbdd4444ddbbbbbbddeeddeeddbbbbbdedbbbbdedbb7bbbb7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
02700720bbb7b76b7bbbdee44eedbbbbbbbbbbbbbbbbbbbbbdedbbbbdedbb7bbbb7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
de6446edbbbbbb6b7bbbd4dddd4dbbbbbbbbbbbbbbbbbbbbbdedbbbbdedbb577775fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
b04dd40bbbbbbb777bbbbdbbbbdbbbbbbbbbbbbbbbbbbbbbbbdbbbbbbdbbbb5555bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__map__
1d1c2e2f5e3f3f3f3f3f5f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d2e2f3e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00003e00000000004f0c4d6c6d5c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00003e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1c00003e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00003e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00003e00000000004f0c5d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d00003e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1c00003e00000000004f0c4d6c6d4c0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00006e4e4e4e4e4e6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d00007e7f8e00008f7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a51018000404304014040350405504015040350962504015040350405504015040350404304014040350405504015040350262504015040350405504015060341000510005100051000512005100050000500000
9d1018000704307014070350705507015070350762507015070350705507015070350604306014060350605506015060350662506015060330605306015020341300510005100051000510005000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000d010160201d0302104024050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000472005731067410c75110761137610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000b6240b634100140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 08424344
00 08424344
02 09424344
__label__
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii8888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii888888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii88888888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii88888888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii88888888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii88888888iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii8888888777777777777778iiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii888888877777777777777778iiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii8888888777a777777777777778iiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii8888888777a77777777777777778iiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii888888877aa77777777777777778iiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiii5ddddddddddddddddiiiiiiiiidddddiiiiiiiiiidiiiiiiiiiiiiiiiiiddddddd888888877a777777777777777777iiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiidddddddddddddddddiiiiiiiiiddddiiiiiiiiiiiiiiii7iii7iii7iiiiidddddd888888877a77a77777a7777777777iiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiidddlllllllllllllliii777iiiliiiiiiiiiiiiiiiiii77ii777ii77iiiiilllll888888877777a7777a777aaa777777iiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiddllllllllllllllliii777iiiiiiiiii777777iiiii777i77777i777iiiiiilliiiiiiiiii777a7777777aaaaa777777iiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiddllllllllllllllliii777iiiiiiiii77777777iii7777i87778i7777iiiiiiiiiiiiiiiiiiiiiiiiiiiiaaaaaa77a77iiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiddllllllllllllllliii777iiiiii7ii778887777ii7777io878oi7777iiiiiiiiiiiiiiiiiiiiiiiiiiiii7aaaa77a77iiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiddllllllllllllllliii777iiiiii77i88ooo87777i7778i2o8o2i8777777iiiiii777777iiiiiiiiiiiiiiiaaaa77a77iiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiddllllllllllllllliii777iiiiii777oo222o7777i777o777772io7777777iiii77777777iii77ii777iiiiiaa777777iiiiiiiiiiiiiiiiiii
iiii5dddddddllllllllllllllllliii7777iiii77772277777777i7772777777i277787777iii778887777ii77i77777iiiii777777iiiiiiiiiiiiiiiiiiii
iiiiddddddddl55555llllllllllliii77777ii777782777777777i777277777772777o87777ii88ooo87777i777777777iiii77777iiiiiiiiiiiiiiiiiiiii
iiiidddllllll55555llllllllllliii77777777778o7777887777i777i7777777i7772o87777ioo222o7777i7777887777iii77774iiiiiiiiiiiiiiiiiiiii
iiiiddlllllll55lllllllllllllliii7777777778o77778oo7777i777i7777777i77772o7777i2277777777i7777oo8777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddlllllll55lllllllllllllliii777777777o27777o227777i777i7777777i7777727777i2777777777i777722o777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddlllllll55lllllllllllllliii7777777772277772227777i777i7777777i7777777778i7778877777i7777222777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllllllllllllllllllliii7777777777287772277777i777i7777777i777777778o7777oo87777i7777ii2777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllllllllllllllllllliii77787777777o8777777777i777i7777777i77777777o2777722o7777i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllllliiiil5ddddddddiii777o87777777o877777887i777i7777777i777777772277772227777i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddlllllllli8888idddddddddiii7772o87777772o88888oo8i777i7777777i777877777287777227777i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddlllllllio7777oiddlllllliii77722o87777722ooooo22oi777i7777777i777o877777o8777777777i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllli677776idllllllliii777i22o87777i222222222i777i8777777i7772o877772o877777887i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllli677776idllllllliii777ii22o8777ii22222ii2i777io877777i77722o777722o88888oo8i7777iii777iii77a94iiiiiiiiiiiiiiiiiiiii
iiiiddllllllli688886idllllllliii777iii22o877iiiiiiiiiii777i2o88888i777i227777i22ooooo22oi8888iii888iii77a94iiiiiiiiiiiiiiiiiiiii
idddddiiiiiiiio8888oiiiiiiiiliii888iiii22o88iiiiiiiiiii888i22oooooi888ii28888ii222222222iooooiiioooiii77a94ddddddddddddddddddddi
iddddi66oooooio2772oiooooo66iiiioooiiiii22ooiiiiiiiiiiioooii222222ioooiiiooooiii22222ii2i2222iii222iii77a94ddddddddddddddddddddi
illli66ooooo2i727727i2ooooo66iii222iiiiii222iiidddddiii222iii22222i222iii2222iiiiiiiiiiii2222iii222iii77a94lllllllllllllllllllli
illi7728882226727727622288827iii222iiiiiii22iiidddddiii222iiiiiiiii222iii2222iiiiiiiiiiiiiiiiiiiiiiiii77a94lllllllllll55555lllli
illi228882iii67277276iii28882iiiiiiiiiiiiiiiiiillllliiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii77a94lllllllllll55555lllli
illi88888i555672dd276555i8888iiiiiiiiidiiiiiiiillllliiiiiiiiiiiiiiiiiiiiiiiiiiiidddddddiiiiiiiiiiiiiid77a94llllllllllllll55lllli
illi22222577i6d2oo2d6i7752222diiiiiiidddiiiiiidllllldiiiiiiidddddiiiiiiiiiiiiiiddddddddddddddddddddddd77a94llllllllllllll55lllli
illi22888i776ldo77odl677i8882dddddddddlddddddddllllldddddddddddddddddddddddddddda9a999adddddddddddddd777a94llllllllllllll55lllli
illdi8ooo6776l62aa26l6776ooo8idddddddlllddddddllliiildddddddllllldddddddddddddd9999999999dddddd49a777777a94lllllllllllllllllllli
ilddioooo6776o752257o6776ooooilllllllllllllllllliiiiilllllllllllllllll9aaaaaaa9999999999add999949a777777a94lllllllllllllllllllli
illlli2226776od7557do6776222illllllllllllllllllliiiiilllllllllllllllll9a9aaa9a99a999a9999i99a9949a777777a94lllllllllllllllllllli
illlli2226dd62od55do26dd6222i55ll55llllllllllllliiiiillllllllllllllll59a9a9aaa99a9a999a999a999a49a777777a94lllllllllllllllllllli
illll5iiidoodi22ii22idoodiiil5ll555llllllllllllliiiiillllllllllllllll5la9aaaaa99a99999a9999999949a777777a94lllllllllllllllllllli
illlld6did22diiid6iiid22dilllll555llllllllllllllliiilllllllllllllllllll59aaaaaa9a9a9a9a9999999949a777777a94lllllllllllllllllllli
illlddllid22dillllddid22dillll555lllllllllllllllllllllllllllllllllllll5a9a9a9a9a99a9a9944999a9949a777777a94lllllllllllllllllllli
illld5d55i66ii555d5dli66illll555ll5llllllllllllllllllllllllllllllllll54aaa9a9a9aa999999a49a999a49a777777a944llllllllllllllllllli
illl5ldll5ii5i5lldl5llii5llll55ll55llllllllllllliiillllllllllllllllll54aaaaaaaaaaa4aaaaa499999949a777777a944llllllllllllllllllli
illllld5lli55ill5dllllllllllllllllllllllllllllliiiiillllllllllllllllll4aaaaaaaaaaa4aaa9a999999949a777777a944llllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllllllliiiiiiilllllllllllllllll4a9aaa9aaa9a4a9a9449a9a9a49a777777a944llllllllllllllllllli
illll5d5lil55lil5d5llll55llll55555lllllllllllliiiiiiillllllllllllllll5449a9aaa9a944a9a94a9a9a9a49a777777a944llllllllllllllllllli
illlll5llil55lill5lllll55llll55ll55llllllllllliiiiiiillllllllllllllll5544aaaaaaa449a944aaa99a9a49a777777a94lllllllllllllllllllli
illll5d5liill5il5d5llllllllll55555lll55ll55ll55ii67il55ll55ll55ll55ll55594aaaaa4333394aaaaa9a9949a777777a94lllllllllllllllllllli
illll5d5lil55lil5d5llllllllll55ll55ll55ll55ll55i6667i55ll55ll55ll55ll55ll4444443rqqr3a9a9aaa9a949a777777a94allllllllllllllllllli
illll5d5lil55lil5d5llll55llll55ll55lllllllllllli6d76illllllllllllllll55lla444443r77r3a9a9a9a9a949a777777a94lalllllllllllllllllli
illll5d5lil55lil5d5llll55llll555iillllllllllllli6d76illllllllllllllll55aa5llll3rq77qr39aaa3333949a777777a94llaalllllllllllllllli
illll5d5lil55lil5d5lllllllllllli67illllllllllllid666illlllllllllllllllalllllll3rq77qr34aa3rqqr349a777777a94llllallllllllllllllli
illll5d5lil55lil5d5llllllllllli6667illllllllllllid6illlllllllllllllllalllllllll3r77r344493r77r349a777777a94lllllalllllllllllllli
illll5d5lil55lil5d5llll55llll5i6d76illllllllllllliillllllllllllllllla55ll55llll3rqqr344a3rq77qr39a777777a94llllllallllllllllllli
illlll5llil55lill5lllll55llll5i6d76illlllllllllllllllllllllllllllllla5ll555llll53333aaaa3rq77qr39a777777a94llllllallllllllllllli
illll5d5liill5il5d5lllllllllliid666illlllllllllllllllllllllllllllllalll555lrrrlll4aaaaaaa3r77r349a777777a94lllllllalllllllllllli
illll5d5lil55lil5d5llllllllli66id6illllllllllllllllllllllllllllllllall555lrqqqrll49a9aaa93rqqr349a777777a94lllllllalllllllllllli
illll5d5lil55lil5d5llll55llli6d7ii5llllllllllllllllllllllllllllllllal555lrqa7aqr549aaa9aaa3333949a777777a94lllllllalllllllllllli
illll5d5lil55lil5d5llll55llli6d76i5llllllllllllllllllllllllllllllllal55llrq777aqr44aaaaaaaaa44949a777777a94lllllllalllllllllllli
illll5d5lil55lil5d5lllllllllid666illlllllllllllllllllllllllllllllllalllllrqa777qrl44aaaaaaa49a949a777777a94lllllllalllllllllllli
illll5d5lil55lil5d5lllllllli6id6illlllllllllllllllllllllllllllllllllalllllrqa7aqrll44rrr9a445li49a777777a94llllllallllllllllllli
illll5d5lil55lil5d5llll55li666iillllllllllllllllllllllllllllllllllllallllllrqqqr5lllrqqqr4455li49a777777a94llllllallllllllllllli
illlll5llil55lill5lllll55li6d76illllllldlllllllllllllllllllllllllllllallllllrrr55llrqa7aqrl55li49a777777a94lllllalllllllllllllli
illll5d5liill5il5d5llllllli6d76illlllllllllllllllllllllllllllllllllllrrrlllllllllllrq777aqrll5i49a777777a94llllalllll55ll55lllli
illll5d5lil55lil5d5lllllllid666illllllllllllllllllllllllllllllllllllrqqqrllllllllllrqa777qr55li49a777777a94llaallllll55ll55lllli
illll5d5lil55lil5d5llll55llid6illllllllllllllllllllllllllllllllllllrqa7aqrlllll55lllrqa7aqr55li49a777777a94lalllllllllllllllllli
illll5d5lil55lil5d5llll55llliillllllllllllllllllllllllllllllllllllrqa777qraalll55llllrqqqrl55l549a777777a94allllllllllllllllllli
illll5d5lil55lil5d5lllllllllllllllllllllllllllllllllllllllllllllllrq777aqrllaaallllll5rrril5555iia777777a945llllllllllllllllllli
illll5d5lil55lil5d5lllllllllllllllllllllllllllllllllllllllllllllllrqa7aqrllllllrrraal5d5lil55di77i777777a9455lllllllllllllllllli
illll555lillllil555llll55llllllllllllllllliilllllllllllllllllllllllrqqqrllllllrqqqrlaaaaaaaaaii66ii7777aaa45dlllllllllllllllllli
illll56dddllllddd65llll55lllllllllllllllli67illlllllllllllllllllllllrrrllllllrqa7aqrl56dddllli9aaai777777a4dllllllllllllllllllli
illlld6ddd5555ddd6dllllllllllllllllllllli6667illllllllrrrlllllllllllllllllllrqa777qrld6ddd555i4999i777777a4lllllllllllllllllllli
illlddllll5ii5llllddlllllllllllllllllllli6d76illlllllrqqqrllllllllllllllllllrq777aqrddllll5iii4999i77777774lllllllllllllllllllli
illld5d555i55i555d5dlll55llllllllllllllli6d76illllllrqa7aqrlllllllllrrrlllllrqa7aqrld5d555i55i4999i7777777llllllllllllllllllllli
illl5ldll5i55i5lldl5lll55lllllllllllllllid666illllllrq777aqrlllllllrqqqrlllllrqqqrll5ldll5i55i4999i7777777llllllllllllllllllllli
illllld5lli55ill5dlllllllllllllllllllllllid6ilrrrlllrqa777qrllllllrqa7aqrlllllrrrllllld5lli55i4444i7777777illlllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllliilrqqqrlllrqa7aqrllllllrq777aqrlllllllllll5d5lil55iiddii7777777iillllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllrqa7aqrlllrqqqrlllllllrqa777qrlllll55llll5d5lil55li55i77ii777aaillllllllllllllllllli
illlll5llil55lill5lllll55lllllllllllllllllllrq777aqrlllrrrlllllllllrqa7aqrlllrrr5lllll5llii75liii77iaai7999illllllllllllllllllli
illll5d5liill5il5d5lllllllllllllllllllllllllrqa777qrllllllllllllllllrqqqrlllrqqqrllll5d5i67il5il5d7i99i4999illllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllllllrqa7aqrlllllllllllllllllrrrlllrqa7aqrlll5di6667ilil5di999ai999illllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllllrqqqrlllllrrrllllllllllllllllrq777aqrll5di6d76ilil5d29449i999illllllllllllllllllli
illll5d5lil55lil5d5llll55llllllllllllllllllllllrrrlllllrqqqrlllllrrrlllllllrqa777qrll57i6d76ilil7i49229i444i6lllllllllllllllllli
illll5d5lil55lil5d5lllllllllllllllllllllllllllllllllllrqa7aqrlllrqqqrlllllllrqa7aqrll5did666il7l5a94774aidii6lllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllllllllrrrlllrqa777qrllrqa7aqrlllllllrqqqrlll5d5id6i5lili9i47749i5il6lllllllllllllllllli
illll5d5lil55lil5d5llll55lllllddddllllllllllllrqqqrllrq777aqrlrqa777qrddddllllrrrllll5d5lii55liia97iii94ii6l6lllllllllllllllllli
illlll5llil55lill5lllll55lllll5555lllllllllllrqa7aqrlrqa7aqrllrq777aqr5555lllll55lllll5llil75lia996722iiai666lllllllllllllllllli
illll5d5liill5il5d5lllllllllllllllllllllllllrqa777qrllrqqqrlllrqa7aqrllllllrrrlllllll5d5liill5ia946544579illllllllllllllllllllli
illll5d5lil55lil5d5lllllllllllllllllllllllllrq777aqrlllrrrlllllrqqqrllllllrqqqrllllll5d5lil55lii429555564ailllllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllrqa7aqrlllllllllrrrlrrrllllllrqa7aqr5llll5d5lil55liii24aiiai49illlllllllllllllllllli
illll5d5lil55lil5d5llll55llllllllllllllllllllrqqqrlllllllllrqqqrllllllllrqa777qr5llll5d5lil55liliia9994i24illlllllllllllllllllli
illll5d5lil55lil5d5lllllllllllllllllllllllllllrrrlllllllllrqa7aqrlllllllrq777aqrlllll5d5lil55lil5i5i42ai2iilllllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllllllllllllrrr4lllrq777aqrllllllrqa7aqrllllll5d5lil55lil5di5i55iilllllllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllllllllrqqqr4llrqa777qr3333lllrqqqrl55llll5d5lil55lil5d5llll55lllllddddllllllllllllli
illlll5llil55lill5lllll55llllllllllllllllllllllllrqa7aqr4llrqa7aqrrqqr3lllrrrll55lllll5llil55lill5lllll55lllll5555llllllllllllli
illll5d5liill5il5d5llllllllllllllllllllllllllllllrq777aqr4llrqqqr3r77r3llllllllllllll5d5liill5il575lllllllllllllllllllllllllllli
illll5d5lil55lil5d5llllllllllllllllllllllllllllllrqa777qr4lllrrr3r337qr3lllllllllllll5d5lil55lil5d5lllllllllllllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllllllllrqa7aqr4llllll33rr33r3llll33335llll5d5lil55lil5d5llll55lllllllllllllllllllllli
illll5d5lil55lil5d5ll2255llllllllllllllllllllllllllrqqqr4llllll3rrqqrr3llll3rqqr3lll22d5lil55lil5d5llll55lllllllllllllllllllllli
illll5d5lil55lil5d5224422lllllllllllllllllllllllllllrrr4l33llll3qaaaaq3llll3r77r3l224422lil55lil5d5lllllllllllllllllllllllllllli
illll5d5lil55lil5d24499442lllllllllllllllllllllllllllll33rr33ll3qaaaaq3lll3rq77qr34499442il55lil5d5lllllllllllllllllllllllllllli
illll5d5lil55lil5d29aaaa92llllllllllllllllllllllllllll3rrqqrr3l3rrqqrr3lll3rq77qr39aaaa92il55lil5d5llll55llll55555llllllllllllli
illlild5iil55lill529aaaa92llllllllllllllllllllllllllll3qaaaaq3ll33rr33lllll3r77r329aaaa92il55lill5lllll55llll55555llllllllllllli
illio777oiill5il5d24499442llllllllllllllllllllllllllll3qaaaaq3llll33lll33333rqqr324499442iill5il5d5llllllllll55lllllllllllllllli
illlo7o7o2l55lil5d5224422llllllllllllllllllllllllllll23rrqqrr3llllllll3rqqr33333ll224422lil55lil5d5llllllllll55lllllllllllllllli
illlo77oool55lil5d5ll2255llllllllllllllllllllllllll224433rr33lllllllll3r77r3lll55lll22d5lil55lil5d5llll55llll55lllllllllllllllli
illlo7o7ool55lil5d5llll55lllllllllllllllllllllllll244994433l333333lll3rq77qr3ll55llll5d5lil55lil5d5llll55lllllllllllllllllllllli
illio777oil55lil5d5lllllllllllllllllllllllllllllll29aaaa9233rr33qr3ll3rq77qr3llllllll5d5lil55lil5d5lllllllllllllllllllllllllllli
illlid77iil55lil5d5lllllllllllllllllllllllllllllll29aaaa93rrqqrr3r3lll3r77r3lllllllll5d5lil55lil5d5lllllllllllllllllllllllllllli
illll5d5lil55lil5d5llll55lllllllllllllllllllllllll24499443qaaaaq3qr3ll3rqqr3lll55llll5d5lil55lil5d5llll55lllllllllllllllllllllli
illlll5llil55lill5lllll55llllllllllllllllllllllllll2244223qaaaaq3qr3lll3333ll3355lllll5llil55lill5lllll55lllllllllllllllllllllli
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
