from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from strutils import contains,repeat,splitLines
from os import findExe,sleep,getCurrentDir,removeFile
from termbase import warn,say,sayPos,inv,clear,exitEcho,drawMenuSect
from terminal import terminalWidth,setCursorXPos,setCursorPos,getch,cursorUp,eraseLine
from strformat import fmt

proc exec*(x:string,args:openArray[string],strm:uint8) =
 if strm == 1: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
 if strm == 0: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

proc execPolled(q,x:string,args:openArray[string]):bool =
 var curl = startProcess(q,args=["-s",args[0],"-o","temp"])
 var app = startProcess(x ,args=args)
 sayPos 4,"Playing.."
 while true:
  sleep 50
  case getch():
   of '/':
    when not defined macos:
     when defined linux: exec "amixer",["--quiet","set","PCM","7%+"],0
     when defined windows: exec "nircmd",["changesysvolume","5000"],0
     warn "Volume+"
     sleep 500
     cursorUp()
     eraseLine()
    else: discard

   of 'P','p':
    cursorUp()
    setCursorXPos 4
    warn "Paused.."
    suspend app
    while true:
     sleep 300
     case getch():
      of 'P','p':
       resume app
       cursorUp()
       setCursorXPos 4
       warn "Playing.."
       sleep 400
       break
      of 'R','r': kill app; discard waitForExit app; kill curl; discard waitForExit curl; removeFile "temp"; break
      of 'Q','q': kill app; discard waitForExit app; kill curl; discard waitForExit curl; removeFile "temp"; exitEcho()
      else: inv()
   of 'Q','q': kill app; discard waitForExit app; kill curl; discard waitForExit curl; removeFile "temp"; exitEcho()
   of 'R','r':
    kill app
    discard waitForExit app
    kill curl
    discard waitForExit curl
    removeFile "temp"
    break
   else: inv()

proc call*(sub,sect,stat,link:string) =
 if link == "" or link.contains " ":
  warn "link dont exist or is invalid"
  sleep 750
 else:
  clear()
  say fmt"PNimRP > {sub} > {sect} > {stat}"
  sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
  var curl = findExe "curl"
  var PLAYER = getCurrentDir() & "/player"
  discard execPolled(curl,PLAYER,[link])
