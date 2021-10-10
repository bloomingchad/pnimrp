from os import sleep
from strutils import repeat
import base/[termbase,initbase],notes, terminal, fm181

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
   #[of '2': blues(); break
   of  '3': bollywood(); break
   of '4': classical(); break
   of '5': country(); break
   of '6': electronic(); break
   of '7': hits(); break
   of '8': jazz(); break
   of '9': listener(); break
   of 'A','a': metal(); break
   of 'B','b': news(); break
   of 'C','c': oldies(); break
   of 'D','d': reggae(); break
   of 'E','e': rock(); break
   of 'F','f': soma(); break
   of 'G','g': urban(); break]#
   of 'N','n': notes(); break
   of 'Q','q': exitEcho()
   else: inv()
