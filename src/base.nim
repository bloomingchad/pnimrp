proc back(x:uint32):void =
  for a in 1..x:
    cursorUp()
    eraseLine()

proc read():char = return readLine(stdin)[0]

proc clear() =
  when defined(windows): eraseScreen()
  else:
    eraseScreen()
    setCursorPos(0,0)

proc wait() = sleep 3000

proc exitEcho() = echo "when I die, just keep playing the records" ; quit(0)

proc checkFileIter(x:seq[string]):bool =
  var i:uint8 = 0
  for f in 0..x.high:
    if fileExists(fmt"pnimrp.d/{x[i]}.csv"): inc i
    else: return false ; break
  return true

var amog = @["pnimrp","181FM/comedy181","181FM/easy181","181FM/latin181","181FM/oldies181","181FM/rock181","181FM/country181",
"181FM/eight181","181FM/nine181","181FM/pop181","181FM/urban181"]

if not ( dirExists("pnimrp.d") and checkFileIter amog ): exitProc() ; exit "Data directory and Config file doesnt exist",1

proc mnuSy(x:int,y:int,colour:ForegroundColor,txt:string) =
  tb.write x,y,colour,txt
  tb.display()

proc mnuSyIter(x:int,y:int,colour:ForegroundColor,txt:string) =
  var i,j:int
  j = 0
  var res = txt.splitLines()
  i = y
  for f in 0..res.high:
    tb.write x,i,colour,res[j]
    inc i
    inc j
  tb.display()

proc mnuCls() =
  tb.write 2,1," ".repeat(width - 4)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(width - 4)
    inc i
  tb.display()

proc Cls(x:int) =
  tb.write 2,x," ".repeat(width - 4)
  tb.display()

proc inv() =
  mnuSy 2,23,fgRed,"INVALID CHOICE"
  sleep 750
  Cls(23)

proc exec(x:string,args:openArray[string],stream:uint8) =
  if stream == 1: discard waitForExit(startProcess(x,args=args,options={poUsePath,poParentStreams}))
  if stream == 0: discard waitForExit(startProcess(x,args=args,options={poUsePath}))

proc execPolled(x:string,args:openArray[string]) =
  var app = startProcess(x,args=args,options={poUsePath})
  var volume:int8 = 30
  proc s() =
    while true:
      sleep 3000
      case getKey():
        of Key.None: discard
        of Key.Slash:
          when defined linux: discard execCmd "amixer --quiet set PCM 5%+"#exec "amixer",["--quiet","set","PCM","5%+"],0
          when defined freebsd:
            exec "mixer",["vol",fmt"{volume}"],0
            volume += 5
          when defined windows: exec ".\nircmd.exe",["changesysvolume","2000"],0
          when defined macos: mnuSy 2,15,"isnt supported in macos as it needs sudo powers and is malicious for the convinience"
          when defined haiku: exec "setvolume",[audio],0
        of Key.Asterisk:
          when defined linux: exec "",["",""],0
          when defined windows: exec "",["",""],0
          when defined freebsd: exec "",["",""],0
          when defined haiku: exec "",["",""],0
        of Key.P:
          suspend(app)
          while true:
            sleep 300
            case getKey():
              of Key.None: discard
              of Key.P:
                resume(app)
                sleep 1000
                s()
              of Key.Q:
                kill(app) ; break
              else: inv()
        of Key.Escape ,Key.Q: kill(app) ; break
        else: inv()
      #echo volume
  s()
  


var PLAYER:string
if findExe("mpv").endsWith("mpv") or findExe("mpv").endsWith("mpv.exe"): PLAYER = findExe("mpv")
elif findExe("ffplay").endsWith("ffplay"):PLAYER = findExe("ffplay")
elif findExe("play").endsWith("sox"): PLAYER = "play"
else: illwillDeinit();showCursor(); exit "error: PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ,1

proc call(main,sub,stat,link:string) =
  mnuCls()
  #echo "PNimRP -> ",main," -> ",sub," -> ",stat ; echo ""
  if PLAYER == findExe("mpv"): execPolled(PLAYER,["--no-video",link])
  elif PLAYER == findExe("ffplay"): execPolled(PLAYER,["-nodisp",link])
  elif PLAYER.endsWith("play"): execPolled(PLAYER,["-t","mp3",link])

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
