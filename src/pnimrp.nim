from os import sleep
from strutils import repeat
from terminal import getch,hideCursor,terminalWidth
import base/[termbase,initbase,menu],
 notes, fm181

hideCursor()
init()

while true:
 clear()
 say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8
 sayPos 4,"Station Categories:"
 sayIter """1 181FM
2 Blues
3 Bollywood
4 Classical
5 Country
6 Electronic
7 Hits
8 Jazz
9 Medley
A Metal
B News & Views
C Oldies
D Reggae
E Rock
F SomaFM
G Urban
N Notes
Q Quit PMRP"""
 while true:
  sleep 100
  case getch():
   of '1': fm181(); break
   of '2': endMenu10 "Blues","Blues","blues"; break
   of  '3': endMenu15 "Bollywood","Bollywood","bollywood"; break
   of '4': endMenu10 "Classical","Classical","classical"; break
   of '5': endMenu10 "Country","Country","country"; break
   of '6': endMenu10 "Electronic","Electronic","electronic"; break
   of '7': endMenu10 "Hits","Hits","hits"; break
   of '8': endMenu10 "Jazz","Jazz","jazz"; break
   #of '9': listener(); break
   of 'A','a': endMenu10 "Metal","Metal","metal"; break
   of 'B','b': endMenu15 "News","News","news"; break
   of 'C','c': endMenu10 "Oldies","Oldies","oldies"; break
   of 'D','d': endMenu10 "Reggae","reggae","reggae"; break
   of 'E','e': endMenu10 "Rock","Rock","rock"; break
   #of 'F','f': soma(); break
   of 'G','g': endMenu5 "Urban","Urban","urban"; break
   of 'N','n': notes(); break
   of 'Q','q': exitEcho()
   else: inv()
