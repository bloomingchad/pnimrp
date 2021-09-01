from osproc import startProcess,waitForExit,poUsePath,poParentStreams
from os import findExe,dirExists,fileExists,sleep
from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
from strutils import split,endsWith,parseUInt,repeat
import illwill

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

proc main() =
  include base
  clear()
  echo """
---Poor Man's Radio Player in Nim-lang---

Station Categories:
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
  while true:
    sleep 160
    var key = getKey()
    case key:
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
        back(21)
        echo "* ffplay & play cant be exited by using q"
        e()
      of Key.Escape, Key.Q: exitEcho();exitProc()
      #[else:
        back(19)
        stdout.write """INVALID CHOICE

select a category by entering the relevant number
Ex: enter '2' to select station category 'Blues'
To select station category 'News & Views' enter '11'
And you can select station category 'Rock' by entering '14'"""
        e() ]#
      else: sleep(50) ; discard
  tb.display()
  sleep 20

main()

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
except: echo "something sus happened"
