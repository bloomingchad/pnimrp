from strformat import fmt
import terminal
from os import sleep
from strutils import repeat,splitLines

proc clear* =
 eraseScreen()
 setCursorPos 0,0

proc exitEcho* =
 showCursor()
 echo ""
 styledEcho fgCyan ,"when I die, just keep playing the records"
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

proc drawMenu*(sub,x:string; sect = "") =
 clear()
 if sect == "": say fmt"PNimRP > {sub}"
 else: say fmt"PNimRP > {sub} > {sect}"
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat int terminalWidth() / 12
 if sect == "": sayPos 4, fmt"{sub} Station Playing Music:"
 else: sayPos 4, fmt"{sect} Station Playing Music:"
 sayIter x
