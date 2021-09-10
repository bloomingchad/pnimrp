from osproc import startProcess,waitForExit,poUsePath,poParentStreams,execCmd
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

var width = terminalWidth()
var height = terminalHeight()

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()
var tb = newTerminalBuffer(width, height)

proc rect() =
  tb.setForegroundColor(fgBlack, true)
  tb.drawRect 0, 0, width - 1 , height - 1
  tb.drawHorizLine 2, (width/3).Natural , 2 ,doubleStyle=true

proc main() =
  include base
  mnuCls()
  rect()
  mnuSy 2,1,fgYellow, fmt"""Poor Mans Radio Player in Nim-lang {"-".repeat((width/8).int)}"""
  mnuSyIter 2,4,fgGreen,"Station Categories:"
  mnuSyIter 6,5,fgBlue,"""1 181FM
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
        include notes
        notes()
      of Key.Escape, Key.Q: exitProc()
      else:
        mnuCls()
        Cls(2)
        mnuSy 2,3,fgRed,"INVALID CHOICE"
        mnuSyIter 6,5,fgGreen,"""select a category by entering the relevant number
Ex: enter 2 to select station category Blues
To select station category News & Views enter 11
And you can select station category Rock by entering 14"""
        sleep 6000
        Cls(3)
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
#except IOError: echo "some files are missing or something sus happened"
#except IllwillError : discard
#except: echo "something sus happened"
