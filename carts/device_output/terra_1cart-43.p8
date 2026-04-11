pico-8 cartridge // http://www.pico-8.com
version 39
__lua__

--terra - a terraria demake
--by cubee 🐱
cartdata "cubee_terra"

function _init()
  for i = -32768, 0x55ff do
    poke(i)
  end
  _reload()
  tospr("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9eeeeee8aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeae9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88eae88eee9a8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88aa988a9a9a9aa9aeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8a9aaaaaaaaa9aaaaaaaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee9a229aa929929929a98eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8aa233294444443339aaeeeeeeee89eeeeeeeeeeeae9eeeeeeeeeeeaaeeeeeeeea944343444433342aa988eeeeeeeaee9e9eeeeee9aeeeeeeeeeeee9e9eeeeee8a9333343333333339aaaeea8eeee9e8e9eeeeeee898ee8eeeeaeee8eaeeeeee8a233333343332232aaa889e8ee8a99a8a898e88a89aea988ee89e88899eeeeeea92929243329aa99aaaa9a9988ea9a9aaaa999a9a9aaaaa8e8eae89a9a9aeeee8aaa9a934439aaaaaaaaaaa9aa9a9aa999aaaaaaaaa999aaa9888a999aa88eeee9aaaa243639aaaa996119aaaaa92222439aaaa929226b9aaaa9a934229a9eeeeeaaaa23762aaaa91777b79aaa9343344432aa9343344771aaaa93444429a8eeee8aa9336139aa96b7617769aa93443233439a93443333679aaa23223432a9eeeeaaaa267139aa97769a9661aa23432992342a24332923161aa933aa9342a98eee8aa936732aa96b19aaa1329a93349aa9333993439aa93169aa22aaa243999eeee9aa371339aa1771111743aa93439aa9239a94339aa9239aaaaaaa9233998eee8a9a2673399ab16b671622aa93349aaaaaaa93439aaaaaaaa999992333998eeee9a936b32aa9776199a99aaaa2332aaaaaaa93332aaaaaaaa233334332a9eeeee8aa21732aa93449aaaaaaaa93432aaaaaaa933329aaaaaa93333333339a9eeee9a933139aaa93329a99329aa2339aaaaaaaa2339aaa9aa92339aa9332a98eeee892333329aaa2433223329a933329aa9aaa933329a9aaaa2333223333a9eeeee8a933339aaaa93333332aaa93339aaaaaaa93339aaa9aaa992233333399eeeee99233339a9a9a923232aaaa93229a9999a993229a9a99a99aaa922333999eeee8a29929a98889aa9a9aa99aa99a998e8e98a99aa9898998e989aa9992a98eeeee899aa998eeee99aaaa88e899899eeeeeee99898eeeeeeeeee889a9aaa98eeeeee8998eeeeeeeee8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee899a98eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", 64, 64, 0)
  t, mouse, mute, cam_x, cam_y, actx, acty, bosshp, env, spawns, bgs, around, stats, palettes, recipes, toolstat, drops = 0, dget(0) == 1, dget(1) == 1, 0, 0, 0, 0, 0, {__index = _ENV}, {}, split "0,0,16,16,16", split "-1,-1,0,-1,1,-1,-1,0,1,0,-1,1,0,1,1,1", split [[gslime|10|14|6|0|59:1|slime|0.8|1|0|0|176|0|1|1
,bslime|13|25|8|2|59:2|slime|1|1|0|0|144|0|1|1|12:13:7|0|0.875
,rslime|1|42|15|4|59:2_20:1|slime|1|1|1|0|144|0|1|1|0:1:6|0|0.875
,yslime|4|42|16|7|59:3_21:1|slime|1|1|1|0|144|0|1|1|3:4:5
,jslime|10|50|18|6|59:4|slime|1|1|1|0|144|0|1|1|9:10:5
,jspike|10|40|20|8|60:1_59:-4|slime|1|1|1|0|195|0|1|1|9:10:5:2:3
,eye|15|55|18|2|54:1|eye|0.8|1|0|1| 1.5|10.5|1|1|13:2:0:15
,caye|15|60|18|4|54:1|eye|0.7|1|0|1|1.5|10.5|1|1|6:2:7:15
,grye|9|55|20|0|54:1|eye|0.8|1|0|1|1.5|10.5|1|1|13:8:0:9
,zombie|9|40|14|6|59:3|fighter|0.5|0.3|0|0|146|0|1|1|0:2:3:1:6
,twigie|9|40|16|4|59:3|fighter|0.55|0.3|0|0|146|0|1|1|0:2:3:1:2:9
,femaie|9|32|12|3|59:3|fighter|0.6|0.3|0|0|146|0|1|1|2:2:3:1:15:3
,baldie|9|36|15|5|59:3|fighter|0.5|0.3|0|0|146|0|1|1|2:2:3:1:6:15
,eater|8|38|24|8|61:1_____________________________________________________________________________________________99:1|flying|0.5|1|0|1|1.5|12.5|1|1|1|0|1.4
,bat|13|15|13|2|86:1|flying|0.8|1|0|0| 162|0|1|1|12:13:5
,jbat|2|30|20|4|89:1|flying|0.8|1|0|0| 162|0|1|1|1:2:4
,hornet|3|46|26|12|60:1|flying|0.5|1.5|1|0|166|0|1|1
,honeyt|4|42|28|12|60:1|flying|0.6|1.5|1|0|166|0|1|1|4:5:2:3:4
,leafyt|9|38|30|14|60:1|flying|0.6|1.5|1|0|166|0|1|1|3:4:8:9:10
,skeleton|7|40|20|8|52:3_52:5_56:1|fighter|0.6|0.4|0|0|182|0|1|1|1:2:3:12:1
,pantston|7|40|22|8|52:3_52:5_56:1|fighter|0.6|0.4|0|0|182|0|1|1|1:2:3:2:6
,headacon|7|44|20|12|52:3_52:5_56:1|fighter|0.6|0.4|0|0|182|0|1|1|8:3:4:9:1
,cohbeetle|15|40|20|10|93:-1|fighter|1|0.5|0|0|164|0|1|1|1:15:15:3:2
,lacbeetle|15|40|20|10|93:-1|fighter|1|0.5|0|0|164|0|1|1|2:15:3:1:0
,cyabeetle|13|40|20|10|93:-1_20:2|fighter|1|0.5|0|0|164|0|1|1|12:13:13:1:0
,eocservant|15|8|12|0|0:1|flying|1|0.6|0|1|1.5|14.5|1|1
,marcoservant|2|20|16|0|0:1|flying|1|0.9|0|1|1.5|16.5|1|1
,tentacle|10|200|22|10|0:1||0|1|0|1|1.5|22.5|1|1|8:9:3:4:5:9:10:8:9:10:11:12:13:14:10
,eoc|15|2400|14|12|23:-18|eoc|0|1|0|1|19.5|22.5|3|3|1|1200|1.1
,kingslime|13|1800|22|10|20:-7_21:-7_22:-7|slime|0|1|1|0|230|0|3|2
,marco|1|3700|28|13|98:-1_55:-6|eoc|0|1|0|1|36|23|4|4|1|2100|1.4
,plantera|10|4200|40|16|90:5||0|1|0|1|27.5|22.5|3|3
,seed|10|1|25|0||projectile|0|1|1|1|1.5|18.5|1|1
,marcolaser|10|1|16|0||projectile|0|1.8|1|1|1.5|20.5|1|1|12:13
,stinger|10|1|13|0||projectile|0|0.7|1|1|1.5|24.5|1|1|0:0:0:0:0:2:3
]], split([[
130,132,4,
9,10,5,134,
131,3,139,7,
1,140,12,136,128;

128,130,132,
4,137,133,5,
1,131,3,6,
129,1,140,2,128;

0,128,130,
132,4,130,133,
129,1,131,13,
0,129,1,130,0;

0,0,128,
128,132,128,130,
0,129,1,5,
0,0,129,128,0;

0,0,0,
0,128,0,128,
0,0,129,130,
0,0,0,0,0;
]], ";"), split([[
17:3|5,59;
68:1|17:3,5:4;
14:2|5;
5|14:2;
78:1:15|5:6;
13:1:16|3:2;
64:1:16|19:2;
70:1:16|21,3;
75:1:15|5:5;

87:1:15|86:2,93;
87:2:4|9:3;
103:1:4|96:1,55:2,98;
96:1:18|89:10,55:2;

74:1:4|55:1,61:2,52:99;

107:100:4|52:100,98:1;
105:30:18|52:30,58:2;

80:15|17:1,52:15;
52:25:15|3:1,5:1;

73:1:4|55:1,61:2,51:99;

106:50:18|51:50,55:1;
106:50:18|81:50,55:1;

81:20:18|57:1;
51:25:18|56:1;

92:1:4|57:2,59:99;

15|5:10;
16:1:15|5:4,3:10,17:3;
18:1:15|56:5;
4:1:18|58:4,98:1;

91:1:4|53,90:4;
65:1:4|85,90:4;

104:1:4|58:3,89:3,98:1;

53:1:4|24,84,34;
8:1:4|72,55:2;
94:1:4|93:5,95;

102:1:4|60:10,89:8;

84:1:18|60:10,89:8;
85:1:18|50,55:2;
95:1:18|48,55:1;

101:1:18|55:4,61:6;

55:1:16|23:3;
24:1:18|55:3;
26:1:18|55:4;
72:1:15|17:4,5:6;

100:1:18|58:7;

58:1:16|22:4;
34:1:18|58:2;
28:1:18|58:3;
33:1:18|58:3,5:4;
35:1:18|58:2,5:3;
32:1:18|58:2,5:3;

57:1:16|21:4;
38:1:18|57:2;
29:1:18|57:3;
37:1:18|57:3,5:4;
39:1:18|57:2,5:3;
36:1:18|57:2,5:3;

56:1:16|20:3;
42:1:18|56:2;
30:1:18|56:3;
41:1:18|56:3,5:3;
43:1:18|56:2,5:3;
40:1:18|56:2,5:3;

46:1:15|5:2;
31:1:15|5:3;
45:1:15|5:3;
47:1:15|5:3;
44:1:15|5:3;

69:4:15|5;
66:4:15|2;
67:4:15|3;
71:4:15|7;
76:4:15|12;

5:1:15|69:4;
2:1:15|66:4;
3:1:15|67:4;
7:1:15|71:4;
12:1:15|76:4;

1:4|2:4,89;
6:4|7:4,89;
10:4|2:4,61;

62:1:15|54:6;
63:1:18|59:15;
25:1:18|61:6,55:1;
88:1:4|89:6;

108:1:75|90:6,9:1,56:2,58:1;

77:1:4|90,55,61:8;
48:1:4|90:2,28,61:2;
49:1:4|90:2,56:2,54:2;
50:1:4|90:2,56:3;
9:1:4|90,87;
87:1:4|90,9;
3:20:4|90,12:20;
12:20:4|90,3:20;
99:1:4|90:2,24
]], ";"), split [[
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
12:ranged:12:gel:1:1.3,
20:hpup:1:1,
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,

0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
20:melee:20,
0:summon:16:marco-22,
9:pick:15:2.4:0:1.1,
0:block,
11:ranged:26:arrow,
9:ranged:27:arrow,
8:ranged:28:arrow,
4:ranged:30:arrow,

9:hammer:28:5:0:1.1,
6:pick:17:1.8:0:1.1,
13:melee:20:1.1:0:1.1,
7:axe:26:1.8:0:1.1,
9:hammer:29:4,
6:pick:19:1.3,
11:melee:21,
6:axe:26:1.3,
7:hammer:30:4,
5:pick:20:1.1,
10:melee:21,
5:axe:27:1.1,
2:hammer:37:3,
4:pick:23,
7:melee:25,
3:axe:30,

8:ranged:20:arrow:0:1.1,
0:mirror,
24:ranged:48:bullet:0:1.2,
7:bullet:8:220,
4:arrow:3.5:52,
42:melee:21:1.15:1:1.2,
0,0,0,0,0,
0:gel:3:123:0:2,
0,0,
0:summon:16:eoc-53,
0:summon:16:kingslime-0,

0:block,
22:ranged:10:bullet:1,
0:block,
0:block,
0:block,
0:block,
0:block,
0:block,
6:ranged:26:gel,
8:bullet:8:220,
6:arrow:3.5:52,
0:block,
0:block,
0,
0:block,
100:pick:8:100,

7:arrow:4:80,
9:bullet:9:220,
0,0,
28:melee:30:1.3:0:1.3,
5:ranged:10:bullet:1:1.1,
15:hpup:60,
50:hpup:140,
0:summon:16:plantera-31,
0,0,
60:melee:18:1.2:1:1.4,
0:gel:4.5:123:0:3,
0,
22:ranged:18:arrow:1:1.1,
14:ranged:25:arrow:1,
0:boot:16:1.3,
0,
0,
22:melee:23:1.1:0:1.2,
5:armour,
8:armour,
13:armour,
0:boot:16:1.5:0:1.2,
13:melee:12:2:1:1.2,
18:arrow:3.2:105,
8:bullet:11:220:0:2,
14:arrow:4.5:107:0:2,
0:saturn,
]], split [[
2,
2,
3,
4,
5,
7,
7,
8,
9,
2,
2
]]
  pjump, pair, pdigt, pfall, pdiet, pswing, pangle, mobs, lights, projectiles, craftable, items, parts, invsel, invside, craftsel, mode, nextmusic, currentmusic, worldmusic, swingitem, drops[79], drops[82], drops[83], tilenames = true, true, 0, 0, 0, 0, 0, {}, {}, {}, {}, {}, {}, 1, 1, 1, 1, 0, -1, 0, {id = 0, usetime = 10}, 78, 5, 5, split([[forest grass
dirt
stone
cursed forge
wood
jungle grass
mud
flamethrower
life crystal
corrupt grass

ebonstone
grey brick
wooden platform
workbench
furnace
torch
anvil
clay
iron ore
silver ore
gold ore
demonite ore
light's bane
sigil of blight
nightmare pickaxe
sapling
gold bow
silver bow
iron bow
wood bow
gold hammer
gold pickaxe
gold broadsword
gold axe
silver hammer
silver pickaxe
silver broadsword
silver axe
iron hammer
iron pickaxe
iron broadsword
iron axe
wooden hammer
wooden pickaxe
wooden broadsword
wooden axe
shade bow
magic mirror
musket
musket ball
wood arrow
night's edge
lens
demonite bar
iron bar
silver bar
gold bar
gel
stinger
rotten chunk
suspicious-looking eye
slime crown
red brick
cubee's dogblaster
dirt wall
stone wall
campfire
wood wall
polished silver brick
jungle wall
wand of sparking
endless musket pouch
endless quiver
table
ebonstone wall
shadow orb
wooden door
the landshearer
flaming arrow
silver bullet


blade of grass
minishark
mushroom
healing potion
suspicious bulb
leafy seed
shimmering seed
terra blade
endless gel booster
beetle husk
beetle bow
demonite repeater
hermes boots

soul of blight
tentacle spike
gold armour
shadow armour
jungle armour
wasteland treads
goldery blattery
golden arrow
demonite bullet
blighted arrow
leinfors' hair protector
]], "\n")
  generate()
  loadplayer "100,100|46:1,45:1,47:1"
  spawnplayer()
  for k, i in next, recipes do
    local r = split(i, "|")
    recipes[k] = {split(r[1], ":"), split(r[2])}
    for j, o in next, recipes[k][2] do
      recipes[k][2][j] = split(o, ":")
    end
  end
  if stat(6) ~= "" then
    loadplayer(stat(6))
    mode = 2
  end
  music "0"
  poke(0x5f36, 16)
  poke(0x5f5a, 255)
end

function _update60()
  menuitem(5, mute and "music: off" or "music: on", function()
    mute = not mute
    dset(1, mute and 1 or 0)
  end)
  poke(0x5f5c, invopen and 0 or -1)
  poke(0x5f2d, mode < 3 and 1 or 0x3)
  msx, msy, jb, ab, rbp, pgfx, invkey, pinvkey, pdef, jk, saturn = stat(32), stat(33), mouse and invopen and 5 or 4, mouse and invopen and 4 or 5, btnp(1), pgfx or "", btnp(6) or stat(28, 8), invkey, 0, btn(jb) or stat(28, 44)
  while stat(30) do
    if stat(31) == "\xe3\x82\xb3" then
      p = stat(4)
    end
  end
  smolmap()
  if mode < 3 then
    if stat(120) or p then
      if mode == 2 then
        for i = 0, p and 32767 or serial(0x800, 0x8000, 32767) do
          poke(0x8000 + i, (p and ord(p[i + 1]) or peek(0x8000 + i)) - 32)
        end
        spawnplayer(php)
      else
        if not p then
          p = ""
          serial(0x800, 0x4300, 4864)
          for i = 0, 4864 do
            p = p .. (chr(peek(0x4300 + i)))
          end
        end
        loadplayer(p)
      end
      loadedfile = true
    end
    if btnp(5) then
      load "#terra_char_edit"
    end
    if btnp(4) or loadedfile then
      mode = mode + (1)
      loadedfile, p = ssfx "7,0"
    end
    if mode > 2 then
      _reload()
    end
  else
    menuitem(4, mouse and "mouse: on" or "mouse: off", function()
      mouse = not mouse
      dset(0, mouse and 1 or 0)
    end)
    lights, mx, jpow = {}, 1, 1
    menuitem(1, "save", function()
      sp, sw = php .. "," .. php_max .. "," .. phurt .. "," .. orbsmash .. "," .. worldtime .. "|", ""
      genprint "processing player..."
      for k, i in next, inventory do
        sp = sp .. (i.id .. ":" .. i.amount .. (k < #inventory and "," or "|"))
      end
      genprint "processing world..."
      for i = 0, 32767 do
        sw = sw .. (chr(peek(i + 0x8000) + 32))
      end

      function a(s, s2)
        printh(s, "@clip")
        repeat
          poke(0x5f30, 1)
          genprint(s2, "press pause to continue")
        until btn(6)
      end

      a(sp .. pgfx .. "|", "player copied to clipboard")
      a(sw, "world copied to clipboard")
    end)
    bigmap()
    -- inventory
    for i in all(inventory) do
      local _ENV, g = i, _ENV
      local stats = split(toolstat[id], ":") or split "0,item"
      type = stats[2] or "item"
      tool = type == "pick" or type == "axe" or type == "hammer"
      damage, var, usetime, amount, autoswing, scale, melee = stats[1], stats[4], stats[3] or 16, amount or 1, stats[5] == 1 or tool or type == "block", stats[6] or 1, type == "melee" or tool
      if type == "boot" then
        g.mx, g.jpow = max(mx, var), max(jpow, scale)
      end
      if type == "armour" then
        g.pdef = max(pdef, damage)
      end
      if type == "saturn" then
        g.saturn = true
      end
      knockback = type == "melee" and var or 1
      del(inventory, amount <= 0 and _ENV)
    end
    if invside == 1 then
      invsel = loop(invsel - stat(36), inventory)
    else
      craftsel = loop(craftsel - stat(36), craftable)
    end
    if invopen then
      if mouse then
        invside = msx // 64
      end
      if invside > 0 then
        if btnp(0) and #craftable > 0 then
          invside = 0
        end
        if btnp(2) then
          invsel = invsel - (1)
        end
        if btnp(3) then
          invsel = invsel + (1)
        end
        invsel = loop(invsel, inventory)
        -- trash
        if btnp(ab) then
          if hoveritem then
            trashslot, hoveritem = hoveritem
          else
            hoveritem, trashslot = trashslot
          end
          updaterecipes()
        -- hover
        elseif btnp(jb) or invkey and not pinvkey and hoveritem then
          if hoveritem then
            hoveritem = add_inventory(hoveritem, max(invsel, 1))
          else
            hoveritem = deli(inventory, invsel)
          end
          updaterecipes()
        end
        invsel = min(invsel, #inventory)
      -- craft
      else
        if rbp then
          invside = 1
        end
        if btnp(2) then
          craftsel = craftsel - (1)
        end
        if btnp(3) then
          craftsel = craftsel + (1)
        end
        craftsel = loop(craftsel, craftable)
        local recipe = craftable[craftsel]
        if recipe then
          local out, ing = unpack(recipe)
          if btnp(jb) then
            for i in all(ing) do
              local missing = true
              for _ENV in all(inventory) do
                if id == i[1] and amount >= (i[2] or 1) then
                  missing = false
                end
              end
              if missing and avail then
                avail = ssfx "9,0"
              end
            end
            if avail then
              for i in all(ing) do
                for _ENV in all(inventory) do
                  if id == i[1] then
                    amount = amount - (i[2] or 1)
                  end
                end
              end
              -- find out
              local slot, ininv = 1
              for a in all(inventory) do
                if a.id == out[1] then
                  ininv = true
                end
                if not ininv then
                  slot = slot + (1)
                end
              end
              if ininv then
                inventory[slot].amount = inventory[slot].amount + (out[2] or 1)
              else
                add_inventory {id = out[1], amount = out[2] or 1}
              end
              ssfx "8,2"
            end
          end
          if pbtn4 and not btn(jb) then
            updaterecipes()
          end
          pbtn4 = btn(jb)
        else
          invside = 1
        end
      end
      pjump = true
    else
      tx, ty, invside, craftsel, frc, bossmusic = rnd "320", rnd "47", 1, 1, pair and 0.03 or 0.08
      if mget(tx, ty) == 27 then
        tree(tx, ty + 1)
      end
      worldtime = worldtime + (0.4)
      worldtime = worldtime % (24000)
      if pdead then
        pdiet = pdiet - (1)
        if pdiet <= 0 and jk then
          spawnplayer(max(php_max / 2, 100))
        end
      else
        php = php + (t % 100 // 99)
        local bl, br = btn(0) or stat(28, 4), btn(1) or stat(28, 7)
        if bl then
          if pxv > -mx then
            pxv = pxv - (pxv > 0 and 0.15 or 0.08)
          end
          if canturn then
            pflip = true
          end
        elseif br then
          if pxv < mx then
            pxv = pxv + (pxv < 0 and 0.15 or 0.08)
          end
          if canturn then
            pflip = false
          end
        else
          pxv = pxv - (sgn(pxv) * frc)
          if abs(pxv) <= frc then
            pxv = 0
          end
        end
        pyv = pyv + (0.08)
        -- right
        local d = 0
        repeat
          local bx, by = (px + 3 + d) / 8, py / 8 + 0.375
          local b, t = mget(bx, by), fmget(bx, py / 8 - 0.375, 0)
          if fget(b, 5) then
            door(bx, by, b, 1)
          elseif pxv > 0 and (t or fget(b, 0)) then
            pxv = 0
            px = px + (d)
            if br and not t then
              pyv, jk = min(pyv, -1), true
            end
            break
          end
          d = d + (1)
        until d > pxv or e
        -- left
        d = 0
        repeat
          local bx, by = (px - 4 + d) / 8, py / 8 + 0.375
          local b, t = mget(bx, by), fmget(bx, py / 8 - 0.375, 0)
          if fget(b, 5) then
            door(bx, by, b, -1)
          elseif pxv < 0 and (t or fget(b, 0)) then
            pxv = 0
            px = px + (d)
            if bl and not t then
              pyv, jk = min(pyv, -1), true
            end
            break
          end
          d = d - (1)
        until d < pxv
        px = px + (pxv)
        -- down
        d, pair = 0, true
        repeat
          local y = (py + 4 + d) / 8
          local l, r = mget(px / 8 - 0.375, y), mget(px / 8 + 0.25, y)
          if pyv > 0 and (fget(l, 0) or fget(r, 0) or (l == 14 or r == 14) and not (btn(3) or stat(28, 22))) then
            if not jk then
              pjump = false
            end
            pyv, pair = 0
            py = py + (d)
            pfall = max(pfall / 8 - 13)
            if pfall > 0 then
              php = php - (pfall * 10 // 1)
              piframes, pfall = 30, 0
              sfx(0, -1, phurt, 12)
            end
            if jk and not pjump then
              pjump, pyv = true, -2.2 * jpow
            end
            break
          end
          d = d + (1)
        until d > pyv
        -- up
        d = 0
        repeat
          local y = (py - 5 + d) / 8
          local l, r = fmget(px / 8 - 0.375, y, 0), fmget(px / 8 + 0.25, y, 0)
          if pyv < 0 and (l or r) then
            if l and r then
              pyv = 0
              py = py + (d)
            end
            if not r then
              px = px + (1)
            end
            if not l then
              px = px - (1)
            end
            break
          end
          d = d - (1)
        until d < pyv
        if pjump and not jk then
          pyv = max(pyv, -0.2)
        end
        py = py + (pyv)
        pfall = pfall + (pyv)
        digx, digy = pflip and -7 or 7, (btn(3) and 7) or (btn(2) and -7) or 0
        if (btn(3) or btn(2)) and not (btn(0) or btn(1)) then
          digx = 0
        end
        actx, acty, helditem = (mouse and cam_x + msx or px + digx) / 8, (mouse and cam_y + msy or py + digy) / 8, inventory[invsel] or {id = 0, usetime = 10}
        tile, canturn, a8x, a8y, hitype, hiuse, hid, hivar, hiscale, digging = mget(actx, acty), true, actx * 8, acty * 8, helditem.type, helditem.usetime, helditem.id, helditem.var, helditem.scale
        local svar = split(hivar, "-")
        if btn(ab) and (not helditem.tool or not mouse or dist(actx * 8 - px, acty * 8 - py) < 32) then
          if lastitem == helditem then
            if not fget(hid, 7) and pswing == 0 and (btnp(ab) or helditem.autoswing) then
              pswing, swingitem = hiuse, helditem
            end
            if hid == 91 then
              if pdigt <= 0 then
                pdigt = hiuse * 2
                sfx "3"
                add_projectile(px, py, pangle, 2.5, 35, 97)
              end
              pdigt = pdigt - (1)
            elseif helditem.tool then
              if hitype == "axe" and tile == 83 or hitype == "pick" and fget(tile, 1) and mget(actx, acty - 1) ~= 83 or hitype == "hammer" and fget(tile, 2) then
                digging = true
                pdigt = pdigt + (hivar or 1)
                if pdigt % hiuse == 1 then
                  sfx "4"
                end
                if pdigt >= hiuse * 3 then
                  pdigt = 0
                  break_tile(actx, acty, tile)
                end
              end
            elseif hitype == "block" and pdigt % 7 == 0 then
              if not mouse and hid == 14 and pxv ~= 0 then
                acty = acty + (1)
              end
              local lt, tile, canplace = mget(actx, acty + 1), mget(actx, acty)

              local function c(i)
                return fget(i, 0) or fget(i, 2) or i == 14
              end

              for i = -1, 1 do
                if tile == 0 and (c(mget(actx + i, acty)) or c(mget(actx, acty + i))) then
                  canplace = true
                end
              end
              if hid < 82 and fget(hid, 4) then
                canplace = fget(lt, 0) or lt == 14
              end
              if canplace and hid ~= tile and not fget(tile, 0) and tile < 83 then
                if tile > 0 then
                  break_tile(actx, acty, tile)
                end
                sfx "4"
                mset(actx, acty, hid)
                helditem.amount = helditem.amount - (1)
              end
            elseif hitype == "ranged" and pswing == hiuse then
              ammosprite, ammodamage = -1
              for a in all(inventory) do
                if a.type == hivar then
                  ammodamage = a.damage
                  if not fget(a.id, 1) then
                    a.amount = a.amount - (1)
                  end
                  add_projectile(px, py, pangle, a.usetime / 2, helditem.damage + ammodamage, a.var, a.scale)
                  ssfx(hivar == "gel" and "9,1" or "7,3")
                  break
                end
              end
              if not ammodamage then
                pswing = 0
                ssfx "9,0"
              end
            elseif hitype == "hpup" and btnp(ab) and pswing == hiuse then
              if php < php_max and not hivar or hivar and php_max < 400 then
                if hivar then
                  php_max = php_max + (helditem.damage)
                end
                php = php + (helditem.damage)
                helditem.amount = helditem.amount - (1)
                sfx "5"
              end
            elseif hitype == "summon" and (svar[1] ~= "marco" or timelight > 1) and btnp(ab) and currentmusic == svar[2] then
              sfx "10"
              addmob(svar[1], px + 80 * sgn(rnd "-1"), py - 40, true)
              helditem.amount = helditem.amount - (1)
              _reload()
              if svar[1] == "plantera" then
                tospr("eeee92f212ffff212f29eeeeeaae8222122ff2212228eaae54991221222222221221994544e812212222222212218e44eef811212222222212118feeee1f1111122222211111f1eeeee2f12f11222211f21f2eeeeee11a81f111111f18911eeeeee9aa9a1211112199aaaeeeeeaa98aa99a99aa9aa89aaeeeee98aa99a9cc9a89aa89eeeeeee999889e8ce9ce9aaeeeeeeeee898ceec8ec8e98eeeeeeeeeeeee88e8eee8ceeeeeeeeeeeeee8cee8ceeceeeeeeeeeeeeeeee8eee8eeeeeeeeeee", 24, 72, 112)
              end
            elseif hitype == "mirror" and btnp(ab) then
              spawnplayer(php)
              sfx "11"
            end
          end
        elseif pswing == 0 then
          pdigt, lastitem = 0, helditem
        end
        pswing, canturn = max(pswing - 1), not (pswing > 1 and (helditem.type == "melee" or helditem.type == "ranged"))
        -- music
        local floortile = mget(px / 8, py / 8 + 1)
        if floortile >= 1 and floortile <= 3 then
          worldmusic = py / 8 > 47 and 12 or (worldtime < 17500 and worldtime > 4300 and 0 or 53)
        else
          worldmusic = tonum(split ",,,,,31,31,,,22,22,22" [floortile]) or worldmusic
        end
        local a, d = (lastitem.usetime - pswing) / (lastitem.usetime * 2) + 0.1, 4 + 4 * hiscale
        wxo, wyo = cos(a) * (pflip and d or -d), sin(a) * d
      end
      for _ENV in all(parts) do
        yv = min(yv + 0.07, 3)
        xv = xv * (0.98)
        x = x + (xv)
        y = y + (yv)
        li = li - (1)
        if li < 0 then
          del(parts, _ENV)
        end
      end
      for i in all(items) do
        local _ENV, g = i, _ENV
        yv, timer = min(yv + 0.04, 1.2), max(timer - 1)
        xv = xv * (0.95)
        if not pdead and timer <= 0 and abs(px - x) < 24 and abs(py - y) < 24 then
          xv = xv + ((px - x) / 50)
          yv = yv + ((py - y) / 50)
          if abs(px - x) < 4 and abs(py - y) < 4 then
            if id == 0 then
              g.php = g.php + (20)
            else
              local slot, ininv = 1
              for a in all(inventory) do
                if a.id == id then
                  ininv = true
                end
                if not ininv then
                  slot = slot + (1)
                end
              end
              if ininv then
                g.inventory[slot].amount = g.inventory[slot].amount + (amount)
              else
                add_inventory {id = id, amount = amount}
              end
              ssfx "7,2"
            end
            del(items, _ENV)
          end
        -- fall
        else
          local u, v = x / 8, y / 8
          local gnd = mget(u, v + 0.25)
          if fget(gnd, 0) or gnd == 14 then
            yv = min(yv)
          end
          if fmget(u, v - 0.25, 0) then
            yv = max(yv)
          end
          if fmget(u, v, 0) then
            xv = 0
          end
        end
        x = x + (xv)
        y = y + (yv)
        del(items, #items > 40 and i)
      end
      for _ENV in all(projectiles) do
        if fget(bulletsprite, 0) then
          yv = yv + (0.01)
        end
        x = x + (xv)
        y = y + (yv)
        del(projectiles, (fmget(x / 8, y / 8, 0) or pierce <= 0) and _ENV)
      end
      -- spawning
      if t % (6 + #mobs) == 1 and not pdead then
        local p, ata, adi = py // 8, rnd(), 80 + rnd "24"
        local atx, aty, sp = (px + cos(ata) * adi) // 8, p + sin(ata) * adi // 8, true
        for ix = -8, 8 do
          for iy = -7, 7 do
            if mget(atx + ix, aty + iy) == 68 then
              sp = false
            end
          end
        end
        if sp and not fmget(atx, aty, 0) then
          local sptile, forest = mget(atx, aty + 1), (worldtime < 4300 or worldtime > 17500) and "zombie,zombie,twigie,twigie,baldie,baldie,femaie,femaie,eye,eye,caye,grye" or "gslime,gslime,gslime,bslime"
          setspawns("10,11,12", "eater")
          setspawns("6,7", "jslime,jspike,jspike,jbat,jbat,jbat,jbat,hornet,hornet,honeyt,honeyt,leafyt,leafyt,lacbeetle")
          if p > 76 then
            setspawns("1,2,3,5", "bat,bat,bat,bat,bat,bat,skeleton,skeleton,pantston,headacon,rslime,rslime,rslime,cohbeetle")
            setspawns("19,20,21,22", "bat,bat,skeleton,pantston,headacon,rslime,rslime,rslime,cyabeetle")
          elseif p > 47 then
            setspawns("1,2", "bslime,bslime,yslime,yslime,rslime")
            setspawns("3,5,19,20,21,22", "bat,bslime,bslime,yslime,yslime,rslime")
          else
            setspawns("1,2,3,5", forest)
            setspawns("6,7", "jslime,jbat,jbat")
            setspawns("19,20,21,22", nil)
          end
          if spawns[sptile] then
            addmob(rnd(split(spawns[sptile])), atx * 8 + 4, aty * 8 + 4)
          end
        end
      end
      -- mobs
      distance, pangle, bosshp = 120, pflip and 0.5 or 0, 0
      local cansting = split "hornet,honeyt,leafyt,jspike"
      for i in all(mobs) do
        local hbscale, playerang, id, ai, collide, stoponwalls, friction, boss, bouncy, grav = 1, 0.25 - atan2(px - i.x, py - i.y) % 1, i.id, i.ai, true, true, true
        i.ispr = i.sprx
        if ai == "flying" then
          if i.rspr then
            i.sprx = 1.5 + t % 20 // 10 * 2
          end
          i.iflip = i.xv < 0
        end
        do
          local _ENV = i
          if id == "eocservant" then
            collide, friction = false
          elseif id == "eoc" then
            spry, bossmus = 22.5 + t % 20 // 10 * 4, 41
          elseif id == "kingslime" then
            scale, vmod, bossmus, boss = 0.6 + hp / 2000, 1.5 - hp / 2500, 41, true
            if hp ~= php then
              addmob("bslime", x, y)
            end
            php = hp
          elseif id == "marco" then
            spry, bossmus, hbscale = 23 + t % 20 // 10 * 5, 41, 0.65
          elseif id == "plantera" then
            spry, bossmus, ang, boss, collide, friction = 22.5 + t % 20 // 10 * 4, 41, playerang, true
            if t % (secondphase and 120 or 70) == 0 then
              addmob("seed", x, y, true)
            end
            if hp < 2200 then
              if not secondphase then
                for a = 0, 5 do
                  addmob("tentacle", x, y, true, i)
                end
                secondphase, palette = true, "8:9:3:4:5:9:10:8:9:10:11:12:13:14:10"
              end
              s, sprx = 0.022 + sin(t / 70) / 50, 31.5
            else
              s = 0.004 + sin(t / 100) / 100
            end
            xv = xv + (s * sgn(px - x))
            yv = yv + (s * sgn(py - y))
            xv, yv = mid(-0.5, xv, 0.5), mid(-0.5, yv, 0.5)
          elseif id == "tentacle" then
            angv, tang, collide, friction = angv or 0, host.ang + sin(t / 100 + irnd) * irnd
            sprx = 1.5 + (t + irnd * 20) % 20 // 10 * 2
            if ang > tang then
              angv = angv - (0.0007)
              if ang > 0.75 and tang < 0.25 then
                angv = angv + (0.0005)
              end
            else
              angv = angv + (0.0007)
              if tang > 0.75 and ang < 0.25 then
                angv = angv - (0.0005)
              end
            end
            angv, d = mid(-0.006, angv, 0.006), 30 + sin(t / 60 + irnd) * 14
            ang = ang + (angv)
            x, y = host.x + cos(ang - 0.25) * d, host.y - sin(ang - 0.25) * d
            if host.hp <= 0 then
              hp = 0
            end
          end
          ang = ang % (1)
          if ai == "fighter" then
            xv = xv + (sgn(px - x) * (air and 0.005 or 0.03) * vmod)
            grav, xv, friction = true, mid(-vmod, xv, vmod)
            iflip = xv < 0
            ispr = ispr + (x / 8 % 2)
          elseif ai == "slime" then
            grav, jumpt, d, v, stoponwalls = true, jumpt or 60, d or sgn(rnd "-1"), angry and sgn(px - x) or d
            jumpt = jumpt - (0.5 * vmod)
            if jumpt <= 0 and not air then
              jumpt, yv, xv = 80 + rnd "40", -1.2 - rnd(), v * vmod
            end
            ispr = ispr + ((jumpt < 30 and t % 20 // 10 or t % 40 // 20) * w)
          elseif ai == "flying" then
            bouncy, v, ang = true, 0.02, playerang
            ispr = ispr + (t % 20 // 10)
            xv, yv = mid(-vmod, xv + cos(0.25 - playerang) * 0.01 * vmod, vmod), mid(-0.5 * vmod, yv + sin(0.25 - playerang) * 0.01 * vmod, 0.5 * vmod)
          elseif ai == "eye" then
            bouncy, xv, yv = true, mid(-0.8, xv + sgn(px - x) * 0.01, 0.8), mid(-0.5, yv + sgn(py - y) * 0.01, 0.5)
            ispr = ispr + (t % 20 // 10)
            ang = atan2(yv, xv) % 1 + 0.5
          elseif ai == "projectile" then
            ang, collide, friction = atan2(yv, xv) % 1 + 0.5
            if angry then
              xv, yv, angry = cos(0.25 - playerang) * vmod, sin(0.25 - playerang) * vmod
            end
            if id == "stinger" and fmget(x / 8, y / 8, 0) then
              x = -32000
            end
            x = x + (xv)
            y = y + (yv)
          elseif ai == "eoc" then
            ang, boss, collide, friction = playerang, true
            if hp < phaseswitch then
              damage, defence = 23, 0
              if not secondphase then
                dashstate, secondphase = 1, true
              end
            end
            -- leave
            if timelight <= 1 then
              yv = yv - (0.02)
            -- spin
            elseif dashstate == 1 then
              angv, ang2 = angv or -0.08, ang2 or ang
              angv = angv + (0.002)
              ang2 = ang2 + (max(angv))
              ang = ang2
              if angv > 0.2 then
                dashstate = sfx "10"
                sprx = id == "marco" and 41 or 23.5
              end
              xv = xv * (0.97)
              yv = yv * (0.97)
            -- dash
            elseif dashstate then
              if t % 120 == 10 then
                va, v = 0.25 - playerang, (secondphase and 2.4 or 1.6) * vmod
                if secondphase then
                  sfx "10"
                end
              end
              xv, yv = cos(va) * v, sin(va) * v
              v = v * (0.98)
            -- above
            else
              if t % 120 == 1 and (id == "marco" or not secondphase) then
                addmob(id .. "servant", x, y, #mobs < 12)
              end
              if t % 30 == 0 and id == "marco" and secondphase then
                addmob("marcolaser", x, y, true)
                sfx "3"
              end
              xv, yv = mid(-vmod, xv + (x < px and (xv < 0 and 0.1 or 0.05) or xv > 0 and -0.1 or -0.05) * vmod, vmod), mid(-vmod, yv + (y < py - 40 and (yv < 0 and 0.1 or 0.05) or yv > 0 and -0.1 or -0.05) * vmod, vmod)
            end
            if t % 360 == 1 and dashstate ~= 1 then
              dashstate = not dashstate
            end
          end
          if grav then
            yv = yv + (0.08)
          elseif id == "marcoservant" then
            ang, collide, friction = t / 60
          end
          pxw, pxh = w * 4 * scale * hbscale, h * 4 * scale * hbscale
          if collide then
            -- down
            d, air, left, right, down = 0, true
            repeat
              local v = (y + pxh + d) / 8
              local l, r = mget((x - pxw + 1) / 8, v), mget((x + pxw - 2) / 8, v)
              if yv > 0 and (fget(l, 0) or fget(r, 0) or (l == 14 or r == 14) and y >= py - 8) then
                y = y + (d)
                yv, down, air = bouncy and min(-yv, -.5) or 0, true
                break
              end
              d = d + (1)
            until d > yv
            -- up
            d = 0
            repeat
              local v = (y - pxh - 1 + d) / 8
              if yv < 0 and (fmget((x - pxw + 1) / 8, v, 0) or fmget((x + pxw - 2) / 8, v, 0)) then
                yv = bouncy and max(-yv, .5) or 0
                y = y + (d)
                break
              end
              d = d - (1)
            until d < yv
            -- right
            d = 0
            repeat
              local h = (x + pxw - 1 + d) / 8
              if xv > 0 and (fmget(h, (y - pxh) / 8, 0) or fmget(h, (y + pxh - 1) / 8, 0)) then
                xv, right = bouncy and min(-xv, -.5) or 0, true
                x = x + (d)
                break
              end
              d = d + (1)
            until d > xv
            -- left
            d = 0
            repeat
              local h = (x - pxw + d) / 8
              if xv < 0 and (fmget(h, (y - pxh) / 8, 0) or fmget(h, (y + pxh - 1) / 8, 0)) then
                xv, left = bouncy and max(-xv, .5) or 0, true
                x = x + (d)
                break
              end
              d = d - (1)
            until d < xv
          end
          if friction then
            xv = xv * (down and 0.8 or 0.99)
          end
          x = x + (xv)
          y = y + (yv)
          -- fighter jump
          if ai == "fighter" and down and (left or right or y > py + 2 and abs(px - x) < 16) then
            yv = -2.2
          -- slime over tiles
          elseif ai == "slime" and v and xv == 0 and not down then
            xv = v / 10
          end
        end
        if not pdead and piframes <= 0 and abs(px - i.x) < i.pxw and abs(py - i.y) < i.pxh then
          php = php - (max(i.damage - pdef, 1))
          piframes, pxv, pyv = 30, sgn(px - i.x) * 1.2, -1.2
          sfx(0, -1, phurt, 12)
        end
        i.iframes, hit = max(i.iframes - 1)
        if ai ~= "projectile" then
          -- p projectiles
          for a in all(projectiles) do
            if i.iframes == 0 and abs(a.x - i.x) < i.pxw and abs(a.y - i.y) < i.pxh then
              i.hp = i.hp - (max(a.damage - i.defence / 2, 1))
              kd, hit = sgn(a.xv), true
              a.pierce = a.pierce - (1)
            end
          end
          -- hit enemies
          local r = 4 * helditem.scale - 1
          if pswing > 0 and helditem.melee and i.iframes == 0 and abs(px + wxo - i.x) < i.pxw + r and abs(py + wyo - i.y) < i.pxh + r then
            i.hp = i.hp - (max(helditem.damage - i.defence / 2, 1))
            kd, hit = pflip and -helditem.knockback or helditem.knockback, true
          end
        end
        do
          local _ENV, g = i, _ENV
          if hit then
            iframes, angry = pswing, true
            if knockback > 0 then
              xv, yv = kd * knockback, -knockback
            end
            ssfx "6,0"
            splat(x, y, colour, 1)
          end
          local cansee, sight, d = true, 1, dist(px - x, py - y)
          if ai ~= "projectile" and (d < distance or boss) then
            local ba = 0.25 - atan2(py - y, px - x)
            repeat
              if fmget((x - cos(ba) * sight) / 8, (y - sin(ba) * sight) / 8, 0) then
                cansee = false
              end
              sight = sight + (2)
            until sight > d or not cansee
            if cansee then
              g.distance, g.pangle = boss and 0 or d, ba
            end
          end
          if cansee and t % 140 == 0 and count(cansting, id) > 0 then
            addmob("stinger", x, y, true)
            ssfx "8,0"
          end
          t = max(t + 1)
          if boss then
            g.bosshp, g.bossmax, g.bossmusic = hp, hpmax, bossmus
          end
          -- die
          if hp <= 0 then
            for k, itm in next, split(drop, "_") do
              if itm ~= "" then
                local it, am = unpack(split(itm, ":"))
                for a = 1, am < 0 and abs(am) or am - rnd(k + 1) // 1 do
                  additem(it, x, y)
                end
              end
            end
            splat(x, y, colour)
            ssfx "6,1"
            if rnd "12" < 1 then
              additem(0, x, y)
            end
            del(mobs, _ENV)
          -- despawn
          elseif d > 360 or pdead then
            del(mobs, _ENV)
          end
        end
      end
      piframes = max(piframes - 1)
      -- die
      if php <= 0 and not pdead then
        php, pdiet, pdead, pswing = 0, 60, true, 0
        sfx "27"
      end
      cam_x, cam_y = mid(0, px - 64, 1920), mid(0, py - 64, 896)
      if mouse then
        pangle = 0.25 - atan2(py - cam_y - msy, px - cam_x - msx)
      end
    end
    if helditem.id == 17 then
      add(lights, {px, py})
    end
    if invkey and not pinvkey and not pdead then
      poke(0x5f30, 1)
      invopen = not invopen
      ssfx(invopen and "7,0" or "7,1")
      updaterecipes()
    end
    timelight, php = split "5,5,4,3,2,1,1,1,1,1,1,1,1,1,2,3,4,5,5,5,5,5,5,5,5" [worldtime // 1000 + 1], min(php, php_max)
    local nextmusic = bossmusic or worldmusic
    if nextmusic ~= currentmusic or stat(24) == -1 then
      music(-1, 1000)
      currentmusic = nextmusic
    end
    if stat(24) == -1 then
      music(nextmusic, 1000, 3)
    end
  end
  t = max(t + 1)
  if mute then
    music "-1"
  end
end

function _draw()
  smolmap()
  respal()
  cls "14"
  if mode < 3 then
    pal(split "130,132,4,9,10,5,134,131,3,139,7,1,140,12,136,128", 1)
    bg(t / 10)
    rotspr(64, 20, sin(t / 700) / 40, 11, 26, 8)
    cprint("a terraria demake", 40)
    cprint(split "drop a player file here,drop a world file here" [mode], 76)
    cprint("(or press 4 to start over)", 84, 7, 1, 63)
    cprint("press 5 for the player editor", 120, 7, 1, 63)
  -- game
  else
    if py < 360 then
      for i = 0, 0.5, 0.5 do
        local s = worldtime / 24000 + 0.75 + i
        local y = 32 + sin(s) * 24
        if y < 32 then
          circfill(64 - cos(s) * 71, y, 7)
        end
      end
      bg(cam_x / 4, 28 - cam_y / 4)
    end
    local e, selectedcraft, d, hpy, l, r, u, f = cam_y // 1, 0, 120, 12 + (php_max - 20) // 200 * 8, cam_x // 8 - 1, cam_x // 8 + 17, cam_y // 8 - 1, cam_y // 8 + 18
    camera(cam_x * 0.75 % 128, e)
    for y = 0, 5 do
      local y28 = y * 128
      map(96, bgs[y], 0, 296 + y28, 32, 16)
    end
    camera(cam_x, e)
    bigmap()
    for iy = u, f do
      for ix = l, r do
        if fmget(ix, iy, 6) then
          for p = 1, #around, 2 do
            local wall = mget(ix + around[p], iy + around[p + 1])
            if fget(wall, 2) then
              spr(wall, ix * 8, iy * 8)
              break
            end
          end
        end
      end
    end
    map()
    for iy = u, f do
      for ix = l, r do
        -- treetops
        local tile = mget(ix, iy)
        if tile == 82 and mget(ix, iy - 1) ~= 82 then
          local y = iy
          repeat
            y = y + (1)
          until mget(ix, y) ~= 82
          local s, w, o, b = 142, 2, 4, mget(ix, y + 1)
          if b == 6 then
            s = 137
            w = 3
            o = 8
          end
          if b == 10 then
            s = 140
          end
          spr(s, ix * 8 - o, iy * 8 - 16, w, 2)
        -- lights
        elseif fget(tile, 7) then
          local px, py = ix * 8 + 4, iy * 8 + 4
          add(lights, {px, py})
          if rnd "400" < 1 and not invopen then
            splat(px, py, 7, 0)
          end
        end
      end
    end
    smolmap()
    if digging then
      spr(192 + pdigt / hiuse, actx // 1 * 8, acty // 1 * 8)
    end
    for _ENV in all(items) do
      sspr(id % 16 * 8, id // 16 * 8, 8, 8, x - 2, y - 2, 4, 4)
    end
    -- draw mobs
    for _ENV in all(mobs) do
      if palette then
        pal(split(palette, ":"))
      end
      if host then
        line(x, y, host.x, host.y, 1)
      end
      if rspr then
        rotspr(x, y, ang, sprx, spry, w, false, scale)
      else
        local sc = scale * 4
        sspr(ispr // 1 % 16 * 8, ispr // 16 * 8, w * 8, h * 8, x - w * sc, y - h * sc, w * 2 * sc, h * 2 * sc, iflip)
        if id == "kingslime" then
          spr(206, x - 8, y - h * sc - 5.5 + (ispr == 233 and sc / 2 or 0), 2, 1)
        end
      end
      if palette then
        respal()
      end
    end
    for _ENV in all(projectiles) do
      mset(1, 1, bulletsprite)
      rotspr(x, y, atan2(yv, xv) + 0.5, 1.5, 1.5, 1)
    end
    -- player
    if not pdead and (piframes == 0 or t % 4 < 2) then
      local pf = flr(pswing ~= 0 and 5 + (lastitem.usetime - pswing) / lastitem.usetime * 3 % 3 or pair and 3 or pxv == 0 and 1 or 1 + px / 8 % 2)
      spr(127 + pf, px - 4, py - 4, 1, 1, pflip)
      if saturn then
        sspr(96, 92, 8, 4, px - 4, py - split "7,6,7,7,7,6,5" [pf], 8, 4, pflip)
      end
    end
    if pswing > 0 then
      mset(1, 1, swingitem.id)
      local sc = swingitem.scale
      if swingitem.type == "ranged" then
        pangle = pangle % (1)
        local vf = pangle <= 0.75 and pangle > 0.25
        rotspr(px + cos(pangle) * 8 * sc, py + sin(pangle) * 8 * sc, (vf and 0.5 or 0) - pangle, 1.5, 1.5, 1, vf, sc)
      else
        rotspr(px + wxo, py + wyo, atan2(wyo, wxo) - (pflip and 0.375 or 0.625), 1.5, 1.5, 1, pflip, sc)
      end
    end
    for _ENV in all(parts) do
      if li < 30 then
        pset(x, y, c)
      else
        circfill(x, y, 1, c)
      end
    end
    camera()
    -- inventory
    for id, i in next, inventory do
      draw_item(i.id, (invopen or id == invsel) and 116 or (116 + (id - invsel) ^ 2 / 2), (id - invsel) * 13 + 64, invside == 1 and id == invsel and not hoveritem, i.amount)
    end
    if hoveritem then
      draw_item(hoveritem.id, 102, 64, true, hoveritem.amount)
    end
    -- craft
    if invopen then
      bprint(pdef .. " defence", 40, hpy)
      pal(split "1,2,3,4,5,6,7,8,9,10,11,1,15")
      local trash = trashslot or {}
      draw_item(trash.id, 116, 129, false, trash.amount)
      -- recipe
      selectedcraft = craftable[craftsel]
      if selectedcraft then
        for id, i in next, selectedcraft[2] do
          draw_item(i[1], 4 + 12 * id, 64, false, i[2])
        end
        selectedcraft = selectedcraft[1][1]
      end
      -- item
      for id, i in next, craftable do
        local out = craftable[id][1]
        draw_item(out[1], 2, (id - craftsel) * 13 + 64, invside == 0 and id == craftsel and avail, out[2])
      end
    end
    for i = 20, php_max + 19, 20 do
      pal(split(i <= php + 19 and "15,2,4" or "2,2,2"))
      sspr(98, 80, 9, 9, i * 0.4 % 80 - 6, i // 220 * 8 + 1)
    end
    bprint(flr(php) .. "/" .. php_max, 2, hpy)
    if bosshp > 0 then
      rectfill(14, 120, 14 + bosshp / bossmax * 100, 126, 15)
      rect(14, 120, 114, 126, 5)
      cprint(ceil(bosshp) .. "/" .. bossmax, 121, 11)
    end
    if invopen and #inventory > 0 then
      cprint(invside < 1 and "crafting" or "inventory", 121)
      if invside == 0 or invside == 1 then
        cprint(avail and tilenames[(hoveritem and hoveritem.id) or (invside > 0 and inventory[invsel] and inventory[invsel].id) or selectedcraft] or "need more materials", 44, 11, 6, 67)
      end
    end
    if pdead then
      cprint("you were slain", 60, 11, 15)
      if pdiet <= 0 then
        cprint("jump to respawn", 68, 11, 15)
      end
    end
    for i in all(lights) do
      d = min(dist(i[1] - px, i[2] - py), d)
    end
    pal(split(palettes[min(mid(1, d / 8 - 6, 5) // 1, max(mid(1, py / 24 - 12, 5) // 1, timelight))]), 1)
    pal(14, split "12,140,1,129,0" [timelight], 1)
  end
  if mouse then
    sspr(88, 90, 5, 6, msx, msy)
  end
end

-->8
function genprint(t, t2)
  pal(split "130,132,4,9,10,5,134,131,3,139,7,1,140,12,136,0", 1)
  cls()
  cprint(t, 62)
  cprint(t2 or "", 110)
  flip()
end

function generate()
  bigmap()
  local walls, worlddir, ry, ra, tunnel, dirttile, surfacecaves, crystals, ores = split ",66,67,,,,71,,,,66,76", rnd() < .5, 30, 0, 0, 2, 0, 0, 0

  function maketunnel(s)
    for ix = -s, s do
      for iy = -s, s do
        local r = mget(cx + ix, cy + iy)
        if not fget(r, 2) then
          mset(cx + ix, cy + iy, cy < 60 and walls[r] or 0)
        end
      end
    end
  end

  genprint "sculpting the land..."
  for ix = 0, 255 do
    ra = mid(-0.22, ra + rnd "0.2" - 0.1, 0.22)
    ry = ry + (sin(ra) * (ix - 128) / 64)
    if ry < 20 or ry > 37 then
      ra, ry = 0, mid(20, ry, 37)
    end
    if rnd "50" < 1 and tunnel <= 0 then
      tunnel = 6 + rnd "8" // 1
    end
    for iy = 0, 127 do
      js, cs = ix < 78 + rnd "7", ix > 178 - rnd "7"
      if worlddir then
        js, cs = cs, js
      end
      if iy > ry + 10 then
        mset(ix, iy, js and 7 or 3)
      elseif iy >= flr(ry) then
        dirttile = cs and 11 or js and 7 or 2
        mset(ix, iy, dirttile)
      end
    end
    if tunnel > 0 then
      for i = 1, 5 do
        mset(ix, ry - i, i > 3 and dirttile or walls[dirttile])
      end
      tunnel = tunnel - (1)
    end
  end
  for i = 0, 30 do
    a, cx, cy, s = rnd(), rnd "256", 50 + i / 2 + rnd(78 - i / 2), 1 + rnd "2"
    for l = 0, 10 + rnd "80" do
      av = -0.0833 + rnd "0.1667"
      a = a + (av)
      cx, cy = cx + cos(a), cy + sin(a)
      maketunnel(s - rnd "2")
    end
  end
  repeat
    ix, iy = 20 + rnd "216", 0
    repeat
      iy = iy + (1)
      dirttile = mget(ix, iy)
      valid = dirtitle == 2 or dirttile == 7 or dirttile == 11
    until valid or iy > 32
    if valid then
      r = 7 + rnd "4"
      for y2 = -r, r do
        x2 = flr(sqrt(abs(y2 * y2 - r * r)))
        for ox = -x2, x2 do
          mset(ix + ox, iy + y2 + 3, dirttile)
        end
      end
      xo = sgn(rnd "-1")
      ca, cx, cy = 0.5 - 0.25 * xo, ix + xo * r, iy
      for l = 0, 80 + rnd "40" do
        ca = mid(0.25, ca - 0.125 + rnd "0.25", 0.75)
        cx = cx + (cos(ca + 0.25))
        cy = cy + (sin(ca + 0.25))
        maketunnel "1"
      end
      surfacecaves = surfacecaves + (1)
    end
  until surfacecaves >= 4
  genprint "digging corrupt chasms..."
  repeat
    x, y = rnd "256", 0
    repeat
      y = y + (1)
    until mget(x, y) == 11 or y > 40
    if y <= 37 then
      for l = 2, 30 + rnd "20" do
        x = x + (-1 + rnd)"2"
        for ix = -3, 3 do
          for iy = -3, 3 do
            mset(x + ix, y + iy + l, ((abs(ix) >= 2 or iy >= 2) and mget(x + ix, y + iy + l) ~= 76) and 12 or 76)
            mset(x, y + l, 77)
          end
        end
      end
    end
    chasms = 0
    for i = 0, 32767 do
      if mget(i % 256, i // 256) == 77 then
        chasms = chasms + (1)
      end
    end
  until chasms >= 3
  genprint "hiding treasure..."
  for ix = 0, 255 do
    for iy = 0, 127 do
      if (mget(ix, iy) == 2 or mget(ix, iy) == 7 or mget(ix, iy) == 11) and not fmget(ix, iy - 1, 0) then
        mset(ix, iy, mget(ix, iy) - 1)
        if rnd "2" < 1 then
          tree(ix, iy)
        end
      end
    end
  end
  repeat
    ix, iy = rnd "256", 60 + rnd "58"
    if mget(ix, iy) == 0 and fmget(ix, iy + 1, 0) then
      mset(ix, iy, 9)
      crystals = crystals + (1)
    end
  until crystals >= 20
  repeat
    ix, iy, set = rnd "256", ores * 0.6 + rnd "38"
    for i = -3, iy / 20 + rnd "3" do
      ix = ix + (-1 + rnd)"2"
      iy = iy + (-1 + rnd)"2"
      if fmget(ix, iy, 0) and mget(ix, iy - 1) < 82 then
        mset(ix, iy, 19 + ores / 46)
        set = true
      end
    end
    if set then
      ores = ores + (1)
    end
  until ores >= 180
end

-->8
function addmob(id, sx, sy, override, host)
  for k, i in next, stats do
    s = split(i, "|")
    if s[1] == id then
      break
    end
  end
  if s and (#mobs < 8 or override) then
    local mob = setmetatable({id = id, x = sx, y = sy, host = host, irnd = rnd()}, env)
    do
      local _ENV, s, unpack = mob, s, unpack
      t, xv, yv, ang, iframes, v, va, dashstate, scale = 0, 0, 0, 0, 0, 0, 0, true, 1
      _, colour, hp, damage, defence, drop, ai, knockback, vmod, angry, rspr, sprx, spry, w, h, palette, phaseswitch, scale = unpack(s)
      hpmax, ispr, angry, rspr, scale = hp, sprx, s[10] == 1, s[11] == 1, scale or 1
    end
    add(mobs, mob)
  end
end

function additem(id, x, y, amount)
  add(items, setmetatable({id = id, amount = amount or 1, x = x, y = y, xv = -0.3333 + rnd "0.6667", yv = -1, timer = 60}, env))
end

function add_inventory(item, pos)
  add(inventory, setmetatable(item, env), pos or #inventory + 1)
end

function bprint(t, x, y, c1, c2)
  for ix = -1, 1 do
    for iy = -1, 1 do
      print(t, x + ix, y + iy, c2 or 6)
    end
  end
  print(t, x, y, c1 or 11)
end

function cprint(t, y, c1, c2, x)
  bprint(t, (x or 65) - #tostr(t) * 2, y, c1, c2)
end

function updaterecipes()
  avail, craftable = true, {}
  for i in all(recipes) do
    s, cancraft = i[1][3]
    for ix = -3, 3 do
      for iy = -2, 1 do
        if not s or mget(px / 8 + ix, py / 8 + iy) == s then
          cancraft = true
        end
      end
    end
    for r in all(i[2]) do
      local a = r[2] or 1
      for slot in all(inventory) do
        if slot.id == r[1] then
          a = a - (slot.amount)
        end
      end
      if a > 0 then
        cancraft = false
      end
    end
    if cancraft then
      add(craftable, i)
    end
  end
end

function spawnplayer(hp)
  bigmap()
  php, px, py, pxv, pyv, piframes, pdead = hp or php_max, 1024, 0, 0, 0, 60
  repeat
    py = py + (8)
  until fmget(px / 8, py / 8, 0)
  py = py - (4)
end

function bigmap()
  poke(0x5f56, 0x80, 0)
end

function smolmap()
  poke(0x5f56, 0x20, 128)
end

function tospr(str, w, x, y)
  for i = 0, #(str or "") - 2 do
    sset(x + i % w, y + i // w, tonum("0x" .. str[i + 1]))
  end
end

function loadplayer(pstr)
  local plr = split(pstr, "|", false)
  local hp = split(plr[1])
  pgfx, inventory, php, php_max, phurt, orbsmash, worldtime = plr[3] or "", {}, unpack(hp)
  if type(php) == "string" then
    run()
  end
  phurt, orbsmash, worldtime = phurt or 0, orbsmash or 0, worldtime or 6000
  for i in all(split(plr[2])) do
    if #i < 10 then
      local it, am = unpack(split(i, ":"))
      add_inventory {id = it, amount = am}
    end
  end
end

function _reload()
  reload()
  tospr(pgfx, 56, 0, 64)
  tospr("66666666666666666666666666666666666666666666666666666666666666666", 8, 24, 64)
end

function setspawns(tiles, mobs)
  for i in all(split(tiles)) do
    spawns[tonum(i)] = mobs
  end
end

function splat(xp, yp, cp, am)
  for i = 0, am or 3 do
    local _ENV = setmetatable({}, env)
    x, y, xv, yv, li, c = xp, yp, -1 + rnd "2", -rnd "1.5", 60 - rnd "20", cp
    add(parts, _ENV)
  end
end

function tree(ix, iy)
  local th = 4 + rnd "5"
  for y = 2, th + 2 do
    if mget(ix, iy - y) ~= 0 then
      return
    end
  end
  for y = 2, th do
    mset(ix, iy - y, 82)
  end
  mset(ix, iy - 1, 83)
end

function door(bx, by, b, fl)
  if pxv * fl > 0 and fget(b, 0) then
    sfx "4"
    mset(bx, by, b + 1)
  elseif pxv * fl < 0 and not fget(b, 0) then
    sfx "4"
    mset(bx, by, b - 1)
  end
end

function loop(a, l)
  return a < 1 and #l or a > #l and 1 or a
end

function break_tile(actx, acty, tile)
  sfx "4"
  local ty, c = -1, tonum(split "3,3,7,6,3,2,2,,15,3,3,1,6,3,5,1,5,6,3,7,7,5,6,,,,9,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,2,,0,12,15,0,11,8,,,,2,12,7,3,2,,,3,3" [tile]) or 5
  if fget(tile, 4) then
    ty = 0
  else
    mset(actx, acty, 0)
    local dropitem = drops[tile] or tile
    if tile == 77 then
      dropitem = 48 + orbsmash % 3
      orbsmash = orbsmash + (1)
      mset(actx, acty, 76)
    end
    if dropitem == 50 then
      additem(51, a8x, a8y, 100)
    end
    additem(dropitem, a8x, a8y)
    splat(a8x, a8y, c)
  end
  -- break supported tiles
  while fmget(actx, acty + ty, 4) do
    local b = mget(actx, acty + ty)
    additem(drops[b] or b, a8x, a8y + ty * 8)
    splat(a8x, a8y + ty * 8, c, 1)
    mset(actx, acty + ty, 0)
    ty = ty - (1)
  end
  -- trees drop saplings
  if tile == 83 then
    for i = 0, rnd "2" do
      additem(27, a8x, a8y)
    end
  end
end

function respal()
  pal()
  palt "0b0000000000000010"
end

function draw_item(id, x, y, sel, am)
  if y <= 0 or y > 141 then
    return
  end
  if sel then
    pal(split "1,2,3,4,5,6,7,8,9,10,11,4,5,14,15,0")
    sspr(88, 80, 10, 10, x - 1, y - 14, 12, 12)
  else
    sspr(88, 80, 10, 10, x, y - 13)
  end
  respal()
  spr(id or -1, x + 1, y - 12)
  if am and am > 1 then
    print(am >= 1000 and (am // 1000) .. "K" or am, x, y - 8, 11)
  end
end

function ssfx(i)
  sfx(split(i)[1], -1, split(i)[2] * 8, 8)
end

function add_projectile(xp, yp, a, v, d, s, p)
  local _ENV = setmetatable({}, env)
  x, y, xv, yv, damage, bulletsprite, pierce = xp, yp, cos(a) * v, sin(a) * v, d, s, p or 1
  add(projectiles, _ENV)
end

function fmget(x, y, f)
  return fget(mget(x, y), f)
end

function bg(x, y)
  map(5, 0, -(x % 512), y, 80, 18)
end

-->8
function rotspr(x, y, rot, mx, my, w, flip, scale)
  scale = scale or 1
  w = w * (scale * 4)
  if flip then
    rot = -rot
  end
  local cs, ss = cos(rot) * .125 / scale, sin(rot) * .125 / scale
  local sx, sy, hx, halfw = mx + cs * -w, my + ss * -w, flip and -w or w, -w
  for py = y - w, y + w do
    tline(x - hx, py, x + hx, py, sx - ss * halfw, sy + cs * halfw, cs, ss)
    halfw = halfw + (1)
  end
end

function dist(dx, dy)
  local maskx, masky = dx >> 31, dy >> 31
  local a0, b0 = (dx + maskx) ~ maskx, (dy + masky) ~ masky
  return a0 > b0 and a0 * 0.9609 + b0 * 0.3984 or b0 * 0.9609 + a0 * 0.3984
end


__gfx__
eeeeeeeeaa9aa99a1233232266677761eeeeeeee34444442aa9aa99a12221112eeeeeeeeeeeeeeee6616611612332322016611016177617734444442eeeeeeee
effeeffe99a818992332333267767676ee7777ee4344434399a8089923333221eeeeeeeeeffeef2e1161106123323332666110006176617643444343eeeeeeee
f44ff4ff189121982233332216777661e7b66b7e444334330890109812322222eee7eeeef44ff4f21010221022333322111116106166616644433433eeeeeeee
f4ffffff212232212323322167776766e550855e322223321121111112211111e47437eff4fffff22222322123233221011006611011101132222332eeeeeeee
fffffff222332212223322127676776674088047444423441211332112113321433376e42fffff2222332212223322120166161177617761eeeeeeee32333322
efffff2e223333232233332377677676608998064434343432222223322222233eee6ee6e2fff22e22333323223333236661111076617661eeeeeeee22222222
ee2ff2ee2222323222223232666667615b9aa9b5344324432221123222211232eeeee66eee2f22ee22223232222232321611011066616661eeeeeeeee111111e
eee22eee23322221233222216111661145577554332223221112112111121122eeeeeeeeeee22eee23322221233222211111000011101110eeeeeeeee2eeee2e
eeeeeeeeeeeeeeeeeeeeeeee2334443276667667677bbb774455554411666611eeeeee61eee77eeeeeee6eeeee9a9eeeee5b5eeeeebbbeeeee777eeeee333eee
eeeeeeeeeeefeeeeeeeeeeee34444443677bb7766bb7b7b745bb5b5416776761eeeee610ee6996eeeee6160eeeaaa9eeee6e45eeee6e7beeee6e67eeee6e23ee
6666661eeeeffeeeeeeeeeee444334447bb7bb667b77bb7655b5555566766666eeee610ee690096eeeee116ee899989eee7ee54eee7eeb7eee7ee76eee7ee32e
612f211eeef44feeeeeeeeee44344433bb7bb7767bbbbb774555545516666166e6e610ee67a00a76eee61016ee8988eeee7eef2eee7ee21eee7ee32eee7ee76e
1f454f77ee4454ee67b77611444444437bbb7b77b7bbb7b75455445461661161e6610eee167aa761ee610e06eee11eeeee7eef2eee7ee21eee7ee32eee7ee76e
77777776eee34eee1666661e3444443277b7b7767bbb77b74554455416611661e016eeeee167761ee610eee1ea9219aeee7ee43eee7ee76eee7ee61eee7ee21e
1111111eeee33eeee11111ee3334333267677767677bbb77345555440166661161001eeeee1661ee610eeee0e983188eee6e54eeee6eb7eeee6e76eeee6e32ee
6161611eeee32eeeee7661ee343332216776667676777776434444431011111010eeeeeeeee11eee10eeeeeeeee21eeeee544eeeeeb77eeeee766eeeee322eee
eeeb5eeeeeb55eeeeeeeeeb5eeeeeeeeeeebbeeeeebbbeeeeeeeeebbeeeeeeeeeee77eeeee777eeeeeeeee77eeeeeeeeeee33eeeee333eeeeeeeee33eeeeeeee
eeb5451eeee442feeeeeeb54eeeee32eeebb7b7eeee772feeeeeebb7eeeee32eee77676eeee6676eeeeee776eeeee32eee33232eeee2232eeeeee332eeeee32e
ee542f5eeeee342eeeeeb54eeeee324eeeb72fbeeeee672eeeeebb7eeeee326eee76767eeeeec67eeeee776eeeee32ceee32323eeeee123eeeee332eeeee321e
eee34243eee32345eeeb54eeeee32f5beee67276eee3267beeebb7eeeee32f7beeec6c6ceee32c67eee776eeeee32c67eee12121eee32123eee332eeeee32123
ee323434ee321e45e5254eeeee324545ee326767ee321e7bebfb7eeeee32676bee32c6c6ee321e67e7676eeeee32c6c7ee321211ee321e23e3232eeeee321212
e321e34ee321eee4e1f2eeeee321e45ee321e67ee321eee7e12feeeee321e7bee321ec6ee321eee6e166eeeee321e67ee321e11ee321eee2e122eeeee321e22e
321eeeee321eeeee3214eeee321eeeee321eeeee321eeeee3217eeee321eeeee321eeeee321eeeee3216eeee321eeeee321eeeee321eeeee3212eeee321eeeee
21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee21eeeeee
ee606eeeeeeeeeeeeeeeeeeeeeeeeeeeeee7eeeeeeeeee61eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee6e16eeee77776eeeeeeeeeeeeeeeeeee766eeeeeeee610eeeebeeeeeee766eeeeeb77eeeeebbbeeeeebb5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5e54e5e
ee7ee61ee76dbd7eee77ee7eeee7eeeeee626eeeeeee610eeeebe7eeee766610eeb77761eebbbb76eebb5543eeedceeeeeee3eeeee671eeeeeff7deee54f244e
ee7ee98ee7dbdd7ee7766666ee776eeeeee3eeeeee6610eeee7eebeee6666100e7777611ebbbb766eb555433eedddceeeee2322eeee6707eef267d0eed77ddce
ee7ee98ee7bddc7e3361e21eeee6eeeeeee2eeee116e0eeeeebeebee6661100077766111bbb7766155544332eecdcceeeee321eeeee0876ef2f67c0edddddddc
ee7ee10ee7ddc76e22eeeeeeeeeeeeeeeee7eeeee0160eeeeee7b7ee1611000e6766111e7b77666e4544333eeeecceeeee32eeeeee76761eee226ceecddddccc
ee6e61eee67776eeeeeeeeeeeeeeeeeeee766eee6101eeeeeeee7eee111000ee666111ee777661ee444332eeeeeeeeeeeeeeeeeeeee161eeeeeeeeeeecccccde
ee610eeeeeeeeeeeeeeeeeeeeeeeeeeeee6e6eee10e0eeeeeeeeeeeee100eeeee611eeeee766eeeee433eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
21ff21ffee32330000000110000ccc00eeeeeeee01111110bbbbbbb7008c0001eeeeee3ee320032eeeeee5eeeeeeeeee000000000000000ceee22eeee211111e
21f221f2eee3022e000001100cc0c0c0eefeeeee10111010bbbbbbb700801000eeeee32ee300321eeeee554e32333322000000cc00666100eee32eeee222111e
21222122eee32eee0100000000ccc000eeffefee11100100bbbbbbb70118118ceeee32eeee32216eeee724542222222200cc0cc006776610eee32eeee222111e
101110113e33322e000000000ccc0c00eef4fffe00000000b7777b76881c18c0eee321eee766621eee77d24ee11ee11e0cc0000006776610eee32eeee222111e
ff21ff21233333ee00110000c0c0cc00ef4544fe11110011bbb7bbbb0cc1c000ee3212aee6322221edddcc3ee2eeee2e0000000006666610ee6326eee222166e
f221f2213322323e00110000cc0cc0c0e455554e11010101bbb7bbbb00001800ee21ee9823333221d7dcce23e1eeee2e0000c00001666110eee32eeee222111e
22212221321e33230000001000000c00e32bb32e01100110bbb7bbbb10008c01e32eeeee22332210cdcc1ee2e2eeee1e00cc000000111100eee32eeee222111e
111011103e1e23e200000000000000002123321100000000b776777b1100c011e2eeeeeee122210eeccee23ee2eeee1e00000000c0000000eee22eeee211111e
eee4eeeeeeeeeeeeee3331eeee3322eeeeeeeeaaeeeeeeeeeeeeeeeeeee32eeeeeffffeeeeeeeeeeee45b3e4eeeeeea9ee766eeeeeeeeeeeeeeeeeeeeeeeeeee
eefbfeeeeeeeeeeeee2332eeee2321eeeeee9aa9ee33eeeeeee4feeeeebbb7eeee1221eeeeeaeeee5eb454eeeeeeea9de7b762eeee1c1eeeeeeeefeeeeeee6ee
ee454eeeeeebeeeeee2322eeee2321eeeee9aa9eeee23eeeee4443eeeeeb7eeeeffffffeeea5aeeee455b47eeeeea9dee7b7612eeef1feeeeeecce2eeee77e1e
eef4feeeeebb7eeeee2321eeee2332eeeeeaa98e33267677eeff3feeeeb667ee2f2ff2f2ee555eeee5b4433eee9aedeeeddcce2eef424feee2fffff2e1666661
eeefeeeeee776eeeee3321eeee3331eea9a998eee2226666ee2f32eeee1f21ee122ff221ea555aee5a43379a5bdedeeee7b7621eeff2ffeeddc1221133201100
eee7eeeeeeeeeeeeee2332eeee3321eee19aeeee21e128eeeee22eeee1fff21e5a12215ae9aaa9eea99a9889e45d8eeee67762eee1f2f1eecceeee2e22eeee1e
ee766eeeeeeeeeeeee2322eee332321e3219eeeeeeeeeeeeeee32eeee1f2221e98911989ee9a9eee9eecce584345eeeee16611eeee121eeeeeeee1eeeeeee0ee
ee6e6eeeeeeeeeeeee3331ee3212332121e8eeeeeeeeeeeeeeeeeeeeee1111eeec8a98ceeeeeeeeeee48ceee54e4eeeeee111eeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeea9eeeeeeeeeeeeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeee6661eeeeee5b5eeeebe4eeeeeeeeeeeee5eeeeeeeeeeee99898888998899898c8c8c8c
ee9aa99eeee9aeeeee5b5eeeeeee017ee54ee45ee61ee16eea9ee9aee1000ceeeeeeb553eeb55eeeeee6eeeeee5b5eee761661ee98988888888989899cc88c8c
eee554eeeeea9eeee54eeeeeeee1106755555555f6666662aa4554aaee11c176eeee55445e534eeeeee7eeeee44544ee0101661e899898888889889898c8c88c
eee9a9bbeee9aeeeebeb545eee1007eee45f254ee26f262ee2a44a2eee32276eeee45543eee4eeeeee661eeeeee7eeee16c0110e888888888989989989c8c8cc
eaaaa7b7eeea9eeee545bebee107e67ee345543eec1661cee39aa93ee661166eee45543eeee3ee5eeec1ceeeee373eeee16cc5468989888888888898988c8ccc
9aa9977eeea9a9eeeeeee45ee1e67eeeee5445eeee6116eeee3223ee67661ceeea9443eee4e5eeeeee1e1eeee4e6e4eeee1166618988888888899888998c88cc
899988eeeeea9eeeeee5b5ee10eeeeeeee4334eeeec00ceeee2112ee16611eee29a9deeeee544eeeeeeeeeeeee5b5eeeeeee11119988888889989989898c88cc
eeeeeeeeeee9aeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeec11ceeee119deeeeee4e4eeeeeeeeeeeee6e6eeeeeeeeeee988988888888999898988ccc
66c8c8c8c88c86c6899896866689898977777777777777777777777776666666666666776666666c86666666eeebeeeeeeeeeeeeeeeeeeee11116666eeeeeeee
6c88c8c8c8cc8866898899666899898977777777777777766777777777666666666667776666666888666666ee454eeeeeeeeeeeeeeeeeee16606760eeeeeeee
c68cc8cccc88c8c6889989868698898877777777777777666667777777666666666677776666668c8c666666e5ebe5eeeeeeeeeeeeeeeeee60007760eeeeeeee
6ccc8cccc8c88c6c898998686888988877777777777777666667777777777666666777776666668cc8666666ee5e5eeeeeeeeeeeeeeeeeee00667770eeeeeeee
c8c88c8cc88c8c8689989896898998987777777777776666666677777777776666677777666666cc88c66666efe4efeeeeeeee23eeeeeeee61111771e2ee2eee
68c88ccccc8ccc8c889888986989988877777777777666666666777777777776667777776666688c8c866666eeeeeeee11111ee311111eee6666071ae32e22ee
8c88c8cc8ccc8c8898889899989989887777777776666666666666777777777666777777666668cccc886666eeefeeee111111ee111111ee16660199333e32ee
c88c8ccccc8c88c888989989899898887777777766666666666666677777777767777777666688ccc8c86666eeeeeeee6611eee16611eee170076a9912e232ee
ee22222eeeeeeeeeee22222e66666666772222eeeeeeeeeeeeeeeeee22eeeeeee3332112eeeee89a8ca989989a8eceeeeeeeee1e16eeeeeeeeeeee8e89eeeeee
e226c6eeee22222e7726c66666666666776c6eeeeee22772eeeeeeeeffeeeeeeee321161eec9caaa9aaaa99aaa9a8cceee16116166161eeeee89889899898eee
ee6777eee226c6ee7767776666666666ff677eeeee22f77eeee22222122eeeee2ee21661ee999aa9aaaaaaaaaa99898ce1766677677671eee8a999aa9aa9a8ee
eeffffeeee6777eeefffff1e66666666effff6eeeefff66eee2266ce2eeeeeee2eee1666c8999aaaaa9aaaa9aa999988e1667677767716eee899a9aaa9aa89ee
e77fff6e77ffff66eeffffee66666666effff6eeeefff6eeeefff76efeeeeeee3221661088a9a9aa9a9aaaaa9aa99989ee6677767766771eee99aa9a9a99aa8e
e771116e77ffff66ee1111ee66666666e1111eeee11ff1eeee1fff77ffeeeeee32216111c9989aa9aa9aa9a9a98a999ce166666767776670e89999a9aaaa99ac
ee1111ee331111223311112266666666111111ee1111111ee1111177ffe45eee332161118899a89aa9a9aaa98899988e1617767676677716898aa99aa99aaa89
e333222ee331122ee33ee22e66666666333e222e333e222e333e222eff1aeeeee3316111c8898999999aa999989988cc0676776776766161c9a9aaa9a9aa989c
eeeeeeeeeeeeeeeeee66611eeeeeeeeeee4ee4eee4eeee4e06771112a1666777112333eecc8898a999a99a98999898890166777777766110c899aaaaaaa99888
eeeeeeeeee2222eee61c7ceeee66611eec3ee3cee23ee32e077700711616116161123eeeeec8c98989898889a88989cc1161767677666661889899a99a999998
ee2222eee233221eeec888eee61c7ceee1c11c1ee1c11c1e07707000661616616612ee2eeccc8888889888998c9c9cee117671667661161188a9989999988988
e232221ee232221eee5998c8eec888eee670076ee670076e607661701161aa66661eee2eeeec8c8c9888c888c9c8c8ce0116661776661101c889899a989988cc
23332221e222221eee5585ceee5998c8a167761ae167761e6601116666689aa61661223eeeeccecc8cccec8c8ccceeeee111161661616110ec889898889898ce
22222221e222221eee2224eeee5585ceeec66ceeaec66cea16066661118aa9a61161223eeeeeceeecc1eeec1ce1eeeeee10111101110101eeee8898c918c8cee
12222111e122111eee2244eeee22244ee916619eee1661ee910000011689a9911161233eeeeeeeeee321e111ee28eeeee0e1011210e01e0eeeece882c1eeceee
e111112ee111112eee33222ee3334222eeecceeeee9cc9ee9a60000069a9aa88116133eeeeeeeeeeee32121ee93eeeeeeee0ee2311ee0eeeeeeeee2321eeeeee
8889898996666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777eeeffeeeeeeffeeecceeee32e23ee66611112edddddddcee4554554e88888eeeeeeee9aaeee8e
8988898999666666eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6677206eee77206eeeeddeeeee1771e367606611dcccccccdc451151254888887eeeeeeeeeeeee8e
8888989898666666122ee111eee122eeeeeeeeeeeeeeeeeeee54200177642001eeeddeee317f271267700061dc000000dc51311312588888777eeeeeeeeee88e
8898989989666666e111221eee2232eeeeeee0e0eeeee0e0e455411166554111eeeddeee27200f7e77766006dc000000dc511111125888887777eeeeeeee88ee
8888888899866666ee1232eee221111ee332160ee332160e55421eee55421eeeeeeddeeee7f0027277111160dc000000dc52111122588888777777eeeeeeeeee
8888988998966666eee111ee211ee111e211100ee211100e4554eeee4554eeeeeeeddeee2172f71317066661dc000000dc45211225488888777777eeeeeeeeee
8888889988996666eeeeeeeeeeeeeeeee45454eee54545eee3454eeee3454eeeeeeddeee3e1771eea1066611dc000000dce4522254e888887777777eeeeeeeee
8888899889896666eeeeeeeeeeeeeeee45e4e54e54e5e45eeee433eeeee433eeeeecceeeee32e23ea9670071dc000000dcee45254ee8888877777777eeeeeeee
eeeeeeeeeeeeeeeeee333eeeee333eee11116660a9aee88eeee77eeeeeeeeeeeeeeeeeeeeeeeee22e3332112cdddddddcceee454eeeeeee6c8cc88c9eeeeeeee
eeeeeeeeeeeeeeeee71116eee71116ee16606760eeeee8eeee7707eeeee77eeeeee00eeeeeeeeeff2e321161ecccccccce888888eeeeee66cc8ccc88eeeeeeee
eeeeeeeeeeeeeeeee67776eee67776ee00707760eeeee88eee6776eeee7707eeeeddddeeeeeee2213ee21661cceee88888888888eeee6666cc88c889eeeeeeee
eeeeeeeeeeeaaeeee42662eee26624ee71667770eeeeee88ee4466eeee6776eeee6776eeeeeeeee232ee1666cbcee88888888888eeee6666ccc8c899eeeeeeee
eeeaaeeeeea5a9eee44442eee44442ee61111771eeeeeeeeee7641eeee4466eeeef662eeeeeeeeef32216610cbbce888ee7eeeeeeee66666cccc8c89ee2ee2ee
ea55aa9eeeaaa9eee2424eeeee4242ee66660719eeeeeeeeee6641eee764416eee2f2feeeeeeeeff33216111cbbbc8886e6160eeee666666cc8c8898e22e23ee
e9aaa99eee9a99eeee4e2eeeee2e4eee000001aaeeeeeeeeee555eeee664411eeee2feeeeee54effe3216111cbcce88806cc54eeee666666cccc8898e23e333e
ee999aeeee999aeeee2eeeeeeeee2eee000069aaeeeeeeeeee3322eee335522eeeee2eeeeeeea1ffee316111eceee8881166610ee6666666ccc8c998e232e211
eeeeeeeeeeeeeeeee0ee00eeeeeeeeeeeeeeeeee66666668ee8eeeee8eeeaa96ef2eff2f2222222f22fe22feeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee0eeeeee00eeeeeeeeeeeeee5455ee66666669ee88eeee8eeeeeeee2eef22ff22ff2fffffeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee54eeeeeee
eeeeeeeeeeee0eee0eee0ee0e55ee55eee4224ee66666698eee8eeee88eeeeeeeeeeef22ff22f2f2ffeeeeeeeeeee62344eeee44326eeeeeeee5e3e55e3e5eee
eeee0eeeeeee0eeee0ee0e0e5e4224e55433225566666698eeeeeeeee88eeeeeeeeee22ef2ff2f2ef2eeeeeeeeee66344eeeeee44366eeeeeee5435554355eee
eee0eeeeee00e0eeee00e0ee443322544225421466666688eeeeeeeeeeeeeeeeeeeee2e2f22f2f2ef2eeeeeeeeeef62eeeeeeeeee262eeeeee554355443554ee
eeeeeeeee0e0eeeee0e0ee0022254221e224421e66666998eeeeeeeeeeeeeeeeeeeeeeef2eeeeffef2eeeeeeeee6f7eeeeeeeeeeee622eeeee5a555f2555a4ee
eeeeeeeeeee0eeee00e0eeee12244111e122111e66666988eeeeeeeeeeeeeeeeeeeeeeef2eeeeefee2eeeeeeeee6672e344ee443ef766eeeee495552254493ee
eeeeeeeeeeeeeeeeeeee00eee111112ee111112e66669988eeeeeeeeeeeeeeeeeeeeeee2eeeeee2eeeeeeeeeee6677f344eeee44377766eeee344444444333ee
eee111177766619a916667771111eeeeeeeeeeee111166660066619aeeeeeeeee3332112eeeeeee2ffe11eff2eeeeeeeeeeeeeeeeeeeeeeeecccccceeeeeeeee
eeee11616116161916161161611eeeeeeeeeeeee1660676061161619eeeeeeee2e321161eeeeeeef22000022feeeeeeeeeefeeeeeeeeeeedccccccccdeeeeeee
eeee16616616166966161661661eeeeeeeeeeeee6000776066198711eeeeeeee3ee21661eeeeee221212212122eeeeeeeee4eeeeeeeee69ddccccccdd96eeeee
eee861166aa161111161aa661168eeeeeeeeeeee006677706aaa7110eeeeeeee32ee1660eeeeeeee2f1ff1f2eeeeeeeeeee4eeeeeeee667fd999999df266eeee
ee88e666a9986669666899a666e88eeeeee2ee2361111771a99871002ee2eeee32216616eeeeeeefff1ff1fffeeeeeeeeee4eeeeeeeef7777fff777f7762eeee
e88eee1699aa811a118aa9961eee88eeee23e2336666071999aa711032e32eee33216111eeeeee2ff12ff21ff2eeeeeeeee4eeeeeee6f7777777777777622eee
e8eeeee19aaa8616168aaa91eeeee8eee233e33e166601aa9aa9671133e332eee3216111eee5eefff1ffff1fffee5eeeeeefeeeeeee667777777777777766eee
e88eeee88aa9a96a69a9aa88eeee88eee23ee211700769aa8aa9a67712ee32eeee316110eee4a1ff21ffff12ff1a4eeeeeeeeeeeee66777f77777777777766ee
eeeeeeee776661a9a1666000eeee8eee6761111266611112eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11110ee6677727777777f277766ee
eeeeeeee6116161a16161161eee88eee6770661167606611eeeeeeeecddddddceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1161ee2277f7f7777ff7772762ee
eeeeeeee6616166a17891661eee8eeee7770700167700061eeeeeedddddddddddceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1661eef267f77777777f7f7662ee
eeeeeeee6aa16111117aa966eeeeeeee7766617077766006eeeeeddd7777777dddceeeeeeeeeeeecddddddddceeeeeeeeee86116eef26f7777777777f77662ee
2eeeeeeeaa98666a01789a96eeeeeeee0711116677111160eeeedd7777777ddddddceeeeeeeeedddddddddddddceeeeeee88e666eef22667f7777f77f26222ee
ee111111a9aa8119117aa9a6eeeeeeee1606666117066661eeedd7777ddccddddddcceeeeeeedddd7777777ddddceeeee88eee16ee22f2266277f776662222ee
e111111199a986161769a991eeeeeeeea100000191066611eeedd77ddddccdddddddceeeeeedd777777ccdddddddceeee8eeeee1eee2ff2662662666662f2eee
eee116668aa9a96976a9aa88eeeeeeeea96000009a670071eecdd7ddddccccddddddcceeeedd77777ddccdddddddcceee88eeee8ee2f2ff22666226222fff2ee
1116766088eea9a691666000112333ee006661a9eeeeeeeeeedddddddccccccddddccceeeedd77ddddccccdddddddceeeeeeeeeeeefeff2f2222222f22fe2fee
17077600e8eeeeee1616116161123e2e6116161aeeeeeeeeeedddddddcdccdcddddccceeecdd7ddddccccccddddddcceeeeeeeeeee2ef22ff22ff2fff2feefee
0077770088eeeeee178916616612ee3e66198711eeeeeeeeeeddddddddccccdddddccceeeddddddddcdccdcdddddccce344ee443eeeef2e2ff22f2f2ffeeeeee
716677608eeeeeee117aaa66661ee23e69aa7110eeeeeeeeeedddddddccddccdddcccdeeedddddddddccccddddddccce73eeee37eeee22eef2ff2f2e2f2eeeee
61117661eeeeeeee017899a61661223e9a987100eeeeeeeeeedddddddddddddddccccdeeeddddddddccddccdddccccdef72eef77eeee2eeef22f2f2eef2eeeee
6666061aeeeeeeee117aa9961161233ea9aa7110ee111111eecdddddddddddccccccddeeecddddddddddddcccccccdde6272f776eeeeeeeef2eeff2eef2eeeee
00000199eeeeeeee1769aa91116123ee99a96711e1111111eeecccdddcccccccccdddeeeeecccdddcccccccccccdddee62662666eeeeeeee22eeefeeee2eeeee
00006a99eeeeeeee76a9aa8811613eee8aa9a677eee11661eeeeeccccccccccddddeeeeeeeeeccccccccccccddddeeee26662262eeeeeeee2eeee2eeeeeeeeee
__map__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bd78747474ae00000000000000000000000000000000000000000000000000000000000000000000004242474742424242424242424242424242424747424242424242424242424242
002e000000bd7674ae00000000000000bd7874ae00000000000000000000000000000000000000000000000000000000000000000000bd83767474747474ae000000000000bd7674ae00000000000000bd7874ae0000000000000000000000004242424747474242424242424242424242424247474742424242424242424242
00000000008383767474ae000000bd8378747474ae00000000000000000000000000000000000000000000000000000000000000bd838383837674747474747474ae0000bd8383767474ae000000bd8378747474ae00000000000000000000004242474747474242424242424242424242424747474742424242424242424242
00dc00000083838383767474aebd8383767474747474ae00000000000000000000000000bd78ae00000000bd7474747474aebd78747783838383838376747474747475838383838383767474aebd8383767474747474000000000000000000004242474747474242424247474242424242424747474742424242474742424242
0000000000838383838376747583838383767474747474ae0000000000000000000000bd7874740000000083767474747474747474758383838383838383838383838383838383838383767475838383837674747474000000000000000000004242474742424242424742424747474242424747424242424247424247474742
003400000083838383838383838383838383837674747474ae0000000000000000bd8376747474ae0000bd83838376747474758383838383838383838383838383838383838383838383838383838383838383767474000000000000000000004242424747474242474742424247474742424247474742424747424242474747
0000000000838383838383838383838383838383837674747583767474ae00bd8383838376747474aebd83838383838383838383838383838383c5a1838383838383c5a1838383838383838383838383838383838376000000000000000000004242424247474747474742424747474742424242474747474747424247474747
001100000083c5a1838383838383c5a18383c5a183838383797ac5a176747477838383838383c5a1838383838383c5a1838383838383c5a183837372797ac5a1838373728383c5a1838383838383c5a18383c5a18383000000000000000000004242424242424247474742424747474242424242424242474747424247474742
00000000007a7372797ac5a1797a7372797a7372797ac5a170717372797a83838383c5a1797a7372797ac5a183837372797ac5a183837372797a737270717372797a7372797a7372797ac5a1797a7372797a7372797a000000000000000000004242424242424242474742424747474242424242424242424747424247474742
000000000071737270717372707173727071737270717372707173727071c5a1797a73727071737270717372797a737270717372797a7372707173727071737270717372707173727071737270717372707173727071000000000000000000004242424242424242474742424742424242424242424242424747424247424242
00b200b30071737270717372707173727071737270717372707173727071737270717372707173727071737270717372707173727071737270be6d6e6f71737270be6d6e6f7173727071737270717372707173727071000000000000000000004242474742424247474242424247424242424747424242474742424242474242
0000000000be6d6e6f71737270be6d6e6fbe6d6e6f71737270be6d6e6f7173727071737270be6d6e6f71737270be6d6e6f71737270be6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6f71737270be6d6e6fbe6d6e6f71000000000000000000004247474747474747474242424242474242474747474747474742424242424742
0094009500be6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6f71737270be6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe000000000000000000004747474742424247474242424247474747474747424242474742424242474747
0000000000be6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe6da06fbe6d6e6fbe6da06fbe6d6e6fbe6d6e6fbe6d6e6fbe6d6e6fbe000000000000000000004247474747424242474742424742424242474747474242424747424247424242
00b800b800be6da06fbe6d6e6fbe6da06fbe6da06fbe6d6e6fbe6da06fbe6d6e6fbe6d6e6fbe6da06fbe6d6e6fbe6da06fbe6d6e6fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6d6e6fbe6da06fbe6da06fbe000000000000000000004242474742424242474747474242424242424747424242424747474742424242
0000000000be6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6d6e6fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe000000000000000000004242424742424242424242424242424242424247424242424242424242424242
00a900a900be6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe0000000000000000000043434c4c4c4343434c4c43434343434343434c4c4c4343434c4c434343434343
0000000000be6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe0000000000000000000043434c4c434343434c4c4c434343434343434c4c434343434c4c4c4343434343
0059005900be6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe00000000000000000000434c4c4c43434343434c4c4c43434343434c4c4c43434343434c4c4c43434343
0000000000be6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe6da06fbe000000000000000000004c4c4c4c434343434343434c4c4c4c4c4c4c4c4c434343434343434c4c4c4c4c
00a800a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004c4c4c4c43434343434343434c4c4c4c4c4c4c4c43434343434343434c4c4c4c
000000000000000000000000000000000000dddedf00cbcccd00d9dadb00cbcccd00d4e07cd700d4e07cd70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434c4c4c4c434343434343434c4c4343434c4c4c4c434343434343434c4c4343
00fc00da0000000000000000000000000000edeeef00edfcef00e9eaeb00e9fceb00bad5aaf300d8b4e4f30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434c4c4c4c43434343434343434c4343434c4c4c4c43434343434343434c4343
000000000000000000000000000000000000fdfeff00fdfeff00f9fafb00f9fafb00d0d1d2d300ecd6f2d3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043434c4c4c43434343434343434c434343434c4c4c43434343434343434c4343
0033003300000008090a0b0c0d0e0f00000000000000000000000000000000000000c6c7afe300c6c7afe300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004343434c4c4c434343434343434c4c434343434c4c4c434343434343434c4c43
0000000000000018191a1b1c1d1e1f000000dddedf00cbcccd00b9da8700cbcccd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043434c4c4c4c4343434343434c4c4c4343434c4c4c4c4343434343434c4c4c43
0062006200000028292a2b2c2d2e2f000000edeeef00edfcef00e9eaeb00e9fceb00bff57d7f00bff57d7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043434c4c4c4c4c4c434343434c4c434343434c4c4c4c4c4c434343434c4c4343
0000000000000038393a3b3c3d3e3f000000c8c9ca00c8c9ca00f9fafb00f9fafb00887ee5980088f09698000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043434c4c4c4c4c4c4c434c4c4c4c434343434c4c4c4c4c4c4c434c4c4c4c4343
00000000000000000000000000000000000000000000000000000000000000000000d0e197d300ecf4e2d300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004343434c4c4c4c4c4c4c4c4c4c4343434343434c4c4c4c4c4c4c4c4c4c434343
00000000000000000000000000000000000000000000000000000000000000000000c6f1b5e300c6f1b5e30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434343434c4c43434c4c4c4343434343434343434c4c43434c4c4c4343434343
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000434343434c4c43434c4c4c4343434343434343434c4c43434c4c4c4343434343
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004343434c4c434343434c4c43434343434343434c4c434343434c4c4343434343
__gff__
00030303d20303030012030303034a52d2d25203030303030400041200000000040404040404040404040404040404040000008081048080808080808080000003000404d20403040082835204047372818010100000000000808000828000008000800080808080008180808000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
__sfx__
000100000e0601107012070120701207011060100500f0400c02000000000000000017560195701a5701a57019570175601554013520000000000000000000000d7600f7700f7700e7600c7600b7500974004730
59800000105540e554005000050000500005000050010551105540e5540050000500005000050000500105510e5551055400500005000050000500005000e5510e5541055400500005000050000500005000e551
1920002000005000050000500005000050c0000e0001000011055000051005510055000050c0550e055100550000500005000050000500005100000e0000c00010035000050c0350c03500000100350e0350c035
510200001c1551d1551f15521145201351515517155161450f155101551215514155171451613511155101450e1450e1450e1450d1350c1350b1250b1250a1150a11500105001050010500105001050010500105
010406000707300003000030000300003000030000000003070730000015100085520a5430000300003000030a552085430000300003000000000308142071330000000000000000000000000000000000000000
330400001c7221c7421c7521c7621c7621c7621c7521c7521c7421c7421c7321c7321c7221c7221c7121c71217600176001c7000e000000001c7000e000000001000000000000000000000000000000000000000
010200001566014640126200000000000000000060000600156651565514645136151262511615006000060000600006000060000600006000060000000006000060000600006000060000600006000060000600
4903000010070170501a0301d020000000000000000000001c070190501503012020000000000000000000000e124116340e615106000e6000000000000000001015315620146151360012600116000000000000
4b0400001765013625396003860036600216000d6050000517650176551c7020000500005000050000500005100730000500005000050000500005000050000511600106000e6000c60017600000001060000000
131000001b075260050000500005000050000500005000050e6500c65010630116200c6150760000005000051a1561d1260c00500005000050000500005000052f65538615000000000000000000000000000000
650400000c1600d1700e1700f1700e1700d1700c1700d1700c1700d1700e1700e1600d1500c1400b1300a12009110121001310013100131001310000100001001400007600001001300007600001001300007600
890400001055610556115561155613556135561554615546175361753618526185261a5161a516000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
310c00002b3751f30500005000052a3750000523375000052330500005233751f1252437500005283750000526375000051f3751f12500005000051f3750000500005000051f3750000526375000052b37500005
310c00002d3751f30500005000052a305000052f3750000523305000051a1041a1021a1541a1521f1541f1521f1541f1521f1521f15521102211052115421152211522115523102231052b37526375233751f375
090c00001f0141f0101f0101f0101f0211f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0201f0311f0301f0301f0301f0301f0301f0301f030
010c000000000000001f1251f1251a2241a2251f1251f1252b7242b7202b7222b7222b7251f2251a1251a125231542315223152231551c1251c12524154241522415224155211252112500000000001f1251f125
090c1f201f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f0301f030
000c000000000000001f1251f12500000000001f1251f1252672426720267222672226725000001f1251f12537525000001f1252b525000002b5151f1251f12500000131252b1251f1251a0241a0251f1251f125
310c00002b3751f30500005000052a3750000523375000052330500005233751f1252437500005283750000526375000051f3051f12500005000051f3050000500005000051f3050000526305000052b30500005
310c000026470264751f4701f4752b0352b0352b0252b0252b0152b0152117421175231742317524174241751f1742117023172231752b0142b0102b0102b0151a3751f375213752130523375000001f37518625
310c00001f4501f4551a4501a45500000000001a1251a1251f2241f22524174241752617426175281742817523174241702617226175375253750526125261252b525000001a1251a1251f525000001f1251f125
041e00001f7141f7211f7311f7411f7511f7501f7501f7501f7521f7521f750207512175121750217522175221750217502475126751287512875028750287502875028741287312872128711287150000000000
081e00000000004611056200562006630066300563004620036111a0141a0211a0111a0151f6141f621206312063220621206111e6151f125181251a125356143561237621386203862236620356113461030615
090c0000240730c073000001f325000001a325000001800018650186601866018671186711867518625186150000000000000001a325240730c0731f325000001865018660186601867118671186751862518615
19200000263751f1251f055233751f125230551f125230351a1741a17217174171721917419172191721917219172191751317415174181741717417172171721717513172131721317213172131752b3751f375
291a18002375423750237502375023750237312371123715227542275022750227502275022731227112271523754237502375023750237502373123711237150000000000000000000000000000000000000000
a91a00001f7241f1211f2311f2311f2411f1311f7311f7251f7241f1211f2311f2311f2411f1311f7311f7251f7241f1211f2311f2311f2411f1311f7311f7251f0001f0011f0011f0011f7011f7011f7011f701
a10200001e1522015222152231521b1521e1521a15219152191521615212152151520010200102001020010200102001020010200102001020010200102001020010200102001020010200102001020010200102
05070f102b4502b430205722053229350293301e5721e5321f4530735007350073500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002b4502b430205722053229350293301e5721e532
291a0a001f7301f725000000000000000000000e305000000e35000000000000000000000000000e3050e30000000000000000000000000000000000000000000000000000000000000000000000000000000000
090d00100c0733f600136150c0731862018623136153f60013615136053f60013615136053f600136153f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f6003f600
050d000007350073500e3500e35024451244502445224452234551f4551d4050e350000000000007350000000735000000073500000024454244522445024455234551f455000000735000000000000e35000000
050d100007350073500e3500e35024451244502445224452234551f4551d4050e350000000000007350000000730000000073000000024404244022440024405234051f405000000730000000000000e30000000
050d00000735000000073500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
914000200862010625000050000510624136250e605000050d6000d600106240e625056000560000000000000b620106250000500005086000860000000000000b6241162500005000050d6200e6250e60500005
8940002000301233110030100301003010030100301195150030100301003012b3110030100301003011b5150000015311003010030124311003010030115515003010030100301003010912100301003011b605
012400001301413020130301304013040130501305013050130501305013050130501305013050130501305013050130501305013050130701307013070130701305013050130501304013040130301302013015
03240000140141401414014140143f000240110c0113c000240110c01139000240110c0113c6153a61539615006200062000620006253a4163b4163a4163b416304243042033421334203a4163b4163a4163b416
1a1200002e3751805337375071452b375260353237526025263751b1252e3751d1251f375161252b3751a1251f375326242137522375071452134522345021452131522315071452737500005243750000525305
001200001a0501a0521a7421a7451f2241f2243761500000180533721407211180533761518053376150000018053000001a0501a0521a7421a74518053376151866018650186401864537615000003761500000
0012000013050130521374213745376150703507035070350000002135071350e1353e0142b0111a0110001007040070431305013052137421374526624296241805329624000003761507145021450704502745
1a1200002537518053081252d375081250f1253e37526025263051b125260351d1250f02516125160251b1251402532624140250f025081450f0251402503145140250f025061451a14419144191451814418145
011200001905019052197421974514224142243761500000180533821408211180533761518053376150000018053000001905019052197421974518053376151866018650186401864532634286241e62412614
0012000014050140521474214745376150803508035080350000003135081350f1353e0142b0111a0110001008040080431405014052147421474526624296241805329624000003761508145031450804503745
1a1200002e3751805337375071452b375260353237526025263751b1252e3751d1251f375161252b3751a1251f375326242137522375071452134522345021453337522305303752e37500005273750000525305
01120000023700e14502470276452c64502175077450e05500000021452c645023752c6450e1450e145276450a370163750a470113752c645276452c62527625021450a37505145276452c645021452c6452c645
01120c140e1301740013130174000e1300c4000e13033400370242a0211a02106021304243042033421334203a4263b4263a4263b426304043040033401334000000000000000000000000000000000000000000
00120000043701014504470276452c645041750b7451005500000041452c645043752c645101451014527645043700e37504470103752c645276452c62527625021450a37505145276452c644021352c6242c614
030d000021451214501807321441214401807321421214201115505050131550505018073141553a6551615518073111553f0253e0253d0253c0253b0253a0253a655180733a655180733a655135503a65516550
020d0000050703a6553a655050703a6553a655110703a655180733a6553a6553a6551124411242112421124505055050553c6551807335655180732b6553a6550505005050111601127005050050501116011270
000d0000164540315016454160202245122450164540a1501645416320214512145016454051501645416020204512045020450204501645416150164540a1501645403150164541653023451234502345023450
020d00000c0530c0530c0533e6550c0530a0503e655160500c0530c0530c0533e6550c0530a1503e655161500c0530c0530c0533e6550c0530a2503e655162500c0530c0530c0533e6550c0533e6553e6553e655
030d0000160503a655160503a655163203a655160503a6551805018320180503a6553a65518053180503a655190503a65519050193203a6553a655190503a6551b0503a6551f0501b3203a6551e3201e0503a655
010d0000180530a1500a1500a150180530a1500a1500a150180530815008150081500815008150081500815018053071500715007150180530715007150071501805306150061500615006150061500615006150
050d000011156051561115605156161560a156161560a1561b1560f1561b1560f15620156141562015614156251561915625156191562a1561e1562a1561e1562a1561e1562a0201e020191501e1502015023150
030e001815650150533d6203d6501e0253d6203d6503d65500000010550d010010550c0530c0033d6203d6501e0253d6203d6503d655000001942400000010550000000000000000000000000000000000000000
011500001975019750197501c7501c7501c7502175021750217502075020750207502074020730207202071519400000000000000000000000000000000000001940000000000000000000000000000000000000
091500001705017050170501805018050180501e0501e0501e0501e0501e0501e0501f0501f0501c0501c0501c0501c0501c0501c0501c0401c0301c0201c0150000000000000000000000000000000000000000
192a0000100541005010050100500b0510b05519154191521715417152171521715519104191020b0500b0500d0500d0500d0500d05008050080501e155201551915508000191351c10507424074220742207425
1915000004050000001c3551435500000193550405017355040500000020355000000405000000000000000004050000001c35514355000001935504050173550405000000203050405004050000000000000000
011500001031000000190551431019025190551731019025190550d31019025190551031019025190550d31019025103101431010310173101431019310173101c31019310203101c31023310203102531023310
001500001031000000150551531015025150551731015025150550931015025150551031015025150550d3101502510310153101031019310153101c31017310213101c310253102131028310253102d31028310
0115000017500195001a5001a50019500175001550013500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
__music__
00 15164354
01 0c110e4e
00 0d100f50
00 12101150
00 13141050
00 18104350
00 0c17110e
00 0d170f10
00 12171110
00 13171410
02 18104350
03 63644344
01 191a4a44
00 1d4c4344
00 191a1f44
00 1c1e4e44
00 20424344
00 214c4344
00 1d224344
00 201f4344
00 211f4344
02 1d224344
01 25264344
00 27282969
00 2a2b2c6c
00 2d282969
00 2a2b2c6c
00 2f2e4344
00 2f304344
00 2f2e4344
02 2f304344
01 383f4344
00 38394344
00 383f4344
00 383d4344
00 383e4344
00 383c4344
00 383c4344
00 383b4344
00 383b4344
02 383f4344
00 04064644
00 04064644
00 04064644
00 31324344
00 31324344
01 33344344
00 33344344
00 33344344
00 33344344
00 35364344
00 35364344
02 37364344
01 01024344
00 01022344
00 01022444
00 01246444
00 01024344
02 01232442
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555mmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555mmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccc55555555mmmmmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccc5555555mmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccc55555555mmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccc55555555mmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccc55555555mmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc55555555mmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccc
mccccccccccccccccccccccccccccccccccccccc555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccccccc
mmccccccccccccccccccccccccccccccccccccc555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccccccccc
mmmmccccccccccccccccccccccccccccccccc5555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccccccc
mmmmmcccccccccccccccccccccccccccccccc555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccccc
mmmmmmmccccccccccccccccccccccccccccc5555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccc
mmmmmmmcccccccccccccccccccccccccccc55555555555r5555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccccc
mmmmmmmmccccccccccccccccccccccccccc55553555555jr555mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccccccccccccccc
mmmmmmmmmccccccccccccccccccccccccc5555r555555r5355mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmccccccccccccccc555jj5r5jj5553rj5mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmccccccccccccc555jjrr3jjr3r3r3rr3rmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmccccccccc555jr3rrrrrrrrr3rrrrrrrmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmcccccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmmcccccccc55553rkk3rr3k33k33k3r3jmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmccccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmmmmccccc5555jrrk44k39999994443rr5mmmmmmmj3mmmmmmmmmmmrm3mmmmmmmmmmmrrmmmmmmmmmmmmmmccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmmmmcccc555555r39949499994449krr3jjmmmmmmmrmm3m3mmmmmm3rmmmmmmmmmmmm3m3mmmmmmmmmmmmmccccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmmmmmccc55555jr3444494444444443rrr55rjmmmm3mjm3mmmmmmmj3jmmjmmmmrmmmjmrmmmmmmmmmmmmmmcccccccccccccccccccccccc
mmmmmmmmmmmmmmmmmmmmmmmmmc555555jrk4444449444kk4krrrjj35jmmjr33rjrj3jmjjrj3rmr3jjmmj3mjjj33mmmmmmmmmmmmmmccccccccccccccccccccccc
5mmmmmmmmmmmmmmmmmmmmmmmm55555555r3k3k3k944k3rr33rrrr3r33jjmr3r3rrrr333r3r3rrrrrjmjmrmj3r3r3rmmmmmmmmmmmmccccccccccccccccccccccc
55mmmmmmmmmmmmmmmmmmmmmm555555555jrrr3r349943rrrrrrrrrrr3rr3r3rr333rrrrrrrrr333rrr3jjjr333rrjjmmmmmmmmmmmmcccccccccccccccccccccc
5555mmmmmmmmmmmmmmmmmmm555555555553rrrrk94543rrrr335ii3rrrrr3kkkk943rrrr3k3kk573rrrr3r349kk3r3mmmmmmmmmmmmmmcccccccccccccccccccc
5555mmmmmmmmmmmmmmmmmmm555555555555rrrrk4m5krrrr3immm7m3rrr349449994krr3494499mmirrrr349999k3rjmmmmmmmmmmmmmmccccccccccccccccccc
55555mmmmmmmmmmmmmmmm55555555555555jrr3445i43rr357m5imm53rr34994k44943r349944445m3rrrk4kk494kr3mmmmmmmmmmmmmmmmccccccccccccccccc
55555mmmmmmmmmmmmmmm555555555555555rrrrk5mi43rr3mm53r355irrk494k33k49krk944k3k4i5irr344rr349kr3jmmmmmmmmmmmmmmmccccccccccccccccc
5555555mmmmmmmmmmm55555555555555555jrr345m4krr357i3rrri4k3r34493rr3444334943rr34i53rrkkrrrk94333mmmmmmmmmmmmmmmmcccccccccccccccc
55555555mmmmmmmmm55555555555555555553rr4mi443rrimmiiiim94rr34943rr3k43r39443rr3k43rrrrrrr3k4433jmmmmmmmmmmmmmmmmmccccccccccccccc
55555555555555555555555555555555555jr3rk5m4433r7i575mi5kkrr34493rrrrrrr34943rrrrrrrr33333k44433jmmmmmmmmmmmmmmmmmccccccccccccccc
5555555555555555555555555555555555553r34574krr3mm5i33r33rrrrk44krrrrrrr3444krrrrrrrrk4444944kr3mmmmmmmmmmmmmmmmmmmcccccccccccccc
555555555555555555555555555555555555jrrkim4krr34993rrrrrrrr3494krrrrrrr3444k3rrrrrr34444444443r3mmmmmmmmmmmmmmmmmmmmcccccccccccc
5555555555555555555555555555555555553r344i43rrr344k3r334k3rrk443rrrrrrrrk443rrr3rr3k443rr344kr3jmmmmmmmmmmmmmmmmmmmmmccccccccccc
555555555555555555555555555555555555j3k4444k3rrrk944kk44k3r3444k3rr3rrr3444k3r3rrrrk444kk4444r3mmmmmmmmmmmmmmmmmmmmmmmmccccccccc
555555555555555555555555555555555555jr344443rrrr3444444krrr34443rrrrrrr34443rrr3rrr33kk44444433mmmmmmmmmmmmmmmmmmmmmmmmccccccccc
55555555555555555555555555555555555533k44443r3r3r3k4k4krrrr34kk3r3333r334kk3r3r33r33rrr3kk444333mmmmmmmmmmmmmmmmmmmmmmmmcccccccc
555555555555555555555555555555555555jrk33k3r3jjj3rr3r3rr33rr33r33j5j53jr33rr3j3j33jm3j3rr333kr3jmmmmmmmmmmmmmmmmmmmmmmmmmccccccc
5555555555555555555555555555555555555j33rr33j555533rrrrjj5j33j33555555533j3j5555555555jj3r3rrr3jmmmmmmmmmmmmmmmmmmmmmmmmm5555555
55555555555555555555555555555555555555j33j555555555j5j55555555555555555555555555555555555j33r3jmmmmmmmmmmmmmmmmmmmmmmmmm55555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555jmmmmmmmmmmmmmmmmmmmmmmmmmm555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555mmmmmmmmmmmmmmmmmmmmmmmmmmm555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555mmmmmmmmmmmmmmmmmmmmmmmm55555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555mmmmmmmmmmmmmmmmmmmmmmm555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555mmmmmmmmmmmmmmmmmmm55555555555555
555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555mmmmmmmmmmmmmm555555555555555
555555555555555555555555555555577755555777577757775777577757775777577755j357755777577757775757577755555555555555555555551j555555
555555555555555555555555555555575755555575575557575757575757575575575755335757575557775757575757555555555555555555555555jjj55555
555555555555555555555555555555577755555575577557755775577757755575577753j3575757755757577757755775555555555555555555555j1j155555
555555555555555555555555555555575755555575575557575757575757575575575753jj575757555757575757575755555555555555555555555j11j55555
55555555555555555555555555555557575555557557775757575757575757577757575jj357775777575757575757577755555555555555555555511jj15555
555555555555555555555555555555555555553555555555555555555555555555555553j355555555555555555555555555555555555555555555jj1j1j5555
555555555555555555555555555555555555553jjjj3355555555555555555555555553jjjj3355555555555555555555555555555555555555555j1111jj555
555555555555555555555555555555555555533jjj3j355555555555555555555555533jjj3j35555555555555555555555555555555555555555jj111j1j555
55555555j3555555555555551j555555555j3j3j3j33j35j555555551j555555555j3j3j3j33j35j555555551j55555555555555j35555555551j1j1j1jj1j51
555555553335555555555555jjj5555555j33j3j3j3jj33555555555jjj5555555j33j3j3j3jj33555555555jjj555555555555533355555551jj1j1j1j11jj5
55555553j3j555555555555j1j1555555j53jj3jjjj33j3j5555555j1j1555555j53jj3jjjj33j3j5555555j1j15555555555553j3j55555515j11j1111jj1j1
55555553jj3555555555555j11j5555555jjj3jjjj3j33j5j555555j11j5555555jjj3jjjj3j33j5j555555j11j5555555555553jj35555555111j1111j1jj15
5555555jj33j5555555555511jj155555j3j33j3jj33j3j3555555511jj155555j3j33j3jj33j3j3555555511jj155555555555jj33j555551j1jj1j11jj1j1j
55555533j3j35555555555jj1j1j5555553j33jjjjj3jjj3j55555jj1j1j5555553j33jjjjj3jjj3j55555jj1j1j555555555533j3j3555555j1jj11111j111j
5555553jjjj33555555555j1111jj55553j33j3jj3jjj3j3355555j1111jj55553j33j3jj3jjj3j3355555j1111jj5555555553jjjj335555j1jj1j11j111j1j
5555533jjj3j355555555jj111j1j5555j33j3jjjjj3j33j35555jj111j1j5555j33j3jjjjj3j33j35555jj111j1j5555555533jjj3j355551jj1j11111j1jj1
555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51
55j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj5
5j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j1
15jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj15
5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j
153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j
j3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1j
jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1
555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51555j3j3j3j33j35j5551j1j1j1jj1j51
55j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj555j33j3j3j3jj335551jj1j1j1j11jj5
5j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j15j53jj3jjjj33j3j515j11j1111jj1j1
15jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj1515jjj3jjjj3j33j5j5111j1111j1jj15
5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j5j3j33j3jj33j3j351j1jj1j11jj1j1j
153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j153j33jjjjj3jjj3j5j1jj11111j111j
j3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1jj3j33j3jj3jjj3j33j1jj1j11j111j1j
jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1jj33j3jjjjj3j33j31jj1j11111j1jj1
555j3j3j3j33j35j5551j1j1j1j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11jj1j51555j3j3j3j33j35j5551j1j1j1j11jj1
55j33j3j3j3jj335551jj1j1j11j111jj3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j11j11jj555j33j3j3j3jj335551jj1j1j11j111j
5j53jj3jjjj33j3j515j11j1111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1j15j53jj3jjjj33j3j515j11j1111jj1jj
15jjj3jjjj3j33j5j5111j111111j1j33jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j111j1jj1515jjj3jjjj3j33j5j5111j111111j1j3
5j3j33j3jj33j3j351j1jj1j11111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111jj1j1j5j3j33j3jj33j3j351j1jj1j11111j1j
153j33jjjjj3jjj3j5j1jj11111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j111j153j33jjjjj3jjj3j5j1jj11111j1jj3
j3j33j3jj3jjj3j33j1jj1j111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj11j111j1jj3j33j3jj3jjj3j33j1jj1j111111jj3
jj33j3jjjjj3j33j31jj1j111111j133j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj11111j1jj1jj33j3jjjjj3j33j31jj1j111111j133
333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1
j3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111j
3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj
3jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j3
3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j
jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3
j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3
j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133
333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1
j3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111j
3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj
3jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j3
3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j
jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3
j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3
j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133
333j3jjjj33jj33j3j1j1j1j11j11jj1333j3jjjjjjj3j3j3j1j1j1j11j11jj1333j3jjjjjjj3j3j3j1j1j1j11j11jj1333j3jjjj33jj33j3j1j1j1j11j11jj1
j3j3jjjjjjjj3j3j3311jj1j111j111jj3j3jjjjjj3jjj3j3311jj1j111j111jj3j3jjjjjj3jjj3j3311jj1j111j111jj3j3jjjjjjjj3j3j3311jj1j111j111j
3j33j3jjjjjj3jj3j3j1j1jj111jj1jj3j33j3jjjjjjj3j3j3j1j1jj111jj1jj3j33j3jjjjjjj3j3j3j1j1jj111jj1jj3j33j3jjjjjj3jj3j3j1j1jj111jj1jj
3jjjjjjjjj3j33j33j31j1j11111j1j33jjjjjjjjjj3j3j33j31j1j11111j1j33jjjjjjjjjj3j3j33j31j1j11111j1j33jjjjjjjjj3j33j33j31j1j11111j1j3
3j3j3jjjjjjjjjj3j3jj1j1111111j1j3j3j3jjjjjjjjjjjj3jj1j1111111j1j3j3j3jjjjjjjjjjjj3jj1j1111111j1j3j3j3jjjjjjjjjj3j3jj1j1111111j1j
jj3jjjjjjjjj33jjj33j1jj1111j1jj3jj3jjjjjjjjjj3jj333j1jj1111j1jj3jj3jjjjjjjjjj3jj333j1jj1111j1jj3jj3jjjjjjjjj33jjj33j1jj1111j1jj3
j33jjjjjjj33j33j3j3j1jj111111jj3j33jjjjjjjjjjjj33j3j1jj111111jj3j33jjjjjjjjjjjj33j3j1jj111111jj3j33jjjjjjj33j33j3j3j1jj111111jj3
j3jj3jjjjjjjj333j3j3jj111111j133j3jj3jjjjjjjjj33j3j3jj111111j133j3jj3jjjjjjjjj33j3j3jj111111j133j3jj3jjjjjjjj333j3j3jj111111j133
333j3jjjjjjj3j3j3j1j1j1j11j11jj1333j3jjjjjjj3j3j3j1j1j1j11j11jj1333j3jjjjjjj3j3j3j1j1j1j11j11jj1333j3jjjjjjj3j3j3j1j1j1j11j11jj1
j3j3jjjjjj3jjj3j3311jj1j111j111jj3j3jjjjjj3jjj3j3311jj1j111j111jj3j3jjjjjj3jjj3j3311jj1j111j111jj3j3jjjjjj3jjj3j3311jj1j111j111j
3j33j3jjjjjjj3j3j3j1j1jj111jj1jj3j33j3jjjjjjj3j3j3j1j1jj111jj1jj3j33j3jjjjjjj3j3j3j1j1jj111jj1jj3j33j3jjjjjjj3j3j3j1j1jj111jj1jj
3jjjjjjjjjj3j3j33j31j1j11111j1j33jjjjjjjjjj3j3j33j31j1j11111j1j33jjjjjjjjjj3j3j33j31j1j11111j1j33jjjjjjjjjj3j3j33j31j1j11111j1j3
3j3j3jjjjjjjjjjjj3jj1j1111111j1j3j3j3jjjjjjjjjjjj3jj1j1111111j1j3j3j3jjjjjjjjjjjj3jj1j1111111j1j3j3j3jjjjjjjjjjjj3jj1j1111111j1j
jj3jjjjjjjjjj3jj333j1jj1111j1jj3jj3jjjjjjjjjj3jj333j1jj1111j1jj3jj3jjjjjjjjjj3jj333j1jj1111j1jj3jj3jjjjjjjjjj3jj333j1jj1111j1jj3
j33jjjjjjjjjjjj33j3j1jj111111jj3j33jjjjjjjjjjjj33j3j1jj111111jj3j33jjjjjjjjjjjj33j3j1jj111111jj3j33jjjjjjjjjjjj33j3j1jj111111jj3
j3jj3jjjjjjjjj33j3j3jj111111j133j3jj3jjjjjjjjj33j3j3jj111111j133j3jj3jjjjjjjjj33j3j3jj1111111133j3jj3jjjjjjjjj33j3j3jj111111j133
__meta:title__
terra - a terraria demake
by cubee 0
