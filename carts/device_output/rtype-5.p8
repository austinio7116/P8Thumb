pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

--r-type
--THE rOBOz - FOR dORIAN
brush_s = {"*\xe3\x82\x86VTR\xe2\x96\xa0*\xe3\x82\xbdtXQ\xc2\xb9&W]Ya\r*\xe3\x81\x82[ZP!*\xf0\x9f\x98\x90kXP\xe2\x96\xa0*\xe2\x96\x91hVO!*\xe3\x83\xa8NXO\xe2\x96\xa1\"{X0d\xe2\x81\xb5'3`\xe2\x98\x89e6'\xe2\x97\x8fb\xec\x9b\x83d\xe2\x81\xb7+NbON\xe3\x81\x8d+N4ON\xe3\x81\xac+N0ON\xe3\x81\xa3", "&NN\xe3\x82\xa4\xe3\x82\x8a\xc2\xb9&Q\xe3\x81\xa6a\xe3\x81\xaf\0&ihyo\0&\xe3\x81\xaf\\\xe3\x82\x8bk\0&\xe2\xa7\x97\xe2\x9c\xbd\xe3\x81\x912\0-\xe3\x81\xae]\xe3\x81\x95k\0#f3\xe2\x8c\x823\0#f\xe2\x96\x91\xe2\x8c\x82\xe2\x96\x91\xe2\x81\xb5+`hUN\xe2\x96\x88+\xf0\x9f\x98\x90KUY\xe2\x80\xa6#NQNj\0#Nkf3\0#y\xe2\x96\x91y\xf0\x9f\x98\x90\0#2h2O\0#y\xe2\x99\xaa\xe2\x96\x882\0#\xe2\x96\x922\xe2\x96\x92\xe3\x81\x88\0#w\xe3\x81\x8aq\xe3\x81\x95\0#p\xe3\x81\x97p\xe3\x81\xb8\0#q\xe3\x81\xbbr\xe3\x81\xbe\0+\xe2\x97\x8fN_V0#s\xe3\x81\xbf\xe3\x81\x8f\xe3\x81\xbf\0#\xe3\x82\xa4g\xe3\x82\x86v\0#\xe3\x82\x84w\xe3\x82\x84\xe2\x96\x88\0&\xe2\x96\xa5\xe2\x99\xa5\xe3\x81\x8d4\xe3\x82\xbf&\xe3\x81\xb5b\xe3\x82\x82i\xe3\x82\xaf&ijxm\xe3\x82\xaf&R\xe3\x81\xaaa\xe3\x81\xad\xe3\x82\xad&\xe2\x88\xa7\xf0\x9f\x98\x90\xe3\x81\x841\xe3\x82\xad&\xe3\x82\x80^\xe3\x82\x88c\xe3\x82\xad", "'f\xe3\x81\xa6q\xe3\x81\x93\xc2\xb2-o\xe3\x81\xa6x\xe3\x81\x9f\xe2\x81\xb4'r\xe3\x81\x8d\xe2\x8c\x82\xe2\x8c\x82\xc2\xb2'j\xe3\x81\xa1v\xe3\x81\x88\xc2\xb2*og\xe3\x81\x95O\xc2\xb9-v\xe3\x81\x99\xf0\x9f\x90\xb1\xe3\x81\x91\xe2\x81\xb4*oj\xe3\x81\x88O\xc2\xb9'o\xe3\x81\x97~\xe2\x98\x85\xc2\xb2'o\xe3\x81\x9fr\xe3\x81\x9b\0'r\xe3\x81\x99v\xe3\x81\x95\0*\xe3\x82\x82\xe2\x9c\xbd\xe2\x99\xaaP\xe2\x96\xa1'y\xe2\x96\xa4\xe2\x97\x86\xec\x9b\x83t'u\xe3\x81\x93{\xe3\x81\x8d\0'p\xe3\x81\x8fz\xcb\x87\xe2\x81\x98'x\xe3\x81\x8a~\xe3\x81\x84\0*oq\xe2\x80\xa6O\xc2\xb9'p\xe3\x81\x8aw5.'y\xe3\x81\x86\xe2\x97\x8f4\xe1\xb5\x89#q1t\xe2\x99\xaa\xc2\xb2\"y\xe3\x81\x88\xe2\x97\x8f\xe2\x99\xaa\xe1\xb6\xa0'q\xe3\x81\x86t\xe2\x96\xa4\xe1\xb6\xa0'|\xe3\x81\x84\xe2\x9c\xbd4\0&~\xe2\x96\xa5\xe2\x96\x91\xe2\x80\xa6\xe3\x82\x8f#\xe2\x99\xa5\xe3\x81\x82\xf0\x9f\x98\x90\xe2\x88\xa7\xe2\x81\xb4'w\xe2\x8c\x82r\xe2\x97\x86@#[\xe3\x82\x82k\xe3\x81\xb8\xe2\x81\xb5#\\\xe3\x82\x84r\xe3\x81\xb2\xe2\x81\xb6#s\xe3\x81\xae{\xe3\x81\xae\xe2\x81\xb6#o\xe3\x81\xb2w\xe3\x81\xae\xe2\x81\xb5#y\xe3\x81\xae|\xe3\x81\xb5\xe2\x81\xb5#|\xe3\x81\xb8z\xe3\x81\xbf\xe2\x81\xb5#{\xe3\x82\x80\xe2\x97\x8b\xe3\x82\x82\xe2\x81\xb5#~\xe3\x82\x82\xe2\x8c\x82\xe3\x81\xbb\xe2\x81\xb5#\xe2\x99\xa5\xe3\x81\xbb4\xe3\x81\xbb\xe2\x81\xb5#{\xe3\x81\xae\xe2\x97\x8b\xe3\x81\xbb\xe2\x81\xb6#~\xe3\x81\xbb{\xe3\x81\xbf\xe2\x81\xb6#{\xe3\x81\xbf\xe2\x97\x8b\xe3\x82\x81\xe2\x81\xb6#\xe2\x97\x8b\xe3\x82\x824\xe3\x81\xb5\xe2\x81\xb6*\xe3\x83\xa8\xe2\x97\x86\xe3\x81\xaaO\xc2\xb2+N4mNp#Q\xe3\x81\xbf[\xe3\x82\x82\xe2\x81\xb5#R\xe3\x81\xbe]\xe3\x82\x82\xe2\x81\xb6*\xe2\x96\x91N\xe3\x81\xb2O1+a1wN\xe3\x81\xac+N\xe3\x82\x89PN\xe3\x82\x8a", "'WSqd\xc2\xb2'VVga\xe1\xb5\x89'XSnbd'XXd`O+_TON@'O^Zq\xc2\xb2-aufj\xe2\x81\xb4-[`eZ\0*\xe3\x81\x88W[O1'XoP_\xe2\x81\xb4'VgSo\xe1\xb5\x89'Q`Um_-SlYe\0*_TfO\xc2\xb9-`t]r\xe2\x81\xb6-U`Sd\xe2\x96\xae#fj_s>*o\\aO\xc2\xb9'_boi^'ZfenP", "*\xe2\x97\x9cP\xe3\x81\x8dR\xc2\xb9*\xe3\x82\xb9\xe2\x96\x91\xe3\x81\xabP\"*\xe2\x97\x9cZ\xe2\x88\xa7R1-0\xe2\x96\xa5i\xe3\x81\x8b\xe2\x81\xb7-n\xe3\x81\x9d\xe2\x99\xaa\xe3\x81\x8f\r-\xec\x9b\x83\xe3\x81\x84p\xe3\x81\x91F+NNQV`-i\xe3\x81\xac\xe3\x81\x8a\xe3\x82\x86\xe2\x81\xb5-f\xe3\x81\xad\xe2\x96\xa4\xe3\x82\x84\r*\xe2\x98\x85N\xe2\x96\xa5P\xc2\xb9'\xe2\x9c\xbd\xe2\x96\xa5\xe3\x81\x8a\xe3\x81\xac\r'\xe2\x98\x89\xe2\x96\xa5\xe3\x81\x84\xe3\x81\xa4\xe2\x81\xb6'0\xe3\x81\x825\xe3\x81\x95\xe2\x81\xb7-\xe2\x99\xa5\xe3\x81\x8f4\xe3\x81\xa4\r'\xe2\x99\xaa\xe3\x81\x8b\xe3\x81\xa6\xe3\x82\x86\xe2\x81\xb5'\xe2\x80\xa6\xe3\x81\x8b\xe3\x81\xa8\xe3\x82\x82\r'\xe2\x98\x85\xe3\x81\x8d\xe3\x81\xa4\xe3\x81\xbf\xe2\x81\xb6&f\xe3\x81\x8dv\xe3\x81\x97\xe2\x81\xb6&h\xe3\x81\x8ft\xe3\x81\x95\0&i\xe3\x81\x8fs\xe3\x81\x95\xe3\x81\xa3*\xe3\x82\x86R\xe3\x81\xacQ\xe2\x96\xa0*\xe3\x82\x86R\xe3\x81\xbbQ\xc2\xb9*\xe3\x82\x86h\xe3\x81\xb8Q1-^\xe3\x81\xad5\xe3\x82\x84\xe3\x81\xb8'\xe2\xa7\x97\xe3\x81\x8d\xe3\x81\x93\xe3\x81\xab\xe2\x81\xb7-5\xe3\x81\x932\xe3\x81\x99\xe2\x81\xb8'\xe3\x81\x9b\xe3\x81\x99\xe2\x88\xa7\xe3\x81\xb8\xe2\x81\xb5*\xe3\x83\x9e5\xe3\x81\x9bP2*\xe2\x96\x92\xe3\x81\x84\xe3\x81\xa4O\xc2\xb9-\xe3\x81\x95\xe3\x81\xbe\xe3\x81\x9b\xe3\x81\xb5\xe2\x81\xb8+N\xe2\x9c\xbdON\xe3\x83\x98", "'N\xe3\x81\xaaZ\xe3\x81\xbf\xe2\x81\xb7-V\xe3\x81\xaeu\xe3\x82\x84\xe2\x81\xb7-Q\xe3\x81\xadn\xe3\x82\x86\xe2\x81\xb6-N\xe3\x81\xaeh\xe3\x82\x88\r'N\xe3\x81\xabW\xe3\x82\x81\xe2\x81\xb6'N\xe3\x81\xadW\xe3\x82\x82\r-O\xe3\x81\xb5b\xe3\x82\x86\xe2\x81\xb5#Z\xe3\x81\xafN\xe3\x81\xaf\xe2\x81\xb5#X\xe3\x81\xafO\xe3\x81\xaf\0#P\xe3\x82\x81X\xe3\x82\x81\0#Q\xe3\x81\xaeV\xe3\x81\xaep#P\xe3\x82\x82X\xe3\x82\x82p#Q\xe3\x82\x81U\xe3\x82\x81\xe2\x98\x89+mNOV\xe3\x82\xaa+N\xe2\x9c\xbdON\xe3\x83\x98", ")\\nON\0)ktON\0)\xe3\x81\x86gON\0)\xec\x9b\x83\xe3\x81\x8fON\0)2\xe3\x82\x88ON\0)P\xe3\x82\x80ON\0)b\xf0\x9f\x98\x90SN\0)d\xe3\x81\xabSN\0)\xe2\x99\xa5USN\0)XXTN\0)yxUN\0)4\xe3\x81\xb2UN\0+~GON\xe3\x82\x89", "'`z\xe3\x82\x82\xe3\x81\x93\xe2\x81\xb5'_Trx\0'eV1\xe3\x81\x86	'Yrx\xcb\x87/'`s2\xe3\x81\x8aT'iW~xN'jYzt8'kZwp\xc2\xb2'eatn\xe2\x81\xb5*\xe3\x83\x86^TQ\xc2\xb3*\xe3\x82\xadu\\O\xc2\xb2+FnUN\xe3\x81\xac+\xe3\x81\x88NPT\xe3\x82\x89$\xe3\x82\x8cgsfw'y}\xe3\x81\x99\xe3\x81\x8d\xe3\x81\xaa'\xe2\x9c\xbd\xe2\x97\x8b\xe3\x81\x84\xe3\x81\x8bh'\xec\x9b\x833\xe2\x96\xa5\xe3\x81\x82\xc2\xb2'0\xe2\x9c\xbd\xe3\x81\x84\xe2\x96\xa4\xe2\x81\xb5'\xf0\x9f\x98\x90\xe2\x98\x89\xe2\x96\xa5\xe2\x88\xa7M*\xe3\x83\x861}P#*\xe3\x82\xad\xe2\x96\x91\xe2\x99\xa5O\"+1)]VP", "'T\\o\xe2\x99\xaa\xe2\x96\x92'Q[l\xe2\x99\xa5\xe2\x9c\xbd'JRi~\xc2\xb9'IRh~\0+ZYOU@'R\xe2\x97\x8b\xf0\x9f\x98\x90\xe3\x82\x871'R\xe2\x97\x8b\xec\x9b\x83\xe3\x82\x935'P\xe2\x97\x8b\xe2\x9c\xbd\xe3\x82\x8dm'Fz\xe2\x96\x91\xe3\x82\x8b\xc2\xb9'Ez3\xe3\x82\x8b\0+\xe2\x99\xaa?OV\xe3\x81\x8d\"MQfw\xe2\x96\x92\"Q{|\xe3\x81\xb5\xe2\x96\x92", "\"NN^^\r\"OO]]\xe1\xb6\x9c\"_No^\xe2\x81\xb8\"`On]\xe1\xb5\x89\"6KMb\xe2\x81\xb8\"7LLa\xe1\xb5\x89  ", "!PYX]\xe3\x82\x82'WY]]\xe1\xb6\x9c'TZ\\\\\xe2\x81\xb6#R[Z[7'PZZ\\\xe2\x97\x8f&ZZ[\\\xe2\x81\xb7'YXb^\xe1\xb6\x9c'XYb]\xe2\x81\xb6'YZ`\\\xe2\x81\xb7']Xi^\xe1\xb6\x9c'\\Yg]\xe2\x81\xb6'\\Zf\\\xe2\x81\xb7'dWs_\xe1\xb6\x9c'dXq^\xe2\x81\xb6'dYq]\xe2\x81\xb7", "&N\xe3\x82\x92\xe3\x82\xa4\xe3\x82\xa4\0!\xf0\x9f\x90\xb1\xe3\x81\xa3\xe3\x81\x9d\xe3\x82\xa2\xe2\x81\xb7", "*\xe3\x83\xa8NNO\xc2\xb2*\xe3\x82\xa6VNP\xc2\xb9*\xe2\x88\xa7fNP!+NUPN1", "*\xe3\x83\xb3^NO\"*\xe3\x83\xb3fNO\"*\xe3\x83\xb2NNP\xc2\xb2+LNOV0", "*\xe3\x83\xb2NNP\xc2\xb2+-NOV\xe2\x96\xae", "-\xe2\x97\x86\xe2\x97\x86\xe3\x81\x93\xe2\x97\x8b\xe3\x81\xa8'X\xe3\x81\x84\xcb\x87\xf0\x9f\x90\xb1\xe2\x81\xb5&\xe3\x82\xb7k\xe3\x81\x88\xf0\x9f\x90\xb1\xe2\x81\xb5-2T\xe3\x82\xb3j\xc2\xb3'[V\xe3\x81\x8f\xe2\x99\xaa\xc2\xb3&e50\xe3\x81\x84-'Nh\xe2\x99\xa5\xe2\xa7\x97\xc2\xb3'Mku\xe2\x80\xa6\xe1\xb5\x87'Sffvj'Uno}v+v5UN\xe3\x81\x8d*\xe3\x82\x89\xe2\x96\x92MP\xc2\xb9&\xe2\x96\xa4l\xe3\x82\xaa}#-\xe2\x96\xa5Y\xe3\x82\xa6l\xe2\x80\xa2'`V\xe3\x81\x8a\xf0\x9f\x90\xb1\xe1\xb5\x87'][\xe3\x81\x82{\xe2\x97\x8f'_Z\xe2\x88\xa7wj&Mz[0\0&bk\xe3\x81\xaat{'Xc\xe3\x82\x83k\xe2\x97\x8f#\xf0\x9f\x98\x90O\xe2\x96\x88`\0*b\xe3\x81\x8ddR\xc2\xb9#~T\xe3\x81\x97T\0#\\imz\0#Qs\xe3\x81\xa8sS*cbiQ\xc2\xb9*\xe3\x82\xbdb{Q\xc2\xb9#OuUu\0#Vu[z\0#yp3z\0*\xe3\x82\x8a\xe2\x96\x91\xf0\x9f\x90\xb1O\xc2\xb9#\xe3\x81\x88\xe2\x97\x8b\xe2\x96\x88\xe3\x81\x86\0+NvhN\xe2\x81\xb8#t\xec\x9b\x83g\xe2\x88\xa7\0#3{3\xec\x9b\x83\0*\xe3\x81\xaes`R\xc2\xb9*\xe3\x81\xae\xe3\x81\x8a|R\xe2\x96\xa0'Xze\xe2\x8c\x82\0'`\xcb\x874\xe3\x81\x86P-zV\xe2\x98\x89N\xe3\x81\xac-`cuV\xe2\x96\x88*\xe3\x82\x86\xe3\x81\xaasR\xc2\xb9*\xe3\x82\x86\xe3\x81\xaamR\xe2\x96\xa0", "&N|\xe2\x99\xaa\xf0\x9f\x90\xb1\xe2\x81\xb5#N{\xe2\x99\xaa{M*\xe3\x83\xa2F3O\xc2\xb2*XN3P#+^NRN@*\xe3\x83\x844{O!+-NQZ`*\xe3\x81\x82KsR\xc2\xb9", "-\xcb\x87\xe3\x81\x8a\xe3\x81\xb5~\xe2\x81\xb4&m\xe3\x81\x822\xe2\x9c\xbd\xe2\x81\xb4&p\xe2\x96\xa4\xe2\xa7\x97\xe2\x8c\x82	'nl\xe3\x81\x9f\xcb\x87	'qs\xe3\x81\x97\xe2\xa7\x97\xe2\x8c\x82'ZU\xe3\x81\xaa\xe2\x98\x89\xe2\x81\xb5'JQ\xe3\x81\xac3\xc2\xb3*\xe3\x82\xbdpNP\xc2\xb9'SR\xe3\x81\x95s\xe1\xb5\x87*\xe3\x81\x82PpR\xc2\xb9'aT\xf0\x9f\x98\x90[\xe2\x8c\x82*\xe3\x82\x86\xf0\x9f\x90\xb1rQ\xc2\xb9*\xe3\x81\x82\xe3\x81\x82sP\xc2\xb9*\xe3\x82\x86\xec\x9b\x83xP\xc2\xb9'\xe2\x96\x88h\xe3\x81\xa6\xe2\x99\xa5\xe3\x82\x8c*h\xe3\x81\xa6sP\xc2\xb2*\xe3\x81\xae`|R\xe2\x96\xa0*\xe3\x83\xafJuQ\xe2\x96\xa0*\xe3\x83\xafbtQ!*b\xe2\x99\xaa\xe2\x96\x88R\xe2\x96\xa0+NXZNH*\xe3\x83\x84p1P\xc2\xb9*\xe3\x82\x89J_P!*\xe3\x83\x84\xe2\x80\xa61O!#P]\xe3\x81\x91]\xc2\xb3#U_\xe2\x96\x92_\xe2\x8c\x82", "*\xe2\x97\x8fSUO\xc2\xb9*\xe2\x96\x91QMO\xc2\xb9*\xe2\x9c\xbdLMO\xe2\x96\xa0*\xe2\x9c\xbdLUO\xc2\xb9'RPVT\0#TUWU\r", "*\xe2\x96\x91TRO\xc2\xb9", "*\xe2\x9c\xbdROO\xe2\x96\xa0*\xe2\x99\xa5UMO\xc2\xb9*\xe2\x9c\xbdRUO\xc2\xb9*\xe2\x99\xa5OMO!", "*\xe2\x9c\xbdRUO\xc2\xb9*\xe2\x9c\xbdRQO\xe2\x96\xa0*\xe2\x97\x8fOMO\xc2\xb9*\xe2\x97\x8fVMO!", "*\xe2\x96\x91SMO\xc2\xb9*\xe2\x9c\xbdNMO\xe2\x96\xa0*\xe2\x9c\xbdNUO\xc2\xb9'TPXT\0#VUXU\r", "*\xe2\x99\xa5PYO\xc2\xb9*\xe2\x99\xa5NSO\xc2\xb9*\xe2\x99\xa5PMO\xc2\xb9*\xe2\x9c\xbdLNO\xe2\x96\xa0*\xe2\x9c\xbdLUO\xc2\xb9", "*rQYR1*rJSR\xe2\x96\xa0'Ehv1\xc2\xb9'Flu\xe2\x80\xa6c'Hpw\xe2\xa7\x97\xe3\x81\xa6'Ftu\xe2\x80\xa6\xe3\x82\x81*\xe3\x81\xabEvP\xc2\xb9*tC~P1'Lxj2\0&E\xe2\x9c\xbdR0\0#KwRq	#RxYu	#EuFq	#GpLo	#KpGq\xe2\x81\xb8#RrMv\xe2\x81\xb8#XvRy\xe2\x81\xb8#_xgo\xe1\xb6\xa0#`WZ_\xc2\xb2#^XX`\xe2\x81\xb4#bjgn\xe1\xb6\xa0#`iYZ\xe1\xb6\xa0#XV`g\xe2\x81\xb4#bihn\xe2\x81\xb4#ho_y\xe2\x81\xb4#d[hc\xe2\x81\xb4#gdWq\xe2\x81\xb4#c[gc\xe1\xb6\xa0#fdWp\xe1\xb6\xa0#Y`Kg\xc2\xb2#LhNl\xc2\xb2#NlSo\xc2\xb2#W`Lf\xe2\x81\xb4#KgMl\xe2\x81\xb4#NmRo\xe2\x81\xb4#LZQf\xe2\x81\xb4#KZPf\xe1\xb6\xa0#Rg]r\xe2\x81\xb4#Qg\\r\xe1\xb6\xa0+N\xe2\x96\x91ONx*\xe3\x83\x86R\xe2\x97\x8bP\xc2\xb3*\xe3\x82\xa6b\xe2\x97\x8bO\xc2\xb9*\xe3\x82\xa8b\xe2\x99\xa5O\xc2\xb9*\xe3\x82\xa8b\xe2\x97\x86O\xe2\x96\xa0"}
dither_p = split "32768,32736,24544,24416,23392,23391,23135,23131,6747,6731,2635,2571,523,521,9,1"
e_data = split("1,8,8,240,0,20 1,8,8,180,0,20 99,144,2,0,100 99,4,4,0,-4,0 99,6,6,90,12,0 1,8,8,160,56,20 1,8,8,150,24,50 24,12,8,120,0,50 26,12,8,90,128,80 6,8,8,240,0,50 1,4,4,150,16,10 1,8,8,110,20,20 1,8,8,60,16,20 30,4,4,200,0,1000 8,12,16,120,12,50 1,4,4,120,16,10 20,16,8,200,32,60 10,8,8,32,0,50 30,6,6,620,0,1200 1,8,8,0,32,40 15,8,8,60,1,130 2,8,8,360,12,220 30,31,8,120,0,80 20,20,8,0,0,60 24,16,8,100,0,80 15,8,4,0,0,18 12,8,4,240,16,60 30,16,8,480,0,600 1,8,8,120,192,40 30,8,12,360,0,1500", " ")
brush_d = {split("1,768,0,56,0,0 6,1120,0,88,0,0 5,1504,0,96,0,0 4,1974,4,40,0,0 3,1980,0,64,0,0", " "), split("8,1456,42,64,0,0", " ")}

function trifill(x1, y1, x2, y2, c)
  local inc = sgn(y2 - y1)
  local fy = y2 - y1 + inc / 2
  for i = inc // 2, fy, inc do
    line(x1 + .5, y1 + i, x1 + (x2 - x1) * i / fy + .5, y1 + i, c)
  end
  line(x1, y1, x2, y2)
end

function pd_draw(index, cx, cy, s_start, h_flip, v_flip, s_end)
  local cmd

  local function _fillp(p, x, y)
    --@sparr/@Felice
    local p16, x = p // 1, x & 3
    local f, p32 = (15 >> x) // 1 * 0x1111, p16 + (p16 >>> 16) >>< (y & 3) * 4 + x
    return fillp(p - p16 + ((p32 & f) + (p32 <<> 4 & 0xffff - f)) // 1)
  end

  local function _flip(p, f, o, n)
    if n > 0 then
      cmd[n] = not cmd[n]
    else
      f = 64
    end
    for i = 0, (o == 0 and n > 0) and 2 or 0, 2 do
      cmd[p + i] = f - cmd[p + i] - o
    end
  end

  local ox, ecx, oy, ecy = peek2(0x5f28), round(peek2(0x5f28) - cx), peek2(0x5f2a), round(peek2(0x5f2a) - cy)
  camera(ecx, ecy)
  if not brush_c[index] then
    brush_c[index] = {}
  end
  for i = s_start and s_start * 6 - 5 or 1, s_end and s_end or #brush_s[index], 6 do
    if brush_c[index][i] then
      cmd = {unpack(brush_c[index][i])}
    else
      cmd = {ord(brush_s[index], i, 6)}
      cmd[1] = cmd[1] + (46)
      for j = 1, 5 do
        cmd[j] = cmd[j] - (78)
      end
      cmd[7] = (cmd[6] & 240) >> 4
      cmd[6] = cmd[6] & (15)
      if cmd[1] == 10 then
        cmd[8], cmd[7] = cmd[7] % 2 == 1, cmd[7] // 2 == 1
      end
      if cmd[1] == 11 then
        add(cmd, index, 2)
        cmd[6] = cmd[6] * (8)
        cmd[7] = cmd[7] * (8)
        cmd[8] = i - 6
      end
      brush_c[index][i] = {unpack(cmd)}
    end
    local cc, c6 = deli(cmd, 1), cmd[6]
    if cc == 10 then
      pdx, pdox, pdoy, pdon = 2, cmd[4] * 8 - 1, cmd[5] * 8 - 1, 6
    elseif cc == 11 then
      f_exp(_ENV, "pdx,5,pdox,0,pdoy,0,pdon,-2")
    else
      f_exp(_ENV, "pdx,1,pdox,0,pdoy,0,pdon,6")
      if c6 > 0 then
        _fillp(-dither_p[c6] + .5, -ecx, -ecy)
      end
    end
    if h_flip and h_flip ~= 0 then
      _flip(pdx, h_flip, pdox, pdon)
    end
    if v_flip and v_flip ~= 0 then
      _flip(pdx + 1, v_flip, pdoy, pdon + 1)
    end
    _ENV[split("rect,oval,line,map,select,rectfill,ovalfill,tri,pset,spr,pd_draw,,trifill")[cc]](unpack(cmd))
    fillp()
  end
  camera(ox, oy)
end

function pd_rotate(x, y, rot, mx, my, w, flip, scale)
  scale = scale or 1
  rot = rot // .05 * .05
  w = w * (scale * 4)
  local cs, ss = rot_coord(rot, .125 / scale)
  local sx, sy = mx + .5 + cs * -w, my + w / 8 + ss * -w
  local hx = flip and -w or w
  local halfw = -w
  for py = y - w, y + w do
    tline(x - hx, py, x + hx, py, sx - ss * halfw, sy + cs * halfw, cs, ss)
    halfw = halfw + (1)
  end
end

function round(n)
  return (n + .5) // 1
end

function any(x, s)
  for e in all(split(s)) do
    if x == e then
      return true
    end
  end
end

function f_exp(e, k)
  --@freds72/@paranoidcactus
  local kv = split(k)
  for i = 1, #kv, 2 do
    e[kv[i]] = kv[i + 1] == "" and {} or kv[i + 1]
  end
end

function a_exp(e, k, ...)
  local kv, v = split(k), {...}
  for i = 1, #kv do
    e[kv[i]] = v[i]
  end
end

function intersects(a, b)
  local _ENV, d = a, e_delta_y(b)
  return not (x2 < b.x1 or x1 > b.x2 or y2 < b.y1 + d or y1 > b.y2 + d)
end

function rot_coord(a, k)
  return k * cos(a), k * sin(a)
end

function pal_d(s)
  pal(s and split(s) or nil)
  palt(16)
end

function pal_fade(x, out)
  local i = min((cam_x - x) // 4, 3)
  pal_d(split("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 0,0,0,1,0,5,5,1,1,4,1,1,1,2,2 0,1,1,2,1,13,6,4,4,9,3,13,1,13,14 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15", " ")[out and 4 - i or i + 1])
end

function _init()
  f_exp(_ENV, "map_tile_w,32,map_tile_h,8,bull_speed,3,beam_speed,4,special_speed,4,laser_speed,3,x,0,y,0,st,0,c_stage,0,r9_lives,4,r9_score,0,cam_x,135,brush_c,")
  if not boss_x then
    for i = 0, 818 do
      local l = peek(0x2830 + (i \ 64) * 128 + i % 64)
      for xs = 0, l % 128 do
        sset(x, y, l // 128 * 1)
        x = x + (1)
        if x > 127 then
          y = y + (1)
          x = 0
        end
      end
    end
    memset(24336, 0, 16)
    cls(11)
    for y = 0, 2 do
      for x = 0, 3 do
        s = 32
        for i = 0, 3 - y * x % 4 do
          pal(1, split "4,9,6,10" [i + 1])
          sspr(x * 32, y * 32, 32, 32, x * 32 + i, y * 32 + i, s, s)
          s = s - (i / 2 + 2)
        end
      end
    end
    memcpy(0x4300, 0x6000, 5008)
    memset(0x5680, 0xbb, 1024)
    for y = 0, 2048, 64 do
      memcpy(0x5300 + y, 0x1800 + y, 16)
    end
    reload()
  end
  invincible, boss_x = false, split "1980,1514,1560,1530"
  music(61)
end

function bbox(e, ky)
  local ky, _ENV = ky or 0, e
  x1, y1, x2, y2 = x - w, y - h + ky, x + w, y + h + ky
  if x1 > x2 then
    ky = x1
    x1 = x2
    x2 = ky
  end
  if y1 > y2 then
    ky = y1
    y1 = y2
    y2 = ky
  end
  x2 = x2 - (1)
  y2 = y2 - (1)
end

function bull_create(parent, ...)
  local b = add(parent, {})
  a_exp(b, "id,x,y,w,h,dx,dy", ...)
  if b.id > 90 then
    sfx(4)
  end
  local _ENV = b
  sx, cnt, ox, oy, f = (id == 1 or id == 3) and 0 or x - w / 2, 0, dx, dy, true
  return b
end

function bull_def(x, y, sy)
  sy = sy or 0
  local sx = abs(sy) == bull_speed and 0 or bull_speed
  if beam_pwr / 9 < 1 then
    bull_create(r9_bullet, 0, x, y, sx == 0 and 1 or 3, sx == 0 and 3 or 1, sx, sy)
  end
end

function bull_draw(b)
  local function bd(id, b, ...)
    spr(id, b.x1, b.y1, ...)
  end

  local bt = b.id
  if any(bt, "0,4,6") then
    if abs(b.dy) == bull_speed then
      sspr(14, 8, 2, 6, b.x1, b.y1)
    else
      if bt == 4 then
        pal_d "1,2,3,4,1,14,8,8,9,10,11,2,8"
      end
      if bt == 6 then
        pal_d "1,2,3,4,1,6,12"
      end
      sspr(10, 14, 6, 2, b.x1, b.y1)
    end
  elseif bt == 1 then
    local dir = b.w
    line(b.x - dir, b.y - b.h, b.x + dir, b.y + b.h, 12)
  elseif bt == 2 then
    local g, _ENV = _ENV, b
    if dx < 0 then
      ex, sx = sx, -w * 2
    end
    for i = 0, 1 do
      for x = sx + 22, 160, 34 do
        clip(x1, y1 - 4 + (i * 13), w * 2, 13)
        if i == 1 then
          g.pal_d "1,2,3,4,5,6,7,13,9,10,11,14,8,12"
        end
        g.pd_draw(10, x, y1, 1, 0, 0, x > sx + 22 and 24 or 36)
      end
    end
  elseif bt == 3 then
    if b.f then
      bd(213, b)
    end
  elseif bt == 90 then
    bd(17, b, .5, .5)
  elseif bt == 93 then
    bd(35, b, 1, 1)
  elseif bt == 96 then
    bd(205, b)
  elseif any(bt, "5,92") then
    if bt == 5 then
      clip(r9.x, b.y1, b.x2, b.y2)
    end
    pd_draw(11, b.x1 - 8, b.y1 - 9, 1, (sgn(b.dx) - 1) * -14, 0, 18 + b.w // 4 * 18)
  elseif any(bt, "7,91,97") then
    if bt > 7 then
      b.r = atan2(b.dx, b.dy)
    end
    local r = b.r - .25
    circfill(b.x1 - sin(r) * 5, b.y + cos(r) * 5, b.cnt % 3, 9)
    pd_rotate(b.x1, b.y, -r, bt == 97 and 124 or 122, 12, 1)
  else
    bd(bt, b)
  end
  pal_d()
  clip()
end

function bull_missile(y)
  local b = bull_create(r9_bullet, 7, r9.x, r9.y - y, 3, 3, 2, 0)
  b.mx, b.my = 256, y
  return b
end

function bull_visibility(b)
  local bbox, _ENV = bbox, b
  x = x + (dx)
  y = y + (dy)
  bbox(b)
  if x1 > 132 or x2 < -4 or y2 < 0 or y1 > 120 then
    w = -128
  end
end

function bull_update(b)
  local function collide_map(x, y)
    local m = mget(bgx + (cam_x + x) // map_tile_w, bgy + y // map_tile_h)
    return y > 0 and y < 120 and (m > 0 and (m < 106 or m == 107)) or ws_collide(x, y)
  end

  id = b.id
  if id == 3 then
    b.x = b.x - (cam_sx)
    local bull_visibility, _ENV = bull_visibility, b
    f = not f
    if collide_map(x, y + dy) then
      dy, cnt = 0, 1
    else
      dy, cnt = oy, 0
    end
    local c = collide_map(x + ox, y)
    if c or cnt == 0 then
      dx = 0
      if cnt == 1 then
        oy = -oy
      end
    else
      dx = ox
    end
    bull_visibility(b)
    if c and not collide_map(x + ox, y) then
      if cnt == 0 then
        oy, cnt = -oy, 1
        x = x + (ox)
        y = y + (dy)
      end
    else
      dy = oy
    end
    sx = sx + (1)
  else
    b.cnt = b.cnt + (1)
    b.r = 0
    if id == 91 then
      b.dy = b.dy + (.04)
    elseif id == 97 and b.cnt > 32 then
      b.dy, b.dx = b.dy * .92, sgn(b.dx) * 1.2
    elseif id == 7 and b.cnt > 8 and b.closest then
      b.r = atan2(b.mx, b.my)
      b.dx, b.dy = rot_coord(b.r, 2)
    end
    bull_visibility(b)
    if (id > 96) then
      for fb in all(r9_bullet) do
        if intersects(fb, b) then
          b.w = 0
          fb.w = fb.w - (1)
          explo_create(b.x2, b.y, 8)
        end
      end
    end
    if level_collide(b) then
      if any(id, "0,4,7,6,91,97,90") then
        b.w = b.w - (b.w)
      elseif id == 1 and b.w > -128 then
        sfx(5)
        local cam_x, _ENV = cam_x, b
        if dy == 0 or (x + cam_x + w / 2) % 32 <= dx then
          dx, w = -dx, -w
          x = x + (dx)
          sx = sx + (1)
        else
          dy, h = -dy, -h
          y = y + (dy)
          sx = sx + (1)
        end
      elseif id == 2 then
        b.w = b.w - (min(b.w, 4))
      elseif id == 5 then
        b.w = b.w - (min(b.w, 8))
        if b.w < 8 then
          explo_create(b.x, b.y, 16)
        end
      end
    end
  end
  if force.x1 and b.id == 90 and intersects(force, b) then
    b.w = 0
  elseif id > 40 then
    r9_hit(b, 0)
  end
  local t = id > 47 and e_bullet or r9_bullet
  if b.w == 0 or b.w <= -128 or ((id == 1 or id == 3) and b.sx > 16 * id) then
    del(t, b)
    if id == 1 then
      lasers = lasers - (1)
    elseif any(id, "7,91,97") then
      explo_create(b.x, b.y, -16)
      if id == 7 then
        del(missiles, b)
      end
    end
  end
end

function e_def(e, k)
  bbox(e, k)
  if force.x1 and intersects(force, e) then
    e.dmg = 1.1
    e_hit(e)
  elseif not ending then
    r9_hit(e)
  end
  local eid, x, y, x1 = e_local(e)
  e.atn = atan2(r9.x - x, r9.y - y - e_delta_y(e))
  if e.hit > 0 then
    e.hit = e.hit - (1)
  end
  if e.hp ~= 0 then
    e.dmg = 0
    for b in all(r9_bullet) do
      --no foreach
      if (eid > 1 or e.r <= .2 or e.r >= .8) and intersects(b, e) then
        local g, _ENV = _ENV, b
        if g.any(id, "0,1,2,3,4,6,7") then
          if id < 1 or id > 2 then
            w = 0
          end
          e.dmg = g.any(id, "0,7") and 1 or g.force_power * 1.1
        elseif id == 5 then
          w = w - (e.hp > 1 and min(w, 8) or 0)
          e.dmg = w // 4 + 2
          break
        end
      end
    end
    e_hit(e)
    if eid ~= 15 and eid ~= 18 and e.tshot > 0 and ((x < 128 or eid == 23)) and e.hp < 99 then
      e.tshot = e.tshot - (1)
      if eid == 10 or eid == 28 then
        for i = 0, 7 do
          if e.tshot == i * 20 then
            bull_create(e_bullet, eid == 10 and 91 or 96, x + (eid == 10 and 8 or -16 + rnd(24)), y, 3, 3, -.8, -2.4)
          end
        end
      elseif e.tshot == 0 then
        local bsx, bsy = rot_coord(e.atn, .85)
        if eid == 2 and (y < 40 or cam_x < 1448) then
          for i = 0, 1, .25 do
            bull_create(e_bullet, 93, x, y, 3, 3, rot_coord(i, 1))
          end
        elseif eid == 8 then
          bull_create(e_bullet, 92, x, y, 8, 4, 2 * sgn(bsx), 0)
        elseif eid == 23 then
          bull_create(e_bullet, 92, x1, x > 124 and y + e_delta_y(e) or 88, 8, 4, -2, 0)
        elseif eid == 9 then
          for i = 3, 7 do
            bull_create(e_bullet, 97, x, y, 3, 3, e.sgx * cos(i / 10), sin(i / 10) * 1.2)
          end
        elseif eid == 14 then
          add(ce, split "5,2000,60,4,0")
        elseif eid == 30 then
          add(ce, split "5,1570,60,1,0")
        elseif eid == 17 then
          add(ce, {18, e.x + cam_x, e.y, 1, 2})
        elseif eid == 25 then
          for i = 0, 3 do
            bull_create(e_bullet, 96, x, y + shell.delta, 4, 4, -1.5, (i - 1) // 2)
          end
        elseif eid < 23 and eid ~= 16 then
          bull_create(e_bullet, 90, x, y + e_delta_y(e), 2, 2, bsx, bsy)
        end
      end
      if e.tshot <= 0 then
        e.tshot = e.shot
      end
    end
  else
    explo_create(x, y + e_delta_y(e), e.w > 6 and 32 or 24)
    r9_score = r9_score + (e.score)
    if eid == 20 then
      bull_create(e_bullet, abs(e.who), x, y, 4, 4, -cam_sx, 0)
    end
    for m in all(missiles or {}) do
      if e == m.closest then
        m.closest = nil
      end
    end
    if eid > 5 then
      if eid == 29 and e.i > 0 then
        e_set(e)
      else
        del(ce, e)
      end
    else
      e.hp = 99
    end
    return true
  end
end

function e_delta_y(e)
  return (e.i and e.id > 20 and (e.id ~= 23 or e.y == 110)) and shell.delta or 0
end

function e_draw(e)
  local function e_legs()
    local f, _ENV = e.dx > 0, e
    local o = cnt // 8 % 4
    if o == 3 or cnt < 0 then
      o = 1
    end
    spr(f and 248 - o or 246 + o, x1 + (f and 2 or 8) - o, y1 + 7, 1, 1, f)
    return o
  end

  if e.x1 and not ending then
    if e.hit % 2 == 1 then
      pal_d "12,6,6,6,6,7,7,7,7,7,7,7,7,7,7"
    end
    local id, x, y, x1, x2, y1, y2, f, r, dx, dy = e_local(e)

    function esd(id, ...)
      spr(id, x1, y1, ...)
    end

    local tt = {nil, nil, function()
      pal(12, 11)
      for i = 1, 3 do
        pd_draw(15 + i, x1 + split "-4,128,192" [i], y - 45)
      end
    end, function()
      esd(e.i == 9 and 34 or 33)
    end, function()
      if c_stage == 4 then
        pal_d "0,1,0,0,0,12,7,12,13,12,12,12,1,7,7"
        r = x / 25
      else
        pal_d "2,2,8,0,5,6,0,8,5,5,13,0,13,14,13"
      end
      pd_rotate(x1 + 6, y1 + 6, -r, 126.5, 3, 2, false, .75)
    end, function()
      spr(130, x1, y1 - e_legs(e), 2, 2, f)
    end, function()
      esd(46, 2, 2, dx > 0)
    end, nil, nil, function()
      --10
      e.r = e.r + ((e.tshot < 160 and e.tshot > 110) and -.005 or (e.tshot > 190 and e.r < 0) and .005 or 0)
      pd_rotate(x + (f and 0 or -2), y, e.r, 122.5, 2.5, 3, f)
      pal_d "1,3,3,12,5,6,7,8,6"
      e_legs(e)
    end, function()
      esd(196, 1, 1, e.dsx < 0, y < 64)
    end, function()
      for i = 0, 1 do
        sspr(96, 24, 16, 8, x1, y1 + 8 + e.s * (i - 1) - i, 16, e.s, false, i == 0)
      end
    end, function()
      pd_rotate(x, y1 + 8, -r / 180, 123.5, 0, 2)
      pd_rotate(x, y1 + 8, r / 180 - .5, 123.5, 0, 2, true)
    end, function()
      esd(212)
    end, function()
      local vf = e.r > 0
      spr(133, x1, y1 + (vf and 24 or 0), 3, 1, f ~= (y1 % 8 < 4), vf)
      spr(149, x1, y1 + (vf and 0 or 8), 3, 3, f, vf)
    end, function()
      esd(50)
    end, function()
      esd(236 + r, 2, 2, false, y < 64)
      spr(236 + r, x1 + 16, y1, 2, 2, true, y < 64)
    end, function()
      esd(e.hp < 7 and 206 or 198, 2, 2, e.x % 8 < 4)
    end, function()
      if e.hit <= 4 then
        pal_d "1,2,3,4,1,13,7,12,9,10,11,12,1,1,12"
      end
      esd(24, 2, 1)
      pal_d "1,2,3,4,2,8,15,8,9,10,11,12,2,14,14"
      spr(24, x - 62 + y1, 98 - y1, 2, 1)
      spr(24, x + 50 - y1, 98 - y1, 2, 1, true)
    end, function()
      esd(24, 2, 2, dx > 0)
    end,
    --20
    function()
      esd(228, 2, 2, r > 0, y < 64)
    end, function()
      pd_rotate(x1 + 6, y1 + 6, .25 - (e.atn or 0), 123, 9, 2.5)
    end, function()
      pd_draw(id - 9, x1, y1)
    end, function()
      pd_draw(id - 9, x1, y1)
    end, function()
      if e.tshot < 40 then
        sspr(106, 96, 6, 9, x1, y1, -16 - rnd(24), 16)
      end
      pd_draw(13, x1, y1)
    end, function()
      esd(12, 2, 1, true)
    end, function()
      esd(58, 2, 1, true)
      if e.tshot < 40 then
        r = 16 + rnd(16)
        e.h = e.h + (r)
        bbox(e)
        sspr(104, 96, 8, 16, x1 + 2, y2, 12, e.h)
        e.h = e.h - (r)
      end
    end, function()
      esd(188, 4, 1, false, true)
      spr(188, x1, y1 + 8, 4, 1, false, false)
    end, function()
      pd_rotate(x, y, -r // 2 * .25, 119.5, x // 8 % 5 * 3, 2.5, f)
    end, function()
      pd_draw(25, x1, y - 62)
    end,
    --30
    }
    if id < 3 then
      if e.hp == 99 then
        pal_d "1,13,5,5,1,5,6,6,5,6,6,6,13,13,6"
      end
      pd_rotate(x1 + 8, y1 + 8, -r + (e.i > 7 and 1 / id or 0), 126.5, (id == 2 and split "9,12,6,6,6,6,6,6,12,9" or split "0,0,3,0,0,0,0,0,0,0,0")[e.i + 1], 2)
    elseif any(id, "8,9") then
      if x % 2 < 1 and (dx == .8 or dx == 0) then
        spr(221, x + (f and -15 or 7), y - 2)
      end
      if id == 9 then
        palt(4536)
      elseif e.hit % 2 == 0 then
        pal_d "1,1,3,3,5,12,7,8,11,6,11,6,3,12,13"
      end
      esd(202, 3, 2, f)
      spr(234, x1 - 2 * sgn(dx - .1), y1 + 15 - 3.5 * dy, 3, 1, f)
    elseif id > 20 and id < 29 and not shell then
      return
    else
      tt[id]()
    end
  end
  pal_d()
end

function e_hit(e)
  local _ENV, sfx = e, sfx
  if hit > 0 or hp == 99 then
    return
  end
  if ((id == 30 and dmg > 1) or (id ~= 30 and dmg > 0)) then
    hp = max(hp - dmg)
    if hp > 1 then
      hit = 12
      sfx(6, 2)
    end
  end
end

function e_local(e)
  local round, _ENV = round, e
  return id, x, y, round(x1), x2, round(y1), y2, f, r, dx, dy, cnt
end

function e_set(e)
  local _ENV = e
  x, hp, y = (x + 80) % 190, 1, r > 0 and 0 or 120
end

function e_visible(e)
  local edata = split(e_data[e[1]])

  local function e_activate(en, idx)
    f_exp(en, "oa,0,os,1,cnt,0,r,0,hit,0")
    a_exp(en, "id,x,y,copy,who", unpack(e))
    a_exp(en, "hp,w,h,shot,dw,score", unpack(edata))
    local g, _ENV = _ENV, en
    i = id == 18 and 1 or idx
    local ws = (2 ^ i & who)
    tshot = ws > 1 and (g.rnd(shot) + 1) // 1 or ws * shot
    x = x - (g.cam_x)
    if id == 20 then
      f = who < 0
      x = x - ((f and 132 or 0))
    elseif id == 22 then
      y = y - (i * 8 * g.sgn(copy))
    end
  end

  if not e.i and (e[2] - edata[2] < cam_x + (e[1] < 5 and 160 or 128)) then
    e_activate(e, 0)
    if (e.id == 2 and e.i == 0) or e.id == 3 then
      shell = e
      shell.delta = 0
    end
    if e.copy == 0 then
      e.r = 1
    end
    for i = 1, abs(e.copy) - 1 do
      et = add(ce, {})
      e_activate(et, i)
      if et.id == 1 and et.i == 2 then
        et.hp, shell = 6, et
      end
      local _ENV = et
      if y < 0 then
        y = y - (i * dw)
      else
        x = x + (i * dw)
      end
    end
  end
  if e.x2 and not any(e.id, "20,28") and e.x2 < -48 then
    del(ce, e)
    return
  end
  return not ending and (e.i and (e.i > 0 or e.x - e.w < ((e.id <= 5 or (c_stage == 3 and cam_x == 1500)) and 232 or 128)))
end

function e_update(e)
  if e_visible(e) then
    function bull_homing(m)
      local emx, emy, abs, _ENV = e.x - m.x, e.y + e_delta_y(e) - m.y, abs, e
      if id < 5 or x > 128 or x < m.x then
        return
      end
      if e.x > m.x and (not m.closest or abs(emx + emy) < abs(m.mx + m.my)) then
        m.closest, m.mx, m.my = e, emx, emy
      end
    end

    if respawn_t == 0 and e.id ~= 2 then
      e.x = e.x - (cam_sx)
    end
    foreach(missiles, bull_homing)
    local f_exp, g, cam_x, rnd, bbox, map_collide, shell, rot_coord, e_def, _ENV = f_exp, _ENV, cam_x, rnd, bbox, map_collide, shell, rot_coord, e_def, e
    dsx, dsy = x - g.r9.x, y + g.e_delta_y(e) - g.r9.y
    sgx, sgy, adx, ady = g.sgn(dsx), g.sgn(dsy), g.abs(dsx), g.abs(dsy)
    if id < 2 then
      if shell.hp == 99 and hp == 1 then
        hp = -5 * i
      end
      if hp < 0 then
        hp = hp + (1)
      end
      r, ox = not x1 and .07 * i or (r + .00225) % 1, x
      c, s = rot_coord(r, 40)
      x, y = ox + c + 8, 60 + s
      e_def(e)
      x = ox
    elseif id == 4 then
      c, s = rot_coord(r + i / 28, 2.5 * i)
      c1 = rot_coord(2 * r + i / 28, 1.5 * i)
      kx, ky = c1 + 4, s + 4 - 2.5 * i
      x = x + (kx)
      --this could be like other "snakes"
      y = y + (ky)
      e_def(e)
      x = x - (kx)
      y = y - (ky)
      r = (r + .0075) % 1
    elseif (id == 2 and shell.x) or id == 5 then
      hp, mul = (i < 2 or i > 7) and 255 or (cam_x == 1454 and y > 64) and 1 or hp, .003
      if id == 2 and (i > 0 or cam_x > 1448) then
        if i == 0 then
          mul = cnt % 2 == 0 and .003 or -.003
          pr = (pr + mul) % 1
          tr = g.round(100 * pr)
          if not gk or (tr == 76 and mul < 0) or (tr == 74 and mul > 0) then
            if g.any(cnt, "2,3,6,10,13,15") then
              f_exp(e, "gk,59,gy,64")
            elseif g.any(cnt, "1,4,7,8,12,14") then
              f_exp(e, "gk,44,gy,42")
            else
              f_exp(e, "gk,16,gy,88")
            end
            cnt = (cnt + 1) % 16
          end
          c, s = rot_coord(pr, gk)
          px, py = 66 + c, gy + s
        end
        dx, dy = (shell.px - x) / 14, (shell.py - y) / 14
        r = atan2(dx, dy)
        x = x + (dx)
        if cam_x == 1454 then
          x = x + ((x < 64 and -7 or 7) * mul * min(i, 5))
        end
        y = y + (dy)
      elseif id == 5 and g.c_stage == 1 then
        x = x - (2)
        r = (r + .05) % 1
        if not dy then
          dy = ady // 1 > 24 and -.75 * sgy or 0
        end
        if x < 72 then
          y = y + (dy)
        end
      elseif i == 0 then
        if id == 5 or cam_x < 1430 then
          local sk = os % 1 / 44
          if x < 8 or x > 158 or y < 8 or y > 112 then
            os = os + (.25)
            r = r + (sk)
          --@GregodEl
          elseif rnd() < .05 then
            os = rnd(1)
            r = r + (sk)
          end
        else
          pr, r = r, (r + mul) % 1
        end
        x = x + ((id == 5 and -1 or 1) * cos(r))
        y = y + (sin(r))
      end
      shell.px, shell.py = x, y
      e_def(e)
    elseif id == 3 or id > 20 and id < 29 then
      x = x + ((cam_x % 60 < 16 and cam_x < 1390) and 0 or g.cam_sx)
      local w = e_def(e)
      if shell.x1 then
        if id == 3 then
          local bd = 0
          if cam_x > 1490 then
            r = (r + .00075) % 4
            bd = 8
          end
          local v = g.split "180,310,.075,900,1004,.075,1360,1440,.075,1470,1500,.075,310,900,-.075,1010,1350,-.075"
          for i = 1, 18, 3 do
            if v[i] < cam_x and cam_x < v[i + 1] then
              delta = delta + (v[i + 2])
              break
            end
          end
          delta = mid(-32 + 4 * bd, delta + (cam_x == 1500 and -.075 * sin(r) or 0), 24 - bd)
          y = 62 + delta
        else
          if (id == 23 or id == 25) and x < 62 * (id == 25 and 1 or 2.2) then
            x = x - (.15)
            y = id == 25 and 76 or (y > 88 and 76 or min(y + .25, 88))
            e_def(e)
          else
            y1 = y1 + (shell.delta)
            y2 = y2 + (shell.delta)
            if id == 28 then
              r = (r + .002) % 3
              if x2 < 132 then
                x = x + (cos(r) / 6)
              end
              if w then
                g.do_ending()
              end
            end
          end
        end
        x = x + (cam_x > 1490 and cos(shell.r) / 4.5 or 0)
      end
    elseif g.any(id, "7,13,16,20") then
      if id == 7 then
        dx, dy, s = (adx < 90 and dx) or -.5 * (sgx - .35), ((adx < 64 and ady > 4) and -.35 * sgy or 0), 0
      else
        dx, dy = (id == 20 and .75 or 1) * (f and .75 or -1), 0
      end
      x = x + (dx)
      bbox(e)
      if id ~= 16 and map_collide(e) then
        x = x - (dx)
        if id == 7 then
          dx = -dx
        else
          f = not f
        end
      end
      r, s = rot_coord(x / 128, id == 13 and 12 or id // 2)
      if id ~= 7 then
        if y < 32 and id == 13 then
          r = 65 - y
          x = x - (dx)
          dy = 1.25
          dy = max(dy - .25)
        end
        if id == 16 and tshot > 0 and tshot < 40 then
          dy = 1
        end
      end
      y = y + (dy)
      e_def(e, s)
      if map_collide(e) then
        y = y - (dy)
      end
    elseif g.any(id, "8,9") then
      f, dy = dsx < 0, ady < 1 and 0 or -.3 * sgy
      dx = ((adx < 48 or tshot < 15) and .8 or 0) * (f and -1 or 1) + (f and .35 or 0)
      bbox(e)
      if map_collide(e) then
        x = x - (dx)
      end
      if y < 96 or adx <= 64 then
        y = y + (dy)
      end
      e_def(e)
      if map_collide(e) then
        y = y - (dy)
      end
      if y < 96 and x < 124 then
        x = x + (dx)
      else
        dy = 0
      end
    elseif g.any(id, "6,10") then
      if id == 6 or r == 0 then
        cnt = cnt + (1)
      end
      dx, dy = dx or -.25, 1
      f = dx < 0
      if (id == 10 and r == 0) or (y > 87 and id == 6) then
        x = x + (dx)
      end
      bbox(e)
      if map_collide(e) or (x2 < 0 and dx == -.25) then
        x = x - (dx)
        dx = (dx == -.25 and .6 or -.25)
      end
      y = y + (dy)
      e_def(e)
      if map_collide(e) then
        y = y - (dy)
      else
        cnt = 0
      end
    elseif id == 11 then
      e_def(e)
      if map_collide(e) then
        y = y + (y > 64 and -8 or 8)
      end
    elseif id == 12 then
      x = x - (.75)
      c = g.abs(cos(x / 26))
      s = max(2, 8 * c)
      e_def(e, 8 * sin(x / 64))
    elseif g.any(id, "14,19,30") then
      r = (r + .01) % 4
      c1, s1 = rot_coord(r, .125)
      if id == 14 and r < 3 then
        x = x + (c1)
        g.brushes[4][2] = 1974 + c1 * (tshot < 50 and 16 or 0)
      elseif r < 2 then
        y = y + (s1)
      end
      if e_def(e) then
        g.do_ending()
      end
    elseif g.any(id, "15,29") then
      if (dx or (dsx < (1 + i % 2 * -1) * 64) and tshot > 0) and hit < 2 then
        dx = f and .4 or -.4 + g.cam_sx
        y = y + (r)
        x = x + (dx)
      end
      if r == 0 then
        r, f = (y > 10 and -1 or 1) * (id == 15 and .8 or .8 + g.cam_sx), i % 2 ~= 0
      elseif id == 29 and dx and ady > 104 then
        g.e_set(e)
      end
      e_def(e)
    elseif id == 17 then
      r = tshot < 30 and 2 or 0
      e_def(e)
      y1 = y1 + ((tshot < 40 and rnd(2) or 0))
    elseif id == 18 then
      if (not tx and not ty) or adx > 48 or ady > 48 then
        tx = 64 - sgx * (16 + tshot)
        ty = 60 - sgy * (16 + tshot)
      end
      dx, dy = tx > x and .45 or -.2, (hit > 0 and hp < 7) and 2 or (ty > y and .2 or -.2)
      x = x + (dx)
      y = y + (dy)
      e_def(e)
    end
  end
end

function do_ending()
  ending = true
  music(63)
  sfx(3, -2)
  if force_type > 0 and force.status > 0 then
    force.status = 3
  end
end

function explo_create(...)
  if #explos >= 12 then
    return
  end
  local e = add(explos, {})
  sfx(7, 2)
  a_exp(e, "x,y,k", ...)
  if e.k < 0 then
    f_exp(e, "k,16,w,16,d,8,frm,18")
  else
    f_exp(e, "w,32,d,4,frm,0")
  end
end

function explo_draw(e)
  --if frm !=last_frame then
  --last_frame=frm
  if e.frm % e.k > 7 then
    del(explos, e)
  end
  local _ENV = e
  for y = 1, w do
    local c = y * 64
    memcpy(0x17C0 + c, 0x42C0 + c + frm // 1 % d * w // 2 + frm // d * 2048, w // 2)
  end
  --end
  if c_stage == 4 then
    pal_d "1,2,3,1,5,12,7,8,13,6,11,12,13,14,15"
  end
  sspr(0, 96, w, w, x - k / 2, y - k / 2, k, k)
  frm = frm + (.35)
end

function r9_explode()
  if not invincible then
    explo_create(r9.x - 4, r9.y, 24)
    r9.hit = true
  end
end

function r9_hit(e, screen)
  local id = e.id
  if not r9.hit and intersects(r9, e) then
    if screen and id < 54 then
      if id == 48 and r9.acc < 1.65 then
        r9.acc = r9.acc + (.15)
        r9_auto = 25
      end
      if id == 49 then
        missiles = missiles or {}
      end
      if id > 50 then
        force_type = id - 50
        force_power = min(force_power + 1, 2)
      end
      del(e_bullet, e)
      r9_score = r9_score + (40)
      sfx(2)
    else
      r9_explode()
    end
  end
  return r9.hit
end

function r9_init(w)
  level_init(w)
  sfx(3, -2)
  f_exp(_ENV, "beam_pwr,0,lasers,0,respawn_t,0,r9_auto,40,r9,,r9_bullet,,force,,force_type,0,shot_delay,0,force_power,-1,ff,0")
  f_exp(force, "x,-16,y,64,w,4,h,4,sx,2,sy,0,target,96,status,1")
  f_exp(r9, "x,8,y,64,w,2,h,2,sx,0,sy,0,acc,.85,frm,4,b_color,0")
  r9.hit, missiles = false
end

function r9_shoot(m)
  if missiles and #missiles == 0 then
    add(missiles, bull_missile(-8))
    add(missiles, bull_missile(8))
  end
  if m then
    return
  end
  bull_def(r9.x1, r9.y - r9.frm // 2)
  if force_type > 0 then
    if force.status == 0 then
      if beam_pwr / 9 < 2 and shot_delay == 0 and force_power > 0 then
        if force_type == 1 then
          if lasers == 0 then
            shot_delay = 10
          end
        elseif force_type == 2 then
          if force_power == 2 then
            --sx is x-w/2xz
            bull_create(r9_bullet, force_type, force.x2, force.y, 17, 8, f_sign * 3, 0)
            shot_delay = 20
          else
            local sx = force.sx > 0 and bull_speed or -bull_speed

            local function red_small(t, x, y)
              bull_create(r9_bullet, t, force.x + x, force.y + y, 3, 1, sx, 0)
            end

            red_small(4, 6, -6)
            red_small(4, 0, -6)
            red_small(6, 6, 4)
            red_small(6, 0, 4)
            shot_delay = 20
          end
        else
          shot_delay = 6 * force_power
        end
        sfx(5)
        return
      end
    else
      local fx, fy = force.x, force.y
      bull_def(fx + 4, fy, force_power > 0 and 1)
      if force_power > 1 then
        bull_def(fx, fy, bull_speed)
        bull_def(fx, fy, -bull_speed)
      end
      if force_power > 0 then
        bull_def(fx + 4, fy, -1)
      end
      shot_delay = 20
    end
  end
  sfx(0)
end

function level_init(w)
  if w then
    c_stage, st, s_score = st + 1, st + 1, r9_score
  end
  if c_stage > 4 then
    _init()
    return
  end
  if c_stage == 4 then
    for y = 0, 2048, 64 do
      memcpy(0x1000 + y, 0x5300 + y, 16)
    end
  else
    reload()
  end
  for i = 0, 12 do
    memset(10288 + i * 128, 0, 64)
  end
  srand(c_stage)
  f_exp(_ENV, "last_frame,-1,start_brush,1,e_bullet,,explos,,brushes,,shell,,")
  shell.delta, bgy, bgx, ending, level_fade_out_start, level_end, fl = 0, c_stage // 3 * 15, (c_stage + 1) % 2 * 65, false, boss_x[c_stage] - 60, boss_x[c_stage] + (c_stage < 4 and 64 or 300), c_stage == 4 and 696 or 64
  for b in all(brush_d[c_stage]) do
    add(brushes, split(b))
  end
  enemies = split("12,260,32,4,8 12,278,80,4,4 13,336,48,5,1 6,330,102,1,1 13,364,80,5,1 12,392,80,3,0 12,430,48,4,2 12,448,80,3,2 12,466,70,3,2 12,478,80,2,0 12,492,40,3,4 20,508,64,1,51 12,508,78,1,0 12,524,82,2,0 12,542,72,1,0 12,562,32,1,0 12,572,80,1,0 6,570,94,4,1 12,580,32,2,0 8,618,64,1,1 10,674,104,1,1 6,724,90,1,1 13,732,-8,5,1 13,780,60,1,1 6,758,-88,1,0 7,836,64,4,9 7,840,16,4,5 7,840,100,4,5 7,900,40,4,5 7,900,76,4,3 6,940,80,2,0 11,937,20,4,10 11,937,100,4,1 10,1054,104,1,1 20,1078,68,1,48 13,1074,-128,5,1 20,1094,52,1,51 11,1097,12,2,0 1,1160,52,11,52 11,1289,12,8,13 6,1300,88,1,1 12,1342,80,3,4 20,1360,64,1,48 10,1368,104,1,1 12,1380,64,2,0 20,1420,56,1,52 13,1428,-8,5,1 6,1416,-128,1,0 6,1440,88,1,1 11,1447,20,2,0 11,1447,100,2,1 20,1532,60,1,49 11,1609,12,6,9 9,1624,98,2,3 20,1756,32,1,51 4,1998,88,10,0 14,2018,60,1,1/20,256,88,1,48 15,256,120,3,2 15,308,0,3,1 15,408,120,3,1 15,428,0,1,1 15,498,120,4,11 15,498,0,3,1 16,560,56,8,69 16,600,86,8,36 16,640,92,8,196 16,680,42,8,85 16,720,62,8,133 16,760,88,8,22 16,800,52,8,0 16,832,108,8,16 20,660,72,1,53 15,560,124,3,3 15,576,0,1,1 17,566,104,1,1 15,620,0,2,0 15,684,0,3,2 15,704,120,2,5 17,748,14,1,1 15,800,120,2,2 15,832,0,3,2 15,864,122,2,1 15,970,120,3,3 20,1008,88,1,51 15,1020,120,1,1 15,1090,0,3,3 15,1100,120,3,2 2,1108,56,10,168 15,1162,0,2,0 20,1178,72,1,51 19,1520,57,1,0/20,252,46,1,53 20,372,68,1,53 24,516,78,1,0 23,772,110,1,1 28,976,53,1,1 3,354,62,1,0 25,210,70,1,1 24,402,95,1,0 26,500,13,1,0 27,760,97,4,15 21,284,87,1,1 22,264,47,3,7 22,326,66,1,1 22,326,74,1,1 22,348,92,-3,7 21,410,19,1,1 21,546,78,0,1 22,616,24,-3,7 21,772,46,0,1 22,980,38,3,7 22,1260,20,-3,7 22,1230,98,3,7 21,1370,36,0,1 21,1372,74,0,1 22,1400,58,1,1 12,732,96,2,1 12,828,92,1,0 20,860,88,1,52 6,880,102,2,1 20,1376,80,1,-51 20,1472,84,1,51/20,836,56,1,53 20,852,64,1,48 5,1080,64,1,0 20,1008,32,1,48 20,1368,92,1,51 20,1374,52,1,52 29,796,120,5,255 29,812,0,5,255 30,1582,64,1,1", "/")
  ce = split(enemies[c_stage], " ")
  for i = 1, #ce do
    ce[i] = split(ce[i])
  end
  check_p = ({split "1400,620,96,0", split "1304,800,0,0", split "0,0,0,0", split "632,632,632,632"})[c_stage]
  for i = 1, 4 do
    if cam_x - 64 + fl >= check_p[i] then
      cam_x = check_p[i]
      music(({split "19,24,18,14", split "28,32,28,57", split "42,42,42,42", split "42,42,42,42"})[c_stage][i], 0, 7)
      break
    end
  end
  if w then
    cam_x = check_p[4]
  else
    for e in all(ce) do
      if e[1] == 2 and cam_x >= 1300 then
        e[2] = 1462
      elseif e[2] < cam_x + 100 then
        del(ce, e)
      end
    end
  end
  stat(0)
end

function level_collide(e)
  return not ending and (map_collide(e) or ws_collide(e))
end

function map_collide(e)
  local mx, my, mx2, my2 = bgx + (cam_x + e.x1) // map_tile_w, bgy + e.y1 // map_tile_h, bgx + (cam_x + e.x2) // map_tile_w, bgy + e.y2 // map_tile_h
  return mget(mx, my) + mget(mx2, my) + mget(mx, my2) + mget(mx2, my2) > 0
end

function ws_collide(e, y)
  if y then
    e = {x = e, y = y}
  end
  return c_stage == 3 and shell.x and mget((e.x - shell.x1) // map_tile_w + 119, (e.y - shell.y + 40) // map_tile_h + 15) == 34
end

function beam_draw(bx)
  bx = bx or 8 + (force.sx == 12 and 9 or 1)
  palt(31760)
  local _ENV = r9
  b_color = (b_color - .4) % 8
  for i = 0, 2 do
    pal(b_color + i, 13 - (i < 2 and i or 12))
    palt(b_color + i, false)
  end
  spr(197, x + bx, y - 3, 1, 1, bx < 0)
end

function prlx_draw(b, c)
  for i = 0, 1 do
    if c then
      clip(0, 0, c - cam_x, 127)
    end
    pd_draw(b, -(cam_x // 2 % 128 - 128 * i), 0)
  end
  clip()
end

function _draw()
  cls()
  if c_stage < 1 then
    camera()
    pal_d()
    if cam_x == 0 then
      print("blast off and strike\nthe evil bydo empire\x2bfh:\x2bec,\x7cj\n\n        0 stage " .. (st + 1) .. " 1\n\x7ch         5 cheat " .. (invincible and " on" or "off") .. "\n\n\n\n\n\n\n\n\n\n\x7cj\x2ac   1.4\n\n\n\n   @2021 BY  tHErOBOz\n   music BY yOURYkIkI", 42, 2, 12)
      print("press 4 to start", 58, 44, t() % 2 + 1)
    else
      cam_x = cam_x - (3)
    end
    for i = 0, 5 do
      camera(-cam_x - i * (16 - cam_x / 8) - (i > 0 and 16 or 22), 0)
      pd_draw(19 + i, 4, 72)
    end
  else
    --draw far_bg
    local ef = boss_x[c_stage] - 256
    if cam_x <= ef + 64 then
      if cam_x < 900 then
        pal_fade(0)
        if c_stage == 1 then
          prlx_draw(7, 820)
        end
      else
        if cam_x > ef then
          if stat(24) < 56 then
            music(56, 0, 3)
          end
          pal_fade(ef, true)
        elseif c_stage == 1 then
          pal_fade(900)
        end
        if c_stage == 1 then
          prlx_draw(2)
        end
      end
      if c_stage == 2 then
        prlx_draw(9)
      end
      pal_d()
    end
    foreach(e_bullet, bull_draw)
    foreach(ce, e_draw)
    if cam_x < fl then
      pal_fade(check_p[4])
    elseif cam_x > level_fade_out_start then
      pal_fade(level_fade_out_start, true)
    end
    for i = start_brush, #brushes do
      local b, bx = brushes[i], brushes[i][2]
      if bx < 128 + cam_x then
        if bx + b[4] > cam_x - 8 then
          pd_draw(b[1], -cam_x + bx, b[3])
        else
          start_brush = i + 1
        end
      else
        break
      end
    end
    camera(round(cam_x), 0)
    local cx = cam_x // 32 + bgx
    for cmy = bgy, bgy + 14 do
      for cmx = cx, cx + 4 do
        local w, m, mx, my = 2, mget(cmx, cmy), cmx - bgx, cmy - bgy
        local x, hflip, m4 = mx * map_tile_w, m % 4 == 3, m - m % 4

        local function bgs(mo, px, hf)
          spr(m4 + mo, px, my * map_tile_h, w, 1, hf, my < 10)
        end

        if m < 35 then
        elseif m % 4 == 1 then
          bgs(0, x, hflip)
          bgs(0, x + 16, not hflip)
        elseif m % 4 == 2 then
          bgs(2, x, not hflip)
          bgs(2, x + 16, hflip)
        else
          w = 4
          bgs(0, x, hflip)
        end
      end
    end
    camera()
    pal_d()
    if respawn_t == 0 then
      foreach(r9_bullet, bull_draw)
      spr(4 + r9.frm // 3 * 2, round(r9.x) - 8, round(r9.y) - 5, 2, 1)
      if beam_pwr > 3 then
        beam_draw()
      end
      if r9_auto > 0 then
        beam_draw(-16)
      end
      pal_d()
      if c_stage == 4 and ending then
        for i = 2, 29, 6 do
          srand(i)
          pal(12, i)
          pal(3, 5)
          spr(4, 28 + rnd(70) + min((2 + rnd(1.5)) * (-boss_x[4] + cam_x)), 4 * i - 8, 2, 1)
        end
      end
      pal_d()
      if force.x >= 0 then
        local fp = force_power == 2 and 8 or 4
        spr(249, force.x1, force.y1, 1, 1)
        sspr(56 + 2 * fp, 64 + ff // 1 * 14, 8, 14, force.x - fp, force.y1 - 3, force_power > 0 and 12 or 8, 14)
        ff = (ff + .2) % 4
      end
    else
      print("\x5ep" .. split " game over ,   ready,   ready,   ready" [r9_lives], 22, 60, 9)
    end
    foreach(explos, explo_draw)
    if ending then
      s_score = s_score + (s_score < r9_score and 10 or 0)
      print((c_stage == 4 and cam_x > 1550) and "thanks to your\nbrave fighting\nthe bydo empire\nwas annihilated.\nyour name will\nremain in the\nuniverse forever!\n\nthank you for playing\nthe game to the end\n\ntHErOBOz" or "\n\n stage clear! " .. s_score .. "0", 24, 32, 12)
    end
    pd_draw(12, 0, 0)
    rectfill(53, 123, 53 + beam_pwr, 125, 12)
    for i = 1, (7 * r9_lives - 12), 7 do
      spr(251, i, 121)
    end
    print("beam\x2ab \f7" .. r9_score .. "0", 36, 122)
  end
end

function _update60()
  if c_stage == 0 then
    if btnp(0) then
      st = st - (1)
    end
    if btnp(1) then
      st = st + (1)
    end
    st = st % (4)
    if btnp(5) then
      invincible = not invincible
    end
    if btnp(4) then
      r9_init(true)
    end
  else
    if respawn_t > 0 then
      respawn_t = respawn_t - (.03)
      if respawn_t <= 0 then
        r9_lives = r9_lives - (1)
        r9_init()
        if r9_lives == 0 then
          _init()
          return
        end
      end
    else
      if r9.hit then
        music(r9_lives)
        respawn_t = 8 - r9_lives
      elseif cam_x >= level_end and s_score == r9_score then
        level_init(true)
      else
        cam_sx, shot_delay, r9_auto = (cam_x < level_fade_out_start or (ending and cam_x < level_end)) and .25 or 0, max(shot_delay - 1), max(r9_auto - 1)
        cam_x = cam_x + (cam_sx)
        f_exp(r9, "sx,0,sy,0")
        if ending or cam_x < fl - 32 then
          r9.frm, r9.sx, r9.sy = 0, min(-sgn(r9.x - 3)), abs(r9.y - 64) < 1 and 0 or -sgn(r9.y - fl)
          if cam_x < fl - 52 then
            r9.sx = 3
          end
          if ending then
            f_exp(_ENV, "beam_pwr,0,r9_auto,40")
            srand(t())
            if cam_x < boss_x[c_stage] - 30 then
              explo_create(16 + rnd(104), 24 + rnd(96), rnd(16) + 24)
            end
          end
        else
          if btnp(5) then
            if beam_pwr == 0 then
              sfx(2)
              local _ENV = force
              if status == 2 then
                sx = 0
              end
              status = status + (1 - status % 2)
            end
            r9_shoot()
          elseif btnp(4) then
            r9_shoot(beam_pwr > 1)
          elseif btn(4) then
            beam_pwr = min(beam_pwr + 1, 36)
            if beam_pwr == 10 then
              sfx(2)
            end
            if beam_pwr == 36 then
              sfx(3)
            end
          else
            if beam_pwr // 9 > 1 then
              bull_create(r9_bullet, 5, r9.x2, r9.y, (beam_pwr // 9) * 4, 4.5, beam_speed, 0)
              sfx(3, -2)
              sfx(4)
            end
            beam_pwr = 0
          end
          if btn(5) then
            beam_pwr = 1
          end
          local fa, ff = r9.acc, r9.frm
          if btn(2) then
            r9.sy = r9.sy - (fa)
            r9.frm = min(ff + .5, 6)
          end
          if btn(3) then
            r9.sy = r9.sy + (fa)
            r9.frm = max(ff - .5, -6)
          end
          if btn(0) then
            r9.sx = r9.sx - (fa)
          end
          if btn(1) then
            r9.sx = r9.sx + (fa)
          end
          if not btn(2) and not btn(3) and ff ~= 0 then
            r9.frm = r9.frm - (sgn(ff) * .5)
          end
        end
        do
          local _ENV = r9
          if sx * sy ~= 0 then
            sx, sy = sx * .707, sy * .707
          end
          x, y = mid(3, x + sx, 112), mid(3, y + sy, 112)
        end
        bbox(r9)
        force_update()
        foreach(r9_bullet, bull_update)
        foreach(ce, e_update)
        foreach(e_bullet, bull_update)
      end
    end
  end

  function force_update()
    --force_update
    if force_type ~= 0 then
      f_sign = sgn(force.sx)
      if force.status == 0 then
        force.x = round(r9.x) + force.sx
        force.y = round(r9.y)
        if force_power > 0 then
          if force_type == 1 and shot_delay > 10 - force_power * 2 then
            max_laser_s = laser_speed * 2
            for j = -1, 1 do
              bull_create(r9_bullet, 1, force.x - f_sign * max_laser_s, force.y + j * max_laser_s, f_sign * laser_speed, -j * laser_speed, f_sign * max_laser_s, -j * max_laser_s)
              lasers = lasers + (1)
            end
          elseif force_type == 3 and shot_delay % 2 == 1 then
            for d = -1, 1, 2 do
              bull_create(r9_bullet, force_type, force.x, force.y, 4, 4, f_sign * special_speed, d * special_speed)
            end
          end
        end
      else
        force.x = force.x + (force.sx)
        bbox(force)
        if level_collide(force) then
          local _ENV = force
          x = x - (sx)
          status = 3
        end
        local dx = abs(r9.x - force.x)
        if force.status == 1 then
          local abs, fx, _ENV = abs, r9.x, force
          if abs(sx) ~= 2 then
            sx = x > fx and 2 or -2
          end
          if x <= 0 and sx < 0 then
            status, target = 2, 32
            sx = sx / (-4)
          elseif x >= 120 and sx > 0 then
            status, target = 2, 96
            sx = sx / (-4)
          end
        else
          if force.status == 2 then
            local _ENV = force
            if x < target then
              sx = .5
            elseif x > target then
              sx = -.5
            else
              sx = 0
              if dx < 28 then
                target = target == 96 and 32 or 96
              end
            end
          else
            local fx, _ENV = r9.x, force
            if sx < .5 and x > fx - 24 then
              sx = -.5
            else
              sx = .5
            end
            if sx > -.5 and x < fx + 24 then
              sx = .5
            else
              sx = -.5
            end
          end
          if level_collide(force) then
            force.x = force.x - ((force.sx > 0 and force.sx or -cam_sx))
          end
          local dy = abs(force.y - r9.y)
          do
            local f, dy, _ENV = r9, dy, force
            if y > f.y + 20 then
              sy = -.25
            elseif y < f.y - 20 then
              sy = .25
            elseif f.sy == 0 and dy <= 2 then
              sy = 0
            end
            y = y + (sy)
            if dy <= 6 and dx <= 12 then
              status = 0
              sx = (x > f.x and 12 or -12)
            end
          end
          if level_collide(force) then
            force.y = force.y - (force.sy)
          end
          force.y = mid(4, force.y + force.sy, 112)
          bbox(force)
        end
      end
      bbox(force)
      force.x = mid(0, force.x, 120)
    end
    if not r9.hit and r9_auto == 0 and level_collide(r9) then
      r9_explode()
    end
  end

end


__gfx__
bb282b555d5bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb28e5dbbbbbbbbbbb285bbbbbbbbbbbddd55110225666ddbbbbbdff779bbbbbbbbbbd6666dbbbbb
bd516772942135bbbb225676d51bbbbbbbd6776d51bbbbbbb5128d5d6531bbbbbb1286667673bbbb66d5551022d66766bbb5df7fff7fdbbbbbbb26666666dbbb
b6d525d76713363bb55d667d56513bbbb128ed5d651bbbbbbd511566d67c31bbb5511524942d3c7b66d55110245776d6bb5d666dd666d4bbbbb346ddddd6d4bb
b51205d6d63ccc73b12285d1563c361bbd511566d6cc31bbb5d506049466cc71bdd5dd566d555dc3d6d555104ad776d6b4466dd55d6d49dbbb3c4dd555dd49db
b68ed5511d3ccc33bd8e5d6776cccc73bbd55677677ccc71bd1d5d5d655563c3bd5dd55dd65555d566d551104fd77766bb14d55225549f4bb1cc455225549f4b
bd6505d24426d3d1b5d5dd5ddd67333db51d6ddddd677c33b5d5d55ddd555dd5b5d5dd155d555d55dd5555104fd7776dbb11d5167155479db3cc453cc355479d
b5115666d6751bbbbd6655d24425d6d1bd67d654945b576dbbb5115242bbb551bb5511d494211551555551054f5677d5bb1151dc16154a7913cc23cccc354a79
bbbb15d5551bbbbbbb155d6dd65bbbbbb51b15551bbbbb51bbbbb5d5bbbbbbbbbbbbb5ddd5bbbbbb515110554a45555544d2ddcdd17259af133c233cc33259af
22222288b98bbb7cbbb5d5bb067009a0bbbbbbbbbbbd3ddc66d5bbbbbbbbbbbbbbbbbb5ff66bbbbb101005544aa4251122d22d1d616259af13332163361259af
299888829a98bb7cbbbd6dbb666d6896bbbbbbb5d6d5d66aaa6c33333555bbbbbbbbd6f77f66dbbb524444499a994551bb1151d1161549f411632137731549f4
988822228994bbcdbbbdddbbddd55dd5bbbbb5d3ca6a6a6aa6caaa6c533355dbbb886f7777f66dbb5ffffffaaaa94511bb11d5167155499db17645133155499d
fff22229b84bbb6cbbbd7dbb05500550bbb33cc6aaaaaaaa6caaacc51533cc6db87886f77ff666db5ffffaaaaaa94551bb14d5522554994bb11745522554994b
f988889fbbbbbbbbbb6f6bbb06700670b3cc6aaaacccccccaaaa6c5051155355878ee6fff66666db5fffaaaaa9994511b44666d55d6d49dbbb114dd555dd49db
7822888fbbbbbbcdbbd8dbbb6896ddddcc6aa6c6d5535333366cc5050055351587efd666677766db5ffaaaaa99944551bb5d669dd966d4bbbbb146ddddd6d4bb
22282288bbcb6c77bb5d5bbbd48d5485c6cccccc5bb5555553cc51501553515388ef66667611dddb5ffaaa9999944511bbb5d9ffff96dbbbbbbb26666666dbbb
22828222bbdbcdccbbd5dbbb0dd00440c333353bbbbbb3b3353335015335153bb8efd6676101165b5faaa99944944551bbbbbd9ff9dbbbbbbbbbbd6666dbbbbb
9ff9f282b224422bb224422bbb28425bbbbbb9ff77ff9bbbbbbbb9f9dbbbbbbbb8efddd6d15d5d5b5aaaa9476d444511bbbb22bbbbbbbbbbbbbbbbbb77677dbb
fffff82924eee42224eee422b244242bb977f5dd99dd4f9bbbbb9fbb9db97f9bbb8e5dd6dd56d5bb5aaa99476d442551bbb8689bb55bbbbbbbbbbb776d5d65bb
f77ff29f4e9f9e424e910442245282459fbb9c3bbbb153f9c31d3542cf5fbbd9bbb2e5556dd561bb59a99944dd422511750449f9d6744bbbbbbb776d55415bbb
f7fff2ff4efffee44e1c30e44825242293c349d3c3c3d9ddfd448884d3d3c33dbbbbbb55555d115d5999944d66425151b6d59f9d674999bbbb776d524bbbbbbb
fffff28f4e9f9ee44e0330e42482428235548845d49d33fcd484284f289423c3bbbbbbbb5111c1db54944455d5551511bbb429d0249fff9bb765d5415bd55dd1
fff9828824eeee4224400442b252822528824d229d5fd4425428824d884d4843bbbbbbbbbbbbb76db55422567551511bbb49fdeff2e99ffbbe8652ad655d15d5
88888228224ee422224ee422bb24225b248924d249d12844589484549f948842bbbbbbbbbbbbbb76bbb5555d65111bbbb49f311e764ed9bbbb5dbb96595d51bb
88822222b224422bb224422bbbb225bb124df1488d2288422fd23c3242288422bbbbbbbbbbbbbbbbbbbb5b55b5bbbbbbb4f3cc34fffd5bbbbb7bbbb6445ddd6b
b5d66d5bd5d666d5bbbbbbbbb5d66d5bb5d66d5bb5d66d5b0d677650bb173cbbb15bbbbb777676d5bbbb5dd66dbbbbbbbb133cd52888e82bbbb77777779555d6
d651156d6d8f776dbb8c3bbbd7610d6dd7620d6dd7640d6d567777d5bb57c6bb136dbbbb6667676dbbbb1115d51bbbbbbbb56d222222bbbba9a66666d544e85b
65c77c56d5c55c55b4e8c3bb6d17d1d66d27d2d66d47d4d6d76dd670bb57c6bb1c375bbbccc6c6ccbbb1555d6d51bbbbb11154eee4222bbbb45ddddd5dde1585
6171111651c33c154a89c7c361711306627228066474490651d77513bb173cbbb13c7dbbdd55111bbb15555d6d551bbbbd6dd282828282bba945bbbb7d185125
d1c77c1651c11c1549897377d0d13c17d0d28927d0d49a47d66763ccbb16c6bbbb13c6d1bbbbbbbbbb111155d5515bbbbbbbbb22288288bbbbbbbb7766518251
61111716d5311355b4e8c3bb6d13c3d76d2898d76d49a9d75d6d1365bb163cbbbbb13c76bbbbbbbbbb1555ddd6d51bbbbbbbbbb214828bbbbbb776d551bbbbbb
d5c77c5d6d8f776dbb873bbbd6d0167dd6d0267dd6d0467d15d5cc31bb1d3cbbbbbb133dbbbbbbbbb15d4ef77f4451bbbbbbbbbb36422bbbbb777766dd551bbb
bd5dd5dbd5d666d5bbbbbbbbb5d67d5bb5d67d5bb5d67d5b01533350bb15d5bbbbbbb1d3bbbbbbbbb15d44ef7f4451bbbbbbbbbbb322bbbbb565655d657d551b
bb5d67777776655bbb5d67777776d5bbbbb5d777777666dbbb5d67777776d5bbb1566666666d6d5155d6d66d666dd51b31dcc31315c6c351d66665d665013106
b677767677777777676777777777776bb677777777777777777777777777776b167766666766d5dddd5d66767777776153cd33110153511001ddd15dd6d51007
d776d5d5d666666d6ddd66666666677d6777777766666666666666666666677d1666ddddd676d9a7a942d66d55d6677d13c6c151013d31055511531515d66d51
ddddd55555dddd577666d5d555dddddd777777766ddddddddddddddddddddddd1ddd5555dd6d54e944215dd5dd5d5dd5133c63311553511d666775d76d51d6d0
66666d10015d66d76666d100011d666676666666d55555555555555555555555029442105dd529a7a942255d21d6666133cd335113dcd35353511001566d0161
d666d5855805d66d666d10454e51d66d6666666d56777775d6777777777777761a7a9421855254e9442152d5125d5555d13c633515c6c31005ddd35d515630d5
15d5154225275dddddd1051014510d516ddddddd5766666d56666d6d6d6666dd02944210156519a7a94215d60055555131c6c353013c3101666665d76506101d
00540155527d005555105505dd104100dd5555555766666d5ddd5151515ddd501a7a942156dd825dd5558565d5d5dd1b11c7313301111106dd1000101d0d0015
bd677777776511515d6777776d5d676d7000282677577882e8882288e8828806bbbbbbbbbbb56777777765bbbbbbbbbb009fff9009ff900bbbbbb009ff90bbbb
d5d677776d510013d50001310005100570028e86775772888282002882888206bbbbbbbb6776560000005676bbbbbbbb49f9f9ff449fff9009f949f9444500bb
10566666650135310135c3101313100170088826775770288282028822828006bbbb567655656d02820000056765bbbb44944449554444559ffff944559fff90
cd5666666d1310135310101c3103135170028206775770228828288220202006bb57650006d6752888820000005d65bb54445544555555144499945599f94445
105666666d01353101353531000c511070008206775772822888828822802006b57500225757708282e882028200565b19ff44449f59fff95544445144444551
cd56dddd65131013531010101311035170028826775772288e82002882828006b750028067d77228e88ee888e820056b99994519f44544999455519fff5559f1
55ddddddd50135310135353531031115702e8286775770022888828828e8820656002e2577577082888288202e8200d549445594519f955445599f944449f945
b55d5ddd5d531010331d6d6dddd5d55d7008828677577022888202822882080665028806775772202820288288e882561555155999f944155999445559994551
bbbbbbb595a95b55bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3ccccccc3353bbbbbbbbb28448822850511d6d12449994bbbbbbbbbbef54584e421bbbbbbbbbbbb
bb55bb5a4a9424a9945bbbbbbbbbbbbbbbbbbbbbcafaafaa3cfaaafcc333553bbbb12882501cd821015d186d49f949f4bbbbbbbb1d684548499421bbbbbbbbbb
59949494894e8e984e9495a945bbbbbbbbbb3cafaaaaaac3caaaafcc3cfc3551b135054101cdc28015d3241d54944494bbbb25dbd6d249544489421bbbbbbbbb
a8888a9449484944a98e4a94245bbbbbbb3caaaacccca35cccccccc3cacc5115b354535410101d28d6318249d5452545bbb54e1b7fdd84954d449421bbbbbbbb
9824a944a4249424e42849484a949a94b3aafccccccc35c3c3c33333333510001315d105d52501d2d8828424fd58725dbb2d625b15d6d54954d4e441bbbbbbbb
a48994494849e88a9448e924a9e888493caccccc333cc5333333ccc3ccc1000153d31d5240245024525425424f0e8204b1e48f75b17f6d58546444921bbbbbbb
4944989e84a48499484a984a4484848853cc33335553c53353533cc3cfc510153545d2402402450242042959249f9ff924e426d1b5dd6d8454dd4e4451bbbbbb
24484449949489a48499489984828484bc333b3b3535353b3b3553335ccc515b34545d2402402450242542454299999449445d751bd6d82845d64492551bbbbb
dd555d55ddd55d555555555535335503024528222242024201551bb067854521bbbbb294294942bbbbbbbbb4bbbbbbbb49e4456f717f6d4915dd4e894251bbbb
6d00111111111111111111105555335024945288848444200015206005675452bbb245449448f92bb82bb212bbbbbbbb149451e720556d4915d654489e21bbbb
dd0155555d5dd66dddddddd53333c335294424242002200b0200470060007545bb495449f86757b6b21bb821bbb212bbb4944586f1b7f6d8455d654449e41bbb
5d505d66666677776766666dcaac3c3302420242442400002252450700068224b254499f57bbbb68bb2b421bbb21112bb244455d75b16ed24515d6d449e411bb
5dd0150111111111111111101555550540242020024022002004245006002805154954827bbb7844bb4221bbbbbb221bb159545d6f1b185d845255d64e4442bb
15d5015555d5dd6dddddddd53333535020024224949288200022022457828284245448242b7df49215201bbbbbb2112bbb1e545de721b52d442555d65448921b
b15d505d666667776766666d3ccc3c3502402240288894820282820224242845295282824526492b22155bbb1242b121b549545d86d515d584512d6d54848411
bbb15dd555555dd5d55555555555555b20040492894949488820282052425252545282288884494201510bbb24944212b249e515d5510d68425215d5d2448942
bbbb555bbbb52121bbbbdccdd11bbbbbb48892bbbbbbb1242bbbbbbbbbbbbbbbbbbbbbbbbbd5bbbbbbbbb12521bbbbbb15d515dd666d51133bbbbbbba99ba99b
bbbdd2dbbb49af67bbbdcd331c71bbbb1988994bbbbb128284bbbbbbbbbbbbbbbbbbbbbb5d6d666bb1221551d5dd1bbb5156515d11dddd5111103bbbaa95aa95
bbdd00d5549ad4944246d31141171bbb148e9861bbb2448282bbb24221bbbbbbbbbbbbbbbdd65dd61d5155d5dd55d1bbd515651d5511d6dddd5103bbaa95aa95
bbd00dc6d9a94d4d4994222449d659bbb288e8d2bbb498e2b2bb4284144bbbbbbbbbbbbbbbbbbbb65d01d5016d5dd5bbd6d1d6d16d551d6dddd5103baa91aa91
5dc2dd0c1999aaaf444249499944499bb1d888e1bb4918ebbbbb289829f94bbbbbbbbbbbbbbbbbbb5d0265016dd6d51bd7616761d76d51dd67dd510baa95aa95
677dc53149aa99fab522444499944499bb22ee81b2918e1bbbb21122829f9bbbb5d6bbbbbbd49bbb156d666d5d66d651d761d7616761d51d565dd103a941a941
56d2dc524a966cdad6d2244449900249bb1288dbb498e1bbbb29e2bb282441bb5d56d6875d5d66d6b165d666d5d656d5d7d167d1d7d1d651d55dd51099419941
564fa944a92552ca6d511222449100c4bb12e81bb4f292bbb29f9e210e82f91b5d5dd5265d5ddd551676267762577765d761d76167616761dddddd10444b444b
bbbbb11555551bbbbbbbbbbb2499217bbb11228b1998e9412f449dd642e2492bbd66bbbbbbd49bbb577757777257777dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb15dd6d6551bbbbbbbbbb24944999bbb1be291429296d242542d69488221bbbbbbbbbbbbbbbbbb176d777d577767dbbbb5dd1551bbbbb284d2555d5dd1482
bbb15ddd655551bbbbbbbbbb2494492bbbbb128db22494d24278f112212946dbbbbbbbbbbbbbbbb6156d66dd5677d6d5bbd66662d5512bbb84d15dd2d256d148
bb1557d555d1551bbbbbbbbb4942991bbbb24482b1d14221228e4944429f4171bbbbbbbbbdd65d6d5d026d017667dd5bbd677661ddd551bbbb25d26d6d6765bb
bb5dd555d55555d1bbbbbbbbb92491bbbbbf98e2bb1d221d49444f9f92992016bbbbbbbb5d6ddddb5d0176016676d5bb1677665225dd552bbb1d6d666d5de82b
b16fd55fd51dd515bbbbbbbbb4299ddbbb4918ebbb161b24499f49f91242941dbbbbbbbbbbd5bbbb5d517665d66651bb56776522425dd55bb15d6d66d50eef82
15f6d55d55d55151bbbbbbbbbb49ccbbb2918e1bbbb1d1d14f99429129f9467dbbbbbbbbbbbbbbbbb52216716dd61bbb5766522825255d5bb5d6d6d65000def2
56ddd5655fd515d5bbbbbbbbbbbbbbbbbb98e1bbbbbbb1d12492f9219e21042bbbbbbbbbbb11bbbbbbbbb12521bbbbbbd6dd28242842555bbd66d6d666666dd5
7d5555d5d6d5d5551d555d5b6651bbbbbb020bbbbbbbbbbbd48929f129f4f91bbbbbbbbb5d6d6d5bbbbbb5d111115511012122425284121bb676676776767dd5
65555d55655d551155151515777761bbbb222bbbbbbbbbbb16e12498e8e9e28bb5d6bbbbbbd49bbdbbb5dc33333c6c33566d54282542555bbd76d7675000def2
155dd65d655dd555515555156666775bb02820bbbbbbbbbb191248eee820882b5d5dd5465d5d66ddbbd3333333cccc331d6d52424426652bbd66d6d6d50eef82
55d76556551d555d55d55155d666677db02820bbbbbbbbbbb12921488e819d1b5dd5d521bd5ddddbb5c3dc676c6766c7bdddd52482d776bbb57d66d66d5de82b
1d6d556d55d555d555d5555d6d6d6667b24982bbbbbbbbbbbbe2082119d2d22bbd679bbbbbbb9a9b5c335dc6c676766cb15ddd51567765bbbb267d666d66d5bb
b55551d55565556556dd555dd6d56d6d0548950bbbbbbbbbbb92411b2d9428e2b9a9abbbbb5babbb115333ddd3cccc3dbb1555d2567d5bbb84d67d66d6dd5148
b15d6f5556f515f556fd515d6d55d56d105d601bbbbbbbbbbbbe9ebbd2ed1e92bbbbbbbbb15b9b923c33353533dccd33bbbb5551555bbbbb284d26776dd51482
bb155d5566d55665566d556dd5d555d55bdddb5bbbbbbbbbbbb2ebbb1ed9ede2bbbbbbbbbbbbbb6b1155000053cccc51bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bb155d666d5556d556fd556e55515555155d651bbbbbbbbbbb211bb1d942d9d115bb1115bdd566d53c30c66705dccd33b7cded666e5622d5111026d6dd22223c
bbb155d6d5556dd5666d556655155155bd555dbbbbbbbbbbbb42bbb21418ed2db151112555d56ddb1150dc6605cccc51bc38d6666e12d66ddd42dfddd228423c
bbb1555d555dfd516fd5556e151155151566d51bbbbbbbbbbb12bbb288e9dbb2bbbbbbbbbbbbbbbb3c305dc603dccd33b33ddd66ee142226f62d6542284dddcc
bbbb15d555d7dd5d6fd5516b511551155d6f6d5bbbbbbbbbbb22b2b42e94bbbdbbbbbbbbbbbbbbbb555105d015555555bb02e6666852282ddd2dd58255ded3cd
bbbb155dd576555766d55d6b1111115d5567765bbbbbbbbbbbddb2bed2bbbbb2b5d7bbbbbbbbbbbb9444200249a9aaaabbb02e66d45ddd4225dd5d4d55dd23d3
bbbbb15d56d555fddd5556db510105d1156f6d1bbbbbbbbbbbbd21bde1bbbbbb5dddd586bbbbbbbb4549444499999999bbbb1de642116d5d6dd2d22515113ac3
bbbbbb15555df6d5d5516dbb11106d1bb05550bbbbbbbbbbbbbbbbbbd2bbbbbbd6d6d621bbd55bbbb454494949494949bbbbb05520bb1654d2422bbbbbb3acdd
bbbbbbb1151551555156dbbbd6555bbbbb000bbbbbbbbbbbbbbbbbbbbd2bbbbbbbbbbbbb5d5dd66bbb24444444444444bbbbbbb00bbbbbb10000bbbbbbb3cdd3
763761bb5153d324bbbbb15dd51bbbbb65bbbbbbbbbbbbb5bbbbbbbbbbbbbbbbbbbbbbbbbd5d6dd6bbbbbccc35513cbb15bbbbbbb567665bbbbbbb11111bbbbb
ffe44221159e3d32bbb303335dd5bbbb5659a7bbbbbbbb4bbbbbb5ccd35bbbbbbbbbbbbbbbdb9bbbbbbbcc3599942bc4444bbbbbd677765dbbb1554545455bbb
9422fff242293dd3bb17c13335dd1bbbb52e9a96bbb234b5bbcc3fdd31423dbbbbbbbbbbbbbbbbbbbbbba334444d544e40245bbb5c7777d5bb5d66d5335d461b
42ff999f22913333bb3c101333dd3bbbbe444a9d1123b3b4bcd312333181d31bbbbbbbbbbbbbbbbbbbbb87a3165d4099f459ff5b1c7776c1b1d67d33313354db
2f99224993311333b301011133533bbbb9444e9612bb3b4bb43114411813318bbbbbbbbbbbdb9bbbbbbbb8a3d259209fee4449e4567777c1156753c3531335d5
f924999fd3d311143303535113353bbbb594e95dbb23b4b5cdf4055581ddf43bbbbbbbbbbd5d66d5bbbc15110404d69fee45cc24d67776d514d5313c35373346
924913d3113d314813313bd511131bbbbd5555d6bbbbbb4bd31857499dcd1835bbbbbbbb5d55dddbb31d65665d5dd554e456dbbb5d677d5db543c37353c334dd
29913d332011148e3313135d35313bbbd5dd666dbbbbbbb531185499ad311481d6d6d621bbd55bbbb315d5ddddd5555244d5bbbbb5c76d5bbb5d37373734dd1b
bb0022888888d575bbb3133d335d3bbbbbb3333bbaabbbabd281059a9d3313435dddd586bbbbbbbbbb24d5555155154442edbbbbdd676d51bbb1d3dcd3d551bb
0028ef8eeedd36d6bbbb33d135d3d3bbb33c8f23ab9998aacdd330f213314414b5d7bbbbbbbbbbbbbb2e94444255d4515144cbbbbc7775cbbb54254424d4bbbb
028f8e999dd13d6fbbbbbb3335dd1dbb3c389882b97a898b1314111801124143bbbbbbbbbbbbbbbbbbb44242225644d5422249bbdc676cd1bdfe42844e42441b
28f8e99dd35331f9bbbbbb135ddd1dbbc3c32e2397a89aaab1488338492d3315bbbbbbbbbbbbbbbbbbbbbbbc5164e4ed543224eb5dc6cdcbbf924449f849ffeb
89f899d317653d94bbbbbb33355153bb3713c33597f89a98bb153d5149d331dbb151112555656d6bbbbbbbbbc51e424ee43b33cbb5dcdd5bb54b5ddfe9f6ddfb
8f9e9d3167331e42bbbbbb1350110533bbb636c38a78998bbbb351333ee11d3b15bb1115bdd5ddd6bbbbbbbbbbc455d4ee4bbbbb515d55bbbb451dbf9d6d192b
288ed6777333122fbbbbbbb335351131b71171d598a98849bbbb1515d34481bbbbbbbbbbbbbbb962bbbbbbbbbb5d5d664ee4bbbbbb151bbbb54bb2fdd6db1e1b
b28e1776765d9ff9bbbbbbbb1331bb31bd33335ba9b849abbbbbbbbbbbbbbbbbbbbbbbbbb15b9a92bbbbbbbb4255d6d5c4442bbbbbb5bbbbbbbbb45bbbbbb2bb
bb28d765911149f2bbbb1111bbbbbbbbbbb2f7af1bbbbbbbbbbbbbbbbbbbbbbbb9a9abbbbb5bbbabbbbbbbb425e9d555bbbbbbbbbbbbbb11bbbbbbbbbbbbbbbb
bbd3762911331299bbb117711bbbbbbb11202faaf1bbbbbbbbbbbbbbbbbbbbbbbd679bbbbbbb9a9bbbbbbb924e94251bbbbbbbbbbbbb2232bbb11bbbbbbbbb13
bbb7687e11301324bbdccc711dbbbbbb2e8202faf90bbbbbbbbbcbcbbc33cbbb5dd5d521bd5d66d5bbbbb944e94e42bbbbbbbbbbbb224124bb3e231bbbbbb132
bbb312e531313622b33dcc11d3353ddb28ee209faf90bbbbbbcc6c6c1c893ccb5d5dd5465d5dddd2bbbb942e94e942bbbbbbbbbbb214524ebbe942330bbb0324
bbbd31133356d221b333311d3351d3dd028ee219faf91bbbcc73d3d3313cd1bbb5d6bbbbbbdb9b45bbb252494e9942bbbbbbbbbb023514e9bb59442530b01244
bbb3156776125d35d5153333131015bbb02445519f9ff0bb33c663ccc31c59e7bbbbbbbb5d6d6d5bb44454545994252bbbbbbbbb21452494bbb594255300324e
bb177676d126d35d1d5128251333ddbbb04f50151999941bb5dd56565551d5dbbbbbbbbbbb11bbbbb242494549425194bbbbbbbb24412494bbb2e44255303444
b1d367676d2d31d3c1d28155353535db5e8255f150494941bbb5d5dbd66dbbbbbbbbbbbbbbbbbbbbbbbbbb2254211544bbbbbbbb29425494bbbb544425315494
b1332676765d31d3bc38111553535d31024df56d05049424555455dbd55d55dbbbd55d55b248842bbbb66bbbbb11bbbbbbbbbb0249442444bbbb594442335444
bb122467676f9951b3d211551135355db0054d5652204442dd5d4dbbbd555dbbbbbd592d24899842bbc6ccbbb17dcbbbbbb131249442d944bbb12944425cd944
bbb124d7d7924f94bd00051313535135bb0e845d48e20222bbd55bbbbbb6dbbbbbbbb64b48faaf8455676c5d41dcc4bbbb3cd32944226e44bb3d194425556e44
bbbb42276f492244b5d1511b11351b11b08f2588d24e2022bbb544bbbbb45bbbbbb96d5b89a77a98d3676c367f7767bbb13dd24942256de4b13d0e4425556de4
29ff9429f4229922bb35d5bb135311bb08e200f800250bbbbbb942bbbb942bbbb99425bb89a77a9863c76c377f7767bbb13112944d15445db1310244d154945d
49fffff94229d399bbbbbbbbb13535350520b2e20b00bbbbbbb4422bbb9442bb6d5442bb48faaf84d55765d6787787bb131302942c65d41c13131013c65de41c
249f9e4f999d3312bbbbbbbbbb111313b00bb4e20bbbbbbbb644222b694442bbd522425b24899842d5c66c56b8bb8bbb1c3102422314d5451c311104314d4545
b244422442100124bbbbbbbbbbbbbbddbbbbb040bbbbbbbbbd54225dd52425dbbbbb2d5bb248842b55bccb5dbbbbbbbb3dd31025429445443dd3310544944544
__map__
0000000000000000000000000000000000000000000000004642434840494a40480043464a46454841434048004a4046464243404945484045494a41454048434452525252545151686b6968616a6063606b696a6b6977946b6a6863745454526b77746168696860636a74607c6b000000000000000000828300002c2d000c0d
00000000000000000000000000000000000000000000000021210000004449000000002100210000440000000049002121210000440000000044490000002121005454545454515100000000007c00000000007c00007b84007c0000005454540000780000000000007c78006c00000000000000000000929300000000001c1d
00000000000000000000000000000000000000000000000021210000000044000000002100210000000000000047002121210000000000000000470000002121005858585854545400000000006c00000000006c00000000006c0000005454580000000000000000006c00000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000212100000000005254540000000000000000000000000000000000000000005252000000000000000000000000000000000000000000000000a28300e6e700000e0f
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000212100000000005454540000000000000000000000000000000000000000005454000000000000000000000000000000000000000000000000929300000000001e1f
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000002100000000005854540000000000000000000000000000000000000000005858000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002100000000000052520000000000000000000000000000000000000000000000000000000000000000000000000000002121210000000000a2a30000cd00009c9d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005454000000000000000000000000000000000000000000000000000000000000000000000000000000212121000000000092b30000dd0000acad
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002100000000000058580000000000000000000000000000000000000000000000000000000000000000000000000000002121210000000000000000000000000000
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002121210000000000a2a30000a400009e9f
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000212100580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002121210000000000b2b30000b40000aeaf
0000000000000000000000000000000000000000000000002121000000000000000000000000000000000000000000212121000000000000000000000000212100520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002121210000000000000000000000000000
0000000044000000000000000044000000000000000000002121000000004400000000210021000047000000004700212121000000000000000047000000212100545858000000000000006c00000000006c000000006c000000000000006c0000000000006c0000000000000000002121210000000000a283001200fa008a8b
0000000049470000000000440049000000000000000047002121000000444900000000210021000049000000444900212121000044000000004449000000212100545454007b6c000000007c786f0000007c0000786f7c8700000000786c7c0000786f00007c786c000078006c00002121210000000000929300000000009a9b
454840454a4b4540484b4549454a4345484b414845434b484642434840494a40454843464a4645484a434840494a4046464243404945434045494a4148404543445452526b777c846b60636a747f606b846a6061747f6a9769746360747c6a636b747f69636a747c686b74627c8768212121686b000000000000000000000000
4c4d4c5d5f5d4c4c4d4c5c5f5d5e00000000000000000000000000000000000000000000000000005f4c4c5c5f5c5d5e5f5f000000000000000000000000000000242624262724242624252527242725252425242426242625272726262725262426262726252424252726272525252425262624000000002200000000002200
4c4e5e0000004d5d4f5f000000000000000000000000000000000000000000000000000000000000004c4f00000000007f7f7f7f1081358205821b831a8333850284128104851a81348501861083038611813c83008101860f83048510823a91108d11823a900e8e0c8102813783018900002527000000002222000000222222
5c5f000000005e005c00000000000000000000000000000000000000000000000000000000000000005c5e000000000001820a81018e0d81048406802983018b018209800190118803822981028c00820c8e00810f8a018429900083099000810e8c01822991008308950c8d02802a9000002121000000222222220000222222
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008408940d8c2e940b930e8b2f95008108930d8100873095008109920d82018300813081018f0c81008f0f80058231830089109117833183008801820c83008900002121000000222222220000222222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000821781328506860c8308844d8407850d810a834e8209831c817f7f7f7f7f7f7f148103810182198300811e80308202830182148a14871c821484008103801300002121000000222222222200222222
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a158a158007810f86038102830c900f830485128109810a970a920d810a831f80089809930c810c840c801080078200930a9509800f8426810193008106820700002121000000002222222222222222
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008b1b841e80049b05810b8a1a841e8004810394158a1a83238106921280018a1b831e800c8d1582018a1a831e800d8b008200801180028a1a841e800c8b00820000000000000000002200002222002222
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008115891b831e800d890083008115891b831e800d8c028115891b831e800d8b0081018015891b831e800c8c0081008115891b831d800d8b0180018015891b831e00000000000000222200002222002200
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800c8d128105871d83228106910e81058700801b831e800481039208810c8600821a831e80059709810983018200821984268e05810a8205840084018008800f00000000000000002200002222002200
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000840b801080098c018102800b8d008100820b810c841d800780028b00830f8c008100830b81098401800e800a810781038901830f8d01830d830485138007810d00002121000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800283008004811191108a1a820f8202810381138604860f8001873080098015810482018217815d817f7f21827e80048305800580008154800381088102810100002121000010200010100000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080038006800380548002800a84068104804b8003800a800180088605810380028000800d8039840986058800810180038513803486058c008b088609803c880700002121000020100020100000000000
5f00000000000000005c0000000000000000000000000000000000000000005c00000000000000000000005c000000008705870380038101830180008005803d8508850886078301800080028109803984088608870380028504800280028000803c820880018100830481018103800800002121001020200010201000000000
4f00005d00000000004e00005c0000000000000000000000000000000000004f5e000000000000000000004e5d005f00830480038002804c80048003800a80058200800680088055800a8003800980068000800080048060800b80068069800b800f000000000000000000000000000000002424001010200020201000000000
4c5e5c4c5c5e5f5c5c4f5c5e4c5c5d00005e5f5d5c5c5f5d5e5e5c5d5f5e5f4d4c5c5c5f005c5e5d5f5c5c4c4c5e4d5c5d5c000000000000000000000000000000272627262527272627252527272726272725242726272625272726272525272427272727252424252726272525252425262624002020100010202000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001020100010201000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000010001000000000
__sfx__
490114001263416642126522e1222e4222b1422b4522b1622c4622a1622946225162221621c4621a1521744215131144211411114413000000000000000000000000000000000000000000000000000000000000
551100001f05021052210522105221052210550000000000210521f0521d0521a0521d0521a052180521505218052150521305210052130521505015052150521505215055000000000000000000000000000000
1502000001534015310253202542035420354204542045520655207552075520756208562095620a5620b5620d5720d7630f57210562117531255212552117231355213552127251455216552157251755217552
110200061753021730175231753021730175201754217522000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010217000363403643087520a5620e3621156221765177621756221765297622d3622d5622c762295622175217752175522174217742175320752106525000000000000000000000000000000000000000000000
41021200202441f2532026025260292602b260202602126025260232501b24019230162201f2101f2101f1101c1111c115002000020000200002001920017200152001420012200102000e2000c2000a20000000
0d0214001863414241194421d44223452267522c75230453314522d252212521a2522e2522a25323252172521c2522c25225252202522b2432f44229241274453173036720000000000000000000000000000000
04021b000f67414671186701b6701a670166701567010673287610a76208762107621d7621b7621d7621f7621f7621f7621a7621d762127620e7520e7420b7420874208742047410470306600006000060000000
251100201c7601c7011b7201b7011c7601c7011b7201b7011c7601c7011b7201b7011c7601c7011e7601e7011c7601c7011b7201b7011c7601c7011b7201b7011c7601c7011b7201b70117760177011876018701
09110000102241032010420102111032010420102221032210422102221032210412102221032210422102250b3240b4200b2200b3110b4200b2200b3220b4220b2220b3220b4220b2120b3220b4220b2220b325
091100000c1731032010421102013c6231042010221103010c1731022010321104013c623103250c153102250c1730b4200b2210b3013c6230b2200b3210b4010c1730b3200b4210b2013c6230b4250c1530b325
091100001c256232361c236232260020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200172001e200172001e200172001e200172001e200
2d1b0000000000000000000000001156011562115651556018560165601656515560135601356213565175601a560185601856517560155601556215565185601d5601f5621f5651f56021560215622156500000
091b00000000000000000000000011540115451c5401a5401853218535005000050013540135451d5401c5401a5321a5350050000500155301553513500135001f5022b5052b5023950539534395323953500000
091100001c200232001c200232000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200172001e200172001e200172561e246172361e226
091100001c256232461c2541c2501e2501e2501c2501c2511c4411c4311c2211c21100200002000020000200002000020017254172501825018250172501725117441174311722117211172001e2000020000200
110c0020177501675015750137501275011750107500e7500b7500a750097500775006750057500475002750177501675015750137501275011750107500e7500b7500a750097500775006750057500475002750
090c002021500205001f5001c50021500205001f5001c500285502755023550235502355123541235412354123531235312353223522235222352223512235122350000500005000050021500205001f5001c500
090c00201f5001e5001d5001a5001f5501e5501d5501a55023550225501f5501f5501f5511f5411f5411f5411f5311f5311f5321f5221f5221f5221f5121f5121f5000050000500005001f5001e5001d5001a500
090c002018550185501a5511a5501a5501b5501b5501b5501c5501c5501b5511b5501b5501a5501a5501a55017550175411753117511215001f5001e5001c5001f5001e5001c5001850017500175011750117501
110c0020177501675015750137501275011750107500e7500b7500a7500975007750067500575004750027502374022740217401f740217401f7401e7401c7401f7401e7401c7401874017740177311772117711
090f0020000000000028411284122841228412283112842128422284322843128442000002844228452284550e05711057150571a057150571a0571d057210571d05721057260572905726057290572d04700000
080f00202120021301214012120121301214142131121311214212142121431214312144121442214522145511057150571a0571d0571a0571d05721057260572105726057290572d05726057290572d04732017
200f00201a5601a5601a5601a5621a5621a5351d5601d5601d5601d5621d5621d5351f560215601f5601f5601f5601f5621f5621f565000000000000000000001f5601f5601f5621f5351d5601d5601d5621d535
210f0020295652956029535285652856028535265652656026535245652456024535235602353524560245352b5652b5602b53529565295602953528565285602853526565265602653524560245602656026550
090f00102d0502d0502d0402d0352b0502b0502b0352d0502d005000000c17321050240502605028050280552d0002d0002d0002d0052b0002b0002b0052d0002d005000000c1032100024000260002800028005
080f00102b0502b0502b0402b0352a0502a0502a0352b0502b005000000c1731f050230502405026050260552b0002b0002b0002b0052a0002a0002a0052b0002b005000000c1031f00023000240002600026005
090f00202d0502d0502d0502d0502d0522d0522d0522d0522d0522d0422d0322d012300503005030042300322f0502f0502f0502f0502f0522f0422f0322f0122b0502d0502e0502f05000000000000000000000
090f00000c173000002d0502d0552b0502b0552b0502d0500c17300000000001e0002a0502805028052280320c173000002d0502d0552b0502b0552b0502d0500c173000003c6231e0002a050280502805228032
090f00200957415571155701557015570155701557215572155721557215572155721357015570135701157013574135711357013570135701357013572135721357213572135721357210570135701157010570
090f0000115741157011570115701157011570115721157211572115721157211575115701557013570115751c0551c0501c03520055200502003523055230502303526055260502603528050280402803028015
090f001029055290502903528055280502803526055260500c17324055240550c1732305023035240502403529005290002900528005280002800526005260000c10324005240050c10323000230052400024005
090f0020260542605026050260502605026050260522605226052260522605226052290502b0502d0502f0502b0552b0502b0352b0552b0502b0352b0552b0502b0352b0552b0502b05528050280502804228035
090f00200232502345024450224502345024450524505345054450524505345054450724507345074450724507345074450724507345074450724507345074450724507345074450724505345054450524505345
090f00201a5501a5501a5501a5521a5521a5351d5501d5501d5501d5521d5521d5353053032540325403254232542325423253232525005000050000500005001f5501f5501f5521f5351d5501d5501d5521d535
090f0020052450534505445052450534505445052450534505445052450534505445112451d3451144505245073450744507245073450744507245073450744507245073450744507245133451f4451324507345
090f00200c1730934515445092453c623094451324515345094450924515345094453c6230e35510455102550c1730944515245093453c623092451334515445092450934515445092553c6230e4551025510355
090f00200c1730734513445072453c623074451124513345074450724513345074553c6230c3550e4550e2550c1730744513245073453c623072451134513445072450734513445072553c6230c4550e2550e355
080f00202d0502d0502d0402d0352b0502b0502b0352d0500c103000000c17321050240502605028050280552d0502d0502d0402d0352b0502b0502b0352d0500c1031e0550c1731f05524000200552800021055
090f00200c1730c345184450c2453c6230c445172450c1730c1031524517345184553c6231835517455152550c1730e4451a2450e3453c6230e245193450c1730c1031c245172051c4553c623182051720515205
090f00101c2351b3353c623152353c623184353c6233c623104350f2350e3350c4353c6233c62310205102051c2051b3053c603152053c603184053c6033c603104050f2050e3050c4053c6033c6031020510205
090f00000c1731533015430152353c623134301323515330094350923509335094353c6230933515435092350c1731343013230133353c623122301233513430072350733507435072353c623074351323507335
090f00200c1731133011430112353c623104301023511330054350523505335054353c6230533511435052350c1730443004235043353c623042350433504430042350233502430022353c623044300423004335
090f00000c1730c33515435092353c62313435052350c335114301122011315112053c6230433010430042300c1730c43515235093353c62313235053350c435112301132011415112053c623044301023004330
090f00000c1731f055000001d0553c623000001c0551c0550c1731d0551d0550c1733c6231f03521055230350c1731c0550c1731c0553c6230c1733c6231c0550c1733c6233c6233c6033c6233c6033c6033c603
081800201f5501f5411f5311f5211f5211f5121f5121f5012155021541215312152121521215111e5501c5501c5401c5411c5311c5311c5211c5221c5121c5010050000500005000050000500005000050000500
080c00202355023550235512355123541235412354123541235312353123531235312352223522235122350126550265502655126551265412654126541265312653226522265122650123550235312155021531
090c00001f020210301f040210502405021050240502605024050260502805026050280502b050280502b0502d0502b0502d050300502b0502d05032050300503205034050340503405234052340523405234055
090c0000130201503013040150501805015050180501a050180501a0501c0501a0501c0501f0501c0501f050210501f05021050240501f0502105026050240502605028050280502805228052280522805228055
090c002021750217522174520750207502073521750217452475024752247452375023752237351f7501f73521750217522174520750207522073521750217451a7501a7521a7451c7501c7521c7351f7501f735
090c00202175021750217452075020750207351f7501f7451e7501e7521e7421e7521e7511e7351e7501e7351f7501f7501f7451e7501e7501e7351d7501d7451c7501c7521c7421c7521c7511c7351c7501c735
090c00201a7501a7501a7451b7501b7501b7351c7501c7451d7501d7501d7451e7501e7501e7351f7501f73520750207502074521750217502173523750237452475024750247452575025750257352675026735
010c00200c173090400c173150303c613090500c173150400c173080300c1731404430623080400c173140300c173090500c173150403c613090300c173150500c173080400c1731402430623080500c17330623
010c00200c173090400c173150303c613090500c173150400c173060300c1731204430623060400c173120300c173070500c173130403c613070300c173130500c173040400c1731002430623040500c17330623
010c00200c173027400c1730e7303c613027500c1730e7400c173057300c1731175030623057400c173117300c173087500c173147403c613087300c173147500c1730c7400c17318730306230c7503062330623
210c00201033010300103301030021225203251f4251c2251033010300103301030021325204251f2251c3251033010300103301030021425202251f3251c4251033010300103301030021225203251f4251c225
200c00200b330150000b330103001c2251b3251a425172250b330150000b330103001c3251b4251a225173250b330150000b330103001c4251b2251a325174250b330150000b330103001c2251b3251a42517225
081800202855028541285312852128521285122851228501275502754127531275212752127511245502355023540235412353123531235212352223512235010050000500005000050000500005000050000500
081800202655026541265312652126521265122651226501255502554125531255212552125511235502155023540235412353123531235212352223512235010b3050b3050b300005000b3050b3050050000500
090c00202355023550235502354123540235402353123530235302352123522235222351223512235122350100500005000050000500005000050000500005000050000500005000050000500005000050000500
110c002015750167501775018750197501a7501b7501c7501d7501e7501f7502075021750227502374024750207502174022750237502475025750267502775028750297502a7502b7502c7502d7502e7402f750
091100001c400234001c2541c2501e2501e2501c2501c2511c4411c4311c2211c211002000020000200002000020000200172541725018250182501725017250154401543115221152111325013240172561e246
171100000c1730432004421042013c6230442004221043010c1730422004321044013c6230432500153042250c1730b4200b2210b3013c6230b2200b3210b4010c1730b3200b4210b2013c6230b4250c1530b325
17110000042200432004421042010432004420042210430104420042200432104401042200432504420042250b3200b4200b2210b3010b4200b2200b3210b4010b2200b3200b4210b2010b3200b4250b2200b325
__music__
00 41424344
00 01424344
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
00 15164344
00 17214344
00 22214344
00 18236444
01 19244344
00 1a254344
00 26244344
00 1b274344
00 1c286944
00 1d295244
00 1e2a4344
00 1f2b4344
02 202c6d44
00 41424344
01 10113744
00 10123744
00 14133844
00 10393744
00 103a3844
00 102d3744
00 102e3744
02 3c3b3844
00 41424344
00 41424344
00 41424344
00 41424344
00 57614344
00 62614344
01 083f0b44
00 083f0e44
00 080a0b44
00 080a0e44
00 080a0b44
00 080a0e44
00 080a0f44
00 080a3d44
00 080a0f44
00 080a3d44
00 483e0f44
02 483e3d44
00 41424344
00 41424344
00 2f304344
01 31344344
00 31347644
00 32354344
02 33364344
00 09424344
03 08094344
04 0c0d4044
__label__
15111111111511115111511111115153551351511555151515515155551111151555151151151151555511515551515111010101101011111111111110000000
5115151111115501515151511000011535355353535d3d3535353511101201111531351513513513553500011535131150110115001111115151511100100101
115150515100115111533535501111011153d3ddd51d6d6ddddd1254441144111151511315155155555100005553515115115111111115111511111000000000
011111511110001511115353515111511111155355035dd66dd12444444224145115115151135315551001015355151151511151515151151315000000010010
00155111111110001111115155115115151511151151535355124244444412244155511511511511111111505555535131115151151115111150010001000001
00011151515101010011110011511111151115115111151551002444449440494445553515115111151515151551151151511311511513101500000100001011
1100010111115110110011511111515113531151113153125500044444944224549d555553555155151515351111011315135151313151100100100010000101
11000001111111515515111151513111515153115355351055000144244442021945555355531531515111553555501515351535155100000001001000101011
01110100051211111515151111155535353535135155552055000054444442044945115515115151110111555553151511515103535110010100100110000111
0111111010511111113535151111355355155355535355005500011442449402944451553515111151151535d535513151115155100000100001011101011115
000111515011151111515353d3550111510015d35535521055002215422444254049415513535351515351535151555351015105100010001110110110101111
0000151111115111111115535dd3d55111111531155555005102205044244420449995dd555515535351155101015d5100151010001010150111501100115151
000000151151115515151355353dd6bdd535551513515520011002401444444049944966bbbbd3ddd55111501105551000350000010101111151051010111111
0000000515111113153531555555155536d353535551150001001451044444402424996fffebebc5551555101150550105500101101151511511511001515151
00000000151115113155500111111011515d3d5d353515212121024402249441245994466655d555515515152411510155511010111151111151151100151111
00000000011000510513501015111501100153535151015024520144012244921499444d55555551555155112125451555100011115111515111510001511515
000000000000000110011101111511511501113551110050245500442012444404249496c3d55555551155214445545551110100111151111515101000131111
000000000000000001000010151111111111150111510012005501441024444414149996666bbbdd511244444555535111101021515111513131000055515151
000000000000000000101001111151151151115131151005100551421014244204994996d5dfefd5204444555551111511011111511351351511101113113151
00000000000000000000111115111151151111111511110111155510002124441444949d53dddd50444955551111511110515151115113111111015531515131
00000011000000010000011551151111111515151115111011155500102049441405999d55555124494551111111115151111115131511511151513151135315
00000011100000100101001135353115111111111511151115115104201244440449449d3d355024445111011111151111515113151115115135351313511353
000000011111111111011110115351115315151511131115111551240014444402999496dd552449451111111515111151111355100031515315135535153515
00000011515151111151150110155311551311131511151115135100002444440544944965510494511115151151351311513510005551111153553111351010
00000000111001515111111151100551015151511151511311155100004224440149499965542445515315115131131151135110113101111351111111110000
00000000010000111115151501100131105311515311315151555002104014441299449f54422945511511151115115131351005511011531100000000000000
000000000000000151111111151501151005513111515151555550000142444404449449e4204445515115313511511355351111110155100000000000000000
00000000000000011151511511110151010150155531355555d350010144444214242449e4444444551511151115135553510150015500011000000000000000
0000000000000000001100011111111511015111515555bbbbdd5001004444400444149e94224444555553511131353513501110151001010000000000000000
000000000000000000000001515111111101311555553555bdd45000004444420494444944524494445151115151535115011015300010100000000000000000
000000000000000000010000111511511511511155555bbd5dd44002014014442441444944259499455315113135351051011111510011010000000000000000
000000000000000000010001511115111111151555d55bb515d410010140144221140444554249453d5510151513510110101511101100000000000000000000
000000000000000100001100135111151511511355b5553453550001004424100494124515529955d31110153153511011011151510010000000000000000000
000000000000000011001010511153111115315555d555544500110000944200544454411414945d351511531535511111055313000100000000000000000000
0000000000000000101001101511113153115155b55453522210110100442442410914415404449d551151351153151111153151100000000000000000000000
000000000000000001001115011515151115551bd55444110100100000422492444942515124499d555531513535111515531510000000000000000000000000
000000000000000000010111111111513553555d44554552011010000042244149af494151444499d55155311553511311353110000000000000000000000000
000000000000000000010051111513151535555534455141001001100024420249aa942531452999dd5553513531513513555100010000000000000000000000
0000000000000000010011151111151315535555d5205124001210001004202244aa9215535449449fdbbb55555311135dd35010001000000000000000000000
000000000000001101101111151115315135b4455410501221552200000200414499941555d4942299fd6db5dd551355d6351000000000000000000000000000
000000000000000111110511111511151555d4444441125112254200000104224449945555b594029499655db3535dd666551101010100000000000000000000
0000000000000011115015111511153135555b425445142520422000000144194444995555bbd421214995d6b55dd67665311010110000000000000000000000
00000000000000011105011111151115155155b5245525154445000000214429994499453dbbd520259f49ffddd66f76eb555101111000000000000000000000
0000000000000011111501511151151315555d41241245524441000001412229a999999bd934b51024d96f99966666da66531115110000000000000000000000
00000000000000111111111111111315115544921410244222410101002224249aa9999fdd5555102466f999499955dd6fd55511110000000000000000000000
00000000000000051515011511151511511115d554512542442121010122224249f999ff5555511154ff9444449455dd56d53115100000000000000000000000
0000000000010001111151111105115151111154544225422442010002103144244444eb55531315dd664154444249dd556d5131501000000000000000000000
000000000000100051111115111511355111505d45524544444411200003b3444244445553115113d6d552451420499655dd3511100010000000000000000000
000000000000100011515111151111155555500d4552454442442020001420144444255351511053d65515522101444965556531511110000000000000000000
0000000000001100051311515115111110241004955224442444400000024202494351311313153563555511012120299d15d355115100000000000000000000
000000000000011001115111111151151100001594544994442442210001210494b1351151511153d51311151240014999315d35311510000000000000000000
0000000000000150010151135153111151000124964524914222442200010014942511311311535dd31511155542024444d13553511111000000000000000000
00000000000000110100315035115111110002444f9454950114422201202004445531515153153d351315115511202204451153531515100000000000000000
0000000000010011110015115115355110000024999444454444224204445222453151113131535d513115131551420114950115351311010000000000000000
000000000000110511001531135115545000000029f44444442011222514444335513135155353d3511511511111020024950111535151101000000000000000
00000000000011011100155555511102410000100594444412244122202559dd653511513351555d531113153000001044950111353111110000000000000000
0000000000000511150103d3555515311000004421d4444204421024405545dd35135131553535d3151511015101002024910511115351151000000000000000
000000000011001511111156c5535111110000294294442042122044124553d351311115355555b5530110530011002002101115153111500000000000000000
0000000000010101151515566655535551100002444524542054202444535d551511513555555db5510100511011011421111511111315111000000000000000
00000000000150111111135df6d5551151500100220524420012424455315d3151011355553bbbb5100105111510152454455111151513010000000000000000
0000000000001511115155b66a6d55551351001010151420115424425555355150055553dbbbdb55101103111111552544455151111115100000000000000000
000000000000111151135becb5dd550115510000005502521111242495355531105353bbbbefd551015051151515544d94551111115111101000000000000000
0000000000000151151556db535355110055000000222152250420494d5515511155b64ded6d53111111151111155d9644551151111510110000000000000000
000000000000011111536b555151535111011000022441201551142149551555155b455696d5311151153115315bdf6d94451111101110000000000000000000
000000000000005153cbb553111111511511110002244500054001249455363155dd5df6dfd1515135111511155d6ff694b51511100501010000000000000000
000000000000011135dd551115115101111101100054110055111424954df95555fdd66dd63515351131110155bdffff4d511111101100000000000000000000
000000000000005155551315111115111111001100200525101545159949f5545fff65556d5355535151511135d666f5dd515151100100000000000000000000
00000000000011535535511115111111111000151000011101155049944ff4edfff650566555bbd5531111515d6c666b45351111001100000000000000000000
0000000000001115555311351115115111110001110000150125129f949ffefffff454ffd55d66535151113536dd6c6d35511111000100000000000000000000
0000000000015153111111111111111110111001110011151501549f449f9fffff949f9954fff55513115355ddd6ddd553151111000000000000000000000000
000000000001135135111015111110511100111555101515550599ff99affff9f944999449f9955315131553d3dbd3d3d5311150010000000000000000000000
00000000011511151110001131150011500015555551555544449ff99fff999994495441499955115151513d66c6d66dd3111100100000000000000000000000
00000000001515111510100055115100151101555db444496999faf99ff9f99944441d514f9451513131355d566f7ff351115111000000000000000000000000
00000000111111111110011013111111111111155d6fffffffffaffafffff99945d15d154d45111315155dd3d6f776d511511110000000000000000000000000
00000000111151001511001105531151111111115dd6fffffff99ffffffff99355515515555511111155dbd5566d666531151110000000000000000000000000
000000011111100011110151113d51115115151555befffffff9fffffffd55b55555515551111115135b6fdd6355bf6551511100000000000000000000000000
000000000110000001151011115d635315115111555bdd6fdffff6d5d6dbd555551551111111151115bdf6bd5115556653115100000000000000000000000000
000000000000000000510151515b66553135311115553555445ddb44db555555515511111111111155dffd453511356cd5150000000000000000000000000000
00000000000000000000511115bbc5d5553535351155554d444bb44d4555555511511111111131515bf6f6d5111513d365311100000000000000000000000000
0000000000000000000111155bc4553535155d3551155553d5555444555555515111111151351515ddd5bed35111115565551100000000000000000000000000
000000000000000000000051bdd5111101113ddd65511555d5555555555555551111111135151535d3555d6531100113dbd35100000000000000000000000000
000000000000000000001555bb55111111010156666d555555555555155555151111515515531555355135dd551111555dd55110000000000000000000000000
00000000000000000001055b553151511111111566766d5555555551515155111131513151111111111155353511111135dd3511000000000000000000000000
0000000000000000001155555111111151111115bff6666d3d13113151513015355151111101111111111355d351150115355551000000000000000000000000
0000000000000000001155510515151111151155ef5b555553515111111111311111111510110110111111135535111011555315110000000000000000000000
0000000000000000015551110113530511115153f5b2101115111111111155151111111111105011001151515351110010535535100000000000000000000000
00000000000000000111511100005531151115bcf551151311135151535535111111115111111110101111151115111001013151150000000000000000000000
000000000000000025151100010103d5511515bdd551130115151315151501111115151115151100111111110111100010051531510100000000000000000000
000000000000000015111010000001566d31556cb515115111111111111111511151313151111001110101001011010001001151151100000000000000000000
0000000000000005111100001010155bfff355555511151151511111151115131531515111510115000100110000000000010111511000000000000000000000
000000000000000151100000000015dcd5b5555d5113111131113515313533553553510010001151101101110000000000000013115110000000000000000000
000000000000001100000100010255555c1555455111151151355353ddddd6ddd535000101151511115011100000000000000011511100000000000000000000
00000000000000100000001000115d5551555d55535511111111535d66666d6d5110015115150005511151000000000000000001051510000000000000000000
0000000000000000000000000155bb551155545000000053515000003b0005111110000000000703115100000000000000000000111001000000000000000000
0000000000000100000000010155555101555550777770f6dd507070000700000000770777770035511010000000000000000000001110000000000000000000
00000000000000000000000055555310155555100000700000007070000777770007000000007011100000000000000000000000010000000000000000000000
00000000000000000000000115535111155555100707007777007070007007000777000000007051110100000000000000000000001010000000000000000000
00000000000000000000000553111005555511000700000000007070700077700007000000070dc5500000000000000000000000010000100000000000000000
00000000000000000000001111011015555510007000d55100070077000770005107000007700dd5510000000000000000000000000000000000000000000000
00000000000000000000000000001155555510000000000000000000000000000000000000000001000000001010000000000000000000000000000000000000
00000000000001555555555555555155555511555511555551155555555555555555555555555511111155551115551111011111111111150000000000000000
000000000000015c66667766d666dd1555110056666666666666666666d6666666dd51d6666666d676666666651536666666666776dd66650000000000000000
0000000000000000553dddd5355dd6d15151001553553ddd353535555555353d35000001dd53555dddd3555ddd51015d3d5d3dd66ddd3d500000000000000000
0000000000000000d6d3333c35313ddd1111000dd3d333333d3d3d333c1153d3d1100002d33511253333d3133dcd156d3333d3333333d3110000000000000000
000000000000000057d3dcd55cdcd335511100056dcdcd3dcdcd3dcdcd515dc3cd51001dddc1105dcdcd3dcd3d36d56dcdcd3dd3ddcdc5100000000000000000
000000000000000057dccc501dcdcdc5511000004dccd156ccc515dccd215dcdccd100ddccd100ddcdc515dccccddd66cccd111511dcd5100000000000000000
0000000000000000576c6cd211dcdccdd1100000266651666c6d21d6cd202d6cdcc501c6cc5101d6cccd21d6cdccddddc6cd2011021cd1100000000000000000
0000000000000000566666d102d66c6c650000000666d566666d15d7d5101d66666d1d666d110566666d105cc666d1d6666d10005d1dd1000000000000000000
00000000000000005e6667d105666666610000000567d566667d1dd7d1000d666666566665100166666d501c6667d1d6667d0001651d51000000000000000000
00000000000000001d67776116676766d000000001d6d2d6777d05661100016677776677d10001d6777650d667776dd67776ddd6651510000000000000000000
00000000000000005d7777667777776d105ddddd1056d2d6777d0d6d100000d667777776110000d77776667777776dd7777777776d0510000000000000000000
00000000000000056677777777777d2105d77777d10652d6777606d10000001d6777777d00001d67777777777776c567777777777d0000000000000000000000
000000000000001dd6666666666665501dd6d6d6d50dd04d666d065100000005dd6d66d210005d6666666666666d10666666666665dd10000000000000000000
00000000000000002d52225542225dd1015555551101d5ed21215d1000000001d521211000000155225545555551016d15215555515665000000000000000000
000000000000000056444421544444550111111110005d6d4542550000000000d6545421000001d4444555555100016d2542011155014d500000000000000000
0000000000000000d7d4994256949941100011100000056d4495200000000000d64444510000056d449500110000016d444510005505d4510000000000000000
00000000000000005669995116699995100000000000016699f5100000000000d69999510000007699950100000001dd99950000050569451000000000000000
00000000000000005c6fffd11d76fffd35115550000001d6f6fd100000000000d6666651000000669ffd156d100101d69a95d6ddddd6d99d5100000000000000
00000000000000001c6f67d11d76767667766d1000000136f67d00000000000056666651100000d6fffd00d7650001d6aaaaf7777fffff9dd100000000000000
00000000000000005c6777d10d66777776d51000000001c6777d1100000000015cf77650010001c6777d01d7765001d6fff7f77fffff6666d100000000000000
000000000000000d6677776dd5d67777d11100000000566677766d1000000005667777dd501116677776d66776501d777777777777777666d100000000000000
000000000000001dd67777766dd67765010000000001d667777766d10000000667777776d11166f7777777777611d7777777776777777766d100000000000000
0000000000000000156777d551d775100000000000001566777d510000000001d66776511101126677766677651115667776dd55567777765100000000000000
0000000000000000011d7d11115d510000000000000001dd67511000000000015dc761110000015d67d11155111001dd67d11100005677651000000000000000
0000000000000000001dd010011010000000000000000005cd1000000000000011d65110000000056d11111100000015cd010000001255111000000000000000
000000000000000000051000000000000000000000000000d5000000000000000015110000000001d510000000000011d5100000000111000000000000000000
00000000000000000001000000000000000000000000000011000000000000000000100000000000110000000000000011000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__meta:title__
r-type
THE rOBOz - FOR dORIAN
