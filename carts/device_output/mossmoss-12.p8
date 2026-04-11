pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

--moss moss
--by noel cody
OFFSETS = {{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

function apply_pal(n, e)
  for n in all(split(n, ",")) do
    local n = split(n, ":")
    pal(n[1], n[2], e and 0 or 1)
  end
end

function reset_pal()
  pal()
  apply_pal "14:0,11:139,15:131,4:142"
  apply_pal(G_colorblind and "4:12,3:135")
end

SFX_MOSS_NOTES = split "50,51,53,50,52,53, 55,55,56,57,8,9, 10,10,11"
SFX_PLAYER_JUMP = split "13,14,15"
SFX_BUBBLE_EMIT, SFX_PLAYER_FALL, SFX_GEM_COLLECT, SFX_CROWN_JUMP, SFX_DOOR_OPEN, SFX_COLLECT, SFX_GROW_BUBBLE_PLANT, SFX_WELL_MOSSED, SFX_SLIDE, SFX_THUD, SFX_BUBBLE_POP, SFX_VOID_BOUNCE = unpack(split "16,17,18,19,20,21,22,23,24,25,26,27")
SPR_HIDDEN, SPR_LADDER_SPROUT, SPR_LADDER_EMPTY, SPR_LADDER, SPR_LADDER_TOP, SPR_SWITCH, SPR_STAIR, SPR_STAIR_FILLED, SPR_SPIRIT, SPR_SPIRIT_HIDDEN, SPR_VOID_SPIRIT, SPR_TROPHY = unpack(split "91,51,124,74,121,56,58,73,86,104,105,11")

function noop()
end

function printr(n, e)
  local e = split(e, ",")
  print("\xe2\x81\xb6o0ff" .. n, G_camera_x + 64 - #n * 2, G_camera_y + e[1], e[2])
end

function merge(n, e)
  for e, o in next, e do
    n[e] = o
  end
end

function destroy(n)
  n.expiry_time = G_time + 1
end

function pal_full(n)
  for e = 0, 15 do
    pal(e, n)
  end
end

function screen_shake_vert()
  G_shake_frames, G_shake_intensity_y, G_shake_intensity_x = 2, 1, 0
end

function screen_shake_horiz()
  G_shake_frames, G_shake_intensity_x, G_shake_intensity_y = 2, G_player.spr_flip_x and -1 or 1, 0
end

_env_mt = {__index = _ENV, __newindex = function(e, n, o)
  rawset(sub(n, 1, 2) == "G_" and _ENV or e, n, o)
end}

function envtable(n)
  return setmetatable(n, _env_mt)
end

function cel2pxl(n)
  return n * 8
end

function pxl2cel(n)
  return n // 8
end

function Map_init()
  local o = get_actor_defs()
  G_room_defs = get_room_defs()
  G_spike_cells = {}
  for e = 0, 127 do
    for n = 0, 63 do
      key = mget(e, n)
      if key == 9 then
        mset(e, n, SPR_HIDDEN)
      end
      if key == 10 then
        mset(e, n, SPR_SPIRIT_HIDDEN)
      end
      if key == SPR_SPIRIT or key == 10 then
        G_spirit_max = G_spirit_max + (1)
      end
      if key == SPR_LADDER_SPROUT and mget(e, n + 1) == SPR_LADDER_SPROUT then
        mset(e, n, SPR_LADDER_EMPTY)
      end
      if key == SPR_STAIR then
        add(G_vine_path, {celx = e, cely = n})
      end
      if key == 52 then
        G_spike_cells[e + n * 128] = true
      end
      if n % 16 == 0 then
        _load_room(_get_coordinates(e, n))
      end
      actor_init = o[key]
      if actor_init then
        mset(e, n, 0)
        actor = ActorFactory_create(key, cel2pxl(e) + 4, cel2pxl(n) + 4, G_room.index)
        actor_init(actor)
      end
    end
  end
  for n in all(G_rooms) do
    n:init_tiles()
    n:init()
  end
  for n = 1, G_spirit_max do
    init_void_spirit(ActorFactory_create(SPR_VOID_SPIRIT, 444, -46), n)
  end
  VOID_CEILING_Y = -46 - G_void_offset + 9 * G_spirit_max + (5.2 + (G_spirit_max - 1) * .7) ^ 2 * .05 / GRAVITY
end

Map_update = function()
  if G_player.y < -20 then
    return
  end
  room_coordinates = _get_coordinates(pxl2cel(G_player.x), pxl2cel(G_player.y))
  pre_index = G_room.index
  if room_coordinates.index == pre_index then
    return
  end
  G_room.fx = {}
  for n in all(G_room.moss_fx) do
    n:complete()
  end
  _load_room(room_coordinates)
  G_player.room_index = G_room.index
  fx_cancel_mossed_text()
  G_room.is_visited = true
  G_room:init_ambients()
  G_room:on_enter(pre_index)
  convert_next_stair()
end

function _get_coordinates(n, e)
  roomx, roomy = n // 16, e // 16
  return {index = roomx + roomy * 8, camera_x = roomx * 128, camera_y = roomy * 128}
end

function _load_room(n)
  G_room = G_rooms[n.index + 1]
  if G_room then
    return
  end
  G_room = room_base()
  merge(G_room, n)
  merge(G_room, G_room_defs[n.index] or {})
  G_room.camera_x = G_room.camera_x + (G_room.camera_offset_x or 0)
  G_room.camera_y = G_room.camera_y + (G_room.camera_offset_y or 0)
  G_rooms[G_room.index + 1] = G_room
end

function ActorFactory_create(e, o, d, t)
  local n = envtable {}
  add(G_actors, n)
  local _ENV = n
  state, x, y, orig_w, orig_h, dx, dy, frame, z = {}, o, d, 4, 4, 0, 0, 0, 1
  update, draw, room_index = noop, noop, t

  function n:set_state(n, t)
    local e = split(n[1], ":")
    local e, f, o = e[1], e[2], e[3]
    local e = split(e)
    local e, d = e[1], e[2]
    if state.id == e then
      return false
    end
    if not t and (last_state_update_time and G_time - last_state_update_time < state.duration) then
      return
    end
    local e = {id = e, key = d, duration = n.duration, frames = n.frames or 1, celw = 1, celh = 1, y_offset = n.y_offset or 0, x_offset = n.x_offset or 0, anim_speed = n.anim_speed, ignore_flip = n.ignore_flip}
    if o then
      e.crown_x, e.crown_y, e.crown_spr = unpack(split(o))
    end
    h, w = n.h or orig_h, n.w or orig_w
    if state.key ~= d or state.frames ~= e.frames then
      frame = 0
    end
    props = {}
    for n in all(split(f)) do
      if n == "anim_slow" then
        e.anim_speed = .2
      else
        props[n] = true
      end
    end
    state = e
    last_state_update_time = e.duration and G_time or false
    return true
  end

  function n:flip_dx(n)
    return spr_flip_x and -n or n
  end

  function n:wrap_float(n)
    local e = base_y + sin(G_time * .006) * 1.3
    if n then
      circ(x, e, 7, n)
    else
      oval(x - 8, y - 8, x + 7, y + 7, 9)
    end
    return e
  end

  function n:draw_ambient_sparkle(n)
    next_ambient_spawn = fx_ambient_sparkle(x, y, next_ambient_spawn, n)
  end

  n:set_state {"-1," .. e .. ":"}
  return n
end

BUBBLE_STATE_NORMAL = {"0,79:"}

function init_bubble_plant(n)
  local _ENV = n
  type, z = 2, 3
  n:set_state(BUBBLE_STATE_NORMAL)

  function n:update()
    n:set_state(G_time % 65 >= 55 and {"1,92:"} or BUBBLE_STATE_NORMAL)
    if G_time % 65 == 0 then
      fx_init_dust_cloud(12, x + 2, y - 4, false, true)
      init_bubble(ActorFactory_create(83, x, y - 8, room_index))
      if self.room_index == G_room.index then
        sfx(SFX_BUBBLE_EMIT)
      end
    end
  end

  return n
end

function init_bubble(n)
  local _ENV = n
  type, h = 1, 3
  n:set_state {"0,76:"}

  function n:update()
    room_index = x // 128 + y // 128 * 8
    y = y - (.5)
    local e = mget(pxl2cel(x), pxl2cel(y - (w + 1)))
    if fget(e, 0) and not fget(e, 5) then
      fx_init_bubble_pop(x, y, 12)
      destroy(n)
    end
  end

end

function init_gem(n)
  local _ENV = n
  type, w, h = 3, 3, 3
  gem_phase = rnd(.2)

  function n:draw()
    for n = 1, 4 do
      local n = (n - 1) / 4 + gem_phase + G_time * .004
      pset(x + cos(n) * 4, y + sin(n) * 4, 9)
    end
  end

end

function init_cloud(n)
  local _ENV = n
  type, z, h, cloud_phase, cloud_speed = 4, 3, 1, rnd(1), rnd(.0008) + .0001

  function n:draw()
    for n = 1, 5 do
      local e = (n - 1) / 5 + cloud_phase + G_time * cloud_speed
      local e, o = x + cos(e) * 3, y + sin(e) * 3
      circfill(e, o, 2.5, 6 + (x + y * 128 + n) % 2)
    end
  end

  function n:reappear()
    local n, e = abs(x - G_player.x), abs(y - G_player.y)
    if n <= 11 and e <= 11 then
      add_delayed_coro(function()
        self:reappear()
      end, 10)
      return
    end
    fx_init_dust_cloud(1, x + 2, y + 2, false, true)
    add_delayed_coro(function()
      fx_init_dust_cloud(7, x + 2, y + 2, false, true)
    end, 2)
    add_delayed_coro(function()
      fx_init_bubble_pop(x, y - 1, 7, true)
      is_hidden = false
    end, 4)
  end

end

function init_spikes(n, e)
  n.type, n.w, n.h = 5, e and -1 or 4, e and 2 or 1
end

function init_spikes_lr(n)
  init_spikes(n, true)
end

function init_spirit(n)
  local _ENV = n
  type, z, w = 7, 2, 2
  n:set_state {"0,86:"}
  draw = draw_ambient_sparkle
end

function init_crown(n)
  local _ENV = n
  y = y - (4)
  x = x + (1)
  type, w, h, base_y = 8, 2, 2, y

  function n:update()
    if is_hidden then
      return
    end
    y = self:wrap_float(nil)
    self:draw_ambient_sparkle(9)
  end

end

function init_leaf(n)
  local _ENV = n
  state.y_offset = 1
  type, w, h, is_hidden, base_y, G_room.leaf = 6, 6, 6, true, y, n

  function n:update()
    if is_hidden then
      return
    end
    next_ambient_spawn = fx_ambient_sparkle(x, y, next_ambient_spawn)
    y = self:wrap_float(G_time % 60 < 35 and 7 or 3)
  end

end

function get_actor_defs()
  return {[49] = init_cloud, [52] = init_spikes, [53] = init_spikes, [108] = init_spikes, [54] = init_spikes_lr, [55] = init_spikes_lr, [50] = init_gem, [73] = init_leaf, [60] = init_player, [61] = init_crown, [86] = init_spirit}
end

function _init()
  poke(24412, 255)
  G_time, G_freeze, G_mossable_rooms, G_leaves_collected, G_stairs_converted, G_spirits_collected, G_spirit_max = 32768, 0, 0, 0, 0, 0, 0
  G_rooms, G_room, G_actors, G_fx, G_fx_top, G_coros, G_active_vines, G_vine_path, G_stair_shake, G_shake_frames, G_shake_intensity_x, G_shake_intensity_y, G_flash = {}, {}, {}, {}, {}, {}, {}, {}, {}, 0, 0, 0, 0
  Map_init()
  Map_update()
  G_room:init_ambients()
  G_game_start_time = time()
  menuitem(1, "colorblind: off", function()
    G_colorblind = not G_colorblind
    G_cb_text_until = G_time + 60
    menuitem(1, G_colorblind and "colorblind: on" or "colorblind: off")
  end)
end

function _draw_fx(n)
  n:draw()
end

function _update()
  G_time = G_time + (1)
  cls()
  G_room:update()
  G_room:remove_expired_entities()
  foreach(G_actors, function(n)
    n:update()
  end)
  if G_shake_frames > 0 then
    G_shake_frames = G_shake_frames - (1)
  end
  Map_update()
  reset_pal()
  G_in_void = G_player.y < 0
  local n = G_shake_frames > 0 and (G_shake_frames % 2 == 0 and 1 or -1) or 0
  local n, e = n * G_shake_intensity_x, n * G_shake_intensity_y
  G_camera_x, G_camera_y = G_room.camera_x, G_room.camera_y
  if G_in_void then
    G_camera_y = max(VOID_CEILING_Y, min(G_player.y - 64, G_room.camera_y))
  end
  camera(G_camera_x + n, G_camera_y + e)
  _draw_map()
  draw_vines()
  foreach(G_fx, _draw_fx)
  foreach(G_room.fx, _draw_fx)
  for e = 1, 3 do
    for n in all(G_actors) do
      if n.z == e and n.room_index == G_room.index then
        _draw_actor(n)
      end
    end
  end
  foreach(G_room.moss_fx, _draw_fx)
  G_room:draw_all_mossable_surfaces(4)
  _draw_map(128)
  G_room:draw()
  play_coros()
  draw_hud()
  if G_flash > 0 then
    local n, e = G_player.x, G_player.y
    ovalfill(n - 9, e - 10, n + 8, e + 6, 7)
    if G_flash == 1 then
      fx_init_bubble_pop(n, e, 7)
    end
    G_flash = G_flash - (1)
  end
  foreach(G_fx_top, _draw_fx)
  if G_cb_text_until then
    if G_time - G_cb_text_until < 0 then
      printr(G_colorblind and "cb filter on" or "cb filter off", "4,7")
    else
      G_cb_text_until = nil
    end
  end
end

function _draw_actor(d)
  local _ENV = d
  if is_hidden or type == 5 and room_index ~= G_room.index then
    return
  end
  if not (type == 0 and G_freeze > 0) then
    frame = frame + (state.anim_speed and (not (props.climbing and abs(dy) == 0) and state.anim_speed or 0) or abs(dx) * .25)
    frame = frame % (state.frames)
  end
  local n, e, t, o = x - 4 + state.x_offset, y - 4 + state.y_offset, state.key + flr(frame), spr_flip_x and not state.ignore_flip
  if type == 7 then
    state.key = 86 + (G_time // 15 + flr(x)) % 2
  end
  if has_gem then
    pal_full(9)
    for d = -1, 1 do
      for f = -1, 1 do
        if d ~= 0 or f ~= 0 then
          spr(t, n + d, e + f, 1, 1, o)
        end
      end
    end
    pal()
  end
  d:draw()
  spr(t, n, e, 1, 1, o)
  if type == 0 and G_crown and not G_player.crown_used then
    spr(state.crown_spr or 72, n + G_player:flip_dx(state.crown_x or 0), e + (state.crown_y or -1) - (G_player.has_gem and 1 or 0), 1, 1, o)
  end
  reset_pal()
end

function _draw_map(o)
  local n, e = G_room.index % 8 * 16, G_room.index // 8 * 16
  map(n, e, n * 8, e * 8, 16, 16, o or 0)
end

function fx_init_mossed_text(d, o, n, e, l)
  fx_cancel_mossed_text()
  o = o or 90
  local t, c, u, i, f = #d, 66 - (#d * 8 - 1) / 2, 60 + (n or 0), {}, 0
  for n = 1, t do
    if e and (n == 1 or sub(d, n - 1, n - 1) == " ") then
      f = f + (1)
    end
    i[n] = e and (f - 1) * 18 or (n - 1) * 2
  end
  G_mossed_text_coro = add_coro(function()
    local n, a, r = 0, 0, -1
    while true do
      if o > 0 and n >= o then
        return
      end
      if e and r < f - 1 and flr(n / 18) > r then
        r = flr(n / 18)
        screen_shake_vert()
      end
      local f = flr(n * .4 % t)
      for e = 1, t do
        if n >= i[e] and (o <= 0 or n < o - (t - e + 1) * 2) then
          print("\xe2\x81\xb6w\xe2\x81\xb6t\xe2\x81\xb6o0ff" .. sub(d, e, e), G_room.camera_x + c + (e - 1) * 8, G_room.camera_y + u + sin(a + e * 1.05) * 3, f == e - 1 and (l and 7 or 11) or l and 9 or 3)
        end
      end
      a = a + (.02)
      n = n + (1)
      yield()
    end
  end)
end

function fx_cancel_mossed_text()
  del(G_coros, G_mossed_text_coro)
end

function _get_surface_coords(n, e)
  return cel2pxl(n.celx) + (e == 4 and 7 or 0), cel2pxl(n.cely) + (e == 2 and 7 or 0)
end

G_MOSS_PAT = {}
for e = 1, 8 do
  local n = {}
  for e = 0, 7 do
    n[e] = 2 + flr(rnd(2))
  end
  G_MOSS_PAT[e] = n
end

function _moss_complete(_ENV)
  growth_frame = 120
  if fl_spr then
    fl_stage = 2
  end
  _moss_draw(_ENV)
end

function _moss_draw(_ENV)
  local e = mget(celx, cely)
  local n = e == 48
  if e == SPR_LADDER or e == SPR_LADDER_EMPTY or e == SPR_LADDER_TOP then
    return
  end
  growth_frame = min(growth_frame + 1, 120)
  if not n and growth_frame < 8 then
    local n = flag_bit < 3
    rectfill(base_x, base_y, base_x + (n and 7 or 0), base_y + (n and 0 or 7), 7)
  end
  local e = flr(growth_frame / 60 * 8)
  local d, e, o, t = min(e / 2, 3.5), flag_bit < 3, n and 12 or 3, G_MOSS_PAT[moss_pat]
  for n = 0, 7 do
    if abs(n - 3.5) <= d then
      local d, t, f, n = t[n], base_x + (e and n or 0), base_y + (e and 0 or n), OFFSETS[flag_bit]
      for e = 0, d - 1 do
        pset(t + n[1] * e, f + n[2] * e, o)
      end
    end
  end
  if growth_frame > last_grass_time + 20 and growth_frame < 120 and not n then
    if rnd() < .2 then
      add(grass, e and base_x + rnd(8) or base_x)
      add(grass, e and base_y or base_y + rnd(8))
      last_grass_time = growth_frame
    end
  end
  local e, d = flag_bit == 4 and 1 or flag_bit == 3 and -1 or 0, flag_bit == 1 and -1 or flag_bit == 2 and 1 or 0
  for n = 1, #grass, 2 do
    pset(grass[n] + e, grass[n + 1] + d, o)
  end
  if fl_spr then
    fl_frame = fl_frame + (1)
    if fl_frame >= 20 and fl_stage < 2 then
      fl_stage = fl_stage + (1)
      fl_frame = 0
    end
    if n and fl_stage == 2 and not fl_done then
      init_bubble_plant(ActorFactory_create(82, fl_x + 4, fl_y + 4, G_room.index))
      fl_done = true
    end
    if not (n and fl_done) then
      spr(fl_spr + fl_stage, fl_x, fl_y, 1, 1, fl_flip)
    end
  elseif pl_spr and growth_frame >= 120 then
    spr(pl_spr, pl_x, pl_y)
  end
end

function fx_init_moss(n, e)
  local o, d = _get_surface_coords(n, e)
  local r, t = mget(n.celx, n.cely), {}
  if r ~= 48 then
    local n = e < 3
    for e = 1, 2 do
      add(t, n and o + rnd(8) or o)
      add(t, n and d or d + rnd(8))
    end
  end
  local n, t, f, l = envtable {base_x = o, base_y = d, celx = n.celx, cely = n.cely, growth_frame = 0, last_grass_time = 0, flag_bit = e, moss_pat = flr(rnd(8)) + 1, grass = t, complete = _moss_complete, draw = _moss_draw}, 0, 0, false
  if r == 48 then
    n.fl_spr, f = 77, -8
    sfx(SFX_GROW_BUBBLE_PLANT, 1)
  elseif rnd() < .13 then
    n.fl_spr = split "93,109,125,125" [e]
    if e == 1 then
      f = -8
    elseif e == 3 then
      t, l = -8, true
    elseif e == 4 then
      t = 1
    end
  end
  if n.fl_spr then
    n.fl_x, n.fl_y, n.fl_stage, n.fl_frame, n.fl_flip = o + t, d + f, 0, 0, l
  elseif rnd() < .08 and e == 1 then
    n.pl_x, n.pl_y, n.pl_spr = o, d - 8, 106
  end
  add(G_room.moss_fx, n)
end

function draw_mossable_surface(n, o, d, t)
  local n, e = _get_surface_coords(n, o)
  local o = o < 3
  rectfill(n, e, n + (o and 7 or 0), e + (o and 0 or 7), d)
  if t and rnd() < .05 then
    fx_ambient_sparkle(n, e)
  end
end

function fx_ambient_sparkle(e, o, n, d)
  if G_time - (n or G_time) >= 0 then
    fx_init_dust_single(d or 7, e + rnd(12) - 6, o + rnd(8) - 9, true, G_fx_top)
    return G_time + rnd(5) + 8
  end
  return n
end

function _dust_draw(_ENV)
  x = x + (dx * .2)
  y = y + (dy)
  local n = act >= 15 and (sm and 1 or 2.5) or act >= 10 and (sm and .5 or 2) or act >= 5 and (sm and -1 or 1.5) or (sm and -1 or 1)
  circfill(x, y, n, clr)
end

function fx_init_dust_single(n, e, o, d, t)
  _fx_init_particles(1, function()
    return {x = e, y = o, dx = rnd(.5) - .25, dy = (rnd(.2) + .05) * -1, act = rnd(13.33333) + 15, clr = n or 7, sm = d, draw = _dust_draw}
  end, t)
end

function fx_init_dust_cloud(f, e, o, d, r, l)
  local t, i = split "-4,-1,2,4", split "6,7,13,7"
  for n = 1, 4 do
    e = e + (d and 0 or t[n])
    o = o + (d and t[n] or 0)
    fx_init_dust_single(f or i[n], e, o, r, l)
  end
end

function _bubble_draw(_ENV)
  x = x + (dx * .7)
  y = y + (dy * .7)
  dx = dx * (.92)
  dy = dy * (.92)
  circfill(x, y, rv and (act < 5 and 1 or .8) or (act < 5 and .8 or 1), clr)
end

function fx_init_bubble_pop(t, f, o, n)
  o = o or 7
  local d = n and -1.5 or 1
  _fx_init_particles(8, function(e)
    local e = (e - 1) / 8 * 6.283
    return {x = t + (n and cos(e) * 8 or 0), y = f + (n and sin(e) * 8 or 0), dx = cos(e) * 1.5 * d, dy = sin(e) * 1.5 * d, act = n and 4 or 15, clr = o, rv = n, draw = _bubble_draw}
  end, n and G_fx_top or G_fx)
end

function _fx_init_particles(e, o, d)
  local n = {}
  for e = 1, e do
    add(n, o(e))
  end
  add(d or G_fx, {draw = function(e)
    for e in all(n) do
      e.act = e.act - (1)
      if e.act < 0 then
        del(n, e)
      else
        e:draw()
      end
    end
    if #n == 0 then
      destroy(e)
    end
  end})
end

function _rm_expired(n)
  for e = #n, 1, -1 do
    if n[e].expiry_time and G_time - n[e].expiry_time >= 0 then
      deli(n, e)
    end
  end
end

function room_base()
  local n = envtable {}
  local _ENV = n
  fx, moss_fx, actors, mossable_surfaces, mossable_surfaces_count, void_moss_count, switch_tiles, init, on_enter, on_leaf, draw, update = {}, {}, {}, {}, 0, 0, {}, noop, noop, noop, noop, noop

  function n:remove_expired_entities()
    _rm_expired(G_actors)
    _rm_expired(n.fx)
    _rm_expired(G_fx)
    _rm_expired(G_fx_top)
  end

  function n:init_tiles()
    mossable_surfaces_count, void_moss_count = 0, 0
    local n, e = index % 8 * 16, index // 8 * 16
    for n = n, n + 15 do
      for e = e, e + 15 do
        local d = mget(n, e)
        local f = fget(d)
        local o = f & 30
        if d == SPR_SWITCH then
          add(switch_tiles, {celx = n, cely = e})
        end
        local t = 0
        while o > 0 do
          if o & 1 == 1 then
            local o = f & 64 ~= 0
            if not o then
              mossable_surfaces_count = mossable_surfaces_count + (1)
            else
              void_moss_count = void_moss_count + (1)
            end
            local f = n .. ":" .. e .. ":" .. t
            mossable_surfaces[f] = {celx = n, cely = e, flag_bit = t, is_void = o, tile_key = d}
          end
          o = o >> 1
          t = t + (1)
        end
      end
    end
    if mossable_surfaces_count > 0 then
      is_mappable = true
      G_mossable_rooms = G_mossable_rooms + (1)
    end
  end

  function n:draw_all_mossable_surfaces(e)
    for o, n in next, mossable_surfaces do
      local e = n.is_void and 7 or n.tile_key == 48 and 12 or e
      draw_mossable_surface(n, n.flag_bit, e, n.is_void)
    end
  end

  function n:moss_surface(n, e)
    if e == 1 and mget(n.celx, n.cely - 1) == SPR_LADDER_SPROUT then
      screen_shake_vert()
      sfx(SFX_DOOR_OPEN, 2)
      G_freeze = 5
      self:_convert_ladder_sprouts_recursive(n.celx, n.cely - 1, 0)
    end
    local o = n.celx .. ":" .. n.cely .. ":" .. e
    if o == "62:61:1" then
      self:moss_surface({celx = 63, cely = 61}, 1)
    end
    local d = mossable_surfaces[o]
    if d then
      mossable_surfaces[o] = nil
      repeat
        _msfx = rnd(SFX_MOSS_NOTES)
      until _msfx ~= last_note
      last_note = _msfx
      sfx(_msfx, 1)
      fx_init_moss(n, e)
      if d.is_void then
        void_moss_count = void_moss_count - (1)
        if void_moss_count == 0 then
          G_player:celebrate()
          set_win()
        end
      else
        mossable_surfaces_count = mossable_surfaces_count - (1)
        if mossable_surfaces_count == 0 then
          self:set_well_mossed()
        end
      end
    end
  end

  function n:set_well_mossed()
    is_well_mossed = true
    add_delayed_coro(function()
      fx_init_bubble_pop(leaf.x, leaf.y, 7, true)
      screen_shake_horiz()
      sfx(32, 2)
      sfx(SFX_DOOR_OPEN)
      leaf.is_hidden = false
    end, is_home and 85 or 20)
    G_player:celebrate()
    add_delayed_coro(function()
      for n in all(switch_tiles) do
        fx_init_dust_cloud(3, cel2pxl(n.celx) + 6, cel2pxl(n.cely))
        mset(n.celx, n.cely, 75)
        screen_shake_horiz()
        sfx(SFX_DOOR_OPEN)
      end
    end, 30)
    fx_init_mossed_text "well mossed!"
  end

  function n:_convert_ladder_sprouts_recursive(n, e, d)
    local o = mget(n, e)
    if o == SPR_LADDER_SPROUT or o == SPR_LADDER_EMPTY or fget(o, 0) then
      local o = fget(o, 0) and SPR_LADDER_TOP or SPR_LADDER
      add_delayed_coro(function()
        mset(n, e, o)
        fx_init_dust_cloud(3, cel2pxl(n) + 6, cel2pxl(e))
      end, d)
      self:_convert_ladder_sprouts_recursive(n, e - 1, d + 2)
    end
  end

  function n:reveal_hidden_tiles(n, e, o)
    mset(n, e, 0)
    for o in all(OFFSETS) do
      local n, e = n + o[1], e + o[2]
      local o = mget(n, e)
      if o == SPR_HIDDEN or o == SPR_SPIRIT_HIDDEN then
        if o == SPR_SPIRIT_HIDDEN then
          init_spirit(ActorFactory_create(SPR_SPIRIT, cel2pxl(n) + 4, cel2pxl(e) + 4, index))
        end
        fx_init_dust_cloud(13, cel2pxl(n) + 6, cel2pxl(e) + 5)
        G_freeze = 10
        screen_shake_horiz()
        sfx(28)
        self:reveal_hidden_tiles(n, e)
      end
    end
  end

  function n:init_ambients()
    local n = {}
    for e = 1, 3 + flr(rnd(3)) do
      local e, o = self:_random_point()
      add(n, envtable {x = e, y = o, p = rnd(2), o = rnd(1), tx = e, ty = o})
    end
    add(fx, {draw = function()
      for n in all(n) do
        local _ENV = n
        local n = max(abs(tx - x) + abs(ty - y), .01)
        x = x + ((tx - x) / n * .2)
        y = y + ((ty - y) / n * .2)
        if rnd() < .03 then
          tx, ty = self:_random_point()
        end
        local n, e = x - G_player.x, y - G_player.y
        if abs(n) + abs(e) < 24 then
          x = x + (sgn(n) * .4)
          y = y + (sgn(e) * .4)
        end
        p = p + (.008)
        pset(x + sin(G_time * .008 + o) * 4, y + cos(G_time * .006 + o) * 3, sin(p) > .1 and 10 or 1)
      end
    end})
    local n, o = {}, G_time
    add(fx, {draw = function()
      local e = is_well_mossed
      if G_time - o >= 0 then
        local d, t = self:_random_point()
        add(n, envtable {x = d, y = t, phase = 0, speed = .02 + rnd(.01), drift_speed = .03 + rnd(.05)})
        o = G_time + (e and rnd(5) or rnd(15))
      end
      for o = #n, 1, -1 do
        local _ENV = n[o]
        phase = phase + (speed)
        y = y - (drift_speed)
        if phase >= 1 then
          del(n, _ENV)
        else
          local n, e = e and 3 or 1, e and 11 or 15
          pset(x, y, phase > .5 and phase < .75 and e or n)
        end
      end
    end})
  end

  function n:_random_point()
    return camera_x + rnd(128), camera_y + rnd(128)
  end

  return n
end

function set_win()
  G_credits = G_time
  G_win_play_time = flr(time() - G_game_start_time)
end

function draw_win_credits(e, n)
  if not G_credits then
    return
  end
  local o, e = G_win_play_time // 60, G_win_play_time % 60
  local o, e = o .. ":" .. (e < 10 and "0" or "") .. e, G_time - G_credits
  if e == 20 then
    fx_init_mossed_text(n and "you win!" or "fully mossed!", -1, -44, true, not n)
    sfx(-1)
    music(0)
  end
  if e >= 83 then
    if n then
      printr("you are the moss prince", "37,11")
    else
      printr("you really mossed it all", "35,9")
      printr("thank you for playing \xe2\x99\xa5", "43,3")
    end
  end
  if e >= 125 then
    rectfill(G_camera_x, G_camera_y + 105, G_camera_x + 128, G_camera_y + 128, 0)
    if not n then
      apply_pal("7:9,3:9,11:9,6:9", 0)
      _ws1 = fx_ambient_sparkle(G_camera_x + 28, G_camera_y + 111, _ws1, 9)
      _ws2 = fx_ambient_sparkle(G_camera_x + 50, G_camera_y + 111, _ws2, 9)
    end
    spr(SPR_STAIR_FILLED, G_camera_x + 26, G_camera_y + 109)
    print(G_leaves_collected, G_camera_x + 18, G_camera_y + 109, 3)
    spr(45, G_camera_x + 48, G_camera_y + 107)
    print(G_spirits_collected, G_camera_x + 40, G_camera_y + 109, 7)
    reset_pal()
    printr("           time  " .. o, "109,3")
  end
  if e >= 165 then
    printr("game by noel cody ", "119,1")
  end
end

function get_room_defs()
  return {[19] = {is_home = true, camera_offset_x = -4, hide_hud = true, on_leaf = function(_ENV)
    hide_hud = false
    add_delayed_coro(function()
      for n = 39, 42 do
        mset(55, n, SPR_LADDER_EMPTY)
      end
      _ENV:_convert_ladder_sprouts_recursive(55, 61, 0)
    end, 85)
  end, draw = function(_ENV)
    if G_time > 32969 and G_time % 130 < 20 then
      _ENV:draw_all_mossable_surfaces(7)
    end
    if not is_well_mossed then
      printr("[c] jump [x] dash", "106,7")
      printr("colorblind option in pause menu", "117,1")
    end
  end}, [27] = {camera_offset_x = -5, on_enter = function(n)
    if not is_well_mossed and not did_show_title then
      fx_init_mossed_text("moss moss", -1, -10)
      did_show_title = true
      music(1, 0, 12)
    end
  end, draw = function(_ENV)
    rectfill(G_camera_x, G_camera_y, G_camera_x + 4, G_camera_y + 128, 0)
  end}, [26] = {draw = draw_win_credits}, [28] = {draw = function(_ENV)
    if not is_well_mossed then
      printr("hold [jump]", "99,1")
      printr("to jump further", "107,1")
      printr("[x] to dash", "115,1")
    end
  end}, [3] = {draw = function(n)
    if G_crown and not G_credits then
      printr("crown jump: [jump] in air", "112,9")
      return
    end
    n:draw_win_credits(true)
    if G_credits and G_time - G_credits > 220 and not G_player.props.grounded then
      G_credits = nil
      fx_cancel_mossed_text()
    end
  end}}
end

WELL_MOSSED_CELEBRATE_TIME = 45
STATE_PLAYER_STAND = {"0,112:grounded", frames = 1}
STATE_PLAYER_WALK = {"1,96:grounded:0,0", frames = 4}
STATE_PLAYER_JUMP = {"2,80:jumping", frames = 1}
STATE_PLAYER_LAND = {"3,82:grounded:1,1", duration = 2}
STATE_PLAYER_DASH = {"4,64:grounded:0,0", frames = 8}
STATE_PLAYER_AIR_DASH = {"5,120:airdashing:-2,-2", frames = 1}
STATE_PLAYER_MOSSING_CEILING = {"6,83:mossing,ceiling_mossing:0,-2", h = 4, w = 4}
STATE_PLAYER_MOSSING_WALL = {"7,81:mossing,wall_mossing:0,0,90", h = 4, w = 4}
STATE_PLAYER_BUBBLE_BOUNCE = {"8,113:spin_jumping,anim_slow:0,-3", frames = 7, ignore_flip = true}
STATE_PLAYER_TUMBLE = {"9,100:tumble,anim_slow:-1,-2", frames = 4}
STATE_PLAYER_CELEBRATE = {"12,113:", frames = 7, anim_speed = 7 / WELL_MOSSED_CELEBRATE_TIME}
STATE_PLAYER_CLIMB = {"13,122:climbing,anim_slow", frames = 2}
STATE_PLAYER_SEEK = {"17,82:grounded,seeking:0,1"}
GRAVITY = .2
PLAYER_RUN_DX = 1
PLAYER_JUMP_DY = -2.8
PLAYER_GEM_JUMP_DY = -3.1
PLAYER_MAX_FALL_DY = 3.5
PLAYER_BUBBLE_DY = -2.8
PLAYER_CLOUD_BOUNCE_DY = -1.6
PLAYER_JUMP_BUFFER = 3
PLAYER_COYOTE_FRAMES = 4
PLAYER_DASH_DX, PLAYER_DASH_DX_DECAY, PLAYER_AIR_DASH_DX = 3.8, .81, 2.2
HANGTIME_VELOCITY_WINDOW, HANGTIME_GRAVITY_MULTIPLIER, COYOTE_GRAVITY_MULTIPLIER = .5, .3, .01

function init_player(n)
  G_player = n
  local _ENV = n
  type, is_solid, orig_h, orig_w, z, timers, idle_timer, has_gem, collected_gems, dash, celx, cely = 0, true, 3, 3, 2, {}, 0, false, {}, init_player_dash(), 0, 0

  function n:celebrate()
    sfx(SFX_WELL_MOSSED, 2)
    fx_init_bubble_pop(x, y, 11)
    timers.moss_celebrate = WELL_MOSSED_CELEBRATE_TIME
    dash:stop()
  end

  function n:reset_gem()
    if not has_gem then
      return
    end
    has_gem = fx_init_bubble_pop(x, y, 9)
    for n in all(collected_gems) do
      add_delayed_coro(function()
        n.is_hidden = fx_init_bubble_pop(n.x, n.y, 1, true)
      end, 12)
    end
    collected_gems = {}
  end

  function n:update()
    if G_freeze > 0 then
      if btnp(4) then
        G_freeze = 0
      else
        G_freeze = G_freeze - (1)
        return
      end
    elseif is_hidden then
      return
    end
    for e, n in next, timers do
      n = n - (1)
      timers[e] = n > 0 and n or nil
    end
    if timers.crown_celebrate == 1 then
      G_crown = true
    end
    if timers.moss_celebrate or timers.crown_celebrate then
      dy = 0
      if props.grounded then
        y = y - (2)
      end
      self:set_state(STATE_PLAYER_CELEBRATE, true)
      return
    end
    celx, cely = pxl2cel(x), pxl2cel(y)
    local e = 0

    local function o()
      dy, timers.jump_dust, timers.gem_flash = PLAYER_GEM_JUMP_DY, 3, 4
      self:set_state(STATE_PLAYER_TUMBLE)
      dash:stop()
    end

    local function n(n, e)
      local o = mget(n, e)
      return o == SPR_LADDER or o == SPR_LADDER_TOP or n == VINE_START_X and e == VINE_START_Y
    end

    local d = n(celx, cely) or props.grounded and n(celx, cely + 1)
    if d and (btn(2) or btn(3)) and not timers.climb_cooldown then
      x = cel2pxl(celx) + 4
      self:set_state(STATE_PLAYER_CLIMB)
    end
    if props.climbing then
      dy, dx = 0, 0
      dash:stop()
      local e, n = n(celx, pxl2cel(y - h)), n(celx, pxl2cel(y + h + 1))
      if btn(2) and e then
        dy = -2
      elseif btn(3) and n then
        dy = 2
      end
      local n = (btn(0) or btn(1)) and dy == 0
      if btnp(4) or btnp(5) or n then
        self:set_state(STATE_PLAYER_JUMP)
        timers.climb_cooldown = 15
        timers.coyote = n and PLAYER_COYOTE_FRAMES or 1
      end
    end
    if not props.climbing and not dash.active then
      local n, o = btn(0), btn(1)
      if n ~= o then
        e = o and PLAYER_RUN_DX or -PLAYER_RUN_DX
        spr_flip_x = n
      end
    end
    if btnp(5) and not timers.dash_cooldown then
      if props.grounded then
        dash:start_ground()
        timers.dash_cooldown = 10
      else
        dash:start_air()
        if props.wall_mossing then
          dy = 1.2
        elseif props.ceiling_mossing then
          dy = btn(3) and 1.5 or -2
          dash.dx = dash.dx * (2)
        else
          dy = btn(3) and 1.5 or 0
          self:set_state(STATE_PLAYER_AIR_DASH)
        end
        timers.dash_cooldown = 20
      end
      G_freeze, timers.spirit_flash = 1, 2
      sfx(SFX_SLIDE)
      fx_init_dust_cloud(7, x, y + (props.ceiling_mossing and -1 or 4), not props.ceiling_mossing and not props.grounded)
    end
    dash:update(props)
    dx = dash.active and dash.dx + (dash.dx > 0 and PLAYER_RUN_DX or -PLAYER_RUN_DX) or e
    if btnp(4) and has_gem then
      o()
      sfx(rnd(SFX_PLAYER_JUMP))
      self:reset_gem()
    elseif (btnp(4) or timers.jumpbuffer) and timers.coyote then
      dy, timers.jump_dust, timers.jumpbuffer, timers.coyote = PLAYER_JUMP_DY, 3
      sfx(rnd(SFX_PLAYER_JUMP))
    elseif btnp(4) and not props.grounded and G_crown and not crown_used then
      o()
      sfx(SFX_CROWN_JUMP)
      fx_init_bubble_pop(x, y, 9)
      crown_used = true
    elseif btnp(4) and not props.grounded then
      timers.jumpbuffer = PLAYER_JUMP_BUFFER
    end
    if props.climbing then
    elseif not btn(4) and dy < 0 and dy > -1.5 and props.jumping and not timers.jump_dust then
      dy, timers.jump_dust = 0
    else
      local n = timers.coyote and (G_in_void and GRAVITY * 2 or GRAVITY * .48) or (abs(dy) <= HANGTIME_VELOCITY_WINDOW and GRAVITY * HANGTIME_GRAVITY_MULTIPLIER or GRAVITY)
      dy = min(dy + n, G_in_void and PLAYER_MAX_FALL_DY * 5 or PLAYER_MAX_FALL_DY)
    end

    function _get_overlaps(o)
      local e, d, t = {}, x + dx, y + dy
      for n in all(G_actors) do
        if n.room_index == G_room.index and n.type == o and not n.is_hidden and abs(d - n.x) < w + n.w and abs(t - n.y) < h + n.h then
          add(e, n)
        end
      end
      return e
    end

    local n = _get_overlaps(1)[1]
    if n then
      dy = PLAYER_BUBBLE_DY
      timers.spirit_flash, G_freeze = 1, y > n.y + 2 and 1 or 0
      if y > n.y then
        y = n.y
      end
      dash:stop()
      sfx(SFX_BUBBLE_POP)
      self:set_state(STATE_PLAYER_BUBBLE_BOUNCE)
      fx_init_bubble_pop(n.x, n.y, 12)
      destroy(n)
    end
    local n = _get_overlaps(4)
    if #n > 0 then
      dash:stop()
      if y > n[1].y then
        y = n[1].y + 1
      end
      dy = PLAYER_CLOUD_BOUNCE_DY
      self:set_state(STATE_PLAYER_TUMBLE)
      G_freeze = 1
      sfx(SFX_THUD)
      for n in all(n) do
        n.is_hidden = true
        fx_init_dust_cloud(7, n.x + 2, n.y)
        add_delayed_coro(function()
          n:reappear()
        end, 80)
      end
    end
    local n = _get_overlaps(3)[1]
    if n then
      G_freeze, has_gem, n.is_hidden = 1, true, true
      add(collected_gems, n)
      sfx(SFX_GEM_COLLECT)
    end
    local n = _get_overlaps(8)[1]
    if n then
      x, y, dx, dy = n.x, n.y + 2, 0, 0
      set_win()
      fx_init_bubble_pop(x, y - 2, 9, true)
      timers.crown_celebrate = 180
      G_flash = 20
      destroy(n)
    end
    local n = _get_overlaps(9)[1]
    if n and not timers.void_spirit_cooldown then
      x, y, timers.void_spirit_cooldown, timers.spirit_flash, timers.jump_dust, G_freeze = n.x, n.y, 10, 7, 3, 7
      dy = -5.2 + (n.index - 1) * -.7
      dash:stop()
      self:set_state(STATE_PLAYER_TUMBLE, true)
      sfx(SFX_VOID_BOUNCE)
      fx_init_dust_cloud(7, n.x, n.y + 2, true)
    end
    local n = _get_overlaps(7)[1]
    if n then
      G_spirits_collected = G_spirits_collected + (1)
      timers.spirit_flash, G_freeze = 7, 7
      fx_init_bubble_pop(x, y, 7, true)
      fx_init_dust_cloud(7, n.x, n.y + 2, true)
      sfx(31, 1)
      destroy(n)
    end
    local n = _get_overlaps(6)[1]
    if n then
      G_freeze, G_room.is_complete, G_room.leaf = 15, true
      fx_init_bubble_pop(n.x, n.y, 11)
      sfx(SFX_COLLECT, 2)
      G_room:on_leaf()
      hud_leaf(n.x, n.y)
      destroy(n)
    end
    local n = mget(celx, cely)
    if n == 7 or n == 8 or n == 57 then
      G_room:reveal_hidden_tiles(celx, cely, true)
    end
    local n = _get_overlaps(5)[1]
    if (n or x < 0 or x > 1024 or y > 512) and last_grounded_tile then
      is_hidden, dx, dy = true, 0, 0
      dash:stop()
      screen_shake_vert()
      fx_init_bubble_pop(x, y, 11)
      local n, e = cel2pxl(last_grounded_tile.celx) + 4, cel2pxl(last_grounded_tile.cely) - h - 2
      self:reset_gem()
      sfx(SFX_PLAYER_FALL)
      add_delayed_coro(function()
        x, y, is_hidden = n, e, false
        fx_init_bubble_pop(x, y, 11, true)
        G_freeze = 10
        self:set_state(STATE_PLAYER_JUMP, true)
      end, 6)
    else
      local n = self:_is_solid_edge(false, y + h + dy + 1, true)
      if #n > 0 then
        local n = n[1]
        if props.grounded and not G_spike_cells[n.celx + (n.cely - 1) * 128] then
          last_grounded_tile = n
        end
      end
    end
    if G_freeze > 0 then
      return
    end
    local t, n, o, d, e = dx, true, false, dy > 0, 0
    for f = 1, max(1, flr(abs(dy)) + 1) do
      if n then
        n = self:_move_axis(true, t)
      end
      local n = d and min(1, dy - e) or max(-1, dy - e)
      e = e + (n)
      if n ~= 0 and self:_move_step(false, n, d) then
        o = true
        break
      end
    end
    if G_in_void then
      x = G_room.camera_x + (x - G_room.camera_x) % 128
    end
    if y < VOID_CEILING_Y then
      x, y = 320, 507
      Map_update()
      return
    end
    local e = self:_is_solid_edge(false, y + h + 2, true)
    if props.climbing then
    elseif #e > 0 and dy >= 0 then
      for n in all(e) do
        G_room:moss_surface(n, 1)
      end
      if not props.grounded then
        timers.dash_cooldown = nil
        for n in all(e) do
          if mget(n.celx, n.cely) == SPR_STAIR_FILLED then
            G_stair_shake[n.celx .. ":" .. n.cely] = G_time
          end
        end
        sfx(SFX_THUD)
        if props.wall_mossing then
          dash:stop()
        end
        self:set_state(STATE_PLAYER_LAND)
        fx_init_dust_cloud(nil, x + 2, y + 3)
        if dash.active then
          dash.landed = true
        end
        self:reset_gem()
      elseif dash.active then
        self:set_state(dash.landed and STATE_PLAYER_LAND or STATE_PLAYER_DASH)
      elseif abs(dx) > 0 then
        self:set_state(STATE_PLAYER_WALK)
      else
        self:set_state(btn(3) and STATE_PLAYER_SEEK or STATE_PLAYER_STAND)
      end
      timers.coyote = PLAYER_COYOTE_FRAMES
      if crown_used then
        crown_used = fx_init_bubble_pop(x, y - 4, 9, true)
      end
      dash.grounded = true
    else
      if props.tumble then
        if G_time % 3 == 0 then
          fx_init_dust_single(7, x, y + 4, true)
        end
        if dy >= 0 then
          self:set_state(STATE_PLAYER_JUMP)
        end
      elseif props.wall_mossing and not n then
        self:set_state(STATE_PLAYER_JUMP)
        dash:stop()
      elseif props.ceiling_mossing and not o then
        self:set_state(STATE_PLAYER_JUMP)
        timers.dash_cooldown = nil
        if dash.active then
          dash.dx = dash.dx * (.2)
          dy = max(0, dy)
        end
      elseif props.mossing then
      elseif dash.active and not dash.grounded then
        if G_time % 2 == 0 then
          fx_init_dust_single(7, x, y, true)
        end
      elseif props.spin_jumping or props.jumping or props.cloud_bouncing then
      else
        self:set_state(STATE_PLAYER_JUMP)
        if timers.jump_dust then
          fx_init_dust_single(3, x, y + 4, true)
        end
      end
    end
    idle_timer = idle_timer + (1)
    if abs(dx) > 0 or abs(dy) > 0 then
      idle_timer = 0
    end
  end

  function n:_move_axis(d, n)
    local o, e = n > 0, 0
    while abs(e) < abs(n) do
      local n = o and min(1, n - e) or max(-1, n - e)
      e = e + (n)
      if self:_move_step(d, n, o) then
        return true
      end
    end
  end

  function n:_move_step(n, o, e)
    local d, t = n and x or y, o + (e and (n and w - 1 or h + 1) or (n and -w or -h))
    local t, r = d + t, self:_is_solid_edge(n, d + t, not n and e)
    if #r > 0 then
      local d = t // 8

      local function f(n)
        for e in all(r) do
          G_room:moss_surface(e, n)
        end
      end

      if not n and e and props.grounded and (dx > 0 and not self:_is_solid_cell(x + (G_in_void and 2 or 0), t, true) or dx < 0 and not self:_is_solid_cell(x - (G_in_void and 3 or 1), t, true)) then
        y = y + (o)
        return true
      end
      if n then
        dx = 0
        if not props.grounded then
          if props.airdashing then
            dy = 1.2
          end
          if props.ceiling_mossing then
            dy = 0
          end
          self:set_state(STATE_PLAYER_MOSSING_WALL)
        end
        if e then
          x = d * 8 - w
          f(3)
        else
          x = (d + 1) * 8 + w
          f(4)
        end
      else
        if e then
          dy = 0
          y = d * 8 - (h + 1)
        else
          y = (d + 1) * 8 + h
          if not props.mossing then
            sfx(SFX_THUD, 3)
            self:set_state(STATE_PLAYER_MOSSING_CEILING)
          end
          f(2)
        end
      end
      return true
    end
    if n then
      x = x + (o)
    else
      y = y + (o)
    end
  end

  function n:_is_solid_edge(e, n, t)
    local o, d, n = {}, pxl2cel(n), e and {{n, y}, {n, y + h - 1}, {n, y - h + 1}} or {{x, n}, {x + w - 1, n}, {x - w, n}}
    for f, n in next, n do
      if self:_is_solid_cell(n[1], n[2], t) then
        add(o, e and {celx = d, cely = pxl2cel(n[2])} or {celx = pxl2cel(n[1]), cely = d})
      end
    end
    return o
  end

  function n:_is_solid_cell(e, n, o)
    local e = mget(pxl2cel(e), pxl2cel(n))
    if fget(e, 5) then
      local n = cel2pxl(pxl2cel(n))
      return not (props.climbing or not o or G_player.y >= n)
    end
    return fget(e, 0)
  end

  function n:draw()
    if timers.gem_flash then
      pal_full(9)
    end
    if timers.spirit_flash then
      pal_full(7)
    end
    if timers.crown_celebrate and G_flash <= 0 then
      spr(61, x - 4, y - 11)
    end
  end

end

function init_player_dash()
  local n = envtable {dx = 0, dy = 0}
  local _ENV = n

  function n:decay()
    if active then
      if abs(dx) > 0 then
        dx = dx * (PLAYER_DASH_DX_DECAY)
        if abs(dx) < .15 then
          self:stop()
        end
      else
        self:stop()
      end
    end
  end

  function n:stop()
    active, dx = false, 0
  end

  function n:start_ground()
    dx, active, should_full_boost, grounded, landed = G_player:flip_dx(PLAYER_DASH_DX), true, true, true
  end

  function n:start_air()
    dx, active, should_full_boost, grounded, landed = G_player:flip_dx(PLAYER_AIR_DASH_DX), true, true
  end

  function n:update(n)
    if active and G_player.props.grounded then
      if dx > 0 and btn(0) or dx < 0 and btn(1) then
        self:stop()
      end
    end
    if active and grounded and not n.grounded then
      should_full_boost = false
      dx = dx * (.8)
    end
    self:decay()
  end

  return n
end

function draw_hud()
  if G_credits or G_room.hide_hud or not (G_player.idle_timer > 16 or G_show_hud_until and G_time - G_show_hud_until < 0 or G_room.is_home and G_room.leaf and not G_room.leaf.is_hidden or G_in_void) then
    return
  end
  local e, o, n, d = _hud_layout()
  rectfill(e - 1, o - 1, e + n + 9, o + 11 + 1, 0)
  for n in all(G_rooms) do
    if n.is_mappable then
      local t, f = n.index % 8, n.index // 8
      local e, o, d = e + t * d, o + f * d, G_in_void and 5 or (n.is_complete and 3 or (n.is_visited and 2 or 1))
      if d then
        rectfill(e, o, e + 1, o + 1, d)
      end
      if n.index == G_room.index and G_time % 60 < 20 and not G_in_void then
        rectfill(e, o, e + 1, o + 1, 7)
      end
    end
  end
  if G_in_void then
    print("?", e + 10, o + 3, 7)
  end
  local n, e, o, d, t, f = e + n + 4, o - (G_in_void and 3 or 2), G_in_void and G_spirits_collected or G_leaves_collected, G_in_void and 7 or 3, G_in_void and 45 or SPR_STAIR_FILLED, G_in_void and -2 or -3
  print(o, n - (o > 9 and 2 or 0), e + 2, d)
  spr(t, n + f, e + 8)
end

function hud_leaf(e, o)
  local n = 0
  G_show_hud_until = G_time + 90
  add(G_fx_top, {draw = function(r)
    local d, t = _hud_layout()
    local d, t = d + 31, t + 10
    n = n + (1)
    local f = (n / 28) ^ 2
    circfill(e + (d - e) * f, o + (t - o) * f, 2, 11)
    if n >= 28 then
      fx_init_dust_cloud(11, d, t, false, false, G_fx_top)
      sfx(SFX_THUD)
      screen_shake_vert()
      G_leaves_collected = G_leaves_collected + (1)
      convert_next_stair()
      destroy(r)
    end
  end})
end

function _hud_layout()
  return G_camera_x + (G_player.x - G_camera_x < 40 and G_player.y - G_camera_y < 30 and 95 or 1), G_camera_y + (G_in_void and 2 or 1), 23, 3
end

function add_coro(n)
  local n = cocreate(n)
  add(G_coros, n)
  return n
end

function add_delayed_coro(n, e)
  if e == 0 then
    return n()
  end
  local e = G_time + e
  add_coro(function()
    while G_time - e < 0 do
      yield()
    end
    n()
  end)
end

function play_coros()
  for n = #G_coros, 1, -1 do
    local e = G_coros[n]
    if costatus(e) == "dead" then
      deli(G_coros, n)
    else
      coresume(e)
    end
  end
end

VINE_START_X, VINE_START_Y = 55, 36
G_last_stair_cx, G_last_stair_cy = VINE_START_X, VINE_START_Y

function draw_vines()
  for e, n in next, G_active_vines do
    pal(1, 3)
    spr(mget(n.celx, n.cely), cel2pxl(n.celx), cel2pxl(n.cely))
    pal()
  end
  for n in all(G_vine_path) do
    local e, n, e, o = mget(n.celx, n.cely), cel2pxl(n.celx), cel2pxl(n.cely), n.celx .. ":" .. n.cely
    rect(n, e - 1, n + 8, e + 6, 0)
    if G_stair_shake[o] then
      G_stair_shake[o] = nil
      spr(SPR_STAIR_FILLED, n, e + 1)
    end
  end
end

function convert_next_stair(o)
  if G_leaves_collected - G_stairs_converted <= 0 or G_stair_convert_pending then
    return
  end
  local n, e = G_room.index, G_stairs_converted
  if not (n == 19 and e <= 3 or n == 11 and e <= 28 or n == 10 and e <= 18 or n == 3 and e >= 28) then
    return
  end
  G_stair_convert_pending = true
  add_delayed_coro(function()
    _walk_to_stair(G_last_stair_cx, G_last_stair_cy, true)
  end, o or 22)
end

function _walk_to_stair(n, e, t)
  local o, d = mget(n, e), n .. ":" .. e
  if o == SPR_STAIR then
    mset(n, e, SPR_STAIR_FILLED)
    G_stairs_converted = G_stairs_converted + (1)
    G_last_stair_cx, G_last_stair_cy = n, e
    fx_init_dust_cloud(7, cel2pxl(n) + 6, cel2pxl(e))
    sfx(30, 2)
    sfx(SFX_DOOR_OPEN, 1)
    screen_shake_vert()
    G_freeze = 10
    G_stair_convert_pending = false
    convert_next_stair(0)
  elseif t or _is_vine_tile(o) and not G_active_vines[d] then
    G_active_vines[d] = {celx = n, cely = e}
    for o in all(OFFSETS) do
      local n, e = n + o[1], e + o[2]
      _walk_to_stair(n, e, false)
    end
  end
end

function _is_vine_tile(n)
  for e in all(split "27,42,43,28,44,59,88,89,107") do
    if n == e then
      return true
    end
  end
end

G_void_offset = 0

function init_void_spirit(e, n)
  local _ENV = e
  type, w, h = 9, 3, 3
  index, base_y, x = n, 9 * n - 55 - G_void_offset, 547 + rnd(50)
  G_void_offset = G_void_offset + ((5.2 + (n - 1) * .7) ^ 2 / (2 * GRAVITY))
  draw = draw_ambient_sparkle

  function e:update()
    if not G_in_void then
      return
    end
    room_index = G_room.index
    is_hidden = index > G_spirits_collected
    y = self:wrap_float(is_hidden and 1 or 7)
    if is_hidden then
      pal_full(1)
      spr(45, x - 3, y - 4)
      pal()
    end
  end

end


__gfx__
00000000444444440220222044022220002220444444444402202220011e111ee111e1100aa0aaa0077077701111111111000000222222224444444401111110
00000000440000442220220044022222200000444422224422202200001e11eeee11e100aaa0aa00777077001100001111010000220000224400004411111111
00700700000220002220000240000222220220044022200422200002001eeee11eeee100aaa0000a777000070001100010011000000220002000200211111111
00077000202220222200220240220000220222044000002422002202001e11e11e11e100aa00aa0a770077070111101010111000022220200000220010011001
00077000202200222202220240222022000022044022002422022202001111e11e111100aa0aaa0a770777070011000010110000002200000222222010011001
0070070020000222000220004002202222200004422220240002200000111eeeeee11100000aa000000770000000000010000000000000000222222011111111
00000000002202204400004444000002222220444422204422000022001eee1111eee100aa0000aa770000770000000011010000000000000000220011111111
00000000022200004444444444022200022220444444444402202220011e111ee111e1100aa0aaa0077077700000000011000000000000000000200011111111
4444444444444444440222200220224444444444000000440000000044000000111e111ee11e1111e11e111e0000000000111000000000111111111101111110
4400000000440044440222222220220444000044000020440000000044020000111e11ee111e11e1111e11ee0000000000111000000010110100001011111111
4002202222022004400002202220004400022000000220040000000040022000111eeee1111eeee1111eeee11100000000011100000110010000000011111111
402220222202220440220000220022440222202000022204000022004022200011ee11e111ee11e111ee11e11111000000011111000111010000000011111111
442200220000220440222022220222040022000000002204020222204022000011e111e111e111e111e111e11111100000001111000011010000000011111111
44000222022000044002202200022004000000000000000400022000400000001ee11eeeeee11ee1eee11eee0011100000000011000000010000000011111111
402202222222204444004404440000440000000000002044440000444402000011eeee1111eeee1111eeee110001110000000000000010110000000011111111
4422002002222044444444444444444400000000000000444444444444000000111e111ee11e1111e11e111e0001110000000000000000110000000001111110
444444444000224444444444444444444000220444444444777777770000000011111111e1e111ee000000000001110000111000000000007000000010101010
440000444220224444000044440000444220220444000000000000000000000011111e1111eeeee1000000000001110000111000007070007000000001010101
4002200442200004400220222202200442200004000220220000000000000000111eeee11ee11e11000000110011100001110000007770007000000010101010
4022202442002204402220222202220442002204202220220000000000000000eeee11ee1e111e11000011111111100001110000001710007000000000000000
402200244202220440220000000022044202220420220000000000000000000011e111e1ee11eeee000111111111000001110000006770007000000001010101
400002244002200440000220022000044002200420000220000000000000000011e11ee11eeee111000111001100000001110000007770007000000000000000
44220224440000444402222002222044440000442202222000000000000000001eeeee1111e11111001110000000000000111000007770007000000000000000
4422000444444444444444444444444444222244444444440000000077777777ee111e1e11111111001110000000000000111000007770007000000000000000
cccccccc077777700000000000000000000000000777077777000000000000770b0bb0b000000000001110000001110000000000000000000000000744444444
cc0000cc77777777000000000000000000000000077707777777000000007777b00000031000000101100110000111000bbbbb00000000000000000704000040
000110007777777700099000000000000000000000700070770000000000007700000000111111110111101100001110bbbbbbb0090990900000000700000000
1011101177777777009799000000000000000000007000700000000000000000b0000003000011000011111100001110bbbbbbb0099999900000000700000000
1011001177777777009999000b0000b000700070000000007700000000000077b0000003110111010001111100001110bb7bbb70093993900000000700000000
1000011177777777000990000bb00bb00070007000000000777700000000777700000000111111110000011100001110bbbbbbb0099999900000000700000000
00110110777777770000000000bbbb0007770777000000007700000000000077b00000031000000100000000000111000bbbbb00000000000000000700000000
011100000777777000000000000bb00007770777000000000000000000000000030330300000000000000000000111000b000b00000000000000000700000000
000000000000000000000000000000000000000000000000000000000000000000909000003330000bbb30000bbbbbb000cccc000000000000000000c0c00c0c
00000000000000000000000000000000000000000000000000000000000000000099900003300bb0000b3bb0b333333f0c0000c00000000000000000c0c00c0c
0bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb0000000000033bb0bb0bbb3000b333333fc070000c00000000000000000cc0c0c0
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb00000000000bbbbbb000b3bb0b333333fc000000c00000000000000000c0c00c0
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb000000000000bbbbb0bbb3000b333333fc000000c00000000000cc0000c0c0cc0
bbb7bb70bbbb7bb0bbbbbb70bbbbbbb0bbbbbbb07bbbbbb0bb7bbbb07bbb7bb00000000000000bbb000b3bb0b333333fc000000c000cc000000cc0000c0c00c0
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb000000000000000000bbb3000b333333f0c0000c0000cc0000c0c00c00c0cc0c0
0bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000000000000000000000b3bb00ffffff000cccc000c0c00c00c0c00c00c0c00c0
000bb00000000bb0000000000bbbbbb00bb00000000000000000000000000000000000000000000000000000e11e111e00000000000000000000000000000000
00bbbb000000bbbb00000000bbbbbbbbbbbb0000000000000000000000000000001111000000000000000000111e11ee00000000000000000000000000000000
0bbbbbb0000bb7bb00000000bb7bbb7bbb7bb000000000000000000000707000111111110000000009900000111eeee1c0c00c0c000000000000000000000c00
0b7bbb70000bbbbb00bbbb000bbbbbb0bbbbb00000001100007070000077700011111111110000110090000011ee11e1c0c00c0c000000000000000000c0c7c0
0bbbbbb0000bbbbb0bbbbbb000bbbb00bbbbb00001011110007770000017100011000011111111110990000011e111e10cc0c0c000000000000c00000c7c0c00
0bbbbbb0000bbbbbbbbbbbbb00000000bbbbb000000110000017100000677000000000001111111100000000eee11eee0c0c00c000000000000bbc0000cbc000
00bbbb000000b7bbbb7bbb7b00000000bb7b000011000011006770000077700000000000001111000000000011eeee110c0c0cc0000cb00000cbb00000bc7c00
000bb00000000bb00bbbbbb0000000000bb00000111111110077700000777000000000000000000000000000e11e111e0c0c00c0000bc000000bc000000bc000
0000000000000000000000000000000000000000000000000000000000000000e11e111e000707000000000000111110770000000000b0000000b0000000b000
00000000000000000000000000000000000000000bbbb000000000000bb7b000111e11ee00077700000000000111111177770000000bb0000090b0000090b000
0bbbbb000bbbbb000bbbbb000bbbbb000bbbbb00bbbbbb000bbbbb00bbbbbb00111eeee100017100000000001110011177000000000bb0000070b0000979b000
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bb7bbb00bbbbbbb0bbbbbb0011ee11e10006770000000000110000110000000000000000000bb7000090b900
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbb007bbb7bb0bbbbbb0011e111e1000777000000030011000011007000700000000000000900000b9790
bb7bbb70bbb7bb70bbbb7bb0bbb7bb70bb7bbb70bbbbbb00bbbbbbb0bbb7bb00eee11eee00077700330033001000011100700070000000000000000000000900
bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbbb0bbbbbb00bbbbbbb0bbbbbb0011eeee1100077700033033000001111007770777000000000000000000000000
0bbbbb000bbbbb000bbbbb000bbbbb000bbbbb000b7bb0000bbbbb000bbbb000e11e111e00070700003030000011110007770777000000000000000000000000
00000000000bb000000bb000000bb000000bb000000bb000000bb000000bb00000bbb000fbbb3fff000000000000000000000000000000000000000000000000
0bbbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb000bbbbb000ffb3bb00bbbbb0000bbbbb000000000000000000000000000000000
bbbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbb7000bbb3000bbbbbbb00bbbbbbb00000000000000000000000000800000
bbbbbbb00b7bbb700bbb7bb00bbbbb700bbbbbb007bbbbb00bb7bbb007bbb7b00b7bbbb0000b3bb0bbbbbbb00bbbbbbb00000000080000000080000008780000
bb7bbb700bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbb3000bbbbbbb00bbbbbbb00000000bb800000087000000b808000
bbbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb00bbbbbb000bbbbb0000b3bb0bbbbbbb00bbbbbbb00000000b0000000bb080000b8087800
0bbbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb0000bbbb00000bbb000bbb30000bbbbb0000bbbbb000000000000000000087000087808000
0b00000bb000000bb000000bb000000bb000000bb000000bb000000bb00000000000000b3bb00b000000000000b000000000000000000000000008000000
a1a19133000000000000000000000000000000000000000000000000c7f0f0f1a100003300000000000000003300000000000000c2000000a2b1000000000000
a1a1a100000000000033000081a1a1a1a1a1a1a1a192929292929292929292a1a1a1a1a1a1a1a1a1a1a1b00000000081a1910000300000000000330000000081
a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1f1f1f100003300000000000000003300000000000000a3b1a2a3b2c1b10000000000
a1a1a1a1000000000033000081a1a1a1a1a1a1a1b00000000000000000000081a1a1a1a1a1a1a1b0b00000000000b081a1910000300000000000330000000081
a1a1a19090909090709090909090907090909090709090909090a1903390a1a1a10000330000000000000000330000000000000000c1b20000a2b20000000000
a1a1a1a1a10000940033000081a1a1a1a1a100000000000000000000009400000000a1a1a1a100000000000094000081a1910000300000000000330094000081
a1a1a1909090202020909090949090a1a1202020209090909090a1903390a1a1a10000330000000000009400330000000000000000000000a2a3000000000000
a1a1a1a1a1a1000000330000f1f1f1f1f1f000000000004110101041000000000033a1a1a100000000b0b00000000081a1910000300000000000330000000081
a1a1a19090319090902120909090a1a1a190909090a190909490a190a190a1a1a100003300000000000000003300000000000000000000a2b200000000000000
a1202020202020000033000081a181a1a1a1101041000000434343434343b0828233a19090000000a173630000000081a1910000300000000000330000000081
a1a1a1934090902232a09021909000a1a190909090a19090909090709090a1a1a100003300000000000000003300000000000000002020202020000000000000
a1000000000000000033000081919191a1a1a10000434343a1a1a1a1a1a1a1a191339090900000a1a173630000000081a1910000300000000000330000000081
a1a1a123409090909050909030a190908090909090a1a1a1a1a1a1a1a1a1a1a1a100003300000000000000003300000000000000310000c70000210000000000
a1000000000000000041000081a1a1a1a1a1a14343a1a1b000000081a1a1a1a191339090800000a1a173630023000081a1910000300000000000330000000081
a1a1a1909011909090909090309093a1a1909090908090909090909030a1a1a1a100003300000000000000003300000000000040000000940000003000000000
a1f3f3f3f3f3f3000000000081a1a1a1a1a1a1a1b0000000000000709090a0a1913390909090a1a1a173630000000081a1910000300000000000410000000081
a1a1a1909090119090909090309090a1a190909090a193101010909030a1a1a1a100003300000000000000003300000000000040005000c30050003000000000
a10000000000000000000000b0a1a1a1a1a1b0000000000000000081a1a1a1a191339020202020202073630000000081a1910000300000000000000000000081
a1a1a1239090901011909090309090a1a190909090a190a19070909030a1a1a1a100003300000000000000003300000000000040000000000000003000000000
a1000000000000000000000000b0a1a1b00000000000000000000081a1a1a1a19133400000000000007363000000f381a1910000300000000000000000000081
a1a1a1909090909090109310909090a1a190909090a190a190a1a1a1a1a1a1a1a100003300004141414100003300000000000000110000000000010000000000
a100000000000000000000000000b0b0000000000000000000000081a1a1a1a191334000000000000073630000000081a1910000300000000000000000000081
a1a1a1909090909090809090909090a1a190909090a190a1908090909090a1a1a100003300000000000000003300000000000000001010101010000000000000
a1000000000000000000000000000000000000011010101100000081a1a1a1a191334000230041410073630000000081a1910000300000000000000000000081
a1a1a1a1a1a1a1a1a1a19090909090a1a190909090a190a1a1a190909090a1a1a100003300000000000000003300000000000000000000330000000000000000
a1000000000000000000000000000000000000212020203100000081a1a1a1a191330000000073630073630023000081a1910000300000000000000000000081
a1a1a1a1a1a1a1a1a1a10390909090a1a190909090a19090000000007090a1a1a100003300000000000000003300000000000000000000330000000000000000
a1820382820382b00000000000000000000000000000000000000081a1a1a1a191330000000073630073630000000081a1910000300000000000000000330081
a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a103030303a1a1a100000000a190a1a1a100003300000000000000003300000000000000000000330000000000000000
a1a1a1a1a1a1a100000000004100000000000000000000000000000000000000a1821010101073630073630000000081a19100003082038200828282823381a1
a1a1a1a1a1a1a1a1f0f1f1f0f1f1f0f1f1f0f1f1f0f1f1f0e1e1e1e1a1a1a1a1a100003300000000000000003300000000000000000000330000000000000000
a1a1a1a1a1a1b000000000000041101010f3a1b0434343b08203b04343000000a1a1a1a1a1917363007363000000f381a19100003000009100810000913381a1
b0b0b0b0b0b0b0a1f1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a100003300000000000000003300000000000000000000330000000000000000
a1a1a1a1a1a100000000000000a1a1a1a100919292929292929292929292a100a1a1a1a1a19173630073630000000081a19100003000009100b0a1a1b033b0a1
63000000000000a1f0f1f1f0f1f1f0f1f1f0f1f1f0f1f1f0a1a1a1a1a1a1a1a1a100003300000000000000003300000000001313000000330000000000000000
a1a1a1a1a100000000000000000000a191f3910000000000000000000000a10000a1a1a1a19173630073630000000081a191000030a1a1b00000000000330081
63000000009400a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1f1a1a1a1a1a1a1a1a1a100003300000000000000003300000000131313130000330000001313000000
a1a1a1a10000000000000000000000a1a100910000000000000000000000a1a10000a1a1a19173630073630000008381a1910000300000000000009400330081
63000000000000f0f1f1f1f0f1f1f0f1f1f0f1f1f0f1f1f0a1a1a1a1a1a1a1a1a100003300000000000000003300000000001313000000330000131313130000
a1a1b0000000006500000000009400a1a1f3910000000000650000000000a1a1a10000a1a19173630073630000000081a1910000300000000000000000330081
630022525252522060a1a1a1a1a1a1a1b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b00000b04343434343434343b000000000000000000000330000001313000000
b00000000000b082b0000000000000a1a100910000000000020000000000a1a1a10065a1a1b073630073630000000081a1910000300000000000414100330081
630023000000000030a1a1a1a1a1a1b0000094000061202061202061000000000000e1a1a1a1a1a1a1a1a1a1a100000000000000000000330000000000000000
0000000000000000000000000000000000f3911100000022203200000001a1a1a1a1a1a1b00073630073630094008381a1910000300000000000000000330081
6300000000225252202060a1a1a1a10000000000000000000000000000000000000000a10072727272727200a1000000d1000000000000330000000000000000
000000000000000000000000020033000000912032000000000000002220a1a1a1a1a191000073630073630000000081a1910000300000000000000000410081
6300000000230000000030a1a1a1a100000000000000000000000000000000000000e1a1e3000000000000e2a100000091000000000000330000000000000000
000000000000000000000001400033828282910000000000000000000000a1a1a1a1a191000073630073630000000081a1910000300041410000000000000081
6300000000000000000030a1a1a1a10000000000230043002300430023000000000000a1e3000000000000e2a100000091000000000000330000000000000000
00000000000000000000016040003381a1a1910000002300940023000000a1a1a1a1a191000073630073630000008381a1910000300000000000000000000081
6300000000000022525260a1a1a1b000000000000000a1000000a100000000000000a1a1e3000000000000e2a1009400f0000000000000330000940000000000
000000000000000000222020310033909090800000000000000000000000f1f1f0f1f191000000000000000000000081a1910000300000000000000000000081
63000000000000230000212020200000000000000000a1000000a10000000041a1a1a1a1e3000000000000e2a1000000f0000000000000330000000000000000
00000000000000000000000000003381a1a1b00023000000230000002300a1a1a1a1f1910000000000000000000000f1f1f00000300000000000000000000081
6300000000c70000000000000000000000b082000000a1000000a10000000000a1a1a1a1e3000000000000e2a1000000f0000000000000330000000000000000
0000000000000041101010434310108191b0000000000000000000000000a1a1a1a12391000000000000000000000081a1910000710000000000414100000081
63000000a1a1a110101010434382828282a100000000a1000000a10000000000a1a1a1a10062626262626200a110101091000000000000330000410000000000
0000000000000000000000d0d0d0d0819100000000000000230000000000a1a1a1a1f19100000000000000b003b00081a1910000000000000000000000000081
63000000a13300a1a1a1a1a1a1a1a1a1a1a100000000a1000000a10000000000a1a1a1a10000000000000000a1000000d100000000000033000000000041e010
101010410000000000000000000000819100000000000000000000000000a1a1a1a1f1f0000000000000000000000081a1910000000000000000000000000081
63000000a1a165000000909090909090908000000000a1000000a10000000000a1a1a1a10000000000000000a100000000411010101010101010104100000000
000000000000000000000000000000819100000000000000000000000000a1a1a191a1b0000000411041000000000081a1910000000000820382000000000081
c6434343a1a1a1a1a1a1a1a1a1a1a1a1a1a143434343a1434343a14343434343a1a1a1a10000000000000000a100000000000000000000000000004343434343
4343434343434343434343434343438191434343434343a1a1a14343434343a1a1434343434343434343434343434381a1828203828282a1a1a1434343434381
__map__
2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f002f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f2f1a29292929292929292929292929291a
360000000000000000000000000000000000000000000000000000000000001a1a00000000000000000000341a1a1a1a1d00000000000000000000000000000c1a1a1a1a1a1a5500000000000000002f00000000000000000000000000000000000000000000000000551a1a1a1a1a1a1d000000000000000000000000000018
360000000000000056000049000000000000000000000000000000000000003535000000000000000000001a1a1a1a1a190000000000000000000000000000181a1a1a1a1a1a1a55000000551a1a1a1a29292929292955000000000000000000001602021600000016020202020202297c7c7c7c490000005600000000000018
3600000000000000203200000000000b1100000000000000000000000000000000000000000000000000341a1a1a1a1a190000000000000000000000000000182929292929292929290002020202021a1a0000000000295500000000000000001500000000120213000000007c7c7c7c00000000000000002000000000001018
3600000000000032240000000000000000140000000000000000000000000000000000000000000000001a560000000f0f0000000000000000000000000000070900000000000000000000000000007c007c00000000002902020202020202021300490000000000000010340111000000002000000000220225251100000318
3600002032000000240000000020320000000000000032000000000049000000000000000000000000000b1a1a1a1a1a1900000000000000000000000000001819003434343434000000143434340128280b00490000000000000000000000000000000010340101010106060606010128001225110000000000001223000318
360032240000000024320000322400000000000000000000000032000000000000000000000000000000000b1a1a1a1a1900000000000000000000000000001819002828282828280049000d0d0d00181933000000000010013414340101010101010114000d000000000000181a1a1a19000000121100000000000000000318
360000240000003224000000002400000000000000000000000000000000320000000000000000000000560000000018190000000000003d0000000000000018190007090909090900000000000000181933000000140100000d0d0d00000000000000000000000000000000181a1a1a19000000002100000005000000220218
3600002432000000210000000024320000000000000000000000000000000000000000000000000000001e0000000018190000000000000000000000000000181900292929292929292929290000001819330000000000000000000000000000000000000000000000000000181a1a1a19000000000000000000000000000018
36003224000000000032000032240000000000000000000000000000000000343400003200000000000000000000001819000b0000000000000049000b0000181900000000000032000000001800001819330000000000320000000000000000003100310000000000000000181a1a1a19000000000000000000000000000018
360000210000003200000000002100000000000000000000000000000000001a1a0000000000003200000000000000181900002a3a2a1b000000000000000018190b0b343434343434343400180000181933000031310000000000000000000031000000310000000000000007090a1a19000032000000000000000000320018
360000003200000000000000000032000000000000000000000000000000001a1a0000000000000000000000000000181900001c582b1c1b00000000000000181a1a1a1a292929292929293218000b1819330031313131000000313100000031000034000031000000000000181a1a1a19000000000000003200000000000018
360032000000000000000000320000000000000000000000000000000000001a1a000000000000000000000000490018190000001401013a01011400000000181a1a1a1900000000000000001800001819330000313100003100000000310000003428340000310000000000181a1a1a19000000000000000000000000000018
360000000000000000000000000000000000000000000000000000000000001a1a000000343434000000000000000018190000000000002c00000000000000181a1a1a190056000000000000180b00181933000000000000000000000000000034281a283400000031000000181a1a1a19000000000000000000000000000018
360000000000000000000000000000000000000000000000330000000000001a1a343434282828343434000000000018190000000000003a581b0000000000181a1a1a19001834343434343418000018190b0000000000000000000000000034281a1a1a2834000000000000181a1a1a19313131003131313100003131310018
6c343434343434343434343434340b0b3434340b34343434333434343434341a1a2828281a1a1a28280b00001401010c1d00000000000000003a0000000000181a1a1a19001828282828281a1a000b18193434343434343434343434343434281a1a1a1a1a28343434343434181a1a1a19313131313131313131313131313118
1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a000000000000003300000000000018360000000000000000000000000000000000000000000000002c00000000000c1d0000000000000000000000000000001a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a060602020202020202020206061a1a1a19313131003131313100003131310018
19020202000000000000000000000000000000000000000033000000000000183600000000000000000000000000000000000000000000002a3a000000000018190000000000000000000000000000000000000000020202020202021a1a1a1a060400000000000000000003061a1a1a19000000000031310000000000000018
190000000000000000000049000000381100004900000000330000000000000c36000000000000000000002a1b00000000000000000000001c1b00000000001819000000000000000000000000000000000000000000000000000000031a1a1a0213001001010101011100120202021a19000000000000000000000000000018
190000000000000000000000000038000400000000383838383838380000000000000000002a3a5859583a582b0000000000490000000000001c3a000000000f0f0000000000313131313131000000000b2828000000000000000000031a1a1a0000000306060606060400000000001819000000000000000000000000000018
193f3f3f000000000000000000380000040000003800000000000000380000000000002a592b00000000001c581b0000000000000000002a1b003b000000000f0f000000003131313131313131000000000000010111000000320000031a0000001a01060602020202062525251100181d0000000c0000000000004900000018
190000000000000000000000380000000400003800000000000000000038000000002a2b0000000000000000003a1b002a3a1b000000003b1c3a2b000000000f0f000000313131313131313131310000000000160213000000000000031a001a1a33030604000000002400000024000000000000180000000000000000000018
190000000000000000000038000000000614380000000000000000000000000101142c00000000000000000000003b003b002c0000002a3a0000000014010119190000003131003131313149313100000000000000000000000000000300001a1a33120213002223002100490003110000000000180000000000000000000018
1900313131000031313138003131310019000000000000000000000000001a1a36003a1b000000004900000000003a582b003a0000002c000000000000000018190000003131313131313131313100000000000000000000100101011a001a1a1a330000000000000000000000030601010e0000180000000000000000000018
19003131310000313138000031323100190000000000000000000000001a1a1a36002a2b00000000000000000000000000001c1b00001c593a1b000000000018190000000031313131313131310000000000000000320000030000001a00001a1a33222501011132200022252502020219190000180000000000000000000018
190031333100003138310000313131001900000000000000000000001a1a1a1a36003a00003100000000003100003a59583a001c1b000000002c002a1b000018190000000000313131313131000000000000000000000000030000001a1a001a1a33000012020400240000000000000009080000180000000000000000000018
1900003300000038000000000000000019000000000000000000001a1a1a1a1a36002c00000000000000000000002c00001c1b001c6b0000001c3a582b000018190000000000000000000000000000000000000000000000170049001a00001a1a332000000024322400001a2929291a1a190000180000000000000000000018
19000033000038000000000000000000190000000000000000001a1a1a1a1a1a36003b2a3a00000000000000002a3a0000003a00003a002a1b002a2b00000018190000000000000000000000000000000000001401010114000000001a001a1a1a3312252300240024001019000056181a190000180000000000000000000018
190000330038000000000000000000001900000000000000001a1a1a1a1a1a1a362a582b3b00002a3a1b00002a2b0000002a2b00001c1b1c3a582b00000000181900000000000000000000000000000000000000000000000000000000001a1a1a330000000024322400031900001e181a190000030000000000330000000018
190000333800000000000000000000001d0000000000001e1a1a1a1a1a1a1a1a361c2b331c59582b001c593a2b000000003a000000001c592b0000000000001819343434340000000000000000000000001038383838383838383838380b1a1a1a0101010101040021000319000000181a190000030000000000333000003018
1934343300000000000000000000000000000000000000001a1a1a1a1a1a1a1a6c343433343434343434343433343434001c59581b00000000000000000000181a1a1a1a1a0000000033000000001401010000000000000000000000000000001a1a1a1a1a1a040000000319000000181a190000030000000000330000000018
1a1a1933000000000000000000000000000000000000001e00000000000000560b0b0b330b0b0b0b0b0b0b0b330b0b0b000000003a000000000000000000000c1a560000001401011433140114343434343434343434343434343434343434341a1a1a1a1a1a1a2828281a1a000000181a190000030000000000330000000018
__gff__
00030509111f818080000001010103800b130d150311050981818100000121801b1d0f171907634581810000000049010300008000000000808000000000512300000000000000000020000100000000000000000001000000000081000000000000000000000000810080000000000000000000000000000020000000000000
__sfx__
4907191f0073400730007300073000730057310573005730077310773007730077300773007730077300773007730077300773007730077300773007730077300773007730077300773007730077300773007740
310e10131f7341f7301d7211d7201d7201d7201d7201d7201d7201872118720187201872018720187201872018724187201871500700007000070000700007000070000700007000070000700007000070000700
010e0b0e1f7641f7601d7511d7501d7501d7501d7501d7501d7501d7501d7551d7441d7401d745187001870018700187001870000700007000070000700007000070000700007000070000700007000070000700
494a131f0b7640c7610c7610c7600c760137611376013760137611376013760137601376013760137601376013760137601376013760137601376013760137601376013760137601376013760137601376013760
300f00000b7040b7050570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
300f00000c7040c7050570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
300f000010704107050570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000011704117050570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000013744137450770501700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000017744177450570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000018744187450570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f00001c7541c7550570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f00001f7441f7450770501700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
010100000c7340e0311103114001170011700014001120010f0010c10100100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010100000d7340f0311103114000170001700014001120010f0010c10100100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
010100000b7340d0310f03111001130011700014001120010f0010c10100100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
910400000d02500000120250000023005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000012765117650f7550e7550d7550c7550b7450a745097450874507735067350573504735037350273501725017150470503705017050770506705067050570504705047050370502705017050170501705
490200000e0551c0002d0021e005370021c0051300213002130021300213002130021300213002130021300213002130021300213002130021300213002130021300207002070022b0001f0001f0021f0021f002
310100002b02430031000000000000000010010100001000020010200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000
01080000081630815308153081031b1031a1030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490900000076502765057650a7650c7750e77511775167002400526005290052e0053000532005350053a00500000000000000000000000000000000000000000000000000000000000000000000000000000000
190a000000074000000000000000000000100001074010000000004000010001300002000020000207402000000000400001000130001a000020000000000000000000400001000130001a000020000000000000
610a00000c7540e7551076513765187751a7751f7752476524700237001370011700107000c700357053a7050c7000e7001070011700137002370024700247000070000700007000070000700007000070000700
010100000c0350c0050c005110550c0050c0050c00516005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010100000773500000000000710500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490200002f72534724000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
490200000b77004770017500a7501304005040010400d7000b7000770005700037000270002700027000270001700017000170501700017000170001700007000070000700007000070000700007000070000700
617400000057500500005000050000500005000050034500005000050000500005000050032500005003050000500005002b50018500215001f50000500285001a5000050000500185000050029500005002b500
610200002b75400700007000070500700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
137300001387500800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
610900001d7251f7252472528725187001a7001d700167002470526705297052e7053070532705357053a70500700007000070000700007000070000700007000070000700007000070000700007000070000700
490800001057513554135000050000500005000050034500005000050000500005000050032500005003050000500005002b50018500215001f50000500285001a5000050000500185000050029500005002b500
794100002487524875137000c7000c700008000c700348000080000800008000c7000080032800008003080000800008002b80018800218001f80000800288001a8000080000800188000080029800008002b800
a9210000007350c7310c7350c7440c7450c7000c700057740c7000c7000c70007700077740070000700007000070000774007000c700007000070000700007000070000700007000070000700007000070000700
092100000c04518041180451805418050180000c000050000c0000c0000c00007000070000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000
a9040000130001500017000180001a0001c0001d000160002400026000290002e0003000032000350003a00000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1d00000188241883118835118001f0001d8241d8201d8301d8351d8001d8001d80000000000001593415930159301592500000000001fd001fd001fd0013924139301393511b000000000000000000000000000
c9e9000018814188101882018825029001d8241d8201d8251d8001d8000000013a2413a2013a2513a000000000000179000b9240b9200b9200b9250000000000000000000011a2411a2011a25000000000000000
01fa00000cb0018a2418a2018a2518a00029001d8001d8001d8001d8001d8000000015a2415a1015a1513a000000000000179000b9000b9000b9000b9000000000000000000000011a2411a2011a250000000000
001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9e9000018834188301883518800029001d8001d8001d8001d8001d8000000013824138201382513a000000000000179001781417810178101781500000000000000000000118241182011825000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
310f000000754007550700501000010000000000000000001a0001b00000000080001800016000150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
310f000004754047550570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000005754057550570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000007744077450770501700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f00000b7440b7450570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f00000c7440c7450570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000010744107450570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
310f000011754117550570001700017000070000700007001a7001b70000700087001870016700157000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
__music__
07 22622321
01 68696828
00 41426929
00 6c42432b
00 4142282a
00 4142682b
00 6c42432c
02 6c422829
00 4142686b
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007770000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000067777777677777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000677777776777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000677777776777777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000677777776777777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777777777777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007770666077777770777777770006660000000000000000000000000000000000000000000000000000777000000777000000000000000000000
00000000000077777777677777777077777700777777000000000000000000000000000000000000000000000000007777770777777700000000000000000000
000000000000777777777777777777777777777777777000000000000000000j0000000000000000000000000000077777777777777770000000000000000000
00000000000077777777777777776777777777777777770000000000000000000000000000000000000000000000777777777777777776000000000000000000
00000000000007777777677777776777777777777777770000000000000000000000000000000000000000100000777777777777777776000000000000000000
00000000000067777777677777776777777777777777770000000000000000000000000000000000000000000000777777777777777776000000000000000000
00000000000067777777677777777777777777777777700000000000000000000000000000000000000000000000077777776777777770000000000000000000
00000000000067777777777777777777777777777777700000000000000000000000000000000000000000000000077777776777777770000000000000000000
00000000000006777777007777770777777766777777700000000000000000000000000000000000000000777666067766676677766670777066600000000000
00000000000000007770007777770077777760666777000000001000000000000000000000000000000007777777677777770777777767777777660000000000
00000000000000000000077777777777777776000000000000000000000000000000000000000000000007777777777777777777777777777777760000000000
00000000000000000000677777777777777776000000000000000000000000000000000000000000000007777777777777777777777777777777760000000000
00000000000000000000677777777777777776000000000000000000000000000000000000000000000077777777777777777777777767777777700000000000
00000000000000000000677777777777777770000000000000000000000000000000000000000000000077777777777777776777777767777777770000000000
00000000000000000000077777777777777770000000000000000000000000000000000000000000000077777777777777776777777767777777770000000000
00000000000000000000077777777777777770000000000000000000000000000000000000000000000007777777777777776777777777777777770000000000
000000000000000000000777777766777777700000000000a0000000000000000000000000000000000000777777777777776666677770777777700000000000
00000000000000000000007776660066677700000000000000000000000000000000000000000000000000066600077777777677777777077700000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000677777777777777777000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000677777777777777770000000000000000000
00000000000000000000000000000000033300000000033300000000333333333300000003333333333300000333333333337777777776000000000000000000
00000000000000000000000000000000333330000000333330000003333333333330000033333333333330003333333333333777777776000000000000000000
00000000000000000000000000000003333333000003333333000033333333333333000333333333333330033333333333333777777776000000000000000000
00000000000000000000000000000003333333300033333333000333333333333333300333333333333330033333333333333677777760000000000000000000
00000000000000000000000000000033333333333333333333300333333333333333300333333333333310033333333333331007770000000000000000000000
00000000000000000000000000000033333333333333333333303333333311333333330333331111111100033333111111110000000000000000000000000000
00000000000000000000000000000033333333333333333333303333333100133333330333330000000000033333000000000000000000000000000000000000
00000000000000000000000000000033333333333333333333303333330000003333330333333333333000033333333333300000000000000000000000000000
00000000000000000000000000000033333333333333333333303333330000003333330333333333333300033333333333330000000000000000000000000000
00000000000000000000000000000033333331333331333333303333330000003333330333333333333330033333333333333000000000000000000000000000
00000000000000000000000000000033333330133310333333303333330000003333330133333333333330013333333333333000000000000000000000000000
00000000000000000000000000000033333330011100333333303333330000003333330033333333333330003333333333333000000000000000000000000000
00000000000110000000000000000033333330000000333333303333330000003333330013333333333330001333333333333000000000000000000000000000
00000000010110000000000000000033333330000000333333303333333000033333330001111111333330000111111133333000000000000000000000000000
00000000110010000000000000000033333330000000333333303333333300333333330000000000333330000000000033333000000000000000000000000000
00000000111010000000000000000033333330000000333333301333333333333333310033333333333330003333333333333000000000000000000000000000
00000000011010000000000000000033333330000000333333301333333333333333310333333333333330033333333333333000000000000000000000000000
00000000000010000000000000000033333330000000333333300133333333333333100333333333333330033333333333333000000000000000000000000000
00000000010110000000000000000033333330000000333333300113333333333331100333333333333310033333333333331000000000000000000000000000
00000000000110000000000000000013333310000000133333100011333333333311000133333333333110013333333333311000000000000000000000000000
00000011011110000000000000000011111110000000111111100011111111111111000111111111111110011111111111111000000000000000000000000000
0000011101101000000000000000000111110000000001111100000111111111111000001111111111110000111111111111000000000000000j000000000000
00000111000010000000000000000000111000000000001110000000111111111100000001111111111000000111111111100000000000000000000000000000
00000110011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110111010000000000000000000033300000000033300000000333333333300000003333333333300000333333333330000000000000000000000000000
00000000110010000000000000000000333330000000333330000003333333333330000033333333333330003333333333333000000000000000000000000000
00000110000110000000000000000003333333000003333333000033333333333333000333333333333330033333333333333000000000000000000000000000
00000011011110000000000000000003333333300033333333000333333333333333300333333333333330033333333333333000000000000000000000000000
00000011011110000000000000000033333333333333333333300333333333333333300333333333333310033333333333331000000000000000000000000000
00000111011010000000100000000033333333333333333333303333333311333333330333331111111100033333111111110000000000000000000000000000
00000111000010000000000000000033333333333333333333303333333100133333330333330000000000033333000000000000000000000000000000000000
00000110011010000000000000000033333333333333333333303333330000003333330333333333333000033333333333300000000000000000000000000000
00000110111010000000000000000033333333333333333333303333330000003333330333333333333300033333333333330000000000000000000000000000
00000000110010000000000000000033333331333331333333303333330000003333330333333333333330033333333333333000000000000000000000000000
00000110000110000000000000000033333330133310333333303333330000003333330133333333333330013333333333333000000000000000000000000000
00000011011110000000000000000033333330011100333333303333330000003333330033333333333330003333333333333000000000000000000000000000
00000011111100000000000000000033333330000000333333303333330000003333330013333333333330001333333333333000000000000000000000000000
00000111111110000000000000000033333330000000333333303333333000033333330001111111333330000111111133333000000000000000000000000000
00000111111110000000000000000033333330000000333333303333333300333333330000000000333330000000000033333000000000000000000000000000
00000100110010000000000000000033333330000000333333301333333333333333310033333333333330003333333333333000000000000000000000000000
00000100110010000000000000000033333330000000333333301333333333333333310333333333333330033333333333333000000000000000000000000000
00000111111110000000000000000033333330000000333333300133333333333333100333333333333330033333333333333000000000000000000000000000
00000111111110000000000000000033333330000000333333300113333333333331100333333333333310033333333333331000000000000000000000000000
00000111111110000000000000000013333310000000133333100011333333333311000133333333333110013333333333311000000000000000000000000000
00000011111100000000000000000011111110000000111111100011111111111111000111111111111110011111111111111000000000000000000000000000
00000111111110000000000000000001111100000000011111000001111111111110000011111111111100001111111111110000000000000000000000000000
00000111111110000000000000000000111000001000001110000000111111111100000001111111111000000111111111100000000000000000000000000000
00000100110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001101111000000000000000000000000000000000000000000000000000000000000000000000000uuuuuuuu00000000000000000000000000000000000
0000011101101000000000000000000000000000000000000000000000000000000000000000000000000uu0000uu00000000000000000000000000000000000
00000111000010000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000
00000110011010000000000000000000000000000000000000000000000000000000000000000000000000222202000000000000000000000000000000000000
00000110111010000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000
00000000110010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000110000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011011110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000uuuuuuuuuuuuuuuuuuu
000000000101100000000000000000rrrrr00000000000000000000000000000000000000000000000000000000000000000000000000uu0000uuuu0000uuuu0
000000001100100000c0000000000rrrrrrr000000c0000000000000000000000000000000000000000000000000000000000000000000002200020002002000
000000001110100c0c7c000000000rrrrrrr000c0c7c000000000000000000000000000000000000000000000000000000000000000000222202000002200202
00000000011010c7c0c0000000000rr7rrr700c7c0c0000000000000000000r0000r000000000000000000000000000000000000000000022000002222220202
000000000000100crc00000000000rrrrrrr000crc00000000000000000000rr00rr000000000000000000000000000000000000000000000000002222220200
000000000101100rc7c00000000000rrrrr0000rc7c00000000000000000000rrrr0000000000000000000000000000000000000000000000000000002200002
0000000000011330rc330330300303r333r00330rc0030000000000000000000rr00000000000000000000000000000000000000000000000000000002000022
000000000000033333333333333333333333333333333uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu000000000000000000000000000
000000000000033333333333333333333333333333333uu0000uuuu0000uuuu0000uuuu0000uuuu0000uuuu0000uuuu0000uu000000000000000000000000000
00000000000003332300000022000333233033332330300022000000220000002200000022000000220000002200000022000000000000000000000000000000
00000000000000222202020222022202220222022202220222022202220222022202220222022202220222022202202222020000000000000000000000000000
00000000000000022000020220022202200222022002220220022202200222022002220220022202200222022002200220000000000000000000000000000000
00000000000000000000020000222200002222000022220000222200002222000022220000222200002222000022200000000000000000000000000000000000
00000000000000000000000220220002202200022022000220220002202200022022000220220002202200022022000000000000000000000000000000000000
00000000000000000000002220000022200000222000002220000022200000222000002220000022200000222000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000700070j070007000700070007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000700070007000700070007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077707770777077707770777077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077707770777077707770777077
__meta:title__
moss moss
by noel cody
