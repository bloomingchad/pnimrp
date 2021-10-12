from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from strutils import contains,repeat
from os import findExe,sleep,getCurrentDir
from termbase import warn,say,sayPos,inv,clear,exitEcho
from terminal import terminalWidth,setCursorXPos,getch,cursorUp,eraseLine
from strformat import fmt

proc exec*(x:string,args:openArray[string]; stream = false) =
 if stream: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
 elif stream == false: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

proc execPolled(args:string):bool =
 var PLAYER = getCurrentDir() & "/player"
 var app = startProcess(PLAYER,args=[args])
 sayPos 4,"Playing.."
 var j = false
 while true:
  sleep 50
  case getch():
   of '/':
    when not defined macos:
     when defined linux: exec "amixer",["--quiet","set","PCM","7%+"]
     when defined windows: exec "nircmd",["changesysvolume","5000"]
     warn "Volume+"
     sleep 500
     cursorUp()
     eraseLine()
    else: discard
   of 'P','p':
    cursorUp()
    setCursorXPos 4
    warn "Paused..."
    suspend app
    while true:
     sleep 300
     case getch():
      of 'P','p':
       resume app
       cursorUp()
       sayPos 4,"Playing.."
       sleep 200
       break
      of 'R','r': kill app; discard waitForExit app; j = true; break
      of 'Q','q': kill app; discard waitForExit app; exitEcho()
      else: inv()
   of 'R','r': kill app; discard waitForExit app; break
   of 'Q','q': kill app; discard waitForExit app; exitEcho()
   else: inv()
  if j: break

proc call*(sub,sect,stat,link:string) =
 if link == "" or link.contains " ": warn "link dont exist or is invalid"; sleep 750
 else:
  clear()
  say fmt"PNimRP > {sub} > {sect} > {stat}"
  sayPos 0,'-'.repeat(int terminalWidth() / 8) & '>'.repeat int terminalWidth() / 12
  discard execPolled link
