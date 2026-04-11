pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

-- 512px under
-- by pck404
-- version 1
-- utils
function vec2(x, y)
  return {x = x or 0, y = y or 0}
end

function sign(v)
  return v > 0 and 1 or v < 0 and -1 or 0
end

function round(v)
  return flr(v + 0.5)
end

function clamp(v, a, b)
  return min(max(min(a, b), v), max(a, b))
end

function move_towards(v, target, step)
  return v > target and max(target, v - step) or min(target, v + step)
end

-- timers
function dec_if_active(timer_name)
  if get_timer(timer_name) > 0 then
    timers[timer_name] = timers[timer_name] - (1)
    return true
  end
  return false
end

function is_timer_active(timer_name)
  return get_timer(timer_name) > 0
end

function get_timer(timer_name)
  return timers[timer_name] or 0
end

-- bounds
function new_bounds(x, y, w, h)
  return {x = x, y = y, w = w or 8, h = h or 8}
end

function copy_bounds(b)
  return new_bounds(b.x, b.y, b.w, b.h)
end

function translated(b, x, y)
  return new_bounds(b.x + x, b.y + y, b.w, b.h)
end

function bounds_center(b)
  return vec2(b.x + b.w / 2, b.y + b.h / 2)
end

function point_rect_col(p, b)
  return p.x >= b.x and p.x <= b.x + b.w and p.y >= b.y and p.y <= b.y + b.h
end

function rect_rect_col(b1, b2)
  return point_rect_col(vec2(b1.x, b1.y), b2) or point_rect_col(vec2(b1.x + b1.w, b1.y), b2) or point_rect_col(vec2(b1.x, b1.y + b1.h), b2) or point_rect_col(vec2(b1.x + b1.w, b1.y + b1.h), b2) or point_rect_col(vec2(b1.x + b1.w / 2, b1.y), b2) or point_rect_col(vec2(b1.x + b1.w / 2, b1.y + b1.h), b2) or point_rect_col(vec2(b1.x, b1.y + b1.h / 2), b2) or point_rect_col(vec2(b1.x + b1.w, b1.y + b1.h / 2), b2)
end

function rect_circ_col(b, c, r)
  local x1 = b.x
  local x2 = b.x + b.w - 1
  local y1 = b.y
  local y2 = b.y + b.h - 1
  local r2 = r * r
  return dist_squared(x1, y1, c.x, c.y) < r2 or dist_squared(x2, y1, c.x, c.y) < r2 or dist_squared(x1, y2, c.x, c.y) < r2 or dist_squared(x2, y2, c.x, c.y) < r2
end

function dist_squared(x1, y1, x2, y2)
  return (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
end

function center_dist_squared(b1, b2)
  return dist_squared(b1.x + b1.w / 2, b1.y + b1.h / 2, b2.x + b2.w / 2, b2.y + b2.h / 2)
end

-- From UnitVector (https://www.lexaloffle.com/bbs/?tid=38338)
-- takes in a table of 32 0|1 values
function b32pack(nums)
  local b = 0
  for i = 0, 31 do
    b = b | nums[i] >> (i - 15)
  end
  return b
-- returns a 32-bit number
end

-- From UnitVector (https://www.lexaloffle.com/bbs/?tid=38338)
-- takes a 32-bit number
function b32unpack(b)
  local nums = {}
  for i = 0, 31 do
    local s = i - 15
    local n = (b & 1 >> s) << s
    nums[i] = abs(n)
  -- absolute value must be taken since neg values get a -1 in the last bit
  end
  return nums
-- returns a table of 32 0|1 values
end

-->8
-- main
-- flags :
-- 0 solid
-- 1 one way platform
-- 2 fake walls
-- 3 friction wall right
-- 4 friction wall left
pal(5, 133, 1)
-- dark-grey -> darker-grey
pal(14, 136, 1)
-- pink -> dark-red
pal(4, 128, 1)
-- brown -> brownish-black
pal(12, 140, 1)
-- blue -> true-blue
poke(0x5F00 + 92, 255)
-- no btnp repeat
-- constants
gravity = 0.5
invicible = false
jump_btn = 5
jump_buf_frames = 4
coyote_frames = 3
-- game state
frame_count, seconds, minutes, total_cards = 0, 0, 0, 0
current_room, spawn_pos, talking_npc, y_to_unlock = nil
room_objects, cleared_rooms, collected_cards, card_ranks, dialogs, timers = {}, {}, {}, {}, {}, {}
-- menu state
can_continue = false
main_menu = true
menu_item = 1
-- player constants
p_sprite_l = 10
p_sprite_r = 8
p_walk_speed = 0.7
p_walk_acc = 0.01
p_air_lat_speed = 1.0
p_air_acc = 0.1
p_jump_force = -8
p_jump_initial_acc = 3.7
p_jump_acc = 2.7
p_max_jump_frames = 5
-- player state
p_vel = vec2()
p_facing = 1
p_walking, p_friction, was_carrying, was_on_ground = false
deaths = 0
p_carried, p_bounds, p_sub_bounds = nil

function _init()
  -- init_cards()
  local rank = 0
  foreach_room(function(rx, ry)
    foreach_room_tile(rx, ry, function(x, y)
      local sprite = mget(x, y)
      if sprite == 39 or sprite == 40 then
        local room_idx = room_index(rx, ry)
        add(card_rooms, room_idx)
        card_ranks[room_idx] = rank
        rank = rank + (1)
      end
    end)
  end)
  total_cards = rank
  -- init save state
  cartdata "pck404_512under_0"
  if dget(0) > 0 then
    can_continue = true
    menu_item = 0
  end
  -- open main menu
  main_menu = true
  load_theme('dirt')
  local rooms_x = {7, 2, 3, 7}
  load_room(rooms_x[ceil(rnd() * #rooms_x)], 0)
  music(62)
end

function save_state()
  local spawn_room_x, spawn_room_y = (spawn_pos.x + 4) // 128, (spawn_pos.y + 4) // 128
  dset(0, 1)
  dset(1, room_index(spawn_room_x, spawn_room_y))
  -- save collected cards
  local cards_table = {}
  foreach_room(function(x, y)
    cards_table[room_index(x, y)] = card_collected(vec2(x, y)) and 1 or 0
  end)
  dset(2, b32pack(cards_table))
  -- save cleared rooms
  local cleared_table = {}
  foreach_room(function(x, y)
    cleared_table[room_index(x, y)] = room_cleared(vec2(x, y)) and 1 or 0
  end)
  dset(3, b32pack(cleared_table))
  dset(4, minutes)
  dset(5, seconds)
  dset(6, frame_count)
  dset(7, deaths)
end

function load_state()
  -- load collected cards
  collected_cards = {}
  local cards_table = b32unpack(dget(2) or 0)
  foreach_room(function(x, y)
    local idx = room_index(x, y)
    if cards_table[idx] == 1 then
      collect_card(vec2(x, y))
    end
  end)
  -- load cleared rooms
  cleared_rooms = {}
  local table = b32unpack(dget(3) or 0)
  foreach_room(function(x, y)
    local idx = room_index(x, y)
    if table[idx] == 1 then
      clear_room(vec2(x, y))
    end
  end)
  minutes = dget(4)
  seconds = dget(5)
  frame_count = dget(6)
  deaths = dget(7)
  local room = dget(1)
  local room_y = clamp(room // 8, 0, 3)
  load_room(clamp(room - room_y * 8, 0, 7), room_y)
  respawn_p()
  foreach_room(function(rx, ry)
    remove_succeeded_doors(rx, ry)
  end)
end

function continue()
  if can_continue then
    reset_game()
    load_state()
    main_menu = false
  end
end

function foreach_room(func)
  for x = 0, 7 do
    for y = 0, 3 do
      func(x, y)
    end
  end
end

function foreach_room_tile(rx, ry, func)
  for y = ry * 16, ry * 16 + 15 do
    for x = rx * 16, rx * 16 + 15 do
      func(x, y)
    end
  end
end

function reset_game()
  spawn_pos = nil
  cam_x = -1
  cam_y = -1
  minutes = 0
  seconds = 0
  frame_count = 0
  deaths = 0
end

function _update()
  if main_menu then
    update_menu()
    return
  end
  frame_count = frame_count + (1)
  if frame_count >= 30 then
    frame_count = 0
    seconds = seconds + (1)
    if (seconds >= 60) then
      seconds = 0
      minutes = minutes + (1)
    end
  end
  room_frames = room_frames + (1)
  dialogs = {}
  talking_npc = nil
  --check_current_room()
  -- do not change room when player is hurt
  if not is_timer_active "p_hurt" then
    local p_center = vec2(p_bounds.x + p_bounds.w / 2, p_bounds.y + p_bounds.h - 1)
    local room_x, room_y = p_center.x // 128, p_center.y // 128
    if room_x ~= current_room.x or room_y ~= current_room.y then
      load_room(room_x, room_y)
    end
  end
  dec_if_active "room_freeze"
  -- update_p()
  local grounded = is_grounded()
  if not is_timer_active "p_hurt" and not is_timer_active "room_freeze" then
    process_lateral(grounded)
    process_vertical(grounded)
  end
  apply_gravity(grounded)
  --apply_velocity(p)
  apply_vel_y()
  apply_vel_x()
  p_bounds.x = round(p_sub_bounds.x)
  p_bounds.y = round(p_sub_bounds.y)
  -- update_player_hurt()
  if dec_if_active "p_hurt" then
    if not is_timer_active "p_hurt" then
      respawn_p()
      load_room(current_room.x, current_room.y)
      camera()
    end
  end
  dec_if_active "wall_jump"
  if p_walking and room_frames % 6 == 0 then
    sfx(30)
  end
  p_vertigo = grounded and is_on_platform_edge() and min(p_vertigo + 1, 8) or 0
  -- update_room_objects()
  was_carrying = carrying()
  foreach(room_objects, function(obj)
    if (obj.update ~= nil) then
      obj:update()
    end
  end)
  move_camera()
end

function _draw()
  cls()
  if main_menu then
    draw_main_menu()
    return
  end
  draw_room()
  -- draw_room_objects()
  foreach(room_objects, function(obj)
    if obj.draw ~= nil then
      obj:draw()
    end
  end)
  local in_last_room, collected_cards_count = current_room.x == 2 and current_room.y == 3, card_count()
  if in_last_room then
    local txt = is_step_active("xxxxxxxx--------") and "thanks for\nplaying \xe2\x99\xa5" or finished_time .. "\n" .. collected_cards_count .. "/" .. total_cards .. " cards\n" .. deaths .. " deaths"
    print(txt, 296, 403, 15)
  end
  -- draw_p()
  local p_visible = not is_timer_active("p_hurt") or frame_count % 2 == 0
  local grounded = is_grounded()
  if p_visible then
    local sprite = nil
    if p_friction and not grounded then
      sprite = 12
    elseif p_vertigo > 7 then
      sprite = 10
      if frame_count % 15 > 6 then
        sprite = sprite + (1)
      end
    else
      sprite = 8
      if p_walking and frame_count % 6 > 3 then
        sprite = sprite + (1)
      end
    end
    spr(sprite, round(p_bounds.x) - 1, round(p_bounds.y), (p_bounds.w + 2) / 8, p_bounds.h / 8, p_facing == 0)
    if room_frames % 300 < 3 then
      pset(p_bounds.x + (p_facing == 1 and 5 or 4), p_bounds.y + 2, 5)
    end
  end
  -- draw_room_objects()
  foreach(room_objects, function(obj)
    if obj.draw_over ~= nil then
      obj:draw_over()
    end
  end)
  -- draw_messages()
  for i, dialog in pairs(dialogs) do
    print(glitched(sub(dialog.text, 0, dialog.counter)), dialog.x, dialog.y, 7)
  end
  if not in_last_room then
    local card_counter_visible = false
    -- draw_card_count()
    if dec_if_active "draw_card_counter" then
      camera()
      local x = collected_cards_count > 9 and 106 or 110
      print("\f7\x5ei" .. collected_cards_count .. "/" .. total_cards, x, 2, 7)
      spr(112, x - 10, 1)
      card_counter_visible = true
    end
    -- draw_room_number()
    if dec_if_active "room_number_counter" then
      local name = room_name(current_room)
      local nx, ny = card_counter_visible and 2 or 126 - #name * 4, card_counter_visible and 10 or 2
      camera()
      print("\f7room " .. "\f7\x5ei" .. (split("abcd", "")[current_room.y + 1] or "?") .. "-" .. current_room.x + 1, 2, 2)
      print("\f7\x5ei" .. name, nx, ny)
    end
  end
  if (p_bounds.y > 800) then
    camera()
    print(glitched "  congratulations\nfor beating the game", 26, 66, 15)
  end
end

function draw_room()
  map(current_room.x * 16, current_room.y * 16, current_room.x * 128, current_room.y * 128, 16, 16)
end

glitch_glyphs = split "*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*,*, ,$,&,@,#"

function glitched(text)
  local output = ""
  for _, c in ipairs(split(text, "")) do
    if c == "*" then
      output = output .. "\f5" .. (glitch_glyphs[flr(rnd() * #glitch_glyphs)] or "*")
    else
      output = output .. "\f7" .. c
    end
  end
  return output
end

function blink(speed, offset)
  return flr((offset or 0) + time() * speed) % 2 == 0
end

function update_menu()
  if dec_if_active "starting" then
    if not is_timer_active "starting" then
      if menu_item == 0 then
        continue()
      else
        -- start game
        reset_game()
        load_room(0, 0)
        respawn_p()
        main_menu = false
      end
      if not no_music then
        music(0, 500, 5)
      end
    end
  else
    if can_continue then
      if menu_item == 0 then
        if btnp(3) then
          menu_item = 1
        end
      else
        if btnp(2) then
          menu_item = 0
        end
      end
    end
    if btnp(4) or btnp(5) then
      timers.starting = 45
      sfx(32)
    end
  end
end

function draw_main_menu()
  if get_timer("starting") > 0 and get_timer("starting") < 15 then
    return
  end
  -- bg
  move_camera()
  draw_room()
  camera()
  -- title
  local title_y = 63
  rectfill(0, title_y, 128, title_y + 15, 5)
  local title = "\x5et\x5ew512px under"
  print(title, 21, title_y + 4, 0)
  print(title, 20, title_y + 3, 7)
  local by = "a game by pck404"
  print(by, x_centred(by), 81, 13)
  print("v1", 2, 122, 5)
  if can_continue then
    rectfill(46, 94, 82, 114, 0)
    rectfill(45, 93, 81, 113, 5)
  else
    rectfill(52, 98, 76, 108, 0)
    rectfill(51, 97, 75, 107, 5)
  end
  local not_starting = not is_timer_active "starting"
  if not_starting or blink(10) then
    if can_continue then
      if not_starting or menu_item == 0 then
        draw_menu_item("continue", 0, 96)
      end
      if not_starting or menu_item == 1 then
        draw_menu_item("new game", 1, 106)
      end
    else
      draw_menu_item("start", 1, 100)
    end
  end
end

function draw_menu_item(text, item_index, y)
  local x, text = x_centred(text), (menu_item == item_index) and "\x5ei" .. text or text
  print(text, x, y, (menu_item ~= item_index or blink(4)) and 6 or 7)
end

function x_centred(text)
  return 64 - #text * 2
end

-->8
-- player
function process_lateral(grounded)
  if is_timer_active "wall_jump" then
    return
  end
  p_friction = false
  local max_speed = grounded and p_walk_speed or p_air_lat_speed
  local acc = grounded and p_walk_acc or p_air_acc
  if btn(1) and btn(0) then
    p_walking = false
    p_vel.x = 0
  elseif btn(1) then
    p_walking = true
    p_vel.x = clamp(move_towards(p_vel.x, max_speed, acc), 0, max_speed)
    p_friction = against_wall_right()
    p_facing = p_friction and 0 or 1
  elseif btn(0) then
    p_walking = true
    p_vel.x = clamp(move_towards(p_vel.x, -max_speed, acc), 0, -max_speed)
    p_friction = against_wall_left()
    p_facing = p_friction and 1 or 0
  elseif not btn(1) and not btn(0) then
    p_walking = false
    p_vel.x = 0
  end
  p_walking = p_walking and grounded
end

function against_wall_left()
  return fmget((p_bounds.x - 1) / 8, (p_bounds.y + p_bounds.h / 2) / 8, 3)
end

function against_wall_right()
  return fget(mget((p_bounds.x + p_bounds.w + 1) / 8, (p_bounds.y + p_bounds.h / 2) / 8), 4)
end

function process_vertical(grounded)
  dec_if_active "jump_buffer"
  dec_if_active "coyote"
  local is_now_grounded = grounded
  if btnp(jump_btn) and not is_now_grounded then
    timers.jump_buffer = jump_buf_frames
  end
  if not was_on_ground and is_now_grounded then
    sfx(30)
  end
  if was_on_ground and not is_now_grounded then
    timers.coyote = coyote_frames
  end
  was_on_ground = is_now_grounded
  local against_left = against_wall_left()
  local against_right = against_wall_right()
  local against_wall = against_left or against_right
  local want_jump = btnp(jump_btn) or (is_timer_active "jump_buffer" and btn(jump_btn))
  local can_jump = is_now_grounded or is_timer_active "coyote" or against_wall
  if want_jump and can_jump then
    -- start jump
    timers.p_jump_frames = p_max_jump_frames
    sfx(29)
    was_on_ground = false
    timers.jump_buffer = 0
    timers.coyote = 0
    local is_wall_jump = not is_now_grounded and against_wall
    p_vel.y = is_wall_jump and wall_jump_initial_acc or move_towards(p_vel.y, p_jump_force, p_jump_initial_acc)
    -- wall jump
    if is_wall_jump then
      local f = 1.8
      p_vel.x = against_left and f or -f
      timers.wall_jump = 8
    end
  elseif btn(jump_btn) and dec_if_active "p_jump_frames" then
    p_vel.y = move_towards(p_vel.y, p_jump_force, p_jump_acc)
    -- why is that ?
    if p_vel.y < 0 then
      p_vel.y = p_vel.y / (2)
    end
  end
  if not btn(jump_btn) and is_timer_active "p_jump_frames" then
    timers.p_jump_frames = 0
    if p_vel.y < 0 then
      p_vel.y = p_vel.y / (2)
    end
  end
end

function collides(b, f)
  local x1 = round(b.x) / 8
  local x2 = round(b.x + b.w - 1) / 8
  local y1 = round(b.y) / 8
  local y2 = round(b.y + b.h - 1) / 8
  return fmget(x1, y1, f) or fmget(x1, y2, f) or fmget(x2, y1, f) or fmget(x2, y2, f)
end

function collides6(b, f)
  local x1 = round(b.x) / 8
  local x2 = round(b.x + b.w - 1) / 8
  local y1 = round(b.y) / 8
  local y2 = round(b.y + (b.h / 2)) / 8
  local y3 = round(b.y + b.h - 1) / 8
  return fmget(x1, y1, f) or fmget(x1, y2, f) or fmget(x2, y1, f) or fmget(x2, y2, f) or fmget(x1, y3, f) or fmget(x2, y3, f)
end

function player_hit(x, y)
  local b = p_bounds
  local x1 = b.x + 1
  local x2 = b.x + b.w - 3
  local y1 = b.y
  local y2 = b.y + b.h - 1
  return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

function fmget(x, y, f)
  return fget(mget(x, y), f)
end

function is_grounded()
  if p_vel.y < 0 then
    return false
  end
  local x1 = round(p_sub_bounds.x) / 8
  local x2 = round(p_sub_bounds.x + p_sub_bounds.w - 1) / 8
  local y = round(p_sub_bounds.y + p_sub_bounds.h)
  local my = y / 8
  local edge = y % 8 == 0
  local not_down = not btn(3)
  return fmget(x1, my, 0) or fmget(x2, my, 0) or (fmget(x1, my, 1) and edge and not_down) or (fmget(x2, my, 1) and edge and not_down)
end

function is_walkable(mx, my)
  return fmget(mx, my, 0) or fmget(mx, my, 1)
end

function is_on_platform_edge()
  local right, my, x1, x2 = p_sub_bounds.x + p_sub_bounds.w - 1, round(p_sub_bounds.y + p_sub_bounds.h) / 8, round(p_sub_bounds.x) / 8, round(p_sub_bounds.x + 2) / 8
  local x3, x4 = round(right) / 8, round(right - 2) / 8
  return (is_walkable(x1, my) and not is_walkable(x2, my)) or (is_walkable(x3, my) and not is_walkable(x4, my))
end

function apply_gravity(grounded)
  -- Slide on walls
  if p_friction and p_vel.y > 0 then
    p_vel.y = 0.0005
    return
  end
  if not grounded then
    p_vel.y = p_vel.y + (gravity)
  -- if falling and on ground, freeze y velocity
  elseif p_vel.y > 0 then
    p_vel.y = 0
  end
end

function apply_vel_x()
  -- a step is 1 or -1
  local step_x = sign(p_vel.x)
  -- the number of step
  local amt_x = step_x * round(abs(p_vel.x))
  -- for each x increment
  for i = 0, abs(amt_x) do
    -- detect collision		
    -- if there's no collision
    if not collides6(translated(p_sub_bounds, step_x, 0), 0) then
      -- move by that increment
      p_sub_bounds.x = p_sub_bounds.x + (step_x)
      -- if that's the last step...
      if i == abs(amt_x) then
        -- try to move by the fractionnal part
        local rem_x = p_vel.x - amt_x
        local rem_bounds = translated(p_sub_bounds, rem_x, 0)
        -- if there's still no collision...
        if not collides6(rem_bounds, 0) then
          -- ...apply fractional part to subpixel bounds
          p_sub_bounds.x = p_sub_bounds.x + (rem_x)
        end
      end
    -- if there's a collision
    else
      -- snap sub-pixel position to nearest integer
      p_sub_bounds.x = round(p_sub_bounds.x)
      break
    end
  end
  p_sub_bounds.x = clamp(p_sub_bounds.x, 0, 1018)
end

function apply_vel_y()
  local step_y = sign(p_vel.y)
  local amt_y = step_y * round(abs(p_vel.y))
  for i = 0, abs(amt_y) do
    if check_y(step_y) then
      p_sub_bounds.y = p_sub_bounds.y + (step_y)
      -- subpixel check
      if i == abs(amt_y) then
        local rem_y = p_vel.y - amt_y
        if check_y(rem_y) then
          p_sub_bounds.y = p_sub_bounds.y + (rem_y)
        else
          p_sub_bounds.y = round(p_sub_bounds.y)
        end
      end
    else
      -- stopped by floor or ceiling
      p_vel.y = 0
      timers.p_jump_frames = 0
      break
    end
  end
end

function check_y(offset_y)
  local col_bounds = translated(p_sub_bounds, 0, offset_y)
  local collides_with_ground = collides(col_bounds, 0)
  local on_1way = p_vel.y > 0 and is_grounded()
  return not collides_with_ground and not on_1way
end

function hurt_player()
  if not invicible and not is_timer_active "p_hurt" then
    timers.p_hurt = 8
    p_carried = nil
    p_vel.x = 0
    timers.shake = shake_dur
    sfx(31)
    deaths = deaths + (1)
  end
end

function respawn_p()
  local b = new_bounds(spawn_pos.x, spawn_pos.y, 6, 10)
  p_bounds = copy_bounds(b)
  p_sub_bounds = copy_bounds(b)
  p_vel = vec2()
  p_facing = spawn_pos.x < (current_room.x + 0.5) * 128 and 1 or 0
  timers.p_jump_frames = 0
  timers.p_hurt = 0
  p_vertigo = 0
  p_walking = false
  p_friction = false
end

function p_center()
  return bounds_center(p_bounds)
end

-->8
-- rooms
room_frames = 0
-- how many frames spent in a room, not for timing critical things
teleporter_index = 0
opened_doors = {}
tile_fns = {[1] = function(x, y)
  return register_spawner(x, y)
end, [8] = function(x, y)
  return create_scroll_bot(x, y)
end, [38] = function(x, y, mx, my)
  add(room_objects, register_spawner(x, y))
  return register_fake_wall(x, y, mx, my, 38)
end, [32] = function(x, y)
  if room_cleared(current_room) then
    return register_spawner(x, y, true)
  end
end, [17] = function(x, y)
  return create_ray_en(x, y)
end, [18] = function(x, y)
  return create_v_ray_en(x, y)
end, [19] = function(x, y)
  return create_h_ray_en(x, y)
end, [51] = function(x, y)
  return create_h_ray_en(x, y, "--xxxx--")
end, [52] = function(x, y)
  return create_h_ray_en(x, y, "xx----xx")
end, [53] = function(x, y)
  return create_v_ray_en(x, y, "--xxxx--")
end, [54] = function(x, y)
  return create_v_ray_en(x, y, "xx----xx")
end, [6] = function(x, y, mx, my)
  return register_button(x, y, mx, my, "yellow", 6)
end, [7] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "yellow", 7)
end, [62] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "yellow", 62)
end, [22] = function(x, y, mx, my)
  return register_button(x, y, mx, my, "pink", 22)
end, [23] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "pink", 23)
end, [63] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "pink", 63)
end, [56] = function(x, y, mx, my)
  return register_fake_wall(x, y, mx, my, 56)
end,
-- Spikes
[4] = function(x, y)
  local bounds = new_bounds(x + 1, y + 4, 6, 4)
  return {update = function()
    if rect_rect_col(p_bounds, bounds) then
      hurt_player()
    end
  end}
end, [5] = function(x, y)
  -- Lamp
  mset(x / 8, y / 8, 0)
  -- prevent from being instantiated twice
  if carrying() and p_carried.type == "lamp" then
    return {reset = function()
      mset(x / 8, y / 8, 5)
    end}
  end
  local lamp = new_carriable("lamp", x, y, 4, 8)

  function lamp:draw()
    local x0 = self.bounds.x + 2 + (p_facing == 0 and 1 or -1)
    local y0 = self.bounds.y + 4
    local res = 60 + rnd() * 20
    for angle = 0, res do
      for d = 1, 38 do
        local px = x0 + sin(angle / res) * d
        local py = y0 + cos(angle / res) * d
        local flags = fget(mget(px / 8, py / 8))
        if (flags & 1) ~= 0 or (flags & 2) ~= 0 then
          pset(px, py, current_theme.lamp)
          break
        end
      end
    end
    spr(5, self.bounds.x, self.bounds.y, 0.5, 1)
    if (frame_count // 4) % 3 > 0 then
      sspr(44, offset == 1 and 0 or 4, 4, 4, self.bounds.x, self.bounds.y + 4)
    end
  end

  function lamp:reset()
    mset(x / 8, y / 8, 5)
  end

  return lamp
end, [58] = function(x, y, mx, my)
  -- register_hidden_btn
  local color = "yellow"
  mset(mx, my, 57)
  local bounds = new_bounds(x, y)
  return {update = function()
    local sprite = opened_doors[color] and 59 or 58
    if draw_fake_wall(bounds, sprite) and not opened_doors[color] and is_grounded() then
      btn_check_collision(bounds, color)
    end
  end, reset = function()
    mset(mx, my, 58)
  end}
end, [48] = function(x, y)
  return register_block(x, y, "blue", 48)
end, [49] = function(x, y)
  return register_receptacle(x, y, "blue")
end, [97] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "blue", 97)
end, [113] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "blue", 113)
end, [20] = function(x, y, mx, my)
  if dget(0) > 0 then
    return register_block(x, y, "red", 20)
  else
    mset(mx, my, 0)
  --return { reset=function() mset(mx,my,20) end}
  end
end, [36] = function(x, y, mx, my)
  return register_door(x, y, mx, my, "red", 36)
end, [21] = function(x, y)
  return register_receptacle(x, y, "red")
end,
-- Card
[40] = function(x, y, mx, my)
  mset(x / 8, y / 8, 0)
  if card_collected(current_room) then
    return
  end
  local b = new_bounds(x + 2, y, 4)
  return {update = function()
    update_card(b)
  end, draw = function()
    draw_card(x, y)
  end, reset = function()
    mset(mx, my, 40)
  end}
end,
-- Hidden card
[39] = function(x, y, mx, my)
  local b = new_bounds(x + 2, y, 4)
  mset(mx, my, 57)
  if not card_collected(current_room) then
    sfx(40)
  end
  return {update = function()
    update_card(b)
  end, draw = function()
    if draw_fake_wall(b) and not card_collected(current_room) then
      draw_card(x, y)
    end
  end, reset = function()
    mset(mx, my, 39)
  end}
end,
-- Breaking wall
[14] = function(x, y, mx, my)
  local breaking, broken, bx1, bx2 = 0, false, x, x + 8
  return {update = function()
    if broken then
      return
    end
    if breaking > 0 then
      breaking = breaking - (1)
      if breaking == 0 then
        mset(mx, my, 0)
        broken = true
      else
        local sprites = split '14,15,30,31,46,47'
        local sprite = ceil((15 - breaking) / 2)
        mset(mx, my, sprites[sprite])
      end
    elseif is_grounded() and over_breakable_only() then
      local px0 = p_bounds.x
      local px1 = p_bounds.x + p_bounds.w / 2
      local px2 = p_bounds.x + p_bounds.w
      local py = p_bounds.y + p_bounds.h
      if py == y and ((px0 >= bx1 and px0 < bx2) or (px1 >= bx1 and px1 < bx2) or (px2 >= bx1 and px2 < bx2)) then
        breaking = 15
        sfx(38, 1)
      end
    end
  end, reset = function()
    mset(mx, my, 14)
  end}
end,
-- NPCs
[94] = function(x, y)
  return register_npc(x, y, "purple")
end, [60] = function(x, y)
  return register_npc(x, y, "blue")
end, [95] = function(x, y)
  return register_npc(x, y, "red")
end, [61] = function(x, y)
  return register_npc(x, y, "yellow")
end, [93] = function(x, y, mx, my)
  local spider = register_talker(x, y, "spider")

  function spider:draw()
    self:draw_dialog()
    local t = (room_frames // 6) % 4
    local sprite = t == 0 and 93 or 106 + t
    mset(mx, my, sprite)
  end

  function spider:reset()
    mset(mx, my, 93)
  end

  return spider
end,
-- theme tiles
[118] = function()
  load_theme("dirt")
end, [119] = function()
  load_theme("dark")
end, [120] = function()
  load_theme("blue")
end, [121] = function()
  load_theme("grey")
end, [122] = function(x, y, mx, my)
  load_theme("dark")
  mset(mx, my, 2)
  return {reset = function()
    mset(mx, my, 122)
  end}
end,
-- unlock tiles
[70] = function()
  register_unlock_y(0)
end, [71] = function()
  register_unlock_y(1)
end, [72] = function()
  register_unlock_y(2)
end, [73] = function()
  register_unlock_y(3)
end, [86] = function()
  register_unlock_x(0)
end, [87] = function()
  register_unlock_x(1)
end, [88] = function()
  register_unlock_x(2)
end, [89] = function()
  register_unlock_x(3)
end, [102] = function()
  register_unlock_x(4)
end, [103] = function()
  register_unlock_x(5)
end, [104] = function()
  register_unlock_x(6)
end, [105] = function()
  register_unlock_x(7)
end,
-- teleporter
[123] = function(x, y)
  return register_teleporter(x, y)
end,
-- flowers
[110] = function(x, y, mx, my)
  return register_flower(mx, my, 110)
end, [126] = function(x, y, mx, my)
  return register_flower(mx, my, 126)
end,}

function register_flower(mx, my, tile)
  local offset = rnd() * 50
  return {update = function()
    mset(mx, my, tile + (blink(0.5, offset) and 1 or 0))
  end, reset = function()
    mset(mx, my, tile)
  end}
end

function is_door_sprite(s)
  -- blue doors are excluded
  return s == 7 or s == 23 or s == 62 or s == 63
end

function remove_succeeded_doors(rx, ry)
  foreach_room_tile(rx, ry, function(mx, my)
    local sprite = mget(mx, my)
    if is_door_sprite(sprite) and room_cleared(vec2(rx, ry)) then
      mset(mx, my, 0)
    end
  end)
end

function room_index(x, y)
  return y * 8 + x
end

room_names = split "entrance,u-room,open sesame,2-room,you have to climb,get sneaky,laser hell,the garden,hidden conduit,timely,light your way,dark room,mind the gap,who put it there?,secret tunnels,repair lab,sticky walls,ridges and spikes,ping pong jumps,stairway,cube and switch,sadistic,plan your way back,that's tight,lair,what the...,warp room,you can do it!,tricky wall jumps,better leave on time,how do i?...,the torch or the cube?"

function room_name(room)
  return room_names[room_index(room.x, room.y) + 1]
end

-- themes
themes = {dirt = {bg = 128, wall = 134, lamp = 7, shoes = 132}, blue = {bg = 0, wall = 1, lamp = 12, shoes = 128}, grey = {bg = 128, wall = 133, lamp = 6, shoes = 132}, dark = {bg = 0, wall = 128, lamp = 9, shoes = 132},}
current_theme = themes.dirt

function load_room(room_x, room_y)
  for _, obj in ipairs(room_objects) do
    if obj.reset ~= nil then
      obj.reset()
    end
  end
  room_frames = 0
  room_objects = {}
  current_room = vec2(room_x, room_y)
  timers.room_number_counter = 60
  timers.room_freeze = 5
  opened_doors = room_cleared(current_room) and {pink = true, yellow = true} or {}
  y_to_unlock = nil
  teleporter_index = 0
  foreach_room_tile(room_x, room_y, function(mx, my)
    local fn = tile_fns[mget(mx, my)]
    if fn ~= nil then
      local ret = fn(mx * 8, my * 8, mx, my)
      if ret ~= nil then
        add(room_objects, ret)
      end
    end
  end)
  if carrying then
    add(room_objects, p_carried)
  end
  if room_x == 2 and room_y == 3 then
    local ms = ((frame_count // 30) * 1000)
    local h = minutes // 60
    local m = minutes - h * 60
    m = m < 10 and "0" .. m or m
    local s = seconds < 10 and "0" .. seconds or seconds
    local time_text = h .. ":" .. m .. ":" .. s
    finished_time = h .. ":" .. m .. ":" .. s .. ":" .. ms
  end
end

function load_theme(name)
  local theme = themes[name]
  if theme ~= nil then
    current_theme = theme
    pal(0, current_theme.bg, 1)
    pal(1, current_theme.wall, 1)
    pal(11, current_theme.bg, 1)
    pal(4, current_theme.shoes, 1)
    pal(15, 11, 1)
  end
end

function clear_room(room)
  local rx, ry = room.x, room.y
  local idx = room_index(rx, ry)
  if not cleared_rooms[idx] then
    cleared_rooms[idx] = true
    remove_succeeded_doors(rx, ry)
  end
end

function room_cleared(room)
  return cleared_rooms[room_index(room.x, room.y)] ~= nil
end

-->8
-- camera
cam_x = -1
cam_y = -1
cam_speed = 40
shake_dur = 6
shake_amount = 3

function move_camera()
  local target_x = current_room.x * 128
  local target_y = current_room.y * 128
  cam_x = cam_x < 0 and target_x or move_towards(cam_x, target_x, cam_speed)
  cam_y = cam_y < 0 and target_y or move_towards(cam_y, target_y, cam_speed)
  if dec_if_active "shake" then
    local shake_x = rnd() * shake_amount - shake_amount / 2
    local shake_y = rnd() * shake_amount - shake_amount / 2
    camera(cam_x + shake_x, cam_y + shake_y)
  else
    camera(cam_x, cam_y)
  end
end

-->8
-- ray enemy
function create_scroll_bot(x, y)
  local st, mx, my = y * 5, x // 8, y // 8
  mset(mx, my)
  return {draw = function()
    spr(8, x + (st + t() * 15) % 258 - 8, y)
  end, reset = function()
    mset(mx, my, 8)
  end}
end

function create_ray_en(x, y)
  local en = {bounds = new_bounds(x, y, 8, 2), ray_points = {}, angle_to_target = nil, shoot = false, beam_on = false, beam_distance = 0, beam_speed = 60, beam_lgth = 70, swing_start = 0, swing_phase = 0.5, expl = 0, expl_frame_count = 6, expl_pos = nil, expl_r = 3,}
  local charge_frame_count, charge, wait_frame_count, wait, charge_particles = 18, 0, 18, 0, {}

  function en:draw()
    -- draw ray
    -- no ray 3 frames before shooting
    if charge_frame_count - charge < 3 then
      return
    end
    for i, p in ipairs(en.ray_points) do
      local col, t = (en.shoot or i == #en.ray_points) and 7 or 2, room_frames - en.swing_start
      if en.shoot or rnd() > max(0.18, 1 - (t / 20)) then
        pset(p.x, p.y, col)
      end
    end
    -- draw_charge(en)
    for _, particle in ipairs(charge_particles) do
      pset(en.bounds.x + en.bounds.w / 2 + sin(particle.angle) * particle.d, en.bounds.y + en.bounds.h / 2 + cos(particle.angle) * particle.d, 7)
    end
    -- draw_expl(en)
    if en.expl > 0 and frame_count % 2 == 0 then
      circfill(en.expl_pos.x, en.expl_pos.y, en.expl_r, 7)
    end
  end

  function en:update()
    if en.shoot then
      en.ray_points = {}
      if en.beam_on then
        beam(en)
      end
      wait = wait + (1)
      if wait >= wait_frame_count then
        en.shoot = false
        en.angle_to_target = nil
        en.swing_start = room_frames
      end
    else
      vision_cone(en)
    end
    -- update_charge(en)
    if en.angle_to_target ~= nil and not en.shoot then
      charge = charge + (1)
      if charge < charge_frame_count then
        add(charge_particles, {d = rnd() * 3 + 13, angle = rnd(), speed = rnd() * 2 + 2})
      else
        -- shoot
        en.shoot = true
        en.ray_points = {}
        en.beam_distance = 0
        wait = 0
        en.beam_on = true
        sfx(34)
      end
    else
      charge = 0
    end
    for i = #charge_particles, 1, -1 do
      local particle = charge_particles[i]
      particle.d = particle.d - (particle.speed)
      if particle.d <= 0 then
        del(charge_particles, particle)
      end
    end
    -- update_expl(en)
    if en.expl > 0 then
      en.expl = en.expl - (1)
      if rect_circ_col(p_bounds, en.expl_pos, en.expl_r) then
        hurt_player()
      end
    end
  end

  return en
end

function beam(ray_en)
  local x0 = ray_en.bounds.x + 4
  local y0 = ray_en.bounds.y + ray_en.bounds.h
  local r2 = ray_en.beam_distance
  local r1 = max(0, r2 - ray_en.beam_lgth)
  local angle = ray_en.angle_to_target
  local x1, y1 = x0 + r1 * sin(angle), y0 + r1 * cos(angle)
  traverse(x1, y1, x0 + r2 * sin(angle), y0 + r2 * cos(angle), function(x, y)
    local hit_p = player_hit(x, y)
    local hit_something = fmget(x / 8, y / 8, 0) or fmget(x / 8, y / 8, 1) or hit_p
    add(ray_en.ray_points, vec2(x, y))
    local d_squared = dist_squared(x, y, x1, y1)
    if hit_something then
      ray_en.beam_on = false
      ray_en.expl = ray_en.expl_frame_count
      ray_en.expl_pos = vec2(x, y)
    end
    if hit_p then
      hurt_player()
    end
    return hit_something or d_squared >= ray_en.beam_lgth * ray_en.beam_lgth
  end)
  ray_en.beam_distance = ray_en.beam_distance + (ray_en.beam_speed)
end

function vision_cone(ray_en)
  local x0 = ray_en.bounds.x + 4
  local y0 = ray_en.bounds.y + ray_en.bounds.h
  local t = ray_en.swing_phase + 0.25 * (room_frames - ray_en.swing_start) / 60
  local base_angle = ray_en.angle_to_target or sin(t) * 0.5 * 0.12
  local points = {}
  local target_found = false
  local angles = {}
  local cone_width = 0.002
  add(angles, base_angle)
  if ray_en.angle_to_target ~= nil then
    add(angles, base_angle - cone_width)
    add(angles, base_angle + cone_width)
  end
  local r = 128
  for _, angle in ipairs(angles) do
    local x1 = x0 + r * sin(angle)
    local y1 = y0 + r * cos(angle)
    traverse(x0, y0, x1, y1, function(x, y)
      local hit_floor = fmget(x / 8, y / 8, 0)
      local hit_1way = fmget(x / 8, y / 8, 1)
      local hit_p = player_hit(x, y)
      if angle == base_angle then
        add(points, vec2(x, y))
      end
      if hit_floor or hit_1way or hit_p then
        if hit_p then
          ray_en.angle_to_target = atan2(p_bounds.y + p_bounds.h / 2 - y0, p_bounds.x + p_bounds.w / 2 - x0)
          target_found = true
        end
        return true
      end
      return false
    end)
    ray_en.ray_points = points
  end
end

function traverse(x0, y0, x1, y1, should_break)
  local dx = abs(x1 - x0)
  local sx = x0 < x1 and 1 or -1
  local dy = -abs(y1 - y0)
  local sy = y0 < y1 and 1 or -1
  local err = dx + dy
  local max = 128
  local count = 0
  while true do
    count = count + (1)
    if count >= max then
      break
    end
    if should_break(x0, y0) then
      break
    end
    if x0 == x1 and y0 == y1 then
      break
    end
    local e2 = 2 * err
    if e2 >= dy then
      err = err + (dy)
      x0 = x0 + (sx)
    end
    if e2 <= dx then
      err = err + (dx)
      y0 = y0 + (sy)
    end
  end
end

function create_h_ray_en(x, y, pattern)
  local ray_points = {}
  return {draw = function()
    draw_laser(ray_points)
  end, update = function()
    ray_points = {}
    if not is_step_active(pattern) then
      return
    end
    for x2 = x + 2, x + 128 do
      if ray_en_hit_test(ray_points, x2, y + 1) then
        break
      end
    end
  end}
end

function draw_laser(ray_points)
  for _, p in ipairs(ray_points) do
    pset(p.x, p.y, rnd() > 0.18 and 8 or 2)
  end
end

function ray_en_hit_test(ray_points, x, y)
  local hit_p = not hit_floor and not hit_1way and player_hit(x, y)
  if hit_p then
    hurt_player()
  end
  local hit_floor = fmget(x / 8, y / 8, 0)
  local hit_1way = fmget(x / 8, y / 8, 1)
  if hit_floor or hit_1way or hit_p then
    return true
  else
    add(ray_points, vec2(x, y))
  end
  return false
end

function is_step_active(pattern)
  if pattern == nil then
    return true
  end
  local step = (stat(56) // 44) % #pattern
  return split(pattern, '')[step + 1] ~= "-"
end

function create_v_ray_en(x, y, pattern)
  local ray_points = {}
  return {draw = function()
    draw_laser(ray_points)
  end, update = function()
    ray_points = {}
    if not is_step_active(pattern) then
      return
    end
    for y2 = y + 2, y + 128 do
      if ray_en_hit_test(ray_points, x + 4, y2) then
        break
      end
    end
  end}
end

-->8
-- buttons and doors
function open_doors(color)
  if not opened_doors[color] then
    opened_doors[color] = true
    sfx(33)
  end
end

function register_button(x, y, mx, my, color, tile)
  local bounds = new_bounds(x, y)
  if room_cleared(current_room) then
    mset(mx, my, 16)
  end
  return {update = function()
    if is_grounded() and not opened_doors[color] then
      if btn_check_collision(bounds, color) then
        mset(mx, my, 16)
      end
    end
  end, reset = function()
    if not room_cleared(current_room) then
      mset(mx, my, tile)
    end
  end}
end

function register_door(x, y, mx, my, color, tile)
  local visible = true
  return {update = function()
    if visible and opened_doors[color] then
      visible = false
      mset(mx, my, 0)
    end
    if not visible and opened_doors[color] ~= true then
      visible = true
      mset(mx, my, tile)
    end
  end, reset = function()
    if not is_door_sprite(tile) or not room_cleared(current_room) then
      mset(mx, my, tile)
    end
  end}
end

function register_fake_wall(x, y, mx, my, reset_tile)
  reveal_tile = reveal_tile or 56
  mset(mx, my, 57)
  local bounds = new_bounds(x, y)
  return {update = function()
    draw_fake_wall(bounds)
  end, reset = function()
    mset(mx, my, reset_tile)
  end}
end

function draw_fake_wall(b, reveal_sprite)
  reveal_sprite = reveal_sprite or 56
  local collides = collides6(p_bounds, 2)
  local close_enough = collides and center_dist_squared(p_bounds, b) < 280
  mset(b.x / 8, b.y / 8, close_enough and reveal_sprite or 57)
  return close_enough
end

function btn_check_collision(bounds, color)
  local px = p_bounds.x + p_bounds.w / 2
  local py = p_bounds.y + p_bounds.h
  if px > bounds.x and px < bounds.x + bounds.w and py > bounds.y + 7 and py <= bounds.y + 8 then
    open_doors(color)
    return true
  end
  return false
end

function carrying()
  return p_carried ~= nil
end

function register_spawner(x, y, secundary)
  local pos = vec2(x, y - 4)
  if spawn_pos == nil and not secundary then
    spawn_pos = pos
  end
  return {update = function()
    local p_c = p_center()
    if dist_squared(p_c.x, p_c.y, x + 4, y + 4) < 30 then
      spawn_pos = pos
      if not secundary then
        save_state()
      end
    end
  end}
end

function new_carriable(type, x, y, w, h)
  local b = new_bounds(x, y, w, h)
  local carriable = {bounds = copy_bounds(b), sub_bounds = copy_bounds(b), vel = vec2(), type = type}

  function carriable:carried()
    return p_carried == self
  end

  function carriable:update()
    if self:carried() then
      local p_v_bounds = new_bounds(p_bounds.x - 1, p_bounds.y, 8, p_bounds.h)
      self.bounds.x = p_v_bounds.x + (p_facing == 0 and 0 or 8) - self.bounds.w / 2
      self.bounds.y = p_v_bounds.y + 1
      self.sub_bounds.x = self.bounds.x
      self.sub_bounds.y = self.bounds.y
      if btnp(4) then
        p_carried = nil
        -- avoid getting stuck in walls
        while collides(self.bounds, 0) do
          self.bounds.x = self.bounds.x + ((p_facing == 0 and 1 or -1))
        end
        self.sub_bounds.x = self.bounds.x
      end
    else
      self:apply_gravity()
      self:apply_vel_y()
      self.bounds.x = round(self.sub_bounds.x)
      self.bounds.y = round(self.sub_bounds.y)
      if btnp(4) and not was_carrying then
        local p_c = p_center()
        local self_c = bounds_center(self.bounds)
        if dist_squared(p_c.x, p_c.y, self_c.x, self_c.y) < 30 then
          p_carried = self
        end
      end
    end
  end

  function carriable:apply_gravity()
    if not self:is_grounded() then
      self.vel.y = self.vel.y + (gravity)
    else
      self.vel.y = 0
    end
  end

  function carriable:is_grounded()
    local b = self.sub_bounds
    local x1 = round(b.x) / 8
    local x2 = round(b.x + b.w - 1) / 8
    local y = round(b.y + b.h)
    local my = y / 8
    local edge = y % 8 == 0
    return fmget(x1, my, 0) or fmget(x2, my, 0) or (fmget(x1, my, 1) and edge) or (fmget(x2, my, 1) and edge)
  end

  function carriable:apply_vel_y()
    local step_y = sign(self.vel.y)
    local amt_y = step_y * round(abs(self.vel.y))
    for i = 0, abs(amt_y) do
      if self:check_y(step_y) then
        self.sub_bounds.y = self.sub_bounds.y + (step_y)
        if i == abs(amt_y) then
          local rem_y = self.vel.y - amt_y
          if self:check_y(rem_y) then
            self.sub_bounds.y = self.sub_bounds.y + (rem_y)
          else
            self.sub_bounds.y = round(self.sub_bounds.y)
          end
        end
      else
        -- stopped by floor or ceiling
        self.vel.y = 0
        break
      end
    end
  end

  function carriable:check_y(offset_y)
    return not collides(translated(self.sub_bounds, 0, offset_y), 0) and not (self.vel.y > 0 and self:is_grounded())
  end

  return carriable
end

function register_block(x, y, color, tile)
  mset(x / 8, y / 8, 0)
  -- prevent from being instantiated twice
  if carrying() and p_carried.type == "block" and p_carried.color == color then
    return {reset = function()
      mset(x / 8, y / 8, 48)
    end}
  end
  local block = new_carriable("block", x + 1, y + 2, 6, 6)
  block.color = color

  function block:draw()
    spr(tile, self.bounds.x, self.bounds.y)
  end

  function block:reset()
    mset(x / 8, y / 8, tile)
  end

  return block
end

function register_receptacle(x, y, color)
  local b = new_bounds(x + 2, y + 6, 4, 2)
  local receptacle = {update = function()
    for _, obj in ipairs(room_objects) do
      if obj.type == "block" then
        if obj.color == color then
          local collides = rect_rect_col(obj.bounds, b)
          if not opened_doors[color] and collides then
            open_doors(color)
          elseif opened_doors[color] and not collides then
            opened_doors[color] = false
            sfx(35)
          end
        end
      end
    end
  end}
  return receptacle
end

function card_collected(room)
  return collected_cards[room_index(room.x, room.y)]
end

function collect_card(room)
  if not card_collected(room) then
    collected_cards[room_index(room.x, room.y)] = true
    timers.draw_card_counter = 60
  end
end

function card_count()
  local sum = 0
  for _, b in pairs(collected_cards) do
    if b then
      sum = sum + (1)
    end
  end
  return sum
end

function draw_card(x, y)
  if card_collected(current_room) then
    return
  end
  local t = (room_frames // 2) % 30
  local current_sprite = 40 + (t < 4 and t or 0)
  spr(current_sprite, x, y)
  spr(current_sprite, x, y)
  spr(current_sprite, x, y)
end

function update_card(bounds)
  if card_collected(current_room) then
    return
  end
  if rect_rect_col(p_bounds, bounds) then
    collect_card(current_room)
    sfx(32)
  end
end

function over_breakable_only()
  local x1, x2, y = round(p_bounds.x) / 8, round(p_bounds.x + p_bounds.w - 1) / 8, round(p_bounds.y + p_bounds.h) / 8
  return mget(x1, y) ~= 2 and mget(x2, y) ~= 2 and mget(x1, y) ~= 3 and mget(x2, y) ~= 3
end

dialog_data = {[7] = {yellow = "this is the garden|stay as long as you want", red = "this whole place|it's not so bad after all", blue = "i like this place|the sun comes in",}, [11] = {purple = "you can keep the lamp|i'm staying here"}, [19] = {yellow = "this building?|it was a factory|before the kaboom||now we're trapped|under the debris"}, [24] = {spider = "it's you again|how long did i sleep?|feels like an eternity"}, [26] = {blue = "you've made it|to the warp zone", red = "beyond this door|there's only void",}, [15] = {blue = "you came here|to get repaired?|that's what we do"}}

function has_rank(n)
  for room_idx, collected in pairs(collected_cards) do
    if collected and card_ranks[room_idx] == n then
      return true
    end
  end
  return false
end

function obfuscate(text)
  local output = ""
  for _, c in ipairs(split(text, "")) do
    if (c == " ") or (c == "!") or (c == "?") then
      output = output .. c
    else
      local o = ord(c) % total_cards
      output = output .. (has_rank(o) and c or "*")
    end
  end
  return output
end

function register_talker(x, y, name)
  local talker = {bounds = new_bounds(x, y), counter = 0, dialog_text = "", dialog_index = 0, name = name,}

  function talker:next_dialog()
    local room_dialogs = dialog_data[room_index(current_room.x, current_room.y)]
    local npc_dials = room_dialogs ~= nil and room_dialogs[self.name]
    local dials = npc_dials ~= nil and split(npc_dials, "|") or nil
    if dials ~= nil then
      self.dialog_index = self.dialog_index + (1)
      local txt = obfuscate(dials[self.dialog_index])
      self.dialog_index = self.dialog_index % (#dials + 1)
      return txt
    end
  end

  function talker:update()
    local d = center_dist_squared(self.bounds, p_bounds)
    if self.showing_dialog then
      self.counter = self.counter + (1)
      if d > 800 or self.counter > 60 then
        self.showing_dialog = false
        talking_npc = nil
        self.counter = 0
      end
    elseif talking_npc == nil and d < 500 then
      self.showing_dialog = true
      talking_npc = name
      self.dialog_text = self:next_dialog()
      self.counter = 0
    end
  end

  function talker:draw_dialog()
    if self.showing_dialog and self.dialog_text ~= nil then
      local x0 = x + 4 - #self.dialog_text * 2
      local rx1 = current_room.x * 128 + 4
      local rx2 = ((current_room.x * 128) + 124) - (#self.dialog_text * 4)
      x0 = max(rx1, min(x0, rx2))
      add(dialogs, {text = self.dialog_text, x = x0, y = y - 15, counter = self.counter})
    end
  end

  function talker:draw()
    self:draw_dialog()
  end

  return talker
end

eye_positions = {purple = {vec2(5, 1)}, red = {vec2(4, 1), vec2(2, 1)}, blue = {vec2(5, 0)}, yellow = {vec2(4, 0), vec2(2, 0)},}

function register_npc(x, y, name)
  local npc = register_talker(x, y, name)
  local eye_offset, eye_cycle = rnd(600) // 1, 300 + rnd(300) // 1

  function npc:draw()
    self:draw_dialog()
    if (room_frames + eye_offset) % eye_cycle < 3 then
      for _, pos in ipairs(eye_positions[name]) do
        pset(x + pos.x, y + pos.y, 5)
      end
    end
  end

  return npc
end

function register_unlock_y(y)
  if not main_menu then
    y_to_unlock = y
  end
end

function register_unlock_x(x)
  if y_to_unlock ~= nil then
    clear_room(vec2(x, y_to_unlock))
  end
end

function register_teleporter(x, y)
  local b = new_bounds(x, y)
  teleporter_index = teleporter_index + (1)
  local index = teleporter_index
  local collides = false
  local teleporting = 0
  local dest_x = index == 1 and 0 or 3
  local dest_y = index == 1 and 0 or (index == 2 and 1 or 2)
  return {update = function()
    collides = center_dist_squared(b, p_bounds) < 30
    if teleporting == 0 then
      if collides and btnp(4) then
        teleporting = 40
        sfx(36)
      end
    else
      teleporting = teleporting - (1)
      if (teleporting > 25 and not btn(4)) or not collides then
        teleporting = 0
      elseif teleporting == 25 then
        sfx(37)
      elseif teleporting == 0 then
        -- do teleport
        spawn_pos = nil
        cam_x = -1
        cam_y = -1
        load_room(dest_x, dest_y)
        respawn_p()
      end
    end
  end, draw = function()
    if collides then
      if teleporting > 0 then
        for bx = x, x + 7 do
          if rnd() > teleporting / 60 then
            pset(bx, y + 7, 15)
          end
          if rnd() > teleporting / 30 then
            line(bx, y + 6, bx, y - rnd(45 - teleporting), 6)
          end
        end
      end
    end
  end, draw_over = function()
    if collides then
      if teleporting > 0 then
        for bx = x, x + 7 do
          if (rnd() > teleporting / 20) then
            line(bx, y + 6, bx, y - rnd(45 - teleporting), rnd() > 0.3 and 7 or 15)
          end
        end
      end
      print(is_step_active("xxxx----") and split("a1,b4,c4")[index] or "4", x + 1, y - 8, 3)
    end
    if teleporting > 0 and teleporting <= 25 then
      local rx, ry = 256, 384 + (teleporting - 10) * 25
      timers.room_freeze = 30
      rectfill(rx, ry, rx + 128, 512, 0)
    end
  end}
end

no_music = true

function menu()
  no_music = not no_music
  menuitem(1, "music " .. (no_music and "off" or "on"), function()
    return menu()
  end)
  music(no_music and 63 or 0, 500, 5)
  return true
end

menu()

__gfx__
0000000000000000111111111111111100000000000060a6000000005a55a5a500ddddd000ddddd000ddddd070ddddd000ddddd00ddddd000111111001111110
00000000000bb00011111111111111110000000000006a96000000005a5a55a50dde555d0dde555d0dde555d7dde555d0dde555ddde555d01111111111111111
00700700000bb00011111111101010100000000000006986000000005a55a5a50dee575d0dee575d0dee575d0dee575d0dee575ddee575d01111111111501111
00077000000bb00011111111010101010000000006605555000000005a5a55a50d55555d0d55555d0d55555d0d55555d0d55555dd55555d01100001111000051
00077000000bb00011111111101010100700070060a66a06000000005a55a5a5ddd555d0ddd555d0ddd555d0ddd555d0ddd555d00d555ddd1000000110000001
007007000bbbbbb01111111101000100060006006a9669a6000000005a5a55a500dd7d0000dd7d0000dd7d0000dd7d0000dd7d0000d7dd001000000150010001
0000000000bbbb0011111111000100017670767068966886000000005a55a5a50ddd5dd00ddd5dd00ddd5dd55ddd5dd05ddd5d0000d5ddd50000000000000000
00000000000bb000111111110000000065676567555555550aaaaaa05a5a55a55dd55dd55dd55dd55dd55dd00dd55dd50dd5dd0000d55dd00000000010000000
000000000001110000022200220000006655660000000000000000005e55e5e5005555000055550000555500005555000555dd0000dd55500111111001111110
000000000001e10000028200280000006887760000000000000000005e5e55e5004004000004400000400400004004004555d000000d55541111111111011111
000000000000000000000000220000005888750000000000000000005e55e5e50000000000000000000000000000000000000000000000001110101101001001
000000000000000000000000000000005888850000000000000000005e5e55e50000000000000000000000000000000000000000000000001500001101050010
000000000000000000000000000000006888860000000000000000005e55e5e50000000000000000000000000000000000000000000000001000050100000505
000000000000000000000000000000006655660000000000000000005e5e55e50000000000000000000000000000000000000000000000000000000010100010
00000000000000000000000000000000000000000d0000d0000000005e55e5e50000000000000000000000000000000000000000000000001005000000000005
0555555000000000000000000000000000000000dd6666dd0eeeeee05e5e55e50000000000000000000000000000000000000000000000000000000550000000
00000000111111166111111161111116555555551588885101010101010101010000000000000000000000000000000000000000000000000511151000151510
000000001111111616111111161111168888888811588511101bb01010dddd1000dddd0000d7dd0000ddd70000dddd0000000000000000001050000110000001
000b00001111116161111111611111615555555511155111010bb10101d66d0100d66d0000766d0000d67d0000d66d0000000000000000000000010000000000
000b00001111111611111111111111168585858511111111101bb01010d66d1000d66d0000d66d0000d76d0000d66d0000000000000000000000050000000000
000b00001111111161111111611111115858585811111111010bb10101d66d0100d66d0000d66d0000766d0000d6670000000000000000000100005000000000
0b0b0011111116161111111611111655555555111111111bbbbbb0105550100055500000555000005550000055700000000000000000000001000000000000
00bbb000111111616111111161111161888888881111111101bbbb01010101010000000000000000000000000000000000ccccc0099999000050000000000000
000b00001111111661111111611111165555555511111111101bb01010101010000000000000000000000000000000000cc9555c955555900000005000000000
665566000000000015cccc5122000000220000000002220000022200bbbbbbbb010101011111111101010101010101010c99575c957575905555555555555555
6cc7760000000000115cc51128000000280000000002820000028200b000000b101010101111111110101010101010100c55555c95555590aaaaaaaaeeeeeeee
5ccc7500000000001115511122000000220000000000000000000000b000000b010101011111111101010101010101010cc555c0095559905555555555555555
5cccc500000000001111111100000000000000000000000000000000b000000b1010101011111111101010101010101000cccc0000999900a5a5a5a5e5e5e5e5
6cccc600000000001111111100000000000000000000000000000000b000000b010101011111111101010101010101010cccccc0099999905a5a5a5a5e5e5e5e
66556600000000001111111100000000000000000000000000000000b000000b101010101111111110101010101010105cccccc5544444455555555555555555
000000000d0000d011111111bbbb00000000bbbbbbbb00000000bbbbb000000b010101011111111101010101010101010055550000555500aaaaaaaaeeeeeeee
00000000dd6666dd111111110000bbbbbbbb00000000bbbbbbbb0000bbbbbbbb10101010111111111aaaaaa01555555000400400004004005555555555555555
00ddd0000000000dd0000000d000000d00f300006666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00d0d0000000000d0dd0000d0dd00dd003000000666666660000bb00000bbb000000bbb0000bbb00000000000000000000000000000000000000000000000000
00d00d0dddddddd0000dd0d0000dd0000f00000066666666000b00b0000b00b0000b0000000b00b0000000000000000000000000000000000000000000000000
0d0000d000000d0000000d0000d000003000000066666666000b00b0000bbb00000b0000000b00b0000000000055000050000000000000000111110001111100
dd000dd0ddd0d000000000d00d0000003000000066666666000bbbb0000b00b0000b0000000b00b0000000500002225540000000000000001100011011010110
d000d00d000d00000000000dd00000000000000066666666000b00b0000b00b0000b0000000b00b0000005050525555540500000000000001101011011101110
000d00d0d0d0000000000000000000000000000066666666000b00b0000bbb000000bbb0000bbb00000005002555522555440000000000001100011011010110
ddd00d000d0000000000000000000000000000006666666600000000000000000000000000000000000005025555555255220000222000000111110001111100
000dddddd00000003111131111111131111111116666666600000000000000000000000000000000000050055555555555255202554200000022222008888800
00d00d0d000000001f111f111111111311111113c6c6c6c6000b000000bb00000bbb00000b00b0000000505555555555555555255e8520000226555285555580
00d000d0000000001131311111111111f31113f1cccccccc00bb00000b00b0000000b0000b00b00000050055555555522252252582e820000266575285757580
000d0d00000000001113111111111111113f3111c6c6c6c6000b00000000b000000b00000b00b000000505553555355255352525588520000225552008555880
000d0d00000000001113113311111111331111116c6c6c6c000b0000000b00000000b0000bbbb000005000533555355555322222555200000022220000888800
d000d0000000000011131311111111f311111111cccccccc000b000000b000000000b0000000b000005000035555555555525252232523000222222008888880
0d0d000000000000111f31111111131111111111c6c6c6c600bbb0000bbbb0000bbb00000000b000005000050000500500500305300033005222222554444445
00d0000000000000113111111111111111111111cccccccc00000000000000000000000000000000005000050000500050305000530000000055454001515500
0d00000055555555113111113311111100030300cccccccc00000000000000000000000000000000000000005542000055420000554200000000000000000000
d0000000cccccccc11311111113111330000f000cccccccc0bbbb00000bbb0000bbbb00000bb00000000000058e5200052e52000582520000000000000000000
0000000055555555111f11111113f31100000303cccccccc0b0000000b0000000000b0000b00b00000011000e2822000828e200082e820000009000000009000
00000000c5c5c5c5111311111111311100000030cccccccc0bbb00000bbb0000000b000000bb00000001100058e52000588520005e852000009a90000009a900
000000005c5c5c5c1113f1111113311100000030cccccccc0000b0000b00b00000b000000b00b000000110005552000055520000555200000309300000309000
000000005555555511113111113f1111000000f0cccccccc0000b0000b00b00000b000000b00b0000111111023252300232523002325000000f0f0030030f030
00000000cccccccc1111331113311111000000f3cccccccc0bbb000000bb000000b0000000bb00000011110030003300300033002002300030f0303030f03f30
000000005555555511111ff11f11111100000300cccccccc0000000000000000000000000000000000011000530000005300000033033000033333f30333333f
007777005c55c5c5111111311311111100000300cccccccc00000000000000000000000000000000111111110000000033333333000000000000000000000000
07dddd705c5c55c5111111131f11111100000300c0c0c0c00000000000000000000000000000000011111111000b000033333333000000000000000000000000
07d66d705c55c5c511111113f3111111000000f0cccccccc0b0000b00b000bb00b000bb00b000b0b1b111bb1b00000b033333333000000000090000000900000
07d66d705c5c55c51111111331111111000000300c0c0c0cbbb00bb0bbb0000bbbb0000bbbb00b0bbbb1111b000b0000333333333f033f0f09a9008009a90800
07d66d705c55c5c51111113f111111110000003f000000000b0000b00b0000b00b0000b00b000bbb1b1111b1000b00b03333333303f303f30090089800908980
075557005c5c55c5111111311111111100000003c0c0c0c00b0000b00b000b000b00000b0b00000b1b11111bb000000033333333655555560f3f0080f03f0800
007770005c55c5c51111133111111111000000030000000000bb0bbb00bb0bbb00bb0bb000bb000b11bb1bb1000000003333333365555556f0333030f03330f0
000000005c5c55c51111131111111111000000030c0c0c0c0000000000000000000000000000000011111111555555553333333365555556f3f333f3f33f33f3
20102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020302020202020202020202020202020
20002020201204140000323400000030300084651204140000000000000024202020340000002000242005530071700000000000000000000000000000000020
20838383830053006300530000000020202020000000002000000000000000202000000000000000000000000000002020000070000000009700000053632120
20002020201205150000320000000000000000001205150000000000000000202020000061002000602006000071700010000000000000000000000000000020
20838383830000000000000000000020204370000060002000008466000000202000000000000084760000000000002020000070000000000000000000008220
2000302020120600008232000000000210000000120697000000000000000020201230303030323030323000302220202020000000000084850097000000d220
20728383830000000000000000030020202012000022202043008700000000202003000000000067000000000000132020202020300000000000000000000020
2000002012340000002212000000302020200000120000002020201200004020201200000000323300320000002220202020200000000000000000000050d320
20202020203000000030003020202020123030300022202000000000000300202020200000000000000000000020232020000000000000000000000000600020
2000002012000000003032000000002020120000303000002200005300002220201243000000320000320000e022202020722020000000003000000020202020
2020202020000084950000003030302012000000002220203300000030202020203030e0e0000000000000e0e0303020200000000000e0e00000e0e030303020
20000020120000970000320000000022201200000000000022820000000022202012000000003200003200000022202020838320200000000000000000202020
20202020200000008700000000000020120000000017000000000000000000202000000000000000000000000000008330000000000000000000000000000020
20000020120000000000303000000022201200000000000022203000000022202012008475003200e03200000022202020838320202000000000000000000020
20303030203000300000000000000020203300000017000000000013000000202031000000e0e00000e0e000000000830000000000000000e0e0000000000020
2000002012000074650000000000002220120000400000302212000000402220201200e097003200003200000022202020208320202083000000000000000020
20000000170000000000000000000020202020202020000000002023202020202000000000000000000000000000302020300000e0e000000000000040000022
20000020120000000000000000000022208330003200000020120000003022202020330000003243003200000030202020838320208383200000000000000020
200060001700000000300000001300202030303030303000003030303020202020000000000000e0e00000000000002012000000000000000000000022000022
20000020201200000000223000000020838300003200000022120000000022202020000000303030003030000000832020838320838383202000000000000020
20202020203000000000003020232020200000820000000000000000002020202000000000000000000000000000002212000000000000004000000022000022
20000020201200000000220000000020838300003200000022120000000022202020000000000000000000000000838320832083838320202020000000000020
202020202000000000000000202020202043000000000000000000000020212020310000e0e0e00000e000000000002212000000000000002200000032003020
20000020201200000000220000000020838300402000300022120000000030303030000000000000000000000000838320838383832020202020200000000070
30303030300000300000000030703030202020202030303030303000002016202000000000000000000000007016162220304000400000002200004032000022
20000030303000000000300000000020832020202040404020204040400000020010000000303030303030300030838320838383838383838383202000000070
0000000000000000000000000070000000000000000000000000000000000070000000000000e0e0e0e000007000002220003000220040002294962022000022
200000100000000000000000000000208383202020202020202020202020202020202040404040404040404040008372202083838383838383a3202020000070
1000000000000000000000000070000210000000000000000000000000000070100000002040404040404040700000202000000020402040204040202240a622
20202020202020202020202020202020628320202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020a6a62020202020202020322020202020201020
20202020202020202020202020202020203020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202030302020202020202020202020202020203020
20202020202020202020202020202020201000970000220414000053006324202000000000000000000000000067002020310067001100001100002072838320
20000000000000000000000000000020202020202020202020202020202072202000000067848600000000000000002020000000000000000000000017000020
202020202020202020202020202020202000000000002205150000004000002020000000c7c7c7c7c7c7c7c70000002020200000000000000000002083838320
20000000000000000000000000000020202020310067005300630000003083202000000000000000000000000010002020130000000000000000000017003020
202020203400000000779475242020202030201200003206000000002200002020b70000c7c7c7c7c7c7c7c70000000000170094660000000000002083838320
2000000000000000000000000000002020202000000000000000000000008320200000e0e0e0e0e0e0e0e0e0e0202020202320730000000000000020e3e3e320
2020203000000000000000000030302020e3203400003200004000002200002020203000c7c7c7c7c7c7c7c70000001000170000000000000000000000000022
20000000000000000000000000006120202020e0e0e0e0202020e0e0e0e020202000003100000000000000000000002020303000000000000000733030303020
2004140000000000000000000000000070306300400053000032000022000020200000000000000000000000949530202020200000e00000e000000000000020
2030303100e0e0e0e0e0000000202020202020330000002020203300000020202000000000000000000000000000002220000000000073730000000000000020
2005000000a4b4c4d40000000000001070000000120000000032000032006020200000000000000000c200000000002020303000000000000000000000000020
20000000000000400000000000008220202020000000002020200000000020201200000000000000000000000000002220000000000000000000000000737320
2006000000a5b5c5d5000000002020202030000032000000303200003000202020003000000000b700c300000000002020000000000000000000000000000020
20000000000000320000000000000020202020e0e0e0e0202020e0e0e0e020201200000000000000000000000000602220000000737300000000007373000020
200000303030303030303030202020202000000032404040403200000000202012000000303030303030303000000022204300e0e0e00000000000e0e0000020
2000e0e0e00000320094760040000020202043000000002020204300000030201233e0e0e0e0e0e0e0e0e0e0e0e0202220730000000000000000000000000020
2000004040404040404040202020202012000000303020303030000000002020120000000000000000d200000000002220000000000000000000000000000320
20000000000000300000670032000020202000000000002020200000000000202040404040404000004040404040402220737300000000007300000000000020
20838320202020202020202020202020120000004000530000000040300020201200000000e500b700d3000000000022203300000000e0e0e0e000000000e020
206000000000000000000000220000202020e0e0e0e0e0202020e0e0e0e0e0202030303030303000003030303030302020000000000000000000000000000020
20208383832020202020202020202020204000003200000000000020004020201200000030303030303030300000303070000000000000000000000000000030
202020e0e0e000000040000030000000303300000000002020203300000000307000000000000000000000000000008300000000000000000000000000000020
20208383838383838383832020202020202000002000000040000022002020201200000000000000000000000000001070021300000000000000e0e0e0000000
00707100000000000022000000000010020000000000002020200000948600107000000000000000000000000000008310500000730073000000730000000320
20202083838383838383838320202020202000003000000020000022402020201200000000000030000000000000002020202320e0e0e0e00000000000000010
0270710000000000002200e0e0e020202020e0e0e0e0e0303030e0e0e0e0202020303030e0e0e0e0e0e0e0737373302020203073730000000000730073302020
202020202083838383728383202020202020000000000000200000202020202020000051f5000000000000000000202020404040404040404040404040202020
202020e0e00000000030000000000020204040404040404040404040404040202040404040404040404040404040402020770000000000000000000000000020
20202020202020202020202020202020202020202020202020202020202020202042425220202020202020202020202020202020202020202020202020202020
20204040404040404040404040404020202020202020202020202020202020202020202020202020202020202020202020404040404040404040404040404020
__map__
0201000202020202020202020252535452540202020202020202020202020202025202020202020202020202020253540202020202020202020202020262535402020202020202020202027252625354020202020202020202020202020202020202020202020202020202020202020202527254555545454545555502525472
0200000000000000110000000000000000000000760002020303030203030302024400003500000000000036000000020200000000350012003600000035646302020202020200000000000000116462020000110000000000000000110000020202130035000036003500003600020202625275656555555555656575620252
0200000000000000000000000000002001000000000000023300000300000003030000000000000000000000002800020200000000000000000000000000740202020000110000000000000000007454020600000000466600000000000000020212000000000000000000000000120202524400757565656565757500725462
0200000000007600000000000003030202030046560000023802000000000020010000000000000000000000000000020200000000000000000000000000000202020076000000000006000000000002020300000000000000000000000000020200000000000000000000000000000202620000000075757575000000740272
0200000000000000000000000000000202000000000000633852000000030302020200000000000000000000000000020300007600020303030202030000000202020000000000000202020000000002020000000000035254620300000000020200060000000000000000000028000202030000000000000000000000000252
0200000000000000000000000000000202000000000000522763000000000002020202030000030300000000000000070000000002026e007e0202000000000202020000000000000203020300000002020000030000006272440000000000020200020000000000000000000000000202000000002c0000000000006e5f0202
020000000000000000000000000303020202020000000073727303033400000202330000000000000003030000002007010000020202020202020202020000020202330000000303022802000000000202000000000000724400000000030002020000000003000003000000000000020200006e7d3c7d000000000002020202
02000000000000000000000000000002020202330003030252020000000000020200000000760000000000000000725402020239020233000000000003030302020200000000465902380200000000020200000300000052330000000000000202130000000000000000000003130002022800020202027e0000000002020202
0200004f0000006a000000000000000202020200000000026202000000000002020000000000000000000000000064540202020202020046580000000000000202020000000000000238383400000302020000000000006252540202000003020200000078000000000000000000000202000002020303030000000303020252
02000000000000000000000000030302020203000000000202023300030303020234000003465700000000000300740202020303020200000000000000000302020200000303000002383800000000020200000300000053440000070000000202000000000000000000000000000002027e0003030000004668000000036262
02000000000202030303000000000002020300000000520202020000000000020200000000000000000000000000000202027e6e02020000000000000000000202000000000000000202380000000002020076000003020200000007000000020200000000000000000000000300000202030000760000000000000000000352
720000000003021400000000000000020200000000006263020200000000000202060000000000000000000000000002020303030202000000030300000000020200000000000202020202020203000202000000000002020000020202020202020000000000000000000000000000020200000000000000002d000300000062
52020203000002020202020000020202023400000303727302020303033400520202020303030000030300000303000263130000030303031300000000020202030303000000000000000000000000020203030000000203030303350303030202000000000000000200000003000002020000000000005e7d3d000000000052
6200000000000000000000000000000202000000000000003500000000000062020000000000000000000000000000025228000000000000000000000000000000000000000000000000000000000007000000000000023400000000000000020213000003130000031300000000030738000000007e020202020200007d7d62
720404040404040404040404040404020200000000000000000000000000007202040404040404040404040404040402620000000000000000000000000000200100000000000000000000000000200701000000000002000000000000006a020200000000000000010000000000000738017e006e020202020202027e020272
5202020202020202020202020202020202020202020202020202025354635452020202020202020202020202020202027254020404020202020202020202020202020202020202020202020202020202020202020202020202020202020220020202020202020202030202020202020202020202020202020202020202020252
0202020202020202020202020202020213000036000000350000003600000002020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020203020202020202020202383802020202020202020202020202020202020202020202
023838383838383838383838383838380000000000000000000000000000000202373737373700000000000077000000070000000000003737000000000000020200000000000000110000000000000202000000350000000000000000000102027a020202020202383802020202020208003600120035001200360012003500
0238383838383838383838383838383820000000000000000000000000000002023737370000000000475900000005010720000000000000370077000000000202000000770000000000476700000002022800000000466700760000000000020238383838380202023838380202020202023802380238023802380238023802
0238383802020202020202020202020202020202020202020202020200000002023737000000000000000000000003020203373737000000370000000000060202000000000000000000000000000002020300000000000000000000030302023838383838383802023838383802020208000000000000000000000000000000
0238020202023838383838383838383800000000000000000000003700000002023737000000000000000000000000020200000000000000370000000000370202000000000000000000000000000002020000000000000000000000000000383838383838383838020238383838020202023802380238023802380238023802
0238020238383838383838383838383820050000000000000000003737000002023700000000373700003737373737020200000000000037000037370000000202000000000600000000000000000002020000030300000000000000000000262638383838383838380202383838020208000000000000000000000000000000
0238023838383838020202020202020202030000003700000000000000000002023400000000000000000000000000020200373737373700000037000000000202000000003700000000000000000002023400000000000000000334000303020202020202023838383802023838020202020202020202020202020202020202
0238020000000000370000475700770202330000000000000000000000000002020000000000000037370000000000020200000000000000000037000000000202000000000000000000000000000002020000000003000000000000000000020238383802020238383838383838020202021300000000000213000000000002
02380200000037370000000000000002020202020202020202020202020202020237373700000000000000003700000202000000000000000037370000373702020000370000000000000000004e0002020000000000000000000000000000020238383838380202383838383802020202021300000000000213000000000002
023802330000000000000000000000020000007700000000000000000000000002373737373700000000000037000002023700000000000037373700000000020200000000000000000000000000000202330000000000030333000000030302023838383838383838383838020202020200007c7c7c00000000007c7c7c0002
023802370000000000000000000000030000000000000047580000000000000002000000000037373737373737030302020000000000373700003700000000020200000000000000000000000005000202000000000000000000000000000002023838383838383838383802020202020278007c7c7c00000000007c7c7c2802
023802000000000000000000000000000000000000000000000000000000000003330000000000000000000000000002020000000000000000000037000000020202030300000000000000000303030202000000030300000000000000000002023838020202020202020202383838020248690000002c000d00000000000002
023802003737370000000000000005012000000000000000000000000000050120000037370000000000000000000002020000370000000047660000000000000700000000000000000000000000000007000000000000000000000000020202023838383838020202020238383827020200000000003c0018005f0000000002
0238023400000000000000000000030202030333000000000000000000000302020202373737370000003737373737020200000000000000000000000000000107200000000000000000000000000001072000000000030000060003030302020202383838383838383838383802020202000000000002020202020000000002
0238020000000037373737370000000000000000003737000000373700000000020202373737370000373737373737020200000000005e000500000000000202020202023737370000003737370202020202020204040404040204040404020202020202023838383838383802020202026a0000020202020202020202000002
0238020404040404040404040404040404040404040404040404040404040404020202020202020202020202020202020202020202020202020202020202020202040404040404040404040404040402020202020202020202020202020202020202020202020202020202020202020202010202020202020202020202020202
__gff__
0000010200000001000000000000020200000000000000010000000000000202000911190101040400000000000002020000010000000001040404040000010100000000000000000000000000000000000001010100000000000000000080000001010100000000000000000000000000010101000000000000010000000000
__sfx__
9404010222053001501f600136000e6000760001600006000f6001160025000220001f00014000110002600000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a13000034655046050060501605006050060500605006050060500605006050160504605096050c6050e60500605006050060500605006050060500605006050060500605006050060500605006050060500605
4a0100003460027600346400060027660156000c5000a5000650004500035000d6000c6000c6000c6000b6000a60009600076000660004600036000260002600006000060000600124000d4000a4000840000000
210205202004121041220412304124041240212402124032240322404224042240422404224042240422405224052240522405224052240522405224052240522405224052240522405224052240522403224022
960b000118055040052b0052100519005000050000524005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
d60802001837224375233021e3021b302173021530200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302003020030200302
90070000180620c13418132180340c012000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
c31f000004612026120661203612076120361209612016120a612016110861202612086120561109612056110a61205612096110a612066110b612056110b612046110c612026110d612036110d612056110e611
191600000e8720e87224a320e862209620c8020e8620e8520e8220e8121fa3224a22189620c80211802118020e8620e86224a320e862209620c8020e8620e8521fa220e8511fa1224a22189620c8021fa121a832
c7cf00191e6141e6101e6152361423610236152ff2032f2525f1027f2028f101e6141e6101e6152361423610236152161421610216152bf222df222af3227f322af502af5028f5026f5024f5023f5024f5000600
1144002029f102bf102bf1228f1029f102bf122bf122bf1129f102bf102bf2228f2029f202bf2029f112bf112bf112bf102bf1228f1629f162bf102bf122bf2229f202bf202bf2228f1129f102bf1229f122bf10
191600001d8621d86224a3211852209521fa1211852118521fa1234a141fa1224a22189620c80234a140e8521f8621f85224a22138522095224a1213852138521fa12000001fa1224a2218952158521fa1218952
d116002014f1214f1214f1214f1214f2214f2214f2214f2214f2214f2214f2214f2214f2214f2414f2214f2214f2214f2214f2213f2213f2213f2213f2216f2214f2214f2214f1214f1214f1214f1214f1214f12
c52c00080cb040cb140cb040cb140cb040cb240cb040cb240000000000000000000018b1418b1518b000000016b1216b1216b1216b1222b2222b2222b3222b3222b15000000000000000000000000022b1422b25
011600000c8500b8500a8500a8500a85000000000000c92412950000000a8500a8500a8000a8500a8500a8500c8500b8000a8000a8000a80000000000000c9241295000000000000000000000000000000000000
050200003765500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
491700010c05000000000000400000000040000e0000e00010000050000000000000000000000000000040000e000040000e0000e000100000400000000040000000000000000000000000000000000000000000
041718000c07327703277531367300003000030c0730000300003136731d753000030c07300003277031367300003277530c073000030c073136731d753187530000000000000000000000000000000000000000
d71600003fa253fa053fa153fa233fa253fa053fa053fa153fa053ca253fa253fa0433a143fa253fa053ca153fa253fa053fa153fa233fa253fa053fa053fa153fa053ca253fa253fa0433a143fa253fa053ca15
911600080ec7512c0515c650ec000ec7515c0015c6500c0515c0509c0500c0500c0500c0500c0500c0504c050ec0509c0513c0510c0513c0504c0500c0504c0500c0500c0500c0500c0500c0500c0500c0500c05
c11600200ec050ec3412c0515c340ec000ec3415c0015c340ec050ec3412c0515c340ec000ec3415c0015c340ec050ec3412c0515c340ec000ec3415c0015c340ec050ec3412c0515c340ec000ec3415c0015c34
c116002024d4524d1524d4524d1224d351ce1226d3523d351ce1223d351ce1223d3523d1521d351fd3523d1421d3518e0215e141ce320ee4418e3215e241ce140ee0418e0415e141ce140ee1418e2415e241ce14
c116000024d1400d0424d2400d0424d3400d0424d2400d0426d2423d3400d0423d2400d0423d2400d0421d241fd341ad0421d2400d0421d1400d0400d0400d0400d0400d0400d0400d0400d0400d0400d0400d04
911600000ec3512c0515c350ec000ec3515c0015c3500c050ec3512c0515c350ec000ec3515c0015c3500c050ec3521c1515c350ec000ec3515c0015c3500c050ec3512c0515c350ec000ec3515c0015c3500c05
6116000024d2224d1224d2224d1224d2224d1226d2223d2223d1223d2223d1223d2223d1221d221fd2223d1521d2221d1215c120e5020ec121250215c120e5020ec1218e1215e241ce220ee2418e3215e341ce24
6116000024d4424d141cd221cd1418d2224d1226d2423d2223d121fd221cd1415d2213d1221d241fd2423d1521d2221d1215c1221d1421c1221d0415c1221d140ec1215b0415c1215b140ec1215b1415c1215b14
911600200ec651ac2215c5521c120ec651ac2215c5534a141ac6526c2215c5521c120ec651ac2215c5521c120ec651ac2215c5521c120ec651ac2215c5521c1232c6526c2221c552dc120ec651ac2215c5521c12
190b00200e8620e8620e8620e86224a3224a3230a1400004209422094230a140000434a140000430a1435a1439a140000430a140000434a140000424a3200004209422094230a1435a1434a1435a141b9421b942
0116000018b1418b1018b1018b2218b0418b1418b1018b2234a1418b1418b2018b2215b0415b1415b1015b1218b1418b2018b2018b3234a1418b2418b2018b3218b0418b1418b1018b2234a1410b2010b1234a14
960205000e6640d0351105016030170200300400004000040000400004000040100404004090040c0040e00400004000040000400004000040000400004000040000400004000040000400004000040000400004
9404010004635046050060501605006050060500605006050060500105001050110504105091050c1050e10500005000050000500005000050000500005000050000500005000050000500005000050000500005
0001150019620176501665015630116300e5000d5400c5400a54006540045200352012850128501285012840118201681015820148200661004600036000260002600006000060000600124000d4000a40008400
030a09002b055260453003526c2030c4526c2530c1526c1530c1424c0030c0006c0000c0026c0018c0007c000cc000cc000dc000dc001ac000ec000ec000fc001bc0010c0010c0011c0012c001cc0012c0013c00
4e0b05000c634046202b6602164019625006000060024600007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
a60b040039b633a353253431eb031bb0317b0315b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b0300b03
4a050500286651a6100f6301865018635006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
5a06000005c1207c120ac220ac220cc220cc220fc220fc220fc2211c3111c3213c3213c3213c3116c3216c3116c3216c3216c3118c3218c3118c321bc311bc321bc311bc321dc311dc321dc111fc121fc111fc11
a84803000065405665046000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90031500009400b8100b8400f80017810068400b9101080005930059100be5000900059100090005e40009000d8300090003e20009000ce100090000900009000090000900009000090000900009000090000900
900b00000ec300ec3015c3015c301ac301ac30215302dc30325403202026010260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030a0900210551f045160351ac2021c351ac1521c151ac1521c1424c0030c0006c0000c0026c0018c0007c000cc000cc000dc000dc001ac000ec000ec000fc001bc0010c0010c0011c0012c001cc0012c0013c00
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
001600100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 55131455
00 08131455
01 08131556
00 08131856
00 171956
00 08131859
00 08131559
00 171959
00 081a1c5c
00 081a1c5c
00 1a1c67
00 08131556
00 08131856
00 171956
00 1c0d1b5c
00 1c0d1b5c
00 1c1a1b5c
00 1c1a1b5c
00 081a1859
00 081a1859
00 1a1959
00 081a1c5c
00 081a1c5c
00 1a1c5c
00 1a1b0d44
02 1a1b0d44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 090a0c44
03 3f424344
__label__
mmmmmmmm3mmmm3mmmmmmmm3mmmmmmmmm6666666666666666666666666666666666666666666666666666666666666666mmmmmmmm3mmmm3mmmmmmmmmmmmmmmm3m
mmmmmmmmmbmmmbmmmmmmmmm3mmmmmmm3s6s6s6s6s6s6s6s666666666666666666666666666666666s6s6s6s6s6s6s6s6mmmmmmmmmbmmmbmmmmmmmmm3mmmmmmm3
mmmmmmmmmm3m3mmmmmmmmmm3b3mmm3bmssssssssssssssss66666666666666666666666666666666ssssssssssssssssmmmmmmmmmm3m3mmmb3mmm3bmmmmmmmm3
mmmmmmmmmmm3mmmmmmmmmmm3mm3b3mmms6s6s6s6s6s6s6s666666666666666666666666666666666s6s6s6s6s6s6s6s6mmmmmmmmmmm3mmmmmm3b3mmmmmmmmmm3
mmmmmmmmmmm3mm33mmmmmm3b33mmmmmm6s6s6s6s6s6s6s6s666666666666666666666666666666666s6s6s6s6s6s6s6smmmmmmmmmmm3mm3333mmmmmmmmmmmm3b
mmmmmmmmmmm3m3mmmmmmmm3mmmmmmmmmssssssssssssssss66666666666666666666666666666666ssssssssssssssssmmmmmmmmmmm3m3mmmmmmmmmmmmmmmm3m
mmmmmmmmmmmb3mmmmmmmm33mmmmmmmmms6s6s6s6s6s6s6s666666666666666666666666666666666s6s6s6s6s6s6s6s6mmmmmmmmmmmb3mmmmmmmmmmmmmmmm33m
mmmmmmmmmm3mmmmmmmmmm3mmmmmmmmmmssssssssssssssss66666666666666666666666666666666ssssssssssssssssmmmmmmmmmm3mmmmmmmmmmmmmmmmmm3mm
mmmmmmmmmm3mmmmm3mmmm3mmssssssssssssssssssssssss66666666666666666666666666666666ssssssssssssssssssssssssmm3mmmmmmmmmmmmm3mmmm3mm
mmmmmmmmmm3mmmmmmbmmmbmmsgsgsgsgsssssssssssssssss6s6s6s6s6s6s6s6s6s6s6s6s6s6s6s6sssssssssssssssssgsgsgsgmm3mmmmmmmmmmmmmmbmmmbmm
mmmmmmmmmmmbmmmmmm3m3mmmssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssmmmbmmmmmmmmmmmmmm3m3mmm
mmmmmmmmmmm3mmmmmmm3mmmmgsgsgsgssssssssssssssssss6s6s6s6s6s6s6s6s6s6s6s6s6s6s6s6ssssssssssssssssgsgsgsgsmmm3mmmmmmmmmmmmmmm3mmmm
mmmmmmmmmmm3bmmmmmm3mm33ggggggggssssssssssssssss6s6s6s6s6s6s6s6s6s6s6s6s6s6s6s6sssssssssssssssssggggggggmmm3bmmmmmmmmmmmmmm3mm33
mmmmmmmmmmmm3mmmmmm3m3mmsgsgsgsgsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssgsgsgsgmmmm3mmmmmmmmmmmmmm3m3mm
mmmmmmmmmmmm33mmmmmb3mmmggggggggsssssssssssssssss6s6s6s6s6s6s6s6s6s6s6s6s6s6s6s6ssssssssssssssssggggggggmmmm33mmmmmmmmmmmmmb3mmm
mmmmmmmmmmmmmbbmmm3mmmmmgsgsgsgsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssgsgsgsgsmmmmmbbmmmmmmmmmmm3mmmmm
mmmmmmmm3mmmm3mmggb3ggggggggggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggggggmmmmmm3mmmmmmmmmmm3mmmmm
mmmmmmmmmbmmmbmmg3ggggggggggggggsgsgsgsgsgsgsgsgsssssssssssssssssssssssssssssssssgsgsgsgsgsgsgsgggggggggmmmmmmm3mmmmmmm3mm3mmmmm
mmmmmmmmmm3m3mmmgbggggggggggggggssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssggggggggmmmmmmm3b3mmm3bmmmmbmmmm
mmmmmmmmmmm3mmmm3ggggggggggggggggsgsgsgsgsgsgsgsssssssssssssssssssssssssssssssssgsgsgsgsgsgsgsgsggggggggmmmmmmm3mm3b3mmmmmm3mmmm
mmmmmmmmmmm3mm333gggggggggggggggggggggggggggggggssssssssssssssssssssssssssssssssggggggggggggggggggggggggmmmmmm3b33mmmmmmmmm3bmmm
mmmmmmmmmmm3m3mmggggggggggggggggsgsgsgsgsgsgsgsgsssssssssssssssssssssssssssssssssgsgsgsgsgsgsgsgggggggggmmmmmm3mmmmmmmmmmmmm3mmm
mmmmmmmmmmmb3mmmggggggggggggggggggggggggggggggggssssssssssssssssssssssssssssssssggggggggggggggggggggggggmmmmm33mmmmmmmmmmmmm33mm
mmmmmmmmmm3mmmmmgggggggggggggggggsgsgsgsgsgsgsgsssssssssssssssssssssssssssssssssgsgsgsgsgsgsgsgsggggggggmmmmm3mmmmmmmmmmmmmmmbbm
mmmmmmmmmm3mmmmmggggggggggggggggggggggggggggggggssssssssssssssssssssssssssssssssggggggggggggggggggggggggggggg3ggmmmmmmmmmmmmmm3m
mmmmmmmmmm3mmmmmggggggggggggggggggggggggggggggggsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgggggggggggggggggggggggggggggg3ggmmmmmmmmmmmmmmm3
mmmmmmmmmmmbmmmmggggggggggggggggggggggggggggggggssssssssssssssssssssssssssssssssggggggggggggggggggggggggggggggbgmmmmmmmmmmmmmmm3
mmmmmmmmmmm3mmmmgggggggggggggggggggggggggggggggggsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgggggggggggggggggggggggggggggg3gmmmmmmmmmmmmmmm3
mmmmmmmmmmm3bmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg3bmmmmmmmmmmmmmm3b
mmmmmmmmmmmm3mmmggggggggggggggggggggggggggggggggsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgggggggggggggggggggggggggggggggg3mmmmmmmmmmmmmm3m
mmmmmmmmmmmm33mmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg3mmmmmmmmmmmmm33m
mmmmmmmmmmmmmbbmgggggggggggggggggggggggggggggggggsgsgsgsgsgsgsgsgsgsgsgsgsgsgsgsggggggggggggggggggggggggggggggg3mmmmmmmmmmmmm3mm
mmmmmmmmmmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmm3mmmm3mm
mmmmmmmmmmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmbmmmbmm
mmmmmmmmmgmgmgmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmm3m3mmm
mmmmmmmmgmgmgmgmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmm3mmmm
mmmmmmmmmgmgmgmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmm3mm33
mmmmmmmmgmgggmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmm3m3mm
mmmmmmmmgggmgggmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmb3mmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg88888ggmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg8lllll8gmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg9gggg8l7l7l8gmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg9a9gggg8lll88gmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg3g93ggggg8888ggmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggbgbgg3g888888gmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggsssssggggggggggggggggggggggggggggggggggggggggggggggggg3gbg3g3glkkkkkklmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggss9lllsggggggggggggggggggggggggggggggggggggggggggggggggg33333b3gmlmllggmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggs99l7lsggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggslllllsggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggg9gggggggggggggsslllsgggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggggg9a9ggg3bg33bgbggssssgg3bg33bgbggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggg3g93gggg3b3g3b3gssssssgg3b3g3b3ggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggggbgbgg36llllll6lssssssl6llllll6ggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmgggggggggggggggg3gbg3g3g6llllll6ggllllgg6llllll6ggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggg33333b36llllll6ggkggkgg6llllll6ggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgg9gggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmg9a9gg8gggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgg9gg898ggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgb3bgg8gggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
mmmmmmmmggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbg333g3gggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
llllllllllllllllllll777777ll7777llll777777ll777777ll77ll77llllllllll77ll77ll7777llll7777llll777777ll777777llllllllllllllllllllll
llllllllllllllllllll777777gl7777glll777777gl777777gl77gl77glllllllll77gl77gl7777glll7777glll777777gl777777glllllllllllllllllllll
llllllllllllllllllll77gggggllg77gllllggg77gl77gg77gl77gl77glllllllll77gl77gl77gg77ll77gg77ll77gggggl77gg77glllllllllllllllllllll
llllllllllllllllllll77glllllll77glllllll77gl77gl77gl77gl77glllllllll77gl77gl77gl77gl77gl77gl77glllll77gl77glllllllllllllllllllll
llllllllllllllllllll777777llll77glll777777gl777777gllg77lgglllllllll77gl77gl77gl77gl77gl77gl7777llll7777lgglllllllllllllllllllll
llllllllllllllllllll777777glll77glll777777gl777777glll77glllllllllll77gl77gl77gl77gl77gl77gl7777glll7777glllllllllllllllllllllll
lllllllllllllllllllllggg77glll77glll77gggggl77gggggl77lg77llllllllll77gl77gl77gl77gl77gl77gl77ggglll77gg77llllllllllllllllllllll
llllllllllllllllllllllll77glll77glll77glllll77glllll77gl77glllllllll77gl77gl77gl77gl77gl77gl77glllll77gl77glllllllllllllllllllll
llllllllllllllllllll777777gl777777ll777777ll77glllll77gl77gllllllllllg7777gl77gl77gl777777gl777777ll77gl77glllllllllllllllllllll
llllllllllllllllllll777777gl777777gl777777gl77glllll77gl77glllllllllll7777gl77gl77gl777777gl777777gl77gl77glllllllllllllllllllll
lllllllllllllllllllllggggggllggggggllggggggllggllllllggllggllllllllllllggggllggllggllggggggllggggggllggllgglllllllllllllllllllll
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
mmmmmmmmb3b333b3ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmbbmmmmmmbbm
mmmmmmmmmmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmm3mmmm3mm
mmmmmmmmmmmmmmmmggggggggggggggggdddggggggddgdddgdddgdddgggggdddgdgdgggggdddggddgdgdgdgdgdddgdgdgggggggggggggggggmmmmmmmmmbmmmbmm
mmmmmmmmmgmgmgmgggggggggggggggggdgdgggggdgggdgdgdddgdgggggggdgdgdgdgggggdgdgdgggdgdgdgdgdgdgdgdgggggggggggggggggmgmgmgmgmm3m3mmm
mmmmmmmmgmgmgmgmggggggggggggggggdddgggggdgggdddgdgdgddggggggddggdddgggggdddgdgggddggdddgdgdgdddggggggggggggggggggmgmgmgmmmm3mmmm
mmmmmmmmmgmgmgmgggggggggggggggggdgdgggggdgdgdgdgdgdgdgggggggdgdgggdgggggdgggdgggdgdgggdgdgdgggdgggggggggggggggggmgmgmgmgmmm3mm33
mmmmmmmmgmgggmggggggggggggggggggdgdgggggdddgdgdgdgdgdddgggggdddgdddgggggdggggddgdgdgggdgdddgggdggggggggggggggggggmgggmggmmm3m3mm
mmmmmmmmgggmgggmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgggmmmmb3mmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmggggggggggggggggggggggggmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmggggggggggggggggggggggggmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgmgmgmgggggggggggggggggggggggggmmmbmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgmgmgmggggggggggggggggggggggggmmm3mmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgmgmgmgggggggggggggggggggggggggmmm3bmmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgggmggggggggggggggggggggggggggmmmm3mmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg99999gggggggggggggmgggmggggggggggggggggggggggggmmmm33mm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg9lllll9gggggggggggggggggggggggggggggggggggggggggmmmmmbbm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggggggggg22222ggggggggg9l7l7l9ggggggggggggggggggggggggggggggggggggggggg3mmmm3mm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggglllllllllllllllllllllllllll9gggggggggggggggggggggggggggggggggggggggggmbmmmbmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggggglllllllllllllllllllllllllg99gggggggggggggggggggggggggggggggggggggggggmm3m3mmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggll777777777777777777777llg9ggggggggggggggggggggggggggggggggggggggggggmmm3mmmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggll77ll7lll7lll7lll7lll7llg99gggggggggggggggggggggggggggggggggggggggggmmm3mm33
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggll7l7777l77l7l7l7l77l77llgkklggggggggggggggggggggggggggggggggggggggggmmm3m3mm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggll7lll77l77lll7ll777l77llglggggggggggggggggggggggggggggggggggggggggggmmmb3mmm
mmmmmmmmgggggggggggggggggggggggggggggggggggggggggggll777l77l77l7l7l7l77l77llgkggggggggggggggggggggggggggggggggggggggggggmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggmmmll7ll777l77l7l7l7l77l77llgmmmmmmmmmmmggggggggggggggggggggggggggggggggmm3mmmmm
mmmmmmmmggggggggggggggggggggggggggggggggggggggggmmmll777777777777777777777llgmmmmmmmmmmmggggggggggggggggggggggggggggggggmm3mmmmm
mmmmmmmmgggggggggggggggggggggggggggggggggg9gggggmmmlllllllllllllllllllllllllgmmmmmmmmmmmggggggggggggggggggggggggggggggggmmmbmmmm
mmmmmmmmggggggggggggggggggggggggggggggggg9a9gg8gmmmlllllllllllllllllllllllllgmmmmmmmmmmmgggggggggggggggg3bg33bgb3bg33bgbmmm3mmmm
mmmmmmmmgggggggggggggggggggggggggggggggggg9gg898mmmmgggggggggggggggggggggggggmmmmmmmmmmmggggggggggggggggg3b3g3b3g3b3g3b3mmm3bmmm
mmmmmmmmgggggggggggggggggggggggggggggggggb3bgg8gmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgggggggggggggggg6llllll66llllll6mmmm3mmm
mmmmmmmmggggggggggggggggggggggggggggggggbg333g3gmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgggggggggggggggg6llllll66llllll6mmmm33mm
mmmmmmmmggggggggggggggggggggggggggggggggb3b333b3mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgggggggggggggggg6llllll66llllll6mmmmmbbm
mmmmmmmmggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmggggggggmmmmmmmmmmmmmmmmmmmmmm3m
mmmmmmmmggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmggggggggmmmmmmmmmmmmmmmmmmmmmmm3
mmmmmmmmgggggggggg9gggggggggggggggg9ggggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgg9gggggmmmmmmmmmmmmmmmmmmmmmmm3
mmmmmmmmggggggggg9a9gg8ggggggggggg9a9gggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmg9a9gg8gmmmmmmmmmmmmmmmmmmmmmmm3
mmmmmmmmgggggggggg9gg898ggggggggg3g93gggmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgg9gg898mmmmmmmmmmmmmmmmmmmmmm3b
mmmmmmmmgggggggggb3bgg8gggggggggggbgbgg3mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmgb3bgg8gmmmmmmmmmmmmmmmmmmmmmm3m
mmmmmmmmggggggggbg333g3ggggggggg3gbg3g3gmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbg333g3gmmmmmmmmmmmmmmmmmmmmm33m
mmmmmmmmggggggggb3b333b3ggggggggg33333b3mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmb3b333b3mmmmmmmmmmmmmmmmmmmmm3mm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3mmmm3mm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmbmmmbmm
mmlmlmllmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3m3mmm
mmlmlmmlmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3mmmm
mmlmlmmlmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3mm33
mmlllmmlmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3m3mm
mmmlmmlllmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmb3mmm
mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm3mmmmm
