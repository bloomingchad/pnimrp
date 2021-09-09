from osproc import startProcess,waitForExit,poUsePath,poParentStreams
from os import findExe,dirExists,fileExists,sleep
from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
from strutils import endsWith,parseUInt,repeat,splitLines
from strformat import fmt
import illwill

proc exitProc() {.noconv.} =
  illwillDeinit()
  echo "when I die, just keep playing the records"
  showCursor()
  quit(0)

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

proc rect() =
  tb.setForegroundColor(fgBlack, true)
  tb.drawRect 0, 0, 60, 25
  tb.drawHorizLine 15, 40, 2 ,doubleStyle=true
rect()

proc main() =
  include base
  mnuCls()
  mnuSy 1,fgYellow,"----------Poor Man's Radio Player in Nim-lang------------"  
  mnuSyIter 4,fgBlue,"""Station Categories:
1 181FM
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
  #tb.display()
  while true:
    sleep 200
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
        mnuCls()
        mnuSy 5,fgRed," ffplay ,play cant be exited by using q"
      of Key.Escape, Key.Q: exitProc()
      else:
        mnuCls()
        mnuSyIter 5,fgGreen,"""INVALID CHOICE
select a category by entering the relevant number
Ex: enter 2 to select station category Blues
To select station category News & Views enter 11
And you can select station category Rock by entering 14"""
        sleep 2000
        mnuCls()
        main()
  tb.display()
  sleep 20

try: main()
except ValueError:
  echo ""
  echo "enter value correctly"
  discard readLine(stdin)
  main()
except IndexDefect:
  echo ""
  echo "enter a value"
  discard readLine(stdin)
  main()
except IOError: echo "some files are missing or something sus happened"
except IllwillError : discard
#except: echo "something sus happened"
