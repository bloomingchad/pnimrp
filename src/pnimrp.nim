import term, os, terminal, notes, fm181, soma, listener, strutils

if not dirExists "assets":
  error "data or config files dont exist"

#disable volControl in koch?
when defined(linux) and not defined(android):
  if findExe("amixer") == "":
    error "alsa mixer utilities not found. please install it for volume control"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD
  Please see user.rst for more information""".}

hideCursor()

while true:
 clear()
 say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8
 sayPos 4,"Station Categories:"
 sayIter """1 FM181
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
  case getch():
   of '1': fm181(); break
   of '2': menu "Blues","blues"; break
   of '3': menu "Bollywood","bollywood"; break
   of '4': menu "Classical","classical"; break
   of '5': menu "Country","country"; break
   of '6': menu "Electronic","electronic"; break
   of '7': menu "Hits","hits"; break
   of '8': menu "Jazz","jazz"; break
   of '9': listener(); break
   of 'A','a': menu "Metal","metal"; break
   of 'B','b': menu "News","news"; break
   of 'C','c': menu "Oldies","oldies"; break
   of 'D','d': menu "Reggae","reggae"; break
   of 'E','e': menu "Rock","rock"; break
   of 'F','f': soma(); break
   of 'G','g': menu "Urban","urban"; break
   of 'N','n': notes(); break
   of 'Q','q': exitEcho()
   else: inv()
