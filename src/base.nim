from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from os import findExe,dirExists,fileExists,sleep,absolutePath
#from terminal import setCursorPos,eraseScreen,eraseLine,cursorUp
import terminal
from strutils import contains,repeat,splitLines
from strformat import fmt

proc parse*(x:string):seq[string] = splitLines readFile fmt"pnimrp.d/{x}"

proc checkFileIter*(x:seq[string]):bool =
 var i:uint8 = 0
 for f in x:
  if fileExists(fmt"pnimrp.d/{x[i]}.csv"): inc i
  else: return false
 return true

var PLAYER*:string

proc init* =
 var amog = @["pnimrp","181FM/comedy181","181FM/easy181","181FM/latin181",
 "181FM/oldies181","181FM/rock181","181FM/country181","181FM/eight181",
 "181FM/nine181","181FM/pop181","181FM/urban181"]

 if not ( dirExists "pnimrp.d" ) and checkFileIter amog: echo "data and config files dont exist" ; quit 1

 PLAYER = parse("pnimrp")[0]

 if PLAYER == "" or PLAYER.contains " ":
  when defined windows:
   if findExe("mpv").contains "mpv": PLAYER = absolutePath(findExe "mpv")
   elif findExe("play",followSymlinks = false).contains "play": PLAYER = absolutePath(findExe("play",followSymlinks = false))
   else: showCursor();echo "error: PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ; quit 1

  when not defined windows:
   if findExe("mpv").contains "mpv": PLAYER = absolutePath(findExe "mpv")
   elif findExe("play",followSymlinks = false).contains "play": PLAYER = absolutePath(findExe("play",followSymlinks = false))
   elif findExe("ffplay").contains "ffplay": PLAYER = absolutePath(findExe "ffplay")
   else: showCursor();echo "error: PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ; quit 1

proc clear*() =
 eraseScreen()
 setCursorPos 0,0

proc exitEcho* =
 showCursor()
 echo ""
 styledEcho fgCyan ,"when I die, just keep playing the records"
 quit 0

var width* = terminalWidth()

proc exec*(x:string,args:openArray[string],strm:uint8) =
 if strm == 1: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
 if strm == 0: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

proc say*(colour:ForegroundColor,txt:string) = styledEcho colour,txt

proc sayPos*(x:int,colour:ForegroundColor,a:string) =
 setCursorXPos x
 styledEcho colour,a

proc sayIter*(shift:int,colour:ForegroundColor,txt:string) =
 var e = splitLines txt
 for f in e.low..e.high:
  setCursorXPos shift
  styledEcho colour, e[f]

proc inv* =
 styledEcho fgRed,"INVALID CHOICE"
 sleep 350
 eraseLine()
 cursorUp()
 eraseLine()

proc execPolled*(x:string,args:openArray[string]):bool =
 if args[1] == "" or args[1].contains(" "): inv() ; return true
 var app = startProcess(x ,args=args)
 setCursorXPos 4
 say fgGreen,"Playing.."
 while true:
  sleep 50
  case getch():
   of '/':
    when not defined macos:
     when defined linux: exec "amixer",["--quiet","set","PCM","7%+"],0
     #when defined freebsd,netbsd,openbsd: exec "mixer",["vol",fmt""],0
     when defined windows: exec "nircmd",["changesysvolume","5000"],0
     #when defined haiku: exec "setvolume",[fmt""],0
     say fgRed,"Volume+"
     sleep 500
    else: discard

   of 'P','p':
    cursorUp()
    setCursorXPos 4
    say fgGreen,"Paused.."
    suspend app
    while true:
     sleep 300
     case getch():
      of 'P','p':
       resume app
       cursorUp()
       setCursorXPos 4
       say fgGreen,"Playing.."
       sleep 400
       break
      of 'R','r': kill app; discard waitForExit app; break
      of 'Q','q': kill app; discard waitForExit app; exitEcho()
      else: inv()
   of 'Q','q':
    kill app
    discard waitForExit app
    exitEcho()
   of 'R','r':
    kill app
    discard waitForExit app #remove app from tree completely
    break
   else: inv()

proc call*(sub,sect,stat,link:string) =
 if link == "" or link.contains " ":
  say fgRed,"link dont exist or is invalid"
  sleep 750
 else:
  clear()
  say fgYellow,fmt"PNimRP > {sub} > {sect} > {stat}"
  if PLAYER == absolutePath(findExe "mpv"): discard execPolled(PLAYER,["--no-video",link])
  elif PLAYER == absolutePath(findExe "ffplay"): discard execPolled(PLAYER,["-nodisp",link])
  elif PLAYER == absolutePath(findExe("play",followSymlinks = false)): discard execPolled(PLAYER,["-t","mp3",link,"upsample"])

#[proc menuIter(sect:string,endn:uint32,arr:seq[string]) =
 var a,b:uint8
 a = 1
 b = 0
 echo "PNimRP -> ",sect ; echo ""
 echo "Stations Playing ",sect," Music:"
 for f in 1..endn:
  echo a," ",arr[b]
  inc a
  inc b
 echo "R Return"
 echo "Q Quit"
 stdout.write "> "

proc back(x:uint32):void =
 for a in 1..x:
  cursorUp()
  eraseLine()

proc read():char = stdin.readLine[0]

proc wait = sleep 3000
proc rect = discard

when defined windows:
  if findExe("nircmd").contains "nircmd":
   mnuSy 2, 6 , fgRed,"nircmd was not found in your windows system"
   sleep 1000
   downloadFile "https://www.nirsoft.net/utils/nircmd.zip","nircmd.zip"
   exec "7z.exe" ,["e","nircmd.zip"],0

proc clsIter(x:int) =
  if x == 0: tb.write 2,1," ".repeat(width - 4)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(width - 4)
    inc i
  tb.display()

proc cls(x:int) =
  tb.write 2,x," ".repeat(width - 4)
  tb.display() ]#
