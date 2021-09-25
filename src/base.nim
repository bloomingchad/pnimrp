from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from os import findExe,dirExists,fileExists,sleep,absolutePath,getCurrentDir,removeFile
import terminal
from strutils import contains,repeat,splitLines

proc parse*(x:string):seq[string] = splitLines readFile "pnimrp.d/" & x

proc checkFileIter*(x:seq[string]):bool =
 var i:uint8 = 0
 for f in x:
  if fileExists("pnimrp.d/" & x[i] & ".csv"): inc i
  else: return false
 return true

proc init* =
 var amog = @["pnimrp","181FM/comedy181","181FM/easy181","181FM/latin181",
 "181FM/oldies181","181FM/rock181","181FM/country181","181FM/eight181",
 "181FM/nine181","181FM/pop181","181FM/urban181"]

 if not ( dirExists "pnimrp.d" ) and checkFileIter amog: echo "data and config files dont exist" ; quit 1

proc initPlayer():string =
 var PLAYER:string = parse("pnimrp.csv")[0]
 if PLAYER == "" or PLAYER.contains " ":
  when defined windows:
   if findExe("mpv").contains "mpv": PLAYER = absolutePath(findExe "mpv")
   elif findExe("play",followSymlinks = false).contains "play": PLAYER = absolutePath(findExe("play",followSymlinks = false))
   else: showCursor();echo "error: PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ; quit 1

  when not defined windows:
   return getCurrentDir() & "/player"
 #"pnimrp.d/pnimrp.csv".writeFile PLAYER
 #return PLAYER

proc clear*() =
 eraseScreen()
 setCursorPos 0,0

proc byteKb(x:int):float32 = x / 1024

proc exitEcho* =
 showCursor()
 echo ""
 styledEcho fgCyan ,"when I die, just keep playing the records"
 when not (defined release) or (defined danger):
  stdout.write "free mem: "
  stdout.write byteKb getFreeMem()
  echo " kB"
  stdout.write "total/max mem: "
  stdout.write  byteKb getTotalMem()
  echo " kB"
  stdout.write "occupied mem: "
  stdout.write byteKb getOccupiedMem()
  echo " kB"
 quit 0

proc exec*(x:string,args:openArray[string],strm:uint8) =
 if strm == 1: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
 if strm == 0: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

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

proc warn*(txt:string) =  styledEcho fgRed,txt

proc inv* =
 styledEcho fgRed,"INVALID CHOICE"
 sleep 350
 eraseLine()
 cursorUp()
 eraseLine()

proc execPolled(q,x:string,args:openArray[string]):bool =
 when defined windows:
  if x.contains "play":
   if args[2] == "" or args[2].contains " ":
    inv() ; return true
  else:
   if args[1] == "" or args[1].contains " ":
    inv() ; return true
 else:
  if args[0] == "" or args[0].contains " ": inv() ; return true
  var curl = startProcess(q,args=["-s",args[0],"-o","temp"])
 var app = startProcess(x ,args=args)
 sayPos 4,"Playing.."
 while true:
  sleep 50
  case getch():
   of '/':
    when not defined macos:
     when defined linux: exec "amixer",["--quiet","set","PCM","7%+"],0
     #when defined freebsd,netbsd,openbsd: exec "mixer",["vol",""],0
     when defined windows: exec "nircmd",["changesysvolume","5000"],0
     #when defined haiku: exec "setvolume",[""],0
     warn "Volume+"
     sleep 500
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
      of 'R','r':kill app; discard waitForExit app; kill curl; discard waitForExit curl; removeFile "temp"; break
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
  say "PNimRP > " & sub & " > " & sect & " > " & stat
  sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
  var curl = findExe "curl"
  var PLAYER = initPlayer()
  when defined windows:
   if PLAYER.contains "mpv": discard execPolled(curl,PLAYER,["--no-video",link])
   elif PLAYER.contains "play": discard execPolled(curl,PLAYER,["-t","mp3",link,"upsample"])
  when not defined windows: discard execPolled(curl,PLAYER,[link])

proc drawMenuSect*(sub,sect,x:string) =
 clear()
 say "PNimRP > " & sub & " > " & sect
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
 sayPos 4, sect & " Station Playing Music:"
 sayIter x

proc drawMenu*(sub,x:string) =
 clear()
 say "PNimRP > " & sub
 sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat(int(terminalWidth()/12))
 sayPos 4, sub & " Station Playing Music:"
 sayIter x

proc back*(x:uint32) =
 for a in 1..x:
  cursorUp()
  eraseLine()

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

proc read():char = stdin.readLine[0]

proc wait = sleep 3000

when defined windows:
  if findExe("nircmd").contains "nircmd":
   mnuSy 2, 6 , fgRed,"nircmd was not found in your windows system"
   sleep 1000
   downloadFile "https://www.nirsoft.net/utils/nircmd.zip","nircmd.zip"
   exec "7z.exe" ,["e","nircmd.zip"],0

proc clsIter(x:int) =
  if x == 0: tb.write 2,1," ".repeat(terminalWidth() - 4)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(terminalWidth() - 4)
    inc i
  tb.display()

proc cls(x:int) =
  tb.write 2,x," ".repeat(terminalWidth() - 4)
  tb.display() ]#
