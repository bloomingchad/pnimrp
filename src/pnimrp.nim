from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from os import findExe,dirExists,fileExists,sleep,absolutePath
#from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
import terminal
from strutils import contains,repeat,splitLines
from strformat import fmt

include base

rect()
hideCursor()

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
  sleep 90
  case getch():
   of '1':
    include fm181/fm181
    fm181()
    break
 #[of '2':
    include blues/blues
    blues()
    break
   of  '3':
    include bollywood/bollywoood
    bollywood()
    break
   of '4':
    include classical/classical
    classical()
    break
   of '5':
    include country/country
    country()
    break
   of '6':
    include electronic/electronic
    electronic()
    break
   of '7':
    include hits/hits
    hits()
    break
   of '8':
    include jazz/jazz
    jazz()
    break
   of '9':
    include listener/listener
    listener()
    break
   of 'A','a':
    include metal/metal
    metal()
    break
   of 'B','b':
    include news/news
    news()
    break
   of 'C','c':
    include oldies/oldies
    oldies()
    break
   of 'D','d':
    include reggae/reggae
    reggae()
    break
   of 'E','e':
    include rock/rock
    rock()
    break
   of 'F','f':
    include soma/soma
    soma()
    break
   of 'G','g':
    include urban/urban
    urban()
    break]#
   of 'N','n':
    include notes
    notes()
    break
   of 'Q','q': exitEcho()
   else: inv()
  sleep 20
