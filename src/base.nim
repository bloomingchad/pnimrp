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

proc wait() = discard getKey() #readLine(stdin)

proc exitEcho() = echo "when I die, just keep playing the records"

if dirExists("pnimrp.d") and fileExists("pnimrp.d/pnimrp.cfg"): discard
else: echo "Data directory and Config file doesnt exist" ; exitProc() ; quit(1)

proc mnuSy(y:int,colour:ForegroundColor,txt:string) =
  tb.write 2,y,colour,txt
  tb.display()

proc mnuSyIter(y:int,colour:ForegroundColor,txt:string) =
  var i,j:int
  j = 0
  var res = txt.splitLines()
  i = y
  for f in 0..res.high:
    tb.write 2,i,colour,res[j]
    inc i
    inc j
  tb.display()

proc mnuCls() =
  tb.write 2,1," ".repeat(57)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(50)
    inc i
  tb.display()

proc Cls(x:int) =
  tb.write 2,x," ".repeat(15)
  tb.display()

proc inv() =
  mnuSy 16,fgRed,"INVALID CHOICE"
  sleep 750
  Cls(16)

var PLAYER:string
if findExe("mpv").endsWith("mpv") or findExe("mpv").endsWith("mpv.exe"): PLAYER = findExe("mpv")
elif findExe("ffplay").endsWith("ffplay"):PLAYER = findExe("ffplay")
elif findExe("play").endsWith("sox"): PLAYER = "play"
else: echo "PNimRP requires ffplay, mpv or play. Install to enjoy PMRP" ; quit(1)

proc call(mainname,subname,statname,link:string):void =
  mnuCls()
  echo "PNimRP -> ",mainname," -> ",subname," -> ",statname
  echo ""
  if PLAYER == findExe("mpv"): discard waitForExit(startProcess(PLAYER, args=["--no-video",link],options={poUsePath,poParentStreams}))
  elif PLAYER == findExe("ffplay"): discard waitForExit(startProcess(PLAYER, args=["-nodisp",link],options={poUsePath,poParentStreams}))
  elif PLAYER.endsWith("play"): discard waitForExit(startProcess(PLAYER, args=["-t","mp3",link],options={poUsePath,poParentStreams}))

proc menuIter(sect:string,endn:uint32,arr:seq[string]) =
  var a,b:uint8
  a = 1
  b = 0
  echo "PNimRP -> ",sect
  echo ""
  echo "Stations Playing ",sect," Music:"
  for f in 1..endn:
    echo a," ",arr[b]
    inc a
    inc b
  echo "R Return"
  echo "Q Quit"
  stdout.write "> "
