from os import sleep
from strutils import repeat
from terminal import getch,terminalWidth
import base/[term,init,menu], notes, fm181, soma, listener

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
9 Listener
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
   of '2': endMenu3 "Blues","blues"; break
   of '3': endMenu15 "Bollywood","bollywood"; break
   of '4': endMenu10 "Classical","classical"; break
   of '5': endMenu10 "Country","country"; break
   of '6': endMenu10 "Electronic","electronic"; break
   of '7': endMenu10 "Hits","hits"; break
   of '8': endMenu10 "Jazz","jazz"; break
   of '9': listener(); break
   of 'A','a': endMenu10 "Metal","metal"; break
   of 'B','b': endMenu15 "News","news"; break
   of 'C','c': endMenu10 "Oldies","oldies"; break
   of 'D','d': endMenu10 "Reggae","reggae"; break
   of 'E','e': endMenu10 "Rock","rock"; break
   of 'F','f': soma(); break
   of 'G','g': endMenu5 "Urban","urban"; break
   of 'N','n': notes(); break
   of 'Q','q': exitEcho()
   else: inv()
