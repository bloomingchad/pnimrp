from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from os import findExe,dirExists,fileExists,sleep,absolutePath
from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
from strutils import contains,repeat,splitLines
from strformat import fmt
import illwill
when defined linux: from httpclient import downloadFile,newHttpClient

include base

rect()

proc main() =
 mnuCls 0
 mnuSy 2,1,fgYellow, fmt"""Poor Mans Radio Player in Nim-lang {"-".repeat((width/8).int)}"""
 mnuSyIter 2,4,fgGreen,"Station Categories:"
 mnuSyIter 6,5,fgBlue,fmt"""1 181FM
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
Q Quit PMRP
{PLAYER}"""
 while true:
  sleep 50
  case getKey():
   of Key.None: discard
   of Key.One:
    include fm181/fm181
    fm181()
 #[of Key.Two:
    include blues/blues
    blues()
   of  Key.Three:
    include bollywood/bollywoood
    bollywood()
   of Key.Four:
    include classical/classical
    classical()
   of Key.Five:
    include country/country
    country()
   of Key.Six:
    include electronic/electronic
    electronic()
   of Key.Seven:
    include hits/hits
    hits()
   of Key.Eight:
    include jazz/jazz
    jazz()
   of Key.Nine:
    include listener/listener
    listener()
   of Key.A:
    include metal/metal
    metal()
   of Key.B:
    include news/news
    news()
   of Key.C:
    include oldies/oldies
    oldies()
   of Key.D:
    include reggae/reggae
    reggae()
   of Key.E:
    include rock/rock
    rock()
   of Key.F:
    include soma/soma
    soma()
   of Key.G:
    include urban/urban
    urban()]#
   of Key.N:
    include notes
    notes()
   of Key.Escape, Key.Q: exitProc();exitEcho()
   else:
    mnuCls 0
    Cls 2
    mnuSy 2,3,fgRed,"INVALID CHOICE"
    mnuSyIter 6,5,fgGreen,"""select a category by entering the relevant number
Ex: enter 2 to select station category Blues
To select station category News & Views enter 11
And you can select station category Rock by entering 14"""
    sleep 4000
    Cls 3
    mnuCls 0
    main()
  sleep 20

#try: 
main()
#except ValueError:
# sleep 5000
# main()
#except IndexDefect: exitProc();exitEcho()
#except IOError: echo "some files are missing or something sus happened"
#except IllwillError : discard
#except: echo "something sus happened"
