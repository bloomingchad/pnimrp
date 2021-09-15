proc back(x:uint32):void =
  for a in 1..x:
    cursorUp()
    eraseLine()

proc read():char = stdin.readLine[0]

proc parse(x:string):seq[string] = readFile(fmt"pnimrp.d/{x}").splitLines()
proc clear() =
  when defined(windows): eraseScreen()
  else:
    eraseScreen()
    setCursorPos(0,0)

proc wait() = sleep 3000

proc exitEcho() =
  echo ""
  echo "when I die, just keep playing the records"
  quit 0

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()

var width = terminalWidth()
var height = terminalHeight()

illwillInit(fullscreen=true)
setControlCHook exitProc
hideCursor()
var tb = newTerminalBuffer(width,height)

proc exec(x:string,args:openArray[string],stream:uint8) =
  if stream == 1: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
  if stream == 0: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

proc checkFileIter(x:seq[string]):bool =
  var i:uint8 = 0
  for f in 0..x.high:
    if fileExists(fmt"pnimrp.d/{x[i]}.csv"): inc i
    else: return false ; break
  return true

var amog = @["pnimrp","181FM/comedy181","181FM/easy181","181FM/latin181","181FM/oldies181","181FM/rock181","181FM/country181",
"181FM/eight181","181FM/nine181","181FM/pop181","181FM/urban181"]

if not ( dirExists("pnimrp.d") and checkFileIter amog ): exitProc(); echo "data and config files dont exist" ; quit 1

proc say(x:int,y:int,colour:ForegroundColor,txt:string) =
  tb.write x,y,colour,txt
  tb.display()

#[when defined windows:
  if findExe("nircmd.exe").contains "nircmd":
    mnuSy 2, 6 , fgRed,"nircmd was not found in your windows system"
    sleep 1000
    downloadFile "https://www.nirsoft.net/utils/nircmd.zip","nircmd.zip"
    exec "7z.exe" ,["e","nircmd.zip"],0 ]#

proc sayIter(x:int,y:int,colour:ForegroundColor,txt:string) =
  var i,j:int
  j = 0
  var res = txt.splitLines()
  i = y
  for f in 0..res.high:
    tb.write x,i,colour,res[j]
    inc i
    inc j
  tb.display()

proc clsIter(x:int) =
  if x == 0: tb.write 2,1," ".repeat(width - 4)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(width - 4)
    inc i
  tb.display()

proc cls(x:int) =
  tb.write 2,x," ".repeat(width - 4)
  tb.display()

proc inv() =
  say 2,23,fgRed,"INVALID CHOICE"
  sleep 750
  cls 23

var PLAYER:string
if findExe("mpav").contains "mpv": PLAYER = absolutePath(findExe "mpv")
elif findExe("ffpqlay").contains "ffplay": PLAYER = absolutePath(findExe "ffplay")
elif findExe("play",followSymlinks = false).contains "play": PLAYER = absolutePath(findExe("play",followSymlinks = false))
else: illwillDeinit();showCursor(); echo "error: PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ; quit 1

proc execPolled(x:string,args:openArray[string]):bool =
  if args[1] == "" or args[1].contains(" "): inv() ; return true
  var app = startProcess(x,args=args,options={poUsePath})
  say 6,10,fgGreen,"Playing.."
  #var volume:int8 = 30
  while true:
      sleep 3000
      case getKey():
        of Key.None: discard
        of Key.Slash:
          when defined linux:
            exec "amixer",["--quiet","set","PCM","7%+"],0
            say 6,13,fgRed,"Volume+"
            sleep 2000
            cls 13
          when defined freebsd: exec "mixer",["vol",fmt"{volume}"],0
          when defined windows: exec ".\nircmd.exe",["changesysvolume","5000"],0
          when defined macos:
            say 2,15,"isnt supported in macos as it needs sudo powers and is malicious for the convinience"
            sleep 5000
            cls 15
          when defined haiku: exec "setvolume",[audio],0

        of Key.Asterisk:
          when defined linux:
            exec "amixer",["--quiet","set","PCM","7%-"],0
            say 6,13,fgRed,"Volume-"
            sleep 2000
            cls 13
          when defined freebsd: exec "mixer",["vol",fmt"{volume}"],0
          when defined windows: exec ".\nircmd.exe",["changesysvolume","-5000"],0
          when defined macos:
            say 2,15,"isnt supported in macos as it needs sudo powers and is malicious for the convinience"
            sleep 5000
            cls 15
          when defined haiku: exec "setvolume",[audio],0
        of Key.P:
          say 6,10,fgGreen,"Paused.."
          suspend app
          while true:
            sleep 300
            case getKey():
              of Key.None: discard
              of Key.P:
                resume app
                say 6,10,fgGreen,"Playing.."
                sleep 1000
              of Key.R: kill app; break
              of Key.Q: kill app; exitProc(); exitEcho()
              else: inv()
        of Key.M: discard
        of Key.Q: kill app; exitProc(); exitEcho()
        of Key.Escape,Key.R: kill app; break
        else: inv()

proc call(sub,sect,stat,link:string) =
 if link == "" or link.contains " ":
  say 2,23,fgRed,"link dont exist or is invalid"
  sleep 750
 else:
  say 2,1,fgYellow,fmt"PNimRP > {sub} > {sect} > {stat}"
  clsIter 1
  if PLAYER == absolutePath(findExe "mpv"): discard execPolled(PLAYER,["--no-video",link])
  elif PLAYER == absolutePath(findExe "ffplay"): discard execPolled(PLAYER,["-nodisp",link])
  elif PLAYER == absolutePath(findExe("play",followSymlinks = false)): discard execPolled(PLAYER,["-t","mp3",link,"upsample"])

proc menuIter(sect:string,endn:uint32,arr:seq[string]) =
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

proc rect() =
  tb.setForegroundColor fgBlack, true
  tb.drawRect 0, 0, width - 1 , height - 1
  tb.drawHorizLine 2, (width/3).Natural , 2 ,doubleStyle=true
