#from terminal import getch,hideCursor
import terminal,os,strutils
from strformat import fmt
import base,notes
import fm181/fm181

hideCursor()
init()

while true:
 clear()
 say fgYellow, fmt"""Poor Mans Radio Player in Nim-lang {"-".repeat((width/8).int)}"""
 sayPos 4,fgGreen,"Station Categories:"
 sayIter 5,fgBlue,"""1 181FM
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
