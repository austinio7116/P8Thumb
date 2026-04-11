pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

--pico valley v1.0
--a demake by taxicomics
--init
poke(0x5f2c, 3)
cartdata("harvestpoon")

function _init()
  music(1)
  --pvars
  part = {}
  pp = {}
  p = 0
  wood = 0
  stone = 0
  money = 80
  has_rod = 0
  chicks = 0
  cows = 0
  artifacts_found = 0
  --how many artifacts were found
  artifacts_given = 0
  --how many artifacts were handed in
  build_progress = 0
  --0=nothing
  --1=2nd field
  --2=coop
  --3=3rd field
  --4=barn(completion)
  mine_level = 0
  --static progression
  artifacts = {"old hammer", "rolling pin", "purple shorts", "watering can", "hoe", "pickaxe", "axe", "ruby", "geode", "emerald", "diamond", "cracked crystal", "prismatic shard", "crown"}
  --all the artifacts
  --gamevars
  debug = 0
  is_swimming = false
  is_fishing = false
  fish_cd = 0
  fish_y = 0
  fisher_y = 0
  bar_size = 5
  fish_state = 0
  fish_progress = 0
  fish_dir = 0
  fish_move_cd = 0
  what_fish = 1
  fish = {}
  freshwater_fish = {
  --name,speed,value
  {"pike", 2, 15}, {"catfish", 3, 20}, {"walleye", 1, 10},}
  saltwater_fish = {
  --name,speed,value
  {"salmon", 2, 15}, {"anchovy", 1, 10}, {"barracuda", 3, 20},}
  fish_progress_max = 100
  dia = split_str("welcome to pICOvALLEY! this is your new home, pelican town!")
  gui_color = 2
  gui_font_color = 7
  rnd_mine_loot = {{"stone"}, {"stone", "metal"}, {"crystal", "metal", "stone"}, {"gold"},}
  grass_loot_table = {"flower", "apple", "wood"}
  chick_flip_flop = true
  cow_flip_flop = true
  mine_stones_left = 0
  mine_stones_max = 9
  sell = {}
  sell_value = 0
  weather = 1
  --1=dry,2=rain
  rnd_stuff_count = 0
  rnd_stuff_max = 15
  trans = 0
  --transition progress
  game2_state = 0
  outside_x = 7 * 8
  outside_y = 15 * 8
  sell_scroll = 0
  maxy = 0
  interior_offset = 64 * 8
  timer = 0
  timercd = .2
  anim = 0
  minute_timer = 0
  minute_timer_cd = 3.5
  tempx = 0
  tempy = 0
  temp = 0
  px = 0
  py = 0
  rx = 0
  ry = 0
  cx = 100
  cy = 100
  maxenergy = 120
  energy = maxenergy
  chosen_item = 1
  game = 0
  day = 1
  hour = 7
  minute = 0
  cloudspeedmax = .2
  cloudsize = 10
  clouds = {}
  for i = 0, 12 do
    local cl = {x = rnd(64), y = rnd(55), xdir = (-rnd(cloudspeedmax) - .1) * (1 - (flr(rnd(2)) * 2)), c = flr(rnd(2)) + 6, size = cloudsize + rnd(cloudsize)}
    add(clouds, cl)
  end
  npc = {
  --museum
  {103, 13, "old hammer this was once used to destroy boulders."}, {104, 13, "rolling pin this was used to make great pizza!"}, {105, 13, "purple shorts nobody knows how these shorts ended up in the potluck soup."}, {106, 13, "watering can this was once the best tool to water ancient fruit"}, {107, 13, "hoe whoever found this,your mom's a \xe2\x99\xa5"}, {108, 13, "pickaxe legend has it that a man in a blue shirt lost this here after trading his emerals for cake"}, {109, 13, "axe lizzie lost this one. give it 40 whacks!"}, {103, 15, "ruby a red gem that somebody must have lost here."}, {104, 15, "geode people used to crack these open at the local blacksmith."}, {105, 15, "emerald it was once a currency,but it lost its value."}, {106, 15, "diamond they are my best friend"}, {107, 15, "cracked crystal an enormous amount of force is necessary to crack these"}, {108, 15, "prismatic shard extremely rare! is rumored to have magical uses."}, {109, 15, "crown this crown is the proof of completion"},
  --signs
  {11, 14, "if you want to sell what you found or grew just put it in the bin to sell it."}, {37, 9, "our community center was renovated a few years ago. we cherish it and it brought us closer together."}, {39, 20, "the stardrop saloon was recently rebuilt, it is a bit smaller now. but it stays open day and night and allows you to always take the edge of a hard day of work."}, {36, 23, "our beloved mona"},
  --npcs
  {105, 3, "hi there! if you want to buy something just pick it up. thank you for shopping at pierre's!"}, {119, 35, "welcome to the stardrop saloon! nice to have you here. stay a little, play on the arcade or... play on the arcade."}, {116, 37, "we used to have a bus, you know? and i was the one driving it! but nobody wants to leave pelican town nowadays..."},}
  --ports
  ports = {
  --home
  {7, 123, 4,},
  --stardrop saloon
  {38, 118, 37,},
  --museum
  {57, 105, 16,},
  --coop
  {9, 119, 27,},
  --train station
  {40, 77, 9,},
  --bath house
  {70, 105, 23,},
  --exit bath house
  {106, 71, 9,},
  --beach
  {41, 78, 18,},
  --shop
  {34, 105, 5,},}
  --upgrade_data
  upgrades = {{0,
  --progress 1
  10,
  --wood 2 
  25,
  --stone 3
  999,
  --gold 4
  "hi! do you want to expand your farmspace? bring me 10 wood and 25 stone and pay the fee of 999\xe2\x97\x8f",}, {1, 25, 25, 2499, "i hope you like the extra farmspace.do you need a coop? bring me 25 wood,25 stone and pay the fee of 2499\xe2\x97\x8f",}, {2, 10, 50, 999, "the coop is a great source of joy and money.do you need more farmspace? bring me 10 wood, 50 stone and pay the fee of 999\xe2\x97\x8f",}, {3, 100, 100, 4999, "you now have the biggest possible farmspace. do you need a barn? bring me 100 wood, 100 stone and pay the fee of 4999\xe2\x97\x8f",},}
  --lovers
  lovers = {{frame = 84, name = "leah", text = {"hi there!", "i love pelican town, it is so inspiring.", "my old girlfriend didnt appreciate my art as much as you do", "can i maybe hang a few of my pictures here?",}, likes = "tomato", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {14, 28}, house_pos = {121, 2},}, {frame = 86, name = "haley", text = {"do i know you?", "bold styling choice. i would never.", "i've gotten really into photography - can i take your picture?", "i'm so happy to live here, that parrot was getting on my nerves...",}, likes = "sunflower", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {31, 19}, house_pos = {122, 2},}, {frame = 87, name = "elliot", text = {"hey love, welome to pelican town!", "i've been working on this poem, maybe you can listen to it?", "do you want to come to my recital? i wrote some great new stuff.", "now i just need to find a spot for my piano...",}, likes = "salmon", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {81, 19}, house_pos = {123, 2},}, {frame = 88, name = "harvey", text = {"nice to meet you! i'm pelican town's doctor", "you're working really hard, maybe you should rest a little in the bathhouse.", "you know they say 'an apple a day keeps the doctor away' - not in my case.", "i'll make us some more coffee, okay?",}, likes = "apple", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {67, 9}, house_pos = {124, 2},}, {frame = 89, name = "shane", text = {"what do you want?", "why do you keep bothering me?", "nowadays i'm only at the pub to game. still feels strange.", "i used to have blue chicken, but i gave 'em to somebody else.",}, likes = "strawberry", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {61, 13}, house_pos = {120, 4},}, {frame = 85, name = "abigail", text = {"are you the new famer? hi!", "have you seen my highscore one the arcade? try beating it!", "crystal posess great power,you know?", "i'm so happy not to live with my dad anymore. lately he's been really weird about my hair color... weird.",}, likes = "crystal", friendshiplevel = 0, given_gift = false, offered_gift = "", pos = {108, 4}, house_pos = {121, 4},},}
  --player functions,inventory etc
  addchar(outside_x / 8, outside_y / 8, "player")
--add_item("sUNFLOWER sEED",5,3)
end

-->8
--update
function _update()
  if time() > timer then
    timer = time() + timercd
    anim = 1 - anim
  end
  if time() > minute_timer then
    --simulating time
    if game == 1 then
      minute = minute + (10)
      if minute > 50 then
        minute = 0
        hour = hour + (1)
        if hour > 23 then
          sleep()
        end
      end
    end
    minute_timer = time() + minute_timer_cd
  end
  if game == 0 then
    if btnp(5) then
      --new game
      transition()
      game = 1
      water(weather)
      progress()
    end
    if btnp(4) or dget(0) > 0 then
      --load game
      transition()
      load_game()
      water(weather)
      dia = {}
      game = 1
    end
  end
  --game
  if game == 1 then
    if #dia == 0 and is_fishing == false and trans == 0 then
      foreach(pp, function(obj)
        obj:update()
      end)
    end
    p = pp[1]
    px = p.x
    py = p.y
    --rules
    if energy <= 0 then
      sleep()
    end
    --interacctionframe
    if p.look == 0 then
      rx = px
      ry = py - 8
    elseif p.look == 1 then
      rx = px + 8
      ry = py
    elseif p.look == 2 then
      rx = px
      ry = py + 8
    elseif p.look == 3 then
      rx = px - 8
      ry = py
    end
    --managing items
    if btnp(4) and #dia == 0 and is_fishing == false then
      chosen_item = chosen_item + (1)
      if chosen_item > #p.inv then
        chosen_item = 1
      end
    end
    for i in all(pp[1].inv) do
      if i[2] <= 0 then
        del(pp[1].inv, i)
      end
    end
    --interactions with and wo btn
    temp = mget(flr((px + 4) / 8), flr((py + 4) / 8))
    temp2 = mget(flr((rx + 4) / 8), flr((ry + 4) / 8))
    if #dia > 0 then
      if btnp(4) then
        deli(dia, 1)
        deli(dia, 1)
      end
    end
    is_swimming = false
    if fget(temp, 5) then
      p_pos_x = flr((px + 4) / 8)
      for i in all(ports) do
        if p_pos_x == i[1] then
          --if at correct position port
          --the player there
          transition()
          if temp ~= 217 and temp ~= 218 then
            if p_pos_x == 41 then
              outside_x = px
              outside_y = py - 12
            else
              outside_x = px
              outside_y = py + 4
            end
          end
          pp[1].x = i[2] * 8
          pp[1].y = i[3] * 8
        end
      end
    end
    --end port statement
    if temp == 233 or temp == 234 then
      --set swimming
      is_swimming = true
      if rnd(5) < 1 then
        energy = energy + (1)
      end
      if energy > maxenergy then
        energy = maxenergy
      end
    elseif temp == 32 or temp == 50 then
      --mines
      --mines_start
      transition()
      if mine_level == 0 then
        outside_x = px
        outside_y = py + 4
      end
      pp[1].x = 121 * 8
      pp[1].y = 11 * 8
      generate_mines()
    elseif fget(temp, 6) then
      transition()
      --back out
      mine_level = 0
      pp[1].x = outside_x
      pp[1].y = outside_y
    end
    --go on with interactions
    if btnp(5) and #dia == 0 and is_fishing == false then
      tempx = flr((rx + 4) / 8)
      tempy = flr((ry + 4) / 8)
      temp = mget(tempx, tempy)
      if temp == 6 or temp == 2 then
        if #p.inv > 0 then
          --plant plants
          p.inv[chosen_item][2] = p.inv[chosen_item][2] - (1)
          if p.inv[chosen_item][1] == "tOMATO\xe2\x96\x91" then
            addchar(tempx, tempy, "tomato")
          elseif p.inv[chosen_item][1] == "sUNFLOWER\xe2\x96\x91" then
            addchar(tempx, tempy, "sunflower")
          elseif p.inv[chosen_item][1] == "strawberry\xe2\x96\x91" then
            addchar(tempx, tempy, "strawberry")
          else
            mset(tempx, tempy, 6)
            p.inv[chosen_item][2] = p.inv[chosen_item][2] + (1)
          end
        end
      elseif fget(temp, 2) then
        --talk to lovers
        check_lovers(temp, tempx, tempy)
      elseif fget(temp, 1) then
        --talk to signs and npcs
        lookup_npc(tempx, tempy)
      elseif temp == 252 then
        --play prairie king
        --and save wares-value
        sell_value = 0
        for i in all(sell) do
          sell_value = sell_value + (i[2] * i[3])
        end
        dset(63, sell_value)
        save_game()
        dset(0, hour)
        load("#jotpkdemade-3", "stop playing")
      elseif temp == 14 then
        --find artifacts
        mset(tempx, tempy, 3)
        if artifacts_found < #artifacts then
          artifacts_found = artifacts_found + (1)
          dia = {"you found", artifacts[artifacts_found]}
        else
          dia = split_str("the mole problem is getting worse")
        end
      elseif temp == 34 then
        --harvest plants
        check_pos(tempx * 8, tempy * 8)
        mset(tempx, tempy, 6)
      elseif temp == 19 then
        --water plants
        energy = energy - (1)
        xplode(tempx * 8 + 4, tempy * 8 + 4, 12)
        sfx(2)
        mset(tempx, tempy, 18)
      elseif temp == 95 then
        if has_rod == 0 and day > 1 then
          dia = split_str("you know what new farmer? the fishing scene here could use some young blood. take this fishing rod and try your luck!")
          has_rod = 1
        else
          if has_rod == 0 then
            dia = split_str("hi! i'm willy, the local fisher. you should give fishing a try sometime. maybe i have an old rod i can give you... come by tomorrow, maybe i will find it until then.")
          else
            dia = split_str("how is your fishing goin? remember there are freshwater and saltwater fish. try catching both!")
          end
        end
      elseif temp == 9 and #p.inv > 0 then
        --sell stuff
        add_sell(p.inv[chosen_item][1], 1, p.inv[chosen_item][3])
        --add sell sound
        xplode(tempx * 8 + 4, tempy * 8 + 2, 10)
        p.inv[chosen_item][2] = p.inv[chosen_item][2] - (1)
      elseif temp == 24 or temp == 8 then
        --sleep	
        sleep()
      elseif temp == 65 then
        --buy sunflower seeds
        if money >= 5 then
          money = money - (5)
          add_item("sUNFLOWER\xe2\x96\x91", 1, 3)
        else
          dia = split_str("you need 5\xe2\x97\x8f to buy these seeds")
        end
      elseif temp == 66 then
        --buy tomato seeds
        if money > 5 then
          money = money - (5)
          add_item("tOMATO\xe2\x96\x91", 1, 3)
        else
          dia = split_str("you need 5\xe2\x97\x8f to buy these seeds")
        end
      elseif temp == 83 then
        --buy strawberry seeds
        if money >= 10 then
          money = money - (10)
          add_item("strawberry\xe2\x96\x91", 1, 3)
        else
          dia = split_str("you need 10\xe2\x97\x8f to buy these seeds")
        end
      elseif temp == 4 or temp == 22 then
        --fishing minigame
        if has_rod == 1 then
          start_fishing()
        else
          dia = split_str("you need a fishing rod to fish here. maybe ask willy for one.")
        end
      elseif temp == 82 then
        --donate to museum
        if artifacts_found > artifacts_given then
          artifacts_given = artifacts_given + (1)
          dia = split_str("thank you for your donation!")
          update_artifacts()
        elseif artifacts_given == 14 then
          dia = split_str("thank you so,so much for your donations! now you can learn everything there is to know about pelican town.")
        else
          dia = split_str("you can talk to me if you have something to donate to the museum here in pelican town")
        end
      elseif temp == 91 then
        dia = split_str("hi! your farm looks very nice. the local stray thought so too, as you surely must have noticed. if you ever get a coop or barn you can buy your animals here on my field!")
      elseif temp == 93 then
        --buy chicken
        if build_progress >= 2 then
          if chick_flip_flop then
            dia = split_str("hi! would you like to buy some chicken for your coop? they are 500\xe2\x97\x8f each.")
          else
            if money >= 500 then
              money = money - (500)
              chicks = chicks + (1)
              dia = split_str("here you go, ill bring her by tomorrow morning. and you don't need to feed them, they live on the towns scraps.")
            else
              dia = split_str("sorry, but you need 500\xe2\x97\x8f to buy one chicken.")
            end
          end
          chick_flip_flop = not chick_flip_flop
        end
      elseif temp == 94 then
        --buy cows
        if build_progress >= 4 then
          if cow_flip_flop then
            dia = split_str("would you like to buy some cows for your barn? they are 700\xe2\x97\x8f each.")
          else
            if money >= 700 then
              money = money - (700)
              cows = cows + (1)
              dia = split_str("here you go, ill bring her by tomorrow morning. and you don't need to feed them, they eat the grass on your farm.")
            else
              dia = split_str("sorry, but you need 700\xe2\x97\x8f to buy one cow.")
            end
          end
          cow_flip_flop = not cow_flip_flop
        end
      elseif temp == 80 then
        --builderbunny
        for i in all(upgrades) do
          if build_progress == i[1] then
            if test_req(i[2], i[3], i[4]) then
              dia = split_str("perect! it'll be done by tomorrow. sleep tight!")
              build_progress = build_progress + (1)
              wood = wood - (i[2])
              stone = stone - (i[3])
              money = money - (i[4])
            else
              dia = split_str(i[5])
            end
          elseif build_progress == 4 then
            dia = split_str("you've got a great farm now, enjoy the fruits of your labor!")
          end
        end
      else
        --check the ground for collectibles
        check_pos(tempx * 8, tempy * 8)
      end
    end
    --cameracontrols
    if px < interior_offset then
      cx = mid(0, px - 28, interior_offset - 64)
    else
      if (px / 8) / 16 > 6 then
        local x_start = flr(((px / 8) / 16)) * 128
        cx = mid(x_start, px - 28, x_start + 128 - 64)
      else
        cx = mid(interior_offset, px - 32, 1000)
      end
    end
    cy = mid(-10, py - 28, 192)
    --if camera in saloon
    if py > 33 * 8 then
      cx = 116 * 8
      cy = 32 * 8
    end
  end
  if game == 2 then
    if btnp(4) and game2_state == 1 then
      game = 1
      save_game()
      game2_state = 0
    elseif btnp(4) and game2_state == 0 then
      game2_state = 1
      sell_scroll = 0
      money = money + (sell_value)
      sell = {}
    end
    if #sell == 0 then
      game2_state = 1
    end
  end
end

-->8
--draw
function _draw()
  if px < 94 * 8 and game == 1 then
    cls(11)
  --mirror char for water reflections
  --spr(64,px,py+8+sin(time()),1,1,p.flip,true)
  else
    cls()
  end
  --main menu
  if game == 0 then
    cx = 0
    cy = 0
    rectfill(0, 0, 64, 64, 1)
    for i in all(clouds) do
      ovalfill(i.x, i.y, i.x + i.size, i.y + i.size / 2, i.c)
      i.x = i.x + (i.xdir)
      if i.x < -100 or i.x > 100 then
        if rnd(10) < 5 then
          i.x = 64
          i.y = rnd(55)
          i.xdir = -rnd(cloudspeedmax) - .1
        else
          i.y = rnd(55)
          i.x = -30
          i.xdir = rnd(cloudspeedmax) + .1
        end
      end
    end
    rectfill(15, 18, 48, 33, 9)
    fillp(0)
    rectfill(15, 18, 48, 33, 15)
    fillp()
    rect(15, 18, 48, 33, 4)
    printm("pico", 20, 4)
    printm("valley", 26, 4)
    if dget(6) > 0 then
      printm("nEW5 lOAD4", 55, 13)
    else
      printm("nEW5", 55, 13)
    end
    --leaves
    line(38, 19, 39, 19 + sin(time()), 11)
    line(23, 22, 22, 22 + sin(time() * .8), 11)
    line(43, 28, 44, 28 + sin(time() * .5), 11)
    line(19, 28, 18, 28 + sin(time() * 2), 11)
  end
  --game
  if game == 1 then
    if px < 94 * 8 then
      set_pal(hour, minute)
    else
      pal()
      if mine_level > 0 then
        --set_pal(mid(6,7-flr((mine_level/2)),12),50)
        if mine_level < 10 then
          set_pal(8, 0)
        end
        if mine_level > 9 then
          set_pal(6, 0)
        end
      end
    end
    camera(cx, cy)
    map(0, 0, 0, 0, 128, 48)
    if weather == 2 and px < interior_offset then
      --make it rain
      new_part(px - 64 + rnd(128), py - 64 + rnd(128), 0, 1.2, 2, 1)
    end
    draw_part()
    foreach(pp, function(obj)
      obj:draw()
    end)
    if energy < maxenergy * .1 then
      print("\xf0\x9f\x98\x90", px, py - 6 + sin(time()), 7)
    end
    if is_swimming == true then
      spr(118, px, py, 1, 1, p.flip)
      if rnd(10) < 5 then
        new_part(px + 4, py + 4, rnd(.5) - .25, rnd(.1), 1, 7)
      end
    else
      if fget(temp2, 1) or fget(temp2, 2) then
        print("5", px, py - 6 + sin(time()), 7)
      end
      spr(64, px, py, 1, 1, p.flip)
    end
    --draw things on top of player
    map(0, 0, 0, 0, 128, 32, fget(7))
    --draw pointer 
    if is_fishing == false then
      oval(rx + 3, ry + 3, rx + 5, ry + 5, 8)
    end
    if is_fishing == true then
      do_fishing()
    end
    --gui
    rectfill(cx, cy, cx + 64, cy + 10, gui_color)
    temp = print(money .. "\xe2\x97\x8f", 0, -20)
    print(money .. "\xe2\x97\x8f", cx + 58 - temp, cy, gui_font_color)
    spr(193, cx + 56, cy, 1, 2)
    rectfill(cx + 63 - get_text_length(day), cy + 16, cx + 64, cy + 22, 2)
    print(day, cx + 64 - get_text_length(day), cy + 17, gui_font_color)
    rectfill(cx + 58, cy + 14 - ((energy / maxenergy) * 13), cx + 62, cy + 14, 8)
    --debug texter
    --printm(debug,7)
    --resources
    spr(73, cx + 0, cy - 1)
    print(wood, cx + 8, cy + 0, gui_font_color)
    spr(74, cx + 0, cy + 4)
    print(stone, cx + 8, cy + 6, gui_font_color)
    if hour < 23 then
      color(gui_font_color)
    else
      color(8)
    end
    if minute > 9 then
      print(hour .. ":" .. minute .. "\xe2\xa7\x97", cx + 58 - get_text_length(hour .. ":" .. minute .. "\xe2\xa7\x97"), cy + 6)
    else
      print(hour .. ":0" .. minute .. "\xe2\xa7\x97", cx + 58 - get_text_length(hour .. ":0" .. minute .. "\xe2\xa7\x97"), cy + 6)
    end
    --mine level counter
    if mine_level > 0 then
      rectfill(cx + 0, cy + 11, cx + get_text_length(mine_level), cy + 16, gui_color)
      print(mine_level, cx + 1, cy + 12, gui_font_color)
    end
    --inventory text
    if #p.inv > 0 then
      if chosen_item > #p.inv then
        chosen_item = chosen_item - (1)
      end
      rectfill(cx, cy + 59, cx + 64, cy + 64, gui_color)
      printm(p.inv[chosen_item][1] .. "X" .. p.inv[chosen_item][2], 59)
    end
    --dialogue screen
    if #dia > 0 then
      rectfill(cx, cy + 49, cx + 63, cy + 63, gui_color)
      rect(cx, cy + 49, cx + 63, cy + 63, 1)
      printm(dia[1], 51)
      if dia[2] ~= nil then
        printm(dia[2], 57)
      end
    end
  end
  --overnight screen
  if game == 2 then
    if game2_state == 1 then
      printm("sweet dreams!", 20, 7)
      printm("4 for new day", 26)
    elseif game2_state == 0 then
      local selly = 0
      sell_value = 0
      for i in all(sell) do
        printm(i[1], selly + sell_scroll)
        printm(i[2] .. "X " .. i[3] .. "\xe2\x97\x8f", selly + 6 + sell_scroll)
        selly = selly + (12)
        sell_value = sell_value + (i[2] * i[3])
        maxy = selly + 6 + sell_scroll
      end
      if maxy > 58 and sell_scroll ~= -maxy then
        print("3", cx + 56, cy + 51)
      end
      if sell_scroll < 0 then
        print("2", cx + 56, cy + 1)
      end
      if btn(3) and sell_scroll > -maxy and maxy > 58 then
        sell_scroll = sell_scroll - (1)
      elseif btn(2) and sell_scroll < 0 then
        sell_scroll = sell_scroll + (1)
      end
      rectfill(cx, cy + 58, cx + 64, cy + 64, 2)
      printm("tOTAL: " .. sell_value .. "\xe2\x97\x8f", 58, 7)
    end
  end
  if trans > 0 then
    color(0)
    rectfill(cx, cy, cx + trans, cy + 64)
    rectfill(cx + 64 - trans, cy, cx + 64, cy + 64)
    fillp(0)
    rectfill(cx, cy, cx + trans + 10, cy + 64)
    rectfill(cx + 54 - trans, cy, cx + 64, cy + 64)
    fillp(0)
    rectfill(cx, cy, cx + trans + 5, cy + 64)
    rectfill(cx + 59 - trans, cy, cx + 64, cy + 64)
    fillp()
    trans = trans - (4)
  end
end

-->8
--functions
function colli(xx, yy)
  local x1 = flr((xx + 2) / 8)
  local y1 = flr((yy + 4) / 8)
  local x2 = flr((xx + 6) / 8)
  local y2 = flr((yy + 7) / 8)
  local ul = fget(mget(x1, y1), 0)
  local ur = fget(mget(x2, y1), 0)
  local dl = fget(mget(x1, y2), 0)
  local dr = fget(mget(x2, y2), 0)
  if dr == true or dl == true or ur == true or ul == true then
    return 0
  else
    return 1
  end
end

function dist(x0, y0, x1, y1)
  -- scale inputs down by 6 bits
  local dx = (x0 - x1) / 64
  local dy = (y0 - y1) / 64
  -- get distance squared
  local dsq = dx * dx + dy * dy
  -- in case of overflow/wrap
  if dsq < 0 then
    return 32767.99999
  end
  -- scale output back up by 6 bits
  return sqrt(dsq) * 64
end

function reset_lovers()
  for i in all(lovers) do
    i.offered_gift = ""
    i.given_gift = false
  end
end

function check_lovers(frame, x, y)
  for i in all(lovers) do
    if i.frame == frame then
      --begin options
      --offer a gift if sth is held
      if #p.inv > 0 and i.given_gift == false and i.offered_gift ~= p.inv[chosen_item][1] then
        dia = split_str("do you want to give " .. p.inv[chosen_item][1] .. " to " .. i.name .. "?")
        i.offered_gift = p.inv[chosen_item][1]
      elseif #p.inv > 0 and i.given_gift == false and i.offered_gift == p.inv[chosen_item][1] then
        if i.likes == p.inv[chosen_item][1] then
          dia = split_str("thank you, i love " .. p.inv[chosen_item][1] .. "!")
          if i.friendshiplevel < 10 then
            i.friendshiplevel = i.friendshiplevel + (1)
          end
          new_part(tempx * 8 + 2, tempy * 8, 0, -rnd(.25), 1, -1)
        else
          dia = split_str(p.inv[chosen_item][1] .. "... thank you, i guess.")
        end
        i.given_gift = true
        p.inv[chosen_item][2] = p.inv[chosen_item][2] - (1)
      elseif #p.inv == 0 or i.given_gift == true then
        dia = split_str(i.text[flr(i.friendshiplevel / 3) + 1])
      end
    --end of options
    end
  end
end

function split_str(str)
  local max_length = 15
  local strings = split(str, " ", false)
  local result = {}
  local cur_str = ""
  for i in all(strings) do
    if #cur_str + #i < max_length then
      cur_str = cur_str .. " " .. i
    else
      add(result, cur_str)
      cur_str = i
    end
  end
  add(result, cur_str)
  return result
end

function lookup_npc(x, y)
  local done = false
  for i in all(npc) do
    if i[1] == x and i[2] == y then
      dia = split_str(i[3])
      done = true
    end
  end
  if done == false then
    dia = split_str("you dont want to disturb the bugs under this rock. if you need stone try the mines.you may find some there")
  end
end

function test_req(rwood, rstone, rmoney)
  if rmoney <= money and rwood <= wood and rstone <= stone then
    return true
  else
    return false
  end
end

function generate_mines()
  mine_level = mine_level + (1)
  for i in all(pp) do
    if i.name == "boulder" or i.name == "bat" or i.name == "crystal" or i.name == "metal" or i.name == "stone" or i.name == "batwing" then
      if i.name == "boulder" then
        mine_stones_left = mine_stones_left - (1)
        mset(i.x / 8, i.y / 8, 16)
      end
      del(pp, i)
    end
  end
  for x = 112, 127 do
    for y = 8, 21 do
      if mget(x, y) == 50 then
        mset(x, y, 16)
      end
      if mget(x, y) == 16 and mine_stones_left < mine_stones_max and rnd(10) < 1 then
        mine_stones_left = mine_stones_left + (1)
        addchar(x, y, "boulder")
      elseif mget(x, y) == 16 and rnd(70) < 1 then
        addchar(x, y, "bat")
      end
    end
  end
end

function add_sell(what, nr, val)
  sfx(8)
  local done = false
  local value = val or 5
  for i in all(sell) do
    if i[1] == what then
      i[2] = i[2] + (nr)
      done = true
    end
  end
  if done == false then
    add(sell, {what, nr, value})
  end
end

function printm(t, y, c)
  local col = c or 7
  local length = print(t, 0, -1000)
  print(t, cx + 32 - length / 2, cy + y, col)
end

function fill_map(x, y, xs, ys, t)
  for xx = x, x + xs do
    for yy = y, y + ys do
      mset(xx, yy, t)
    end
  end
end

function progress()
  --deleting and resetting the cat
  for i in all(pp) do
    if i.name == "cat" then
      del(pp, i)
    end
  end
  addchar(4 + rnd(6), 15 + rnd(6), "cat")
  --setting up lovers positions
  for i in all(lovers) do
    if i.friendshiplevel == 10 then
      mset(i.house_pos[1], i.house_pos[2], i.frame)
      mset(i.pos[1], i.pos[2], 36)
    else
      mset(i.pos[1], i.pos[2], i.frame)
    end
    --if returned from prairie king
    if dget(0) ~= 0 then
      given_gift = true
    end
  end
  --setting the tiles in map
  if (build_progress < 1) then
    fill_map(4, 20, 3, 1, 1)
  else
    fill_map(4, 20, 3, 1, 6)
  end
  if (build_progress < 2) then
    fill_map(9, 9, 3, 1, 17)
    fill_map(9, 11, 1, 0, 1)
    mset(15, 23, 1)
  else
    fill_map(9, 9, 1, 0, 7)
    fill_map(9, 10, 1, 0, 54)
    fill_map(9, 11, 1, 0, 53)
    mset(9, 11, 219)
    mset(10, 11, 53)
    mset(15, 23, 93)
    --spawn chicken
    for i in all(pp) do
      if i.name == "chicken" then
        del(pp, i)
      end
    end
    if chicks > 0 then
      for x = 1, chicks do
        addchar(117 + rnd(5), 25 + rnd(2), "chicken")
        if dget(0) == 0 then
          addchar(117 + flr(rnd(5)), 25 + flr(rnd(2)), "egg")
        end
      end
    end
  end
  if (build_progress < 3) then
    fill_map(9, 17, 1, 4, 1)
  else
    fill_map(9, 17, 1, 4, 6)
  end
  if (build_progress < 4) then
    fill_map(1, 14, 2, 7, 1)
    fill_map(0, 14, 0, 7, 52)
    mset(16, 23, 1)
  else
    fill_map(0, 14, 0, 7, 15)
    fill_map(3, 17, 0, 4, 52)
    fill_map(2, 15, 1, 0, 49)
    fill_map(0, 13, 2, 1, 54)
    fill_map(0, 12, 2, 0, 7)
    mset(16, 23, 94)
    --spawn cows
    for i in all(pp) do
      if i.name == "cow" then
        del(pp, i)
      end
    end
    if cows > 0 then
      for x = 1, cows do
        addchar(0 + rnd(2), 17 + rnd(4), "cow")
        if dget(0) == 0 then
          addchar(0 + flr(rnd(2)), 17 + flr(rnd(4)), "milk")
        end
      end
    end
  end
  --setting the blank farmspaces
  --back to seeded spaces via pp
  for i in all(pp) do
    if mget(flr(i.x / 8), flr(i.y / 8)) ~= 19 and i.plant == 1 then
      if i.age < 3 then
        mset(flr(i.x / 8), flr(i.y / 8), 19)
      else
        mset(flr(i.x / 8), flr(i.y / 8), 34)
      end
    end
  end
  dset(0, 0)
end

function water(value)
  --1=dry everything(normal day)
  --0=water everything(rainy day)
  local spawn_mound = false
  if rnd(10) < 4 then
    spawn_mound = true
  end
  update_artifacts()
  for i = 0, 127 do
    for l = 0, 31 do
      local check_m = mget(i, l)
      --spawning random stuff
      if rnd_stuff_count < rnd_stuff_max then
        if rnd(100) < 5 then
          if check_m == 1 then
            --grass
            addchar(i, l, grass_loot_table[ceil(rnd(#grass_loot_table))])
            rnd_stuff_count = rnd_stuff_count + (1)
          end
          if check_m == 3 and rnd(10) < 5 and spawn_mound == true then
            mset(i, l, 14)
            spawn_mound = false
          end
        end
      end
      --adjusting for rain etc
      if value == 1 then
        --sunny
        if check_m == 18 then
          mset(i, l, 19)
        end
        if check_m == 2 then
          mset(i, l, 6)
        end
      elseif value == 2 then
        --rain
        if check_m == 6 then
          mset(i, l, 2)
        end
        if check_m == 19 then
          mset(i, l, 18)
        end
      end
    end
    if value == 1 then
      --pal()
      pal({[0] = 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}, 1)
    else
      pal({[0] = 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}, 1)
    end
  end
end

function get_text_length(t)
  return print(t, 0, -1000)
end

function check_pos(x, y)
  local ret = true
  for i in all(pp) do
    if dist(i.x, i.y, x, y) < 8 then
      ret = false
      if i.plant == 1 and i.age == 3 then
        add_item(i.name, 1, i.value)
        del(pp, i)
      elseif i.name == "wood" then
        wood = wood + (1)
        sfx(1)
        del(pp, i)
        rnd_stuff_count = rnd_stuff_count - (1)
      elseif i.name == "chicken" or i.name == "cow" or i.name == "cat" then
        sfx(7)
        new_part(i.x + 2, i.y, 0, -rnd(.25), 1, -1)
      elseif i.name == "stone" then
        stone = stone + (1)
        sfx(1)
        del(pp, i)
      elseif i.name == "bat" then
        xplode(i.x + 4, i.y + 4)
        sfx(6)
        add_item("batwing", 1, 15)
        del(pp, i)
      elseif i.name == "boulder" then
        sfx(3)
        xplode(i.x + 4, i.y + 4, 6)
        mine_stones_left = mine_stones_left - (1)
        mset(i.x / 8, i.y / 8, 16)
        energy = energy - (1)
        if flr(rnd(mine_stones_left * mine_stones_left) + 1) == 1 or mine_stones_left == 1 then
          --spawning the stairs
          mset(i.x / 8, i.y / 8, 50)
        else
          --spawn loot instead of stairs
          if rnd(10) < 4 then
            local loot = "stone"
            if mine_level <= 27 then
              loot = rnd_mine_loot[flr(mine_level / 7) + 1][flr(rnd(#rnd_mine_loot[flr(mine_level / 7) + 1])) + 1]
            else
              loot = "gold"
            end
            addchar(i.x / 8, i.y / 8, loot)
          end
        --of wether to spawn loot
        end
        del(pp, i)
        break
      elseif i.collect == true then
        add_item(i.name, 1, i.value)
        del(pp, i)
        if mine_level == 0 then
          rnd_stuff_count = rnd_stuff_count - (1)
        end
      end
    end
  end
  return ret
end

function xplode(x, y, c, nr, f)
  local force = f or .5
  local col = c or 9
  local nr = 12 or nr
  for i = 1, nr do
    new_part(x, y, rnd(force * 2) - force, rnd(force * 2) - force, .4, col)
  end
end

function addchar(x, y, name, age)
  local p = {}
  p.x = x * 8
  p.y = y * 8
  p.age = age or 0
  p.look = 0
  --0=o,1=r,2=d,3=l
  p.flip = false
  p.dirx = 0
  p.diry = 0
  p.collect = false
  p.speed = 1
  p.frame = 64
  p.name = name
  if p.name == "sunflower" then
    p.frame = 128 + p.age
    p.plant = 1
    p.value = 40
  elseif p.name == "chicken" then
    p.frame = 75
    p.brain_cd = time() + rnd(10)
  elseif p.name == "bat" then
    p.frame = 126
    p.brain_cd = time() + rnd(1)
  elseif p.name == "cow" then
    p.frame = 78
    p.brain_cd = time() + rnd(10)
  elseif p.name == "cat" then
    p.frame = 77
    p.brain_cd = time() + rnd(10)
  elseif p.name == "tomato" then
    p.frame = 132 + p.age
    p.plant = 1
    p.value = 40
  elseif p.name == "strawberry" then
    p.frame = 136 + p.age
    p.plant = 1
    p.value = 50
  elseif p.name == "flower" then
    p.frame = 68
    p.collect = true
    p.value = 13
  elseif p.name == "crystal" then
    p.frame = 71
    p.collect = true
    p.value = 18
  elseif p.name == "gold" then
    p.frame = 92
    p.collect = true
    p.value = 25
  elseif p.name == "metal" then
    p.frame = 72
    p.collect = true
    p.value = 12
  elseif p.name == "wood" then
    p.frame = 73
  elseif p.name == "stone" then
    p.frame = 74
  elseif p.name == "apple" then
    p.frame = 69
    p.collect = true
    p.value = 13
  elseif p.name == "milk" then
    p.frame = 79
    p.collect = true
    p.value = 30
  elseif p.name == "egg" then
    p.frame = 76
    p.collect = true
    p.value = 25
  elseif p.name == "boulder" then
    p.frame = 70
    mset(x, y, 51)
  elseif p.name == "player" then
    p.inv = {}
  end
  if p.plant == 1 then
    if mget(x, y) == 6 then
      mset(x, y, 19)
    end
    if mget(x, y) == 2 then
      mset(x, y, 18)
    end
    if p.age == 3 then
      mset(x, y, 34)
    end
    debug = p.age
  end
  p.grow = function()
    if p.plant == 1 then
      if p.age < 3 and mget(flr(p.x / 8), flr(p.y / 8)) == 18 then
        p.age = p.age + (1)
        p.frame = p.frame + (1)
      elseif p.age < 3 and mget(flr(p.x / 8), flr(p.y / 8)) == 19 then
        --let dry plants die
        mset(flr(p.x / 8), flr(p.y / 8), 6)
        del(pp, p)
      end
      if p.age == 3 and mget(flr(p.x / 8), flr(p.y / 8)) == 18 then
        mset(flr(p.x / 8), flr(p.y / 8), 34)
      end
    end
  end
  p.update = function()
    --movement
    if p.name == "player" then
      if is_swimming then
        p.speed = .6
      else
        p.speed = 1
      end
      if btn(1) then
        p.dirx = p.speed
        p.look = 1
        p.flip = false
      elseif btn(0) then
        p.flip = true
        p.dirx = -p.speed
        p.look = 3
      else
        p.dirx = 0
      end
      if btn(2) then
        p.diry = -p.speed
        p.look = 0
      elseif btn(3) then
        p.diry = p.speed
        p.look = 2
      else
        p.diry = 0
      end
      --moving characters
      if colli(p.x + p.dirx, p.y) == 1 then
        p.x = p.x + (p.dirx)
      end
      if colli(p.x, p.y + p.diry) == 1 then
        p.y = p.y + (p.diry)
      end
    end
    --chicken brain
    if p.name == "chicken" or p.name == "bat" or p.name == "cat" or p.name == "cow" then
      if time() > p.brain_cd then
        if rnd(10) < 2 then
          p.dirx = rnd(.25) - .5
          p.diry = rnd(.25) - .5
          if rnd(10) < 5 then
            p.dirx = p.dirx * (-1)
          end
          if rnd(10) < 5 then
            p.diry = p.diry * (-1)
          end
          p.brain_cd = time() + rnd(1)
        else
          p.dirx = 0
          p.diry = 0
          p.brain_cd = time() + rnd(5)
        end
        if p.dirx <= 0 then
          p.flip = true
        else
          p.flip = false
        end
      end
      if p.name == "bat" then
        if dist(p.x, p.y, px, py) < 3 then
          xplode(p.x, p.y)
          energy = energy - (10)
          del(pp, p)
        end
      end
      if colli(p.x + p.dirx, p.y) == 1 then
        p.x = p.x + (p.dirx)
      end
      if colli(p.x, p.y + p.diry) == 1 then
        p.y = p.y + (p.diry)
      end
    end
  end
  p.draw = function()
    if p.name == "bat" then
      spr(p.frame + anim, p.x, p.y, 1, 1, p.flip)
    else
      if p.name ~= "player" then
        spr(p.frame, p.x, p.y, 1, 1, p.flip)
      end
    end
    if p.name == "player" and is_swimming == false then
      if p.dirx ~= 0 or p.diry ~= 0 then
        spr(113 + anim, p.x, p.y, 1, 1, p.flip)
      else
        spr(112, p.x, p.y, 1, 1, p.flip)
      end
    end
  end
  add(pp, p)
end

function add_item(what, howmuch, price)
  sfx(1)
  local nr = howmuch or 1
  local worth = price or 20
  local done = false
  for i in all(pp[1].inv) do
    if i[1] == what then
      i[2] = i[2] + (nr)
      done = true
    end
  end
  if done == false then
    add(pp[1].inv, {what, nr, worth})
  end
end

function new_part(x, y, xs, ys, t, c)
  local p = {}
  p.x = x
  p.y = y
  p.xs = xs
  p.ys = ys
  p.c = c or 10
  p.t = time() + t
  add(part, p)
end

function transition()
  trans = 64
  sfx(9)
end

function draw_part()
  for i in all(part) do
    --draw
    if i.c == -1 then
      print("\xe2\x99\xa5", i.x, i.y, 8)
    else
      pset(i.x, i.y, i.c)
    end
    --simulate
    i.x = i.x + (i.xs)
    i.y = i.y + (i.ys)
    --kill
    if time() > i.t then
      del(part, i)
    end
  end
end

function sleep()
  --change position to bed
  pp[1].x = 120 * 8
  pp[1].y = 2 * 8
  outside_x = 7 * 8
  outside_y = 15 * 8
  --adjust vars for next day
  if rnd(10) < 1 then
    weather = 2
  else
    weather = 1
  end
  if energy > 0 and px > 117 * 8 and py < 64 then
    energy = maxenergy
  else
    --take away some items
    for i in all(pp[1].inv) do
      i[2] = i[2] - (flr(rnd(3)))
    end
    energy = flr(maxenergy / 2)
  end
  --sleep
  game = 2
  mine_level = 0
  day = day + (1)
  hour = 7
  minute = 0
  game2_state = 0
  --grow plants and adjust progress
  foreach(pp, function(obj)
    obj:grow()
  end)
  progress()
  water(weather)
  reset_lovers()
end

function count_item(what)
  local ret = 0
  for i in all(pp[1].inv) do
    if i[1] == what then
      ret = i[2]
    end
  end
  return ret
end

function save_game()
  dset(0, 0)
  --if>0 spawn @ saloon
  --first save static save data
  dset(1, wood)
  dset(2, stone)
  dset(3, money)
  dset(4, build_progress)
  dset(5, chicks)
  dset(6, day)
  dset(7, cows)
  dset(8, artifacts_found)
  dset(9, artifacts_given)
  dset(10, has_rod)
  --then set items data
  dset(11, count_item("tOMATO\xe2\x96\x91"))
  dset(12, count_item("sUNFLOWER\xe2\x96\x91"))
  dset(13, count_item("sunflower"))
  dset(14, count_item("metal"))
  dset(15, count_item("crystal"))
  dset(16, count_item("tomato"))
  dset(17, count_item("flower"))
  dset(18, count_item("apple"))
  dset(19, count_item("strawberry\xe2\x96\x91"))
  dset(20, count_item("strawberry"))
  dset(21, count_item("salmon"))
  dset(22, count_item("anchovy"))
  dset(23, count_item("milk"))
  dset(24, count_item("egg"))
  dset(25, count_item("pike"))
  dset(26, count_item("catfish"))
  dset(27, count_item("walleye"))
  dset(28, count_item("barracuda"))
  dset(29, count_item("batwing"))
  dset(30, count_item("gold"))
  --save relationships
  dset(31, lovers[1].friendshiplevel)
  dset(32, lovers[2].friendshiplevel)
  dset(33, lovers[3].friendshiplevel)
  dset(34, lovers[4].friendshiplevel)
  dset(35, lovers[5].friendshiplevel)
  dset(36, lovers[6].friendshiplevel)
  --save farmslots
  --upper field
  for x = 0, 3 do
    dset(37 + x, get_slot_code(4 + x, 17))
    dset(41 + x, get_slot_code(4 + x, 18))
  end
  --lower field
  for x = 0, 3 do
    dset(45 + x, get_slot_code(4 + x, 20))
    dset(49 + x, get_slot_code(4 + x, 21))
  end
  --long field
  for y = 0, 4 do
    dset(58 + y, get_slot_code(9, 17 + y))
    dset(53 + y, get_slot_code(10, 17 + y))
  end
end

function update_artifacts()
  for i = 0, 6 do
    if artifacts_given >= i + 1 then
      mset(103 + i, 13, 97 + i)
      xplode((103 + i) * 8 + 4, 13 * 8 + 2, rnd(16))
    else
      mset(103 + i, 13, 96)
    end
    if artifacts_given >= i + 8 then
      mset(103 + i, 15, 104 + i)
      xplode((103 + i) * 8 + 4, 15 * 8 + 2, rnd(16))
    else
      mset(103 + i, 15, 96)
    end
  end
end

function load_game()
  if dget(0) > 0 then
    pp[1].x = 121 * 8
    pp[1].y = 36 * 8
    outside_x = 38 * 8
    outside_y = 21 * 8
    hour = dget(0)
    if dget(63) > 0 then
      add_sell("wares", 1, dget(63))
    end
  else
    --change position to bed
    pp[1].x = 120 * 8
    pp[1].y = 2 * 8
    outside_x = 7 * 8
    outside_y = 15 * 8
  end
  --first save static save data
  wood = dget(1)
  stone = dget(2)
  money = dget(3)
  build_progress = dget(4)
  chicks = dget(5)
  day = dget(6)
  cows = dget(7)
  artifacts_found = dget(8)
  artifacts_given = dget(9)
  has_rod = dget(10)
  --then set items data
  add_item("tOMATO\xe2\x96\x91", dget(11))
  add_item("sUNFLOWER\xe2\x96\x91", dget(12))
  add_item("sunflower", dget(13))
  add_item("metal", dget(14))
  add_item("crystal", dget(15))
  add_item("tomato", dget(16))
  add_item("flower", dget(17))
  add_item("apple", dget(18))
  add_item("strawberry\xe2\x96\x91", dget(19))
  add_item("strawberry", dget(20))
  add_item("salmon", dget(21))
  add_item("anchovy", dget(22))
  add_item("milk", dget(23))
  add_item("egg", dget(24))
  add_item("pike", dget(25))
  add_item("catfish", dget(26))
  add_item("walleye", dget(27))
  add_item("barracuda", dget(28))
  add_item("batwing", dget(29))
  add_item("gold", dget(30))
  --load relationships
  lovers[1].friendshiplevel = dget(31)
  lovers[2].friendshiplevel = dget(32)
  lovers[3].friendshiplevel = dget(33)
  lovers[4].friendshiplevel = dget(34)
  lovers[5].friendshiplevel = dget(35)
  lovers[6].friendshiplevel = dget(36)
  --save farmslots
  progress()
  --upper field
  for x = 0, 3 do
    read_slot_code(4 + x, 17, dget(37 + x))
    read_slot_code(4 + x, 18, dget(41 + x))
  end
  --lower field
  for x = 0, 3 do
    read_slot_code(4 + x, 20, dget(45 + x))
    read_slot_code(4 + x, 21, dget(49 + x))
  end
  --long field
  for y = 0, 4 do
    read_slot_code(9, 17 + y, dget(58 + y))
    read_slot_code(10, 17 + y, dget(53 + y))
  end
end

function get_slot_code(x, y)
  local ret = 0
  --0=nothing
  for i in all(pp) do
    if i.x / 8 == x and i.y / 8 == y then
      if i.name == "tomato" then
        ret = ret + (5)
      end
      if i.name == "sunflower" then
        ret = ret + (10)
      end
      if i.name == "strawberry" then
        ret = ret + (15)
      end
      ret = ret + (i.age)
    end
  end
  return ret
end

function read_slot_code(x, y, code)
  if code >= 15 then
    addchar(x, y, "strawberry", code - 15)
  elseif code >= 10 then
    addchar(x, y, "sunflower", code - 10)
  elseif code >= 5 then
    addchar(x, y, "tomato", code - 5)
  end
end

function start_fishing()
  is_fishing = true
  fish_cd = time() + 2 + rnd(5)
  fish_state = 0
  fish_progress = 40
  fish_y = 20
  bar_y = 0
  bar_size = 10
  fish_dir = -2
  fish_move_cd = 0
  if px > 64 * 8 then
    what_fish = flr(rnd(#saltwater_fish)) + 1
    fish = saltwater_fish
  else
    what_fish = flr(rnd(#freshwater_fish)) + 1
    fish = freshwater_fish
  end
  sfx(5)
end

function do_fishing()
  --drawing the rod and particles
  if p.flip then
    line(px, py + 2, rx + 4, ry + 5, 13)
  else
    line(px + 7, py + 2, rx + 4, ry + 4, 13)
  end
  if rnd(10) < 1 then
    new_part(rx + 4, ry + 5, rnd(.5) - .25, rnd(.5) - .25, .3, 7)
  end
  pset(rx + 4, ry + 5, 13)
  pset(rx + 4, ry + 6 + sin(time()), 8)
  spr(116, px, py, 1, 1, p.flip)
  --making the player react
  if fish_state == 0 and time() > fish_cd then
    print("!5!", px - 3, py - 6 + sin(time() * 4), 7)
    if time() < fish_cd + .5 then
      sfx(6)
      if btnp(5) then
        --catching the fish
        sfx(4)
        fish_state = 1
      end
    else
      --play sound for missing fish
      is_fishing = false
      dia = split_str("the fish got away...")
    end
  end
  --making the player catch the 
  --fish
  if fish_state == 1 then
    --drawing the fish bar
    rectfill(cx + 30, cy + 10, cx + 38, cy + 54, 13)
    rect(cx + 32, cy + 12, cx + 36, cy + 52, 15)
    rectfill(cx + 33, cy + 13, cx + 35, cy + 51, 12)
    line(cx + 31, cy + 12, cx + 31, cy + 52, 6)
    line(cx + 37, cy + 12, cx + 37, cy + 52, 4)
    line(cx + 37, cy + 52 - (40 * (fish_progress / fish_progress_max)), cx + 37, cy + 52, 11)
    rectfill(cx + 33, cy + 51 - bar_y - bar_size, cx + 35, cy + 51 - bar_y, 11)
    spr(115, cx + 30, cy + 51 - fish_y)
    --making the fish bar work
    if btn(5) then
      bar_y = bar_y + (2)
      if bar_y + bar_size > 39 then
        bar_y = 39 - bar_size
      end
    end
    if bar_y > 0 then
      bar_y = bar_y - (1)
    end
    --moving the fish
    if time() > fish_move_cd then
      fish_move_cd = time() + rnd(.5)
      fish_dir = rnd(fish[what_fish][2]) - (fish[what_fish][2] / 2)
    end
    fish_y = fish_y + (fish_dir)
    if fish_y > 38 then
      fish_y = 38
      fish_move_cd = 0
    elseif fish_y < 4 then
      fish_y = 4
      fish_move_cd = 0
    end
    --checking wether the fish is
    --caught or not
    if bar_y - bar_size < fish_y - 12 and bar_y > fish_y - 12 then
      fish_progress = fish_progress + (1)
    else
      if fish_progress > 0 then
        fish_progress = fish_progress - (1)
      end
    end
    if fish_progress >= 100 then
      fish_state = 2
    elseif fish_progress == 0 then
      is_fishing = false
      dia = split_str("the fish got away...")
    end
  end
  --end minigame
  if fish_state == 2 then
    dia = split_str("you caught a " .. fish[what_fish][1])
    add_item(fish[what_fish][1], 1, fish[what_fish][3])
    is_fishing = false
  end
end

function set_pal(h, m)
  local pals = {
  --night palette from achiegamedev - thx ♥
  {[0] = 0, 129, 130, 131, 132, 133, 5, 13, 2, 4, 137, 3, 1, 141, 136, 143},
  --regular second palette
  {[0] = 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143},
  --sharpen contrast
  {[0] = 128, 1, 130, 131, 132, 5, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}, {[0] = 0, 1, 130, 131, 132, 5, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143},
  --introduce greens
  {[0] = 0, 1, 130, 3, 132, 5, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}, {[0] = 0, 1, 130, 3, 132, 5, 134, 135, 136, 137, 138, 11, 140, 141, 142, 143},
  --introduce yellows
  {[0] = 0, 1, 130, 3, 132, 5, 134, 135, 136, 9, 138, 11, 140, 141, 142, 143}, {[0] = 0, 1, 130, 3, 132, 5, 134, 135, 136, 9, 10, 11, 140, 141, 142, 143},
  --introduce reds
  {[0] = 0, 1, 2, 3, 4, 5, 134, 135, 136, 9, 10, 11, 140, 141, 142, 143}, {[0] = 0, 1, 2, 3, 4, 5, 134, 135, 8, 9, 10, 11, 140, 141, 14, 15},}
  local ho = h or hour
  if ho < 7 then
    pal(pals[1], 1)
  elseif ho == 7 then
    pal(pals[2], 1)
  elseif ho == 8 then
    if m < 30 then
      pal(pals[2], 1)
    end
    if m > 20 then
      pal(pals[3], 1)
    end
    if m > 40 then
      pal(pals[4], 1)
    end
  elseif ho == 9 then
    if m < 30 then
      pal(pals[5], 1)
    end
    if m > 20 then
      pal(pals[6], 1)
    end
  elseif ho == 10 then
    if m < 30 then
      pal(pals[7], 1)
    end
    if m > 20 then
      pal(pals[8], 1)
    end
  elseif ho == 11 then
    if m < 30 then
      pal(pals[9], 1)
    end
    if m > 20 then
      pal(pals[10], 1)
    end
  elseif ho == 12 then
    pal()
  elseif ho == 17 then
    if m < 30 then
      pal(pals[10], 1)
    end
    if m > 20 then
      pal(pals[9], 1)
    end
  elseif ho == 18 then
    if m < 30 then
      pal(pals[8], 1)
    end
    if m > 20 then
      pal(pals[7], 1)
    end
  elseif ho == 19 then
    if m < 30 then
      pal(pals[6], 1)
    end
    if m > 20 then
      pal(pals[5], 1)
    end
  elseif ho == 20 then
    if m < 30 then
      pal(pals[4], 1)
    end
    if m > 20 then
      pal(pals[3], 1)
    end
  elseif ho == 21 then
    if m < 30 then
      pal(pals[2], 1)
    end
  elseif ho > 21 then
    pal(pals[1], 1)
  end
end

-->8
--extra documentation
--flags
--0=collision
--1=regular text starter
--2=lover interactions
--5=port flag
--6=back out flag
--7=sprites being drawn last#
--how to add plants
--555555555555555
--1.pixel the 4 stages from
--  seed to fruitling
--2.define its value in add_char
--3.add the ░-seed item as a
--  shop tile and add it to the
--  btn(5) checks in tab 1
--4.add it to the slot-code-func
--5.add it and its ░ items to
--  the save and load function
--how to add npc's or signs
--555555555555555
--1.make a sprite with flag 1
--  enabled
--2.place it on the map
--3.add its mget-position and
--  text to the npc-table
--how to add interiors
--555555555555555
--1.place a door on the map
--2.map the interior on the 
--  interior side of the map
--3.make sure its x-value is 
--  unique. add to ports table
__gfx__
0000000033bb33bb44444444ffffffffcccccccc55555d559999999928222282545ffff42ffffff20000000000000000bbb4bbb4bb4bbbbbffffffffbbbb3bbb
00000000bb33bb3344444444ffffffffccccccccdddddddd999999998822882247222274f444444f000000eee6000000b2b4b2b4bbdbbbbbffffffffbbbbb33b
00700700b3bb3b3b44444444ffffffffcccccccc55d55555999999992288228842222224f444444f0006eee82e68e600d2d4d2d4bb4bbbbbffffffffbbbbbbbb
00077000b33b33bb44444444ffffffffccccccccdddddddd9999999922282228472222742ffffff2006ee22ee2eeee60b2b4b2b4bb4bbbbbfff44fffbbbbbbbb
000770003bb3bb3344444444ffffffffcccccccc55555d5599999999222822284777777444499444028eeeeeeeee8260b2b4b2b4bb4bbbbbff4ff4ffbbbb3bbb
0070070033b3b3bb44444444ffffffffccccccccdddddddd999999998228822847782274444444440e22ee2ee2222ee0b2b4b2b4bb4bbbbbffffffffbb33bbbb
00000000bb3b3b3344444444ffffffffcccccccc55d555559999999928822882478822242444444206eee28eeeeeeee052545254bbdbbbbbffffffffbbbbbbbb
00000000b3bb3b3b44444444ffffffffcccccccc6666666699999999228222824882222422222222006eee222eeeee00b2b4b2b4bb4bbbbbffffffffbbbbbbbb
dddddddd55d55d5544444444999999997777111155555d55bbbbbbbbbbbbbbbb4222222403133000bb6eeeeeeee8e6bb22eeee22f4444422bbbbbbbb44444444
dddddddd5d5555d5444444449999999977771111dffffffdbb4b4bb4bdb5bbdb4222222402bb3300bb28eeeeeeee62bb222ee222f4444442bffffffb44444444
dddddddd66d55d564444444499999999777711115f4444454444444466d55d56422222243baabb10bbb222eeee222bbbe222222ef4444422b444444b22222222
dddddddd55dd66d5444444449999999977771111df44444d4444444455dd66d54222222413bab340bbbbbb422ebbbbbbee2222eec5cccc5cb424244b44444444
dddddddd555d55d54444444499999999111177775f444445cccccccc555d55d5422222241b3b3130bbbbb242442bbbbbeee22eeef4444422b442424b44444444
dddddddd56655556444944449994999911117777df44454dcccccccc566555564222227431b31230bbb3242442423bbbee2222eef4444442b444444b44444444
ddddddddd55d55d54494944499494999111177775f444445ccccccccd55d55d54722227433333b10bb3332442f2333bbe22ee22ef4444422bb2bb2bb22222222
dddddddd5dd566554444444499999999111177776f444446cccccccc5dd56655545ffff41b331100bbb3332232333bbb22eeee22c5cccc5cb323323b44444444
dd511d556666666699999999dd6aa6dddd6666dd55555d5555555d5559a9a9a5bb3313bb13b3b1bbddddddddddddddddffffffffffffffff0000000880000000
551111656666666699999999dad66dadddd66dddddd7cddddddddddd9a9a9a9ab13bb31b133431bbddddddddddddddddffffffff244444420000002882000000
5111111611111111999999996dddddd66dddddd6557ccc5555d555555f44444533baab33b1111bbbddddddddddddddddffffffff299999920000022882200000
51111115dddddddd99999999a6daad6a66dddd66ddccc1dddddddddddf44444d313b3933bb2fbbbbdddddddddddddddd44444444244444420000228888220000
51111115666666669999999966adda66666dd6665511115555555d555f44444513333331bb44bbbbdddddddddddddddd44444444299999920008282882828000
6111111666666666999999996adaada666dddd66dddddddddddddddddf44454db113931bb12423bbdddddddddddddddd24444442244444420028822882288200
611111161111111199999999adaaaada6dd66dd655d5555555d555555f444445bb1111bb1224213bdddddddddddddddd22222222222222220228228888228220
5111111ddddddddd99999999daaaaaaddd6666dd66666666dddddddd6f444446bbbbbbbbb33133bb666666dddddddddddddddddddddddddd8288282882828828
d4556d45b7bbb7bbddddddddddddddddbbbbb7bb44444244444442445e555e55222c222cbbbbbbbb666666ddddddddddc1c1c1c1d65dd6668828822882288288
22222222b7b6b7b6dd5555ddddddddddbbbbbdbb2222222222222222e2e9e2e524252425bbbbbbbbddddddddddddddddc1c1c1c1d65566dd8228228448228228
54666646d7d6d7d6d540045dddddddddbbbbb7bb44244444442444445e9a9e85444c444cbbbbbbbbddddddddddddddddc1c1c1c1566665dd8288282222828828
5ffffff5b7b6b7b650444405dd5d5dddbbbbb7bb22222222222222225e494828444c444cbb3bbbbbddddddddddddddddc1c1c1c166dd655d8828844444488288
545dd545b7b6b7b650200205ddd5ddddbbbbb7bb4444424444444244e2e49485444c444cbbbbbbbbddddddddddddddddc1c1c1c16dddd6668228444444448228
22222222b7b6b7b650222205dd5d5dddbbbbb7bb22222222222222225e49a945444c444cbbbbbbbbddddddddddddddddc1c1c1c165ddd6dd8284444444444828
6465554657565756d520025dddddddddbbbbbdbb4424444444244444dddd9ddd44454445bbbbbb3bddddddddddddddddc1c1c1c1655d665d8822222222222288
5ffffffdb7b6b7b6dd5555ddddddddddbbbbb7bbdddddddd22222222ddddddddfffcfffcbbbbbbbbddddddddddddddddc1c1c1c1666666558444444444444448
000eee00dd4444dddd4444dddd4444dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000400400000000
00e4eee0ddd55dddddd55dddddd55ddd000e00000003000000555500000000000000060000000440000000000000000000000000000000000000077000066000
0e4141006dd44dd66dd44dd66dd44dd600eae0000028380005566550000700000000655000004420000000000000000000000000000000000000077000600600
00e44400664994666644346666444466000e000002888880556555550077000000065550000442000006d000000080000000000000e0020000757ee000dddd00
00111000649aa946644884466444444600030000022888805655551100770600006665500044200000d660000000d700000000000e000e100057570000d77d00
00111000649aa946644884466444444600333000002288001555111100776660006665000ff2000000555000006770000000600000444ee0007e050000d77d00
00c1c0006d4994d66d4444d66d4444d600030000000000000151111007777660006660000f900000000000000766700000007000004444000070070000577500
00000000dddddddddddddddddd6666dd000000000000000000111100000000000000000000000000000000000000000000000000002002000070070000555500
bb999bbb00099900ddd999dddd4444dddd999ddddd222ddddddaaaddd4444dddddd44dddd1111ddddd444dddd4d444dd00000000bbbbbbbbbbbb4bb4d44444dd
b999f9bb00949990dd94999dddd55dddd999f9ddd222f2ddddafaaadd444f4dddd4f44ddddf1f1dddd44f4dddd4f444d00000000bbbbbbbbbbbbb77bd4fff44d
bbcfcf9b09414100d94141dd6dd44dd6ddcfcf9ddd3f3f2ddafcfcddd43f3f4ddd5151ddddcfc1ddddcfcfddd4f3f3dd00000000bbbbbbbbbbbbb77bdd1f1f4d
bbfef99b00944400dd9444dd66433466ddfef99dddfef22ddaafefddddfef44ddd4fefddddfeffddddfeffddd44fefdd0090a000bbbb8bbbbb757eebdd5e5fdd
bbb222ab00111000d7717ddd648e8846ddd333addd21112ddacccadddd43224ddd3c2dddddd311dddddc44ddd42324dd00aa9a00bbbbd7bbbb5757bbdd5552dd
bbb222b900111000d57175dd6428e246ddd333d9dd21112dddcccdddddd322dddd332dddddd311dddddc44dddd232ddd0a9aaaa0bb677bbbbb7eb5bbddd522dd
bbb222bb00c1c000dd777ddd6d4224d6ddd333ddddd111ddddcccdddddd222dddd333dddddd111ddddd444dddd333ddd00000000b7667bbbbb7bb7bbddd111dd
bbb5b5bb00000000dd5d5ddddd6666ddddd5d5ddddd5d5dddd5d5dddddd5d5dddd5d5dddddd5d5ddddd5d5dddd5d5ddd00000000bbbbbbbbbb7bb7bbddd5d5dd
fffffffffffff5ffffffffffffffffffffffffffffffffffffff5fffffffffffffffffffffffdffffff3bffffffccffffffffffffffffffffffafaff00000000
ffffffffff4445fff244442fff21112fffd55fdfff4445ffff4445ffff4445ffffee22fffff5d5ffff3b3bfff1c77c1fffff7ffffe29abffffa9a9ff00000000
fffffffffffff5ffffffffffff21f12ffdf55dfffffff5fffffff5ffffff55fffeeee22fff156d1fffb3b3ffff1cc1ffff6767ffff9ab31fffaaaaff00000000
ffffffffffffffffffffffffff21f12fffd55fffffffffffffff5ffffffffffffffffffffff111fffffffffffff11ffffff77fffffffffffffffffff00000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444400000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444400000000
24444442244444422444444224444442244444422444444224444442244444422444444224444442244444422444444224444442244444422444444200000000
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000
0000000000000000000000000000000000000000000000f0000eee0000000000000000002299a922222444220000000000000000000000000000000000000000
000000000000000000000000000000000000000000000f0000e4eee0000000000000000029af9a92224f44420000000000000000000000000000000000000000
000000000000000000000000005100000000000f0000f0000e41410000000000000000002af1f1a222f1f1220000000000000000000000000500005000000000
00000000000000000000000000555000000000f0000f000000e44400000000000000000029ff2f9222f444220000000000000000000000000550055000500500
0000000000000500050000000005d50000000f0000f000000000000000000000000000002aeeea2222aaa2220000000000000000000000000052520005525250
050005000500000000000500000055d0000000000f00000000000000000000000000000022c1c222229192220000000000000000000000000005500000055000
00000000005000000000500000000d00000000000000000000000000000000000000000022ddd222229192220000000000000000000000000000000000000000
00505000000050000050000000000000000000000000000000000000000000000000000022525222225252220000000000000000000000000000000000000000
000000000000000000000000000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000a99a0000000000000000000003a00000003b000000000000000000000000000008000000000000000000000000000000000000
00000000000000000000000000a99a000000000000000000000b00000003b800000000000000000000070000080b000000000000000000000000000000000000
00000000000000000030b000000aa00000000000000b300000ab0000003b0000000000000000b000070b0700030b038000000000636363636363630000000000
000000000000b000000300000003bb000000000000b300000003a000008b300000000000000300000b030b000b030b0000000000000000000000000000000000
0000000000030000000b0000003bb00000000000000b0000000b0000000b8000000000000033b0000033b000003bb000000000005353535353ce530000000000
000a0000000b0000000b00000003b00000020000000b0000000b0000000b0000000e0000000b0000000b0000000b000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004f4f30a74fcf4f0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c2c2c24f4f4f4f0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000974f4f4f4f4f4f0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000032000000000000000000
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
00000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044444444bbbbbbbbbbbbbbbbbbbbbbbb0000033133100000b31133311333113bf44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbbbbbbbbbbbbbbbbbbbbbbb0000313333330000333113333331133355555555000000000000000000000000000000000000000000000000
000000004d555554bbbbbbbbbbbbbbbbbbbbbbbb0003a3baab313000ab331313313133baf44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbbbbbbb3bb33bbbbbbbbbbb00333baaaab33300aab3113113113baaf44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbbbbbb3bbbb3b3b3bb3bbbb011333baab311330ab333111113333baf44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbbbb3bbbb3bbbbbbb33bbbb013ab333311331303331331113341333f44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbb3bbb33b33bb3b3bbbbbbb03311333313313303333331113333333dddddddd000000000000000000000000000000000000000000000000
000000004d555554bbb33b333333333333b3bbbb01333113333ab31033a33134413331abf44ff44f000000000000000000000000000000000000000000000000
000000004d555554bbbbbbb333b3bb3333bb3bbbb311333113ab133b3ab31331331333b14cccccc4444444444444444400000000000000000000000000000000
000000004d555554bbbb3b333bbbbbb333bbbbbbb13113333311331b3b1131333331313325555552255555522555555200000000000000000000000000000000
000000004d555554bbbbbbb33bbbbbbb3bbbbbbbbb131313333331bb3133a3baab31311145dddd5445dddd5445dddd5400000000000000000000000000000000
000000004d555554bbbbbb333bbbbbbb33bb3bbbbbb1113133111bbb33133baaaab3333325dddd5225dddd5225dddd5200000000000000000000000000000000
000000004d555554bbb3bb33bbbbbbb333bbbbbbbbb3111111113bbb111333baab31133145ddd95445ddd95445ddd95400000000000000000000000000000000
000000004d555554bbbbb3333bbbbbbb3bbbbbbbbb314211112413bb113ab3333113313125dddd5225dddd5225dddd5200000000000000000000000000000000
000000004d555554bbbbbb33bbbbbbbb33b3bbbbb31421244212413b433113333133133445dddd5445dddd5445dddd5400000000000000000000000000000000
0000000044444444bbb3bbb33bbb33b333bbbbbbbb331441144133bb11333113333ab31125dddd5225dddd52d5dddd5d00000000000000000000000000000000
00000000bbbbbbbbbbbb3b333333333333b3bbbbfffffffff4444422ffffffffffffffffccccccccccdccdcc7777111144444444000000000000000000000000
00000000bbbbbbbbbbbbbbb333b333b33bbbbbbbfffffffff4444442ffffffffffffffffcccccccccc1111cc7777111122222222000000000000000000000000
00000000bbb33bbbbbbbb3bbbbbbb3bbbb33bbbbfffffffff4444422ffffffffffffddffcccccccccc1cc1cc7777111144444444000000000000000000000000
00000000bb3333bbbbbb33b3b3b3bbbb3b3bbbbbffffffffc5cccc5cfffffffffffd6ddfcccccccccc1111cc7777111122988922000000000000000000000000
00000000bb3333bbbbbbbbbbbbb33bb3bbbbbbbbfffffffff4444422ffffffffffd6d5dfcccccccccc1cc1cc1111777749999994000000000000000000000000
00000000bbb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbfffffffff4444442ffffffffffd555dfcccccccccccccccc1111777729999992000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbfffffffff4444422fffffffff44d1144cccccccccccccccc11d17d7744555544000000000000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbffffffffc5cccc5cffffffffff44444fcccccccccccccccc11dddd7724555542000000000000000000000000
0000000033333333bbbbbbbbbbbbbbbb2222222222488422bbbbbbbb000000000000000077771111777ee1110000000024555542000000000000000000000000
0000000033333333bbbbbbbbbbddbbbb2222222224444442bbb65bbb00000000000000007777111177eaae110000000029396d92000000000000000000000000
0000000033333333bbbbddbbbdd6ddbb4444444424555542bb66d5bb00000000000000007d77111177eaae110000000029999992000000000000000000000000
0000000033333333bbbd6ddbbd6ddd5b2222222224555542bb6dd5bb000000000000000066d71111777ee1110000000024444442000000000000000000000000
0000000033333333bbd6d5dbbdddd55b2222222224444442bb6d55bb0000000000000000166d77771113bb77000000002449a442000000000000000000000000
0000000033333333bbd555dbb155551b222222222449a442bbbbbbbb000000000000000011666666113bb77700000000249a9a42000000000000000000000000
0000000033333333b33d11333311113344444444249a9a42bbbbbbbb00000000000000001666666711000077000000002449a442000000000000000000000000
0000000033333333bb33333bb333333b222222222449a442bbbbbbbb000000000000000061117776111007770000000024444442000000000000000000000000
__map__
04190a0b040404190419040a0b04040f012828e104040404190f0104040404c5c604041111111128e528111111070707071717170a0b1717171717171717171711111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000
19291a1b04190f290129e11a1b0419010f01f22801e10f01290128c4e10fc3d5d6010101282801c403010f010105050707d203031a1b1111111111112011111111111111111111111111111111111111111111111111111111111111111111000000000000000026262525262525262600000000000000052505050525000000
29010101012901e10101010f010f290303030303030303030303030303030303030303030303030303030303c40d500505d2030303030f013801010f390139281111111111111111111111030303e80307070707070701010303031111111100000000000000002c2c2c24242424242400000000000000082424242424000000
39190f0103030303030303030303030301e1010f282828010fe10128f201010f2828e3e10f0f0fe3010f0f0303030303031717171703d40f040439040404040411111111030303030303030303030303353535353535e22803030303111111000000000000000041245a242d2d00242400000000000000182424242424000000
39290103030101c5c6010f010101e10128011717171717171717171717171717171717171717171717171703171717d203111111110304040404040404040404111111c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c9c91111110000000000000000532424242424002d2d00000000000000242424242424000000
0f0a0b0328280fd5d60a0b010ff22801171711111111111111111111111111111111111111111111111111031111110f0303030303030404040404040404040411111103343131313131e80303d22801030303030303030101c40303111111000000000000000042242400000000000000000000000000000000002300000000
191a1b03340f01e1011a1b010f28010f111111111111111111111111190303030a0b2807070707070c0c0c03010d1101010f0404040404010101040101010f0d11111103342e2f04043401c403030303030303010103030128010303111111000000000000000000002300000000000000000000000000000000000000000000
2939340334010ff3e1010f011717171711112828010f01390f011111290303031a1b28252525252537e10d030f0d1117170f040404010101010f010139c5c60d11111124243e3f040434280103030303e80303012803030101280303111111000000000000000000000000000000000000000000000000000000000000000000
39393403c5c6011717171717111111112a2b2a2b2a2b2a2b2a2b1111c2d3c3c40128f205050505050c010c03010d391111173c3c3c17c5c60101c5c601d5d60d111111242436d9313131010103030303030303e201010303e2010303111111000000000000000000000000000000000000000000000000000000000000000000
17173403d5d6171111070711111111113a3b3a3b3a3b3a3b3a3b1111d20303d40f010137c21ed33703030303010c0c0c0c113c3c3c11d5d6c5c6d5d601e3e40d11111124242424030303030303030303030303030303030303030303111111000000000000000000000000000000000000000000001111113011110000000000
111117211717111111363611c5c60a0b19010f01390f01390a0b1111d203e40101390f01d203030303e3e3e30101010f01113c3c3c11e3e3d5d60fc5c601010d11111111111111111111111111e71111111111111111111111111111111111000000000000000000000000000000000000000000111111113011111111000000
1111112111112e072f353534d5d61a1b2901390a0b010f011a1b11110103010139171717e203e3e3e3010139011901011701383838030303030303d5d6010f0d11111111111111111111111111031111111111111111111111111111111111000000000000002626262626262626260000000011111010102424101111111100
1111112111113e1f3f0f0134280a0b28010f391a1b01c5c6391111111721171717111111170301393901010101292117110f040404010301070707070c0c0c0d11111111111111111111111111031111111111111111111111111111111111000000000000000525052505250525050000000011101010101010101010111100
111111211111262626013131281a1b28280101010f01d5d63911111111211111112e072f112101010117170101172111010104040401030f050505052424240d11111111111111111111111111031111111111111111111111111111111111000000000000005261626364656667370000000010101010101010101010101000
3439393901c4251525c2091e2828283131013131313131313111111111211111113e1f3f112117171711111717110101010404040101030f252525252424240d040404c5d8d7d8d7d8d7d8d7d8d6d5d6d5d6040404d5d7d8d7d8d7d8d7d8d7000000000000002424242424242424240000000010101010101010101010101000
34390f3903030303030303030303030303030303030303030f01390f01240f0a0b2626260f211111110a0b1111010f04040404010f03030324242424240c0c0d040404d5c8c7c8c7c8c7c8c7c8c603f2f3e1040404c5c7c8c7c8c7c8c7c8c7000000000000002468696a6b6c6d6e240000000010101010001111111011000000
34390f39e339e3e4e30fe334c5c628010f01190f010f0103032424242424241a1b2527250124010ff21a1b0f013901040404010f0103010101013901010f010d040404c5d8d7d8d7d8d7d8d7d8d603c52e2f040404d5d7d8d7d8d6d5d6d5d6000000000000002424242424242424240000000000101000111111111011000000
343939390606060601060634d5d628190a0b290c0c0c0c0c030c0c0c3901242424242424242403030303030303030338383803030303390c0c0c0c0c0c01010d040404d5d6d5d6d5d6d5d6d5d6f3e7d53e3f040404c5d8d7d8d7c604040404000000000000000000002300000000000000000000000000111010101010000000
3439390f06060606010606340a0b28291a1b010f010f390103010f0d373724241c1c1c242e072f0f01070707010a0b04040401c5c601010d2839390a0b01010d040404e2e30101e3e30101e3e3e403033535040404d5d6d5d6d5d604040404000000000000000000000000000000000000000000000000101010101010000000
343939390101e1010f0606341a1b28c5c60f39010303010f030f010d390f24241c3d1c243e1f3f010f353535391a1b39040404d5d60f010d2828391a1b010f0d0404040303e1c40303f3030303030303242404040403030303030304040404000000000000000000000000000000000000000000000000000000000000000000
343939390606060601060634280a0bd5d60a0b0f010303030301390d010124241c1c1c242525151e012e2f2c01010707040404010101010c0c0c0c0c0c01010d0404040403030303030303030303030324240404040303e803030304040404000000000000000000000000000000000000000000000000000000000000000000
340f0f39060606060106063407070707071a1b0c0c0c2e072f0c0c0c2e072f2424242424242424010c07070c0c012525040404010f010707010139010101010d0404040403030303e8030303030303030303383838030303e8030304040404000000000000363636363636363636363600000000000000000000000000000000
31313131313131310331313136363625250d0f0101013e1f3f0f390d3e1f3f0f01242819282828010d3e3f370d39010104040401190107070c0c0c0c01c5c60d040404040303030303030303030303030303040404030303030303040404040000000000003535353535da353535353500000000000000000000000000000000
280f0139010f012803c437373535355d5e0d390f010f252525390f0d252525010f242829f63928010d2626010d010f0404040101290126263d3d3d0d01d5d60d04040404041d040303030303e803030303030404040303e803030304040404000000000000fa1414eb141414fa14fa1400000000003636363636360000000000
07011916160f01d20303c4c4245b2439390cc30c0cc3370337010f0d0f03013901242801013928010d05050f0d0f010404040f010f0105053d3d3d0d01010f0d04040404041d040404040303030303e8030404040404030303030404040404000000000000f914e9eae9e9e9e9e9e91400000000003535353535350000000000
2601290404010101d3030303030303030303030303030303032424242424242424240303030303030101010f0d01010404040139010103010107070707390f0d04040404041d040404041d04030303030404040404040404041d0404040404000000000000f914e9e9e9e9e9e9e9e91400000000000303030303030000000000
2601010404010a0be2e3e3e3313107073131c5c63131e339e30f01010f010a0b0c0c0c0c0cc5c6030f0c0c0c0c030338383803030303030c0c363636360101c504040404041d383838381d04070704040404040404040404041d0404040404000000000000f914e9e9e9e9e9e9e9e91400000000000303030303030000000000
2501010101011a1b0f39390f0101252534c5c7c8c63416161616161616161a1b0139010119d5d60303030303030301040404010f0101030d011525252501c5c704040404041d040404041d04363604040404040404040404041d040404040400000000000014e9e9e9e9e9e9e9e9e91400000000000303030303030000000000
c5c6c20101390101010101013924242434d5d7d8d63404040404040404043919010f390129010f010f010f0f011616040404010f013903010f03030303c5c7c804040404041d040404041d38245f040404040404040404043838380404040400000000000014e9e9e9e9e9e9e9e9e91400000000000000230000000000000000
c7c8c61616010f0116161616161616161639d5d62834040404040404040416290101010f01011616161d161616040404040416010f01030303030303c5d8d7d80404040438383804040438383838040404040404040404040404040404040400000000000014e9e9e9e9e9e9e9e9e91400000000000000000000000000000000
d7d8d604041616160404040404040404041616161616040404040404040404010116161616160404041d04040404040404040416161601390101f3c5c7c8c7c804040404040404040404040404040404040404040404040404040404040404000000000000141414141414141414141400000000000000000000000000000000
d5d6160404040404040404040404040404040404040404040404040404040416160404040404040404e604040404040404040404040416161616c5c7c8d8d7d804040404040404040404040404040404040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000
__gff__
0100000001010080010180800101000000010000002001010180010100000380000000400001012001010000010180804001000101010101000000000100808000010101000000000000000000000000010001010505050505050301000101010103030303030303030303030303030000000000000000000003030000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008080010100000000000000000000000001018181202020000000000000000000202040030000000000000000000303000003000001010001010000
__sfx__
000100002605000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050800000c71018720247222472224725387003870000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00040000046100a6101162015620196201b6201b620186201562013620116200f6200d6100b6100a6100961008610076100661004610036100261001610006100060000600006000060000600006000060000600
c10400002b6102e620316203372033620317202a62025620216201d62018620147200e6200d6100b7100461003610007100070000700007000070000700007000070000700007000070000700007000070000700
8907000025654370503c0520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31030000196241f6342165429144281442713427134261342613425134251342512424124241242412424124231242312422124221242112420124201241f1241e12410150101501015004170041700417004175
010a00002062400600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000600001c55028550285522854228532285322852228522285120050200502005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010500000c7502b75024750227401f7301d7201a72018720137101271013710187101c71000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
78050000056120561206632066120761208632096120b6120d63210612156121b6122261200602006020060200602006020060200602006020060200602006020060200602006020060200602006020060200602
311800000c0241002413024100240c0241002413024100240c0241002415024100240c0241002415024100240c0241102415024110240c0241102415024110240e0241302417024130240e024130241702413024
9118000018010000000000018014000001c010000001f01021010000000000021014000001c010000001801024010000000000024014000002801000000240102101000000000002101400000230102401426014
911800000c0300c0300c0300c030000000c0300c03000000150301503015030150300000015030150300000011030110301103011030000001103011030000001303013030130301303000000130301303000000
011800000c0300c0300c0300c0300c0300c0300c0300c030150301503015030150301503015030150301503011030110301103011030110301103011030110301303013030130301303013030110301303011030
0118000015032150321503213032130321303210032100320c0320c0320c0320c0320c0320000210032100320e0320e0320e0320c0320c0320c0320e0320e0320e0320e0320e0320e0320e032000020000200002
0118000015032150321503213032130321303210032100321803218032180321803218032000021c0321c0321d0321d0321d0321c0321c0321c0321a0321a0321f0321f0321f0321f0321f032000020000200002
0118000015032150321503213032130321303210032100321803218032180321803218032000021c0321c0321d0321d0321d0321c0321c0321c0321a0321a032210321a032210321f0321f032000020000200000
__music__
01 4a4b0a4b
00 4a4b0a4b
00 4a4b0a0b
00 4a4b0a0b
00 4a0c0a4b
00 4a0c0a4b
00 4a0c0a0b
00 4a0c0a0b
00 4a0c0a4b
00 4a0c0a4b
00 4a4c4a0b
00 4a0c0a0b
00 4a0c0a0b
00 4a4e4a0c
00 4a0e4a0d
00 4a0f4a0d
00 4a0e0a0d
00 4a100a0d
00 4a0c0a4b
00 4a0c0a0b
02 4a0c0a0b
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
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66777777777777777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66777777777777777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111111111166666666666666661111111111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111111111166666666666666661111111111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111111666666666666666666666666111111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111111666666666666666666666666111111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111166666666666666666666666666661111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111111166666666666666666666666666661111111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
77777777777777777777777777777711111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
77777777777777777777777777771111111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
77777777777777777777777777771111111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
77777777777777777777777777111111111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
77777777777777777777777777111111111111111111111111111111111111111111111111111111116666666666666666666666666666666611111111111111
11777777777777777777111111111111111111111111111111111111111111111111111111111111111166666666666666666666666666661111111111111111
11777777777777777777111111111111111111111111111111111111111111111111111111111111111166666666666666666666666666661111111111111111
77777777111111111111111111111111111111111111111111111111111111111111111111111111111111666666666666666666666666111111111111111111
77777777111111111111111111111111111111111111111111111111111111111111111111111111111111666666666666666666666666111111111111111111
77777777777777111111111111111111111111111111111111111111111166666666666666666666111111111166666666666666661111111111111111111111
77777777777777111111111111111111111111111111111111111111111166666666666666666666111111111166666666666666661111111111111111111111
77777777777777771111111111111144444444444444444444444444444444444444444444444444444444444444444444111111111111111111111111111111
77777777777777771111111111111144444444444444444444444444444444444444444444444444444444444444444444111111111111111111111111111111
7777777777777777771111111111114499999999999999999999999999999999999999999999bbbb999999999999999944111111111111111111111111111111
7777777777777777771111111111114499999999999999999999999999999999999999999999bbbb999999999999999944111111111111111111111111111111
77777777777777777711111111111144ffffffffffffffff444444ff444444ffff4444ffff4444ffffffffffffffffff44111111111111111111111111111111
77777777777777777711111111111144ffffffffffffffff444444ff444444ffff4444ffff4444ffffffffffffffffff44111111111111111111111111111111
77777777777777777711111111111144999999999999bb9944994499994499994499999944994499999999999999999944111111111111111111111111111111
77777777777777777711111111111144999999999999bb9944994499994499994499999944994499999999999999999944111111111111111111111111111111
77777777777777777711111111111144ffffffffffffffbb444444ffff44ffff44ffffff44ff44ffffffffffffffffff44111111111111111111111111111111
77777777777777777711111111111144ffffffffffffffbb444444ffff44ffff44ffffff44ff44ffffffffffffffffff44111111111111111111111111111111
77777777777777771111111111111144999999999999999944999999994499994499999944994499999999999999999944111111111111111111111111111111
77777777777777771111111111111144999999999999999944999999994499994499999944994499999999999999999944111111111111111111111111111111
77777777777777111111111111111144ffffffffffffffff44ffffff444444ffff4444ff4444ffffffffffffffffffff44661111111111111111111111111111
77777777777777111111111111111144ffffffffffffffff44ffffff444444ffff4444ff4444ffffffffffffffffffff44661111111111111111111111111111
77777777111111111111111111111144999999999999999999999999999999999999999999999999999999999999999944661111111111111111111111111111
77777777111111111111111111111144999999999999999999999999999999999999999999999999999999999999999944661111111111111111111111111111
11111111111111111111111111111144ffffffff44ff44ff444444ff44ffffff44ffffff444444ff44ff44ffffffffff44661111111111111111111111111111
11111111111111111111111111111144ffffffff44ff44ff444444ff44ffffff44ffffff444444ff44ff44ffffffffff44661111111111111111111111111111
11111111111111111111111111111144999999994499449944994499449999994499999944999999449944999999999944111111111111111111111111111111
11111111111111111111111111111144999999994499449944994499449999994499999944999999449944999999999944111111111111111111111111111111
11111111111111111111111111111144ffffbbbb44ff44ff444444ff44ffffff44ffffff4444ffff444444bbbbffffff44111111111111111111111111111111
11111111111111111111111111111144ffffbbbb44ff44ff444444ff44ffffff44ffffff4444ffff444444bbbbffffff44111111111111111111111111111111
11111111111111111111111111111144999999994444449944994499449999994499999944999999999944999999999944111111111111111111111111111111
11111111111111111111111111111144999999994444449944994499449999994499999944999999999944999999999944111111111111111111111111111111
11111111111111111111111111111144ffffffffff44ffff44ff44ff444444ff444444ff444444ff444444ffffffffff44111111111111111111111111111111
11111111111111111111111111111144ffffffffff44ffff44ff44ff444444ff444444ff444444ff444444ffffffffff44111111111111111111111111111111
11111111111111111111111111111144999999999999999999999999999999999999999999999999999999999999999944111111111111111111111111111111
11111111111111111111111111111144999999999999999999999999999999999999999999999999999999999999999944111111111111111111111111111111
11111111111111111111111111111144ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44111111111111111111111111111111
11111111111111111111111111111144ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff44111111111111111111111111111111
11111111111111111111111111111144444444444444444444444444444444444444444444444444444444444444444444111111111111111111111111111111
11111111111111111111111111111144444444444444444444444444444444444444444444444444444444444444444444111111111111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666666666666666666661111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666666666666666666661111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111116666666666666666666666666666111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111116666666666666666666666666666111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111116666666666666666111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111116666666666666666111111111111111111111111111111111111111111111111111111
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
11111111111111111111111111111111111111111111111111111111111111666666666666661111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111666666666666661111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111666666666666666666666666661111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111666666666666666666666666661111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111166666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111166666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111117766666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111117766666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111777766666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111777766666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777766666666666666666666666666666677111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777766666666666666666666666666666677111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777666666666666666666666666667777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777666666666666666666666666667777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777777777666666666666667777777777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777777777666666666666667777777777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777776666666666666666667777777777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111177777777776666666666666666667777777777111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111776666666666666666666666666666667711111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111776666666666666666666666666666667711111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111666666666666666666666666666666666611111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111166666666666666666666666666666666666666111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111166666666666666666666666666666666666666111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111166666666666666666666666666666666666666111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111166666666666666666666666666666666666666111111111111111111111111111111111111111111
11111111dddd1111111111111111111111dddddddddd11116666666666666666666666dd66666666666666111111111111111111dddddddddd11111111111111
11111111dddd1111111111111111111111dddddddddd11116666666666666666666666dd66666666666666111111111111111111dddddddddd11111111111111
11111111dd11dd11dddddd11dd11dd11dddd11dd11dddd116666666666666666666666dd66666666dddd6611dddd11dddd1111dddd111111dddd111111111111
11111111dd11dd11dddddd11dd11dd11dddd11dd11dddd116666666666666666666666dd66666666dddd6611dddd11dddd1111dddd111111dddd111111111111
11111111dd11dd11dddd1111dd11dd11dddddd11dddddd111166666666666666666666dd666666dd66dd11dd11dd11dd11dd11dddd11dd11dddd111111111111
11111111dd11dd11dddd1111dd11dd11dddddd11dddddd111166666666666666666666dd666666dd66dd11dd11dd11dd11dd11dddd11dd11dddd111111111111
11111111dd11dd11dd111111dddddd11dddd11dd11dddd111111666666666666666666dd666666dd66dd11dddddd11dd11dd11dddd111111dddd111111111111
11111111dd11dd11dd111111dddddd11dddd11dd11dddd111111666666666666666666dd666666dd66dd11dddddd11dd11dd11dddd111111dddd111111111111
11111111dd11dd1111dddd11dddddd1111dddddddddd11111111111111666666666666dddddd11dddd1111dd11dd11dddd111111dddddddddd11111111111111
11111111dd11dd1111dddd11dddddd1111dddddddddd11111111111111666666666666dddddd11dddd1111dd11dd11dddd111111dddddddddd11111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
__meta:title__
pico valley v1.0
a demake by taxicomics
