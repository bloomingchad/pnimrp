from osproc import startProcess,waitForExit,poUsePath,poParentStreams
from os import findExe,dirExists,fileExists,sleep
from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
from strutils import split,endsWith,parseUInt,repeat
import illwill

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  #eraseScreen()
  #setCursorPos(0,0)
  echo "when I die, just keep playing the records"
  quit(0)

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()
var tb = newTerminalBuffer(terminalWidth(), terminalHeight())
proc rect() =
  tb.setForegroundColor(fgBlack, true)
  tb.drawRect 0, 0, 60, 25
  tb.drawHorizLine(15, 40, 2, doubleStyle=true)

rect()

proc main() =
  include base
  mnuSy 1,"ye","----------Poor Man's Radio Player in Nim-lang------------"
  mnuSy 4,"","Station Categories:"
  mnuSy 5,"","1 181FM"
  mnuSy 6,"","2 Blues"
  mnuSy 7,"","3 Bollywood"
  mnuSy 8,"","4 Classical"
  mnuSy 9,"","5 Country"
  mnuSy 10,"","6 Electronic"
  mnuSy 11,"","7 Hits"
  mnuSy 12,"","8 Jazz"
  mnuSy 13,"","9 Medley"
  mnuSy 14,"","A Metal"
  mnuSy 15,"","B News & Views"
  mnuSy 16,"","C Oldies"
  mnuSy 17,"","D Reggae"
  mnuSy 18,"","E Rock"
  mnuSy 19,"","F SomaFM"
  mnuSy 20,"","G Urban"
  mnuSy 21,"","N Notes"
  mnuSy 22,"","Q Quit PMRP"
  tb.display()
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
        back(33)
        rect()
        mnuSy 5,"non"," ffplay ,play cant be exited by using q"
        e()
      of Key.Escape, Key.Q: exitProc()
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
