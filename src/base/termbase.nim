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
 when not(defined release) or not(defined danger):
  echo fmt"free mem: {getFreeMem() / 1024} kB"
  echo fmt"total/max mem: {getTotalMem() / 1024} kB"
  echo fmt"occupied mem: {getOccupiedMem() / 1024} kB"
 quit QuitSuccess

proc say*(txt:string) = styledEcho fgYellow,txt

proc sayPos*(x:int,a:string) =
 setCursorXPos x
 styledEcho fgGreen,a

proc sayIter*(txt:string) =
 var e = splitLines txt
 for f in e.low..e.high:
  setCursorXPos 5
  styledEcho fgBlue, e[f]

proc sayC*(txt:string) =
 setCursorXPos 5
 styledEcho fgBlue,txt

proc warn*(txt:string) = styledEcho fgRed,txt

proc inv* =
 warn "INVALID CHOICE"
 sleep 350
 eraseLine()
 cursorUp()
 eraseLine()

#[proc drawMenu*(sub,x:string) =
 clear()
 say fmt"PNimRP > {sub}"
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat int terminalWidth() / 12
 sayPos 4, fmt"{sub} Station Playing Music:"
 sayIter x
]#
proc drawMenu*(sub,x:string; sect = "") =
 clear()
 if sect == "": say fmt"PNimRP > {sub}"
 else: say fmt"PNimRP > {sub} > {sect}"
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat int terminalWidth() / 12
 if sect == "": sayPos 4, fmt"{sub} Station Playing Music:"
 else: sayPos 4, fmt"{sect} Station Playing Music:"
 sayIter x

proc back*(x:uint32) =
 for a in 1..x:
  cursorUp()
  eraseLine()
