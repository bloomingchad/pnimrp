from strformat import fmt
import terminal
import random
from os import sleep
from strutils import repeat,splitLines

proc clear* =
 eraseScreen()
 setCursorPos 0,0

proc sayBye(str:string;auth = "Human") =
 styledEcho fgCyan, str, "..."
 setCursorXPos 15
 styledEcho fgGreen, "—", auth

proc exitEcho* =
 showCursor()
 echo ""
 randomize()
 case rand 1..6:
  of 1: sayBye "When I Die, Keep Playing The Records"
  of 2: sayBye "Where words fail, music speaks", "Hans Christian Andersen"
  of 3: sayBye "Country music is three chords and truth", "Harlan Howard"
  of 4:
   sayBye "There are two ways of refuge from misery — music and cats",
     "Albert Schweitzer"

  of 5: sayBye "Music is a safe kind of high", "Jimi Hendrix"
  of 6:
   sayBye "You enjoy music when you're happy, you understand lyrics when you're sad",
    "Frank Ocean"
  else: discard

 when defined debug:
  echo fmt"free mem: {getFreeMem() / 1024} kB"
  echo fmt"total/max mem: {getTotalMem() / 1024} kB"
  echo fmt"occupied mem: {getOccupiedMem() / 1024} kB"
 quit QuitSuccess

proc say*(txt:string) = styledEcho fgYellow,txt

proc sayPos*(x:int,a:string; echo = true) =
 setCursorXPos x
 if echo: styledEcho fgGreen,a
 else: stdout.styledWrite fgGreen,a

proc sayIter*(txt:string) =
 for f in splitLines txt:
  setCursorXPos 5
  styledEcho fgBlue, f

proc warn*(txt:string; x = -1) =
 if not(x == -1): setCursorXPos x
 styledEcho fgRed,txt
 #if echo == false: stdout.styledWrite fgRed,txt
 #default Args dosent seem to be working?
 sleep 750

proc inv* =
 cursorDown()
 warn "INVALID CHOICE", 4
 cursorUp()
 eraseLine()
 cursorUp()

proc error*(str:string) =
 styledEcho fgRed, "Error: ", str
 quit QuitFailure

proc drawMenu*(sub,x:string; sect = "") =
 clear()
 if sect == "": say fmt"PNimRP > {sub}"
 else: say fmt"PNimRP > {sub} > {sect}"
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat int terminalWidth() / 12
 if sect == "": sayPos 4, fmt"{sub} Station Playing Music:"
 else: sayPos 4, fmt"{sect} Station Playing Music:"
 sayIter x
