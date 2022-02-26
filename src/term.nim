import
  osproc, terminal, random, os, #times,
  strformat, strutils, json,
  ../client/src/client

proc clear* =
  eraseScreen()
  setCursorPos 0,0

proc error*(str:string) =
  styledEcho fgRed, "Error: ", str
  quit QuitFailure

proc sayBye(str, auth: string, line = -1) =
  if str == "":
    error "no qoute"

  styledEcho fgCyan, str, "..."
  setCursorXPos 15
  styledEcho fgGreen, "—", auth

  if auth == "":
    error "there can no be qoute without man"
    if line != -1:
      error fmt"@ line: {line} in qoute.json"

proc parseJ(x: string): JsonNode =
  try:
    return parseJson readFile x
  except IOError:
    error "base assets dont exist?"

proc parseJArray(file: string): seq[string] =
  result = to(
    parseJ(file){"pnimrp"},
    seq[string]
  )

  if result.len mod 2 != 0:
    error "JArrayResult.len not even"

proc exitEcho* =
  showCursor()
  echo ""
  randomize()

  var
    seq = parseJArray "assets/qoute.json"
    qoutes, authors: seq[string] = @[]

  for i in 0 .. seq.high:
    case i mod 2:
      of 0: qoutes.add seq[i]
      else: authors.add seq[i]

  var rand = rand qoutes.low .. qoutes.high

  sayBye(
    qoutes[rand],
    authors[rand],
    rand*2
  )

  when defined debug:
    echo fmt"free mem: {getFreeMem() / 1024} kB"
    echo fmt"total/max mem: {getTotalMem() / 1024} kB"
    echo fmt"occupied mem: {getOccupiedMem() / 1024} kB"
  quit()

proc say*(txt: string) =
  styledEcho fgYellow,txt

proc sayPos*(x:int, a:string; echo = true) =
  setCursorXPos x
  if echo: styledEcho fgGreen,a
  else: stdout.styledWrite fgGreen,a

proc sayIter*(txt:string) =
  for f in splitLines txt:
    setCursorXPos 5
    styledEcho fgBlue, f

proc sayIter*(txt: seq[string]) =
  var chars =
    @[
      '1', '2', '3', '4', '5',
      '6', '7', '8', '9', 'A',
      'B', 'C', 'D', 'E', 'F',
      'G', 'H', 'I', 'J', 'K',
      'L', 'M', 'N', 'O', 'P',
      'Q', 'R', 'S', 'T', 'U',
      'V', 'W', 'X', 'Y', 'Z'
    ]
  var num = 0
  for f in txt:
    setCursorXPos 5
    if f != "Quit": styledEcho fgBlue, $chars[num], " ", f
    else: styledEcho fgBlue, "Q Quit"
    inc num

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

proc drawMenu*(sub: string ,x:string | seq[string], sect = "") =
  clear()
  if sect == "":
    say fmt"PNimRP > {sub}"
  else:
    say fmt"PNimRP > {sub} > {sect}"

  sayPos 0,'-'.repeat((terminalWidth()/8).int) & '>'.repeat int terminalWidth() / 12
  if sect == "":
    sayPos 4, fmt"{sub} Station Playing Music:"
  else:
    sayPos 4, fmt"{sect} Station Playing Music:"
  sayIter x

proc exec*(x:string,args:openArray[string]; stream = false) =
  discard waitForExit startProcess(x, args = args,
    options =
      if stream: {poUsePath,poParentStreams}
      else: {poUsePath}
  )

proc exit(ctx:ptr handle, isPaused: bool) =
  if not(isPaused):
    terminateDestroy ctx
  exitEcho()

template cE(s: cint) = checkError s

proc init(parm:string,ctx: ptr handle) =
  let file = allocCStringArray ["loadfile", parm] #couldbe file,link,playlistfile
  var val: cint = 1
  cE ctx.setOption("osc", fmtFlag, addr val)
  cE initialize ctx
  cE ctx.cmd file

proc call*(sub:string; sect = ""; stat,link:string):Natural {.discardable.} =
 if link == "": return 1
 elif link.contains " ":
   warn "link dont exist or is invalid"
 else:
  clear()
  if sect == "": say fmt"PNimRP > {sub} > {stat}"
  else: say fmt"PNimRP > {sub} > {sect} > {stat}"

  sayPos 0,'-'.repeat(int terminalWidth() / 8) & '>'.repeat int terminalWidth() / 12

  let ctx = create()
  init link, ctx
  var
   echoPlay = true
   event = ctx.waitEvent 1000
   isPaused = false

  while true:
   if echoPlay:
    sayPos 4, "Playing"
    cursorUp()
    echoPlay = false

   #remove cursorUp?
   #add time check playing error link
   if not isPaused:
     #var t0 = now().second
     event = ctx.waitEvent 1000
     #if now().second - t0 >= 5:
      # error "timeout of 5s"

   #remove casting?
   case cast[eventID](event):
     of IDShutdown, IDIdle: break
     else: discard

   case getch():
    of 'p','m','P','M':
     if isPaused:
      eraseLine()
      let ctx = create()
      init link, ctx
      echoPlay = true
      isPaused = false

     else:
      warn "Paused/Muted",4
      cursorUp()
      terminateDestroy ctx
      isPaused = true

    of '/','+':
     when defined(linux) and not defined(android):
      exec "amixer",["--quiet","set","PCM","5+"]
      #when defined windows: exec "nircmd",["changesysvolume","5000"]
     cursorDown()
     warn "Volume+", 4
     cursorUp()
     eraseLine()
     cursorUp()

    of '*','-':
     when defined(linux) and not defined(android):
      exec "amixer",["--quiet","set","PCM","5-"]
      #when defined windows: exec "nircmd",["changesysvolume","-5000"]
     cursorDown()
     warn "Volume-", 4
     cursorUp()
     eraseLine()
     cursorUp()

    of 'r','R':
     if not isPaused: terminateDestroy ctx
     break
    of 'q','Q': exit ctx, isPaused
    else: inv()

proc menu*(sub, file: string; sect = "") =
  var n, l: seq[string] = @[]
  var input = parseJArray file

  for f in input.low .. input.high:
    case f mod 2:
      of 0: n.add input[f]
      of 1: l.add input[f]
      else: discard

  while true:
    var j = false
    drawMenu sub,n,sect
    #add conditiinal check for every if len not thereown size
    #else no use danger use release
    while true:
      try:
       case getch():
        of '1': call sub,sect,n[0],l[0]; break
        of '2': call sub,sect,n[1],l[1]; break
        of '3': call sub,sect,n[2],l[2]; break
        of '4': call sub,sect,n[3],l[3]; break
        of '5': call sub,sect,n[4],l[4]; break
        of '6': call sub,sect,n[5],l[5]; break
        of '7': call sub,sect,n[6],l[6]; break
        of '8': call sub,sect,n[7],l[7]; break
        of '9': call sub,sect,n[8],l[8]; break
        of 'A','a': call sub,sect,n[9],l[9]; break
        of 'B','b': call sub,sect,n[10],n[10]; break
        of 'C','c': call sub,sect,n[11],n[11]; break
        of 'D','d': call sub,sect,n[12],n[12]; break
        of 'E','e': call sub,sect,n[13],n[13]; break
        of 'F','f': call sub,sect,n[14],n[14]; break
        of 'R','r': j = true; break
        of 'Q','q': exitEcho()
        else: inv()
      except IndexDefect: inv()
    if j: break
