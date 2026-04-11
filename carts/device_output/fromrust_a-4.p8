pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

cartname, item_data = "#fromrust_b-3", [[1,rusty,cutter,atk,280,7,3,1000,4,2,3,MELEE&RUSTY
2,shock,axe,atk,400,8,6,1,6,2,3,MELEE&SHOCK
3,thin,dagger,atk,120,3,3,0,0,2,3,MELEE
4,repair,piston,def,320,8,8,2,96,2,3,FUEL
5,flame,launcher,flm,480,5,2,0,36,3,3,RANGED&FUEL&FIRE
6,heated,machete,atk,280,4,3,101,8,2,3,MELEE&FIRE
7,pulse,smg,atk,150,6,3,0,46,2,3,RANGED
8,heavy,sniper,atk,800,40,10,201,104,3,3,RANGED
9,shielding,belt,shl,240,8,8,0,136,2,2,SHIELD
10,rough,whetstone,buf,0,0,0,1001,158,2,1,BUFF
11,dull,cutter,atk,220,6,6,0,2,2,3,MELEE
12,electric,axe,atk,480,14,6,7,10,3,3,MELEE&SHOCK
13,solder,gun,def,280,8,8,0,78,2,2,FUEL&PISTOL
14,rusty,shield,shl,320,7,3,1000,128,2,3,SHIELD&RUSTY
15,flame,bomb,flm,900,5,2,1002,34,2,3,FIRE
16,rusty,pistol,atk,240,5,3,1000,76,2,2,RUSTY&PISTOL
17,quick,pistol,atk,240,8,3,3,92,2,2,RANGED&PISTOL
18,heavy,revolver,atk,240,8,3,4,94,2,2,RANGED&PISTOL
19,shelter,shotgun,atk,320,10,4,104,66,3,3,SHOTGUN
20,fast,loader,buf,0,0,0,1003,140,2,1,BUFF
21,rusty,wire,buf,0,0,0,2001,175,1,2,BUFF&RUSTY
22,ap,bullets,buf,0,0,0,1004,156,2,1,BUFF
23,ignition,core,def,480,16,8,301,98,2,3,BUFF&FUEL
24,flimsy,torch,atk,380,10,6,302,32,2,3,MELEE&FIRE
25,heavy,plating,shl,420,10,5,1005,130,2,3,SHIELD
26,solar,deathray,flm,1200,40,10,0,42,4,3,FIRE
27,short,blaster,atk,360,7,3,102,64,2,3,SHOTGUN
28,loaded,shells,buf,0,0,0,1006,111,1,2,BUFF
29,impact,grenade,atk,720,32,6,1002,72,2,3,GRENADE
30,grenade,launcher,atk,480,2,2,303,69,3,3,RANGED
31,amplifier,belt,buf,0,0,0,1007,142,2,1,BUFF
32,cooling,barrier,shl,300,6,3,5,132,2,3,SHIELD
33,rusty,core,def,520,13,5,6,102,2,3,RUSTY
34,emp,grenade,atk,720,24,6,1002,74,2,3,GRENADE&SHOCK
35,steel,ripper,atk,520,6,6,8,13,3,3,MELEE&FUEL
36,shocking,lance,atk,240,12,3,9,107,3,3,RANGED&SHOCK
37,fusion,rifle,flm,600,8,3,304,39,3,3,FIRE&FUEL
38,linked,plates,buf,0,15,0,1005,174,1,3,BUFF
39,tempo,engine,def,500,6,6,3001,100,2,3,FUEL&BUFF
40,r1,cannon,atk,600,38,12,0,196,2,3,RANGED
41,enhanced,mix,buf,0,0,0,1008,110,1,2,BUFF
42,imperial,blade,atk,360,12,4,202,166,2,3,MELEE&REGAL
43,imperial,shield,shl,440,12,4,203,168,2,3,SHIELD&REGAL
44,imperial,armor,def,400,16,4,204,170,2,3,REGAL
45,sunder,blade,flm,560,2,4,3002,201,3,3,MELEE&FIRE
46,electric,cleaver,atk,300,8,6,0,162,2,3,MELEE&SHOCK
47,shocking,buckler,shl,360,12,6,1015,164,2,3,SHIELD&SHOCK
48,emp,bolter,atk,400,10,4,102,192,2,3,SHOTGUN&SHOCK
49,shell,loader,shl,720,18,8,10,194,2,2,SHIELD
50,plated,belt,buf,0,10,0,1005,172,2,1,BUFF
51,rusty,belt,buf,0,7,0,1005,188,2,1,BUFF&RUSTY
52,r2,cannon,atk,720,60,20,0,198,3,3,RANGED
53,hand,cannon,atk,260,12,6,0,210,2,2,RANGED&PISTOL
54,destroyer,rounds,buf,0,0,0,1009,222,1,3,BUFF
55,centurion,remains,buf,0,0,0,4000,204,2,1,SCRAP
56,mech,finger,atk,300,2,10,1010,160,2,3,MELEE&BOT
57,service,repeater,atk,330,18,6,0,152,3,2,RANGED
58,exceptional,core,buf,0,0,0,1011,138,1,1,BUFF
59,shield,array,shl,400,3,2,205,134,2,3,SHIELD
60,energy,transfer,buf,0,0,0,2002,139,1,2,BUFF
61,mechanic,toolbelt,shl,420,8,6,501,224,2,2,SHIELD&BOT
62,scout,drone,atk,240,8,8,0,240,2,2,MELEE&BOT
63,guardian,drones,shl,480,6,6,2003,226,2,3,SHIELD&BOT
64,repairing ,swarm,def,400,6,3,502,228,2,3,FUEL&BOT
65,twin,protectors,atk,300,16,6,503,230,2,3,RANGED&BOT
66,spare,parts,buf,0,0,0,1012,236,1,2,BUFF
67,shepards,rod,buf,0,0,0,2501,221,1,3,BUFF
68,integrated,core,buf,0,0,0,1013,220,1,1,BUFF
69,repairing ,center,buf,0,0,0,2502,223,1,3,BUFF
70,coiling,devourer,atk,900,40,15,504,232,4,3,MELEE&BOT
71,industrial,flexer,buf,0,0,0,1014,14,2,3,BUFF
72,ancient,sixgun,atk,160,6,6,0,2,2,2,RANGED&PISTOL
73,ignition,pulser,atk,300,7,3,11,18,2,2,RANGED&PISTOL&FIRE
74,ignition,cannon,flm,800,8,3,1002,4,2,3,RANGED&FIRE
75,enhanced,magazine,buf,0,0,0,1004,13,1,2,BUFF
76,pulse,cannon,atk,900,80,20,0,38,3,3,RANGED&SHOCK
77,twin,dagger,atk,150,6,6,102,0,2,3,MELEE&RANGED
78,heavy,minigun,atk,120,4,4,103,41,3,3,RANGED
79,gauss,shotgun,atk,320,14,6,102,6,2,3,SHOTGUN&RANGED]]

function get_trigtxt(d)
  dply_lines = {_1 = "bUFF ALL YOUR|OTHER MELEE|WEAPONS BY +" .. 1 + d.level, _2 = "bUFF ADJECENT|MELEE WEAPONS|BY +" .. d.level, _3 = "cHARGE YOUR|RIGHT PISTOL BY 1|SECOND", _4 = "cHARGE YOUR|LEFT PISTOL BY 1|SECOND", _5 = "rEDUCE YOUR|IGNITE BY " .. d.v // 3 .. " POINTS", _6 = "bUFF ALL YOUR|RUSTY ITEMS BY +2", _7 = "bUFF ALL YOUR|OTHER MELEE|WEAPONS BY +" .. 2 + d.level, _8 = "rEDUCE THE|COOLDOWN BY 15%", _9 = "bUFF ALL YOUR|SHOCK ITEMS|BY +1", _10 = "bUFF ADJECENT|SHOTGUNS BY +" .. d.level, _11 = "iGNITE 2 POINTS", _101 = "dEALS DOUBLE|DAMAGE IF THE|TARGET IS IGNITED", _102 = "aTTACKS 2 TIMES", _103 = "aTTACKS 3 TIMES", _104 = "dEALS TRIPLE|DAMAGE AND BUFF|SHIELDS BY +1", _201 = "dEALS TRIPLE|DAMAGE IF THIS IS|YOUR ONLY WEAPON", _202 = "dEALS DOUBLE|DAMAGE IF THIS IS|YOUR ONLY WEAPON", _203 = "sHIELDS DOUBLE|IF THIS IS YOUR|ONLY SHIELD ITEM", _204 = "hEALS DOUBLE|IF THIS IS YOUR|ONLY HEAL ITEM", _205 = "sHIELDS 3 TIMES", _301 = "cHARGE ADJECENT|ITEMS BY 0.5|SECONDS IF IGNITED", _302 = "iGNITE YOURSELF|AND THE TARGET|FOR 3 POINTS", _303 = "cHARGE ADJECENT|GRENADES FULLY|AND BUFF BY +" .. d.v, _304 = "dEBUFF TARGET'S|SHIELD ITEMS BY 1", _501 = "bUFF A RANDOM|BOT ITEM BY +1|rEQUIERES 3 BOTS", _502 = "hEALS 3 TIMES|rEQUIERES 3 BOTS", _503 = "aTTACKS 2 TIMES|rEQUIERES 3 BOTS", _504 = "dOUBLE THIS ITEMS|DAMAGE.|rEQUIERES 3 BOTS", _1000 = "sTART COMBAT:|fOR EVERY OTHER|RUSTY, BUFF BY +2", _1001 = "bUFF ADJECENT|MELEE WEAPONS|BY +3", _1002 = "sTART COMBAT:|uSE THIS ITEM", _1003 = "aDJECENT PISTOLS|GET THEIR|COOLDOWN REDUCED|BY 0.5 SECONDS", _1004 = "bUFF ADJECENT|RANGED WEAPONS|BY +2", _1005 = "dURING COMBAT,|YOUR MAX HP IS|INCREASED BY " .. d.v * 5, _1006 = "bUFF ALL YOUR|SHOTGUNS BY +3", _1007 = "bUFF ALL YOUR|SHIELD ITEMS|BY +5", _1008 = "bUFF ALL YOUR|FIRE ITEMS|BY +2", _1009 = "cANNONS DEAL 35%|MORE DAMAGE|BUT CHARGE|10% SLOWER", _1010 = "tHIS ITEM DEAL 8%|OF YOUR mAX hp|AS EXTRA DAMAGE", _1011 = "bUFF ALL ITEMS|LACKING ADDITIONAL|EFFECTS BY +4", _1012 = "bUFF ALL YOUR|BOT ITEMS BY +2", _1013 = "sTART COMBAT:|fOR EVERY BOT|ITEM, GAIN 50|mAX hp", _1014 = "bUFF ADJECENT|MELEE WEAPONS|BY +12", _1015 = "sTART COMBAT:|fOR EVERY OTHER|SHOCK, BUFF BY +2", _2001 = "wHEN HIT BY A|MELEE WEAPON,|DEAL 4 DAMAGE|TO THE ATTACKER", _2002 = "aFTER YOU HEAL,|IF YOU hp IS EQUAL|TO YOUR mAX hp,|SHIELD 4 POINTS", _2003 = "wHEN HIT BY A|RANGED WEAPON,|SHIELD " .. d.v // 2, _2501 = "uSING A BOT ITEM|CHARGES ANOTHER|FOR 0.5 SECONDS.|rEQUIERES 3 BOTS", _2502 = "uSING A BOT ITEM|HEALS YOU 4 hp.|rEQUIERES 2 BOTS", _3001 = "aTTACKING WITH|A MELEE WEAPON,|BUFFS THIS BY +" .. d.level, _3002 = "aTTACKING WITH|A MELEE WEAPON,|BUFFS THIS BY +1", _4000 = "wHEN DESTROYED,|GAIN 35 mAX hp"}
  local d = dply_lines["_" .. d.trig] or "ERROR 1:|DESCRIPTION|NOT FOUND"
  return split(d, "|")
end

function _init()
  cartdata "loki-fromrust"
  toggle_joystick()
  poke(24405, 0)
  poke(22016, unpack(split "4,8,7,0,0,1,0,0,0,0,0,0,0,0,0,0,7,0,0,97,0,0,7,7,0,0,0,0,0,0,0,0,16,0,0,0,96,7,38,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,32,0,0,0,0,32,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,2,4,0,0,0,0,0,4,0,0,0,0,5,5,0,0,0,0,0,0,2,5,2,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,1,0,0,0,0,5,0,0,0,0,0,0,5,7,5,7,5,0,0,0,2,6,3,6,3,2,0,0,5,4,2,1,5,0,0,0,6,5,2,5,11,0,0,0,1,1,0,0,0,0,0,0,2,1,1,1,2,0,0,0,1,2,2,2,1,0,0,0,0,5,2,2,5,0,0,0,0,0,2,7,2,0,0,0,0,0,0,0,2,1,0,0,0,0,0,7,0,0,0,0,0,0,0,0,1,0,0,0,4,2,2,2,1,0,0,0,0,7,5,5,7,0,0,0,0,3,2,2,7,0,0,0,0,7,4,3,7,0,0,0,0,7,6,4,7,0,0,0,0,5,5,7,4,0,0,0,0,7,1,6,7,0,0,0,0,1,7,5,7,0,0,0,0,7,4,2,2,0,0,0,0,6,7,5,7,0,0,0,0,7,5,7,4,0,0,0,0,2,0,2,0,0,0,0,0,2,0,2,1,0,0,0,4,2,1,2,4,0,0,0,0,7,0,7,0,0,0,0,1,2,4,2,1,0,0,0,0,7,6,0,2,0,0,0,0,2,5,1,6,0,0,0,0,0,6,5,11,0,0,0,0,1,3,5,3,0,0,0,0,0,6,1,7,0,0,0,0,4,6,5,6,0,0,0,0,0,7,3,6,0,0,0,0,4,2,7,2,0,0,0,0,0,6,5,6,1,0,0,0,1,3,5,5,0,0,0,0,1,0,1,1,0,0,0,0,2,0,2,2,1,0,0,0,1,5,3,5,0,0,0,0,1,1,1,1,0,0,0,0,0,15,21,21,0,0,0,0,0,3,5,5,0,0,0,0,0,6,5,3,0,0,0,0,0,3,5,3,1,0,0,0,0,6,5,6,4,0,0,0,0,5,3,1,0,0,0,0,0,6,3,6,1,0,0,0,2,7,2,2,0,0,0,0,0,5,5,6,0,0,0,0,0,5,5,2,0,0,0,0,0,21,21,10,0,0,0,0,0,5,2,5,0,0,0,0,0,5,5,6,1,0,0,0,0,7,6,3,4,0,0,3,1,1,1,3,0,0,0,0,1,2,2,4,0,0,0,3,2,2,2,3,0,0,0,2,5,0,0,0,0,0,0,0,0,0,0,7,0,0,0,2,4,0,0,0,0,0,0,0,6,5,7,5,0,0,0,0,3,7,5,7,0,0,0,0,6,1,1,7,0,0,0,0,3,5,5,7,0,0,0,0,7,1,3,7,0,0,0,0,7,1,3,1,0,0,0,0,6,1,5,7,0,0,0,0,5,5,7,5,0,0,0,0,7,2,2,7,0,0,0,0,7,4,4,3,0,0,0,0,5,5,3,5,0,0,0,0,1,1,1,7,0,0,0,0,17,27,21,17,0,0,0,0,9,11,13,9,0,0,0,0,6,5,5,3,0,0,0,0,3,5,7,1,0,0,0,0,6,5,5,3,4,0,0,0,3,5,3,5,0,0,0,0,6,3,4,3,0,0,0,0,7,2,2,2,0,0,0,0,5,5,5,6,0,0,0,0,5,5,5,2,0,0,0,0,17,21,27,17,0,0,0,0,9,10,5,9,0,0,0,0,5,5,6,3,0,0,0,0,7,4,2,7,0,0,0,6,2,1,2,6,0,0,0,1,1,0,1,1,0,0,0,3,2,4,2,3,0,0,0,0,0,5,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,99,99,119,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,103,99,103,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,99,107,99,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,115,99,115,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,119,99,99,62,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,62,107,119,107,62,0,0,0"))
  poke(24408, 129)
  memcpy(40960, 0, 8192)
end

function _update60()
  if not scanned then
    init_image_banks()
    init_mouse()
    init_textdraw()
    init_menu()
    toggle_joystick()
  else
    update_menu()
    update_load()
  end
end

function _draw()
  cls()
  draw_menu()
end

function start_load()
  if not loading then
    loading = 0
    music(-1, 1200)
  end
end

function update_load()
  if loading then
    loading = loading + (1)
    if loading == 180 then
      load(cartname)
    end
  end
end

function toggle_joystick()
  if joystick == nil then
    joystick = dget(25) == 1
  else
    joystick = not joystick
  end
  dset(25, tonum(joystick))
  menuitem(1, "joystick:" .. (joystick and "on" or "off"), toggle_joystick)
end

function color_management(d)
  for d = 0, 15 do
    pal(d, d, 1)
  end
  pal(10, -15, 1)
  if d == 0 then
    pal(4, -2, 1)
    pal(14, -1, 1)
    pal(3, -13, 1)
  elseif d == 1 then
    pal(5, -1, 1)
    pal(4, -11, 1)
    pal(3, -16, 1)
    pal(2, 8, 1)
    pal(1, -11, 1)
  end
end

function dclr(d)
  local d, n, E = unpack(split(d, "|"))
  d, n = split(d), split(n)
  local c = E and {} or _ENV
  for E = 1, #d do
    c[d[E]] = pars(n[E])
  end
  if E then
    if E == "out" then
      return c
    end
    _ENV[E] = c
  end
end

function pars(d)
  if d == "{}" then
    return {}
  end
  if d == "nil" then
    return nil
  end
  return d ~= "false" and d
end

function add_(d, E)
  local E = dclr(E .. "|out")
  for E, n in pairs(E) do
    d[E] = n
  end
end

function lerp(n, d, E)
  local E = (1 - E) * n + E * d
  return abs(E - d) < .1 and d or E
end

function toggle_joystick()
  joystick = joystick == nil and dget(25) == 1 or not joystick
  dset(25, tonum(joystick))
  menuitem(1, "joystick:" .. (joystick and "on" or "off"), toggle_joystick)
end

function init_mouse()
  poke(24365, 1)
  dclr "mx,my,m_xo,m_yo,m_lx,m_ly,m_grab,mlp,mlwp,mrp,mrwp,mdirx,mdiry,m_hover_t|64,64,0,0,0,0,false,false,false,false,false,64,64,0"
end

function ml_down()
  return mlp
end

function ml_click()
  return mlp and not mlwp
end

function ml_release()
  return mlwp and not mlp
end

function update_mouse()
  m_lastx, m_lasty = mx, my
  if joystick then
    mdirx = mdirx + (tonum(btn(1)) - tonum(btn(0)))
    mdiry = mdiry + (tonum(btn(3)) - tonum(btn(2)))
    mx, my = mdirx, mdiry + camy
    mlwp, mlp = mlp, btn(5)
  else
    mx, my = mid(0, stat "32", 128), mid(0, stat "33", 128) + flr(camy)
    mlwp, mlp = mlp, stat "34" & 1 ~= 0
  end
  m_hover, m_lasthover = false, m_hover_targ
  foreach(items, check_hover)
  if not m_hover then
    m_hover_targ = nil
  end
  if m_hover and m_hover_targ == m_lasthover then
    m_hover_t = min(m_hover_t + 1, 35)
  else
    m_hover_t = 0
  end
end

function check_hover(d)
  if m_inside(d) then
    m_hover = true
    m_hover_targ = d
  end
end

function m_inside(d)
  return mx >= d.x and mx <= d.x + d.w * 8 - 1 and my >= d.y and my <= d.y + d.h * 8 - 1
end

function m_wasinside(d)
  return m_lastx >= d.x and m_lastx <= d.x + d.w * 8 - 1 and m_lasty >= d.y and m_lasty <= d.y + d.h * 8 - 1
end

function draw_mouse()
  pal(1, 10)
  local d = 1
  if m_hover then
    d = 2
  end
  spr(d, mx + 0, my)
  pal(1, 1)
end

function init_image_banks()
  scanned = false
  timer = 0
  items_1 = "&129&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&172&46&30&7d&62&d&15&d67&12&d677&28&628&18&16c1&9&1d&29&67&13&d67&12&46771&12&1&14&7282&16&16c1767&8&d1&29&d7&12&d67&12&d777&1&1&11&7cd6&11&7282&16&6c17dc7&10&d&2&16777d&2&76&1&6&14&d67&11&d67&12&4677&1&1d&10&dcd67c&8&17682&15&dd17dcd7&11&1d&1&1d7776d17777&13&d677&10&dd7&12&467711d&10&d1&1&67c&8&1d6d&15&dd1&2&cd767&10&1dd1d1666d1776777&10&d6777&10&d67&12&6777d&12&d1&2&dc&8&1112&14&dd1&4&767&12&66666d111dddd&1&676&8&1d677&11&1d7&15&d1&12&d1&3&6&8&11&1&2&14&d1&5&67&14&777776&3&1777677&8&111d&12&111&15&d1&12&d1&13&1&17&1&23&7777&1&1&2&1&1&777776&6&11&14&11&16&d1&12&d1&62&11&2&6&1&67&8&1&15&1&16&d1&126&1&93&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&131&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&3&2&27&2&3&2&11&2&94&1d6&44&2&80&1d6&43&292&13&dd&57&d1&5&11d&2&11d6171&34&978&10&2&1&d&2&d&7&776167767776&3&9&13&67&17&1d1&2&6777d1d1d67d7d676&31&189&10&298&3&d&6&77616777676&4&28&9&761ddd12898989&9&11d16777d16771&18&6777661166&10&1d2&10&88892&2&d&6&776167&3&7767776&9&7616777d128282&11&16617761d7712828282&11&77667ddd1&11&d11&10&89782&3&d&7&761727772&16&7616777711&14&6771677d1dd289898982&10&1111111&12&11d&10&28798&3&d&10&112888211&16&11d1&2&d6666d&10&67716761d7712828282&10&116d&2&d7&11&11&11&29888&16&1888881&16&11d&4&11111&12&671dd7d16771&16&16&4&d6&10&11&13&892&18&28882&18&1d&26&d&1&11d1d67d7d676&9&1&4&d6&9&11&15&2&19&82228&52&11d6171&16&1&10&1&36&28882&212&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&3&2&27&2&3&2&11&2&131&2&11&2&3&2&19&2&3&2&19&2&3&2&11&2&3&2&11&2&3&2&3&d&7&2&3&3&11&3&102&67674242&6&666db3b3b1&104&d11664&10&d&1&13331&54&7776&48&1d&1&d&12&dd1&1&111&52&66776&21&d&15&d&9&1dd&19&11&26&617171677767d&12&11111167&16&d6d1d&10&d71d1d&8&1d&20&1&6&67716dd777776&7&d6d6d6d777767d&9&67717167771777d&11&d776&1&1&9&611c1&1&1&5&2&11&2&3&3&11&3&3&77611616d6d6&8&11dd7d77ddd7&11&776d6111111666d&10&d1d7d&10&d1c717&39&6&1&1dd&2&1111&8&11d&3&d1d666d&11&6&1&111166771111&10&d7d1d&11&71cc1d&7&2&2&7&8&2&3&2&2&6&8&2&5&1d&15&11&6&1111&13&1dd&1&111111&1&d&11&677d&12&1c116&10&676777776&7&67766767d&8&1&16&1&22&1dd&3&d666&2&6&12&6d&14&17d&11&d11666671&7&d1d77dd7&49&1d&10&d&43&1d&1&dddd&9&11dd66d&50&1&10&1&42&1dd&13&11d&1&111&105&1d&14&11&12&2&11&2&3&2&19&2&3&2&19&2&3&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&115&66666&3&66666&3&3&11&3&3&3&11&3&3&3&11&3&3&3&11&3&3&2&19&2&3&2&19&2&2&6&5&6&1&6&5&6&36&167616761&68&6&5&6&1&6&2&8826&4&1671&1&16761&7&d6&3&6d&9&1dd1dd1&8&72&5&27&52&6&1&676&1&6&1&6&2&8826&3&16&2&6&1&16761&6&d1761671d&7&167616761&6&77d6d2d6d77&8&77776&22&1&9&1&5&61d6d16&1&6828826&3&17&2&73&1&333&6&d171d1d171d&6&1d13b31d1&6&d727717727d&7&677776&21&6167766d7d7d7&4&6211126&1&682dd16&4&1677636761&5&171d616d171&5&1711d1d1171&5&16461716461&9&111&11&6&6&6776761767dc1c1c&5&6288826&1&682f946&4&1367763761&5&1dd67&1&76dd1&4&1713d171d3171&5&d21dc712d&6&6771666677777676767&6&76767616&13&6888886&1&6dd8826&3&1673677631&7&d6719176d&5&161b13b71b161&6&161d161&7&7761dd1ddd666&5&6&6&67&1&11111d7dc1c1c&5&6288826&1&6f98826&3&1676367761&6&d&1&6&1&979&1&6&1&d&4&1713d131d3171&7&76167&8&6&2&16&2&677&15&6&1&1d61&1&d666d7d7d7&4&6822286&1&6828826&4&333&1&37&2&71&5&1d1189811d1&5&1d11d1d11d1&8&17771&10&16&3&167&16&1d6&3&67776&9&6288826&1&682dd16&3&16761&1&6&2&61&5&d17&1&181&1&71d&5&16763b36761&8&46764&16&11&16&1d1&3&d666d&9&6122216&1&682f946&3&16761&1&1761&7&6d71&1&17d6&7&1dd111dd1&8&2d111d2&34&1&5&111&10&6&1&111&1&6&1&6dd1116&20&61d777d16&6&16761&1&16761&67&6&5&6&1&6f94&2&6&22&1&3&1&8&16761&1&16761&68&66666&3&66666&3&3&11&3&3&3&11&3&3&3&11&3&3&3&11&3&3&2&19&2&3&2&19&2&99&6d&1&d6&3&66666&3&6666666666666&3&6666666666666&3&d&11&d&3&d&11&d&3&d&11&d&3&d&2&1&5&1&2&d&3&d&11&d&2&6&1&1d1&1&6&1&6&1&111&1&6&1&6&3&11&1&11&1&11&2&6&1&6&1&11&1&11d11&1&11&1&6&22&c777c&10&1777771&8&d1c1d1c1d&20&d11c11d&1&6167616&1&6&2&167167167&2&6&1&616d1dd7dd1d616&6&777&10&c717777717c&6&167777761&6&7c1c676c1c7&5&1cd&1&c77&1&dc1&4&dc7cd&2&61d1d16&1&6&1&11771771771&1&6&1&61761c676c16716&5&d7664&9&77d17771d77&6&1d66766d1&6&77c16761c77&5&1c1c1c7c1c1&3&d11c11d&1&6&1&171&1&6&1&6&1&11d61d61d61&1&6&1&6161d6c7c6d1616&5&674dd4&8&c71c111c17c&5&1ddd&3&ddd1&5&c7d&1&ddd&1&d7c&6&d1d11cd1d&4&6&1&1d1&1&6&1&613b716&1&6&3&11&1&11&1&11&2&6&1&6&1&1&1&1111111&1&1&1&6&5&d7411d&8&1c1dcccd1c1&6&17&2&7&2&71&6&1dc16761cd1&8&1ddd1&7&6d&1&d6&2&6&1&131&1&6&2&6666666666666&3&6666666666666&7&661c17&7&c1dc111cd1c&6&16&1&1c7&1&61&5&7c1cd676dc1c7&3&d&11&d&10&61d1d16&36&11d71c17&7&77177777177&5&1d7&2&1&2&7d1&4&77c1d676d1c77&26&6167616&2&6666666666666&3&6666666666666&5&dd1761c7&7&c711777117c&6&1dd&3&dd1&5&c7d&1&16761&1&d7c&3&2&19&2&2&6c1d1c6&1&6&13&6&1&6&2&111111111&2&6&7&d6d167&6&1cdc111cdc1&6&167777761&6&1dc&1&ddd&1&cd1&9&6&11&6&5&67c1c76&1&6&3&f4ffff&4&6&1&6&1&17677677671&1&6&8&d6d67&6&771dcccd177&5&1d&1&d676d&1&d1&5&7c1&1&676&1&1c7&5&767766dd677777777d6&3&6c7d7c6&1&6&3&9499999&3&6&1&616776777677616&8&4d677&6&c71c111c17c&6&167111761&6&77c16761c77&5&77661166d7d7d7d7d&5&6&1&c1c&1&6&1&6&3&41444911&2&6&1&6&1&11dd111dd11&1&6&9&477&7&1cd77777dc1&7&d67776d&7&c7d&1&d6d&1&d7c&5&76&1&1dd&2&1d6d6d6d6&5&6&5&6&1&6&4&111111&3&6&1&6&1&1d11&3&11d1&1&6&22&17771&25&c&2&1d1&2&c&9&1d&5&111&1&111&6&66666&3&6666666666666&3&6666666666666&3&d&11&d&3&d&11&d&3&d&11&d&3&d&11&d&3&2&4&1&14&2&139&6666666666666&3&66666&3&66666&3&2&11&2&3&2&11&2&3&d&11&d&3&2&11&2&3&d&2&1c1&1&1c1&2&d&3&3&11&3&2&6&13&6&1&6&5&6&1&6&2&1&2&6&38&d&3&d&25&1c71c17c1&20&6&1&17&1&d777d&1&71&1&6&1&6&1&176&1&6&1&6&2&d&2&6&6&176&19&d&8&16&3&61&16&d7&6&c71c7c17c&20&6&1&16167776161&1&6&1&6&1&677d6&1&6&1&161&1&6&6&1676&17&d6d&7&c7&1&1&1&7c&15&67c&6&717c1c717&7&771&3&177&4&6&2&d1d676d1d&2&6&1&6&1&d7616&1&6&1&147&1&6&7&d611&15&167c&6&1671c1761&13&67c&6&117c7c7c711&6&d7d&3&d7d&4&6&4&1ddd1&4&6&1&6&1&16d&1&6&1&6&2&6d&1&6&8&d17&14&d67c&7&c7c1c1c7c&12&67c&7&171c1c1c171&5&67d17771d76&4&6666666666666&2&6&2&d&2&6&1&6&1&7d&2&6&8&1676&12&167c&8&1dd616dd1&11&67c&8&c1c17771c1c&5&dd&1&67d76&1&dd&19&6d76&2&6&1&6&1&d41&1&6&8&d676&11&d67c&9&177767771&8&d&1&67c&9&717c777c717&7&17d1d71&6&6666666666666&2&6d77d&1&6&1&6&1&d71&1&6&8&1d76&10&167c&10&1d67776d1&8&c67c&10&c1c17771c1c&7&1d171d1&5&6&13&6&1&61671&1&6&1&6&2&d7&1&6&8&1111&9&11dc&11&c1d666d1c&8&d7d&11&171c1c1c171&8&17671&6&6&1&16146764161&1&6&1&6&1&1d&2&6&1&6&2&14&1&6&7&1d671&8&11&1&6&12&1c6d1d6c1&7&11d&12&117c7c7c711&8&16d61&6&6&1&242d777d242&1&6&1&6&1&67d&1&6&1&6&2&7d&1&6&7&16761&7&11&16&dc1c1cd&7&11&15&717c1c717&9&d7&1&7d&6&6&3&4147414&3&6&1&6&1&776d6&1&6&1&1d1&1&6&6&1d67d&8&1&17&1d1c1d1&7&1&16&c71c7c17c&10&d&1&d&7&6&4&1&1&d&1&1&4&6&1&6&1&d7616&1&6&2&1&2&6&5&1d67d1&27&d&1&1&1&d&25&1c71c17c1&21&6666666666666&2&6&1&161&1&6&2&66666&3&2&11&2&3&2&11&2&3&d&3&1&3&1&3&d&3&2&11&2&3&d&2&1c1&1&1c1&2&d&3&3&11&3&18&61d&3&6&106&6666666666666&2&6676&2&6&2&66666&3&2&11&2&3&d&11&d&3&2&11&2&3&2&19&2&3&2&19&2&2&6&2&d11d6d11d&2&6&1&6677d&1&6&1&6&5&6&97&6&1&16d67776d61&1&6&1&6d671&1&6&1&6f4ff&1&6&20&82&5&82&35&776&30&6&1&28288888282&1&6&1&61d1&2&6&1&69499f6&19&18216761821&13&76&17&7776&1&6&23&28&4&6&1&16d67776d61&1&6&1&6&1&1&3&6&1&6414916&19&1dd17771dd1&11&776&1&6&14&777d676&22&289&5&6&2&d11d6d11d&2&6&1&6&5&6&1&6&1&11116&2&67761d6777776&5&f4&1&d6d&1&f4&10&777d76&13&777d6d111&20&2889&7&6666666666666&3&66666&3&66666&3&776761dcdcdc&4&d&11&d&6&6776d76&1&6&9&7d17d6d111&20&2889&41&6&2&111161616&22&d76d77dd6&9&661d6d111&19&d2889&11&6d&1&d6&3&66666&3&66666&3&66666&5&1dd&11&2&3&7&7&2&5&7d776611&10&611dd11&20&d689&12&6&2&d&2&6&1&6&5&6&1&6&5&6&1&6&5&6&4&1d&15&6d7d7776d&6&d76d11&13&dd11dd&18&1167&14&d&1&287&1&d&1&6&1&177&1&6&1&6&5&6&1&61&3&16&5&1&14&d1d66ddd6&8&11111&13&771111&16&11&2&7&16&1288d&2&6&1&d82&1&6&1&6&2&4&2&6&1&661&1&166&20&161&1&d666d&7&67d1d1d&11&776d1d1d&14&6&3&7&16&d&1&d22&1&d&1&61628&1&6&1&6&2&4&2&6&1&6761676&19&16d&13&6761d1d1&11&d661d1d1&35&6&2&1&2&7&1&616d1&1&6&1&6&1&494&1&6&1&6671766&20&1d1&75&6d&1&d6&2&6&1&171&1&6&1&6&1&494&1&6&1&6761676&2&2&11&2&3&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&10&6&2&6&2&6&1&6&1&494&1&6&1&6d717d6&98&66666&2&6&1&1d&2&6&1&6&1&494&1&6&1&61d1d16&2&d&11&d&3&d&11&d&3&3&11&3&3&2&11&2&3&2&27&2&2&6&5&6&1&6&1&1d&2&6&1&649f946&1&6761676&3&11&7&11&22&76167&15&76167&36&6&1&177&1&6&1&6&1&141&1&6&1&649f946&1&6d111d6&3&761&1&767&1&167&7&76167&9&671b176&13&6718176&20&d111d17d&7&616d116&1&6&1&161&1&6&1&649f946&1&613b316&3&6771dcd1776&5&d1d1c1d1d&7&d61316d&13&7612167&19&d11211d17d&6&61d6116&1&6&2&71&1&6&1&649f946&1&61b7b16&3&d6d16c61d6d&4&c7c11c11c7c&6&1dd1dd1&13&1761671&19&61287161717&5&6&1&1d116&1&6&2&61&1&6&1&649f946&1&613b316&3&1d1&1&d1d&1&1d1&4&c77cd1dc77c&7&1&3&176167&10&d111d&19&761d82167d1d6&4&61761&1&6&1&6&2&d&2&6&1&649f946&1&6d111d6&2&d&11&d&4&c7d&3&d7c&12&671b176&9&6&3&6&11&176167&2&1761216717167&4&6678216&1&6&1&1d&2&6&1&649f946&1&6161616&40&d61316d&24&1d71761d1&1&1d111d1d117d&4&6d62816&1&6&1&171&1&6&1&649f946&1&6db1bd6&2&2&11&2&8&76167&12&1dd1dd1&5&76167&13&d76d171d6d611111111111d&4&61d1176&1&6&1&161&1&6&1&6111116&1&613&1&316&5&1761671&9&d1d1c1d1d&6&761671&3&1&5&6718176&11&117d61617d1761d61d7d16d1&4&6&1&116d6&1&6&1&171&1&6&1&649f946&1&6d1&1&1d6&5&7618167&8&c7c11c11c7c&4&671b176&9&7612167&11&6161d17d7167161d1d111d1&5&6&3&d16&1&6&2&d1&1&6&1&6111116&1&61&3&16&5&d71217d&8&c77cd1dc77c&4&d61316d&9&1761671&11&6d111&1&1d61d6161d616d1&7&6&3&1&1&6&1&6&2&1&2&6&1&649f946&1&61&3&16&5&1d&1&1&1&d1&9&c7d&3&d7c&5&1dd1dd1&10&d111d&12&1611&3&1d61d61611111&8&6&5&6&1&6&2&1&2&6&1&6&5&6&1&6&5&6&6&6&3&6&25&1&3&1&11&6&3&6&13&11&5&1d11d111d&12&66666&3&66666&3&66666&3&66666&3&2&11&2&3&d&11&d&3&3&11&3&3&2&11&2&3&2&27&2&34&"
  items_2 = "&97&66666&3&66666&3&6666666666666&3&2&11&2&3&2&11&2&3&2&11&2&3&2&11&2&11&2&7&d&9&d&1&2&2&6&1&ddd&1&6&1&6&5&6&1&6&13&6&20&7&54&6777617767667667667&3&6&1&676&1&6&1&6&5&6&1&6&13&6&8&7&12&d77177d7&46&67767177d7cc7cc7cc7&3&61d1d16&1&6&1&111&1&6&1&6&5&6776&4&6&7&67&12&1661dd&10&717&35&6&1&1dd11d6d11d11d11d&3&6d676d6&1&6149f16&1&6&4&616676&3&6&6&d7d&4&1&6&1d1d&12&628267&12&177777776&14&1d&2&16761&11&6711176&1&6166716&1&6&3&1d&1&7676&3&6&6&77&4&1&7&1d&14&d121d677&7&771d1d1d1d1&16&1&3&767&12&6d1c1d6&1&61d7716&1&6&3&1d&2&161&3&6&5&d7d&4&1&5&2&2&1&8&2&5&128211666&5&6771177777776&11&2&7&111&9&2&2&6&1&c7c&1&6&1&6&1&1dd&1&6&1&6&3&d7dd6d1&3&6&5&66&3&d1&24&d121d722dd&5&661d6d6d6d1&35&6d1c1d6&1&61d6716&1&6&2&16761d1&4&6&5&1d&3&66&6&2&3&6&3&d&3&2&5&628266771&7&1dd111111&36&6711176&1&61d7716&1&6&2&d76d1&6&6&4&1&4&d7d&9&77d77628&8&7176266dd&6&1d1&42&6d676d6&1&6&1&1d616&1&6&1&16761&7&6&4&1&4&77&9&7766d1&12&dd11dd1&8&11&42&61d1d16&1&6&2&1d&1&6&1&6&1&d761d&7&6&3&1&4&d7d&11&1d61212&10&dd11&54&6&1&676&1&6&1&6&2&11&1&6&1&6&1&1d1d1&7&6&8&76&11&1d&1&1d6d6&9&776ddd&53&6&1&ddd&1&6&1&6&5&6&1&6&1&d6d6d1&6&6&8&7&12&1d&2&111&9&77666ddd&53&66666&3&66666&2&6&2&d176d1&5&6&2&2&11&2&3&2&3&1&7&2&3&2&11&2&3&2&11&2&50&6&3&d676d1&4&6&98&66666&3&66666&2&6&4&d6&1&16d6&2&6&2&d&11&d&3&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&2&6&5&6&1&6&1&1&3&6&1&6&5&d1671&1&d&1&6&7&111&17&7&69&6&5&6&1&6171&2&6&1&6&6&6d671&2&6&6&d&3&d&15&467&68&6&5&6&1&67c1&2&6&1&6&7&676d1&1&6&5&d6&3&6d&14&67&1&7&14&d&35&1&16&6&1&8&1&8&1&6&1&66711&1&6&1&6&8&6d1&2&6&5&677&1&776&12&46777d&10&61&1&d&1&d&29&1&4&61&15&68&3&86&1&6d6d716&1&6&13&6&4&d&1&6d&1&d6d1&11&6777d&11&76d&12&6677677677777777&4&7&4&161777d66dd6d61&2&68&1&8&1&86&1&61d1c76&2&6666666666666&4&1d1d&3&2&1&d1&8&46777d&11&24761&6&677166776776dcccccc&6&6&2&161dd11117711711&3&68&3&86&1&6&2&1766&19&d&1&d&4&d1&1&d&8&6777d&11&298476&6&77611111111111111&8&61&1&77111677d77dd7d61&2&6&1&8&1&8&1&6&1&617d6d6&2&6666666666666&3&6&1&d&1&1&4&1d16&8&77d&10&674892&8&6&1&1dd&1&6666d6666667&8&ddddddd17116611611&3&6&5&6&1&67c1d16&1&6d&1&1&1&1&1&1&1&1&1&1&1&d6&2&11d1d1&2&1&1&d11&8&16&11&16742&10&1dd&2&1dddd11&13&6777777117d11dd1d61&2&6167616&1&66711&1&6&1&6&1&1b3b3b3b3b1&1&6&3&d1&1&2&3&1d1d&8&11&13&d67&11&1d1&3&1111&15&d666666d&13&61d6d16&1&6d61&2&6&1&61b7b7b7b7b7b16&3&2d2&6&d2&7&11&15&16&12&1&24&dddddd&14&6&1&1d1&1&6&1&61d1&2&6&1&6&1&1b3b3b3b3b1&1&6&4&1&6&11&7&11&75&6&5&6&1&6&1&1&3&6&1&6d&1&1&1&1&1&1&1&1&1&1&1&d6&5&2&4&2&9&1&77&66666&3&66666&3&6666666666666&3&d&11&d&3&2&11&2&3&2&11&2&3&2&19&2&3&2&19&2&12322&"
  rectfill(0, 0, 127, 127, 0)
  decompress(items_1, 0, 0, 128)
  memcpy(57344, 24576, 8192)
  decompress(items_2, 0, 0, 128)
  memcpy(49152, 24576, 8192)
  reload(0, 0, 8192)
  scanned = true
  poke(24405, 96)
end

function init_textdraw()
  index, _idx = {}, split("a,38,16|b,43,16|c,48,16|d,53,16|e,58,16|f,63,16|g,68,16|h,73,16|i,78,16|j,83,16|k,88,16|l,93,16|m,98,16|n,103,16|o,108,16|p,113,16|q,118,16|r,123,16|s,38,21|t,43,21|u,48,21|v,53,21|w,58,21|x,63,21|y,68,21|z,73,21|0,78,21|1,83,21|2,88,21|3,93,21|4,98,21|5,103,21|6,108,21|7,113,21|8,118,21|9,123,21| ,128,21", "|")
  for d in all(_idx) do
    local d = split(d)
    index[d[1] .. ""] = {d[2], d[3]}
  end
end

function draw_text(d, c, e)
  for E = 1, #d do
    for o, n in pairs(index) do
      if d[E] == o then
        sspr(n[1], n[2], 5, 5, c + (E - 1) * 6, e)
      end
    end
  end
end

function import_logo()
  ln_cmds = {}
  local d = split("42,1,44,8|39,2,44,8|36,3,44,8|33,4,43,8|31,5,43,8|31,6,43,8|31,7,42,8|30,8,42,8|30,9,42,8|30,10,41,8|29,11,41,8|27,12,29,7|29,12,41,8|24,13,29,7|29,13,40,8|21,14,28,7|28,14,40,8|18,15,28,7|28,15,40,8|18,16,28,7|28,16,39,8|18,17,27,7|27,17,39,8|17,18,27,7|27,18,39,8|17,19,27,7|27,19,38,8|17,20,26,7|26,20,38,8|16,21,26,7|26,21,38,8|16,22,26,7|26,22,37,8|16,23,25,7|25,23,37,8|16,24,25,7|25,24,37,8|15,25,25,7|25,25,36,8|15,26,24,7|24,26,36,8|14,27,24,7|24,27,36,8|14,28,24,7|24,28,35,8|57,28,59,8|14,29,23,7|23,29,35,8|54,29,59,8|13,30,23,7|23,30,35,8|51,30,59,8|13,31,23,7|23,31,34,8|48,31,59,8|13,32,22,7|22,32,34,8|45,32,58,8|12,33,22,7|22,33,34,8|42,33,58,8|12,34,22,7|22,34,33,8|39,34,58,8|12,35,21,7|21,35,33,8|36,35,57,8|11,36,21,7|21,36,57,8|11,37,21,7|21,37,57,8|11,38,20,7|20,38,56,8|61,38,63,7|10,39,20,7|20,39,56,8|58,39,63,7|10,40,20,7|20,40,56,8|56,40,63,7|10,41,19,7|19,41,56,8|56,41,63,7|9,42,19,7|19,42,56,8|56,42,62,7|9,43,19,7|19,43,56,8|56,43,62,7|9,44,18,7|18,44,55,8|55,44,62,7|8,45,18,7|18,45,55,8|55,45,61,7|8,46,18,7|18,46,40,8|40,46,41,7|41,46,55,8|55,46,61,7|8,47,17,7|17,47,37,8|37,47,41,7|41,47,54,8|54,47,61,7|7,48,17,7|17,48,34,8|34,48,41,7|41,48,54,8|54,48,60,7|7,49,17,7|17,49,31,8|31,49,40,7|40,49,54,8|54,49,60,7|7,50,16,7|16,50,28,8|28,50,40,7|40,50,53,8|53,50,60,7|6,51,16,7|16,51,25,8|25,51,40,7|40,51,53,8|53,51,57,7|6,52,16,7|16,52,22,8|22,52,39,7|39,52,53,8|53,52,54,7|6,53,16,7|16,53,19,8|19,53,39,7|39,53,51,8|5,54,39,7|39,54,51,8|5,55,38,7|38,55,51,8|5,56,38,7|38,56,50,8|4,57,37,7|37,57,50,8|4,58,37,7|37,58,50,8|4,59,33,7|37,59,49,8|3,60,30,7|37,60,49,8|3,61,27,7|36,61,49,8|3,62,24,7|36,62,48,8|2,63,21,7|36,63,48,8|2,64,18,7|35,64,48,8|2,65,15,7|35,65,47,8|1,66,12,7|35,66,47,8|1,67,9,7|34,67,47,8|1,68,6,7|34,68,46,8|1,69,3,7|34,69,46,8|33,70,46,8|33,71,45,8|33,72,45,8|32,73,45,8|32,74,44,8|32,75,44,8|31,76,44,8|31,77,44,8|31,78,41,8|30,79,38,8|30,80,35,8|30,81,32,8", "|")
  for d in all(d) do
    add(ln_cmds, dclr("x,y,w,c|" .. d .. "|out"))
  end
end

function print_logo(E, n, c)
  for d = 1, #ln_cmds do
    local d, e = ln_cmds[d], t() + d / #ln_cmds * 2
    line(E + d.x + sin(e + rnd(4)) * c, n + d.y, E + d.w + sin(e + rnd(4)) * c, n + d.y, d.c)
  end
end

function decompress(E, e, o, c)
  local d, n = 1, ""
  while d <= #E do
    if E[d] == "&" then
      local c, e = 0, 0
      repeat
        c = c + (1)
      until E[d + c] == "&"
      e = tonum(sub(E, d + 1, d + c - 1))
      for d = 1, e do
        n = n .. ("0")
      end
      d = d + (c + 1)
    else
      n = n .. (E[d])
      d = d + (1)
    end
  end
  for d = 0, #n - 1 do
    pset(e + d % c - 1, o + d // c, tonum(n[d], 1))
  end
end

function init_menu()
  color_management(1)
  menu_state, camy = "intro", 0
  init_intro()
  itemlib = split(item_data, "\n")
  init_items()
  updates = {intro = update_intro, select = update_select, how = update_how, score = update_score, credits = update_credits, extra = update_extra}
  draws = {intro = draw_intro, select = draw_select, how = draw_how, score = draw_score, credits = draw_credits, extra = draw_extra}
  tabs = {start_load, init_score, init_how, init_credits, init_extra}
end

function update_menu()
  update_transition()
  update_mouse()
  updates[menu_state]()
end

function draw_menu()
  draws[menu_state]()
  draw_transition()
  draw_mouse()
end

function scene_transition()
  items = {}
  if switch_color then
    color_management(0)
  end
  if slct_index == 0 then
    init_select()
  else
    tabs[slct_index]()
  end
end

function init_transition(d)
  t_active = true
  t_timer = 0
  if d then
    t_limit = 81
  end
end

function update_transition()
  if t_active then
    t_timer = min(t_timer + 3, t_limit or 200)
    if t_timer == 81 then
      scene_transition()
    end
    if t_timer == 200 then
      t_active = false
    end
  end
end

function draw_transition()
  if t_active then
    fillp(0)
    local d = t_timer * 2
    rectfill(0, -256 + d, 127, -1 + d, 0)
    fillp()
    rectfill(0, -160 + d, 127, -32 + d)
    if loading then
      if loading > 30 then
        print("lOADING...", 92, 120, 7)
      end
    end
  end
end

function init_select()
  menu_state = "select"
  init_proc()
  if long_intro then
    music(8, 2000)
    long_intro = false
    a = -.3
  end
end

function update_select()
  update_prog()
  if not t_active then
    for d = 1, 5 do
      if m_lasty ~= my then
        local d = {x = 24, y = 72 + d * 8, w = 8, h = 1}
        if m_inside(d) and not m_wasinside(d) then
          sfx(0)
        end
      end
    end
    if ml_click() then
      slct_index = 0
      for d = 1, 5 do
        local E = {x = 24, y = 72 + d * 8, w = 8, h = 1}
        if m_inside(E) then
          slct_index = d
        end
      end
      if slct_index > 0 then
        local d = false
        if slct_index == 1 then
          d = true
          sfx(7)
        else
          sfx(5)
        end
        init_transition(d)
      end
    end
  end
end

function draw_select()
  draw_proc()
  camera()
  local E = split "start run,view last run,how to play,credits,support me"
  for d = 1, #E do
    if a >= d * .1 then
      local n = 0
      pal(7, 13)
      local c = {x = 24, y = 72 + d * 8, w = 8, h = 1}
      if m_inside(c) then
        pal(7, 7)
        n = n + (4)
      end
      draw_text(E[d], 24 - n, 72 + d * 8)
      pal(7, 7)
    end
  end
end

function init_proc()
  q, n, s, w, a, p = 40, 15, 64, 0, -.2, 0
end

function update_prog()
  a = min(a + .005, 1)
  p = p + (.0001)
  if a > 0 then
    w = lerp(0, 15, 1 + 3 * (a - 1) ^ 3 + 2 * (a - 1) ^ 2)
  end
  q = lerp(q, 40 + sin(t() * .01) * 4, .01)
end

function draw_proc()
  if a < 0 then
    return
  end
  camera(-(16 - w) * 4, -(16 - w) * 4)
  for d = 1, flr(q) do
    x1 = cos(d / q + p) * s % 8 * w
    y1 = sin(d / q + p) * s % 8 * w
    for d = d + 1, flr(q) do
      x2 = cos(d / q + p) * s % 8 * w
      y2 = sin(d / q + p) * s % 8 * w
      local d = (x1 - x2) ^ 2 + (y1 - y2) ^ 2
      if d < 800 then
        line(x1, y1, x2, y2, 1)
      end
      if rnd() > .6 and d < 1000 then
        fillp(0)
        line(x1, y1, x2, y2, 1)
        fillp()
      end
    end
    pset(x1, y1, 12)
  end
end

function init_score()
  menu_state, scr_count = "score", 0
  init_items_from_memory()
  color_management(0)
end

function update_score()
  if not t_active then
    local d = false
    if ml_click() then
      d = m_inside {x = 60, y = 120, w = 1, h = 1}
    end
    if btnp(3) or d then
      slct_index = 0
      init_transition()
      sfx(5)
    end
  end
end

function draw_score()
  rectfill(15, 0, 17, 113 + sin(t() + .1) * 2.1, 1)
  rectfill(11, 0, 13, 109 + sin(t() + .2) * 2.1)
  rectfill(7, 0, 9, 105 + sin(t() + .3) * 2.1)
  rectfill(109, 86 + sin(t() + .5) * 2.1, 111, 127)
  rectfill(113, 90 + sin(t() + .6) * 2.1, 115, 127)
  rectfill(117, 94 + sin(t() + .7) * 2.1, 119, 127)
  spr(16, 60, 120 + abs(sin(t() * .3) * 2.1))
  local d = 0
  for E = 30, 26, -1 do
    local E = tostr(dget(E))
    print(E, 112 - #E * 4, 34 + d, 6)
    d = d + (7)
  end
  rectfill(0, 22, 127, 30, 13)
  draw_text("run ended", 8, 24)
  cursor(22, 34, 6)
  print "-total events :\n-items looted :\n-items activated :\n-damage dealt :\n-damage taken :"
  draw_text("inventory", 22, 78)
  rect(22, 86, 104, 113, 1)
  batch_itemlists()
  if not t_active then
    draw_items()
  else
    if t_timer < 80 then
      draw_items()
    end
  end
  draw_displaybox()
end

function init_items()
  dclr "items,uid|{},0"
  i_colors = split("8,2|11,3|8,2|12,13|6,13", "|")
  act_txt = split("dEALS , DAMAGE|hEAL , HITPOINTS|iNFLICT , IGNITE|sHIELD , POINTS| , ", "|")
  if dget(31) == 1 then
    init_transition()
    t_timer = 82
    init_score()
    music(8, 2000)
    dset(31, 0)
  end
end

function init_items_from_memory()
  for d = 32, 63 do
    local d = dget(d)
    if d > 0 then
      local d = split(tostr(d, 2), "")
      if #d < 5 then
        return
      end
      local n, E, d, c = deli(d, 1), deli(d, 1), deli(d, 1), tostr(d[1] .. d[2])
      local d = get_item(tonum(d - 1 .. c))
      d.y = 80 + n * 8
      d.x = 24 + E * 8
      d.tm = -E * 6
      d.shake = 0
      add(items, d)
    end
  end
end

function get_item(d)
  local E = d
  if E > 100 then
    d = d % 100
    E = (E - d) // 100
  else
    E = 0
  end
  local d = itemlib[d]
  local d = dclr("id,name,name2,type,cd,v,add,trig,sprn,w,h,tagdata|" .. d .. "|out")
  add_(d, "x,y,t,shake,p,bonus,level,tm|0,0,0,0,false,0,1,0")
  d.typ = get_ntype(d)
  d.tags = split(d.tagdata, "&")
  d.iv, d.tcd = d.v, d.cd
  d.uid = uid
  for E = 1, E do
    upgrade(d)
  end
  uid = uid + (1)
  return d
end

function batch_itemlists()
  ilist1, ilist2 = {}, {}
  foreach(items, batch_assign)
end

function batch_assign(d)
  add(d.id <= 70 and ilist1 or ilist2, d)
end

function draw_items()
  batch_itemlists()
  memcpy(0, 57344, 8192)
  foreach(ilist1, draw_item)
  memcpy(0, 49152, 8192)
  foreach(ilist2, draw_item)
  memcpy(0, 40960, 8192)
  camera(0, 0)
end

function draw_item(d)
  if d == nil then
    return
  end
  if d.y > camy + 128 then
    return
  end
  d.tm = min(d.tm + 1, 12)
  if d.tm < 0 then
    return
  end
  if d.tm == 6 then
    sfx(62)
  end
  local c, e, E = d.x + cos(rnd()) * d.shake * .1, d.y + sin(rnd()) * d.shake * .1, d.w * 8 - 2
  local n = mid(0, E - ceil(d.tm / 12 * E), E)
  camera(-c - n // 2, -e + camy)
  local E, n, e, c = E - n, d.h * 8 - 1, get_colors(d)
  if d.cd == 0 then
    rectfill(0, 0, E, n, 0)
    spr(d.sprn, 0, 0, d.w * d.tm / 12, d.h)
    return
  end
  rectfill(1, 0, E - 1, n, c)
  rectfill(0, 1, E, n - 1)
  rectfill(0, 1, E, 5, e)
  line(1, 0, E - 1, 0)
  if d.tm < 6 then
    return
  end
  rectfill(1, 6, E - 1, n - 3, 0)
  if d.tm < 12 then
    return
  end
  for d = 1, d.level - 1 do
    line(E - d * 2, 0, E - d * 2, 3, c)
  end
  print(d.v, 2, 0, d.typ == 3 and 9 or 7)
  spr(d.sprn, 0, 5, d.w, d.h - 1)
  if how_page == 2 then
    line(2, n - 1, E - 2, n - 1, 1)
    local E = E - 4
    E = E * (d.t / d.tcd)
    if E > .5 then
      line(2, n - 1, 2 + E, n - 1, 7)
    end
  end
  camera(0, camy)
end

function get_colors(d)
  return unpack(split(i_colors[d.typ]))
end

function get_ntype(d)
  local E = dclr "atk,def,flm,shl,buf|1,2,3,4,5|out"
  return E[d.type]
end

function upgrade(d, E)
  d.iv = d.iv + (d.add)
  d.v = d.v + (d.add)
  d.level = d.level + (1)
  d.shake = 10
  del(items, E)
end

function draw_displaybox()
  if m_hover_t == 35 then
    local d = m_hover_targ
    local n, E, c, e = d.x + d.w * 8, d.y, d.w * 8, d.h * 8
    if n + 70 > 127 then
      n = n - (72)
      E = E + (e + 1)
      if E + 56 > 127 + camy then
        n = n - (c)
        E = E - (58)
        if E < 0 + camy then
          E = 0 + camy
        end
        if n < 0 then
          n = n + (72)
          E = E - (e + 1)
          if n + 70 > 127 then
            n = n - (70 - c + 2)
          end
          if E < 0 + camy then
            E = 0 + camy
          end
        end
      elseif n < 0 then
        n = 0
      end
    elseif E + 56 > 126 + camy then
      n = n - (c)
      E = E - (58)
      if E < 0 + camy then
        E = 0 + camy
        n = n + (c)
      end
    elseif E < 0 + camy then
      E = 0 + camy
    end
    local c, e = get_colors(d)
    camera(-n, -E + camy)
    color(e)
    rectfill(1, 0, 69, 56)
    rectfill(0, 1, 70, 55)
    rectfill(2, 1, 68, 55, 0)
    rectfill(1, 2, 69, 54)
    draw_text(d.name, 3, 3)
    draw_text(d.name2, 3, 9)
    color(c)
    rect(3, 16, 67, 17)
    if d.typ ~= 5 then
      local E = "" .. flr(d.tcd / 60 * 10) / 10
      spr(34, 63, 3)
      sspr(38, 27, 5, 5, 63, 3)
      print(E, 70 - #E * 4 - 1, 9, 7)
      local E = split(act_txt[d.typ])
      print(E[1] .. d.v .. E[2], 5, 20, 7)
    end
    if d.trig > 0 then
      local d, n = get_trigtxt(d), d.typ ~= 5 and 21 or 14
      for E = 1, #d do
        print(d[E], 5, n + E * 6, 7)
      end
    end
    line(5, 48, 66, 48, 13)
    local E = ""
    for d in all(d.tags) do
      E = E .. (d .. " ")
    end
    print(E, 5, 49)
    camera()
  end
end

function init_how()
  menu_state, how_page, how_utimer = "how", 1, 0
  init_page(how_page)
end

function update_how()
  update_prog()
  if ml_click() then
    if m_inside {x = 4, y = 109, w = 1, h = 1} then
      slct_index = 0
      init_transition()
      sfx(5)
    end
    if m_inside {x = 112, y = 109, w = 1, h = 1} then
      how_page = how_page % 7 + 1
      init_page(how_page)
      sfx(5)
    end
  end
  update_pages()
end

function draw_how()
  draw_proc()
  camera()
  if how_page == 5 then
    page_5_bg()
  end
  batch_itemlists()
  draw_items()
  _ENV["page_" .. how_page]()
  draw_displaybox()
  spr(33, 4, 109)
  spr(32, 112, 109)
  print(how_page .. "/7", 112, 7, 7)
end

function update_pages()
  if how_page == 2 then
    for d in all(items) do
      d.t = d.t + (1)
      if d.t == d.cd then
        d.t = 0
        d.shake = 10
        sfx(55 + d.typ)
      end
      d.shake = max(0, d.shake - 1)
    end
  end
  local d = how_utimer
  if how_page == 4 then
    how_utimer = how_utimer + (1)
    if d < 60 then
      return
    end
    if d < 120 then
      items[2].x = items[2].x + (.4)
      return
    end
    if d == 120 then
      upgrade(items[2], items[1])
      sfx(55)
    end
    if d < 160 then
      items[1].shake = max(0, items[1].shake - 1)
      return
    end
    if d < 350 then
      return
    end
    if d < 360 then
      items[1].y = items[1].y - (.5)
      items[1].tm = items[1].tm - (2)
    end
    if d == 360 then
      set_page4()
    end
  end
end

function init_page(d)
  items = {}
  if d == 1 then
    local d = get_item(11)
    d.x = 102
    d.y = 76
    items = {d}
  elseif d == 2 then
    local d = get_item(46)
    d.x, d.y = 16, 52
    local E = get_item(13)
    E.x, E.y = 40, 56
    local n = get_item(9)
    n.x, n.y = 64, 56
    local c = get_item(15)
    c.x, c.y = 88, 52
    items = {d, E, n, c}
  elseif d == 3 then
    local d = get_item(12)
    d.x, d.y = 88, 46
    items = {d}
  elseif d == 4 then
    set_page4()
  elseif d == 5 then
    local d = get_item(8)
    d.x, d.y = 24, 56
    local E = get_item(48)
    E.x, E.y = 88, 96
    items = {d, E}
  end
end

function set_page4()
  how_utimer = 0
  local d = get_item(53)
  d.x, d.y, d.tm = 104, 42, -10
  local E = get_item(53)
  E.x, E.y, E.tm = 80, 42, -10
  items = {d, E}
end

function page_1()
  local E, d = draw_text, print
  E("from rust to ash", 4, 8)
  d("BY lOKIsTRIKER", 4, 14, 6)
  local E = {"'fROM rUST TO aSH' IS A ROGUELIKE", "AUTO-BATTLER WITH INVENTORY", "MANAGEMENT MECHANICS.", "", "aS YOU PLAY, YOU WILL OBTAIN", "ITEMS THAT YOU CAN \xe1\xb6\x9c9EQUIP\xe1\xb6\x9c6,", "\xe1\xb6\x9c9STORE \xe1\xb6\x9c6OR \xe1\xb6\x9c9SCRAP\xe1\xb6\x9c6.", "", "\xe1\xb6\x9c6eQUIPPED ITEMS WILL BE", "USED DURING COMBAT.", "yOU CAN CHANGE AND", "MOVE YOUR EQUIPPED", "ITEMS OUTSIDE OF COMBAT."}
  for n = 1, #E do
    d(E[n], 4, 18 + n * 6)
  end
end

function page_2()
  local d, n = draw_text, print
  d("items", 4, 8)
  local d = {"tHERE ARE 4 ITEM TYPES:\xe1\xb6\x9c8weapon\xe1\xb6\x9c6,", "\xe1\xb6\x9cbheal\xe1\xb6\x9c6, \xe1\xb6\x9ccshield \xe1\xb6\x9c6AND \xe1\xb6\x9c9flame\xe1\xb6\x9c6.", "aDDITIONALLY, THERE ARE ITEMS", "THAT BUFF YOU OR BUFF ITEMS", "YOU HAVE EQUIPPED.", "", "", "", "", "", "", "yOU CAN FIND THE CHARGE TIME", "OF AN ITEM ON THE TOP RIGHT", "OF ITS \xe1\xb6\x9c9DESCRIPTION\xe1\xb6\x9c6, WHICH YOU", "CAN SEE BY \xe1\xb6\x9c9HOVERING\xe1\xb6\x9c6 OVER IT."}
  for E = 1, #d do
    n(d[E], 4, 10 + E * 6, 6)
  end
end

function page_3()
  local d, n = draw_text, print
  d("tags", 4, 8)
  local d = {"tAGS ARE IDENTIFIERS THAT", "ITEMS POSSESS. tHEY ARE FOUND", "AT THE BOTTOM SECTION OF THEIR", "DESCRIPTION", "", "tHESE TAGS ALLOW", "ITEMS TO INTERACT", "WITH OTHERS THROUGH", "UNIQUE BUFFS.", "", "mOST TAGS DONT DO ANYTHING", "BY THEMSELVES, BUT THE TAG", "\xe1\xb6\x9ccshock \xe1\xb6\x9c6ALLOWS WEAPONS TO DEAL", "\xe1\xb6\x9c8DOUBLE DAMAGE \xe1\xb6\x9c6TO \xe1\xb6\x9ccSHIELDS \xe1\xb6\x9c6ON", "AN ENEMY."}
  for E = 1, #d do
    n(d[E], 4, 10 + E * 6, 6)
  end
end

function page_4()
  local d, E = draw_text, print
  d("upgrade", 4, 8)
  local n = {"fINDING A COPY OF AN ITEM, ALLOWS", "YOU TO DROP IT UNTO THE OTHER", "TO UPGRADE ITS \xe1\xb6\x9c9rANK\xe1\xb6\x9c6.", "iTEMS NEED TO BE OF", "THE \xe1\xb6\x9c8SAME rANK\xe1\xb6\x9c6 TO", "BE USED AS PART", "OF AN UPGRADE."}
  for d = 1, #n do
    E(n[d], 4, 10 + d * 6, 6)
  end
  d("scrap", 4, 62)
  local d = {"yOU CAN SCRAP ITEMS BY PRESSING", "THE \xe1\xb6\x9c9'TRASHCAN' \xe1\xb6\x9c6ICON ON THE BOTTOM", "RIGHT TO START SCRAPPING. hOLDING", "YOUR CLICK OVER AN ITEM WILL SCRAP", "IT. sCRAPPING ITEMS GIVE YOU", "\xe1\xb6\x9cbmax hp \xe1\xb6\x9c6EQUAL TO ITS \xe1\xb6\x9ccrANK TIMES 5\xe1\xb6\x9c6."}
  for n = 1, #d do
    E(d[n], 4, 64 + n * 6, 6)
  end
  if how_utimer > 190 and how_utimer < 350 then
    if how_utimer % 20 > 4 then
      line(116, 42, 116, 45, 7)
    end
  end
end

function page_5_bg()
  rectfill(0, 51, 127, 127, 0)
  line(0, 51, 127, 51, 1)
  map(0, 10, 0, 48, 16, 16)
  rect(22, 94, 105, 121, 1)
  spr(35, 3, 120, 1.75, 1)
end

function page_5()
  local d, n = draw_text, print
  d("storage", 4, 8)
  local d = {"oUTSIDE OF COMBAT, YOU CAN", "MOVE ITEMS FROM YOUR INVENTORY", "TO YOUR STORAGE BY PRESSING THE", "\xe1\xb6\x9c9'BACKPACK'\xe1\xb6\x9c6 ICON TO REVEAL IT."}
  for E = 1, #d do
    n(d[E], 4, 10 + E * 6, 6)
  end
end

function page_6()
  local d, n = draw_text, print
  d("encounters", 4, 8)
  local d = {"dURING YOUR RUNS, YOU WILL", "BE SHOWN ENCOUNTERS YOU GET TO", "SELECT FROM.tHERE ARE 3 TYPES OF", "ENCOUNTERS:", "", "\xe1\xb6\x9cbloot\xe1\xb6\x9c6: yOU ARE OFFERED A", "SELECTION OF ITEMS AND CHOOSE", "ONE TO TAKE.", "", "\xe1\xb6\x9ccupgrade\xe1\xb6\x9c6: yOU GET A PERMANENT", "UPGRADE TO YOUR CHARACTER.", "", "\xe1\xb6\x9c8combat\xe1\xb6\x9c6: yOU CHOOSE YOUR NEXT", "COMBAT ENCOUNTER, AFTER WHICH", "YOU GET A RANDOM ITEM."}
  for E = 1, #d do
    n(d[E], 4, 10 + E * 6, 6)
  end
end

function page_7()
  local d, E = draw_text, print
  d("combat", 4, 8)
  local n = {"dURING COMBAT, ITEMS WILL", "ACTIVATE AUTOMATICALLY. aFTER", "60 SECONDS, \xe1\xb6\x9c8overheat\xe1\xb6\x9c6 WILL START", "SLOWLY DAMAGING PLAYER & ENEMY.", "oNCE YOUR ENEMY REACHES 0 hp,", "YOU WIN, \xe1\xb6\x9ccGET A RANDOM ITEM\xe1\xb6\x9c6 AND", "MOVE TO SELECT A NEW ENCOUNTER"}
  for d = 1, #n do
    E(n[d], 4, 10 + d * 6, 6)
  end
  d("lives", 4, 62)
  local d = {"iF YOU REACH 0 hp, YOU WILL LOSE A", "\xe1\xb6\x9c8lIFE\xe1\xb6\x9c6 (FOUND RIGHT OF YOUR hp BAR)", "AND REGAIN \xe1\xb6\x9cb50% OF YOUR max hp\xe1\xb6\x9c6.", "iF YOUR hp REACHES 0 AND YOU", "HAVE 0 lIVES, \xe1\xb6\x9c8YOU ARE DEFEATED\xe1\xb6\x9c6."}
  for n = 1, #d do
    E(d[n], 4, 64 + n * 6, 6)
  end
  if how_utimer > 190 and how_utimer < 350 then
    if how_utimer % 20 > 4 then
      line(116, 42, 116, 45, 7)
    end
  end
end

function init_extra()
  menu_state = "extra"
  init_extra_items()
end

function update_extra()
  update_prog()
  if not t_active then
    local d, E = false, false
    if ml_click() then
      d = m_inside {x = 119, y = 120, w = 1, h = 1}
      E = m_inside {x = 0, y = 36, w = 12, h = 1}
    end
    if btnp(3) or d then
      slct_index = 0
      init_transition()
      sfx(5)
    end
    if E then
      local d = "https://lokistriker.itch.io/rust"
      poke(24449, ord(d, 1, #d))
      print("\xe2\x81\xb6!5f80u")
    end
  end
end

function draw_extra()
  draw_proc()
  camera()
  batch_itemlists()
  draw_items()
  draw_text("thank you!", 8, 8)
  print("fOR PLAYING THE WEB VERSION!\niF YOU LIKED THE GAME, CONSIDER\nSUPPORTING ME BY BUYING IT AT\n\xe1\xb6\x9cclokistriker.itch.io/rust\xe1\xb6\x9c6", 10, 16, 6)
  print("bUYING THE GAME UNLOCKS NEW\nITEMS AS WELL AS ANOTHER\nSTARTING CHARACTER", 10, 100)
  spr(16, 119, 120 + abs(sin(t() * .3) * 2.1))
  draw_displaybox()
end

function init_extra_items()
  items = {}
  local E, n, c = split "61,63,65,64,68,70,71,74", split "32,72,92,52,36,32,70,92", split "44,44,44,44,62,72,72,72"
  for d = 1, #E do
    local E = get_item(E[d])
    E.x = n[d] - 6
    E.y = c[d] + 2
    E.tm = E.tm - (d * 6)
    add(items, E)
  end
end

function init_credits()
  menu_state = "credits"
end

function update_credits()
  update_prog()
  if not t_active then
    local d = false
    if ml_click() then
      d = m_inside {x = 60, y = 120, w = 1, h = 1}
    end
    if btnp(3) or d then
      slct_index = 0
      init_transition()
      sfx(5)
    end
  end
end

function draw_credits()
  draw_proc()
  camera()
  local d, n = draw_text, print
  d("credits", 8, 12)
  local d = {"dEV:", "  \xe1\xb6\x9c7lOKISTRIKER", "", "aRTISTS:", "  \xe1\xb6\x9c7lOKISTRIKER, ePICHEEZENESS", "", "pLAYTESTERS:", "  \xe1\xb6\x9c7aCHIE72, lOUIEcHAPM,", "  \xe1\xb6\x9c7oTTO_pIRAMUTHU,", "  \xe1\xb6\x9c7sMELLYfISHSTICKS, wERXZY", "", "sPECIAL THANKS:", "  \xe1\xb6\x9c7kRYSTMAN, zEP, sQUIDLIGHT,", "  \xe1\xb6\x9c7pANCELOR "}
  for E = 1, #d do
    n(d[E], 12, 18 + E * 6, 6)
  end
  spr(16, 60, 120 + abs(sin(t() * .3) * 2.1))
end

function init_intro()
  intro_timer = -120
  intro_state = "logo"
  import_logo()
end

function draw_intro()
  if intro_state == "logo" then
    draw_logo()
  end
  if intro_state == "splash" then
    draw_splash()
  end
end

function update_intro()
  if intro_timer == -20 then
    music(0, 4000)
  end
  if intro_state == "logo" then
    update_logo()
  end
  if intro_state == "splash" then
    update_splash()
  end
end

function update_logo()
  intro_timer = intro_timer + (1)
  if intro_timer > 240 then
    intro_state = "splash"
    intro_timer = 0
  else
    if ml_click() or btnp() ~= 0 then
      if intro_timer <= -20 then
        music(0, 4000)
      end
      intro_timer = 240
    end
  end
end

function draw_logo()
  if intro_timer < 0 or intro_timer > 180 then
    return
  end
  if intro_timer < 45 then
    pal(7, 1)
    pal(8, 13)
    fillp(0)
  elseif intro_timer < 90 then
    pal(7, 13)
    pal(8, 1)
    fillp(0)
  else
    pal(7, 4)
  end
  print_logo(32, 24, (180 - intro_timer) / 10)
  fillp()
  pal(7, 7)
  pal(8, 8)
end

function update_splash()
  intro_timer = min(30, intro_timer + .01667)
  intro_music_delay = min(510, intro_music_delay and intro_music_delay + 1 or 1)
  if intro_music_delay == 510 then
    music(-1, 50)
  end
  if ml_click() or btnp() ~= 0 then
    if not t_active then
      if intro_timer < 7 then
        intro_timer = 8
        music(-1)
        sfx(13)
      else
        slct_index = 0
        init_transition()
        switch_color, long_intro = true, true
        init_transition()
      end
    end
  end
end

function draw_splash()
  pal(1, 0)
  pal(2, 0)
  pal(7, 0)
  sspr(0, 26, 128, 102, 0, flr(max(20, 135 - intro_timer * 16)))
  pal(1, 1)
  pal(2, 2)
  palt(3, true)
  pal(7, 7)
  sspr(0, 26, 128, 102, 0, flr(max(20, 192 - intro_timer * 24)))
  rectfill(0, flr(max(20, 192 - intro_timer * 24)) + 101, 127, 128, 1)
  palt(3, false)
  if intro_timer > 4 then
    local E = split "from,rust,to,ash"
    for d = 1, 4 do
      if intro_timer > 4 + d * .5 then
        draw_text(E[d], 88, 66 + d * 6)
      end
    end
  end
end


__gfx__
00000000111000000010000000000000000000000000000000000000000000000010011111100100000000000000000001000000001001000000000000000000
00000000176110000161000000000000000000000000000000000000000000000011001001001100000000000000000001011100011111100000000000000000
00700700167761000171100000000000000000000000000000000000000000000011101001011100000000000000000001011100011001100000000000000000
000770001d6776100177610000000000000000000000000000000000000000000011101001011100000000000000000001011100011001100000000000000000
0007700001d611001d67761000000000000000000000000000000000000000000011101001011100111111111111111101011100011001100000000000000000
0070070001d1d1001666671000000000000000000000000000000000000000000011101001011100111111100111111101011100011001100000000000000000
000000000010110001d6661000011111111111111111111111111111111110000011101001011100111111000011111101011100011111100000000000000000
0000000000000000001dd10000001111100000000000000000000001111100000011101001011100111110000001111101000000001001000000000000000000
6d777760707777700000000000001111100000000000000000000001111100000011101001011100111110000001111100000010000120000000000000000000
17d77610070777000000000000011111111111111111111111111111111110000011101001011100111111000011111100111010001211000000000000000000
017d6100007070000000000000000000000000000000000000000000000000000011101001011100111111100111111100111010001182000000000000000000
00161000000700000000000000000000000000000000000000000000000000000011101001011100111111111111111100111010018228100000000000000000
00010000000000000000000000000000000000000000000000000000000000000011101001011100000000000000000000111010011892100000000000000000
00000000000000000000000000000000000000000000000000000000000000000011101001011100000000000000000000111010018978100000000000000000
00000000000000000000000000000000000000000000000000000000000000000011001001001100000000000000000000111010001791000000000000000000
00000000000000000000000000000000000000000000000000000000000000000010011111100100000000000000000000000010000110000000000000000000
00610000007100007777700000111111111100077707777007777777707777777777077777000777777777777000770000700077000707770777700777077770
00761000077d11000777000001100000000110700077000770000700077000070000700007000700700007007000770000770777700770007700077000770007
00776100677676100070000011006d77770011700077077070000700077770077700700777777700700007007777070000707077070770007777707000777770
0077d610067d00610777000011060dd7770011777777000770000700077000070000700077000700700007007000770000700077007770007700007007070007
007d7100006001d17777700011060dd6d60011700077777007777777707777770000077777000777777770007000777777700077000707770700000770770007
00d7100000011d610000000011006dd6660011077777777770007700077000770007700077777707777777007777077770700077777707777777770777007770
00610000016dd6100000000011000dd6660011700000070070007700077000707070700070007070007007000000700007700077000070000000077000770007
00000000001111000000000011000000000011777770070070007700077070700700077770070070007007000777700777777777777777777000070777077777
00000000000000000000000000000000000000000070070070007070707707707070000070700070007007007000000007000070000770007000077000700007
00000000000000000000000000000000000000777700070007770007007000770007777707777777770777777777777770000077777007770000070777077770
00000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000300000000000000
00000000000000000000000000000000000000000000000000000002221200000000000000000000000000000000000000000000000000000300000000000003
00000000000000000000000000000000000000000000000000000022210020000000000000000000000000000000000000000000000000000300000000000333
00000000000000000000000000000000000000000000000000000222210002000000000000000000000000000000000000000000000000003000033300333333
00000000000000000000000000000000000000000000000000022222110001000000000000000000000000000000000000000000000000003000333303333333
00000000000000000000000000000000000000000000000000222211211001000000000000000000000000000000000000000000000000000003333333333333
00000000000000000000000000000000000000000000000002222122111101000000000000000000000000000000000000000000000000300003333333333333
00000000000000000000000000000000000000000000000222221211110111000000000000000000000000000000000000000000000030000033333333333333
00000000000000000000000000000000000000000000022222112111000011000000000000000000000000000000000000000000000030000333333333333333
00000000000000000000000000000000000000000000222221221110000100000000000000000000000000000000000000000000000330000333333333333333
00000000000000000000000000000000000000002222222112111100011000000000000000000000000000000000000000000000000330003333333333333333
00000000000000000000000000000000000000022222221221110000100000000000000000000000000000000000000000000000000000003333333333333333
00000000000000000000000000000000000000222222112111100001000000000000000000000000000000000222000000000000000000003333333333333330
00000000000000000000000000000000000002222221221110000100000000000000000000000000000000022222200000000000000000033333333333333000
00000000000000000000000000000000000022222212211100001000000000000000000000000000000022222221120000000000000030033333333333000000
00000000000000000000000000000000000221221121110000000000000000000000000000000000002222222221000000000000000030000333333300000000
00000000000000000000000000000200022221212111100000220000000000000000000000000000222222222222001000000000000000000333330000000000
00000000000000000000000000000022222221121111000022000200000000000000000000000022222222222211000000000000000030000333330000333333
00000000000000000000000000000222222221111100000000022022000000000000000000002222222222221122100100000000000030003333333333333333
00000000000000000000000000022222222221111000010000002201200000000000220000222222222222112211100100000000000000003333333333333333
00000000000000000000000000222112222112211110100011000001120000000022222222222222222211221110010100000000000030003333333333333333
00000000000000000000000022222122222122122111100011110011112200002222222222222222221122111000011100000000000030000333333333333333
00000000000000000000000222222121222222211212200011111111111100022222222212222222112211100000001100000000000030000033333333333333
00000000000000000000000222222222222222222211100010011111111100222222222212222211221110000000111000000000000000000033333333333333
00000000000000000000000222222222222222222111000000000011111100211222122212221121111000000011100000000000000000000333333333333333
00000000000000000000002222222222222222221111010000000000111102111122112211112111100000001111000000000000000330000333333333333333
00000000000000000000000222222222222222211111110000000000011101111112112211211110000000111100000000000000000330000333333333333333
00000000000000000000002222222222222211111111111111110000000101111112112211111000000011000000000000000000000330000333333333333333
00000000000000000000002222222222222222111111111211111110000011111112212211100000001100000000000000000000000300000333333333333333
00000000000000000000002222222222221111111111111122221111100021111112111110000001100000000000000000000000003000003333333333333333
00000000000000000000002222221022222211110111111122222221110021111122111000000112000000000000000000000000000000033333333333333333
00000000000000000000000222220001222111110111111122222222221112111221100000012100000000000000000000000000030000033333333333333333
00000000000000000000000222210000122111100111111122222122221112211210000001111200000000000000000000003000030000333333333333333333
00000000000000000000002222110000011111000111111122222122222211121000000011112000000000000000000000033330000333333333333333333333
00000000000000000000022221100000001110000111111122122222222211220000000110000000000000000000000000000300033333333333333333333333
00000000000000000000022221000000000110000111111112212222222111222200001200000000000000000000000000033330033333333333333333333333
00000000000000000000222210000000000000000111111112122222222111122222000000000000000000000000000000033330003333333333333333333333
00000000000000000000221100000000000000000111111122222222222111122220000000000000000000000000030000030330003333333333333333333333
00000000000000000000221000000000000100000111111122222222222111122220000000000000000000000000333000003330003333333333333333333333
00000000000000000000221000000000012110000111111112222212222111111220000000000000000000000000333000003330033333333333333333333333
00000000000000000002221000000000022211110111111222221222222211100120000000000000000000000000003300003300033333333333333333333333
00000000000000000002220000000000102210011111111222222222222211100122000000000000000000000000333333330000333333333333333333333333
00000000000000000022221000000001000211011111101112222122222211111122200222000000000000000003333333330003333333333333333333333333
00000000000000000021211100001110000211111000001000000111222222211122201112200000000000000003333333000033333333333333333333333333
00000000000000000212211110012000000211110000001000100000111122211122001111220000000000000000333333000333333333333333333333333333
00000000000000000222211111120000000111110000000100001001010001111122011111120000000000000033303033000333333333333333333333333333
00000000000000002222221111100000000111100000000101000000000000001100111100120000000000000033333330003333333333333333333333333333
00000000000000002222221211000000000111000000000000000001101000000011111000010000000000000003330330003333333333333333333333333333
00000003000000002222111111000000000111000000000000000000110000000011110000100000000000000003333000033333333333333333333333333333
00000333300000022221111112000000000110000000000000000000000001000111100001000000000000000000030000033333333333333333333333333333
00033333300000022222221110000000000100000000000000000000000000000110000100000000000000000003330000033333333333333333333333333333
30333333330000022111111120000000000100000000000000000000000000000100001000000000000000000000030000333333333333333333333333300000
33333333330001221111111100000000000000000000000000222200000000000000112000000022200000000000300000333333333333333333330000000000
00033303333001221111101200000000002001000000000001222222000000000001111222222222010000000000333003333333333333333000000000033333
30000000033001222111000100000000022111100000000001222222000000000011221222221222001000000003300003333333333300000000003333333333
33333330003002211110000010000000222111111100010111222222021111110111111111122222201000000033030003333333000000000033333333333333
33333333000302222110000001100002222111111101110111222222022111111111111122000022220000000033000033000000033333333333333333333333
33333333330001222211000022021000011111111111110111222222011111111122220000000022000000000330000333333333333333333333333333333333
33333333333000222211100202222222200111111111000111222222011111111112000000111000000000000030003333333333333333333333333333333333
33333333333000122211010122222222222001111100000111122220101111111112200110000000000000003300033333333333333333333333333333333333
33333333333300001221110012222222222220011100000111122220000111111111121100000000000000000000333333333333333333333333333333333333
33333333333300002222100001222222222222200100000111122220000000111111112000000000000000300000333333333333333333333333333333333333
33333333333300000000000000122222222222222000000011122220000000011111111200000000000000000003333333333333333333333333333333333333
33333333333300000000000000011122222222222222000001122220000000001111111120000000000030330003333333333333333333333333333333333333
33333333333300000000000000001212222222222222222000000220000000000111111112000000000000000003333333333333333333333333333333333333
33333333333330000000000002000021222222222222222100000000000000000111111111200000000000000033333333333333333333333333333333333333
33333333333333000000000022200002122222222222221111200000111110000111111111120000000000300033333333333333333333333333333333333333
33333333333333330000000222210000212122222222221222222200111111001111111111112000000000000333333333333333333333333333333333333333
33333333333333333300000222211000001212222222222222222210001111111111111111111200000003000333333333333333333333333333333333333333
33333333333333333000022222110100000121222222222222222221100001001111111111000120000300003333333333333333333333333333333333333333
33333333333333333000022221100110000012122222222222222221122220000111111111100112000300333333333333333333333333333333333333333333
33333333333333333000022211100111000001122222222222222222122222220011111111110011203000333333333333333333333333333333333333333333
33333333333333333002222100001111110001122222222222222222222222222200111111111011203003333333333333333333333333333333333333333333
33333333333333333022221100001111111100112122222222222222222222222100111001111111000003333333333333333333333333333333333333333333
33333333333333333022211000001111011210011221222222222222222222211000011100100002030033333333333333333333333333333333333333333333
33333333333333330001110000000110111100000121122222122222222221100200001110010000030033333333333333333333333333333333333333333333
03003333333333330110000000000010012000000011122221122222222112000010000111010000300033333333333333333333333333333333333333333333
00000033333333300110000000000000120000000000111221112222111200000011000000000010300333333333333333333333333333333333333333333333
33000000033333301110111000000000100000000000000111111111000000000211100000000020300333333333333333333333333333333333333333333333
33300003003333001100111100000000000000000000000001111000000000000211110000000003000333333333333333333333333333333333333333333333
33300333300003011110011111001100000000000000000000000000000000000011111000000000003333333333333333333333333333333333333333333333
33300000333300011111111111100000000000000000000000000000000000000001111111111200033333333333333333333333333333333333333333333333
33000000033300011111111111000000000000000000000000000000000000000002211111111003333333333333333333333333333333333333333333333333
00011000033000211111111200000000000000000000000000000000000000000002211111111003333333333333330333333333333333333333333333333333
00111100003002111110000000000000000000000000000000000000000000000000111111110000000003333333333333333333333333333333333333333333
03111111000021111120000000000000000000000000000000000000000000000002111111112000003333333333333333333333333333333333333333033300
01111111100021111000000000001111000000000000000000000110000000000002111111121200133333333333333333333333333333333333330000000000
11111111100221110001111111111111111000000000000001111111110000000002111111112220111333333333333333333333333333330000000000000000
11111111100211100111111111111111111111111111111111111111111111111100211111111122011111333333333333333333333333000000000000000000
11111111102111001111111111111111111111111111111111111111111111111110000001101112201111111300333333333333333333000000000000000000
11111111002100011111111111111111111111111111111111111111111111111111110000000212220011111111111111100033333300000000000000000000
11111111021000111111111111111111111111111111111111111111111111111111111100000000122001111111111111111133333000000000000000000000
11111110000001111111111111111111111111111111111111111111111111111111110003330000000000111111111111111111111111111111110000000000
11111110000000011111111000000000000000000000000001111111100000000000000033330000000000000111111111111111111111111111111100000000
11111111000000000011111000000000000000000000000000000000000000000000000000333000000000000001111111111111111111111111111111100000
00111111110000000000111110000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111
00000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111100001111111111111
11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111
11000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000011111111111111111
11111111110000000000000000000000000000000011101110000000000011111000000000000000000000000000000000000000000000011111111111111111
11111111111111110000000000000111111111111111111111111111111111111111111100000000000000000000000000000001111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000001111111111111111111111111111111
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1a00030405050505050505050607001b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000080d0d0d0d0d0d0d0d0d0d09000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001c0d0d0d0d0d0d0d0d0d0d0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000180d0d0d0d0d0d0d0d0d0d19000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000131415151515151515151617000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000d0d0d0d0d0d0d0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000d0d0d0d0d0d0d0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000d0d0d0d0d0d0d0d0d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
a502020023514235152e5002e5002e5002e5002e5003a5022e5002e5003c5023c5020050200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
001180000aa7410a1516a451ca7520a2626a4630a1736a473aa6700010060400a060100311c032340140c10512105101643e0421e0111000110060080200287738a2732a072ea662aa3620a6516a150ea5406a04
0011800022a742ca1536a453ea7506b260eb4616b171cb4724b6700010060400a060100311c032340140c10512105101643e0421e011100011006008020028771ab2714b070cb6606b3604b653ea1536a5430a04
d508030818011180111802118032180221802218031180410c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000
47040c0026552265522b5422b5222b5322b5122b512375022b5222b51239502395020050200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
470406002b5222b5122e5002e5002e5002e5002e5003a5022e5002e5003c5023c5020050200502005020050200502005020050200502005020050200502005020050200502005020050200502005020050200502
38000000500e0700c050080500e0600a050060200001302171100203eb4732b5626b2624b2626b662cb5628b2736b3738b77040200c05008011120700e060060500a1720c0203eb372cb2622b1624b6630b47
3110000018c5018c5018c5518c0018d350c00018d250c00018d150c0000c00018d150c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c0000c000
b140000013b3513b3513b3513b3513b3513b3513b3513b3515b3515b3515b3515b3515b3515b3515b3515b3511b3511b3511b3511b3511b3511b3511b3511b3510b3510b3510b3510b3510b3510b3510b3510b35
b94000000ab300ab300ab300ab300ab300ab300ab300ab3009b3009b3009b3009b3009b3009b3009b3009b300cb300cb300cb300cb300cb300cb300cb300cb300bb300bb300bb300bb300bb300bb300bb300bb30
d51000201fb721fb3518b7218b351ab721ab351fb721fb311fb211fb150000000000269142691026915000002b9142b9122b9152b905000000000024914249102491528900000050000500005000050000500005
a70200010422303200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d31018000c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0430c6450c6450c0000c6000c6000c6000c600
d31002000c04300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bd10002000b001fb001fb0018b0018b001ab001ab001fb001fb001fb001fb0000b0000b0026b1426b1226b1226b152bb142bb122bb122bb1500b0000b0024b1424b1224b1224b1224b1528b1128b1128b1228b15
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
5d0302002375523000007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
d70808002f0302f7202f715001002f0202f7102f71500100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
ab030400000331a6510c0310010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000000
a10400001c53210554005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
b7060800186541b642186311b612186211b6150c60000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000000000000000000
bd030500170231a0311c0552300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300002d7242d725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 0c5444
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
01 47504d43
03 08090a0e
00 49514d43
00 4a4b4c43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
00 4b4c4d43
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
00000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000000000g00000000000000
0000000000000000000000000000000000000000000000000000000888i800000000000000000000000000000000000000000000000000000g0000000000000g
000000000000000000000000000000000000000000000000000000888i0080000000000000000000000000000000000000000000000000000g00000000000ggg
000000000000000000000000000000000000000000000000000008888i000800000000000000000000000000000000000000000000000000g0000ggg00gggggg
00000000000000000000000000000000000000000000000000088888ii000i00000000000000000000000000000000000000000000000000g000gggg0ggggggg
000000000000000000000000000000000000000000000000008888ii8ii00i00000000000000000000000000000000000000000000000000000ggggggggggggg
00000000000000000000000000000000000000000000000008888i88iiii0i000000000000000000000000000000000000000000000000g0000ggggggggggggg
0000000000000000000000000000000000000000000000088888i8iiii0iii0000000000000000000000000000000000000000000000g00000gggggggggggggg
00000000000000000000000000000000000000000000088888ii8iii0000ii0000000000000000000000000000000000000000000000g0000ggggggggggggggg
0000000000000000000000000000000000000000000088888i88iii0000i00000000000000000000000000000000000000000000000gg0000ggggggggggggggg
00000000000000000000000000000000000000008888888ii8iiii000ii000000000000000000000000000000000000000000000000gg000gggggggggggggggg
0000000000000000000000000000000000000008888888i88iii0000i0000000000000000000000000000000000000000000000000000000gggggggggggggggg
00000000000000000000000000000000000000888888ii8iiii0000i00000000000000000000000000000000088800000000000000000000ggggggggggggggg0
0000000000000000000000000000000000000888888i88iii0000i000000000000000000000000000000000888888000000000000000000gggggggggggggg000
000000000000000000000000000000000000888888i88iii0000i00000000000000000000000000000008888888ii800000000000000g00ggggggggggg000000
0000000000000000000000000000000000088i88ii8iii000000000000000000000000000000000000888888888i0000000000000000g0000ggggggg00000000
0000000000000000000000000000080008888i8i8iiii0000088000000000000000000000000000088888888888800i000000000000000000ggggg0000000000
0000000000000000000000000000008888888ii8iiii0000000008000000000000000000000000888888888888ii0000000000000000g0000ggggg0000gggggg
0000000000000000000000000000088888888iiiii0000000008808800000000000000000000888888888888ii88i00i000000000000g000gggggggggggggggg
0000000000000000000000000008888888888iiii0000i0000008808800000000000880000888888888888ii88iii00i0000000000000000gggggggggggggggg
00000000000000000000000000888ii8888ii88iiii0i000880000088800000000888888888888888888ii88iii00i0i000000000000g000gggggggggggggggg
00000000000000000000000088888i88888i88i88iiii0888888008888880000888888888888888888ii88iii0000iii000000000000g0000ggggggggggggggg
00000000000000000000000888888i8i8888888ii8i88088iii888888888000888888888i8888888ii88iii0000000ii000000000000g00000gggggggggggggg
000000000000000000000008888888888888888888iii0iiiiii88888888008888888888i88888ii88iii0000000iii0000000000000000000gggggggggggggg
00000000000000000000000888888888888888888iii0iiiiiiii8888888008ii888i888i888ii8iiii0000000iii00000000000000000000ggggggggggggggg
0000000000000000000000888888888888888888iiii0iiii0iiiii8888808iiii88ii88iiii8iiii0000000iiii000000000000000gg0000ggggggggggggggg
000000000000000000000008888888888888888iiiiiiii0iiiiiiiii8880iiiiii8ii88ii8iiii0000000iiii00000000000000000gg0000ggggggggggggggg
000000000000000000000088888888888888iiiiiiiiiiiiiiiiiiiiiiii0iiiiii8ii88iiiii0000000ii000000000000000000000gg0000ggggggggggggggg
00000000000000000000008888888888888888iiiiiiiii8iiiiiiiiii00iiiiiii88i88iii0000000ii00000000000000000000000g00000ggggggggggggggg
0000000000000000000000888888888888iiiiiiiiiiiiii8888iiiii0ii8iiiiii8iiiii000000ii0000000000000000000000000g00000gggggggggggggggg
0000000000000000000000888888i0888888iiii0iiiiiii8888888iiiii8iiiii88iii000000ii80000000000000000000000000000000ggggggggggggggggg
0000000000000000000000088888000i888iiiii0iiiiiii8888888888iii8iii88ii000000i8i000000000000000000000000000g00000ggggggggggggggggg
000000000000000000000008888i0000i88iiii00iiiiiii88888i8888iii88ii8i000000iiii80000000000000000000000g0000g0000gggggggggggggggggg
00000000000000000000008888ii00000iiiii000iiiiiii88888i888888iii8i0000000iiii80000000000000000000000gggg0000ggggggggggggggggggggg
0000000000000000000008888ii0000000iii0000iiiiiii88i888888888ii880000000ii0000000000000000000000000000g000ggggggggggggggggggggggg
0000000000000000000008888i000000000ii0000iiiiiiii88i8888888iii88880000i8000000000000000000000000000gggg00ggggggggggggggggggggggg
000000000000000000008888i0000000000000000iiiiiiii8i88888888iiii888880000000000000000000000000000000gggg000gggggggggggggggggggggg
0000000000000000000088ii00000000000000000iiiiiii88888888888iiii888800000000000000000000000000g00000g0gg000gggggggggggggggggggggg
0000000000000000000088i000000000000i00000iiiiiii88888888888iiii88880000000000000000000000000ggg00000ggg000gggggggggggggggggggggg
0000000000000000000088i0000000000i8ii0000iiiiiiii88888i8888iiiiii880000000000000000000000000ggg00000ggg00ggggggggggggggggggggggg
0000000000000000000888i0000000000888iiii0iiiiii88888i8888888iii00i8000000000000000000000000000gg0000gg000ggggggggggggggggggggggg
00000000000000000008880000000000i088i00iiiiiiii8888888888888iii00i88000000000000000000000000gggggggg0000gggggggggggggggggggggggg
0000000000000000008888i00000000i0008ii0iiiiii0iii8888i888888iiiiii8880088800000000000000000ggggggggg000ggggggggggggggggggggggggg
0000000000000000008i8iii0000iii00008iiiii00000i000000iii8888888iii8880iii880000000000000000ggggggg0000gggggggggggggggggggggggggg
000000000000000008i88iiii00i80000008iiii000000i000i00000iiii888iii8800iiii880000000000000000gggggg000ggggggggggggggggggggggggggg
000000000000000008888iiiiii80000000iiiii0000000i0000i00i0i000iiiii880iiiiii800000000000000ggg0g0gg000ggggggggggggggggggggggggggg
0000000000000000888888iiiii00000000iiii00000000i0i00000000000000ii00iiii00i800000000000000ggggggg000gggggggggggggggggggggggggggg
0000000000000000888888i8ii000000000iii00000000000000000ii0i0000000iiiii0000i000000000000000ggg0gg000gggggggggggggggggggggggggggg
0000000g000000008888iiiiii000000000iii000000000000000000ii00000000iiii0000i0000000000000000gggg0000ggggggggggggggggggggggggggggg
00000gggg0000008888iiiiii8000000000ii000000000000000000000000i000iiii0000i0000000000000000000g00000ggggggggggggggggggggggggggggg
000gggggg0000008888888iii0000000000i00000000000000000000000000000ii0000i0000000000000000000ggg00000ggggggggggggggggggggggggggggg
g0gggggggg0000088iiiiiii80000000000i00000000000000000000000000000i0000i0000000000000000000000g0000ggggggggggggggggggggggggg00000
gggggggggg000i88iiiiiiii00000000000000000000000000888800000000000000ii8000000088800000007777707777ggg777gg7ggg7ggggggg0000000000
000ggg0ggggg0i88iiiii0i80000000000800i00000000000i88888800000000000iiii8888888880i0000007000gg700g7g7ggg7g77g77gg0000000000ggggg
g00000000gg00i888iii000i00000000088iiii0000000000i8888880000000000ii88i88888i88800i00000777gg07777gg7ggg7g7g7070000000gggggggggg
ggggggg000ggg88iiii00000i0000000888iiiiiii000i0iii88888808iiiiii0iiiiiiiiii8888880i0000070gg0g700g7g7ggg7070007000gggggggggggggg
gggggggg000gg8888ii000000ii00008888iiiiiii0iii0iii888888088iiiiiiiiiiiii880000888800000070gg0070gg7007770g7ggg7ggggggggggggggggg
gggggggggg000i8888ii00008808i0000iiiiiiiiiiiii0iii8888880iiiiiiiii88880000000088000000000gg0000ggggggggggggggggggggggggggggggggg
gggggggggggggg8888iii00808888888800iiiiiiiii000iii8888880iiiiiiiiii8000000iii000000000007777007ggg7gg7777g77777ggggggggggggggggg
ggggggggggggg0i888ii0i0i8888888888800iiiii00000iiii88880i0iiiiiiiii8800ii0000000000000007g007g7ggg7g7ggggggg7ggggggggggggggggggg
gggggggggggg0000i88iii00i88888888888800iii00000iiii88880000iiiiiiiiii8ii00000000000000007777gg7ggg7g77777ggg7ggggggggggggggggggg
ggggggggggggg0008888i0000i888888888888800i00000iiii88880000000iiiiiiii8000000000000000g070007g7ggg7ggggg7ggg7ggggggggggggggggggg
gggggggggggg00000000000000i888888888888880000000iii888800000000iiiiiiii80000000000000000700g7gg777gg7777gggg7ggggggggggggggggggg
ggggggggggggg00000000000000iii8888888888888800000ii8888000000000iiiiiiii800000000000g0gg000ggggggggggggggggggggggggggggggggggggg
gggggggggggg0000000000000000i8i8888888888888888000000880000000000iiiiiiii80000000000000077777gg777gggggggggggggggggggggggggggggg
ggggggggggggg000000000000800008i888888888888888i00000000000000000iiiiiiiii80000000000000007ggg7ggg7ggggggggggggggggggggggggggggg
gggggggggggggg000000000088800008i8888888888888iiii800000iiiii0000iiiiiiiiii80000000000g0007ggg7ggg7ggggggggggggggggggggggggggggg
gggggggggggggggg00000008888i00008i8i8888888888i888888800iiiiii00iiiiiiiiiiii8000000000000g7ggg7ggg7ggggggggggggggggggggggggggggg
gggggggggggggggggg000008888ii00000i8i88888888888888888i000iiiiiiiiiiiiiiiiiii80000000g000g7gggg777gggggggggggggggggggggggggggggg
ggggggggggggggggg000088888ii0i00000i8i88888888888888888ii0000i00iiiiiiiiii000i80000g0000gggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggg00008888ii00ii00000i8i8888888888888888ii88880000iiiiiiiiii00ii8000g00ggg777ggg7777g7ggg7ggggggggggggggggggggggg
ggggggggggggggggg0000888iii00iii00000ii88888888888888888i888888800iiiiiiiiii00ii80g000gg7ggg7g7ggggg7ggg7ggggggggggggggggggggggg
gggggggggggggggggg08888i0000iiiiii000ii88888888888888888888888888800iiiiiiiii0ii8gg00ggg7ggg7g77777g77777ggggggggggggggggggggggg
gggggggggggggggggg8888ii0000iiiiiiii00ii8i88888888888888888888888i00iii00iiiiiii0g000ggg77777ggggg7g7ggg7ggggggggggggggggggggggg
gggggggggggggggggg888ii00000iiii0ii8i00ii88i8888888888888888888ii0000iii00i00008gg00gggg7ggg7g7777gg7ggg7ggggggggggggggggggggggg
gggggggggggggggggggiii0000000ii0iiii00000i8ii88888i8888888888ii0080000iii00i000ggg00gggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggii00000000000i00i80000000iii8888ii88888888ii80000i0000iii0i000gg000gggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggii0000000000000i80000000000iii88iii8888iii8000000ii0000000000igg00ggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggiii0iii000000000i00000000000000iiiiiiiii0000000008iii0000000008gg00ggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggii00iiii0000000000000000000000000iiii0000000000008iiii00000000gg000ggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggiiii00iiiii00ii000000000000000000000000000000000000iiiii000000ig000gggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggiiiiiiiiiiii0000000000000000000000000000000000000000iiiiiiiiii8000ggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggiiiiiiiiiii0000000000000000000000000000000000000000088iiiiiiii00ggggggggggggggggggggggggggggggggggggggggggggggggg
gggiiigggggggg8iiiiiiii8000000000000000000000000000000000000000000088iiiiiiii00ggggggggggggggg0ggggggggggggggggggggggggggggggggg
ggiiiiigggggg8iiiii0000000000000000000000000000000000000000000000000iiiiiiii000000000ggggggggggggggggggggggggggggggggggggggggggg
ggiiiiiiggig8iiiii80000000000000000000000000000000000000000000000008iiiiiiii800000gggggggggggggggggggggggggggggggggggggggg0ggg00
giiiiiiiiigg8iiii00000000000iiii000000000000000000000ii0000000000008iiiiiii8i800iggggggggggggggggggggggggggggggggggggg0000000000
iiiiiiiiiig88iii000iiiiiiiiiiiiiiii00000000000000iiiiiiiii0000000008iiiiiiii8880iiiggggggggggggggggggggggggggggg0000000000000000
iiiiiiiiiig8iii00iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii008iiiiiiiii880iiiiigggggggggggggggggggggggg000000000000000000
iiiiiiiiig8iii00iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii000000ii0iii880iiiiiiig00gggggggggggggggggg000000000000000000
iiiiiiii008i000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii00000008i88800iiiiiiiiiiiiiii000gggggg00000000000000000000
iiiiiiii08i000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii00000000i8800iiiiiiiiiiiiiiiiiggggg000000000000000000000
iiiiiii000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii000ggg0000000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii0000000000
iiiiiii00000000iiiiiiii00000000000000000000000000iiiiiiii000000000000000gggg0000000000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii00000000
iiiiiiii0000000000iiiii000000000000000000000000000000000000000000000000000ggg00000000000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii00000
00iiiiiiii0000000000iiiii0000000000000000000000000000000000000000000000000000000000000000000000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiii
0000000iiii0000000000000000000000000000000000000000000000000000000000000000000000000000000000000iiiiiiiiiiiiiii0000iiiiiiiiiiiii
ii000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000iiiiiiiiiiiiiii
ii0000000000000000000000000000000000000000000000ii0000000000000000000000000000000000000000000000000000000000000iiiiiiiiiiiiiiiii
iiiiiiiiii00000000000000000000000000000000iii0iii00000000000iiiii0000000000000000000000000000000000000000000000iiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiii0000000000000iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii0000000000000000000000000000000iiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
